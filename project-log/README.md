# Project Log

这是 DashCat 的开发知识库。它面向开发者和 AI 助手，不是用户说明文档。

## 文件索引

| 编号 | 文件 | 作用 |
|------|------|------|
| 00 | `00-project-overview.md` | 项目背景、目标、范围、技术栈 |
| 01 | `01-function-design.md` | 功能拆分、业务流程、边界情况 |
| 02 | `02-database-design.md` | SQLite 结构、索引、清理规则 |
| 03 | `03-api-design.md` | 外部接口与系统 API 说明 |
| 04 | `04-project-architecture.md` | 目录结构、架构和关键决策 |
| 05 | `05-current-status.md` | 当前进度、待办、阻塞和交接 |
| 06 | `06-dev-log.md` | 开发过程记录 |
| 07 | `07-deployment.md` | 构建、签名、打包与发布 |
| 08 | `08-env-config.md` | 权限、配置和运行环境 |
| 09 | `09-external-api-reference.md` | Apple / GitHub 等外部 API 参考 |
| 10 | `10-planning-log.md` | 改动前的方案和决策依据 |
| 11 | `11-code-review-log.md` | 评审记录、问题和复核结论 |
| 12 | `12-design-decisions.md` | 长期设计取舍和反思 |

## 阅读顺序

新对话或新成员先看：

1. `05-current-status.md`
2. `00-project-overview.md`
3. 任务相关的 `01` / `02` / `03` / `04`
4. 需要理解长期取舍时看 `10` / `12`
5. 最近开发细节看 `06`，评审看 `11`

## 维护规则

- 优先把内容放进现有 00-12 文件
- 大改动先写 `10-planning-log.md`
- 做完后更新 `05-current-status.md` 和 `06-dev-log.md`
- 形成长期取舍时补 `12-design-decisions.md`
- 发现文档和代码不一致时，要明确记下差异

## 当前迁移状态

本轮已按标准结构重建 `project-log/`，旧内容也已迁移并清理完成。
