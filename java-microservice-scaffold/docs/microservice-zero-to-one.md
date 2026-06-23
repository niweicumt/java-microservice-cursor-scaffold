# 微服务工程从零搭建指南（macOS）

本文档面向 **macOS 本地开发**，说明如何基于 **`java-microservice-scaffold/`** 工程，从 0 到 1 搭建、理解并运行微服务。

> **新同学请先读**：[`docs/GETTING-STARTED.md`](../../docs/GETTING-STARTED.md)（Day 1 路径与文档地图）  
> 仓库结构：根目录 [`README.md`](../../README.md)  
> 包路径配置：[`shared/docs/PACKAGE-IDENTITY.md`](../../shared/docs/PACKAGE-IDENTITY.md)（公共）  
> **部署指南**：[`docs/DEPLOYMENT.md`](../../docs/DEPLOYMENT.md)  
> common 工程：[`java-microservice-common/README.md`](../../java-microservice-common/README.md)  
> gateway 工程：[`java-microservice-gateway/README.md`](../../java-microservice-gateway/README.md)

---

## 1. 你将得到什么

启动完成后，本地将具备：

| 能力 | 实现 |
|------|------|
| 服务注册与发现 | Nacos |
| 配置中心 | Nacos Config |
| 统一 API 入口 | Spring Cloud Gateway（8080） |
| 业务微服务样例 | skeleton-service（8081） |
| 消息队列 | Kafka |
| 健康检查 | Actuator（health / metrics） |
| 持久化 | MySQL + Flyway |
| 容器编排（本地） | Docker Compose |
| 容器编排（生产） | Kubernetes（`platform/k8s/base/`） |

---

## 2. 工程结构说明

本仓库包含 **三个独立 Maven 工程**（可拆为三个 Git 仓库维护）：

```text
<repo-root>/
├── java-microservice-common/        # ① 公共组件工程（独立发版）
│   ├── pom.xml
│   ├── common-core/                 # Result、异常、GlobalExceptionHandler
│   ├── common-cloud-starter/        # Nacos/Feign/Kafka/Actuator Starter
│   └── common-bom/                  # 版本 BOM，供业务工程 import
│
├── java-microservice-gateway/       # ② API 网关（独立 deploy，全局一份）
│   ├── pom.xml
│   └── src/                         # Spring Cloud Gateway + Knife4j
│
└── java-microservice-scaffold/      # ③ 业务服务脚手架（本目录 pom.xml）
    ├── pom.xml                      # 通过 microservice-common.version 引用 common
    ├── skeleton-service/
    └── platform/                    # Compose / K8s / Nacos（共享基础设施）
```

**原则**：业务微服务 **不复制** `com.s3.common.*` 源码，仅在 `pom.xml` 中依赖已发布的 `com.s3:common-cloud-starter` 等坐标。

### 2.1 模块职责

| 工程 / 模块 | 类型 | 职责 |
|-------------|------|------|
| `java-microservice-common` | 独立 Maven 工程 | 构建、测试、发布公共 jar |
| `common-core` | Jar | `Result(code,msg,data)`、`BusinessException`、`GlobalExceptionHandler` |
| `common-cloud-starter` | Starter | Nacos、OpenFeign、Kafka、Actuator |
| `common-bom` | BOM | 锁定 common 各模块版本 |
| `java-microservice-gateway` | 独立 Maven 工程 | API 网关，路由转发、Knife4j 文档聚合 |
| `skeleton-service` | 可执行服务 | 业务分层模板，依赖 `common-cloud-starter` |

### 2.2 请求链路（本地）

```text
浏览器 / curl
    │
    ▼
gateway-service :8080          ← 统一入口
    │  lb://skeleton-service
    ▼
skeleton-service :8081        ← 业务逻辑 + DB + Kafka
    │
    ├── Nacos（注册自身、拉取配置）
    ├── MySQL（Flyway 迁移）
    ├── Kafka（可选事件）
    └── Actuator（health / metrics）
```

---

## 3. 组件与依赖版本（锁定清单）

版本在根目录 `pom.xml` 的 `<properties>` 与 `<dependencyManagement>` 中统一管理，**业务模块不应自行覆盖**。

### 3.1 核心运行时

