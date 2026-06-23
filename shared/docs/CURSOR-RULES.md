# Cursor 规则说明（团队共享）

本仓库通过 **`.cursor/rules/`** 下的规则文件，在 Cursor / AI 生成代码时自动加载统一约束。规则可提交 Git，多微服务团队打开项目即可共享。

---

## 规则文件一览

| 文件 | 何时生效 | 作用 |
|------|----------|------|
| [`specify-rules.mdc`](../../.cursor/rules/specify-rules.mdc) | **始终**（`alwaysApply: true`） | Monorepo 结构、技术栈、文档索引 |
| [`microservice-architecture.mdc`](../../.cursor/rules/microservice-architecture.mdc) | 编辑 `src/**`、yml、xml、pom 时 | **架构强制**：目录分层、H2/CI 测试、AssertJ、SQL 禁止项、DTO 兼容 |
| [`alibaba-java-standard.mdc`](../../.cursor/rules/alibaba-java-standard.mdc) | 编辑 Java / Mapper XML / yml 时 | **编码规范**：阿里泰山版 + DTO/Service/Result/H2 |

> 独立微服务仓库（从骨架拆出）自带 [`skeleton-service/.cursor/rules/microservice-architecture.mdc`](../../java-microservice-scaffold/skeleton-service/.cursor/rules/microservice-architecture.mdc)，globs 为项目根相对路径，克隆即用。  
> 原 `java-codegen-constraints.mdc` 已 **合并** 进 `alibaba-java-standard.mdc`，无需单独维护。

---

## `microservice-architecture.mdc` 内容摘要

### 目录分层

| 类型 | 路径 |
|------|------|
| AI 业务代码 | `auto.service` / `auto.repository` / `auto.controller` |
| 人工定制 | `custom.service`；单测 `custom/**/*Test` |
| 单元测试 | `unit/auto/**/*Test`（随 CRUD 同步刷新） |
| 集成测试 | `integration/**/*IntegrationTest`（H2 + OpenAPI 契约） |

### 测试与 CI

- 单元/集成默认 **H2**（`MODE=MySQL`）；Mapper 须覆盖增删改查全场景。
- **AssertJ** + Mockito；Service 覆盖率 **≥ 90%**。
- 仅 Release 分支跑 Testcontainers MySQL。

### SQL / 迭代

- 禁存储过程、`DATE_FORMAT`、MySQL 专属 DDL。
- 新增 DTO 字段须非破坏、可空或有默认值。

---

## `alibaba-java-standard.mdc` 内容摘要

### 阿里泰山版落地

| 类别 | 要点 |
|------|------|
| **包隔离** | AI 生成 CRUD 放 `auto` 包；`custom` 包仅人工扩展，AI **禁止覆盖** |
| **日志** | SLF4J + `{}`；禁 `System.out`；敏感字段脱敏 |
| **并发** | 禁无锁改共享变量；细粒度 Lock；禁大方法 `synchronized` |
| **工具类** | 优先 `common-core`，禁止重复工具方法 |

### 微服务代码生成（项目约束）

| 类别 | 要点 |
|------|------|
| **DTO** | JSR 303 校验 + Controller `@Valid` |
| **Service** | 基础 CRUD 与业务组合分离；Controller 不编排 |
| **异常** | 仅 `BusinessException` + `ResultCode` |
| **Mapper** | MP 单表；复杂 SQL 进 XML；禁硬编码 SQL |
| **分页/返回** | MP `Page` → `PageVO` → `Result<T>` |
| **注释** | Service public 方法 Javadoc（入参、异常、分支） |
| **H2 单测** | 禁存储过程 / MySQL 专属语法；`mvn test` 不依赖 MySQL |
| **边界** | null、空集合、0/负数/超大值、循环与批量上限 |

### 测试要求

- JUnit 5 + Mockito；类名 `*Test` / `*IntegrationTest`。
- 每方法覆盖：正常、空值、边界、异常。
- Mapper 测试用 H2；SQL 用 `#{}` 绑定。

### AI 输出约定

1. 自动校验规范；违规则先输出修正代码并标注问题。
2. 业务代码须同步生成配套单元测试。
3. 生成后按规则内 **自检清单** 逐项确认。

---

## 与工程文档的关系

| 文档 | 说明 |
|------|------|
| 本文 | 规则**简要说明**（给人看） |
| [`CURSOR-IDE-SETUP.md`](CURSOR-IDE-SETUP.md) | **必装：SonarLint + Superpowers + OpenSpec** |
| [`CI-TOOLCHAIN.md`](CI-TOOLCHAIN.md) | **工程自动化工具链与 CI 质量门禁（团队强制）** |
| [`DEPLOYMENT.md`](../../docs/DEPLOYMENT.md) | 部署与 H2 单测环境 |
| [`PACKAGE-IDENTITY.md`](PACKAGE-IDENTITY.md) | 包路径与组织前缀 |
| [`unit-testing.md`](../../java-microservice-scaffold/docs/unit-testing.md) | 测试分层与 JaCoCo |
| [`engineering-standards.md`](../../java-microservice-scaffold/docs/engineering-standards.md) | Maven / Profile 工程细则 |

---

## 团队使用方式

1. 克隆仓库后 Cursor **自动加载** `.cursor/rules/`（无需个人复制）。
2. 生成 Java 代码时，Agent 匹配 `alibaba-java-standard.mdc` 的 glob（含 `src/main/java`、 `src/test/java`、 `mapper xml`、 `yml`）。
3. Speckit 实现（`/speckit.implement`）会强制阅读本说明与规则文件。
4. 修改规范：编辑 `alibaba-java-standard.mdc` 并同步更新 **本文摘要**。
5. 代码质量：安装 **SonarLint** 扩展，详见 [`SONARQUBE.md`](SONARQUBE.md)。
6. **CI 门禁**：提交前本地 `mvn test` + JaCoCo；PR 须通过 Sonar / 单测 / 集成 / 契约流水线，详见 [`CI-TOOLCHAIN.md`](CI-TOOLCHAIN.md)。
