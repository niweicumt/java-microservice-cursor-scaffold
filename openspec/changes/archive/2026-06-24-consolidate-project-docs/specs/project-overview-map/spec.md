## ADDED Requirements

### Requirement: Project overview document exists

The repository SHALL provide a project overview and documentation map at `docs/PROJECT-OVERVIEW.md` as the single source for repository structure, request flow, technology stack summary, and staged document routing.

#### Scenario: Developer needs big-picture understanding

- **WHEN** a developer asks "what is in this monorepo and where do I find X?"
- **THEN** `docs/PROJECT-OVERVIEW.md` SHALL answer without requiring them to read README, GETTING-STARTED, and multiple sub-project READMEs

#### Scenario: Root README references overview

- **WHEN** a developer reads the root README
- **THEN** the README SHALL link to `docs/PROJECT-OVERVIEW.md` for structure and document map (not duplicate the full map inline)

### Requirement: Staged document routing table

`docs/PROJECT-OVERVIEW.md` SHALL organize all human-facing documentation into staged categories: onboarding, engineering quality, development and deployment, sub-project READMEs, and AI / Speckit references — with one-line descriptions and relative links.

#### Scenario: Developer in first week

- **WHEN** a developer is in their first week
- **THEN** the routing table SHALL clearly mark which documents are required vs optional deep-dives

#### Scenario: Role-based reading paths

- **WHEN** a developer identifies as backend, DevOps, or tech lead
- **THEN** the document SHALL provide a suggested reading order table by role linking to existing topic documents

### Requirement: Architecture and request flow

`docs/PROJECT-OVERVIEW.md` SHALL include the monorepo directory tree (common / gateway / scaffold / shared), local request flow (browser → gateway :8080 → skeleton :8081 → Nacos/MySQL/Kafka), and a concise technology stack list.

#### Scenario: Onboarding defers architecture detail

- **WHEN** `docs/GETTING-STARTED.md` mentions repository structure
- **THEN** it SHALL use a brief summary plus link to `docs/PROJECT-OVERVIEW.md` for the full tree and diagram

### Requirement: Sub-project README index alignment

Each sub-project README (`java-microservice-common`, `java-microservice-gateway`, `java-microservice-scaffold`) SHALL replace its local document index section with a link to `docs/PROJECT-OVERVIEW.md` while retaining module-specific build and run instructions.

#### Scenario: Developer opens scaffold README

- **WHEN** a developer reads `java-microservice-scaffold/README.md`
- **THEN** module-specific commands remain present and the full monorepo doc map is not duplicated
