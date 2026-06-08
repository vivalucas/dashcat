# 环境配置

DashCat 没有环境变量，也没有外部服务配置。

## 运行前提

- macOS 13 Ventura 或更高版本
- 菜单栏权限正常
- 需要时允许辅助功能权限
- 需要时允许自动化权限

## 权限与配置

| 项目 | 位置 | 说明 |
|------|------|------|
| 自动化权限 | 系统设置 / 隐私与安全性 / 自动化 | 用于读取 Finder 当前窗口目录 |
| 辅助功能权限 | 系统设置 / 隐私与安全性 / 辅助功能 | 用于鼠标滚轮反转 |
| 剪贴板访问 | 系统默认 | 通过 `NSPasteboard.general` 轮询 |
| Launch at Login | 系统登录项 | 由 `SMAppService` 注册 |

## Info.plist

| Key | 用途 |
|-----|------|
| `LSUIElement` | 作为菜单栏应用运行 |
| `NSAppleEventsUsageDescription` | 读取 Finder 目录 |
| `ITSAppUsesNonExemptEncryption` | 申明不使用非豁免加密 |

## entitlements

| Key | 用途 |
|-----|------|
| `com.apple.security.app-sandbox = false` | 不启用沙箱 |

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-05-24 | 用实际权限项替换模板内容 | 迁移到标准 project-log 结构 |
