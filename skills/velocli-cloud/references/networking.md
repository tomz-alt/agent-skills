---
title: Networking — Public Access & PrivateLink
tags: [networking, public-access, privatelink, security]
---

## Networking

### Execution Contract

- Read current state first where possible (`public-access get`, `privatelink inbound get`, outbound `ls`)
- Public access changes and PrivateLink register/unregister are mutations. Show the target warehouse/service, current state, requested change, and connectivity impact before asking explicit confirmation
- If `velocli` is unavailable locally, still provide the exact read → confirm → mutate → verify workflow. Do not stop at installation guidance

### Public Access Policy (Per-Warehouse)

Three mutually-exclusive modes:

```bash
velocli cloud public-access get --format json     # current policy + allowlist
velocli cloud public-access deny                  # → DENY_ALL
velocli cloud public-access allow                 # → ALLOW_ALL (open to internet — not recommended for prod)
velocli cloud public-access allowlist \
  --rule 203.0.113.5/32:bastion \
  --rule 198.51.100.0/24:office             # → ALLOWLIST_ONLY
```

- `--rule` accepts `CIDR` or `CIDR:DESCRIPTION` (repeatable)
- CLI warns on RFC 1918 private ranges (10/8, 172.16/12, 192.168/16) — API silently drops these because allowlist must be public IPs
- Prefer `allowlist` over `allow` for production

### PrivateLink Inbound (Per-Warehouse)

Customer VPC endpoints connecting TO the warehouse:

```bash
velocli cloud privatelink inbound get --format json
velocli cloud privatelink inbound register \
  --endpoint-id vpce-0abc123 \
  [--dns-name analytics.corp.internal] \
  [--description "analytics prod"]
```

Response includes per-endpoint protocol URLs (jdbc, http, stream_load, adbc, studio, mcp).

### PrivateLink Outbound (Org-Wide)

External services your warehouses can call:

```bash
velocli cloud privatelink outbound ls --cloud-provider aws [--region us-east-1] --format json
velocli cloud privatelink outbound register \
  --cloud-provider aws \
  --region us-east-1 \
  --service-id vpce-svc-0123456789abcdef0 \
  --service-name com.amazonaws.vpce.us-east-1.vpce-svc-0123456789abcdef0 \
  [--zone us-east-1d] \
  [--provider-account-id 123456789012] \
  [--description "Corporate API gateway"]
velocli cloud privatelink outbound unregister <service-id>
```

- `--cloud-provider` is required for `outbound ls`
- For AWS providers, `--service-id` is functionally required (CLI warns when missing)
