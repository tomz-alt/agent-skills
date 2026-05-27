# VeloDB Agent Skills

AI agent skills that teach Claude, Antigravity, Cursor, Windsurf, and other AI coding assistants how to design, diagnose, and operate Apache Doris / VeloDB systems.

## Three Skills, Clean Boundaries

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

### velodb-architecture-advisor — Design

Translates business requirements into VeloDB/Doris architecture designs. Covers workload classification, cluster sizing, data model selection (DUPLICATE / UNIQUE / AGGREGATE), ingestion strategy, and generates initial DDL.

**Triggers on**: "design a table for...", "how should I store...", "we have X devices sending data every Y seconds", "recommend a cluster size", "migrate from Impala/Kudu/ES/Greenplum/HBase/Hive to VeloDB", or any OLAP workload description.

**Includes**: 8 decision frameworks (sizing matrix, data model selection, ingestion strategy, time-series design, mutable state, query acceleration, deployment mode, workload classification) and 10 industry examples (IoT, log/observability, CDC, securities, retail, logistics, web3, payment, gaming, adtech).

### velodb-best-practices — Validate + Diagnose

37 DDL rules, 7 use case templates, pre-flight checklist, and CLI-based query investigation. Validates every CREATE TABLE before output and diagnoses slow queries using evidence from `velocli` or fallback SQL.

**Triggers on**: DDL review, slow query investigation, query profiling, tablet skew, "optimize this query", "review this CREATE TABLE", or any performance diagnosis.

**Includes**: Schema rules (model, partition, bucket, keys, types, indexes, MVs, properties, cache), DDL gotchas, use case templates (log/event, CDC, dashboard, point query, star schema, dimension, observability), sizing guides, getting-started guides, and CLI investigation workflow with evidence-first methodology.

### velocli-cloud — Operate

Operational workflows for VeloDB Cloud. Manages the full Cloud lifecycle without touching query optimization or table design.

**Triggers on**: "connect to VeloDB Cloud", "pause cluster", "check billing", "resize to N vCPU", "configure public access", "set up PrivateLink", "who changed the cluster settings", CI/CD setup, or any Cloud infrastructure management.

**Includes**: Onboarding (API key setup, host selection, context resolution), cluster lifecycle (pause/resume/resize/create/delete with confirmation gates), billing and audit queries, networking (public access, PrivateLink), troubleshooting (API host mismatch, missing context, HTTP port, permissions), and stateless/CI mode.

## Prerequisites

**Required:**
- An AI coding assistant (Claude Code, Cursor, Windsurf, Antigravity, Codex, Gemini CLI, Kiro, etc.)
- VeloDB Cloud account **or** self-hosted Apache Doris cluster

