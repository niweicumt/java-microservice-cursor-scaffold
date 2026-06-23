-- 骨架占位迁移：创建新业务时请替换或追加 V2__xxx.sql
CREATE TABLE IF NOT EXISTS skeleton_baseline (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
    note        VARCHAR(64)  NOT NULL DEFAULT 'skeleton' COMMENT '说明',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='骨架基线表（可删除）';
