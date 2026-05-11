import Cocoa

private func localized(_ key: String) -> String {
    let code = UserDefaults.standard.string(forKey: "DashCatLanguage") ?? "en"
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
    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let tableView = ClipboardTableView()
    private var items: [ClipboardItem] = []
    private var searchQuery = ""
    private let maxHeight: CGFloat = 500
    private var searchTimer: Timer?
    private var hasAppeared = false
    private var isSelecting = false
    private let iconCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 100
        return cache
    }()

    var onSelect: ((ClipboardItem) -> Void)?
    weak var statusItem: NSStatusItem?

    init() {
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
            selector: #selector(reloadDataFromNotification),
            name: .DashCatClipboardDidChange, object: nil)

        setupVisualEffect()
        setupSearchField()
        setupTableView()
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

    @objc private func reloadDataFromNotification() {
        guard isVisible else { return }
        reloadData()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            close()
        } else if event.keyCode == 36 { // Enter key
            let row = tableView.selectedRow
            guard row >= 0, row < items.count else {
                super.keyDown(with: event)
                return
            }
            let item = items[row]
            let pb = NSPasteboard.general
            pb.clearContents()

            if event.modifierFlags.contains(.option) {
                // Option+Enter: copy plain text only; for images, fall back to normal copy
                if let content = item.content {
                    pb.setString(content, forType: .string)
                } else if item.isImage, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                    pb.writeObjects([image])
                }
            } else {
                // Enter: copy normally (image or text)
                if item.isImage, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
                    pb.writeObjects([image])
                } else if let content = item.content {
                    pb.setString(content, forType: .string)
                }
            }

            ClipboardManager.shared.syncChangeCount()
            tableView.deselectRow(row)
            close()
            onSelect?(item)
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
        searchField.target = self
        searchField.action = #selector(searchChanged(_:))
        searchField.font = NSFont.systemFont(ofSize: 13)
        searchField.isBezeled = true
        searchField.bezelStyle = .roundedBezel
        searchField.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(searchField)
    }

    @objc private func searchChanged(_ sender: NSSearchField) {
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

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView?.addSubview(scrollView)
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
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    // MARK: - Data

    func reloadData() {
        let manager = ClipboardManager.shared
        items = searchQuery.isEmpty ? manager.fetchAll() : manager.search(query: searchQuery)
        tableView.reloadData()
        resizeToFitContent()
    }

    private func resizeToFitContent() {
        let rowHeight = tableView.rowHeight + tableView.intercellSpacing.height
        let contentHeight = CGFloat(items.count) * rowHeight
        let searchHeight: CGFloat = 44
        let padding: CGFloat = 28
        let desiredHeight = min(maxHeight, contentHeight + searchHeight + padding)

        guard let button = statusItem?.button, let buttonWindow = button.window else {
            guard let screen = NSScreen.main else { return }
            let finalHeight = max(100, min(desiredHeight, screen.visibleFrame.height - 50))
            let currentFrame = frame
            let newFrame = NSRect(x: currentFrame.origin.x,
                                  y: currentFrame.origin.y + currentFrame.height - finalHeight,
                                  width: currentFrame.width,
                                  height: finalHeight)
            setFrame(newFrame, display: true, animate: isVisible && !hasAppeared)
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

        setFrame(NSRect(x: clampedX, y: panelY, width: frame.width, height: finalHeight),
                 display: true, animate: isVisible && !hasAppeared)
    }

    // MARK: - Public

    func showPanel() {
        searchField.stringValue = ""
        searchQuery = ""
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
        if isVisible { reloadData() }
    }

    func contextMenu(forRow row: Int) -> NSMenu? {
        guard row >= 0, row < items.count else { return nil }
        let item = items[row]
        let menu = NSMenu()

        let pinTitle = item.isPinned ? localized("unpin") : localized("pin")
        let pinItem = NSMenuItem(title: pinTitle, action: #selector(togglePinForItem(_:)), keyEquivalent: "")
        pinItem.target = self
        pinItem.representedObject = item.id
        menu.addItem(pinItem)

        let deleteItem = NSMenuItem(title: localized("delete"), action: #selector(deleteItemAtIndex(_:)), keyEquivalent: "")
        deleteItem.target = self
        deleteItem.representedObject = item.id
        menu.addItem(deleteItem)

        return menu
    }
}

// MARK: - NSTableViewDataSource & NSTableViewDelegate

extension ClipboardPanel: NSTableViewDataSource, NSTableViewDelegate {
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

            let pinIndicator = NSTextField(labelWithString: "")
            pinIndicator.tag = 3
            pinIndicator.font = NSFont.systemFont(ofSize: 10)
            pinIndicator.textColor = .secondaryLabelColor
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
                pinIndicator.widthAnchor.constraint(greaterThanOrEqualToConstant: 12),
            ])
        }

        let iconView = cell.viewWithTag(1) as? NSImageView
        let label = cell.viewWithTag(2) as? NSTextField
        let pinIndicator = cell.viewWithTag(3) as? NSTextField

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
            label?.stringValue = localized("image")
            label?.textColor = .secondaryLabelColor
            // Show thumbnail
            if let imgPath = item.imagePath,
               let thumbPath = ClipboardManager.shared.thumbnailPath(for: imgPath) {
                if let image = NSImage(contentsOfFile: thumbPath) {
                    iconView?.image = image
                    iconView?.image?.size = NSSize(width: 20, height: 20)
                }
            }
        } else {
            let text = item.content ?? ""
            let display = String(text.prefix(80))
                .replacingOccurrences(of: "\r\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\n", with: " ")
            label?.stringValue = display
            label?.textColor = .labelColor
        }

        pinIndicator?.stringValue = item.isPinned ? localized("pin") : ""

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !isSelecting else { return }
        let row = tableView.selectedRow
        guard row >= 0, row < items.count else { return }
        isSelecting = true
        let item = items[row]

        // Copy to pasteboard
        let pb = NSPasteboard.general
        pb.clearContents()
        if item.isImage, let path = item.imagePath, let image = NSImage(contentsOfFile: path) {
            pb.writeObjects([image])
        } else if let content = item.content {
            pb.setString(content, forType: .string)
        }

        ClipboardManager.shared.syncChangeCount()
        tableView.deselectRow(row)
        close()
        isSelecting = false
        onSelect?(item)
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        true
    }

    @objc private func togglePinForItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? Int64 else { return }
        ClipboardManager.shared.togglePin(id: id)
        reloadData()
    }

    @objc private func deleteItemAtIndex(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? Int64 else { return }
        ClipboardManager.shared.deleteItem(id: id)
        reloadData()
    }
}
