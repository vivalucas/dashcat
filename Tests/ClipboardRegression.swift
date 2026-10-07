import Cocoa
import ImageIO
import SQLite3
import UniformTypeIdentifiers

@main
struct ClipboardRegression {
    static func require(_ condition: Bool, _ message: String) {
        guard condition else { fatalError(message) }
    }
    static func awaitResult<T>(_ operation: (@escaping (T) -> Void) -> Void) -> T {
        var value: T?
        operation { value = $0 }
        let deadline = Date().addingTimeInterval(10)
        while value == nil && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        guard let value else { fatalError("Timed out waiting for background operation") }
        return value
    }
    static func load(_ manager: ClipboardManager, query: String = "", limit: Int = 1000, offset: Int = 0) throws -> [ClipboardItem] {
        let result: Result<[ClipboardItem], Error> = awaitResult { manager.load(query: query, limit: limit, offset: offset, completion: $0) }
        return try result.get()
    }
    static func page(_ manager: ClipboardManager, after: ClipboardItem? = nil, revision: Int? = nil) throws -> ClipboardPage {
        let result: Result<ClipboardPage, Error> = awaitResult {
            manager.loadPage(after: after.map(ClipboardCursor.init), revision: revision, completion: $0)
        }
        return try result.get()
    }
    static func main() throws {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("DashCat-regression-\(UUID())")
        let suite = "DashCat.regression.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        let pb = NSPasteboard.withUniqueName()
        defer {
            pb.releaseGlobally()
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        defaults.set(36500, forKey: "DashCatHistoryDays")
        // Existing installations have no name column. Upgrade without losing their records.
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var legacyDB: OpaquePointer?
        require(sqlite3_open(directory.appendingPathComponent("clipboard.db").path, &legacyDB) == SQLITE_OK, "Legacy DB failed")
        require(sqlite3_exec(legacyDB, "CREATE TABLE clipboard_history (id INTEGER PRIMARY KEY AUTOINCREMENT,content TEXT,image_path TEXT,source_app TEXT NOT NULL DEFAULT '',is_pinned INTEGER NOT NULL DEFAULT 0,created_at REAL NOT NULL); INSERT INTO clipboard_history(content,is_pinned,created_at) VALUES('legacy original',1,1)", nil, nil, nil) == SQLITE_OK, "Legacy schema fixture failed")
        sqlite3_close(legacyDB)
        var sourceApp = "com.dashcat.regression.source"
        let manager = ClipboardManager(directory: directory, defaults: defaults, pasteboard: pb, sourceAppProvider: { sourceApp })
        let legacy = try load(manager).first!
        require(legacy.content == "legacy original" && legacy.name == nil && legacy.isPinned, "Migration changed old content/pin")
        let renamedLegacy: ClipboardMutationResult = awaitResult { manager.renameItem(id: legacy.id, name: "Legacy label", completion: $0) }
        require(try renamedLegacy.succeeded && (load(manager).first?.name) == "Legacy label", "Old schema was not upgraded")
        let initialClear: ClipboardMutationResult = awaitResult { manager.clearAll(includePinned: true, completion: $0) }
        require(initialClear.succeeded, "Fixture reset failed")
        func capture(_ value: String, type: String? = nil) throws {
            pb.clearContents()
            pb.setString(value, forType: .string)
            if let type { pb.setData(Data(), forType: .init(type)) }
            manager.checkPasteboard()
            _ = try load(manager)
        }
        manager.setPaused(true)
        try capture("paused synthetic content")
        manager.setPaused(false)
        manager.checkPasteboard()
        require(try load(manager).isEmpty, "Pause/resume imported skipped clipboard")
        manager.setAppExcluded(sourceApp, excluded: true)
        try capture("excluded synthetic content")
        manager.setAppExcluded(sourceApp, excluded: false)
        manager.checkPasteboard()
        require(try load(manager).isEmpty, "Exclusion removal imported skipped clipboard")
        sourceApp = "com.dashcat.regression.other"
        print("PASS: old-schema migration, pause/resume and excluded applications")
        let original = String(repeating: "a", count: 10000) + "TAIL\r\n\0结束"
        try capture(original)
        require(try load(manager).first?.content == original, "Long text/line endings/NUL lost")
        try capture(String(repeating: "a", count: 10000) + "DIFFERENT")
        require(try load(manager).count == 2, "Distinct suffix treated as duplicate")
        let textID = try load(manager).first(where: { $0.content == original })!.id
        let textPin: ClipboardMutationResult = awaitResult { manager.togglePin(id: textID, completion: $0) }
        let rename: ClipboardMutationResult = awaitResult { manager.renameItem(id: textID, name: "  常用 École  ", completion: $0) }
        require(textPin.succeeded && rename.succeeded, "Pinned text rename failed")
        require(try load(manager, query: "常用 école").first?.name == "常用 École", "Name search/trim failed")
        require(try load(manager, query: "TAIL").first?.content == original, "Renaming changed original/search")
        let summary = try page(manager).items.first!
        require((summary.content?.count ?? 0) <= 240 && summary.name == "常用 École", "List loads full text or loses name")
        let namedPanel = ClipboardPanel(manager: manager, pasteboard: pb)
        _ = try load(manager)
        let namedSearch = namedPanel.contentView!.subviews.compactMap { $0 as? NSSearchField }.first!
        let namedTable = namedPanel.contentView!.subviews.compactMap { ($0 as? NSScrollView)?.documentView as? NSTableView }.first!
        let cell = namedPanel.tableView(namedTable, viewFor: namedTable.tableColumns[0], row: 0)!
        require((cell.viewWithTag(2) as? NSTextField)?.stringValue == "常用 École", "Alias is not the visible row name")
        require(cell.viewWithTag(3) is NSImageView && !cell.viewWithTag(3)!.isHidden, "Pin marker is not a static image")
        let footer = namedPanel.contentView!.subviews.compactMap { $0 as? NSStackView }.first!
        require(footer.arrangedSubviews.allSatisfy { $0.isHidden }, "Simple list still contains a permanent footer")
        let pinnedMenu = namedPanel.contextMenu(forRow: 0)!
        require(pinnedMenu.items.contains { $0.action == NSSelectorFromString("renameItem:") }, "Pinned rename menu is missing")
        require(!namedPanel.contextMenu(forRow: 1)!.items.contains { $0.action == NSSelectorFromString("renameItem:") }, "Unpinned rename menu is visible")
        let selected: ClipboardItem = awaitResult { done in
            namedPanel.onSelect = done
            _ = namedPanel.control(namedSearch, textView: NSTextView(), doCommandBy: #selector(NSResponder.insertNewline(_:)))
        }
        require(selected.content == original && pb.string(forType: .string) == original, "Named row copied summary or name instead of complete original")
        let invalid: ClipboardMutationResult = awaitResult { manager.renameItem(id: textID, name: "bad\nname", completion: $0) }
        require(!invalid.committed && invalid.error == .invalidName, "Invalid name changed storage")
        let tooLong: ClipboardMutationResult = awaitResult { manager.renameItem(id: textID, name: String(repeating: "a", count: 201), completion: $0) }
        require(tooLong.error == .invalidName, "Oversized name accepted")
        let textUnpin: ClipboardMutationResult = awaitResult { manager.togglePin(id: textID, completion: $0) }
        let nonPinned: ClipboardMutationResult = awaitResult { manager.renameItem(id: textID, name: "wrong", completion: $0) }
        require(textUnpin.succeeded && nonPinned.error == .notPinned, "Unpinned row accepts rename")
        require(try load(manager, query: "常用").first?.name == "常用 École", "Unpin lost saved name")
        let rePin: ClipboardMutationResult = awaitResult { manager.togglePin(id: textID, completion: $0) }
        let reset: ClipboardMutationResult = awaitResult { manager.renameItem(id: textID, name: "   ", completion: $0) }
        let restoreUnpin: ClipboardMutationResult = awaitResult { manager.togglePin(id: textID, completion: $0) }
        require(rePin.succeeded && reset.succeeded && restoreUnpin.succeeded, "Name reset failed")
        require(try load(manager, query: "TAIL").first?.name == nil, "Blank name did not restore default display")
        print("PASS: pinned names, original-content copying, summary bounds, pin image and name validation")
        for type in ["org.nspasteboard.ConcealedType", "org.nspasteboard.TransientType", "org.nspasteboard.AutoGeneratedType", "com.agilebits.onepassword"] {
            try capture("synthetic-secret", type: type)
        }
        require(try load(manager).count == 2, "Confidential content captured")
        manager.setFilterTerms(["Secret", "secret", " "])
        try capture("A SECRET example")
        require(try load(manager).count == 2, "Filter terms not applied")
        manager.setFilterTerms([])
        try capture("École ПРИВЕТ %_\\")
        for query in ["école", "привет", "%_\\"] { require(try load(manager, query: query).count == 1, "Unicode/literal search failed") }
        require(try load(manager, query: "nonexistent").isEmpty, "False search result")
        print("PASS: complete text, deduplication, sensitive types, filters, Unicode and literal search")

        let context = CGContext(data: nil, width: 1600, height: 900, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 0.5))
        context.fill(CGRect(x: 0, y: 0, width: 1600, height: 900))
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, context.makeImage()!, nil)
        require(CGImageDestinationFinalize(destination), "PNG fixture failed")
        defaults.set(true, forKey: "DashCatSaveImages")
        pb.clearContents(); pb.setData(data as Data, forType: .png); manager.checkPasteboard()
        let image = try load(manager).first!
        let path = image.imagePath!
        require(try Data(contentsOf: URL(fileURLWithPath: path)) == data as Data, "Original image bytes changed")
        require(FileManager.default.fileExists(atPath: manager.thumbnailPath(for: path)!), "Thumbnail missing")
        let originalSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)!
        let decoded = CGImageSourceCreateImageAtIndex(originalSource, 0, nil)!
        require(decoded.width == 1600 && decoded.height == 900, "Original resolution lost")
        let payload = try ClipboardPanel.imagePayload(image) as! NSPasteboardItem
        require(payload.data(forType: .png) == data as Data, "Image copy did not preserve original bytes")
        // Remove IDAT chunks: ImageIO reports complete/count=1, but no pixels can be decoded.
        let png = data as Data
        var malformed = Data(png.prefix(8))
        var position = 8
        while position + 12 <= png.count {
            let size = png[position..<position+4].reduce(0) { ($0 << 8) | Int($1) }
            let end = position + size + 12
            require(end <= png.count, "PNG chunk fixture invalid")
            if String(decoding: png[position+4..<position+8], as: UTF8.self) != "IDAT" { malformed.append(png[position..<end]) }
            position = end
        }
        let brokenSource = CGImageSourceCreateWithData(malformed as CFData, nil)!
        require(CGImageSourceGetStatus(brokenSource) == .statusComplete && CGImageSourceGetCount(brokenSource) == 1, "Corrupt-image fixture does not reach old guard")
        try malformed.write(to: URL(fileURLWithPath: path))
        pb.clearContents(); pb.setString("preserve this synthetic clipboard", forType: .string)
        do { _ = try ClipboardPanel.imagePayload(image); fatalError("Undecodable image accepted") }
        catch { require(error as? ClipboardError == .image, "Wrong corrupt-image error") }
        require(pb.string(forType: .string) == "preserve this synthetic clipboard", "Image validation changed clipboard")
        try png.write(to: URL(fileURLWithPath: path))
        try FileManager.default.moveItem(atPath: path, toPath: path + ".moved")
        do { _ = try ClipboardPanel.imagePayload(image); fatalError("Missing image accepted") }
        catch { require(error as? ClipboardError == .imageMissing, "Missing image is not distinguished from corruption") }
        try FileManager.default.moveItem(atPath: path + ".moved", toPath: path)
        let pin: ClipboardMutationResult = awaitResult { manager.togglePin(id: image.id, completion: $0) }
        require(pin.succeeded, "Pin failed")
        print("PASS: exact PNG bytes, original dimensions, separate thumbnail and pin")

