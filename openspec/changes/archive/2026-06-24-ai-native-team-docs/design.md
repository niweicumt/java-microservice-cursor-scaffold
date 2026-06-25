## Context

Phase 1（`consolidate-project-docs`，已归档）建立了三入口文档模型。当前仍有 **质量与工程专题分散** 的问题：`CI-TOOLCHAIN.md`（218 行）、`unit-testing.md`、`engineering-standards.md`（256 行）、`constitution.md`（165 行）与 `AI-NATIVE-ENGINEERING.md` 的 §5 质量门禁存在重叠。团队硬性约束：Java 17、Cursor、OpenSpec vibe coding、架构分层（`.cursor/rules` + constitution）、**变更必须带单元测试且覆盖率达标方可合入**（JaCoCo + Jenkins 阶段 2）。

业界 AI Native 产研团队常见模式（2024–2026）：

| 实践 | 本仓库对应 |
|------|------------|
| Spec-driven / Intent-first | OpenSpec `/opsx-*` + Speckit `/speckit.*` |
| AI guardrails | `.cursor/rules/*.mdc` + constitution |
| Shift-left quality | SonarLint 本地 + `mvn test` + JaCoCo 预 PR |
| Trunk-based + PR gates | `main` 保护 + Jenkins 阶段 1–4 |
| Tests as contract for AI | `auto.*` + `unit/auto/**/*Test` + 集成/契约测试 |

## Goals / Non-Goals

**Goals:**

- **4+1 文档模型**：Day1（GETTING-STARTED）→ 地图（PROJECT-OVERVIEW）→ AI 工具（AI-NATIVE-ENGINEERING）→ **日常手册（TEAM-PLAYBOOK）** → 质量深读（QUALITY-GATES）
- 在组同学 **一篇手册** 走完 vibe coding + 提 PR；新人 Week 1 读完即可独立开发
- 合并 CI/单测/门禁重复内容；stub 旧链接
- 文档表述与现有 Jenkinsfile、JaCoCo 阈值、constitution **一致**（不发明新门槛）

**Non-Goals:**

- 不修改 Jenkinsfile、pom JaCoCo 配置、Sonar 质量门数值
- 不重写 constitution（Speckit 源）或 `.mdc` 规则正文
- 不合并 DEPLOYMENT、microservice-zero-to-one、SKELETON 长篇操作手册
- 不引入新工具（GitHub Actions 替代 Jenkins 等）

## Decisions

### D1: 新增 TEAM-PLAYBOOK 而非继续膨胀 AI-NATIVE-ENGINEERING

| 文档 | 受众 | 内容 |
|------|------|------|
| AI-NATIVE-ENGINEERING | 工具安装 + OpenSpec/Speckit 说明 + 业界对照 | 「用什么、为什么」 |
| TEAM-PLAYBOOK | 日常开发全员 | 「怎么做」：闭环、架构检查、PR Checklist、角色速查 |
| QUALITY-GATES | 质量/DevOps 深读 | CI 阶段、Profile、JaCoCo、Sonar、测试分层 |

**理由**：AI-NATIVE-ENGINEERING 已 266 行；再把 CI 细则塞入会违背 Phase 1 精简目标。

### D2: QUALITY-GATES 合并 CI-TOOLCHAIN + unit-testing

- **迁入**：Profile 表、JaCoCo 门槛、CI 阶段 1–5、测试分层、本地复现命令
- **保留链出**：SONARQUBE.md（Connected Mode 细节）、engineering-standards.md（Maven 日常操作，去重 Profile 段）
- **Stub**：CI-TOOLCHAIN.md、unit-testing.md

### D3: Vibe Coding 标准闭环（文档化）

```text
需求/intent
  → /opsx-propose（或 /speckit.specify 功能级）
  → /opsx-apply 或 /speckit.implement
  → mvn test + jacoco:check + SonarLint
  → PR（CI 1–4）
  → /opsx-sync + /opsx-archive
```

非 trivial 代码变更 **必须有** OpenSpec change 或 Speckit spec；纯 docs 变更可仅 PR。

### D4: 架构约束双层

- **TEAM-PLAYBOOK**：10 条人类可读检查项（分层、auto/custom、Result、Flyway、禁 MySQL 专属语法于 H2 测试）
- **constitution.md**：Speckit 完整宪法，不改动

### D5: specify-rules.mdc 四入口

```text
GETTING-STARTED → PROJECT-OVERVIEW → AI-NATIVE-ENGINEERING → TEAM-PLAYBOOK
QUALITY-GATES（单行）
```

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 4 入口仍偏多 | PROJECT-OVERVIEW 明确「Week1 只读 3 篇」路径 |
| QUALITY-GATES 过长 | 目录 + 锚点；Sonar 细节链出 |
| 与 Phase 1 文档冲突 | 增量修改，不删除三入口 |
| 清理遗留 `openspec/changes/consolidate-project-docs/` | tasks 含删除重复未归档目录 |

## Migration Plan

1. 新建 TEAM-PLAYBOOK.md、QUALITY-GATES.md
2. 更新 AI-NATIVE-ENGINEERING（业界对照 + 交叉链）
3. 更新 PROJECT-OVERVIEW、GETTING-STARTED
4. Stub CI-TOOLCHAIN、unit-testing；engineering-standards 去重
5. 更新 specify-rules.mdc；全仓链接 grep
6. 删除重复 `openspec/changes/consolidate-project-docs/`（若存在）

## Open Questions

- `engineering-standards.md` 是否整体 stub？**建议**：保留 Maven 操作章节，Profile/测试段 stub 指向 QUALITY-GATES。
- PR 工作流是否并入 TEAM-PLAYBOOK？**建议**：Playbook 保留摘要 Checklist，PULL-REQUEST-WORKFLOW 保持完整细则 + stub 顶链。
