import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

// MARK: - MonitorMode

enum MonitorMode: String, CaseIterable {
    case combined = "Combined"
    case cpu      = "CPU"
    case memory   = "Memory"

    var locKey: String {
        switch self {
        case .combined: return "combined"
        case .cpu:      return "cpu"
        case .memory:   return "memory"
        }
    }
}

// MARK: - DisplayMode

enum DisplayMode: String, CaseIterable {
    case both      = "both"
    case animOnly  = "animOnly"
    case pctOnly   = "pctOnly"

    var locKey: String {
        switch self {
        case .both:     return "displayBoth"
        case .animOnly: return "displayAnimOnly"
        case .pctOnly:  return "displayPctOnly"
        }
    }
}

// MARK: - CaffeineMode

enum CaffeineMode: Int, CaseIterable {
    case off
    case noSleep
    case noDisplaySleep

    var locKey: String {
        switch self {
        case .off:            return "sleepOff"
        case .noSleep:        return "sleepSystem"
        case .noDisplaySleep: return "sleepDisplay"
        }
    }

    var assertionType: CFString? {
        switch self {
        case .off:            return nil
        case .noSleep:        return kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
        case .noDisplaySleep: return kIOPMAssertionTypeNoDisplaySleep as CFString
        }
    }
}

// MARK: - HistoryDays

enum HistoryDays: Int, CaseIterable {
    case seven = 7
    case fourteen = 14
    case thirty = 30
    case ninety = 90
    case forever = 36500

    var locKey: String {
        switch self {
        case .seven:    return "days7"
        case .fourteen: return "days14"
        case .thirty:   return "days30"
        case .ninety:   return "days90"
        case .forever:  return "forever"
        }
    }
}

// MARK: - Language

enum Language: String, CaseIterable {
    case chinese  = "zh"
    case english  = "en"
    case japanese = "ja"
    case korean   = "ko"
    case german   = "de"
    case french   = "fr"
    case russian  = "ru"

    var displayName: String {
        switch self {
        case .chinese:  return "中文"
        case .english:  return "English"
        case .japanese: return "日本語"
        case .korean:   return "한국어"
        case .german:   return "Deutsch"
        case .french:   return "Français"
        case .russian:  return "Русский"
        }
    }

