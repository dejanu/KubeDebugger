#!/usr/bin/env bash
# set var before running the script
# HOST
# USER
# PASSWORD
# DATABASE

# Set error handling
set -o errexit
set -o pipefail

# Function to handle errors
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Function to check if psql is installed
check_psql() {
    if ! command -v psql >/dev/null 2>&1; then
        handle_error "psql is not installed. Please install PostgreSQL client tools."
    fi
}

# Function to test database connection
test_connection() {
    if ! psql -h "$HOST" -U "$USER" -d "$DATABASE" -c "SELECT 1" >/dev/null 2>&1; then
        handle_error "Unable to connect to database. Please check credentials and connection parameters."
    fi
}

# Function to check if pg_stat_statements is installed
check_pg_stat_statements() {
    if ! psql -h "$HOST" -U "$USER" -d "$DATABASE" -c "SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements'" | grep -q "pg_stat_statements"; then
        handle_error "pg_stat_statements extension is not installed in the database."
    fi
}

# Function to execute query and print header with error handling
run_query() {
    local title="$1"
    local query="$2"
    local temp_file=$(mktemp)

    echo -e "\n$title\n"

    if ! PGOPTIONS='-c statement_timeout=30s' psql -h "$HOST" -U "$USER" -d "$DATABASE" -c "$query" -P format=aligned -P border=2 -F $'\t'> "$temp_file" 2>&1; then
        local error_msg=$(cat "$temp_file")
        rm "$temp_file"
        handle_error "Query failed: $title\n$error_msg"
    fi

    cat "$temp_file"
    rm "$temp_file"
}

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --host=*)
            HOST="${1#*=}"
            ;;
        --user=*)
            USER="${1#*=}"
            ;;
        --password=*)
            PASSWORD="${1#*=}"
            ;;
        --database=*)
            DATABASE="${1#*=}"
            ;;
        --help|-h)
            echo "Usage: $0 --host=dbhost --user=username --password=pass --database=dbname"
            echo "Options:"
            echo "  --host      PostgreSQL host"
            echo "  --user      Database user"
            echo "  --password  User password"
            echo "  --database  Database name"
            exit 0
            ;;
        *)
            handle_error "Unknown parameter: $1"
            ;;
    esac
    shift
done

# Check if required parameters are set
if [ -z "$HOST" ] || [ -z "$USER" ] || [ -z "$PASSWORD" ] || [ -z "$DATABASE" ]; then
    handle_error "Missing required parameters\nUsage: $0 --host=dbhost --user=username --password=pass --database=dbname"
fi

