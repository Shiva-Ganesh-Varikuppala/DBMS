# Experiment 10: Query Optimization Using EXPLAIN, Indexing and Query Rewriting

## 🎯 Objective

Generate a dataset containing at least **10,000 rows** and identify inefficient SQL queries.

The queries are analyzed using `EXPLAIN` and `EXPLAIN ANALYZE`, then optimized using appropriate indexing and query rewriting techniques. The execution plans and performance before and after optimization are compared.

---

## 🧠 Concepts Covered

- Query Optimization
- Database Indexing
- Single-Column Index
- Composite Index
- Full-Text Index
- Query Rewriting
- `EXPLAIN`
- `EXPLAIN ANALYZE`
- Full Table Scan
- Index Scan
- Range Scan
- Correlated Subqueries
- `UNION`
- Aggregate Queries
- MySQL Query Optimizer

---

# 1. Database Used

This experiment is designed for the ByteXL-provided database:

```text
sandbox_db
```

Verify the current database:

```sql
SELECT DATABASE();
```

Expected:

```text
sandbox_db
```

No separate database needs to be created.

---

# 2. Problem Statement

A sales system contains a large dataset of customer transactions.

When the amount of data increases, poorly written SQL queries can become expensive because the database may have to scan a large number of rows.

The experiment demonstrates how query performance can be improved by:

1. Identifying slow queries.
2. Analyzing their execution plans.
3. Creating suitable indexes.
4. Rewriting inefficient queries.
5. Comparing the execution plans and execution times before and after optimization.

---

# 3. Dataset

The experiment creates the following table:

```text
sales_data
```

The table contains **10,000 records**.

The major attributes are:

| Column | Description |
|---|---|
| `sale_id` | Unique sale identifier |
| `customer_name` | Customer name |
| `customer_city` | Customer's city |
| `product_name` | Product name |
| `category` | Product category |
| `sale_date` | Date of sale |
| `quantity` | Quantity purchased |
| `unit_price` | Price per unit |
| `total_amount` | Total sale amount |
| `payment_method` | Payment method |
| `sales_status` | Sale status |

---

# 4. Creating the Dataset

The SQL script uses a recursive CTE to generate 10,000 records automatically.

```sql
SET SESSION cte_max_recursion_depth = 11000;
```

The generated records contain different customers, cities, products, categories, dates, quantities, prices, payment methods, and statuses.

Verify the number of records:

```sql
SELECT COUNT(*) AS total_records
FROM sales_data;
```

Expected:

```text
+---------------+
| total_records |
+---------------+
|         10000 |
+---------------+
```

---

# 5. Initial Index State

Before optimization, the table has only the primary key index on:

```text
sale_id
```

Verify the indexes:

```sql
SHOW INDEX FROM sales_data;
```

This gives us a baseline for the experiment.

---

# 6. Understanding EXPLAIN

The `EXPLAIN` statement shows how MySQL intends to execute a query.

Example:

```sql
EXPLAIN
SELECT *
FROM sales_data
WHERE customer_name = 'Customer_0500';
```

Important columns include:

| Column | Meaning |
|---|---|
| `type` | Method used to access the data |
| `possible_keys` | Indexes MySQL could use |
| `key` | Index actually selected |
| `key_len` | Length of the index used |
| `rows` | Estimated rows to examine |
| `filtered` | Estimated percentage of rows retained |
| `Extra` | Additional execution information |

---

# 7. Understanding EXPLAIN ANALYZE

`EXPLAIN ANALYZE` actually executes the query and reports information about its execution.

Example:

```sql
EXPLAIN ANALYZE
SELECT *
FROM sales_data
WHERE customer_name = 'Customer_0500';
```

It can show:

- Actual execution time
- Actual rows processed
- Number of loops
- Execution plan
- Estimated versus actual behavior

This is useful when comparing query performance before and after optimization.

> If the ByteXL MySQL environment does not support `EXPLAIN ANALYZE`, use `EXPLAIN` and compare the execution-plan details such as `type`, `key`, and `rows`.

---

# 8. Slow Query 1 — Function on Date Column

The first inefficient query uses `YEAR()` on the `sale_date` column:

```sql
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE YEAR(sale_date) = 2026;
```

Analyze it:

```sql
EXPLAIN
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE YEAR(sale_date) = 2026;
```

And:

```sql
EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE YEAR(sale_date) = 2026;
```

### Problem

