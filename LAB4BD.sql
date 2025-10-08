-- Create tables
CREATE TABLE employees (
 employee_id SERIAL PRIMARY KEY,
 first_name VARCHAR(50),
 last_name VARCHAR(50),
 department VARCHAR(50),
 salary NUMERIC(10,2),
 hire_date DATE,
 manager_id INTEGER,
 email VARCHAR(100)
);
CREATE TABLE projects (
 project_id SERIAL PRIMARY KEY,
 project_name VARCHAR(100),
 budget NUMERIC(12,2),
 start_date DATE,
 end_date DATE,
 status VARCHAR(20)
);
CREATE TABLE assignments (
 assignment_id SERIAL PRIMARY KEY,
 employee_id INTEGER REFERENCES employees(employee_id),
 project_id INTEGER REFERENCES projects(project_id),
 hours_worked NUMERIC(5,1),
 assignment_date DATE
);
-- Insert sample data
INSERT INTO employees (first_name, last_name, department,
salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
'lisa.a@company.com');
INSERT INTO projects (project_name, budget, start_date,
end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30',
'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');
INSERT INTO assignments (employee_id, project_id,
hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

--Part 1: Basic SELECT Queries
--Task 1.1:
SELECT first_name || ' ' || last_name AS full_name,
       department,
       salary
FROM employees;

--Task 1.2:
SELECT DISTINCT department
FROM employees;

--Task 1.3;
SELECT project_name,budget,
    CASE
        WHEN budget>150000 THEN 'Large' 
        WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'SMALL'
    END AS budget_category
FROM projects;
--Task 1.4;
SELECT first_name ||' '|| last_name AS full_name,
COALESCE(email,'No email provided') AS email
FROM employees;

--PART 2.WHERE Clause and Comparison Operators
--Task 2.1
SELECT first_name || ' ' || last_name AS full_name,hire_date
FROM employees
WHERE hire_date>'2020-01-01';
--Task 2.2
SELECT first_name || ' ' || last_name AS full_name,salary
FROM employees
WHERE salary BETWEEN 60000 AND 70000;
--Task 2.3
SELECT first_name || ' ' || last_name AS full_name
FROM employees
WHERE last_name like 'S%' 
   OR last_name like 'J%';
--Task 2.4;
SELECT first_name || ' ' || last_name AS full_name,manager_id,department
FROM employees
WHERE manager_id IS NOT NULL
AND department='IT';

--PART 3:STRING and Mathematical Functions
--Task 3.1;
SELECT first_name || ' ' || last_name AS full_name,  --• Employee names in uppercase
       LENGTH(last_names) as last_name_Length, --• Length of their last names
       SUBSTRING(email from 1 for 3) AS email_start --First 3 characters of their email address (use substring)
FROM employees;
--Task 3.2;
SELECT first_name || ' ' || last_name AS full_name,
       salary*12 AS annual_salary,
       ROUND(salary/12.0,2) AS monthly_salary,
       salary*0.10 AS raise_10
FROM employees;
--Task 3.3;
--format()=printf;
--Плейсхолдер	Описание
--%s	Строковое значение (string)
--%I	Идентификатор (название таблицы или колонки), автоматически берёт в кавычки
--%L	Литерал (например, текст с одинарными кавычками), безопасно для SQL-инъекций
--%t	Таблица (редко используется)
--%	Процентная строка (сам по себе символ %
SELECT
      FORMAT(
        'Project: %s -Budget: $%s - Status: %s',
        project_name,
        budget,
        status
      )AS project_info
    FROM projects;

--Task 3.4; Calculate how many years each employee has been with the company (use date functions
--and the current date).
SELECT
    first_name || ' ' || last_name AS full_name,
    hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE,hire_date)) AS years_with_company
FROM employees;
--PART 4; Aggregate Functions and GROUP BY
--Task 4.1 average
SELECT department,AVG(salary) AS avg_salary
FROM employees
GROUP BY department;
--Task 4.2
SELECT projects.project_name ,
       SUM(hours_worked) as total_hours
FROM assignments a
JOIN projects ON a.project_id=projects.project_id
GROUP BY projects.project_name;
--TASK 4.3;
SELECT
department,COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*)>1;
--TASK 4.4
SELECT 
MAX(salary) AS maximum,
MIN(salary) AS minimum,
SUM(salary) AS TOTAL_payroll 
FROM employees;

--PART 5;SET OPERATION
--task 5.1;
SELECT
    employee_id,
    first_name || ' ' || last_name AS full_name,
    salary
FROM employees
WHERE salary>65000

UNION

SELECT 
    employee_id,
    first_name || ' ' || last_name AS full_name,
    salary
FROM employees
WHERE hire_date>'2020-01-01';
--task 5.2
SELECT employee_id,
       first_name || ' ' || last_name AS full_name,
       salary
FROM employees
WHERE department='IT'

INTERSECT
SELECT employee_id,
       first_name || ' ' || last_name AS full_name,
       salary
FROM employees
WHERE salary>65000;

--task 5.3
SELECT employee_id,
       first_name || ' ' || last_name AS full_name
FROM employees

EXCEPT

SELECT employees.employee_id,
       employees.first_name || ' ' || employees.last_name AS full_name
FROM employees
JOIN assignments ON employees.employee_id = assignments.employee_id;
--PART 6 SUBQUERIES
-- Task 6.1: Find all employees who have at least one project assignment (EXISTS)
SELECT employee_id,
       first_name || ' ' || last_name AS full_name
FROM employees
WHERE EXISTS (
    SELECT 1
    FROM assignments
    WHERE assignments.employee_id = employees.employee_id
);

-- Task 6.2: Find all employees working on projects with status 'Active' (IN with subquery)
SELECT employee_id,
       first_name || ' ' || last_name AS full_name
FROM employees
WHERE employee_id IN (
    SELECT assignments.employee_id
    FROM assignments
    JOIN projects ON assignments.project_id = projects.project_id
    WHERE projects.status = 'Active'
);

-- Task 6.3: Find employees whose salary is greater than ANY employee in the Sales department (ANY)
SELECT employee_id,
       first_name || ' ' || last_name AS full_name,
       salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);
-- Part 7: Complex Queries

-- Task 7.1: Employee info with average hours and rank by salary within department
SELECT 
    e.first_name || ' ' || e.last_name AS full_name,
    e.department,
    COALESCE(AVG(a.hours_worked), 0) AS avg_hours,
    RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank  -- если оконные функции разрешены
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY e.department, salary_rank;



-- Task 7.2: Projects with total hours > 150
SELECT 
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS num_employees
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_name
HAVING SUM(a.hours_worked) > 150
ORDER BY total_hours DESC;


-- Task 7.3: Departments with total employees, average salary, highest paid employee name
SELECT 
    department,
    COUNT(*) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(first_name || ' ' || last_name) AS highest_paid_name,
    GREATEST(MIN(salary), 30000) AS min_or_30000,   -- пример использования GREATEST
    LEAST(MAX(salary), 100000) AS max_or_100000     -- пример использования LEAST
FROM employees
GROUP BY department
ORDER BY total_employees DESC;