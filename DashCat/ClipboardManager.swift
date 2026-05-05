import Cocoa
import SQLite3
import os.log

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let maxTextLength = 10000

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
    private var changeCount: Int = 0
    private var pollTimer: Timer?
    private var lastStorageCheck: TimeInterval = 0

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
        cleanupExpired()

        changeCount = NSPasteboard.general.changeCount
    }

    deinit {
        pollTimer?.invalidate()
        if db != nil { sqlite3_close(db) }
    }

    // MARK: - Database

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
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

        // Try text first
        if let string = pb.string(forType: .string), !string.isEmpty {
            let truncated = string.count > maxTextLength ? String(string.prefix(maxTextLength)) : string
            // Skip duplicate of last item
            if let last = fetchLatest(), !last.isImage, last.content == truncated { return }
            insert(content: truncated, imagePath: nil, sourceApp: sourceApp)
            return
        }

        // Try image
        if UserDefaults.standard.bool(forKey: "DashCatSaveImages"),
           let tiff = pb.data(forType: .tiff) {
            let image = NSImage(data: tiff)
            if let saved = saveImage(image) {
                insert(content: nil, imagePath: saved, sourceApp: sourceApp)
            }
        }
    }

    // MARK: - Image Storage

    private func saveImage(_ image: NSImage?) -> String? {
        guard let tiffData = image?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        let uuid = UUID().uuidString
        let maxSize: CGFloat = 500

        // Save compressed original
        let targetSize: NSSize
        let origSize = bitmap.size
        if origSize.width > maxSize || origSize.height > maxSize {
            let scale = maxSize / max(origSize.width, origSize.height)
            targetSize = NSSize(width: origSize.width * scale, height: origSize.height * scale)
        } else {
            targetSize = origSize
        }

        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        bitmap.draw(in: NSRect(origin: .zero, size: targetSize),
                    from: .zero, operation: .copy, fraction: 1.0, respectFlipped: true, hints: nil)
        resized.unlockFocus()

        guard let resizedRep = resized.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0) }) else { return nil }

        // Try decreasing compression until under 500KB
        let maxImageBytes = 500 * 1024
        var jpegData: Data?
        for factor: CGFloat in [0.6, 0.4, 0.25] {
            if let data = resizedRep.representation(using: .jpeg, properties: [.compressionFactor: factor]) {
                jpegData = data
                if data.count <= maxImageBytes { break }
            }
        }
        guard let finalData = jpegData else { return nil }

        let filePath = (imagesDir as NSString).appendingPathComponent("\(uuid).jpg")
        let url = URL(fileURLWithPath: filePath)
        do {
            try finalData.write(to: url)
        } catch {
            return nil
        }

        // Save thumbnail
        let thumbSize = NSSize(width: 80, height: 80)
        let thumb = NSImage(size: thumbSize)
        thumb.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        resizedRep.draw(in: NSRect(origin: .zero, size: thumbSize),
                        from: .zero, operation: .copy, fraction: 1.0, respectFlipped: true, hints: nil)
        thumb.unlockFocus()

        if let thumbRep = thumb.tiffRepresentation.flatMap({ NSBitmapImageRep(data: $0) }),
           let thumbData = thumbRep.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) {
            let thumbPath = (imagesDir as NSString).appendingPathComponent("\(uuid)_thumb.jpg")
            try? thumbData.write(to: URL(fileURLWithPath: thumbPath))
        }

        return filePath
    }

    // MARK: - CRUD

    private func insert(content: String?, imagePath: String?, sourceApp: String) {
        guard db != nil else { return }
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
        sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
        if sqlite3_step(stmt) != SQLITE_DONE {
            logger.error("Failed to insert clipboard item")
        }

        NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: nil)

        // Throttle storage check to at most once per 60 seconds
        let now = Date().timeIntervalSince1970
        if now - lastStorageCheck > 60 {
            lastStorageCheck = now
            enforceMaxStorage()
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
        // Delete associated image files first
        var stmt: OpaquePointer?
        let selectSql = "SELECT image_path FROM clipboard_history WHERE id = ?"
        if sqlite3_prepare_v2(db, selectSql, -1, &stmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_ROW, let cStr = sqlite3_column_text(stmt, 0) {
                let path = String(cString: cStr)
                try? FileManager.default.removeItem(atPath: path)
                if let thumbPath = thumbnailPath(for: path) {
                    try? FileManager.default.removeItem(atPath: thumbPath)
                }
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
        }
    }

    func clearAll() {
        guard db != nil else { return }
        // Delete image files first, then database records
        if let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) {
            for file in files {
                try? FileManager.default.removeItem(atPath: (imagesDir as NSString).appendingPathComponent(file))
            }
        }
        sqlite3_exec(db, "DELETE FROM clipboard_history", nil, nil, nil)
        sqlite3_exec(db, "VACUUM", nil, nil, nil)
    }

    private func thumbnailPath(for path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        guard url.pathExtension.lowercased() == "jpg" else { return nil }
        let stem = url.deletingPathExtension().lastPathComponent
        let dir = url.deletingLastPathComponent().path
        return (dir as NSString).appendingPathComponent("\(stem)_thumb.jpg")
    }

    // MARK: - Cleanup

    func cleanupExpired() {
        guard db != nil else { return }
        let days = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
        let effectiveDays = days > 0 ? days : 30
        if effectiveDays >= 36500 { return } // "Forever" = ~100 years

        let cutoff = Date().timeIntervalSince1970 - Double(effectiveDays * 86400)

        // Delete expired records
        var stmt: OpaquePointer?
        let sql = "DELETE FROM clipboard_history WHERE is_pinned = 0 AND created_at < ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, cutoff)
        sqlite3_step(stmt)

        // Clean orphaned images
        cleanupOrphanedImages()
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
                    dbPaths.insert(String(cString: cStr))
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

    private func enforceMaxStorage() {
        let maxBytes: Int64 = 500 * 1024 * 1024 // 500 MB
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: imagesDir) else { return }

        // Collect only non-thumbnail jpg files with their sizes
        var totalSize: Int64 = 0
        var imageFiles: [(String, Int64)] = []
        for file in files where file.hasSuffix(".jpg") && !file.hasSuffix("_thumb.jpg") {
            let path = (imagesDir as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                totalSize += size
                imageFiles.append((file, size))
            }
        }
        guard totalSize > maxBytes else { return }

        // Batch-query all pinned image paths
        var pinnedPaths = Set<String>()
        var pinStmt: OpaquePointer?
        let pinSql = "SELECT image_path FROM clipboard_history WHERE is_pinned = 1 AND image_path IS NOT NULL"
        if sqlite3_prepare_v2(db, pinSql, -1, &pinStmt, nil) == SQLITE_OK {
            defer { sqlite3_finalize(pinStmt) }
            while sqlite3_step(pinStmt) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(pinStmt, 0) {
                    pinnedPaths.insert(String(cString: cStr))
                }
            }
        }

        // Sort by modification date, delete oldest first
        imageFiles.sort { a, b in
            let pathA = (imagesDir as NSString).appendingPathComponent(a.0)
            let pathB = (imagesDir as NSString).appendingPathComponent(b.0)
            let dateA = (try? FileManager.default.attributesOfItem(atPath: pathA))?[.modificationDate] as? Date ?? .distantPast
            let dateB = (try? FileManager.default.attributesOfItem(atPath: pathB))?[.modificationDate] as? Date ?? .distantPast
            return dateA < dateB
        }

        for (file, size) in imageFiles {
            guard totalSize > maxBytes else { break }
            let path = (imagesDir as NSString).appendingPathComponent(file)

            // Skip pinned items
            if pinnedPaths.contains(path) { continue }

            try? FileManager.default.removeItem(atPath: path)
            // Delete associated database record
            var delStmt: OpaquePointer?
            let delSql = "DELETE FROM clipboard_history WHERE image_path = ?"
            if sqlite3_prepare_v2(db, delSql, -1, &delStmt, nil) == SQLITE_OK {
                defer { sqlite3_finalize(delStmt) }
                sqlite3_bind_text(delStmt, 1, path, -1, SQLITE_TRANSIENT)
                sqlite3_step(delStmt)
            }
            // Delete thumbnail too
            if let thumbPath = thumbnailPath(for: path) {
                try? FileManager.default.removeItem(atPath: thumbPath)
            }
            totalSize -= size
        }
    }

    // MARK: - Helpers

    private func fetchLatest() -> ClipboardItem? {
        guard db != nil else { return nil }
        var stmt: OpaquePointer?
        let sql = "SELECT id, content, image_path, source_app, is_pinned, created_at FROM clipboard_history ORDER BY created_at DESC LIMIT 1"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return itemFromRow(stmt)
        }
        return nil
    }

    private func itemFromRow(_ stmt: OpaquePointer?) -> ClipboardItem {
        let id = sqlite3_column_int64(stmt, 0)
        let content = sqlite3_column_text(stmt, 1).map { String(cString: $0) }
        let imagePath = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
        let sourceApp = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? ""
        let isPinned = sqlite3_column_int(stmt, 4) != 0
        let createdAt = sqlite3_column_double(stmt, 5)
        return ClipboardItem(id: id, content: content, imagePath: imagePath,
                             sourceApp: sourceApp, isPinned: isPinned, createdAt: createdAt)
    }
}
