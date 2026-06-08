# 外部 API 参考

DashCat 主要依赖系统 API 和 GitHub 页面。

## Apple 系统 API

| 名称 | 用途 | 说明 |
|------|------|------|
| AppKit | 菜单栏和面板 | NSStatusItem、NSMenu、NSPanel、NSTableView |
| Foundation | 文件和数据 | 时间、文件、字符串、URL、NotificationCenter |
| SQLite3 | 数据库存取 | 剪贴板历史持久化 |
| IOKit Power Sources | 电量读取 | 电量、供电和充电状态 |
| IOPMAssertion | 防休眠 | 创建 / 释放休眠抑制 |
| ApplicationServices / CoreGraphics | 滚轮事件 | CGEventTap 反转鼠标滚轮 |
| ServiceManagement | 开机启动 | SMAppService 注册 / 注销 |
| NSAppleScript | Finder 路径 | 获取当前 Finder 窗口目录 |

## GitHub

| 名称 | 用途 | 说明 |
|------|------|------|
| Releases 页面 | 更新检查 | 打开 `releases/latest` 观察最新版本 |
| 仓库主页 | 代码和说明 | 用户可查看项目主页和文档 |

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-05-24 | 从模板改为 DashCat 实际依赖列表 | 迁移到标准 project-log 结构 |
