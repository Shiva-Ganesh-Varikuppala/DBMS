# Experiment 9: Railway Booking — Indexing and Query Performance

## 🎯 Objective

Create a Railway Booking table containing at least **5,000 records** and analyze query performance before and after creating indexes.

The experiment demonstrates:

- Single-column indexes
- Composite indexes
- Query execution plans using `EXPLAIN`
- Query execution time using `EXPLAIN ANALYZE`
- Comparison of query performance before and after indexing

---

## 🧠 Concepts Covered

- Database Indexing
- Single-Column Index
- Composite Index
- Primary Key Index
- Query Optimization
- Query Execution Plans
- `EXPLAIN`
- `EXPLAIN ANALYZE`
- Index Selectivity
- Composite Index and Leftmost-Prefix Rule
- Full Table Scan
- Index Scan

---

## 🏦 Problem Statement

A railway reservation system stores booking information such as passenger details, train information, source and destination stations, journey date, seat details, fare, and booking status.

The table contains at least **5,000 booking records**.

The objective is to determine how indexes affect query performance by:

1. Executing queries before creating additional indexes.
2. Examining their execution plans using `EXPLAIN`.
3. Creating single-column indexes.
4. Creating a composite index.
5. Executing the same queries again.
6. Comparing the execution plans and rows examined.

---

# 1. Database Used

This experiment is designed for the ByteXL-provided database:

```text
sandbox_db
```

Verify the selected database:

```sql
SELECT DATABASE();
```

Expected:

```text
sandbox_db
```

The SQL script does **not** create a separate database.

---

# 2. Railway Booking Table

The experiment uses the following table:

```text
railway_bookings
```

The table contains:

| Column | Description |
|---|---|
| `booking_id` | Unique booking identifier |
| `passenger_name` | Name of passenger |
| `age` | Passenger age |
| `gender` | Passenger gender |
| `train_number` | Train number |
| `train_name` | Train name |
| `source_station` | Boarding station |
| `destination_station` | Destination station |
| `journey_date` | Date of journey |
| `seat_number` | Allocated seat |
| `coach` | Coach number |
| `class_type` | Travel class |
| `fare` | Ticket fare |
| `booking_status` | Booking status |

---

# 3. Creating the Table

The table is created using:

```sql
CREATE TABLE railway_bookings (
    booking_id INT PRIMARY KEY,
    passenger_name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER') NOT NULL,
    train_number INT NOT NULL,
    train_name VARCHAR(100) NOT NULL,
    source_station VARCHAR(100) NOT NULL,
    destination_station VARCHAR(100) NOT NULL,
    journey_date DATE NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    coach VARCHAR(10) NOT NULL,
    class_type VARCHAR(20) NOT NULL,
    fare DECIMAL(10,2) NOT NULL,
    booking_status ENUM('CONFIRMED', 'WAITING', 'CANCELLED') NOT NULL
);
```

The `booking_id` is the primary key and therefore has an index automatically.

---

# 4. Generating 5,000 Records

The SQL file uses a MySQL recursive CTE to generate the records automatically.

```sql
WITH RECURSIVE numbers AS (
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM numbers
    WHERE n < 5000
)
```

The generated numbers are used to create realistic-looking railway booking data.

Verify the number of records:

```sql
SELECT COUNT(*) AS total_records
FROM railway_bookings;
```

Expected:

```text
+---------------+
| total_records |
+---------------+
|          5000 |
+---------------+
```

---

# 5. Query Performance Before Indexing

Initially, only the primary key index exists.

For example:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';
```

Another query:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;
```

And a query using two conditions:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';
```

---

# 6. Understanding EXPLAIN

`EXPLAIN` displays the execution plan selected by MySQL for a query.

Important columns include:

| Column | Meaning |
|---|---|
| `type` | Access method used by MySQL |
| `possible_keys` | Indexes that could potentially be used |
| `key` | Index actually selected |
| `key_len` | Length of the index portion used |
| `rows` | Estimated number of rows examined |
| `filtered` | Estimated percentage of rows filtered |
| `Extra` | Additional execution information |

---

# 7. Full Table Scan

Before creating indexes, a query such as:

```sql
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';
```

may require MySQL to examine many rows because there is no index on `passenger_name`.

The execution plan may show:

```text
type = ALL
```

`ALL` generally indicates a full table scan.

Conceptually:

```text
Query
  ↓
Scan railway_bookings
  ↓
Check each row
  ↓
Find matching passenger
```

---

# 8. Creating a Single-Column Index

Create an index on `passenger_name`:

```sql
CREATE INDEX idx_railway_passenger_name
ON railway_bookings(passenger_name);
```

Verify:

```sql
SHOW INDEX FROM railway_bookings;
```

Run the same query again:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';
```

MySQL can now use:

```text
idx_railway_passenger_name
```

This can reduce the number of rows that need to be examined.

---

# 9. Index on Train Number

Create another single-column index:

```sql
CREATE INDEX idx_railway_train_number
ON railway_bookings(train_number);
```

Verify:

```sql
SHOW INDEX FROM railway_bookings;
```