        var db: OpaquePointer?
        require(sqlite3_open(directory.appendingPathComponent("clipboard.db").path, &db) == SQLITE_OK, "Fixture DB failed")
        defer { sqlite3_close(db) }
        func sql(_ text: String) {
            require(sqlite3_exec(db, text, nil, nil, nil) == SQLITE_OK, "Fixture SQL failed: \(text)")
        }
        sql("UPDATE clipboard_history SET created_at=1")
        let expiring: Result<Int, Error> = awaitResult { manager.countExpiring(days: 1, completion: $0) }
        let forever: Result<Int, Error> = awaitResult { manager.countExpiring(days: 36500, completion: $0) }
        require(try expiring.get() == 3 && forever.get() == 0 && load(manager).count == 4, "Retention preview mutates history or counts pins")
        defaults.set(1, forKey: "DashCatHistoryDays")
        let cleaned: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(try cleaned.succeeded && load(manager).count == 1, "Expiry did not preserve only pinned item")
        require(FileManager.default.fileExists(atPath: path), "Pinned image removed")
        sql("WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<201) INSERT INTO clipboard_history(content,created_at) SELECT 'fixture-'||x,2000000000+x FROM n")
        let page1 = try load(manager, limit: 200)
        let page2 = try load(manager, limit: 200, offset: 200)
        require(page1.count == 200 && page2.count == 2, "Pagination lost records")
        require(Set((page1 + page2).map(\.id)).count == 202, "Pagination duplicated records")
        let cursorPage1 = try page(manager)
        let cursorPage2 = try page(manager, after: cursorPage1.items.last, revision: cursorPage1.revision)
        require(cursorPage1.items.count == 200 && cursorPage1.hasMore && cursorPage2.items.count == 2 && !cursorPage2.hasMore, "Cursor page boundary failed")
        require(Set((cursorPage1.items + cursorPage2.items).map(\.id)).count == 202, "Cursor duplicated or skipped records")
        let changedPin: ClipboardMutationResult = awaitResult { manager.togglePin(id: cursorPage1.items[1].id, completion: $0) }
        let stale: Result<ClipboardPage, Error> = awaitResult { manager.loadPage(after: ClipboardCursor(cursorPage1.items.last!), revision: cursorPage1.revision, completion: $0) }
        require(changedPin.succeeded, "Cursor mutation fixture failed")
        switch stale { case .failure(let error): require(error as? ClipboardError == .historyChanged, "Wrong cursor invalidation error")
        case .success: fatalError("Stale cursor accepted") }
        let restorePin: ClipboardMutationResult = awaitResult { manager.togglePin(id: cursorPage1.items[1].id, completion: $0) }
        require(restorePin.succeeded, "Cursor fixture restore failed")
        let cleared: ClipboardMutationResult = awaitResult { manager.clearAll(completion: $0) }
        require(try cleared.succeeded && load(manager).count == 1, "Clear did not preserve pin")
        print("PASS: expiry, pinned preservation, pagination and scoped clear")

