---
name: velodb-best-practices
description: >
  VeloDB/Apache Doris table design and cluster sizing best practices.
  MUST USE when writing, reviewing, or optimizing Doris CREATE TABLE statements,
  partition/bucket strategies, data models, or cluster configurations.
  Also use when user provides a VeloDB connection string or asks to get started.
  Also use when user says "design a table", "size a cluster", "my query is slow",
  or mentions Doris, VeloDB, OLAP table design.
license: Apache-2.0
metadata:
  author: VeloDB
  version: "3.0.0"
---

# VeloDB Best Practices

> Guided table design workflow for Apache Doris.
> 4-step process: Gather → Classify → Design → Validate.
> 37 rules, 7 templates, 4 sizing guides in `references/`.

---

## Instructions

Follow these steps in order. Do NOT skip steps. Do NOT guess what the user needs — ask.

### Step 1: Gather Context

Before designing any table, collect these 5 dimensions. Ask for anything the user hasn't provided:

| # | Ask | Why It Matters | Example Answer |
|---|-----|---------------|----------------|
| 1 | **What is the data?** Schema, source, example rows | Determines model (DUP/UNIQUE/AGG), data types | "User activity events with user_id, action, timestamp, payload JSON" |
| 2 | **How much data?** Rows/day, retention period, current total | Determines partition granularity, bucket count, compression | "~200M rows/day, keep 30 days, ~100GB/day raw" |
| 3 | **How will it be queried?** Top 2-3 query patterns, latency needs | Determines sort key order, indexes, MVs | "Filter by user_id + time range; aggregate by action per day" |
| 4 | **How will it be loaded?** Batch/streaming/CDC, source system | Determines UNIQUE vs DUP, sequence_col, batch strategy | "Kafka streaming, append-only, no updates" |
| 5 | **What environment?** Cloud/self-hosted, node count, any SLAs | Determines replication, cache, bucket constraints | "VeloDB Cloud, 3 BEs, dashboard queries < 2s" |

**Rules for gathering:**
- If user provides partial info, acknowledge what you know and ask for the rest.
- If user says "I don't know" for volume, suggest starting with a reasonable default and note it can be tuned.
- If user provides a MySQL/PG schema, infer Q1 and Q4 from it, then ask Q2, Q3, Q5.
- Sizing and CREATE TABLE are **intertwined** — gather both before designing.

### Step 2: Classify Workload

Based on answers, classify into one or more patterns. Load the matching template:

| If the data is... | Load Template | Key Rules |
|-------------------|--------------|-----------|
| Append-only events/logs | `references/usecase-log-event.md` | DUPLICATE, RANGE partition, ZSTD |
| Updated/deleted rows (CDC) | `references/usecase-cdc-sync.md` | UNIQUE MoW, sequence_col |
| Pre-aggregated metrics | `references/usecase-dashboard-metrics.md` | AGGREGATE, BITMAP_UNION |
| User-facing point queries | `references/usecase-point-query.md` | UNIQUE MoW, store_row_column |
| JOIN-heavy star schema | `references/usecase-star-schema-join.md` | Colocation, matching bucket keys |
| Small lookup/dimension | `references/usecase-dimension-lookup.md` | DUPLICATE, RANDOM, few buckets |
| Logs + traces + metrics | `references/usecase-observability.md` | Multi-table design |

**Multi-pattern workloads are normal.** If the user needs both log analytics AND a dashboard, design multiple tables. Explain why they're separate.

### Step 3: Design (CREATE TABLE + Sizing Together)

Produce a **unified design** that includes:

1. **Complete CREATE TABLE** with inline comments explaining WHY each choice:
   ```sql
   CREATE TABLE events (
       event_time DATETIME NOT NULL,  -- Q3: most filtered → sort key pos 1
       user_id BIGINT NOT NULL,       -- Q3: second filter → sort key pos 2
       action VARCHAR(50),
       payload VARIANT                -- Q1: semi-structured JSON → VARIANT
   ) DUPLICATE KEY(event_time, user_id)  -- Q4: append-only → DUPLICATE
   PARTITION BY RANGE(event_time) ()     -- Q2: 200M/day → daily partitions
   DISTRIBUTED BY HASH(user_id) BUCKETS AUTO  -- Q3: user_id filter → HASH
   PROPERTIES (
       "dynamic_partition.enable" = "true",
       "dynamic_partition.time_unit" = "DAY",
       "dynamic_partition.start" = "-30",    -- Q2: 30-day retention
       "dynamic_partition.end" = "3",
       "dynamic_partition.prefix" = "p",
       "compression" = "zstd"               -- Q2: 100GB/day → ZSTD saves 3×
   );
   ```

2. **Sizing implications** derived from the same answers:
   ```
   Storage: 100GB/day × 30 days × ZSTD(~10×) × 1 replica = ~300 GB
   Tablets: 30 partitions × AUTO(~8 buckets) = ~240 tablets
   Per-tablet: ~1.25 GB ✓ (target: 1-10 GB)
   ```

3. **Recommended indexes** based on Q3 query patterns.

