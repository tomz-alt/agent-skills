---
title: Cloud Context Management
tags: [context, warehouse, cluster, routing]
---

## Cloud Context Management

### Hierarchy

```
Organization
  └── Warehouse (deployment unit: region, provider, engine version)
        └── Cluster (compute unit: SQL, COMPUTE, or OBSERVER type)
```

A warehouse has one or more clusters. Data-plane commands (`sql`, `tablet`, `profile`) route to the current cluster's MySQL endpoint.

### Set Context

```bash
velocli cloud use <warehouse-id>              # set warehouse, clear cluster
velocli cloud use <warehouse-id>/<cluster-id> # set both
velocli cloud use /<cluster-id>               # set cluster within current warehouse
velocli cloud ctx --format json               # inspect current context
```

Switching warehouse clears `current_cluster` because the old cluster may belong to a different warehouse.

### Resolution Precedence

For any cluster-scoped command, target resolves in this order:

1. Positional ID on the command (e.g., `cluster pause c-other`)
2. `--cluster <id>` / `--warehouse <id>` flags
3. `VELO_CURRENT_CLUSTER` / `VELO_CURRENT_WAREHOUSE` env vars
4. Stored `current_cluster` / `current_warehouse` in the env config
5. Error with exact fix command

### Data-Plane Auto-Routing

When `env_type=cloud` and `current_cluster` is set:
- `velocli sql` / `tablet` / `profile` resolve the cluster's MySQL endpoint automatically
- COMPUTE clusters get `USE @<cluster-name>` at session start
- SQL/meta clusters use the server's default compute group (no `USE @` emitted)

### Per-Command Override

Override without switching persistent context:

```bash
velocli sql "SELECT 1" --cluster c-other
velocli tablet db.table --warehouse other-wh --cluster c-xyz
```

### Environment Switching

```bash
velocli use              # show current + list all
velocli use prod         # switch default (persists)
velocli sql "..." --env dev   # per-command override
export VELO_ENV=staging       # per-session override
```