        // Legacy absolute paths resolve inside the current Images directory.
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        sql("UPDATE clipboard_history SET image_path='/legacy/home/Images/\(fileName)'")
        require(try load(manager).first?.imagePath == path, "Legacy path did not resolve")
        let orphan = directory.appendingPathComponent("Images/orphan_thumb.jpg")
        try Data([1, 2, 3]).write(to: orphan)
        let orphanCleaned: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(orphanCleaned.succeeded && !FileManager.default.fileExists(atPath: orphan.path), "Orphan thumbnail retained")

        // Sparse fixture checks the real 500 MB accounting without allocating 500 MB of RAM.
        let sparse = directory.appendingPathComponent("Images/pinned-large.tiff")
        require(FileManager.default.createFile(atPath: sparse.path, contents: Data()), "Sparse fixture failed")
        let handle = try FileHandle(forWritingTo: sparse)
        try handle.truncate(atOffset: 501 * 1024 * 1024)
        try handle.close()
        sql("INSERT INTO clipboard_history(image_path,is_pinned,created_at) VALUES('pinned-large.tiff',1,2000000000)")
        let largeID = sqlite3_last_insert_rowid(db)
        let overBudget: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(overBudget.succeeded && FileManager.default.fileExists(atPath: sparse.path), "Budget removed a pinned image")
        let unpinned: ClipboardMutationResult = awaitResult { manager.togglePin(id: largeID, completion: $0) }
        let reduced: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(unpinned.succeeded && reduced.succeeded && !FileManager.default.fileExists(atPath: sparse.path), "Budget failed to evict unpinned TIFF")
        require(FileManager.default.fileExists(atPath: path), "Budget removed another pinned original")
        print("PASS: legacy paths, orphan thumbnails, 500 MB budget and pinned overflow")

