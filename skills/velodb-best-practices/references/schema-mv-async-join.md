---
title: Async MV for Multi-Table JOIN Acceleration
impact: HIGH
tags: [schema, mv, async, join, multi-table]
---
## Async MV for Multi-Table JOIN Acceleration
**Impact: HIGH — Pre-computes JOINs so queries read a flat table instead of joining at runtime.**
```sql
CREATE MATERIALIZED VIEW mv_order_details
REFRESH SCHEDULE EVERY 10 MINUTES
AS SELECT o.order_id, o.amount, p.product_name, c.customer_name
FROM orders o
JOIN products p ON o.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id;
```
**Refresh modes:** SCHEDULE (periodic), ON COMMIT (on base table change, limit: ≤5 updates/hr), MANUAL.
Reference: [Async Materialized View](https://doris.apache.org/docs/query-acceleration/materialized-view/async-materialized-view)
