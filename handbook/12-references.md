# 外部服务与参考资料

> 适用状态：启用。项目主要依赖 Apple 系统框架和 GitHub Releases；不在此复制官方文档。

| 服务 / 资料 | 官方来源或原件位置 | 本项目用途 | 当前实现入口 |
| --- | --- | --- | --- |
| AppKit / Foundation | Apple Developer Documentation | 状态项、菜单、NSPanel、pasteboard、文件与网络基础 | `AppDelegate.swift`、`ClipboardPanel.swift`、`ClipboardManager.swift` |
| Carbon Hot Key API | Apple SDK | 可选全局快捷键 | `AppDelegate.swift` |
| IOKit Power Sources / IOPMAssertion | Apple SDK | 电量与防休眠 | `AppDelegate.swift` |
| CoreGraphics / ApplicationServices | Apple SDK | 鼠标滚轮 event tap | `ScrollManager.swift` |
| ServiceManagement | Apple SDK | 开机启动 | `AppDelegate.swift` |
| Apple Events / Finder | Apple SDK 与 macOS 权限设置 | 获取 Finder 当前窗口目录 | `AppDelegate.swift`、`DashCat.entitlements` |
| SQLite3 | macOS SDK | 剪贴板历史 | `ClipboardManager.swift` |
| GitHub Releases | 仓库 Releases 与 Actions | 更新检查、DMG 发行 | `AppDelegate.swift`、`.github/workflows/release.yml` |

系统 API 行为应以目标 macOS SDK 和 Apple 官方资料为准；升级部署目标、Xcode 或相关实现时重新核对。GitHub workflow actions 版本变化时检查官方 action 文档。这里不缓存易过期的参数表，也不把代码中的调用细节复制成第二份契约。
