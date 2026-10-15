-- 1. Database and Schema Setup (DDL & DML)
-- Step 1: Create and select the database
CREATE DATABASE IF NOT EXISTS LabPracticalDB;
USE LabPracticalDB;

-- Step 2: Create Department Table
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL
);

-- Step 3: Create Employee Table (with manager_id for hierarchy)
CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2),
    dept_id INT,
    manager_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id),
    FOREIGN KEY (manager_id) REFERENCES Employee(emp_id)
);

-- Step 4: Insert Departments
INSERT INTO Department (dept_id, dept_name) VALUES
(101, 'Engineering'),
(102, 'Data Science'),
(103, 'Human Resources');

-- Step 5: Insert Employees (Notice the manager_id assignments establishing a chain of command)
-- Employee 1 is the CEO (Manager is NULL)
INSERT INTO Employee (emp_id, emp_name, salary, dept_id, manager_id) VALUES
(1, 'Aarav Sharma', 150000, 101, NULL),
(2, 'Vihaan Singh', 120000, 101, 1),
(3, 'Ananya Gupta', 115000, 102, 1),
(4, 'Advik Desai', 85000, 101, 2),
(5, 'Myra Reddy', 95000, 102, 3),
(6, 'Diya Kumar', 75000, 103, 1),
(7, 'Ishaan Mehta', 65000, 101, 4),
(8, 'Kabir Das', 60000, 102, 5);

-- 2. Creating SQL Views
-- Views are virtual tables based on the result-set of an SQL statement.
-- Query 1: Department Salary Summary View (Creates a summarized view of financial metrics per department)
CREATE VIEW Dept_Salary_Summary AS
SELECT
    d.dept_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.salary) AS total_salary_expense,
    ROUND(AVG(e.salary), 2) AS average_salary
FROM Department d
LEFT JOIN Employee e ON d.dept_id = e.dept_id
GROUP BY d.dept_name;

-- Execute this to see the view's output:
SELECT * FROM Dept_Salary_Summary;

-- Query 2: Employee Hierarchy View (Creates a view using a self-join to easily see who reports to whom)
CREATE VIEW Employee_Hierarchy AS
SELECT
    e.emp_id AS Employee_ID,
    e.emp_name AS Employee_Name,
    m.emp_name AS Manager_Name
FROM Employee e
LEFT JOIN Employee m ON e.manager_id = m.emp_id;

-- Execute this to see the view's output:
SELECT * FROM Employee_Hierarchy;

-- 3. Testing Updatability of Views
-- Test 1: Attempting to update a Complex View (This will produce an ERROR)
-- This fails because the database cannot map a changed average back to a specific row.
UPDATE Dept_Salary_Summary
SET average_salary = 100000
WHERE dept_name = 'Engineering';

-- Test 2: Creating and updating a Simple View (This will SUCCEED)
-- Create a simple view with a direct row-to-row mapping
CREATE VIEW Engineering_Staff AS
SELECT emp_id, emp_name, salary
FROM Employee
WHERE dept_id = 101;

-- This update succeeds because there are no aggregations or group by clauses
UPDATE Engineering_Staff
SET salary = salary + 5000
WHERE emp_id = 7;

-- Check the base table to confirm the data actually changed
SELECT emp_name, salary FROM Employee WHERE emp_id = 7;

-- 4. Recursive CTE for Reporting Chains
-- This query starts at the top (CEO) and recursively joins the table to itself to build a visual text chain of command for every employee.
WITH RECURSIVE ReportingChain AS (
    -- Anchor Member: Start with the top-level manager (manager_id is NULL)
    SELECT
        emp_id,
        emp_name,
        manager_id,
        1 AS hierarchy_level,
        CAST(emp_name AS CHAR(255)) AS chain_of_command
    FROM Employee
    WHERE manager_id IS NULL
    UNION ALL
    -- Recursive Member: Join the Employee table with the CTE itself
    SELECT
        e.emp_id,
        e.emp_name,
        e.manager_id,
        rc.hierarchy_level + 1,
        CONCAT(rc.chain_of_command, ' -> ', e.emp_name)
    FROM Employee e
    INNER JOIN ReportingChain rc ON e.manager_id = rc.emp_id
)
-- Display the generated paths
SELECT
    emp_name,
    hierarchy_level,
    chain_of_command
FROM ReportingChain
ORDER BY hierarchy_level, emp_id;
