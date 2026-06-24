## Context

Monorepo 当前有约 20 篇面向人的 Markdown 文档，分布在 4 个目录层级。`README.md` 与 `docs/GETTING-STARTED.md` 均含仓库结构、快速开始、文档索引；AI 相关规范分散在 `CURSOR-IDE-SETUP.md`、`CURSOR-RULES.md`、`PULL-REQUEST-WORKFLOW.md` 及 `.cursor/rules/`。新人反馈「不知道从哪看起」；AI Agent 的 `specify-rules.mdc` 也列出 10+ 链接，权重相同。

已有 `GETTING-STARTED.md`（274 行）已具备 Day 1 Checklist 与路径编排雏形，可作为 onboarding 基底而非从零重写。

## Goals / Non-Goals

**Goals:**

- 3 个顶层入口：上手、综述地图、AI Native 工程化
- 消除 README ↔ GETTING-STARTED 重复；专题文档保留但由地图链入
- 旧 URL 通过 stub 保持可用；`.cursor/rules` 机器规则不变
- 全仓相对链接一致、可 grep 验证

**Non-Goals:**

- 不重写 `DEPLOYMENT.md`、`CI-TOOLCHAIN.md`、`microservice-zero-to-one.md` 等长篇专题
- 不合并 Speckit 模板、examples、constitution 到人类可读文档
- 不改变 CI、构建脚本或 Cursor 规则 `.mdc` 的约束内容
- 不引入文档站点生成器（MkDocs 等）——本次仅 Markdown 重组

## Decisions

### D1: 三文档信息架构（「3+专题」模型）

| 文档 | 职责 | 主要来源 |
|------|------|----------|
| `docs/GETTING-STARTED.md` | Day 1 动作：环境、构建、Checklist、三条路径 | 现有 GETTING-STARTED 精简 |
| `docs/PROJECT-OVERVIEW.md` | 是什么、模块关系、文档地图、按角色阅读 | README §结构 + GETTING-STARTED §4/§9/§10 |
| `docs/AI-NATIVE-ENGINEERING.md` | AI 团队怎么协作：工具、工作流、规则、PR、门禁 | CURSOR-IDE-SETUP + CURSOR-RULES + PULL-REQUEST-WORKFLOW 摘要 |

**理由**：与用户目标一一对应；GETTING-STARTED 已有良好结构，改动成本最低。  
**备选**：合并为 2 篇（上手+地图合一）—— rejected，地图会再次膨胀 onboarding。

### D2: Stub 而非直接删除源文档

对 `CURSOR-IDE-SETUP.md`、`CURSOR-RULES.md`、`PULL-REQUEST-WORKFLOW.md` 保留文件，顶部加 `> **已合并** → [AI-NATIVE-ENGINEERING.md](...)`，正文缩为 5～15 行索引。

**理由**：外部链接、Git 历史、IDE 书签不中断。  
**备选**：删除并重定向 HTTP（不适用，纯 Git 仓库）。

### D3: `MICROSERVICES.md` 合并进 `SKELETON.md`

两文均含模块速查与 `spring-boot:run` 命令，重复度高。将 MICROSERVICES 独特内容（若有）并入 SKELETON，MICROSERVICES 改为 stub 指向 SKELETON。

**理由**：减少 scaffold/docs 入口数量。  
**风险**：SKELETON 变长 → 在 PROJECT-OVERVIEW 中仍单列 SKELETON 为「创建新服务」专题。

### D4: 根 README 极简化

保留：标题、一句话、链到 3 入口、改组织前缀一行命令。移除：完整文档大表、重复 quick start 代码块。

### D5: `specify-rules.mdc` 三链结构

```text
新人入门 → GETTING-STARTED.md
项目地图 → PROJECT-OVERVIEW.md
AI 工程化 → AI-NATIVE-ENGINEERING.md
（其余专题仍保留单行链接，但排在三者之后）
```

Agent 仍需要 CI、PACKAGE-IDENTITY 等单行引用，不全部塞进 AI 文档。

### D6: 内容归属边界

| 留在专题、不并入 3 入口 | 原因 |
|-------------------------|------|
| DEPLOYMENT | 运维长文，按需阅读 |
| CI-TOOLCHAIN / SONARQUBE | 流水线细节，AI 文档只摘要+链接 |
| microservice-zero-to-one | 逐步截图级，Day 1 可选 |
| constitution / unit-testing / engineering-standards | Speckit / 工程细则，TL 与实现期查阅 |
| PACKAGE-IDENTITY | 配置操作手册 |

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 合并文档过长（尤其 AI-NATIVE-ENGINEERING） | 用目录锚点；详细步骤仍链出；目标 ≤ 350 行 |
| 全仓链接遗漏 | tasks 含 `rg` 检查清单；stub 兜底 |
| 双维护 stub 与主文档 | stub 仅保留重定向，禁止在 stub 写新内容 |
| SKELETON 合并后过长 | 只合并重复段落，模块 API 说明保留在 SKELETON 独立章节 |

## Migration Plan

1. 新建 `PROJECT-OVERVIEW.md`、`AI-NATIVE-ENGINEERING.md`（从现有文复制+编辑，非空白重写）
2. 精简 `GETTING-STARTED.md`、根 `README.md`
3. 源文档改 stub；合并 MICROSERVICES → SKELETON
4. 更新 `specify-rules.mdc`、子工程 README 索引
5. `rg` 全仓旧链接；修 broken links
6. 删除 `JAVA-CODEGEN-CONSTRAINTS.md`（已是单行 stub，可合并进 CURSOR-RULES stub）

**Rollback**：Git revert 单 commit；stub 文件恢复全文。

## Open Questions

- `engineering-standards.md` 是否与 `CI-TOOLCHAIN.md` 做进一步合并？**建议**：本次仅在 PROJECT-OVERVIEW 标注二者关系，不合并正文。
- `PULL-REQUEST-WORKFLOW.md` stub 后 PR 全文是否保留附录？**建议**：保留完整 PR 文于 stub 下方折叠或「详见 §X」链接，避免 AI 文档重复 360 行 PR 文。
