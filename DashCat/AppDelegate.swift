import Cocoa
import IOKit.pwr_mgt
import ServiceManagement

// MARK: - MonitorMode

enum MonitorMode: String, CaseIterable {
    case combined     = "Combined"
    case cpu          = "CPU"
    case memory       = "Memory"
    case cpuAndMemory = "CPU + Memory"

    var locKey: String {
        switch self {
        case .combined:     return "combined"
        case .cpu:          return "cpu"
        case .memory:       return "memory"
        case .cpuAndMemory: return "cpuAndMemory"
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
    case traditionalChinese = "zh-TW"
    case english  = "en"
    case japanese = "ja"
    case korean   = "ko"
    case german   = "de"
    case french   = "fr"
    case spanish  = "es"
    case portugueseBrazil = "pt-BR"
    case italian  = "it"
    case russian  = "ru"

    var displayName: String {
        switch self {
        case .chinese:  return "中文"
        case .traditionalChinese: return "繁體中文"
        case .english:  return "English"
        case .japanese: return "日本語"
        case .korean:   return "한국어"
        case .german:   return "Deutsch"
        case .french:   return "Français"
        case .spanish:  return "Español"
        case .portugueseBrazil: return "Português"
        case .italian:  return "Italiano"
        case .russian:  return "Русский"
        }
    }

    private static let table: [String: [String: String]] = [
        "monitor":      ["zh":"监控",       "zh-TW":"監控",     "en":"Monitor",          "ja":"モニター",             "ko":"모니터",        "de":"Monitor",                     "fr":"Moniteur",               "es":"Monitor",                "pt-BR":"Monitor",             "it":"Monitor",                "ru":"Монитор"],
        "combined":     ["zh":"综合",       "zh-TW":"綜合",     "en":"Combined",         "ja":"総合",                 "ko":"종합",          "de":"Kombiniert",                  "fr":"Combiné",                "es":"Combinado",              "pt-BR":"Combinado",           "it":"Combinato",              "ru":"Комбинированный"],
        "cpu":          ["zh":"CPU",        "zh-TW":"CPU",      "en":"CPU",              "ja":"CPU",                  "ko":"CPU",           "de":"CPU",                         "fr":"CPU",                    "es":"CPU",                    "pt-BR":"CPU",                 "it":"CPU",                    "ru":"CPU"],
        "memory":       ["zh":"内存",       "zh-TW":"記憶體",   "en":"Memory",           "ja":"メモリ",               "ko":"메모리",        "de":"Speicher",                    "fr":"Mémoire",                "es":"Memoria",                "pt-BR":"Memória",             "it":"Memoria",                "ru":"Память"],
        "cpuAndMemory": ["zh":"CPU + 内存", "zh-TW":"CPU + 記憶體","en":"CPU + Memory",    "ja":"CPU + メモリ",         "ko":"CPU + 메모리",  "de":"CPU + Speicher",             "fr":"CPU + mémoire",          "es":"CPU + memoria",          "pt-BR":"CPU + memória",       "it":"CPU + memoria",          "ru":"CPU + память"],
        "sleep":        ["zh":"阻止休眠",   "zh-TW":"防止休眠", "en":"Sleep Prevention", "ja":"スリープ防止",         "ko":"절전 방지",     "de":"Ruhezustand verhindern",      "fr":"Prévention de veille",   "es":"Prevención de suspensión","pt-BR":"Prevenção de suspensão","it":"Prevenzione sospensione","ru":"Предотвращение сна"],
        "sleepOff":     ["zh":"关闭",       "zh-TW":"關閉",     "en":"Off",              "ja":"オフ",                 "ko":"끔",            "de":"Aus",                         "fr":"Désactivé",              "es":"Desactivado",            "pt-BR":"Desativado",          "it":"Disattivato",            "ru":"Выкл"],
        "sleepSystem":  ["zh":"阻止系统休眠","zh-TW":"防止系統休眠","en":"Prevent System Sleep","ja":"システムスリープを防止","ko":"시스템 절전 방지","de":"System-Ruhezustand verhindern","fr":"Empêcher la veille du système","es":"Evitar suspensión del sistema","pt-BR":"Evitar suspensão do sistema","it":"Impedisci sospensione sistema","ru":"Предотвратить сон системы"],
        "sleepDisplay": ["zh":"阻止屏幕休眠","zh-TW":"防止螢幕休眠","en":"Prevent Display Sleep","ja":"ディスプレイスリープを防止","ko":"화면 절전 방지","de":"Display-Ruhezustand verhindern","fr":"Empêcher la veille de l'écran","es":"Evitar suspensión de pantalla","pt-BR":"Evitar suspensão da tela","it":"Impedisci sospensione schermo","ru":"Предотвратить сон экрана"],
        "display":       ["zh":"显示",      "zh-TW":"顯示",    "en":"Display",           "ja":"表示",                "ko":"표시",           "de":"Anzeige",                     "fr":"Affichage",              "es":"Visualización",          "pt-BR":"Exibição",            "it":"Visualizzazione",       "ru":"Отображение"],
        "displayBoth":   ["zh":"数值与动画","zh-TW":"數值與動畫","en":"Percentage & Animation","ja":"数値とアニメーション","ko":"백분율 및 애니메이션","de":"Prozentwert & Animation","fr":"Pourcentage & animation","es":"Porcentaje y animación","pt-BR":"Porcentagem e animação","it":"Percentuale e animazione","ru":"Процент и анимация"],
        "displayAnimOnly":["zh":"仅动画",   "zh-TW":"僅動畫",   "en":"Animation Only",    "ja":"アニメーションのみ",   "ko":"애니메이션만",   "de":"Nur Animation",               "fr":"Animation uniquement",   "es":"Solo animación",        "pt-BR":"Apenas animação",     "it":"Solo animazione",       "ru":"Только анимация"],
        "displayPctOnly":["zh":"仅数值",    "zh-TW":"僅數值",   "en":"Percentage Only",   "ja":"数値のみ",             "ko":"백분율만",       "de":"Nur Prozentwert",             "fr":"Pourcentage uniquement", "es":"Solo porcentaje",       "pt-BR":"Apenas porcentagem",  "it":"Solo percentuale",       "ru":"Только процент"],
        "clipboard":    ["zh":"剪贴板",     "zh-TW":"剪貼簿",   "en":"Clipboard",        "ja":"クリップボード",       "ko":"클립보드",      "de":"Zwischenablage",              "fr":"Presse-papiers",         "es":"Portapapeles",           "pt-BR":"Área de Transferência","it":"Appunti",               "ru":"Буфер обмена"],
        "language":     ["zh":"语言",       "zh-TW":"語言",     "en":"Language",         "ja":"言語",                 "ko":"언어",          "de":"Sprache",                     "fr":"Langue",                 "es":"Idioma",                 "pt-BR":"Idioma",              "it":"Lingua",                 "ru":"Язык"],
        "saveImages":   ["zh":"保存图片",   "zh-TW":"儲存圖片", "en":"Save Images",      "ja":"画像を保存",           "ko":"이미지 저장",   "de":"Bilder speichern",            "fr":"Enregistrer les images", "es":"Guardar imágenes",       "pt-BR":"Salvar imagens",      "it":"Salva immagini",         "ru":"Сохранять изображения"],
        "history":      ["zh":"历史记录",   "zh-TW":"歷史記錄", "en":"History",          "ja":"履歴",                 "ko":"기록",          "de":"Verlauf",                     "fr":"Historique",             "es":"Historial",              "pt-BR":"Histórico",           "it":"Cronologia",             "ru":"История"],
        "days7":        ["zh":"7 天",       "zh-TW":"7 天",     "en":"7 Days",           "ja":"7日",                  "ko":"7일",           "de":"7 Tage",                      "fr":"7 jours",                "es":"7 días",                 "pt-BR":"7 dias",              "it":"7 giorni",              "ru":"7 дней"],
        "days14":       ["zh":"14 天",      "zh-TW":"14 天",    "en":"14 Days",          "ja":"14日",                 "ko":"14일",          "de":"14 Tage",                     "fr":"14 jours",               "es":"14 días",                "pt-BR":"14 dias",             "it":"14 giorni",              "ru":"14 дней"],
        "days30":       ["zh":"30 天",      "zh-TW":"30 天",    "en":"30 Days",          "ja":"30日",                 "ko":"30일",          "de":"30 Tage",                     "fr":"30 jours",               "es":"30 días",                "pt-BR":"30 dias",             "it":"30 giorni",              "ru":"30 дней"],
        "days90":       ["zh":"90 天",      "zh-TW":"90 天",    "en":"90 Days",          "ja":"90日",                 "ko":"90일",          "de":"90 Tage",                     "fr":"90 jours",               "es":"90 días",                "pt-BR":"90 dias",             "it":"90 giorni",              "ru":"90 дней"],
        "forever":      ["zh":"永久",       "zh-TW":"永久",     "en":"Forever",          "ja":"無期限",               "ko":"영구",          "de":"Unbegrenzt",                  "fr":"Illimité",               "es":"Para siempre",           "pt-BR":"Para sempre",         "it":"Per sempre",             "ru":"Навсегда"],
        "customDays":   ["zh":"自定义\u{2026}","zh-TW":"自訂\u{2026}","en":"Custom\u{2026}","ja":"カスタム\u{2026}","ko":"사용자 정의\u{2026}","de":"Benutzerdefiniert\u{2026}","fr":"Personnalisé\u{2026}","es":"Personalizado\u{2026}","pt-BR":"Personalizado\u{2026}","it":"Personalizzato\u{2026}","ru":"Пользовательский\u{2026}"],
        "search":       ["zh":"搜索\u{2026}",   "zh-TW":"搜尋\u{2026}",  "en":"Search\u{2026}",  "ja":"検索\u{2026}",         "ko":"검색\u{2026}",      "de":"Suchen\u{2026}",              "fr":"Rechercher\u{2026}",      "es":"Buscar\u{2026}",         "pt-BR":"Pesquisar\u{2026}",   "it":"Cerca\u{2026}",          "ru":"Поиск\u{2026}"],
        "image":        ["zh":"图片",       "zh-TW":"圖片",     "en":"Image",           "ja":"画像",                 "ko":"이미지",            "de":"Bild",                        "fr":"Image",                  "es":"Imagen",                 "pt-BR":"Imagem",              "it":"Immagine",               "ru":"Изображение"],
        "pin":          ["zh":"固定",       "zh-TW":"釘選",     "en":"Pin",             "ja":"ピン",                 "ko":"고정",              "de":"Anheften",                    "fr":"Épingler",               "es":"Fijar",                  "pt-BR":"Fixar",               "it":"Fissa",                  "ru":"Закрепить"],
        "unpin":        ["zh":"取消固定",   "zh-TW":"取消釘選", "en":"Unpin",           "ja":"ピン解除",             "ko":"고정 해제",         "de":"Lösen",                       "fr":"Détacher",               "es":"Desfijar",               "pt-BR":"Desafixar",           "it":"Rimuovi fissaggio",      "ru":"Открепить"],
        "delete":       ["zh":"删除",       "zh-TW":"刪除",     "en":"Delete",          "ja":"削除",                 "ko":"삭제",              "de":"Löschen",                     "fr":"Supprimer",              "es":"Eliminar",               "pt-BR":"Excluir",             "it":"Elimina",                "ru":"Удалить"],
        "customDaysPrompt":["zh":"输入天数 (1-365)：","zh-TW":"輸入天數 (1-365)：","en":"Enter number of days (1-365):","ja":"日数を入力 (1-365)：","ko":"일수 입력 (1-365)：","de":"Anzahl der Tage eingeben (1-365):","fr":"Entrez le nombre de jours (1-365) :","es":"Ingrese número de días (1-365):","pt-BR":"Digite o número de dias (1-365):","it":"Inserisci il numero di giorni (1-365):","ru":"Введите количество дней (1-365):"],
        "reverseMouseScroll":["zh":"反转鼠标滚轮","zh-TW":"反轉滑鼠滾輪","en":"Reverse Mouse Wheel","ja":"マウスホイールを反転","ko":"마우스 휠 반전","de":"Mausrad umkehren","fr":"Inverser la molette","es":"Invertir rueda del mouse","pt-BR":"Inverter roda do mouse","it":"Inverti rotella mouse","ru":"Инвертировать колесо мыши"],
        "accessibilityNeeded":["zh":"需要辅助功能权限","zh-TW":"需要輔助使用權限","en":"Accessibility Permission Required","ja":"アクセシビリティ権限が必要","ko":"손쉬운 사용 권한 필요","de":"Bedienungshilfen-Berechtigung erforderlich","fr":"Autorisation Accessibilité requise","es":"Se requiere permiso de Accesibilidad","pt-BR":"Permissão de Acessibilidade necessária","it":"Permesso Accessibilità richiesto","ru":"Требуется разрешение Универсального доступа"],
        "openAccessibility":["zh":"前往授权\u{2026}","zh-TW":"前往授權\u{2026}","en":"Open System Settings\u{2026}","ja":"システム設定を開く\u{2026}","ko":"시스템 설정 열기\u{2026}","de":"Systemeinstellungen öffnen\u{2026}","fr":"Ouvrir les Réglages Système\u{2026}","es":"Abrir Ajustes del Sistema\u{2026}","pt-BR":"Abrir Ajustes do Sistema\u{2026}","it":"Apri Impostazioni di Sistema\u{2026}","ru":"Открыть Системные настройки\u{2026}"],
        "ok":           ["zh":"确定",       "zh-TW":"確定",     "en":"OK",              "ja":"OK",                   "ko":"확인",              "de":"OK",                          "fr":"OK",                     "es":"OK",                     "pt-BR":"OK",                  "it":"OK",                     "ru":"OK"],
        "cancel":       ["zh":"取消",       "zh-TW":"取消",     "en":"Cancel",          "ja":"キャンセル",           "ko":"취소",              "de":"Abbrechen",                   "fr":"Annuler",                "es":"Cancelar",               "pt-BR":"Cancelar",            "it":"Annulla",                "ru":"Отмена"],
        "clearHistory": ["zh":"清除历史",   "zh-TW":"清除歷史", "en":"Clear History",    "ja":"履歴をクリア",         "ko":"기록 지우기",   "de":"Verlauf löschen",             "fr":"Effacer l'historique",   "es":"Borrar historial",       "pt-BR":"Limpar histórico",    "it":"Cancella cronologia",    "ru":"Очистить историю"],
        "launchLogin":  ["zh":"开机启动",   "zh-TW":"登入時啟動", "en":"Launch at Login",  "ja":"ログイン時に起動",     "ko":"로그인 시 시작","de":"Beim Login starten",          "fr":"Lancer au démarrage",    "es":"Abrir al iniciar sesión","pt-BR":"Iniciar ao fazer login","it":"Avvia al login",         "ru":"Запуск при входе"],
        "help":         ["zh":"帮助与更新",   "zh-TW":"幫助與更新", "en":"Help & Updates",   "ja":"ヘルプと更新",         "ko":"도움말 및 업데이트","de":"Hilfe & Updates",            "fr":"Aide et mises à jour",  "es":"Ayuda y actualizaciones","pt-BR":"Ajuda e atualizações","it":"Aiuto e aggiornamenti",  "ru":"Справка и обновления"],
        "checkUpdates": ["zh":"检查更新\u{2026}","zh-TW":"檢查更新\u{2026}","en":"Check for Updates\u{2026}","ja":"アップデートを確認\u{2026}","ko":"업데이트 확인\u{2026}","de":"Nach Updates suchen\u{2026}","fr":"Vérifier les mises à jour\u{2026}","es":"Buscar actualizaciones\u{2026}","pt-BR":"Verificar atualizações\u{2026}","it":"Cerca aggiornamenti\u{2026}","ru":"Проверить обновления\u{2026}"],
        "viewOnGitHub": ["zh":"在 GitHub 上查看","zh-TW":"在 GitHub 上查看","en":"View on GitHub","ja":"GitHubで開く",       "ko":"GitHub에서 보기","de":"Auf GitHub öffnen",          "fr":"Voir sur GitHub",       "es":"Ver en GitHub",          "pt-BR":"Ver no GitHub",       "it":"Vedi su GitHub",         "ru":"Открыть на GitHub"],
        "contact":      ["zh":"联系方式",   "zh-TW":"聯絡方式", "en":"Contact",          "ja":"お問い合わせ",           "ko":"연락처",              "de":"Kontakt",                    "fr":"Contact",                "es":"Contacto",               "pt-BR":"Contato",             "it":"Contatto",               "ru":"Контакты"],
        "contactTitle": ["zh":"DashCat 联系信息","zh-TW":"DashCat 聯絡資訊","en":"DashCat Contact Info","ja":"DashCat 連絡先","ko":"DashCat 연락처 정보","de":"DashCat Kontaktinformationen","fr":"Infos de contact DashCat","es":"Información de contacto de DashCat","pt-BR":"Informações de contato do DashCat","it":"Informazioni di contatto DashCat","ru":"Контактная информация DashCat"],
        "contactBody":  ["zh":"作者：Lucas\n\n功能建议与问题反馈：\nhttps://github.com/vivalucas/DashCat/issues\n\n邮箱：lucas6.zju@vip.163.com","zh-TW":"作者：Lucas\n\n功能建議與問題回饋：\nhttps://github.com/vivalucas/DashCat/issues\n\n電子郵件：lucas6.zju@vip.163.com","en":"Author: Lucas\n\nBug reports & feature requests:\nhttps://github.com/vivalucas/DashCat/issues\n\nEmail: lucas6.zju@vip.163.com","ja":"作者：Lucas\n\nバグ報告・機能リクエスト：\nhttps://github.com/vivalucas/DashCat/issues\n\nメール：lucas6.zju@vip.163.com","ko":"작성자: Lucas\n\n버그 신고 및 기능 요청:\nhttps://github.com/vivalucas/DashCat/issues\n\n이메일: lucas6.zju@vip.163.com","de":"Autor: Lucas\n\nFehlermeldungen & Feature Requests:\nhttps://github.com/vivalucas/DashCat/issues\n\nE-Mail: lucas6.zju@vip.163.com","fr":"Auteur : Lucas\n\nSignalement de bugs et demandes de fonctionnalités :\nhttps://github.com/vivalucas/DashCat/issues\n\nE-mail : lucas6.zju@vip.163.com","es":"Autor: Lucas\n\nInformes de errores y solicitudes de funciones:\nhttps://github.com/vivalucas/DashCat/issues\n\nCorreo: lucas6.zju@vip.163.com","pt-BR":"Autor: Lucas\n\nRelatórios de bugs e solicitações de recursos:\nhttps://github.com/vivalucas/DashCat/issues\n\nE-mail: lucas6.zju@vip.163.com","it":"Autore: Lucas\n\nSegnalazioni bug e richieste funzionalità:\nhttps://github.com/vivalucas/DashCat/issues\n\nEmail: lucas6.zju@vip.163.com","ru":"Автор: Lucas\n\nОтчёты об ошибках и запросы функций:\nhttps://github.com/vivalucas/DashCat/issues\n\nEmail: lucas6.zju@vip.163.com"],
        "quit":         ["zh":"退出 DashCat","zh-TW":"結束 DashCat","en":"Quit DashCat","ja":"DashCatを終了",     "ko":"DashCat 종료","de":"DashCat beenden",           "fr":"Quitter DashCat",      "es":"Salir de DashCat",       "pt-BR":"Sair do DashCat",     "it":"Esci da DashCat",        "ru":"Выйти из DashCat"],
        "updateFail":     ["zh":"无法检查更新",       "zh-TW":"無法檢查更新",       "en":"Could not check for updates",         "ja":"アップデートを確認できませんでした",       "ko":"업데이트를 확인할 수 없습니다",           "de":"Updates konnten nicht überprüft werden",          "fr":"Impossible de vérifier les mises à jour",       "es":"No se pudieron buscar actualizaciones",       "pt-BR":"Não foi possível verificar atualizações",          "it":"Impossibile cercare aggiornamenti",           "ru":"Не удалось проверить обновления"],
        "updateFailMsg":  ["zh":"请检查网络连接后重试。","zh-TW":"請檢查網路連線後重試。","en":"Please check your internet connection and try again.","ja":"ネットワーク接続を確認して、もう一度お試しください。","ko":"네트워크 연결을 확인하고 다시 시도해 주세요.","de":"Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.","fr":"Veuillez vérifier votre connexion Internet et réessayer.","es":"Verifique su conexión a internet e inténtelo de nuevo.","pt-BR":"Verifique sua conexão com a internet e tente novamente.","it":"Controlla la connessione internet e riprova.","ru":"Проверьте подключение к интернету и попробуйте снова."],
        "updateAvail":    ["zh":"发现新版本",         "zh-TW":"發現新版本",         "en":"New Version Available",               "ja":"新しいバージョンがあります",             "ko":"새로운 버전이 있습니다",                 "de":"Neue Version verfügbar",                          "fr":"Nouvelle version disponible",                   "es":"Nueva versión disponible",               "pt-BR":"Nova versão disponível",               "it":"Nuova versione disponibile",                 "ru":"Доступна новая версия"],
        "updateAvailMsg": ["zh":"DashCat %@ 可用。当前版本为 %@。","zh-TW":"DashCat %@ 可用。目前版本為 %@。","en":"DashCat %@ is available. You have %@.","ja":"DashCat %@ が利用可能です。現在のバージョンは %@ です。","ko":"DashCat %@ 사용 가능합니다. 현재 버전은 %@입니다.","de":"DashCat %@ ist verfügbar. Sie haben %@.","fr":"DashCat %@ est disponible. Vous avez %@.","es":"DashCat %@ está disponible. Tienes %@.","pt-BR":"DashCat %@ está disponível. Você tem %@.","it":"DashCat %@ è disponibile. Hai %@.","ru":"DashCat %@ доступна. У вас установлена %@."],
        "download":       ["zh":"下载",               "zh-TW":"下載",               "en":"Download",                            "ja":"ダウンロード",                           "ko":"다운로드",                               "de":"Herunterladen",                                   "fr":"Télécharger",                                   "es":"Descargar",                         "pt-BR":"Baixar",                           "it":"Scarica",                                   "ru":"Скачать"],
        "later":          ["zh":"稍后",               "zh-TW":"稍後",               "en":"Later",                               "ja":"後で",                                  "ko":"나중에",                                 "de":"Später",                                         "fr":"Plus tard",                                     "es":"Más tarde",                         "pt-BR":"Mais tarde",                       "it":"Più tardi",                                     "ru":"Позже"],
        "updateOk":       ["zh":"已是最新版本",       "zh-TW":"已是最新版本",       "en":"You're up to date",                   "ja":"最新バージョンです",                     "ko":"최신 버전입니다",                         "de":"Sie sind auf dem neuesten Stand",                 "fr":"Vous êtes à jour",                              "es":"Estás actualizado",               "pt-BR":"Você está atualizado",             "it":"Sei aggiornato",                              "ru":"Установлена последняя версия"],
        "updateOkMsg":    ["zh":"DashCat %@ 是最新版本。","zh-TW":"DashCat %@ 是最新版本。","en":"DashCat %@ is the latest version.","ja":"DashCat %@ は最新バージョンです。","ko":"DashCat %@는 최신 버전입니다.","de":"DashCat %@ ist die neueste Version.","fr":"DashCat %@ est la dernière version.","es":"DashCat %@ es la última versión.","pt-BR":"DashCat %@ é a versão mais recente.","it":"DashCat %@ è l'ultima versione.","ru":"DashCat %@ — последняя версия."],
    ]

    func str(_ key: String) -> String {
        Language.table[key]?[rawValue] ?? Language.table[key]?["en"] ?? key
    }

    static func systemDefault() -> Language {
        let candidates = Locale.preferredLanguages + [Locale.current.identifier]
        for candidate in candidates {
            let normalized = candidate.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.hasPrefix("zh-hant") ||
                normalized.hasPrefix("zh-tw") ||
                normalized.hasPrefix("zh-hk") ||
                normalized.hasPrefix("zh-mo") {
                return .traditionalChinese
            }
            if normalized.hasPrefix("pt") {
                return .portugueseBrazil
            }
            if let languageCode = normalized.split(separator: "-").first,
               let language = Language(rawValue: String(languageCode)) {
                return language
            }
        }
        return .english
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
    private var dualMetric: (cpu: MonitorInfo, memory: MonitorInfo)?
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
    private var reverseMouseScrollItem: NSMenuItem!
    private var accessibilityHintItem: NSMenuItem!
    private var openAccessibilityItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!
    private var helpMenuItem: NSMenuItem!
    private var checkUpdatesItem: NSMenuItem!
    private var viewGitHubItem: NSMenuItem!
    private var contactItem: NSMenuItem!
    private var quitItem: NSMenuItem!

    private var language: Language = {
        if let saved = UserDefaults.standard.string(forKey: "DashCatLanguage"),
           let lang = Language(rawValue: saved) { return lang }
        return Language.systemDefault()
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
        restoreState()
        startRunning()

        // Start clipboard monitoring (cleanupExpired runs inside ClipboardManager.init)
        ClipboardManager.shared.startPolling()
        if ScrollManager.shared.mouseReversed {
            ScrollManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        clipboardPanel?.close()
        clipboardPanel = nil
        stopRunning()
        ClipboardManager.shared.stopPolling()
        ScrollManager.shared.stop()
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

        // Mouse wheel scrolling
        reverseMouseScrollItem = NSMenuItem(title: "", action: #selector(toggleReverseMouseScroll(_:)), keyEquivalent: "")
        menu.addItem(reverseMouseScrollItem)

        accessibilityHintItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        accessibilityHintItem.isEnabled = false
        menu.addItem(accessibilityHintItem)

        openAccessibilityItem = NSMenuItem(title: "", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        menu.addItem(openAccessibilityItem)

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
        helpSubmenu.addItem(contactItem)
        helpMenuItem.submenu = helpSubmenu
        menu.addItem(helpMenuItem)

        menu.addItem(.separator())

        // Quit
        quitItem = NSMenuItem(title: "", action: #selector(terminateApp(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        applyLanguage()
        refreshScrollState()
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
        reverseMouseScrollItem.title = l.str("reverseMouseScroll")
        accessibilityHintItem.title  = l.str("accessibilityNeeded")
        openAccessibilityItem.title  = l.str("openAccessibility")
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
            clipboardPanel?.close()
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
        if displayMode == .pctOnly {
            statusItem.button?.image = nil
        } else {
            let frames = currentFrames
            statusItem.button?.image = frames[index % frames.count]
        }
        applyMetricDisplay()
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

        activateAppForModal()
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

    @objc private func toggleReverseMouseScroll(_ sender: NSMenuItem) {
        let newValue = sender.state == .off
        ScrollManager.shared.mouseReversed = newValue
        if newValue {
            ScrollManager.shared.start()
        } else {
            ScrollManager.shared.stop()
        }
        refreshScrollState()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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

    private func refreshScrollState() {
        if ScrollManager.shared.mouseReversed && ScrollManager.shared.isTrusted {
            ScrollManager.shared.start()
        }
        reverseMouseScrollItem.state = ScrollManager.shared.mouseReversed ? .on : .off
        let needsPermission = ScrollManager.shared.mouseReversed && !ScrollManager.shared.isTrusted
        accessibilityHintItem.isHidden = !needsPermission
        openAccessibilityItem.isHidden = !needsPermission
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
        dualMetric = nil
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
        case .cpuAndMemory:
            let cpu = monitor.cpuUsage()
            let mem = monitor.memoryPressure()
            dualMetric = (cpu, mem)
            metric = MonitorInfo(max(cpu.value, mem.value), "")
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
        if currentMode == .cpuAndMemory {
            let metrics = dualMetric ?? (cpu: SystemMonitor.default, memory: SystemMonitor.default)
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = makeDualMetricTitle(cpu: metrics.cpu, memory: metrics.memory)
        } else if currentMode == .combined {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = makeStackedTitle(metric.description)
        } else if let textColor = metricTextColor {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString(string: metric.description, attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: textColor
            ])
        } else {
            statusItem.button?.attributedTitle = NSAttributedString()
            statusItem.button?.title = metric.description
        }
    }

    private var metricTextColor: NSColor? {
        switch caffeineMode {
        case .off:            return nil
        case .noSleep:        return .systemBlue
        case .noDisplaySleep: return .systemOrange
        }
    }

    private func makeStackedTitle(_ description: String) -> NSAttributedString {
        let label = String(description.prefix(1))
        let value = String(description.dropFirst()).trimmingCharacters(in: .whitespaces)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 0
        var valueAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
            .paragraphStyle: para
        ]
        var labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 7, weight: .regular),
            .paragraphStyle: para
        ]
        if let textColor = metricTextColor {
            valueAttributes[.foregroundColor] = textColor
            labelAttributes[.foregroundColor] = textColor
        }
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(string: value + "\n", attributes: valueAttributes))
        result.append(NSAttributedString(string: label, attributes: labelAttributes))
        return result
    }

    private func makeDualMetricTitle(cpu: MonitorInfo, memory: MonitorInfo) -> NSAttributedString {
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        para.lineSpacing = 0
        var attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 8, weight: .regular),
            .paragraphStyle: para
        ]
        if let textColor = metricTextColor {
            attributes[.foregroundColor] = textColor
        }
        return NSAttributedString(
            string: String(format: "C%.0f\nM%.0f", cpu.value, memory.value),
            attributes: attributes
        )
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
            activateAppForModal()
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
        activateAppForModal()
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
        activateAppForModal()
        _ = alert.runModal()
    }

    private func activateAppForModal() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
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
        refreshScrollState()
    }

    func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil
    }
}
