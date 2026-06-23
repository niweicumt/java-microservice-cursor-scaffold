# 实施计划：用户管理后端服务

**分支**：`001-user-management` | **日期**：2026-05-26 | **规格**：[spec.md](./spec.md)

**输入**：来自 `specs/001-user-management/spec.md` 的功能规格说明

**说明**：本计划由 `/speckit.plan` 生成；任务拆分见后续 `/speckit.tasks` 输出的 `tasks.md`。

## 摘要

新建 Spring Boot 2.7.18（JDK 1.8）单模块 REST 服务，基于 **Spring MVC + MyBatis + MyBatis Plus** 实现用户主数据的增删改查、分页与条件查询。横切能力包括统一返回（code/msg/data）、全局异常处理、Bean Validation 参数校验、**springdoc-openapi + knife4j** 接口文档、五套 Profile（dev/test/uat/pre/prod）及 Logback 文件日志。数据存储使用 **MySQL 8.0**，用户删除采用逻辑删除。

## 技术上下文

**语言/版本**：Java 8（JDK 1.8）

**主要依赖**：
- Spring Boot 2.7.18（Web、Validation、JDBC）
- MyBatis Spring Boot Starter 2.3.x
- MyBatis Plus 3.5.5（Boot 2.7 兼容线）
- MySQL Connector/J 8.0.x
- springdoc-openapi 1.7.x + knife4j-openapi3-spring-boot-starter 4.3.x
- Flyway（库表版本管理）
- Lombok（可选，减少样板代码）
- spring-security-crypto（仅 BCrypt 密码编码，不引入完整 Security 过滤链）

**存储**：MySQL 8.0，库名默认 `user_mgmt`，表 `sys_user`

**测试**：JUnit 5、Spring Boot Test、`@WebMvcTest` / `@SpringBootTest`、Testcontainers MySQL（集成测试可选）或 H2（单测 mock Mapper）

**目标平台**：Linux/Windows 服务器或本地 JVM 部署

**项目类型**：web-service（REST API）

**性能目标**：1 万用户分页列表 P95 ≤ 2s（规格 SC-002）；索引覆盖 username、status、deleted、create_time

**约束**：符合项目宪法；阿里巴巴 Java 开发手册；v1 无认证鉴权

**规模/范围**：单模块、单聚合（用户）；约 6 个 REST 端点 + 基础设施配置

## 宪法检查

*门禁：阶段 0 调研前已通过；阶段 1 设计后复核通过。*

对照 `.specify/memory/constitution.md`（v1.0.0）：

- [x] Maven POM 锁定 JDK 1.8 与 Spring Boot 2.7.18
- [x] Maven UTF-8 编码
- [x] Controller / Service / Repository / Entity 包结构已规划（Repository 层为 MyBatis Mapper）
- [x] MySQL 8.0 数据模型与 Mapper 访问层已定义（见 data-model.md）
- [x] 全局异常处理 + 统一返回（`common` 包）
- [x] Logback 按 Profile 输出文件
- [x] knife4j + OpenAPI（满足宪法与规格 Swagger 要求）
- [x] 任务阶段将体现阿里巴巴手册（命名、分层、异常、日志）

## 项目结构

### 文档（本功能）

```text
specs/001-user-management/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── users-api.openapi.yaml
└── tasks.md          # /speckit.tasks 生成
```

### 源代码（仓库根目录）

```text
pom.xml

src/main/java/com/s3/user/
├── UserManagementApplication.java
├── controller/
│   └── UserController.java
├── service/
│   ├── UserService.java
│   └── impl/UserServiceImpl.java
├── repository/
│   └── UserMapper.java          # MyBatis Plus BaseMapper
├── entity/
│   └── User.java
├── dto/
│   ├── request/                 # CreateUserRequest, UpdateUserRequest, UserQueryRequest
│   └── response/                # UserVO（对外无 password）
├── common/
│   ├── result/Result.java
│   ├── result/ResultCode.java
│   ├── exception/BusinessException.java
│   └── exception/GlobalExceptionHandler.java
└── config/
    ├── MybatisPlusConfig.java
    ├── OpenApiConfig.java
    └── MetaObjectHandlerConfig.java   # 自动填充 createTime/updateTime

src/main/resources/
├── application.yml
├── application-dev.yml
├── application-test.yml
├── application-uat.yml
├── application-pre.yml
├── application-prod.yml
├── logback-spring.xml
└── db/migration/
    └── V1__init_sys_user.sql

src/test/java/com/s3/user/
├── controller/UserControllerTest.java
└── service/UserServiceTest.java
```

**结构决策**：单 Maven 模块；持久化使用 MyBatis Plus，Mapper 接口置于 `repository` 包以符合宪法分层命名；DTO 与 Entity 分离，避免密码字段泄漏至 API 响应。

## 复杂度追踪

| 违规项 | 为何需要 | 拒绝更简单方案的原因 |
|--------|----------|----------------------|
| Repository 包存放 MyBatis `Mapper` 而非 JPA `JpaRepository` | 规格明确要求 MyBatis + MyBatis Plus | JPA 与规格及团队选型冲突；Mapper 仍承担唯一数据访问职责 |
| 文档使用 knife4j + springdoc，而非裸 Swagger 2 | 宪法要求 knife4j；规格要求 Swagger 文档 | knife4j 基于 OpenAPI 3，UI 增强且满足宪法；裸 springfox 在 SB 2.7 已过时 |
