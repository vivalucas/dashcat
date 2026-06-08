# API 设计

DashCat 不提供 HTTP / Web API。

项目依赖的是系统框架和外部服务页面，不是自建接口层。

## 外部接口

| 接口 | 用途 | 说明 |
|------|------|------|
| `NSPasteboard.general` | 剪贴板读写 | 轮询监控和回写内容 |
| `IOKit Power Sources` | 电量读取 | 获取电量、供电和充电状态 |
| `IOPMAssertion` | 防休眠 | 创建 / 释放休眠抑制 |
| `CGEventTap` | 滚轮拦截 | 反转鼠标滚轮 |
| `SMAppService` | 开机启动 | 注册和注销登录项 |
| `NSAppleScript` | Finder 目录读取 | 获取当前 Finder 窗口目录 |
| GitHub Releases 页面 | 更新检查 | 打开最新发布页进行检查 |

## 认证方式

无应用内认证。

## 接口说明

这些接口都是系统 API 或网页跳转，没有统一的请求/响应封装。

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-05-24 | 明确本项目不提供自建 API | 迁移到标准 project-log 结构 |