| 组件 | 版本 | 说明 |
|------|------|------|
| JDK | **17** | Spring Boot 3 最低要求 |
| Maven | **3.6.3+**（建议 3.9+） | 构建工具 |
| Spring Boot | **3.3.13** | 父 POM |
| Spring Cloud | **2023.0.5** | 代号 Leyton，对齐 Boot 3.3 |
| Spring Cloud Alibaba | **2023.0.1.2** | Nacos 集成 |

### 3.2 业务与文档

| 组件 | 版本 | 使用模块 |
|------|------|----------|
| MyBatis Plus | **3.5.9** | skeleton-service |
| mybatis-plus-jsqlparser | **3.5.9** | 分页插件依赖 |
| springdoc-openapi | **2.6.0** | skeleton-service |
| knife4j | **4.5.0** | skeleton-service + gateway 聚合 |
| Flyway | Boot 管理版本 | skeleton-service |
| MySQL Connector/J | Boot 管理版本 | skeleton-service |
| JaCoCo | **0.8.12** | 测试覆盖率 |

### 3.3 微服务治理（common-cloud-starter / gateway）

| 组件 | Maven 坐标概要 | 作用 |
|------|----------------|------|
| Nacos Discovery | `spring-cloud-starter-alibaba-nacos-discovery` | 服务注册 |
| Nacos Config | `spring-cloud-starter-alibaba-nacos-config` | 配置中心 |
| OpenFeign | `spring-cloud-starter-openfeign` | 服务间 HTTP 调用 |
| LoadBalancer | `spring-cloud-starter-loadbalancer` | 客户端负载均衡 |
| Spring Cloud Gateway | `spring-cloud-starter-gateway` | 网关（`java-microservice-gateway`） |
| Spring Kafka | `spring-kafka` | 消息生产/消费 |
| Spring Boot Actuator | `spring-boot-starter-actuator` | 健康检查 / 基础指标 |

### 3.4 基础设施镜像（Compose）

**本地开发（推荐）** — [`docker-compose.local.yml`](../platform/docker-compose/docker-compose.local.yml) / `./platform/docker-compose/start-local.sh`：

| 组件 | 镜像版本 | 端口 |
|------|----------|------|
| Nacos | `nacos/nacos-server:v2.3.2` | 8848, 9848 |
| MySQL | `mysql:8.0.40` | 3306 |
| Kafka | `apache/kafka:3.8.1` | 9092 |
| Redis | `redis:7.4.2` | 6379 |

---

## 4. macOS 环境准备

### 4.1 必备软件

