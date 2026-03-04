---
title: Sync MV (Rollup) for Single-Table Aggregation
impact: HIGH
tags: [schema, mv, sync, rollup, aggregation]
---
## Sync MV (Rollup) for Single-Table Aggregation
**Impact: HIGH — Pre-aggregates data; optimizer rewrites queries automatically.**
```sql
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT dt, store_id, SUM(amount) AS total, COUNT(*) AS cnt
FROM orders GROUP BY dt, store_id;
```
**Restriction: NOT supported on UNIQUE KEY tables.** Use async MVs instead.
Sync MVs are maintained synchronously with the base table — zero lag.
Reference: [Sync Materialized View](https://doris.apache.org/docs/query-acceleration/materialized-view/sync-materialized-view)
