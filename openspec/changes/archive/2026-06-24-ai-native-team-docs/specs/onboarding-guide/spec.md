## MODIFIED Requirements

### Requirement: Day 1 checklist completeness

`docs/GETTING-STARTED.md` SHALL include a numbered Day 1 checklist covering: JDK/Maven/Git/Cursor installation, first `mvn clean install` on common, first `mvn clean test` on gateway and scaffold, required IDE extensions, optional Docker full-stack path, and **a Week 1 item to read TEAM-PLAYBOOK**.

#### Scenario: Developer completes Day 1 without external guidance

- **WHEN** a developer follows only `docs/GETTING-STARTED.md` for Day 1
- **THEN** they SHALL be able to run unit tests successfully without MySQL or Docker and know which document to read next for vibe coding and quality gates (TEAM-PLAYBOOK)
