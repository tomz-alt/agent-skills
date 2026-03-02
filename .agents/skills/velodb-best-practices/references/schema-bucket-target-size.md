---
title: Target 1-10 GB Per Tablet
impact: HIGH
impactDescription: "Too many small tablets waste metadata; too few large tablets limit parallelism"
tags: [schema, bucket, tablet, size, auto]
---

## Target 1-10 GB Per Tablet

**Impact: HIGH — Tablet size directly affects query parallelism and metadata overhead.**

Rules:
- **Target:** 1-10 GB per tablet (compressed)
- **Max buckets per partition:** ≤ 64
- **Preferred:** Use `BUCKETS AUTO` to let Doris calculate

```sql
-- GOOD: Let Doris decide
DISTRIBUTED BY HASH(user_id) BUCKETS AUTO

-- Manual: 100 GB partition / target 5 GB per tablet = 20 buckets
DISTRIBUTED BY HASH(user_id) BUCKETS 20
```

**Warning signs:**
- Tablets < 100 MB → Too many buckets, merge or reduce
- Tablets > 20 GB → Too few buckets, increase count

Reference: [Data Distribution](https://doris.apache.org/docs/table-design/data-partitioning/data-distribution)