**Optional (for CLI-based diagnostics):**
- [Node.js](https://nodejs.org/) ≥ 16
- velocli CLI: `npm install -g @velodb/velocli`
- VeloDB Cloud API key — get one from your Cloud console:
  - https://www.velodb.cloud/organization/api-keys
- MySQL password (set during warehouse creation in the Cloud console)

**Connection info** is available in the Cloud console under each warehouse's **Connection Methods** page:

| Protocol | Default Port | Example |
|----------|-------------|---------|
| MySQL | 9030 | `mysql -h <host> -P 9030 -u admin -p` |
| JDBC | 9030 | `jdbc:mysql://<host>:9030/<db>?user=admin` |
| StreamLoad | 8080 | `http://<host>:8080` |
| MCP | 443 | `https://<slug>.<region>.aws.velodb.cloud/mcp` |

For self-hosted Apache Doris: check `fe.conf` for `mysql_service_port` (default 9030) and `http_port` (default 8030). VeloDB Cloud uses HTTP port **8080**.

## Install

### Via npx skills (recommended)
```bash
npx skills add velodb/agent-skills
npx skills add velodb/agent-skills -a claude-code -a antigravity  # specific agents
npx skills add velodb/agent-skills --list                         # list available skills
```

### Via install.sh
```bash
git clone https://github.com/velodb/agent-skills.git
cd agent-skills

./install.sh              # Interactive menu — auto-detects agents
./install.sh --all        # Install to all detected agents
./install.sh --claude     # Claude Code only
./install.sh --cursor     # Cursor only
./install.sh --path DIR   # Custom directory
./install.sh --velocli    # Install velocli CLI
./install.sh --prereqs    # Show prerequisites
```

The installer copies all three skills into each agent's skill directory. Run `./install.sh --help` for the full option list.

### Manual install
```bash
# Clone and symlink (or copy) into your agent's skills directory
git clone https://github.com/velodb/agent-skills.git
ln -s $(pwd)/agent-skills/skills/velodb-architecture-advisor ~/.claude/skills/
ln -s $(pwd)/agent-skills/skills/velodb-best-practices ~/.claude/skills/
ln -s $(pwd)/agent-skills/skills/velocli-cloud ~/.claude/skills/
```

### Install velocli CLI (optional)
```bash
npm install -g @velodb/velocli    # global install
npm install @velodb/velocli       # project-level install (use via npx)
```

Skills work without velocli — they fall back to SQL commands (`SHOW CREATE TABLE`, `EXPLAIN`, `SHOW DATA SKEW`, `SHOW COLUMN STATS`). But with velocli installed, the agent can run structured JSON diagnostics proactively.

## What's Included

```
skills/
├── velodb-architecture-advisor/
│   ├── SKILL.md                        # Workload → architecture workflow
│   └── references/
│       ├── decision-workload-classification.md
│       ├── decision-sizing-matrix.md
│       ├── decision-data-model-selection.md
│       ├── decision-ingestion-strategy.md
│       ├── decision-time-series-design.md
│       ├── decision-mutable-state.md
│       ├── decision-query-acceleration.md
│       ├── decision-deployment-mode.md
│       ├── example-iot-sensor-platform.md
│       ├── example-log-observability.md
│       ├── example-cdc-operational-sync.md
│       ├── example-securities-analytics.md
│       ├── example-retail-fashion.md
│       ├── example-logistics-courier.md
│       ├── example-web3-exchange.md
│       ├── example-payment-fintech.md
│       ├── example-gaming.md
│       └── example-adtech-marketing.md
│
├── velodb-best-practices/
│   ├── SKILL.md                        # 4-step design workflow + pre-flight checklist
│   ├── AGENTS.md                       # Compiled reference (all rules inline)
│   └── references/                     # 51 files
│       ├── cli-investigation.md        # Evidence-first query diagnosis
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
│       └── start-*.md                  # Getting started guides (2)
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
The best-practices skill does not guess. When a query is slow, it collects evidence (profile, tablet, EXPLAIN, column stats) before forming hypotheses. No DDL rewrites, materialized views, or tuning recommendations appear until at least one evidence source has been collected.

### Safety Gates
- **Read-only** CLI commands (profile get, tablet, auth status, billing, audit) run proactively
- **Expensive SQL** requires EXPLAIN first, then user confirmation before profiled execution
- **Cloud mutations** (pause, resize, delete, public-access, password) require explicit confirmation with target, current state, and impact shown
- **Secrets** stay in environment variables — never output in chat

### CLI Support (velocli)
When `velocli` is installed, the agent uses it for structured JSON diagnostics:
```bash
velocli profile get <query_id> --format json    # Full query profile
velocli tablet db.table --detail --format json   # Tablet distribution + skew
velocli profile diff <slow> <fast> --format json # Regression comparison
velocli profile history "pattern" --days 7       # Performance trend
velocli cloud cluster ls --format json           # Cluster discovery
velocli cloud billing summary --format json      # Cost breakdown
```

When `velocli` is unavailable, the agent falls back to SQL commands and provides the exact CLI commands for the user to run elsewhere.

## Supported Agents

| Agent | Config Dir | Flag |
|-------|-----------|------|
| Claude Code | `~/.claude/skills/` | `--claude` |
| Antigravity | `~/.gemini/antigravity/skills/` | `--antigravity` |
| Cursor | `~/.cursor/skills/` | `--cursor` |
| Windsurf | `~/.codeium/windsurf/skills/` | `--windsurf` |
| Codex | `~/.codex/skills/` | `--codex` |
| Gemini CLI | `~/.gemini-cli/skills/` | `--gemini` |
| Kiro | `~/.kiro/skills/` | `--kiro` |
| GitHub Copilot | `~/.github/copilot/skills/` | `--copilot` |

## License

Apache-2.0
