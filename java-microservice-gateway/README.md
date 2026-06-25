# java-microservice-gateway

微服务 **API 网关独立工程**：Spring Cloud Gateway + Nacos 服务发现/配置 + Knife4j 文档聚合。

网关是**全局唯一入口**，各业务脚手架（`java-microservice-scaffold`）只需提供业务服务，**不需要**内嵌 gateway 模块。

> 新同学入门：[`../docs/GETTING-STARTED.md`](../docs/GETTING-STARTED.md) · 文档地图：[`../docs/PROJECT-OVERVIEW.md`](../docs/PROJECT-OVERVIEW.md)  
> 包路径配置（com.s3 → com.tm）：[`../shared/docs/PACKAGE-IDENTITY.md`](../shared/docs/PACKAGE-IDENTITY.md)

## 职责

| 能力 | 说明 |
|------|------|
| 路由转发 | 按服务名 `lb://{service-id}` 转发到 Nacos 注册的业务服务 |
| 文档聚合 | Knife4j Gateway 自动发现下游 OpenAPI |
| 健康检查 | Actuator（health / metrics） |

默认端口：**8080**

## 构建与运行

```bash
# 编译测试
mvn clean test

# 本地启动（需 Nacos 等基础设施，见 scaffold/platform）
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# Docker 镜像
mvn clean package -DskipTests
docker build -t gateway-service:local .
```

## 路由配置

- 本地默认路由：`src/main/resources/application.yml`
- Nacos 远程配置样例：`platform/nacos/config/gateway-service.yaml`
- K8s 部署样例：`platform/k8s/base/gateway-service.yaml`

新增业务服务后，在网关配置中增加对应路由（或通过 Nacos 动态刷新）。

## 与脚手架的关系

```text
java-microservice-gateway/     ← 全局网关（本工程，独立部署）
java-microservice-scaffold/    ← 业务服务模板（skeleton-service 等）
java-microservice-common/      ← 公共库（Result、异常、Cloud Starter）
```

业务服务注册到 Nacos 后，网关通过服务发现自动路由；无需把 gateway 代码复制到每个业务仓库。

部署说明：[`docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md)

## 修改组织前缀

在仓库根目录：

```bash
./shared/scripts/configure-organization.sh --org com.tm
cd java-microservice-gateway && mvn clean test
```
