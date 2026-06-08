# 数据库设计

## 数据库选型

| 项目 | 选择 | 说明 |
|------|------|------|
| 数据库类型 | SQLite | 使用系统内置 `libsqlite3` |
| 存储位置 | Application Support | `~/Library/Application Support/DashCat/clipboard.db` |
| ORM / 驱动 | 无 | 直接调用 SQLite C API |

## ER 关系概览

项目只有一张主表，没有多表关系。

```
clipboard_history
```

## 表设计

### `clipboard_history`

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT | 主键 |
| content | TEXT | 可空 | 文本内容 |
| image_path | TEXT | 可空 | 图片文件路径 |
| source_app | TEXT | NOT NULL DEFAULT '' | 来源应用 bundle id |
| is_pinned | INTEGER | NOT NULL DEFAULT 0 | 是否固定 |
| created_at | REAL | NOT NULL | Unix 时间戳 |

### 索引

| 表 | 索引名 | 字段 | 说明 |
|----|--------|------|------|
| clipboard_history | idx_created_at | created_at | 按时间倒序读取历史 |

## 图片存储

- 原图：`~/Library/Application Support/DashCat/Images/{UUID}.jpg`
- 缩略图：`{UUID}_thumb.jpg`
- 处理方式：JPEG 压缩，单张上限约 500KB
- 总量阈值：500MB，超出后删除最旧的非固定图片

## 清理策略

- 启动时清理过期记录，并清理孤儿图片；永久保留模式也会清理孤儿图片
- 手动清空时先确认范围，可只清除非固定项，也可清除全部；数据库记录删除成功后再删除图片文件
- 过期清理会跳过固定项

## 设计决策

- 只保留一张主表，避免过度建模
- 搜索和历史列表都按 `created_at` 排序
- 图片文件和数据库记录一起管理，避免悬挂路径
- 不做全文索引，当前数据量不需要

## 变更记录

| 日期 | 变更内容 | 原因 |
|------|----------|------|
| 2026-06-08 | 更新清理策略：永久保留仍清孤儿图片，清空历史支持保留或清除固定项 | 综合评审修复 |
| 2026-05-24 | 将剪贴板数据库结构补全为当前实现 | 迁移到标准 project-log 结构 |
