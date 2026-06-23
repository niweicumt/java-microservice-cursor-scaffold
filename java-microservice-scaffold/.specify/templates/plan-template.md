# 实施计划：[功能名称]

**分支**：`[###-feature-name]` | **日期**：[DATE] | **规格**：[链接]

**输入**：来自 `/specs/[###-feature-name]/spec.md` 的功能规格说明

**说明**：本模板由 `/speckit.plan` 命令填写。执行流程见 `.specify/templates/plan-template.md`。

## 摘要

[从功能规格提取：主要需求 + 调研后的技术方案]

## 技术上下文

<!--
  必须操作：将本节替换为本功能/项目的技术细节。
  下列结构仅供参考，用于指导迭代。
-->

**语言/版本**：Java 17（JDK 17）— 依宪法

**主要依赖**：Spring Boot 3.3.13、Maven、knife4j/Swagger — 依宪法

**存储**：MySQL 8.0 — 依宪法

**测试**：JUnit 5 + Spring Boot Test（API 使用 MockMvc）— 或【待澄清】

**目标平台**：JVM / Spring Boot Web 服务 — 或【待澄清】

**项目类型**：web-service（REST API）— 或【待澄清】

**性能目标**：[领域相关，如 1000 req/s、P95 < 200ms，或【待澄清】]

**约束**：[领域相关，如 P95 < 200ms、内存 < 100MB、可离线，或【待澄清】]

**规模/范围**：[领域相关，如 1 万用户、50 个接口，或【待澄清】]

## 宪法检查

*门禁：阶段 0 调研前必须通过；阶段 1 设计完成后须再次核对。*

对照 [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) 与
[宪法检查附录](../../docs/plan-constitution-check-appendix.md)（详细核对清单见附录 §一～§十一）。

### 摘要（必填）

- [ ] 技术栈：JDK 17 + Spring Boot 3.3.13 + Maven + UTF-8
- [ ] 分层：Controller / Service / Repository / Entity（+ dto）
- [ ] 数据库：MySQL 8.0 + Flyway；凭证外置
- [ ] 横切：统一返回 + 全局异常 + Logback + Knife4j
- [ ] 本地/测试：application-local 模板 + H2 单测配置
- [ ] 代码规范：阿里巴巴 Java 开发手册
- [ ] 阶段验证：`mvn clean test` 通过

### 偏离项

> 无偏离填「无」。有偏离见下方「复杂度追踪」表。

- 偏离说明：[无 / 列出项]

### 附录核对

- 阶段 0 前：附录 §一～§六 已核对
- 阶段 1 后：附录 §七～§十 已复核
- 新服务初始化：附录 §十一 [已核对 / N/A]

## 项目结构

### 文档（本功能）

```text
specs/[###-feature]/
├── plan.md              # 本文件（/speckit.plan 输出）
├── research.md          # 阶段 0 输出（/speckit.plan）
├── data-model.md        # 阶段 1 输出（/speckit.plan）
├── quickstart.md        # 阶段 1 输出（/speckit.plan）
├── contracts/           # 阶段 1 输出（/speckit.plan）
└── tasks.md             # 阶段 2 输出（/speckit.tasks，非 /speckit.plan 创建）
```

### 源代码（仓库根目录）

<!--
  必须操作：将下方占位目录树替换为本功能的真实布局。
  删除未用选项，展开所选结构的真实路径。
  交付的计划中不得保留「Option」等选项标签。
-->

```text
# Spring Boot 单模块（宪法默认）
src/main/java/com/example/demo/
├── controller/       # REST 接口
├── service/          # 业务逻辑
├── repository/       # 数据访问
├── entity/           # JPA/MyBatis 实体
├── config/           # 安全、Swagger/knife4j 等
├── common/           # 统一返回、异常、常量
└── Application.java

src/main/resources/
├── application.yml
├── application-dev.yml
└── db/migration/     # Flyway/Liquibase（若使用）

src/test/java/        # 单元与集成测试（包结构与 main 对应）
```

**结构决策**：[说明所选结构，并引用上方真实目录]

## 复杂度追踪

> **仅当宪法检查存在必须说明理由的违规项时填写**

| 违规项 | 为何需要 | 拒绝更简单方案的原因 |
|--------|----------|----------------------|
| [示例：额外子项目] | [当前需求] | [为何现有结构不足] |
| [示例：Repository 模式] | [具体问题] | [为何不宜直接访问数据库] |
