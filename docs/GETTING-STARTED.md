# 新手入门指南

面向 **新加入团队的开发者**，按顺序完成环境搭建、首次构建、IDE 配置与日常开发路径。  
详细专题仍保留在各自文档中，本文只做 **路径编排与索引**，避免在多个 README 之间来回跳转。

> **预计用时**：Day 1 约 1～2 小时（不含 Docker 全栈联调）；全栈联调另需约 30 分钟。

---

## 1. 第一天 Checklist

按顺序勾选，全部完成即可进入日常开发：

- [ ] **1.1** 安装 JDK 17、Maven 3.9+、Git、Cursor
- [ ] **1.2** 克隆仓库并在 `java-microservice-common` 执行 `mvn clean install`
- [ ] **1.3** 在 gateway / scaffold 执行 `mvn clean test`（H2，无需 Docker）
- [ ] **1.4** 用 Cursor 打开仓库根目录，安装推荐扩展（SonarLint）
- [ ] **1.5** 安装 Cursor 插件 Superpowers、CLI 工具 OpenSpec（见 [§3](#3-ide-与-ai-工具链)）
- [ ] **1.6** 阅读 [§4 仓库结构](#4-仓库结构) 与 [§6 团队必守原则](#6-团队必守原则)
- [ ] **1.7**（可选）启动 Docker Compose 做 MySQL 联调（见 [§5.2](#52-路径-b本地全栈联调)）

---

## 2. 环境要求

| 项 | 版本 / 说明 | 用途 |
|----|-------------|------|
| **JDK** | 17 | Spring Boot 3 最低要求 |
| **Maven** | 3.9+ | 构建；根目录 `.mvn/settings.xml` 已配镜像 |
| **Git** | 任意较新版本 | 版本管理 |
| **Cursor** | 团队统一 IDE | 开发 + AI Agent |
| **Node.js** | ≥ 20.19.0 | OpenSpec CLI |
| **Docker** | 可选 | MySQL 联调、SonarQube 本地、release Testcontainers |

验证命令：

```bash
java -version    # openjdk 17
mvn -version     # Apache Maven 3.9+
node -v          # v20.19.0+（OpenSpec 需要）
docker -v        # 可选
```

---

## 3. 克隆与首次构建

```bash
git clone <repo-url> java-cursor-demo
cd java-cursor-demo

# ① 安装公共组件到本地 ~/.m2（必须先做）
cd java-microservice-common && mvn clean install && cd ..

# ② 单元测试（H2 内存库，无需 MySQL / Docker）
cd java-microservice-gateway && mvn clean test && cd ..
cd java-microservice-scaffold && mvn clean test
```

**说明**：

- `mvn test` 走 H2 内存库，**不需要**启动 MySQL 或 Docker。
- 只有 `spring-boot:run` 本地联调时才需要基础设施，见 [§5.2](#52-路径-b本地全栈联调)。
- Maven 镜像：根目录 `.mvn/settings.xml`；个人仓库路径可复制 `.mvn/settings.xml.example`。

---

## 4. 仓库结构

本 Monorepo 包含 **三个独立 Maven 工程** + **共享配置**：

```text
java-cursor-demo/
├── shared/                         # 包路径配置与脚本（三个工程共用）
│   ├── package.defaults.json
│   ├── docs/                       # 团队共享文档（CI、IDE、包路径…）
│   └── scripts/
│       ├── configure-organization.sh   # 一键改组织前缀
│       ├── configure-skeleton.sh
│       └── rename-skeleton.sh
│
├── .mvn/                           # Maven 镜像（三工程共用）
├── Jenkinsfile                     # CI/CD 主流水线
│
├── java-microservice-common/       # ① 公共组件（独立 build / deploy）
│   ├── common-core/                # Result、异常、工具
│   ├── common-cloud-starter/       # Nacos、Feign、Kafka
│   └── common-bom/
│
├── java-microservice-gateway/      # ② API 网关（全局唯一，8080）
│
└── java-microservice-scaffold/     # ③ 业务服务脚手架
    ├── skeleton-service/           # 业务模板（8081）
    └── platform/                   # Compose / K8s / Nacos
```

### 请求链路（本地联调）

```text
浏览器 / curl
    │
    ▼
gateway-service :8080          ← 统一入口
    │  lb://skeleton-service
    ▼
skeleton-service :8081        ← 业务逻辑 + DB + Kafka
    │
    ├── Nacos（注册、配置）
    ├── MySQL（Flyway）
    └── Kafka（可选）
```

### 技术栈摘要

JDK 17 · Spring Boot 3.3.13 · Spring Cloud 2023.0.5 · Spring Cloud Alibaba 2023.0.1.2 ·  
Nacos · Gateway · Kafka · MyBatis Plus · MySQL 8.0 · Flyway · 统一返回 `Result(code, msg, data)`

---

## 5. 三条开发路径

根据你的目标选择路径，不必第一天全部做完。

### 5.1 路径 A：只跑单元测试（最快，Day 1 必做）

适合：熟悉代码、改 common、CI 门禁验证。

```bash
cd java-microservice-common && mvn clean install && cd ..
cd java-microservice-scaffold && mvn clean test

# 查看覆盖率报告（可选）
open skeleton-service/target/site/jacoco/index.html
```

Profile 与测试约定见 [`shared/docs/CI-TOOLCHAIN.md`](../shared/docs/CI-TOOLCHAIN.md) §2。

### 5.2 路径 B：本地全栈联调

适合：接口调试、Flyway 迁移验证、网关路由。

```bash
# 1. 启动基础设施（Nacos / MySQL / Kafka / Redis）
cd java-microservice-scaffold
./platform/docker-compose/start-local.sh

# 2. 启动业务服务（另开终端）
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev

# 3. 启动网关（再开终端）
cd ../java-microservice-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

**个人 H2 调试**（无需 Compose）：`-Dspring-boot.run.profiles=dev,local`，需自建 `application-local.yml`（gitignore）。

macOS 逐步说明：[`java-microservice-scaffold/docs/microservice-zero-to-one.md`](../java-microservice-scaffold/docs/microservice-zero-to-one.md)  
部署与运维细节：[`docs/DEPLOYMENT.md`](DEPLOYMENT.md)

### 5.3 路径 C：用 AI 开发新功能

团队 **不直接让 Agent 改代码**，而是先写可追溯的规格文档，再按文档实现。

| 工具 | 定位 | Cursor 命令 | 产出目录 |
|------|------|-------------|----------|
| **OpenSpec** | 变更级：提案 → 设计 → 任务 → 归档 | `/opsx-*` | `openspec/changes/<变更名>/` |
| **Speckit** | 功能级：spec → plan → tasks → 实现 | `/speckit.*` | `java-microservice-scaffold/specs/<feature>/` |

推荐流程：

```text
需求 → /opsx-propose → /speckit.specify → /speckit.plan → /speckit.tasks
     → /speckit.implement → /opsx-sync → /opsx-archive
```

样例：`java-microservice-scaffold/examples/001-user-management/`  
完整说明：[`shared/docs/CURSOR-IDE-SETUP.md`](../shared/docs/CURSOR-IDE-SETUP.md) §1.2

---

## 6. IDE 与 AI 工具链

| # | 类型 | 名称 | 必装 |
|---|------|------|:----:|
| 1 | VS Code 扩展 | SonarLint | ✅ |
| 2 | Cursor 插件 | Superpowers | ✅ |
| 3 | CLI | OpenSpec | ✅ |

安装步骤、Connected Mode、Superpowers 更新方式：  
**[`shared/docs/CURSOR-IDE-SETUP.md`](../shared/docs/CURSOR-IDE-SETUP.md)**

AI 生成代码时的规范约束：  
**[`shared/docs/CURSOR-RULES.md`](../shared/docs/CURSOR-RULES.md)**（源文件在 `.cursor/rules/`）

---

## 7. 团队必守原则

1. **common / gateway / scaffold 分离** — common 发版供依赖；gateway 全局部署一份；scaffold 只含业务模板。
2. **禁止 copy common 源码** 到业务工程，通过 Maven 依赖 `common-cloud-starter`。
3. **包路径可配置** — 改组织前缀用 `./shared/scripts/configure-organization.sh`，详见 [`shared/docs/PACKAGE-IDENTITY.md`](../shared/docs/PACKAGE-IDENTITY.md)。
4. **配置分离** — 环境用 Spring Profile 切换；密钥走环境变量 / K8s Secret；`application-local.yml` 不提交 Git。
5. **提交前自测** — `mvn clean test` + SonarLint 无新增阻断项；核心业务覆盖率 ≥ 80%。
6. **分层约定** — AI 业务代码在 `auto.*`，人工定制在 `custom.*`；详见 [`java-microservice-scaffold/docs/SKELETON.md`](../java-microservice-scaffold/docs/SKELETON.md)。

---

## 8. 常见操作速查

| 目标 | 命令 / 文档 |
|------|-------------|
| 改组织前缀 `com.s3` → `com.tm` | `./shared/scripts/configure-organization.sh --org com.tm` → 见 [PACKAGE-IDENTITY](../shared/docs/PACKAGE-IDENTITY.md) |
| 从 skeleton 复制出新服务 | `./shared/scripts/rename-skeleton.sh --package com.acme.order --artifact order-service` |
| 创建新功能规格 | Cursor：`/speckit.specify` 或 `/opsx-propose` |
| 提交 PR / Code Review | 见 [PULL-REQUEST-WORKFLOW](PULL-REQUEST-WORKFLOW.md) |
| 本地 Sonar 扫描 | 见 [SONARQUBE](../shared/docs/SONARQUBE.md) |
| CI 流水线与门禁 | 见 [CI-TOOLCHAIN](../shared/docs/CI-TOOLCHAIN.md)、根目录 `Jenkinsfile` |

---

## 9. 文档地图

按 **阶段** 查阅，避免迷失：

### 新手入门（本文 + 首周）

| 文档 | 说明 |
|------|------|
| **[docs/GETTING-STARTED.md](GETTING-STARTED.md)** | **本文：Day 1 路径与索引** |
| [shared/docs/CURSOR-IDE-SETUP.md](../shared/docs/CURSOR-IDE-SETUP.md) | Cursor 必装、OpenSpec / Speckit |
| [java-microservice-scaffold/docs/microservice-zero-to-one.md](../java-microservice-scaffold/docs/microservice-zero-to-one.md) | macOS 从零搭建（逐步截图级） |

### 工程规范与质量

| 文档 | 说明 |
|------|------|
| [docs/PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md) | **Pull Request 工作流** |
| [shared/docs/CI-TOOLCHAIN.md](../shared/docs/CI-TOOLCHAIN.md) | Maven、Profile、JaCoCo、CI 门禁 |
| [shared/docs/SONARQUBE.md](../shared/docs/SONARQUBE.md) | SonarLint / SonarQube |
| [shared/docs/CURSOR-RULES.md](../shared/docs/CURSOR-RULES.md) | Cursor 规则（阿里 + 微服务架构） |
| [java-microservice-scaffold/docs/engineering-standards.md](../java-microservice-scaffold/docs/engineering-standards.md) | Maven 与工程细则 |
| [java-microservice-scaffold/docs/unit-testing.md](../java-microservice-scaffold/docs/unit-testing.md) | 单元测试约定 |
| [java-microservice-scaffold/.specify/memory/constitution.md](../java-microservice-scaffold/.specify/memory/constitution.md) | 技术宪法（Speckit 对齐） |

### 开发与部署

| 文档 | 说明 |
|------|------|
| [docs/DEPLOYMENT.md](DEPLOYMENT.md) | 本地基础设施、网关/业务部署、Jenkins |
| [shared/docs/PACKAGE-IDENTITY.md](../shared/docs/PACKAGE-IDENTITY.md) | 包路径与组织前缀 |
| [java-microservice-scaffold/docs/SKELETON.md](../java-microservice-scaffold/docs/SKELETON.md) | 分层、脚本、创建新服务 |
| [java-microservice-scaffold/docs/MICROSERVICES.md](../java-microservice-scaffold/docs/MICROSERVICES.md) | 模块速查 |

### 子工程 README

| 文档 | 说明 |
|------|------|
| [java-microservice-common/README.md](../java-microservice-common/README.md) | 公共组件 |
| [java-microservice-gateway/README.md](../java-microservice-gateway/README.md) | API 网关 |
| [java-microservice-scaffold/README.md](../java-microservice-scaffold/README.md) | 业务脚手架 |

---

## 10. 下一步（按角色）

| 角色 | 建议阅读顺序 |
|------|--------------|
| **后端开发** | 本文 → SKELETON → PULL-REQUEST-WORKFLOW → CI-TOOLCHAIN → CURSOR-IDE-SETUP |
| **DevOps / 发布** | DEPLOYMENT → CI-TOOLCHAIN → Jenkinsfile |
| **架构 / TL** | constitution → MICROSERVICES → PACKAGE-IDENTITY |
| **仅改 common** | common/README → common/docs/DEVELOPMENT.md |

有问题先在团队频道提问，并附上 `mvn -version` 与失败命令的完整输出。
