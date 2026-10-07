import Cocoa
import ImageIO
import UniformTypeIdentifiers

private func localized(_ key: String) -> String {
    let code = UserDefaults.standard.string(forKey: "DashCatLanguage") ?? Language.systemDefault().rawValue
    let lang = Language(rawValue: code) ?? .english
    return lang.str(key)
}

private final class ClipboardTableView: NSTableView {
    weak var clipboardMenuProvider: ClipboardPanel?

    override func menu(for event: NSEvent) -> NSMenu? {
        let point = convert(event.locationInWindow, from: nil)
        let clickedRow = row(at: point)
        guard clickedRow >= 0 else { return nil }
        return clipboardMenuProvider?.contextMenu(forRow: clickedRow)
    }
}

final class ClipboardPanel: NSPanel {
    private let manager: ClipboardManager
    private let pasteboard: NSPasteboard
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let tableView = ClipboardTableView()
    private let emptyLabel = NSTextField(labelWithString: "")
    private let hintLabel = NSTextField(labelWithString: "")
    private let footerView = NSStackView()
    private var items: [ClipboardItem] = []
    private var searchQuery = ""
    private let moreButton = NSButton(title: "", target: nil, action: nil)
    private var pageRevision: Int?
    private var hasMore = false
    private var loadFailed = false
    private var needsStorageRetry = false
    private var operationError: ClipboardError?
    private var operationCommitted = false
    private var loadGeneration = 0
    private var isLoading = false
    private var pendingCommands: [Selector] = []
    private var copyGeneration = 0
    private var previewGeneration = 0
    private var toast: NSPanel?
    private var loadingThumbnails = Set<String>()
    private let maxHeight: CGFloat = 500
    private var searchTimer: Timer?
    private var hasAppeared = false
    private let thumbnailCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 200
        return cache
    }()
    private let iconCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 100
        return cache
    }()
    private var appNames = [String: String]()

    var onSelect: ((ClipboardItem) -> Void)?
    weak var statusItem: NSStatusItem?

    init(manager: ClipboardManager = .shared, pasteboard: NSPasteboard = .general) {
        self.manager = manager
        self.pasteboard = pasteboard
        let panelWidth: CGFloat = 350
        super.init(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: maxHeight),
                   styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                   backing: .buffered, defer: true)

        isFloatingPanel = true
        level = .statusBar
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .clear
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Auto-refresh when clipboard data changes
        NotificationCenter.default.addObserver(self,
            selector: #selector(reloadDataFromNotification(_:)),
            name: .DashCatClipboardDidChange, object: manager)

        setupVisualEffect()
        setupSearchField()
        setupTableView()
        setupEmptyLabel()
        setupLayout()

        reloadData()
    }

    deinit {
        searchTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    override func close() {
        searchTimer?.invalidate()
        searchTimer = nil
        copyGeneration += 1
        previewGeneration += 1
        loadGeneration += 1
        isLoading = false
        pendingCommands.removeAll()
        super.close()
    }

    private var isResigningKey = false

    @objc override func resignKey() {
        guard !isResigningKey else { return }
        isResigningKey = true
        super.resignKey()
        // Delay close to avoid dismissal on transient key loss (e.g. input method, system dialogs)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isResigningKey = false
            guard let self = self, self.isVisible, !self.isKeyWindow else { return }
            self.close()
        }
    }

    @objc private func reloadDataFromNotification(_ notification: Notification) {
        if notification.userInfo?["storageRecovered"] as? Bool == true {
            needsStorageRetry = false
            operationError = nil
        }
        guard isVisible else { return }
        reloadData()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            close()
        } else if event.keyCode == 36 { // Enter key
            _ = handleNavigation(#selector(NSResponder.insertNewline(_:)))
        } else if event.keyCode == 49, tableView.selectedRow >= 0 {
            showPreview(items[tableView.selectedRow])
        } else {
            super.keyDown(with: event)
        }
    }

    // MARK: - Visual Effect

    private func setupVisualEffect() {
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .menu
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 8
        contentView = visualEffect
    }

    // MARK: - Search

    private func setupSearchField() {
        searchField.placeholderString = localized("search")
        searchField.sendsSearchStringImmediately = true
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(searchChanged(_:))
        searchField.font = NSFont.systemFont(ofSize: 13)
        searchField.isBezeled = true
        searchField.bezelStyle = .roundedBezel
        searchField.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(searchField)
    }

    @objc private func searchChanged(_ sender: NSSearchField) {
        if !needsStorageRetry { operationError = nil }
        pendingCommands.removeAll()
        copyGeneration += 1
        loadGeneration += 1
        isLoading = false
        setHint(localized("loading"))
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.searchQuery = sender.stringValue
            self?.reloadData()
        }
    }

    // MARK: - Table View

    private func setupTableView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("item"))
        column.isEditable = false
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.rowHeight = 32
        tableView.intercellSpacing = NSSize(width: 0, height: 1)
        tableView.selectionHighlightStyle = .regular
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipboardMenuProvider = self
        tableView.action = #selector(tableViewClicked(_:))
        tableView.target = self

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(scrollView)
    }

    private func setupEmptyLabel() {
        emptyLabel.font = NSFont.systemFont(ofSize: 13)
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.maximumNumberOfLines = 3
        emptyLabel.lineBreakMode = .byWordWrapping
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(emptyLabel)

        hintLabel.font = NSFont.systemFont(ofSize: 11)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.alignment = .center
        hintLabel.lineBreakMode = .byTruncatingTail
        hintLabel.isHidden = true
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        footerView.orientation = .vertical
        footerView.alignment = .centerX
        footerView.spacing = 6
        footerView.detachesHiddenViews = true
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.addArrangedSubview(hintLabel)
        moreButton.title = localized("loadMore")
        moreButton.target = self
        moreButton.action = #selector(loadMore)
        moreButton.bezelStyle = .rounded
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        moreButton.isHidden = true
        footerView.addArrangedSubview(moreButton)
        contentView?.addSubview(footerView)
    }

    // MARK: - Layout

    private func setupLayout() {
        guard let contentView = contentView else { return }
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -8),
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            hintLabel.widthAnchor.constraint(equalTo: footerView.widthAnchor),

            emptyLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emptyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emptyLabel.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
        ])
    }

    // MARK: - Data

    func reloadData() {
        requestPage(append: false)
    }

    private func requestPage(append: Bool) {
        loadGeneration += 1
        isLoading = true
        let generation = loadGeneration
        let selectedID = items.indices.contains(tableView.selectedRow) ? items[tableView.selectedRow].id : nil
        setHint(items.isEmpty ? nil : localized("loading"))
        emptyLabel.isHidden = !items.isEmpty
        if items.isEmpty { emptyLabel.stringValue = localized("loading") }
        moreButton.isEnabled = false
        let cursor = append ? items.last.map(ClipboardCursor.init) : nil
        manager.loadPage(query: searchQuery, after: cursor, revision: append ? pageRevision : nil) { [weak self] result in
            guard let self, generation == self.loadGeneration else { return }
            self.isLoading = false
            switch result {
            case .success(let page):
                self.loadFailed = false
                self.pageRevision = page.revision
                self.hasMore = page.hasMore
                self.moreButton.title = localized(self.needsStorageRetry ? "retry" : "loadMore")
                self.moreButton.isHidden = !page.hasMore && !self.needsStorageRetry
                self.moreButton.isEnabled = true
                if append { self.items.append(contentsOf: page.items) } else { self.items = page.items }
                self.tableView.reloadData()
                self.tableView.deselectAll(nil)
                if let selectedID, let row = self.items.firstIndex(where: { $0.id == selectedID }) {
                    self.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                }
                self.updateEmptyState()
                self.restoreHint()
                self.resizeToFitContent()
                let commands = self.pendingCommands
                self.pendingCommands.removeAll()
                for command in commands {
                    _ = self.executeNavigation(command)
                    if self.isCopyCommand(command) { break }
                }
            case .failure(let error):
                if error as? ClipboardError == .historyChanged { self.reloadData(); return }
                self.pendingCommands.removeAll()
                self.loadFailed = true
                if !append { self.items = []; self.tableView.reloadData() }
                self.moreButton.title = localized("retry")
                self.moreButton.isHidden = false
                self.moreButton.isEnabled = true
                if self.items.isEmpty { self.setHint(nil) }
                else { self.showOperationFailure(error) }
                self.emptyLabel.stringValue = localized((error as? ClipboardError)?.messageKey ?? "clipboardFailure")
                self.emptyLabel.isHidden = !self.items.isEmpty
                self.resizeToFitContent()
            }
        }
    }

    @objc private func loadMore() {
        guard !isLoading else { return }
        if loadFailed || needsStorageRetry {
            moreButton.isEnabled = false
            manager.retryStorage { [weak self] result in
                guard let self else { return }
                self.moreButton.isEnabled = true
                if result.succeeded {
                    self.needsStorageRetry = false
                    self.operationError = nil
                    self.reloadData()
                } else { self.showMutationResult(result) }
            }
        } else if hasMore { requestPage(append: true) }
    }

    private func restoreHint() {
        guard let error = operationError else { setHint(nil); return }
        let detail = localized(error.messageKey)
        let message = operationCommitted ? localized("cleanupPending") : detail
        setHint(message, details: operationCommitted ? message + "\n" + detail : detail)
    }

    private func setHint(_ message: String?, details: String? = nil) {
        hintLabel.stringValue = message ?? ""
        hintLabel.toolTip = details ?? message
        hintLabel.isHidden = message == nil
    }

    private func showOperationFailure(_ error: Error) {
        setHint(localized((error as? ClipboardError)?.messageKey ?? "copyFailed"))
    }

    private func showMutationResult(_ result: ClipboardMutationResult) {
        if let error = result.error {
            operationError = error
            operationCommitted = result.committed
            if error.requiresStorageRetry {
                needsStorageRetry = true
                moreButton.title = localized("retry")
                moreButton.isHidden = false
                moreButton.isEnabled = true
            }
        } else if !needsStorageRetry { operationError = nil }
        if result.committed { reloadData() }
        else { restoreHint(); resizeToFitContent() }
    }

    private func updateEmptyState() {
        emptyLabel.stringValue = searchQuery.isEmpty ? localized("noClipboardHistory") : localized("noSearchResults")
        emptyLabel.isHidden = !items.isEmpty
    }

    private func resizeToFitContent() {
        let rowHeight = tableView.rowHeight + tableView.intercellSpacing.height
        let contentHeight = CGFloat(items.count) * rowHeight
        let searchHeight: CGFloat = 44
        let hintHeight: CGFloat = hintLabel.isHidden ? 0 : 18
        let buttonHeight: CGFloat = moreButton.isHidden ? 0 : 24
        let footerHeight = hintHeight + buttonHeight + (hintHeight > 0 && buttonHeight > 0 ? 6 : 0)
        let padding: CGFloat = 16 + footerHeight
        let desiredHeight = min(maxHeight, contentHeight + searchHeight + padding)

        guard let button = statusItem?.button, let buttonWindow = button.window else {
            guard let screen = NSScreen.main else { return }
            let screenFrame = screen.visibleFrame
            let finalHeight = max(100, min(desiredHeight, screen.visibleFrame.height - 50))
            let currentFrame = frame
            let rawY = currentFrame.origin.y + currentFrame.height - finalHeight
            let clampedX = max(screenFrame.minX, min(currentFrame.origin.x, screenFrame.maxX - currentFrame.width))
            let clampedY = max(screenFrame.minY, min(rawY, screenFrame.maxY - finalHeight))
            setFrame(NSRect(x: clampedX, y: clampedY, width: currentFrame.width, height: finalHeight),
                     display: true, animate: isVisible && !hasAppeared)
            return
        }

        // Find the screen containing the status item button
        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let buttonPoint = NSPoint(x: buttonFrame.midX, y: buttonFrame.midY)
        let screen: NSScreen? = NSScreen.screens.first { $0.frame.contains(buttonPoint) } ?? NSScreen.main
        guard let screen else { return }
        let screenFrame = screen.visibleFrame
        let finalHeight = max(100, min(desiredHeight, screenFrame.height - 50))

        let buttonCenterX = buttonFrame.midX
        let panelX = buttonCenterX - frame.width / 2
        let panelY = buttonFrame.minY - finalHeight - 4
        let clampedX = max(screenFrame.minX, min(panelX, screenFrame.maxX - frame.width))
        let clampedY = max(screenFrame.minY, min(panelY, screenFrame.maxY - finalHeight))

        setFrame(NSRect(x: clampedX, y: clampedY, width: frame.width, height: finalHeight),
                 display: true, animate: isVisible && !hasAppeared)
    }

    // MARK: - Public

    func showPanel(query: String = "") {
        searchField.stringValue = query
        searchQuery = query
        pendingCommands.removeAll()
        restoreHint()
        hasAppeared = false
        reloadData()
        hasAppeared = true
        makeKeyAndOrderFront(nil)
        if let window = searchField.window {
            window.makeFirstResponder(searchField)
        }
    }

    func toggle() {
        if isVisible {
            close()
        } else {
            showPanel()
        }
    }

    func refreshLocale() {
        searchField.placeholderString = localized("search")
        restoreHint()
        moreButton.title = localized(loadFailed || needsStorageRetry ? "retry" : "loadMore")
        if isVisible { reloadData() }
    }

    func contextMenu(forRow row: Int) -> NSMenu? {
        guard row >= 0, row < items.count, !isLoading, searchQuery == searchField.stringValue else { return nil }
        let item = items[row]
        let menu = NSMenu()
        let preview = NSMenuItem(title: localized("preview"), action: #selector(previewItem(_:)), keyEquivalent: "")
        preview.target = self
        preview.representedObject = item
        menu.addItem(preview)

        let pinTitle = item.isPinned ? localized("unpin") : localized("pin")
        let pinItem = NSMenuItem(title: pinTitle, action: #selector(togglePinForItem(_:)), keyEquivalent: "")
        pinItem.target = self
        pinItem.representedObject = item.id
        menu.addItem(pinItem)

        if item.isPinned {
            let rename = NSMenuItem(title: localized("renameClip"), action: #selector(renameItem(_:)), keyEquivalent: "")
            rename.target = self
            rename.representedObject = item
            menu.addItem(rename)
        }

        let deleteItem = NSMenuItem(title: localized("delete"), action: #selector(deleteItemAtIndex(_:)), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.representedObject = item.id
        menu.addItem(deleteItem)

        return menu
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate

extension ClipboardPanel: NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = items[row]
        let cellID = NSUserInterfaceItemIdentifier("ClipboardCell")

        let cell: NSTableCellView
        if let recycled = tableView.makeView(withIdentifier: cellID, owner: self) as? NSTableCellView {
            cell = recycled
        } else {
            cell = NSTableCellView()
            cell.identifier = cellID

            let iconView = NSImageView()
            iconView.tag = 1
            iconView.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(iconView)

            let label = NSTextField(labelWithString: "")
            label.tag = 2
            label.font = NSFont.systemFont(ofSize: 12)
            label.lineBreakMode = .byTruncatingTail
            label.maximumNumberOfLines = 1
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)

            let pinIndicator = NSImageView()
            pinIndicator.tag = 3
            pinIndicator.contentTintColor = .secondaryLabelColor
            pinIndicator.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(pinIndicator)

            NSLayoutConstraint.activate([
                iconView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
                iconView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 20),
                iconView.heightAnchor.constraint(equalToConstant: 20),

                label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
                label.trailingAnchor.constraint(equalTo: pinIndicator.leadingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

                pinIndicator.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
                pinIndicator.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
                pinIndicator.widthAnchor.constraint(equalToConstant: 12),
                pinIndicator.heightAnchor.constraint(equalToConstant: 14),
            ])
        }

        let iconView = cell.viewWithTag(1) as? NSImageView
        let label = cell.viewWithTag(2) as? NSTextField
        let pinIndicator = cell.viewWithTag(3) as? NSImageView

        // App icon (cached)
        if let bundleId = item.sourceApp.isEmpty ? nil : item.sourceApp {
            let cacheKey = bundleId as NSString
            if let cached = iconCache.object(forKey: cacheKey) {
                iconView?.image = cached
            } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                icon.size = NSSize(width: 16, height: 16)
                iconCache.setObject(icon, forKey: cacheKey)
                iconView?.image = icon
            } else {
                iconView?.image = nil
            }
        } else {
            iconView?.image = nil
        }

        // Content
        if item.isImage {
            label?.stringValue = item.name ?? localized("image")
            label?.textColor = item.name == nil ? .secondaryLabelColor : .labelColor
            iconView?.image = nil
            // Show thumbnail
            if let imgPath = item.imagePath,
               let thumbPath = manager.thumbnailPath(for: imgPath) {
                let cacheKey = thumbPath as NSString
                if let cached = thumbnailCache.object(forKey: cacheKey) {
                    iconView?.image = cached
                } else if loadingThumbnails.insert(thumbPath).inserted {
                    let itemID = item.id
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        let data = try? Data(contentsOf: URL(fileURLWithPath: thumbPath))
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            self.loadingThumbnails.remove(thumbPath)
                            guard let data, let image = NSImage(data: data) else { return }
                            image.size = NSSize(width: 20, height: 20)
                            self.thumbnailCache.setObject(image, forKey: cacheKey)
                            if let currentRow = self.items.firstIndex(where: { $0.id == itemID }) {
                                self.tableView.reloadData(forRowIndexes: IndexSet(integer: currentRow),
                                                          columnIndexes: IndexSet(integer: 0))
                            }
                        }
                    }
                }
            }
        } else {
            let text = item.content ?? ""
            let display = String(text.prefix(80))
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
            label?.stringValue = item.name ?? display
            label?.textColor = .labelColor
        }

        pinIndicator?.image = item.isPinned ? NSImage(systemSymbolName: "pin.fill", accessibilityDescription: localized("pinnedMarker")) : nil
        pinIndicator?.isHidden = !item.isPinned
        pinIndicator?.toolTip = item.isPinned ? localized("pinnedMarker") : nil
        pinIndicator?.setAccessibilityLabel(item.isPinned ? localized("pinnedMarker") : nil)
        let details = [item.name, item.content, "\(sourceName(item.sourceApp)) · \(Date(timeIntervalSince1970: item.createdAt).formatted())", localized("previewFullHint")].compactMap { $0 }.joined(separator: "\n")
        cell.toolTip = details
        label?.toolTip = details
        cell.setAccessibilityLabel([label?.stringValue, sourceName(item.sourceApp), item.isPinned ? localized("pinnedMarker") : nil].compactMap { $0 }.joined(separator: ", "))

        return cell
    }

    private func sourceName(_ bundleID: String) -> String {
        if bundleID.isEmpty { return localized("unknown") }
        if let name = appNames[bundleID] { return name }
        let name = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
            .map { FileManager.default.displayName(atPath: $0.path).replacingOccurrences(of: ".app", with: "") } ?? bundleID
        appNames[bundleID] = name
        return name
    }

    @objc private func tableViewClicked(_ sender: NSTableView) {
        // action fires only on mouse click; clickedRow is always valid here
        let row = sender.clickedRow
        guard row >= 0, row < items.count, !isLoading, searchField.stringValue == searchQuery else { return }
        let isOption = NSApp.currentEvent?.modifierFlags.contains(.option) == true
        performCopy(forRow: row, isOption: isOption)
    }

    private func performCopy(forRow row: Int, isOption: Bool) {
        guard items.indices.contains(row), !isLoading else { return }
        copy(items[row]) // Text history is always plain text.
    }

    private func copy(_ item: ClipboardItem) {
        copyGeneration += 1
        let generation = copyGeneration
        setHint(localized("loading"))
        manager.loadItem(id: item.id) { [weak self] result in
            guard let self, generation == self.copyGeneration else { return }
            switch result {
            case .failure(let error): self.showCopyFailure(error)
            case .success(let fullItem):
                if let content = fullItem.content { self.writeCopy(fullItem, payload: content as NSString); return }
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let payload = Result { try Self.imagePayload(fullItem) }
                    DispatchQueue.main.async {
                        guard let self, generation == self.copyGeneration else { return }
                        switch payload {
                        case .success(let prepared): self.writeCopy(fullItem, payload: prepared)
                        case .failure(let error): self.showCopyFailure(error)
                        }
                    }
                }
            }
        }
    }

    static func imagePayload(_ item: ClipboardItem) throws -> NSPasteboardWriting {
        guard let path = item.imagePath else { throw ClipboardError.itemMissing }
        let data = try ClipboardManager.readImage(at: path)
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let type = CGImageSourceGetType(source) as String?
        let payload = NSPasteboardItem()
        if type == UTType.png.identifier || type == UTType.tiff.identifier {
            guard payload.setData(data, forType: type == UTType.png.identifier ? .png : .tiff) else { throw ClipboardError.image }
        } else {
            guard let image = NSImage(data: data), let tiff = image.tiffRepresentation,
                  payload.setData(tiff, forType: .tiff) else { throw ClipboardError.image }
        }
        return payload
    }

    private func writeCopy(_ item: ClipboardItem, payload: NSPasteboardWriting) {
        let pb = pasteboard
        pb.clearContents()
        guard pb.writeObjects([payload]) else {
            showCopyFailure()
            return
        }
        manager.syncChangeCount()
        close()
        showCopiedToast()
        onSelect?(item)
    }

    private func showCopyFailure(_ error: Error? = nil) {
        if let error { showOperationFailure(error) }
        else { setHint(localized("copyFailed")) }
        resizeToFitContent()
        if !isVisible {
            let alert = NSAlert()
            alert.messageText = localized("copyFailed")
            alert.informativeText = hintLabel.stringValue
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }

    private func showCopiedToast() {
        toast?.close()
        let panel = NSPanel(contentRect: NSRect(x: frame.midX - 100, y: frame.maxY - 45, width: 200, height: 32),
                            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = .statusBar
        panel.hasShadow = true
        let label = NSTextField(labelWithString: localized("copied"))
        label.alignment = .center
        label.frame = NSRect(x: 4, y: 8, width: 192, height: 20)
        panel.contentView?.addSubview(label)
        toast = panel
        panel.orderFrontRegardless()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self, weak panel] in
            panel?.close()
            if self?.toast === panel { self?.toast = nil }
        }
    }

    @objc private func previewItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipboardItem else { return }
        showPreview(item)
    }

    private func showPreview(_ item: ClipboardItem) {
        previewGeneration += 1
        let generation = previewGeneration
        setHint(localized("loading"))
        manager.loadItem(id: item.id) { [weak self] result in
            guard let self, generation == self.previewGeneration else { return }
            switch result {
            case .failure(let error): self.showCopyFailure(error)
            case .success(let fullItem):
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    let image = Result { () throws -> CGImage? in
                        guard let path = fullItem.imagePath else { return nil }
                        return try ClipboardManager.validatedThumbnail(ClipboardManager.readImage(at: path), maxSize: 560)
                    }
                    DispatchQueue.main.async {
                        guard let self, generation == self.previewGeneration else { return }
                        switch image {
                        case .failure(let error): self.showCopyFailure(error)
                        case .success(let image): self.presentPreview(fullItem, image: image)
                        }
                    }
                }
            }
        }
    }

    private func presentPreview(_ item: ClipboardItem, image: CGImage?) {
        let alert = NSAlert()
        alert.messageText = item.name ?? localized("preview")
        alert.informativeText = "\(sourceName(item.sourceApp)) · \(Date(timeIntervalSince1970: item.createdAt).formatted())"
        alert.addButton(withTitle: localized("copy"))
        alert.addButton(withTitle: localized("cancel"))
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 560, height: 340))
        scroll.hasVerticalScroller = true
        if let content = item.content {
            let text = NSTextView(frame: scroll.bounds)
            text.isEditable = false
            text.isRichText = false
            text.string = content
            text.font = .systemFont(ofSize: 13)
            text.isVerticallyResizable = true
            text.autoresizingMask = [.width]
            text.textContainer?.widthTracksTextView = true
            scroll.documentView = text
            alert.accessoryView = scroll
        } else if let image {
            let view = NSImageView(frame: scroll.bounds)
            view.image = NSImage(cgImage: image, size: .zero)
            view.imageScaling = .scaleProportionallyUpOrDown
            alert.accessoryView = view
        } else {
            self.showCopyFailure()
            return
        }
        self.close()
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn { self.copy(item) }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Leave IME composition/selection to the field editor.
        guard !textView.hasMarkedText() else { return false }
        return handleNavigation(commandSelector)
    }

    private func isCopyCommand(_ command: Selector) -> Bool {
        command == #selector(NSResponder.insertNewline(_:)) || command == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:))
    }

    private func handleNavigation(_ commandSelector: Selector) -> Bool {
        let navigation: Set<Selector> = [#selector(NSResponder.moveDown(_:)), #selector(NSResponder.moveUp(_:)),
            #selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:))]
        if navigation.contains(commandSelector), isLoading || searchQuery != searchField.stringValue {
            pendingCommands.append(commandSelector)
            if searchQuery != searchField.stringValue {
                searchTimer?.invalidate()
                searchQuery = searchField.stringValue
                reloadData()
            }
            return true
        }
        return executeNavigation(commandSelector)
    }

    private func executeNavigation(_ commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)), #selector(NSResponder.moveUp(_:)):
            guard !items.isEmpty else { return true }
            let down = commandSelector == #selector(NSResponder.moveDown(_:))
            let selected = tableView.selectedRow
            let row = selected < 0 ? (down ? 0 : items.count - 1) : min(items.count - 1, max(0, selected + (down ? 1 : -1)))
            tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            tableView.scrollRowToVisible(row)
            return true
        case #selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
            if !items.isEmpty { copy(items[max(0, tableView.selectedRow)]) }
            return true
        case #selector(NSResponder.cancelOperation(_:)):
            close(); return true
        default: return false
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { true }

    @objc private func togglePinForItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? Int64 else { return }
        manager.togglePin(id: id) { [weak self] result in self?.showMutationResult(result) }
    }

    @objc private func deleteItemAtIndex(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? Int64 else { return }
        manager.deleteItem(id: id) { [weak self] result in self?.showMutationResult(result) }
    }

    @objc private func renameItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipboardItem, item.isPinned else { return }
        let query = searchField.stringValue
        close()
        let alert = NSAlert()
        alert.messageText = localized("renameClip")
        alert.informativeText = localized("renameClipPrompt")
        alert.addButton(withTitle: localized("save"))
        alert.addButton(withTitle: localized("cancel"))
        if item.name != nil { alert.addButton(withTitle: localized("resetClipName")) }
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 360, height: 24))
        input.stringValue = item.name ?? ""
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        NSApp.activate(ignoringOtherApps: true)
        var response = alert.runModal()
        while response == .alertFirstButtonReturn && (input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).count > 200 || input.stringValue.contains(where: { $0.isNewline })) {
            alert.informativeText = localized("invalidClipName")
            response = alert.runModal()
        }
        guard response == .alertFirstButtonReturn || response == .alertThirdButtonReturn else { showPanel(query: query); return }
        manager.renameItem(id: item.id, name: response == .alertThirdButtonReturn ? nil : input.stringValue) { [weak self] result in
            guard let self else { return }
            self.showPanel(query: query)
            self.showMutationResult(result)
        }
    }
}
