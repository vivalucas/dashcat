# 环境、换机与运维

> 适用状态：启用。项目仅支持 macOS 开发和运行。

## 环境矩阵

| 环境 | 工具链依据 | 安装与启动入口 | 已验证范围 |
| --- | --- | --- | --- |
| macOS 13+ / Apple Silicon | Xcode、系统 Swift 与 macOS SDK；`DashCat.xcodeproj` | Xcode 打开工程，选择 `DashCat` scheme 后运行 | 2.5.0 Debug/Release 无签名构建曾通过 |
| Intel macOS | 不支持 | 不适用 | 未构建 |
| Windows / Linux | 不支持 AppKit 应用 | 不适用 | 未验证 |

项目没有环境变量、包管理器依赖或外部服务密钥。不要为换机复制 DerivedData 或运行时数据库；克隆仓库后使用本机 Xcode 构建。

## 权限与配置

| 配置 | 用途 | 必需性 / 位置 |
| --- | --- | --- |
| 辅助功能 | `CGEventTap` 反转传统鼠标滚轮 | 只在启用该功能时需要；系统设置 → 隐私与安全性 → 辅助功能 |
| 自动化 / Finder | 获取 Finder 当前窗口目录 | 首次使用新建文件时可能请求；拒绝后可手选目录 |
| 登录项 | 开机启动 | 用户启用后由 `SMAppService` 管理 |
| 剪贴板 | 监控和回写 | 使用系统 `NSPasteboard`；历史保存在 Application Support |

`Info.plist` 的关键项为 `LSUIElement`、`NSAppleEventsUsageDescription` 和 `ITSAppUsesNonExemptEncryption`。entitlements 明确关闭 App Sandbox，并包含 `com.apple.security.automation.apple-events` 以支持 Hardened Runtime 下的 Finder 授权。

回归命令和构建方式见 [10](10-quality.md)，发行见 [08](08-deployment.md)。
