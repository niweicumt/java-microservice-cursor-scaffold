# java-microservice-scaffold

微服务 **业务脚手架工程**：业务服务模板、Compose/K8s 共享基础设施配置。公共组件通过 Maven 依赖 [`java-microservice-common`](../java-microservice-common/)，API 网关见独立工程 [`java-microservice-gateway`](../java-microservice-gateway/)。

> **新同学入门**：[`docs/GETTING-STARTED.md`](../docs/GETTING-STARTED.md)  
> 从零搭建（macOS）：[`docs/microservice-zero-to-one.md`](docs/microservice-zero-to-one.md)  
> 包路径配置：[`../shared/docs/PACKAGE-IDENTITY.md`](../shared/docs/PACKAGE-IDENTITY.md)

## 模块

| 模块 | 端口 | 说明 |
|------|------|------|
| `skeleton-service` | 8081 | 业务服务模板（MyBatis Plus + Flyway + Kafka） |
| `platform/` | — | Docker Compose、K8s、Nacos 配置样例（共享基础设施） |

> API 网关（8080）不在本工程内，见 [`java-microservice-gateway`](../java-microservice-gateway/)。

## 首次构建

```bash
# 1. 先安装 common（独立工程）
cd ../java-microservice-common && mvn clean install && cd ../java-microservice-scaffold

# 2. 单元测试（H2 内存库，无需 MySQL / Docker）
mvn clean test

# 3. 本地联调：启动基础设施（含 MySQL）
./platform/docker-compose/start-local.sh

# 4. MySQL 联调：启动业务服务（dev Profile，见 application-dev.yml）
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev

# 5. 个人 H2 调试（无需 Compose）：
# mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local

# 6. 启动网关（独立工程，另开终端）
cd ../java-microservice-gateway && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

> **单测 vs 联调**：`mvn test` 走 H2；MySQL 联调用 `dev` Profile；个人 H2 用 `dev,local`。详见 [`docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md) §3.4。

## 引用 common

根 `pom.xml`：

```xml
<properties>
    <microservice-common.version>1.0.0-SNAPSHOT</microservice-common.version>
</properties>
```

## 修改包名 / 创建新服务

| 操作 | 命令 |
|------|------|
| 组织前缀 com.s3 → com.tm | 仓库根：`./shared/scripts/configure-organization.sh --org com.tm` |
| 团队 fork 改前缀 | `./shared/scripts/configure-skeleton.sh --base-package com.acme.skeleton` |
| 创建 order-service | `./shared/scripts/rename-skeleton.sh --package com.acme.order --artifact order-service` |

配置标识：[`skeleton.defaults.json`](skeleton.defaults.json)

## 文档

| 文档 | 说明 |
|------|------|
| [docs/DEPLOYMENT.md](../../docs/DEPLOYMENT.md) | **网关与业务微服务部署** |
| [docs/microservice-zero-to-one.md](docs/microservice-zero-to-one.md) | macOS 0→1 搭建 |
| [docs/SKELETON.md](docs/SKELETON.md) | 分层与规范 |
| [docs/MICROSERVICES.md](docs/MICROSERVICES.md) | 模块速查 |
| [docs/engineering-standards.md](docs/engineering-standards.md) | Maven 细则 |

## 技术栈

JDK 17 · Spring Boot 3.3.13 · Spring Cloud 2023.0.5 · Nacos · Kafka
