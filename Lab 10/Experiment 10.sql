-- ============================================================
-- EXPERIMENT 10
-- Query Optimization Using EXPLAIN, Indexing and Query Rewriting
--
-- Database: ByteXL sandbox_db
--
-- Objective:
--   1. Generate a dataset with at least 10,000 rows.
--   2. Execute five intentionally inefficient/slow queries.
--   3. Analyze them using EXPLAIN / EXPLAIN ANALYZE.
--   4. Optimize them using indexes and query rewriting.
--   5. Compare execution plans and execution time before/after.
--
-- MySQL 8.0+
-- ============================================================


-- ============================================================
-- 0. VERIFY DATABASE
-- ============================================================

SELECT DATABASE();


-- ============================================================
-- 1. CLEANUP
-- ============================================================

DROP TABLE IF EXISTS sales_data;


-- ============================================================
-- 2. CREATE DATASET
-- ============================================================

CREATE TABLE sales_data (
    sale_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_city VARCHAR(50) NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sale_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    sales_status VARCHAR(20) NOT NULL
) ENGINE = InnoDB;


-- ============================================================
-- 3. GENERATE 10,000 RECORDS
-- ============================================================

SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO sales_data
(
    sale_id,
    customer_name,
    customer_city,
    product_name,
    category,
    sale_date,
    quantity,
    unit_price,
    total_amount,
    payment_method,
    sales_status
)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n

    UNION ALL

    SELECT n + 1
    FROM numbers
    WHERE n < 10000
)
SELECT
    n AS sale_id,

    CONCAT(
        'Customer_',
        LPAD(MOD(n - 1, 2000) + 1, 4, '0')
    ) AS customer_name,

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
    END AS customer_city,

    CASE MOD(n, 20)
        WHEN 0 THEN 'Express Laptop'
        WHEN 1 THEN 'Office Laptop'
        WHEN 2 THEN 'Gaming Laptop'
        WHEN 3 THEN 'Wireless Mouse'
        WHEN 4 THEN 'Mechanical Keyboard'
        WHEN 5 THEN 'USB Keyboard'
        WHEN 6 THEN 'Noise Cancelling Headphones'
        WHEN 7 THEN 'Bluetooth Headphones'
        WHEN 8 THEN 'Smartphone Pro'
        WHEN 9 THEN 'Smartphone Lite'
        WHEN 10 THEN 'Express Monitor'
        WHEN 11 THEN '4K Monitor'
        WHEN 12 THEN 'Tablet Pro'
        WHEN 13 THEN 'Tablet Mini'
        WHEN 14 THEN 'Smart Watch'
        WHEN 15 THEN 'Fitness Watch'
        WHEN 16 THEN 'Express Printer'
        WHEN 17 THEN 'Laser Printer'
        WHEN 18 THEN 'External SSD'
        ELSE 'USB Drive'
    END AS product_name,

    CASE MOD(n, 5)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Computers'
        WHEN 2 THEN 'Accessories'
        WHEN 3 THEN 'Mobile'
        ELSE 'Office'
    END AS category,

    DATE_ADD(
        '2025-01-01',
        INTERVAL MOD(n * 17, 730) DAY
    ) AS sale_date,

    1 + MOD(n, 10) AS quantity,

    ROUND(
        100 + MOD(n * 83, 9900),
        2
    ) AS unit_price,

    ROUND(
        (1 + MOD(n, 10)) * (100 + MOD(n * 83, 9900)),
        2
    ) AS total_amount,

    CASE MOD(n, 4)
        WHEN 0 THEN 'UPI'
        WHEN 1 THEN 'CARD'
        WHEN 2 THEN 'CASH'
        ELSE 'NET_BANKING'
    END AS payment_method,

    CASE
        WHEN MOD(n, 10) <= 7 THEN 'COMPLETED'
        WHEN MOD(n, 10) = 8 THEN 'PENDING'
        ELSE 'CANCELLED'
    END AS sales_status

FROM numbers;


-- ============================================================
-- 4. VERIFY DATASET
-- ============================================================

SELECT COUNT(*) AS total_records
FROM sales_data;

SELECT *
FROM sales_data
ORDER BY sale_id
LIMIT 10;


