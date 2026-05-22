---
title: Billing & Audit Logs
tags: [billing, audit, cost, operations]
---

## Billing

### Summary (Aggregated)

```bash
velocli cloud billing summary --format json
velocli cloud billing summary --granularity day --format json
velocli cloud billing summary --granularity month --start-month 2026-05 --end-month 2026-05
velocli cloud billing summary --status settled --payment-source cash
velocli cloud billing summary --total    # client-side sum of billedAmount
```

Time filters depend on `--granularity`:
- `hour` / `day`: use `--start` / `--end` (RFC 3339 timestamps, must pair together)
- `month`: use `--start-month` / `--end-month` (YYYY-MM format, must pair together)

If time filters omitted: API default is most recent 30 days (hour/day) or 3 months (month).

Options: `--status settled|unsettled`, `--payment-source cash|marketplace|voucher|suspended|contract|credit`, `--sort-order asc|desc`, `--page N --size N`

### Details (Per-Resource)

```bash
velocli cloud billing details --format json
velocli cloud billing details --warehouse <id> --cluster <id>
velocli cloud billing details --cluster-name analytics
velocli cloud billing details --resource-type compute|cache|storage|byoc|support|frontend_compute
velocli cloud billing details --granularity hour --start T --end T
velocli cloud billing details --sort-by serviceStartTime --sort-order asc
velocli cloud billing details --total
```

Decimal amounts returned as strings for precision.

---

## Audit Logs (Org-Wide, Read-Only)

```bash
velocli cloud audit ls --format json
velocli cloud audit ls --actor <name>                    # exact match
velocli cloud audit ls --contains "<substring>"          # full-text in details
velocli cloud audit ls --start 2026-05-01T00:00:00Z --end 2026-05-21T00:00:00Z
velocli cloud audit ls --sort asc --page 1 --size 50
```

- `actor`: API-key prefix (~36 chars) for API calls; `system` for service-initiated events
- Paginated: `page`, `size`, `total` in response metadata
- Useful for: tracking who changed what, incident timelines, compliance audit trails
