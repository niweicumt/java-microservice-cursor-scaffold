# plan.md 宪法检查附录

本附录为 Speckit `plan.md` 中 **「宪法检查」** 节的详细核对清单，对照
[`.specify/memory/constitution.md`](../.specify/memory/constitution.md)（v1.1.0+）与骨架默认技术栈。

**使用方式**：

1. `/speckit.plan` 生成 `specs/<feature>/plan.md` 时，在「宪法检查」节勾选摘要项。
2. 阶段 0（调研）前完成 **§一～§六** 门禁核对；存在违规须在 `plan.md`「复杂度追踪」中说明。
3. 阶段 1（设计）完成后复核 **§七～§九**，并执行 **§十** 验证命令。
4. 从骨架创建**全新服务**时，额外完成 **§十一** 服务初始化检查。

---

## 一、强制技术栈（宪法 §I）

| # | 检查项 | 要求值 | plan.md 勾选 |
|---|--------|--------|--------------|
| 1.1 | JDK | **17**（`pom.xml` `java.version`） | ☐ |
| 1.2 | Spring Boot | **3.3.13**（父 POM 锁定） | ☐ |
| 1.3 | 构建工具 | **Maven**（不得使用 Gradle） | ☐ |
| 1.4 | 源文件编码 | **UTF-8** | ☐ |
| 1.5 | 偏离记录 | 若有例外，已写入 plan.md「复杂度追踪」并获批 | ☐ / N/A |

**验证**：`java -version`（17.x）、`mvn -version`（Java 17）

---

## 二、分层架构（宪法 §II）

| # | 检查项 | 包后缀 | plan.md 勾选 |
|---|--------|--------|--------------|
| 2.1 | Controller 层 | `.controller` — REST、校验委托、响应映射 | ☐ |
| 2.2 | Service 层 | `.service` — 业务逻辑、事务、编排 | ☐ |
| 2.3 | Repository 层 | `.repository` — 数据访问（骨架默认 MyBatis Plus Mapper） | ☐ |
| 2.4 | Entity 层 | `.entity` — 持久化模型 / 表映射 | ☐ |
| 2.5 | DTO 层 | `.dto` — 请求/响应对象（建议） | ☐ |
| 2.6 | 边界约束 | Controller 无 SQL/业务规则；Repository 无 HTTP 处理 | ☐ |

---

## 三、数据库标准（宪法 §III）

| # | 检查项 | 要求 | plan.md 勾选 |
|---|--------|------|--------------|
| 3.1 | 数据库引擎 | **MySQL 8.0** | ☐ |
| 3.2 | 字符集 | `utf8mb4` | ☐ |
| 3.3 | 结构变更 | **Flyway** 版本化（`db/migration/V*.sql`） | ☐ |
| 3.4 | 凭证外置 | 环境变量或 Profile；**禁止**密钥入库 | ☐ |
| 3.5 | 逻辑删除 | 复用骨架 `deleted` 字段约定（0/1）或已在 data-model 说明 | ☐ |
| 3.6 | 数据模型 | `data-model.md` 已定义表结构与索引 | ☐ |

---

## 四、横切基础设施（宪法 §IV）

| # | 能力 | 骨架位置 / 约定 | plan.md 勾选 |
|---|------|-----------------|--------------|
| 4.1 | 统一返回 | `Result(code, msg, data)` — Controller **必须**返回包装体 | ☐ |
| 4.2 | 全局异常 | `GlobalExceptionHandler`（`@ControllerAdvice`） | ☐ |
| 4.3 | 日志 | SLF4J + Logback（`logback-spring.xml`）；错误含堆栈 | ☐ |
| 4.4 | 接口文档 | springdoc-openapi + **Knife4j**（`/doc.html`） | ☐ |
| 4.5 | 入参校验 | Bean Validation（`@Valid` / `@Validated`） | ☐ |
| 4.6 | 密码编码 | 需密码场景复用 `PasswordEncoderConfig`（BCrypt） | ☐ / N/A |

---

## 五、代码风格与质量（宪法 §V）

| # | 检查项 | plan.md 勾选 |
|---|--------|--------------|
| 5.1 | 符合《阿里巴巴 Java 开发手册》 | ☐ |
| 5.2 | 无魔法值、过宽 catch、已废弃 API（或例外已说明） | ☐ |
| 5.3 | `tasks.md` 阶段已体现分层测试与评审要求 | ☐ |

---

## 六、本地开发与构建（宪法 §VI）

| # | 检查项 | 要求 | plan.md 勾选 |
|---|--------|------|--------------|
| 6.1 | Maven 仓库 | `.mvn/settings.xml` + `.mvn/maven.config` | ☐ |
| 6.2 | POM 仓库声明 | `<repositories>` / `<pluginRepositories>` | ☐ |
| 6.3 | 本地 Profile | `application-local.yml.example` 已提交；`application-local.yml` 在 `.gitignore` | ☐ |
| 6.4 | 本地 MySQL 联调 | 使用 `dev` Profile + Compose；**非** `application-local.yml` 配 MySQL | ☐ |
| 6.5 | 单测配置 | `src/test/resources/application.yml` 使用 **H2**，`mvn test` 不依赖本机 MySQL | ☐ |
| 6.6 | 多环境 Profile | dev / test / uat / pre / prod 已规划或说明 | ☐ |

