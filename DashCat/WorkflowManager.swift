import Foundation
import os.log

final class WorkflowManager {
    static let shared = WorkflowManager()

    private let logger = Logger(subsystem: "com.dashcat.app", category: "WorkflowManager")
    private let servicesDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Services", isDirectory: true)
    private let workflowName = "DashCat New File.workflow"
    private let installedLanguageKey = "DashCatFinderNewFileLanguage"

    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: workflowURL.path)
    }

    private var workflowURL: URL {
        servicesDir.appendingPathComponent(workflowName, isDirectory: true)
    }

    private init() {}

    func install(language: Language) throws {
        let text = WorkflowText(language: language)
        let temporaryURL = temporaryWorkflowURL()
        do {
            let contentsDir = temporaryURL.appendingPathComponent("Contents", isDirectory: true)
            try FileManager.default.createDirectory(at: contentsDir, withIntermediateDirectories: true)

            try writeWorkflowDocument(to: contentsDir.appendingPathComponent("document.wflow"), text: text)
            try writeInfoPlist(to: contentsDir.appendingPathComponent("Info.plist"), text: text)

            if FileManager.default.fileExists(atPath: workflowURL.path) {
                _ = try FileManager.default.replaceItemAt(
                    workflowURL,
                    withItemAt: temporaryURL,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try FileManager.default.moveItem(at: temporaryURL, to: workflowURL)
            }

            UserDefaults.standard.set(language.rawValue, forKey: installedLanguageKey)
            refreshServices()
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            UserDefaults.standard.removeObject(forKey: installedLanguageKey)
            throw error
        }
    }

    func uninstall() throws {
        if FileManager.default.fileExists(atPath: workflowURL.path) {
            try FileManager.default.removeItem(at: workflowURL)
        }
        UserDefaults.standard.removeObject(forKey: installedLanguageKey)
        refreshServices()
    }

    func refreshLocalizationIfNeeded(language: Language) {
        guard isInstalled else {
            UserDefaults.standard.removeObject(forKey: installedLanguageKey)
            return
        }
        guard UserDefaults.standard.string(forKey: installedLanguageKey) != language.rawValue else { return }
        do {
            try install(language: language)
        } catch {
            logger.error("Failed to refresh Finder New File localization: \(error.localizedDescription)")
        }
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

    private func temporaryWorkflowURL() -> URL {
        let name = ".DashCat New File-\(UUID().uuidString).workflow"
        return servicesDir.appendingPathComponent(name, isDirectory: true)
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
        serviceName = language.str("newFileServiceName")
        dialogTitle = language.str("newFileServiceName")
        dialogPrompt = language.str("newFileDialogPrompt")
    }
}
