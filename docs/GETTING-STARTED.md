# 新手入门指南

面向 **新加入团队的开发者**，按顺序完成环境搭建、首次构建与三条开发路径。  
项目全貌见 [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)；Week 1 日常开发见 **[TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md)**。

> **预计用时**：Day 1 约 1～2 小时（不含 Docker 全栈联调）。

---

## 1. 第一天 Checklist

- [ ] **1.1** 安装 JDK 17、Maven 3.9+、Git、Cursor
- [ ] **1.2** 克隆仓库并在 `java-microservice-common` 执行 `mvn clean install`
- [ ] **1.3** 在 gateway / scaffold 执行 `mvn clean test`（H2，无需 Docker）
- [ ] **1.4** 安装 SonarLint、AgentLens、Superpowers、OpenSpec（见 [AI-NATIVE-ENGINEERING §2](AI-NATIVE-ENGINEERING.md#2-工具链必装) · [AGENTLENS.md](AGENTLENS.md)）
- [ ] **1.5** 阅读 [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) 了解文档地图
- [ ] **1.6**（Week 1 必读）阅读 **[TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md)** — Vibe Coding 与 Pre-PR Checklist
- [ ] **1.7**（可选）Docker Compose MySQL 联调（见 [§5.2](#52-路径-b本地全栈联调)）

---

## 2. 环境要求

| 项 | 版本 / 说明 |
|----|-------------|
| **JDK** | 17 |
| **Maven** | 3.9+ |
| **Cursor** | 团队统一 IDE |
| **Node.js** | ≥ 20.19.0（OpenSpec） |
| **Docker** | 可选 |

```bash
java -version && mvn -version && node -v
```

---

## 3. 克隆与首次构建

```bash
git clone <repo-url> java-cursor-demo && cd java-cursor-demo
cd java-microservice-common && mvn clean install && cd ..
cd java-microservice-gateway && mvn clean test && cd ..
cd java-microservice-scaffold && mvn clean test
```

---

## 4. 仓库概览

三个 Maven 工程 + `shared/` 共享配置。详见 **[PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md)**。

---

## 5. 三条开发路径

### 5.1 路径 A：单元测试（Day 1 必做）

```bash
cd java-microservice-common && mvn clean install && cd ..
cd java-microservice-scaffold && mvn clean test
```

Profile 与覆盖率：[QUALITY-GATES.md](QUALITY-GATES.md)

### 5.2 路径 B：本地全栈联调

```bash
cd java-microservice-scaffold && ./platform/docker-compose/start-local.sh
mvn -pl skeleton-service spring-boot:run -Dspring-boot.run.profiles=dev
# 网关：cd ../java-microservice-gateway && mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

详见 [microservice-zero-to-one.md](../java-microservice-scaffold/docs/microservice-zero-to-one.md) · [DEPLOYMENT.md](DEPLOYMENT.md)

### 5.3 路径 C：AI 开发新功能

```text
/opsx-propose → /speckit.specify → /speckit.implement → Pre-PR Checklist → PR
```

详见 **[TEAM-PLAYBOOK.md §2](TEAM-PLAYBOOK.md#2-vibe-coding-闭环)** · [AI-NATIVE-ENGINEERING.md](AI-NATIVE-ENGINEERING.md)

---

## 6. 常见操作速查

| 目标 | 文档 |
|------|------|
| 日常开发 / 提 PR | [TEAM-PLAYBOOK.md](TEAM-PLAYBOOK.md) |
| CI / 覆盖率 | [QUALITY-GATES.md](QUALITY-GATES.md) |
| 文档索引 | [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) |
