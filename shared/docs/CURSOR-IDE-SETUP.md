# Cursor / IDE 团队插件与新人上手

本文档说明新员工 **必须安装** 的工具链：VS Code 扩展、Cursor 插件、OpenSpec CLI，以及仓库内置的 Cursor 规则与 Speckit 工作流。

> **新同学总入口**：[`docs/GETTING-STARTED.md`](../../docs/GETTING-STARTED.md)（Day 1 Checklist + 文档地图）  
> 代码质量与 CI 门禁：[`SONARQUBE.md`](SONARQUBE.md)、[`CI-TOOLCHAIN.md`](CI-TOOLCHAIN.md)  
> AI 代码规范：[`CURSOR-RULES.md`](CURSOR-RULES.md)

---

## 1. 必装清单（总览）

| # | 类型 | 名称 | 作用 | 必装 |
|---|------|------|------|:----:|
| 1 | **VS Code 扩展** | [SonarLint](#2-sonarlint-vs-code-扩展) | 实时代码质量检查，与 CI SonarQube 对齐 | ✅ |
| 2 | **Cursor 插件** | [Superpowers](#3-superpowers-cursor-插件) | Agent 技能库：TDD、调试、计划执行、Code Review 等工作流 | ✅ |
| 3 | **CLI 工具** | [OpenSpec](#4-openspec-cli) | 规格驱动开发：`/opsx-*` 命令，需求→设计→实现可追溯 | ✅ |

另：**Speckit**（[`/speckit.*`](#5-仓库内置-speckit-工作流)）已内置在本仓库，**无需单独安装**，与 OpenSpec 互补使用。

### 1.1 前置环境

| 项 | 版本 / 说明 |
|----|-------------|
| **Cursor** | 团队统一 IDE |
| **JDK** | 17 |
| **Maven** | 3.9+（根目录 `.mvn/settings.xml` 已配镜像） |
| **Node.js** | **≥ 20.19.0**（OpenSpec CLI 要求） |
| **Docker** | 可选；MySQL 联调、SonarQube 本地、release Testcontainers |

```bash
git clone <repo-url> java-cursor-demo
cd java-cursor-demo

java -version    # 17
mvn -version     # 3.9+
node -v          # ≥ v20.19.0（OpenSpec）

cd java-microservice-common && mvn clean install && cd ..
cd java-microservice-scaffold && mvn clean test
```

### 1.2 OpenSpec 与 Speckit：新人必读

团队用 AI 写微服务时，**不是直接让 Agent 改代码**，而是先把「要做什么、为什么、怎么做」写成可追溯的文档，再按文档实现。本仓库有两套互补的规格工具：

| | **OpenSpec** | **Speckit** |
|--|--------------|-------------|
| **定位** | 变更级规格：一次需求 / 一次改动的「提案 → 设计 → 任务 → 实现 → 归档」 | 功能级规格：本脚手架内的「spec → plan → tasks → 实现」全流程 |
| **安装** | 需安装 CLI + 仓库 `openspec init` | **仓库内置**，克隆即用 |
| **工作目录** | Monorepo **根目录** | 主要在 `java-microservice-scaffold/` |
| **产出目录** | `openspec/specs/`（现状）、`openspec/changes/<变更名>/`（进行中） | `java-microservice-scaffold/specs/<feature>/` |
| **Cursor 命令** | `/opsx-*` | `/speckit.*` |
| **适合场景** | 界定变更范围、多轮探索、与现状 spec 同步、变更归档 | 按团队模板写详细 spec/plan/tasks、对齐宪法与工程规范 |
| **样例** | 各变更目录内 `proposal.md`、`design.md`、`tasks.md` | `examples/001-user-management/` |

#### 各自解决什么问题？

**OpenSpec**（[Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)）强调 **「先规格、后代码」** 的变更管理：

- 把一次改动当成独立 **change**，避免 AI 在长对话里「忘掉」最初约定
- 维护 `openspec/specs/` 作为系统**当前真相**（按领域拆分的能力说明）
- 在 `openspec/changes/` 里放**进行中**的提案、设计、任务，完成后归档并回写 specs
- 适合回答：「这次到底改什么？和现有 spec 差在哪？做完了怎么合回主线？」

**Speckit**（本仓库 `.specify/` + `/speckit.*`）强调 **与本 Java 微服务脚手架绑定的工程化产出**：

- 按固定模板生成 `spec.md`、`plan.md`、`research.md`、`data-model.md`、`tasks.md`
- 强制对齐 [`constitution.md`](../../java-microservice-scaffold/.specify/memory/constitution.md)（技术栈、分层、测试、CI）
- `/speckit.implement` 会读 [`CURSOR-RULES.md`](CURSOR-RULES.md)，按 `auto`/`custom` 分层写代码
- 适合回答：「这个功能的详细设计、表结构、任务拆解、实现步骤是什么？」

#### 推荐协作流程（新功能）

```text
需求描述
    │
    ▼
OpenSpec /opsx-propose     ← 定变更名、写 proposal / design / tasks（变更边界）
    │   （可选 /opsx-explore 探索不清的点）
    ▼
Speckit /speckit.specify   ← 在 scaffold 下出功能 spec（用户故事、验收标准）
    ▼
/speckit.plan → /speckit.tasks
    ▼
/speckit.implement         ← 按 tasks 写代码 + 测试
    │   （执行节奏可由 Superpowers：TDD、验证、Review 约束）
    ▼
OpenSpec /opsx-sync        ← 实现完成后，把变更合入 openspec/specs/
    ▼
/opsx-archive              ← 归档本次 change
```

> **简记**：OpenSpec 管 **「这一次变更」** 的生命周期；Speckit 管 **「这个功能在脚手架里怎么落地」** 的文档与实现。小改动可以只用其一；正式业务功能建议 **两者串联**。

#### 命令速查

**OpenSpec（`/opsx-*`，需已 `openspec init --tools cursor`）**

| 命令 | 主要作用 |
|------|----------|
| `/opsx-propose` | 创建变更并生成 proposal、design、tasks |
| `/opsx-explore` | 探索需求或技术方案，不直接写实现 |
| `/opsx-apply` | 按当前 change 的 tasks 实施代码 |
| `/opsx-sync` | 将变更同步到 `openspec/specs/` |
| `/opsx-archive` | 归档已完成的 change |

**Speckit（`/speckit.*`，仓库内置）**

| 命令 | 主要作用 |
|------|----------|
| `/speckit.specify` | 从自然语言需求生成 `specs/<feature>/spec.md` |
| `/speckit.clarify` | 找出 spec 里模糊点并提问澄清 |
| `/speckit.plan` | 生成 `plan.md`、research、data-model 等 |
| `/speckit.tasks` | 生成可执行的 `tasks.md` |
| `/speckit.implement` | 按 tasks 实现（遵守 Cursor 规则） |
| `/speckit.analyze` | 检查 spec / plan / tasks 一致性 |

其他：`/speckit.checklist`、`/speckit.constitution`、`/speckit.taskstoissues` 用于清单、宪法维护、任务转 GitHub Issue。

#### 与 Superpowers、Cursor 规则的关系

```text
OpenSpec（变更边界）  +  Speckit（详细设计与任务）
            │
            ▼
Superpowers（怎么开发：TDD、调试、计划执行、完成前验证）
            │
            ▼
.cursor/rules/（写什么代码：阿里规范、分层、H2 单测、Result）
```

冲突时 **仓库 `.cursor/rules/` 优先**（编码与架构硬约束）。

---

## 2. SonarLint（VS Code 扩展）

仓库通过 [`.vscode/extensions.json`](../../.vscode/extensions.json) 声明推荐扩展。  
用 Cursor 打开仓库后，右下角提示 **Install Recommended Extensions** → 一键安装。

| 扩展 ID | 名称 |
|---------|------|
| `SonarSource.sonarlint-vscode` | SonarLint |

### 2.1 命令行安装

**macOS：**

```bash
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
  --install-extension SonarSource.sonarlint-vscode
```

**Windows / Linux：**

```bash
cursor --install-extension SonarSource.sonarlint-vscode
```

安装后执行 **Developer: Reload Window**。

### 2.2 工作区配置

[`.vscode/settings.json`](../../.vscode/settings.json) 已提交 Git：

| 配置 | 说明 |
|------|------|
| `java.configuration.updateBuildConfiguration` | 自动同步 Maven |
| `sonarlint.rules` | 启用 `java:S106`（禁 System.out）等 |
| `sonarlint.connectedMode.connections.sonarqube` | 预置 `http://localhost:9000` |

Connected Mode 绑定 Token 见 [`SONARQUBE.md`](SONARQUBE.md) §1～§2。

---

## 3. Superpowers（Cursor 插件）

**Superpowers** 是 Cursor **插件市场**中的 Agent 技能库（非 VS Code 扩展），提供结构化开发工作流：

| 能力 | 典型 Skill |
|------|------------|
| 需求澄清 / 设计 | `brainstorming`、`writing-plans` |
| 计划执行 | `executing-plans`、`subagent-driven-development` |
| 质量保障 | `test-driven-development`、`systematic-debugging`、`verification-before-completion` |
| 收尾 | `finishing-a-development-branch`、`requesting-code-review` |

上游：[obra/superpowers](https://github.com/obra/superpowers)（团队参考版本 **5.0.x**）

### 3.1 安装

在 **Cursor Agent 聊天框** 输入：

```text
/add-plugin superpowers
```

或在 **Cursor Settings → Plugins** 搜索 **Superpowers** → Install。

### 3.2 更新

```text
/plugin update superpowers
```

更新后 **新开 Agent 会话** 或重载窗口，确保 Skills / Hooks 生效。

### 3.3 验证

新开 Chat，输入「帮我规划一个用户模块功能」—— Agent 应自动触发 `brainstorming` 等 Skill，而不是直接写代码。

### 3.4 与本仓库的关系

- Superpowers 管 **怎么开发**（TDD、计划、调试、Review）。
- 本仓库 `.cursor/rules/` 管 **写什么代码**（阿里规范、`auto`/`custom`、`Result`、H2 单测）。
- 两者 **同时生效**；冲突时 **仓库规则更严格**。

---

## 4. OpenSpec（CLI）

**OpenSpec**（[@fission-ai/openspec](https://github.com/Fission-AI/OpenSpec)）是规格驱动开发的 **CLI + Cursor 斜杠命令**。  
功能定位与 Speckit 对比见 [§1.2](#12-openspec-与-speckit新人必读)。

主要职责：

- 以 **change** 为单位管理一次需求从提案到归档的全流程
- 维护 `openspec/specs/`（系统现状）与 `openspec/changes/`（进行中变更）
- 提供 `/opsx-*` 命令，在 Cursor 内可追溯地驱动 AI 实现

> 本仓库同时内置 **Speckit**（§5）。OpenSpec 需 **单独安装 CLI**；二者互补，新人两项都应了解。

### 4.1 安装 CLI

```bash
# 要求 Node.js ≥ 20.19.0
npm install -g @fission-ai/openspec@latest

openspec --version
```

### 4.2 在仓库中初始化（首次 / 尚无 openspec/ 时）

在 **Monorepo 根目录**（或团队约定的子工程根）执行：

```bash
cd java-cursor-demo
openspec init --tools cursor
```

交互式亦可 `openspec init` 并选择 **Cursor**。会生成 `openspec/`、`.cursor/commands/opsx-*.md`、`.cursor/skills/openspec-*` 等。  
**请将生成物提交 Git**，以便全员命令一致。

若仓库已有 `openspec/`，新人克隆后 **无需重复 init**，直接更新 CLI 即可：

```bash
npm install -g @fission-ai/openspec@latest
openspec update
```

### 4.3 常用命令（Cursor Chat）

| 命令 | 用途 |
|------|------|
| `/opsx-propose` | 创建变更，生成 proposal / design / tasks |
| `/opsx-explore` | 探索需求或方案，不直接写实现 |
| `/opsx-apply` | 按当前 change 的 tasks 实施 |
| `/opsx-sync` | 将变更同步到 `openspec/specs/` |
| `/opsx-archive` | 归档已完成的 change |

> 完整说明见 [§1.2](#12-openspec-与-speckit新人必读) 与 [OpenSpec Commands](https://github.com/Fission-AI/OpenSpec/blob/main/docs/commands.md)。

### 4.4 验证

```bash
openspec --version   # 有版本号
```

Cursor Chat 输入 `/opsx` 应能联想出 OpenSpec 相关斜杠命令。

---

## 5. 仓库内置 Speckit 工作流

**无需安装**，克隆仓库即具备。与 OpenSpec 的分工见 [§1.2](#12-openspec-与-speckit新人必读)。

Speckit 面向 **本 Java 微服务脚手架** 的功能交付：按团队模板产出 spec / plan / tasks，并驱动 `/speckit.implement` 在 `skeleton-service` 等模块中写代码。

| 位置 | 说明 |
|------|------|
| `java-microservice-scaffold/.specify/` | 宪法、模板、脚本（spec / plan / tasks） |
| `.cursor/skills/speckit-*/` | Cursor Skills，对应 `/speckit.*` 命令 |

| 命令 | 说明 |
|------|------|
| `/speckit.specify` | 从需求生成 `specs/<feature>/spec.md` |
| `/speckit.clarify` | 澄清 spec 中模糊需求 |
| `/speckit.plan` | 生成 `plan.md`、research、data-model |
| `/speckit.tasks` | 生成 `tasks.md` |
| `/speckit.implement` | 按 tasks 实现（强制读 CURSOR-RULES） |
| `/speckit.analyze` | spec / plan / tasks 一致性分析 |

工作目录：`java-microservice-scaffold/`。完整样例：`examples/001-user-management/`。  
项目宪法：`java-microservice-scaffold/.specify/memory/constitution.md`。

**与 OpenSpec 串联示例：**

```text
/opsx-propose "订单服务 MVP"  →  openspec/changes/.../
/speckit.specify "订单 CRUD"  →  specs/00x-order/spec.md
/speckit.plan → /speckit.tasks → /speckit.implement
/opsx-sync → /opsx-archive
```

---

## 6. 仓库内置 Cursor 规则（自动生效）

[`.cursor/rules/`](../../.cursor/rules/) 提交 Git，打开仓库自动加载：

| 文件 | 作用 |
|------|------|
| `specify-rules.mdc` | Monorepo 结构、技术栈、文档索引（始终生效） |
| `alibaba-java-standard.mdc` | 阿里泰山版 + 微服务代码生成约束 |

摘要：[`CURSOR-RULES.md`](CURSOR-RULES.md)

---

## 7. 新人 Checklist

- [ ] JDK 17、Maven 3.9+、**Node.js ≥ 20.19.0**
- [ ] 克隆仓库，Cursor 打开 **Monorepo 根目录**
- [ ] 安装 **SonarLint**（§2）
- [ ] 安装 **Superpowers** 插件（§3）
- [ ] 安装 **OpenSpec CLI** 并确认 `/opsx-*` 可用（§4）
- [ ] `mvn install` + `mvn test` 通过
- [ ] 阅读 [§1.2 OpenSpec 与 Speckit](#12-openspec-与-speckit新人必读)、[`CURSOR-RULES.md`](CURSOR-RULES.md)、[`PACKAGE-IDENTITY.md`](PACKAGE-IDENTITY.md)、[`CI-TOOLCHAIN.md`](CI-TOOLCHAIN.md)
- [ ] （推荐）SonarLint 绑定 SonarQube — [`SONARQUBE.md`](SONARQUBE.md)
- [ ] 熟悉 `/speckit.*` 与 `/opsx-*` 至少各跑通一次示例

---

## 8. 常见问题

| 现象 | 处理 |
|------|------|
| 未弹出 SonarLint 推荐 | 扩展视图 → **Recommended** → 安装 |
| Superpowers 无 Skill 触发 | 确认插件已启用；新开 Chat；执行 `/plugin update superpowers` |
| `openspec: command not found` | `npm install -g @fission-ai/openspec@latest`；检查 Node ≥ 20.19 |
| 无 `/opsx-*` 命令 | 在仓库根执行 `openspec init` 并选 Cursor；重载窗口 |
| OpenSpec 与 Speckit 用哪个 | **都要会**：OpenSpec 管变更提案；Speckit 管本仓库详细 spec/plan/tasks |
| AI 代码不符合规范 | 确认打开仓库根目录；检查 `.cursor/rules/` |

---

## 9. 相关文件

| 文件 | 说明 |
|------|------|
| [`.vscode/extensions.json`](../../.vscode/extensions.json) | SonarLint 推荐 |
| [`.vscode/settings.json`](../../.vscode/settings.json) | SonarLint / Java 设置 |
| [`.cursor/rules/`](../../.cursor/rules/) | Cursor AI 规则 |
| `openspec/` | OpenSpec 规格与变更目录 |
| `.cursor/commands/opsx-*.md` | OpenSpec Cursor 斜杠命令 |
| `.cursor/skills/openspec-*/` | OpenSpec Skills |
| [`.cursor/skills/`](../../.cursor/skills/) | Speckit / OpenSpec Skills |
| `java-microservice-scaffold/.specify/` | Speckit 模板与宪法 |
| [`SONARQUBE.md`](SONARQUBE.md) | Sonar 详细用法 |
| [`CURSOR-RULES.md`](CURSOR-RULES.md) | 代码规范摘要 |
