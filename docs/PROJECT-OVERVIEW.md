# 项目综述与文档地图

Monorepo **是什么、模块怎么协作、文档去哪找**。新人 Day 1 后读本文建立全局认知。

---

## 1. 四个主入口 + 质量深读

| 文档 | 必读 | 说明 |
|------|:----:|------|
| **[GETTING-STARTED.md](GETTING-STARTED.md)** | Day 1 | 环境、首次构建、三条路径 |
| **[TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md)** | Week 1 | **日常手册**：Vibe Coding、架构十条、Pre-PR |
| **[AI-NATIVE-ENGINEERING.md](AI-NATIVE-ENGINEERING.md)** | Week 1 | 工具链、OpenSpec/Speckit、Cursor 规则 |
| **[PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)** | 按需 | **本文** — 结构与文档路由 |
| **[QUALITY-GATES.md](QUALITY-GATES.md)** | 按需 | CI、JaCoCo、单测分层（质量/DevOps 深读） |

> **Week 1 最小路径**：GETTING-STARTED → TEAM-PLAYBOOK → 按需查本文地图。

---

## 2. 仓库结构

```text
java-cursor-demo/
├── shared/                         # 脚本 + 共享专题
├── java-microservice-common/       # ① 公共组件
├── java-microservice-gateway/      # ② API 网关 :8080
└── java-microservice-scaffold/     # ③ 业务模板 :8081 + platform/
```

请求链路：浏览器 → gateway :8080 → skeleton :8081 → Nacos / MySQL / Kafka

技术栈：JDK 17 · Spring Boot 3.3.13 · Spring Cloud 2023.0.5 · Nacos · Gateway · Kafka · MyBatis Plus · MySQL 8.0 · Flyway · `Result(code, msg, data)`

---

## 3. 文档地图（按阶段）

### 工程规范与质量

| 文档 | 说明 |
|------|------|
| [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) | 日常闭环 + Pre-PR Checklist |
| [QUALITY-GATES.md](QUALITY-GATES.md) | CI / 覆盖率 / 单测（合并 CI-TOOLCHAIN + unit-testing） |
| [PULL-REQUEST-WORKFLOW.md](PULL-REQUEST-WORKFLOW.md) | PR 完整细则 |
| [AGENTLENS.md](AGENTLENS.md) | AgentLens：AI 代码占比统计（团队统一安装） |
| [CI-TOOLCHAIN.md](../shared/docs/CI-TOOLCHAIN.md) | → stub，见 QUALITY-GATES |
| [unit-testing.md](../java-microservice-scaffold/docs/unit-testing.md) | → stub，见 QUALITY-GATES |
| [SONARQUBE.md](../shared/docs/SONARQUBE.md) | → stub，见 QUALITY-GATES §5 |
| [shared/docs/README.md](../shared/docs/README.md) | shared 目录索引 |
| [engineering-standards.md](../java-microservice-scaffold/docs/engineering-standards.md) | Maven 日常操作 |
| [constitution.md](../java-microservice-scaffold/.specify/memory/constitution.md) | 技术宪法 |

### 开发与部署

| 文档 | 说明 |
|------|------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | 部署与 Jenkins |
| [PACKAGE-IDENTITY.md](../shared/docs/PACKAGE-IDENTITY.md) | 包路径配置（`shared/docs/` 唯一完整正文） |
| [SKELETON.md](../java-microservice-scaffold/docs/SKELETON.md) | 分层、创建新服务 |
| [microservice-zero-to-one.md](../java-microservice-scaffold/docs/microservice-zero-to-one.md) | macOS 0→1（可选） |

### Stub 索引（旧链接保留）

`shared/docs/README.md` 汇总全部重定向。  
CURSOR-IDE-SETUP · CURSOR-RULES · JAVA-CODEGEN · CI-TOOLCHAIN · SONARQUBE · MICROSERVICES · unit-testing → 均已指向 `docs/` 入口或 QUALITY-GATES

---

## 4. 按角色阅读路径

| 角色 | 建议顺序 |
|------|----------|
| **后端开发** | GETTING-STARTED → **TEAM-PLAYBOOK** → AI-NATIVE-ENGINEERING → SKELETON |
| **DevOps** | GETTING-STARTED → **QUALITY-GATES** → DEPLOYMENT → Jenkinsfile |
| **架构 / TL** | 本文 → constitution → PACKAGE-IDENTITY |
| **仅改 common** | GETTING-STARTED → common/README → common/docs/DEVELOPMENT.md |

---

## 5. 常见操作速查

| 目标 | 文档 |
|------|------|
| Vibe Coding → PR | [TEAM-PLAYBOOK](TEAM-PLAYBOOK.md) |
| 覆盖率 / CI 失败 | [QUALITY-GATES](QUALITY-GATES.md) |
| 改组织前缀 | [PACKAGE-IDENTITY](../shared/docs/PACKAGE-IDENTITY.md) |
| OpenSpec / Speckit | [AI-NATIVE-ENGINEERING](AI-NATIVE-ENGINEERING.md) |