Run:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;
```

The execution plan can now use:

```text
idx_railway_train_number
```

---

# 10. Composite Index

A composite index contains more than one column.

Create:

```sql
CREATE INDEX idx_railway_train_date
ON railway_bookings(train_number, journey_date);
```

This index contains the columns in this order:

```text
train_number → journey_date
```

It is particularly useful for queries that filter by both columns.

Example:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';
```

MySQL can use:

```text
idx_railway_train_date
```

---

# 11. Composite Index with a Date Range

The composite index can also help with a query such as:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date
      BETWEEN '2026-06-01' AND '2026-06-30';
```

This demonstrates how a composite index can support queries involving an equality condition followed by a range condition.

---

# 12. Leftmost-Prefix Rule

The composite index is:

```text
(train_number, journey_date)
```

The first column is:

```text
train_number
```

Therefore, the index can generally be used efficiently for:

```sql
WHERE train_number = 12005
```

and:

```sql
WHERE train_number = 12005
AND journey_date = '2026-06-15'
```

However, it is not equivalent to having an index whose first column is `journey_date`.

Test:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;
```

Then:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE journey_date = '2026-06-15';
```

Compare the execution plans.

---

# 13. EXPLAIN ANALYZE

`EXPLAIN ANALYZE` executes the query and provides information about its actual execution.

Example:

```sql
EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';
```

It can provide information such as:

- Actual execution time
- Number of rows produced
- Number of loops
- Actual rows processed
- Execution plan

This is useful for comparing the actual behavior of queries.

---

# 14. Benchmarking Process

The experiment follows this sequence:

```text
             Railway Booking Table
                     │
                     ▼
                5,000 Rows
                     │
                     ▼
        ┌────────────────────────┐
        │ Query Before Indexing  │
        └────────────────────────┘
                     │
                     ▼
                  EXPLAIN
                     │
                     ▼
        Create Single-Column Index
                     │
                     ▼
                  EXPLAIN
                     │
                     ▼
        Create Composite Index
                     │
                     ▼
                  EXPLAIN
                     │
                     ▼
              Compare Results
```

---

# 15. Indexes Created

The experiment creates three additional indexes:

| Index | Columns | Purpose |
|---|---|---|
| `idx_railway_passenger_name` | `passenger_name` | Search passengers |
| `idx_railway_train_number` | `train_number` | Search trains |
| `idx_railway_train_date` | `train_number, journey_date` | Search train + date |

The primary key index on `booking_id` is created automatically.

---

# 16. Important Verification Queries

Check the number of records:

```sql
SELECT COUNT(*) AS total_records
FROM railway_bookings;
```

View sample records:

```sql
SELECT *
FROM railway_bookings
LIMIT 10;
```

Display all indexes:

```sql
SHOW INDEX FROM railway_bookings;
```

Check the execution plan:

```sql
EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;
```

Check actual execution:

```sql
EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005;
```

---

# 17. Expected Observation

Before indexing, queries on non-indexed columns may require a larger number of rows to be examined.

After creating suitable indexes, MySQL may choose an index access method and examine fewer rows.

For example:

```text
BEFORE INDEX

Query
  ↓
Full Table Scan
  ↓
Many rows examined


AFTER INDEX

Query
  ↓
Index Lookup
  ↓
Fewer rows examined
```

The exact execution plan and timing depend on the MySQL optimizer, available indexes, data distribution, and the ByteXL environment.

Therefore, the actual `EXPLAIN` output should be used as the experimental result rather than assuming a particular timing or row count.

---

# 18. Comparison Table

The results can be recorded in the following format:

| Query | Before Index | After Index | Index Used |
|---|---|---|---|
| Search by passenger | Compare `EXPLAIN` | Compare `EXPLAIN` | `idx_railway_passenger_name` |
| Search by train | Compare `EXPLAIN` | Compare `EXPLAIN` | `idx_railway_train_number` |
| Train + date | Compare `EXPLAIN` | Compare `EXPLAIN` | `idx_railway_train_date` |

---

# 19. Result

The Railway Booking table was successfully created with at least **5,000 records**.

Query execution plans were examined before and after creating indexes. Single-column indexes were created for `passenger_name` and `train_number`, while a composite index was created on `train_number` and `journey_date`.

Using `EXPLAIN` and `EXPLAIN ANALYZE`, the execution plans and query behavior could be compared to understand how appropriate indexes can improve query performance.

---

# 20. Conclusion

The experiment demonstrates the importance of database indexing for query optimization.

Single-column indexes are useful when queries frequently search using one particular column, while composite indexes are useful when queries commonly filter using multiple columns together.

The `EXPLAIN` command helps understand how MySQL plans to execute a query, while `EXPLAIN ANALYZE` provides information about the actual execution.

Thus, indexing can reduce unnecessary row scanning and improve the efficiency of frequently executed queries, although the actual benefit depends on the query, data distribution, and optimizer decisions.

---

## 📁 Files

```text
Experiment_9_Railway_Booking_Indexing.sql
README.md
```

Run the SQL file in the ByteXL MySQL editor connected to `sandbox_db`.