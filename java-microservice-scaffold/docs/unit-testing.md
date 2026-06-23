# 单元测试规范

本文档约定本项目的单元测试目录结构、运行方式、覆盖率统计与质量门槛。  
骨架使用说明见 [`SKELETON.md`](SKELETON.md)。

## 1. 测试分层

| 层级 | 类命名 | 注解 | 说明 |
|------|--------|------|------|
| 纯单元测试 | `*Test` | `@ExtendWith(MockitoExtension.class)` | 不启动 Spring |
| Controller 单元测试 | `*Test` | MockMvc standalone + Mockito | 不启容器 |
| **Controller 集成测试** | `*IntegrationTest` | 继承 `AbstractControllerIntegrationTest` | H2 + MockMvc + **OpenAPI 响应契约** |
| **OpenAPI 契约测试** | `contract/*Test` | `@SpringBootTest` | 基线 YAML vs `/v3/api-docs` 兼容性 |

## 2. 目录与命名

```text
src/test/java/com/s3/skeleton/
├── support/
│   ├── AbstractControllerIntegrationTest.java   # 集成测试基类
│   └── OpenApiContractSupport.java              # 契约比对工具
├── contract/
│   └── OpenApiContractTest.java                 # CI 阶段 4
├── controller/
│   └── HealthControllerIntegrationTest.java
└── auto/controller/
    └── UserControllerIntegrationTest.java

src/test/resources/contracts/
└── skeleton-api.openapi.yaml                    # 提交 Git 的 API 契约基线
```

新增业务后：

- 单元：`XxxServiceTest`、`XxxControllerTest`
- 集成：`XxxControllerIntegrationTest`（继承基类，`.andExpect(openApiContract())`）
- 更新 `skeleton-api.openapi.yaml` 后跑契约测试

## 3. 运行命令

```bash
# 全部测试
mvn clean test

# CI 阶段 3：Controller 集成测试
mvn test -Pci-integration-tests

# CI 阶段 4：OpenAPI 契约兼容性
mvn test -Pcontract-tests
```

## 4. 覆盖率统计范围

`pom.xml` 中 JaCoCo **排除**：`SkeletonApplication`、`config/**`、`dto/**`、`entity/**`、`repository/**`。

**纳入统计**：`controller/**`、`service/**`、`common/**`。

## 5. 质量门槛（建议）

| 指标 | 建议值 |
|------|--------|
| 核心业务行覆盖率 | ≥ 80% |
| 新增功能 | 必须带测试，`mvn test` 通过 |

## 6. 测试数据与环境

- **禁止** 单测依赖本机 MySQL；使用 `src/test/resources/application.yml`（H2）
- 集成测试继承 `AbstractControllerIntegrationTest`，默认 `@Transactional` 回滚

## 6.1 OpenAPI 契约

| 文件 | 作用 |
|------|------|
| `contracts/skeleton-api.openapi.yaml` | 基线契约（path / schema / 响应） |
| `OpenApiContractTest` | 运行时 `/v3/api-docs` 不得删除基线 operation |
| `swagger-request-validator-mockmvc` | 集成测试 `.andExpect(openApiContract())` 校验响应 body |

**变更 API 时**：先更新 YAML，再改 Controller/DTO；破坏性变更须 bump `info.version` 并在 PR 说明。

## 7. 相关文档

- [`CURSOR-RULES.md`](../../shared/docs/CURSOR-RULES.md) — Cursor 规则摘要与测试生成约定
- [`CI-TOOLCHAIN.md`](../../shared/docs/CI-TOOLCHAIN.md) — JaCoCo 留存与 CI 覆盖率门禁
- [`engineering-standards.md`](engineering-standards.md) 第 3 节
- [`test-coverage-report.md`](test-coverage-report.md)
