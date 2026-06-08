# 项目架构

## 系统架构

```
AppKit App
├─ 菜单栏猫咪状态项
├─ 独立电量状态项
├─ 剪贴板弹窗 NSPanel
├─ SQLite 剪贴板数据库
└─ 系统框架
   ├─ IOKit / Power Sources
   ├─ IOPMAssertion
   ├─ CGEventTap
   ├─ ServiceManagement
   └─ NSAppleScript
```

## 目录结构

```
DashCat/
├── main.swift
├── AppDelegate.swift
├── ClipboardManager.swift
├── ClipboardPanel.swift
├── SystemMonitor.swift
├── ScrollManager.swift
├── Info.plist
├── DashCat.entitlements
└── Assets.xcassets/
project-log/
└── 00-12 文档
```

## 关键技术决策

### 1. 纯 AppKit

- **选择**：不用 SwiftUI
- **备选方案**：SwiftUI + AppKit 混合
- **原因**：菜单栏和浮窗逻辑简单，纯 AppKit 更轻

### 2. 单进程、少文件

- **选择**：一个 App 里直接放主要逻辑
- **备选方案**：拆成多层 service / view model
- **原因**：项目体量不大，复杂分层只会增加维护成本

### 3. 本地 SQLite

- **选择**：SQLite
- **备选方案**：JSON / Core Data / SwiftData
- **原因**：历史数据清理和按需查询都更直接

### 4. 菜单即配置

- **选择**：所有设置放右键菜单
- **备选方案**：独立设置窗口
- **原因**：符合菜单栏工具习惯，路径更短

### 5. 系统能力优先

- **选择**：Apple 内置框架
- **备选方案**：第三方依赖
- **原因**：项目强调低依赖和低维护

## 依赖关系

| 依赖 | 版本 | 用途 |
|------|------|------|
| AppKit | 系统 | UI、菜单栏、面板 |
| Foundation | 系统 | 基础模型、文件和时间处理 |
| SQLite3 | 系统 | 剪贴板历史 |
| IOKit / ApplicationServices / CoreGraphics | 系统 | 电量、防休眠、滚轮 |
| ServiceManagement | 系统 | 开机启动 |

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-05-24 | 补全当前 DashCat 的目录和架构 | 迁移到标准 project-log 结构 |
