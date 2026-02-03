# SQLite Architecture

## Table of Contents
- [Execution Pipeline](#execution-pipeline)
- [B-Tree Storage](#b-tree-storage)
- [Pager and Caching](#pager-and-caching)
- [Concurrency and Locking](#concurrency-and-locking)
- [Query Planner](#query-planner)

## Execution Pipeline

SQLite is an embedded library running in-process (no separate server).

**Query lifecycle:**
```
SQL Text → Tokenizer → Parser → Code Generator → VDBE Bytecode → Execution → Results
```

### Virtual Database Engine (VDBE)

The VDBE is SQLite's virtual machine that executes bytecode instructions.

**View bytecode:**
```sql
EXPLAIN SELECT * FROM users WHERE id = 1;
```

**Performance implications:**
- Complex subqueries generate more bytecode instructions
- Correlated subqueries re-execute inner loop per outer row
- Minimize VDBE cycles by simplifying queries

## B-Tree Storage

SQLite stores all data in a single file organized as B-trees.

### Page Structure

- Database file divided into fixed-size pages (default: 4096 bytes)
- Each page = atomic I/O unit
- Page types: interior (navigation), leaf (data)

**Check page size:**
```sql
PRAGMA page_size;  -- Typically 4096
```

### Table B+Trees (Rowid Tables)

- Interior pages: navigation keys only (rowids)
- Leaf pages: actual row data
- Maximizes fan-out, minimizes tree depth

**Lookup by rowid:** O(log N) single B-tree traversal

### Index B-Trees

- Store indexed column values as keys
- Values point to rowids in main table
- Both interior and leaf pages store keys

**Lookup by indexed column:**
1. Search index B-tree → find rowid
2. Search table B-tree → find row
3. Total: 2 × O(log N) = O(log N)

### Overflow Pages

When row data exceeds page capacity:
- Excess spills to linked overflow pages
- Reading one row may require multiple page reads
- **Performance cliff:** Large BLOBs/TEXT trigger overflow

**Avoid overflow:**
- Keep rows compact
- Store large BLOBs in separate table or external files
- Index keys should be small (avoid large TEXT primary keys)

## Pager and Caching

The Pager mediates between B-tree layer and disk.

### Page Cache

- LRU cache of recently accessed pages
- Controlled by `PRAGMA cache_size`
- Cache miss = disk I/O

**Cache spilling:**
When working set > cache size, pages evicted to disk repeatedly.

**Symptoms:** High latency, excessive disk I/O

**Solution:** Increase `cache_size` or reduce working set

### Memory-Mapped I/O

`PRAGMA mmap_size` enables direct memory mapping.

- Bypasses kernel buffer copies
- Pages accessed like memory addresses
- Risk: I/O errors cause process crash (SIGBUS)

## Concurrency and Locking

### Rollback Journal Mode (Legacy)

**Lock progression:**
```
UNLOCKED → SHARED → RESERVED → PENDING → EXCLUSIVE
```

| Lock | Who Can Read | Who Can Write |
|------|--------------|---------------|
| SHARED | Many | None |
| RESERVED | Many (existing) | One (preparing) |
| PENDING | Existing only | One (waiting) |
| EXCLUSIVE | None | One |

**Problem:** Writers block all readers during commit.

### WAL Mode (Recommended)

**Inverted model:**
- Original DB file unchanged during transaction
- New pages appended to separate WAL file
- Readers see consistent snapshot from DB + WAL

**Concurrency:**
- Multiple readers + one writer simultaneously
- Writers never block readers
- Readers never block writers

**Checkpointing:**
- WAL changes transferred to main DB periodically
- Auto-checkpoint at 1000 pages by default
- Manual: `PRAGMA wal_checkpoint;`

**Checkpoint types:**
| Type | Behavior |
|------|----------|
| PASSIVE | Copy what's possible, don't block |
| FULL | Wait for readers, copy all |
| RESTART | Reset WAL to beginning |
| TRUNCATE | Reset and truncate WAL file |

### Shared Memory (.shm)

WAL uses shared memory file for coordination:
- Maps WAL frame index
- Enables lock-free reads
- Requires local filesystem (not NFS)

## Query Planner

### Next-Generation Query Planner (NGQP)

Since SQLite 3.8.0, uses N Nearest Neighbors (N3) algorithm:
- Considers multiple execution paths
- Better join ordering for complex queries
- Star-query heuristic for fact/dimension patterns

### Cost Estimation

Planner estimates cost based on:
- Table sizes (from `sqlite_stat1`)
- Index selectivity
- Join cardinality

**Without statistics:** Assumes uniform distribution → poor plans

**Fix:** Run `ANALYZE` or `PRAGMA optimize`

### Query Transformations

**Subquery flattening:**
- Merges simple subqueries into main query
- Blocked by: aggregates, LIMIT, DISTINCT

**Co-routines:**
- Non-flattenable subqueries run as generators
- Rows produced on-demand, not materialized

### EXPLAIN QUERY PLAN Interpretation

```sql
EXPLAIN QUERY PLAN
SELECT o.*, u.name
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.status = 'active';
```

**Read output as execution order:**
1. Which table scanned first (outer loop)
2. Which index used
3. Join method
4. Any temporary structures

## Performance Boundaries

### SQLite Excels At
- Embedded/local applications
- Single-writer workloads
- Datasets fitting in RAM or local SSD
- Low-latency local access

### SQLite Struggles With
- Many concurrent writers
- Multi-TB OLTP
- Network filesystem access
- Cross-machine replication (no built-in support)

### Scaling Limits
| Metric | Practical Limit |
|--------|-----------------|
| Database size | ~1 TB (performance degrades) |
| Concurrent readers | Hundreds (WAL mode) |
| Concurrent writers | 1 (serialized) |
| Transactions/sec | Thousands (batched) |