| 软件 | 建议版本 | 安装方式（macOS） |
|------|----------|-------------------|
| JDK 17 | 17.0.x | [Oracle](https://www.oracle.com/java/technologies/downloads/) / [Temurin](https://adoptium.net/) / `sdk install java 17.0.x-tem` |
| Maven | 3.9+ | `brew install maven` |
| Docker Desktop | 最新稳定版 | [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/) |
| Git | 2.x | `xcode-select --install` 或 `brew install git` |

### 4.2 配置 JDK 17（写入 `~/.zshrc`）

```bash
# Apple Silicon / Intel 均适用
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"
```

```bash
source ~/.zshrc
java -version    # 应显示 17.x
mvn -version     # Java version 应为 17.x
```

### 4.3 验证 Docker

```bash
docker --version
docker compose version
docker info      # 确认 Docker Desktop 已运行
```

### 4.4 克隆仓库

```bash
git clone <your-repo-url> java-cursor-demo
cd java-cursor-demo
```

### 4.5 安装公共组件到本地 Maven 仓库（必做）

common 为**独立工程**（`java-microservice-common/`），脚手架通过版本依赖引用：

```bash
cd java-microservice-common
mvn clean install
cd ../java-microservice-scaffold
```

验证（应能解析到本地 jar）：

```bash
ls ~/.m2/repository/com/s3/common-cloud-starter/1.0.0-SNAPSHOT/
```

### 4.6 Maven 镜像（可选）

项目已包含 `.mvn/settings.xml`（阿里云镜像）。在仓库根目录直接执行 `mvn` 即可，无需额外 `-s` 参数。

---

## 5. 从零启动（macOS 逐步操作）

### 步骤 1：启动基础设施（仅本地联调需要）

> 若只需 `mvn test`，可 **跳过本步骤及步骤 2～3**，直接执行 [步骤 4](#步骤-4编译与测试)。单测使用 H2，不依赖 MySQL。

在 **`java-microservice-scaffold/`** 目录执行：

```bash
./platform/docker-compose/start-local.sh
```

或：

```bash
docker compose -f platform/docker-compose/docker-compose.local.yml up -d
docker compose -f platform/docker-compose/docker-compose.local.yml ps
```

等待 Nacos `healthy`（首次约 30～60 秒）。

| 服务 | 本机地址 | 默认账号 |
|------|----------|----------|
| Nacos 控制台 | http://localhost:8848/nacos | nacos / nacos |
| MySQL | localhost:3306 | root / root |
| Kafka | localhost:9092 | — |
| Redis | localhost:6379 | 密码 `root` |

Compose 已自动创建数据库 `cursor-demo`（utf8mb4）。需要本地监控栈时使用 `docker-compose.yml`（见 [DEPLOYMENT.md](../../docs/DEPLOYMENT.md)）。

### 步骤 2：（推荐）导入 Nacos 配置

打开 Nacos → **配置管理** → **配置列表** → **创建配置**，导入 `platform/nacos/config/` 下样例：

| Data ID | Group | 格式 |
|---------|-------|------|
| `skeleton-service.yaml` | DEFAULT_GROUP | YAML |
| `gateway-service.yaml` | DEFAULT_GROUP | YAML（样例位于 `java-microservice-gateway/platform/nacos/config/`） |

> 未导入也可启动：应用使用 `optional:nacos:...`，本地以 `application*.yml` 为准。

### 步骤 3：编译与测试

```bash
mvn clean test
```

单测使用 H2 内存库，**不需要** MySQL / Nacos / Kafka 即可通过。

> **MySQL 全栈联调**使用 **`dev` Profile**（见 `application-dev.yml`，账号 `root/root`，库 `cursor-demo`），**无需**在 `application-local.yml` 中配置 MySQL。  
> **个人 H2 调试**才需要复制 `application-local.yml.example` → `application-local.yml`，并使用 `dev,local`（见 [`engineering-standards.md`](engineering-standards.md) §2）。

### 步骤 4：启动业务服务

**终端 1**（业务服务，MySQL 联调）：

```bash
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
```

**终端 2**（网关，在 `java-microservice-gateway/` 目录）：

```bash
cd ../java-microservice-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

启动成功标志：

- 日志出现 `Started SkeletonApplication` / `Started GatewayApplication`
- Nacos 控制台 **服务管理 → 服务列表** 可见 `skeleton-service`、`gateway-service`

### 步骤 5：验证

```bash
# 经网关（推荐）
curl -s http://localhost:8080/api/v1/health | python3 -m json.tool

# 直连业务服务
curl -s http://localhost:8081/api/v1/health | python3 -m json.tool
```

浏览器访问：

| 入口 | URL |
|------|-----|
| 网关 API 文档 | http://localhost:8080/doc.html |
| 业务 API 文档 | http://localhost:8081/doc.html |
| Nacos | http://localhost:8848/nacos |

---

## 6. 配置文件说明

### 6.1 Profile 体系

| Profile | 文件 | 用途 |
|---------|------|------|
| 默认 | `application.yml` | Nacos、Kafka、监控、MyBatis 等公共配置 |
| dev | `application-dev.yml` | **Compose MySQL 联调**（`root/root`，库 `cursor-demo`） |
| local | `application-local.yml` | **个人 H2** 覆盖（日志、端口等；**不用于 MySQL 联调**） |
| test | `application-test.yml` | **远端测试环境** MySQL |
| uat/pre/prod | 对应 yml | 各环境部署 |

| 场景 | 启动 Profile | 数据源 |
|------|--------------|--------|
| 个人 H2 调试 | `dev,local` | H2 文件库 |
| **Docker MySQL 全栈联调** | **`dev`** | Compose MySQL |
| 单元测试 | （无需启动）`mvn test` | H2 内存 |

### 6.2 skeleton-service 关键配置

**`application.yml`（节选说明）**

```yaml
spring:
  application:
    name: skeleton-service          # Nacos 注册名，网关 lb:// 路由依赖此名称
  config:
    import: optional:nacos:${spring.application.name}.yaml?...
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
      config:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP:127.0.0.1:9092}

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics

app:
  kafka:
    enabled: true                   # 设为 false 可关闭 Kafka 示例
    skeleton-events-topic: skeleton.events
```

**`application-dev.yml`**

```yaml
server:
  port: 8081                          # 业务服务端口（网关为 8080）
spring:
  datasource: ...                     # 可用环境变量 DB_* 覆盖
  flyway:
    enabled: true
```

### 6.3 网关关键配置（`java-microservice-gateway/`）

```yaml
server:
  port: 8080

spring:
  application:
    name: gateway-service
  cloud:
    gateway:
      routes:
        - id: skeleton-service-api
          uri: lb://skeleton-service   # 通过 Nacos 发现实例
          predicates:
            - Path=/api/v1/**
        - id: skeleton-service-doc
          uri: lb://skeleton-service
          predicates:
            - Path=/v3/api-docs/**,/doc.html/**,/swagger-ui/**,/webjars/**

knife4j:
  gateway:
    enabled: true                     # 聚合下游 OpenAPI 文档
    strategy: discover
```

### 6.4 环境变量一览

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NACOS_ADDR` | `127.0.0.1:8848` | Nacos 地址 |
| `NACOS_NAMESPACE` | `public` | Nacos 命名空间 |
| `KAFKA_BOOTSTRAP` | `127.0.0.1:9092` | Kafka 地址 |
| `DB_HOST` | `127.0.0.1` | MySQL 主机 |
| `DB_PORT` | `3306` | MySQL 端口 |
| `DB_NAME` | `cursor-demo` | 数据库名 |
| `DB_USER` / `DB_PASSWORD` | `root` / `root` | 数据库账号 |

macOS 临时导出示例：

```bash
export NACOS_ADDR=127.0.0.1:8848
export KAFKA_BOOTSTRAP=127.0.0.1:9092
```

### 6.6 脚手架如何引用 common（pom 说明）

根目录 `pom.xml` 片段：

```xml
<properties>
    <microservice-common.version>1.0.0-SNAPSHOT</microservice-common.version>
</properties>

<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.s3</groupId>
            <artifactId>common-bom</artifactId>
            <version>${microservice-common.version}</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>
```

`skeleton-service/pom.xml` 仅声明 artifact，**不写 version**：

```xml
<dependency>
    <groupId>com.s3</groupId>
    <artifactId>common-cloud-starter</artifactId>
</dependency>
```

升级 common：修改 `microservice-common.version` → 在 `java-microservice-common` 执行 `mvn install` 或从私服拉取。

### 6.7 单测配置（无需中间件）

`skeleton-service/src/test/resources/application.yml` 会：

- 关闭 Nacos（`discovery.enabled: false`）
- 使用 H2 内存库
- 关闭 Kafka（`app.kafka.enabled: false`）

因此 `mvn test` 可在无 Docker 环境下运行（仍建议 CI 全量测）。

---

## 7. 创建新的业务微服务

以新增 `order-service` 为例：

### 7.1 复制模块

```bash
cp -R skeleton-service order-service
```

### 7.2 修改 `order-service/pom.xml`

```xml
<artifactId>order-service</artifactId>
<name>order-service</name>
```

### 7.3 注册到父 POM

编辑根目录 `pom.xml`：

```xml
<modules>
    ...
    <module>order-service</module>
</modules>
```

### 7.4 调整包名与启动类

- 将 `com.s3.skeleton` 替换为 `com.acme.order`（包路径、类名）
- `spring.application.name` 改为 `order-service`
- 独立数据库：如 `order_dev`（Flyway 迁移脚本独立维护）

### 7.5 网关增加路由

在 `java-microservice-gateway/src/main/resources/application.yml` 添加：

```yaml
- id: order-service-api
  uri: lb://order-service
  predicates:
    - Path=/api/v1/orders/**
```

### 7.6 Nacos 添加配置

Data ID：`order-service.yaml`，Group：`DEFAULT_GROUP`。

### 7.7 启动验证

```bash
mvn -pl order-service spring-boot:run -Dspring-boot.run.profiles=dev
curl http://localhost:8080/api/v1/orders/...
```

---

## 8. 常用 Maven 命令（macOS 终端）

在 **`java-microservice-scaffold/`** 目录执行：

| 操作 | 命令 |
|------|------|
| 全模块编译测试 | `mvn clean test` |
| 仅业务服务测试 | `mvn -pl skeleton-service clean test` |
| 打包（跳过测试） | `mvn clean package -DskipTests` |
| 启动业务服务（MySQL 联调） | `mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev` |
| 启动业务服务（个人 H2） | `mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local` |
| 启动网关 | 在 `java-microservice-gateway/`：`mvn spring-boot:run -Dspring-boot.run.profiles=dev` |
| 构建 Docker 镜像 | scaffold：`docker build -t skeleton-service:local skeleton-service/`；gateway：`cd ../java-microservice-gateway && docker build -t gateway-service:local .` |

---

## 9. 停止与清理（macOS）

```bash
# 停止 Java 进程：在各终端 Ctrl+C

# 停止并删除基础设施容器
docker compose -f platform/docker-compose/docker-compose.yml down

# 连数据卷一起删除（慎用，会清空 MySQL/Nacos 数据）
docker compose -f platform/docker-compose/docker-compose.yml down -v
```

---

## 10. 常见问题（macOS）

### Q1：`java -version` 不是 17

```bash
/usr/libexec/java_home -V              # 列出已安装 JDK
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

### Q2：Docker 拉镜像失败

- 确认 Docker Desktop 已启动
- 配置 Docker 镜像加速（Docker Desktop → Settings → Docker Engine）

### Q3：端口被占用（8080 / 8081 / 3306）

```bash
lsof -i :8080
lsof -i :8081
kill -9 <PID>
```

macOS 若已安装本机 MySQL，可能与 Compose 的 3306 冲突：停止本机 MySQL（`brew services stop mysql`）或修改 Compose 端口映射。

### Q4：Nacos 注册不上

1. 确认 `docker compose ps` 中 nacos 正常
2. 访问 http://localhost:8848/nacos
3. 检查 `NACOS_ADDR` 环境变量

### Q5：Kafka 连接失败但想先跑通 HTTP

在 `application.yml` 或启动参数中关闭 Kafka 示例：

```yaml
app:
  kafka:
    enabled: false
```

或：

```bash
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev \
  -Dspring-boot.run.arguments=--app.kafka.enabled=false
```

### Q6：`mvn test` 通过但 `spring-boot:run` 失败

- MySQL 联调：是否已 `start-local.sh`，且使用 **`dev` Profile**（勿在 `application-local.yml` 配 MySQL 密码）
- H2 调试：是否已复制 `application-local.yml` 并使用 `dev,local`
- 查看日志中 Flyway / 数据源 / Nacos 相关错误

---

## 11. 生产部署简述

本地验证通过后，生产环境建议：

1. 中间件（Nacos、Kafka、MySQL）由运维平台或 Helm 部署
2. 应用使用 `platform/k8s/base/` 清单部署（修改镜像地址、Secret）
3. 通过 K8s ConfigMap / Nacos 注入 `NACOS_ADDR`、`KAFKA_BOOTSTRAP` 等
4. 仅 `gateway-service` 对外暴露 LoadBalancer/Ingress

详见 `platform/k8s/base/` 与 [MICROSERVICES.md](MICROSERVICES.md) 第 5 节。

---

## 12. 检查清单（首次搭建）

| # | 步骤 | 验证 |
|---|------|------|
| ☐ | macOS 安装 JDK 17、Maven、Docker | `java -version`、`mvn -version`、`docker info` |
| ☐ | `mvn clean test`（可先执行） | H2 通过，**无需** MySQL / Docker |
| ☐ | `./platform/docker-compose/start-local.sh` | 联调时 Nacos/MySQL/Kafka/Redis 可访问 |
| ☐ | 启动 skeleton-service（`dev` Profile） | Nacos 可见服务；直连 `8081/api/v1/health` |
| ☐ | 启动 gateway-service | Nacos 可见服务 |
| ☐ | `curl localhost:8080/api/v1/health` | 返回 `"status":"UP"` |

完成以上步骤，即表示你已在 macOS 上从 0 到 1 跑通微服务脚手架。
