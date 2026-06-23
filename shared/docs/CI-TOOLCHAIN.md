# 工程自动化工具链与 CI 质量门禁

本文档为 **所有 Java 微服务团队共享的强制约束**：统一构建、多环境 Profile、覆盖率留存、SonarQube 质量扫描，以及标准 CI 门禁流水线。

> 本 Monorepo 采用 **Maven** 统一构建（不使用 Gradle）。各子工程独立 `pom.xml`，共享根目录 `.mvn/settings.xml`。

---

## 1. 统一构建与环境隔离

| 约束 | 说明 |
|------|------|
| **构建工具** | Maven 3.9+；JDK 17 |
| **配置分离** | 运行环境通过 Spring Profile 切换；**禁止**在代码中硬编码环境差异 |
| **密钥隔离** | 数据库账号、Token 等通过环境变量或 K8s Secret 注入；`application-local.yml` 不提交 Git |
| **测试与生产配置分离** | 单测 / CI 使用 `src/test/resources`（H2）；`prod` 使用 MySQL；二者配置不得混用 |

**本地预校验（提交前必做）**：

```bash
cd java-microservice-common && mvn clean install && cd ..

cd java-microservice-scaffold
mvn clean test                                    # JUnit5 + JaCoCo
open skeleton-service/target/site/jacoco/index.html

# 可选：本地 Sonar 扫描（需 SonarQube Server + Token）
mvn sonar:sonar -pl skeleton-service -am -Dsonar.token=${SONAR_TOKEN}
```

---

## 2. 多环境 Profile（团队标准）

| Profile | 数据源 | 配置文件 | 典型场景 |
|---------|--------|----------|----------|
| **dev** | **MySQL** 8.0 | `application-dev.yml` | 本地 Compose 联调（默认） |
| **test** | **MySQL** 8.0 | `application-test.yml` | 远端测试环境部署 |
| **prod** | **MySQL** 8.0 | `application-prod.yml` | 生产 / 预发（uat、pre 同 prod 模式） |
| **local**（个人） | H2 **文件库** `./data/local-db` | `application-local.yml`（gitignore） | 覆盖 dev 的个人 H2 / 日志 / 端口 |
| **（单测）** | H2 内存 | `src/test/resources/application.yml` | `mvn test` / CI 阶段 2 |

**Profile 组合示例**：

```bash
# 本地 MySQL 联调（需 start-local.sh + Compose MySQL）
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev

# 个人 H2 调试（独立数据文件，需 application-local.yml）
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local

# 远端测试环境
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=test

# 生产
java -jar skeleton-service.jar --spring.profiles.active=prod
```

H2 使用 `MODE=MySQL`，Flyway 脚本与 MySQL 方言对齐；联调阶段在 MySQL 上再做最终验证。

---

## 3. JaCoCo 覆盖率报告

| 项 | 约定 |
|----|------|
| **插件** | `jacoco-maven-plugin`（各业务模块 `pom.xml` 已配置） |
| **生成时机** | `mvn test` 后输出 `target/site/jacoco/`（HTML + `jacoco.xml`） |
| **统计范围** | 纳入 `controller/**`、`service/**`、`common/**`；排除启动类、纯配置/DTO/Entity |
| **团队门槛** | 核心业务行覆盖率 **≥ 80%**；新增功能须带测试 |
| **平台留存** | CI 将 `jacoco.xml` / HTML 归档至 Jenkins（或等价 CI）Artifacts；SonarQube 读取 XML 展示历史趋势 |

**CI 覆盖率门禁（强制）**：流水线阶段 2 在 `mvn test` 后校验 JaCoCo 阈值，未达标 **阻断合并**。

---

## 4. SonarQube 代码质量扫描

SonarQube 用于拦截 AI 批量生成代码中的常见问题，并与 IDE SonarLint 规则对齐。

### 4.1 扫描目标（AI 高发问题）

| 类别 | 检测内容 |
|------|----------|
| **空指针 / NPE** | 未判空 dereference、Optional 误用 |
| **硬编码** | 魔法数、环境相关常量、敏感信息明文 |
| **资源未关闭** | IO / Connection / Stream 未 try-with-resources |
| **安全漏洞** | SQL 注入、弱加密、路径遍历、日志泄露密钥 |

### 4.2 强制规则（Quality Gate 阻断项）

以下规则在 SonarQube **Quality Profile** 中设为 **Blocker / Critical**，CI 阶段 1 未通过则 **禁止合并**：

| 规则 ID / 主题 | 说明 |
|----------------|------|
| **`java:S106`** | 禁止 `System.out` / `System.err`（须 SLF4J） |
| **`java:S1181` / `java:S2221`** | 禁止捕获 `Throwable` 或空 catch 吞掉异常 |
| **`java:S3649` / `java:S2077`** | SQL 注入风险（字符串拼接 SQL、`${}` 误用） |
| **`java:S3047` / 循环内创建** | 循环内重复 `new` 可复用对象（性能与 GC 风险） |
| **安全 Hotspot** | 须人工或 CI 策略确认，未审核阻断发布 |

> 完整规则清单与本地用法见 [`SONARQUBE.md`](SONARQUBE.md)。Cursor 规则 [`alibaba-java-standard.mdc`](../../.cursor/rules/alibaba-java-standard.mdc) 与上述规则一致，生成代码须先过 IDE SonarLint。

### 4.3 AI 生成代码的扫描策略

1. **IDE 实时**：SonarLint Standalone / Connected Mode，保存即提示。
2. **提交前**：开发者本地 `mvn test` + 可选 `mvn sonar:sonar`。
3. **CI 强制**：每次 Push / PR 触发 Sonar 扫描，Quality Gate 失败则流水线红。

---

## 5. 标准 CI 门禁流水线

