# 微服务脚手架使用指南

> **推荐阅读**：[microservice-zero-to-one.md](microservice-zero-to-one.md) — macOS 从零搭建完整步骤、配置说明与版本清单。

基于 **JDK 17 + Spring Boot 3.3.13 + Spring Cloud 2023.0.5** 的多模块微服务脚手架，可从 0 到 1 搭建完整微服务体系。

## 1. 模块结构

```text
<repo-root>/
├── java-microservice-common/          # 独立工程：common-core / common-cloud-starter / common-bom
├── java-microservice-gateway/         # 独立工程：API 网关（全局一份）
└── java-microservice-scaffold/        # 脚手架：skeleton-service / platform
```

## 2. 锁定版本（成熟稳定线）

| 组件 | 版本 | 说明 |
|------|------|------|
| JDK | **17** | LTS |
| Spring Boot | **3.3.13** | 父 POM |
| Spring Cloud | **2023.0.5** | Leyton，对齐 Boot 3.3 |
| Spring Cloud Alibaba | **2023.0.1.2** | Nacos 注册/配置 |
| MyBatis Plus | **3.5.9** | Spring Boot 3 Starter |
| springdoc-openapi | **2.6.0** | OpenAPI 3 |
| knife4j | **4.5.0** | 文档 UI / Gateway 聚合 |
| Nacos Server | **2.3.2** | Compose 镜像 |
| MySQL | **8.0.40** | 业务数据库 |
| Redis | **7.4.2** | 缓存（Compose 镜像） |
| Kafka | **3.8.1** | Apache 官方 KRaft 单节点（`apache/kafka`） |

> **说明**：可观测性（Prometheus / Grafana / Zipkin）不在当前骨架范围内，UAT / 生产由运维平台另行接入。

## 3. 本地 0→1 启动

### 3.0 安装 common（首次必做）

```bash
cd java-microservice-common && mvn clean install && cd ..
```

### 3.1 启动基础设施

```bash
cd java-microservice-scaffold
./platform/docker-compose/start-local.sh
```

| 服务 | 地址 | 默认账号 |
|------|------|----------|
| Nacos | http://localhost:8848/nacos | nacos / nacos |
| MySQL | localhost:3306 | root / root |
| Kafka | localhost:9092 | — |
| Redis | localhost:6379 | 密码 `root` |

### 3.2（可选）导入 Nacos 配置

在 Nacos 控制台创建配置（或使用 `platform/nacos/config/` 样例）：

| Data ID | Group |
|---------|-------|
| `skeleton-service.yaml` | DEFAULT_GROUP |
| `gateway-service.yaml` | DEFAULT_GROUP（样例在 `java-microservice-gateway/platform/nacos/config/`） |

### 3.3 启动业务服务

先确保 **3.1** 已执行（MySQL 可连），再启动 Java 进程：

```bash
cd java-microservice-scaffold

# 终端 1：业务服务（dev = Compose MySQL 联调，端口 8081）
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev

# 个人 H2 调试（无需 Docker MySQL，需 application-local.yml）：
# mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local

# 终端 2：网关（8080，在 java-microservice-gateway/）
cd ../java-microservice-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

> `dev` 默认连接 Compose MySQL（`application-dev.yml`：`root/root`，库 `cursor-demo`）。  
> 仅 **`dev,local`** 使用个人 H2 文件库（见 `application-local.yml.example`）。

### 3.4 验证

```bash
# 经网关访问
curl -s http://localhost:8080/api/v1/health

# 直连业务服务
curl -s http://localhost:8081/api/v1/health

# Nacos 服务列表
open http://localhost:8848/nacos
```

| 入口 | URL |
|------|-----|
| 网关 API 文档 | http://localhost:8080/doc.html |
| 业务服务文档 | http://localhost:8081/doc.html |

### 3.5 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NACOS_ADDR` | 127.0.0.1:8848 | Nacos 地址 |
| `KAFKA_BOOTSTRAP` | 127.0.0.1:9092 | Kafka |
| `DB_*` | 见 `application-dev.yml` | MySQL 联调（dev） |

本地无 Kafka 时可设置 `app.kafka.enabled=false`。

## 4. 创建新业务服务

1. Fork 本仓库
2. 复制 `skeleton-service` 模块并重命名（或执行 `scripts/rename-skeleton.sh`，需适配多模块路径）
3. 在父 `pom.xml` `<modules>` 中注册新模块
4. 在 [`java-microservice-gateway`](../../java-microservice-gateway/) 增加路由规则
5. 在 Nacos 添加对应 `{service-name}.yaml`

## 5. 生产部署（Kubernetes）

```bash
# 修改镜像地址后部署
kubectl apply -f platform/k8s/base/namespace.yaml
kubectl apply -f platform/k8s/base/configmap-env.yaml
kubectl apply -f platform/k8s/base/secret-example.yaml   # 生产请改用 SealedSecret/ExternalSecret
kubectl apply -f platform/k8s/base/skeleton-service.yaml
kubectl apply -f ../java-microservice-gateway/platform/k8s/base/gateway-service.yaml
```

生产环境 Nacos、Kafka、MySQL 建议由运维平台或 Helm 独立部署；`platform/k8s/base/` 仅包含**应用层**清单。

## 6. 构建镜像

```bash
# scaffold
mvn clean package -DskipTests
docker build -t skeleton-service:local skeleton-service/

# gateway（独立工程）
cd ../java-microservice-gateway
mvn clean package -DskipTests
docker build -t gateway-service:local .
```

## 7. 公共 Starter 能力（common-cloud-starter）

引入后自动启用：

- Nacos 服务注册与配置（`spring.config.import`）
- OpenFeign + LoadBalancer
- Kafka Producer/Consumer（可 `app.kafka.enabled=false` 关闭）
- Actuator（health / info / metrics）

## 8. 相关文档

- [SKELETON.md](SKELETON.md) — 骨架通用规范
- [engineering-standards.md](engineering-standards.md) — 工程细则
- [unit-testing.md](unit-testing.md) — 单测规范
