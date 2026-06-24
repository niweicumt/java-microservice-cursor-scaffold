## ADDED Requirements

### Requirement: Team playbook document

The repository SHALL provide a unified team playbook at `docs/TEAM-PLAYBOOK.md` as the single daily reference for in-team developers covering vibe coding workflow, architecture constraints summary, quality gate checklist, and role-based quick paths.

#### Scenario: Developer starts a new task mid-sprint

- **WHEN** an in-team developer begins work on a feature or bugfix
- **THEN** `docs/TEAM-PLAYBOOK.md` SHALL provide the end-to-end loop from OpenSpec change to PR merge without reading CI-TOOLCHAIN, unit-testing, and PULL-REQUEST-WORKFLOW separately for basics

#### Scenario: New hire after Day 1

- **WHEN** a developer completes GETTING-STARTED Day 1 checklist
- **THEN** TEAM-PLAYBOOK SHALL be listed as the required Week 1 read in onboarding checklist

### Requirement: Architecture constraints human summary

`docs/TEAM-PLAYBOOK.md` SHALL include a concise summary of non-negotiable architecture rules (layering, auto/custom packages, Result pattern, MySQL/Flyway, forbidden SQL patterns) with a link to `java-microservice-scaffold/.specify/memory/constitution.md` for full detail.

#### Scenario: AI generates code outside constraints

- **WHEN** a developer reviews AI-generated code before PR
- **THEN** the playbook architecture section SHALL list the top violations to check (layer bleed, missing tests, custom package overwrite)

### Requirement: Pre-merge quality checklist in playbook

`docs/TEAM-PLAYBOOK.md` SHALL include a mandatory pre-PR checklist: `mvn clean test`, JaCoCo threshold met, SonarLint clean, OpenSpec/Speckit tasks complete, integration/contract tests when API changed.

#### Scenario: Developer prepares to push

- **WHEN** a developer is ready to create a pull request
- **THEN** the playbook checklist SHALL be copy-paste usable and match CI pipeline stages documented in QUALITY-GATES
