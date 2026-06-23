# Pull Request 工作流说明

本文档说明本 Monorepo 的 **分支策略、PR 创建、Code Review 与合并规范**。  
所有向 `main` 合入的变更须通过 Pull Request，**禁止**直接 push 到 `main`。

> **仓库地址**：https://github.com/niweicumt/java-microservice-cursor-scaffold  
> **CI 门禁详情**：[`shared/docs/CI-TOOLCHAIN.md`](../shared/docs/CI-TOOLCHAIN.md)  
> **新人环境搭建**：[`docs/GETTING-STARTED.md`](GETTING-STARTED.md)

---

## 1. 流程总览

```text
main（受保护，仅 PR 合入）
  │
  ├── feature/<issue>-<简述>     ← 新功能
  ├── fix/<issue>-<简述>         ← Bug 修复
  ├── refactor/<简述>            ← 重构（无行为变更）
  ├── docs/<简述>                ← 纯文档
  └── chore/<简述>               ← 工具链、依赖升级

开发者本地分支
    │
    ▼
本地预校验（mvn test + SonarLint）
    │
    ▼
git push ──► 创建 Pull Request（目标：main）
    │
    ▼
CI 门禁（Jenkins / GitHub Checks）阶段 1～4
    │
    ▼
至少 1 位 Reviewer Approve + 全部分析评论已解决
    │
    ▼
Squash Merge ──► main ──► （可选）部署流水线
```

---

## 2. 分支命名规范

| 类型 | 格式 | 示例 |
|------|------|------|
| 新功能 | `feature/<issue>-<kebab-case>` | `feature/42-user-login` |
| Bug 修复 | `fix/<issue>-<kebab-case>` | `fix/58-npe-on-empty-list` |
| 重构 | `refactor/<kebab-case>` | `refactor/extract-user-validator` |
| 文档 | `docs/<kebab-case>` | `docs/update-pr-workflow` |
| 工具 / 依赖 | `chore/<kebab-case>` | `chore/bump-spring-boot-patch` |
| 发布准备 | `release/<version>` | `release/1.2.0`（触发 CI 阶段 5 MySQL 全量测试） |

**约定**：

- 分支名使用 **小写 + 连字符**（kebab-case），不含空格
- 有关联 Issue / 任务单时，前缀带上编号便于追溯
- 一条 PR 只做 **一件事**；大功能拆成多个可独立 review 的小 PR

---

## 3. 标准工作流（逐步）

### 3.1 同步 main 并创建分支

```bash
git clone git@github.com:niweicumt/java-microservice-cursor-scaffold.git
cd java-microservice-cursor-scaffold

git checkout main
git pull origin main

git checkout -b feature/42-user-login
```

### 3.2 开发与本地预校验

按改动范围执行构建（**至少覆盖你改动的工程**）：

```bash
# 改了 common 时（其他工程依赖它，须先 install）
cd java-microservice-common && mvn clean install && cd ..

# 改了 gateway
cd java-microservice-gateway && mvn clean test && cd ..

# 改了 scaffold / skeleton-service（含 JaCoCo 门禁）
cd java-microservice-scaffold
mvn clean test -Pci-unit-tests -pl skeleton-service -am
mvn jacoco:check -pl skeleton-service

# 改了 Controller / API 时，建议加跑集成与契约
mvn test -Pci-integration-tests -pl skeleton-service -am
mvn test -Pcontract-tests -pl skeleton-service -am
```

**提交前 Checklist**：

- [ ] IDE SonarLint 无新增 Blocker / Critical
- [ ] 未提交 `application-local.yml`、`.env`、密钥或 `target/`
- [ ] 新增业务逻辑附带单元测试；覆盖率不低于团队门槛（≥ 80%）
- [ ] AI 生成代码在 `auto.*` 包；人工扩展在 `custom.*`
- [ ] 若改 OpenAPI / 对外接口，已确认契约测试通过或已 bump 版本

### 3.3 提交并推送

```bash
git add .
git status   # 再次确认无敏感文件

git commit -m "$(cat <<'EOF'
feat(skeleton): add user login API

Implement POST /api/v1/auth/login with JWT token response.
EOF
)"

git push -u origin feature/42-user-login
```

**Commit Message 格式**（Conventional Commits）：

```text
<type>(<scope>): <subject>

[optional body]
```

| type | 用途 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `refactor` | 重构（无功能变更） |
| `test` | 补测试 |
| `docs` | 文档 |
| `chore` | 构建、依赖、脚本 |
| `ci` | CI / Jenkins 配置 |

