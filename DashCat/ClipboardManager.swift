import Cocoa
import ImageIO
import SQLite3
import UniformTypeIdentifiers
import os.log

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
private let filterTermsKey = "DashCatClipboardFilterTerms"

enum ClipboardError: Error, Equatable {
    case storage, image, imageMissing, imageUnreadable, itemMissing, notPinned, invalidName
    case fileCleanup, privacyCleanup, historyChanged

    var requiresStorageRetry: Bool {
        self == .storage || self == .fileCleanup || self == .privacyCleanup
    }

    var messageKey: String {
        switch self {
        case .storage: return "clipboardFailure"
        case .image: return "imageInvalid"
        case .imageMissing: return "imageMissing"
        case .imageUnreadable: return "imageUnreadable"
        case .itemMissing: return "itemMissing"
        case .notPinned: return "pinBeforeRename"
        case .invalidName: return "invalidClipName"
        case .fileCleanup: return "fileCleanupFailed"
        case .privacyCleanup: return "privacyCleanupFailed"
        case .historyChanged: return "loading"
        }
    }
}

struct ClipboardMutationResult {
    let committed: Bool
    let error: ClipboardError?
    var succeeded: Bool { error == nil }
}

extension NSNotification.Name {
    static let DashCatClipboardDidChange = NSNotification.Name("DashCatClipboardDidChange")
    static let DashCatClipboardFailed = NSNotification.Name("DashCatClipboardFailed")
}

struct ClipboardItem {
    let id: Int64
    let content: String?
    let imagePath: String?
    let sourceApp: String
    let isPinned: Bool
    let createdAt: TimeInterval
    var name: String? = nil
    var isImage: Bool { imagePath != nil }
}

struct ClipboardCursor {
    let isPinned: Bool
    let createdAt: TimeInterval
    let id: Int64
    init(_ item: ClipboardItem) { isPinned = item.isPinned; createdAt = item.createdAt; id = item.id }
}

struct ClipboardPage {
    let items: [ClipboardItem]
    let hasMore: Bool
    let revision: Int
}

final class ClipboardManager {
    static let shared = ClipboardManager()
    private var db: OpaquePointer?
    // Every database operation and image mutation runs on this queue.
    private let maintenanceQueue = DispatchQueue(label: "com.dashcat.app.clipboard-maintenance", qos: .utility)
    private let defaults: UserDefaults
    private let pasteboard: NSPasteboard
    private let sourceAppProvider: () -> String
    private var changeCount: Int
    private var pollTimer: Timer?
    private var cleanupTimer: Timer?
    private let imagesDir: String
    private let databaseURL: URL
    private var databaseReady = false
    private var historyRevision = 0
    private let logger = Logger(subsystem: "com.dashcat.app", category: "ClipboardManager")

    // Injectable locations keep regression checks away from personal clipboard history.
    init(directory: URL? = nil, defaults: UserDefaults = .standard, pasteboard: NSPasteboard = .general,
         sourceAppProvider: @escaping () -> String = { NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "" }) {
        self.defaults = defaults
        self.pasteboard = pasteboard
        self.sourceAppProvider = sourceAppProvider
        changeCount = pasteboard.changeCount
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DashCat", isDirectory: true)
        imagesDir = base.appendingPathComponent("Images", isDirectory: true).path
        databaseURL = base.appendingPathComponent("clipboard.db")
        do { try openDatabase(); cleanupExpired() }
        catch { reportFailure(error as? ClipboardError ?? .storage) }
    }

