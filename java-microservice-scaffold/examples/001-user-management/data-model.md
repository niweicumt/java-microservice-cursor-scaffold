# 数据模型：用户管理

**功能**：001-user-management | **日期**：2026-05-26

## 实体：User（sys_user）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 用户唯一标识 |
| username | VARCHAR(64) | NOT NULL | 登录名；有效用户内唯一（见索引） |
| password_hash | VARCHAR(128) | NOT NULL | BCrypt 摘要，永不对外返回 |
| email | VARCHAR(128) | NOT NULL | 邮箱；有效用户内唯一 |
| phone | VARCHAR(20) | NULL | 手机号 |
| status | TINYINT | NOT NULL, DEFAULT 1 | 1=启用，0=停用 |
| deleted | TINYINT | NOT NULL, DEFAULT 0 | 逻辑删除：0 未删，1 已删（@TableLogic） |
| create_time | DATETIME | NOT NULL | 创建时间，自动填充 |
| update_time | DATETIME | NOT NULL | 更新时间，自动填充 |

### 索引

| 名称 | 列 | 类型 | 用途 |
|------|-----|------|------|
| uk_username_deleted | username, deleted | UNIQUE | 逻辑删除下用户名唯一 |
| uk_email_deleted | email, deleted | UNIQUE | 逻辑删除下邮箱唯一 |
| idx_status | status | INDEX | 状态筛选 |
| idx_create_time | create_time | INDEX | 默认排序 |

> 说明：唯一约束含 `deleted`，允许逻辑删除后使用相同 username/email 新建用户（规格边界情况）。

## 状态转换

```text
[新建] --> status=1, deleted=0（启用）
[停用] --> status=0（仍 deleted=0，可出现在「停用」筛选）
[删除] --> deleted=1（默认列表/详情不可见）
```

## 校验规则（入参）

| 字段 | 规则 |
|------|------|
| username | 非空；长度 4～64；字母数字下划线 |
| password（创建） | 非空；长度 8～32（创建必填） |
| password（更新） | 可选；若提供则 8～32 |
| email | 非空；邮箱格式 |
| phone | 可选；大陆手机号正则或国际宽松格式 |
| status | 可选；仅 0 或 1 |
| page | ≥1 |
| size | 1～100 |

## API 对外模型（VO）

**UserVO**（响应）：id, username, email, phone, status, createTime, updateTime（无 password_hash）

**CreateUserRequest**：username, password, email, phone, status（可选，默认 1）

**UpdateUserRequest**：username, password（可选）, email, phone, status（均可选部分更新）

**UserPageQuery**：page, size, username（模糊）, status, email, phone

## 关系

本功能仅单表，无关联实体。

## DDL 摘要

见 `src/main/resources/db/migration/V1__init_sys_user.sql`（实施阶段创建）；契约见 `contracts/users-api.openapi.yaml`。
