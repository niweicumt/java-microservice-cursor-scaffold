# onboarding-guide

## Purpose

定义 Monorepo 新人唯一上手文档 `docs/GETTING-STARTED.md` 的结构与必含内容。

## Requirements

### Requirement: Single onboarding entry document

The repository SHALL provide exactly one primary onboarding document at `docs/GETTING-STARTED.md` that new developers MUST be directed to from the root README and `.cursor/rules/specify-rules.mdc`.

#### Scenario: New developer opens repository

- **WHEN** a new developer clones the repository and reads the root README
- **THEN** the README SHALL link to `docs/GETTING-STARTED.md` as the first recommended document

#### Scenario: Cursor agent loads project rules

- **WHEN** Cursor loads `specify-rules.mdc` with alwaysApply enabled
- **THEN** the rules SHALL reference `docs/GETTING-STARTED.md` as the onboarding entry (not a list of 5+ equally weighted docs)

### Requirement: Day 1 checklist completeness

`docs/GETTING-STARTED.md` SHALL include a numbered Day 1 checklist covering: JDK/Maven/Git/Cursor installation, first `mvn clean install` on common, first `mvn clean test` on gateway and scaffold, required IDE extensions, optional Docker full-stack path, and **a Week 1 item to read TEAM-PLAYBOOK**.

#### Scenario: Developer completes Day 1 without external guidance

- **WHEN** a developer follows only `docs/GETTING-STARTED.md` for Day 1
- **THEN** they SHALL be able to run unit tests successfully without MySQL or Docker and know which document to read next for vibe coding and quality gates (TEAM-PLAYBOOK)

#### Scenario: Developer needs full-stack local debug

- **WHEN** a developer completes the optional checklist item for Docker
- **THEN** the document SHALL link to the dedicated deployment or zero-to-one guide rather than inlining full deployment steps

### Requirement: Three development paths

`docs/GETTING-STARTED.md` SHALL describe three distinct paths: (A) unit tests only, (B) local full-stack with MySQL, (C) AI-assisted feature development — each with commands and a link to the deep-dive document.

#### Scenario: Backend developer chooses test-only path

- **WHEN** a developer selects Path A
- **THEN** the document SHALL provide copy-paste commands and link to `docs/QUALITY-GATES.md` for Profile details

#### Scenario: Developer starts AI feature work

- **WHEN** a developer selects Path C
- **THEN** the document SHALL link to `docs/AI-NATIVE-ENGINEERING.md` for the full OpenSpec workflow (not duplicate that content inline)

### Requirement: No duplicate project overview in onboarding

`docs/GETTING-STARTED.md` SHALL NOT contain a full document map table or exhaustive repository architecture diagram; it SHALL link to `docs/PROJECT-OVERVIEW.md` for those sections.

#### Scenario: Onboarding doc length control

- **WHEN** the consolidated onboarding document is published
- **THEN** it SHALL be shorter than the pre-consolidation version by removing duplicated content now owned by PROJECT-OVERVIEW or AI-NATIVE-ENGINEERING