# Check for valid hostname
if ! [[ "$HOST" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    handle_error "Invalid hostname format: $HOST"
fi

# Check for valid database name
if ! [[ "$DATABASE" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    handle_error "Invalid database name format: $DATABASE"
fi

# Check for empty password
if [ -z "$PASSWORD" ]; then
    handle_error "Password cannot be empty"
fi

# Export password for psql
export PGPASSWORD="$PASSWORD"

# Perform initial checks
check_psql
test_connection
check_pg_stat_statements

# Query 1: 10 slowest queries with over 1000 calls
# This query retrieves the top 10 slowest queries that have been called more than 1000 times.
# It calculates the average execution time, total time, and number of calls,
# and orders the results by number of calls in descending order.
# It also limits the results to the top 10 queries.
# The query uses the pg_stat_statements view to gather statistics about executed queries.
# It filters for queries with more than 1000 calls and total execution time greater than 0.
# The results include the average time per call, total calls, total execution time,
# I/O time (block read and write), and a substring of the query text for readability
QUERY1="SELECT
    round((total_time/calls)::numeric, 2) AS avg_time,
    calls,
    round(total_time::numeric, 2) AS total_time,
    round((blk_read_time+blk_write_time)::numeric, 2) AS io_time,
    substring(query, 1, 100) AS query_excerpt
FROM pg_stat_statements
WHERE calls > 1000
    AND total_time > 0
ORDER BY calls DESC
LIMIT 10;"

# Query 2: 10 slowest SELECT queries
# This query retrieves the top 10 slowest SELECT queries that have been called more than 1000 times.
# It calculates the average execution time, total time, and number of calls,
# and orders the results by average execution time in descending order.
# It also limits the results to the top 10 queries.
# The query uses the pg_stat_statements view to gather statistics about executed queries.
# It filters for queries that start with 'SELECT' and have more than 1000 calls.
# The results include the average time per call, total calls, total execution time, and the query text itself.
QUERY2="SELECT
    round((total_time/calls)::numeric, 2) as avg_time,
    calls,
    round(total_time::numeric, 2) as total_time,
    query
FROM pg_stat_statements
WHERE calls > 1000
    AND query ILIKE 'SELECT%'
ORDER BY avg_time DESC
LIMIT 10;"

# Query 3: Currently running slow queries
# This query retrieves currently running queries that have been running for more than 5 seconds.
# It selects the process ID (pid), the duration of the query, the query text,
# and the state of the query (e.g., active, idle).
# It orders the results by duration in descending order.
QUERY3="SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
    AND now() - pg_stat_activity.query_start > interval '5 seconds'
ORDER BY duration DESC;"

# Query 4: Queries touching most rows
# This query retrieves the top 10 SELECT queries that have touched the most rows.
# It calculates the average number of rows returned per call and orders by the total number of rows
# returned, limiting the results to the top 10.
QUERY4="SELECT
    query,
    rows,
    calls,
    rows/calls as avg_rows
FROM pg_stat_statements
WHERE query ILIKE 'SELECT%'
ORDER BY rows DESC
LIMIT 10;"

# Query 5: Blocked queries and their blocking processes
# Note: This query assumes you have the necessary permissions to view pg_locks and pg_stat_activity.
# It retrieves blocked queries and their corresponding blocking queries.
# The query uses pg_locks to find locks that are not granted and joins with pg_stat_activity to get the query text.
# It also ensures that the blocking process is different from the blocked process.
QUERY5="SELECT blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.granted;"

# Query 6: Oldest running query
QUERY6="SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC
LIMIT 1;"

# Query 7: find unused or low-use indices
# This query identifies indexes that are either never used or have low usage
# It calculates the scan percentage, writes, and size of the index and table.
# It groups the results into categories based on usage patterns.
# The categories include:
# - Never Used Indexes: Indexes that have never been scanned.
# - Low Scans, High Writes: Indexes that have low scan percentages but high writes.
# - Seldom Used Large Indexes: Indexes that have low scan percentages and high writes,
#   but are large in size.
# - High-Write Large Non-Btree: Non-Btree indexes that have high write activity
#   relative to total writes and are large in size.
# The query uses Common Table Expressions (CTEs) to calculate the necessary statistics
# and then aggregates the results into meaningful groups.
QUERY7="WITH table_scans as (
    SELECT relid,
        tables.idx_scan + tables.seq_scan as all_scans,
        ( tables.n_tup_ins + tables.n_tup_upd + tables.n_tup_del ) as writes,
                pg_relation_size(relid) as table_size
        FROM pg_stat_user_tables as tables
),
all_writes as (
    SELECT sum(writes) as total_writes
    FROM table_scans
),
indexes as (
    SELECT idx_stat.relid, idx_stat.indexrelid,
        idx_stat.schemaname, idx_stat.relname as tablename,
        idx_stat.indexrelname as indexname,
        idx_stat.idx_scan,
        pg_relation_size(idx_stat.indexrelid) as index_bytes,
        indexdef ~* 'USING btree' AS idx_is_btree
    FROM pg_stat_user_indexes as idx_stat
        JOIN pg_index
            USING (indexrelid)
        JOIN pg_indexes as indexes
            ON idx_stat.schemaname = indexes.schemaname
                AND idx_stat.relname = indexes.tablename
                AND idx_stat.indexrelname = indexes.indexname
    WHERE pg_index.indisunique = FALSE
),
index_ratios AS (
SELECT schemaname, tablename, indexname,
    idx_scan, all_scans,
    round(( CASE WHEN all_scans = 0 THEN 0.0::NUMERIC
        ELSE idx_scan::NUMERIC/all_scans * 100 END),2) as index_scan_pct,
    writes,
    round((CASE WHEN writes = 0 THEN idx_scan::NUMERIC ELSE idx_scan::NUMERIC/writes END),2)
        as scans_per_write,
    pg_size_pretty(index_bytes) as index_size,
    pg_size_pretty(table_size) as table_size,
    idx_is_btree, index_bytes
    FROM indexes
    JOIN table_scans
    USING (relid)
),
index_groups AS (
SELECT 'Never Used Indexes' as reason, *, 1 as grp
FROM index_ratios
WHERE
    idx_scan = 0
    and idx_is_btree
UNION ALL
SELECT 'Low Scans, High Writes' as reason, *, 2 as grp
FROM index_ratios
WHERE
    scans_per_write <= 1
    and index_scan_pct < 10
    and idx_scan > 0
    and writes > 100
    and idx_is_btree
UNION ALL
SELECT 'Seldom Used Large Indexes' as reason, *, 3 as grp
FROM index_ratios
WHERE
    index_scan_pct < 5
    and scans_per_write > 1
    and idx_scan > 0
    and idx_is_btree
    and index_bytes > 100000000
UNION ALL
SELECT 'High-Write Large Non-Btree' as reason, index_ratios.*, 4 as grp
FROM index_ratios, all_writes
WHERE
    ( writes::NUMERIC / ( total_writes + 1 ) ) > 0.02
    AND NOT idx_is_btree
    AND index_bytes > 100000000
ORDER BY grp, index_bytes DESC )
SELECT reason, schemaname, tablename, indexname,
    index_scan_pct, scans_per_write, index_size, table_size
FROM index_groups;"

# Query 8: Connection utilization
# This query retrieves the maximum number of connections allowed by the database,
# the current number of connections, and the percentage of connections used.
# It uses the pg_stat_activity view to count the current connections and pg_settings to get the     
# maximum connections setting.
QUERY8="WITH max_conn AS (
    SELECT setting::int as max_connections 
    FROM pg_settings 
    WHERE name = 'max_connections'
)
SELECT 
    max_conn.max_connections,
    COUNT(pid)::int AS current_connections,
    ROUND(COUNT(pid)::numeric / max_conn.max_connections::numeric * 100, 1) AS pct_used
FROM pg_stat_activity 
CROSS JOIN max_conn
GROUP BY max_conn.max_connections;"

# Query 9: Database sizes (allocated and actual)
# This query retrieves the allocated size and actual size of the current database.
# It uses pg_database to get the allocated size and pg_stat_user_tables to calculate the actual size.
# The results include the database name, allocated size, actual size, and storage efficiency percentage.
# The storage efficiency is calculated as the ratio of actual size to allocated size, expressed as a percentage.
# The pg_size_pretty function is used to format the sizes in a human-readable way.
# The query groups the results by database name to ensure it works correctly in multi-database environments.
# It also filters out system schemas (those starting with 'pg_') to focus on user-defined schemas.
# The query is designed to be run in the context of the current database, using `current_database()` 
# to ensure it retrieves information for the database being queried.
QUERY9="SELECT
    d.datname AS database_name,
    pg_size_pretty(pg_database_size(d.datname)) AS allocated_size,
    pg_size_pretty(SUM(pg_total_relation_size(relid))::bigint) AS actual_size,
    ROUND(SUM(pg_total_relation_size(relid))::numeric / pg_database_size(d.datname) * 100, 1) AS storage_efficiency
FROM pg_database d
    LEFT JOIN pg_stat_user_tables st ON st.schemaname NOT LIKE 'pg_%'
WHERE d.datname = current_database()
GROUP BY d.datname;"

# Query 10: Transaction age and wraparound status
# This query calculates the age of the current transaction ID (XID) in relation to the maximum possible XID.
# It uses the pg_database system catalog to get the current database's frozen transaction ID.
QUERY10="WITH max_age AS (
    SELECT 2147483647 AS max_old_xid
)
SELECT
    datname,
    age(datfrozenxid) AS current_xid_age,
    round(100 * age(datfrozenxid)::numeric / max_old_xid, 2) AS pct_towards_wraparound,
    CASE 
        WHEN age(datfrozenxid) < 500000000 THEN 'Safe'
        WHEN age(datfrozenxid) < 1000000000 THEN 'Monitor'
        WHEN age(datfrozenxid) < 1500000000 THEN 'Warning'
        ELSE 'Critical'
    END AS status,
    CASE 
        WHEN age(datfrozenxid) < 500000000 THEN 'No action needed'
        WHEN age(datfrozenxid) < 1000000000 THEN 'Plan VACUUM FREEZE within month'
        WHEN age(datfrozenxid) < 1500000000 THEN 'Schedule VACUUM FREEZE this week'
        ELSE 'Immediate VACUUM FREEZE required!'
    END AS recommendation
FROM pg_database, max_age
WHERE datname = current_database();"

# Query 11: Cache hit ratios
# This query retrieves cache hit ratios for heap, index, and toast blocks.
# It calculates the hit ratio as the percentage of blocks hit over the total blocks read.
# The results include the heap hit ratio, index hit ratio, and toast hit ratio.
# The pg_statio_user_tables view is used to get statistics about user tables.
# The hit ratio is calculated as the number of blocks hit divided by the total number of blocks read,
# multiplied by 100 to express it as a percentage.
QUERY11="WITH table_stats AS (
    SELECT 
        schemaname,
        relname as table_name,
        round(100 * heap_blks_hit::numeric / nullif(heap_blks_hit + heap_blks_read, 0), 2) AS heap_hit_ratio,
        round(100 * idx_blks_hit::numeric / nullif(idx_blks_hit + idx_blks_read, 0), 2) AS index_hit_ratio,
        round(100 * toast_blks_hit::numeric / nullif(toast_blks_hit + toast_blks_read, 0), 2) AS toast_hit_ratio,
        pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as toast_size,
        pg_total_relation_size(relid) - pg_relation_size(relid) as toast_bytes,
        CASE 
            WHEN pg_total_relation_size(relid) - pg_relation_size(relid) > 0 THEN 'Yes'
            ELSE 'No'
        END as uses_toast
    FROM pg_statio_user_tables
)
SELECT 
    schemaname,
    table_name,
    heap_hit_ratio,
    index_hit_ratio,
    COALESCE(toast_hit_ratio, 0) as toast_hit_ratio,
    COALESCE(toast_size, '0 bytes') as toast_size,
    uses_toast
