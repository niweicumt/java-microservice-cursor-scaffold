# Java 团队服务骨架 — 项目宪法

## 核心原则

### I. 强制技术栈（不可协商）

所有应用代码与构建配置 **必须** 使用下列版本与工具。如需偏离，须在 OpenSpec 变更的 design 或 tasks 中记录例外说明，并在实施前获得明确批准。

- **JDK**：17（Java 17）— Maven 中 `source`/`target`/`release` **必须** 为 17
- **Spring Boot**：3.3.13 — 父 POM 或 BOM **必须** 锁定此版本
- **Spring Cloud**：2023.0.5 — 微服务治理 BOM
- **Spring Cloud Alibaba**：2023.0.1.2 — Nacos 注册/配置
- **构建工具**：Maven — 主应用不得使用 Gradle 或其他构建工具
- **编码**：UTF-8 — `project.build.sourceEncoding` 与 `project.reporting.outputEncoding`
  **必须** 为 UTF-8；源文件 **必须** 以 UTF-8 保存

**理由**：统一且锁定的技术栈可保证构建可复现、依赖兼容，并在各功能间保持人与 Agent 实现一致。

### II. 分层架构（不可协商）

业务功能 **必须** 遵循标准四层结构。各层职责 **不得** 混用（例如：Controller 中不得写 SQL 或业务规则，Repository 中不得处理 HTTP）。

| 层级 | 包后缀（示例） | 职责 |
|------|----------------|------|
| **Controller** | `.controller` | REST 接口、请求/响应映射、入参校验委托 |
| **Service** | `.service` | 业务逻辑、事务、编排 |
| **Repository** | `.repository` | 数据访问（按项目选用 Spring Data JPA / MyBatis） |
| **Entity** | `.entity` | 持久化模型 / 与数据表映射的领域实体 |

**理由**：结构可预期，便于评审、测试与上手；符合 Spring Boot 惯例及阿里巴巴 Java 手册。

### III. 数据库标准（不可协商）

- **数据库**：MySQL 8.0 — 生产与本地开发 **必须** 面向 MySQL 8.0 兼容的 SQL 与驱动
- 项目采用迁移工具时，表结构变更 **必须** 版本化管理（Flyway 或 Liquibase）
- 连接配置 **必须** 外置凭证（环境变量或 Spring Profile）；**禁止** 将密钥提交入库

**理由**：单一数据库引擎可避免方言漂移，简化运维。

### IV. 横切基础设施（不可协商）

每个服务或新功能分支 **必须** 包含或复用以下横切能力，**不得** 在各接口上临时重复实现。

1. **全局异常处理** — 使用 `@ControllerAdvice`（或等价机制）将异常映射为统一响应格式
2. **统一 API 返回** — 一致的包装结构（如 code、message、data、timestamp）；对外 REST 接口的 Controller **必须** 返回包装体，不得直接返回裸实体
3. **日志** — SLF4J + Logback（Spring Boot 默认）；通过 `application.yml` / `application-{profile}.yml` 配置级别；错误 **必须** 记录堆栈及关键业务标识
4. **接口文档** — 通过 **knife4j** 暴露 Swagger/OpenAPI（或 SpringDoc + knife4j UI）；所有对外 REST 接口 **必须** 有文档

**理由**：统一的错误形态、可观测性与可发现 API 可降低联调成本与线上事故。

### V. 代码风格与质量（不可协商）

- 代码 **必须** 符合 **《阿里巴巴 Java 开发手册》**
- 命名、格式、异常处理、并发与 ORM 用法 **必须** 遵循手册，除非本宪法另有明确规定
- **禁止** 魔法值、过宽的 catch、已废弃 API；例外须在代码评审中说明理由

**理由**：业界通用标准使评审更客观，减少风格争议。

### VI. 本地开发与构建规范（不可协商）

为便于本机调试与单元测试，所有 Java 服务工程 **必须** 遵循下列约定：

**Maven 仓库**

- **必须** 提供项目级 `.mvn/settings.xml`（推荐阿里云 `public` 镜像 + Central 备用）及 `.mvn/maven.config`（自动 `-s .mvn/settings.xml`）
- **必须** 在 `pom.xml` 声明 `<repositories>` 与 `<pluginRepositories>`，保证 CI 与未配置全局 settings 的机器可构建
- 详细说明见 `docs/engineering-standards.md` 第 1 节

