--TASK 1.1:check
DROP TABLE IF EXISTS employees;
CREATE TABLE if not exists employees(
    employee_id INT,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age>=18 AND age<=65),
    salary NUMERIC CHECK(salary>0)
);
--TASK 1.2:NAMED CHECK
DROP TABLE IF EXISTS products_catalog;
CREATE TABLE if not exists products_catalog(
    product_id INTEGER,
    product_name text,
    regular_price numeric,
    discount_price numeric,
    constraint valid_discount check(
        regular_price>0
        AND discount_price>0
        AND discount_price <regular_price
        )
);
--task 1.3:multiple column check
DROP TABLE IF EXISTS bookings;
CREATE TABLE if not exists bookings (
    booking_id INT,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INT,
    CONSTRAINT guests_check CHECK (num_guests BETWEEN 1 AND 10),
    CONSTRAINT after_1 CHECK (check_out_date > check_in_date)
);

--task 1.4
INSERT INTO employees(employee_id, first_name, last_name, age, salary)
VALUES (1, 'Auzhan', 'Erkebulan', 18, 500000);

INSERT INTO employees(employee_id, first_name, last_name, age, salary)
VALUES (2, 'Python', 'Leader', 20, 500000000);
INSERT INTO products_catalog(product_id, product_name, regular_price, discount_price)
VALUES (1, 'playstation', 50000, 40000);

INSERT INTO products_catalog(product_id, product_name, regular_price, discount_price)
VALUES (2, 'TV', 60000, 30000);

INSERT INTO bookings(booking_id, check_in_date, check_out_date, num_guests)
VALUES (1, '2025-10-01', '2025-10-03', 4);

INSERT INTO bookings(booking_id, check_in_date, check_out_date, num_guests)
VALUES (2, '2025-09-28', '2025-09-30', 5);



--TASK 2.1:NOT NULL
CREATE TABLE customers(
    customer_id INTEGER NOT NULL,
    email text not null,
    phone text,
    registration_date date not null
);
CREATE TABLE inventory(
    item_id INT not null,
    item_name text not null,
    quantity int not null check(quantity>0),
    unit_price numeric not null check(quantity>0),
    last_updated timestamp not null

);
--1
INSERT INTO customers(customer_id,email,phone,registration_date) VALUES(1,'sfdffasf@gmail.com','870823143','2025-10-12');
INSERT INTO inventory(item_id,item_name,quantity,unit_price,last_updated) VALUES(1,'kit',3,15000,'2025-10-13 14:00:00');
--2
INSERT INTO customers(customer_id,email,registration_date) VALUES(NULL,NULl,NULL);
INSERT INTO inventory(item_id,item_name,quantity,unit_price,last_updated) VALUES(NULL,NULL,NULL,NULL,NULL);
--3
INSERT INTO customers(customer_id,email,phone,registration_date) VALUES(3,'dsadasa@mail.ru',NULL,'2025-10-12');

--Unique
--3.1
CREATE TABLE users(
    user_id INT,
    username text unique,
    email text unique,
    created_at timestamp
);
--3.2
CREATE TABLE course_enrollment(
    enrollment_id int,
    student_id int,
    course_code text,
    semester text,
    constraint uniqueness unique(student_id,course_code,semester)
);
--3.3
ALTER TABLE users
ADD constraint unique_username unique(username);

ALTER TABLE users
ADD constraint unique_email unique(email);

Insert INto users(username) VALUES('fasdsadsa');
Insert INto users(username) VALUES('fasdsadsa');

--part 4 primary key;
Create table departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name text not null,
    location text
);
Insert into departments(dept_id,dept_name,location) values(1,'dsaasd','astana');
Insert into departments(dept_id,dept_name,location) values(1,'dsaasd','astana');
Insert into departments(dept_id,dept_name,location) values(1,'dsaasd','astana');

