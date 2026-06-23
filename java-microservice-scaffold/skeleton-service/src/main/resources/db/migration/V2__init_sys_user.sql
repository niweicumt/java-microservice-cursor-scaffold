-- 用户表（示例 CRUD；H2 MODE=MySQL / MySQL 8 兼容）
CREATE TABLE IF NOT EXISTS sys_user (
    id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    username      VARCHAR(64)  NOT NULL COMMENT '登录名',
    password_hash VARCHAR(128) NOT NULL COMMENT 'BCrypt 密码摘要',
    email         VARCHAR(128) NOT NULL COMMENT '邮箱',
    phone         VARCHAR(20)  NULL COMMENT '手机号',
    status        TINYINT      NOT NULL DEFAULT 1 COMMENT '1=启用 0=停用',
    deleted       TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    create_time   DATETIME     NOT NULL COMMENT '创建时间',
    update_time   DATETIME     NOT NULL COMMENT '更新时间',
    PRIMARY KEY (id)
);

-- Flyway 版本化脚本仅执行一次，索引无需 IF NOT EXISTS（MySQL < 8.0.29 不支持该语法）
CREATE UNIQUE INDEX uk_username_deleted ON sys_user (username, deleted);
CREATE UNIQUE INDEX uk_email_deleted ON sys_user (email, deleted);
CREATE INDEX idx_status ON sys_user (status);
CREATE INDEX idx_create_time ON sys_user (create_time);
