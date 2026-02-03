# PRAGMA Reference

## Table of Contents
- [Journal Mode](#journal-mode)
- [Synchronous](#synchronous)
- [Cache Settings](#cache-settings)
- [Memory-Mapped I/O](#memory-mapped-io)
- [Temporary Storage](#temporary-storage)
- [Concurrency](#concurrency)
- [Maintenance](#maintenance)
- [Integrity](#integrity)

## Journal Mode

```sql
PRAGMA journal_mode = WAL;  -- Recommended
```

| Mode | Description | Use Case |
|------|-------------|----------|
| `DELETE` | Traditional rollback journal, deleted after commit | Legacy compatibility |
| `WAL` | Write-ahead log, append-only | **Default for most apps** |
| `MEMORY` | Journal in RAM only | Ephemeral DBs, testing |
| `OFF` | No journal | Read-only or disposable data |

**WAL Mechanics:**
- Writes append to separate `.wal` file
- Readers see consistent snapshot without blocking writer
- Checkpointing transfers WAL changes back to main DB
- Auto-checkpoint at 1000 pages by default

**WAL Limitations:**
- Requires local filesystem (not NFS/SMB)
- Creates `.wal` and `.shm` auxiliary files
- Large transactions can grow WAL unboundedly

## Synchronous

```sql
PRAGMA synchronous = NORMAL;  -- Recommended for WAL
```

| Setting | WAL Behavior | Rollback Behavior | Speed |
|---------|--------------|-------------------|-------|
| `FULL` (2) | Sync WAL every commit | Sync journal + DB | Slowest |
| `NORMAL` (1) | Sync only at checkpoint | Sync at critical moments | **Recommended** |
| `OFF` (0) | No syncs | No syncs | Fastest, risky |

**In WAL mode with `synchronous = NORMAL`:**
- Application crash: No data loss (WAL protects)
- OS/power crash: May lose last transaction, but DB stays consistent

## Cache Settings

```sql
PRAGMA cache_size = -64000;  -- 64MB (negative = KB)
```

**Sizing:**
- Positive value = number of pages
- Negative value = KB (recommended for consistent memory budget)
- Larger cache reduces disk I/O for read-heavy workloads
- Too large may cause OS swapping

**Guidelines:**
| Workload | Recommended Size |
|----------|------------------|
| Mobile app | 8-32 MB (`-8000` to `-32000`) |
| Desktop app | 32-128 MB (`-32000` to `-128000`) |
| Server | 128 MB+ based on available RAM |

## Memory-Mapped I/O

```sql
PRAGMA mmap_size = 2147483648;  -- 2GB
```

**Benefits:**
- Bypasses kernel buffer copy overhead
- Significant speedup for read-heavy workloads
- Can reduce CPU usage by orders of magnitude

**Risks:**
- I/O errors (disk failure, file truncation) cause SIGBUS/SIGSEGV crashes
- Cannot be gracefully caught by SQLite
- 32-bit systems limited to ~2GB address space

**Recommendations:**
- Benchmark in your specific environment
- Set to 0 to disable if stability is paramount
- Use when DB fits in available RAM

## Temporary Storage

```sql
PRAGMA temp_store = MEMORY;
```

| Setting | Behavior |
|---------|----------|
| `DEFAULT` (0) | Compile-time default |
| `FILE` (1) | Temp structures on disk |
| `MEMORY` (2) | Temp structures in RAM |

**Use `MEMORY` when:**
- Complex queries with sorting/aggregation
- Sufficient RAM available
- Faster GROUP BY, ORDER BY, DISTINCT operations

## Concurrency

```sql
PRAGMA busy_timeout = 5000;  -- 5 seconds
```

- Sets how long to wait for locked DB before returning SQLITE_BUSY
- 0 = return immediately on lock
- Higher values reduce lock errors but increase latency

**Locking States (Rollback mode):**
1. `SHARED` — Multiple readers allowed
2. `RESERVED` — Writer planning to write, readers continue
3. `PENDING` — Writer ready, blocks new readers
4. `EXCLUSIVE` — Writer committing, blocks all

**WAL mode advantage:** Readers never block writers, writers never block readers.

## Maintenance

### ANALYZE / PRAGMA optimize

```sql
-- Smart analysis (recommended)
PRAGMA optimize;

-- Full database analysis
ANALYZE;

-- Analyze specific table
ANALYZE table_name;
```

**PRAGMA optimize patterns:**
- Short-lived connections: Run before closing
- Long-lived connections: Run `PRAGMA optimize=0x10002;` at open, then `PRAGMA optimize;` daily

### VACUUM

```sql
VACUUM;  -- Full rebuild
```

- Defragments and compacts database file
- Requires free disk space ≈ current DB size
- Blocking operation — schedule during maintenance

### Auto-Vacuum

```sql
PRAGMA auto_vacuum = FULL;       -- Automatic space reclaim
PRAGMA auto_vacuum = INCREMENTAL; -- Manual incremental reclaim
PRAGMA auto_vacuum = NONE;        -- Default, manual VACUUM only
VACUUM;  -- Required to apply change
```

**Incremental usage:**
```sql
PRAGMA incremental_vacuum(100);  -- Reclaim up to 100 pages
```

## Integrity

```sql
PRAGMA foreign_keys = ON;  -- Enable FK enforcement
```

- Must be set per-connection (not persistent)
- Prevents orphaned records
- Enables CASCADE operations

```sql
PRAGMA integrity_check;  -- Full integrity verification
PRAGMA quick_check;      -- Faster, less thorough check
```

## Complete Baseline Template

```sql
-- Set immediately after opening connection
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA foreign_keys = ON;
PRAGMA cache_size = -64000;
PRAGMA temp_store = MEMORY;
PRAGMA busy_timeout = 5000;
PRAGMA mmap_size = 2147483648;

-- Periodic maintenance
PRAGMA optimize;  -- Run before close or periodically

-- Scheduled maintenance (low-traffic windows)
VACUUM;           -- After large deletions
ANALYZE;          -- If PRAGMA optimize insufficient
```
