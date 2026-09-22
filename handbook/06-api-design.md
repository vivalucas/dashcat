# 接口约定

> 适用状态：启用，但项目没有自建 HTTP、WebSocket 或 IPC API。这里维护系统接口边界。

无应用内认证。权限由 macOS 的辅助功能、自动化和登录项机制管理；缺少权限时只禁用相关能力并给出恢复入口。

| 能力 / 操作 | 实现或契约入口 | 调用方 | 当前边界 |
| --- | --- | --- | --- |
| 剪贴板读写 | `NSPasteboard.general` | ClipboardManager / Panel | 轮询 changeCount；写回不模拟粘贴 |
| 全局快捷键 | Carbon `RegisterEventHotKey` | AppDelegate | 默认关闭；注册冲突提示且保留原配置 |
| 电量 | IOKit Power Sources | AppDelegate | 可空充电状态保留“未知”语义 |
| 防休眠 | `IOPMAssertion` | AppDelegate | 创建失败回退关闭，旧 assertion 必须释放 |
| 滚轮事件 | `CGEventTap` | ScrollManager | 只处理非连续鼠标滚轮；需辅助功能权限 |
| 登录项 | `SMAppService` | AppDelegate | 菜单状态以系统真实状态为准 |
| Finder 目录 | `NSAppleScript` / Apple Events | AppDelegate | 仅用户触发时请求；失败可手选目录 |
| 更新检查 | GitHub Releases `latest` 页面 | AppDelegate | URLSession 跟随重定向读取版本标签；下载仍打开发布页 |

变更系统调用前检查所有调用方、主线程要求、权限失败和取消路径。新增功能不自动意味着引入网络服务；若未来增加自建接口，需在此明确认证、错误、版本和隐私边界。