-- ============================================================
-- 5. INITIAL INDEX STATE
--
-- Only the PRIMARY KEY index exists at this point.
-- ============================================================

SHOW INDEX FROM sales_data;


-- ============================================================
-- IMPORTANT BENCHMARK NOTE
--
-- EXPLAIN ANALYZE actually executes the query and reports
-- actual execution information, including timing.
--
-- If ByteXL does not support EXPLAIN ANALYZE, use EXPLAIN
-- instead and compare the 'rows' and 'type' columns.
-- ============================================================


-- ============================================================
-- SLOW QUERY 1
-- YEAR() applied to sale_date
--
-- Problem:
-- Applying YEAR() to the indexed column prevents a normal
-- B-tree index lookup on sale_date.
-- ============================================================

EXPLAIN
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE YEAR(sale_date) = 2026;

-- Actual execution benchmark:
EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE YEAR(sale_date) = 2026;


-- ============================================================
-- OPTIMIZATION 1
-- Create index on sale_date.
-- Rewrite YEAR() condition as a date range.
-- ============================================================

CREATE INDEX idx_sales_sale_date
ON sales_data(sale_date);

EXPLAIN
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01';


-- ============================================================
-- SLOW QUERY 2
-- LOWER() applied to customer_name
--
-- Problem:
-- Applying LOWER() to the column makes a normal index on
-- customer_name ineffective for this form of predicate.
-- ============================================================

EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE LOWER(customer_name) = 'customer_0500';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE LOWER(customer_name) = 'customer_0500';


-- ============================================================
-- OPTIMIZATION 2
-- Index customer_name and rewrite the predicate.
--
-- The generated names are stored in a consistent case, so
-- the direct equality predicate is appropriate here.
-- ============================================================

CREATE INDEX idx_sales_customer_name
ON sales_data(customer_name);

EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE customer_name = 'Customer_0500';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE customer_name = 'Customer_0500';


-- ============================================================
-- SLOW QUERY 3
-- OR condition across two different columns
--
-- Problem:
-- Searching source-like and destination-like attributes with
-- an OR can result in a less efficient plan.
--
-- Here we use customer_city and category as two filter
-- columns to demonstrate rewriting OR into UNION ALL.
-- ============================================================

EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE customer_city = 'Delhi'
   OR category = 'Electronics';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE customer_city = 'Delhi'
   OR category = 'Electronics';


-- ============================================================
-- OPTIMIZATION 3
-- Create indexes for both filter columns.
-- Rewrite OR using UNION.
--
-- UNION (rather than UNION ALL) removes duplicate rows.
-- This preserves the result of the original OR query.
-- ============================================================

CREATE INDEX idx_sales_city
ON sales_data(customer_city);

CREATE INDEX idx_sales_category
ON sales_data(category);

EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE customer_city = 'Delhi'

UNION

SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE category = 'Electronics';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE customer_city = 'Delhi'

UNION

SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE category = 'Electronics';


-- ============================================================
-- SLOW QUERY 4
-- Leading-wildcard LIKE
--
-- Problem:
-- LIKE '%Express%' cannot normally use a standard B-tree
-- index efficiently because the search starts with '%'.
-- ============================================================

EXPLAIN
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE product_name LIKE '%Express%';

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE product_name LIKE '%Express%';


-- ============================================================
-- OPTIMIZATION 4
-- Use a FULLTEXT index and MATCH ... AGAINST for word search.
--
-- This is a query rewrite as well as an indexing optimization.
-- ============================================================

CREATE FULLTEXT INDEX idx_sales_product_fulltext
ON sales_data(product_name);

EXPLAIN
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE MATCH(product_name)
      AGAINST('+Express' IN BOOLEAN MODE);

EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE MATCH(product_name)
      AGAINST('+Express' IN BOOLEAN MODE);


-- ============================================================
-- SLOW QUERY 5
-- Correlated subquery for each row
--
-- Problem:
-- The subquery calculates the category average repeatedly
-- for rows from the outer query.
-- ============================================================

EXPLAIN
SELECT
    s.sale_id,
    s.product_name,
    s.category,
    s.total_amount
FROM sales_data s
WHERE s.total_amount >
(
    SELECT AVG(s2.total_amount)
    FROM sales_data s2
    WHERE s2.category = s.category
);

