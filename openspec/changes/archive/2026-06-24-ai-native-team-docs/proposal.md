## Why

Phase 1 已建立三入口（GETTING-STARTED / PROJECT-OVERVIEW / AI-NATIVE-ENGINEERING），但工程规范仍分散在 `CI-TOOLCHAIN.md`、`unit-testing.md`、`engineering-standards.md`、`constitution.md` 等 10+ 篇专题中，新人与在组同学需在「上手 → AI 协作 → 质量门禁 → 架构约束 → 测试约定」之间反复横跳。团队约束明确：**Java + Cursor、OpenSpec 驱动 vibe coding、CI/CD 门禁、架构不可协商、变更必须带覆盖率单元测试才能合入** — 需要一份对齐业界 AI Native 产研实践的 **统一团队手册**，并将重复专题进一步合并为「入口 + 深读 stub」结构。

## What Changes

- 新建 **`docs/TEAM-PLAYBOOK.md`** — 团队唯一日常手册：Vibe Coding 闭环（OpenSpec → 实现 → 测试 → PR）、架构约束摘要、质量门禁 Checklist、角色速查；对齐业界 spec-driven + shift-left quality + trunk-based PR 模式
- 新建 **`docs/QUALITY-GATES.md`** — 合并 CI/CD、JaCoCo 覆盖率、单测分层、Sonar、Maven Profile 的 **强制门禁** 为一篇；`CI-TOOLCHAIN.md`、`unit-testing.md` 改为 stub 重定向
- 增强 **`docs/AI-NATIVE-ENGINEERING.md`** — 补充业界 AI Native 实践对照（spec-first、rules-as-guardrails、TDD with Agent），与 TEAM-PLAYBOOK 交叉引用，避免重复长文
- 精简 **`docs/PROJECT-OVERVIEW.md`** — 文档地图升级为「4 入口模型」（Day1 / 地图 / AI 工程化 / 团队手册），标注必读 vs 深读
- **`engineering-standards.md`** — Maven 操作细节保留，与 Profile/CI 重复段落 stub 化或删除，链到 QUALITY-GATES
- **`constitution.md`** — 保持 Speckit 机器源；在 TEAM-PLAYBOOK 增加人类可读「架构十条」，链到完整宪法
- 更新 **`.cursor/rules/specify-rules.mdc`** — 四入口 + 质量门禁单行引用
- **不改动** CI 流水线脚本、JaCoCo 阈值、pom 配置 — 仅文档重组与交叉链接；门禁数值与现有 Jenkinsfile 保持一致

## Capabilities

### New Capabilities

- `team-playbook`: 定义 TEAM-PLAYBOOK 的结构、Vibe Coding 闭环、角色速查及与 OpenSpec/Speckit 的衔接
- `quality-gates-consolidation`: 定义 QUALITY-GATES 合并范围、覆盖率/架构/CI 强制要求及源文档 stub 策略
- `vibe-coding-workflow`: 定义 OpenSpec 驱动的 vibe coding 标准流程（ propose → apply → test → PR ）及 Agent 约束

### Modified Capabilities

- `ai-native-engineering`: 补充业界 AI Native 实践对照，与 TEAM-PLAYBOOK 分工（工具链 vs 日常手册）
- `project-overview-map`: 更新为四入口文档路由与必读标记
- `onboarding-guide`: Day 1 Checklist 增加 TEAM-PLAYBOOK 首周阅读项，去除与手册重复的质量门禁长文

## Impact

- **文档**：`docs/` 新增 2 篇、改写 3 篇；`shared/docs/`、`java-microservice-scaffold/docs/` 若干 stub
- **OpenSpec specs**：3 个新 capability + 3 个 delta spec
- **Cursor 规则**：`specify-rules.mdc` 索引更新
- **无运行时变更**：构建、CI、测试阈值不变
