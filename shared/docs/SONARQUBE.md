# SonarQube 代码质量扫描

本仓库集成 **SonarLint（IDE）** + **SonarQube Server（可选本地 Docker）** + **Maven Sonar 插件**。

---

## 1. IDE：SonarLint（Cursor / VS Code）

> 新人安装步骤见 **[`CURSOR-IDE-SETUP.md`](CURSOR-IDE-SETUP.md)** §2。

### 安装

团队推荐扩展（已写入 [`.vscode/extensions.json`](../../.vscode/extensions.json)）：

| 扩展 ID | 名称 |
|---------|------|
| `SonarSource.sonarlint-vscode` | SonarLint |

**命令行安装（macOS）：**

```bash
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
  --install-extension SonarSource.sonarlint-vscode
```

打开仓库后 Cursor 会提示安装推荐扩展；安装后 **重载窗口** 生效。

### 使用模式

| 模式 | 说明 |
|------|------|
| **Standalone** | 不连服务器，编辑 Java 时实时提示 Bug / 漏洞 / 坏味道 |
| **Connected** | 连接本地 SonarQube，同步质量门禁与规则（见 §2） |

工作区已预置 Connected Mode 地址 `http://localhost:9000`（[`.vscode/settings.json`](../../.vscode/settings.json)）。  
在 SonarQube 创建项目并生成 Token 后，在 Cursor 命令面板执行 **SonarLint: Add SonarQube Connection** 绑定 Token。

---

## 2. 本地 SonarQube Server（可选）

```bash
cd java-microservice-scaffold
docker compose -f platform/docker-compose/docker-compose.sonar.yml up -d
```

| 项 | 值 |
|----|-----|
| 地址 | http://localhost:9000 |
| 默认账号 | `admin` / `admin`（首次登录须改密） |
| 镜像 | `sonarqube:10.8.1-community` |

等待 healthcheck 通过后访问控制台，为各工程创建 Project Key（与 `sonar-project.properties` 一致）。

---

## 3. Maven 扫描

各工程父 POM 已声明 `sonar-maven-plugin`，配置文件为各目录下 `sonar-project.properties`。

### 脚手架（含 JaCoCo 覆盖率）

```bash
cd java-microservice-common && mvn clean install -DskipTests && cd ..

cd java-microservice-scaffold
mvn clean test
mvn sonar:sonar -Dsonar.token=<YOUR_TOKEN>
```

### Common / Gateway

```bash
cd java-microservice-common
mvn clean test sonar:sonar -Dsonar.token=<YOUR_TOKEN>

cd ../java-microservice-gateway
mvn clean test sonar:sonar -Dsonar.token=<YOUR_TOKEN>
```

> Token 勿提交 Git；可用环境变量：`export SONAR_TOKEN=...` 后 `-Dsonar.token=${SONAR_TOKEN}`。

---

## 4. 与 JaCoCo 的关系

- 单测仍用 **H2**（`mvn test` 无需 MySQL）。
- Sonar 读取 `target/site/jacoco/jacoco.xml` 展示覆盖率（先跑 `mvn test` 再 `sonar:sonar`）。

---

## 5. 常见问题

| 现象 | 处理 |
|------|------|
| SonarLint 无提示 | 确认已安装扩展并重载；Java 项目需加载 Maven |
| Connected Mode 失败 | 检查 SonarQube 是否启动、Token 是否有效 |
| `sonar:sonar` 401 | 补充 `-Dsonar.token=` |
| SonarQube 启动慢 | 首次约 1～2 分钟；Docker 分配 ≥4GB 内存更稳 |

---

## 6. 强制规则（Quality Gate）

团队 Quality Profile 须启用以下 **阻断项**（与 [`CI-TOOLCHAIN.md`](CI-TOOLCHAIN.md) §4.2 一致）：

| 规则 | 说明 |
|------|------|
| `java:S106` | 禁止 `System.out` / `System.err` |
| `java:S1181` / `java:S2221` | 禁止吞异常、禁止 catch `Throwable` |
| `java:S3649` / `java:S2077` | SQL 注入风险（拼接 SQL、`${}` 误用） |
| 循环内重复 `new` | 性能与 GC 风险（如 `java:S3047` 等效规则） |

CI 阶段 1 扫描未通过 Quality Gate 时 **阻断 PR 合并**。AI 生成代码须先过 SonarLint，再提交。

---

## 7. 相关文件

| 文件 | 说明 |
|------|------|
| `.vscode/extensions.json` | 推荐 SonarLint |
| `.vscode/settings.json` | SonarLint / Connected Mode |
| `platform/docker-compose/docker-compose.sonar.yml` | 本地 SonarQube |
| `*/sonar-project.properties` | 各 Maven 工程 Sonar 配置 |
