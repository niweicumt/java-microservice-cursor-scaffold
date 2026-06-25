# java-microservice-common

微服务 **公共组件独立工程**：常量、枚举、通用异常、工具类、统一返回、Cloud Starter（Nacos/Feign/Kafka/监控/链路）。

业务微服务通过 **Maven 版本依赖** 引用本工程产物，**禁止** copy 源码。

> 新同学入门：[`../docs/GETTING-STARTED.md`](../docs/GETTING-STARTED.md) · 文档地图：[`../docs/PROJECT-OVERVIEW.md`](../docs/PROJECT-OVERVIEW.md)  
> 包路径配置（com.s3 → com.tm）：[`../shared/docs/PACKAGE-IDENTITY.md`](../shared/docs/PACKAGE-IDENTITY.md)

## 模块

| 模块 | 说明 |
|------|------|
| `common-core` | 常量 `constant`、枚举 `enums`、异常 `exception`、工具 `util`、统一返回 `result` |
| `common-cloud-starter` | Nacos、OpenFeign、Kafka、Actuator 自动配置 |
| `common-bom` | 版本 BOM，供业务工程 `import` |

## 包结构

```text
com.s3.common.core
├── constant/     ApiConstants 等
├── enums/        通用枚举（ResultCode 在 result 包，属 API 码表）
├── exception/    BusinessException、GlobalExceptionHandler
├── result/       Result、ResultCode
├── util/         StringUtils 等
└── autoconfigure/

com.s3.common.cloud
├── autoconfigure/
└── kafka/
```

## 构建与发布

```bash
# 安装到本地 ~/.m2
mvn clean install

# 发布私服（可选）
mvn clean deploy -DskipTests
```

## 业务工程引用

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

<dependencies>
    <dependency>
        <groupId>com.s3</groupId>
        <artifactId>common-cloud-starter</artifactId>
    </dependency>
</dependencies>
```

## 配置标识

见 [`common.defaults.json`](common.defaults.json)。修改组织前缀请使用仓库根目录：

```bash
./shared/scripts/configure-organization.sh --org com.yourteam
```

## 技术栈

JDK 17 · Spring Boot 3.3.13 · Spring Cloud 2023.0.5 · Spring Cloud Alibaba 2023.0.1.2

## 更多文档

- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) — 开发约定与扩展指南
