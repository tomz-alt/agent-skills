# VeloDB Agent Skills

AI agent skills that teach Claude, Antigravity, Cursor, Windsurf, and other AI coding assistants how to design, diagnose, and operate Apache Doris / VeloDB systems.

## Three Skills, Clean Boundaries

| Skill | Domain | What It Does |
|-------|--------|-------------|
| **velodb-architecture-advisor** | Design | Workload classification, sizing, data model selection, architecture patterns, and initial DDL templates |
| **velodb-best-practices** | Validate + Diagnose | 37 DDL rules, 7 use case templates, pre-flight checklist, CLI-based query investigation, profile/tablet interpretation, and fix recommendations |
| **velocli-cloud** | Operate | Cloud onboarding, warehouse/cluster context, cluster lifecycle (pause/resume/resize/create/delete), billing, audit, public access, PrivateLink, and troubleshooting |

```
User prompt
    │
    ▼
┌──────────────────────────┐   ┌──────────────────────────┐   ┌──────────────────────────┐
│ velodb-architecture-     │   │ velodb-best-practices    │   │ velocli-cloud            │
│ advisor                  │   │                          │   │                          │
│                          │   │ Pre-Flight Checklist     │   │ Cloud onboarding         │
│ 1. Classify workload     │   │ 5 DDL Templates (T1-T5)  │   │ Cluster lifecycle        │
│ 2. Size cluster          │   │ 37 rule files            │   │ Billing & audit          │
│ 3. Design architecture   │   │ CLI investigation        │   │ Networking & security    │
│ 4. Generate DDL       ──►│   │  (profile/tablet/EXPLAIN)│   │ Troubleshooting          │
│                          │   │ Diagnostic hypotheses    │   │ Stateless / CI mode      │
└──────────────────────────┘   └──────────────────────────┘   └──────────────────────────┘
   Design                         Validate + Diagnose             Operate
```

## Install

### Via npx skills (recommended)
```bash
# Install all skills
npx skills add velodb/agent-skills

# Install to specific agents
npx skills add velodb/agent-skills -a claude-code -a antigravity

# List available skills first
npx skills add velodb/agent-skills --list
```

### Manual install
```bash
git clone https://github.com/velodb/agent-skills.git
cd agent-skills
./skills/velodb-best-practices/install.sh
```

## What's Included

```
skills/
├── velodb-architecture-advisor/
│   ├── SKILL.md                        # Workload → architecture workflow
│   └── references/
│       ├── decision-*.md               # 8 decision frameworks (sizing, data model, ingestion, etc.)
│       └── example-*.md                # 10 industry examples (IoT, retail, securities, etc.)
│
├── velodb-best-practices/
│   ├── SKILL.md                        # 4-step design workflow + pre-flight checklist
│   ├── AGENTS.md                       # Compiled reference (all rules inline)
│   └── references/
│       ├── cli-investigation.md        # Evidence-first query diagnosis with velocli
│       ├── schema-model-*.md           # Data model rules (4)
│       ├── schema-partition-*.md       # Partition rules (4)
│       ├── schema-bucket-*.md          # Bucket rules (5)
│       ├── schema-keys-*.md            # Sort key rules (5)
│       ├── schema-types-*.md           # Data type rules (5)
│       ├── schema-index-*.md           # Index rules (7)
│       ├── schema-mv-*.md              # Materialized view rules (3)
│       ├── schema-props-*.md           # Table properties (2)
│       ├── schema-cache-*.md           # Cache rules (2)
│       ├── schema-ddl-gotchas.md       # DDL syntax pitfalls
│       ├── usecase-*.md                # Use case templates (7)
│       ├── sizing-*.md                 # Cluster sizing guides (4)
│       └── start-*.md                  # Getting started (2)
│
└── velocli-cloud/
    ├── SKILL.md                        # Cloud operations workflow + safety policy
    └── references/
        ├── onboarding.md               # API key, auth, connection setup
        ├── context.md                  # Warehouse → cluster hierarchy
        ├── cluster-lifecycle.md        # Pause/resume/resize/create/delete
        ├── networking.md               # Public access, PrivateLink
        ├── billing-and-audit.md        # Cost queries, audit trails
        └── troubleshooting.md          # Common Cloud errors + fixes
```

## Key Design Principles

### Evidence-First Diagnosis
The best-practices skill does not guess. When a query is slow, it collects evidence (profile, tablet, EXPLAIN, column stats) before forming hypotheses. Fixes come after evidence, not before.

### Safety Gates
- Read-only CLI commands run proactively
- Expensive SQL requires EXPLAIN first, then user confirmation
- Cloud mutations (pause, resize, delete, public-access) require explicit confirmation with impact shown
- Secrets stay in environment variables, never in chat

### CLI Support (velocli)
When `velocli` is installed, the agent uses it for structured JSON diagnostics:
```bash
velocli profile get <query_id> --format json    # Full query profile
velocli tablet db.table --detail --format json   # Tablet distribution + skew
velocli profile diff <slow> <fast> --format json # Regression comparison
velocli cloud cluster ls --format json           # Cluster discovery
```

When `velocli` is unavailable, the agent falls back to SQL commands (`SHOW CREATE TABLE`, `EXPLAIN`, `SHOW DATA SKEW`, `SHOW COLUMN STATS`) and provides exact CLI commands for the user to run.

Install velocli: `npm install -g @velodb/velocli`

## Supported Agents

| Agent | Config Dir |
|-------|-----------|
| Antigravity | `.agents/skills/` |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| Windsurf | `.windsurf/skills/` |
| Kimi Code | `.kiro/skills/` |
| Gemini CLI | `.gemini/skills/` |

## License

Apache-2.0
