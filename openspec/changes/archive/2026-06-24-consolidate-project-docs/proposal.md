## Why

当前 Monorepo 文档分散在 `docs/`、`shared/docs/`、`java-microservice-scaffold/docs/` 及多个子工程 README 中，约 20+ 篇面向人的文档存在内容重叠（环境搭建、仓库结构、文档索引在 README 与 GETTING-STARTED 中重复出现）。新人难以判断「先看哪一篇、何时才需要深入专题」，AI Native 团队的工程化规范（OpenSpec / Speckit、Cursor 规则、PR 与 CI 门禁）也散落在 6 篇以上文档中。需要一次有目标的精简合并，形成 **3 个清晰入口**，其余文档降级为按需深读的专题。

## What Changes

- 确立 **3 篇顶层文档** 作为唯一主入口：
  1. **`docs/GETTING-STARTED.md`** — 新人 Day 1 上手（环境、首次构建、三条开发路径、Checklist）；去除与综述/规范重复的长篇内容，改为短链指向专题
  2. **`docs/PROJECT-OVERVIEW.md`**（新建）— 项目综述与文档地图（Monorepo 结构、请求链路、技术栈、按角色/阶段的文档路由表）
  3. **`docs/AI-NATIVE-ENGINEERING.md`**（新建）— AI Native 团队工程化规范（IDE 工具链、OpenSpec / Speckit 工作流、Cursor 规则、PR 流程、质量门禁）的合并版
- 精简 **根 README.md**：保留一句话定位 + 链到上述 3 篇入口，删除重复的文档索引大表与快速开始细节
- 合并/降级冗余文档：
  - `shared/docs/CURSOR-IDE-SETUP.md`、`shared/docs/CURSOR-RULES.md`、`docs/PULL-REQUEST-WORKFLOW.md` 的核心内容迁入 `AI-NATIVE-ENGINEERING.md`，原文件保留为 **stub**（简短说明 + 重定向链接），避免旧链接失效
  - `java-microservice-scaffold/docs/MICROSERVICES.md` 与 `SKELETON.md` 中重复的模块速查/启动命令合并到 `SKELETON.md`，`MICROSERVICES.md` 改为 stub 或删除（**BREAKING**：若删除需全仓链接更新）
  - `shared/docs/JAVA-CODEGEN-CONSTRAINTS.md` 已是 stub，确认删除或保留一行重定向
  - `engineering-standards.md` 中与 `CI-TOOLCHAIN.md` 重复的 Maven/Profile 说明：在 `AI-NATIVE-ENGINEERING.md` 或 `CI-TOOLCHAIN.md` 中只保留一处，另一处 stub
- 更新 **`.cursor/rules/specify-rules.mdc`** 中的文档索引，指向 3 个新入口
- 子工程 README（common / gateway / scaffold）保留模块级说明，但文档索引统一指向 `docs/PROJECT-OVERVIEW.md`
- **不合并** 以下专题（保持独立，由地图链入）：`DEPLOYMENT.md`、`CI-TOOLCHAIN.md`、`SONARQUBE.md`、`PACKAGE-IDENTITY.md`、`microservice-zero-to-one.md`、`constitution.md`、`unit-testing.md`、Speckit 示例与模板

## Capabilities

### New Capabilities

- `onboarding-guide`: 定义新人唯一上手文档的结构、必含 Checklist、三条开发路径及对外链规则
- `project-overview-map`: 定义项目综述文档的结构、文档路由表、角色阅读路径及与子工程 README 的衔接
- `ai-native-engineering`: 定义 AI Native 工程化合并文档的结构、必含规范章节、与 Cursor 规则 / OpenSpec / Speckit 的对应关系及 stub 迁移策略

### Modified Capabilities

（`openspec/specs/` 当前为空，无既有 capability 需 delta）

## Impact

- **文档**：`docs/`（新增 2 篇、改写 GETTING-STARTED）、`shared/docs/`（若干 stub）、`java-microservice-scaffold/docs/`（MICROSERVICES 等可能删除或 stub）、根 `README.md`、子工程 README 索引段
- **Cursor 规则**：`.cursor/rules/specify-rules.mdc` 文档链接更新
- **无代码 / API 变更**：纯文档重构；CI、构建、运行时行为不变
- **链接维护**：全仓 grep 旧路径并更新；Git 历史中旧链接通过 stub 保持可用
