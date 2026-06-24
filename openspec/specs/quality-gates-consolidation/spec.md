# quality-gates-consolidation

## Purpose

定义质量与 CI 合并文档 `docs/QUALITY-GATES.md` 的结构与必含内容，统一 Maven、Profile、JaCoCo、SonarQube 与测试要求。

## Requirements

### Requirement: Consolidated quality gates document

The repository SHALL provide a consolidated quality and CI document at `docs/QUALITY-GATES.md` covering Maven build standards, Spring Profiles, JaCoCo coverage thresholds, SonarQube gates, Jenkins CI stages, and unit/integration/contract test requirements.

#### Scenario: Developer needs coverage rules

- **WHEN** a developer asks what coverage is required before merge
- **THEN** `docs/QUALITY-GATES.md` SHALL state thresholds (core business ≥ 80%, Service ≥ 90%) and link to JaCoCo report path without opening unit-testing.md separately

#### Scenario: CI stage failure

- **WHEN** a PR fails a CI check
- **THEN** QUALITY-GATES SHALL map each Jenkins stage (1–5) to local reproduction commands

### Requirement: Source document stub migration for quality topics

After consolidation, `shared/docs/CI-TOOLCHAIN.md`, `shared/docs/SONARQUBE.md`, and `java-microservice-scaffold/docs/unit-testing.md` SHALL become stubs redirecting to `docs/QUALITY-GATES.md` with section anchors.

#### Scenario: Old CI-TOOLCHAIN bookmark

- **WHEN** a user opens CI-TOOLCHAIN via an old link
- **THEN** they SHALL see an explicit redirect to QUALITY-GATES at the top of the file

### Requirement: Coverage mandatory for code changes

Documentation SHALL state that all code changes MUST include unit tests meeting team coverage thresholds before PR approval; AI-generated code in `auto.*` MUST sync unit tests in `unit/auto/**/*Test`.

#### Scenario: PR without tests

- **WHEN** a PR adds business logic without corresponding tests
- **THEN** QUALITY-GATES and TEAM-PLAYBOOK SHALL both state this blocks merge per CI stage 2