FROM table_stats
ORDER BY toast_bytes DESC, table_name
LIMIT 10;"

# Query 12: Deadlocks and conflicts
# This query retrieves statistics about deadlocks, conflicts, temporary files, and temporary bytes.
QUERY12="SELECT
    deadlocks,
    conflicts,
    temp_files,
    pg_size_pretty(temp_bytes) AS temp_bytes_pretty
FROM pg_stat_database
WHERE datname = current_database();"

# Query for vacuum and autovacuum health monitoring
# Shows tables requiring maintenance with:
# - Dead tuple percentage
# - Current vacuum status
# - Maintenance recommendations
# Only displays tables needing attention (status != 'Good')
QUERY14="WITH table_stats AS (
    SELECT
        schemaname,
        relname,
        n_dead_tup,
        n_live_tup,
        last_vacuum,
        last_autovacuum,
        CASE 
            WHEN n_live_tup = 0 THEN 0
            ELSE round(n_dead_tup::numeric * 100 / (n_dead_tup + n_live_tup), 2)
        END as dead_tup_ratio,
        CASE
            WHEN last_autovacuum IS NULL AND last_vacuum IS NULL THEN 'Never vacuumed'
            WHEN last_autovacuum IS NULL THEN 'No autovacuum'
            WHEN age(now(), last_autovacuum) > interval '1 day' THEN 'Stale autovacuum'
            ELSE 'Recent autovacuum'
        END as vacuum_status
    FROM pg_stat_user_tables
),
status_info AS (
    SELECT
        *,
        CASE 
            WHEN dead_tup_ratio > 20 THEN 'Critical'
            WHEN dead_tup_ratio > 10 THEN 'Warning'
            WHEN vacuum_status IN ('Never vacuumed', 'Stale autovacuum') THEN 'Warning'
            ELSE 'Good'
        END as status
    FROM table_stats
)
SELECT
    schemaname as schema,
    relname as table_name,
    dead_tup_ratio as dead_tuple_percentage,
    vacuum_status,
    status,
    CASE 
        WHEN dead_tup_ratio > 20 THEN 
            'URGENT: Run VACUUM ANALYZE ' || quote_ident(schemaname) || '.' || quote_ident(relname)
        WHEN dead_tup_ratio > 10 THEN 
            'Run VACUUM ANALYZE ' || quote_ident(schemaname) || '.' || quote_ident(relname)
        WHEN vacuum_status = 'Never vacuumed' THEN
            'Schedule initial VACUUM ANALYZE ' || quote_ident(schemaname) || '.' || quote_ident(relname)
        WHEN vacuum_status = 'Stale autovacuum' THEN
            'Check autovacuum settings for ' || quote_ident(schemaname) || '.' || quote_ident(relname)
        WHEN vacuum_status = 'No autovacuum' THEN
            'Enable autovacuum for ' || quote_ident(schemaname) || '.' || quote_ident(relname)
        ELSE ''
    END as recommendation
