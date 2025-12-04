CREATE TABLE accounts (
 id SERIAL PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
 id SERIAL PRIMARY KEY,
 shop VARCHAR(100) NOT NULL,
 product VARCHAR(100) NOT NULL,
 price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);
INSERT INTO products (shop, product, price) VALUES
('Joe''s shop','Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);
--3.2 Task 1:Basic transaction with commit
Begin;
Update accounts set balance=balance-100.0
    Where name='Alice';
Update accounts SET balance=balance+100.0
    Where name='Bob';
Commit;
--a)After the transaction, Alice's balance is decreased by 100.00 and Bob's balance is increased by 100.00. If Alice had 1000.00 and Bob had 500.00 before, then after the transaction Alice has 900.00 and Bob has 600.00."
--b)The main reason is between them can appear some problems, and it will influence to the database by leading problems.That's why we need use it in single transactions to determine should we execute it or not.
--c)the money may be withdrawn from one account but not deposited into the other—the database will be left in an inconsistent state.

--Task 2: Using ROLLBACK
Begin;
Update accounts set balance=balance-500.00
    WHERE name='Alice';
SELECT * FROM accounts WHERE name='Alice';
--Oops! Wrong amount ,let's undo
ROLLBACK;
SELECT*FROM accounts Where name='Alice';

--a)Before rollback and after the update Alice's balance have decreased on 500
--b)After rollback the change process in update before rollback have canceled,and all data in database remain as it was before transaction
--c)When we accidently add wrong value to column, or choose incorrect name of column to change or violate a business rule or and error occurence

--TASK 3:Working with Savepoints
Begin;
Update accounts Set balance=balance-100.00
    Where name='Alice';
Savepoint my_savepoint;
Update accounts set balance = balance + 100.00
    Where name= 'Bob';
--OOPS,should transfer to Wally instead
Rollback to my_savepoint;
Update accounts set balance = balance +100.00
    Where name='Wally';
commit;
--a) Alice's balance become 900 , Bob's balance remains same 500 ,Wally 850
--b)It was rolled back
--c)It lets you roll back part of a transaction instead of the entire transaction,and by this property we can save more time

--Task 4: Isolation level demonstration
--Scenario A: READ COMMITTED
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
--Wait for terminal 2 to make changes and COMMIT
--then re-run:
SELECT * FROM products WHERE shop='Joe''s Shop';
Commit;

--Terminal 2(While Terminal 1 is still running):
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
Insert INTO products(shop,product,price)
    VALUES ('Joe''s Shop','Fanta',3.50);
COMMIT;

--SCENARIO B:Serializable
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZable;
SELECT * FROM products WHERE shop='Joe''s Shop';
--Wait for terminal 2 to make changes and COMMIT
--then re-run:
SELECT * FROM products WHERE shop='Joe''s Shop';
Commit;

--Terminal 2(While Terminal 1 is still running):
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
Insert INTO products(shop,product,price)
    VALUES ('Joe''s Shop','Fanta',3.50);
COMMIT;

--a)Before terminal 1 sql sees only old and nonchanged data,while in terminal on contrast it sees updated data rows
--b)The both SELECTs in Terminal 1  must see only old data
--c)With SERIALIZABLE, the database must make the result look as if Terminal 1 and Terminal 2 ran one after another, not mixed.

--TASK 5: Phantom Read Demonstration
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), min(Price) from products
    Where shop='Joe''s Shop';
--Wait for terminal 2;
SELECT MAX(price),min(price) from products
    Where shop='Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
INSERT INTO products (shop, product, price)
 VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
--a)No,because one of the main property of isolation level of repeatable read is no non-repeated reads.Which means that reading same query again in the transaction return the same value ,even if the others changed and committed it
--b)A phantom read happens when, inside the same transaction, you run the same query twice, and the set of rows you get the second time is different because another transaction inserted or deleted rows that match your condition and committed in between.
--c)SERIALIZABLE level of isolation can prevent the phantom read

--TASK 6:Dirty Read Demonstration
--Termimal 1
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
UPDATE products SET price = 99.99
 WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;