Applying a function to the indexed column can prevent MySQL from using a normal B-tree index efficiently for the date lookup.

---

# 9. Optimization 1 — Date Index and Range Query

Create an index:

```sql
CREATE INDEX idx_sales_sale_date
ON sales_data(sale_date);
```

Instead of:

```sql
WHERE YEAR(sale_date) = 2026
```

rewrite the query as:

```sql
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01'
```

Optimized query:

```sql
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01';
```

Analyze again:

```sql
EXPLAIN
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01';
```

And:

```sql
EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    sale_date,
    total_amount
FROM sales_data
WHERE sale_date >= '2026-01-01'
  AND sale_date < '2027-01-01';
```

---

# 10. Slow Query 2 — Function on Customer Name

The second inefficient query applies `LOWER()` to the column:

```sql
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE LOWER(customer_name) = 'customer_0500';
```

Analyze it:

```sql
EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE LOWER(customer_name) = 'customer_0500';
```

### Problem

Applying a function to the column can prevent efficient use of a normal index on that column.

---

# 11. Optimization 2 — Customer Name Index

Create:

```sql
CREATE INDEX idx_sales_customer_name
ON sales_data(customer_name);
```

The generated customer names use a consistent case, so the query can be rewritten as:

```sql
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE customer_name = 'Customer_0500';
```

Analyze the optimized query:

```sql
EXPLAIN
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE customer_name = 'Customer_0500';
```

And:

```sql
EXPLAIN ANALYZE
SELECT
    sale_id,
    customer_name,
    customer_city,
    total_amount
FROM sales_data
WHERE customer_name = 'Customer_0500';
```

---

# 12. Slow Query 3 — OR Condition

The third query uses an `OR` condition:

```sql
SELECT
    sale_id,
    customer_name,
    customer_city,
    category,
    total_amount
FROM sales_data
WHERE customer_city = 'Delhi'
   OR category = 'Electronics';
```

Analyze:

```sql
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
```

### Problem

An `OR` involving different columns can result in a less efficient execution plan depending on data distribution and available indexes.

---

# 13. Optimization 3 — Indexes and UNION

Create indexes:

```sql
CREATE INDEX idx_sales_city
ON sales_data(customer_city);

CREATE INDEX idx_sales_category
ON sales_data(category);
```

Rewrite the query using `UNION`:

```sql
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
```

`UNION` is used instead of `UNION ALL` because the original `OR` condition should return each matching row only once.

Analyze:

```sql
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
```

---

# 14. Slow Query 4 — Leading Wildcard

The fourth query searches for a word using a leading wildcard:

```sql
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE product_name LIKE '%Express%';
```

Analyze:

```sql
EXPLAIN
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE product_name LIKE '%Express%';
```

### Problem

A normal B-tree index generally cannot efficiently perform a lookup when the search pattern starts with `%`.

For example:

```text
%Express%
```

does not provide a fixed starting prefix.

---

# 15. Optimization 4 — FULLTEXT Search

Create a full-text index:

```sql
CREATE FULLTEXT INDEX idx_sales_product_fulltext
ON sales_data(product_name);
```

Rewrite the search using:

```sql
MATCH()
AGAINST()
```

Optimized query:

```sql
SELECT
    sale_id,
    customer_name,
    product_name,
    category,
    total_amount
FROM sales_data
WHERE MATCH(product_name)
      AGAINST('+Express' IN BOOLEAN MODE);
```

Analyze:

```sql
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
```

This demonstrates how a full-text index can be used for word-based searching instead of a leading-wildcard `LIKE`.

---

# 16. Slow Query 5 — Correlated Subquery

The fifth query uses a correlated subquery:

```sql
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
```

Analyze:

```sql
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
```

### Problem

The correlated subquery depends on the outer row and may require repeated work.

---

# 17. Optimization 5 — JOIN with Precomputed Aggregate

First create an index:

```sql
CREATE INDEX idx_sales_category_total
ON sales_data(category, total_amount);
```

Rewrite the query by calculating the category averages once and joining them:

```sql
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
```

Analyze:

```sql
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
```

And:

```sql
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
```

---

# 18. Indexes Created

The experiment creates the following indexes:

| Index | Columns | Purpose |
|---|---|---|
| `idx_sales_sale_date` | `sale_date` | Date-based filtering |
| `idx_sales_customer_name` | `customer_name` | Customer lookup |
| `idx_sales_city` | `customer_city` | City filtering |
| `idx_sales_category` | `category` | Category filtering |
| `idx_sales_product_fulltext` | `product_name` | Full-text product search |
| `idx_sales_category_total` | `category, total_amount` | Category aggregation/filtering |

