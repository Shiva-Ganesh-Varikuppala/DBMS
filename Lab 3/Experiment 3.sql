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

-- Insert 5 Departments

INSERT INTO Department (dept_id, dept_name) VALUES
(101, 'Engineering'),
(102, 'Data Science'),
(103, 'Human Resources'),
(104, 'Marketing'),
(105, 'Operations');

-- Insert 8 Projects
INSERT INTO Project (proj_id, proj_name, budget) VALUES
(201, 'AI Chatbot Migration', 150000.00),
(202, 'Cloud Infrastructure Setup', 200000.00),
(203, 'Employee Portal Redesign', 50000.00),
(204, 'Q3 Marketing Campaign', 75000.00),
(205, 'Cybersecurity Audit', 120000.00),
(206, 'Data Warehouse Optimization', 180000.00),
(207, 'Logistics Tracking App', 90000.00),
(208, 'Annual Recruitment Drive', 30000.00);

-- Insert 30 Employees
INSERT INTO Employee (emp_id, emp_name, salary, dept_id) VALUES
(1, 'Aarav Sharma', 75000, 101), (2, 'Vihaan Singh', 82000, 101),
(3, 'Vivaan Patel', 65000, 102), (4, 'Ananya Gupta', 95000, 102),
(5, 'Diya Kumar', 55000, 103), (6, 'Advik Desai', 72000, 101),
(7, 'Kavya Joshi', 48000, 104), (8, 'Ishaan Mehta', 60000, 105),
(9, 'Myra Reddy', 88000, 102), (10, 'Dhruv Iyer', 91000, 101),
(11, 'Riya Kapoor', 53000, 104), (12, 'Arjun Nair', 67000, 105),
(13, 'Aisha Verma', 45000, 103), (14, 'Ayaan Trivedi', 78000, 101),
(15, 'Krish Pillai', 85000, 102), (16, 'Zara Ahuja', 62000, 104),
(17, 'Kabir Das', 59000, 105), (18, 'Fatima Shaikh', 51000, 103),
(19, 'Rudra Pandey', 96000, 101), (20, 'Nisha Choudhury', 81000, 102),
(21, 'Reyansh Bhatia', 58000, 105), (22, 'Saanvi Jain', 74000, 101),
(23, 'Om Rathi', 69000, 102), (24, 'Navya Sengupta', 47000, 104),
(25, 'Samar Ghosh', 52000, 103), (26, 'Tanya Malik', 83000, 101),
(27, 'Lakshya Bose', 92000, 102), (28, 'Mira Rajput', 64000, 104),
(29, 'Darsh Chauhan', 56000, 105), (30, 'Kyra Thakur', 49000, 103);

-- Insert Works_On Assignments (Sample data mapping employees to projects)
INSERT INTO Works_On (emp_id, proj_id, hours_worked) VALUES
(1, 201, 40), (2, 202, 35), (3, 206, 45), (4, 201, 20),
(5, 203, 15), (6, 205, 50), (7, 204, 30), (8, 207, 40),
(9, 206, 25), (10, 202, 30), (11, 204, 20), (12, 207, 35);


-- 3. Practical Lab Queries (DQL)

SELECT emp_name, salary 
FROM Employee 
WHERE salary >= 75000;

-- 4. GROUP BY with HAVING
-- Demonstrates filtering grouped data (HAVING is used instead of WHERE for aggregate functions).
SELECT dept_id, AVG(salary) AS Dept_Avg_Salary
FROM Employee
GROUP BY dept_id
HAVING AVG(salary) > 65000;

-- 5. CASE Expression
-- Demonstrates conditional logic to create a new derived column.

SELECT 
    emp_name, 
    salary,
    CASE 
        WHEN salary >= 80000 THEN 'Senior Level'
        WHEN salary >= 60000 THEN 'Mid Level'
        ELSE 'Entry Level'
    END AS Salary_Bracket
FROM Employee;

-- 6. Comprehensive Query (Combines multiple concepts)
SELECT 
    d.dept_name, 
    COUNT(e.emp_id) AS Total_Staff,
    ROUND(AVG(e.salary), 2) AS Avg_Salary,
    CASE 
        WHEN AVG(e.salary) > 75000 THEN 'High Budget Dept'
        ELSE 'Standard Budget Dept'
    END AS Budget_Status
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id
GROUP BY d.dept_name
HAVING Total_Staff >= 5
ORDER BY Avg_Salary DESC;
