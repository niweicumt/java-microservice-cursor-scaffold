# Java 服务骨架使用指南

本仓库是团队统一的 **Spring Boot 3.3.13 + Spring Cloud 微服务脚手架**（多模块），开箱包含 Gateway、Nacos 集成、Kafka、监控链路与业务服务模板 `skeleton-service`。

## 1. 骨架包含什么

| 模块 | 路径 | 说明 |
|------|------|------|
| 启动类 | `com.s3.skeleton.SkeletonApplication` | `@SpringBootApplication` + `@MapperScan` |
| 示例接口 | `HealthController` | `GET /api/v1/health` |
| 横切能力 | `common/result`、`common/exception` | `Result`、全局异常处理 |
| 配置 | `config/` | OpenAPI、MyBatis Plus、MetaObject 填充、PasswordEncoder |
| 分层占位 | `service/`、`repository/`、`entity/`、`dto/` | `package-info.java` 说明职责 |
| 数据库 | `db/migration/V1__skeleton_baseline.sql` | 可替换的 Flyway 占位迁移 |
| 示例文档 | `examples/001-user-management/` | 用户管理 Speckit 样例（**不参与编译**） |
| 标识配置 | `skeleton.defaults.json` | 根包、groupId、artifact 等**可配置**单一事实来源 |

> 默认根包为 `com.s3.skeleton`，**不必**以 `com.s3` 开头。见 §2。

## 2. 骨架标识配置（可自定义根包）

骨架的组织前缀、根包、Maven 坐标等集中在仓库根目录的 **`skeleton.defaults.json`**，脚本从此读取当前标识，替换后写回该文件。

### 2.1 配置文件说明

```json
{
  "basePackage": "com.s3.skeleton",
  "groupId": "com.s3",
  "artifactId": "java-service-skeleton",
  "appName": "java-service-skeleton",
  "moduleName": "skeleton",
  "databases": { "dev": "cursor-demo", "test": "app_test", ... }
}
```

| 字段 | 含义 | 示例 |
|------|------|------|
| `basePackage` | Java 根包（源码目录与 `package` 声明） | `com.acme.skeleton` |
| `groupId` | Maven `groupId`（通常为根包去掉末段） | `com.acme` |
| `artifactId` | Maven `artifactId` | `java-service-skeleton` |
| `appName` | `spring.application.name` | 同 `artifactId` |
| `moduleName` | 模块名，决定主类前缀（如 `SkeletonApplication`） | `skeleton` |
| `databases` | 各环境默认库名 | `dev` / `test` / … |

查看当前值：

```bash
cat skeleton.defaults.json
```

### 2.2 两种使用场景

**场景 A：团队 fork 骨架后，统一改组织前缀（推荐先做）**

将默认 `com.s3` 换成团队前缀，模块名仍为 `skeleton`：

```bash
./scripts/configure-skeleton.sh \
  --base-package com.acme.skeleton \
  --group-id com.acme
```

**场景 B：从骨架创建具体业务服务**

在场景 A 之后（或直接从默认 `com.s3.skeleton`）执行：

```bash
./scripts/rename-skeleton.sh \
  --package com.acme.order \
  --group-id com.acme \
  --artifact order-service \
  --db-name order_dev
```

| 脚本 | 用途 | 何时使用 |
|------|------|----------|
| `configure-skeleton.sh` | 只改组织前缀，保留 skeleton 模块名 | fork 后、团队统一模板 |
| `rename-skeleton.sh` | 改为具体业务服务的包名与 artifact | 创建新微服务时 |

`--group-id` 可省略，默认取 `--package` / `--base-package` **去掉末段**（如 `com.acme.order` → `com.acme`）。

脚本会自动替换：Java 包路径、`pom.xml` 的 `groupId`/`artifactId`、日志包名、JaCoCo 路径、`spring.application.name`、默认库名，并更新 `skeleton.defaults.json`；同时安装 **`.cursor/rules/`** 到 `skeleton-service/`（见 `shared/scripts/lib/copy-cursor-rules.sh`）。

---

## 3. 环境准备检查清单

在 **§4 从骨架创建新服务** 之前，请逐项确认本机环境。全部通过后再执行复制与重命名。

### 3.1 必备软件

| # | 检查项 | 要求 | 验证命令 |
|---|--------|------|----------|
| ☐ | JDK | **17**（与 `pom.xml` 一致；Spring Boot 3 最低要求 Java 17） | `java -version` |
| ☐ | Maven | **3.6.3+**（Spring Boot 3 父 POM 要求；建议 3.9+） | `mvn -version` |
| ☐ | Git | 可克隆与初始化仓库 | `git --version` |
| ☐ | MySQL | **8.0**（本地启动服务时需要；单测不需要） | `mysql --version` |

### 3.2 环境变量与路径

