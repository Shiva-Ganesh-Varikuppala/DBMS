-- ============================================================
-- EXPERIMENT 9
-- Railway Booking: Indexing and Query Performance
--
-- Objective:
--   1. Create a Railway Booking table with at least 5,000 records.
--   2. Benchmark query performance before indexes.
--   3. Create single-column indexes.
--   4. Create a composite index.
--   5. Use EXPLAIN / EXPLAIN ANALYZE to compare execution plans.
--
-- Database:
--   ByteXL sandbox_db
--
-- MySQL:
--   MySQL 8.0+
--
-- IMPORTANT:
--   This script does NOT create or drop a database.
--   It works inside the ByteXL-provided sandbox_db.
-- ============================================================


-- ============================================================
-- 0. VERIFY DATABASE
-- ============================================================

SELECT DATABASE();


-- ============================================================
-- 1. CLEAN PREVIOUS EXPERIMENT TABLE
-- ============================================================

DROP TABLE IF EXISTS railway_bookings;


-- ============================================================
-- 2. CREATE RAILWAY BOOKING TABLE
-- ============================================================

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
) ENGINE = InnoDB;


-- ============================================================
-- 3. INSERT AT LEAST 5,000 RECORDS
--
-- MySQL 8.0 recursive CTE generates 5,000 rows.
-- ============================================================

SET SESSION cte_max_recursion_depth = 6000;

INSERT INTO railway_bookings
(
    booking_id,
    passenger_name,
    age,
    gender,
    train_number,
    train_name,
    source_station,
    destination_station,
    journey_date,
    seat_number,
    coach,
    class_type,
    fare,
    booking_status
)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM numbers
    WHERE n < 5000
)
SELECT
    n AS booking_id,

    CONCAT(
        'Passenger_',
        LPAD(MOD(n - 1, 1000) + 1, 4, '0')
    ) AS passenger_name,

    18 + MOD(n, 63) AS age,

    CASE MOD(n, 3)
        WHEN 0 THEN 'MALE'
        WHEN 1 THEN 'FEMALE'
        ELSE 'OTHER'
    END AS gender,

    12000 + MOD(n, 20) AS train_number,

    CASE MOD(n, 20)
        WHEN 0 THEN 'Rajdhani Express'
        WHEN 1 THEN 'Shatabdi Express'
        WHEN 2 THEN 'Duronto Express'
        WHEN 3 THEN 'Vande Bharat Express'
        WHEN 4 THEN 'Garib Rath'
        WHEN 5 THEN 'Deccan Express'
        WHEN 6 THEN 'Konkan Kanya'
        WHEN 7 THEN 'Chennai Express'
        WHEN 8 THEN 'Howrah Mail'
        WHEN 9 THEN 'Grand Trunk Express'
        WHEN 10 THEN 'Karnataka Express'
        WHEN 11 THEN 'Punjab Mail'
        WHEN 12 THEN 'Golden Temple Mail'
        WHEN 13 THEN 'Kerala Express'
        WHEN 14 THEN 'Goa Express'
        WHEN 15 THEN 'Andhra Pradesh Express'
        WHEN 16 THEN 'Tamil Nadu Express'
        WHEN 17 THEN 'Himsagar Express'
        WHEN 18 THEN 'Nizamuddin Express'
        ELSE 'A.P. Sampark Kranti'
    END AS train_name,

    CASE MOD(n, 10)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Chennai'
        WHEN 3 THEN 'Hyderabad'
        WHEN 4 THEN 'Bengaluru'
        WHEN 5 THEN 'Kolkata'
        WHEN 6 THEN 'Pune'
        WHEN 7 THEN 'Jaipur'
        WHEN 8 THEN 'Ahmedabad'
        ELSE 'Lucknow'
    END AS source_station,

    CASE MOD(n + 3, 10)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Chennai'
        WHEN 3 THEN 'Hyderabad'
        WHEN 4 THEN 'Bengaluru'
        WHEN 5 THEN 'Kolkata'
        WHEN 6 THEN 'Pune'
        WHEN 7 THEN 'Jaipur'
        WHEN 8 THEN 'Ahmedabad'
        ELSE 'Lucknow'
    END AS destination_station,

    DATE_ADD(
        '2026-01-01',
        INTERVAL MOD(n, 365) DAY
    ) AS journey_date,

    CONCAT(
        CASE MOD(n, 4)
            WHEN 0 THEN 'A'
            WHEN 1 THEN 'B'
            WHEN 2 THEN 'C'
            ELSE 'D'
        END,
        LPAD(MOD(n - 1, 72) + 1, 2, '0')
    ) AS seat_number,

    CASE MOD(n, 4)
        WHEN 0 THEN 'A1'
        WHEN 1 THEN 'A2'
        WHEN 2 THEN 'B1'
        ELSE 'B2'
    END AS coach,

    CASE MOD(n, 4)
        WHEN 0 THEN 'AC 1-Tier'
        WHEN 1 THEN 'AC 2-Tier'
        WHEN 2 THEN 'AC 3-Tier'
        ELSE 'Sleeper'
    END AS class_type,

    ROUND(
        350 + MOD(n * 37, 4650),
        2
    ) AS fare,

    CASE
        WHEN MOD(n, 10) <= 6 THEN 'CONFIRMED'
        WHEN MOD(n, 10) <= 8 THEN 'WAITING'
        ELSE 'CANCELLED'
    END AS booking_status

FROM numbers;


-- ============================================================
-- 4. VERIFY RECORD COUNT
-- ============================================================

