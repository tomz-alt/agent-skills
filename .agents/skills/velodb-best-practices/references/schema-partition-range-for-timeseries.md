---
title: RANGE Partition on Time Column for Time-Series
impact: CRITICAL
impactDescription: "Partition key is irreversible; wrong choice prevents pruning and TTL"
tags: [schema, partition, range, time-series, pruning]
---

## RANGE Partition on Time Column for Time-Series

**Impact: CRITICAL — Partition key cannot be changed after table creation.**

For any table with a time column (logs, events, metrics), use RANGE partition:

```sql
PARTITION BY RANGE(event_time) ()
```

Combined with dynamic partitioning, this enables:
- **Partition pruning:** `WHERE event_time > '2025-01-01'` only scans relevant partitions
- **TTL:** Old partitions are auto-dropped
- **Parallel loading:** Each partition can be loaded independently

**Incorrect:**

```sql
-- BAD: No partition on a time-series table
CREATE TABLE events (
    event_time DATETIME, user_id BIGINT, data STRING
) DUPLICATE KEY(event_time)
DISTRIBUTED BY HASH(user_id) BUCKETS AUTO;
-- Every query scans ALL data, no TTL possible
```

**Correct:**

```sql
CREATE TABLE events (
    event_time DATETIME NOT NULL, user_id BIGINT, data STRING
) DUPLICATE KEY(event_time, user_id)
PARTITION BY RANGE(event_time) ()
DISTRIBUTED BY HASH(user_id) BUCKETS AUTO
PROPERTIES (
    "dynamic_partition.enable" = "true",
    "dynamic_partition.time_unit" = "DAY",
    "dynamic_partition.start" = "-30",
    "dynamic_partition.end" = "3",
    "dynamic_partition.prefix" = "p"
);
```

Reference: [Range Partition](https://doris.apache.org/docs/table-design/data-partitioning/range-partitioning)
