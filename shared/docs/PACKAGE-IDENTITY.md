# 包路径与组织前缀配置（公共文档）

本文档适用于仓库内 **三个独立 Maven 工程** 的包名与 Maven 坐标配置：

| 工程 | 默认根包 | 说明 |
|------|----------|------|
| `java-microservice-common` | `com.s3.common.*` | 常量、枚举、异常、工具、Starter |
| `java-microservice-gateway` | `com.s3.gateway.*` | API 网关（全局唯一，独立部署） |
| `java-microservice-scaffold` | `com.s3.skeleton.*` | 业务服务模板 |

默认组织前缀为 **`com.s3`**，可一键改为 `com.tm`、`com.ljy` 等。

---

## 团队守则

- **禁止** 手动修改 Java 包名、源码目录（如 `com/s3/...`）或各工程 `pom.xml` 中的组织前缀。
- **必须** 通过脚本统一替换：
  - 跨 common / gateway / scaffold：`./shared/scripts/configure-organization.sh --org <新前缀>`
  - 仅 scaffold 模块标识：`shared/scripts/configure-skeleton.sh` / `rename-skeleton.sh`
- 手动改动易导致目录结构与 import、pom、Feign 扫描包、JaCoCo 路径不一致，且难以在 PR 中完整 review。

---

## 1. 配置文件（单一事实来源）

| 文件 | 作用域 |
|------|--------|
| [`shared/package.defaults.json`](../package.defaults.json) | **组织前缀**（跨两个工程） |
| [`java-microservice-common/common.defaults.json`](../../java-microservice-common/common.defaults.json) | common 工程 groupId、basePackage |
| [`java-microservice-scaffold/skeleton.defaults.json`](../../java-microservice-scaffold/skeleton.defaults.json) | 脚手架业务服务标识 |
| [`java-microservice-gateway/gateway.defaults.json`](../../java-microservice-gateway/gateway.defaults.json) | 网关工程标识 |

### shared/package.defaults.json

```json
{
  "organizationPrefix": "com.s3"
}
```

### common.defaults.json

```json
{
  "organizationPrefix": "com.s3",
  "basePackage": "com.s3.common",
  "groupId": "com.s3",
  "artifactId": "java-microservice-common"
}
```

### skeleton.defaults.json

```json
{
  "organizationPrefix": "com.s3",
  "basePackage": "com.s3.skeleton",
  "groupId": "com.s3",
  "artifactId": "java-microservice-scaffold",
  "appName": "skeleton-service",
  "moduleName": "skeleton"
}
```

---

## 2. 修改组织前缀（com.s3 → com.tm）

在**仓库根目录**执行：

```bash
./shared/scripts/configure-organization.sh --org com.tm
```

脚本将自动：

1. 移动 Java 目录：`com/s3/...` → `com/tm/...`（common + gateway + scaffold 全部模块）
2. 替换源码、pom、配置、文档中的 `com.s3` 为 `com.tm`
3. 更新上述三个 `*.defaults.json`

完成后重新安装 common：

```bash
cd java-microservice-common && mvn clean install
cd ../java-microservice-scaffold && mvn clean test
```

### 包路径映射示例

| 变更前 | 变更后（--org com.tm） |
|--------|------------------------|
| `com.s3.common.core.result.Result` | `com.tm.common.core.result.Result` |
| `com.s3.common.cloud.autoconfigure.*` | `com.tm.common.cloud.autoconfigure.*` |
| `com.s3.skeleton.controller.*` | `com.tm.skeleton.controller.*` |
| `com.s3.gateway.GatewayApplication` | `com.tm.gateway.GatewayApplication` |
| Maven `groupId` `com.s3` | `com.tm` |

---

## 3. 仅调整脚手架业务服务（不改组织前缀）

在 fork 后创建具体业务服务时使用：

```bash
# 改组织前缀下的 skeleton 模块名（com.acme.skeleton 保持不变，仅换团队前缀时用上一节）
./shared/scripts/configure-skeleton.sh \
  --base-package com.acme.skeleton \
  --group-id com.acme

# 从 skeleton 模板创建 order-service
./shared/scripts/rename-skeleton.sh \
  --package com.acme.order \
  --artifact order-service \
  --db-name order_dev
```

> 上述脚本作用域为 `java-microservice-scaffold/`，不会修改 common 工程。

---

## 4. common 工程包结构约定

```text
com.{org}.common.core
├── constant/     # 常量类
├── enums/        # 枚举（API 码表见 result.ResultCode）
├── exception/    # 通用异常与 GlobalExceptionHandler
├── result/       # 统一返回 Result
├── util/         # 工具类
└── autoconfigure/

com.{org}.common.cloud
├── autoconfigure/
└── kafka/
```

**原则**：跨服务复用的常量、枚举、异常、工具 **只放在 common 工程**，业务服务通过 Maven 依赖引用，**禁止 copy 源码**。

---

## 5. 脚手架工程包结构约定

```text
com.{org}.skeleton         # skeleton-service（复制后改为 com.{org}.order 等）
  ├── controller/
  ├── service/
  ├── repository/
  ├── entity/
  └── dto/
```

## 6. 网关工程包结构约定

```text
com.{org}.gateway          # java-microservice-gateway（独立工程，全局部署一份）
```

> 网关不在业务脚手架内；新增业务服务后，在 [`java-microservice-gateway`](../../java-microservice-gateway/) 中配置路由即可。

---

## 7. 相关脚本

| 脚本 | 用途 |
|------|------|
| `shared/scripts/configure-organization.sh` | 修改组织前缀（三个工程） |
| `shared/scripts/configure-skeleton.sh` | 修改脚手架团队前缀（仅 scaffold） |
| `shared/scripts/rename-skeleton.sh` | 从 skeleton 创建新业务服务 |

---

## 8. 常见问题

**Q：改完组织前缀后编译失败？**  
先 `cd java-microservice-common && mvn clean install`，再编译 scaffold。

**Q：两个工程可以拆成两个 Git 仓库吗？**  
可以。common、gateway、scaffold 均可独立仓库维护；保留各自的 `*.defaults.json`，`configure-organization.sh` 中的 `_COMMON_ROOT` / `_GATEWAY_ROOT` / `_SCAFFOLD_ROOT` 需按实际路径调整。

**Q：Feign 扫描包名会变吗？**  
`common-cloud-starter` 中 `@EnableFeignClients(basePackages = "com.s3")` 会随组织前缀脚本一并替换为新前缀。
