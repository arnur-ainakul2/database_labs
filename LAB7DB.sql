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

--LAB7 PART 1
--exercice 1
CREATE OR REPLACE VIEW employee_details AS
    SELECT employees.emp_name,departments.dept_name,employees.salary,departments.location
from employees left join departments on employees.dept_id=departments.dept_id
Where departments.dept_name is not null ;

SELECT * FROM employee_details;
--exercise 2
DROP VIEW IF EXISTS dept_statistics;
CREATE OR REPLACE VIEW dept_statistics AS
    SELECT departments.dept_name,count(employees.emp_id) as employee_count,avg(employees.salary) as avg_salary,max(employees.salary) as max_salary,min(employees.salary) as min_salary
    FROM departments left join employees on employees.dept_id=departments.dept_id
group by departments.dept_name;

SELECT * FROM dept_statistics
ORDER BY employee_count DESC;
SELECT * From employees;
SELECT * FROM departments;
--ex 2.3
CREATE OR REPLACE VIEW project_overview AS
    SELECT projects.project_name,projects.budget,departments.dept_name,departments.location,count(emp_id) as emp_count
FROM departments
INNER JOIN projects on projects.dept_id=departments.dept_id
INNER JOIN employees on departments.dept_id=employees.dept_id
GROUP BY departments.dept_name,projects.project_name,projects.budget,departments.location;
SELECT * FROM project_overview;
--ex 2.4
CREATE OR REPLACE VIEW high_earners AS
    SELECT employees.emp_name,employees.salary,departments.dept_name FROM employees
INNER JOIN departments ON employees.dept_id=departments.dept_id
WHERE employees.salary>55000;
SELECT * FROM  high_earners;
--PART 3
--ex 3.1
CREATE OR REPLACE VIEW employee_details AS
    SELECT employees.emp_name,departments.dept_name,employees.salary,departments.location,
           CASE
            WHEN employees.salary>60000 THEN 'high'
            WHEN employees.salary>50000 THEN 'Medium'
            ELSE 'Standart'
     END AS Employee_details
from employees left join departments on employees.dept_id=departments.dept_id
Where departments.dept_name is not null ;
SELECT * FROM employee_details;
--ex 3.2
ALTER VIEW high_earners RENAME TO top_performers;
SELECT * FROM top_performers;
CREATE VIEW temp_view AS
    SELECT emp_name,salary FROM employees WHERE salary<50000;
SELECT * FROM temp_view;
DROP VIEW temp_view;
--PART 4
--ex 4.1
CREATE OR REPLACE VIEW employee_salaries AS
    SELECT emp_id, emp_name, dept_id,salary
FROM employees;
SELECT * FROM employee_salaries;
--ex 4.2
Update employee_salaries
SET salary=52000
WHERE emp_name='John Smith'
--ex 4.3
INSERT INTO employees(emp_id, dept_id, salary) VALUES(6,102,58000)
-- ex 4.4
SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM projects;
DROP VIEW it_employees;
CREATE OR REPLACE view it_employees AS
    SELECT emp_id ,emp_name,dept_id,salary from employees where dept_id=101 with local check option;

INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);

--PART 5 MAterialized view
DROP materialized view dept_summary_mv;
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT
    departments.dept_id,
    departments.dept_name,
    count(employees.emp_id) as total_number,
    sum(coalesce(salary,0)) as total_salary,
    count(projects.project_id) as count_proj,
    sum(projects.budget) as total_budget
FROM departments
JOIN employees ON employees.dept_id = departments.dept_id
JOIN projects ON projects.dept_id = departments.dept_id
GROUP BY departments.dept_id, departments.dept_name
WITH DATA;
SELECT * FROM dept_summary_mv ORDER BY total_number DESC;
--exercise 5.2;
DELETE FROM employees
   WHERE emp_id=8;
INSERT INTO employees(emp_id,emp_name, dept_id, salary) VALUES(8,'Charlie BROWN',101,54000);
REFRESH MATERIALIZED VIEW dept_summary_mv;
--exercise 5.3
CREATE UNIQUE INDEX index_summary
ON dept_summary_mv(dept_id);
REFRESH MATERIALIZED VIEW dept_summary_mv;
--5.4
CREATE MATERIALIZED VIEW project_stuts_mv AS
    SELECT projects.project_name,projects.budget,departments.dept_name,count(employees.emp_id)
    FROM projects
    JOIN departments ON projects.dept_id=departments.dept_id
    JOIN employees ON employees.dept_id=projects.dept_id
    GROUP BY projects.project_name,projects.budget,departments.dept_name
WITH NO DATA;
SELECT * FROM project_stuts_mv;

--PART 6
SELECT rolname
FROM pg_roles;
CREATE ROLE analyst;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user WITH PASSWORD 'report456';
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';
--6.2
CREATE ROLE db_creator
LOGIN
CREATEDB
PASSWORD 'creator789';

CREATE ROLE user_manager
LOGIN
CREATEROLE
PASSWORD 'manager101';

CREATE ROLE admin_user
LOGIN
SUPERUSER
PASSWORD 'admin999';

--6.3
GRANT SELECT ON employees TO analyst;
GRANT SELECT ON departments TO analyst;
GRANT SELECT ON projects TO analyst;

GRANT ALL PRIVILEGES ON employee_details TO data_viewer;

