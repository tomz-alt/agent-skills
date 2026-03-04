---
title: Async MV Operational Limits
impact: HIGH
tags: [schema, mv, async, limits, capacity]
---
## Async MV Operational Limits
| Limit | Value |
|-------|-------|
| Max rows per MV | ~50 million |
| Max JOINs | 2 |
| Max partitions | 30 |
| Max concurrent refreshes | 3 |
| Cluster resource cap | 40% |
| ON COMMIT limit | ≤ 5 updates/hour |
**Capacity estimation:** ~20-30 active async MVs on a 3-node cluster.
**Layered design pattern:** Build MVs on top of other MVs (Layer 1: base aggregations, Layer 2: cross-table joins).
**partition_sync_limit:** Focus refresh on recent data only:
```sql
CREATE MATERIALIZED VIEW mv_recent
PROPERTIES ("partition_sync_limit" = "7")
REFRESH SCHEDULE EVERY 1 HOUR
AS SELECT ... FROM orders ...;
```