    private func openDatabase() throws {
        databaseReady = false
        if let db { sqlite3_close(db); self.db = nil }
        try FileManager.default.createDirectory(atPath: imagesDir, withIntermediateDirectories: true)
        guard sqlite3_open_v2(databaseURL.path, &db,
                              SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK else {
            throw ClipboardError.storage
        }
        sqlite3_busy_timeout(db, 2000)
        try execute("PRAGMA journal_mode=WAL")
        try execute("PRAGMA secure_delete=ON")
        try execute("""
            CREATE TABLE IF NOT EXISTS clipboard_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, image_path TEXT,
                source_app TEXT NOT NULL DEFAULT '', is_pinned INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL, name TEXT);
            CREATE INDEX IF NOT EXISTS idx_created_at ON clipboard_history(created_at);
            CREATE INDEX IF NOT EXISTS idx_history_order ON clipboard_history(is_pinned DESC, created_at DESC, id DESC);
            """)
        // CREATE TABLE does not upgrade existing installations.
        let columns = try prepare("PRAGMA table_info(clipboard_history)")
        var hasName = false
        var step = sqlite3_step(columns)
        while step == SQLITE_ROW {
            hasName = hasName || text(columns, 1) == "name"
            step = sqlite3_step(columns)
        }
        sqlite3_finalize(columns)
        guard step == SQLITE_DONE else { throw ClipboardError.storage }
        if !hasName { try execute("ALTER TABLE clipboard_history ADD COLUMN name TEXT") }
        guard sqlite3_create_function_v2(db, "unicode_contains", 2, SQLITE_UTF8 | SQLITE_DETERMINISTIC,
            nil, { context, _, args in
                guard let args, let a = sqlite3_value_text(args[0]), let b = sqlite3_value_text(args[1]) else {
                    sqlite3_result_int(context, 0); return
                }
                let text = String(decoding: UnsafeBufferPointer(start: a, count: Int(sqlite3_value_bytes(args[0]))), as: UTF8.self)
                let query = String(decoding: UnsafeBufferPointer(start: b, count: Int(sqlite3_value_bytes(args[1]))), as: UTF8.self)
                sqlite3_result_int(context, text.range(of: query, options: .caseInsensitive) == nil ? 0 : 1)
            }, nil, nil, nil) == SQLITE_OK else { throw ClipboardError.storage }
        databaseReady = true
    }

    deinit {
        pollTimer?.invalidate()
        cleanupTimer?.invalidate()
        if let db { sqlite3_close(db) }
    }

    func startPolling() {
        stopPolling()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.checkPasteboard() }
        pollTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        let cleanup = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in self?.cleanupExpired() }
        cleanupTimer = cleanup
        RunLoop.main.add(cleanup, forMode: .common)
        cleanupExpired() // Also runs after wake, when timers may have missed an expiry.
    }

    func stopPolling() {
        pollTimer?.invalidate(); pollTimer = nil
        cleanupTimer?.invalidate(); cleanupTimer = nil
    }

    func syncChangeCount() { changeCount = pasteboard.changeCount }

    var isPaused: Bool { defaults.bool(forKey: "DashCatClipboardPaused") }
    func setPaused(_ paused: Bool) {
        defaults.set(paused, forKey: "DashCatClipboardPaused")
        syncChangeCount() // Never import content copied while capture was paused.
        DispatchQueue.main.async { NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: self) }
    }
    func excludedApps() -> [String] { defaults.stringArray(forKey: "DashCatClipboardExcludedApps") ?? [] }
    func setAppExcluded(_ bundleID: String, excluded: Bool) {
        var apps = Set(excludedApps())
        if excluded { apps.insert(bundleID) } else { apps.remove(bundleID) }
        defaults.set(apps.sorted(), forKey: "DashCatClipboardExcludedApps")
        syncChangeCount()
    }

    static func shouldIgnore(types: [NSPasteboard.PasteboardType]) -> Bool {
        let ignored: Set<String> = ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType",
            "org.nspasteboard.AutoGeneratedType", "com.agilebits.onepassword",
            "de.petermaurer.TransientPasteboardType", "com.typeit4me.clipping", "Pasteboard generator type"]
        return types.contains { ignored.contains($0.rawValue) }
    }

    func checkPasteboard() {
        let count = pasteboard.changeCount
        guard count != changeCount else { return }
        changeCount = count
        let source = sourceAppProvider()
        guard !isPaused, !excludedApps().contains(source) else { return }
        guard !Self.shouldIgnore(types: pasteboard.types ?? []) else { return }
        let string = pasteboard.string(forType: .string)
        // Avoid materializing large image representations when disabled or when text wins.
        let data = defaults.bool(forKey: "DashCatSaveImages") && (string?.isEmpty ?? true)
            ? (pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)) : nil
        guard pasteboard.changeCount == count else { return }
        maintenanceQueue.async {
            guard !self.isPaused, !self.excludedApps().contains(source) else { return }
            let before = self.totalChanges
            defer { if self.totalChanges != before { self.notifyChange() } }
            do {
                guard self.databaseReady else { throw ClipboardError.storage }
                if let string, !string.isEmpty {
                    let terms = self.savedFilterTerms()
                    guard !terms.contains(where: { string.range(of: $0, options: .caseInsensitive) != nil }) else { return }
                    // Preserve the original text, including line endings and embedded NULs.
                    guard try self.latestText() != string else { return }
                    try self.insert(content: string, imagePath: nil, sourceApp: source)
                } else if let data {
                    let name = try self.saveImage(data)
                    do { try self.insert(content: nil, imagePath: name, sourceApp: source) }
                    catch { self.removeImage(name); throw error }
                    try self.enforceMaxStorage()
                } else { return }
            } catch { self.reportFailure(error as? ClipboardError ?? .storage, committed: self.totalChanges != before) }
        }
    }

    func savedFilterTerms() -> [String] { defaults.stringArray(forKey: filterTermsKey) ?? [] }
    func setFilterTerms(_ terms: [String]) {
        var seen = Set<String>()
        let normalized = terms.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
        defaults.set(normalized, forKey: filterTermsKey)
    }

    func load(query: String = "", limit: Int = 201, offset: Int = 0,
              completion: @escaping (Result<[ClipboardItem], Error>) -> Void) {
        maintenanceQueue.async {
            let result = Result { try self.fetch(query: query, limit: limit, offset: offset) }
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func fetch(query: String, limit: Int, offset: Int) throws -> [ClipboardItem] {
        guard databaseReady else { throw ClipboardError.storage }
        let condition = query.isEmpty ? "" : "WHERE (unicode_contains(content, ?) OR unicode_contains(name, ?))"
        let stmt = try prepare("SELECT id,content,image_path,source_app,is_pinned,created_at,name FROM clipboard_history \(condition) ORDER BY is_pinned DESC,created_at DESC,id DESC LIMIT ? OFFSET ?")
        defer { sqlite3_finalize(stmt) }
        var index: Int32 = 1
        if !query.isEmpty { try bind(query, to: stmt, at: 1); try bind(query, to: stmt, at: 2); index = 3 }
        sqlite3_bind_int64(stmt, index, Int64(max(1, limit)))
        sqlite3_bind_int64(stmt, index + 1, Int64(max(0, offset)))
        var items = [ClipboardItem]()
        while true {
            switch sqlite3_step(stmt) {
            case SQLITE_ROW:
                items.append(item(from: stmt))
            case SQLITE_DONE: return items
            default: throw ClipboardError.storage
            }
        }
    }

    // List pages carry only bounded summaries; copying and previewing load by id.
    func loadPage(query: String = "", after cursor: ClipboardCursor? = nil, revision: Int? = nil,
                  limit: Int = 200, completion: @escaping (Result<ClipboardPage, Error>) -> Void) {
        maintenanceQueue.async {
            let result = Result {
                guard self.databaseReady else { throw ClipboardError.storage }
                if let revision, revision != self.historyRevision { throw ClipboardError.historyChanged }
                var conditions = [String]()
                if !query.isEmpty { conditions.append("(unicode_contains(content, ?) OR unicode_contains(name, ?))") }
                if cursor != nil { conditions.append("(is_pinned,created_at,id) < (?,?,?)") }
                let condition = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
                let stmt = try self.prepare("SELECT id,substr(content,1,240),image_path,source_app,is_pinned,created_at,name FROM clipboard_history \(condition) ORDER BY is_pinned DESC,created_at DESC,id DESC LIMIT ?")
                defer { sqlite3_finalize(stmt) }
                var index: Int32 = 1
                if !query.isEmpty { try self.bind(query, to: stmt, at: 1); try self.bind(query, to: stmt, at: 2); index = 3 }
                if let cursor {
                    sqlite3_bind_int(stmt, index, cursor.isPinned ? 1 : 0)
                    sqlite3_bind_double(stmt, index + 1, cursor.createdAt)
                    sqlite3_bind_int64(stmt, index + 2, cursor.id)
                    index += 3
                }
                let pageSize = min(200, max(1, limit))
                sqlite3_bind_int(stmt, index, Int32(pageSize + 1))
                var items = [ClipboardItem]()
                while true {
                    let step = sqlite3_step(stmt)
                    if step == SQLITE_DONE { break }
                    guard step == SQLITE_ROW else { throw ClipboardError.storage }
                    items.append(self.item(from: stmt))
                }
                return ClipboardPage(items: Array(items.prefix(pageSize)), hasMore: items.count > pageSize, revision: self.historyRevision)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func loadItem(id: Int64, completion: @escaping (Result<ClipboardItem, Error>) -> Void) {
        maintenanceQueue.async {
            let result = Result {
                guard self.databaseReady else { throw ClipboardError.storage }
                let stmt = try self.prepare("SELECT id,content,image_path,source_app,is_pinned,created_at,name FROM clipboard_history WHERE id=?")
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_int64(stmt, 1, id)
                let step = sqlite3_step(stmt)
                guard step == SQLITE_ROW else { throw step == SQLITE_DONE ? ClipboardError.itemMissing : ClipboardError.storage }
                return self.item(from: stmt)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    private func item(from stmt: OpaquePointer) -> ClipboardItem {
        ClipboardItem(id: sqlite3_column_int64(stmt, 0), content: text(stmt, 1),
            imagePath: text(stmt, 2).map(fullPath), sourceApp: text(stmt, 3) ?? "",
            isPinned: sqlite3_column_int(stmt, 4) != 0, createdAt: sqlite3_column_double(stmt, 5), name: text(stmt, 6))
    }

    func renameItem(id: Int64, name: String?, completion: @escaping (ClipboardMutationResult) -> Void) {
        mutate(completion: completion, cleanup: { try self.truncateWAL() }) {
            let value = name?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (value?.count ?? 0) <= 200, value?.contains(where: { $0.isNewline }) != true else { throw ClipboardError.invalidName }
            let stmt = try self.prepare("UPDATE clipboard_history SET name=? WHERE id=? AND is_pinned=1")
            defer { sqlite3_finalize(stmt) }
            try self.bind(value?.isEmpty == true ? nil : value, to: stmt, at: 1)
            sqlite3_bind_int64(stmt, 2, id)
            try self.finish(stmt)
            guard sqlite3_changes(self.db) > 0 else { throw ClipboardError.notPinned }
        }
    }

    func countExpiring(days: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        maintenanceQueue.async {
            let result = Result {
                guard self.databaseReady else { throw ClipboardError.storage }
                if days == 36500 { return 0 }
                guard (1...365).contains(days) else { throw ClipboardError.storage }
                let stmt = try self.prepare("SELECT count(*) FROM clipboard_history WHERE is_pinned=0 AND created_at < ?")
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970 - Double(days) * 86400)
                guard sqlite3_step(stmt) == SQLITE_ROW else { throw ClipboardError.storage }
                return Int(sqlite3_column_int64(stmt, 0))
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func retryStorage(completion: @escaping (ClipboardMutationResult) -> Void) {
        mutate(completion: { result in
            if result.succeeded {
                NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: self, userInfo: ["storageRecovered": true])
            }
            completion(result)
        }, cleanup: { try self.maintainImages() }) {
            if !self.databaseReady { try self.openDatabase() }
            else { try FileManager.default.createDirectory(atPath: self.imagesDir, withIntermediateDirectories: true) }
        }
    }

    func togglePin(id: Int64, completion: @escaping (ClipboardMutationResult) -> Void) {
        mutate(completion: completion) {
            let stmt = try self.prepare("UPDATE clipboard_history SET is_pinned = 1-is_pinned WHERE id = ?")
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int64(stmt, 1, id)
            try self.finish(stmt)
            guard sqlite3_changes(self.db) > 0 else { throw ClipboardError.itemMissing }
        }
    }

    func deleteItem(id: Int64, completion: @escaping (ClipboardMutationResult) -> Void) {
        mutate(completion: completion, cleanup: { try self.maintainImages() }) {
            let stmt = try self.prepare("DELETE FROM clipboard_history WHERE id = ?")
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_int64(stmt, 1, id)
            try self.finish(stmt)
        }
    }

    func clearAll(includePinned: Bool = false, completion: ((ClipboardMutationResult) -> Void)? = nil) {
        mutate(completion: completion, cleanup: { try self.maintainImages(vacuum: true) }) {
            try self.execute(includePinned ? "DELETE FROM clipboard_history" : "DELETE FROM clipboard_history WHERE is_pinned = 0")
        }
    }

    func cleanupExpired(completion: ((ClipboardMutationResult) -> Void)? = nil) {
        mutate(completion: completion, cleanup: { try self.maintainImages() }) {
            guard self.databaseReady else { throw ClipboardError.storage }
            let stored = self.defaults.integer(forKey: "DashCatHistoryDays")
            if stored != 36500 {
                let days = (1...365).contains(stored) ? stored : 30
                let stmt = try self.prepare("DELETE FROM clipboard_history WHERE is_pinned = 0 AND created_at < ?")
                defer { sqlite3_finalize(stmt) }
                sqlite3_bind_double(stmt, 1, Date().timeIntervalSince1970 - Double(days) * 86400)
                try self.finish(stmt)
            }
        }
    }

    private func mutate(completion: ((ClipboardMutationResult) -> Void)?, cleanup: (() throws -> Void)? = nil,
                        operation: @escaping () throws -> Void) {
        maintenanceQueue.async {
            let before = self.totalChanges
            var committed = false
            var failure: ClipboardError?
            do { try operation(); committed = true; try cleanup?() }
            catch { failure = error as? ClipboardError ?? .storage }
            if committed || self.totalChanges != before { self.notifyChange() }
            if let failure { self.reportFailure(failure, committed: committed || self.totalChanges != before, alert: completion == nil) }
            let result = ClipboardMutationResult(committed: committed, error: failure)
            DispatchQueue.main.async { completion?(result) }
        }
    }

    private var totalChanges: Int64 { db.map { sqlite3_total_changes64($0) } ?? 0 }

    private func truncateWAL() throws {
        guard databaseReady, sqlite3_wal_checkpoint_v2(db, nil, SQLITE_CHECKPOINT_TRUNCATE, nil, nil) == SQLITE_OK else {
            throw ClipboardError.privacyCleanup
        }
    }

    private func maintainImages(vacuum: Bool = false) throws {
        var failure: ClipboardError?
        do { try cleanupOrphanedImages(); try enforceMaxStorage() }
        catch { failure = error as? ClipboardError ?? .fileCleanup }
        if vacuum {
            do { try execute("VACUUM") } catch { failure = failure ?? .storage }
        }
        // Also scrub WAL when ancillary cleanup fails after a successful DELETE.
        do { try truncateWAL() } catch { failure = .privacyCleanup }
        if let failure { throw failure }
    }

    // A failed/incomplete SELECT must never become permission to delete files.
    private func knownImages() throws -> Set<String> {
        guard databaseReady else { throw ClipboardError.storage }
        let stmt = try prepare("SELECT image_path FROM clipboard_history WHERE image_path IS NOT NULL")
        defer { sqlite3_finalize(stmt) }
        var paths = Set<String>()
        while true {
            switch sqlite3_step(stmt) {
            case SQLITE_ROW:
                if let path = text(stmt, 0) { paths.insert(fullPath(path)) }
            case SQLITE_DONE: return paths
            default: throw ClipboardError.storage
            }
        }
    }

    private func cleanupOrphanedImages() throws {
        let paths = try knownImages()
        let kept = paths.union(paths.compactMap { thumbnailPath(for: $0) })
        for file in try FileManager.default.contentsOfDirectory(atPath: imagesDir) {
            let path = fullPath(file)
            if !kept.contains(path) { try FileManager.default.removeItem(atPath: path) }
        }
    }

    private func enforceMaxStorage() throws {
        let files = try FileManager.default.contentsOfDirectory(atPath: imagesDir)
        var total: Int64 = 0
        for file in files {
            let attrs = try FileManager.default.attributesOfItem(atPath: fullPath(file))
            total += (attrs[.size] as? NSNumber)?.int64Value ?? 0
        }
        let maximum: Int64 = 500 * 1024 * 1024
        guard total > maximum else { return }
        let stmt = try prepare("SELECT id,image_path FROM clipboard_history WHERE is_pinned=0 AND image_path IS NOT NULL ORDER BY created_at,id")
        defer { sqlite3_finalize(stmt) }
        var candidates = [(Int64, String)]()
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw ClipboardError.storage }
            if let path = text(stmt, 1) { candidates.append((sqlite3_column_int64(stmt, 0), path)) }
        }
        let before = totalChanges
        do {
            for (id, name) in candidates where total > maximum {
                let deletion = try prepare("DELETE FROM clipboard_history WHERE id=? AND is_pinned=0")
                sqlite3_bind_int64(deletion, 1, id)
                let result = sqlite3_step(deletion)
                let changed = sqlite3_changes(db) > 0
                sqlite3_finalize(deletion)
                guard result == SQLITE_DONE else { throw ClipboardError.storage }
                guard changed else { continue }
                let path = fullPath(name)
                for file in [path] + (thumbnailPath(for: path).map { [$0] } ?? []) {
                    guard FileManager.default.fileExists(atPath: file) else { continue }
                    let attrs = try FileManager.default.attributesOfItem(atPath: file)
                    try FileManager.default.removeItem(atPath: file)
                    total -= (attrs[.size] as? NSNumber)?.int64Value ?? 0
                }
            }
        } catch {
            if totalChanges != before { try? truncateWAL() }
            throw error
        }
        if totalChanges != before { try truncateWAL() }
        // Pinned data is deliberately retained even if it alone exceeds the budget.
    }

    private func saveImage(_ data: Data) throws -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) as String?, CGImageSourceGetStatus(source) == .statusComplete,
              [UTType.png.identifier, UTType.tiff.identifier].contains(type) else { throw ClipboardError.image }
        let thumb = try Self.validatedThumbnail(data)
        let name = UUID().uuidString + (type == UTType.png.identifier ? ".png" : ".tiff")
        let path = fullPath(name)
        try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        if let thumbPath = thumbnailPath(for: path),
           let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: thumbPath) as CFURL, UTType.jpeg.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, thumb, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
            if !CGImageDestinationFinalize(destination) { try? FileManager.default.removeItem(atPath: thumbPath) }
        }
        return name
    }

    static func validatedThumbnail(_ data: Data, maxSize: Int = 80) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0, CGImageSourceGetStatus(source) == .statusComplete else { throw ClipboardError.image }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize, kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              image.dataProvider?.data != nil, CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else { throw ClipboardError.image }
        return image
    }

    static func readImage(at path: String) throws -> Data {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            _ = try validatedThumbnail(data)
            return data
        } catch let error as ClipboardError { throw error }
        catch {
            let value = error as NSError
            if value.domain == NSCocoaErrorDomain && [NSFileNoSuchFileError, NSFileReadNoSuchFileError].contains(value.code) { throw ClipboardError.imageMissing }
            throw ClipboardError.imageUnreadable
        }
    }

    func thumbnailPath(for path: String) -> String? {
        let url = URL(fileURLWithPath: path)
        return url.deletingLastPathComponent().appendingPathComponent(url.deletingPathExtension().lastPathComponent + "_thumb.jpg").path
    }

    private func removeImage(_ name: String) {
        let path = fullPath(name)
        try? FileManager.default.removeItem(atPath: path)
        if let thumb = thumbnailPath(for: path) { try? FileManager.default.removeItem(atPath: thumb) }
    }
    private func fullPath(_ name: String) -> String { (imagesDir as NSString).appendingPathComponent((name as NSString).lastPathComponent) }
    private func insert(content: String?, imagePath: String?, sourceApp: String) throws {
        let stmt = try prepare("INSERT INTO clipboard_history(content,image_path,source_app,created_at) VALUES(?,?,?,?)")
        defer { sqlite3_finalize(stmt) }
        try bind(content, to: stmt, at: 1); try bind(imagePath, to: stmt, at: 2); try bind(sourceApp, to: stmt, at: 3)
        sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
        try finish(stmt)
    }
    private func latestText() throws -> String? {
        let stmt = try prepare("SELECT content FROM clipboard_history ORDER BY created_at DESC,id DESC LIMIT 1")
        defer { sqlite3_finalize(stmt) }
        switch sqlite3_step(stmt) {
        case SQLITE_ROW: return text(stmt, 0)
        case SQLITE_DONE: return nil
        default: throw ClipboardError.storage
        }
    }
    private func prepare(_ sql: String) throws -> OpaquePointer {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { throw ClipboardError.storage }
        return stmt
    }
    private func execute(_ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw ClipboardError.storage }
    }
    private func finish(_ stmt: OpaquePointer) throws {
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw ClipboardError.storage }
    }
    private func bind(_ value: String?, to stmt: OpaquePointer, at index: Int32) throws {
        let result: Int32
        if let value { result = sqlite3_bind_text64(stmt, index, value, UInt64(value.utf8.count), SQLITE_TRANSIENT, UInt8(SQLITE_UTF8)) }
        else { result = sqlite3_bind_null(stmt, index) }
        guard result == SQLITE_OK else { throw ClipboardError.storage }
    }
    private func text(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        guard let ptr = sqlite3_column_text(stmt, index) else { return nil }
        return String(decoding: UnsafeBufferPointer(start: ptr, count: Int(sqlite3_column_bytes(stmt, index))), as: UTF8.self)
    }
    private func notifyChange() {
        historyRevision += 1
        DispatchQueue.main.async { NotificationCenter.default.post(name: .DashCatClipboardDidChange, object: self) }
    }
    private func reportFailure(_ error: ClipboardError, committed: Bool = false, alert: Bool = true) {
        logger.error("Clipboard operation failed; content omitted for privacy")
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .DashCatClipboardFailed, object: self,
                userInfo: ["error": error, "committed": committed, "alert": alert])
        }
    }
}
