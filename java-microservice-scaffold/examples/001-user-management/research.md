# 调研结论：用户管理后端服务

**功能**：001-user-management | **日期**：2026-05-26

## 1. 持久化方案：MyBatis + MyBatis Plus

**决策**：使用 `mybatis-plus-boot-starter` 3.5.5 + `mybatis-spring-boot-starter` 2.3.x。

**理由**：
- 与规格一致，支持分页插件、逻辑删除、自动填充时间字段。
- 与 Spring Boot 2.7.18 / JDK 8 兼容成熟。

**备选**：
- Spring Data JPA：宪法允许但规格明确排除。
- 纯 MyBatis XML：样板代码多，分页与逻辑删除需自研。

## 2. 接口文档：springdoc + knife4j

**决策**：`springdoc-openapi-ui` 1.7.x + `knife4j-openapi3-spring-boot-starter` 4.3.x。

**理由**：
- 生成 OpenAPI 3 文档（满足规格「Swagger」诉求）。
- knife4j 满足宪法增强 UI；替代已停止维护的 springfox。

**备选**：
- 仅 springdoc：无 knife4j UI 增强，不符合宪法表述。
- springfox 3：与 SB 2.7 集成问题多，不推荐。

## 3. 密码存储

**决策**：`BCryptPasswordEncoder`（`spring-security-crypto`），仅存 `password_hash`。

**理由**：行业标准单向摘要；不引入完整 Spring Security 过滤器（v1 无认证）。

**备选**：MD5/SHA1：不安全，拒绝。

## 4. 逻辑删除

**决策**：MyBatis Plus `@TableLogic`，字段 `deleted`（0 未删除 / 1 已删除）。

**理由**：与规格 FR-006 一致；查询默认自动过滤已删除记录。

**备选**：物理 DELETE：不符合规格默认策略。

## 5. 分页与条件查询

**决策**：`Page<User>` + `LambdaQueryWrapper`；条件：username LIKE、status EQ、email/phone 可选 EQ。

**理由**：MP 内置分页；避免手写 LIMIT；默认 sort `create_time DESC`。

**参数**：page 从 1 开始，size 默认 10、最大 100（规格假设）。

## 6. 多环境配置

**决策**：`spring.profiles.active` + `application-{profile}.yml` 五文件（dev/test/uat/pre/prod）。

**理由**：满足 FR-012；公共项放 `application.yml`，环境差异（数据源、日志路径）下沉。

**备选**：单文件多 document：可维护性差。

## 7. 数据库迁移

**决策**：Flyway，`classpath:db/migration/V1__init_sys_user.sql`。

**理由**：宪法推荐版本化 schema；首版单表即可。

## 8. 统一返回与异常

**决策**：
- `Result<T>{ Integer code; String msg; T data; }`
- 成功 code=200；业务错误 4xx 段；系统错误 500
- `@RestControllerAdvice` 捕获 `MethodArgumentNotValidException`、`BusinessException`、`Exception`

**理由**：满足 FR-008～FR-010；HTTP 状态码与业务 code 分离（HTTP 200 + 业务 code 表示失败亦可，调研采用常见「HTTP 200 + 业务码」或 RESTful HTTP 码 — **采用 RESTful HTTP 状态 + body 内 code 一致**）。

**最终约定**：
- 成功：HTTP 200，`code=200`
- 参数错误：HTTP 400，`code=400`
- 未找到：HTTP 404，`code=404`
- 冲突：HTTP 409，`code=409`

## 9. 包名与模块

**决策**：根包 `com.s3.user`，artifactId `user-management`。

**理由**：简短可读；与示例宪法路径一致可替换为组织域。

## 未决项

无。技术上下文全部可在实施阶段落地。
