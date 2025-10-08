--part A
--1)creating database
CREATE DATABASE advanced_Lab;
--creating table employees
CREATE TABLE employees(
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    department VARCHAR(100),
    salary INTEGER,
    hire_date DATE,
    status VARCHAR(50) DEFAULT 'Active'
);
--creating table departments
CREATE TABLE departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);
--creating table projects
CREATE TABLE projects(
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);
--Part B
--2)INSERT with column specification
INSERT INTO employees (emp_id,first_name,last_name,department) 
VALUES (DEFAULT, 'Emily','Brown', 'IT');
--3)INSERT with DEFAULT values
INSERT INTO employees(first_name,last_name,department,salary,status,hire_date)
VALUES ('David','Green','Finance',DEFAULT,DEFAULT,'2025-10-01');
--4)INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
('Marketing', 40000, NULL),
('Sales', 60000, NULL),
('R&D', 80000, NULL);
--5)INSERT with expressions
INSERT INTO employees(first_name,last_name,department,hire_date,salary)
VALUES ('Alice','White','HR',CURRENT_DATE,50000*1.1);
--6)INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees AS
SELECT*FROM employees WHERE 1=0;

INSERT INTO temp_employees
SELECT*FROM employees
WHERE department='IT';
--PART C: Complex UPDATE OPERATIONS
--7)UPDATE with arithmetic expressions
UPDATE employees
SET salary = salary * 1.10;
--8)UPDATE with WHERE clause and multiple conditions;
UPDATE employees
SET status='Senior'
WHERE salary>60000
 AND hire_date <'2020-01-01';
 --9)UPDATE using CASE expression
UPDATE employees
SET department=
    CASE
        WHEN salary > 80000 THEN 'Management'
        WHEN salary BETWEEN 50000 AND 80000 THEN 'Junior'
    END;
--10)UPDATE with DEFAULT
UPDATE employees
SET department=DEFAULT
WHERE status='Inactive';
--11)Update with subquery
UPDATE departments d
SET budget=(
     SELECT avg(salary)*1.2 
     FROM employees e
     WHERE e.department=d.dept_name
);
--12)Update multiple columns
UPDATE employees
SET salary=salary*1.15,
    status='Promoted'
WHERE department='Sales';

--PART D:Advanced DELETE operations
--13)
DELETE FROM employees
WHERE status='Terminated';
--14)Delete with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000 
AND hire_date>'2023-01-01'
AND department IS NULL;
--15)DELETE with subquery
DELETE FROM departments
WHERE dept_name NOT IN(
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);
--16)DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date<'2023-01-01'
RETURNING *;

--PART E
--17)INSERT with NULL values
INSERT INTO employees(first_name,last_name,salary,department) 
VALUES('John','Doe',NULL,NULL);
--18)UPDATE NULL handling
UPDATE employees
SET department='Unassigned'
WHERE department IS NULL;
--19)
DELETE FROM employees
WHERE salary IS NULL 
OR department IS NULL;
      
--PART F;
--20)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Alice', 'Johnson', 'IT', 70000, '2024-05-10')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--21)
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;


--22)
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;
--PART G
-- 23) Conditional INSERT
-- Insert employee only if no employee with same first_name and last_name already exists.
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Michael', 'Smith', 'HR', 55000, '2024-06-01'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Michael' AND last_name = 'Smith'
);


UPDATE employees e
SET salary = salary * (
    CASE
        WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000 THEN 1.10
        ELSE 1.05
    END
);

-- =========================================


INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('Anna', 'Lee', 'Sales', 45000, '2024-03-10'),
('Brian', 'Kim', 'IT', 60000, '2023-12-01'),
('Cathy', 'Park', 'HR', 52000, '2024-01-15'),
('David', 'Tran', 'Marketing', 48000, '2024-02-20'),
('Ella', 'Wong', 'Finance', 70000, '2024-04-05');

UPDATE employees
SET salary = salary * 1.10
WHERE first_name IN ('Anna', 'Brian', 'Cathy', 'David', 'Ella');

-- =========================================

-- 26) Data migration simulation
CREATE TABLE IF NOT EXISTS employee_archive AS
SELECT * FROM employees WHERE 1 = 0;

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- =========================================

--27)
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      WHERE e.department = p.department
  ) > 3;