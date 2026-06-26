# 团队日常开发手册

**在组同学唯一日常参考**：Vibe Coding 闭环、架构约束、Pre-PR Checklist、角色速查。  
Day 1 见 [GETTING-STARTED.md](GETTING-STARTED.md)；工具安装见 [AI-NATIVE-ENGINEERING.md](AI-NATIVE-ENGINEERING.md)；CI/覆盖率深读见 [QUALITY-GATES.md](QUALITY-GATES.md)。

---

## 目录

1. [业界实践对照](#1-业界实践对照)
2. [Vibe Coding 闭环](#2-vibe-coding-闭环)
3. [架构十条（必守）](#3-架构十条必守)
4. [Pre-PR Checklist](#4-pre-pr-checklist)
5. [角色速查](#5-角色速查)

---

## 1. 业界实践对照

| 业界 AI Native 实践 | 本团队落地 |
|---------------------|------------|
| **Spec-driven development** | OpenSpec `/opsx-*` |
| **AI guardrails** | `.cursor/rules/*.mdc` + [constitution](../java-microservice-scaffold/docs/constitution.md) |
| **Shift-left quality** | SonarLint 本地 + `mvn test` + JaCoCo 预 PR |
| **Trunk-based + PR gates** | `main` 保护 + Jenkins 阶段 1～4 |
| **Tests as contract for AI** | `auto.*` 代码 + `unit/auto/**/*Test` 同步提交 |

---

## 2. Vibe Coding 闭环

团队 **禁止** 无规格直接让 Agent 改生产代码（纯 docs 变更除外）。

```text
需求 / intent
    │
    ▼
/opsx-propose                         ← 写清边界与验收标准
    │   （可选 /opsx-explore）
    ▼
/opsx-apply                           ← 按 tasks 写代码 + 测试
    │
    ▼
本地门禁（§4 Checklist）               ← mvn test + jacoco + SonarLint
    │
    ▼
git push → Pull Request → CI 1～4 全绿
    │
    ▼
/opsx-sync → /opsx-archive            ← 合入后归档 OpenSpec change
```

| 变更类型 | 最低要求 |
|----------|----------|
| 业务功能 / Bug | OpenSpec change（`openspec/changes/`） |
| 纯文档 | `docs/<简述>` 分支 + PR，可跳过 OpenSpec |
| 改 common | 先 `mvn install`，再测依赖工程 |

命令与工具细节：[AI-NATIVE-ENGINEERING.md](AI-NATIVE-ENGINEERING.md)  
PR 完整细则：[PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md)

---

## 3. 架构十条（必守）

完整宪法：[constitution.md](../java-microservice-scaffold/docs/constitution.md)

| # | 约束 | 检查点 |
|---|------|--------|
| 1 | JDK 17 + Spring Boot 3.3.13 + Maven | pom 未擅自升级 |
| 2 | 四层分离：Controller → Service → Repository → Entity | 无 SQL/业务逻辑进 Controller |
| 3 | AI 代码在 `auto.*`；`custom.*` **禁止 AI 覆盖** | PR diff 包路径 |
| 4 | 统一返回 `Result<T>`；异常仅 `BusinessException` | 无裸实体、无吞异常 |
| 5 | MySQL 8.0 + Flyway 版本化迁移 | 不改已上线迁移文件 |
| 6 | 单测/CI 用 H2（`MODE=MySQL`） | 无 MySQL 专属语法进单测 |
| 7 | DTO：JSR 303 + `@Valid`；新字段非破坏 | OpenAPI 契约通过 |
| 8 | 日志 SLF4J + `{}`；禁 `System.out` | SonarLint S106 |
| 9 | 配置 Profile 切换；密钥不进 Git | 无 `application-local.yml` 提交 |
| 10 | 禁止 copy common 源码 | 仅 Maven 依赖 |

Review AI 大批量改动时，重点看：**集成测试 + OpenAPI 契约 diff + 覆盖率**。

---

## 4. Pre-PR Checklist

**全部勾选后再 push。**

### 4.1 规格与代码

- [ ] 非 trivial 变更已有 OpenSpec change
- [ ] AI 业务代码在 `auto.*`；人工扩展在 `custom.*`
- [ ] 未提交 `application-local.yml`、`.env`、密钥、`target/`

### 4.2 测试与覆盖率（强制）

- [ ] `mvn clean test` 全绿（H2，无需 MySQL）
- [ ] **新增/变更业务逻辑已附带单元测试**
- [ ] JaCoCo：核心业务行覆盖率 **≥ 80%**；Service **≥ 90%**
- [ ] 改 Controller/API 时已跑集成 + 契约测试

```bash
cd java-microservice-common && mvn clean install && cd ../java-microservice-scaffold

mvn clean test -Pci-unit-tests -pl skeleton-service -am
mvn jacoco:check -pl skeleton-service

# 改了 API 时
mvn test -Pci-integration-tests -pl skeleton-service -am
mvn test -Pcontract-tests -pl skeleton-service -am
```

### 4.3 质量与流程

- [ ] SonarLint 无新增 Blocker / Critical
- [ ] 分支命名符合规范（`feature/`、`fix/`、`docs/`…）
- [ ] PR 描述含 Test plan；至少 1 人 Approve 后合并

CI 阶段与本地复现：[QUALITY-GATES.md](QUALITY-GATES.md)

---

## 5. 角色速查

| 角色 | 日常阅读 | 遇到问题时 |
|------|----------|------------|
| **后端开发** | 本文 + [AI-NATIVE-ENGINEERING](AI-NATIVE-ENGINEERING.md) | [SKELETON](../java-microservice-scaffold/docs/SKELETON.md)、[QUALITY-GATES](QUALITY-GATES.md) |
| **DevOps** | [QUALITY-GATES](QUALITY-GATES.md) + [DEPLOYMENT](DEPLOYMENT.md) | `Jenkinsfile` |
| **TL / 架构** | [PROJECT-OVERVIEW](PROJECT-OVERVIEW.md) + constitution | [PACKAGE-IDENTITY](../shared/docs/PACKAGE-IDENTITY.md) |
| **新人 Week 1** | [GETTING-STARTED](GETTING-STARTED.md) → **本文** → [PROJECT-OVERVIEW](PROJECT-OVERVIEW.md) | 团队频道 |
