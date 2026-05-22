---
title: Cluster Lifecycle Operations
tags: [cluster, pause, resume, resize, create, delete, lifecycle]
---

## Cluster Lifecycle Operations

### Execution Contract

- Start with read-only discovery (`cloud ctx`, `cluster ls`, `cluster get`) to identify the exact target
- For every mutation, show target name/id, current status, requested change, and impact before asking confirmation
- Ask an explicit confirmation question before running pause/resume/reboot/resize/create/delete/upgrade/password commands
- If `velocli` is unavailable in the current environment, still provide the workflow and exact commands. Do not stop at installation guidance
- After a submitted mutation, report `request_id` when present and verify final state with `cluster get` or `sql "SELECT 1"` as appropriate

### Discovery

```bash
velocli cloud warehouse ls --format json
velocli cloud warehouse ls --cloud-provider aws --region us-east-1
velocli cloud cluster ls --format json
velocli cloud cluster ls --status Running --cluster-type COMPUTE
velocli cloud cluster get --format json              # current cluster + connection_strings
velocli cloud cluster get <cluster-id> --private     # use private endpoint
```

`cluster get` returns: cluster metadata, endpoint (domain + ports), and connection_strings (mysql_cli, jdbc, http, stream_load).

### Pause / Resume / Reboot

```bash
velocli cloud cluster pause [<id>] [--wait]     # → Suspended
velocli cloud cluster resume [<id>] [--wait]    # → Running
velocli cloud cluster reboot [<id>] [--wait]    # → Running
```

- Confirm first. Pause/resume/reboot changes availability and may affect running jobs or downstream clients
- `--wait` blocks until terminal status (cadence: 1s → 2s → 5s → 10s; timeout 30 min, override with `--wait-timeout-secs N`)
- Without `--wait`: returns immediately with `{status, cluster_id, request_id}`
- Idempotent: repeated pause/resume/reboot is a no-op
- Every write auto-includes a `RequestId` UUID for retry safety

### Create (On-Demand)

```bash
velocli cloud cluster create <name> \
  --cluster-type SQL|COMPUTE|OBSERVER \
  --zone <zone> \
  --vcpu <N> \
  --cache-gb <N> \
  [--auto-pause --idle-timeout-minutes 15] \
  [--wait]
```

Confirm first. Both `--vcpu` and `--cache-gb` are required — they size and price the cluster.

### Resize

```bash
velocli cloud cluster resize [<id>] --vcpu 32 [--wait]
velocli cloud cluster resize [<id>] --cache-gb 1600 [--wait]
velocli cloud cluster resize [<id>] --auto-pause true --idle-timeout-minutes 5
```

Resize semantics:
- Confirm first. Resize affects billing and may change cache automatically
- Cache cannot be decreased
- vCPU resize may cause API to adjust cache automatically
- If `--vcpu` + `--cache-gb` together, cache must equal the API-implied value
- For custom CPU + cache: resize CPU first, then separate cache-only resize

### Delete

```bash
velocli cloud cluster delete <id> [--wait]
```

Confirm first. Do not retry a failed delete blindly. If the API rejects the request, surface `code`, `message`, and `request_id`, then inspect current state with `cluster get` / `cluster ls`.

### Warehouse Operations

```bash
velocli cloud warehouse get --format json
velocli cloud warehouse connections --format json    # all endpoints + connection strings
velocli cloud warehouse versions                     # upgrade targets
velocli cloud warehouse upgrade --to <version-id> --yes [--wait]
velocli cloud warehouse password set --new "$NEW_PW"
```

Confirm first. Warehouse upgrade is disruptive and password rotation affects all existing clients using the old MySQL password.

Password rotation: update stored MySQL password after rotation (`auth add` again or edit `~/.velodb/credentials.toml`).

### Subscription Note

Subscription billing (`--subscription-vcpu`, `--period`, `cluster renew/convert`) is not yet exposed in CLI. Manage subscription clusters via VeloDB Cloud console.