**Cross-check every decision** against these rules (read the reference file if unsure):
- [ ] Model matches workload → `references/schema-model-*`
- [ ] Partition matches volume → `references/schema-partition-*`
- [ ] Bucket key matches query filters → `references/schema-bucket-*`
- [ ] Sort key: high-selectivity first, fixed-length before VARCHAR → `references/schema-keys-*`
- [ ] Native types, not STRING → `references/schema-types-*`
- [ ] Indexes match query patterns → `references/schema-index-*`
- [ ] Properties correct for environment → `references/schema-props-*`

### Step 4: Validate

After producing the design, verify:

- [ ] Every query pattern from Step 1 is served by sort key, index, or MV
- [ ] Tablet size is within 1-10 GB range (check with sizing formula)
- [ ] Partition count is reasonable (no thousands of empty partitions)
- [ ] Storage fits cluster capacity
- [ ] No rule violations

If validation fails, revise Step 3 and explain what changed.

---

## Troubleshooting (Reactive Workflow)

When the user comes with an **existing problem**, follow the same discovery-first approach:

### Step T1: Gather Evidence

Ask for ALL of these before suggesting any fix:

| # | Ask For | Why | If Missing |
|---|---------|-----|------------|
| 1 | **The CREATE TABLE** (full DDL) | Can't diagnose without seeing model, keys, partitions | Run `SHOW CREATE TABLE tablename` |
| 2 | **The slow query** (exact SQL) | Need to see WHERE, JOIN, GROUP BY, ORDER BY | Ask user to paste it |
| 3 | **Query profile** | Shows scan type, rows read, time breakdown | `curl -u user:pass http://<fe>:<http_port>/api/profile/text?query_id=<id>` |
| 4 | **Data volume & cluster** | Skew and sizing issues need context | `SHOW TABLETS FROM tablename` for distribution |

**DO NOT suggest fixes until you have ALL four items.** Don't guess.

### Step T2: Diagnose Root Cause

With evidence in hand, check in this order (most impactful first):

1. **Sort key vs WHERE clause** → Is the filtered column in the sort key prefix?
   - Read `references/schema-keys-selectivity-first.md`
   - Check if ZoneMap can prune → `references/schema-types-zonemap-limitations.md`

2. **Model mismatch** → Is AGGREGATE used where updates are needed? Is DUPLICATE used where dedup is needed?
   - Read `references/schema-model-choose-for-workload.md`

3. **Partition/Bucket issues** → Too many small tablets? Skew? Full scan across all partitions?
   - Read `references/schema-partition-*` and `references/schema-bucket-*`

4. **Missing indexes** → LIKE without NGram? Point query without BloomFilter? Text search without inverted?
   - Read `references/schema-index-*`

5. **JOIN performance** → Missing colocation? Wrong bucket key?
   - Read `references/usecase-star-schema-join.md`

### Step T3: Prescribe Fix

Produce a clear output:

```
## Diagnosis
- Root cause: [what's wrong and why, citing evidence from EXPLAIN]
- Rule violated: [reference file name]

## Fix
### Revised CREATE TABLE (if schema change needed)
[full DDL with inline comments showing what changed and why]

### Migration Steps
1. CREATE TABLE new_table AS SELECT ... (new schema)
2. INSERT INTO new_table SELECT ... FROM old_table
3. ALTER TABLE old_table RENAME ... / DROP ...

### Expected Improvement
- Before: [X rows scanned, Y seconds]
- After: [Z rows scanned, estimated time]
```

### Symptom Quick-Reference (for Step T2)

| Symptom | Most Likely Root Cause | Key Reference |
|---------|----------------------|---------------|
| Full table scan on WHERE | Filtered column not in sort key prefix | `schema-keys-selectivity-first` |
| JOINs are slow / shuffle | Missing colocation group | `usecase-star-schema-join` |
| COUNT DISTINCT slow | Using raw COUNT instead of BITMAP | `schema-types-bitmap-count-distinct` |
| LIKE '%keyword%' slow | No NGram BloomFilter index | `schema-index-ngram-for-like` |
| Point query > 100ms | Missing store_row_column or BloomFilter | `usecase-point-query` |
| Storage growing too fast | No TTL or wrong compression | `schema-partition-dynamic-ttl` |
| Data skew / hot tablets | Low-cardinality bucket key | `schema-bucket-composite-for-skew` |
| VARCHAR in key kills perf | Variable-length type before fixed-length | `schema-keys-fixed-length-types` |
| Writes slow on UNIQUE | Using MoR instead of MoW | `schema-model-prefer-mow` |

---

## Rule Index (Reference Library)

All 37 rules, 7 templates, and guides are in `references/`. For quick lookup:

### Data Model (4 rules)
- `schema-model-choose-for-workload` — DUP vs UNIQUE vs AGG
- `schema-model-prefer-mow` — Always MoW for UNIQUE
- `schema-model-avoid-agg-for-updates` — AGG cannot UPDATE/DELETE
- `schema-model-sequence-col-for-cdc` — Sequence column for CDC

### Partition (4) · Bucket (5) · Sort Key (5) · Types (5)
See `references/schema-partition-*`, `schema-bucket-*`, `schema-keys-*`, `schema-types-*`

### Indexes (7) · MVs (3) · Properties (2) · Caching (2)
See `references/schema-index-*`, `schema-mv-*`, `schema-props-*`, `schema-cache-*`

### Use Case Templates (7)
See `references/usecase-*`

### Sizing (4) · Getting Started (2)
See `references/sizing-*`, `references/start-*`

Full compiled document: `AGENTS.md`