        // Synthetic large-history query: the main run loop must keep making progress.
        sql("WITH RECURSIVE n(x) AS (VALUES(1) UNION ALL SELECT x+1 FROM n WHERE x<50000) INSERT INTO clipboard_history(content,created_at) SELECT 'bulk-history-'||x,2000000000+x FROM n")
        var ticks = 0
        let heartbeat = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { _ in ticks += 1 }
        let started = Date()
        let matches = try load(manager, query: "bulk-history-49999")
        heartbeat.invalidate()
        require(matches.count == 1 && ticks > 0, "Large search blocked the main run loop or lost result")
        print("PASS: 50,000-row search in \(String(format: "%.3f", Date().timeIntervalSince(started)))s; main-run-loop ticks: \(ticks)")
        sql("DELETE FROM clipboard_history WHERE content LIKE 'bulk-history-%'")

        // Successful deletes must remove synthetic text from both the DB and its WAL.
        func requireNoResidual(_ token: String) throws {
            for name in ["clipboard.db", "clipboard.db-wal"] {
                let url = directory.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: url.path) {
                    require(try Data(contentsOf: url).range(of: Data(token.utf8)) == nil, "Deleted token remains in \(name)")
                }
            }
        }
        let token = "synthetic-delete-\(UUID())"
        try capture(token)
        let deletionID = try load(manager, query: token).first!.id
        let deletion: ClipboardMutationResult = awaitResult { manager.deleteItem(id: deletionID, completion: $0) }
        require(deletion.succeeded && deletion.committed, "Deletion failed")
        try requireNoResidual(token)
        let clearToken = "synthetic-clear-\(UUID())"
        try capture(clearToken)
        let privacyClear: ClipboardMutationResult = awaitResult { manager.clearAll(completion: $0) }
        require(privacyClear.succeeded, "Privacy clear failed")
        try requireNoResidual(clearToken)

        try capture("partial file cleanup fixture")
        let partialID = try load(manager, query: "partial file cleanup").first!.id
        let movedImages = directory.appendingPathComponent("MovedImages")
        try FileManager.default.moveItem(at: directory.appendingPathComponent("Images"), to: movedImages)
        var noticed = false
        let observer = NotificationCenter.default.addObserver(forName: .DashCatClipboardDidChange, object: manager, queue: .main) { _ in noticed = true }
        let partial: ClipboardMutationResult = awaitResult { manager.deleteItem(id: partialID, completion: $0) }
        NotificationCenter.default.removeObserver(observer)
        require(try partial.committed && partial.error == .fileCleanup && noticed && load(manager, query: "partial file cleanup").isEmpty, "Partial deletion concealed actual DB state")
        try FileManager.default.moveItem(at: movedImages, to: directory.appendingPathComponent("Images"))
        let recovered: ClipboardMutationResult = awaitResult { manager.retryStorage(completion: $0) }
        require(recovered.succeeded, "File cleanup retry failed")

        // A reader can prevent WAL truncation after DELETE has committed.
        try capture("synthetic-busy-WAL-\(UUID())")
        let busyItem = try load(manager).first(where: { !$0.isPinned })!
        sql("BEGIN")
        var reader: OpaquePointer?
        require(sqlite3_prepare_v2(db, "SELECT * FROM clipboard_history", -1, &reader, nil) == SQLITE_OK && sqlite3_step(reader) == SQLITE_ROW, "Reader fixture failed")
        let blocked: ClipboardMutationResult = awaitResult { manager.deleteItem(id: busyItem.id, completion: $0) }
        require(blocked.committed && blocked.error == .privacyCleanup, "Busy WAL cleanup reported false success")
        sqlite3_finalize(reader); sql("COMMIT")
        let walRecovered: ClipboardMutationResult = awaitResult { manager.retryStorage(completion: $0) }
        require(walRecovered.succeeded, "WAL cleanup retry failed")
        try requireNoResidual(busyItem.content!)
        print("PASS: deletion/clear residuals, partial-cleanup notification and blocked-WAL recovery")

        // Name persistence across reopen and original data stay independent.
        let imageRename: ClipboardMutationResult = awaitResult { manager.renameItem(id: image.id, name: "Saved image", completion: $0) }
        require(imageRename.succeeded, "Pinned image rename failed")
        do {
            let reopened = ClipboardManager(directory: directory, defaults: defaults, pasteboard: pb)
            let saved = try load(reopened).first!
            require(saved.name == "Saved image" && saved.imagePath == path, "Reopening lost image name or original path")
        }
        try capture("keyboard-older-A")
        try capture("keyboard-newer-B")

        // Exercise the real search-field delegate with an injected manager/pasteboard.
        let panel = ClipboardPanel(manager: manager, pasteboard: pb)
        _ = try load(manager) // Drain the panel's initial asynchronous query.
        let search = panel.contentView!.subviews.compactMap { $0 as? NSSearchField }.first!
        let table = panel.contentView!.subviews.compactMap { ($0 as? NSScrollView)?.documentView as? NSTableView }.first!
        let editor = NSTextView()
        let priorCount = pb.changeCount
        require(panel.control(search, textView: editor, doCommandBy: #selector(NSResponder.moveDown(_:))), "Search did not handle Down")
        require(table.selectedRow == 0 && pb.changeCount == priorCount, "Navigation copied or failed to select")
        table.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        let orderedCopy: ClipboardItem = awaitResult { done in
            panel.onSelect = done
            panel.reloadData()
            _ = panel.control(search, textView: editor, doCommandBy: #selector(NSResponder.moveDown(_:)))
            _ = panel.control(search, textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:)))
        }
        require(orderedCopy.content == "keyboard-older-A" && pb.string(forType: .string) == "keyboard-older-A", "Down then Enter during loading copied the old selection")
        search.stringValue = "no-such-history"
        require(panel.control(search, textView: editor, doCommandBy: #selector(NSResponder.moveDown(_:))), "Pending search command ignored")
        _ = try load(manager)
        require(table.numberOfRows == 0 && table.selectedRow == -1, "Navigation used stale search results")
        editor.setMarkedText("候选", selectedRange: NSRange(location: 0, length: 2), replacementRange: NSRange(location: NSNotFound, length: 0))
        require(!panel.control(search, textView: editor, doCommandBy: #selector(NSResponder.insertNewline(_:))), "IME confirmation was intercepted")
        if let output = ProcessInfo.processInfo.environment["DASHCAT_TEST_PREVIEW"], let view = panel.contentView {
            view.layoutSubtreeIfNeeded()
            if let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: bitmap)
                try bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: output))
            }
        }
        panel.close()
        print("PASS: search keyboard navigation, stale search protection and IME command passthrough")

        let usage = SystemMonitor.memoryUsage(active: 300, inactive: 200, wired: 100, compressed: 50, purgeable: 20, fileBacked: 130, total: 1000)
        require(usage.value == 50 && usage.description == "50% ", "Memory usage formula is ambiguous")
        require(SystemMonitor.memoryUsage(active: 0, inactive: 0, wired: 0, compressed: 0, purgeable: 1, fileBacked: 1, total: 100).value == 0, "Memory usage underflow")
        require(SystemMonitor.memoryUsage(active: 200, inactive: 0, wired: 0, compressed: 0, purgeable: 0, fileBacked: 0, total: 100).value == 100, "Memory usage overflow")
        print("PASS: memory occupancy formula and bounds")

        // Query preparation failure must retain files even when their names look orphaned.
        sql("DROP TABLE clipboard_history")
        let failed: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(!failed.succeeded, "Failed SQL reported success")
        require(FileManager.default.fileExists(atPath: path), "Failed query deleted valid image")
        // Specifically reach the SELECT guard via permanent retention (no DELETE first).
        defaults.set(36500, forKey: "DashCatHistoryDays")
        let failedSelect: ClipboardMutationResult = awaitResult { manager.cleanupExpired(completion: $0) }
        require(!failedSelect.succeeded && FileManager.default.fileExists(atPath: path), "Orphan scan failure deleted image")
        print("PASS: database failure fails closed and retains images")
        print("All clipboard regression checks passed; only temporary data was used.")
    }
}
