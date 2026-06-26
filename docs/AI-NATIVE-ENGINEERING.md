# AI Native 团队工程化规范

面向 **用 Cursor + AI Agent 协作开发**：必装工具、OpenSpec 工作流、Cursor 规则、业界实践对照。  
**日常开发闭环与 Pre-PR Checklist** → [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md)  
**CI / 覆盖率 / 单测深读** → [QUALITY-GATES.md](QUALITY-GATES.md)

Day 1：[GETTING-STARTED.md](GETTING-STARTED.md) · 文档地图：[PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)

---

## 目录

1. [业界 AI Native 实践](#1-业界-ai-native-实践)
2. [工具链必装](#2-工具链必装)
3. [OpenSpec 工作流](#3-openspec-工作流)
4. [Cursor 规则](#4-cursor-规则)

---

## 1. 业界 AI Native 实践

| 实践 | 本仓库 |
|------|--------|
| Spec-driven / Intent-first | OpenSpec（先规格后代码） |
| AI guardrails | `.cursor/rules/*.mdc` + constitution |
| Shift-left quality | SonarLint + 本地 `mvn test` + JaCoCo |
| Trunk-based + PR gates | `main` 保护 + Jenkins 1～4 |
| Tests as contract | 变更必须带达标单测才能合入 |

**分工**：本文讲 **用什么工具**；[TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) 讲 **每天怎么做**；[QUALITY-GATES.md](QUALITY-GATES.md) 讲 **门禁数值与 CI 阶段**。

---

## 2. 工具链必装

| # | 类型 | 名称 | 必装 |
|---|------|------|:----:|
| 1 | VS Code 扩展 | **SonarLint** | ✅ |
| 2 | Cursor 插件 | **Superpowers** | ✅ |
| 3 | CLI | **OpenSpec** | ✅ |

| 项 | 版本 |
|----|------|
| Cursor | 团队统一 IDE |
| JDK | 17 |
| Maven | 3.9+ |
| Node.js | ≥ 20.19.0 |

### SonarLint

```bash
"/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
  --install-extension SonarSource.sonarlint-vscode
```

详情：[QUALITY-GATES.md §5](QUALITY-GATES.md#5-sonarqube-与-sonarlint)

### Superpowers

Cursor Chat：`/add-plugin superpowers` · 更新：`/plugin update superpowers`

### OpenSpec CLI

```bash
npm install -g @fission-ai/openspec@latest
openspec --version
```

---

## 3. OpenSpec 工作流

| 项 | 说明 |
|----|------|
| **定位** | 变更级：提案 → 设计 → 任务 → 实施 → 归档 |
| **目录** | Monorepo 根 `openspec/changes/`、`openspec/specs/` |
| **命令** | `/opsx-propose` `/opsx-explore` `/opsx-apply` `/opsx-sync` `/opsx-archive` |

推荐流程（详见 [TEAM-PLAYBOOK §2](TEAM-PLAYBOOK.md#2-vibe-coding-闭环)）：

```text
/opsx-propose → /opsx-apply → 本地门禁 → PR → /opsx-sync → /opsx-archive
```

### 命令速查

| 阶段 | 命令 |
|------|------|
| 提案与探索 | `/opsx-propose` `/opsx-explore` |
| 实施 | `/opsx-apply` |
| 合入后 | `/opsx-sync` `/opsx-archive` |

Cursor Skills 位于 `.cursor/skills/openspec-*/`；斜杠命令位于 `.cursor/commands/opsx-*.md`。

---

## 4. Cursor 规则

源文件：[`.cursor/rules/`](../.cursor/rules/)（机器可读，自动加载）

| 文件 | 作用 |
|------|------|
| `specify-rules.mdc` | Monorepo 结构、文档索引 |
| `microservice-architecture.mdc` | 分层、H2/CI、SQL 禁止项 |
| `alibaba-java-standard.mdc` | 阿里规范 + DTO/Service/Result |

要点：`auto.*` 给 AI；`custom.*` 禁止 AI 覆盖；单测 H2；Service 覆盖率 ≥ 90%。

架构检查清单：[TEAM-PLAYBOOK §3](TEAM-PLAYBOOK.md#3-架构十条必守) · 完整宪法：[constitution.md](../java-microservice-scaffold/docs/constitution.md)

---

## 相关文档

| 文档 | 说明 |
|------|------|
| [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) | **日常手册**：Vibe Coding + Pre-PR |
| [QUALITY-GATES.md](QUALITY-GATES.md) | CI、JaCoCo、单测分层 |
| [PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md) | PR 完整细则 |
