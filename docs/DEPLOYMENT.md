# 微服务部署指南

本文档说明如何部署 **共享基础设施**（Docker Compose）、**API 网关**与 **业务微服务**。  
**单元测试**使用 **H2 内存库**，无需安装 MySQL（见 [§3.4](#34-单元测试h2-内存库无需-mysql--docker-基础设施)）。

> **新同学请先读**：[GETTING-STARTED.md](GETTING-STARTED.md)（Day 1 路径）· [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)（文档地图）；本文侧重部署与运维  
> **本地联调基础设施**（Nacos / MySQL / Kafka / Redis）：见 [第 4 节](#4-本地基础设施安装与部署)（仅 `spring-boot:run` 时需要）

> 本地开发与环境搭建见：[microservice-zero-to-one.md](../java-microservice-scaffold/docs/microservice-zero-to-one.md)  
> 包路径配置见：[PACKAGE-IDENTITY.md](../shared/docs/PACKAGE-IDENTITY.md)  
> **CI/CD**：Jenkins，见本文 [第 13 节](#13-jenkins-cicd-流水线) 与根目录 [`Jenkinsfile`](../Jenkinsfile)

---

## 1. 部署架构

```text
                    ┌─────────────────────────────────────┐
                    │  客户端 / 前端 / 第三方系统           │
                    └──────────────────┬──────────────────┘
                                       │ HTTP :8080
                                       ▼
                    ┌─────────────────────────────────────┐
                    │  gateway-service（全局唯一）          │
                    │  java-microservice-gateway/          │
                    └──────────────────┬──────────────────┘
                                       │ lb://{service-id}
              ┌────────────────────────┼────────────────────────┐
              ▼                        ▼                        ▼
    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
    │ skeleton-service │    │  order-service   │    │  ... 其他业务服务  │
    │      :8081       │    │      :808x       │    │                  │
    └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘
             │                       │                       │
             └───────────────────────┼───────────────────────┘
                                     ▼
              ┌──────────────────────────────────────────────────┐
              │  共享基础设施                                      │
              │  Nacos · MySQL · Kafka · Redis                          │
              └──────────────────────────────────────────────────┘
```

### 1.1 工程与部署单元

| 工程 | 部署形态 | 实例数建议 | 对外暴露 |
|------|----------|------------|----------|
| `java-microservice-common` | Maven 依赖（jar），**不单独部署** | — | 否 |
| `java-microservice-gateway` | 可执行 JAR / Docker / K8s | 2+（无状态） | **是**（唯一入口） |
| `java-microservice-scaffold/*` | 各业务模块独立 JAR / Docker / K8s | 按服务扩缩 | 否（经网关访问） |

### 1.2 部署原则

1. **单测与联调分离**：`mvn test` 使用 **H2 内存库**，无需启动 MySQL 或 Docker 基础设施（见 [第 3.4 节](#34-单元测试h2-内存库无需-mysql--docker-基础设施)）。
2. **先基础设施，后应用（联调时）**：本地 `spring-boot:run` 前，再启动 Nacos、MySQL、Kafka、Redis 等（第 4 节）。
3. **先 common，后应用**：业务服务依赖 `common-bom`，须先 `mvn install` 或从私服拉取。
4. **先业务服务，后网关（首次联调）**：网关路由依赖 Nacos 中已注册的服务实例。
5. **仅网关对外**：业务服务 ClusterIP 内网访问，不直接暴露公网。

---

## 2. 前置条件

| 项 | 要求 |
|----|------|
| JDK | 17 |
| Maven | 3.6.3+（建议 3.9+） |
| Docker | 构建镜像 / 本地 Compose 基础设施 |
| Kubernetes | 1.24+（生产，可选） |
| 镜像仓库 | Harbor / ACR / ECR 等（生产） |

环境变量约定见 [第 8 节](#8-环境变量)。

---

## 3. 构建产物

### 3.1 安装公共组件（必做）

业务服务编译依赖 common，**每次 common 升级后需重新 install 或 deploy**：

```bash
cd java-microservice-common
mvn clean install -DskipTests
# 生产私服：mvn clean deploy -DskipTests
```

### 3.2 构建 API 网关

```bash
cd java-microservice-gateway
mvn clean package -DskipTests
# 产物：target/gateway-service-1.0.0-SNAPSHOT.jar
```

### 3.3 构建业务微服务

以 `skeleton-service` 为例：

```bash
cd java-microservice-scaffold
mvn clean package -DskipTests -pl skeleton-service -am
# 产物：skeleton-service/target/skeleton-service-1.0.0-SNAPSHOT.jar
```

新建业务服务（如 `order-service`）时，将 `-pl skeleton-service` 替换为对应模块名。

### 3.4 单元测试（H2 内存库，无需 MySQL / Docker 基础设施）

业务微服务单测与集成测试使用 **H2 内存数据库**，替代本地部署 MySQL，实现轻量级、可重复的 `mvn test`：

| 对比项 | `mvn test`（单测/集成测） | `spring-boot:run`（本地联调） |
|--------|---------------------------|-------------------------------|
| 数据库 | **H2** 内存库（`test` scope） | **MySQL**（Compose，`dev` Profile）；个人 H2 用 **`dev,local`** |
| Nacos / Kafka / Redis | 测试配置中默认关闭或 Mock | 需 Compose 或真实中间件 |
| Docker 基础设施 | **不需要** | **需要**（见第 4 节；MySQL 联调时） |
| 配置文件 | `skeleton-service/src/test/resources/application.yml` | MySQL 联调：`application-dev.yml`；个人 H2：`application-local.yml` |

H2 测试配置要点（[`skeleton-service/src/test/resources/application.yml`](../java-microservice-scaffold/skeleton-service/src/test/resources/application.yml)）：

```yaml
spring:
  datasource:
    url: jdbc:h2:mem:app_test;MODE=MySQL;DB_CLOSE_DELAY=-1;...
    driver-class-name: org.h2.Driver
  flyway:
    enabled: true   # 与主工程相同 db/migration 脚本
  cloud.nacos.discovery.enabled: false
  cloud.nacos.config.enabled: false
app.kafka.enabled: false
```

**推荐本地验证流程：**

```bash
# 1. 安装 common
cd java-microservice-common && mvn clean install && cd ..

# 2. 单测（H2，无需 start-local.sh / MySQL）
cd java-microservice-scaffold && mvn clean test
cd ../java-microservice-gateway && mvn clean test
```

> H2 使用 `MODE=MySQL` 尽量对齐方言；与生产 MySQL 8.0 存在差异时，以 Compose MySQL 联调为准。详见 [`docs/QUALITY-GATES.md`](../docs/QUALITY-GATES.md)。

---

## 4. 本地基础设施安装与部署

> **仅本地联调 / 启动应用时需要本节。** 运行 `mvn test` 使用 H2，**不必**安装 MySQL 或执行 `start-local.sh`（见 [§3.4](#34-单元测试h2-内存库无需-mysql--docker-基础设施)）。

本地联调使用 **Compose**（Nacos / MySQL / Kafka / Redis）。MySQL 容器供 **`spring-boot:run`（dev Profile）** 使用；单测由 H2 承担。

| 场景 | Compose 文件 | 一键脚本 |
|------|--------------|----------|
| **本地开发（推荐）** | [`docker-compose.local.yml`](../java-microservice-scaffold/platform/docker-compose/docker-compose.local.yml) | [`start-local.sh`](../java-microservice-scaffold/platform/docker-compose/start-local.sh) |
| 等价全路径引用 | [`docker-compose.yml`](../java-microservice-scaffold/platform/docker-compose/docker-compose.yml) | 手动 `docker compose -f … up -d` |

应用进程（gateway、skeleton-service）在**宿主机**以 JAR 或 `mvn spring-boot:run` 运行，通过 `127.0.0.1` 访问容器内中间件。

### 4.1 组件清单与版本（锁定）

| 组件 | Docker 镜像 | 版本 | 默认端口 | 作用 | 本地精简 | 生产/全量 |
|------|-------------|------|----------|------|:--------:|:---------:|
| **Nacos** | `nacos/nacos-server` | **v2.3.2** | 8848 / 9848 | 注册发现、配置中心 | ✓ | ✓ |
| **MySQL** | `mysql` | **8.0.40** | 3306 | 联调业务库、Flyway（**单测不用**） | ✓ | ✓ |
| **Kafka** | `apache/kafka` | **3.8.1** | 9092 | 消息队列（KRaft 单节点；原 bitnami 镜像已下架） | ✓ | ✓ |
| **Redis** | `redis` | **7.4.2** | 6379 | 缓存、分布式锁、Session | ✓ | ✓ |

> **Redis 7.4.2** 为 Redis 7.4 稳定线，与生产 K8s / 云 Redis 7.4 主版本对齐；应用侧引入 `spring-boot-starter-data-redis` 即可对接。  
> **可观测性**（Prometheus / Grafana / Zipkin）不在当前骨架范围内，UAT / 生产由运维平台另行接入。

与 Java 应用侧对齐的版本（供参考）：

| 组件 | 应用侧版本 | 说明 |
|------|------------|------|
| Spring Cloud Alibaba | **2023.0.1.2** | Nacos 客户端 |
| Spring Kafka | Boot 3.3 管理 | Kafka 客户端 |
| Spring Data Redis | Boot 3.3 管理 | Redis 客户端（按需引入） |
| H2 Database | Boot 3.3 管理 | **仅 `test` scope**，单测内存库 |
| Spring Boot Actuator | Boot 3.3 管理 | health / info / metrics |

### 4.2 本地一键部署（推荐）

**方式 A：脚本一键启动**

```bash
cd java-microservice-scaffold
./platform/docker-compose/start-local.sh
```

**方式 B：docker compose 命令**

```bash
cd java-microservice-scaffold
docker compose -f platform/docker-compose/docker-compose.local.yml up -d
docker compose -f platform/docker-compose/docker-compose.local.yml ps
```

**停止 / 清理**

```bash
./platform/docker-compose/stop-local.sh          # down（保留数据卷）
./platform/docker-compose/stop-local.sh stop    # 仅停止容器
./platform/docker-compose/stop-local.sh clean   # down -v（清空数据，慎用）
```

首次启动 **Nacos 约需 30～60 秒** 变为 healthy；MySQL 自动初始化库 `cursor-demo`。

### 4.3 架构关系（本地）

```text
┌──────────────────────────────────────────────────────────┐
│  docker-compose.local.yml                                │
│                                                          │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐        │
│  │  Nacos  │ │  MySQL  │ │  Kafka  │ │  Redis  │        │
│  │  :8848  │ │  :3306  │ │  :9092  │ │  :6379  │        │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘        │
└───────┼───────────┼───────────┼───────────┼──────────────┘
        │           │           │           │
        └───────────┴───────────┴───────────┘
                          │ 127.0.0.1
                          ▼
              ┌────────────────────────────┐
              │  宿主机 Java 进程            │
              │  gateway :8080             │
              │  skeleton-service :8081    │
              └────────────────────────────┘
```

### 4.5 主机前置条件

| 项 | 要求 |
|----|------|
| 操作系统 | macOS / Linux（Windows 建议 WSL2 + Docker Desktop） |
| Docker | Docker Desktop 或 Docker Engine **20.10+** |
| Docker Compose | **V2**（`docker compose`） |
| 内存 | 建议 **6 GB+** |
| 磁盘 | 数据卷约 **2 GB+** |
| 端口 | 8848、9848、3306、9092、**6379** 未被占用 |

```bash
docker --version && docker compose version && docker info
```

### 4.6 访问地址与默认账号（本地精简）

| 服务 | 地址 | 账号 / 说明 |
|------|------|-------------|
| Nacos 控制台 | http://localhost:8848/nacos | `nacos` / `nacos` |
| MySQL | `localhost:3306` | `root` / `root`，库名 `cursor-demo` |
| Kafka | `localhost:9092` | 无认证，PLAINTEXT |
| Redis | `localhost:6379` | 密码 `root`，AOF 持久化已开启 |

应用连接环境变量（本地默认值）：

```bash
export NACOS_ADDR=127.0.0.1:8848
export KAFKA_BOOTSTRAP=127.0.0.1:9092
export REDIS_HOST=127.0.0.1
export REDIS_PORT=6379
export REDIS_PASSWORD=root
```

### 4.7 各组件说明

#### Nacos（v2.3.2）

- **模式**：`standalone`；数据卷 `nacos-data`
- **应用连接**：`NACOS_ADDR=127.0.0.1:8848`，命名空间 `public`

#### MySQL（8.0.40）

- **用途**：本地 **MySQL 全栈联调**（`test` Profile）及 Flyway；**单元测试不使用 MySQL**
- **自动建库**：`cursor-demo`（utf8mb4）
- **单测替代**：H2 内存库 + 相同迁移脚本（见 §3.4）
- **Flyway**：skeleton-service 启动时自动迁移

#### Kafka（3.8.1，Apache 官方 KRaft）

- **镜像**：`apache/kafka:3.8.1`（`bitnami/kafka` 公共 catalog 已下架，见 §4.11）
- **广播地址**：`127.0.0.1:9092`；无 ZooKeeper
- **无 Kafka 时**：`app.kafka.enabled=false`

#### Redis（7.4.2）

- **模式**：单机，`appendonly yes`（AOF）
- **密码**：本地默认 `root`（与 MySQL 约定一致，**生产务必修改**）
- **数据卷**：`redis-data`
- **验证**：`redis-cli -h 127.0.0.1 -a root ping` → `PONG`
- **用途**：缓存、分布式锁、限流计数等；骨架工程按需引入 `spring-boot-starter-data-redis`

### 4.8 导入 Nacos 远程配置（推荐）

| Data ID | Group | 样例文件 |
|---------|-------|----------|
| `gateway-service.yaml` | DEFAULT_GROUP | [`java-microservice-gateway/platform/nacos/config/gateway-service.yaml`](../java-microservice-gateway/platform/nacos/config/gateway-service.yaml) |
| `skeleton-service.yaml` | DEFAULT_GROUP | [`java-microservice-scaffold/platform/nacos/config/skeleton-service.yaml`](../java-microservice-scaffold/platform/nacos/config/skeleton-service.yaml) |

### 4.9 停止、重启与清理

```bash
cd java-microservice-scaffold
COMPOSE="-f platform/docker-compose/docker-compose.local.yml"

docker compose $COMPOSE stop          # 停止
docker compose $COMPOSE down            # 删除容器
docker compose $COMPOSE down -v         # 删除容器 + 数据卷（慎用）
docker compose $COMPOSE restart redis   # 重启单个服务
```

### 4.10 基础设施验证清单（本地精简）

| 步骤 | 命令 / 操作 | 预期 |
|------|-------------|------|
| 启动 | `./platform/docker-compose/start-local.sh` | 4 个服务 running |
| Nacos | http://localhost:8848/nacos | 可登录 |
| MySQL | `mysql -h127.0.0.1 -uroot -proot -e "SHOW DATABASES;"` | 含 `cursor-demo` |
| Kafka | `docker exec ms-kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server 127.0.0.1:9092 --list` | 命令成功 |
| Redis | `redis-cli -h 127.0.0.1 -a root ping` | `PONG` |

### 4.11 基础设施常见问题

| 现象 | 原因与处理 |
|------|------------|
| Nacos 长时间 unhealthy | 内存不足；`docker logs ms-nacos`，增大 Docker 内存 |
| 3306 / 6379 端口冲突 | 本机已占用；停止本机服务或改 Compose 端口映射 |
| Kafka 连接失败 | 确认 9092 可达；或 `app.kafka.enabled=false` |
| Redis NOAUTH | 需带密码：`-a root` 或配置 `REDIS_PASSWORD` |
| 镜像拉取慢 / Kafka manifest unknown | Docker 镜像加速；Kafka 已改用 `apache/kafka:3.8.1`（勿再用 `bitnami/kafka`） |
| `down -v` 后 Flyway 报错 | 空库会重新执行迁移，属正常 |

---

## 5. 本地应用部署（JAR / Maven）

本节适用于 **启动可运行服务**（联调、验收）。若仅需跑通测试，执行 [§3.4](#34-单元测试h2-内存库无需-mysql--docker-基础设施) 的 `mvn test` 即可，**无需**本节与第 4 节基础设施。

### 5.0 两种本地工作流

| 目标 | 命令 | 需要 Compose？ |
|------|------|:--------------:|
| 单元测试 / CI | `mvn clean test` | 否（H2） |
| 本地联调 HTTP / Nacos / Kafka | `spring-boot:run` + `start-local.sh` | 是 |

### 5.1 启动业务微服务

**路径 A：MySQL 全栈联调（需 start-local.sh，推荐）**

```bash
cd java-microservice-scaffold
./platform/docker-compose/start-local.sh

mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
```

或使用 JAR：

```bash
java -jar skeleton-service/target/skeleton-service-1.0.0-SNAPSHOT.jar \
  --spring.profiles.active=dev
```

**路径 B：个人 H2 调试（无需 Compose MySQL）**

```bash
cd java-microservice-scaffold

cp skeleton-service/src/main/resources/application-local.yml.example \
   skeleton-service/src/main/resources/application-local.yml
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev,local
```

### 5.2 启动 API 网关

```bash
cd java-microservice-gateway
mvn spring-boot:run -Dspring-boot.run.profiles=dev
# 或
java -jar target/gateway-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev
```

### 5.3 本地完整联调顺序

**路径 A：仅验证代码（推荐日常开发）**

```text
1. mvn install common
2. mvn clean test          ← H2，无需 Docker / MySQL
```

**路径 B：完整微服务联调**

```text
1. ./platform/docker-compose/start-local.sh   ← 第 4 节（含 MySQL）
2. （可选）Nacos 导入 gateway/skeleton 配置
3. mvn install common
4. 启动 skeleton-service（8081）
5. 启动 gateway-service（8080）
6. curl 验证                                 ← 第 5.4 节
```

### 5.4 验证

```bash
# 经网关
curl -s http://localhost:8080/api/v1/health

# 直连业务（排障用）
curl -s http://localhost:8081/api/v1/health

# Nacos 服务列表应含 gateway-service、skeleton-service
open http://localhost:8848/nacos
```

---

## 6. Docker 镜像部署

适用于单机、VM 或任意支持 Docker 的环境。

### 6.1 构建镜像

```bash
# 网关
cd java-microservice-gateway
mvn clean package -DskipTests
docker build -t your-registry/gateway-service:1.0.0-SNAPSHOT .

# 业务服务
cd ../java-microservice-scaffold
mvn clean package -DskipTests -pl skeleton-service -am
docker build -t your-registry/skeleton-service:1.0.0-SNAPSHOT skeleton-service/
```

### 6.2 推送镜像

```bash
docker push your-registry/gateway-service:1.0.0-SNAPSHOT
docker push your-registry/skeleton-service:1.0.0-SNAPSHOT
```

### 6.3 运行容器

先确保 Nacos 等基础设施可达（[第 4 节](#4-本地基础设施安装与部署) Compose 或运维平台）。示例：

```bash
# 业务服务
docker run -d --name skeleton-service \
  -p 8081:8081 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e NACOS_ADDR=host.docker.internal:8848 \
  -e DB_HOST=host.docker.internal \
  -e DB_PORT=3306 \
  -e DB_NAME=cursor-demo \
  -e DB_USER=root \
  -e DB_PASSWORD=root \
  -e KAFKA_BOOTSTRAP=host.docker.internal:9092 \
  your-registry/skeleton-service:1.0.0-SNAPSHOT

# 网关
docker run -d --name gateway-service \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e NACOS_ADDR=host.docker.internal:8848 \
  your-registry/gateway-service:1.0.0-SNAPSHOT
```

> macOS / Docker Desktop 可用 `host.docker.internal` 访问宿主机上的 Compose 服务；Linux 需改用实际 IP 或 `--network host`。

---

## 7. Kubernetes 生产部署

清单位置：

| 资源 | 路径 |
|------|------|
| Namespace | `java-microservice-scaffold/platform/k8s/base/namespace.yaml` |
| ConfigMap（公共环境变量） | `java-microservice-scaffold/platform/k8s/base/configmap-env.yaml` |
| Secret 样例 | `java-microservice-scaffold/platform/k8s/base/secret-example.yaml` |
| 业务服务 Deployment | `java-microservice-scaffold/platform/k8s/base/skeleton-service.yaml` |
| 网关 Deployment | `java-microservice-gateway/platform/k8s/base/gateway-service.yaml` |

> Nacos、MySQL、Kafka 等**中间件**建议由运维 Helm / 云产品独立部署；上述清单仅覆盖**应用层**。

### 7.1 部署顺序

```text
1. 中间件就绪（Nacos / MySQL / Kafka）
2. Nacos 导入各服务配置（gateway-service.yaml、skeleton-service.yaml …）
3. kubectl apply Namespace / ConfigMap / Secret
4. 部署业务微服务（Deployment + Service）
5. 部署 API 网关（LoadBalancer / Ingress）
6. 验证健康检查与路由
```

### 7.2 修改镜像地址

编辑 YAML 中的 `image` 字段，例如：

```yaml
image: your-registry/skeleton-service:1.0.0-SNAPSHOT
image: your-registry/gateway-service:1.0.0-SNAPSHOT
```

### 7.3 执行部署

```bash
# 1. 命名空间与配置
kubectl apply -f java-microservice-scaffold/platform/k8s/base/namespace.yaml
kubectl apply -f java-microservice-scaffold/platform/k8s/base/configmap-env.yaml

# 2. Secret（生产请改用 SealedSecret / ExternalSecret / Vault）
kubectl apply -f java-microservice-scaffold/platform/k8s/base/secret-example.yaml

# 3. 业务服务
kubectl apply -f java-microservice-scaffold/platform/k8s/base/skeleton-service.yaml

# 4. 网关（唯一对外 Service，type: LoadBalancer）
kubectl apply -f java-microservice-gateway/platform/k8s/base/gateway-service.yaml
```

### 7.4 使用 Ingress（可选）

若集群无 LoadBalancer，将 `gateway-service` Service 改为 `ClusterIP`，并创建 Ingress：

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-ingress
  namespace: microservice
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: gateway-service
                port:
                  number: 80
```

### 7.5 健康检查

| 服务 | Readiness | Liveness |
|------|-----------|----------|
| gateway-service | `GET /actuator/health/readiness:8080` | 可选 |
| skeleton-service | `GET /actuator/health/readiness:8081` | `GET /actuator/health/liveness:8081` |

```bash
kubectl get pods -n microservice
kubectl logs -n microservice deploy/gateway-service --tail=100
kubectl logs -n microservice deploy/skeleton-service --tail=100
```

### 7.6 滚动升级

```bash
# 更新镜像版本后
kubectl set image deployment/skeleton-service \
  skeleton-service=your-registry/skeleton-service:1.0.1-SNAPSHOT \
  -n microservice

kubectl rollout status deployment/skeleton-service -n microservice
# 回滚
kubectl rollout undo deployment/skeleton-service -n microservice
```

网关升级同理，替换 `deployment/gateway-service` 即可。网关无状态，可多副本滚动。

---

## 8. 环境变量

业务服务与网关均通过环境变量覆盖连接信息（见 `application*.yml` 中的 `${VAR:default}`）。

| 变量 | 默认值（本地） | 说明 | 网关 | 业务服务 |
|------|----------------|------|:----:|:--------:|
| `SPRING_PROFILES_ACTIVE` | `dev` | 激活 Profile；生产用 `prod` | ✓ | ✓ |
| `NACOS_ADDR` | `127.0.0.1:8848` | Nacos 地址 | ✓ | ✓ |
| `NACOS_NAMESPACE` | `public` | Nacos 命名空间 | ✓ | ✓ |
| `KAFKA_BOOTSTRAP` | `127.0.0.1:9092` | Kafka | — | ✓ |
| `REDIS_HOST` | `127.0.0.1` | Redis 主机 | — | ✓ |
| `REDIS_PORT` | `6379` | Redis 端口 | — | ✓ |
| `REDIS_PASSWORD` | `root`（本地） | Redis 密码；**生产用 Secret** | — | ✓ |
| `DB_HOST` | `127.0.0.1` | MySQL 主机 | — | ✓ |
| `DB_PORT` | `3306` | MySQL 端口 | — | ✓ |
| `DB_NAME` | `cursor-demo` | 数据库名 | — | ✓ |
| `DB_USER` | `root` | 数据库用户 | — | ✓ |
| `DB_PASSWORD` | — | 数据库密码（**Secret 注入**） | — | ✓ |
| `SERVER_PORT` | 8080 / 8081 | 覆盖端口（可选） | ✓ | ✓ |

K8s 公共变量已在 `configmap-env.yaml` 中预置；`DB_PASSWORD`、`REDIS_PASSWORD` 通过 `secret-example.yaml` 注入。

---

## 9. 网关路由与新服务接入

新增业务微服务（如 `order-service`）后：

### 9.1 业务侧

1. 在 scaffold 中新增模块，`spring.application.name=order-service`
2. 注册 Nacos，端口不与现有服务冲突（如 8082）
3. 构建镜像并部署 K8s Deployment + ClusterIP Service

### 9.2 网关侧

在 `java-microservice-gateway/src/main/resources/application.yml` 或 Nacos `gateway-service.yaml` 增加路由：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: order-service-api
          uri: lb://order-service
          predicates:
            - Path=/api/v1/orders/**
        - id: order-service-doc
          uri: lb://order-service
          predicates:
            - Path=/order/v3/api-docs/**,/order/doc.html/**
```

> `lb://order-service` 中的名称须与 Nacos 注册的 `spring.application.name` 一致。

### 9.3 发布网关

- **Nacos 管理配置**：改 `gateway-service.yaml` 后，网关自动刷新（`refreshEnabled=true`）
- **本地 YAML 管理**：修改后重新构建镜像并滚动升级 gateway Deployment

---

## 10. Profile 与配置优先级

| Profile | 典型场景 | 业务服务端口 | 网关端口 |
|---------|----------|--------------|----------|
| **`dev`** | **本地 Compose MySQL 联调** | **8081** | **8080** |
| 个人 H2 | **`dev,local`** | 8081（local 可改） | 8080 |
| `test` / `uat` / `pre`（远端部署） | 各环境 | 按 yml / 环境变量 | 8080 |
| `prod` | 生产 | 建议 8081（与 Dockerfile/K8s 一致） | 8080 |

配置加载顺序（Spring Boot 3）：

```text
application.yml → application-{profile}.yml → Nacos 远程配置 → 环境变量
```

---

## 11. 部署验证清单

### 11.0 单元测试（H2，无需基础设施）

| 步骤 | 命令 / 检查 | 预期 |
|------|-------------|------|
| common 已安装 | `cd java-microservice-common && mvn install` | BUILD SUCCESS |
| 脚手架单测 | `cd java-microservice-scaffold && mvn clean test` | BUILD SUCCESS（H2 + Flyway） |
| 网关单测 | `cd java-microservice-gateway && mvn clean test` | BUILD SUCCESS |
| 无需 MySQL | 未执行 `start-local.sh` 亦可过测 | — |

### 11.1 本地基础设施（联调前，第 4 节）

| 步骤 | 命令 / 检查 | 预期 |
|------|-------------|------|
| 一键启动 | `./platform/docker-compose/start-local.sh` | 4 个服务 running / healthy |
| Nacos | http://localhost:8848/nacos | 可登录 `nacos/nacos` |
| MySQL | `mysql -h127.0.0.1 -uroot -proot -e "SHOW DATABASES;"` | 含 `cursor-demo` |
| Redis | `redis-cli -h 127.0.0.1 -a root ping` | `PONG` |
| Kafka | 端口 9092 可连 | 可选 |

### 11.2 应用与联调

| 步骤 | 命令 / 检查 | 预期 |
|------|-------------|------|
| common 已安装 | `ls ~/.m2/repository/com/s3/common-bom/` | 存在对应版本 |
| 业务服务注册 | Nacos → 服务列表 | 可见 `skeleton-service` |
| 网关注册 | Nacos → 服务列表 | 可见 `gateway-service` |
| 网关路由 | `curl http://localhost:8080/api/v1/health` | HTTP 200 + JSON |
| 数据库迁移 | 业务服务日志 | Flyway migrate 成功 |

---

## 12. 常见问题

### Q1：业务服务启动报找不到 common 依赖？

先在 `java-microservice-common` 执行 `mvn clean install`，或配置私服并在 `pom.xml` 中引用已发布的 `microservice-common.version`。

### Q2：网关 503 / Unable to find instance for skeleton-service？

1. 确认 `skeleton-service` 已启动并成功注册 Nacos  
2. 确认 `spring.application.name` 与路由 `lb://` 名称一致  
3. 确认网关与业务服务使用同一 `NACOS_NAMESPACE`

### Q3：K8s Pod Ready 但接口 502？

检查 `readinessProbe` 路径与端口；业务服务 Flyway / 数据库连不通会导致 readiness 失败。

### Q4：生产是否每个业务仓库都要部署 gateway？

**否**。`java-microservice-gateway` 全局部署一份（或多副本），所有业务服务共用同一网关集群。

### Q5：如何禁用 Kafka？

业务服务设置 `app.kafka.enabled=false`（可在 Nacos 对应服务配置中覆盖）。

### Q6：基础设施相关问题？

见 [第 4.11 节](#411-基础设施常见问题)（端口冲突、Nacos 启动慢、Redis 认证等）。

---

## 13. Jenkins CI/CD 流水线

本仓库使用 **Jenkins Pipeline** 完成构建、测试、镜像推送与 K8s 滚动发布。流水线定义见根目录 [`Jenkinsfile`](../Jenkinsfile)。

**团队标准质量门禁**见 **[`docs/QUALITY-GATES.md`](../docs/QUALITY-GATES.md)**；根目录 [`Jenkinsfile`](../Jenkinsfile) **已实现**阶段 1～5，任意门禁失败阻断镜像推送与合并。

### 13.1 流水线总览

```text
Checkout
    │
    ▼
Build Common（mvn install / deploy）
    │
    ▼
Quality Gates（并行：Gateway ∥ Skeleton）
    │
    ├── Skeleton：[2] 单测+JaCoCo → [1] Sonar → [3] 集成 → [4] 契约
    │              → [5] release/* Testcontainers MySQL（条件）
    │
    └── Gateway ：[2] 单测 → [1] Sonar
    │
    ▼
Package（-DskipTests）→ Docker Build & Push → Deploy K8s（可选）
```

| 阶段 | 说明 |
|------|------|
| Build Common | **必在前**；`install` 到工作区 `.m2`（跳过测试），或 `common-only` 模式 `deploy` 私服 |
| Quality Gates | 见 CI-TOOLCHAIN §5；失败则后续 Package / Docker **不执行** |
| Package | `mvn package -DskipTests`（测试已在门禁完成） |
| Docker Build & Push | 按 `BUILD_TARGET` 选择性构建镜像 |
| Deploy K8s | `kubectl set image` + `rollout status` 滚动升级 |

### 13.2 Jenkins 环境准备

#### 必需插件

| 插件 | 用途 |
|------|------|
| Pipeline | Declarative Pipeline |
| Docker Pipeline | `docker.withRegistry` 推送镜像 |
| JUnit | 收集 `surefire-reports` |
| Credentials Binding | kubeconfig / settings.xml |
| Timestamper | 日志时间戳 |

#### 全局工具（Manage Jenkins → Tools）

| 工具 | 名称（与 Jenkinsfile 一致） | 版本 |
|------|----------------------------|------|
| JDK | `JDK17` | 17 |
| Maven | 可选；流水线使用系统 `mvn` 或绑定 Maven 工具 | 3.9+ |
| Docker | Agent 需能执行 `docker build`（Docker CLI 或 Kaniko 改造） | — |

#### 凭据（Manage Jenkins → Credentials）

| ID | 类型 | 说明 |
|----|------|------|
| `docker-registry` | Username with password | 镜像仓库登录 |
| `kubeconfig` | Secret file | 目标 K8s 集群 kubeconfig |
| `maven-settings` | Secret file | 含私服账号的 `settings.xml`（`common-only` / 独立 common Job 使用） |
| `sonar-token` | Secret text | SonarQube User Token（阶段 1 扫描） |

#### Agent 要求

- JDK 17、`mvn` 在 PATH 中（或通过 `tool` 注入）
- 可访问 Maven 中央仓库或内网镜像（仓库已含 `.mvn/settings.xml` 阿里云镜像）
- 构建镜像阶段需 Docker daemon（`docker` 命令）或改用 Kaniko/BuildKit 侧车

### 13.3 创建 Jenkins Job

1. **新建 Item** → 名称如 `java-microservice-monorepo` → 类型 **Pipeline**
2. **Pipeline** → Definition 选 **Pipeline script from SCM**
3. SCM 选 Git，填写仓库 URL 与凭据
4. Script Path 填 **`Jenkinsfile`**
5. 保存后 **Build with Parameters** 首次运行

### 13.4 构建参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `BUILD_TARGET` | `all` | `all` / `common-only` / `gateway` / `skeleton-service` |
| `DEPLOY_ENV` | `none` | 环境标识（日志与后续扩展）；`none` 仅 CI 不部署 |
| `IMAGE_TAG` | 空 → `{BUILD_NUMBER}-SNAPSHOT` | 镜像标签，生产建议传 Git Tag 如 `1.0.0` |
| `SKIP_TESTS` | false | 跳过全部测试与质量门禁 |
| `SKIP_QUALITY_GATES` | false | 仅跳过门禁阶段 1～5 |
| `SKIP_SONAR` | false | 跳过 SonarQube 扫描 |
| `PUSH_IMAGE` | true | 是否构建并推送 Docker 镜像 |
| `DEPLOY_K8S` | false | 推送后是否滚动更新 K8s |

**常用组合：**

| 场景 | BUILD_TARGET | PUSH_IMAGE | DEPLOY_K8S |
|------|--------------|------------|------------|
| PR 验证 | `all` | false | false |
| 仅发 common 私服 | `common-only` | false | false |
| 发布网关 | `gateway` | true | true |
| 发布业务服务 | `skeleton-service` | true | true |
| 全量发布 | `all` | true | true |

### 13.5 修改镜像仓库地址

编辑 [`Jenkinsfile`](../Jenkinsfile) 中环境变量：

```groovy
DOCKER_REGISTRY = 'your-registry.example.com'   // 如 harbor.example.com/team
K8S_NAMESPACE = 'microservice'
```

镜像命名约定：

```text
{DOCKER_REGISTRY}/gateway-service:{IMAGE_TAG}
{DOCKER_REGISTRY}/skeleton-service:{IMAGE_TAG}
```

与 K8s Deployment 中 `your-registry/...` 保持一致，或在首次部署前 `kubectl apply` 清单后再由 Jenkins 滚动更新镜像。

### 13.6 多 Job 拆分（推荐生产）

Monorepo 可用单 Job；团队扩大后可拆为独立 Pipeline：

| Job | Jenkinsfile | 触发方式 |
|-----|-------------|----------|
| `common-release` | [`jenkins/Jenkinsfile.common`](../jenkins/Jenkinsfile.common) | common 目录变更 / 手动 / Tag |
| `gateway-deploy` | 根 `Jenkinsfile`，`BUILD_TARGET=gateway` | 网关目录变更 |
| `skeleton-deploy` | 根 `Jenkinsfile`，`BUILD_TARGET=skeleton-service` | 业务模块变更 |

common 采用 **`mvn deploy`** 发布至 Nexus 后，gateway / 业务 Job **无需再 install common**，只要 `settings.xml` 能解析私服与 `microservice-common.version` 一致。

在 Nexus 发布 common 时，需在 `java-microservice-common/pom.xml` 增加：

```xml
<distributionManagement>
    <repository>
        <id>team-releases</id>
        <url>https://nexus.example.com/repository/maven-releases/</url>
    </repository>
    <snapshotRepository>
        <id>team-snapshots</id>
        <url>https://nexus.example.com/repository/maven-snapshots/</url>
    </snapshotRepository>
</distributionManagement>
```

`settings.xml` 中 `<server><id>` 与上述 id 对应。

### 13.7 按分支/环境自动部署

在 Jenkinsfile 的 `post` 或 `when` 中扩展，例如：

```groovy
stage('Deploy to Kubernetes') {
    when {
        branch 'main'   // 或 env.GIT_BRANCH == 'origin/main'
    }
    // ...
}
```

| 分支 | 建议行为 |
|------|----------|
| `feature/*` | 仅 `mvn test`（H2，无 Docker） | 不推镜像 |
| `develop` | 推镜像 `:develop-{BUILD_NUMBER}`，部署 test 命名空间 |
| `main` / Tag | 推镜像 `:1.x.x`，部署 prod（需人工审批插件） |

可配合 **Generic Webhook Trigger** 或 **Bitbucket/GitHub hook** 实现提交自动构建。

### 13.8 部署顺序（首次上线）

Jenkins 日常滚动升级可并行；**首次**环境建议：

```text
1. 本地：`./platform/docker-compose/start-local.sh`（见 [第 4 节](#4-本地基础设施安装与部署)）；生产中间件由运维平台部署
2. Nacos 导入 gateway-service.yaml、skeleton-service.yaml
3. kubectl apply Namespace / ConfigMap / Secret / Deployment（见 [第 7 节](#7-kubernetes-生产部署)）
4. Jenkins：BUILD_TARGET=all，PUSH_IMAGE=true，DEPLOY_K8S=true
5. 验证网关与业务健康检查
```

### 13.9 流水线故障排查

| 现象 | 处理 |
|------|------|
| 找不到 `common-bom` | 确认 Build Common 阶段成功；或私服已 deploy 且 version 匹配 |
| Docker push 401 | 检查 `docker-registry` 凭据与 `DOCKER_REGISTRY` 地址 |
| kubectl 连接失败 | 检查 `kubeconfig` 凭据与 Agent 网络 |
| 滚动升级卡住 | `kubectl describe pod` 查看 readiness；多为 DB/Nacos 未就绪 |
| surefire 失败 | 下载 `target/surefire-reports` 附件，本地复现 `mvn test` |

---

## 14. 相关文件索引

| 文件 | 说明 |
|------|------|
| [skeleton-service/src/test/resources/application.yml](../java-microservice-scaffold/skeleton-service/src/test/resources/application.yml) | **单测 H2 配置（无需 MySQL）** |
| [docs/QUALITY-GATES.md](../docs/QUALITY-GATES.md) | **质量门禁与 CI 流水线** |
| [docs/TEAM-PLAYBOOK.md](../docs/TEAM-PLAYBOOK.md) | 日常 Pre-PR Checklist |
| [docs/QUALITY-GATES.md](../docs/QUALITY-GATES.md) §5 | SonarLint / SonarQube 扫描 |
| [docker-compose.local.yml](../java-microservice-scaffold/platform/docker-compose/docker-compose.local.yml) | 本地联调基础设施（含 MySQL；单测不需要） |
| [start-local.sh](../java-microservice-scaffold/platform/docker-compose/start-local.sh) | **一键启动本地联调基础设施** |
| [stop-local.sh](../java-microservice-scaffold/platform/docker-compose/stop-local.sh) | 停止 / 清理本地基础设施 |
| [docker-compose.yml](../java-microservice-scaffold/platform/docker-compose/docker-compose.yml) | 本地基础设施（等价 local 文件） |
| [java-microservice-gateway/Dockerfile](../java-microservice-gateway/Dockerfile) | 网关镜像 |
| [skeleton-service/Dockerfile](../java-microservice-scaffold/skeleton-service/Dockerfile) | 业务服务镜像 |
| [platform/docker-compose/docker-compose.yml](../java-microservice-scaffold/platform/docker-compose/docker-compose.yml) | 本地基础设施 |
| [gateway-service.yaml (Nacos)](../java-microservice-gateway/platform/nacos/config/gateway-service.yaml) | 网关远程配置样例 |
| [skeleton-service.yaml (Nacos)](../java-microservice-scaffold/platform/nacos/config/skeleton-service.yaml) | 业务远程配置样例 |
| [gateway-service.yaml (K8s)](../java-microservice-gateway/platform/k8s/base/gateway-service.yaml) | 网关 K8s 清单 |
| [skeleton-service.yaml (K8s)](../java-microservice-scaffold/platform/k8s/base/skeleton-service.yaml) | 业务 K8s 清单 |
| [Jenkinsfile](../Jenkinsfile) | Monorepo 主流水线 |
| [jenkins/Jenkinsfile.common](../jenkins/Jenkinsfile.common) | 仅发布 common 的独立 Job |
