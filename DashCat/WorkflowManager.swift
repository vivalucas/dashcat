import Foundation
import os.log

final class WorkflowManager {
    static let shared = WorkflowManager()

    private let logger = Logger(subsystem: "com.dashcat.app", category: "WorkflowManager")
    private let servicesDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Services", isDirectory: true)
    private let workflowName = "DashCat New File.workflow"

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: workflowURL.path)
    }

    private var workflowURL: URL {
        servicesDir.appendingPathComponent(workflowName, isDirectory: true)
    }

    private init() {}

    func install(language: Language) throws {
        let text = WorkflowText(language: language)
        do {
            try? FileManager.default.removeItem(at: workflowURL)

            let contentsDir = workflowURL.appendingPathComponent("Contents", isDirectory: true)
            try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)

            try writeWorkflowDocument(to: contentsDir.appendingPathComponent("document.wflow"), text: text)
            try writeInfoPlist(to: contentsDir.appendingPathComponent("Info.plist"), text: text)
            refreshServices()
        } catch {
            try? FileManager.default.removeItem(at: workflowURL)
            refreshServices()
            throw error
        }
    }

    func uninstall() throws {
        if FileManager.default.fileExists(atPath: workflowURL.path) {
            try FileManager.default.removeItem(at: workflowURL)
        }
        refreshServices()
    }

    private func writeWorkflowDocument(to url: URL, text: WorkflowText) throws {
        let document: [String: Any] = [
            "AMApplicationBuild": "521.1",
            "AMApplicationVersion": "2.10",
            "AMDocumentVersion": "2",
            "actions": [[
                "action": [
                    "AMAccepts": [
                        "Container": "List",
                        "Optional": true,
                        "Types": ["com.apple.cocoa.path"]
                    ],
                    "AMActionVersion": "2.0.3",
                    "AMApplication": ["Finder"],
                    "AMParameterProperties": [
                        "COMMAND_STRING": [:],
                        "inputMethod": [:],
                        "shell": [:],
                        "source": [:]
                    ],
                    "AMProvides": [
                        "Container": "List",
                        "Types": ["com.apple.cocoa.path"]
                    ],
                    "ActionBundlePath": "/System/Library/Automator/Run Shell Script.action",
                    "ActionName": "Run Shell Script",
                    "ActionParameters": [
                        "COMMAND_STRING": shellScript(text: text),
                        "inputMethod": 1,
                        "shell": "/bin/zsh",
                        "source": ""
                    ],
                    "BundleIdentifier": "com.apple.automator.RunShellScript",
                    "CFBundleVersion": "2.0.3",
                    "CanShowSelectedItemsWhen": false,
                    "CanShowWhenRun": false,
                    "Category": ["AMCategoryUtilities"],
                    "Class Name": "RunShellScriptAction",
                    "InputUUID": "inputUUID-\(UUID().uuidString)",
                    "Keywords": ["Shell"],
                    "OutputUUID": "outputUUID-\(UUID().uuidString)",
                    "UUID": UUID().uuidString,
                    "UnlocalizedApplications": ["Finder"],
                    "arguments": [],
                    "isViewVisible": true,
                    "location": "309.5:253",
                    "nibPath": "/System/Library/Automator/Run Shell Script.action/Contents/Resources/English.lproj/main.nib"
                ],
                "isViewVisible": true
            ]],
            "connectors": [:],
            "workflowMetaData": [
                "applicationBundleIDsByPath": [:],
                "applicationPathsByBundleID": [:],
                "inputTypeIdentifier": "com.apple.Automator.fileSystemObject",
                "outputTypeIdentifier": "com.apple.Automator.nothing",
                "presentationMode": 11,
                "processesInput": 0,
                "serviceInputTypeIdentifier": "com.apple.Automator.fileSystemObject",
                "serviceOutputTypeIdentifier": "com.apple.Automator.nothing",
                "serviceProcessesInput": 1,
                "shouldShowSelectedItemsWhen": 0,
                "shouldUseSelectedItems": 1,
                "subtypes": [[
                    "inputTypeIdentifier": "com.apple.Automator.fileSystemObject"
                ]],
                "workflowTypeIdentifier": "com.apple.Automator.servicesMenu"
            ]
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: document, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    private func writeInfoPlist(to url: URL, text: WorkflowText) throws {
        let info: [String: Any] = [
            "NSServices": [[
                "NSMenuItem": ["default": text.serviceName],
                "NSMessage": "runWorkflowAsService",
                "NSSendFileTypes": ["public.item"],
                "NSRequiredContext": ["NSApplicationIdentifier": "com.apple.finder"]
            ]]
        ]

        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: url, options: .atomic)
    }

    private func refreshServices() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/System/Library/CoreServices/pbs")
        task.arguments = ["-update"]
        do {
            try task.run()
        } catch {
            logger.error("Failed to refresh services: \(error.localizedDescription)")
        }
    }

    private func shellScript(text: WorkflowText) -> String {
        let title = appleScriptString(text.dialogTitle)
        let prompt = appleScriptString(text.dialogPrompt)
        return """
        set -e

        if [[ $# -gt 0 ]]; then
            first="$1"
            if [[ -d "$first" ]]; then
                folder="$first"
            else
                folder="$(/usr/bin/dirname "$first")"
            fi
        else
            folder="$(/usr/bin/osascript <<'APPLESCRIPT'
        tell application "Finder"
            if (count of Finder windows) > 0 then
                set targetFolder to target of front Finder window as alias
            else
                set targetFolder to path to desktop folder
            end if
            return POSIX path of targetFolder
        end tell
        APPLESCRIPT
            )"
        fi

        ext="$(/usr/bin/osascript <<'APPLESCRIPT'
        set choices to {"TXT", "Markdown"}
        set picked to choose from list choices with title \(title) with prompt \(prompt) default items {"TXT"}
        if picked is false then
            return ""
        end if
        if item 1 of picked is "Markdown" then
            return "md"
        end if
        return "txt"
        APPLESCRIPT
        )"

        if [[ -z "$ext" ]]; then
            exit 0
        fi

        base="Untitled"
        name="${base}.${ext}"
        path="${folder%/}/${name}"
        count=2

        while [[ -e "$path" ]]; do
            name="${base} ${count}.${ext}"
            path="${folder%/}/${name}"
            count=$((count + 1))
        done

        : > "$path"
        /usr/bin/open -R "$path"
        """
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

private struct WorkflowText {
    let serviceName: String
    let dialogTitle: String
    let dialogPrompt: String

    init(language: Language) {
        switch language {
        case .chinese:
            serviceName = "新建文件"
            dialogTitle = "新建文件"
            dialogPrompt = "选择文件类型："
        case .traditionalChinese:
            serviceName = "新建檔案"
            dialogTitle = "新建檔案"
            dialogPrompt = "選擇檔案類型："
        case .english:
            serviceName = "New File"
            dialogTitle = "New File"
            dialogPrompt = "Choose file type:"
        case .japanese:
            serviceName = "新規ファイル"
            dialogTitle = "新規ファイル"
            dialogPrompt = "ファイル形式を選択："
        case .korean:
            serviceName = "새 파일"
            dialogTitle = "새 파일"
            dialogPrompt = "파일 형식 선택:"
        case .german:
            serviceName = "Neue Datei"
            dialogTitle = "Neue Datei"
            dialogPrompt = "Dateityp wählen:"
        case .french:
            serviceName = "Nouveau fichier"
            dialogTitle = "Nouveau fichier"
            dialogPrompt = "Choisissez le type de fichier :"
        case .spanish:
            serviceName = "Nuevo archivo"
            dialogTitle = "Nuevo archivo"
            dialogPrompt = "Elige el tipo de archivo:"
        case .portugueseBrazil:
            serviceName = "Novo arquivo"
            dialogTitle = "Novo arquivo"
            dialogPrompt = "Escolha o tipo de arquivo:"
        case .italian:
            serviceName = "Nuovo file"
            dialogTitle = "Nuovo file"
            dialogPrompt = "Scegli il tipo di file:"
        case .russian:
            serviceName = "Новый файл"
            dialogTitle = "Новый файл"
            dialogPrompt = "Выберите тип файла:"
        }
    }
}
