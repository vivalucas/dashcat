import Cocoa
import CoreGraphics
import ImageIO
import SQLite3
import UniformTypeIdentifiers
import os.log

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let maxTextLength = 10000
private let filterTermsKey = "DashCatClipboardFilterTerms"

extension NSNotification.Name {
    static let DashCatClipboardDidChange = NSNotification.Name("DashCatClipboardDidChange")
}

struct ClipboardItem {
    let id: Int64
    let content: String?
    let imagePath: String?
    let sourceApp: String
    let isPinned: Bool
    let createdAt: TimeInterval

    var isImage: Bool { imagePath != nil }
}

final class ClipboardManager {
    static let shared = ClipboardManager()

    private var db: OpaquePointer?
    private let maintenanceQueue = DispatchQueue(label: "com.dashcat.app.clipboard-maintenance", qos: .utility)
    private let stateLock = NSLock()
    private var changeCount: Int = 0
    private var pollTimer: Timer?
    private var lastStorageCheck: TimeInterval = 0
    private var latestCache: ClipboardItem?
    private var filterTerms: [String] = []

    private let dbPath: String
    private let imagesDir: String
    private let logger = Logger(subsystem: "com.dashcat.app", category: "ClipboardManager")

    private init() {
        let appSupport = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
        let baseDir = (appSupport as NSString).appendingPathComponent("DashCat")
        dbPath = (baseDir as NSString).appendingPathComponent("clipboard.db")
        imagesDir = (baseDir as NSString).appendingPathComponent("Images")

        try? FileManager.default.createDirectory(atPath: baseDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: imagesDir, withIntermediateDirectories: true)

        openDatabase()
        createTable()
        reloadFilterTerms()
        cleanupExpired()

        changeCount = NSPasteboard.general.changeCount
    }

    deinit {
        pollTimer?.invalidate()
        if db != nil { sqlite3_close(db) }
    }

    // MARK: - Database

    private func openDatabase() {
        if sqlite3_open_v2(dbPath, &db,
                           SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
                           nil) != SQLITE_OK {
            logger.error("Failed to open database at \(self.dbPath)")
            db = nil
            return
        }
        sqlite3_exec(db, "PRAGMA journal_mode=WAL", nil, nil, nil)
    }

