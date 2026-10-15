
# Lab 6: PL/SQL - Stored Procedures and Triggers

## 🎯 Objective
Implement procedural logic in the database using stored procedures and triggers for automation and auditing.

## 🧠 Concepts Covered
- Stored Procedures
- Parameter Handling & Variable Declaration
- Error Handling & Validation
- Database Triggers (`BEFORE/AFTER INSERT/UPDATE`)
- Audit Logging

## 🏗️ Implementation Overview
Develop a `transfer_employee` procedure that safely moves employees between departments and create triggers to monitor salary changes.

## 📝 Procedure
1. Write the `transfer_employee(emp_id, new_dept_id)` stored procedure.
2. Include logic inside the procedure to validate IDs and handle exceptions.
3. Create an audit table for salaries.
4. Implement a trigger that automatically logs old and new salary values whenever an employee's salary is updated.
5. Test edge cases (e.g., invalid department ID).

## 🎓 Learning Outcomes
Understanding of how to encapsulate business logic within the database and automate data auditing.
[🔗 Open Experiment 6](./Experiment%206.sql)