--a)"Yes, Terminal 1 saw 99.99 in the second SELECT. This is problematic because that value was never committed — it was rolled back. Terminal 1 read data that effectively never existed, which can lead to incorrect decisions or inconsistent reports."
--b)"A dirty read is when a transaction reads uncommitted data from another transaction. The data is called 'dirty' because it may be rolled back, meaning we read values that were never finalized in the databas
--c)"READ UNCOMMITTED should be avoided because it allows dirty reads — reading data that may be rolled back. This can cause applications to make decisions based on data that never existed, leading to incorrect results, inconsistent reports, and potential business errors. Only use it when approximate results are acceptable and speed is more important than accuracy."
--4.Independent Exercices
SELECT * FROM accounts;

DO $$
DECLARE
    v_balance numeric;
Begin
    BEGIN;
    SELECT balance INTO v_balance
    FROM accounts
    WHERE name='Alice'
    FOR UPDATE;
    IF v_balance>=200 THEN
        UPDATE accounts
        SET balance=balance - 200
        WHERE name='Alice';

        UPDATE accounts
        SET balance=balance+200
        WHERE name='Wally';

        COMMIT;
        RAISE NOTICE 'Transfer 200 from Alice to Wally completed';
    ELSE
        ROllBACK;
        RAISE NOTICE 'Not enough funds on Alice';
    END IF;
end $$;

--task2
INSERT INTO products(name, price)
VALUES ('Widget', 10.00);    -- step 1: insert
SAVEPOINT sp1;               -- step 2: savepoint 1

UPDATE products
SET price = 12.50
WHERE name = 'Widget';       -- step 3: update
SAVEPOINT sp2;               -- step 4: savepoint 2

DELETE FROM products
WHERE name = 'Widget';       -- step 5: delete

ROLLBACK TO SAVEPOINT sp1;   -- step 6: undo delete+update
COMMIT;                      -- step 7
--task3
BEGIN;

DO $$
DECLARE
  current_balance DECIMAL(10,2);
  amount          DECIMAL(10,2) := 250.00;
BEGIN
  SELECT balance
  INTO current_balance
  FROM accounts
  WHERE name = 'Shared'
  FOR UPDATE;

  IF current_balance < amount THEN
    RAISE EXCEPTION 'Insufficient funds: current %, need %',
      current_balance, amount;
  ELSE
    UPDATE accounts
    SET balance = balance - amount
    WHERE name = 'Shared';
  END IF;
END $$;

COMMIT;

--session A
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;

-- A видит 300 и блокирует строку
SELECT balance
FROM accounts
WHERE name = 'Shared'
FOR UPDATE;

/* тут выполняем тот же DO-блок, что выше */
DO $$
DECLARE
  current_balance DECIMAL(10,2);
  amount          DECIMAL(10,2) := 250.00;
BEGIN
  SELECT balance
  INTO current_balance
  FROM accounts
  WHERE name = 'Shared'
  FOR UPDATE;

  IF current_balance < amount THEN
    RAISE EXCEPTION 'Insufficient funds: %, need %', current_balance, amount;
  ELSE
    UPDATE accounts
    SET balance = balance - amount
    WHERE name = 'Shared';
  END IF;
END $$;

-- пока НЕ коммитим, оставим блокировку висеть
-- COMMIT сделал бы после того как B начнет ждать
--SESSION B
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;

SELECT balance
FROM accounts
WHERE name = 'Shared'
FOR UPDATE;
-- эта команда будет ЖДАТЬ, пока Session A не сделает COMMIT/ROLLBACK

-- после COMMIT в Session A
-- balance теперь = 50, DO-блок выдаст "Insufficient funds" и откатит транзакцию
DO $$
DECLARE
  current_balance DECIMAL(10,2);
  amount          DECIMAL(10,2) := 250.00;
BEGIN
  SELECT balance
  INTO current_balance
  FROM accounts
  WHERE name = 'Shared'
  FOR UPDATE;

  IF current_balance < amount THEN
    RAISE EXCEPTION 'Insufficient funds: %, need %', current_balance, amount;
  ELSE
    UPDATE accounts
    SET balance = balance - amount
    WHERE name = 'Shared';
  END IF;
END $$;

ROLLBACK;  -- после исключения транзакция уже в ошибочном состоянии

--task 4
           SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN;

SELECT MAX(price) AS max_price
FROM products
WHERE product = 'Coke';

SELECT MIN(price) AS min_price
FROM products
WHERE product = 'Coke';

COMMIT;