    private static let table: [String: [String: String]] = [
        "monitor":      ["zh":"监控",       "en":"Monitor",          "ja":"モニター",             "ko":"모니터",        "de":"Monitor",                     "fr":"Moniteur",               "ru":"Монитор"],
        "combined":     ["zh":"综合",       "en":"Combined",         "ja":"複合",                 "ko":"복합",          "de":"Kombiniert",                  "fr":"Combiné",                "ru":"Комбинированный"],
        "cpu":          ["zh":"CPU",        "en":"CPU",              "ja":"CPU",                  "ko":"CPU",           "de":"CPU",                         "fr":"CPU",                    "ru":"CPU"],
        "memory":       ["zh":"内存",       "en":"Memory",           "ja":"メモリ",               "ko":"메모리",        "de":"Speicher",                    "fr":"Mémoire",                "ru":"Память"],
        "sleep":        ["zh":"阻止休眠",   "en":"Sleep Prevention", "ja":"スリープ防止",         "ko":"절전 방지",     "de":"Ruhezustand",                 "fr":"Prévention veille",      "ru":"Режим сна"],
        "sleepOff":     ["zh":"关闭",       "en":"Off",              "ja":"オフ",                 "ko":"끔",            "de":"Aus",                         "fr":"Désactivé",              "ru":"Выкл"],
        "sleepSystem":  ["zh":"阻止系统休眠","en":"Prevent System Sleep","ja":"システムスリープを防止","ko":"시스템 절전 방지","de":"Systemschlaf verhindern","fr":"Empêcher la mise en veille","ru":"Предотвратить сон системы"],
        "sleepDisplay": ["zh":"阻止屏幕休眠","en":"Prevent Display Sleep","ja":"ディスプレイスリープを防止","ko":"화면 절전 방지","de":"Display-Schlaf verhindern","fr":"Empêcher la veille écran","ru":"Предотвратить сон экрана"],
        "display":       ["zh":"显示",          "en":"Display",            "ja":"表示",                "ko":"표시",           "de":"Anzeige",                     "fr":"Affichage",              "ru":"Отображение"],
        "displayBoth":   ["zh":"数值与动画",    "en":"Percentage & Animation","ja":"数値とアニメーション","ko":"숫자 및 애니메이션","de":"Prozentwert & Animation","fr":"Pourcentage & animation","ru":"Процент и анимация"],
        "displayAnimOnly":["zh":"仅动画",       "en":"Animation Only",     "ja":"アニメーションのみ",   "ko":"애니메이션만",   "de":"Nur Animation",               "fr":"Animation uniquement",   "ru":"Только анимация"],
        "displayPctOnly":["zh":"仅数值",        "en":"Percentage Only",    "ja":"数値のみ",             "ko":"숫자만",         "de":"Nur Prozentwert",             "fr":"Pourcentage uniquement", "ru":"Только процент"],
        "clipboard":    ["zh":"剪贴板",     "en":"Clipboard",        "ja":"クリップボード",       "ko":"클립보드",      "de":"Zwischenablage",              "fr":"Presse-papiers",         "ru":"Буфер обмена"],
        "language":     ["zh":"语言",       "en":"Language",         "ja":"言語",                 "ko":"언어",          "de":"Sprache",                     "fr":"Langue",                 "ru":"Язык"],
        "saveImages":   ["zh":"保存图片",   "en":"Save Images",      "ja":"画像を保存",           "ko":"이미지 저장",   "de":"Bilder speichern",            "fr":"Enregistrer les images", "ru":"Сохранять изображения"],
        "history":      ["zh":"历史记录",   "en":"History",          "ja":"履歴",                 "ko":"기록",          "de":"Verlauf",                     "fr":"Historique",             "ru":"История"],
        "days7":        ["zh":"7 天",       "en":"7 Days",           "ja":"7日",                  "ko":"7일",           "de":"7 Tage",                      "fr":"7 jours",                "ru":"7 дней"],
        "days14":       ["zh":"14 天",      "en":"14 Days",          "ja":"14日",                 "ko":"14일",          "de":"14 Tage",                     "fr":"14 jours",               "ru":"14 дней"],
        "days30":       ["zh":"30 天",      "en":"30 Days",          "ja":"30日",                 "ko":"30일",          "de":"30 Tage",                     "fr":"30 jours",               "ru":"30 дней"],
        "days90":       ["zh":"90 天",      "en":"90 Days",          "ja":"90日",                 "ko":"90일",          "de":"90 Tage",                     "fr":"90 jours",               "ru":"90 дней"],
        "forever":      ["zh":"永久",       "en":"Forever",          "ja":"無期限",               "ko":"영구",          "de":"Unbegrenzt",                  "fr":"Pour toujours",          "ru":"Навсегда"],
        "customDays":   ["zh":"自定义\u{2026}","en":"Custom\u{2026}","ja":"カスタム\u{2026}","ko":"사용자 정의\u{2026}","de":"Benutzerdefiniert\u{2026}","fr":"Personnalisé\u{2026}","ru":"Пользовательский\u{2026}"],
        "search":       ["zh":"搜索\u{2026}",   "en":"Search\u{2026}",  "ja":"検索\u{2026}",         "ko":"검색\u{2026}",      "de":"Suchen\u{2026}",              "fr":"Rechercher\u{2026}",      "ru":"Поиск\u{2026}"],
        "image":        ["zh":"图片",           "en":"Image",           "ja":"画像",                 "ko":"이미지",            "de":"Bild",                        "fr":"Image",                  "ru":"Изображение"],
        "pin":          ["zh":"固定",           "en":"Pin",             "ja":"ピン",                 "ko":"고정",              "de":"Anheften",                    "fr":"Épingler",               "ru":"Закрепить"],
        "unpin":        ["zh":"取消固定",       "en":"Unpin",           "ja":"ピン解除",             "ko":"고정 해제",         "de":"Lösen",                       "fr":"Détacher",               "ru":"Открепить"],
        "delete":       ["zh":"删除",           "en":"Delete",          "ja":"削除",                 "ko":"삭제",              "de":"Löschen",                     "fr":"Supprimer",              "ru":"Удалить"],
        "customDaysPrompt":["zh":"输入天数 (1-365)：","en":"Enter number of days (1-365):","ja":"日数を入力 (1-365)：","ko":"일수 입력 (1-365)：","de":"Anzahl der Tage eingeben (1-365)：","fr":"Entrez le nombre de jours (1-365) :","ru":"Введите количество дней (1-365):"],
        "ok":           ["zh":"好",             "en":"OK",              "ja":"OK",                   "ko":"확인",              "de":"OK",                          "fr":"OK",                     "ru":"OK"],
        "cancel":       ["zh":"取消",           "en":"Cancel",          "ja":"キャンセル",           "ko":"취소",              "de":"Abbrechen",                   "fr":"Annuler",                "ru":"Отмена"],
        "clearHistory": ["zh":"清除历史",   "en":"Clear History",    "ja":"履歴をクリア",         "ko":"기록 지우기",   "de":"Verlauf löschen",             "fr":"Effacer l'historique",   "ru":"Очистить историю"],
        "launchLogin":  ["zh":"开机启动",   "en":"Launch at Login",  "ja":"ログイン時に起動",     "ko":"로그인 시 시작","de":"Beim Login starten",          "fr":"Lancer au démarrage",    "ru":"Запуск при входе"],
        "help":         ["zh":"帮助与更新",   "en":"Help & Updates",   "ja":"ヘルプと更新",         "ko":"도움말 및 업데이트","de":"Hilfe & Updates",            "fr":"Aide et mises à jour",  "ru":"Справка и обновления"],
        "checkUpdates": ["zh":"检查更新\u{2026}","en":"Check for Updates\u{2026}","ja":"アップデートを確認\u{2026}","ko":"업데이트 확인\u{2026}","de":"Nach Updates suchen\u{2026}","fr":"Vérifier les mises à jour\u{2026}","ru":"Проверить обновления\u{2026}"],
        "viewOnGitHub": ["zh":"在 GitHub 上查看","en":"View on GitHub","ja":"GitHubで開く",       "ko":"GitHub에서 보기","de":"Auf GitHub öffnen",          "fr":"Voir sur GitHub",       "ru":"Открыть на GitHub"],
        "contact":      ["zh":"联系方式",            "en":"Contact",                "ja":"お問い合わせ",           "ko":"연락처",              "de":"Kontakt",                    "fr":"Contact",                "ru":"Контакты"],
        "contactTitle": ["zh":"DashCat 联系信息",    "en":"DashCat Contact Info",   "ja":"DashCat 連絡先",         "ko":"DashCat 연락처 정보", "de":"DashCat Kontaktinformationen","fr":"Infos de contact DashCat","ru":"Контактная информация DashCat"],
        "contactBody":  ["zh":"作者：Lucas\n\n功能建议与问题反馈：\nhttps://github.com/vivalucas/DashCat/issues\n\n邮箱：lucas6.zju@vip.163.com","en":"Author: Lucas\n\nBug reports & feature requests:\nhttps://github.com/vivalucas/DashCat/issues\n\nEmail: lucas6.zju@vip.163.com","ja":"作者：Lucas\n\nバグ報告・機能リクエスト：\nhttps://github.com/vivalucas/DashCat/issues\n\nメール：lucas6.zju@vip.163.com","ko":"작성자: Lucas\n\n버그 신고 및 기능 요청:\nhttps://github.com/vivalucas/DashCat/issues\n\n이메일: lucas6.zju@vip.163.com","de":"Autor: Lucas\n\nFehlermeldungen & Feature Requests:\nhttps://github.com/vivalucas/DashCat/issues\n\nE-Mail: lucas6.zju@vip.163.com","fr":"Auteur : Lucas\n\nSignalement de bugs et demandes de fonctionnalités :\nhttps://github.com/vivalucas/DashCat/issues\n\nE-mail : lucas6.zju@vip.163.com","ru":"Автор: Lucas\n\nОтчёты об ошибках и запросы функций:\nhttps://github.com/vivalucas/DashCat/issues\n\nEmail: lucas6.zju@vip.163.com"],
        "quit":         ["zh":"退出 DashCat","en":"Quit DashCat","ja":"DashCatを終了",     "ko":"DashCat 종료","de":"DashCat beenden",           "fr":"Quitter DashCat",      "ru":"Выйти из DashCat"],
        "updateFail":     ["zh":"无法检查更新",       "en":"Could not check for updates",         "ja":"アップデートを確認できませんでした",       "ko":"업데이트를 확인할 수 없습니다",           "de":"Updates konnten nicht überprüft werden",          "fr":"Impossible de vérifier les mises à jour",       "ru":"Не удалось проверить обновления"],
        "updateFailMsg":  ["zh":"请检查网络连接后重试。","en":"Please check your internet connection and try again.","ja":"ネットワーク接続を確認して、もう一度お試しください。","ko":"네트워크 연결을 확인하고 다시 시도해 주세요.","de":"Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.","fr":"Veuillez vérifier votre connexion Internet et réessayer.","ru":"Проверьте подключение к интернету и попробуйте снова."],
        "updateAvail":    ["zh":"发现新版本",         "en":"New Version Available",               "ja":"新しいバージョンがあります",             "ko":"새로운 버전이 있습니다",                 "de":"Neue Version verfügbar",                          "fr":"Nouvelle version disponible",                   "ru":"Доступна новая версия"],
        "updateAvailMsg": ["zh":"DashCat %@ 可用。当前版本为 %@。","en":"DashCat %@ is available. You have %@.","ja":"DashCat %@ が利用可能です。現在のバージョンは %@ です。","ko":"DashCat %@ 사용 가능합니다. 현재 버전은 %@입니다.","de":"DashCat %@ ist verfügbar. Sie haben %@.","fr":"DashCat %@ est disponible. Vous avez %@.","ru":"DashCat %@ доступна. У вас установлена %@."],
        "download":       ["zh":"下载",               "en":"Download",                            "ja":"ダウンロード",                           "ko":"다운로드",                               "de":"Herunterladen",                                   "fr":"Télécharger",                                   "ru":"Скачать"],
        "later":          ["zh":"稍后",               "en":"Later",                               "ja":"後で",                                  "ko":"나중에",                                 "de":"Später",                                         "fr":"Plus tard",                                     "ru":"Позже"],
        "updateOk":       ["zh":"已是最新版本",       "en":"You're up to date",                   "ja":"最新バージョンです",                     "ko":"최신 버전입니다",                         "de":"Sie sind auf dem neuesten Stand",                 "fr":"Vous êtes à jour",                              "ru":"Установлена последняя версия"],
        "updateOkMsg":    ["zh":"DashCat %@ 是最新版本。","en":"DashCat %@ is the latest version.","ja":"DashCat %@ は最新バージョンです。","ko":"DashCat %@는 최신 버전입니다.","de":"DashCat %@ ist die neueste Version.","fr":"DashCat %@ est la dernière version.","ru":"DashCat %@ — последняя версия."],
    ]

