## 1. 新建 TEAM-PLAYBOOK.md

- [x] 1.1 创建 `docs/TEAM-PLAYBOOK.md` 骨架：Vibe Coding 闭环、架构十条、Pre-PR Checklist、角色速查
- [x] 1.2 写入 OpenSpec 驱动闭环（propose → apply → test → PR → sync/archive），对齐 vibe-coding-workflow spec
- [x] 1.3 写入架构约束人类摘要（分层、auto/custom、Result、Flyway、H2 单测），链到 constitution.md
- [x] 1.4 写入 Pre-PR Checklist（mvn test、JaCoCo、SonarLint、集成/契约测试条件），与 Jenkins 阶段对齐
- [x] 1.5 添加业界 AI Native 实践对照表（spec-driven、shift-left、trunk+PR、tests-as-contract）

## 2. 新建 QUALITY-GATES.md

- [x] 2.1 创建 `docs/QUALITY-GATES.md`：Maven/JDK、Profile 表、JaCoCo 门槛、Sonar 摘要
- [x] 2.2 迁入 CI 流水线阶段 1–5 与本地复现命令（来源 CI-TOOLCHAIN.md）
- [x] 2.3 迁入单测分层、目录约定、覆盖率统计范围（来源 unit-testing.md）
- [x] 2.4 明确「代码变更必须带单元测试且覆盖率达标方可合入」强制表述
- [x] 2.5 链到 SONARQUBE.md、PULL-REQUEST-WORKFLOW.md、Jenkinsfile

## 3. 增强现有入口文档

- [x] 3.1 更新 `docs/AI-NATIVE-ENGINEERING.md`：业界对照 + 链到 TEAM-PLAYBOOK/QUALITY-GATES，去除与手册重复的 Pre-PR 长文
- [x] 3.2 更新 `docs/PROJECT-OVERVIEW.md`：四入口模型 + Week1 必读标记 + QUALITY-GATES 路由
- [x] 3.3 更新 `docs/GETTING-STARTED.md`：Checklist 增加 Week1 阅读 TEAM-PLAYBOOK

## 4. Stub 与去重

- [x] 4.1 `shared/docs/CI-TOOLCHAIN.md` → stub 重定向 QUALITY-GATES
- [x] 4.2 `java-microservice-scaffold/docs/unit-testing.md` → stub 重定向 QUALITY-GATES
- [x] 4.3 `engineering-standards.md`：删除与 QUALITY-GATES 重复的 Profile/测试段，顶部加链
- [x] 4.4 清理重复目录 `openspec/changes/consolidate-project-docs/`（Phase 1 已归档副本）

## 5. Cursor 规则与全仓链接

- [x] 5.1 更新 `.cursor/rules/specify-rules.mdc`：四入口 + QUALITY-GATES
- [x] 5.2 `rg` 全仓更新 CI-TOOLCHAIN、unit-testing 引用为 QUALITY-GATES / TEAM-PLAYBOOK
- [x] 5.3 更新子工程 README、DEPLOYMENT、PULL-REQUEST-WORKFLOW 相关文档索引

## 6. 验收

- [x] 6.1 新人 Week1：GETTING-STARTED → TEAM-PLAYBOOK 可独立完成首个 OpenSpec 变更 + 本地 test
- [x] 6.2 在组同学：仅读 TEAM-PLAYBOOK 可走完 vibe coding → PR Checklist
- [x] 6.3 质量专题：仅读 QUALITY-GATES 可理解覆盖率门槛与 CI 阶段
- [x] 6.4 各 stub 文件顶部重定向可见、无 broken relative links
