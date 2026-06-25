## ADDED Requirements

### Requirement: OpenSpec-driven vibe coding standard flow

The repository SHALL document a standard vibe coding workflow: `/opsx-propose` or `/opsx-explore` → `/opsx-apply` (or `/speckit.implement`) → local test + coverage → `/opsx-sync` → PR → `/opsx-archive`, enforced for non-trivial changes.

#### Scenario: Feature development with AI

- **WHEN** a developer uses Cursor Agent to implement a feature
- **THEN** TEAM-PLAYBOOK and AI-NATIVE-ENGINEERING SHALL require an OpenSpec change or Speckit spec to exist before `/opsx-apply` or `/speckit.implement` for production code paths

#### Scenario: Small doc-only change

- **WHEN** a change is documentation-only under `docs/`
- **THEN** the workflow MAY skip Speckit but SHALL still use a PR with `docs/` branch naming per PULL-REQUEST-WORKFLOW

### Requirement: Cursor as mandatory IDE with rules enforcement

Documentation SHALL state that Cursor is the team-standard IDE and `.cursor/rules/*.mdc` are mandatory guardrails; Superpowers skills (TDD, verification-before-completion) SHOULD be used alongside OpenSpec tasks.

#### Scenario: Developer uses alternative IDE

- **WHEN** a developer cannot use Cursor
- **THEN** documentation SHALL note they must manually run the same local quality gates and read CURSOR rules summaries in TEAM-PLAYBOOK

### Requirement: Industry alignment reference

AI-NATIVE-ENGINEERING or TEAM-PLAYBOOK SHALL include a brief mapping to industry AI Native practices: spec-driven development, shift-left quality, trunk-based development with PR gates, and tests-as-contract for AI output.

#### Scenario: Tech lead onboarding external hire

- **WHEN** a hire asks how this team compares to common AI-native setups
- **THEN** the industry alignment section SHALL map team tools (OpenSpec, Speckit, SonarLint, JaCoCo) to those practice names
