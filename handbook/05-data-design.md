# 数据约定

> 适用状态：启用。当前没有独立迁移框架；任何结构变化都必须兼容既有用户数据库。

## 当前依据

- 数据库：macOS 系统 `libsqlite3`，直接使用 C API；实现入口 `DashCat/ClipboardManager.swift`。
- 位置：`~/Library/Application Support/DashCat/clipboard.db`；图片位于同级 `Images/`。这是运行时位置，不进入 Git。
- 环境隔离：回归脚本使用临时数据库、临时文件和独立 pasteboard，不读取真实历史。
- 备份/恢复：没有应用内备份功能；如需人工备份，应在应用停止写入后整体复制数据库及 `Images/`，恢复流程尚未专项验证。

## 实体与结构

唯一业务实体为剪贴板历史，对应 `clipboard_history`：

| 字段 | SQLite 类型与约束 | 语义 |
| --- | --- | --- |
| `id` | `INTEGER PRIMARY KEY AUTOINCREMENT` | 本地记录标识，也是稳定分页的次级排序键 |
| `content` | `TEXT`，可空 | 完整纯文本；图片记录可以为空 |
| `image_path` | `TEXT`，可空 | 当前保存图片文件名；读取时兼容旧绝对路径 |
| `source_app` | `TEXT NOT NULL DEFAULT ''` | 来源应用 bundle id，未知为空字符串 |
| `is_pinned` | `INTEGER NOT NULL DEFAULT 0` | 0/1 固定状态 |
| `created_at` | `REAL NOT NULL` | Unix 时间戳 |

索引：`idx_created_at(created_at)` 支持时间读取；`idx_history_order(is_pinned DESC, created_at DESC, id DESC)` 支持稳定分页。

## 图片与生命周期

- 新图片原始 PNG/TIFF 数据保真保存为 UUID 文件，旧 `.jpg` 和绝对路径记录继续可读；另生成 `{UUID}_thumb.jpg`。
- 原图不缩放；缩略图最长边 80 像素。数据库记录删除成功后才删除对应文件。
- 启动、每小时、唤醒和保留设置变化时清理过期非固定项；永久保留仍清理孤儿文件。
- 原图与缩略图合计超过 500MB 时按最旧顺序删除非固定图片。固定图片保留，因此总量可以超过阈值。
- 查询图片引用集合失败时不得清孤儿，防止数据库故障被误判为“无人引用”。

## 兼容与变更要求

当前是单连接串行访问，不存在多进程写入承诺。新增字段或索引前必须核对已有用户库的建表/升级路径并补回归测试；不能只修改首次建表 SQL。旧版已截断文本或降采样图片不可逆，不得声称迁移可恢复。删除、容量清理和孤儿清理需继续保护固定项及数据库/文件一致性。
