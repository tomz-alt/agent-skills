---
title: High-Selectivity Columns First in Sort Key
impact: CRITICAL
impactDescription: "Sort key order determines prefix index effectiveness and ZoneMap pruning"
tags: [schema, keys, sort, selectivity, prefix-index]
---

## High-Selectivity Columns First in Sort Key

**Impact: CRITICAL — Sort key order determines query performance through prefix index.**

Place columns in this order:
1. Most frequently filtered columns first
2. Higher selectivity (more distinct values) before lower
3. Equality filters before range filters

```sql
-- GOOD: user_id (high selectivity, common filter) first
DUPLICATE KEY(user_id, event_time, event_type)

-- BAD: event_type (low selectivity) first
DUPLICATE KEY(event_type, event_time, user_id)
```

The first 3 columns (or first 36 bytes) form the **prefix index**, which is the primary lookup structure in Doris.

Reference: [Sort Key](https://doris.apache.org/docs/table-design/index/prefix-index)
