import Cocoa
import Carbon
import IOKit.pwr_mgt
import IOKit.ps
import ServiceManagement
import UniformTypeIdentifiers

// MARK: - MonitorMode

enum MonitorMode: String, CaseIterable {
    case combined     = "Combined"
    case cpu          = "CPU"
    case memory       = "Memory"
    case cpuMemory    = "cpuMemory"

    var locKey: String {
        switch self {
        case .combined:     return "combined"
        case .cpu:          return "cpu"
        case .memory:       return "memory"
        case .cpuMemory:    return "cpuMemory"
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
        case .both:     return "displayAnimationValue"
        case .animOnly: return "displayAnimation"
        case .pctOnly:  return "compactValues"
        }
    }

    var showsAnimation: Bool {
        self != .pctOnly
    }

    var showsNumber: Bool {
        self != .animOnly
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
        "retry": ["zh":"重试", "zh-TW":"重試", "en":"Retry", "ja":"再試行", "ko":"다시 시도", "de":"Erneut versuchen", "fr":"Réessayer", "es":"Reintentar", "pt-BR":"Tentar novamente", "it":"Riprova", "ru":"Повторить"],
        "save": ["zh":"保存", "zh-TW":"儲存", "en":"Save", "ja":"保存", "ko":"저장", "de":"Speichern", "fr":"Enregistrer", "es":"Guardar", "pt-BR":"Salvar", "it":"Salva", "ru":"Сохранить"],
        "pauseCapture": ["zh":"暂停采集", "zh-TW":"暫停擷取", "en":"Pause Capture", "ja":"記録を一時停止", "ko":"기록 일시 정지", "de":"Aufzeichnung pausieren", "fr":"Suspendre la collecte", "es":"Pausar captura", "pt-BR":"Pausar captura", "it":"Sospendi acquisizione", "ru":"Приостановить запись"],
        "resumeCapture": ["zh":"恢复采集", "zh-TW":"恢復擷取", "en":"Resume Capture", "ja":"記録を再開", "ko":"기록 다시 시작", "de":"Aufzeichnung fortsetzen", "fr":"Reprendre la collecte", "es":"Reanudar captura", "pt-BR":"Retomar captura", "it":"Riprendi acquisizione", "ru":"Возобновить запись"],
        "capturePausedHint": ["zh":"采集已暂停 · 历史仍可复制", "zh-TW":"擷取已暫停 · 歷史仍可複製", "en":"Capture paused · History can still be copied", "ja":"記録は停止中 · 履歴はコピー可能", "ko":"기록 일시 정지 · 기존 기록 복사 가능", "de":"Aufzeichnung pausiert · Verlauf bleibt kopierbar", "fr":"Collecte suspendue · Historique toujours copiable", "es":"Captura pausada · El historial se puede copiar", "pt-BR":"Captura pausada · Histórico ainda disponível", "it":"Acquisizione sospesa · Cronologia copiabile", "ru":"Запись приостановлена · Историю можно копировать"],
        "captureActive": ["zh":"剪贴板采集中", "zh-TW":"剪貼簿擷取中", "en":"Clipboard capture active", "ja":"クリップボードを記録中", "ko":"클립보드 기록 중", "de":"Zwischenablage wird aufgezeichnet", "fr":"Collecte du presse-papiers active", "es":"Captura del portapapeles activa", "pt-BR":"Captura da área de transferência ativa", "it":"Acquisizione appunti attiva", "ru":"Запись буфера обмена включена"],
        "excludedApps": ["zh":"不记录这些应用", "zh-TW":"不記錄這些應用程式", "en":"Excluded Applications", "ja":"記録しないアプリ", "ko":"기록 제외 앱", "de":"Ausgeschlossene Apps", "fr":"Applications exclues", "es":"Aplicaciones excluidas", "pt-BR":"Aplicativos excluídos", "it":"Applicazioni escluse", "ru":"Исключённые приложения"],
        "excludeCurrentApp": ["zh":"不记录当前应用：%@", "zh-TW":"不記錄目前應用程式：%@", "en":"Exclude Current App: %@", "ja":"現在のアプリを除外：%@", "ko":"현재 앱 제외: %@", "de":"Aktuelle App ausschließen: %@", "fr":"Exclure l’application active : %@", "es":"Excluir aplicación actual: %@", "pt-BR":"Excluir aplicativo atual: %@", "it":"Escludi applicazione attuale: %@", "ru":"Исключить текущее приложение: %@"],
        "addExcludedApp": ["zh":"添加应用…", "zh-TW":"加入應用程式…", "en":"Add Application…", "ja":"アプリを追加…", "ko":"앱 추가…", "de":"App hinzufügen…", "fr":"Ajouter une application…", "es":"Añadir aplicación…", "pt-BR":"Adicionar aplicativo…", "it":"Aggiungi applicazione…", "ru":"Добавить приложение…"],
        "removeExcludedAppHint": ["zh":"点击恢复记录此应用；只影响后续复制。", "zh-TW":"點擊恢復記錄此應用程式；僅影響後續複製。", "en":"Click to resume capturing this app. Future copies only.", "ja":"クリックで記録を再開。今後のコピーのみ。", "ko":"클릭하여 기록 재개. 이후 복사에만 적용.", "de":"Klicken zum Aufzeichnen dieser App. Nur künftige Kopien.", "fr":"Cliquez pour reprendre la collecte. Copies futures uniquement.", "es":"Haz clic para registrar esta app. Solo copias futuras.", "pt-BR":"Clique para registrar este app. Apenas cópias futuras.", "it":"Clic per acquisire questa app. Solo copie future.", "ru":"Нажмите для возобновления записи. Только будущие копии."],
        "clipboardNeedsAttention": ["zh":"历史记录需要处理", "zh-TW":"歷史記錄需要處理", "en":"History Needs Attention", "ja":"履歴の確認が必要", "ko":"기록 확인 필요", "de":"Verlauf erfordert Aufmerksamkeit", "fr":"Historique à vérifier", "es":"El historial requiere atención", "pt-BR":"O histórico precisa de atenção", "it":"Cronologia da controllare", "ru":"История требует внимания"],
        "cleanupPending": ["zh":"历史记录已更新，但清理尚未完成；请修复存储问题后重试。", "zh-TW":"歷史記錄已更新，但清理尚未完成；請修復儲存問題後重試。", "en":"History updated, but cleanup is incomplete. Resolve the storage issue and retry.", "ja":"履歴は更新済みですが、消去処理は未完了です。保存先を確認して再試行してください。", "ko":"기록은 갱신되었지만 정리가 완료되지 않았습니다. 저장 문제를 해결한 후 다시 시도하세요.", "de":"Verlauf aktualisiert, Bereinigung unvollständig. Speicherproblem beheben und erneut versuchen.", "fr":"Historique mis à jour, mais nettoyage incomplet. Corrigez le stockage puis réessayez.", "es":"Historial actualizado, limpieza incompleta. Resuelve el almacenamiento y reintenta.", "pt-BR":"Histórico atualizado, limpeza incompleta. Resolva o armazenamento e tente novamente.", "it":"Cronologia aggiornata, pulizia incompleta. Risolvi l’archiviazione e riprova.", "ru":"История обновлена, но очистка не завершена. Исправьте проблему хранения и повторите."],
        "fileCleanupFailed": ["zh":"部分图片文件尚未清理。请检查图片目录权限和磁盘空间后重试。", "zh-TW":"部分圖片檔案尚未清理。請檢查圖片目錄權限與磁碟空間後重試。", "en":"Some image files remain. Check image folder permissions and disk space, then retry.", "ja":"一部の画像が残っています。保存先の権限と空き容量を確認してください。", "ko":"일부 이미지 파일이 남아 있습니다. 폴더 권한과 디스크 공간을 확인하세요.", "de":"Einige Bilder verbleiben. Ordnerrechte und Speicherplatz prüfen, dann erneut versuchen.", "fr":"Des images restent. Vérifiez les droits du dossier et l’espace disque.", "es":"Quedan imágenes. Revisa permisos de carpeta y espacio en disco.", "pt-BR":"Algumas imagens permanecem. Verifique permissões da pasta e espaço em disco.", "it":"Restano immagini. Controlla permessi della cartella e spazio su disco.", "ru":"Остались изображения. Проверьте права на папку и место на диске."],
        "privacyCleanupFailed": ["zh":"存储中的旧内容尚未完成清理。请关闭其他读取历史的程序，检查磁盘空间和权限后重试。", "zh-TW":"儲存中的舊內容尚未清理完成。請關閉其他讀取歷史的程式，檢查磁碟空間與權限後重試。", "en":"Old stored content could not be cleaned up. Close other history readers, check disk space and permissions, then retry.", "ja":"保存先の古い内容を消去できません。他の履歴閲覧プログラムを閉じ、空き容量と権限を確認してください。", "ko":"저장소의 이전 내용을 정리하지 못했습니다. 다른 기록 읽기 프로그램을 닫고 공간과 권한을 확인하세요.", "de":"Alte Daten nicht bereinigt. Andere Verlaufsleser schließen, Speicherplatz und Rechte prüfen.", "fr":"Anciennes données non nettoyées. Fermez les autres lecteurs, vérifiez espace et droits.", "es":"No se limpiaron los datos antiguos. Cierra otros lectores y revisa espacio y permisos.", "pt-BR":"Dados antigos não foram limpos. Feche outros leitores e verifique espaço e permissões.", "it":"Dati precedenti non puliti. Chiudi altri lettori e controlla spazio e permessi.", "ru":"Не удалось очистить старые данные. Закройте другие программы чтения истории и проверьте место и права."],
        "imageInvalid": ["zh":"图片无法解码，请从来源应用重新复制原图。", "zh-TW":"圖片無法解碼，請從來源應用程式重新複製原圖。", "en":"This image cannot be decoded. Copy the original again from its source app.", "ja":"画像を読み込めません。元のアプリから再度コピーしてください。", "ko":"이미지를 해석할 수 없습니다. 원래 앱에서 다시 복사하세요.", "de":"Bild nicht lesbar. Original erneut aus der Quell-App kopieren.", "fr":"Image illisible. Recopiez l’original depuis son application.", "es":"No se puede decodificar. Copia de nuevo el original desde su aplicación.", "pt-BR":"Não foi possível decodificar. Copie o original novamente no app de origem.", "it":"Immagine non decodificabile. Ricopia l’originale dall’app di origine.", "ru":"Не удаётся декодировать изображение. Скопируйте оригинал снова из исходного приложения."],
        "imageMissing": ["zh":"原图文件缺失，请从来源应用重新复制图片。", "zh-TW":"原圖檔案遺失，請從來源應用程式重新複製圖片。", "en":"The original image is missing. Copy it again from its source app.", "ja":"元の画像が見つかりません。元のアプリから再度コピーしてください。", "ko":"원본 이미지가 없습니다. 원래 앱에서 다시 복사하세요.", "de":"Originalbild fehlt. Erneut aus der Quell-App kopieren.", "fr":"Image originale introuvable. Recopiez-la depuis son application.", "es":"Falta el original. Copia la imagen de nuevo desde su aplicación.", "pt-BR":"O original não foi encontrado. Copie novamente no app de origem.", "it":"Originale mancante. Ricopia dall’app di origine.", "ru":"Оригинал отсутствует. Скопируйте его снова из исходного приложения."],
        "imageUnreadable": ["zh":"无法读取原图，请检查文件权限后重试。", "zh-TW":"無法讀取原圖，請檢查檔案權限後重試。", "en":"Cannot read the original image. Check file permissions and retry.", "ja":"元の画像を読み取れません。ファイルの権限を確認してください。", "ko":"원본 이미지를 읽을 수 없습니다. 파일 권한을 확인하세요.", "de":"Originalbild nicht lesbar. Dateirechte prüfen und erneut versuchen.", "fr":"Image originale inaccessible. Vérifiez les droits du fichier.", "es":"No se puede leer el original. Revisa los permisos del archivo.", "pt-BR":"Não foi possível ler o original. Verifique as permissões do arquivo.", "it":"Originale non leggibile. Controlla i permessi del file.", "ru":"Не удаётся прочитать оригинал. Проверьте права на файл."],
        "itemMissing": ["zh":"此条目已被删除，请刷新列表。", "zh-TW":"此項目已被刪除，請重新整理列表。", "en":"This item was deleted. Refresh the list.", "ja":"項目は削除済みです。一覧を更新してください。", "ko":"항목이 삭제되었습니다. 목록을 새로 고치세요.", "de":"Eintrag gelöscht. Liste aktualisieren.", "fr":"Entrée supprimée. Actualisez la liste.", "es":"Elemento eliminado. Actualiza la lista.", "pt-BR":"Item apagado. Atualize a lista.", "it":"Voce eliminata. Aggiorna l’elenco.", "ru":"Запись удалена. Обновите список."],
        "pinBeforeRename": ["zh":"请先固定此条目，再设置名称。", "zh-TW":"請先固定此項目，再設定名稱。", "en":"Pin this item before naming it.", "ja":"名前を付ける前に固定してください。", "ko":"이름 지정 전에 항목을 고정하세요.", "de":"Eintrag vor dem Benennen anheften.", "fr":"Épinglez cette entrée avant de la nommer.", "es":"Fija el elemento antes de nombrarlo.", "pt-BR":"Fixe o item antes de nomeá-lo.", "it":"Fissa la voce prima di nominarla.", "ru":"Закрепите запись перед переименованием."],
        "invalidClipName": ["zh":"名称应为单行，不超过 200 个字符。留空恢复默认显示。", "zh-TW":"名稱應為單行，不超過 200 個字元。留空恢復預設顯示。", "en":"Use one line, up to 200 characters. Leave blank to reset.", "ja":"名前は1行、200文字以内。空欄で既定表示に戻ります。", "ko":"이름은 한 줄, 200자 이내. 비우면 기본 표시로 복원.", "de":"Eine Zeile, maximal 200 Zeichen. Leer lassen zum Zurücksetzen.", "fr":"Une ligne, 200 caractères maximum. Laissez vide pour réinitialiser.", "es":"Una línea y hasta 200 caracteres. Vacío para restablecer.", "pt-BR":"Uma linha, até 200 caracteres. Em branco para restaurar.", "it":"Una riga, massimo 200 caratteri. Vuoto per ripristinare.", "ru":"Одна строка, до 200 символов. Пустое имя сбрасывает отображение."],
        "pinnedMarker": ["zh":"已固定", "zh-TW":"已固定", "en":"Pinned", "ja":"固定済み", "ko":"고정됨", "de":"Angeheftet", "fr":"Épinglé", "es":"Fijado", "pt-BR":"Fixado", "it":"Fissato", "ru":"Закреплено"],
        "renameClip": ["zh":"重命名…", "zh-TW":"重新命名…", "en":"Rename…", "ja":"名前を変更…", "ko":"이름 변경…", "de":"Umbenennen…", "fr":"Renommer…", "es":"Renombrar…", "pt-BR":"Renomear…", "it":"Rinomina…", "ru":"Переименовать…"],
        "renameClipPrompt": ["zh":"名称仅用于显示和搜索，复制与预览仍使用完整原内容。留空恢复默认显示。", "zh-TW":"名稱僅用於顯示與搜尋，複製及預覽仍使用完整原內容。留空恢復預設顯示。", "en":"The name is used for display and search. Copy and preview keep the full original content. Leave blank to reset.", "ja":"名前は表示と検索に使います。コピーとプレビューは元の内容を使用します。空欄で表示を戻します。", "ko":"이름은 표시와 검색에만 사용됩니다. 복사와 미리보기는 전체 원본을 사용합니다. 비우면 기본 표시로 복원.", "de":"Name für Anzeige und Suche. Kopieren und Vorschau nutzen den vollständigen Originalinhalt. Leer lassen zum Zurücksetzen.", "fr":"Nom pour l’affichage et la recherche. Copie et aperçu conservent le contenu original complet. Laissez vide pour réinitialiser.", "es":"El nombre sirve para mostrar y buscar. Copia y vista previa mantienen todo el original. Vacío para restablecer.", "pt-BR":"Nome para exibição e busca. Cópia e prévia mantêm todo o original. Em branco para restaurar.", "it":"Nome per visualizzazione e ricerca. Copia e anteprima mantengono tutto l’originale. Vuoto per ripristinare.", "ru":"Имя для отображения и поиска. Копирование и просмотр сохраняют полный оригинал. Оставьте пустым для сброса."],
        "resetClipName": ["zh":"恢复默认显示", "zh-TW":"恢復預設顯示", "en":"Reset Name", "ja":"既定表示に戻す", "ko":"기본 표시 복원", "de":"Name zurücksetzen", "fr":"Réinitialiser le nom", "es":"Restablecer nombre", "pt-BR":"Restaurar nome", "it":"Ripristina nome", "ru":"Сбросить имя"],
        "previewFullHint": ["zh":"右键预览完整内容；单击或 Enter 复制原内容。", "zh-TW":"右鍵預覽完整內容；點擊或 Enter 複製原內容。", "en":"Right-click for full preview. Click or Enter copies the original.", "ja":"右クリックで全文を表示。クリックまたはEnterで元の内容をコピー。", "ko":"우클릭으로 전체 미리보기. 클릭 또는 Enter로 원본 복사.", "de":"Rechtsklick für vollständige Vorschau. Klick oder Enter kopiert das Original.", "fr":"Clic droit : aperçu complet. Clic ou Entrée copie l’original.", "es":"Botón derecho para ver todo. Clic o Enter copia el original.", "pt-BR":"Botão direito para prévia completa. Clique ou Enter copia o original.", "it":"Clic destro per anteprima completa. Clic o Invio copia l’originale.", "ru":"Правый щелчок — полный просмотр. Щелчок или Enter копирует оригинал."],
        "mainClickHint": ["zh":"左键打开剪贴板 · 右键打开设置", "zh-TW":"左鍵開啟剪貼簿 · 右鍵開啟設定", "en":"Click: clipboard · Right-click: settings", "ja":"クリック：履歴 · 右クリック：設定", "ko":"클릭: 클립보드 · 우클릭: 설정", "de":"Klick: Zwischenablage · Rechtsklick: Einstellungen", "fr":"Clic : presse-papiers · Clic droit : réglages", "es":"Clic: portapapeles · Botón derecho: ajustes", "pt-BR":"Clique: área de transferência · Botão direito: ajustes", "it":"Clic: appunti · Clic destro: impostazioni", "ru":"Щелчок: буфер обмена · Правый щелчок: настройки"],
        "retentionConfirmTitle": ["zh":"缩短历史保留时间？", "zh-TW":"縮短歷史保留時間？", "en":"Shorten History Retention?", "ja":"履歴の保存期間を短縮しますか？", "ko":"기록 보관 기간을 줄일까요?", "de":"Verlaufsdauer verkürzen?", "fr":"Réduire la conservation ?", "es":"¿Reducir la conservación?", "pt-BR":"Reduzir retenção do histórico?", "it":"Ridurre la conservazione?", "ru":"Сократить срок хранения?"],
        "retentionConfirmMessage": ["zh":"改为 %@ 天将立即删除约 %@ 条过期记录。固定项保留，此操作无法撤销。", "zh-TW":"改為 %@ 天將立即刪除約 %@ 筆過期記錄。固定項目保留，無法復原。", "en":"Changing to %@ days removes about %@ expired entries immediately. Pinned entries stay. This cannot be undone.", "ja":"%@日への変更で期限切れの約%@件を即時削除します。固定項目は保持されます。元に戻せません。", "ko":"%@일로 변경하면 만료된 약 %@개가 즉시 삭제됩니다. 고정 항목은 유지됩니다. 되돌릴 수 없습니다.", "de":"Bei %@ Tagen werden etwa %@ alte Einträge sofort gelöscht. Angeheftete bleiben. Nicht rückgängig zu machen.", "fr":"Passer à %@ jours supprime aussitôt environ %@ entrées expirées. Les épingles restent. Irréversible.", "es":"Cambiar a %@ días borra de inmediato unas %@ entradas caducadas. Las fijadas se conservan. No se puede deshacer.", "pt-BR":"Mudar para %@ dias apaga cerca de %@ registros vencidos imediatamente. Os fixados permanecem. Irreversível.", "it":"Passare a %@ giorni elimina subito circa %@ voci scadute. Quelle fissate restano. Non annullabile.", "ru":"Срок %@ дней сразу удалит около %@ старых записей. Закреплённые сохранятся. Отменить нельзя."],
        "changeRetention": ["zh":"更改并清理", "zh-TW":"變更並清理", "en":"Change and Clean Up", "ja":"変更して削除", "ko":"변경 및 정리", "de":"Ändern und bereinigen", "fr":"Modifier et nettoyer", "es":"Cambiar y limpiar", "pt-BR":"Alterar e limpar", "it":"Modifica e pulisci", "ru":"Изменить и очистить"],
        "memoryUsageHint": ["zh":"M：内存占用率（应用、系统及压缩内存；不含可回收文件缓存）", "zh-TW":"M：記憶體使用率（應用程式、系統與壓縮記憶體；不含可回收檔案快取）", "en":"M: memory used by apps, system and compression; reclaimable file cache excluded", "ja":"M：アプリ・システム・圧縮メモリの使用率。回収可能なファイルキャッシュを除く", "ko":"M: 앱·시스템·압축 메모리 사용률. 회수 가능한 파일 캐시 제외", "de":"M: Speicher für Apps, System und Kompression; rückgewinnbarer Dateicache ausgeschlossen", "fr":"M : mémoire des apps, du système et compressée ; cache récupérable exclu", "es":"M: memoria de apps, sistema y compresión; caché recuperable excluida", "pt-BR":"M: memória de apps, sistema e compressão; cache recuperável excluído", "it":"M: memoria di app, sistema e compressione; cache recuperabile esclusa", "ru":"M: память приложений, системы и сжатия; освобождаемый файловый кеш исключён"],
        "filterTermsHelp": ["zh":"每行一个词，包含匹配、不区分大小写；仅影响后续复制。", "zh-TW":"每行一個詞，包含比對、不區分大小寫；僅影響之後的複製。", "en":"One term per line. Case-insensitive contains matching; applies only to future copies.", "ja":"1 行に 1 語。大文字・小文字を区別しない部分一致。今後のコピーにのみ適用。", "ko":"한 줄에 한 단어. 대소문자를 구분하지 않는 포함 검색이며 이후 복사에만 적용됩니다.", "de":"Ein Begriff pro Zeile. Teiltreffer ohne Beachtung der Großschreibung; nur für künftige Kopien.", "fr":"Un terme par ligne. Recherche partielle sans distinction de casse ; uniquement pour les prochaines copies.", "es":"Un término por línea. Coincidencia parcial sin distinguir mayúsculas; solo para futuras copias.", "pt-BR":"Um termo por linha. Correspondência parcial sem distinguir maiúsculas; só para cópias futuras.", "it":"Un termine per riga. Corrispondenza parziale senza distinzione di maiuscole; solo per copie future.", "ru":"Один термин на строку. Поиск вхождения без учёта регистра; только для будущих копирований."],
        "batteryClickHint": ["zh":"左键切换防休眠 · 右键查看详情", "zh-TW":"左鍵切換防休眠 · 右鍵查看詳情", "en":"Click: cycle sleep prevention · Right-click: details", "ja":"クリック：スリープ防止切替 · 右クリック：詳細", "ko":"클릭: 잠자기 방지 전환 · 우클릭: 상세", "de":"Klick: Ruhezustand umschalten · Rechtsklick: Details", "fr":"Clic : veille · Clic droit : détails", "es":"Clic: suspensión · Clic derecho: detalles", "pt-BR":"Clique: suspensão · Botão direito: detalhes", "it":"Clic: sospensione · Clic destro: dettagli", "ru":"Щелчок: режим сна · Правый щелчок: сведения"],
        "finderFallback": ["zh":"无法读取 Finder 目录，你仍可手动选择文件夹。", "zh-TW":"無法讀取 Finder 目錄，你仍可手動選擇資料夾。", "en":"Cannot read the Finder folder. You can choose a folder manually.", "ja":"Finderの場所を取得できません。フォルダを手動で選択できます。", "ko":"Finder 폴더를 읽을 수 없습니다. 직접 선택할 수 있습니다.", "de":"Finder-Ordner nicht lesbar. Ordner manuell wählen.", "fr":"Dossier Finder inaccessible. Choisissez un dossier manuellement.", "es":"No se puede leer la carpeta de Finder. Elige una manualmente.", "pt-BR":"Não foi possível ler a pasta do Finder. Escolha manualmente.", "it":"Cartella Finder non disponibile. Scegli una cartella manualmente.", "ru":"Папка Finder недоступна. Выберите папку вручную."],
        "loginApproval": ["zh":"需要在系统登录项中允许 DashCat。", "zh-TW":"需要在系統登入項目中允許 DashCat。", "en":"Allow DashCat in System Settings → Login Items.", "ja":"システム設定のログイン項目でDashCatを許可してください。", "ko":"시스템 설정의 로그인 항목에서 DashCat을 허용하세요.", "de":"DashCat in den Anmeldeobjekten erlauben.", "fr":"Autorisez DashCat dans les éléments d’ouverture.", "es":"Permite DashCat en los ítems de inicio.", "pt-BR":"Permita DashCat nos itens de início.", "it":"Consenti DashCat negli elementi login.", "ru":"Разрешите DashCat в объектах входа."],
        "shortcutFailed": ["zh":"快捷键无法注册，可能已被占用。请选择其他组合。", "zh-TW":"快捷鍵無法註冊，可能已被佔用。請選擇其他組合。", "en":"Shortcut unavailable; it may already be in use. Choose another combination.", "ja":"ショートカットを登録できません。別の組み合わせを選んでください。", "ko":"단축키를 등록할 수 없습니다. 다른 조합을 선택하세요.", "de":"Kurzbefehl nicht verfügbar. Andere Kombination wählen.", "fr":"Raccourci indisponible. Choisissez une autre combinaison.", "es":"Atajo no disponible. Elige otra combinación.", "pt-BR":"Atalho indisponível. Escolha outra combinação.", "it":"Scorciatoia non disponibile. Scegli un’altra combinazione.", "ru":"Сочетание недоступно. Выберите другое."],
        "historyCleared": ["zh":"已清除所选范围的历史记录。", "zh-TW":"已清除所選範圍的歷史記錄。", "en":"Selected history cleared.", "ja":"選択範囲の履歴を消去しました。", "ko":"선택한 기록을 삭제했습니다.", "de":"Ausgewählter Verlauf gelöscht.", "fr":"Historique sélectionné effacé.", "es":"Historial seleccionado borrado.", "pt-BR":"Histórico selecionado apagado.", "it":"Cronologia selezionata eliminata.", "ru":"Выбранная история очищена."],
        "operationFailed": ["zh":"操作未成功，请检查系统设置后重试。", "zh-TW":"操作未成功，請檢查系統設定後重試。", "en":"Operation failed. Check System Settings and try again.", "ja":"操作に失敗しました。システム設定を確認してください。", "ko":"작업에 실패했습니다. 시스템 설정을 확인하세요.", "de":"Aktion fehlgeschlagen. Systemeinstellungen prüfen.", "fr":"Échec. Vérifiez les Réglages Système.", "es":"Error. Revisa los Ajustes del Sistema.", "pt-BR":"Falha. Verifique os Ajustes do Sistema.", "it":"Operazione fallita. Controlla Impostazioni di Sistema.", "ru":"Ошибка. Проверьте Системные настройки."],
        "clipboardFailure": ["zh":"历史记录操作失败，请检查可用磁盘空间和存储目录权限后重试。", "zh-TW":"歷史記錄操作失敗，請檢查磁碟空間與儲存目錄權限後重試。", "en":"History operation failed. Check free disk space and storage folder permissions, then retry.", "ja":"履歴の操作に失敗しました。空き容量とフォルダの権限を確認してください。", "ko":"기록 작업에 실패했습니다. 디스크 공간과 폴더 권한을 확인하세요.", "de":"Verlaufsaktion fehlgeschlagen. Speicherplatz und Ordnerrechte prüfen.", "fr":"Échec de l’opération. Vérifiez l’espace disque et les droits du dossier.", "es":"Error en el historial. Revisa el espacio y los permisos de la carpeta.", "pt-BR":"Falha no histórico. Verifique o espaço e as permissões da pasta.", "it":"Operazione non riuscita. Controlla spazio e permessi della cartella.", "ru":"Ошибка истории. Проверьте место на диске и права на папку."],
        "copyFailed": ["zh":"无法读取或复制此条目，请重试。", "zh-TW":"無法讀取或複製此項目，請重試。", "en":"Could not read or copy this item. Try again.", "ja":"読み取りまたはコピーできません。再試行してください。", "ko":"읽거나 복사할 수 없습니다. 다시 시도하세요.", "de":"Eintrag nicht lesbar oder kopierbar. Erneut versuchen.", "fr":"Lecture ou copie impossible. Réessayez.", "es":"No se pudo leer o copiar. Inténtalo de nuevo.", "pt-BR":"Não foi possível ler ou copiar. Tente novamente.", "it":"Impossibile leggere o copiare. Riprova.", "ru":"Не удалось прочитать или скопировать. Повторите попытку."],
        "invalidDays": ["zh":"请输入 1–365 之间的整数，当前设置尚未更改。", "zh-TW":"請輸入 1–365 的整數，目前設定尚未變更。", "en":"Enter a whole number from 1 to 365. Settings are unchanged.", "ja":"1〜365の整数を入力してください。設定は未変更です。", "ko":"1~365의 정수를 입력하세요. 설정은 변경되지 않았습니다.", "de":"Ganze Zahl von 1 bis 365 eingeben. Einstellung unverändert.", "fr":"Saisissez un entier de 1 à 365. Réglage inchangé.", "es":"Introduce un entero de 1 a 365. Ajuste sin cambios.", "pt-BR":"Digite um inteiro de 1 a 365. Configuração inalterada.", "it":"Inserisci un intero da 1 a 365. Impostazione invariata.", "ru":"Введите целое число от 1 до 365. Настройки не изменены."],
        "clipboardShortcut": ["zh":"打开剪贴板快捷键", "zh-TW":"開啟剪貼簿快捷鍵", "en":"Open Clipboard Shortcut", "ja":"履歴を開くショートカット", "ko":"클립보드 단축키", "de":"Kurzbefehl für Verlauf", "fr":"Raccourci du presse-papiers", "es":"Atajo del portapapeles", "pt-BR":"Atalho da área de transferência", "it":"Scorciatoia appunti", "ru":"Клавиши открытия истории"],
        "unknown": ["zh":"未知", "zh-TW":"未知", "en":"Unknown", "ja":"不明", "ko":"알 수 없음", "de":"Unbekannt", "fr":"Inconnu", "es":"Desconocido", "pt-BR":"Desconhecido", "it":"Sconosciuto", "ru":"Неизвестно"],
        "loading": ["zh":"正在读取…", "zh-TW":"正在讀取…", "en":"Loading…", "ja":"読み込み中…", "ko":"불러오는 중…", "de":"Wird geladen…", "fr":"Chargement…", "es":"Cargando…", "pt-BR":"Carregando…", "it":"Caricamento…", "ru":"Загрузка…"],
        "copied": ["zh":"已复制", "zh-TW":"已複製", "en":"Copied", "ja":"コピーしました", "ko":"복사됨", "de":"Kopiert", "fr":"Copié", "es":"Copiado", "pt-BR":"Copiado", "it":"Copiato", "ru":"Скопировано"],
        "copy": ["zh":"复制", "zh-TW":"複製", "en":"Copy", "ja":"コピー", "ko":"복사", "de":"Kopieren", "fr":"Copier", "es":"Copiar", "pt-BR":"Copiar", "it":"Copia", "ru":"Копировать"],
        "preview": ["zh":"预览", "zh-TW":"預覽", "en":"Preview", "ja":"プレビュー", "ko":"미리보기", "de":"Vorschau", "fr":"Aperçu", "es":"Vista previa", "pt-BR":"Prévia", "it":"Anteprima", "ru":"Просмотр"],
        "loadMore": ["zh":"加载更多", "zh-TW":"載入更多", "en":"Load More", "ja":"さらに表示", "ko":"더 보기", "de":"Mehr laden", "fr":"Charger plus", "es":"Cargar más", "pt-BR":"Carregar mais", "it":"Carica altro", "ru":"Загрузить ещё"],
        "statusSummary":["zh":"CPU %@  内存 %@","zh-TW":"CPU %@  記憶體 %@","en":"CPU %@  Mem %@","ja":"CPU %@  メモリ %@","ko":"CPU %@  메모리 %@","de":"CPU %@  Speicher %@","fr":"CPU %@  Mémoire %@","es":"CPU %@  Mem %@","pt-BR":"CPU %@  Mem %@","it":"CPU %@  Mem %@","ru":"CPU %@  Память %@"],
        "monitor":      ["zh":"监控",       "zh-TW":"監控",     "en":"Monitor",          "ja":"モニター",             "ko":"모니터",        "de":"Monitor",                     "fr":"Moniteur",               "es":"Monitor",                "pt-BR":"Monitor",             "it":"Monitor",                "ru":"Монитор"],
        "compactValues":["zh":"紧凑数值",   "zh-TW":"緊湊數值", "en":"Compact Values",   "ja":"コンパクト数値",       "ko":"간결한 수치",   "de":"Kompakte Werte",              "fr":"Valeurs compactes",      "es":"Valores compactos",      "pt-BR":"Valores compactos",   "it":"Valori compatti",        "ru":"Компактные значения"],
        "customDisplay":["zh":"自定义显示", "zh-TW":"自訂顯示", "en":"Custom Display",   "ja":"カスタム表示",         "ko":"사용자 지정 표시","de":"Eigene Anzeige",             "fr":"Affichage personnalisé", "es":"Visualización personalizada","pt-BR":"Exibição personalizada","it":"Visualizzazione personalizzata","ru":"Пользовательский вид"],
        "monitorSource":["zh":"监控来源",   "zh-TW":"監控來源", "en":"Monitor Source",   "ja":"監視ソース",           "ko":"모니터 소스",   "de":"Monitorquelle",               "fr":"Source du moniteur",     "es":"Fuente del monitor",     "pt-BR":"Fonte do monitor",    "it":"Sorgente monitor",       "ru":"Источник мониторинга"],
        "display":      ["zh":"显示方式",   "zh-TW":"顯示方式", "en":"Display",          "ja":"表示方式",             "ko":"표시 방식",     "de":"Anzeige",                     "fr":"Affichage",              "es":"Visualización",          "pt-BR":"Exibição",            "it":"Visualizzazione",        "ru":"Отображение"],
        "displayAnimation":["zh":"动画",    "zh-TW":"動畫",     "en":"Animation",        "ja":"アニメーション",       "ko":"애니메이션",    "de":"Animation",                   "fr":"Animation",              "es":"Animación",              "pt-BR":"Animação",            "it":"Animazione",             "ru":"Анимация"],
        "displayAnimationValue":["zh":"动画 + 数值","zh-TW":"動畫 + 數值","en":"Animation + Value","ja":"アニメーション + 数値","ko":"애니메이션 + 수치","de":"Animation + Wert","fr":"Animation + valeur","es":"Animación + valor","pt-BR":"Animação + valor","it":"Animazione + valore","ru":"Анимация + значение"],
        "combined":     ["zh":"综合",       "zh-TW":"綜合",     "en":"Combined",         "ja":"総合",                 "ko":"종합",          "de":"Kombiniert",                  "fr":"Combiné",                "es":"Combinado",              "pt-BR":"Combinado",           "it":"Combinato",              "ru":"Комбинированный"],
        "cpu":          ["zh":"CPU",        "zh-TW":"CPU",      "en":"CPU",              "ja":"CPU",                  "ko":"CPU",           "de":"CPU",                         "fr":"CPU",                    "es":"CPU",                    "pt-BR":"CPU",                 "it":"CPU",                    "ru":"CPU"],
        "memory":       ["zh":"内存",       "zh-TW":"記憶體",   "en":"Memory",           "ja":"メモリ",               "ko":"메모리",        "de":"Speicher",                    "fr":"Mémoire",                "es":"Memoria",                "pt-BR":"Memória",             "it":"Memoria",                "ru":"Память"],
        "cpuMemory":    ["zh":"CPU + 内存", "zh-TW":"CPU + 記憶體","en":"CPU + Memory",    "ja":"CPU + メモリ",         "ko":"CPU + 메모리", "de":"CPU + Speicher",              "fr":"CPU + mémoire",          "es":"CPU + memoria",          "pt-BR":"CPU + memória",       "it":"CPU + memoria",          "ru":"CPU + память"],
        "sleep":        ["zh":"阻止休眠",   "zh-TW":"防止休眠", "en":"Sleep Prevention", "ja":"スリープ防止",         "ko":"절전 방지",     "de":"Ruhezustand verhindern",      "fr":"Prévention de veille",   "es":"Prevención de suspensión","pt-BR":"Prevenção de suspensão","it":"Prevenzione sospensione","ru":"Предотвращение сна"],
        "sleepOff":     ["zh":"关闭",       "zh-TW":"關閉",     "en":"Off",              "ja":"オフ",                 "ko":"끔",            "de":"Aus",                         "fr":"Désactivé",              "es":"Desactivado",            "pt-BR":"Desativado",          "it":"Disattivato",            "ru":"Выкл"],
        "sleepSystem":  ["zh":"阻止系统休眠","zh-TW":"防止系統休眠","en":"Prevent System Sleep","ja":"システムスリープを防止","ko":"시스템 절전 방지","de":"System-Ruhezustand verhindern","fr":"Empêcher la veille du système","es":"Evitar suspensión del sistema","pt-BR":"Evitar suspensão do sistema","it":"Impedisci sospensione sistema","ru":"Предотвратить сон системы"],
        "sleepDisplay": ["zh":"阻止屏幕休眠","zh-TW":"防止螢幕休眠","en":"Prevent Display Sleep","ja":"ディスプレイスリープを防止","ko":"화면 절전 방지","de":"Display-Ruhezustand verhindern","fr":"Empêcher la veille de l'écran","es":"Evitar suspensión de pantalla","pt-BR":"Evitar suspensão da tela","it":"Impedisci sospensione schermo","ru":"Предотвратить сон экрана"],
        "battery":      ["zh":"电量",       "zh-TW":"電量",     "en":"Battery",          "ja":"バッテリー",           "ko":"배터리",        "de":"Batterie",                    "fr":"Batterie",               "es":"Batería",                "pt-BR":"Bateria",             "it":"Batteria",               "ru":"Батарея"],
        "showCompactBattery":["zh":"显示极简电量","zh-TW":"顯示極簡電量","en":"Show Compact Battery","ja":"コンパクトなバッテリー表示","ko":"간결한 배터리 표시","de":"Kompakte Batterie anzeigen","fr":"Afficher la batterie compacte","es":"Mostrar batería compacta","pt-BR":"Mostrar bateria compacta","it":"Mostra batteria compatta","ru":"Показывать компактную батарею"],
        "hideBatteryPluggedIn":["zh":"接电时隐藏","zh-TW":"接上電源時隱藏","en":"Hide When Plugged In","ja":"電源接続中は非表示","ko":"전원 연결 시 숨기기","de":"Bei Netzbetrieb ausblenden","fr":"Masquer sur secteur","es":"Ocultar al conectar corriente","pt-BR":"Ocultar quando conectado à energia","it":"Nascondi con alimentazione collegata","ru":"Скрывать при подключении питания"],
        "batteryTooltip":["zh":"电量：%@%%","zh-TW":"電量：%@%%","en":"Battery: %@%%","ja":"バッテリー：%@%%","ko":"배터리: %@%%","de":"Batterie: %@%%","fr":"Batterie : %@%%","es":"Batería: %@%%","pt-BR":"Bateria: %@%%","it":"Batteria: %@%%","ru":"Батарея: %@%%"],
        "batteryLevel":["zh":"电量：%@%%","zh-TW":"電量：%@%%","en":"Level: %@%%","ja":"残量：%@%%","ko":"배터리 잔량: %@%%","de":"Ladestand: %@%%","fr":"Niveau : %@%%","es":"Nivel: %@%%","pt-BR":"Nível: %@%%","it":"Livello: %@%%","ru":"Уровень: %@%%"],
        "batteryPowerSource":["zh":"电源：%@","zh-TW":"電源：%@","en":"Power: %@","ja":"電源：%@","ko":"전원: %@","de":"Stromquelle: %@","fr":"Alimentation : %@","es":"Fuente de energía: %@","pt-BR":"Energia: %@","it":"Alimentazione: %@","ru":"Питание: %@"],
        "batteryStatus":["zh":"状态：%@","zh-TW":"狀態：%@","en":"Status: %@","ja":"状態：%@","ko":"상태: %@","de":"Status: %@","fr":"État : %@","es":"Estado: %@","pt-BR":"Status: %@","it":"Stato: %@","ru":"Состояние: %@"],
        "powerAdapter":["zh":"电源适配器","zh-TW":"電源轉接器","en":"Power Adapter","ja":"電源アダプタ","ko":"전원 어댑터","de":"Netzteil","fr":"Adaptateur secteur","es":"Adaptador de corriente","pt-BR":"Adaptador de energia","it":"Alimentatore","ru":"Адаптер питания"],
        "batteryPower":["zh":"电池","zh-TW":"電池","en":"Battery","ja":"バッテリー","ko":"배터리","de":"Batterie","fr":"Batterie","es":"Batería","pt-BR":"Bateria","it":"Batteria","ru":"Батарея"],
        "batteryCharging":["zh":"正在充电","zh-TW":"正在充電","en":"Charging","ja":"充電中","ko":"충전 중","de":"Wird geladen","fr":"En charge","es":"Cargando","pt-BR":"Carregando","it":"In carica","ru":"Заряжается"],
        "batteryPluggedIn":["zh":"已接电","zh-TW":"已接上電源","en":"Plugged In","ja":"電源接続中","ko":"전원 연결됨","de":"Angeschlossen","fr":"Branché","es":"Conectado","pt-BR":"Conectado","it":"Collegato","ru":"Подключено"],
        "batteryDischarging":["zh":"正在使用电池","zh-TW":"正在使用電池","en":"Using Battery","ja":"バッテリー使用中","ko":"배터리 사용 중","de":"Batteriebetrieb","fr":"Sur batterie","es":"Usando batería","pt-BR":"Usando bateria","it":"Uso batteria","ru":"Работает от батареи"],
        "lowPowerMode":["zh":"低电量模式：%@","zh-TW":"低耗電模式：%@","en":"Low Power Mode: %@","ja":"低電力モード：%@","ko":"저전력 모드: %@","de":"Stromsparmodus: %@","fr":"Mode économie d'énergie : %@","es":"Modo de bajo consumo: %@","pt-BR":"Modo de pouca energia: %@","it":"Risparmio energetico: %@","ru":"Режим энергосбережения: %@"],
        "on":["zh":"开启","zh-TW":"開啟","en":"On","ja":"オン","ko":"켬","de":"Ein","fr":"Activé","es":"Activado","pt-BR":"Ativado","it":"Attivo","ru":"Вкл"],
        "off":["zh":"关闭","zh-TW":"關閉","en":"Off","ja":"オフ","ko":"끔","de":"Aus","fr":"Désactivé","es":"Desactivado","pt-BR":"Desativado","it":"Disattivo","ru":"Выкл"],
        "batterySettings":["zh":"电池设置\u{2026}","zh-TW":"電池設定\u{2026}","en":"Battery Settings\u{2026}","ja":"バッテリー設定\u{2026}","ko":"배터리 설정\u{2026}","de":"Batterie-Einstellungen\u{2026}","fr":"Réglages Batterie\u{2026}","es":"Configuración de batería\u{2026}","pt-BR":"Ajustes de bateria\u{2026}","it":"Impostazioni Batteria\u{2026}","ru":"Настройки батареи\u{2026}"],
        "clipboardSettings":["zh":"剪贴板设置","zh-TW":"剪貼簿設定","en":"Clipboard Settings","ja":"クリップボード設定","ko":"클립보드 설정","de":"Zwischenablage-Einstellungen","fr":"Réglages du presse-papiers","es":"Ajustes del portapapeles","pt-BR":"Configurações da área de transferência","it":"Impostazioni appunti","ru":"Настройки буфера обмена"],
        "language":     ["zh":"语言",       "zh-TW":"語言",     "en":"Language",         "ja":"言語",                 "ko":"언어",          "de":"Sprache",                     "fr":"Langue",                 "es":"Idioma",                 "pt-BR":"Idioma",              "it":"Lingua",                 "ru":"Язык"],
        "saveImages":   ["zh":"保存图片",   "zh-TW":"儲存圖片", "en":"Save Images",      "ja":"画像を保存",           "ko":"이미지 저장",   "de":"Bilder speichern",            "fr":"Enregistrer les images", "es":"Guardar imágenes",       "pt-BR":"Salvar imagens",      "it":"Salva immagini",         "ru":"Сохранять изображения"],
        "history":      ["zh":"历史记录",   "zh-TW":"歷史記錄", "en":"History",          "ja":"履歴",                 "ko":"기록",          "de":"Verlauf",                     "fr":"Historique",             "es":"Historial",              "pt-BR":"Histórico",           "it":"Cronologia",             "ru":"История"],
        "filterTerms":  ["zh":"过滤词\u{2026}","zh-TW":"過濾詞\u{2026}","en":"Filter Terms\u{2026}","ja":"フィルター語句\u{2026}","ko":"필터 단어\u{2026}","de":"Filterbegriffe\u{2026}","fr":"Termes filtrés\u{2026}","es":"Términos de filtro\u{2026}","pt-BR":"Termos de filtro\u{2026}","it":"Termini filtro\u{2026}","ru":"Фильтры\u{2026}"],
        "filterTermsPrompt":["zh":"每行一个过滤词：","zh-TW":"每行一個過濾詞：","en":"One filter term per line:","ja":"1行に1つのフィルター語句：","ko":"한 줄에 필터 단어 하나:","de":"Ein Filterbegriff pro Zeile:","fr":"Un terme filtré par ligne :","es":"Un término de filtro por línea:","pt-BR":"Um termo de filtro por linha:","it":"Un termine filtro per riga:","ru":"Один фильтр на строку:"],
        "days7":        ["zh":"7 天",       "zh-TW":"7 天",     "en":"7 Days",           "ja":"7日",                  "ko":"7일",           "de":"7 Tage",                      "fr":"7 jours",                "es":"7 días",                 "pt-BR":"7 dias",              "it":"7 giorni",              "ru":"7 дней"],
        "days14":       ["zh":"14 天",      "zh-TW":"14 天",    "en":"14 Days",          "ja":"14日",                 "ko":"14일",          "de":"14 Tage",                     "fr":"14 jours",               "es":"14 días",                "pt-BR":"14 dias",             "it":"14 giorni",              "ru":"14 дней"],
        "days30":       ["zh":"30 天",      "zh-TW":"30 天",    "en":"30 Days",          "ja":"30日",                 "ko":"30일",          "de":"30 Tage",                     "fr":"30 jours",               "es":"30 días",                "pt-BR":"30 dias",             "it":"30 giorni",              "ru":"30 дней"],
        "days90":       ["zh":"90 天",      "zh-TW":"90 天",    "en":"90 Days",          "ja":"90日",                 "ko":"90일",          "de":"90 Tage",                     "fr":"90 jours",               "es":"90 días",                "pt-BR":"90 dias",             "it":"90 giorni",              "ru":"90 дней"],
        "forever":      ["zh":"永久",       "zh-TW":"永久",     "en":"Forever",          "ja":"無期限",               "ko":"영구",          "de":"Unbegrenzt",                  "fr":"Illimité",               "es":"Para siempre",           "pt-BR":"Para sempre",         "it":"Per sempre",             "ru":"Навсегда"],
        "customDays":   ["zh":"自定义\u{2026}","zh-TW":"自訂\u{2026}","en":"Custom\u{2026}","ja":"カスタム\u{2026}","ko":"사용자 정의\u{2026}","de":"Benutzerdefiniert\u{2026}","fr":"Personnalisé\u{2026}","es":"Personalizado\u{2026}","pt-BR":"Personalizado\u{2026}","it":"Personalizzato\u{2026}","ru":"Пользовательский\u{2026}"],
        "search":       ["zh":"搜索\u{2026}",   "zh-TW":"搜尋\u{2026}",  "en":"Search\u{2026}",  "ja":"検索\u{2026}",         "ko":"검색\u{2026}",      "de":"Suchen\u{2026}",              "fr":"Rechercher\u{2026}",      "es":"Buscar\u{2026}",         "pt-BR":"Pesquisar\u{2026}",   "it":"Cerca\u{2026}",          "ru":"Поиск\u{2026}"],
        "noClipboardHistory":["zh":"暂无剪贴板历史","zh-TW":"暫無剪貼簿歷史","en":"No clipboard history yet","ja":"クリップボード履歴はまだありません","ko":"아직 클립보드 기록이 없습니다","de":"Noch kein Zwischenablageverlauf","fr":"Aucun historique du presse-papiers","es":"Aún no hay historial del portapapeles","pt-BR":"Ainda não há histórico da área de transferência","it":"Nessuna cronologia degli appunti","ru":"Истории буфера обмена пока нет"],
        "noSearchResults":["zh":"没有匹配结果","zh-TW":"沒有符合結果","en":"No matching results","ja":"一致する結果はありません","ko":"일치하는 결과가 없습니다","de":"Keine passenden Ergebnisse","fr":"Aucun résultat correspondant","es":"No hay resultados coincidentes","pt-BR":"Nenhum resultado correspondente","it":"Nessun risultato corrispondente","ru":"Нет совпадающих результатов"],
        "image":        ["zh":"图片",       "zh-TW":"圖片",     "en":"Image",           "ja":"画像",                 "ko":"이미지",            "de":"Bild",                        "fr":"Image",                  "es":"Imagen",                 "pt-BR":"Imagem",              "it":"Immagine",               "ru":"Изображение"],
        "pin":          ["zh":"固定",       "zh-TW":"釘選",     "en":"Pin",             "ja":"ピン",                 "ko":"고정",              "de":"Anheften",                    "fr":"Épingler",               "es":"Fijar",                  "pt-BR":"Fixar",               "it":"Fissa",                  "ru":"Закрепить"],
        "unpin":        ["zh":"取消固定",   "zh-TW":"取消釘選", "en":"Unpin",           "ja":"ピン解除",             "ko":"고정 해제",         "de":"Lösen",                       "fr":"Détacher",               "es":"Desfijar",               "pt-BR":"Desafixar",           "it":"Rimuovi fissaggio",      "ru":"Открепить"],
        "delete":       ["zh":"删除",       "zh-TW":"刪除",     "en":"Delete",          "ja":"削除",                 "ko":"삭제",              "de":"Löschen",                     "fr":"Supprimer",              "es":"Eliminar",               "pt-BR":"Excluir",             "it":"Elimina",                "ru":"Удалить"],
        "customDaysPrompt":["zh":"输入天数 (1-365)：","zh-TW":"輸入天數 (1-365)：","en":"Enter number of days (1-365):","ja":"日数を入力 (1-365)：","ko":"일수 입력 (1-365)：","de":"Anzahl der Tage eingeben (1-365):","fr":"Entrez le nombre de jours (1-365) :","es":"Ingrese número de días (1-365):","pt-BR":"Digite o número de dias (1-365):","it":"Inserisci il numero di giorni (1-365):","ru":"Введите количество дней (1-365):"],
        "reverseMouseScroll":["zh":"反转鼠标滚轮","zh-TW":"反轉滑鼠滾輪","en":"Reverse Mouse Wheel","ja":"マウスホイールを反転","ko":"마우스 휠 반전","de":"Mausrad umkehren","fr":"Inverser la molette","es":"Invertir rueda del mouse","pt-BR":"Inverter roda do mouse","it":"Inverti rotella mouse","ru":"Инвертировать колесо мыши"],
        "newFileInFinder":["zh":"在 Finder 中新建文件","zh-TW":"在 Finder 中新建檔案","en":"New File in Finder","ja":"Finderで新規ファイル","ko":"Finder에서 새 파일","de":"Neue Datei im Finder","fr":"Nouveau fichier dans Finder","es":"Nuevo archivo en Finder","pt-BR":"Novo arquivo no Finder","it":"Nuovo file nel Finder","ru":"Новый файл в Finder"],
        "newFileTypePrompt":["zh":"选择要创建的文件类型：","zh-TW":"選擇要建立的檔案類型：","en":"Choose the file type to create:","ja":"作成するファイル形式を選択してください：","ko":"만들 파일 형식을 선택하세요:","de":"Wählen Sie den Dateityp aus:","fr":"Choisissez le type de fichier à créer :","es":"Elige el tipo de archivo que quieres crear:","pt-BR":"Escolha o tipo de arquivo para criar:","it":"Scegli il tipo di file da creare:","ru":"Выберите тип создаваемого файла:"],
        "newFileTarget":["zh":"目标文件夹：","zh-TW":"目標檔案夾：","en":"Target folder:","ja":"作成先フォルダ：","ko":"대상 폴더:","de":"Zielordner:","fr":"Dossier cible :","es":"Carpeta de destino:","pt-BR":"Pasta de destino:","it":"Cartella di destinazione:","ru":"Целевая папка:"],
        "chooseFolder":["zh":"选择其他文件夹\u{2026}","zh-TW":"選擇其他檔案夾\u{2026}","en":"Choose Other Folder\u{2026}","ja":"別のフォルダを選択\u{2026}","ko":"다른 폴더 선택\u{2026}","de":"Anderen Ordner wählen\u{2026}","fr":"Choisir un autre dossier\u{2026}","es":"Elegir otra carpeta\u{2026}","pt-BR":"Escolher outra pasta\u{2026}","it":"Scegli altra cartella\u{2026}","ru":"Выбрать другую папку\u{2026}"],
        "create":       ["zh":"创建",       "zh-TW":"建立",     "en":"Create",          "ja":"作成",                 "ko":"만들기",            "de":"Erstellen",                   "fr":"Créer",                  "es":"Crear",                  "pt-BR":"Criar",               "it":"Crea",                   "ru":"Создать"],
        "newFileCreateFail":["zh":"无法新建文件","zh-TW":"無法新建檔案","en":"Could Not Create File","ja":"ファイルを作成できませんでした","ko":"파일을 만들 수 없습니다","de":"Datei konnte nicht erstellt werden","fr":"Impossible de créer le fichier","es":"No se pudo crear el archivo","pt-BR":"Não foi possível criar o arquivo","it":"Impossibile creare il file","ru":"Не удалось создать файл"],
        "newFileCreateFailMsg":["zh":"请确认 Finder 当前文件夹可写，并允许 DashCat 控制 Finder。","zh-TW":"請確認目前 Finder 檔案夾可寫入，並允許 DashCat 控制 Finder。","en":"Make sure the current Finder folder is writable and DashCat is allowed to control Finder.","ja":"現在のFinderフォルダに書き込めることと、DashCatによるFinderの制御が許可されていることを確認してください。","ko":"현재 Finder 폴더에 쓸 수 있고 DashCat이 Finder를 제어할 수 있는지 확인하세요.","de":"Stellen Sie sicher, dass der aktuelle Finder-Ordner beschreibbar ist und DashCat Finder steuern darf.","fr":"Vérifiez que le dossier Finder actuel est accessible en écriture et que DashCat est autorisé à contrôler Finder.","es":"Asegúrate de que la carpeta actual de Finder permita escritura y que DashCat pueda controlar Finder.","pt-BR":"Verifique se a pasta atual do Finder permite gravação e se o DashCat pode controlar o Finder.","it":"Verifica che la cartella Finder attuale sia scrivibile e che DashCat possa controllare Finder.","ru":"Убедитесь, что текущая папка Finder доступна для записи и DashCat разрешено управлять Finder."],
        "accessibilityNeeded":["zh":"需要辅助功能权限","zh-TW":"需要輔助使用權限","en":"Accessibility Permission Required","ja":"アクセシビリティ権限が必要","ko":"손쉬운 사용 권한 필요","de":"Bedienungshilfen-Berechtigung erforderlich","fr":"Autorisation Accessibilité requise","es":"Se requiere permiso de Accesibilidad","pt-BR":"Permissão de Acessibilidade necessária","it":"Permesso Accessibilità richiesto","ru":"Требуется разрешение Универсального доступа"],
        "openAccessibility":["zh":"前往授权\u{2026}","zh-TW":"前往授權\u{2026}","en":"Open System Settings\u{2026}","ja":"システム設定を開く\u{2026}","ko":"시스템 설정 열기\u{2026}","de":"Systemeinstellungen öffnen\u{2026}","fr":"Ouvrir les Réglages Système\u{2026}","es":"Abrir Ajustes del Sistema\u{2026}","pt-BR":"Abrir Ajustes do Sistema\u{2026}","it":"Apri Impostazioni di Sistema\u{2026}","ru":"Открыть Системные настройки\u{2026}"],
        "ok":           ["zh":"确定",       "zh-TW":"確定",     "en":"OK",              "ja":"OK",                   "ko":"확인",              "de":"OK",                          "fr":"OK",                     "es":"OK",                     "pt-BR":"OK",                  "it":"OK",                     "ru":"OK"],
        "cancel":       ["zh":"取消",       "zh-TW":"取消",     "en":"Cancel",          "ja":"キャンセル",           "ko":"취소",              "de":"Abbrechen",                   "fr":"Annuler",                "es":"Cancelar",               "pt-BR":"Cancelar",            "it":"Annulla",                "ru":"Отмена"],
        "clearHistory": ["zh":"清除历史",   "zh-TW":"清除歷史", "en":"Clear History",    "ja":"履歴をクリア",         "ko":"기록 지우기",   "de":"Verlauf löschen",             "fr":"Effacer l'historique",   "es":"Borrar historial",       "pt-BR":"Limpar histórico",    "it":"Cancella cronologia",    "ru":"Очистить историю"],
        "clearHistoryConfirmTitle":["zh":"清除剪贴板历史？","zh-TW":"清除剪貼簿歷史？","en":"Clear Clipboard History?","ja":"クリップボード履歴をクリアしますか？","ko":"클립보드 기록을 지울까요?","de":"Zwischenablageverlauf löschen?","fr":"Effacer l'historique du presse-papiers ?","es":"¿Borrar historial del portapapeles?","pt-BR":"Limpar histórico da área de transferência?","it":"Cancellare la cronologia degli appunti?","ru":"Очистить историю буфера обмена?"],
        "clearHistoryConfirmMsg":["zh":"可以只清除未固定项，也可以连固定项一起清除。","zh-TW":"可以只清除未釘選項目，也可以連釘選項目一起清除。","en":"You can clear only unpinned items, or clear pinned items too.","ja":"ピン留めしていない項目だけ、またはピン留め項目も含めてクリアできます。","ko":"고정하지 않은 항목만 지우거나 고정 항목까지 모두 지울 수 있습니다.","de":"Sie können nur nicht angeheftete Einträge oder auch angeheftete Einträge löschen.","fr":"Vous pouvez effacer seulement les éléments non épinglés, ou aussi les éléments épinglés.","es":"Puedes borrar solo los elementos sin fijar o también los fijados.","pt-BR":"Você pode limpar apenas os itens não fixados ou também os itens fixados.","it":"Puoi cancellare solo gli elementi non fissati o includere anche quelli fissati.","ru":"Можно очистить только незакрепленные элементы или также закрепленные."],
        "clearUnpinned":["zh":"清除未固定项","zh-TW":"清除未釘選項目","en":"Clear Unpinned","ja":"未ピン留めをクリア","ko":"고정 안 함 지우기","de":"Nicht angeheftete löschen","fr":"Effacer non épinglés","es":"Borrar sin fijar","pt-BR":"Limpar não fixados","it":"Cancella non fissati","ru":"Очистить незакрепленные"],
        "clearAllItems":["zh":"清除全部","zh-TW":"清除全部","en":"Clear All","ja":"すべてクリア","ko":"모두 지우기","de":"Alle löschen","fr":"Tout effacer","es":"Borrar todo","pt-BR":"Limpar tudo","it":"Cancella tutto","ru":"Очистить всё"],
        "launchLogin":  ["zh":"开机启动",   "zh-TW":"登入時啟動", "en":"Launch at Login",  "ja":"ログイン時に起動",     "ko":"로그인 시 시작","de":"Beim Login starten",          "fr":"Lancer au démarrage",    "es":"Abrir al iniciar sesión","pt-BR":"Iniciar ao fazer login","it":"Avvia al login",         "ru":"Запуск при входе"],
        "help":         ["zh":"帮助与更新",   "zh-TW":"幫助與更新", "en":"Help & Updates",   "ja":"ヘルプと更新",         "ko":"도움말 및 업데이트","de":"Hilfe & Updates",            "fr":"Aide et mises à jour",  "es":"Ayuda y actualizaciones","pt-BR":"Ajuda e atualizações","it":"Aiuto e aggiornamenti",  "ru":"Справка и обновления"],
        "checkUpdates": ["zh":"检查更新\u{2026}","zh-TW":"檢查更新\u{2026}","en":"Check for Updates\u{2026}","ja":"アップデートを確認\u{2026}","ko":"업데이트 확인\u{2026}","de":"Nach Updates suchen\u{2026}","fr":"Vérifier les mises à jour\u{2026}","es":"Buscar actualizaciones\u{2026}","pt-BR":"Verificar atualizações\u{2026}","it":"Cerca aggiornamenti\u{2026}","ru":"Проверить обновления\u{2026}"],
        "updateChecking":["zh":"正在检查更新\u{2026}","zh-TW":"正在檢查更新\u{2026}","en":"Checking for Updates\u{2026}","ja":"アップデートを確認中\u{2026}","ko":"업데이트 확인 중\u{2026}","de":"Updates werden gesucht\u{2026}","fr":"Recherche de mises à jour\u{2026}","es":"Buscando actualizaciones\u{2026}","pt-BR":"Verificando atualizações\u{2026}","it":"Ricerca aggiornamenti\u{2026}","ru":"Проверка обновлений\u{2026}"],
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
        "fileName":       ["zh":"文件名：","zh-TW":"檔案名稱：","en":"File name:","ja":"ファイル名：","ko":"파일 이름:","de":"Dateiname:","fr":"Nom du fichier :","es":"Nombre del archivo:","pt-BR":"Nome do arquivo:","it":"Nome file:","ru":"Имя файла:"],
        "copyHint": ["zh":"⏎ 复制纯文本 · 右键预览", "zh-TW":"⏎ 複製純文字 · 右鍵預覽", "en":"⏎ Copy plain text · Right-click to preview", "ja":"⏎ テキストをコピー · 右クリックでプレビュー", "ko":"⏎ 일반 텍스트 복사 · 우클릭 미리보기", "de":"⏎ Nur Text kopieren · Rechtsklick: Vorschau", "fr":"⏎ Copier le texte brut · Clic droit : aperçu", "es":"⏎ Copiar texto plano · Clic derecho: vista previa", "pt-BR":"⏎ Copiar texto simples · Botão direito: prévia", "it":"⏎ Copia testo semplice · Clic destro: anteprima", "ru":"⏎ Копировать текст · Правый щелчок: просмотр"],
        "automationPermissionNeeded": ["zh":"DashCat 需要“自动化”权限才能在 Finder 中新建文件。","zh-TW":"DashCat 需要「自動化」權限才能在 Finder 中建立檔案。","en":"DashCat needs Automation permission to create files in Finder.","ja":"DashCatがFinderでファイルを作成するには「自動化」権限が必要です。","ko":"DashCat이 Finder에서 파일을 만들려면 자동화 권한이 필요합니다.","de":"DashCat benötigt die Berechtigung Automatisierung, um Dateien im Finder zu erstellen.","fr":"DashCat a besoin de l'autorisation Automatisation pour créer des fichiers dans le Finder.","es":"DashCat necesita permiso de Automatización para crear archivos en el Finder.","pt-BR":"O DashCat precisa da permissão de Automação para criar arquivos no Finder.","it":"DashCat ha bisogno dell'autorizzazione Automazione per creare file nel Finder.","ru":"DashCat требует разрешения Автоматизации для создания файлов в Finder."],
        "openSettings":   ["zh":"前往设置\u{2026}","zh-TW":"前往設定\u{2026}","en":"Open Settings\u{2026}","ja":"設定を開く\u{2026}","ko":"설정 열기\u{2026}","de":"Einstellungen öffnen\u{2026}","fr":"Ouvrir les réglages\u{2026}","es":"Abrir ajustes\u{2026}","pt-BR":"Abrir ajustes\u{2026}","it":"Apri impostazioni\u{2026}","ru":"Открыть настройки\u{2026}"],
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

// MARK: - Status Metric Layout

private enum StatusMetricLayout {
    static let singleFont = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
    static let singleBaselineOffset: CGFloat = -0.5
    static let combinedValueFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
    static let combinedLabelFont = NSFont.monospacedSystemFont(ofSize: 7, weight: .regular)
    static let dualFont = NSFont.monospacedSystemFont(ofSize: 8.5, weight: .regular)
}

// MARK: - Status Dual Metric View

final class StatusDualMetricView: NSView {
    var cpu: MonitorInfo = SystemMonitor.default { didSet { needsDisplay = true } }
    var memory: MonitorInfo = SystemMonitor.default { didSet { needsDisplay = true } }
    var textColor: NSColor = .labelColor { didSet { needsDisplay = true } }

    private let horizontalPadding: CGFloat = 0

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    var preferredWidth: CGFloat {
        ceil(makeText().size().width + horizontalPadding * 2)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let text = makeText()
        let textSize = text.size()
        let rect = NSRect(
            x: horizontalPadding,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(with: rect, options: [.usesLineFragmentOrigin])
    }

    private func makeText() -> NSAttributedString {
        let para = NSMutableParagraphStyle()
        para.alignment = .left
        para.lineSpacing = 0
        let cpuValue = min(100, max(0, Int(cpu.value.rounded())))
        let memoryValue = min(100, max(0, Int(memory.value.rounded())))
        return NSAttributedString(
            string: "C\(cpuValue)%\nM\(memoryValue)%",
            attributes: [
                .font: StatusMetricLayout.dualFont,
                .paragraphStyle: para,
                .foregroundColor: textColor
            ]
        )
    }
}

// MARK: - Battery Status

private struct BatteryInfo: Equatable {
    let level: Int
    let isPluggedIn: Bool
    let isCharging: Bool?
}

private final class BatteryStatusView: NSView {
    private static let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    private static let horizontalPadding: CGFloat = 2
    private static let verticalInset: CGFloat = 3.5

    var battery: BatteryInfo = BatteryInfo(level: 0, isPluggedIn: false, isCharging: false) {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    var preferredWidth: CGFloat {
        Self.preferredWidth(for: battery.level)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let text = "\(battery.level)"
        let attributedText = NSAttributedString(string: text, attributes: [
            .font: Self.font,
            .foregroundColor: textColor
        ])
        let textSize = attributedText.size()
        let badgeRect = NSRect(
            x: 0.5,
            y: Self.verticalInset,
            width: max(0, bounds.width - 1),
            height: max(0, bounds.height - Self.verticalInset * 2)
        )

        drawBatteryFill(in: badgeRect)

        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2 - 0.5,
            width: textSize.width,
            height: textSize.height
        )
        attributedText.draw(with: textRect, options: [.usesLineFragmentOrigin])
    }

    private func drawBatteryFill(in rect: NSRect) {
        guard rect.width > 0, rect.height > 0 else { return }
        let tint = tintColor
        let radius = min(4, rect.height / 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

        tint.withAlphaComponent(0.08).setFill()
        path.fill()

        let levelFraction = min(1, max(0, CGFloat(battery.level) / 100))
        let fillRect = NSRect(
            x: rect.minX,
            y: rect.minY,
            width: max(1, rect.width * levelFraction),
            height: rect.height
        )
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        tint.withAlphaComponent(fillAlpha).setFill()
        fillRect.fill()
        NSGraphicsContext.restoreGraphicsState()

        if shouldStroke {
            tint.withAlphaComponent(strokeAlpha).setStroke()
            path.lineWidth = 1
            path.stroke()
        }
    }

    private var tintColor: NSColor {
        if battery.isPluggedIn || battery.isCharging == true { return .systemPink }
        if battery.level <= 10 { return .systemRed }
        if battery.level <= 20 { return .systemOrange }
        return .systemBlue
    }

    private var textColor: NSColor {
        isLowBatteryWarning ? tintColor : .labelColor
    }

    private var isLowBatteryWarning: Bool {
        !battery.isPluggedIn && battery.isCharging != true && battery.level <= 20
    }

    private var shouldStroke: Bool {
        battery.isPluggedIn || battery.isCharging == true || isLowBatteryWarning
    }

    private var strokeAlpha: CGFloat {
        if battery.isCharging == true { return 0.9 }
        if battery.isPluggedIn { return 0.7 }
        return battery.level <= 10 ? 0.9 : 0.78
    }

    private var fillAlpha: CGFloat {
        battery.isPluggedIn || battery.isCharging == true ? 0.26 : 0.16
    }

    static func preferredWidth(for level: Int) -> CGFloat {
        let text = "\(level)" as NSString
        let width = text.size(withAttributes: [.font: font]).width
        return ceil(width + horizontalPadding * 2)
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
    private var cachedCPU: MonitorInfo = SystemMonitor.default
    private var cachedMemory: MonitorInfo = SystemMonitor.default
    private var dualMetric: (cpu: MonitorInfo, memory: MonitorInfo)?
    private var cpuTimer: Timer?
    private var runnerTimer: Timer?
    private var batteryTimer: Timer?
    private var displayMode: DisplayMode = .both
    private var currentMode: MonitorMode = .combined
    private var caffeineMode: CaffeineMode = .off
    private var sleepAssertionID: IOPMAssertionID = 0
    private var dualMetricView: StatusDualMetricView?
    private var batteryStatusItem: NSStatusItem?
    private var batteryStatusView: BatteryStatusView?
    private var lastBatteryInfo: BatteryInfo?
    private var powerSourceRunLoopSource: CFRunLoopSource?
    private var showBatteryPercentage = false
    private var hideBatteryWhenCharging = true
    private var accessibilityRetryTimer: Timer?
    private var isCheckingForUpdates = false

    // Clipboard panel
    private var clipboardPanel: ClipboardPanel?
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var shortcutItems = [NSMenuItem]()
    private var shortcutMenuItem: NSMenuItem!
    private var hasReportedClipboardFailure = false
    private var clipboardStorageError: ClipboardError?
    private var isChangingRetention = false

    // Menu item references
    private var statusSummaryItem: NSMenuItem!
    private var monitorHeader: NSMenuItem!
    private var compactValuesItem: NSMenuItem!
    private var customDisplayItem: NSMenuItem!
    private var monitorDetailsSeparator: NSMenuItem!
    private var monitorSourceHeader: NSMenuItem!
    private var displayHeader: NSMenuItem!
    private var displayItems: [NSMenuItem] = []
    private var modeItems: [NSMenuItem] = []
    private var batteryHeader: NSMenuItem!
    private var showBatteryItem: NSMenuItem!
    private var hideBatteryOnPowerItem: NSMenuItem!
    private var sleepHeader: NSMenuItem!
    private var caffeineItems: [NSMenuItem] = []
    private var clipboardMenuItem: NSMenuItem!
    private var saveImagesItem: NSMenuItem!
    private var pauseCaptureItem: NSMenuItem!
    private var excludedAppsItem: NSMenuItem!
    private var clipboardStatusItem: NSMenuItem!
    private var retryHistoryItem: NSMenuItem!
    private var historyMenuItem: NSMenuItem!
    private var historyDaysItems: [NSMenuItem] = []
    private var customDaysItem: NSMenuItem!
    private var filterTermsItem: NSMenuItem!
    private var clearHistoryItem: NSMenuItem!
    private var languageMenuItem: NSMenuItem!
    private var languageItems: [NSMenuItem] = []
    private var reverseMouseScrollItem: NSMenuItem!
    private var accessibilityHintItem: NSMenuItem!
    private var openAccessibilityItem: NSMenuItem!
    private var newFileInFinderItem: NSMenuItem!
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
        migrateDisplayMode()
        cleanupLegacyFinderWorkflow()

        setupMenu()
        setupStatusItem()
        setupSleepWakeNotifications()
        restoreState()
        startRunning()
        setupClipboardShortcut()
        NotificationCenter.default.addObserver(self, selector: #selector(clipboardFailed(_:)), name: .DashCatClipboardFailed, object: ClipboardManager.shared)
        NotificationCenter.default.addObserver(self, selector: #selector(clipboardStatusChanged(_:)), name: .DashCatClipboardDidChange, object: ClipboardManager.shared)

        // Start clipboard monitoring (cleanupExpired runs inside ClipboardManager.init)
        ClipboardManager.shared.startPolling()
        if ScrollManager.shared.mouseReversed {
            ScrollManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let hotKeyHandler { RemoveEventHandler(hotKeyHandler) }
        clipboardPanel?.close()
        clipboardPanel = nil
        stopAccessibilityRetryTimer()
        stopRunning()
        stopPowerSourceMonitoring()
        removeBatteryStatusItem()
        ClipboardManager.shared.stopPolling()
        ScrollManager.shared.stop()
        if sleepAssertionID != 0 { IOPMAssertionRelease(sleepAssertionID) }
    }

    private func migrateDisplayMode() {
        let newKey = "DashCatDisplayMode"
        if UserDefaults.standard.string(forKey: newKey) == "dualValues" {
            UserDefaults.standard.set(MonitorMode.cpuMemory.rawValue, forKey: "DashCatMonitorMode")
            UserDefaults.standard.set(DisplayMode.pctOnly.rawValue, forKey: newKey)
            return
        }
        guard UserDefaults.standard.string(forKey: newKey) == nil else { return }
        let oldKey = "DashCatShowPercentage"
        if UserDefaults.standard.object(forKey: oldKey) != nil {
            let old = UserDefaults.standard.bool(forKey: oldKey)
            UserDefaults.standard.set(old ? DisplayMode.both.rawValue : DisplayMode.animOnly.rawValue,
                                      forKey: newKey)
            UserDefaults.standard.removeObject(forKey: oldKey)
        }
    }

    private func cleanupLegacyFinderWorkflow() {
        let workflowURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Services/DashCat New File.workflow", isDirectory: true)
        if FileManager.default.fileExists(atPath: workflowURL.path) {
            try? FileManager.default.removeItem(at: workflowURL)
            refreshServices()
        }
        UserDefaults.standard.removeObject(forKey: "DashCatFinderNewFileLanguage")
    }

    private func setupStatusItem() {
        statusItem.behavior = []
        statusItem.button?.imagePosition = .imageTrailing
        statusItem.button?.image = defaultFrames.first
        statusItem.button?.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        statusItem.button?.action = #selector(buttonClicked(_:))
        statusItem.button?.target = self
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusItemLength()
    }

    // MARK: - Menu Setup

    private func setupMenu() {
        menu.delegate = self

        statusSummaryItem = makeHeader()
        menu.addItem(statusSummaryItem)

        menu.addItem(.separator())

        // Monitor section
        monitorHeader = makeHeader()
        menu.addItem(monitorHeader)

        compactValuesItem = NSMenuItem(title: "", action: #selector(selectCompactValues(_:)), keyEquivalent: "")
        compactValuesItem.indentationLevel = 1
        menu.addItem(compactValuesItem)

        customDisplayItem = NSMenuItem(title: "", action: #selector(selectCustomDisplay(_:)), keyEquivalent: "")
        customDisplayItem.indentationLevel = 1
        menu.addItem(customDisplayItem)

        monitorDetailsSeparator = .separator()
        menu.addItem(monitorDetailsSeparator)

        monitorSourceHeader = makeHeader()
        monitorSourceHeader.indentationLevel = 1
        menu.addItem(monitorSourceHeader)
        for mode in [MonitorMode.combined, .cpu, .memory] {
            let item = NSMenuItem(title: "", action: #selector(selectMode(_:)), keyEquivalent: "")
            item.representedObject = mode
            item.indentationLevel = 2
            modeItems.append(item)
            menu.addItem(item)
        }

        displayHeader = makeHeader()
        displayHeader.indentationLevel = 1
        menu.addItem(displayHeader)
        for mode in [DisplayMode.animOnly, .both] {
            let item = NSMenuItem(title: "", action: #selector(selectDisplayMode(_:)), keyEquivalent: "")
            item.representedObject = mode
            item.indentationLevel = 2
            displayItems.append(item)
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Sleep prevention
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

        // Battery
        batteryHeader = makeHeader()
        menu.addItem(batteryHeader)

        showBatteryItem = NSMenuItem(title: "", action: #selector(toggleBatteryPercentage(_:)), keyEquivalent: "")
        showBatteryItem.indentationLevel = 1
        menu.addItem(showBatteryItem)

        hideBatteryOnPowerItem = NSMenuItem(title: "", action: #selector(toggleHideBatteryWhenCharging(_:)), keyEquivalent: "")
        hideBatteryOnPowerItem.indentationLevel = 1
        menu.addItem(hideBatteryOnPowerItem)

        menu.addItem(.separator())

        // Clipboard submenu
        clipboardMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let clipboardSubmenu = NSMenu()

        pauseCaptureItem = NSMenuItem(title: "", action: #selector(toggleClipboardCapture(_:)), keyEquivalent: "")
        clipboardSubmenu.addItem(pauseCaptureItem)
        excludedAppsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        excludedAppsItem.submenu = NSMenu()
        clipboardSubmenu.addItem(excludedAppsItem)
        clipboardStatusItem = makeHeader()
        clipboardSubmenu.addItem(clipboardStatusItem)
        retryHistoryItem = NSMenuItem(title: "", action: #selector(retryClipboardStorage(_:)), keyEquivalent: "")
        clipboardSubmenu.addItem(retryHistoryItem)
        clipboardSubmenu.addItem(.separator())

        saveImagesItem = NSMenuItem(title: "", action: #selector(toggleSaveImages(_:)), keyEquivalent: "")
        saveImagesItem.state = UserDefaults.standard.bool(forKey: "DashCatSaveImages") ? .on : .off
        clipboardSubmenu.addItem(saveImagesItem)

        historyMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let historySubmenu = NSMenu()
        for days in HistoryDays.allCases {
            let item = NSMenuItem(title: "", action: #selector(selectHistoryDays(_:)), keyEquivalent: "")
            item.representedObject = days
            if customHistoryDays == nil && days == historyDays { item.state = .on }
            historyDaysItems.append(item)
            historySubmenu.addItem(item)
        }
        historySubmenu.addItem(.separator())
        customDaysItem = NSMenuItem(title: "", action: #selector(selectCustomDays(_:)), keyEquivalent: "")
        historySubmenu.addItem(customDaysItem)
        historyMenuItem.submenu = historySubmenu
        clipboardSubmenu.addItem(historyMenuItem)

        filterTermsItem = NSMenuItem(title: "", action: #selector(editFilterTerms(_:)), keyEquivalent: "")
        clipboardSubmenu.addItem(filterTermsItem)

        clipboardSubmenu.addItem(.separator())

        clearHistoryItem = NSMenuItem(title: "", action: #selector(clearClipboardHistory(_:)), keyEquivalent: "")
        clipboardSubmenu.addItem(clearHistoryItem)

        shortcutMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let shortcuts = NSMenu()
        for (index, title) in ["", "⌘⇧V", "⌃⌥V", "⌃⇧Space"].enumerated() {
            let item = NSMenuItem(title: title, action: #selector(selectClipboardShortcut(_:)), keyEquivalent: "")
            item.representedObject = index
            item.target = self
            shortcutItems.append(item)
            shortcuts.addItem(item)
        }
        shortcutMenuItem.submenu = shortcuts
        clipboardSubmenu.addItem(shortcutMenuItem)
        clipboardMenuItem.submenu = clipboardSubmenu
        menu.addItem(clipboardMenuItem)

        // Mouse wheel scrolling
        reverseMouseScrollItem = NSMenuItem(title: "", action: #selector(toggleReverseMouseScroll(_:)), keyEquivalent: "")
        menu.addItem(reverseMouseScrollItem)

        accessibilityHintItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        accessibilityHintItem.isEnabled = false
        menu.addItem(accessibilityHintItem)

        openAccessibilityItem = NSMenuItem(title: "", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        menu.addItem(openAccessibilityItem)

        menu.addItem(.separator())

        // Finder new file
        newFileInFinderItem = NSMenuItem(title: "", action: #selector(createNewFileInFinder(_:)), keyEquivalent: "")
        menu.addItem(newFileInFinderItem)

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

    private func updateStatusSummary() {
        guard statusSummaryItem != nil else { return }
        statusSummaryItem.title = String(
            format: language.str("statusSummary"),
            "\(Int(cachedCPU.value.rounded()))%",
            "\(Int(cachedMemory.value.rounded()))%"
        )
        let detail = statusSummaryItem.title + "\n" + language.str("memoryUsageHint") + "\n" + language.str(caffeineMode.locKey)
            + "\n" + language.str(ClipboardManager.shared.isPaused ? "capturePausedHint" : "captureActive")
        statusItem.button?.toolTip = detail + "\n" + language.str("mainClickHint")
        statusItem.button?.setAccessibilityLabel("DashCat")
        statusItem.button?.setAccessibilityValue(detail)
        statusItem.button?.setAccessibilityHelp(language.str("mainClickHint"))
    }

    private func applyLanguage() {
        let l = language
        monitorHeader.title = l.str("monitor")
        compactValuesItem.title = l.str("compactValues")
        customDisplayItem.title = l.str("customDisplay")
        monitorSourceHeader.title = l.str("monitorSource")
        for item in displayItems {
            if let mode = item.representedObject as? DisplayMode {
                item.title = l.str(mode.locKey)
            }
        }
        displayHeader.title = l.str("display")
        for item in modeItems {
            if let mode = item.representedObject as? MonitorMode {
                item.title = l.str(mode.locKey)
            }
        }
        batteryHeader.title = l.str("battery")
        showBatteryItem.title = l.str("showCompactBattery")
        hideBatteryOnPowerItem.title = l.str("hideBatteryPluggedIn")
        sleepHeader.title = l.str("sleep")
        for item in caffeineItems {
            if let mode = item.representedObject as? CaffeineMode {
                item.title = l.str(mode.locKey)
            }
        }
        clipboardMenuItem.title = l.str("clipboardSettings")
        saveImagesItem.title    = l.str("saveImages")
        pauseCaptureItem.title = l.str(ClipboardManager.shared.isPaused ? "resumeCapture" : "pauseCapture")
        excludedAppsItem.title = l.str("excludedApps")
        retryHistoryItem.title = l.str("retry")
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
        filterTermsItem.title = l.str("filterTerms")
        clearHistoryItem.title  = l.str("clearHistory")
        shortcutMenuItem.title = l.str("clipboardShortcut")
        shortcutItems.first?.title = l.str("off")
        reverseMouseScrollItem.title = l.str("reverseMouseScroll")
        accessibilityHintItem.title = l.str("accessibilityNeeded")
        openAccessibilityItem.title = l.str("openAccessibility")
        newFileInFinderItem.title = l.str("newFileInFinder")
        launchAtLoginItem.title = l.str("launchLogin")
        helpMenuItem.title      = l.str("help")
        checkUpdatesItem.title  = isCheckingForUpdates ? l.str("updateChecking") : l.str("checkUpdates")
        checkUpdatesItem.isEnabled = !isCheckingForUpdates
        viewGitHubItem.title    = l.str("viewOnGitHub")
        contactItem.title       = l.str("contact")
        quitItem.title          = l.str("quit")
        updateStatusSummary()
        refreshHistoryMenuState()
        refreshClipboardMenuState()
    }

    // MARK: - Button

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            clipboardPanel?.close()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
        } else {
            toggleClipboardPanel()
        }
    }

    fileprivate func toggleClipboardPanel() {
        if clipboardPanel == nil {
            clipboardPanel = ClipboardPanel()
            clipboardPanel?.statusItem = statusItem
        }
        clipboardPanel?.toggle()
    }

    private func setupClipboardShortcut() {
        var type = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            let app = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { app.toggleClipboardPanel() }
            return noErr
        }, 1, &type, Unmanaged.passUnretained(self).toOpaque(), &hotKeyHandler)
        let saved = UserDefaults.standard.integer(forKey: "DashCatClipboardShortcut")
        if !registerShortcut(saved) { presentAlert(title: language.str("clipboardShortcut"), message: language.str("shortcutFailed")) }
        refreshShortcutState()
    }

    private func registerShortcut(_ index: Int) -> Bool {
        guard (0...3).contains(index) else { return false }
        var next: EventHotKeyRef?
        if index > 0 {
            guard hotKeyHandler != nil else { return false }
            let modifiers = [0, cmdKey | shiftKey, controlKey | optionKey, controlKey | shiftKey]
            let code = index == 3 ? kVK_Space : kVK_ANSI_V
            let id = EventHotKeyID(signature: 0x44434154, id: UInt32(index))
            guard RegisterEventHotKey(UInt32(code), UInt32(modifiers[index]), id, GetApplicationEventTarget(), 0, &next) == noErr else { return false }
        }
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = next
        return true
    }

    @objc private func selectClipboardShortcut(_ sender: NSMenuItem) {
        guard let index = sender.representedObject as? Int else { return }
        if index == UserDefaults.standard.integer(forKey: "DashCatClipboardShortcut"), (index == 0 || hotKey != nil) { return }
        if registerShortcut(index) {
            UserDefaults.standard.set(index, forKey: "DashCatClipboardShortcut")
        } else {
            presentAlert(title: language.str("clipboardShortcut"), message: language.str("shortcutFailed"))
        }
        refreshShortcutState()
    }

    private func refreshShortcutState() {
        let active = hotKey == nil ? 0 : UserDefaults.standard.integer(forKey: "DashCatClipboardShortcut")
        shortcutItems.forEach { $0.state = ($0.representedObject as? Int) == active ? .on : .off }
    }

    @objc private func clipboardFailed(_ notification: Notification) {
        let error = notification.userInfo?["error"] as? ClipboardError ?? .storage
        if error.requiresStorageRetry { clipboardStorageError = error }
        refreshClipboardMenuState()
        guard notification.userInfo?["alert"] as? Bool != false else { return }
        // Do not present an alert for every polling failure.
        guard !hasReportedClipboardFailure else { return }
        hasReportedClipboardFailure = true
        let committed = notification.userInfo?["committed"] as? Bool == true
        presentClipboardResult(ClipboardMutationResult(committed: committed, error: error))
    }

    @objc private func clipboardStatusChanged(_ notification: Notification) {
        if notification.userInfo?["storageRecovered"] as? Bool == true {
            clipboardStorageError = nil
            hasReportedClipboardFailure = false
        }
        refreshClipboardMenuState()
        updateStatusSummary()
    }

    private func presentClipboardResult(_ result: ClipboardMutationResult, successKey: String? = nil) {
        if let error = result.error {
            let detail = language.str(error.messageKey)
            presentAlert(title: language.str("clipboardSettings"), message: result.committed ? language.str("cleanupPending") + "\n\n" + detail : detail)
        } else if let successKey { presentAlert(title: language.str("clipboardSettings"), message: language.str(successKey)) }
    }

    @objc private func retryClipboardStorage(_ sender: NSMenuItem) {
        sender.isEnabled = false
        ClipboardManager.shared.retryStorage { [weak self] result in
            guard let self else { return }
            sender.isEnabled = true
            if result.succeeded { self.clipboardStorageError = nil; self.hasReportedClipboardFailure = false }
            self.refreshClipboardMenuState()
            self.presentClipboardResult(result)
        }
    }

    private func refreshClipboardMenuState() {
        guard pauseCaptureItem != nil else { return }
        pauseCaptureItem.title = language.str(ClipboardManager.shared.isPaused ? "resumeCapture" : "pauseCapture")
        pauseCaptureItem.state = ClipboardManager.shared.isPaused ? .on : .off
        clipboardStatusItem.title = language.str("clipboardNeedsAttention")
        clipboardStatusItem.toolTip = clipboardStorageError.map { language.str($0.messageKey) }
        clipboardStatusItem.isHidden = clipboardStorageError == nil
        retryHistoryItem.isHidden = clipboardStorageError == nil
        refreshExcludedAppsMenu()
    }

    private func refreshExcludedAppsMenu() {
        guard let submenu = excludedAppsItem.submenu else { return }
        submenu.removeAllItems()
        let excluded = ClipboardManager.shared.excludedApps()
        if let app = NSWorkspace.shared.frontmostApplication, let bundleID = app.bundleIdentifier,
           bundleID != Bundle.main.bundleIdentifier {
            let item = NSMenuItem(title: String(format: language.str("excludeCurrentApp"), app.localizedName ?? bundleID), action: #selector(toggleExcludedApp(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = bundleID
            item.state = excluded.contains(bundleID) ? .on : .off
            submenu.addItem(item)
        }
        let add = NSMenuItem(title: language.str("addExcludedApp"), action: #selector(addExcludedApplication(_:)), keyEquivalent: "")
        add.target = self
        submenu.addItem(add)
        if !excluded.isEmpty { submenu.addItem(.separator()) }
        for bundleID in excluded {
            let name = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
                .map { FileManager.default.displayName(atPath: $0.path) } ?? bundleID
            let item = NSMenuItem(title: name, action: #selector(toggleExcludedApp(_:)), keyEquivalent: "")
            item.target = self; item.representedObject = bundleID; item.state = .on
            item.toolTip = language.str("removeExcludedAppHint")
            submenu.addItem(item)
        }
    }

    @objc private func toggleExcludedApp(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        ClipboardManager.shared.setAppExcluded(bundleID, excluded: !ClipboardManager.shared.excludedApps().contains(bundleID))
        refreshClipboardMenuState()
    }

    @objc private func addExcludedApplication(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.prompt = language.str("addExcludedApp")
        activateAppForModal()
        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            if let bundleID = Bundle(url: url)?.bundleIdentifier { ClipboardManager.shared.setAppExcluded(bundleID, excluded: true) }
        }
        refreshClipboardMenuState()
    }

    // MARK: - Caffeine

    private func applyCaffeineMode(_ mode: CaffeineMode) {
        if sleepAssertionID != 0 {
            IOPMAssertionRelease(sleepAssertionID)
            sleepAssertionID = 0
        }
        var appliedMode = mode
        caffeineMode = mode
        if let type = mode.assertionType {
            let ret = IOPMAssertionCreateWithName(type,
                                                  IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                  "DashCat" as CFString,
                                                  &sleepAssertionID)
            if ret != kIOReturnSuccess {
                sleepAssertionID = 0
                appliedMode = .off
                caffeineMode = .off
                presentAlert(title: language.str("sleep"), message: language.str("operationFailed"))
            }
        }
        caffeineItems.forEach { $0.state = ($0.representedObject as? CaffeineMode) == appliedMode ? .on : .off }
        if displayMode == .pctOnly || currentMode == .cpuMemory {
            statusItem.button?.image = nil
        } else {
            let frames = currentFrames
            statusItem.button?.image = frames[index % frames.count]
        }
        applyMetricDisplay()
        updateStatusSummary()
        UserDefaults.standard.set(appliedMode.rawValue, forKey: "DashCatCaffeineMode")
        updateBatteryStatus(force: true)
    }

    // MARK: - Menu Actions

    @objc private func selectCompactValues(_ sender: NSMenuItem) {
        currentMode = .cpuMemory
        displayMode = .pctOnly
        UserDefaults.standard.set(currentMode.rawValue, forKey: "DashCatMonitorMode")
        UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        refreshDisplayMenuState()
        updateMetric()
    }

    @objc private func selectCustomDisplay(_ sender: NSMenuItem) {
        if currentMode == .cpuMemory {
            currentMode = .combined
            UserDefaults.standard.set(currentMode.rawValue, forKey: "DashCatMonitorMode")
        }
        if displayMode == .pctOnly {
            displayMode = .both
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        }
        refreshDisplayMenuState()
        updateMetric()
    }

    @objc private func selectDisplayMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? DisplayMode else { return }
        guard currentMode != .cpuMemory else { return }
        displayMode = mode
        refreshDisplayMenuState()
        UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        updateMetric()
    }

    @objc private func toggleBatteryPercentage(_ sender: NSMenuItem) {
        showBatteryPercentage.toggle()
        UserDefaults.standard.set(showBatteryPercentage, forKey: "DashCatShowBatteryPercentage")
        refreshBatteryMenuState()
        if showBatteryPercentage {
            setupPowerSourceMonitoring()
        } else {
            stopPowerSourceMonitoring()
            updateBatteryStatus(force: true)
        }
    }

    @objc private func toggleHideBatteryWhenCharging(_ sender: NSMenuItem) {
        hideBatteryWhenCharging.toggle()
        UserDefaults.standard.set(hideBatteryWhenCharging, forKey: "DashCatHideBatteryWhenCharging")
        refreshBatteryMenuState()
        updateBatteryStatus(force: true)
    }

    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? MonitorMode else { return }
        currentMode = mode
        if mode == .cpuMemory {
            displayMode = .pctOnly
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        } else if displayMode == .pctOnly {
            displayMode = .both
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        }
        refreshDisplayMenuState()
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

    @objc private func toggleClipboardCapture(_ sender: NSMenuItem) {
        ClipboardManager.shared.setPaused(!ClipboardManager.shared.isPaused)
        refreshClipboardMenuState()
        updateStatusSummary()
    }

    @objc private func selectHistoryDays(_ sender: NSMenuItem) {
        guard let days = sender.representedObject as? HistoryDays else { return }
        requestRetentionChange(days.rawValue)
    }

    @objc private func selectCustomDays(_ sender: NSMenuItem) {
        let l = language
        let alert = NSAlert()
        alert.messageText = l.str("customDays")
        alert.informativeText = l.str("customDaysPrompt")
        alert.addButton(withTitle: l.str("ok"))
        alert.addButton(withTitle: l.str("cancel"))

        let currentDays = customHistoryDays ?? (historyDays == .forever ? 30 : historyDays.rawValue)
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 100, height: 24))
        input.stringValue = "\(currentDays)"
        input.placeholderString = "1~365"
        alert.accessoryView = input

        activateAppForModal()
        alert.window.initialFirstResponder = input
        while alert.runModal() == .alertFirstButtonReturn {
            guard let days = Int(input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)), (1...365).contains(days) else {
                alert.informativeText = l.str("invalidDays")
                continue
            }
            requestRetentionChange(days)
            break
        }
    }

    private func refreshHistoryMenuState() {
        let saved = UserDefaults.standard.integer(forKey: "DashCatHistoryDays")
        let days = saved == 0 ? 30 : saved
        historyDaysItems.forEach { $0.state = ($0.representedObject as? HistoryDays)?.rawValue == days ? .on : .off }
        customDaysItem.state = HistoryDays(rawValue: days) == nil ? .on : .off
        customDaysItem.title = HistoryDays(rawValue: days) == nil ? "\(language.str("customDays")) (\(days))" : language.str("customDays")
        historyMenuItem.isEnabled = !isChangingRetention
    }

    private func requestRetentionChange(_ days: Int) {
        guard !isChangingRetention else { return }
        isChangingRetention = true
        refreshHistoryMenuState()
        ClipboardManager.shared.countExpiring(days: days) { [weak self] result in
            guard let self else { return }
            defer { self.isChangingRetention = false; self.refreshHistoryMenuState() }
            switch result {
            case .failure(let error):
                self.presentAlert(title: self.language.str("history"), message: self.language.str((error as? ClipboardError)?.messageKey ?? "clipboardFailure"))
            case .success(let count):
                if count > 0 {
                    let alert = NSAlert()
                    alert.messageText = self.language.str("retentionConfirmTitle")
                    alert.informativeText = String(format: self.language.str("retentionConfirmMessage"), "\(days)", "\(count)")
                    alert.addButton(withTitle: self.language.str("changeRetention"))
                    alert.addButton(withTitle: self.language.str("cancel"))
                    self.activateAppForModal()
                    guard alert.runModal() == .alertFirstButtonReturn else { return }
                }
                UserDefaults.standard.set(days, forKey: "DashCatHistoryDays")
                self.cleanupClipboardHistoryAfterRetentionChange()
            }
        }
    }

    private func cleanupClipboardHistoryAfterRetentionChange() {
        ClipboardManager.shared.cleanupExpired { [weak self] result in
            guard let self else { return }
            self.clipboardPanel?.reloadData()
            self.presentClipboardResult(result)
        }
    }

    @objc private func editFilterTerms(_ sender: NSMenuItem) {
        let l = language
        let alert = NSAlert()
        alert.messageText = l.str("filterTerms")
        alert.addButton(withTitle: l.str("ok"))
        alert.addButton(withTitle: l.str("cancel"))

        let accessory = FilterTermsAccessoryView(
            language: l,
            terms: ClipboardManager.shared.savedFilterTerms()
        )
        alert.accessoryView = accessory

        activateAppForModal()
        if alert.runModal() == .alertFirstButtonReturn {
            let terms = accessory.currentTerms()
            ClipboardManager.shared.setFilterTerms(terms)
        }
    }

    @objc private func clearClipboardHistory(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = language.str("clearHistoryConfirmTitle")
        alert.informativeText = language.str("clearHistoryConfirmMsg")
        alert.addButton(withTitle: language.str("clearUnpinned"))
        alert.addButton(withTitle: language.str("clearAllItems"))
        alert.addButton(withTitle: language.str("cancel"))

        activateAppForModal()
        let response = alert.runModal()
        let includePinned: Bool
        switch response {
        case .alertFirstButtonReturn:
            includePinned = false
        case .alertSecondButtonReturn:
            includePinned = true
        default:
            return
        }

        ClipboardManager.shared.clearAll(includePinned: includePinned) { [weak self] result in
            guard let self else { return }
            self.clipboardPanel?.reloadData()
            self.presentClipboardResult(result, successKey: "historyCleared")
        }
    }

    @objc private func toggleReverseMouseScroll(_ sender: NSMenuItem) {
        let newValue = sender.state == .off
        ScrollManager.shared.mouseReversed = newValue
        if newValue {
            if ScrollManager.shared.isTrusted {
                if !ScrollManager.shared.start() {
                    startAccessibilityRetryTimer()
                }
            } else {
                ScrollManager.shared.requestTrustPrompt()
                startAccessibilityRetryTimer()
            }
        } else {
            stopAccessibilityRetryTimer()
            ScrollManager.shared.stop()
        }
        refreshScrollState()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        if ScrollManager.shared.mouseReversed {
            ScrollManager.shared.requestTrustPrompt()
            startAccessibilityRetryTimer()
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func createNewFileInFinder(_ sender: NSMenuItem) {
        do {
            let defaultFolderURL: URL
            do { defaultFolderURL = try currentFinderFolderURL() }
            catch {
                let alert = NSAlert()
                alert.messageText = language.str("newFileCreateFail")
                let denied = (error as NSError).userInfo["NSAppleScriptErrorNumber"] as? Int == -1743
                alert.informativeText = language.str(denied ? "automationPermissionNeeded" : "finderFallback")
                alert.addButton(withTitle: language.str("chooseFolder"))
                alert.addButton(withTitle: language.str("cancel"))
                if denied { alert.addButton(withTitle: language.str("openSettings")) }
                activateAppForModal()
                let response = alert.runModal()
                if response == .alertThirdButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
                    return
                }
                guard response == .alertFirstButtonReturn,
                      let folder = chooseFolder(startingAt: FileManager.default.homeDirectoryForCurrentUser) else { return }
                defaultFolderURL = folder
            }
            guard let request = promptForNewFile(defaultFolderURL: defaultFolderURL) else { return }
            let fileURL = try createEmptyFile(in: request.folderURL,
                                              fileName: request.fileName,
                                              fileExtension: request.fileExtension)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch let error as NSError {
            NSLog("DashCat Finder new file failed: \(error)")
            let isPermissionError = error.code == 1 && (error.userInfo["NSAppleScriptErrorNumber"] as? Int) == -1743
            
            let alert = NSAlert()
            alert.messageText = language.str("newFileCreateFail")
            alert.informativeText = isPermissionError ? language.str("automationPermissionNeeded") : language.str("newFileCreateFailMsg")
            alert.addButton(withTitle: language.str("ok"))
            if isPermissionError {
                alert.addButton(withTitle: language.str("openSettings"))
            }
            activateAppForModal()
            if alert.runModal() == .alertSecondButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private func promptForNewFile(defaultFolderURL: URL) -> (folderURL: URL, fileName: String, fileExtension: String)? {
        let alert = NSAlert()
        alert.messageText = language.str("newFileInFinder")
        alert.addButton(withTitle: language.str("create"))
        alert.addButton(withTitle: language.str("cancel"))

        var selectedFolderURL = defaultFolderURL
        let accessory = NewFileAccessoryView(
            language: language,
            folderURL: selectedFolderURL,
            chooseFolder: { [weak self] currentFolder in
                guard let self else { return nil }
                return self.chooseFolder(startingAt: currentFolder)
            },
            folderChanged: { selectedFolderURL = $0 }
        )
        alert.accessoryView = accessory

        activateAppForModal()
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return (selectedFolderURL, accessory.selectedFileName, accessory.selectedFileExtension)
    }

    private func chooseFolder(startingAt folderURL: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = folderURL
        panel.prompt = language.str("chooseFolder")
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func currentFinderFolderURL() throws -> URL {
        let script = """
        tell application "Finder"
            if (count of Finder windows) > 0 then
                set targetFolder to target of front Finder window as alias
            else
                set targetFolder to path to desktop folder
            end if
            return POSIX path of targetFolder
        end tell
        """

        var errorInfo: NSDictionary?
        guard let output = NSAppleScript(source: script)?.executeAndReturnError(&errorInfo).stringValue,
              !output.isEmpty else {
            throw NSError(domain: "DashCat.NewFile", code: 1, userInfo: errorInfo as? [String: Any])
        }
        return URL(fileURLWithPath: output, isDirectory: true)
    }

    private func createEmptyFile(in folderURL: URL, fileName: String, fileExtension ext: String) throws -> URL {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw NSError(domain: "DashCat.NewFile", code: 2)
        }

        let baseName = normalizedFileBaseName(fileName, selectedExtension: ext)
        var index = 1
        while true {
            let suffix = index == 1 ? "" : " \(index)"
            let fileURL = folderURL.appendingPathComponent("\(baseName)\(suffix).\(ext)")
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                do {
                    try Data().write(to: fileURL, options: .withoutOverwriting)
                    return fileURL
                } catch let error as NSError {
                    if error.domain != NSCocoaErrorDomain || error.code != NSFileWriteFileExistsError { throw error }
                }
            }
            index += 1
        }
    }

    private func normalizedFileBaseName(_ fileName: String, selectedExtension ext: String) -> String {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = "Untitled"
        let cleaned = trimmed
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        guard !cleaned.isEmpty else { return fallback }
        let url = URL(fileURLWithPath: cleaned)
        if url.pathExtension.lowercased() == ext.lowercased() {
            let base = url.deletingPathExtension().lastPathComponent
            return base.isEmpty ? fallback : base
        }
        return cleaned
    }

    private func refreshServices() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
        task.arguments = ["-update"]
        try? task.run()
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        guard let lang = sender.representedObject as? Language else { return }
        language = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "DashCatLanguage")
        languageItems.forEach { $0.state = ($0.representedObject as? Language) == lang ? .on : .off }
        applyLanguage()
        updateBatteryStatus(force: true)
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
            presentAlert(title: language.str("launchLogin"), message: language.str("operationFailed"))
        }
        refreshLaunchAtLoginState()
        if SMAppService.mainApp.status == .requiresApproval {
            presentAlert(title: language.str("launchLogin"), message: language.str("loginApproval"))
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func refreshLaunchAtLoginState() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        launchAtLoginItem.state = isEnabled ? .on : .off
        UserDefaults.standard.set(isEnabled, forKey: "DashCatLaunchAtLogin")
    }

    private func refreshScrollState() {
        if ScrollManager.shared.mouseReversed && ScrollManager.shared.isTrusted {
            stopAccessibilityRetryTimer()
            if !ScrollManager.shared.start() {
                startAccessibilityRetryTimer()
            }
        }
        reverseMouseScrollItem.state = ScrollManager.shared.mouseReversed ? .on : .off
        let needsPermission = ScrollManager.shared.mouseReversed && !ScrollManager.shared.isTrusted
        accessibilityHintItem.isHidden = !needsPermission
        openAccessibilityItem.isHidden = !needsPermission
    }

    private func startAccessibilityRetryTimer() {
        accessibilityRetryTimer?.invalidate()
        var attempts = 0
        accessibilityRetryTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            guard ScrollManager.shared.mouseReversed else {
                timer.invalidate()
                self.accessibilityRetryTimer = nil
                return
            }
            attempts += 1
            if attempts > 240 {
                timer.invalidate()
                self.accessibilityRetryTimer = nil
                return
            }
            if ScrollManager.shared.isTrusted {
                if ScrollManager.shared.start() {
                    timer.invalidate()
                    self.accessibilityRetryTimer = nil
                    self.refreshScrollState()
                }
            }
        }
        if let timer = accessibilityRetryTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopAccessibilityRetryTimer() {
        accessibilityRetryTimer?.invalidate()
        accessibilityRetryTimer = nil
    }

    private func refreshBatteryMenuState() {
        showBatteryItem.state = showBatteryPercentage ? .on : .off
        hideBatteryOnPowerItem.state = hideBatteryWhenCharging ? .on : .off
        hideBatteryOnPowerItem.isHidden = !showBatteryPercentage
    }

    private func refreshDisplayMenuState() {
        let isCpuMemory = currentMode == .cpuMemory
        compactValuesItem.state = isCpuMemory ? .on : .off
        customDisplayItem.state = isCpuMemory ? .off : .on
        monitorDetailsSeparator.isHidden = isCpuMemory
        monitorSourceHeader.isHidden = isCpuMemory
        displayHeader.isHidden = isCpuMemory
        for item in modeItems {
            guard let mode = item.representedObject as? MonitorMode else { continue }
            item.state = (!isCpuMemory && mode == currentMode) ? .on : .off
            item.isHidden = isCpuMemory
        }
        for item in displayItems {
            guard let mode = item.representedObject as? DisplayMode else { continue }
            item.isHidden = isCpuMemory
            item.state = (!isCpuMemory && mode == displayMode) ? .on : .off
        }
    }

    private func setupPowerSourceMonitoring() {
        stopPowerSourceMonitoring()

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        if let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                appDelegate.updateBatteryStatus()
            }
        }, context)?.takeRetainedValue() {
            powerSourceRunLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }

        batteryTimer = Timer(timeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateBatteryStatus()
        }
        if let timer = batteryTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        updateBatteryStatus(force: true)
    }

    private func stopPowerSourceMonitoring() {
        batteryTimer?.invalidate()
        batteryTimer = nil
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            powerSourceRunLoopSource = nil
        }
    }

    private func updateBatteryStatus(force: Bool = false) {
        guard showBatteryPercentage else {
            lastBatteryInfo = nil
            removeBatteryStatusItem()
            return
        }
        guard let info = readBatteryInfo() else {
            lastBatteryInfo = nil
            removeBatteryStatusItem()
            return
        }

        let shouldHide = hideBatteryWhenCharging && info.isPluggedIn
        if shouldHide {
            lastBatteryInfo = info
            removeBatteryStatusItem()
            return
        }

        if force || lastBatteryInfo != info || batteryStatusItem == nil {
            applyBatteryInfo(info)
        }
        lastBatteryInfo = info
    }

    private func applyBatteryInfo(_ info: BatteryInfo) {
        let view = ensureBatteryStatusView(for: info)
        view.battery = info
        batteryStatusItem?.length = view.preferredWidth
        batteryStatusItem?.button?.toolTip = String(format: language.str("batteryTooltip"), "\(info.level)")
            + "\n" + language.str(caffeineMode.locKey) + "\n" + language.str("batteryClickHint")
        batteryStatusItem?.button?.setAccessibilityLabel(language.str("battery"))
        batteryStatusItem?.button?.setAccessibilityValue(String(format: language.str("batteryTooltip"), "\(info.level)") + ", " + language.str(caffeineMode.locKey))
        batteryStatusItem?.button?.setAccessibilityHelp(language.str("batteryClickHint"))
    }

    private func ensureBatteryStatusView(for info: BatteryInfo) -> BatteryStatusView {
        if let view = batteryStatusView {
            return view
        }

        let view = BatteryStatusView()
        view.battery = info
        batteryStatusView = view

        let item = NSStatusBar.system.statusItem(withLength: view.preferredWidth)
        item.behavior = []
        batteryStatusItem = item

        if let button = item.button {
            button.target = self
            button.action = #selector(batteryButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                view.topAnchor.constraint(equalTo: button.topAnchor),
                view.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
        }

        return view
    }

    @objc private func batteryButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showBatteryDetailsMenu()
        } else {
            cycleCaffeineMode()
        }
    }

    private func cycleCaffeineMode() {
        let nextRaw = caffeineMode.rawValue + 1
        let nextMode = CaffeineMode(rawValue: nextRaw) ?? .off
        applyCaffeineMode(nextMode)
    }

    private func showBatteryDetailsMenu() {
        guard let item = batteryStatusItem,
              let button = item.button,
              let info = lastBatteryInfo ?? readBatteryInfo() else {
            return
        }
        let menu = makeBatteryDetailsMenu(for: info)
        menu.delegate = self
        item.menu = menu
        button.performClick(nil)
    }

    private func makeBatteryDetailsMenu(for info: BatteryInfo) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(disabledMenuItem(language.str("battery")))
        menu.addItem(.separator())
        menu.addItem(disabledMenuItem(String(format: language.str("batteryLevel"), "\(info.level)")))

        let powerSource = info.isPluggedIn ? language.str("powerAdapter") : language.str("batteryPower")
        menu.addItem(disabledMenuItem(String(format: language.str("batteryPowerSource"), powerSource)))

        let status: String
        if info.isCharging == true {
            status = language.str("batteryCharging")
        } else if info.isPluggedIn && info.isCharging == nil {
            status = language.str("unknown")
        } else if info.isPluggedIn {
            status = language.str("batteryPluggedIn")
        } else {
            status = language.str("batteryDischarging")
        }
        menu.addItem(disabledMenuItem(String(format: language.str("batteryStatus"), status)))

        menu.addItem(.separator())
        let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled ? language.str("on") : language.str("off")
        menu.addItem(disabledMenuItem(String(format: language.str("lowPowerMode"), lowPower)))

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: language.str("batterySettings"),
                                      action: #selector(openBatterySettings),
                                      keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    private func disabledMenuItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func openBatterySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func removeBatteryStatusItem() {
        if let item = batteryStatusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        batteryStatusItem = nil
        batteryStatusView = nil
    }

    private func readBatteryInfo() -> BatteryInfo? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any] else {
                continue
            }
            if let transport = description[kIOPSTransportTypeKey as String] as? String,
               transport != kIOPSInternalType {
                continue
            }
            guard let current = doubleValue(description[kIOPSCurrentCapacityKey as String]),
                  let maximum = doubleValue(description[kIOPSMaxCapacityKey as String]),
                  maximum > 0 else {
                continue
            }

            let rawLevel = Int((current / maximum * 100).rounded())
            let level = min(100, max(0, rawLevel))
            let state = description[kIOPSPowerSourceStateKey as String] as? String
            let isPluggedIn = state == kIOPSACPowerValue
            let isCharging = boolValue(description[kIOPSIsChargingKey as String])
            return BatteryInfo(level: level, isPluggedIn: isPluggedIn, isCharging: isCharging)
        }
        return nil
    }

    private func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        return nil
    }

    private func boolValue(_ value: Any?) -> Bool? {
        if let number = value as? NSNumber { return number.boolValue }
        if let value = value as? Bool { return value }
        return nil
    }

    @objc private func terminateApp(_ sender: Any?) { NSApp.terminate(nil) }
    @objc private func receiveSleep() {
        stopRunning()
        stopPowerSourceMonitoring()
        ClipboardManager.shared.stopPolling()
    }
    @objc private func receiveWakeUp() {
        if showBatteryPercentage {
            setupPowerSourceMonitoring()
        }
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
        let cpu = monitor.cpuUsage()
        let mem = monitor.memoryUsage()
        cachedCPU = cpu
        cachedMemory = mem
        updateStatusSummary()
        dualMetric = nil
        if currentMode == .cpuMemory {
            dualMetric = (cpu, mem)
            metric = MonitorInfo(max(cpu.value, mem.value), "")
        } else {
            switch currentMode {
            case .cpu:
                metric = cpu
            case .memory:
                metric = mem
            case .cpuMemory:
                break
            case .combined:
                if cpu.value >= mem.value {
                    metric = MonitorInfo(cpu.value, "C" + cpu.description)
                } else {
                    metric = MonitorInfo(mem.value, "M" + mem.description)
                }
            }
        }

        runnerTimer?.invalidate()
        runnerTimer = nil
        guard displayMode != .pctOnly && currentMode != .cpuMemory else {
            statusItem.button?.image = nil
            applyMetricDisplay()
            return
        }
        applyMetricDisplay()
        let frames = currentFrames
        statusItem.button?.image = frames[index % frames.count]
        updateStatusItemLength()

        let t = min(metric.value / 100.0, 1.0)
        let fps = 1.0 + 11.0 * t
        let interval = 1.0 / fps
        runnerTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.nextFrame()
        }
        if let timer = runnerTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func nextFrame() {
        let frames = currentFrames
        index = (index + 1) % frames.count
        statusItem.button?.image = frames[index]
    }

    // MARK: - Display

    private func applyMetricDisplay() {
        if currentMode == .cpuMemory {
            applyDualMetricDisplay()
            return
        }
        removeDualMetricView()
        guard displayMode != .animOnly else {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString()
            updateStatusItemLength()
            return
        }
        if currentMode == .combined {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = makeStackedTitle(metric.description)
        } else if let textColor = metricTextColor {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString(string: metric.description, attributes: [
                .font: StatusMetricLayout.singleFont,
                .baselineOffset: StatusMetricLayout.singleBaselineOffset,
                .foregroundColor: textColor
            ])
        } else {
            statusItem.button?.title = ""
            statusItem.button?.attributedTitle = NSAttributedString(string: metric.description, attributes: [
                .font: StatusMetricLayout.singleFont,
                .baselineOffset: StatusMetricLayout.singleBaselineOffset
            ])
        }
        updateStatusItemLength()
    }

    private func applyDualMetricDisplay() {
        guard let button = statusItem.button else { return }
        let metrics = dualMetric ?? (cpu: SystemMonitor.default, memory: SystemMonitor.default)
        button.title = ""
        button.attributedTitle = NSAttributedString()
        button.image = nil

        let view: StatusDualMetricView
        if let existing = dualMetricView {
            view = existing
        } else {
            view = StatusDualMetricView()
            dualMetricView = view
            button.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                view.topAnchor.constraint(equalTo: button.topAnchor),
                view.bottomAnchor.constraint(equalTo: button.bottomAnchor)
            ])
        }

        view.cpu = metrics.cpu
        view.memory = metrics.memory
        view.textColor = metricTextColor ?? .labelColor
        statusItem.length = view.preferredWidth
    }

    private func removeDualMetricView() {
        dualMetricView?.removeFromSuperview()
        dualMetricView = nil
    }

    private func updateStatusItemLength() {
        guard let button = statusItem.button else { return }
        if currentMode != .cpuMemory,
           currentMode == .combined,
           button.attributedTitle.length > 0 {
            statusItem.length = NSStatusItem.variableLength
            return
        }
        let imageWidth = button.image?.size.width ?? 0
        let attributedWidth = button.attributedTitle.length > 0 ? button.attributedTitle.size().width : 0
        let plainWidth: CGFloat
        if attributedWidth > 0 {
            plainWidth = 0
        } else if !button.title.isEmpty {
            plainWidth = (button.title as NSString).size(withAttributes: [.font: button.font ?? NSFont.systemFont(ofSize: 11)]).width
        } else {
            plainWidth = 0
        }
        let textWidth = max(attributedWidth, plainWidth)
        let contentGap: CGFloat = 0
        let sidePadding: CGFloat = textWidth > 0 ? 0 : 2
        statusItem.length = ceil(imageWidth + textWidth + contentGap + sidePadding * 2)
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
            .font: StatusMetricLayout.combinedValueFont,
            .paragraphStyle: para
        ]
        var labelAttributes: [NSAttributedString.Key: Any] = [
            .font: StatusMetricLayout.combinedLabelFont,
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

    // MARK: - Check for Updates

    @objc private func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        applyLanguage()

        let url = URL(string: "https://github.com/vivalucas/dashcat/releases/latest")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("DashCat/\(bundleVersion)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            let tag = Self.releaseTag(from: response)
            DispatchQueue.main.async {
                guard let self else { return }
                self.isCheckingForUpdates = false
                self.applyLanguage()
                if let tag {
                    self.handleUpdateTag(tag)
                } else {
                    self.handleUpdateFailure(error: error)
                }
            }
        }.resume()
    }

    private var bundleVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private static func releaseTag(from response: URLResponse?) -> String? {
        guard let response = response as? HTTPURLResponse,
              (200..<400).contains(response.statusCode),
              let url = response.url else {
            return nil
        }
        let pathComponents = url.pathComponents
        guard let tagIndex = pathComponents.firstIndex(of: "tag") else {
            return nil
        }
        let versionIndex = pathComponents.index(after: tagIndex)
        guard pathComponents.indices.contains(versionIndex) else {
            return nil
        }
        return pathComponents[versionIndex]
    }

    private func handleUpdateFailure(error: Error?) {
        let l = language
        if let error {
            NSLog("DashCat update check failed: \(error.localizedDescription)")
        }
        presentAlert(title: l.str("updateFail"),
                     message: l.str("updateFailMsg"))
    }

    private func handleUpdateTag(_ tag: String) {
        let l = language
        let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
        let local  = bundleVersion
        if isNewerVersion(remote, than: local) {
            let alert = NSAlert()
            alert.messageText     = l.str("updateAvail")
            alert.informativeText = String(format: l.str("updateAvailMsg"), remote, local)
            alert.addButton(withTitle: l.str("download"))
            alert.addButton(withTitle: l.str("later"))
            activateAppForModal()
            if alert.runModal() == .alertFirstButtonReturn { openRelease(tag: tag) }
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

    private func openRelease(tag: String) {
        let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? tag
        NSWorkspace.shared.open(URL(string: "https://github.com/vivalucas/dashcat/releases/tag/\(encodedTag)")!)
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
        } else {
            currentMode = .cpuMemory
            UserDefaults.standard.set(currentMode.rawValue, forKey: "DashCatMonitorMode")
        }
        // Restore display mode (default: compact values)
        if let modeStr = UserDefaults.standard.string(forKey: "DashCatDisplayMode"),
           let mode = DisplayMode(rawValue: modeStr) {
            displayMode = mode
        } else {
            displayMode = .pctOnly
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        }
        if currentMode == .cpuMemory {
            displayMode = .pctOnly
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        } else if displayMode == .pctOnly {
            displayMode = .both
            UserDefaults.standard.set(displayMode.rawValue, forKey: "DashCatDisplayMode")
        }
        refreshDisplayMenuState()
        refreshClipboardMenuState()
        refreshHistoryMenuState()
        switch displayMode {
        case .pctOnly:
            statusItem.button?.image = nil
            applyMetricDisplay()
        case .animOnly:
            if currentMode == .cpuMemory { applyMetricDisplay() }
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
        showBatteryPercentage = UserDefaults.standard.bool(forKey: "DashCatShowBatteryPercentage")
        if UserDefaults.standard.object(forKey: "DashCatHideBatteryWhenCharging") == nil {
            hideBatteryWhenCharging = true
            UserDefaults.standard.set(true, forKey: "DashCatHideBatteryWhenCharging")
        } else {
            hideBatteryWhenCharging = UserDefaults.standard.bool(forKey: "DashCatHideBatteryWhenCharging")
        }
        refreshBatteryMenuState()
        if showBatteryPercentage {
            setupPowerSourceMonitoring()
        } else {
            updateBatteryStatus(force: true)
        }
        refreshLaunchAtLoginState()
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        guard menu === self.menu else { return }
        updateStatusSummary()
        refreshLaunchAtLoginState()
        refreshScrollState()
        refreshBatteryMenuState()
        refreshDisplayMenuState()
        refreshClipboardMenuState()
        refreshHistoryMenuState()
    }

    func menuDidClose(_ menu: NSMenu) {
        if statusItem.menu === menu {
            statusItem.menu = nil
        }
        if batteryStatusItem?.menu === menu {
            batteryStatusItem?.menu = nil
        }
    }
}

private final class NewFileAccessoryView: NSView {
    private let language: Language
    private var folderURL: URL
    private let chooseFolder: (URL) -> URL?
    private let folderChanged: (URL) -> Void
    private let nameField = NSTextField(string: "Untitled")
    private let pathField = NSTextField(labelWithString: "")
    private let txtButton = NSButton(radioButtonWithTitle: "TXT", target: nil, action: nil)
    private let markdownButton = NSButton(radioButtonWithTitle: "Markdown", target: nil, action: nil)

    var selectedFileName: String {
        nameField.stringValue
    }

    var selectedFileExtension: String {
        markdownButton.state == .on ? "md" : "txt"
    }

    init(language: Language,
         folderURL: URL,
         chooseFolder: @escaping (URL) -> URL?,
         folderChanged: @escaping (URL) -> Void) {
        self.language = language
        self.folderURL = folderURL
        self.chooseFolder = chooseFolder
        self.folderChanged = folderChanged
        super.init(frame: NSRect(x: 0, y: 0, width: 520, height: 140))
        build()
        updatePath()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func build() {
        let typeLabel = NSTextField(labelWithString: language.str("newFileTypePrompt"))
        typeLabel.frame = NSRect(x: 0, y: 116, width: 520, height: 18)

        txtButton.frame = NSRect(x: 0, y: 90, width: 90, height: 22)
        markdownButton.frame = NSRect(x: 92, y: 90, width: 130, height: 22)
        txtButton.target = self
        txtButton.action = #selector(selectFileType(_:))
        markdownButton.target = self
        markdownButton.action = #selector(selectFileType(_:))
        txtButton.state = .on

        let nameLabel = NSTextField(labelWithString: language.str("fileName"))
        nameLabel.frame = NSRect(x: 0, y: 62, width: 96, height: 18)

        nameField.frame = NSRect(x: 98, y: 58, width: 422, height: 24)
        nameField.font = NSFont.systemFont(ofSize: 13)
        nameField.placeholderString = "Untitled"

        let folderLabel = NSTextField(labelWithString: language.str("newFileTarget"))
        folderLabel.frame = NSRect(x: 0, y: 32, width: 520, height: 18)

        pathField.frame = NSRect(x: 0, y: 8, width: 330, height: 18)
        pathField.lineBreakMode = .byTruncatingMiddle

        let chooseButton = NSButton(title: language.str("chooseFolder"), target: self, action: #selector(chooseOtherFolder))
        chooseButton.frame = NSRect(x: 342, y: 0, width: 178, height: 30)
        chooseButton.bezelStyle = .rounded

        addSubview(typeLabel)
        addSubview(txtButton)
        addSubview(markdownButton)
        addSubview(nameLabel)
        addSubview(nameField)
        addSubview(folderLabel)
        addSubview(pathField)
        addSubview(chooseButton)
    }

    @objc private func selectFileType(_ sender: NSButton) {
        txtButton.state = sender === txtButton ? .on : .off
        markdownButton.state = sender === markdownButton ? .on : .off
    }

    @objc private func chooseOtherFolder() {
        guard let url = chooseFolder(folderURL) else { return }
        folderURL = url
        folderChanged(url)
        updatePath()
    }

    private func updatePath() {
        pathField.stringValue = displayPath(for: folderURL)
        pathField.toolTip = folderURL.path
    }

    private func displayPath(for url: URL) -> String {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path == homePath { return "~" }
        if url.path.hasPrefix(homePath + "/") {
            return "~" + String(url.path.dropFirst(homePath.count))
        }
        return url.path
    }
}

private final class FilterTermsAccessoryView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let helperLabel = NSTextField(labelWithString: "")
    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    init(language: Language, terms: [String]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 420, height: 260))
        build(language: language, terms: terms)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func currentTerms() -> [String] {
        textView.string.components(separatedBy: .newlines)
    }

    private func build(language: Language, terms: [String]) {
        titleLabel.stringValue = language.str("filterTerms")
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.frame = NSRect(x: 0, y: 238, width: 420, height: 18)

        helperLabel.stringValue = language.str("filterTermsHelp")
        helperLabel.font = NSFont.systemFont(ofSize: 11)
        helperLabel.textColor = .secondaryLabelColor
        helperLabel.frame = NSRect(x: 0, y: 184, width: 420, height: 44)
        helperLabel.maximumNumberOfLines = 3
        helperLabel.lineBreakMode = .byWordWrapping

        scrollView.frame = NSRect(x: 0, y: 0, width: 420, height: 176)
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true

        textView.frame = scrollView.bounds
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.string = terms.joined(separator: "\n")
        textView.textContainerInset = NSSize(width: 7, height: 8)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        scrollView.documentView = textView

        addSubview(titleLabel)
        addSubview(helperLabel)
        addSubview(scrollView)
    }
}