GRANT SELECT, INSERT ON employees TO report_user;
--6.4
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1 LOGIN PASSWORD 'hr001';
CREATE USER hr_user2 LOGIN PASSWORD 'hr002';
CREATE USER finance_user1 LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;


-- HR команда может SELECT и UPDATE на employees
GRANT SELECT, UPDATE ON employees TO hr_team;
-- Финанс команда может SELECT на dept_statistics
GRANT SELECT ON dept_statistics TO finance_team;
--Exercise 6.5: Отзыв привилегий
-- Отзываем привилегию UPDATE на таблицу employees у группы hr_team
REVOKE UPDATE ON employees FROM hr_team;

-- Отзываем членство hr_user2 в группе hr_team
REVOKE hr_team FROM hr_user2;

-- Отзываем все привилегии на представление employee_details у роли data_viewer
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

Exercise 6.6: Изменение атрибутов роли
-- Добавляем LOGIN и пароль 'analyst123' роли analyst
ALTER ROLE analyst LOGIN PASSWORD 'analyst123';

-- Делаем роль user_manager суперпользователем
ALTER ROLE user_manager SUPERUSER;

-- Убираем пароль у роли analyst (ставим NULL)
ALTER ROLE analyst PASSWORD NULL;

-- Ограничиваем количество подключений к роли data_viewer до 5
ALTER ROLE data_viewer CONNECTION LIMIT 5;

Exercise 7.1: Иерархия ролей
-- Создаём родительскую роль read_only
CREATE ROLE read_only;

-- Даем read_only привилегию SELECT на все таблицы схемы public
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

-- Создаём дочерние роли с паролями
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';

-- Даем членство read_only обоим аналитикам
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;

-- Даем senior_analyst дополнительные привилегии INSERT и UPDATE на employees
GRANT INSERT, UPDATE ON employees TO senior_analyst;

Exercise 7.2: Владение объектами
-- Создаём роль project_manager с LOGIN и паролем
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

-- Передаём владение представлением dept_statistics роли project_manager
ALTER VIEW dept_statistics OWNER TO project_manager;

-- Передаём владение таблицей projects роли project_manager
ALTER TABLE projects OWNER TO project_manager;

-- Проверяем владельцев таблиц в схеме public
SELECT tablename, tableowner
FROM pg_tables
WHERE schemaname = 'public';

--Exercise 7.3: Перепередача и удаление ролей
-- Создаём временную роль temp_owner с LOGIN
CREATE ROLE temp_owner LOGIN;

-- Создаём таблицу temp_table
CREATE TABLE temp_table (
    id INT
);

-- Передаём владение temp_table роли temp_owner
ALTER TABLE temp_table OWNER TO temp_owner;

-- Перепередаём все объекты temp_owner роли postgres
REASSIGN OWNED BY temp_owner TO postgres;

-- Удаляем все объекты, принадлежащие temp_owner
DROP OWNED BY temp_owner;

-- Удаляем роль temp_owner
DROP ROLE temp_owner;

Exercise 7.4: Ролевые представления с ограничением доступа
-- Создаём представление hr_employee_view для сотрудников HR (dept_id = 102)
CREATE VIEW hr_employee_view AS
SELECT *
FROM employees
WHERE dept_id = 102;

-- Даем SELECT на hr_employee_view роли hr_team
GRANT SELECT ON hr_employee_view TO hr_team;

-- Создаём представление finance_employee_view с ограниченными колонками
CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

-- Даем SELECT на finance_employee_view роли finance_team
GRANT SELECT ON finance_employee_view TO finance_team;
Exercise 8.1: Department Dashboard View
-- Создаём представление dept_dashboard для руководителей отделов
CREATE OR REPLACE VIEW dept_dashboard AS
SELECT
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS employee_count,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    COUNT(DISTINCT p.project_id) AS active_projects,
    COALESCE(SUM(p.budget), 0) AS total_budget,
    ROUND(
        CASE
            WHEN COUNT(e.emp_id) = 0 THEN 0
            ELSE SUM(p.budget)::numeric / COUNT(e.emp_id)
        END, 2
    ) AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
LEFT JOIN projects p ON p.dept_id = d.dept_id
GROUP BY d.dept_name, d.location;


Комментарии:

Используем LEFT JOIN, чтобы показать все отделы, даже если нет сотрудников или проектов.

COALESCE обрабатывает случаи, когда суммарный бюджет = NULL.

ROUND(...,2) округляет значения до 2 знаков после запятой.

budget_per_employee учитывает деление на ноль.

Exercise 8.2: Audit View
-- 1️⃣ Добавляем колонку created_date с текущей датой в projects
ALTER TABLE projects
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 2️⃣ Создаём представление high_budget_projects
CREATE OR REPLACE VIEW high_budget_projects AS
SELECT
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;


Комментарии:

Показываем только проекты с бюджетом > 75000.

approval_status классифицирует проекты по бюджету.

Используем JOIN, чтобы добавить имя отдела.

Exercise 8.3: Create Access Control System
-- Level 1: Viewer Role
CREATE ROLE viewer_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;

-- Level 2: Entry Role
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role; -- наследует права viewer_role
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3: Analyst Role
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role; -- наследует права entry_role
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4: Manager Role
CREATE ROLE manager_role;
GRANT analyst_role TO manager_role; -- наследует права analyst_role
GRANT DELETE ON employees, projects TO manager_role;