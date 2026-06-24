## ADDED Requirements

### Requirement: Consolidated AI-native engineering guide

The repository SHALL provide a consolidated AI-native engineering guide at `docs/AI-NATIVE-ENGINEERING.md` covering: required IDE tooling (SonarLint, Superpowers, OpenSpec CLI), OpenSpec and Speckit workflows, Cursor rules overview, Pull Request workflow summary, and pre-commit quality gates (tests, SonarLint, coverage).

#### Scenario: Developer starts AI-assisted feature

- **WHEN** a developer follows Path C from GETTING-STARTED
- **THEN** `docs/AI-NATIVE-ENGINEERING.md` SHALL be sufficient to understand the full propose → specify → plan → implement → archive flow without opening 4+ separate docs

#### Scenario: specify-rules references AI guide

- **WHEN** Cursor loads `specify-rules.mdc`
- **THEN** AI workflow and engineering gate references SHALL point to `docs/AI-NATIVE-ENGINEERING.md` as the primary human-readable guide

### Requirement: Source document stub migration

After consolidation, the following source documents SHALL become stubs (title, one-paragraph redirect, link to `docs/AI-NATIVE-ENGINEERING.md` and relevant deep-dive): `shared/docs/CURSOR-IDE-SETUP.md`, `shared/docs/CURSOR-RULES.md`, `docs/PULL-REQUEST-WORKFLOW.md`.

#### Scenario: Old bookmark or external link

- **WHEN** a user opens a stubbed document via an old URL
- **THEN** they SHALL see an explicit redirect to the new consolidated guide and the relevant section anchor if applicable

#### Scenario: Deep-dive still available

- **WHEN** content is too long for the consolidated guide (e.g., full PR merge policies, Sonar Connected Mode steps)
- **THEN** the consolidated guide SHALL summarize requirements and link to the retained deep-dive document (`CI-TOOLCHAIN.md`, `SONARQUBE.md`, etc.)

### Requirement: Cursor rules remain machine-readable source of truth

Consolidating human-readable docs SHALL NOT remove or merge `.cursor/rules/*.mdc` files; `docs/AI-NATIVE-ENGINEERING.md` SHALL explain what each rule file does and link to `shared/docs/CURSOR-RULES.md` stub or inline summary.

#### Scenario: AI generates Java code

- **WHEN** Cursor applies `microservice-architecture.mdc` and `alibaba-java-standard.mdc`
- **THEN** behavior SHALL be unchanged; only human documentation routing changes

### Requirement: Engineering quality gate summary

`docs/AI-NATIVE-ENGINEERING.md` SHALL state mandatory pre-PR checks: `mvn clean test`, SonarLint with no new blockers, core business coverage ≥ 80%, and link to `shared/docs/CI-TOOLCHAIN.md` and `shared/docs/SONARQUBE.md` for CI pipeline details.

#### Scenario: Developer prepares pull request

- **WHEN** a developer reads the PR section of the AI-native guide
- **THEN** they SHALL find branch naming, review expectations, and a checklist without opening a separate PR doc for basics
