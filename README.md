# Java 微服务 Monorepo

三个独立 Maven 工程 + 共享配置，可从 0 到 1 搭建微服务体系。

---

## 文档入口

| 文档 | 说明 |
|------|------|
| **[docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)** | 新人 Day 1 |
| **[docs/TEAM-PLAYBOOK.md](docs/TEAM-PLAYBOOK.md)** | **日常手册** — Vibe Coding + Pre-PR |
| **[docs/AI-NATIVE-ENGINEERING.md](docs/AI-NATIVE-ENGINEERING.md)** | AI 工具链与 OpenSpec |
| **[docs/PROJECT-OVERVIEW.md](docs/PROJECT-OVERVIEW.md)** | 项目综述与文档地图 |
| **[docs/QUALITY-GATES.md](docs/QUALITY-GATES.md)** | CI / 覆盖率 / 单测门禁 |

---

## 修改组织前缀

```bash
./shared/scripts/configure-organization.sh --org com.tm
cd java-microservice-common && mvn clean install
cd ../java-microservice-scaffold && mvn clean test
```

详见 [shared/docs/PACKAGE-IDENTITY.md](shared/docs/PACKAGE-IDENTITY.md)。
