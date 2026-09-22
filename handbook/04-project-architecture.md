# 架构约定

> 适用状态：启用。当前采用单进程、少文件的纯 AppKit 架构。

## 系统边界

```text
DashCat App
├─ AppDelegate：状态项、菜单、偏好、休眠/电量/Finder/更新协调
├─ ClipboardPanel：搜索、列表、预览与键盘交互
├─ ClipboardManager：pasteboard 采集、SQLite 与图片生命周期
├─ SystemMonitor：CPU/内存采样
├─ ScrollManager：CGEventTap 鼠标滚轮反转
└─ macOS 系统框架 + GitHub Releases 页面
```

| 模块 | 职责 | 依赖方向 | 不承担什么 |
| --- | --- | --- | --- |
| `AppDelegate.swift` | 生命周期、状态项、菜单和跨模块协调 | 调用其他模块与系统 API | 不直接实现数据库查询 |
| `ClipboardManager.swift` | 剪贴板采集、持久化、查询与文件清理 | SQLite、AppKit/Foundation | 不管理面板布局 |
| `ClipboardPanel.swift` | 面板 UI、异步请求协调和用户操作 | ClipboardManager | 不直接管理数据库连接 |
| `SystemMonitor.swift` | CPU/内存采样 | Darwin 系统信息 | 不决定菜单呈现策略 |
| `ScrollManager.swift` | event tap 生命周期和鼠标滚轮转换 | CoreGraphics/ApplicationServices | 不改变触控板连续滚动 |

## 关键路径与约束

- 剪贴板变化 → 类型/偏好过滤 → 串行数据库队列 → SQLite/图片文件 → 面板分页查询 → 主线程更新 UI。
- 复制图片 → 后台读取与验证 → 清空并写入 pasteboard → 同步 changeCount，避免自身写回被重复采集；面板关闭或请求失效时可取消。
- 所有数据库访问与图片清理共用串行队列。查询只有完整到达 `SQLITE_DONE` 才能作为孤儿清理的权威集合。
- 系统睡眠时暂停采样/轮询，唤醒后恢复并触发过期清理。
- 保持系统框架优先、零第三方依赖。项目规模显著增长或模块互相阻塞时再评估拆层，不为形式提前增加 service/view-model 层。

核心验证入口为 [10 测试与质量](10-quality.md)；长期理由见 [11 决策](11-decisions.md)。
