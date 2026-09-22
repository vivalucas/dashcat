# 测试、评审与质量

> 适用状态：启用。这里维护可重复入口、当前风险与验收边界，不保存每轮通过流水账。

## 验证入口与完成标准

| 范围 | 测试 / 构建 / 手动检查入口 | 通过条件 | 限制 |
| --- | --- | --- | --- |
| 剪贴板回归 | `bash Tests/run-clipboard-regression.sh` | 进程退出 0；使用临时数据库、文件和独立 pasteboard | 不覆盖真实系统 UI/TCC |
| Debug 构建 | `xcodebuild ... -configuration Debug -derivedDataPath /tmp/... CODE_SIGNING_ALLOWED=NO build` | `BUILD SUCCEEDED` | 不验证签名/安装 |
| Release 构建 | 同上改为 `Release` | `BUILD SUCCEEDED`，产物版本符合预期 | 不等于 workflow/DMG 发布成功 |
| 签名与权限 | 临时副本 ad-hoc Hardened Runtime 签名，`codesign` 检查 entitlement | 签名完整且包含 Apple Events entitlement | 不替代真实 TCC 交互 |
| UI / 系统交互 | 实机操作面板、Finder、登录项、快捷键、电量和多屏 | 主路径及失败恢复符合 02/03 | 需要合适设备和权限状态 |

回归脚本当前覆盖长文本/NUL、敏感类型、Unicode 包含搜索、PNG 原始字节和尺寸、分页、过期/固定/容量清理、旧路径兼容、数据库错误保护、键盘 delegate/IME 分流及 5 万行查询。修改对应路径时同步调整测试，且不得运行主应用污染真实剪贴板历史。

## 当前待验证风险

| 编号 | 类型 / 优先级 | 触发条件、影响 | 状态 / 所需验证 |
| --- | --- | --- | --- |
| Q-001 | 系统交互 / 中 | Finder TCC 拒绝与恢复、登录项批准、快捷键冲突可能因系统版本不同而变化 | 代码与隔离路径已核对；需真机完整验收 |
| Q-002 | 输入与显示 / 中 | 不同输入法、多屏和真实键盘事件可能暴露 delegate 测试未覆盖的问题 | 需实际 UI 验收 |
| Q-003 | 性能 / 低 | 超过 5 万条或特殊大图可能增加查询、解码和清理延迟 | 当前合成样本通过；更大规模待按需求压测 |

## 已沉淀的防复发覆盖

敏感类型过滤、完整文本、查询失败不清孤儿、周期清理、稳定分页、原图保真、复制失败不先清 pasteboard、保留天数校验、Unicode 搜索、统一默认语言、Apple Events entitlement 和未知充电状态均已由测试或明确验收边界保护。历史逐项评审详情由 Git 保存，不在当前文档重复维护。

本项目不是 AI 产品，AI 效果评测不适用。