    private func createTable() {
        let sql = """
            CREATE TABLE IF NOT EXISTS clipboard_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                content TEXT,
                image_path TEXT,
                source_app TEXT NOT NULL DEFAULT '',
                is_pinned INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_created_at ON clipboard_history(created_at);
            """
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logger.error("Failed to create clipboard_history table")
        }
    }

    // MARK: - Polling

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        if let timer = pollTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func syncChangeCount() {
        changeCount = NSPasteboard.general.changeCount
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != changeCount else { return }
        changeCount = pb.changeCount

        let sourceApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        let string = pb.string(forType: .string)
        let imageData = pb.data(forType: .tiff) ?? pb.data(forType: .png)
        maintenanceQueue.async { [weak self] in
            self?.processPasteboardSnapshot(string: string, imageData: imageData, sourceApp: sourceApp)
        }
    }

    private func processPasteboardSnapshot(string: String?, imageData: Data?, sourceApp: String) {
        // Try text first
        if let string, !string.isEmpty {
            guard !shouldSkipText(string) else { return }
            let truncated = string.count > maxTextLength ? String(string.prefix(maxTextLength)) : string
            // Normalize Windows/Mac line endings to Unix
            let normalized = truncated
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
            // Skip duplicate of last item
            if let last = fetchLatest(), !last.isImage, last.content == normalized { return }
            insert(content: normalized, imagePath: nil, sourceApp: sourceApp)
            return
        }

        // Try image (TIFF or PNG)
        if UserDefaults.standard.bool(forKey: "DashCatSaveImages"),
           let data = imageData {
            if let saved = saveImage(from: data) {
                insert(content: nil, imagePath: saved, sourceApp: sourceApp)
            }
        }
    }

    // MARK: - Filter Terms

    func savedFilterTerms() -> [String] {
        UserDefaults.standard.stringArray(forKey: filterTermsKey) ?? []
    }

    func setFilterTerms(_ terms: [String]) {
        let normalized = normalizeTermsForStorage(terms)
        UserDefaults.standard.set(normalized, forKey: filterTermsKey)
        reloadFilterTerms()
    }

    func reloadFilterTerms() {
        let terms = normalizeTermsForStorage(savedFilterTerms()).map { $0.lowercased() }
        stateLock.lock()
        filterTerms = terms
        stateLock.unlock()
    }

    private func shouldSkipText(_ text: String) -> Bool {
        stateLock.lock()
        let terms = filterTerms
        stateLock.unlock()
        guard !terms.isEmpty else { return false }
        let lowercased = text.lowercased()
        return terms.contains { lowercased.contains($0) }
    }

    private func normalizeTermsForStorage(_ terms: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for term in terms {
            let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let key = trimmed.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(trimmed)
        }
        return result
    }

    // MARK: - Image Storage

    private func saveImage(from data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        let uuid = UUID().uuidString
        let maxDimension: CGFloat = 500
        let scaledImage = scaleImage(image, maxDimension: maxDimension) ?? image

        let fileName = "\(uuid).jpg"
        let filePath = (imagesDir as NSString).appendingPathComponent(fileName)
        guard writeJPEG(scaledImage, to: URL(fileURLWithPath: filePath), quality: 0.6) else {
            return nil
        }

        if let thumbnail = scaleImage(scaledImage, maxDimension: 80) {
            let thumbPath = (imagesDir as NSString).appendingPathComponent("\(uuid)_thumb.jpg")
            _ = writeJPEG(thumbnail, to: URL(fileURLWithPath: thumbPath), quality: 0.6)
        }

        return fileName
    }

    // MARK: - CRUD

    private func insert(content: String?, imagePath: String?, sourceApp: String) {
        guard db != nil else { return }
        let now = Date().timeIntervalSince1970
        var stmt: OpaquePointer?
        let sql = "INSERT INTO clipboard_history (content, image_path, source_app, is_pinned, created_at) VALUES (?, ?, ?, 0, ?)"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        if let content = content {
            sqlite3_bind_text(stmt, 1, content, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        if let path = imagePath {
            sqlite3_bind_text(stmt, 2, path, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(stmt, 2)
        }
        sqlite3_bind_text(stmt, 3, sourceApp, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 4, now)
        if sqlite3_step(stmt) == SQLITE_DONE {
            let rowId = sqlite3_last_insert_rowid(db)
            stateLock.lock()
            let fullImagePath = imagePath.map { (self.imagesDir as NSString).appendingPathComponent(($0 as NSString).lastPathComponent) }
            latestCache = ClipboardItem(id: rowId, content: content, imagePath: fullImagePath,
                                        sourceApp: sourceApp, isPinned: false, createdAt: now)
            stateLock.unlock()
        } else {
            logger.error("Failed to insert clipboard item")
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: nil)
        }

        // Throttle storage check to at most once per 60 seconds
        stateLock.lock()
        let shouldEnforce = now - lastStorageCheck > 60
        if shouldEnforce { lastStorageCheck = now }
        stateLock.unlock()
        if shouldEnforce {
            maintenanceQueue.async { [weak self] in
                self?.enforceMaxStorage()
            }
        }
    }

    func fetchAll(limit: Int = 200) -> [ClipboardItem] {
        guard db != nil else { return [] }
        var items: [ClipboardItem] = []
        var stmt: OpaquePointer?
        let sql = "SELECT id, content, image_path, source_app, is_pinned, created_at FROM clipboard_history ORDER BY is_pinned DESC, created_at DESC LIMIT ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int(stmt, 1, Int32(limit))
        while sqlite3_step(stmt) == SQLITE_ROW {
            items.append(itemFromRow(stmt))
        }
        return items
    }

    func search(query: String) -> [ClipboardItem] {
        guard db != nil, !query.isEmpty else { return [] }
        var items: [ClipboardItem] = []
        var stmt: OpaquePointer?
        let sql = "SELECT id, content, image_path, source_app, is_pinned, created_at FROM clipboard_history WHERE content LIKE ? ESCAPE '\\' ORDER BY is_pinned DESC, created_at DESC LIMIT 200"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        // Escape SQL wildcards in user input
        let escaped = query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
        let pattern = "%\(escaped)%"
        sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
        while sqlite3_step(stmt) == SQLITE_ROW {
            items.append(itemFromRow(stmt))
        }
        return items
    }

    func togglePin(id: Int64) {
        guard db != nil else { return }
        stateLock.lock()
        latestCache = nil
        stateLock.unlock()
        var stmt: OpaquePointer?
        let sql = "UPDATE clipboard_history SET is_pinned = 1 - is_pinned WHERE id = ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logger.error("Failed to prepare togglePin statement")
            return
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int64(stmt, 1, id)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logger.error("Failed to toggle pin for item \(id)")
        }
    }

    func deleteItem(id: Int64) {
        guard db != nil else { return }
        stateLock.lock()
        latestCache = nil
        stateLock.unlock()

        var imagePath: String?
        var stmt: OpaquePointer?
        let selectSql = "SELECT image_path FROM clipboard_history WHERE id = ?"
        if sqlite3_prepare_v2(db, selectSql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW, let cStr = sqlite3_column_text(stmt, 0) {
                let dbPath = String(cString: cStr)
                imagePath = (imagesDir as NSString).appendingPathComponent((dbPath as NSString).lastPathComponent)
            }
        }

        var delStmt: OpaquePointer?
        let delSql = "DELETE FROM clipboard_history WHERE id = ?"
        guard sqlite3_prepare_v2(db, delSql, -1, &delStmt, nil) == SQLITE_OK else {
            logger.error("Failed to prepare deleteItem statement")
            return
        }
        defer { sqlite3_finalize(delStmt) }
        sqlite3_bind_int64(delStmt, 1, id)
        if sqlite3_step(delStmt) != SQLITE_DONE {
            logger.error("Failed to delete item \(id)")
            return
        }

        if let path = imagePath {
            try? FileManager.default.removeItem(atPath: path)
            if let thumbPath = thumbnailPath(for: path) {
                try? FileManager.default.removeItem(atPath: thumbPath)
            }
        }
    }

    func clearAll(includePinned: Bool = false, completion: (() -> Void)? = nil) {
        maintenanceQueue.async { [weak self] in
            self?.clearAllOnMaintenanceQueue(includePinned: includePinned)
            if let completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func thumbnailPath(for path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        guard url.pathExtension.lowercased() == "jpg" else { return nil }
        let stem = url.deletingPathExtension().lastPathComponent
        let dir = url.deletingLastPathComponent().path
        return (dir as NSString).appendingPathComponent("\(stem)_thumb.jpg")
    }

    // MARK: - Cleanup

    func cleanupExpired() {
        cleanupExpired(completion: nil)
    }

    func cleanupExpired(completion: (() -> Void)?) {
        maintenanceQueue.async { [weak self] in
            self?.cleanupExpiredOnMaintenanceQueue()
            if let completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    private func cleanupOrphanedImages() {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) else { return }

        // Fetch all known image paths in one query (fixes N+1)
        var dbPaths = Set<String>()
        var stmt: OpaquePointer?
        let sql = "SELECT image_path FROM clipboard_history WHERE image_path IS NOT NULL"
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            while sqlite3_step(stmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(stmt, 0) {
                    let dbPath = String(cString: cStr)
                    let fullPath = (imagesDir as NSString).appendingPathComponent((dbPath as NSString).lastPathComponent)
                    dbPaths.insert(fullPath)
                }
            }
        }

        for file in files where !file.hasSuffix("_thumb.jpg") {
            let path = (imagesDir as NSString).appendingPathComponent(file)
            if !dbPaths.contains(path) {
                try? FileManager.default.removeItem(atPath: path)
                if let thumbPath = thumbnailPath(for: path) {
                    try? FileManager.default.removeItem(atPath: thumbPath)
                }
            }
        }
    }

    private func clearAllOnMaintenanceQueue(includePinned: Bool) {
        guard db != nil else { return }
        stateLock.lock()
        latestCache = nil
        stateLock.unlock()

        let sql = includePinned ? "DELETE FROM clipboard_history" : "DELETE FROM clipboard_history WHERE is_pinned = 0"
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            logger.error("Failed to clear clipboard history")
            return
        }

        if sqlite3_exec(db, "VACUUM", nil, nil, nil) != SQLITE_OK {
            logger.error("Failed to vacuum clipboard database after clearing history")
        }

        cleanupOrphanedImages()
    }

    private func cleanupExpiredOnMaintenanceQueue() {
        guard db != nil else { return }
        stateLock.lock()
        latestCache = nil
        stateLock.unlock()

        let days = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
        let effectiveDays = days > 0 ? days : 30
        if effectiveDays >= 36500 {
            cleanupOrphanedImages()
            return
        } // "Forever" = ~100 years

        let cutoff = Date().timeIntervalSince1970 - Double(effectiveDays * 86400)

        // Delete expired records
        var stmt: OpaquePointer?
        let sql = "DELETE FROM clipboard_history WHERE is_pinned = 0 AND created_at < ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, cutoff)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logger.error("Failed to clean expired clipboard records")
            return
        }

        // Clean orphaned images
        cleanupOrphanedImages()
    }

    private func scaleImage(_ image: CGImage, maxDimension: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let largest = max(width, height)
        guard largest > maxDimension else { return image }

        let scale = maxDimension / largest
        let targetWidth = max(1, Int((width * scale).rounded()))
        let targetHeight = max(1, Int((height * scale).rounded()))
        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                      width: targetWidth,
                                      height: targetHeight,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        return context.makeImage()
    }

    private func writeJPEG(_ image: CGImage, to url: URL, quality: CGFloat) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                                UTType.jpeg.identifier as CFString,
                                                                1,
                                                                nil) else {
            return false
        }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        return CGImageDestinationFinalize(destination)
    }

    private func enforceMaxStorage() {
        let maxBytes: Int64 = 500 * 1024 * 1024 // 500 MB
        cleanupOrphanedImages()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) else { return }

        // Collect only non-thumbnail jpg files with their sizes and dates
        var totalSize: Int64 = 0
        var imageFiles: [(file: String, size: Int64, modifiedAt: Date)] = []
        for file in files where file.hasSuffix(".jpg") && !file.hasSuffix("_thumb.jpg") {
            let path = (imagesDir as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                let modifiedAt = attrs[.modificationDate] as? Date ?? .distantPast
                totalSize += size
                imageFiles.append((file: file, size: size, modifiedAt: modifiedAt))
            }
        }
        guard totalSize > maxBytes else { return }
        stateLock.lock()
        latestCache = nil
        stateLock.unlock()

        // Batch-query all pinned image paths
        var pinnedPaths = Set<String>()
        var pinStmt: OpaquePointer?
        let pinSql = "SELECT image_path FROM clipboard_history WHERE is_pinned = 1 AND image_path IS NOT NULL"
        if sqlite3_prepare_v2(db, pinSql, -1, &pinStmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(pinStmt) }
            while sqlite3_step(pinStmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(pinStmt, 0) {
                    let dbPath = String(cString: cStr)
                    let fullPath = (imagesDir as NSString).appendingPathComponent((dbPath as NSString).lastPathComponent)
                    pinnedPaths.insert(fullPath)
                }
            }
        }

        // Sort by modification date, delete oldest first
        imageFiles.sort { $0.modifiedAt < $1.modifiedAt }

        for (file, size, _) in imageFiles {
            guard totalSize > maxBytes else { break }
            let path = (imagesDir as NSString).appendingPathComponent(file)

            // Skip pinned items
            if pinnedPaths.contains(path) { continue }

            // Delete the database record first with a pinned guard. This prevents
            // a newly pinned item from being removed by an older cleanup snapshot.
            var delStmt: OpaquePointer?
            let delSql = "DELETE FROM clipboard_history WHERE image_path LIKE ? AND is_pinned = 0"
            if sqlite3_prepare_v2(db, delSql, -1, &delStmt, nil) == SQLITE_OK {
                let pattern = "%" + file
                sqlite3_bind_text(delStmt, 1, pattern, -1, SQLITE_TRANSIENT)
                let deleted = sqlite3_step(delStmt) == SQLITE_DONE && sqlite3_changes(db) > 0
                sqlite3_finalize(delStmt)
                guard deleted else { continue }
            } else {
                continue
            }

            try? FileManager.default.removeItem(atPath: path)
            // Delete thumbnail too
            if let thumbPath = thumbnailPath(for: path) {
                try? FileManager.default.removeItem(atPath: thumbPath)
            }
            totalSize -= size
        }
    }

    // MARK: - Helpers

    private func fetchLatest() -> ClipboardItem? {
        stateLock.lock()
        if let cache = latestCache {
            stateLock.unlock()
            return cache
        }
        stateLock.unlock()
        guard db != nil else { return nil }
        var stmt: OpaquePointer?
        let sql = "SELECT id, content, image_path, source_app, is_pinned, created_at FROM clipboard_history ORDER BY created_at DESC LIMIT 1"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            let item = itemFromRow(stmt)
            stateLock.lock()
            latestCache = item
            stateLock.unlock()
            return item
        }
        return nil
    }

    private func itemFromRow(_ stmt: OpaquePointer?) -> ClipboardItem {
        let id = sqlite3_column_int64(stmt, 0)
        let content = sqlite3_column_text(stmt, 1).map { String(cString: $0) }
        var imagePath = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
        if let path = imagePath {
            imagePath = (imagesDir as NSString).appendingPathComponent((path as NSString).lastPathComponent)
        }
        let sourceApp = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
        let isPinned = sqlite3_column_int(stmt, 4) != 0
        let createdAt = sqlite3_column_double(stmt, 5)
        return ClipboardItem(id: id, content: content, imagePath: imagePath,
                             sourceApp: sourceApp, isPinned: isPinned, createdAt: createdAt)
    }
}
