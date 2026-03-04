---
title: AUTO PARTITION for Sporadic Data
impact: HIGH
impactDescription: "Creates partitions on-demand when data arrives, avoiding empty partitions"
tags: [schema, partition, auto, on-demand, sporadic]
---

## AUTO PARTITION for Sporadic Data

**Impact: HIGH — Avoids creating empty partitions for dates with no data.**

Use AUTO PARTITION when data arrival is unpredictable (not every day/month has data):

```sql
CREATE TABLE sparse_events (
    event_time DATETIME NOT NULL,
    user_id BIGINT,
    event_type VARCHAR(50)
) DUPLICATE KEY(event_time, user_id)
AUTO PARTITION BY RANGE(date_trunc(event_time, 'month'))
()
DISTRIBUTED BY HASH(user_id) BUCKETS AUTO;
```

**When to use AUTO vs DYNAMIC:**
- **Dynamic:** Continuous data (logs, metrics) — pre-creates future partitions
- **Auto:** Sporadic data (user uploads, batch jobs) — creates only when data arrives

Reference: [Auto Partition](https://doris.apache.org/docs/table-design/data-partitioning/auto-partitioning)
