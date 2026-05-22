---
name: velocli-cloud
description: >
  VeloDB Cloud operational workflows using velocli CLI.
  Use for VeloDB Cloud setup, velocli auth, API host selection, warehouse/cluster
  context management, cluster pause/resume/reboot/create/delete/resize, billing
  queries, audit log inspection, public access policy, PrivateLink configuration,
  BYOC/SOCKS5 connectivity, password rotation, warehouse upgrade, and Cloud
  operations troubleshooting.
  Also triggers on: "connect to VeloDB Cloud", "set up velocli", "pause cluster",
  "resume cluster", "check billing", "resize to N vCPU", "configure public access",
  "set up PrivateLink", "rotate password", "upgrade warehouse", environment
  switching, stateless mode for CI, audit/infrastructure change investigation,
  "who changed cluster/network/warehouse settings", and any VeloDB Cloud
  infrastructure management.
  Does NOT handle query optimization or table design — those belong to
  velodb-best-practices.
---

# VeloCLI Cloud Operations

Operational workflows for VeloDB Cloud using `velocli`.

---

## Safety Policy

- Read-only Cloud discovery (warehouse ls, cluster ls, ctx, auth status, billing, audit) may run proactively
- Mutating operations (pause, resume, resize, create, delete, reboot, upgrade, password set, public-access changes, PrivateLink register/unregister) require explicit user confirmation before execution
- Before asking for confirmation, show the target resource, current state if known, requested change, and user impact (billing, downtime, connectivity, or credential rotation)
- The confirmation must be a clear question such as "Proceed with `<command>`?" Do not treat the user's initial request as confirmation
- Secret values (API keys, passwords) must stay in environment variables or user terminal — never output raw secrets

---

## Binary Detection

1. `VELOCLI_PATH` env var → use that binary
2. `command -v velocli` → use from PATH
3. `command -v sdbcli` → only for explicit SelectDB environments
4. If unavailable: do **not** stop at installation advice. Say commands cannot be executed in this environment, then still provide the full operational workflow, exact commands, confirmation gates, expected verification command, and install note. The user may have `velocli` elsewhere or may need the workflow as the deliverable.

---

## Core Workflows

### Onboarding (New Cloud Environment)

Read `references/onboarding.md` for the complete flow:
1. Select API host (sandbox / international / China)
2. `velocli auth add <name> --api-key $KEY --api-host <host> --mysql-password $PW`
3. `velocli auth status --format json` — verify API connectivity
4. Resolve warehouse/cluster context (may auto-pick or require `cloud use`)
5. `velocli sql "SELECT 1" --format json` — verify data-plane connectivity

### Context Management

Read `references/context.md` for warehouse→cluster hierarchy and resolution rules.

- Always show current context before changing: `velocli cloud ctx --format json`
- Use explicit `--env`, `--warehouse`, `--cluster` when ambiguity exists
- Switching warehouse clears cluster (old cluster may not belong to new warehouse)

### Cluster Lifecycle

Read `references/cluster-lifecycle.md` for pause/resume/resize/create/delete flows.

- Use `--wait` for user-facing workflows where completion feedback matters
- All writes are idempotent (auto-generated RequestId)
- Read-only: `cluster get`, `cluster ls`
- Mutating (confirm first): `pause`, `resume`, `reboot`, `resize`, `create`, `delete`
- If the binary is unavailable, still show: discovery command → confirmation question → mutation command → verification command. Do not bail out after "install velocli"

### Networking

Read `references/networking.md` for public access and PrivateLink.

- Read current state first: `velocli cloud public-access get`
- Confirm before any policy change

### Billing & Audit

Read `references/billing-and-audit.md` for cost queries and operational history.

- Billing summary for cost questions (supports hour/day/month granularity)
- Audit ls for incident timelines, "who changed it" questions, and infrastructure change tracking

### Troubleshooting

Read `references/troubleshooting.md` for common Cloud connection and configuration issues.

- For permission errors, distinguish read-only success from mutation failure and tell the user which operation likely needs elevated scope
- For API business-rule failures, do not retry the mutation blindly. Surface the API `code`, `message`, and `request_id`, then inspect current state with read-only commands

---

## Environment Switching

Multiple ways to select environment (highest → lowest precedence):
1. `--env <name>` flag (per-command)
2. `VELO_ENV` environment variable (per-session)
3. `velocli use <name>` (persistent)
4. fallback: `default`
