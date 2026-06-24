# 质量门禁与 CI/CD

**团队强制约束**：构建、Profile、JaCoCo 覆盖率、SonarQube、单测分层与 Jenkins 流水线。  
日常 Checklist 见 [TEAM-PLAYBOOK.md §4](TEAM-PLAYBOOK.md#4-pre-pr-checklist)；PR 流程见 [PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md)。

> Monorepo 使用 **Maven 3.9+ / JDK 17**；各子工程独立 `pom.xml`，共享根目录 `.mvn/settings.xml`。

---

## 目录

1. [强制原则](#1-强制原则)
2. [统一构建与 Profile](#2-统一构建与-profile)
3. [单元测试与分层](#3-单元测试与分层)
4. [JaCoCo 覆盖率](#4-jacoco-覆盖率)
5. [SonarQube](#5-sonarqube)
6. [CI 流水线（Jenkins）](#6-ci-流水线jenkins)
7. [本地模拟 CI](#7-本地模拟-ci)

---

## 1. 强制原则

| 原则 | 说明 |
|------|------|
| **测试随代码提交** | 所有业务代码变更 **必须** 附带单元测试；未达标覆盖率 **禁止** 合入 |
| **配置分离** | Profile 切换环境；密钥走环境变量 / K8s Secret |
| **单测不依赖 MySQL** | `mvn test` / CI 阶段 2 使用 H2 内存库 |
| **AI 代码同步测试** | `auto.*` 业务代码须同步 `unit/auto/**/*Test` |
| **CI 全绿才合并** | 阶段 1～4 任一失败即阻断（release 另含阶段 5） |

---

## 2. 统一构建与 Profile

| Profile | 数据源 | 配置文件 | 典型场景 |
|---------|--------|----------|----------|
| **dev** | MySQL 8.0 | `application-dev.yml` | 本地 Compose 联调 |
| **test** | MySQL | `application-test.yml` | 远端测试环境 |
| **prod** | MySQL | `application-prod.yml` | 生产 / 预发 |
| **local** | H2 文件库 | `application-local.yml`（gitignore） | `dev,local` 个人调试 |
| **（单测）** | H2 内存 | `src/test/resources/application.yml` | `mvn test` / CI |

```bash
# 本地 MySQL 联调
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev

# 个人 H2
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local
```

**提交前预校验**：

```bash
cd java-microservice-common && mvn clean install && cd ../java-microservice-scaffold
mvn clean test
open skeleton-service/target/site/jacoco/index.html
```

Maven 日常命令（非 Profile）：[engineering-standards.md](../java-microservice-scaffold/docs/engineering-standards.md)

---

## 3. 单元测试与分层

| 层级 | 类命名 | 说明 |
|------|--------|------|
| 纯单元测试 | `*Test` | Mockito，不启 Spring |
| Controller 单元 | `*Test` | MockMvc standalone |
| **Controller 集成** | `*IntegrationTest` | H2 + MockMvc + OpenAPI 契约 |
| **OpenAPI 契约** | `contract/*Test` | 基线 YAML vs `/v3/api-docs` |

```text
src/test/java/.../
├── unit/auto/**/*Test          # AI 业务单测（随 CRUD 同步）
├── integration/**/*IntegrationTest
└── contract/OpenApiContractTest.java

src/test/resources/contracts/skeleton-api.openapi.yaml
```

```bash
mvn clean test                              # 全部
mvn test -Pci-integration-tests             # 阶段 3
mvn test -Pcontract-tests                   # 阶段 4
```

**变更 API 时**：先更新 `skeleton-api.openapi.yaml`，再改 Controller/DTO；破坏性变更须 bump `info.version`。

---

## 4. JaCoCo 覆盖率

| 项 | 约定 |
|----|------|
| 生成 | `mvn test` → `target/site/jacoco/` |
| 纳入统计 | `controller/**`、`service/**`、`common/**` |
| 排除 | 启动类、`config/**`、`dto/**`、`entity/**`、`repository/**` |
| **团队门槛** | 核心业务行覆盖率 **≥ 80%**；Service **≥ 90%** |
| CI | 阶段 2 `jacoco:check` 未达标 **阻断合并** |

---

## 5. SonarQube 与 SonarLint

本仓库集成 **SonarLint（IDE）** + **SonarQube Server（可选本地 Docker）** + **Maven Sonar 插件**。  
IDE 安装步骤见 [AI-NATIVE-ENGINEERING.md §2](AI-NATIVE-ENGINEERING.md#2-工具链必装)。

### 5.1 SonarLint（IDE）

团队推荐扩展（[`.vscode/extensions.json`](../.vscode/extensions.json)）：

| 扩展 ID | 名称 |
|---------|------|
| `SonarSource.sonarlint-vscode` | SonarLint |

```bash
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
  --install-extension SonarSource.sonarlint-vscode
```

| 模式 | 说明 |
|------|------|
| **Standalone** | 编辑 Java 时实时提示 Bug / 漏洞 / 坏味道 |
| **Connected** | 连接 SonarQube，同步质量门禁（见 §5.2） |

工作区已预置 `http://localhost:9000`（[`.vscode/settings.json`](../.vscode/settings.json)）。  
在 SonarQube 创建项目并生成 Token 后，命令面板执行 **SonarLint: Add SonarQube Connection** 绑定 Token。

### 5.2 本地 SonarQube Server（可选）

```bash
cd java-microservice-scaffold
docker compose -f platform/docker-compose/docker-compose.sonar.yml up -d
```

| 项 | 值 |
|----|-----|
| 地址 | http://localhost:9000 |
| 默认账号 | `admin` / `admin`（首次须改密） |
| 镜像 | `sonarqube:10.8.1-community` |

### 5.3 Maven 扫描

各工程 `sonar-project.properties` 已配置；先 `mvn test` 生成 JaCoCo，再 `sonar:sonar`。

```bash
cd java-microservice-common && mvn clean install -DskipTests && cd ../java-microservice-scaffold
mvn clean test
mvn sonar:sonar -pl skeleton-service -am -Dsonar.token=${SONAR_TOKEN}
```

Common / Gateway 同理：`mvn clean test sonar:sonar -Dsonar.token=${SONAR_TOKEN}`。Token **勿提交 Git**。

### 5.4 强制规则（Quality Gate）

CI 阶段 1 未通过 **阻断 PR 合并**。AI 生成代码须先过 SonarLint。

| 规则 | 说明 |
|------|------|
| `java:S106` | 禁止 `System.out` / `System.err` |
| `java:S1181` / `java:S2221` | 禁止吞异常、禁止 catch `Throwable` |
| `java:S3649` / `java:S2077` | SQL 注入（拼接 SQL、`${}` 误用） |
| 循环内重复 `new` | 性能与 GC 风险 |

### 5.5 常见问题

| 现象 | 处理 |
|------|------|
| SonarLint 无提示 | 安装扩展并重载；确认 Maven 项目已加载 |
| Connected Mode 失败 | 检查 SonarQube 是否启动、Token 是否有效 |
| `sonar:sonar` 401 | 补充 `-Dsonar.token=` |
| SonarQube 启动慢 | 首次约 1～2 分钟；Docker 建议 ≥4GB 内存 |

相关文件：`.vscode/extensions.json` · `platform/docker-compose/docker-compose.sonar.yml` · 各工程 `sonar-project.properties`

---

## 6. CI 流水线（Jenkins）

```text
Push / PR
    ├── [1] SonarQube ──────────────── 失败 ► 阻断
    ├── [2] JUnit5 + JaCoCo ──────── 失败 ► 阻断
    ├── [3] Controller 集成测试 ──── 失败 ► 阻断
    ├── [4] OpenAPI 契约 ─────────── 失败 ► 阻断
    └── [5] Testcontainers MySQL ─── 仅 release/* / Tag
```

| Jenkins Stage | 阶段 | 通过标准 |
|---------------|------|----------|
| `[1] SonarQube` | 1 | Quality Gate OK |
| `[2] Unit Tests + JaCoCo` | 2 | 全绿 + 覆盖率阈值 |
| `[3] Integration Tests` | 3 | API 行为一致 |
| `[4] Contract Tests` | 4 | 无破坏性 API 变更 |
| `[5] Release MySQL` | 5 | 真实 MySQL + Flyway |

| 分支 | 执行阶段 |
|------|----------|
| `feature/*`、PR | 1～4 |
| `release/*`、Tag | 1～5 |

定义见根目录 [`Jenkinsfile`](../Jenkinsfile)；部署见 [DEPLOYMENT.md](DEPLOYMENT.md)。

---

## 7. 本地模拟 CI

```bash
cd java-microservice-scaffold

# 阶段 2
mvn clean test -Pci-unit-tests -pl skeleton-service -am
mvn jacoco:check -pl skeleton-service

# 阶段 3
mvn test -Pci-integration-tests -pl skeleton-service -am

# 阶段 1（需 SONAR_TOKEN）
mvn sonar:sonar -pl skeleton-service -am -Dsonar.token=${SONAR_TOKEN}

# 阶段 4
mvn test -Pcontract-tests -pl skeleton-service -am

# 阶段 5（需 Docker，release 分支）
mvn test -Prelease-integration -pl skeleton-service -am
```

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) | 日常 Pre-PR Checklist |
| [engineering-standards.md](../java-microservice-scaffold/docs/engineering-standards.md) | Maven 操作 |
| [test-coverage-report.md](../java-microservice-scaffold/docs/test-coverage-report.md) | 覆盖率报告说明 |
| [PACKAGE-IDENTITY.md](../shared/docs/PACKAGE-IDENTITY.md) | 包路径配置（shared 专题） |