**本地 Profile：`application-local`**

- **必须** 提供可提交的模板 `src/main/resources/application-local.yml.example`
- **必须** 将实际 `application-local.yml` 加入 `.gitignore`，**禁止** 提交含个人密码的文件
- 本地启动 **应当** 使用 `dev,local`（或等价组合），在 `local` 中覆盖数据源、日志级别等
- 扩展名与项目一致，使用 `.yml`（若团队统一 YAML 后缀为 `.yaml`，须在工程规范中写明二者等价）

**单元测试**

- **必须** 提供 `src/test/resources/application.yml`，默认使用 H2 内存库（或文档批准的等价方案），使 `mvn test` 不依赖本机 MySQL
- 测试依赖 `h2` **必须** 为 `test` scope

**理由**：统一仓库源减少依赖下载失败；local 配置隔离避免污染共享环境配置；测试配置独立保证 CI 与本地单测可重复执行。

### VII. 包路径与组织前缀（不可协商）

- **禁止** 手动修改 Java 包名、源码目录（如 `com/s3/...`）或各工程 `pom.xml` 中的组织前缀
- **必须** 通过脚本统一替换组织前缀：
  - 跨 common / gateway / scaffold：`./shared/scripts/configure-organization.sh --org <新前缀>`
  - 仅 scaffold 模块标识：`shared/scripts/configure-skeleton.sh` / `rename-skeleton.sh`
- 详细说明见 [`shared/docs/PACKAGE-IDENTITY.md`](../../shared/docs/PACKAGE-IDENTITY.md)

**理由**：包路径与 Maven 坐标、Feign 扫描、JaCoCo 路径、文档引用联动；脚本批量替换可保证三工程一致，避免 PR 遗漏与编译/runtime 不一致。

## 技术栈要求

| 项目 | 要求值 |
|------|--------|
| JDK | 17 |
| Spring Boot | 3.3.13 |
| Spring Cloud | 2023.0.5 |
| Spring Cloud Alibaba | 2023.0.1.2 |
| 注册/配置中心 | Nacos 2.3.x |
| API 网关 | Spring Cloud Gateway |
| 消息队列 | Kafka 3.7.x |
| 构建工具 | Maven |
| 源文件编码 | UTF-8 |
| 架构 | Controller / Service / Repository / Entity |
| 数据库 | MySQL 8.0 |
| 接口文档 | Swagger + knife4j |
| 代码规范 | 阿里巴巴 Java 开发手册 |
| Maven 仓库 | `.mvn/settings.xml` + `pom.xml` repositories |
| 本地调试 | `application-local.yml`（模板 `.example` 提交） |
| 单元测试 | `src/test/resources/application.yml` + H2 |

## 开发流程与质量门禁

1. **提案**（`/opsx-propose`）— 在 `openspec/changes/` 写清边界与验收标准；假设 **不得** 与本宪法冲突
2. **设计与任务**（`/opsx-apply` 前）— 技术上下文 **必须** 列出本文档中的栈版本；偏离项须在 design 中记录
3. **实施**（`/opsx-apply`）— **必须** 使用 `src/main/java` 包结构；测试放在 `src/test/java`
4. **评审** — PR **必须** 核对：版本锁定、分层边界、横切组件、阿里巴巴手册符合性
5. **归档**（`/opsx-archive`）— 合入 `main` 后归档 OpenSpec change

## 治理

本宪法优先于 OpenSpec 变更文档及临时实施说明中的冲突内容。若某功能需要技术栈或架构例外，OpenSpec design **必须** 记录并说明理由；**禁止** 静默偏离。

**修订程序**：

1. 通过 PR 直接修订本文件，附理由与版本号 bump 类型
2. 同步更新 `docs/TEAM-PLAYBOOK.md` 等人类可读摘要（若原则有变）
3. 在本文件页脚记录版本与日期

**合规审查**：Code Review 与人工评审 **必须** 将违反宪法的事项视为 **严重（CRITICAL）** 问题。Agent 在实施前 **必须** 阅读本文件与对应 OpenSpec change。

**运行时指引**：`.cursor/rules/specify-rules.mdc` 为 Agent 提供技术栈摘要；本地/测试细则见 `docs/engineering-standards.md`。

**版本**：1.3.0 | **批准日期**：2026-05-26 | **最后修订**：2026-06-25
