# Lab 4: Advanced Joins and Subqueries

## 🎯 Objective
Perform complex data retrieval on the Employee schema using various join techniques and subqueries, and analyze execution plans.

## 🧠 Concepts Covered
- `INNER JOIN`, `LEFT JOIN`
- Self Joins & 3-way Joins
- Correlated Subqueries & `EXISTS`
- Set Operations (Simulated `INTERSECT` and `EXCEPT`)
- Query Execution Plans (`EXPLAIN`)

## 🏗️ Implementation Overview
Write advanced queries that combine data from multiple tables simultaneously and filter data based on dynamic sub-conditions.

## 📝 Procedure
1. Write `INNER JOIN` and `LEFT JOIN` queries linking employees to departments and projects.
2. Write a self-join (e.g., matching employees to their managers).
3. Implement a 3-way join connecting Employee, Department, and Project.
4. Draft correlated subqueries utilizing the `EXISTS` operator.
5. Simulate `INTERSECT` and `EXCEPT` using `IN` or `NOT EXISTS`.
6. Prepend `EXPLAIN` to queries to observe execution differences.

## 🎓 Learning Outcomes
Mastery of combining multi-table datasets and understanding how the database engine interprets complex queries.
[🔗 Open Experiment 4](./Experiment%204.sql)
