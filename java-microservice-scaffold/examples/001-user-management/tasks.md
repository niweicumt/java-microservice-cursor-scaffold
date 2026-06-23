# 任务列表：用户管理后端服务

**输入**：`specs/001-user-management/` 下的 plan.md、spec.md、data-model.md、contracts/

**前置条件**：plan.md、spec.md、research.md、data-model.md、contracts/users-api.openapi.yaml

**测试**：规格未要求 TDD；本任务列表不含独立测试任务（plan.md 中的测试类可在收尾阶段按需补充）。

**组织方式**：按用户故事分组，支持独立实施与验收。

## 格式说明

`- [ ] [TaskID] [P?] [Story?] 描述（含文件路径）`

---

## 阶段 1：搭建（共享基础设施）

**目的**：初始化 Maven 工程与多环境骨架

- [x] T001 创建 `pom.xml`：parent Spring Boot 2.7.18、JDK 1.8、UTF-8、依赖 Web/Validation/MyBatis Plus/MySQL/Flyway/springdoc/knife4j/Lombok/spring-security-crypto
- [x] T002 创建启动类 `src/main/java/com/s3/user/UserManagementApplication.java`
- [x] T003 [P] 创建 `src/main/resources/application.yml`（公共配置、默认 profile、MyBatis Plus/Flyway 占位）
- [x] T004 [P] 创建 `src/main/resources/application-dev.yml`（数据源、端口、日志路径）
- [x] T005 [P] 创建 `src/main/resources/application-test.yml`
- [x] T006 [P] 创建 `src/main/resources/application-uat.yml`
- [x] T007 [P] 创建 `src/main/resources/application-pre.yml`
- [x] T008 [P] 创建 `src/main/resources/application-prod.yml`
- [x] T009 [P] 创建 `src/main/resources/logback-spring.xml`（按 profile 输出到文件）
- [x] T010 创建 `.gitignore`（target/、logs/、IDE、本地配置覆盖文件）

**检查点**：`mvn -q validate` 通过（尚无业务代码）

---

## 阶段 2：基础设施（阻塞性前置）

**目的**：横切能力、数据表与持久化层；完成前不得开始用户故事

**⚠️ 关键**：本阶段完成前禁止 US1/US2/US3 开发

- [x] T011 创建 `src/main/resources/db/migration/V1__init_sys_user.sql`（见 data-model.md 字段与索引）
- [x] T012 [P] 创建 `src/main/java/com/s3/user/common/result/ResultCode.java`
- [x] T013 [P] 创建 `src/main/java/com/s3/user/common/result/Result.java`（code/msg/data）
- [x] T014 [P] 创建 `src/main/java/com/s3/user/common/exception/BusinessException.java`
- [x] T015 创建 `src/main/java/com/s3/user/common/exception/GlobalExceptionHandler.java`（校验异常、业务异常、兜底异常 → Result）
- [x] T016 [P] 创建 `src/main/java/com/s3/user/config/MybatisPlusConfig.java`（分页插件 PaginationInnerInterceptor）
- [x] T017 [P] 创建 `src/main/java/com/s3/user/config/MetaObjectHandlerConfig.java`（createTime/updateTime 自动填充）
- [x] T018 [P] 创建 `src/main/java/com/s3/user/config/OpenApiConfig.java`（springdoc + knife4j 基本信息）
- [x] T019 [P] 创建 `src/main/java/com/s3/user/config/PasswordEncoderConfig.java`（BCryptPasswordEncoder Bean）
- [x] T020 创建 `src/main/java/com/s3/user/entity/User.java`（@TableName sys_user、@TableLogic deleted、字段映射）
- [x] T021 创建 `src/main/java/com/s3/user/repository/UserMapper.java`（extends BaseMapper&lt;User&gt;）

**检查点**：应用可在 dev profile 启动；Flyway 建表成功；访问 `/doc.html` 可打开（尚无业务接口）

---

## 阶段 3：用户故事 1 - 创建并查看用户（优先级：P1）🎯 MVP

**目标**：支持创建用户与按 ID 查询详情；密码 BCrypt 存储且不返回明文

**独立测试**：`POST /api/v1/users` 创建 → `GET /api/v1/users/{id}` 查询；重复用户名/邮箱返回 409

### 用户故事 1 的实施

- [x] T022 [P] [US1] 创建 `src/main/java/com/s3/user/dto/request/CreateUserRequest.java`（Bean Validation）
- [x] T023 [P] [US1] 创建 `src/main/java/com/s3/user/dto/response/UserVO.java` 与 `src/main/java/com/s3/user/dto/converter/UserConverter.java`（Entity↔VO，屏蔽 password_hash）
- [x] T024 [US1] 创建 `src/main/java/com/s3/user/service/UserService.java`（createUser、getUserById 方法签名）
- [x] T025 [US1] 创建 `src/main/java/com/s3/user/service/impl/UserServiceImpl.java`（唯一性校验、BCrypt 编码、调用 UserMapper）
- [x] T026 [US1] 创建 `src/main/java/com/s3/user/controller/UserController.java` 实现 `POST /api/v1/users` 与 `GET /api/v1/users/{id}`（返回 Result&lt;UserVO&gt;，OpenAPI 注解）
- [x] T027 [US1] 在 `UserServiceImpl` 中实现用户名/邮箱冲突时抛出 BusinessException（409）

**检查点**：按 quickstart.md 完成创建与查询冒烟；冲突与 404 返回统一 Result 格式