EXPLAIN ANALYZE
SELECT
    s.sale_id,
    s.product_name,
    s.category,
    s.total_amount
FROM sales_data s
WHERE s.total_amount >
(
    SELECT AVG(s2.total_amount)
    FROM sales_data s2
    WHERE s2.category = s.category
);


-- ============================================================
-- OPTIMIZATION 5
-- Rewrite the correlated subquery as a JOIN against a
-- precomputed category aggregate.
--
-- Index category to support the grouping/join.
-- ============================================================

CREATE INDEX idx_sales_category_total
ON sales_data(category, total_amount);

EXPLAIN
SELECT
    s.sale_id,
    s.product_name,
    s.category,
    s.total_amount
FROM sales_data s
JOIN
(
    SELECT
        category,
        AVG(total_amount) AS avg_category_amount
    FROM sales_data
    GROUP BY category
) a
    ON a.category = s.category
WHERE s.total_amount > a.avg_category_amount;

EXPLAIN ANALYZE
SELECT
    s.sale_id,
    s.product_name,
    s.category,
    s.total_amount
FROM sales_data s
JOIN
(
    SELECT
        category,
        AVG(total_amount) AS avg_category_amount
    FROM sales_data
    GROUP BY category
) a
    ON a.category = s.category
WHERE s.total_amount > a.avg_category_amount;


-- ============================================================
-- 6. FINAL INDEX LIST
-- ============================================================

SHOW INDEX FROM sales_data;


-- ============================================================
-- 7. FINAL DATA VERIFICATION
-- ============================================================

SELECT COUNT(*) AS total_records
FROM sales_data;

SELECT
    MIN(sale_date) AS earliest_sale,
    MAX(sale_date) AS latest_sale,
    SUM(total_amount) AS total_sales
FROM sales_data;


-- ============================================================
-- 8. OPTIONAL: FORCE/IGNORE INDEX FOR EDUCATIONAL COMPARISON
--
-- These statements can be used to compare a plan with and
-- without an index when the optimizer chooses the same plan.
-- ============================================================

-- Example:
--
-- EXPLAIN
-- SELECT *
-- FROM sales_data
-- WHERE sale_date >= '2026-01-01'
--   AND sale_date < '2027-01-01';
--
-- EXPLAIN
-- SELECT *
-- FROM sales_data IGNORE INDEX (idx_sales_sale_date)
-- WHERE sale_date >= '2026-01-01'
--   AND sale_date < '2027-01-01';


-- ============================================================
-- 9. OPTIONAL CLEANUP
-- Run only after completing the experiment.
-- ============================================================

-- DROP INDEX idx_sales_sale_date ON sales_data;
-- DROP INDEX idx_sales_customer_name ON sales_data;
-- DROP INDEX idx_sales_city ON sales_data;
-- DROP INDEX idx_sales_category ON sales_data;
-- DROP INDEX idx_sales_product_fulltext ON sales_data;
-- DROP INDEX idx_sales_category_total ON sales_data;
-- DROP TABLE sales_data;


-- ============================================================
-- EXPECTED EXPERIMENT FLOW
--
-- BEFORE OPTIMIZATION
--     ↓
-- Execute 5 slow queries
--     ↓
-- EXPLAIN / EXPLAIN ANALYZE
--     ↓
-- Identify expensive scans / operations
--     ↓
-- Create appropriate indexes
--     ↓
-- Rewrite queries
--     ↓
-- EXPLAIN / EXPLAIN ANALYZE again
--     ↓
-- Compare execution plans and timing
--
-- Five optimization techniques:
--
-- 1. YEAR(sale_date)
--       ↓
--    Date range + index on sale_date
--
-- 2. LOWER(customer_name)
--       ↓
--    Direct equality + index on customer_name
--
-- 3. OR condition
--       ↓
--    Indexes + UNION rewrite
--
-- 4. LIKE '%Express%'
--       ↓
--    FULLTEXT index + MATCH ... AGAINST
--
-- 5. Correlated aggregate subquery
--       ↓
--    Precomputed GROUP BY + JOIN
--
-- ============================================================
-- END OF EXPERIMENT 10
-- ============================================================