---

# 19. Before vs After Optimization

The experiment follows this process:

```text
             10,000 Records
                   │
                   ▼
          Execute Slow Query
                   │
                   ▼
                EXPLAIN
                   │
                   ▼
          Identify Bottleneck
                   │
                   ▼
        ┌─────────────────────┐
        │ Index / Rewrite SQL │
        └─────────────────────┘
                   │
                   ▼
          Execute Optimized Query
                   │
                   ▼
          EXPLAIN / ANALYZE
                   │
                   ▼
            Compare Results
```

---

# 20. Benchmark Results

The actual execution time depends on the ByteXL environment and MySQL optimizer.

Record your observed results in a table like this:

| Query | Before Optimization | After Optimization | Optimization |
|---|---:|---:|---|
| Query 1 — Date | Record actual time | Record actual time | Date index + range |
| Query 2 — Customer | Record actual time | Record actual time | Customer index |
| Query 3 — OR | Record actual time | Record actual time | Index + UNION |
| Query 4 — LIKE | Record actual time | Record actual time | FULLTEXT |
| Query 5 — Subquery | Record actual time | Record actual time | JOIN + aggregate |

Do **not** assume fixed execution times. Measure them in your ByteXL environment.

---

# 21. EXPLAIN Comparison

The following `EXPLAIN` attributes are particularly useful when comparing the queries:

| Attribute | What to Observe |
|---|---|
| `type` | Whether MySQL performs a full scan or indexed access |
| `possible_keys` | Available indexes |
| `key` | Index selected by optimizer |
| `rows` | Estimated rows examined |
| `filtered` | Estimated filtering |
| `Extra` | Additional operations |

A typical improvement is:

```text
Before:

type = ALL
key  = NULL
rows = large number


After:

type = range / ref
key  = appropriate index
rows = smaller number
```

The exact values may differ in ByteXL.

---

# 22. Important Note About Query Optimization

Adding an index does **not** guarantee that MySQL will use it.

The MySQL optimizer chooses an execution plan based on factors such as:

- Table size
- Data distribution
- Index selectivity
- Query conditions
- Available indexes
- Estimated cost

Therefore, the correct approach is to verify the actual plan using `EXPLAIN` or `EXPLAIN ANALYZE`.

---

# 23. Verification Queries

Check the total number of rows:

```sql
SELECT COUNT(*) AS total_records
FROM sales_data;
```

View the indexes:

```sql
SHOW INDEX FROM sales_data;
```

View sample data:

```sql
SELECT *
FROM sales_data
LIMIT 10;
```

Check the date range:

```sql
SELECT
    MIN(sale_date) AS earliest_sale,
    MAX(sale_date) AS latest_sale
FROM sales_data;
```

Calculate total sales:

```sql
SELECT SUM(total_amount) AS total_sales
FROM sales_data;
```

---

# 24. Expected Result

The experiment demonstrates that query performance can often be improved by:

1. Avoiding functions on columns used for filtering.
2. Creating indexes on frequently searched columns.
3. Using range predicates for date filtering.
4. Rewriting suitable `OR` conditions.
5. Using full-text search for word-based text searches.
6. Replacing expensive correlated subqueries with precomputed aggregates and joins.
7. Examining execution plans before and after optimization.

---

# 25. Result

A sales dataset containing at least **10,000 records** was successfully generated.

Five potentially inefficient SQL queries were identified and analyzed using `EXPLAIN` and `EXPLAIN ANALYZE`.

The queries were optimized using indexing and query rewriting techniques. The resulting execution plans were then compared with the original plans to evaluate the effect of optimization.

---

# 26. Conclusion

The experiment demonstrates the importance of SQL query optimization when working with large datasets.

`EXPLAIN` helps identify how MySQL intends to execute a query, while `EXPLAIN ANALYZE` provides information about the actual execution.

Appropriate indexes can reduce unnecessary row scanning, while query rewriting can make predicates and operations more efficient.

Thus, combining **execution-plan analysis, indexing, and query rewriting** provides an effective approach to improving SQL query performance.

---

## 📁 Files

```text
Experiment_10_Query_Optimization.sql
README.md
```

Run the SQL file in the ByteXL MySQL editor with `sandbox_db` selected.