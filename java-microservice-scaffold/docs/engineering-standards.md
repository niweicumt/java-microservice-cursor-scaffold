# 项目工程规范

本文档补充 `.specify/memory/constitution.md`，约定**本地调试**与**单元测试**相关的构建与配置标准。  
本仓库为 **Java 服务骨架**，使用说明见 [`SKELETON.md`](SKELETON.md)。

## 0. 骨架标识配置

根包、Maven `groupId` 等标识集中在仓库根目录 **`skeleton.defaults.json`**（单一事实来源），由以下脚本读取并写回：

| 脚本 | 用途 |
|------|------|
| `scripts/configure-skeleton.sh` | fork 后调整组织前缀（如 `com.s3` → `com.acme`） |
| `scripts/rename-skeleton.sh` | 创建具体业务服务（包名、artifact、库名） |

详见 [`SKELETON.md`](SKELETON.md) §2。

## 1. Maven 仓库配置

### 1.1 项目级设置（推荐，开箱即用）

| 文件 | 作用 |
|------|------|
| `.mvn/settings.xml` | 提交到 Git：**仅镜像**，本地仓库默认 `~/.m2/repository` |
| `.mvn/settings.xml.example` | 模板：含 `<localRepository>` 占位，复制后自定义 |
| `.mvn/maven.config` | 自动执行 `mvn` 时使用 `-s .mvn/settings.xml` |

自定义本地仓库路径（可选）：

```bash
cp .mvn/settings.xml.example .mvn/settings.xml
# 编辑 <localRepository> 为本机路径（勿提交含个人路径的文件）
```

在仓库根目录执行 `mvn` 时**无需**再手动指定 `-s`。

### 1.2 POM 仓库声明

`pom.xml` 中声明 `<repositories>` / `<pluginRepositories>`，保证 CI 或未使用项目 settings 时仍可解析依赖。

### 1.3 覆盖个人全局 settings（可选）

若需使用公司私服，可在 `~/.m2/settings.xml` 中配置，但**不得**覆盖项目锁定的 JDK / Spring Boot 版本。

### 1.4 Maven 常用命令（日常操作）

在**项目根目录**执行以下命令。项目已通过 `.mvn/maven.config` 自动加载 `.mvn/settings.xml`，一般**不必**手写 `-s .mvn/settings.xml`；若未生效，可显式加上该参数。

#### 环境与配置检查

```bash
# 确认 JDK 版本（须为 17）
java -version

# 确认 Maven 版本（建议 3.6.3+，Spring Boot 3 父 POM 推荐 3.6.3 及以上）
mvn -version

# 查看本项目实际使用的本地仓库路径
mvn help:evaluate -Dexpression=settings.localRepository -q -DforceStdout
# 预期输出：/Users/niwei/Work/company/羚夏/maven/repository
```

#### 编译与打包

| 场景 | 命令 | 说明 |
|------|------|------|
| 仅编译 | `mvn clean compile` | 校验代码能否通过编译，依赖会下载到本地仓库 |
| 打包（跳过测试） | `mvn clean package -DskipTests` | 生成 `target/java-service-skeleton-1.0.0-SNAPSHOT.jar` |
| 强制更新依赖 | `mvn clean package -DskipTests -U` | 远程检查 SNAPSHOT/依赖更新后再构建 |
| 预下载全部依赖 | `mvn dependency:go-offline -DincludeScope=test` | 将 compile/test 依赖尽量拉入本地仓库，便于离线或首启加速 |

```bash
# 常用组合：清理 + 编译
mvn clean compile

# 常用组合：清理 + 打包（发版/本地试运行 jar 前）
mvn clean package -DskipTests
```

#### 单元测试

| 场景 | 命令 | 说明 |
|------|------|------|
| 运行测试 | `mvn test` | 使用 H2 内存库，**无需**启动 MySQL（见第 3 节） |
| 仅编译测试代码 | `mvn test-compile` | 不执行测试用例，只编译 `src/test/java` |

```bash
mvn test
```

#### 运行服务

| 场景 | 命令 | 说明 |
|------|------|------|
| 本地 MySQL 联调 | `mvn spring-boot:run -Dspring-boot.run.profiles=dev` | 需 `start-local.sh` + Compose MySQL |
| 个人 H2 调试 | `mvn spring-boot:run -Dspring-boot.run.profiles=dev,local` | 需 `application-local.yml`（见第 2 节） |
| 远端测试环境 | `mvn spring-boot:run -Dspring-boot.run.profiles=dev` | 见 `application-test.yml` |

```bash
# MySQL 全栈联调（先 start-local.sh，再 dev Profile）
./platform/docker-compose/start-local.sh
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
```

#### 使用已打包 jar 启动（MySQL 联调）

```bash
mvn clean package -DskipTests
java -jar target/skeleton-service-1.0.0-SNAPSHOT.jar --spring.profiles.active=dev
```

#### 依赖与问题排查

```bash
# 查看依赖树（排查版本冲突）
mvn dependency:tree

# 查看某依赖为何被引入
mvn dependency:tree -Dincludes=org.springframework.boot

# 仅解析依赖，不编译
mvn dependency:resolve
```

#### 注意事项

1. **工作目录**：必须在包含 `pom.xml` 的仓库根目录执行。
2. **本地仓库**：依赖 jar 会写入 `<localRepository>` 所指目录，不会使用默认 `~/.m2/repository`（除非 settings 被覆盖）。
3. **IDE**：IntelliJ IDEA 导入 Maven 项目后，建议在 Maven 设置中勾选「使用项目 settings」，或指定 `.mvn/settings.xml`。
4. **首次构建**：网络正常时首次 `mvn package` 会下载较多依赖，属正常现象。

## 2. 本地调试配置（application-local）

### 2.1 约定

