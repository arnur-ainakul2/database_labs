--PART 1  
--TASK 1
--первая база данных
CREATE DATABASE university_main
    OWNER = postgres     
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE   = 'en_US.UTF-8'
    TEMPLATE = template0;
--вторая база данных
CREATE DATABASE university_archive
TEMPLATE=template0
CONNECTION LIMIT=50;
--третья база данных
CREATE DATABASE university_test
CONNECTION LIMIT=10;
ALTER DATABASE university_test IS_TEMPLATE = TRUE;
--TASK 1.2
--создание пространства student_data
CREATE TABLESPACE student_data
OWNER postgres
LOCATION 'C:/data/students';
--создание пространства course_data
CREATE TABLESPACE course_data
OWNER postgres 
LOCATION 'C:\data\courses';
--создание базы данных university_distributed
CREATE DATABASE university_distributed
WITH 
ENCODING='UTF8'
LC_COLLATE='C'
LC_CTYPE='C'
TABLESPACE=student_data
TEMPLATE=template0;
--PART 2 Complex management system
--TASK 2.1 UNIVERSITY MANAGEMENT SYSTEM
--создание таблицы студенты
\c university_main
CREATE TABLE students(
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone CHAR(15),
    date_of_birth DATE,
    enrollment DATE,
    gpa DECIMAL(4,2),
    is_active BOOLEAN,
    graduation_year SMALLINT
);
CREATE TABLE professors(
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    office_number VARCHAR(20),
    hire_date DATE,
    salary DECIMAL(4,2),
    is_tenured BOOLEAN,
    years_experience INT
);

CREATE TABLE courses(
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8),
    course_title VARCHAR(100),
    description TEXT,
    credits SMALLINT,
    max_enrollment INT,
    course_fee DECIMAL(4,2),
    is_online BOOLEAN,
    created_at timestamp without time zone
);

--TASK 2.2:Time-based and Specialized Tables
CREATE TABLE class_schedule(
    schedule_id SERIAL PRIMARY KEY,
    course_id INT,
    professor_id INT,
    classroom VARCHAR(20),
    class_date DATE,
    start_time time without time zone,
    end_time time without time zone,
    duration interval
);
CREATE TABLE student_records(
    record_id SERIAL PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    year INT,
    grade CHAR(2),
    attendance_percentage DECIMAL(5,1),
    submission_timestamp timestamp with time zone,
    last_updated timestamp with time zone
);

--Part 3:Advancet ALTER TABLE Operations
--Task 3.1:Modifying Existing Tables
--modifying students table:
ALTER TABLE students
ADD COLUMN middle_name VARCHAR(30),
ADD COLUMN student_status VARCHAR(20),
ALTER COLUMN phone TYPE VARCHAR(20);
ALTER COLUMN student_status SET DEFAULT 'ACTIVE',
ALTER COLUMN gpa SET DEFAULT 0.00;

--modyfying professors table:
ALTER TABLE professors
ADD COLUMN department_code CHAR(5),
ADD COLUMN research_area TEXT,
ALTER COLUMN years_experience TYPE SMALLINT,
ALTER COLUMN is_tenured SET DEFAULT FALSE,
ADD COLUMN last_promotion_date DATE;

--modyfying courses table:
ALTER TABLE courses
ADD COLUMN prerequisite_course_id INT,
ADD COLUMN difficulty_level SMALLINT,
ALTER COLUMN course_code TYPE varchar(10),
ALTER COLUMN credits SET DEFAULT 3;
ADD COLUMN lab_required BOOLEAN DEFAULT FALSE;

--Task 3.2: Column Management Operations
--FOR class_schedule table:
ALTER TABLE class_schedule
ADD COLUMN room_capacity INT,
DROP COLUMN duration,
ADD COLUMN session_type VARCHAR(15),
ALTER COLUMN classroom TYPE VARCHAR(30),
ADD COLUMN equipment_needed TEXT;

--for student record table:

ALTER TABLE student_records
ADD COLUMN extra_credit_points DECIMAL(5,1),
ALTER COLUMN grade TYPE VARCHAR(5),
ALTER COLUMN extra_credit_points SET DEFAULT 0.0,
ADD COLUMN final_exam_date DATE,
DROP COLUMN last_updated;

--PART 4:Table Relationships and Managemnet
--Task 4.1:Additional Supporting TABLES
--Table:departments
CREATE TABLE departments(
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget DECIMAL(15,2),
    established_year INT
)

CREATE TABLE library_books(
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price DECIMAL(5,2),
    is_available Boolean,
    acquisition_timestamp timestamp without time zone
)


CREATE TABLE student_book_loans(
    loan_id SERIAL PRIMARY KEY,
    student_id INT,
    book_id INT,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(5,2),
    loan_status VARCHAR(20)
)

--TASK 4.2:TABLE MODIFICATIONS FOR INTEGRATION
ALTER TABLE professors
ADD COLUMN department_id INT;
ALTER TABLE students
ADD COLUMN advisor_id INT;
ALTER TABLE courses
ADD COLUMN  department_id INT;

--table grade_scale
CREATE TABLE grade_scale(
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(5,1),
    max_percentage DECIMAL(5,1),
    gpa_points DECIMAL(5,2)
);

--TABLE semester_calendar
CREATE TABLE semester_calendar(
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline timestamp with time zone,
    is_current BOOLEAN
)

--Part 2:Table Deletion and Cleanup
--TASK 5.1:Conditional Table Operations
--DROP TABLES IF THEY EXIST
DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

--RECREATE ONE OF THE DROPPED TABLES WITH MODIFIED STRUCTURE
CREATE TABLE grade_e_scale (
    grade_id SERIAL PRIMARY KEY,       -- автоинкремент, PK
    letter_grade CHAR(2),              -- буква оценки
    min_percentage DECIMAL(5,1),       -- минимальный процент
    max_percentage DECIMAL(5,1),       -- максимальный процент
    gpa_points DECIMAL(5,2),           -- баллы GPA
    description TEXT                   -- новое поле для описания (неограниченный текст)
);

--DROP AND RECREATE WITH CASCADE:
DROP TABLE IF EXISTS semester_calendar CASCADE;
CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INT,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN
);


--TASK 5.2:DATABASE CLEANUP
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;
CREATE DATABASE university_backup
TEMPLATE university_main;