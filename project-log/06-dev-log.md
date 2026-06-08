# 开发日志

## 2026-06-08（综合评审修复与体验优化）

**触发原因**：综合检查项目后，需要修复已确认 bug / 风险，并按用户确认优化剪贴板、Finder 和更新检查流程。

**修改内容**：
1. `DashCat/AppDelegate.swift` - 防休眠 assertion 创建失败时回退关闭，并同步菜单状态和 `UserDefaults`。
2. `DashCat/ClipboardManager.swift` - 永久保留模式仍清理孤儿图片；图片条目删除改为数据库删除成功后再删文件。
3. `DashCat/ClipboardManager.swift`、`DashCat/AppDelegate.swift` - 清除历史增加确认选项，可清除未固定项或清除全部。
4. `DashCat/ClipboardPanel.swift` - 增加空状态提示，并将图片缩略图加载改为后台加载后刷新对应行。
5. `DashCat/AppDelegate.swift` - Finder 新建文件弹窗增加文件名输入，保留 TXT / Markdown 和重名自动递增。
6. `DashCat/AppDelegate.swift` - 更新检查期间显示“正在检查更新”并禁用菜单项，避免重复请求。
7. `README*.md`、`project-log` - 同步电量蓝色 / 粉色口径、清除历史语义、Finder 文件名输入和当前版本状态。
8. `DashCat.xcodeproj/project.pbxproj` - 将 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 推进到 `2.3.11`，用于发布新版本。

**遇到的问题**：
- 旧文档中仍有接电 / 充电蓝色描述，且 `05-current-status.md` 版本落后于工程配置。

**解决方式**：
- 按当前代码实际行为同步 README 和 project-log。

**验证方式**：
- `xcodebuild -scheme DashCat -project DashCat.xcodeproj -configuration Debug -derivedDataPath /tmp/dashcat-derived build CODE_SIGNING_ALLOWED=NO`

**验证结果**：
- 通过。

**本地产物清理**：
- 构建产物位于 `/tmp/dashcat-derived`，仓库内无新增构建产物。

## 2026-06-06（电量状态颜色调整与 2.3.8 发布）

**触发原因**：需要调整极简电量状态项在未接电正常电量和接电 / 充电时的颜色表达，并发布新版本。

**修改内容**：
1. `DashCat/AppDelegate.swift` - 将未接电正常电量的填充色从绿色改为蓝色。
2. `DashCat/AppDelegate.swift` - 保持未接电低电量逻辑：20% 及以下橙色，10% 及以下红色。
3. `DashCat/AppDelegate.swift` - 将接电 / 充电状态的填充色和描边从蓝色改为粉色，并让接电 / 充电状态优先于低电量颜色。
4. `DashCat.xcodeproj/project.pbxproj` - 将 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION` 推进到 `2.3.8`。
5. `project-log/05-current-status.md`、`project-log/06-dev-log.md` - 同步当前状态和开发记录。

**遇到的问题**：
- 旧逻辑中低电量颜色优先于接电 / 充电颜色，接电低电量时不会显示接电状态色。

**解决方式**：
- 将接电 / 充电判断提前，未接电时再按低电量阈值显示橙色或红色。

**验证方式**：
- 代码复核。
- `xcodebuild -project DashCat.xcodeproj -scheme DashCat -configuration Debug -arch arm64 CODE_SIGNING_ALLOWED=NO build`

**验证结果**：
- 通过。

**本地产物清理**：
- 构建产物位于 Xcode DerivedData，仓库内无新增构建产物。

## 2026-05-24（Project log 规范迁移）

**触发原因**：旧的 `project-log` 文件夹结构零散，不适合作为长期知识库。

**修改内容**：
1. `project-log/README.md` - 重写为标准 00-12 索引和维护规则。
2. `project-log/00-project-overview.md` - 补充 DashCat 的背景、边界、技术栈和核心功能。
3. `project-log/01-function-design.md` - 按模块补全菜单栏、剪贴板、监控、电量、滚轮和 Finder 功能。
4. `project-log/02-database-design.md` - 写明 SQLite 表结构、索引和图片存储策略。
5. `project-log/03-api-design.md` - 明确本项目没有 HTTP API，只使用系统接口。
6. `project-log/04-project-architecture.md` - 补全目录结构和关键技术决策。
7. `project-log/05-current-status.md` - 写入当前版本、阶段、待办和交接信息。
8. `project-log/06-dev-log.md` - 用新的项目历史结构承接开发记录。
9. `project-log/07-deployment.md`、`08-env-config.md`、`09-external-api-reference.md`、`10-planning-log.md`、`11-code-review-log.md`、`12-design-decisions.md` - 从模板补成可用文档。

**遇到的问题**：
- 旧文件夹内容分散，必须先统一到标准结构再谈补全。

**解决方式**：
- 先把旧目录备份成 `project-logBAK`，再用样例结构重建 `project-log`。
- 结合现有代码、README 和旧日志，把文档改成当前项目真实状态。

**验证方式**：
- 逐个对照现有代码和 README。
- 检查新目录是否包含标准 00-12 文件。

**验证结果**：
- 通过，结构已重建，内容已补齐大半。

**本地产物清理**：
- `project-logBAK` 已删除。

## 2026-05-20（电量详情菜单）

**触发原因**：极简电量状态项上线后，需要补足右键详情菜单。

**修改内容**：
1. `DashCat/AppDelegate.swift` - 为独立电量状态项增加右键详情菜单，保留窄数字显示。
2. `DashCat/Info.plist` - 补充 `NSAppleEventsUsageDescription`，允许读取 Finder 当前窗口目录。
3. `project-log/spec.md`、`project-log/principles.md` - 写明电量菜单边界：只做轻量只读信息，不做高能耗 App 列表和充满动作。

**遇到的问题**：
- 系统电池菜单的部分动作没有公开稳定 API。

**解决方式**：
- 只保留可验证的公开行为，不做私有 API 或自动化点击绕过。

**验证方式**：
- 代码审查。

**验证结果**：
- 通过。

**本地产物清理**：
- 无。

## 2026-05-19（电量显示和剪贴板过滤）

**触发原因**：需要让电量状态项和剪贴板历史更符合实际使用。

**修改内容**：
1. `DashCat/AppDelegate.swift` - 充电或接电时给电量状态项加蓝色视觉反馈，并保留接电隐藏开关。
2. `DashCat/ClipboardManager.swift` - 增加过滤词表，在写入数据库前过滤文本。
3. `project-log/spec.md`、`project-log/principles.md` - 明确过滤规则和电量显示规则。

**遇到的问题**：
- 文档里曾经把搜索口径写得太像“精确匹配”。

**解决方式**：
- 统一改成包含匹配。

**验证方式**：
- 代码和文档对照。

**验证结果**：
- 通过。

**本地产物清理**：
- 无。

## 2026-05-18（右键菜单重整）

**触发原因**：菜单结构需要回收成更清晰的信息架构。

**修改内容**：
1. `DashCat/AppDelegate.swift` - 重新组织 Monitor、Battery、Clipboard Settings、Help & Updates 等菜单分组。
2. `project-log/spec.md` - 写入当前菜单结构和技术口径。
3. `project-log/principles.md` - 增加“菜单即功能地图”的原则。

**遇到的问题**：
- 过深层级和工程术语让菜单不容易扫读。

**解决方式**：
- 用分隔线和更直观的命名替代多层缩进。

**验证方式**：
- 本地构建和菜单检查。

**验证结果**：
- 通过。

**本地产物清理**：
- 无。
