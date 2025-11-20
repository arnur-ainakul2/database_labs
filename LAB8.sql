-- Create tables
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(100),
 dept_id INT,
 salary DECIMAL(10,2),
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
CREATE TABLE projects (
 proj_id INT PRIMARY KEY,
 proj_name VARCHAR(100),
 budget DECIMAL(12,2),
 dept_id INT,
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);
-- Insert sample data
INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');
INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);
INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);
--ex2.1
CREATE INDEX idx_users_username ON employees USING btree (salary);
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
--ex2.2
CREATE INDEX index_dept_id ON employees(dept_id);
SELECT*FROM employees WHERE dept_id=101; /*Speeds up joins between parent and child tables
                                           Speeds up DELETE/UPDATE checks on the parent table
                                           Speeds uo queries filtering by the foreign key.*/

--ex2.3
SELECT
 tablename,
 indexname,
 indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname; --All of them were create automatically by using primary key definition when creating tables

--PART 3:Multicolumn Indexes
--ex 3.1:
CREATE INDEX multi_column_idx ON employees(dept_id,salary);
SELECT emp_name, salary
FROM employees
WHERE dept_id=101 AND salary>52000;
--Question's answer:No,because in this case this index lost his functions. The Process of finding needed column will work as usual
--ex 3.2: Understanding Column Order
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
--Both of them equals to each other
--PART4 Unique Indexes
ALTER TABLE employees
ADD COLUMN email VARCHAR(100);
UPDATE employees set email ='john.smith@company.com' WHERE emp_id=1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;
CREATE UNIQUE INDEX email_idx_uniq ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--ОШИБКА: повторяющееся значение ключа нарушает ограничение уникальности "email_idx_uniq"
--  Detail: Ключ "(email)=(john.smith@company.com)" уже существует.
--ex 4.2:Unique Index vs Unique Constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) unique;
SELECT indexname,indexdef FROM pg_indexes WHERE tablename='employees' AND indexname like '%phone%';
--there will be used B-tree type of index because it's default and only index type that supports enforcing uniqueness across all data types
--PART 5: Indexes and Sorting
--exercise 5.1: Create an Index for Sorting
CREATE INDEX emp_salary_idx on employees(salary desc);
SELECT emp_name, salary FROM employees ORDER BY salary DESC;
--exercise 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;
--PART 6:Indexes on Expressions
--exercise 6.1 CREATE FUNCTION_BASED INDEX
ALTER TABLE employees
ADD COLUMN hire_date date;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(year FROM hire_date));
SELECT emp_name ,hire_date
FRom employees
WHERE extract(Year from hire_date)=2020;
--PART 7: MANAGIN INDEXES
--ex 7.1 Rename an Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';
--ex 7.2
DROP INDEX emp_salary_idx
--ex 7.3
REINDEX index employees_salary_index;
 --after bult insert operations
 --when index becomes bloated
 --after sinificant data modifications


 --Part 8 Practical Scenarios
 --ex 8.1
 Select e.emp.name,e.salary,d.dept_name
 FROP employees JOIN departments ON employees.dept_id=departments.dept_id
 where e.salary > 50000
 order by salary desc;

CREATE INDEX emp_salary_filter_idx On employees(salary) where salary>50000;
--8.2 partial index
CREATE INDEX proj_high_budget idx on projects(budget)
where budget>80000;
--PART 9
--ex 9.1 Hash index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
--ex 9.2 Compare Index Types
Create index proj_name_btree_idx on projects(proj_name);
create index proj_name_hash_idx on projects using hash(proj_name);

--PART 10;
--ex 10.1
List all indexes and their sizes:
sql
SELECT
 schemaname,
 tablename,
 indexname,
 pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


DROP INDEX IF EXISTS proj_name_hash_idx;


CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;