| # | 检查项 | 说明 | 验证 |
|---|--------|------|------|
| ☐ | `JAVA_HOME` | 指向 JDK 17 安装目录（非 JRE） | `echo $JAVA_HOME` |
| ☐ | `java` / `mvn` 一致 | `mvn -version` 显示的 Java 版本应为 17.x | `mvn -version` |
| ☐ | Maven 本地仓库 | 默认可写；团队自定义路径见 `.mvn/settings.xml.example` | `mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout` |

**macOS 切换 JDK 17 示例**：

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

建议将上述配置写入 `~/.zshrc` 或 `~/.bash_profile`，避免新终端回退到旧版本。

### 3.3 网络与依赖

| # | 检查项 | 说明 |
|---|--------|------|
| ☐ | Maven 镜像 | 项目已提供 `.mvn/settings.xml`（阿里云 + Central） |
| ☐ | 首次构建 | 需能下载依赖；公司网络受限时配置私服或代理 |

### 3.4 骨架工程自检（复制前可选）

在骨架仓库根目录预检，确认模板本身可构建：

```bash
mvn clean test
```

预期：`BUILD SUCCESS`，测试使用 H2，**无需**本机 MySQL。

### 3.5 本地运行前置

| 场景 | 检查项 |
|------|--------|
| **MySQL 全栈联调** | `./platform/docker-compose/start-local.sh` 已执行；使用 **`dev` Profile**（无需改 `application-local.yml`） |
| **个人 H2 调试** | 复制 `application-local.yml.example` → `application-local.yml`；使用 **`dev,local`** |
| 新建业务库（非 Compose 默认库时） | `utf8mb4` 字符集，库名与 `DB_NAME` / `--db-name` 一致 |

---

## 4. 从骨架创建新服务（推荐流程）

### 步骤 1：复制仓库

```bash
git clone <skeleton-repo-url> my-order-service
cd my-order-service
rm -rf .git && git init   # 或 fork 后改 remote
```

### 步骤 2（可选）：配置团队组织前缀

若业务包**不是** `com.s3` 开头，先统一改骨架默认前缀（见 §2.2 场景 A）：

```bash
chmod +x scripts/configure-skeleton.sh
./scripts/configure-skeleton.sh \
  --base-package com.acme.skeleton \
  --group-id com.acme
```

### 步骤 3：一键重命名为业务服务

```bash
chmod +x scripts/rename-skeleton.sh
./scripts/rename-skeleton.sh \
  --package com.acme.order \
  --group-id com.acme \
  --artifact order-service \
  --app-name order-service \
  --db-name order_dev
```

当前骨架标识以 `skeleton.defaults.json` 为准；脚本执行后会更新该文件。

### 步骤 4：调整 Maven 本地仓库（可选）

```bash
cp .mvn/settings.xml.example .mvn/settings.xml
# 编辑 <localRepository> 为本机路径（若团队不统一使用 ~/.m2）
```

仓库默认提交的 `.mvn/settings.xml` **仅配置阿里云镜像**，本地仓库为 `~/.m2/repository`。

### 步骤 5：本地配置与建库

```bash
cp src/main/resources/application-local.yml.example \
   src/main/resources/application-local.yml
# 编辑数据库账号密码

mysql -h 127.0.0.1 -P 3306 -uroot -p -e \
  "CREATE DATABASE IF NOT EXISTS order_dev DEFAULT CHARSET utf8mb4;"
```

### 步骤 6：验证

```bash
mvn clean test
mvn spring-boot:run -Dspring-boot.run.profiles=dev
curl -s http://localhost:8080/api/v1/health
```

### 步骤 7：开发业务功能

1. 在 `entity` / `repository` / `service` / `controller` / `dto` 下新增代码  
2. 在 `db/migration/` 增加 `V2__xxx.sql`（可删除或保留 `V1__skeleton_baseline`）  
3. （可选）使用 Speckit 在 `specs/<feature>/` 生成规格与任务  

## 5. Speckit / Cursor 工作流（可选）

`.specify/`、`.cursor/skills/speckit-*` 为 **AI 辅助研发可选模块**，不影响 `mvn package`。

- 新功能目录：`specs/<编号>-<feature>/`（由 `/speckit.specify` 等命令生成）  
- 参考样例：`examples/001-user-management/`（原用户管理完整 spec/plan/tasks）  

## 6. 目录约定

```text
src/main/java/com/s3/skeleton/
├── controller/     # REST
├── service/        # 业务逻辑
├── repository/     # MyBatis Mapper
├── entity/         # 表映射
├── dto/            # 请求/响应/转换
├── common/         # Result、异常
└── config/         # Spring 配置

skeleton.defaults.json   # 根包 / groupId / artifact 可配置标识
examples/                # 仅文档与契约样例，不编译
docs/                    # 工程规范、单测规范、本指南
scripts/                 # configure-skeleton.sh、rename-skeleton.sh 等
```

## 7. 常见问题

### Q1：`mvn test` 失败，提示 Java 版本不对