`scope` 常用值：`common`、`gateway`、`skeleton`、`shared`、`docs`。

### 3.4 创建 Pull Request

#### 方式 A：GitHub 网页

1. 打开 https://github.com/niweicumt/java-microservice-cursor-scaffold
2. push 后点击 **Compare & pull request**
3. **Base**：`main` ← **Compare**：你的功能分支
4. 填写标题与描述（见 [§4 PR 模板](#4-pr-描述模板)）
5. 指定 Reviewer，创建 PR

#### 方式 B：GitHub CLI

```bash
gh pr create --base main --head feature/42-user-login \
  --title "feat(skeleton): add user login API" \
  --body "$(cat <<'EOF'
## Summary
- Add POST /api/v1/auth/login endpoint
- Return JWT access token on successful authentication

## Test plan
- [x] mvn clean test -Pci-unit-tests -pl skeleton-service -am
- [x] mvn test -Pci-integration-tests -pl skeleton-service -am
- [ ] Manual: curl login with valid/invalid credentials

## Affected modules
- [ ] java-microservice-common
- [x] java-microservice-scaffold / skeleton-service
- [ ] java-microservice-gateway
EOF
)"
```

### 3.5 Code Review 与 CI

PR 创建后自动触发 CI（对齐 [`CI-TOOLCHAIN.md`](../shared/docs/CI-TOOLCHAIN.md) §5）：

| 阶段 | 内容 | 失败后果 |
|------|------|----------|
| 1 | SonarQube 质量扫描 | 阻断合并 |
| 2 | JUnit5 + JaCoCo 覆盖率 | 阻断合并 |
| 3 | Controller 集成测试 | 阻断合并 |
| 4 | OpenAPI 契约校验 | 阻断合并 |
| 5 | Testcontainers MySQL | 仅 `release/*` 分支 |

**Reviewer 职责**：

- 确认设计与 [`constitution.md`](../java-microservice-scaffold/.specify/memory/constitution.md) 一致
- 检查分层、异常处理、SQL 方言、DTO 兼容性
- 对 AI 大批量改动，重点看集成测试与契约 diff

**作者职责**：

- 逐条回复 Review 评论；讨论达成一致后 resolve thread
- CI 红时主动修复并 push；**不要** force push 到已有人 review 的分支（除非与 Reviewer 协商）

### 3.6 合并

满足以下 **全部** 条件方可合并：

- [ ] CI 阶段 1～4 全绿
- [ ] 至少 **1** 位 Reviewer **Approve**
- [ ] 无未解决的 Review 讨论
- [ ] PR 描述中的 Test plan 已勾选完成项

**合并方式**：默认 **Squash and merge**（保持 `main` 历史简洁，一条 PR 对应一个 commit）。

合并后：

```bash
git checkout main
git pull origin main
git branch -d feature/42-user-login        # 删除本地分支
git push origin --delete feature/42-user-login   # 可选：删除远程分支
```

---

## 4. PR 描述模板

创建 PR 时复制以下模板填写：

```markdown
## Summary
<!-- 1～3 条：做了什么、为什么做 -->

## Related
<!-- Issue / OpenSpec change / Speckit feature 链接（如有） -->
- Closes #42
- openspec/changes/add-user-login/

## Affected modules
<!-- 勾选实际改动的工程 -->
- [ ] java-microservice-common
- [ ] java-microservice-gateway
- [ ] java-microservice-scaffold / skeleton-service
- [ ] shared/ / docs/ / .cursor/
- [ ] Jenkinsfile / platform/

## Test plan
<!-- Reviewer 可按此复现 -->
- [ ] cd java-microservice-common && mvn clean install
- [ ] cd java-microservice-scaffold && mvn clean test -Pci-unit-tests -pl skeleton-service -am
- [ ] mvn test -Pci-integration-tests -pl skeleton-service -am
- [ ] mvn test -Pcontract-tests -pl skeleton-service -am
- [ ] （可选）本地 MySQL 联调步骤

## Breaking changes
<!-- 无则写 None -->
None

## Screenshots / logs
<!-- 可选：接口响应、JaCoCo 截图等 -->
```

---

## 5. Monorepo 专项说明

本仓库含 **三个独立 Maven 工程**，PR 时注意依赖顺序与影响面：

| 改动位置 | 额外要求 |
|----------|----------|
| `java-microservice-common` | 须 `mvn install`；若改 API 需评估对 gateway / scaffold 的兼容性；重大变更考虑 bump 版本号 |
| `java-microservice-gateway` | 确认路由 / Nacos 配置样例同步更新 |
| `java-microservice-scaffold` | 默认跑 skeleton-service 全套 CI profile |
| `shared/scripts/` | 在干净 clone 上试跑脚本；文档同步更新 |
| 仅 `docs/` | 可只跑 markdown 目检；仍须走 PR，CI 文档类变更通常较快 |

**禁止**：

- 将 `common` 源码 copy 到业务工程
- 在 PR 中提交 `target/`、本地 H2 数据、`application-local.yml`
- 跳过 CI 合入（`--no-verify`、强推覆盖 main 均不允许）

---

## 6. 与 AI 工作流的衔接

正式功能开发建议 **先规格、后 PR**：

```text
/opsx-propose 或 /speckit.specify
    → plan / tasks
    → /speckit.implement（在功能分支上）
    → 本地预校验
    → 创建 PR（描述中链接 openspec/changes/ 或 specs/<feature>/）
    → Review + CI
    → 合并后 /opsx-archive（OpenSpec 变更）
```

PR 描述中应链接对应的规格目录，便于 Reviewer 对照验收标准。

---

## 7. Reviewer Checklist

Review 时可按此清单检查：

- [ ] 变更范围与 PR 标题、Affected modules 一致
- [ ] 分层正确：`auto.*` / `custom.*`，无业务逻辑泄漏到 Controller
- [ ] 统一返回 `Result(code, msg, data)`；异常走 `BusinessException`
- [ ] SQL / Flyway 脚本兼容 H2（`MODE=MySQL`）与 MySQL 8.0
- [ ] 新增 API 有 OpenAPI 注解；契约测试已更新
- [ ] 测试 meaningful（非空断言）；Mock 使用合理
- [ ] 无硬编码密钥、无 `System.out`
- [ ] 文档与脚本变更与代码同步

---

## 8. 常见问题

### Q：CI 红了但我本地能通过？

1. 确认本地命令与 CI 一致（见 [`CI-TOOLCHAIN.md`](../shared/docs/CI-TOOLCHAIN.md) §5.4）
2. 检查是否改了 common 但未 `mvn install`
3. 查看 Jenkins / GitHub Checks 日志中的具体失败阶段

### Q：PR 太大不好 Review 怎么办？

按模块或层次拆分，例如：先 PR「数据模型 + Repository」，再 PR「Service + API」；每个 PR 独立通过 CI。

### Q：需要紧急 hotfix？

从 `main` 拉 `fix/` 分支，走同样 PR 流程；禁止直接 push `main`。合并后可 cherry-pick 到 `release/*`。

### Q：common 版本升级如何协调？

1. 在 common PR 中 bump 版本并 `deploy` / `install`
2. scaffold / gateway PR 更新 `microservice-common.version`
3. 两个 PR 可并行 review，但 **common 须先合并**

---

## 9. GitHub 仓库建议设置

仓库管理员可在 GitHub **Settings → Branches** 为 `main` 配置：

| 规则 | 建议 |
|------|------|
| Require a pull request before merging | ✅ |
| Require approvals | 1 |
| Require status checks to pass | Jenkins / CI 阶段 1～4 |
| Require conversation resolution | ✅ |
| Do not allow bypassing | ✅ |
| Allow squash merging | ✅（默认） |
| Allow merge commits / rebase | ❌（可选关闭，保持历史一致） |

---

## 10. 相关文档

| 文档 | 说明 |
|------|------|
| [docs/GETTING-STARTED.md](GETTING-STARTED.md) | 新人入门 |
| [shared/docs/CI-TOOLCHAIN.md](../shared/docs/CI-TOOLCHAIN.md) | CI 门禁阶段与本地模拟 |
| [shared/docs/SONARQUBE.md](../shared/docs/SONARQUBE.md) | 代码质量扫描 |
| [shared/docs/CURSOR-RULES.md](../shared/docs/CURSOR-RULES.md) | AI 代码规范 |
| [java-microservice-scaffold/docs/SKELETON.md](../java-microservice-scaffold/docs/SKELETON.md) | 分层与包结构 |
| [docs/DEPLOYMENT.md](DEPLOYMENT.md) | 合并后部署与 Jenkins |
| [Jenkinsfile](../Jenkinsfile) | CI 流水线定义 |