| 项 | 约定 |
|----|------|
| 模板文件 | `src/main/resources/application-local.yml.example`（**提交 Git**） |
| 个人文件 | `src/main/resources/application-local.yml`（**不提交**，见 `.gitignore`） |
| 激活方式 | `dev,local`（在 dev 基线上覆盖个人项） |
| 数据源 | **H2 文件库** `./data/local-db`（覆盖 dev 的 MySQL） |
| 用途 | 个人 H2 路径、DEBUG 日志、端口等差异 |

### 2.2 初始化步骤

```bash
cp src/main/resources/application-local.yml.example \
   src/main/resources/application-local.yml
# 按需调整 H2 路径、端口、日志级别
```

### 2.3 启动示例

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=dev,local
```

IDE：Run Configuration → Active profiles 填写 `dev,local`。

### 2.4 本地 MySQL 联调（dev Profile）

本地 Compose 联调使用 **`dev` Profile**（见 `application-dev.yml`），**非** `application-local.yml`：

```bash
# 先启动基础设施（含 MySQL）
./platform/docker-compose/start-local.sh

mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

环境变量 `DB_HOST` / `DB_PORT` / `DB_NAME` / `DB_USER` / `DB_PASSWORD` 可覆盖默认连接信息。

### 2.5 与安全规范的关系

- **禁止**在 `application-local.yml` 中提交生产/UAT 真实密码后推送到远程仓库
- `application-local.yml` 必须保持在 `.gitignore` 中

## 3. 单元测试配置

完整规范见 **[`docs/unit-testing.md`](unit-testing.md)**（分层、命名、覆盖率、质量门槛）。

### 3.1 测试资源

| 文件 | 作用 |
|------|------|
| `src/test/resources/application.yml` | 测试默认配置：H2 内存库 + Flyway 迁移 |
| `pom.xml` 中 `h2`（runtime scope） | dev / local Profile 与 `mvn test` 使用 H2 驱动 |
| `src/test/java/com/s3/user/**` | 单元测试 / 集成测试代码 |
| JaCoCo（`pom.xml`） | `mvn test` 后生成 `target/site/jacoco/index.html` |

### 3.2 运行测试与覆盖率

```bash
# 运行全部测试
mvn clean test

# 浏览器查看覆盖率报告
open target/site/jacoco/index.html
```

测试使用 H2 `MODE=MySQL`，执行与主工程相同的 `db/migration` 脚本（注意方言差异时以 MySQL 为准做联调）。

**测试分层（摘要）**：

| 类型 | 示例类 | 说明 |
|------|--------|------|
| Service 单元 | `UserServiceImplTest` | Mockito，不启容器 |
| Controller 单元 | `UserControllerTest` | MockMvc standalone，Mock Service |
| API 集成 | `UserApiIntegrationTest` | `@SpringBootTest` + H2 + MockMvc |

### 3.3 与 Profile 的分工

| 场景 | Profile / 配置 |
|------|----------------|
| 本地开发（默认） | `dev` → H2 文件库 `./data/dev-db` |
| 个人 H2 调试 | `dev,local` → H2 文件库 `./data/local-db` |
| 本机 MySQL 全栈联调 | `test` → MySQL（Compose） |
| CI / 本地快速单测 | `src/test/resources/application.yml` → H2 内存 |
| 测试环境部署 | `test` → MySQL |
| 生产 | `prod` → MySQL |

详见 **[`../../shared/docs/CI-TOOLCHAIN.md`](../../shared/docs/CI-TOOLCHAIN.md)** §2。

### 3.4 本地 MySQL 联调验证（可选）

在已启动 Compose MySQL 时：

```bash
# 1. 单元测试（H2，不依赖 MySQL）
mvn test

# 2. MySQL 联调启动
./platform/docker-compose/start-local.sh
mvn spring-boot:run -Dspring-boot.run.profiles=dev
curl -s http://localhost:8080/api/v1/health
```

预期：`/api/v1/health` 返回 `code: 200`，`data.status` 为 `UP`。

## 4. 环境 Profile 一览

| Profile | 数据源 | 配置文件 | 提交 Git | 用途 |
|---------|--------|----------|----------|------|
| **dev** | MySQL | application-dev.yml | ✅ | 本地 Compose 联调 |
| **test** | MySQL | application-test.yml | ✅ | 远端测试环境 |
| **prod** | MySQL | application-prod.yml | ✅ | 生产 |
| uat / pre | MySQL | 对应 yml | ✅ | 预发 / UAT（同 prod 模式） |
| **local** | H2 文件 | application-local.yml | ❌ | 个人 H2 覆盖（dev,local） |
| （单测） | H2 内存 | src/test/resources/application.yml | ✅ | `mvn test` / CI |

团队强制约束与 CI 门禁：**[`../../shared/docs/CI-TOOLCHAIN.md`](../../shared/docs/CI-TOOLCHAIN.md)**。

## 5. 相关文档

- 项目宪法：`.specify/memory/constitution.md`
- **工程自动化与 CI 门禁**：[`../../shared/docs/CI-TOOLCHAIN.md`](../../shared/docs/CI-TOOLCHAIN.md)
- **Java / AI 代码规范**：[`../../shared/docs/CURSOR-RULES.md`](../../shared/docs/CURSOR-RULES.md) · [`.cursor/rules/microservice-architecture.mdc`](../../.cursor/rules/microservice-architecture.mdc) · [`.cursor/rules/alibaba-java-standard.mdc`](../../.cursor/rules/alibaba-java-standard.mdc)
- 单元测试规范：[`docs/unit-testing.md`](unit-testing.md)
- 骨架指南：[`SKELETON.md`](SKELETON.md)
- 示例 quickstart：`examples/001-user-management/quickstart.md`
- README：根目录 `README.md`
