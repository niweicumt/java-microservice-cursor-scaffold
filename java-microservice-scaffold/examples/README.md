# 示例功能（非骨架运行时代码）

本目录存放**参考实现**的规格与设计文档，不参与 `mvn compile` 构建。

> **注意**：`001-user-management/` 为早期 Speckit 样例，文档中仍引用 JDK 8 / Spring Boot 2.7 等历史栈；**当前骨架**以 `.specify/memory/constitution.md` 为准（JDK 17 + Spring Boot 3.3.13）。

| 目录 | 说明 |
|------|------|
| [`001-user-management/`](001-user-management/) | 用户管理 CRUD 完整 Speckit 产物（spec / plan / tasks / OpenAPI），可作为新功能开发流程样例 |

从骨架创建新业务服务后，可在仓库根目录重新执行 Speckit 工作流，生成新的 `specs/<feature>/` 目录（见 [docs/SKELETON.md](../docs/SKELETON.md)）。
