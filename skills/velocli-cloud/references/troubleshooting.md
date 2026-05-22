---
title: Cloud Operations Troubleshooting
tags: [troubleshooting, errors, debugging]
---

## Cloud Operations Troubleshooting

### "The API key is missing or invalid"

**Cause**: API key belongs to a different environment than `--api-host`.

**Fix**: Match key to correct host:
- Sandbox keys → `sandbox.velodb.io`
- International production keys → `api.velodb.cloud`
- China production keys → `api.selectdb.com`

**Verify**: `velocli auth status --env <name> --format json` — check `cloud_api_status`

### "Could not resolve MySQL host" / Data-plane unreachable

**Cause**: No current warehouse/cluster set, or cluster is stopped.

**Fix**:
```bash
velocli cloud ctx --env <name> --format json        # check context
velocli cloud warehouse ls --env <name>             # discover warehouses
velocli cloud cluster ls --env <name>               # discover clusters
velocli cloud use <warehouse>/<cluster> --env <name>
velocli cloud cluster resume <id> --wait            # if cluster is Suspended
```

### HTTP port misconfiguration

**Cause**: VeloDB Cloud uses port **8080**; self-hosted Apache Doris uses **8030**. Wrong port → `profile get` fails with confusing error.

**Fix**: `velocli auth status` shows `http_status` and `http_probe` results. If misconfigured, `auth add` probes 8080/8030/8040 and shows `http_port_suggestions`.

### MySQL works but `velocli sql` fails

**Debug**:
```bash
# Test direct mysql
mysql -h <host> -P 9030 -u admin -p"$PW" -e "SELECT 1"

# Test velocli
velocli auth status --env <name> --format json
velocli sql "SELECT 1" --env <name> --format json
```

If direct endpoint works but cloud mode fails, inspect endpoint resolution:
```bash
velocli cloud cluster get --env <name> --format json    # check endpoint domain
velocli cloud warehouse connections --env <name>        # full endpoint list
```

### BYOC / Private DNS not resolving

**Cause**: BYOC endpoint hostnames only resolve inside customer VPC.

**Fix**: Use SOCKS5 proxy through bastion:
```bash
velocli --socks5 admin:admin@127.0.0.1:10061 sql "SELECT 1"
```

Or env vars:
```bash
export VELO_SOCKS5_HOST=127.0.0.1
export VELO_SOCKS5_PORT=10061
```

### Cluster operation "already in target state"

**Not an error**: API treats repeated pause/resume/reboot as no-ops (idempotent). Response still includes `request_id` for tracking.

### Mutation rejected by Cloud API

**Do not retry blindly.** Surface the API `code`, `message`, and `request_id`, then inspect current state with read-only commands:

```bash
velocli cloud ctx --format json
velocli cloud cluster get <id> --format json
velocli cloud audit ls --contains "cluster" --size 5 --format json
```

Examples: deleting the last cluster in a warehouse, resizing to unsupported capacity, cache shrink rejected, or operation blocked by current lifecycle state.

### Permission denied on mutation

If read-only commands work but pause/resume/resize/delete fails, the API key likely lacks the mutation scope or role for that operation.

Use read-only verification first:

```bash
velocli auth status --format json
velocli cloud warehouse ls --format json
velocli cloud cluster get <id> --format json
```

Then ask an org admin for an API key/role that allows the specific operation. Do not work around permissions by trying unrelated mutation commands.

### Public-access changes produce Terraform drift

When comparing CLI with Terraform, keep network policy state in one tool. CLI sends requested operation immediately; Terraform may report drift if its local state expects previous policy.
