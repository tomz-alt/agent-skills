---
title: Getting Started — VeloDB Cloud
tags: [start, cloud, connection, setup]
---
## Getting Started — VeloDB Cloud

### Where to Find Credentials

**API key**: VeloDB Cloud console → Organization → API Keys (e.g. `https://www.velodb.cloud/organization/api-keys`). Starts with `sk-`.

**MySQL password**: set during warehouse creation. If forgotten, rotate via `velocli cloud warehouse password set` or the console.

**Host, port, connection strings**: open the warehouse in the Cloud console → Connection Methods. Shows MySQL CLI, JDBC, StreamLoad, and MCP connection strings ready to copy.

### Connection Info
You'll need: **Host**, **Port** (9030 for MySQL protocol), **HTTP Port** (8080 for VeloDB Cloud), **User**, **Password**.

### Connect with VeloCLI (Preferred)

```bash
velocli auth add cloud \
  --api-key "$VELO_CLOUD_API_KEY" \
  --api-host api.velodb.cloud \
  --mysql-password "$VELO_MYSQL_PASSWORD"
velocli auth status --format json
velocli sql "SELECT 1" --format json
```

Or with a direct endpoint (host already known):

```bash
velocli auth add cloud --host <host> --port 9030 --http-port 8080 --user admin --password "$VELO_MYSQL_PASSWORD"
velocli use cloud
velocli auth status --format json
```

### Connect via MySQL Client
```bash
mysql -h <host> -P 9030 -u admin -p"$VELO_MYSQL_PASSWORD"
```

### Connect via JDBC
```
jdbc:mysql://<host>:9030/<database>?user=admin&password=<Password>
```

### First Steps
1. Create a database: `CREATE DATABASE IF NOT EXISTS my_db;`
2. Use the database: `USE my_db;`
3. Create your first table (see use case templates for guidance)
4. Load data via Stream Load, INSERT, or external connectors

### Cloud-Specific Properties
Always set these for cloud mode:
```sql
PROPERTIES ("replication_num" = "1");
```
