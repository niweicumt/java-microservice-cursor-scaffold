## 1. 新建 PROJECT-OVERVIEW.md

- [x] 1.1 创建 `docs/PROJECT-OVERVIEW.md`：Monorepo 目录树、请求链路图、技术栈摘要（来源：README §仓库结构 + GETTING-STARTED §4）
- [x] 1.2 编写分阶段文档路由表（新手 / 工程规范 / 开发部署 / 子工程 / AI 参考），替代 GETTING-STARTED §9 大表
- [x] 1.3 添加按角色阅读路径表（后端 / DevOps / TL），来源 GETTING-STARTED §10

## 2. 新建 AI-NATIVE-ENGINEERING.md

- [x] 2.1 创建 `docs/AI-NATIVE-ENGINEERING.md` 骨架：目录锚点（工具链、OpenSpec、Speckit、Cursor 规则、PR、质量门禁）
- [x] 2.2 迁入 IDE 必装清单与安装步骤摘要（来源：`shared/docs/CURSOR-IDE-SETUP.md` §1–§4）
- [x] 2.3 迁入 OpenSpec / Speckit 协作流程与推荐命令序列（来源：CURSOR-IDE-SETUP §1.2、GETTING-STARTED §5.3）
- [x] 2.4 迁入 Cursor 规则说明摘要（来源：`shared/docs/CURSOR-RULES.md`），保留 `.mdc` 为机器源
- [x] 2.5 迁入 PR 工作流摘要与提交前 Checklist（来源：`docs/PULL-REQUEST-WORKFLOW.md` 前半 + 门禁要点）
- [x] 2.6 添加质量门禁小节：链到 `CI-TOOLCHAIN.md`、`SONARQUBE.md`，写明 `mvn clean test`、覆盖率、SonarLint 要求

## 3. 精简 GETTING-STARTED.md

- [x] 3.1 保留 §1 Checklist、§2 环境、§3 首次构建、§5 三条路径；压缩 §4 仓库结构为 1 段 + 链到 PROJECT-OVERVIEW
- [x] 3.2 删除 §6 IDE 详情、§7 必守原则长文、§9 文档地图、§10 角色表（改为链到 PROJECT-OVERVIEW / AI-NATIVE-ENGINEERING）
- [x] 3.3 更新 §8 常见操作速查：PR / Sonar / AI 链到新入口
- [x] 3.4 验证精简后篇幅明显短于当前 274 行（现 125 行）

## 4. 精简根 README 与子工程 README

- [x] 4.1 根 `README.md`：保留定位 + 三入口链接 + 改前缀命令；删除重复 quick start 与文档大表
- [x] 4.2 `java-microservice-common/README.md`：文档索引改为链到 PROJECT-OVERVIEW
- [x] 4.3 `java-microservice-gateway/README.md`：同上
- [x] 4.4 `java-microservice-scaffold/README.md`：同上

## 5. 源文档 Stub 与去重

- [x] 5.1 `shared/docs/CURSOR-IDE-SETUP.md` → stub（重定向 AI-NATIVE-ENGINEERING §工具链）
- [x] 5.2 `shared/docs/CURSOR-RULES.md` → stub（重定向 AI-NATIVE-ENGINEERING §Cursor 规则）
- [x] 5.3 `docs/PULL-REQUEST-WORKFLOW.md` → 顶部 stub + 保留完整 PR 正文供深读（或链到 AI 文档摘要）
- [x] 5.4 合并 `java-microservice-scaffold/docs/MICROSERVICES.md` 独特内容到 `SKELETON.md`；MICROSERVICES 改 stub
- [x] 5.5 删除或 stub `shared/docs/JAVA-CODEGEN-CONSTRAINTS.md`（已合并进 alibaba-java-standard.mdc）

## 6. Cursor 规则与全仓链接

- [x] 6.1 更新 `.cursor/rules/specify-rules.mdc`：三入口优先，其余专题单行保留
- [x] 6.2 `rg` 全仓：`GETTING-STARTED.md`、`CURSOR-IDE-SETUP`、`PULL-REQUEST-WORKFLOW`、`MICROSERVICES` 等旧引用，修正为 PROJECT-OVERVIEW / AI-NATIVE-ENGINEERING
- [x] 6.3 检查 `shared/docs/CI-TOOLCHAIN.md` 等专题文档内的交叉链接是否仍有效

## 7. 验收

- [x] 7.1 新人路径演练：仅读 GETTING-STARTED 可完成 Day 1 单测
- [x] 7.2 地图路径：仅读 PROJECT-OVERVIEW 可找到任意专题文档
- [x] 7.3 AI 路径：仅读 AI-NATIVE-ENGINEERING 可理解 OpenSpec/Speckit/PR/门禁流程
- [x] 7.4 打开各 stub 文件，确认重定向可见且无 broken relative links
