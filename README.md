# Java 微服务 Monorepo

本仓库包含 **三个独立 Maven 工程** + **共享配置与脚本**，可从 0 到 1 搭建微服务体系。

> **新加入团队？** 请从 **[新手入门指南](docs/GETTING-STARTED.md)** 开始，按 Day 1 Checklist 逐步完成环境搭建与首次构建。

---

## 仓库结构

```text
java-cursor-demo/
├── shared/                            # 公共：包路径配置与脚本
│   ├── package.defaults.json          # 组织前缀（com.s3 → com.tm …）
│   ├── docs/                          # 团队共享文档（CI、IDE、包路径…）
│   └── scripts/
│       ├── configure-organization.sh  # 一键改三个工程的组织前缀
│       ├── configure-skeleton.sh
│       └── rename-skeleton.sh
│
├── .mvn/                              # 公共 Maven 镜像配置（三个工程共用）
├── Jenkinsfile                        # Jenkins 主流水线（构建 + 镜像 + K8s 发布）
├── jenkins/Jenkinsfile.common         # 独立 Job：仅发布 common 到私服
│
├── java-microservice-common/          # ① 公共组件（独立 build / deploy）
│   ├── common-core/                   # 常量、枚举、异常、工具、Result
│   ├── common-cloud-starter/          # Nacos、Feign、Kafka、监控、链路
│   └── common-bom/
│
├── java-microservice-gateway/         # ② API 网关（独立 deploy，全局唯一）
│   └── gateway-service（可执行 JAR）
│
└── java-microservice-scaffold/        # ③ 业务服务脚手架
    ├── skeleton-service/              # 业务服务模板
    └── platform/                      # Compose / K8s / Nacos（共享基础设施）
```

---

## 快速开始

```bash
# 1. 安装公共组件
cd java-microservice-common && mvn clean install && cd ..

# 2. 单元测试（H2 内存库，无需 MySQL / Docker）
cd java-microservice-gateway && mvn clean test && cd ..
cd java-microservice-scaffold && mvn clean test

# 3. 本地联调时再启动基础设施（含 MySQL）
# cd java-microservice-scaffold && ./platform/docker-compose/start-local.sh
# mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
```

完整步骤、IDE 配置、AI 工作流与文档索引见 **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)**。

---

## 文档索引

### 入门

| 文档 | 说明 |
|------|------|
| **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)** | **新手入门指南（Day 1 路径 + 文档地图）** |
| [java-microservice-scaffold/docs/microservice-zero-to-one.md](java-microservice-scaffold/docs/microservice-zero-to-one.md) | macOS 从零搭建（逐步说明） |

### 规范与质量

| 文档 | 说明 |
|------|------|
| [docs/PULL-REQUEST-WORKFLOW.md](docs/PULL-REQUEST-WORKFLOW.md) | **Pull Request 工作流（分支、Review、合并）** |
| [shared/docs/CI-TOOLCHAIN.md](shared/docs/CI-TOOLCHAIN.md) | 工程自动化与 CI 质量门禁 |
| [shared/docs/SONARQUBE.md](shared/docs/SONARQUBE.md) | SonarLint / SonarQube |
| [shared/docs/CURSOR-RULES.md](shared/docs/CURSOR-RULES.md) | Cursor 规则（阿里 + 微服务约束） |
| [shared/docs/CURSOR-IDE-SETUP.md](shared/docs/CURSOR-IDE-SETUP.md) | Cursor 必装 + OpenSpec / Speckit |
| [.cursor/rules/alibaba-java-standard.mdc](.cursor/rules/alibaba-java-standard.mdc) | Cursor 规则源文件 |

### 开发与部署

| 文档 | 说明 |
|------|------|
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | 部署指南（本地基础设施 + 网关/业务 + Jenkins） |
| [shared/docs/PACKAGE-IDENTITY.md](shared/docs/PACKAGE-IDENTITY.md) | 包路径与组织前缀 |
| [java-microservice-scaffold/docs/SKELETON.md](java-microservice-scaffold/docs/SKELETON.md) | 分层与创建新服务 |
| [java-microservice-scaffold/docs/MICROSERVICES.md](java-microservice-scaffold/docs/MICROSERVICES.md) | 模块速查 |

### 子工程

| 文档 | 说明 |
|------|------|
| [java-microservice-common/README.md](java-microservice-common/README.md) | 公共组件工程 |
| [java-microservice-gateway/README.md](java-microservice-gateway/README.md) | API 网关工程 |
| [java-microservice-scaffold/README.md](java-microservice-scaffold/README.md) | 业务脚手架工程 |

---

## 修改组织前缀

将默认 `com.s3` 改为团队前缀（如 `com.tm`）：

```bash
./shared/scripts/configure-organization.sh --org com.tm
cd java-microservice-common && mvn clean install
cd ../java-microservice-gateway && mvn clean test
cd ../java-microservice-scaffold && mvn clean test
```

详见 [shared/docs/PACKAGE-IDENTITY.md](shared/docs/PACKAGE-IDENTITY.md)。

---

## 原则

- **common / gateway / scaffold 分离**：common 发版供依赖；gateway 全局部署一份；scaffold 只含业务服务模板
- **禁止 copy common 源码** 到业务工程
- **包路径可配置**：通过 `shared/scripts/configure-organization.sh` 统一替换组织前缀