SELECT COUNT(*) AS total_records
FROM railway_bookings;


-- Expected:
-- +---------------+
-- | total_records |
-- +---------------+
-- |          5000 |
-- +---------------+


-- ============================================================
-- 5. VIEW SAMPLE RECORDS
-- ============================================================

SELECT *
FROM railway_bookings
ORDER BY booking_id
LIMIT 10;


-- ============================================================
-- 6. BASELINE: QUERY PERFORMANCE BEFORE INDEXES
--
-- At this point only the PRIMARY KEY index exists.
-- The following queries deliberately use columns without
-- additional indexes.
-- ============================================================


-- ------------------------------------------------------------
-- 6A. Search by passenger_name
-- ------------------------------------------------------------

EXPLAIN
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';


-- Optional runtime measurement:
-- Run this if your ByteXL MySQL version supports EXPLAIN ANALYZE.

EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';


-- ------------------------------------------------------------
-- 6B. Search by train_number
-- ------------------------------------------------------------

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005;


-- ------------------------------------------------------------
-- 6C. Search using TWO columns
-- This will be useful for the composite index later.
-- ------------------------------------------------------------

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';


-- ============================================================
-- 7. SINGLE-COLUMN INDEX 1
-- Index passenger_name
-- ============================================================

CREATE INDEX idx_railway_passenger_name
ON railway_bookings(passenger_name);


-- Verify:
SHOW INDEX FROM railway_bookings;


-- Compare the same query after the single-column index.

EXPLAIN
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE passenger_name = 'Passenger_0500';


-- Expected observation:
-- The optimizer can use:
--     idx_railway_passenger_name


-- ============================================================
-- 8. SINGLE-COLUMN INDEX 2
-- Index train_number
-- ============================================================

CREATE INDEX idx_railway_train_number
ON railway_bookings(train_number);


SHOW INDEX FROM railway_bookings;


-- Compare before/after plan for train_number.

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005;


-- Expected observation:
-- The optimizer can use:
--     idx_railway_train_number


-- ============================================================
-- 9. COMPOSITE INDEX
-- Composite index on:
--     (train_number, journey_date)
--
-- Column order matters.
-- This index is especially suitable for queries that filter
-- by train_number and journey_date together.
-- ============================================================

CREATE INDEX idx_railway_train_date
ON railway_bookings(train_number, journey_date);


SHOW INDEX FROM railway_bookings;


-- ============================================================
-- 10. EXPLAIN AFTER COMPOSITE INDEX
-- ============================================================

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date = '2026-06-15';


-- Expected observation:
-- The optimizer can use:
--     idx_railway_train_date


-- ============================================================
-- 11. COMPOSITE INDEX WITH RANGE CONDITION
-- ============================================================

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date BETWEEN '2026-06-01' AND '2026-06-30';


EXPLAIN ANALYZE
SELECT *
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date BETWEEN '2026-06-01' AND '2026-06-30';


-- ============================================================
-- 12. TESTING THE LEFTMOST-PREFIX PROPERTY
--
-- The composite index is:
--     (train_number, journey_date)
--
-- It is useful for:
--     train_number
--     train_number + journey_date
--
-- It is NOT generally equivalent to an index on
-- journey_date alone.
-- ============================================================

EXPLAIN
SELECT *
FROM railway_bookings
WHERE train_number = 12005;


EXPLAIN
SELECT *
FROM railway_bookings
WHERE journey_date = '2026-06-15';


-- ============================================================
-- 13. ANOTHER QUERY FOR BENCHMARKING
-- ============================================================

EXPLAIN
SELECT
    train_number,
    train_name,
    journey_date,
    COUNT(*) AS booking_count
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY train_number, train_name, journey_date;


EXPLAIN ANALYZE
SELECT
    train_number,
    train_name,
    journey_date,
    COUNT(*) AS booking_count
FROM railway_bookings
WHERE train_number = 12005
  AND journey_date BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY train_number, train_name, journey_date;


-- ============================================================
-- 14. INDEX INFORMATION
-- ============================================================

SHOW INDEX FROM railway_bookings;


-- ============================================================
-- 15. FINAL DATA CHECK
-- ============================================================

SELECT COUNT(*) AS total_records
FROM railway_bookings;

SELECT
    MIN(booking_id) AS first_booking_id,
    MAX(booking_id) AS last_booking_id
FROM railway_bookings;


-- ============================================================
-- 16. OPTIONAL CLEANUP
--
-- Run only if you want to remove the indexes and table after
-- completing the experiment.
-- ============================================================

-- DROP INDEX idx_railway_passenger_name ON railway_bookings;
-- DROP INDEX idx_railway_train_number ON railway_bookings;
-- DROP INDEX idx_railway_train_date ON railway_bookings;
-- DROP TABLE railway_bookings;


-- ============================================================
-- EXPECTED EXPERIMENT FLOW
--
-- 1. Create railway_bookings
-- 2. Insert 5,000 records
-- 3. Verify COUNT(*)
-- 4. EXPLAIN queries before additional indexes
-- 5. Create single-column index on passenger_name
-- 6. EXPLAIN the passenger query again
-- 7. Create single-column index on train_number
-- 8. EXPLAIN the train query again
-- 9. Create composite index on (train_number, journey_date)
-- 10. EXPLAIN the combined train/date query
-- 11. Compare execution plans and rows examined
--
-- Key EXPLAIN columns to observe:
--     type
--     possible_keys
--     key
--     key_len
--     rows
--     filtered
--     Extra
--
-- ============================================================
-- END OF EXPERIMENT 9
-- ============================================================
