
-- 1. Schema Creation (DDL)

-- Create and use the database
CREATE DATABASE IF NOT EXISTS LabPracticalDB;
USE LabPracticalDB;

-- Create Department Table
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- Create Project Table
CREATE TABLE Project (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100) NOT NULL,
    budget DECIMAL(12, 2)
);

-- Create Employee Table
CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

-- Create Works_On Table (Many-to-Many relationship between Employee and Project)
CREATE TABLE Works_On (
    emp_id INT,
    proj_id INT,
    hours_worked INT,
    PRIMARY KEY (emp_id, proj_id),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id),
    FOREIGN KEY (proj_id) REFERENCES Project(proj_id)
);

-- 1. Joins
-- INNER JOIN

SELECT e.emp_id, e.emp_name, d.dept_name
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id;

-- LEFT JOIN

SELECT e.emp_name, w.proj_id, w.hours_worked
FROM Employee e
LEFT JOIN Works_On w ON e.emp_id = w.emp_id;

-- Self-Join

SELECT e1.emp_name AS Employee_1, e2.emp_name AS Employee_2, d.dept_name
FROM Employee e1
INNER JOIN Employee e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
INNER JOIN Department d ON e1.dept_id = d.dept_id;

-- 3-Way Join
SELECT e.emp_name, p.proj_name, w.hours_worked
FROM Employee e
INNER JOIN Works_On w ON e.emp_id = w.emp_id
INNER JOIN Project p ON w.proj_id = p.proj_id;

-- 2. Subqueries and EXISTS

-- Correlated Subquery

SELECT e1.emp_name, e1.salary, e1.dept_id
FROM Employee e1
WHERE e1.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e1.dept_id = e2.dept_id
);

-- EXISTS clause
SELECT d.dept_name
FROM Department d
WHERE EXISTS (
    SELECT 1
    FROM Employee e
    WHERE e.dept_id = d.dept_id AND e.salary > 90000
);

-- 3. Set Operations (Simulated for MySQL) Simulated INTERSECT
-- Using the IN clause to simulate INTERSECT
SELECT emp_id, emp_name 
FROM Employee 
WHERE dept_id = 101 
AND emp_id IN (
    SELECT emp_id FROM Works_On
);

-- Simulated EXCEPT (MINUS)
-- Using LEFT JOIN and IS NULL to simulate EXCEPT
SELECT e.emp_id, e.emp_name
FROM Employee e
LEFT JOIN Works_On w ON e.emp_id = w.emp_id
WHERE e.dept_id = 101 AND w.proj_id IS NULL;

-- 4. Using EXPLAIN to Compare Execution Plans

EXPLAIN SELECT e.emp_name, p.proj_name, w.hours_worked
FROM Employee e
INNER JOIN Works_On w ON e.emp_id = w.emp_id
INNER JOIN Project p ON w.proj_id = p.proj_id;

-- Run this EXPLAIN on the Correlated Subquery:
EXPLAIN SELECT e1.emp_name, e1.salary, e1.dept_id
FROM Employee e1
WHERE e1.salary > (
    SELECT AVG(e2.salary)
    FROM Employee e2
    WHERE e1.dept_id = e2.dept_id
);