Insert into departments(dept_id,dept_name,location) values(null,'dsad','asdada');
--task 4.2;
CREATE TABLE student_courses(
    student_id int,
    course_id int,
    enrollment_date date,
    grade text,
    PRIMARY KEY (student_id, course_id)
)
--task 4.3
/*
Difference between UNIQUE and PRIMARY KEY
PRIMARY KEY — main identifier of a row.
Always unique.
Cannot be NULL.
Only one per table.
UNIQUE — ensures uniqueness of one or more columns.
Values must be unique, but NULL is allowed.
You can have multiple UNIQUE constraints per table.
2. When to use single-column vs composite PRIMARY KEY
Single-column PRIMARY KEY — one column uniquely identifies a row.
Example: user_id in a users table.
Composite (multi-column) PRIMARY KEY — combination of two or more columns uniquely identifies a row.
Example: student_id + course_id in a student_courses table.
Used when a single column is not enough.
3. Why a table can have only one PRIMARY KEY but multiple UNIQUE constraints
PRIMARY KEY — only one main identifier per table.
UNIQUE — additional uniqueness rules for other columns or combinations.
Example: employee_id as PRIMARY KEY, email and username as UNIQUE.
*/
--part5
--5.1.
CREATE TABLE employees_dept(
    emp_id int primary key
    emp_name text not null,
    dept_id int references departments(dept_id),
    hire_date date;
)
insert into employees_dept(emp_id,emp_name,dept_id,hire_date) 
values
(1,'sadd',1,'2025-01-10'),
(2,'sdads',2,'2025-03-15'),
(3,'dsadas',3,'2025-10-13');
INSERT INTO employees_dept (emp_id, emp_name, dept_id, hire_date)
VALUES (4, 'David Lee', 99, '2025-06-01');

--5.2
CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

-- Publishers table
CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

-- Books table
CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT REFERENCES authors,
    publisher_id INT REFERENCES publishers,
    publication_year INT,
    isbn TEXT UNIQUE
);
-- Authors
INSERT INTO authors VALUES
(1, 'J.K. Rowling', 'UK'),
(2, 'George Orwell', 'UK'),
(3, 'Mark Twain', 'USA'),
(4, 'Jane Austen', 'UK'),
(5, 'Ernest Hemingway', 'USA');

-- Publishers
INSERT INTO publishers VALUES
(1, 'Penguin Books', 'London'),
(2, 'HarperCollins', 'New York'),
(3, 'Random House', 'New York'),
(4, 'Oxford Press', 'Oxford'),
(5, 'Vintage', 'London');

-- Books
INSERT INTO books VALUES
(1, 'Harry Potter', 1, 1, 1997, '9780747532743'),
(2, '1984', 2, 2, 1949, '9780451524935'),
(3, 'Adventures of Huckleberry Finn', 3, 3, 1884, '9780486280615'),
(4, 'Pride and Prejudice', 4, 4, 1813, '9780141439518'),
(5, 'The Old Man and the Sea', 5, 5, 1952, '9780684801223');

--5.3
-- Categories
CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name TEXT NOT NULL
);

-- Products with RESTRICT
CREATE TABLE products_fk (
    product_id INT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INT REFERENCES categories ON DELETE RESTRICT
);

-- Orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL
);

-- Order items with CASCADE
CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders ON DELETE CASCADE,
    product_id INT REFERENCES products_fk,
    quantity INT CHECK (quantity > 0)
);

--6.1
REATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- Products
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INT CHECK (stock_quantity >= 0)
);

-- Orders
CREATE TABLE orders_ecom (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

-- Order Details
CREATE TABLE order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders_ecom ON DELETE CASCADE,
    product_id INT REFERENCES products,
    quantity INT CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);
--sample data
INSERT INTO customers (name, email, phone, registration_date) VALUES
('Alice Smith','alice@example.com','1234567890','2025-01-01'),
('Bob Johnson','bob@example.com','2345678901','2025-02-10'),
('Charlie Brown','charlie@example.com','3456789012','2025-03-05'),
('David Lee','david@example.com','4567890123','2025-04-12'),
('Emma Davis','emma@example.com','5678901234','2025-05-20');

-- Products
INSERT INTO products (name, description, price, stock_quantity) VALUES
('Laptop','Gaming laptop',1000,10),
('Smartphone','Latest model',700,20),
('Headphones','Wireless',150,50),
('Monitor','4K display',300,15),
('Keyboard','Mechanical',80,25);

-- Orders
INSERT INTO orders_ecom (customer_id, order_date, total_amount, status) VALUES
(1,'2025-10-01',1700,'pending'),
(2,'2025-10-02',1000,'processing'),
(3,'2025-10-03',150,'shipped'),
(4,'2025-10-04',380,'delivered'),
(5,'2025-10-05',80,'cancelled');

-- Order Details
INSERT INTO order_details (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,1000),
(1,2,1,700),
(2,1,1,1000),
(3,3,1,150),
(4,4,1,300),
(4,5,1,80);

--test
--Test constraints

/*Try inserting negative price / stock → ❌ fails because of CHECK.

Try inserting invalid status → ❌ fails due to CHECK on status.

Try inserting zero or negative quantity in order_details → ❌ fails.

Try inserting duplicate customer email → ❌ fails due to UNIQUE.

Delete a customer → ✅ all their orders and order_details are deleted automatically (CASCADE).
*/