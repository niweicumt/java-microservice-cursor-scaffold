# AgentLens 使用指南

团队统一安装 **AgentLens**，用于统计 Cursor 等 AI Agent **自动生成代码 vs 人工编写** 的比例，便于 Code Review、质量分析与团队度量对齐。

> **工具定位**：本文讲 AgentLens 的安装、连接与统计导出；日常 AI 开发闭环见 [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md)；必装工具总览见 [AI-NATIVE-ENGINEERING.md §2](AI-NATIVE-ENGINEERING.md#2-工具链必装)。

---

## 目录

1. [为什么需要 AgentLens](#1-为什么需要-agentlens)
2. [安装（团队统一）](#2-安装团队统一)
3. [项目初始化与连接 Cursor](#3-项目初始化与连接-cursor)
4. [日常使用](#4-日常使用)
5. [团队统计与导出](#5-团队统计与导出)
6. [判定规则与配置](#6-判定规则与配置)
7. [故障排查](#7-故障排查)
8. [隐私与 Git 约定](#8-隐私与-git-约定)

---

## 1. 为什么需要 AgentLens

| 目标 | AgentLens 能力 |
|------|----------------|
| 统计 AI 生成代码占比 | 对 Git diff 逐 hunk 标注 AI / 人工 / AI+人工修改 |
| 统一度量口径 | 全员同一扩展 + CLI + 相同分类阈值（≥90% / 70–90% / <70%） |
| 辅助 Code Review | GitLens 式行内 blame，悬停可见贡献来源 |
| 对接 Cursor | 通过 Cursor Third-party Hooks 实时采集 Agent 变更 |

**注意**：市面上存在多个同名项目（如 `@tasszz2k/agentlens` 侧重成本仪表盘）。本团队使用的是 **[vibe-x-ai / AgentLens](https://github.com/alienzhou/agentlens)**（扩展 ID：`vibe-x-ai.agentlens`），专用于 **代码归属追踪**。

---

## 2. 安装（团队统一）

### 2.1 前置条件

| 项 | 要求 |
|----|------|
| Cursor | 团队统一 IDE |
| Node.js | ≥ 22.15.0（CLI 依赖；与 OpenSpec 的 ≥ 20.19 取较高者） |
| Git | 已配置用户名 / 邮箱 |
| 仓库 | 在 Monorepo 根目录工作 |

### 2.2 安装 Cursor 扩展（必装）

**方式 A：Cursor 扩展面板**

1. `Cmd+Shift+X`（Windows/Linux：`Ctrl+Shift+X`）打开扩展
2. 搜索 **AgentLens**（发布者 **vibe-x-ai**）
3. 点击 Install

**方式 B：命令行（推荐脚本化）**

```bash
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
  --install-extension vibe-x-ai.agentlens
```

Linux / Windows 将路径替换为本机 Cursor 可执行文件；或使用 `cursor --install-extension vibe-x-ai.agentlens`。

### 2.3 安装 CLI（团队统一，用于导出报告）

```bash
npm install -g @vibe-x/agentlens-cli@latest
agentlens --help
```

验证：

```bash
agentlens hook list    # 应列出 cursor、claude-code
```

### 2.4 启用 Cursor Hooks（必做，否则无法采集）

1. 打开 **Cursor Settings**
2. 进入 **Features**
3. 开启 **Third-party skills**（第三方 Hooks）

> 扩展与 CLI 均可独立连接 Agent；团队规范为 **扩展 + CLI 均安装**，便于 IDE 内查看与命令行导出。

---

## 3. 项目初始化与连接 Cursor

在 **Monorepo 根目录**（`java-cursor-demo/`）执行一次：

```bash
cd /path/to/java-cursor-demo

# 1. 初始化项目（创建 .agentlens/ 目录结构）
agentlens config --init

# 2. 连接 Cursor（写入 ~/.cursor/hooks.json）
agentlens hook connect cursor

# 3. 确认连接状态
agentlens hook status
```

**Cursor 内连接（与 CLI 二选一或双保险）**：

1. `Cmd+Shift+P` → **AgentLens: Connect Agent**
2. 选择 **Cursor**
3. 侧边栏 **Connected Agents** 应显示 ✅ Connected

初始化后目录结构：

```text
.agentlens/
├── config/           # 团队可对齐的匹配参数（可选提交）
└── data/             # 本地采集数据（勿提交 Git）
    ├── hooks/
    │   ├── changes/  # 按日期分片的 JSONL
    │   └── prompts/
    └── sessions/
```

---

## 4. 日常使用

### 4.1 开发前

- 确认 `agentlens hook status` 中 Cursor 为 **Connected**
- 若刚换机器或重装 Cursor，重新执行 [§3](#3-项目初始化与连接-cursor)

### 4.2 开发中

正常使用 Cursor Agent（Chat / Composer / Agent 模式）生成或修改代码；AgentLens 通过 Hooks **自动记录**，无需额外操作。

IDE 内可：

- **悬停代码行**：查看 AI Generated / AI Generated (Human Modified) / Human Contribution
- **侧边栏 Recent Activity**：浏览近期 AI 变更，跳转文件或 diff
- `Cmd+Shift+P` → **AgentLens: Show Blame**：查看当前行归属

### 4.3 提 PR 前

在 Pre-PR 流程中增加 AgentLens 自检（见 [TEAM-PLAYBOOK §4](TEAM-PLAYBOOK.md#4-pre-pr-checklist)）：

```bash
# 查看当前工作区相对 main 的标注 diff
agentlens diff --annotated --ref origin/main

# 导出 Markdown 报告（可附在 PR 描述或团队统计）
agentlens diff --annotated --ref origin/main \
  --format markdown -o /tmp/agentlens-pr-report.md
```

---

## 5. 团队统计与导出

### 5.1 统一统计口径

团队约定以下三类加总为 **AI 相关代码**：

| 分类 | 相似度 | 计入 AI 占比 |
|------|--------|:------------:|
| AI Generated | ≥ 90% | ✅ |
| AI Generated (Human Modified) | 70%–90% | ✅（标注为「AI+人工」） |
| Human Contribution | < 70% | ❌ |

**AI 代码占比（行级近似）** = `(AI Generated 行数 + AI Modified 行数) / 总变更行数`  
具体以 CLI 输出的 hunk 统计为准。

### 5.2 个人周期报告（CLI）

```bash
# 相对 main 的完整标注 diff（终端彩色输出）
agentlens diff --annotated --ref origin/main

# JSON（便于脚本汇总）
agentlens diff --annotated --ref origin/main --format json -o report.json

# 交互式 Review 会话
agentlens review --since "2026-06-01" --format markdown -o weekly-review.md
```

### 5.3 团队汇总建议流程

```text
开发者本地（AgentLens 全程开启）
    │
    ▼
周期末 / PR 前：agentlens diff --format json --ref origin/main
    │
    ▼
提交 JSON / Markdown 至团队统计渠道（Sheet、内部脚本或 CI 工件）
    │
    ▼
TL 按统一口径汇总 AI 占比、AI+人工占比、纯人工占比
```

> AgentLens 当前以 **本地采集 + diff 标注** 为主，暂无官方中心化 Dashboard。团队度量依赖 **统一安装 + 统一阈值 + 定期导出**；若后续上游提供聚合 API，可在本文 §5 追加。

### 5.4 PR 描述可选片段

```markdown
## AgentLens（AI 代码占比）
- [ ] 已连接 Cursor Hooks
- AI Generated: __%
- AI + Human Modified: __%
- Human: __%
- 报告：`agentlens diff --format markdown --ref origin/main` 输出见附件
```

---

## 6. 判定规则与配置

### 6.1 匹配流程（了解即可）

```text
文件路径过滤 → 时间窗口过滤 → 内容长度过滤 → Levenshtein 相似度
```

### 6.2 团队推荐配置

可在 **工作区** `.vscode/settings.json` 或用户级设置中统一：

```json
{
  "agentLens.matching.timeWindowDays": 3,
  "agentLens.matching.lengthTolerance": 0.5,
  "agentLens.autoCleanup.enabled": true,
  "agentLens.autoCleanup.retentionDays": 7,
  "agentLens.developerMode": false
}
```

| 设置 | 含义 | 默认 |
|------|------|------|
| `timeWindowDays` | 与 Hook 记录匹配的时间窗口（天） | 3 |
| `lengthTolerance` | 内容长度容差 | 0.5 |
| `autoCleanup.retentionDays` | 本地数据保留天数 | 7 |

CLI 修改项目级配置：

```bash
agentlens config --show
agentlens config --set matching.timeWindowDays=3
```

---

## 7. 故障排查

### Q：侧边栏无 Recent Activity

1. 运行 **AgentLens: Connect Agent** 并选择 Cursor
2. 确认 Cursor **Third-party skills** 已开启
3. 连接后再用 Agent 改代码；历史未连接期间的变更无法追溯

### Q：Blame 显示 Human，但代码明显来自 Agent

常见原因：

- 写入代码时 Agent **未连接**
- 生成后被 **大幅手工修改**（相似度 < 70%）
- 超出 **timeWindowDays** 窗口
- 在 **未 init** 的目录下工作

处理：重新 `agentlens hook connect cursor`；对疑难 hunk 使用 **AgentLens: Report Matching Issue**。

### Q：`agentlens hook connect cursor` 失败

```bash
agentlens hook status
agentlens hook disconnect cursor
agentlens hook connect cursor
```

检查 `~/.cursor/hooks.json` 是否被其他工具覆盖；团队内 Hooks 冲突时与 TL 对齐保留 AgentLens 条目。

### Q：CLI 命令找不到

```bash
node -v          # 需 >= 22.15
npm install -g @vibe-x/agentlens-cli@latest
which agentlens
```

---

## 8. 隐私与 Git 约定

| 路径 | 是否提交 Git | 说明 |
|------|:------------:|------|
| `.agentlens/data/` | ❌ | 含 prompts、session，可能含业务上下文 |
| `.agentlens/config/` | 可选 ✅ | 团队对齐匹配参数时可提交 |
| 导出的 `report.json` / `*.md` | 视内容 | 默认放 `/tmp` 或团队统计系统，**勿**含密钥 |

`.gitignore` 已忽略 `.agentlens/data/`。导出报告前请脱敏，禁止上传含 `application-local.yml`、Token 等敏感信息的内容。

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [AI-NATIVE-ENGINEERING.md](AI-NATIVE-ENGINEERING.md) | 工具链必装总览 |
| [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) | Vibe Coding 与 Pre-PR |
| [PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md) | PR 流程 |
| [AgentLens GitHub](https://github.com/alienzhou/agentlens) | 上游仓库 |
| [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=vibe-x-ai.agentlens) | 扩展安装页 |