**现象**：编译报错、字节码版本不匹配，或 `mvn -version` 显示 Java 8。

**处理**：

1. 确认 `java -version` 与 `mvn -version` 均为 **11.x**
2. 设置 `JAVA_HOME` 指向 JDK 17（见 §2.2）
3. 重新打开终端后执行 `mvn clean test`

---

### Q2：`The JAVA_HOME environment variable is not defined correctly`

**现象**：Maven 无法启动，提示 `JAVA_HOME` 应指向 JDK 而非 JRE。

**常见原因**：

- `JAVA_HOME` 指向已删除的 JDK（如 sdkman 残留路径）
- `JAVA_HOME` 为空或指向 JRE 子目录

**处理**：

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export PATH="$JAVA_HOME/bin:$PATH"
mvn -version
```

---

### Q3：`mvn test` 通过，但 `spring-boot:run` 启动失败

**现象**：数据源连接失败、Flyway 报错、无法连接 MySQL。

**说明**：单测使用 H2（`src/test/resources/application.yml`），**不依赖** MySQL；MySQL 联调使用 **`dev` Profile**；个人 H2 调试使用 **`dev,local`**。

**处理**：

1. 确认 MySQL 8.0 已启动
2. 已复制 `application-local.yml.example` → `application-local.yml`
3. 数据库已创建且账号密码正确
4. 检查环境变量：`DB_HOST`、`DB_PORT`、`DB_NAME`、`DB_USER`、`DB_PASSWORD`

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

---

### Q4：Flyway 迁移失败

**现象**：启动时报 `FlywayException`、校验和冲突、表已存在等。

**处理**：

| 场景 | 建议 |
|------|------|
| 全新本地库 | 确认库为空或仅含 Flyway 基线；检查 `db/migration/V*.sql` 命名 |
| 修改了已执行的脚本 | **禁止**改已上线迁移文件；新增 `V{n+1}__xxx.sql` |
| 本地试验需重置 | 删库重建（仅 dev 环境），勿用于生产 |

---

### Q5：`rename-skeleton.sh` 后仍有旧包名残留

**现象**：包名、文档或配置中仍出现旧的 `basePackage`、`groupId` 或 `skeleton`。

**处理**：

```bash
# 确认当前标识
cat skeleton.defaults.json

# 搜索残留（将 com.s3 换成你的旧 groupId）
rg "com\.s3" --glob '!target/**' --glob '!examples/**'
```

手动修正遗漏项后执行 `mvn clean test` 确认。`examples/` 目录为参考样例，脚本**不会**自动替换。

---

### Q5b：如何只改组织前缀、暂不创建业务服务？

使用 `configure-skeleton.sh`（§2.2 场景 A），无需改 `artifactId`。完成后再用 `rename-skeleton.sh` 创建具体服务。

---

### Q6：端口 8080 被占用

**现象**：`Web server failed to start. Port 8080 was already in use.`

**处理**：

- 关闭占用进程，或在 `application-local.yml` 中修改 `server.port`
- 健康检查地址改为对应端口：`curl http://localhost:<port>/api/v1/health`

---

### Q7：依赖下载慢或失败

**现象**：`Could not transfer artifact`、超时、镜像不可达。

**处理**：

1. 确认在项目根目录执行 `mvn`（自动加载 `.mvn/settings.xml`）
2. 必要时复制并自定义本地仓库：`.mvn/settings.xml.example` → `.mvn/settings.xml`
3. 强制更新：`mvn clean test -U`
4. 公司环境配置 Maven 私服（见 [engineering-standards.md](engineering-standards.md) §1）

---

### Q8：API 文档打不开

**现象**：`/doc.html` 或 `/v3/api-docs` 404。

**处理**：

1. 确认服务已启动且无启动异常
2. 默认地址：
   - Knife4j：http://localhost:8080/doc.html
   - OpenAPI：http://localhost:8080/v3/api-docs
3. 检查是否修改了 `server.port` 或 `context-path`

---

### Q9：需要偏离骨架默认技术栈怎么办？

骨架锁定 JDK 17、Spring Boot 3.3.13、MyBatis Plus、MySQL 8.0 等。若必须使用其他版本或组件（如 Redis、完整 Spring Security），须：

1. 在 Speckit `plan.md` 的 **「复杂度追踪」** 中记录偏离项与理由
2. 获得评审批准后再实施

详见 [plan-constitution-check-appendix.md](plan-constitution-check-appendix.md) 与 `.specify/memory/constitution.md`。

---

## 8. 相关文档

- [engineering-standards.md](engineering-standards.md) — Maven、Profile、本地配置  
- [unit-testing.md](unit-testing.md) — 单测分层与 JaCoCo  
- [plan-constitution-check-appendix.md](plan-constitution-check-appendix.md) — Speckit `plan.md` 宪法检查附录  
- [README.md](../README.md) — 快速命令  
- `.specify/memory/constitution.md` — 团队技术宪法  
