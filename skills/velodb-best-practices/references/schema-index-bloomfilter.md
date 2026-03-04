---
title: BloomFilter for High-Cardinality Equality Filters
impact: HIGH
tags: [schema, index, bloomfilter, equality, high-cardinality]
---
## BloomFilter for High-Cardinality Equality Filters
**Impact: HIGH — Skips data pages that definitely don't contain the filtered value.**
Use for columns with ≥ 5000 distinct values, filtered with `=` or `IN`.
```sql
-- Add BloomFilter index
PROPERTIES ("bloom_filter_columns" = "trace_id, session_id");
-- Or per-column:
INDEX idx_trace(trace_id) USING BLOOM FILTER
```
**Constraints:**
- NOT supported on TINYINT, FLOAT, or DOUBLE columns
- Only accelerates `=` and `IN` filters (not LIKE, not range)
- Minimum recommended cardinality: 5000+ distinct values
- False positive rate ~1% (configurable via bloom_filter_fpp)
