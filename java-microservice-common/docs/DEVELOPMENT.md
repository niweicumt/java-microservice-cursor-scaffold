# common 工程开发指南

## 新增公共代码放哪里

| 类型 | 包路径 | 示例 |
|------|--------|------|
| 常量 | `com.s3.common.core.constant` | `ApiConstants` |
| 枚举 | `com.s3.common.core.enums` | 业务无关的通用枚举 |
| API 错误码 | `com.s3.common.core.result` | `ResultCode`（与 Result 配套） |
| 异常 | `com.s3.common.core.exception` | `BusinessException` |
| 工具类 | `com.s3.common.core.util` | `StringUtils` |
| 微服务 Starter | `com.s3.common.cloud` | Nacos/Kafka 等自动配置 |

## 不应放在 common 的内容

- 具体业务 Entity / Controller
- 单服务专属 Flyway 脚本
- 与某一业务域强耦合的逻辑

## 发版流程

1. 修改 common 代码并 `mvn clean test`
2. 升级 `pom.xml` 中 `<version>`（或团队 CI 自动 bump）
3. `mvn clean install` 或 `deploy`
4. 业务脚手架更新 `microservice-common.version`

## 单测

```bash
mvn -pl common-core clean test
```
