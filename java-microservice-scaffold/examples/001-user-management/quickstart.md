# 快速开始：用户管理后端服务（示例文档）

> 本目录为 **examples** 参考样例，不参与骨架工程编译。骨架本地联调见 [`../../docs/SKELETON.md`](../../docs/SKELETON.md) 与 [`../../docs/microservice-zero-to-one.md`](../../docs/microservice-zero-to-one.md)。

**功能**：001-user-management

## 前置条件

- JDK 17
- Maven 3.9+
- MySQL 8.0（Compose 或本机；骨架默认 `./platform/docker-compose/start-local.sh`）

## 1. 准备数据库（MySQL 联调）

骨架约定：**MySQL 全栈联调使用 `dev` Profile**（`application-dev.yml`），**不在** `application-local.yml` 中配置 MySQL。

Compose 默认账号与库（与 `application-dev.yml` 一致）：

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES;"
# 默认库：cursor-demo
```

若本服务使用独立库名（示例 `user_mgmt`），可先创建库并在启动时覆盖 `DB_NAME`：

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -proot -e \
  "CREATE DATABASE IF NOT EXISTS user_mgmt \
   DEFAULT CHARACTER SET utf8mb4 \
   DEFAULT COLLATE utf8mb4_unicode_ci;"
export DB_NAME=user_mgmt
```

## 2. 本地个人配置（仅 H2 调试）

`application-local.yml` 用于 **个人 H2 文件库**（`dev,local`），与 MySQL 联调无关：

```bash
cp src/main/resources/application-local.yml.example \
   src/main/resources/application-local.yml
# 按需调整 H2 路径、端口、日志级别
```

MySQL 联调请跳过本节，直接使用第 3 节 `dev` Profile。

## 3. 构建与启动

在**仓库根目录**执行（Maven 常用命令见 [`docs/engineering-standards.md`](../../docs/engineering-standards.md) 第 1.4 节）：

```bash
# 编译
mvn clean compile

# 打包（跳过测试）
mvn clean package -DskipTests

# MySQL 联调（推荐：先 start-local.sh，再 dev Profile）
./platform/docker-compose/start-local.sh
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 个人 H2 调试（无需 Docker MySQL）
# mvn spring-boot:run -Dspring-boot.run.profiles=dev,local
```

默认端口：业务服务 **8081**（`application-dev.yml`）；经网关访问为 **8080**。

## 4. 访问接口文档

- 经网关 Knife4j：`http://localhost:8080/doc.html`
- 直连业务服务：`http://localhost:8081/doc.html`
- OpenAPI JSON：`http://localhost:8081/v3/api-docs`

## 5. 冒烟测试示例

**创建用户**（经网关）

```bash
curl -s -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "zhangsan",
    "password": "Passw0rd!",
    "email": "zhangsan@example.com",
    "phone": "13800138000",
    "status": 1
  }'
```

**分页查询**

```bash
curl -s "http://localhost:8080/api/v1/users?page=1&size=10&username=zhang"
```

**按 ID 查询**

```bash
curl -s http://localhost:8080/api/v1/users/1
```

## 6. 切换环境

```bash
# 远端测试环境 MySQL
mvn spring-boot:run -Dspring-boot.run.profiles=test

# 生产
java -jar target/user-management-*.jar --spring.profiles.active=prod
```

各环境日志文件路径见 `application-{profile}.yml` 与 `logback-spring.xml`。

## 7. 运行测试

```bash
# 使用 H2 内存库，无需 MySQL（见 src/test/resources/application.yml）
mvn clean test

# 覆盖率报告
open target/site/jacoco/index.html
```

单测规范：[`docs/QUALITY-GATES.md`](../../../docs/QUALITY-GATES.md)。

## 相关文档

- [spec.md](./spec.md) — 功能规格
- [plan.md](./plan.md) — 实施计划
- [contracts/users-api.openapi.yaml](./contracts/users-api.openapi.yaml) — API 契约
- [docs/engineering-standards.md](../../docs/engineering-standards.md) — Maven 日常命令、Profile、application-local
- [README.md](../../README.md) — 项目总览与快速命令表
