# 部署、发行与恢复

> 适用状态：启用。DashCat 没有服务器部署；本文件描述 macOS 应用发行。

## 触发关系

- 工程版本来源：`DashCat.xcodeproj/project.pbxproj` 的 `MARKETING_VERSION` 与 `CURRENT_PROJECT_VERSION`；当前均为 2.5.0。
- 对 `v*` 标签的 push 会触发 `.github/workflows/release.yml`。
- Workflow 在 `macos-15` 上执行 arm64 Release 构建，以标签名覆盖构建版本，创建 `DashCat-<版本>.dmg` 并通过 GitHub Token 上传到对应 Release。
- 普通分支 push 不触发该发行工作流。提交、推送、版本、标签和 Release 分别需要用户授权。

## 本地构建与发行检查

开发构建可在 Xcode 中打开 `DashCat.xcodeproj`，或使用：

```bash
xcodebuild -project DashCat.xcodeproj -scheme DashCat -configuration Debug \
  -derivedDataPath /tmp/dashcat-derived CODE_SIGNING_ALLOWED=NO build
```

发布前应核对工程版本与标签一致、回归测试通过、Release 构建通过、Apple Events entitlement 已嵌入，并在可用设备上检查 Finder/TCC、登录项、快捷键和电量交互。文档同步到 handbook；构建产物放仓库外或由 workflow 管理。

## 安装、回滚与限制

用户可从 GitHub Releases 下载 DMG，或在 Xcode 选择自己的开发者账号构建。当前公开产物未使用付费开发者签名，Gatekeeper 可能拦截；用户 README 记录了右键打开或移除隔离标记的处理方式。

没有自动降级或应用内回滚。需要回退时安装旧 Release；数据库向旧版本回退的兼容性未系统验证，操作前应备份 `~/Library/Application Support/DashCat/`。不能把“旧 DMG 可下载”视为数据回滚已经验证。
