## MODIFIED Requirements

### Requirement: Consolidated AI-native engineering guide

The repository SHALL provide a consolidated AI-native engineering guide at `docs/AI-NATIVE-ENGINEERING.md` covering: required IDE tooling (SonarLint, Superpowers, OpenSpec CLI), OpenSpec and Speckit workflows, Cursor rules overview, Pull Request workflow summary, pre-commit quality gates (tests, SonarLint, coverage), **industry AI Native practice alignment**, and **cross-links to TEAM-PLAYBOOK and QUALITY-GATES** as the operational deep references.

#### Scenario: Developer starts AI-assisted feature

- **WHEN** a developer follows Path C from GETTING-STARTED
- **THEN** `docs/AI-NATIVE-ENGINEERING.md` SHALL link to `docs/TEAM-PLAYBOOK.md` for the daily vibe coding loop rather than duplicating the full loop inline

#### Scenario: specify-rules references AI guide

- **WHEN** Cursor loads `specify-rules.mdc`
- **THEN** AI workflow references SHALL include TEAM-PLAYBOOK as the daily handbook in addition to AI-NATIVE-ENGINEERING
