## MODIFIED Requirements

### Requirement: Staged document routing table

`docs/PROJECT-OVERVIEW.md` SHALL organize all human-facing documentation into staged categories including a **team playbook** entry as required reading for Week 1, with four primary entrances: GETTING-STARTED, PROJECT-OVERVIEW, AI-NATIVE-ENGINEERING, and TEAM-PLAYBOOK, plus QUALITY-GATES for CI/deep quality topics.

#### Scenario: Developer in first week

- **WHEN** a developer is in their first week
- **THEN** the routing table SHALL mark GETTING-STARTED, TEAM-PLAYBOOK, and AI-NATIVE-ENGINEERING as required and CI-TOOLCHAIN/unit-testing as redirected stubs to QUALITY-GATES

#### Scenario: Role-based reading paths

- **WHEN** a developer identifies as backend, DevOps, or tech lead
- **THEN** the document SHALL update reading orders to include TEAM-PLAYBOOK and QUALITY-GATES in appropriate positions