---

## 七、技术上下文核对（plan.md 必填节）

生成 `plan.md` 时，「技术上下文」须与宪法一致，不得留空或冲突：

| 字段 | 骨架默认值 |
|------|------------|
| 语言/版本 | Java 17 |
| 主要依赖 | Spring Boot 3.3.13、MyBatis Plus 3.5.9、Flyway、knife4j/springdoc |
| 存储 | MySQL 8.0 |
| 测试 | JUnit 5 + Spring Boot Test；H2 单测；MockMvc |
| 目标平台 | JVM / Spring Boot Web 服务 |
| 项目类型 | web-service（REST API） |

未知项标记为「待澄清」，阶段 0 `research.md` 中必须解决。

---

## 八、可选模块偏离（未开箱能力）

骨架**未默认包含**下列能力；若本功能需要，须在 plan.md「复杂度追踪」记录：

| 模块 | 默认 | 需偏离时 |
|------|------|----------|
| Spring Security 认证/鉴权 | 未包含 | 复杂度追踪 + 审批 |
| 服务注册发现 | **Nacos**（`common-cloud-starter`） | 已包含 |
| Redis | **7.4.2** + Kafka 已包含 | 见 Compose / K8s |
| Java 代码生成 | [`shared/docs/CURSOR-RULES.md`](../../shared/docs/CURSOR-RULES.md) | 阿里 + 项目约束（Cursor 规则） |
| API 网关 | **java-microservice-gateway** 独立工程 | 已包含 |
| Spring Data JPA | 未包含（用 MyBatis Plus） | 同上 |
| Speckit / AI 工作流 | 可选 | 不需要偏离记录 |

---

## 九、测试与覆盖率（见 `docs/unit-testing.md`）

| # | 检查项 | plan.md 勾选 |
|---|--------|--------------|
| 9.1 | 纯单测 `*Test` 不启 Spring（Mockito） | ☐ |
| 9.2 | 集成测试 `*IntegrationTest` + H2 + Flyway | ☐ |
| 9.3 | 新增功能附带测试，`mvn test` 通过 | ☐ |
| 9.4 | JaCoCo 纳入 `controller` / `service` / `common` | ☐ |

---

## 十、阶段验证命令

阶段 1 设计完成后，在仓库根目录执行：

```bash
# 编译与单测（H2，无需本机 MySQL）
mvn clean test

# 本地 MySQL 全栈联调（需 Compose + dev Profile）
./platform/docker-compose/start-local.sh
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 健康检查（经网关，需已启动 gateway-service）
curl -s http://localhost:8080/api/v1/health

# API 文档
open http://localhost:8080/doc.html

# 覆盖率报告（可选）
open target/site/jacoco/index.html
```

| # | 验收项 | 预期 | plan.md 勾选 |
|---|--------|------|--------------|
| 10.1 | `mvn clean test` | BUILD SUCCESS | ☐ |
| 10.2 | 健康检查 | 正常响应 | ☐ |
| 10.3 | Knife4j | `/doc.html` 可访问 | ☐ |
| 10.4 | Flyway | 迁移无报错 | ☐ |
| 10.5 | 无密钥入库 | `application-local.yml` 未提交 | ☐ |

---

## 十一、从骨架创建新服务（额外检查）

仅在从骨架复制并 `rename-skeleton.sh` 时适用：

| # | 检查项 | 说明 | 勾选 |
|---|--------|------|------|
| 11.1 | 包名 | `--package <group>.<module>` 已确定（见 `skeleton.defaults.json`） | ☐ |
| 11.2 | artifact | `--artifact <service-name>` 与仓库名一致 | ☐ |
| 11.3 | 应用名 | `spring.application.name` 已更新 | ☐ |
| 11.4 | 库名 | dev 默认库已创建（`utf8mb4`） | ☐ |
| 11.5 | 无 skeleton 残留 | 包路径、文档、pom 无旧标识 | ☐ |
| 11.6 | rename 后构建 | `mvn clean test` 通过 | ☐ |

```bash
# 可选：先配置团队组织前缀
./scripts/configure-skeleton.sh --base-package <group>.skeleton --group-id <group>

./scripts/rename-skeleton.sh \
  --package <group>.<module> \
  --group-id <group> \
  --artifact <service-name> \
  --db-name <service>_dev
```

标识配置见根目录 `skeleton.defaults.json`，流程详见 [`SKELETON.md`](SKELETON.md) §2、§4。

---

## 十二、plan.md 摘要勾选模板

将下列内容复制到 `specs/<feature>/plan.md` 的「宪法检查」节，并按实际勾选：

```markdown
## 宪法检查

*门禁：阶段 0 调研前必须通过；阶段 1 设计完成后须再次核对。*

对照 [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) 与
[宪法检查附录](../../docs/plan-constitution-check-appendix.md)：

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
```

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) | 团队技术宪法（权威来源） |
| [`.specify/templates/plan-template.md`](../.specify/templates/plan-template.md) | Speckit plan 模板 |
| [`SKELETON.md`](SKELETON.md) | 骨架创建流程 |
| [`engineering-standards.md`](engineering-standards.md) | Maven、Profile、本地配置 |
| [`unit-testing.md`](unit-testing.md) | 单测分层与 JaCoCo |
