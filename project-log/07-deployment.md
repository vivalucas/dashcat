# 部署

DashCat 是本地 macOS 应用，没有服务器部署。

## 构建环境

- macOS 13 或更高版本
- Xcode
- Apple Silicon 优先

## 构建步骤

1. 打开 `DashCat.xcodeproj`
2. 选择对应 scheme
3. 调整 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`（如需要）
4. 执行 Debug 或 Release build
5. 如需发布，导出 `.app` 或打包成 `.dmg`

## 发布前检查

- `Info.plist` 版本号正确
- 签名和权限正常
- `project-log` 已同步更新
- 本地构建产物已清理

## 运行时前提

- 需要剪贴板访问
- 滚轮反转功能需要辅助功能权限
- Finder 新建文件在首次使用时可能请求自动化权限

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-05-24 | 改成桌面应用的构建与发布说明 | 迁移到标准 project-log 结构 |