本流程保证：**Cursor 批量重生成业务代码后，只要流水线全部放行，迭代不会破坏原有功能**。

```text
开发提交代码
    │
    ▼
本地预校验（单元测试 + JaCoCo 覆盖率）
    │
    ▼
Git Push / PR ──► 触发 CI 流水线
    │
    ├──► [1] SonarQube 代码质量扫描 ────────────── 失败 ► 阻断合并
    │
    ├──► [2] JUnit5 单元测试（H2 内存）+ JaCoCo 覆盖率门禁 ─ 失败 ► 阻断
    │
    ├──► [3] Controller 集成测试（@SpringBootTest + MockMvc）── 失败 ► 阻断
    │
    ├──► [4] 契约兼容性校验（OpenAPI / Spring Cloud Contract）─ 失败 ► 阻断
    │
    └──► [5] 【仅 release/* 分支】Testcontainers + MySQL 全量测试 ─ 失败 ► 阻断
    │
    ▼
全部通过 ──► 允许合并到 main / 发布
任意环节失败 ──► 阻断合并（无例外，除非架构师书面豁免并留痕）
```

### 5.1 各阶段说明

| 阶段 | 工具 / 实现 | 通过标准 |
|------|-------------|----------|
| **1 Sonar** | `mvn sonar:sonar` + SonarQube Server | Quality Gate = OK；强制规则零违规 |
| **2 单测 + 覆盖率** | JUnit 5、H2（`src/test/resources`）、JaCoCo | 全部测试绿；覆盖率 ≥ 团队阈值 |
| **3 Controller 集成测试** | `*IntegrationTest`、`@AutoConfigureMockMvc` | API 行为与重构前一致 |
| **4 契约校验** | springdoc OpenAPI diff / Spring Cloud Contract（SCC） | 对外 API 无破坏性变更（或版本已 bump） |
| **5 Release 全量** | Testcontainers MySQL 8.0 + Flyway + 全量集成测试 | 真实方言 SQL、事务、迁移脚本可跑通 |

### 5.2 分支策略

| 分支类型 | 执行阶段 |
|----------|----------|
| `feature/*`、`develop`、PR | 阶段 1～4 |
| `release/*`、生产 Tag | 阶段 1～5（含 Testcontainers MySQL） |

### 5.3 与 Jenkins 的关系

根目录 [`Jenkinsfile`](../../Jenkinsfile) 已对齐本文 §5 门禁阶段：

| Jenkins Stage | CI-TOOLCHAIN 阶段 |
|---------------|-------------------|
| `[2] * Unit Tests + JaCoCo` | 阶段 2（skeleton 含 `jacoco:check`） |
| `[1] * SonarQube` | 阶段 1（依赖 JaCoCo 报告，`qualitygate.wait=true`） |
| `[3] * Integration Tests` | 阶段 3 |
| `[4] * Contract Tests` | 阶段 4（`-Pcontract-tests`） |
| `[5] * Release MySQL` | 阶段 5（`-Prelease-integration`，仅 `release/*` 或 Tag） |

部署细节见 [`docs/DEPLOYMENT.md`](../../docs/DEPLOYMENT.md) §13。

### 5.4 本地模拟 CI

```bash
# 阶段 2（单测 + JaCoCo 门禁）
mvn clean test -Pci-unit-tests -pl skeleton-service -am
mvn jacoco:check -pl skeleton-service

# 阶段 3（Controller 集成）
mvn test -Pci-integration-tests -pl skeleton-service -am

# 阶段 1（Sonar，依赖阶段 2 的 jacoco.xml）
mvn sonar:sonar -pl skeleton-service -am -Dsonar.token=${SONAR_TOKEN}

# 阶段 4（OpenAPI 契约）
mvn test -Pcontract-tests -pl skeleton-service -am

# 阶段 5（release 分支，需 Docker）
mvn test -Prelease-integration -pl skeleton-service -am
```

---

## 6. 相关文件索引

| 文件 | 说明 |
|------|------|
| [`SONARQUBE.md`](SONARQUBE.md) | SonarLint / SonarQube 使用与强制规则 |
| [`CURSOR-RULES.md`](CURSOR-RULES.md) | Cursor / AI 代码规范（与 Sonar 对齐） |
| [`.cursor/rules/alibaba-java-standard.mdc`](../../.cursor/rules/alibaba-java-standard.mdc) | 规则源文件 |
| [`unit-testing.md`](../../java-microservice-scaffold/docs/unit-testing.md) | 测试分层与 JaCoCo |
| [`engineering-standards.md`](../../java-microservice-scaffold/docs/engineering-standards.md) | Maven / Profile 细则 |
| [`Jenkinsfile`](../../Jenkinsfile) | CI 流水线（持续对齐本文门禁） |
| [`docs/PULL-REQUEST-WORKFLOW.md`](../../docs/PULL-REQUEST-WORKFLOW.md) | Pull Request 分支、Review 与合并规范 |
| [`docs/DEPLOYMENT.md`](../../docs/DEPLOYMENT.md) | 部署与 Jenkins 配置 |

---

## 7. 团队执行 checklist

- [ ] 提交前本地 `mvn clean test` 通过，JaCoCo 达门槛
- [ ] IDE 已安装 SonarLint，Connected Mode 绑定团队 SonarQube
- [ ] 变更通过 Pull Request 合入 `main`，流程见 [`docs/PULL-REQUEST-WORKFLOW.md`](../../docs/PULL-REQUEST-WORKFLOW.md)
- [ ] PR 必须等 CI 全绿再合并；禁止 `--no-verify` 跳过门禁
- [ ] AI 批量改码后重点回归：阶段 3 集成测试 + 阶段 4 契约
- [ ] release 分支合并前确认阶段 5 MySQL 全量测试已通过
