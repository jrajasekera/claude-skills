# Indexing Guide

## Table of Contents
- [Index Mechanics](#index-mechanics)
- [Composite Index Column Order](#composite-index-column-order)
- [Covering Indexes](#covering-indexes)
- [Partial Indexes](#partial-indexes)
- [Expression Indexes](#expression-indexes)
- [Diagnosing Index Usage](#diagnosing-index-usage)
- [Index Maintenance](#index-maintenance)

## Index Mechanics

SQLite indexes are B-trees where:
- Key = indexed column(s)
- Value = rowid pointing to main table row

**Lookup flow:**
1. Traverse index B-tree to find matching key → O(log N)
2. Use rowid to fetch full row from table B-tree → O(log N)

**Total:** O(log N) + O(log N) = O(log N)

**Without index:** Full table scan = O(N)

## Composite Index Column Order

Column order in composite indexes is critical. The index can only be used efficiently when queries filter on a **prefix** of the indexed columns.

**Example index:**
```sql
CREATE INDEX idx_orders ON orders (user_id, status, created_at);
```

| Query Filter | Uses Index? |
|--------------|-------------|
| `WHERE user_id = ?` | ✅ Yes |
| `WHERE user_id = ? AND status = ?` | ✅ Yes |
| `WHERE user_id = ? AND status = ? AND created_at > ?` | ✅ Yes |
| `WHERE status = ?` | ❌ No (user_id not filtered) |
| `WHERE user_id = ? AND created_at > ?` | ⚠️ Partial (only user_id) |

**Column ordering rules:**
1. Equality conditions first (`=`)
2. Range conditions last (`>`, `<`, `>=`, `<=`, `BETWEEN`)
3. ORDER BY columns match index order and direction

**Index with sort direction:**
```sql
-- For: ORDER BY created_at DESC
CREATE INDEX idx_orders_user_date 
ON orders (user_id, created_at DESC);
```

## Covering Indexes

A covering index contains all columns needed by the query, eliminating table lookup.

**Non-covering (requires table lookup):**
```sql
CREATE INDEX idx_orders_user ON orders (user_id);

SELECT user_id, total, created_at 
FROM orders WHERE user_id = ?;
-- Must fetch total, created_at from main table
```

**Covering (index-only scan):**
```sql
CREATE INDEX idx_orders_cover 
ON orders (user_id, created_at, total);

SELECT user_id, total, created_at 
FROM orders WHERE user_id = ?;
-- All columns in index, no table access
```

**INCLUDE clause (SQLite 3.38+):**
```sql
CREATE INDEX idx_orders_cover 
ON orders (user_id) INCLUDE (total, created_at);
```
- Included columns stored in leaf pages only
- Reduces index depth for large included values
- Older SQLite: simulate with composite index

## Partial Indexes

Index only a subset of rows using WHERE clause.

```sql
-- Index only active orders
CREATE INDEX idx_active_orders 
ON orders (user_id, created_at) 
WHERE status = 'active';
```

**Benefits:**
- Smaller index size
- Faster updates (fewer rows to maintain)
- Perfect for "hot" subset queries

**Query must match predicate:**
```sql
-- Uses partial index
SELECT * FROM orders 
WHERE user_id = ? AND status = 'active';

-- Does NOT use partial index
SELECT * FROM orders WHERE user_id = ?;
```

## Expression Indexes

Index computed expressions for queries that filter on transformations.

```sql
-- For case-insensitive email lookup
CREATE INDEX idx_users_email_lower 
ON users (lower(email));

-- Query must use same expression
SELECT * FROM users WHERE lower(email) = ?;
```

**Common use cases:**
```sql
-- JSON field extraction
CREATE INDEX idx_data_type 
ON items (json_extract(data, '$.type'));

-- Date part extraction
CREATE INDEX idx_orders_year 
ON orders (strftime('%Y', created_at));

-- Concatenated search
CREATE INDEX idx_full_name 
ON users (first_name || ' ' || last_name);
```

## Diagnosing Index Usage

### EXPLAIN QUERY PLAN

```sql
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE user_id = 123;
```

**Interpret results:**

| Output | Meaning | Action |
|--------|---------|--------|
| `SCAN TABLE orders` | Full table scan | Add index |
| `SEARCH TABLE orders USING INDEX idx_...` | Index used | Good |
| `SEARCH TABLE orders USING COVERING INDEX idx_...` | Index-only scan | Optimal |
| `USE TEMP B-TREE FOR ORDER BY` | Sort not covered | Add ORDER BY columns to index |

### Finding Missing Indexes

Look for `SCAN TABLE` in slow queries:
```sql
EXPLAIN QUERY PLAN <your_slow_query>;
```

### Finding Unused Indexes

Check `sqlite_stat1` for selectivity:
```sql
SELECT * FROM sqlite_stat1;
```

**Indicators of unused/useless indexes:**
- Index on low-cardinality column (few distinct values)
- Index never appearing in EXPLAIN QUERY PLAN for actual queries
- Redundant index (prefix of another composite index)

### Index Cost

Every index:
- Consumes disk space
- Slows INSERT/UPDATE/DELETE (must update all indexes)
- Competes for cache space

**Rule:** Only index columns actually used in queries.

## Index Maintenance

### After Bulk Operations

```sql
-- Rebuild all indexes
REINDEX;

-- Rebuild specific index
REINDEX idx_orders_user;

-- Update statistics
ANALYZE;
```

### Index Creation Strategy

**For existing data:**
```sql
-- Faster to drop/recreate than incremental updates
DROP INDEX IF EXISTS idx_orders_user;
CREATE INDEX idx_orders_user ON orders (user_id);
```

**For bulk inserts:**
1. Drop indexes
2. Insert data
3. Recreate indexes
4. Run ANALYZE

## Checklist

- [ ] Every foreign key column has an index
- [ ] Composite indexes ordered: equality → range → ORDER BY
- [ ] Covering indexes for frequent queries
- [ ] Partial indexes for "active" subset queries
- [ ] No indexes on low-cardinality columns alone
- [ ] No redundant indexes (check prefixes)
- [ ] EXPLAIN QUERY PLAN shows no unexpected SCAN TABLE
- [ ] ANALYZE run after bulk changes