    func str(_ key: String) -> String {
        Language.table[key]?[rawValue] ?? Language.table[key]?["en"] ?? key
    }
}

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()

    // Cat animation frames
    private lazy var defaultFrames: [NSImage] = makeFrames(tint: nil)
    private lazy var blueFrames:    [NSImage] = makeFrames(tint: .systemBlue)
    private lazy var orangeFrames:  [NSImage] = makeFrames(tint: .systemOrange)

    private var currentFrames: [NSImage] {
        switch caffeineMode {
        case .off:            return defaultFrames
        case .noSleep:        return blueFrames
        case .noDisplaySleep: return orangeFrames
        }
    }

    private func makeFrames(tint: NSColor?) -> [NSImage] {
        let size = NSSize(width: 28, height: 18)
        let frames: [NSImage] = (0..<5).compactMap { i in
            guard let src = NSImage(named: "cat_page\(i)") else { return nil }
            guard let tint else {
                guard let img = src.copy() as? NSImage else { return nil }
                img.size = size
                return img
            }
            let out = NSImage(size: size, flipped: false) { rect in
                src.draw(in: rect, from: .zero, operation: .sourceOver,
                         fraction: 1.0, respectFlipped: true, hints: nil)
                tint.setFill()
                rect.fill(using: .sourceAtop)
                return true
            }
            out.isTemplate = false
            return out
        }
        if !frames.isEmpty { return frames }
        let fallback = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil)
            ?? NSImage(size: size, flipped: false) { _ in true }
        fallback.size = size
        return [fallback]
    }

    private var index = 0
    private let monitor = SystemMonitor()
    private var metric: MonitorInfo = SystemMonitor.default
    private var cpuTimer: Timer?
    private var runnerTimer: Timer?
    private var displayMode: DisplayMode = .both
    private var currentMode: MonitorMode = .combined
    private var caffeineMode: CaffeineMode = .off
    private var sleepAssertionID: IOPMAssertionID = 0

    // Clipboard panel
    private var clipboardPanel: ClipboardPanel?

    // Menu item references
    private var monitorHeader: NSMenuItem!
    private var modeItems: [NSMenuItem] = []
    private var displayMenu: NSMenuItem!
    private var displayModeItems: [NSMenuItem] = []
    private var sleepHeader: NSMenuItem!
    private var caffeineItems: [NSMenuItem] = []
    private var clipboardHeader: NSMenuItem!
    private var saveImagesItem: NSMenuItem!
    private var historyMenuItem: NSMenuItem!
    private var historyDaysItems: [NSMenuItem] = []
    private var customDaysItem: NSMenuItem!
    private var clearHistoryItem: NSMenuItem!
    private var languageMenuItem: NSMenuItem!
    private var languageItems: [NSMenuItem] = []
    private var launchAtLoginItem: NSMenuItem!
    private var helpMenuItem: NSMenuItem!
    private var checkUpdatesItem: NSMenuItem!
    private var viewGitHubItem: NSMenuItem!
    private var contactItem: NSMenuItem!
    private var quitItem: NSMenuItem!

    private var language: Language = {
        if let saved = UserDefaults.standard.string(forKey: "DashCatLanguage"),
           let lang = Language(rawValue: saved) { return lang }
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Language(rawValue: code) ?? .english
    }()

    private var historyDays: HistoryDays {
        let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
        if saved == 0 { return .thirty }
        return HistoryDays(rawValue: saved) ?? .thirty
    }

    private var customHistoryDays: Int? {
        get {
            let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
            if saved == 0 { return nil }
            return HistoryDays(rawValue: saved) == nil ? saved : nil
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: "DashCatHistoryDays")
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Migrate from CatMeter if needed
        migrateFromCatMeter()
        migrateDisplayMode()

        setupMenu()
        setupStatusItem()
        setupSleepWakeNotifications()
        startRunning()

        // Start clipboard monitoring (cleanupExpired runs inside ClipboardManager.init)
        ClipboardManager.shared.startPolling()

        restoreState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        clipboardPanel?.close()
        clipboardPanel = nil
        stopRunning()
        ClipboardManager.shared.stopPolling()
        if sleepAssertionID != 0 { IOPMAssertionRelease(sleepAssertionID) }
    }

    private func migrateFromCatMeter() {
        // Migrate CatMeter language setting if present
        if UserDefaults.standard.string(forKey: "DashCatLanguage") == nil,
           let catLang = UserDefaults.standard.string(forKey: "CatMeterLanguage") {
            UserDefaults.standard.set(catLang, forKey: "DashCatLanguage")
        }
    }

    private func migrateDisplayMode() {
        let newKey = "DashCatDisplayMode"
        guard UserDefaults.standard.string(forKey: newKey) == nil else { return }
        let oldKey = "DashCatShowPercentage"
        if UserDefaults.standard.object(forKey: oldKey) != nil {
            let old = UserDefaults.standard.bool(forKey: oldKey)
            UserDefaults.standard.set(old ? DisplayMode.both.rawValue : DisplayMode.animOnly.rawValue,
                                      forKey: newKey)
            UserDefaults.standard.removeObject(forKey: oldKey)
        }
    }

    private func setupStatusItem() {
        statusItem.behavior = []
        statusItem.button?.imagePosition = .imageTrailing
        statusItem.button?.image = defaultFrames.first
        statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusItem.button?.action = #selector(buttonClicked(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        menu.delegate = self

        // Monitor section
        monitorHeader = makeHeader()
        menu.addItem(monitorHeader)
        for mode in MonitorMode.allCases {
            let item = NSMenuItem(title: "", action: #selector(selectMode(_:)), keyEquivalent: "")
            item.representedObject = mode
            item.indentationLevel = 1
            modeItems.append(item)
            menu.addItem(item)
        }
        modeItems.first?.state = .on

        // Display submenu (inside Monitor section)
        menu.addItem(.separator())
        displayMenu = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let displaySubmenu = NSMenu()
        for mode in DisplayMode.allCases {
            let item = NSMenuItem(title: "", action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
            item.representedObject = mode
            item.indentationLevel = 1
            displayModeItems.append(item)
            displaySubmenu.addItem(item)
        }
        displayMenu.submenu = displaySubmenu
        displayMenu.indentationLevel = 1
        menu.addItem(displayMenu)

        menu.addItem(.separator())

        // Sleep Prevention section
        sleepHeader = makeHeader()
        menu.addItem(sleepHeader)
        for mode in CaffeineMode.allCases {
            let item = NSMenuItem(title: "", action: #selector(selectCaffeineMode(_:)), keyEquivalent: "")
            item.representedObject = mode
            item.indentationLevel = 1
            caffeineItems.append(item)
            menu.addItem(item)
        }
        caffeineItems.first?.state = .on

        menu.addItem(.separator())

        // Clipboard section
        clipboardHeader = makeHeader()
        menu.addItem(clipboardHeader)

        saveImagesItem = NSMenuItem(title: "", action: #selector(toggleSaveImages(_:)), keyEquivalent: "")
        saveImagesItem.indentationLevel = 1
        saveImagesItem.state = UserDefaults.standard.bool(forKey: "DashCatSaveImages") ? .on : .off
        menu.addItem(saveImagesItem)

        // History days submenu
        historyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let historySubmenu = NSMenu()
        for days in HistoryDays.allCases {
            let item = NSMenuItem(title: "", action: #selector(selectHistoryDays(_:)), keyEquivalent: "")
            item.representedObject = days
            item.indentationLevel = 1
            if customHistoryDays == nil && days == historyDays { item.state = .on }
            historyDaysItems.append(item)
            historySubmenu.addItem(item)
        }
        historySubmenu.addItem(.separator())
        customDaysItem = NSMenuItem(title: "", action: #selector(selectCustomDays(_:)), keyEquivalent: "")
        historySubmenu.addItem(customDaysItem)
        historyMenuItem.submenu = historySubmenu
        historyMenuItem.indentationLevel = 1
        menu.addItem(historyMenuItem)

        menu.addItem(.separator())

        clearHistoryItem = NSMenuItem(title: "", action: #selector(clearClipboardHistory(_:)), keyEquivalent: "")
        clearHistoryItem.indentationLevel = 1
        menu.addItem(clearHistoryItem)

        menu.addItem(.separator())

        // Language submenu — title stays fixed so users can always find it
        languageMenuItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        let langSubmenu = NSMenu()
        for lang in Language.allCases {
            let item = NSMenuItem(title: lang.displayName,
                                  action: #selector(selectLanguage(_:)),
                                  keyEquivalent: "")
            item.representedObject = lang
            if lang == language { item.state = .on }
            languageItems.append(item)
            langSubmenu.addItem(item)
        }
        languageMenuItem.submenu = langSubmenu
        menu.addItem(languageMenuItem)

        menu.addItem(.separator())

        // Launch at Login
        launchAtLoginItem = NSMenuItem(title: "", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.state = UserDefaults.standard.bool(forKey: "DashCatLaunchAtLogin") ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        // Help & Updates submenu
        helpMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let helpSubmenu = NSMenu()
        checkUpdatesItem = NSMenuItem(title: "", action: #selector(checkForUpdates), keyEquivalent: "")
        viewGitHubItem   = NSMenuItem(title: "", action: #selector(openGitHub),      keyEquivalent: "")
        contactItem      = NSMenuItem(title: "", action: #selector(showContact),     keyEquivalent: "")
        helpSubmenu.addItem(checkUpdatesItem)
        helpSubmenu.addItem(viewGitHubItem)
        helpSubmenu.addItem(.separator())
        helpSubmenu.addItem(contactItem)
        helpMenuItem.submenu = helpSubmenu
        menu.addItem(helpMenuItem)

        menu.addItem(.separator())

        // Quit
        quitItem = NSMenuItem(title: "", action: #selector(terminateApp(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        applyLanguage()
    }

    private func makeHeader() -> NSMenuItem {
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func applyLanguage() {
        let l = language
        monitorHeader.title = l.str("monitor")
        for item in modeItems {
            if let mode = item.representedObject as? MonitorMode {
                item.title = l.str(mode.locKey)
            }
        }
        displayMenu.title = l.str("display")
        for item in displayModeItems {
            if let mode = item.representedObject as? DisplayMode {
                item.title = l.str(mode.locKey)
            }
        }
        sleepHeader.title = l.str("sleep")
        for item in caffeineItems {
            if let mode = item.representedObject as? CaffeineMode {
                item.title = l.str(mode.locKey)
            }
        }
        clipboardHeader.title   = l.str("clipboard")
        saveImagesItem.title    = l.str("saveImages")
        historyMenuItem.title   = l.str("history")
        for item in historyDaysItems {
            if let days = item.representedObject as? HistoryDays {
                item.title = l.str(days.locKey)
            }
        }
        if let custom = customHistoryDays {
            customDaysItem.title = "\(l.str("customDays")) (\(custom))"
        } else {
            customDaysItem.title = l.str("customDays")
        }
        clearHistoryItem.title  = l.str("clearHistory")
        // Language menu title stays fixed so users can always find it
        launchAtLoginItem.title = l.str("launchLogin")
        helpMenuItem.title      = l.str("help")
        checkUpdatesItem.title  = l.str("checkUpdates")
        viewGitHubItem.title    = l.str("viewOnGitHub")
        contactItem.title       = l.str("contact")
        quitItem.title          = l.str("quit")
    }

    // MARK: - Button

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        } else {
            // Left click: toggle clipboard panel
            if clipboardPanel == nil {
                clipboardPanel = ClipboardPanel()
                clipboardPanel?.statusItem = statusItem
            }
            clipboardPanel?.toggle()
        }
    }

    // MARK: - Caffeine

    private func applyCaffeineMode(_ mode: CaffeineMode) {
        if sleepAssertionID != 0 {
            IOPMAssertionRelease(sleepAssertionID)
            sleepAssertionID = 0
        }
        caffeineMode = mode
        if let type = mode.assertionType {
            let ret = IOPMAssertionCreateWithName(type,
                                                  IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                  "DashCat" as CFString,
                                                  &sleepAssertionID)
            if ret != kIOReturnSuccess { sleepAssertionID = 0 }
        }
        caffeineItems.forEach { $0.state = ($0.representedObject as? CaffeineMode) == mode ? .on : .off }
        let frames = currentFrames
        statusItem.button?.image = frames[index % frames.count]
        UserDefaults.standard.set(mode.rawValue, forKey: "DashCatCaffeineMode")
    }

    // MARK: - Menu Actions

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? DisplayMode else { return }
        displayMode = mode
        displayModeItems.forEach { $0.state = ($0.representedObject as? DisplayMode) == mode ? .on : .off }
        UserDefaults.standard.set(mode.rawValue, forKey: "DashCatDisplayMode")
        switch mode {
        case .pctOnly:
            statusItem.button?.image = nil
            applyMetricDisplay()
        case .animOnly:
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString()
            let frames = currentFrames
            statusItem.button?.image = frames[index % frames.count]
        case .both:
            applyMetricDisplay()
            let frames = currentFrames
            statusItem.button?.image = frames[index % frames.count]
        }
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? MonitorMode else { return }
        currentMode = mode
        modeItems.forEach { $0.state = ($0.representedObject as? MonitorMode) == mode ? .on : .off }
        UserDefaults.standard.set(mode.rawValue, forKey: "DashCatMonitorMode")
        updateMetric()
    }

    @objc private func selectCaffeineMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? CaffeineMode else { return }
        applyCaffeineMode(mode)
    }

    @objc private func toggleSaveImages(_ sender: NSMenuItem) {
        let newValue = sender.state == .off
        sender.state = newValue ? .on : .off
        UserDefaults.standard.set(newValue, forKey: "DashCatSaveImages")
    }

    @objc private func selectHistoryDays(_ sender: NSMenuItem) {
        guard let days = sender.representedObject as? HistoryDays else { return }
        UserDefaults.standard.set(days.rawValue, forKey: "DashCatHistoryDays")
        historyDaysItems.forEach { $0.state = ($0.representedObject as? HistoryDays) == days ? .on : .off }
        customDaysItem.title = language.str("customDays")
        cleanupClipboardHistoryAfterRetentionChange()
    }

    @objc private func selectCustomDays(_ sender: NSMenuItem) {
        let l = language
        let alert = NSAlert()
        alert.messageText = l.str("customDays")
        alert.informativeText = l.str("customDaysPrompt")
        alert.addButton(withTitle: l.str("ok"))
        alert.addButton(withTitle: l.str("cancel"))

        let currentDays = customHistoryDays ?? historyDays.rawValue
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        input.stringValue = "\(currentDays)"
        alert.accessoryView = input

        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            let days = max(1, min(365, Int(input.stringValue) ?? 30))
            UserDefaults.standard.set(days, forKey: "DashCatHistoryDays")
            historyDaysItems.forEach { $0.state = .off }
            customDaysItem.title = "\(l.str("customDays")) (\(days))"
            cleanupClipboardHistoryAfterRetentionChange()
        }
    }

    private func cleanupClipboardHistoryAfterRetentionChange() {
        ClipboardManager.shared.cleanupExpired()
        clipboardPanel?.reloadData()
    }

    @objc private func clearClipboardHistory(_ sender: NSMenuItem) {
        ClipboardManager.shared.clearAll()
        clipboardPanel?.reloadData()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? Language else { return }
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "DashCatLanguage")
        languageItems.forEach { $0.state = ($0.representedObject as? Language) == lang ? .on : .off }
        applyLanguage()
        clipboardPanel?.refreshLocale()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newValue = sender.state == .off
        do {
            if newValue {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("DashCat launch at login update failed: \(error.localizedDescription)")
        }
        refreshLaunchAtLoginState()
    }

    private func refreshLaunchAtLoginState() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        launchAtLoginItem.state = isEnabled ? .on : .off
        UserDefaults.standard.set(isEnabled, forKey: "DashCatLaunchAtLogin")
    }

    @objc private func terminateApp(_ sender: Any?) { NSApp.terminate(nil) }
    @objc private func receiveSleep() {
        stopRunning()
        ClipboardManager.shared.stopPolling()
    }
    @objc private func receiveWakeUp() {
        startRunning()
        ClipboardManager.shared.startPolling()
    }

    // MARK: - Sleep/Wake

    private func setupSleepWakeNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(receiveSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(receiveWakeUp),
                       name: NSWorkspace.didWakeNotification, object: nil)
    }

    // MARK: - Timers

    private func startRunning() {
        cpuTimer?.invalidate()
        cpuTimer = Timer(timeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMetric()
        }
        if let timer = cpuTimer {
            RunLoop.main.add(timer, forMode: .common)
            timer.fire()
        }
    }

    private func stopRunning() {
        runnerTimer?.invalidate()
        cpuTimer?.invalidate()
        runnerTimer = nil
        cpuTimer = nil
    }

    private func updateMetric() {
        switch currentMode {
        case .cpu:
            metric = monitor.cpuUsage()
        case .memory:
            metric = monitor.memoryPressure()
        case .combined:
            let cpu = monitor.cpuUsage()
            let mem = monitor.memoryPressure()
            if cpu.value >= mem.value {
                metric = MonitorInfo(cpu.value, "C" + cpu.description)
            } else {
                metric = MonitorInfo(mem.value, "M" + mem.description)
            }
        }

        let t = min(metric.value / 100.0, 1.0)
        let fps = 1.0 + 11.0 * t
        let interval = 1.0 / fps
        applyMetricDisplay()
        runnerTimer?.invalidate()
        runnerTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.nextFrame()
        }
        if let timer = runnerTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func nextFrame() {
        guard displayMode != .pctOnly else { return }
        let frames = currentFrames
        index = (index + 1) % frames.count
        statusItem.button?.image = frames[index]
    }

    // MARK: - Display

    private func applyMetricDisplay() {
        guard displayMode != .animOnly else {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString()
            return
        }
        if currentMode == .combined {
            statusItem.button?.attributedTitle = makeStackedTitle(metric.description)
        } else {
            statusItem.button?.title = metric.description
        }
    }

    private func makeStackedTitle(_ description: String) -> NSAttributedString {
        let label = String(description.prefix(1))
        let value = String(description.dropFirst()).trimmingCharacters(in: .whitespaces)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 0
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: value + "\n", attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
            .paragraphStyle: para
        ]))
        result.append(NSAttributedString(string: label, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 7, weight: .regular),
            .paragraphStyle: para
        ]))
        return result
    }

    // MARK: - Check for Updates

    @objc private func checkForUpdates() {
        let url = URL(string: "https://api.github.com/repos/vivalucas/DashCat/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("DashCat/\(bundleVersion)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async { self?.handleUpdateResponse(data: data, error: error) }
        }.resume()
    }

    private var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private func handleUpdateResponse(data: Data?, error: Error?) {
        let l = language
        guard error == nil,
              let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else {
            presentAlert(title: l.str("updateFail"),
                         message: l.str("updateFailMsg"))
            return
        }
        let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let local  = bundleVersion
        if isNewerVersion(remote, than: local) {
            let alert = NSAlert()
            alert.messageText     = l.str("updateAvail")
            alert.informativeText = String(format: l.str("updateAvailMsg"), remote, local)
            alert.addButton(withTitle: l.str("download"))
            alert.addButton(withTitle: l.str("later"))
            NSApp.activate()
            if alert.runModal() == .alertFirstButtonReturn { openGitHub() }
        } else {
            presentAlert(title: l.str("updateOk"),
                         message: String(format: l.str("updateOkMsg"), local))
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText     = title
        alert.informativeText = message
        NSApp.activate()
        _ = alert.runModal()
    }

    private func isNewerVersion(_ remote: String, than local: String) -> Bool {
        let parseVersion: (String) -> [Int] = { s in
            s.split(separator: ".").compactMap { Int($0.prefix(while: { $0.isNumber })) }
        }
        let r = parseVersion(remote)
        let l = parseVersion(local)
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }

    @objc private func openGitHub() {
        NSWorkspace.shared.open(URL(string: "https://github.com/vivalucas/DashCat")!)
    }

    @objc private func showContact() {
        let l = language
        let alert = NSAlert()
        alert.messageText = l.str("contactTitle")
        alert.informativeText = l.str("contactBody")
        alert.addButton(withTitle: l.str("ok"))
        NSApp.activate()
        _ = alert.runModal()
    }

    // MARK: - Restore State

    private func restoreState() {
        // Restore monitor mode
        if let modeStr = UserDefaults.standard.string(forKey: "DashCatMonitorMode"),
           let mode = MonitorMode(rawValue: modeStr) {
            currentMode = mode
            modeItems.forEach { $0.state = ($0.representedObject as? MonitorMode) == mode ? .on : .off }
        }
        // Restore display mode (default: .both)
        if let modeStr = UserDefaults.standard.string(forKey: "DashCatDisplayMode"),
           let mode = DisplayMode(rawValue: modeStr) {
            displayMode = mode
        }
        displayModeItems.forEach { $0.state = ($0.representedObject as? DisplayMode) == displayMode ? .on : .off }
        switch displayMode {
        case .pctOnly:
            statusItem.button?.image = nil
            applyMetricDisplay()
        case .animOnly:
            break // image already set in setupStatusItem
        case .both:
            applyMetricDisplay()
        }
        // Restore caffeine mode
        let caffeineRaw = UserDefaults.standard.integer(forKey: "DashCatCaffeineMode")
        if let mode = CaffeineMode(rawValue: caffeineRaw), mode != .off {
            applyCaffeineMode(mode)
        }
        // Restore custom history days display
        if let custom = customHistoryDays {
            historyDaysItems.forEach { $0.state = .off }
            customDaysItem.title = "\(language.str("customDays")) (\(custom))"
        }
        refreshLaunchAtLoginState()
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        refreshLaunchAtLoginState()
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}
