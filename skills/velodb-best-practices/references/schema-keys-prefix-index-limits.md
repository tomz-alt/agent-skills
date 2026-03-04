---
title: Prefix Index Limits — 3 Columns, 36 Bytes
impact: HIGH
impactDescription: "Only the first 3 columns or 36 bytes participate in the prefix index"
tags: [schema, keys, prefix-index, limits]
---

## Prefix Index Limits — 3 Columns, 36 Bytes

**Impact: HIGH — Columns beyond the limit get no prefix index benefit.**

| Rule | Detail |
|------|--------|
| Max columns | 3 |
| Max bytes | 36 |
| VARCHAR | Terminates the index (only first 20 bytes included) |
| FLOAT/DOUBLE | **Cannot be in prefix index** — breaks ZoneMap too |

**Example:**

```sql
-- user_id(BIGINT=8B) + event_date(DATE=4B) + app_id(INT=4B) = 16B, 3 cols ✓
DUPLICATE KEY(user_id, event_date, app_id)

-- If you need a 4th filter column, add a separate index (BloomFilter, Inverted)
```

Reference: [Prefix Index](https://doris.apache.org/docs/table-design/index/prefix-index)
