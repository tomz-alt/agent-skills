---
title: "Use Case: Star Schema / JOIN-Heavy Analytics"
impact: CRITICAL
tags: [usecase, star-schema, join, colocation, fact-table, dimension]
---
## Use Case: Star Schema / JOIN-Heavy Analytics
Uses colocation to ensure JOINs execute locally without network shuffle.
### Fact Table
```sql
CREATE TABLE fact_orders (
    order_date DATE NOT NULL, order_id BIGINT NOT NULL,
    user_id INT NOT NULL, store_id INT NOT NULL, product_id INT NOT NULL,
    amount DECIMAL(12,2), quantity INT
) ENGINE=OLAP DUPLICATE KEY(order_date, order_id)
PARTITION BY RANGE(order_date) ()
DISTRIBUTED BY HASH(store_id) BUCKETS 16
PROPERTIES ("dynamic_partition.enable"="true","dynamic_partition.time_unit"="MONTH",
    "dynamic_partition.start"="-24","dynamic_partition.end"="1",
    "dynamic_partition.prefix"="p","dynamic_partition.buckets"="16",
    "colocate_with"="group_orders");
```
### Dimension Table (colocated)
```sql
CREATE TABLE dim_stores (
    store_id INT NOT NULL, region VARCHAR(20), city VARCHAR(50), manager_name VARCHAR(100)
) ENGINE=OLAP DUPLICATE KEY(store_id)
DISTRIBUTED BY HASH(store_id) BUCKETS 16
PROPERTIES ("colocate_with" = "group_orders");
```
### Colocation Rules — ALL must match:
1. Same `colocate_with` group name
2. Same bucket key column(s) and same column types
3. Same bucket count
4. Same replication_num