---

## 阶段 4：用户故事 2 - 分页浏览与条件查询（优先级：P2）

**目标**：分页列表，支持 username 模糊、status/email/phone 条件筛选

**独立测试**：插入多条用户后 `GET /api/v1/users?page=1&size=10&username=xx&status=1` 返回 records+total

### 用户故事 2 的实施

- [x] T028 [P] [US2] 创建 `src/main/java/com/s3/user/dto/request/UserPageQuery.java`（page≥1、size 1～100、可选筛选字段）
- [x] T029 [P] [US2] 创建 `src/main/java/com/s3/user/dto/response/UserPageVO.java`（records、total、page、size）
- [x] T030 [US2] 在 `UserService.java` / `UserServiceImpl.java` 新增 `pageUsers(UserPageQuery)`（MyBatis Plus Page + LambdaQueryWrapper，默认 create_time DESC）
- [x] T031 [US2] 在 `UserController.java` 实现 `GET /api/v1/users`（契约见 contracts/users-api.openapi.yaml）

**检查点**：空结果返回 total=0；非法 page/size 返回 400；逻辑删除用户不出现在列表

---

## 阶段 5：用户故事 3 - 更新与删除用户（优先级：P3）

**目标**：部分字段更新、逻辑删除；更新冲突与不存在时正确错误码

**独立测试**：`PUT /api/v1/users/{id}` 更新字段；`DELETE` 后 GET/列表不可见

### 用户故事 3 的实施

- [x] T032 [P] [US3] 创建 `src/main/java/com/s3/user/dto/request/UpdateUserRequest.java`（可选字段 + 校验）
- [x] T033 [US3] 在 `UserService` / `UserServiceImpl` 新增 `updateUser(id, request)`（可选改密、唯一性、update_time）
- [x] T034 [US3] 在 `UserService` / `UserServiceImpl` 新增 `deleteUser(id)`（逻辑删除 @TableLogic）
- [x] T035 [US3] 在 `UserController.java` 实现 `PUT /api/v1/users/{id}` 与 `DELETE /api/v1/users/{id}`

**检查点**：删除后 GET 返回 404；逻辑删除后可使用相同 username 新建（规格边界）

---

## 阶段 6：收尾与横切优化

**目的**：文档、可运行性与规格 SC 对齐

- [x] T036 [P] 创建根目录 `README.md`（技术栈、环境变量、启动命令、文档地址）
- [x] T037 核对 `UserController` 全部端点与 `specs/001-user-management/contracts/users-api.openapi.yaml` 一致（SC-004）
- [x] T038 在各 profile 下验证启动与日志文件生成（dev/test/uat/pre/prod，SC-005）
- [x] T039 按 `specs/001-user-management/quickstart.md` 执行端到端冒烟并记录结果

---

## 依赖与执行顺序

### 阶段依赖

```text
阶段 1（搭建）→ 阶段 2（基础设施）→ 阶段 3（US1）→ 阶段 4（US2）→ 阶段 5（US3）→ 阶段 6（收尾）
```

- **阶段 2** 阻塞所有用户故事
- **US2** 依赖 US1 的 User 实体/Service/Controller 基础（可复用，不重复建表）
- **US3** 依赖 US1 的 Service/Controller；与 US2 无强依赖（可在 US2 后或并行由不同人做 PUT/DELETE）

### 用户故事依赖

| 故事 | 依赖 | 独立测试方式 |
|------|------|----------------|
| US1 | 阶段 2 | POST + GET by id |
| US2 | 阶段 2 + US1 持久化层 | GET 列表 + 筛选 |
| US3 | 阶段 2 + US1 Service | PUT + DELETE |

### 单故事内部顺序

Entity/Mapper（阶段 2）→ DTO → Service → Controller

### 并行机会

- 阶段 1：T003～T009 可并行
- 阶段 2：T012～T014、T016～T019 可并行（T015 依赖 T012～T014）
- US1：T022、T023 可并行
- US2：T028、T029 可并行
- US3：T032 可与 T033 设计并行，T035 依赖 T033、T034

---

## 并行示例：阶段 2

```bash
# 可同时进行（不同文件）：
T012 ResultCode.java
T013 Result.java
T014 BusinessException.java
T016 MybatisPlusConfig.java
T017 MetaObjectHandlerConfig.java
T018 OpenApiConfig.java
T019 PasswordEncoderConfig.java

# 完成后：
T015 GlobalExceptionHandler.java
T020 User.java → T021 UserMapper.java
```

---

## 实施策略

### MVP 优先（仅用户故事 1）

1. 完成阶段 1～2
2. 完成阶段 3（US1）
3. **停止并验证**：quickstart 创建 + 查询
4. 可演示 MVP

### 增量交付

1. 搭建 + 基础设施
2. +US1 → 演示
3. +US2 → 演示列表检索
4. +US3 → 完整 CRUD
5. 阶段 6 收尾

---

## 任务统计

| 阶段 | 任务数 | 说明 |
|------|--------|------|
| 阶段 1 搭建 | 10 | T001～T010 |
| 阶段 2 基础设施 | 11 | T011～T021 |
| 阶段 3 US1 | 6 | T022～T027 |
| 阶段 4 US2 | 4 | T028～T031 |
| 阶段 5 US3 | 4 | T032～T035 |
| 阶段 6 收尾 | 4 | T036～T039 |
| **合计** | **39** | |

**建议 MVP 范围**：阶段 1～3（T001～T027，共 27 项）
