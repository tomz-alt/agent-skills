---
title: Cloud Onboarding
tags: [auth, setup, connection, api-key, cloud]
---

## Cloud Onboarding

### Where to Find Your Credentials

If the user doesn't have credentials yet, guide them to the right place:

**VeloDB Cloud API key:**
- Go to the VeloDB Cloud console → Organization → API Keys
- `https://www.velodb.cloud/organization/api-keys`
- Copy the API key (starts with `sk-`). Store it in an env var, not in chat

**MySQL password:**
- Set during warehouse creation in the VeloDB Cloud console
- If forgotten, rotate via: `velocli cloud warehouse password set --new "$NEW_PW"` (or via console)

**Host, port, and connection strings (VeloDB Cloud):**
- Open the warehouse in the VeloDB Cloud console → Connection Methods
- The console shows ready-to-copy connection details:
  - **MySQL CLI**: `mysql -h <host> -P 9030 -u admin -p<Password>`
  - **JDBC**: `jdbc:mysql://<host>:9030/<Database>?user=admin&password=<Password>`
  - **StreamLoad**: `http://<host>:8080`
  - **MCP**: `https://<warehouse-slug>.<region>.aws.velodb.cloud/mcp`
- Alternatively, `velocli cloud cluster get --format json` returns `connection_strings` with all of these once auth is configured

**Host and port (self-hosted / Apache Doris):**
- **MySQL host + port**: the FE node address and MySQL protocol port (default 9030)
- **HTTP port**: FE HTTP port — 8080 for VeloDB Cloud, 8030 for self-hosted Apache Doris
- Ask your DBA or check `fe.conf` → `mysql_service_port` and `http_port`
- If unsure which HTTP port: `velocli auth add` probes 8080/8030/8040 automatically and shows `http_port_suggestions`

### Step 1: Select API Host

API keys are scoped to the control-plane environment that issued them. A key from one environment fails on another with "The API key is missing or invalid."

| Environment | `--api-host` value | Use for |
|---|---|---|
| Sandbox | `sandbox.velodb.io` | Sandbox/test API keys |
| International production | `api.velodb.cloud` | VeloDB Cloud international-site keys |
| China production | `api.selectdb.com` | SelectDB Cloud China-site keys |

### Step 2: Auth Add

Keep secrets in environment variables:

```bash
export VELO_CLOUD_API_KEY='sk-...'
export VELO_MYSQL_PASSWORD='<mysql-password>'
```

Create the environment:

```bash
velocli auth add <name> \
  --api-key "$VELO_CLOUD_API_KEY" \
  --api-host <host> \
  --mysql-password "$VELO_MYSQL_PASSWORD"
```

### Step 3: Check Auto-Pick Result

`auth add` auto-discovers warehouses/clusters. The `context_pick` field indicates what happened:

| `context_pick` value | Meaning | Next step |
|---|---|---|
| `auto_picked` | Both warehouse and cluster set | Ready — `velocli sql "SELECT 1"` |
| `multiple_warehouses` | Multiple warehouses, none picked | `velocli cloud use <warehouse-id>` |
| `warehouse_set_multiple_clusters` | Warehouse set, multiple clusters | `velocli cloud use /<cluster-id>` |
| `warehouse_set_no_clusters` | Warehouse set, no running clusters | Resume or create a cluster |
| `no_warehouses` | No warehouses in org | Create warehouse via console |
| `api_error: ...` | API key or network issue | Check API host and key validity |

### Step 4: Verify

```bash
velocli auth status --format json    # Control-plane + data-plane probe
velocli cloud ctx --format json      # Current environment, warehouse, cluster
velocli sql "SELECT 1" --format json # End-to-end data-plane verification
```

### Self-Hosted / Direct Endpoint Mode

For self-hosted Apache Doris or direct endpoint connections (no Cloud API):

```bash
velocli auth add <name> \
  --host <mysql-host> \
  --port 9030 \
  --http-port 8080 \
  --user admin \
  --password "$VELO_MYSQL_PASSWORD"
```

Or MySQL URI form:

```bash
velocli auth add <name> --mysql "mysql://admin:${PW}@host:9030"
```

### Stateless Mode (CI / Bastion)

When `VELO_HOST` + `VELO_USER` are both set, velocli runs without reading or writing `~/.velodb/`:

```bash
export VELO_HOST=<host>
export VELO_USER=admin
export VELO_PASSWORD="$VELO_MYSQL_PASSWORD"
export VELO_PORT=9030
export VELO_HTTP_PORT=8080
velocli sql "SELECT 1"    # no filesystem side effects
```

Cloud stateless mode:

```bash
export VELO_ENV_TYPE=cloud
export VELO_CLOUD_TOKEN="$VELO_CLOUD_API_KEY"
export VELO_CLOUD_API_HOST=api.velodb.cloud
export VELO_CURRENT_WAREHOUSE=<warehouse-id>
export VELO_CURRENT_CLUSTER=<cluster-id>
export VELO_PASSWORD="$VELO_MYSQL_PASSWORD"
velocli sql "SELECT 1"
```

### SOCKS5 / BYOC

BYOC clusters sit inside customer VPC, reachable via SOCKS5 proxy on bastion:

```bash
export VELO_SOCKS5_HOST=127.0.0.1
export VELO_SOCKS5_PORT=10061
export VELO_SOCKS5_USER=admin
export VELO_SOCKS5_PASS=admin
velocli sql "SELECT 1"
```

Or per-command: `velocli --socks5 admin:admin@127.0.0.1:10061 sql "SELECT 1"`

Uses `socks5h://` so DNS resolves on proxy side (private hostnames).
