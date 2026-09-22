# 项目定义

> 状态：已初始化；事实依据为当前 `main` 的 2.5.0 代码、工程配置与用户 README。

## 目标与边界

DashCat 是面向 Apple Silicon、macOS 13 及以上用户的轻量菜单栏工具。它把系统负载展示、剪贴板历史、防休眠、外接鼠标滚轮反转、极简电量显示和 Finder 新建文件集中在一个本地应用中，减少菜单栏图标、后台进程和配置入口。

成功标准：常用能力可从菜单栏直接完成；剪贴板数据仅保存在本机；常驻资源开销和依赖数量保持低；权限缺失不拖累无关功能。

核心能力与验收入口见 [02 功能设计](02-function-design.md)，近期状态见 [01 当前状态](01-current-status.md)。

明确不做：

- 独立设置窗口、完整电池管理、健康曲线或高能耗 App 列表。
- OCR、Paste Stack、模糊/正则搜索、富文本历史或跨设备同步。
- Finder Sync Extension 或伪装成 Finder 空白处右键菜单。
- 自建 HTTP 服务、第三方运行时依赖或额外常驻后台服务。
- Intel 构建；当前发行仅面向 arm64。

关键术语：主状态项（菜单栏猫咪）、电量状态项、Clipboard Panel（剪贴板浮窗）、MonitorMode（监控来源）、DisplayMode（呈现方式）、CaffeineMode（休眠抑制状态）。

## 技术与配置依据

| 项目 | 实际选择 | 版本 / 配置依据 | 核对日期 |
| --- | --- | --- | --- |
| 运行时与 UI | Swift + AppKit，单进程 macOS 应用 | `DashCat.xcodeproj`、`DashCat/*.swift`；部署目标 macOS 13 | 2026-09-22 |
| 数据 | 系统 `libsqlite3` + Application Support 图片文件 | `ClipboardManager.swift`；无 ORM、无独立迁移工具 | 2026-09-22 |
| 系统能力 | IOKit、CoreGraphics、ApplicationServices、Carbon、ServiceManagement、AppleScript | 工程链接项与实现导入 | 2026-09-22 |
| 发行 | GitHub Actions 构建 arm64 DMG，标签 `v*` 触发 | `.github/workflows/release.yml` | 2026-09-22 |
| 依赖策略 | 无第三方运行时或 SPM 依赖 | 工程与仓库文件 | 2026-09-22 |

项目起点借鉴 CatMeter 的监控与猫咪动画思路；当前 DashCat 的产品与实现以本仓库为准。