FROM status_info
WHERE (n_dead_tup + n_live_tup) > 0
    AND (dead_tup_ratio > 10 OR vacuum_status != 'Recent autovacuum')
ORDER BY 
    CASE status
        WHEN 'Critical' THEN 1
        WHEN 'Warning' THEN 2
        ELSE 3
    END,
    dead_tup_ratio DESC
LIMIT 10;"

# Header
echo "Database report"
echo "- Database server: $HOST"
echo "- Database: $DATABASE"

# Execute all queries
run_query "10 Slowest Queries (>1000 calls)" "$QUERY1"
run_query "10 Slowest SELECT Queries (>1000 calls)" "$QUERY2"
run_query "Currently Running Slow Queries" "$QUERY3"
run_query "10 SELECT Queries Touching Most Rows" "$QUERY4"
run_query "Oldest Running Query" "$QUERY6"
run_query "Blocked Queries and Their Blocking Processes" "$QUERY5"
run_query "Unused or Low-Use Indices" "$QUERY7"
run_query "Connection Utilization" "$QUERY8"
run_query "Database Size Analysis" "$QUERY9"
run_query "Transaction Age Status" "$QUERY10"
run_query "Cache Hit Ratios" "$QUERY11"
run_query "Deadlocks and Conflicts" "$QUERY12"
run_query "Vacuum Statistics and Recommendations" "$QUERY14"

# Cleanup
cleanup() {
    rm -f "$temp_file" 2>/dev/null
    unset PGPASSWORD
}
trap cleanup EXIT INT TERM