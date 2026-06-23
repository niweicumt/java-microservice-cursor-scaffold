# Java 代码生成约束

> **已合并**：Cursor 规则与阿里规范统一为 [`.cursor/rules/alibaba-java-standard.mdc`](../../.cursor/rules/alibaba-java-standard.mdc)。  
> **简要说明**（给人阅读）：[`CURSOR-RULES.md`](CURSOR-RULES.md)

原 `java-codegen-constraints.mdc` 内容（DTO 校验、Service 分层、Result、H2、边界等）均已纳入上述规则，请勿再引用已删除的独立规则文件。

实现参考：

- `java-microservice-common/common-core` — `Result`、`BusinessException`
- `examples/001-user-management/` — 分页、校验、MyBatis-Plus 样例
- `docs/unit-testing.md` — 单测分层
