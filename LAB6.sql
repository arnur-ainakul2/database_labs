-- Create table: employees
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(50),
 dept_id INT,
 salary DECIMAL(10, 2)
);
-- Create table: departments
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
-- Create table: projects
CREATE TABLE projects (
 project_id INT PRIMARY KEY,
 project_name VARCHAR(50),
 dept_id INT,
 budget DECIMAL(10, 2)
);

-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);
sELECT*from projects;
sELECT*from departments;
sELECT*from employees;

--Task 2.1 CROSS JOIN
SELECT employees.emp_name, departments.dept_name
FROM employees CROSS JOIN departments ;
--the result will 20 rows by multiplying 4 to 5

--Task 2.2: Alternative CROSS JOIN syntax
--A)
SELECT employees.emp_name, departments.dept_name
FROM employees CROSS JOIN departments ;
--B)
SELECT employees.emp_name, departments.dept_name
FROM employees INNER JOIN departments ON TRUE;

--TASK 2.3 Practical CROSS JOIN
SELECT employees.emp_name ,projects.project_name
from employees CROSS JOIN projects;

--PART 3: INNER JOIN
--task 3.1
SELECT e.emp_name , d.dept_name,d.location from employees e
INNER JOIN departments d on e.dept_id =d.dept_id;
--it returns 4 rows
--task 3.2 INNER JOIN with USING

SELECT employees.emp_name ,departments.dept_name,departments.location
from employees
INNER JOIN departments using (dept_id);

--task3.3:NATURAL INNER JOIN
SELECT emp_name, dept_name ,departments.location
FROM employees
NATURAL INNER JOIN departments;
--(natural inner join - is automatically connecting tables with the same column);
--===============================================--
--task 3.4:
SELECT e.emp_name , d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id=d.dept_id
INNER JOIN projects p ON d.dept_id=p.dept_id;

--PART 4:LEFT JOIN Exercises
--4.1 Basic LEFT JOIN
SELECT employees.emp_name ,departments.dept_name FROM
employees LEFT JOIN departments
On employees.dept_id=departments.dept_id;

--4.2 LEFT JOIN with using
SELECT employees.emp_name ,departments.dept_name FROM
employees LEFT JOIN departments using (dept_id);
--4.3 FIND Unmatched Records
SELECT employees.emp_name,departments.dept_name
From employees LEFT JOIN departments on employees.dept_id=departments.dept_id;
WHERE d.dept_id is NULL;
--4.4
SELECT departments.dept_name, count(employyes.emp_id) AS total_employees
FROM departments LEFT JOIN employees on departments.dept_id=employees.dept_id
group by d.dept_id ,d.dept_name
order by employee_count DESC;
--PART 5 RIGHT JOIN
--TASK 5.1:BASIC RIGHT JOIN
SELECT employees.emp_name , departments.dept_name
from employees right Join departments on employees.dept_id=departments.dept_id;

--TASK 5.2:Convert to LEFT JOIN
SELECT employees.emp_name , departments.dept_name
from departments left Join employees on employees.dept_id=departments.dept_id;
--TASK 5.3:FIND DEPARTMENT
SELECT departments.dept_name, departments.location
FROM employees RIGHT JOIN departments ON employees.dept_id=departments.dept_id;
where employees
--PART 6 FULL JOIN
--TASK 6.1: BASIC FULL JOIN
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS
dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
--TASK 6.2 FULL JOIN with Projects
--Show all departments and all projects, including those without matches.
SELECT d.dept_name, p.project_name, p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;
--TASK 6.3 FIND Orphaned Records
--Using FULL JOIN, write a query to find both:
--• Employees without departments
--• Departments without employees
-- Your query here
SELECT
 CASE
 WHEN e.emp_id IS NULL THEN 'Department without
employees'
 WHEN d.dept_id IS NULL THEN 'Employee without
department'
 ELSE 'Matched'
 END AS record_status,
 e.emp_name,
 d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

--PART 7 ON vs WHERE Clause
--Exercise 7.1: Filtering in ON Clause (Outer Join)
--Write a query using LEFT JOIN with an additional condition in the ON clause.
-- Query 1: Filter in ON clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND
d.location = 'Building A';
--TASK 7.2 Filtering in WHERE Clause (Outer Join)
--Write the same query but move the location filter to the WHERE clause.
-- Query 2: Filter in WHERE clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--Question: Compare the results of Query 1 and Query 2. Explain the difference.
--Answer:
--• Query 1 (ON clause): Applies the filter BEFORE the join, so all employees are included, but
--only departments in Building A are matched.
--• Query 2 (WHERE clause): Applies the filter AFTER the join, so employees are excluded if
--their department is not in Building A.

--PART 8;
-TASK 8.1
SELECT
 d.dept_name,
 e.emp_name,
 e.salary,
 p.project_name,
 p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;
--TASK 8.2:
-- Add manager_id column
ALTER TABLE employees ADD COLUMN manager_id INT;
-- Update with sample data
UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;
-- Self join query
SELECT
 e.emp_name AS employee,
 m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;
--TASK 8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;