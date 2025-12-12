-- Bonus lab KazFinance
-- Student: Ainakul Arnur, Thursday 9:00
-- 1. SCHEMA: tables
----------------------------------------------------------------------------
SET client_min_messages = WARNING;

-- Drop if exists for repeatability
DROP MATERIALIZED VIEW IF EXISTS salary_batch_summary;
DROP VIEW IF EXISTS suspicious_activity_view;
DROP VIEW IF EXISTS daily_transaction_report;
DROP VIEW IF EXISTS customer_balance_summary;
DROP FUNCTION IF EXISTS process_transfer(text, text, numeric, text, text);
DROP FUNCTION IF EXISTS process_salary_batch(text, jsonb);
DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS exchange_rates;
DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS customers;

-- customers
CREATE TABLE customers (
    customer_id   BIGSERIAL PRIMARY KEY,
    iin           CHAR(12) UNIQUE NOT NULL, -- 12 digits
    full_name     TEXT NOT NULL,
    phone         TEXT,
    email         TEXT,
    status        VARCHAR(10) NOT NULL DEFAULT 'active', -- active/blocked/frozen
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    daily_limit_kzt NUMERIC(18,2) NOT NULL DEFAULT 1000000 -- default 1,000,000 KZT
);

-- accounts
CREATE TABLE accounts (
    account_id    BIGSERIAL PRIMARY KEY,
    customer_id   BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number TEXT UNIQUE NOT NULL, -- IBAN-like
    currency      VARCHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance       NUMERIC(20,2) NOT NULL DEFAULT 0,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    closed_at     TIMESTAMPTZ
);

-- exchange_rates
CREATE TABLE exchange_rates (
    rate_id       BIGSERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency   VARCHAR(3) NOT NULL,
    rate          NUMERIC(30,10) NOT NULL,
    valid_from    TIMESTAMPTZ NOT NULL,
    valid_to      TIMESTAMPTZ
);

-- transactions
CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id BIGINT REFERENCES accounts(account_id) ON DELETE SET NULL,
    to_account_id   BIGINT REFERENCES accounts(account_id) ON DELETE SET NULL,
    amount          NUMERIC(20,2) NOT NULL,
    currency        VARCHAR(3) NOT NULL,
    exchange_rate   NUMERIC(30,10),
    amount_kzt      NUMERIC(20,2) NOT NULL,
    type            VARCHAR(20) NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
    status          VARCHAR(20) NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    description     TEXT
);

-- audit_log
CREATE TABLE audit_log (
    log_id      BIGSERIAL PRIMARY KEY,
    table_name  TEXT NOT NULL,
    record_id   TEXT,
    action      VARCHAR(10) NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_values  JSONB,
    new_values  JSONB,
    changed_by  TEXT,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    ip_address  INET
);

-------------------------------------------------------------------------------------------
    --INSERTING DATA
-- customers:
INSERT INTO customers (iin, full_name, phone, email, status, created_at, daily_limit_kzt)
VALUES
('870101123456','Aizhan Nurmagambet','+7-701-000-0001','aizhan@example.com','active',now()-interval '400 days', 2000000),
('880202123457','Baurzhan Sapar','+7-701-000-0002','baurzhan@example.com','active',now()-interval '300 days', 1500000),
('890303123458','Dina Akhmetova','+7-701-000-0003','dina@example.com','blocked',now()-interval '200 days', 500000),
('900404123459','Ermek Nurgali','+7-701-000-0004','ermek@example.com','active',now()-interval '100 days', 1000000),
('910505123450','Gulnara Toleu','+7-701-000-0005','gulnara@example.com','frozen',now()-interval '90 days', 800000),
('920606123451','Kairat S','+7-701-000-0006','kairat.s@example.com','active',now()-interval '60 days', 1200000),
('930707123452','Laila M','+7-701-000-0007','laila@example.com','active',now()-interval '50 days', 600000),
('940808123453','Marat Zh','+7-701-000-0008','marat@example.com','active',now()-interval '40 days', 900000),
('950909123454','Nazira K','+7-701-000-0009','nazira@example.com','active',now()-interval '30 days', 700000),
('961010123455','Oleg P','+7-701-000-0010','oleg@example.com','active',now()-interval '20 days', 1100000),
('971111123456','Polina R','+7-701-000-0011','polina@example.com','active',now()-interval '10 days', 1000000),
('980121123457','Qairat B','+7-701-000-0012','qairat@example.com','active',now()-interval '5 days', 3000000);

-- accounts:
INSERT INTO accounts (customer_id, account_number, currency, balance, is_active, opened_at)
VALUES
(1,'KZ00AIZHAN0000000001','KZT', 5_000_000.00, TRUE, now()-interval '300 days'),
(1,'KZ00AIZHAN0000000002','USD', 2_000.00, TRUE, now()-interval '300 days'),
(2,'KZ00BAURZHA000000001','KZT', 1_200_000.00, TRUE, now()-interval '200 days'),
(3,'KZ00DINA00000000003','KZT', 50_000.00, TRUE, now()-interval '150 days'),
(4,'KZ00ERMEK0000000004','EUR', 500.00, TRUE, now()-interval '100 days'),
(5,'KZ00GULNARA00000005','RUB', 30000.00, TRUE, now()-interval '90 days'),
(6,'KZ00KAIRAT0000000006','KZT', 800_000.00, TRUE, now()-interval '60 days'),
(7,'KZ00LAILA0000000007','USD', 100.00, TRUE, now()-interval '50 days'),
(8,'KZ00MARAT0000000008','KZT', 2_500_000.00, TRUE, now()-interval '40 days'),
(9,'KZ00NAZIRA0000000009','EUR', 50.00, TRUE, now()-interval '30 days'),
(10,'KZ00OLEG0000000010','KZT', 300_000.00, TRUE, now()-interval '20 days'),
(11,'KZ00POLINA0000000011','KZT', 650_000.00, TRUE, now()-interval '10 days'),
(12,'KZ00QAIRAT0000000012','USD', 10_000.00, TRUE, now()-interval '2 days');

-- exchange_rates:
INSERT INTO exchange_rates (from_currency,to_currency,rate,valid_from,valid_to)
VALUES
('USD','KZT', 470.00, now()-interval '10 days', now()+interval '30 days'),
('EUR','KZT', 510.00, now()-interval '10 days', now()+interval '30 days'),
('RUB','KZT', 5.50, now()-interval '10 days', now()+interval '30 days'),
('KZT','KZT', 1, now()-interval '10 days', now()+interval '30 days'),
('USD','EUR', 0.92, now()-interval '10 days', now()+interval '30 days'),
('EUR','USD', 1.09, now()-interval '10 days', now()+interval '30 days'),
('USD','RUB', 85.0, now()-interval '10 days', now()+interval '30 days'),
('RUB','USD', 0.01176, now()-interval '10 days', now()+interval '30 days'),
('EUR','RUB', 93.0, now()-interval '10 days', now()+interval '30 days'),
('RUB','EUR', 0.01075, now()-interval '10 days', now()+interval '30 days');

-- transactions:
INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,completed_at,description)
VALUES
(1,3, 200000, 'KZT', 1, 200000, 'transfer', 'completed', now()-interval '2 days', now()-interval '2 days', 'Payment A->B'),
(3,1, 50000, 'KZT', 1, 50000, 'transfer', 'completed', now()-interval '1 day', now()-interval '1 day', 'Refund'),
(2,7, 100.00, 'USD', 470, 47000, 'transfer', 'completed', now()-interval '20 hours', now()-interval '20 hours', 'USD transfer'),
(8,1, 250000, 'KZT', 1, 250000, 'transfer', 'completed', now()-interval '3 days', now()-interval '3 days', 'Loan pay'),
(NULL,1, 100000, 'KZT', 1, 100000, 'deposit', 'completed', now()-interval '10 days', now()-interval '10 days', 'Cash deposit'),
(1,NULL, 50000, 'KZT', 1, 50000, 'withdrawal', 'completed', now()-interval '40 days', now()-interval '40 days', 'ATM withdrawal'),
(12,11, 500.00, 'USD', 470, 235000, 'transfer', 'completed', now()-interval '5 hours', now()-interval '5 hours', 'Salary'),
(1,4, 200.00, 'USD', 470, 94000, 'transfer', 'completed', now()-interval '4 hours', now()-interval '4 hours', 'To EUR acct'),
(6,10, 100000, 'KZT', 1, 100000, 'transfer', 'completed', now()-interval '3 hours', now()-interval '3 hours', 'Routine'),
(1,9, 80.00, 'USD', 470, 37600, 'transfer', 'completed', now()-interval '2 hours', now()-interval '2 hours', 'Small USD');

-- audit_log:
INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by, changed_at, ip_address)
VALUES
('customers','1','INSERT', NULL, jsonb_build_object('iin','870101123456','full_name','Aizhan Nurmagambet'), 'system', now()-interval '400 days', '127.0.0.1'),
('accounts','1','INSERT', NULL, jsonb_build_object('account_number','KZ00AIZHAN0000000001','balance',5000000), 'system', now()-interval '300 days', '127.0.0.1');

---------------------------------------------------------------------------------------------------------------------
-- 3. indexes
-- 1) btree
CREATE INDEX idx_accounts_customer_id ON accounts(customer_id); -- common join
CREATE INDEX idx_transactions_created_at ON transactions(created_at);

-- 2) composite
CREATE INDEX idx_tx_from_created ON transactions (from_account_id, created_at DESC);

-- 3) partial
CREATE INDEX idx_accounts_accountnum_cover ON accounts (account_number) INCLUDE (balance, currency, is_active);

-- 4)  partial
CREATE INDEX idx_accounts_active ON accounts (account_number) WHERE is_active IS TRUE;

-- 5) email lower
CREATE INDEX idx_customers_email_lower ON customers (lower(email));

-- 6) gin jsonb
CREATE INDEX idx_auditlog_jsonb ON audit_log USING gin ((coalesce(old_values,'{}'::jsonb) || coalesce(new_values,'{}'::jsonb)));

-- 7) hash
CREATE INDEX idx_exch_from_to_hash ON exchange_rates USING hash (from_currency, to_currency);



----------------------------------------------------------------------------------
-- 4. Stored procedure: process_transfer
CREATE OR REPLACE FUNCTION process_transfer(
    from_account_number TEXT,
    to_account_number   TEXT,
    in_amount           NUMERIC,
    in_currency         TEXT,
    in_description      TEXT
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_from_account RECORD;
    v_to_account   RECORD;
    v_sender_customer RECORD;
    v_rate_to_kzt NUMERIC;
    v_exchange_rate NUMERIC := NULL;
    v_amount_kzt NUMERIC;
    v_daily_sum NUMERIC;
    v_tx_id BIGINT;
BEGIN
    IF in_amount <= 0 THEN
        RETURN jsonb_build_object('status','failed','code','TF_001','message','Amount must be positive');
    END IF;

    -- Basic existence checks
    SELECT * INTO v_from_account FROM accounts WHERE account_number = from_account_number;
    IF NOT FOUND THEN
        -- audit log
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('accounts', from_account_number, 'UPDATE', NULL, jsonb_build_object('attempt','transfer_from_not_found','amount', in_amount), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_002','message','Source account not found');
    END IF;

    SELECT * INTO v_to_account FROM accounts WHERE account_number = to_account_number;
    IF NOT FOUND THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('accounts', to_account_number, 'UPDATE', NULL, jsonb_build_object('attempt','transfer_to_not_found','amount', in_amount), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_003','message','Destination account not found');
    END IF;

    IF NOT v_from_account.is_active THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('accounts', from_account_number, 'UPDATE', jsonb_build_object('is_active', v_from_account.is_active), jsonb_build_object('attempt','transfer_from_inactive'), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_004','message','Source account is not active');
    END IF;

    IF NOT v_to_account.is_active THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('accounts', to_account_number, 'UPDATE', jsonb_build_object('is_active', v_to_account.is_active), jsonb_build_object('attempt','transfer_to_inactive'), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_005','message','Destination account is not active');
    END IF;

    -- Check sender customer status
    SELECT c.* INTO v_sender_customer FROM customers c WHERE c.customer_id = v_from_account.customer_id;
    IF v_sender_customer.status <> 'active' THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('customers', v_sender_customer.customer_id::text, 'UPDATE', jsonb_build_object('status', v_sender_customer.status), jsonb_build_object('attempt','transfer_customer_not_active'), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_006','message','Source customer status not active');
    END IF;

    -- Use SELECT ... FOR UPDATE to lock accounts
    -- Lock order to avoid deadlocks
    IF v_from_account.account_id < v_to_account.account_id THEN
        SELECT * INTO v_from_account FROM accounts WHERE account_id = v_from_account.account_id FOR UPDATE;
        SELECT * INTO v_to_account   FROM accounts WHERE account_id = v_to_account.account_id FOR UPDATE;
    ELSE
        SELECT * INTO v_to_account   FROM accounts WHERE account_id = v_to_account.account_id FOR UPDATE;
        SELECT * INTO v_from_account FROM accounts WHERE account_id = v_from_account.account_id FOR UPDATE;
    END IF;

    -- convert to KZT
    IF in_currency = 'KZT' THEN
        v_exchange_rate := 1;
        v_amount_kzt := in_amount;
    ELSE
        -- find the latest valid rate from in_currency -> KZT
        SELECT rate INTO v_rate_to_kzt
         FROM exchange_rates
         WHERE from_currency = in_currency AND to_currency = 'KZT'
           AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
         ORDER BY valid_from DESC LIMIT 1;

        IF v_rate_to_kzt IS NULL THEN
            -- log and error
            INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
            VALUES ('exchange_rates', in_currency || '->KZT', 'UPDATE', NULL, jsonb_build_object('attempt','missing_rate'), 'process_transfer');
            RETURN jsonb_build_object('status','failed','code','TF_007','message','No KZT rate for ' || in_currency);
        END IF;
        v_exchange_rate := v_rate_to_kzt;
        v_amount_kzt := (in_amount * v_rate_to_kzt)::numeric(20,2);
    END IF;

    -- check daily limit
    SELECT COALESCE(SUM(amount_kzt),0) INTO v_daily_sum
     FROM transactions
     WHERE from_account_id = v_from_account.account_id
       AND status = 'completed'
       AND created_at::date = current_date;

    IF (v_daily_sum + v_amount_kzt) > v_sender_customer.daily_limit_kzt THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('attempt','daily_limit_exceeded','sum_today', v_daily_sum, 'this_amount_kzt', v_amount_kzt), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_008','message','Daily transaction limit exceeded');
    END IF;

    -- check balance in source currency
    DECLARE
        v_amount_in_source_currency NUMERIC;
        v_rate_in_to_src NUMERIC;
    BEGIN
        IF in_currency = v_from_account.currency THEN
            v_amount_in_source_currency := in_amount;
        ELSE
            -- find exchange rate from in_currency -> source_currency
            SELECT rate INTO v_rate_in_to_src
             FROM exchange_rates
             WHERE from_currency = in_currency AND to_currency = v_from_account.currency
               AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
             ORDER BY valid_from DESC LIMIT 1;

            IF v_rate_in_to_src IS NULL THEN
                -- try via KZT as fallback (in -> KZT, KZT -> src)
                SELECT rate INTO v_rate_in_to_src FROM exchange_rates WHERE from_currency = in_currency AND to_currency = 'KZT' AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                IF FOUND THEN
                    -- find KZT -> source_currency
                    SELECT rate INTO v_rate_in_to_src FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_from_account.currency AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                END IF;
            END IF;

            IF v_rate_in_to_src IS NULL THEN
                RETURN jsonb_build_object('status','failed','code','TF_009','message','Missing exchange rate to convert payment currency to source account currency');
            END IF;
            v_amount_in_source_currency := (in_amount * v_rate_in_to_src)::numeric(20,2);
        END IF;
    END;

    IF v_from_account.balance < v_amount_in_source_currency THEN
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('accounts', v_from_account.account_number, 'UPDATE', jsonb_build_object('balance',v_from_account.balance), jsonb_build_object('attempt','insufficient_funds','requested', v_amount_in_source_currency), 'process_transfer');
        RETURN jsonb_build_object('status','failed','code','TF_010','message','Insufficient funds in source account');
    END IF;

    -- All checks passed: perform the transfer in a SAVEPOINT to allow partial rollback
    SAVEPOINT sp_transfer;

    BEGIN
        -- Calculate exchange_rate to use for record
        IF v_from_account.currency = v_to_account.currency THEN
            v_exchange_rate := 1;
        ELSE
            -- find rate from from_account.currency -> to_account.currency
            SELECT rate INTO v_exchange_rate
             FROM exchange_rates
             WHERE from_currency = v_from_account.currency AND to_currency = v_to_account.currency
               AND valid_from <= now() AND (valid_to IS NULL OR valid_to > now())
             ORDER BY valid_from DESC LIMIT 1;

            IF v_exchange_rate IS NULL THEN
                -- attempt via KZT
                -- from -> KZT then KZT -> to
                DECLARE r1 NUMERIC; r1 := NULL; r1 := NULL;
                SELECT rate INTO r1 FROM exchange_rates WHERE from_currency = v_from_account.currency AND to_currency = 'KZT' AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                DECLARE r2 NUMERIC; r2 := NULL;
                SELECT rate INTO r2 FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_to_account.currency AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                IF r1 IS NOT NULL AND r2 IS NOT NULL THEN
                    v_exchange_rate := r1 * r2;
                ELSE
                    -- default continue with no exchange rate but log
                    RAISE NOTICE 'No direct conversion rate found from % to %', v_from_account.currency, v_to_account.currency;
                    v_exchange_rate := NULL;
                END IF;
            END IF;
        END IF;

        -- Insert transactions row (pending)
        INSERT INTO transactions (from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,created_at,description)
        VALUES (v_from_account.account_id, v_to_account.account_id, in_amount, in_currency, v_exchange_rate, v_amount_kzt, 'transfer', 'pending', now(), in_description)
        RETURNING transaction_id INTO v_tx_id;

        -- Debit source account: deduct in source currency (v_amount_in_source_currency)
        UPDATE accounts SET balance = balance - v_amount_in_source_currency WHERE account_id = v_from_account.account_id;

        -- Credit destination account: convert source amount into destination currency
        DECLARE v_amount_for_dest NUMERIC;
        BEGIN
            IF v_from_account.currency = v_to_account.currency THEN
                v_amount_for_dest := v_amount_in_source_currency;
            ELSE
                -- convert from source currency into dest currency
                IF v_exchange_rate IS NOT NULL THEN
                    -- v_exchange_rate defined as source_currency -> dest_currency
                    v_amount_for_dest := (v_amount_in_source_currency * v_exchange_rate)::numeric(20,2);
                ELSE
                    -- fallback: convert via KZT: source->KZT then KZT->dest
                    DECLARE r_src_kzt NUMERIC; r_src_kzt := NULL;
                    DECLARE r_kzt_dest NUMERIC; r_kzt_dest := NULL;
                    SELECT rate INTO r_src_kzt FROM exchange_rates WHERE from_currency = v_from_account.currency AND to_currency = 'KZT' AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                    SELECT rate INTO r_kzt_dest FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_to_account.currency AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                    IF r_src_kzt IS NULL OR r_kzt_dest IS NULL THEN
                        -- cannot convert -> rollback
                        ROLLBACK TO SAVEPOINT sp_transfer;
                        UPDATE transactions SET status = 'failed', completed_at = now() WHERE transaction_id = v_tx_id;
                        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
                        VALUES ('transactions', v_tx_id::text, 'UPDATE', NULL, jsonb_build_object('status','failed','reason','missing_conversion'), 'process_transfer');
                        RETURN jsonb_build_object('status','failed','code','TF_011','message','No rate for dest account');
                    END IF;
                    v_amount_for_dest := (v_amount_in_source_currency * r_src_kzt * r_kzt_dest)::numeric(20,2);
                END IF;
            END IF;
        END;

        UPDATE accounts SET balance = balance + v_amount_for_dest WHERE account_id = v_to_account.account_id;

        -- Mark transaction completed
        UPDATE transactions SET status = 'completed', completed_at = now() WHERE transaction_id = v_tx_id;

        -- Audit log success
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('transactions', v_tx_id::text, 'INSERT', NULL,
                jsonb_build_object('from', v_from_account.account_number, 'to', v_to_account.account_number, 'amount', in_amount, 'currency', in_currency, 'amount_kzt', v_amount_kzt, 'status','completed'),
                'process_transfer');

    EXCEPTION WHEN others THEN
      -- rollback to savepoint
        ROLLBACK TO SAVEPOINT sp_transfer;
        IF v_tx_id IS NOT NULL THEN
            UPDATE transactions SET status = 'failed', completed_at = now() WHERE transaction_id = v_tx_id;
            INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
            VALUES ('transactions', v_tx_id::text, 'UPDATE', NULL, jsonb_build_object('status','failed','error', SQLERRM), 'process_transfer');
        END IF;
        RETURN jsonb_build_object('status','failed','code','TF_999','message', 'Unexpected error: ' || SQLERRM);
    END;

    RETURN jsonb_build_object('status','success','code','TF_000','message','Transfer completed','transaction_id', v_tx_id);
END;
$$;

-- ============================================================
-- View 1: customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    c.iin,
    c.email,
    c.daily_limit_kzt,
    a.account_id,
    a.account_number,
    a.currency,
    a.balance,
    -- convert each account balance to KZT using latest exchange rate
    (a.balance * COALESCE((
        SELECT rate FROM exchange_rates er
        WHERE er.from_currency = a.currency AND er.to_currency = 'KZT'
          AND er.valid_from <= now() AND (er.valid_to IS NULL OR er.valid_to > now())
        ORDER BY er.valid_from DESC LIMIT 1
    ),1))::numeric(20,2) AS balance_kzt,
    -- total per customer (window)
    SUM( (a.balance * COALESCE((
        SELECT rate FROM exchange_rates er
        WHERE er.from_currency = a.currency AND er.to_currency = 'KZT'
          AND er.valid_from <= now() AND (er.valid_to IS NULL OR er.valid_to > now())
        ORDER BY er.valid_from DESC LIMIT 1
    ),1)) ) OVER (PARTITION BY c.customer_id)::numeric(20,2) AS total_balance_kzt,
    -- daily limit utilization: (sum of today's transfers for this customer / daily_limit_kzt) * 100
    ( COALESCE((
        SELECT SUM(t.amount_kzt) FROM transactions t
        JOIN accounts ac ON ac.account_id = t.from_account_id
        WHERE ac.customer_id = c.customer_id AND t.status = 'completed' AND t.created_at::date = current_date
    ),0) / NULLIF(c.daily_limit_kzt,0) * 100 )::numeric(5,2) AS daily_limit_util_pct,
    -- rank by total balance
    RANK() OVER (ORDER BY SUM( (a.balance * COALESCE((
        SELECT rate FROM exchange_rates er
        WHERE er.from_currency = a.currency AND er.to_currency = 'KZT'
          AND er.valid_from <= now() AND (er.valid_to IS NULL OR er.valid_to > now())
        ORDER BY er.valid_from DESC LIMIT 1
    ),1)) ) OVER (PARTITION BY c.customer_id) DESC) AS balance_rank
FROM customers c
LEFT JOIN accounts a ON a.customer_id = c.customer_id
ORDER BY total_balance_kzt DESC NULLS LAST;

-- View 2: daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    date_trunc('day', created_at)::date AS tx_date,
    type,
    COUNT(*) AS tx_count,
    SUM(amount_kzt) AS total_volume_kzt,
    AVG(amount_kzt) AS avg_amount_kzt,
    SUM(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) AS running_total_kzt,
    LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) AS prev_day_total_kzt,
    CASE
      WHEN LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) IS NULL THEN NULL
      WHEN LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) = 0 THEN NULL
      ELSE (SUM(amount_kzt) - LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at))) / LAG(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day', created_at)) * 100
    END AS day_over_day_growth_pct
FROM transactions
WHERE created_at IS NOT NULL
GROUP BY date_trunc('day', created_at), type
ORDER BY tx_date DESC;

-- View 3: suspicious_activity_view (WITH SECURITY BARRIER)
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount_kzt,
    t.created_at,
    t.status,
    -- Over threshold flag
    (t.amount_kzt > 5000000) AS over_threshold_flag,
    -- customers with >10 transactions in a single hour (we will join and mark)
    EXISTS (
        SELECT 1 FROM (
            SELECT from_account_id, date_trunc('hour', created_at) AS hour_bucket, count(*) AS cnt
            FROM transactions tt
            WHERE tt.from_account_id = t.from_account_id
            GROUP BY from_account_id, date_trunc('hour', created_at)
            HAVING count(*) > 10
        ) x WHERE x.from_account_id = t.from_account_id AND date_trunc('hour', t.created_at) = x.hour_bucket
    ) AS high_freq_hour_flag,
    -- rapid sequential transfers: check if this sender had another transfer within 1 minute before
    EXISTS (
        SELECT 1 FROM transactions tt2
        WHERE tt2.from_account_id = t.from_account_id
          AND tt2.transaction_id <> t.transaction_id
          AND tt2.created_at BETWEEN t.created_at - interval '1 minute' AND t.created_at + interval '1 minute'
    ) AS rapid_seq_flag
FROM transactions t
WHERE t.status = 'completed'
  AND (
    t.amount_kzt > 5000000
    OR EXISTS (
        SELECT 1 FROM (
            SELECT from_account_id, date_trunc('hour', created_at) AS hour_bucket, count(*) AS cnt
            FROM transactions tt
            GROUP BY from_account_id, date_trunc('hour', created_at)
            HAVING count(*) > 10
        ) x WHERE x.from_account_id = t.from_account_id AND date_trunc('hour', t.created_at) = x.hour_bucket
    )
    OR EXISTS (
        SELECT 1 FROM transactions tt2 WHERE tt2.from_account_id = t.from_account_id
          AND tt2.transaction_id <> t.transaction_id
          AND tt2.created_at BETWEEN t.created_at - interval '1 minute' AND t.created_at + interval '1 minute'
    )
  );

-- ============================================================
-- 6. process_salary_batch procedure
CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number TEXT,
    payments_jsonb JSONB
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_company RECORD;
    v_payments JSONB;
    v_total NUMERIC := 0;
    v_payment JSONB;
    v_iin TEXT;
    v_amount NUMERIC;
    v_description TEXT;
    v_emp_customer RECORD;
    v_emp_account RECORD;
    v_results JSONB := '[]'::jsonb;
    v_success_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::jsonb;
    v_tx_id BIGINT;
    v_lock_key BIGINT;
    temp_updates TABLE(tmp_account_id BIGINT, tmp_delta NUMERIC);
BEGIN
    -- find company + advisory lock
    SELECT * INTO v_company FROM accounts WHERE account_number = company_account_number;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('status','failed','code','SB_001','message','Company account not found');
    END IF;

    -- use advisory lock on company account id
    v_lock_key := v_company.account_id;
    PERFORM pg_advisory_lock(v_lock_key);

    BEGIN
        v_payments := payments_jsonb;

        -- check array
        IF jsonb_typeof(v_payments) IS DISTINCT FROM 'array' THEN
            PERFORM pg_advisory_unlock(v_lock_key);
            RETURN jsonb_build_object('status','failed','code','SB_002','message','Payments must be a JSONB array');
        END IF;

        -- sum total batch amount (in company account currency) by converting each payment amount from default KZT (assume payments.amount are in KZT) to company currency
        -- For simplicity, assume input amounts are in KZT. Convert to company currency if needed.
        FOR v_payment IN SELECT * FROM jsonb_array_elements(v_payments)
        LOOP
            v_iin := v_payment->> 'iin';
            v_amount := (v_payment->> 'amount')::numeric;
            v_description := COALESCE(v_payment->> 'description','salary');

            -- Convert v_amount (KZT) to company's currency if company account currency != KZT
            IF v_company.currency = 'KZT' THEN
                v_total := v_total + v_amount;
            ELSE
                -- find KZT -> company_currency rate
                DECLARE r NUMERIC;
                SELECT rate INTO r FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_company.currency AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                IF r IS NULL THEN
                    -- fallback fail the batch start
                    PERFORM pg_advisory_unlock(v_lock_key);
                    RETURN jsonb_build_object('status','failed','code','SB_003','message','Missing rate KZT->' || v_company.currency);
                END IF;
                v_total := v_total + (v_amount * r);
            END IF;
        END LOOP;

        -- Check company has sufficient balance
        IF v_company.balance < v_total THEN
            PERFORM pg_advisory_unlock(v_lock_key);
            RETURN jsonb_build_object('status','failed','code','SB_004','message','Company account has insufficient funds for total batch','required',v_total,'available',v_company.balance);
        END IF;

        -- temp table for deltas
        CREATE TEMP TABLE tmp_salary_updates (
            account_id BIGINT,
            delta NUMERIC(20,2)
        ) ON COMMIT DROP;

        -- loop payments with savepoint
        FOR v_payment IN SELECT * FROM jsonb_array_elements(v_payments)
        LOOP
            SAVEPOINT sp_individual;
            v_iin := v_payment->> 'iin';
            v_amount := (v_payment->> 'amount')::numeric;
            v_description := COALESCE(v_payment->> 'description','salary');

            -- find employee customer by iin
            SELECT * INTO v_emp_customer FROM customers WHERE iin = v_iin;
            IF NOT FOUND THEN
                v_failed_count := v_failed_count + 1;
                v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', 'customer_not_found', 'amount', v_amount);
                ROLLBACK TO SAVEPOINT sp_individual;
                CONTINUE;
            END IF;

            -- find employee account
            SELECT * INTO v_emp_account FROM accounts WHERE customer_id = v_emp_customer.customer_id AND is_active = TRUE AND currency = 'KZT' LIMIT 1;
            IF NOT FOUND THEN
                SELECT * INTO v_emp_account FROM accounts WHERE customer_id = v_emp_customer.customer_id AND is_active = TRUE LIMIT 1;
            END IF;

            IF NOT FOUND THEN
                v_failed_count := v_failed_count + 1;
                v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', 'no_active_account', 'amount', v_amount);
                ROLLBACK TO SAVEPOINT sp_individual;
                CONTINUE;
            END IF;

           -- salary: no daily limit
            DECLARE v_delta NUMERIC;
            IF v_emp_account.currency = 'KZT' THEN
                v_delta := v_amount;
            ELSE
                SELECT rate INTO v_rate_to_kzt FROM exchange_rates WHERE from_currency = 'KZT' AND to_currency = v_emp_account.currency AND valid_from <= now() ORDER BY valid_from DESC LIMIT 1;
                IF v_rate_to_kzt IS NULL THEN
                    -- fail this payment but continue
                    v_failed_count := v_failed_count + 1;
                    v_failed_details := v_failed_details || jsonb_build_object('iin', v_iin, 'reason', 'missing_rate_kzt_to_emp_currency', 'amount', v_amount);
                    ROLLBACK TO SAVEPOINT sp_individual;
                    CONTINUE;
                END IF;
                v_delta := (v_amount * v_rate_to_kzt)::numeric(20,2);
            END IF;

            -- Append to temp table (we will update balances atomically later)
            INSERT INTO tmp_salary_updates(account_id, delta) VALUES (v_emp_account.account_id, v_delta);

            -- Insert a pending transaction row for audit (status will be set completed at commit after balances updated)
            INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, created_at, description)
            VALUES (v_company.account_id, v_emp_account.account_id, v_amount, 'KZT', 1, v_amount, 'salary', 'pending', now(), v_description)
            RETURNING transaction_id INTO v_tx_id;

            -- store mapping for later update (we can store transaction ids and account ids into temp)
            INSERT INTO tmp_salary_updates(account_id, delta) VALUES (v_emp_account.account_id, 0) ON CONFLICT DO NOTHING; -- no-op to ensure account exists in temp list

            -- mark success for this record in result
            v_success_count := v_success_count + 1;
            v_results := v_results || jsonb_build_object('iin', v_iin, 'account', v_emp_account.account_number, 'amount', v_amount, 'status', 'queued');

            RELEASE SAVEPOINT sp_individual;
        END LOOP;

      -- apply balance updates
        CREATE TEMP TABLE tmp_agg AS
        SELECT account_id, SUM(delta) AS total_delta FROM tmp_salary_updates GROUP BY account_id;

        -- Debit company account by total , Credit each employee account by total_delta
        UPDATE accounts SET balance = balance - v_total WHERE account_id = v_company.account_id;

        -- Apply credits
        FOR v_emp_account IN SELECT account_id, total_delta FROM tmp_agg
        LOOP
            UPDATE accounts SET balance = balance + v_emp_account.total_delta WHERE account_id = v_emp_account.account_id;
        END LOOP;

        -- Update all pending salary transactions created in this run to completed
        UPDATE transactions SET status = 'completed', completed_at = now()
         WHERE type = 'salary' AND from_account_id = v_company.account_id AND status = 'pending' AND created_at >= now() - interval '5 minutes';

        -- Insert audit log for batch
        INSERT INTO audit_log(table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('transactions', v_company.account_number, 'INSERT', NULL,
                jsonb_build_object('batch_total', v_total, 'success_count', v_success_count, 'failed_count', v_failed_count), 'process_salary_batch');

        -- Materialized view refresh will be done by caller
        PERFORM pg_advisory_unlock(v_lock_key);

        RETURN jsonb_build_object('status','completed','code','SB_000','message','Batch processed','success_count',v_success_count,'failed_count',v_failed_count,'failed_details', v_failed_details);

    EXCEPTION WHEN others THEN
        PERFORM pg_advisory_unlock(v_lock_key);
        RETURN jsonb_build_object('status','failed','code','SB_999','message','Unexpected error during batch processing','error', SQLERRM);
    END;
END;
$$;

-- Materialized view for salary batch summary
CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT date_trunc('day', created_at)::date AS day,
       COUNT(*) FILTER (WHERE type = 'salary') AS salary_count,
       SUM(amount_kzt) FILTER (WHERE type = 'salary') AS salary_total_kzt
FROM transactions
GROUP BY date_trunc('day', created_at)
ORDER BY day DESC;

---------------------------------------------------------------------------------------
-- 7. EXPLAIN ANALYZE
-- EXPLAIN ANALYZE SELECT * FROM accounts WHERE account_number = 'KZ00AIZHAN0000000001';
-- EXPLAIN ANALYZE SELECT * FROM transactions WHERE from_account_id = 1 ORDER BY created_at DESC LIMIT 10;
-- EXPLAIN ANALYZE SELECT * FROM audit_log WHERE old_values @> '{"balance":5000000}'::jsonb;
---------------------------------------------------------------------------------------
-- 8. Test cases
-- 8.1 Successful transfer
-- Expected: success, transaction created, balances updated
SELECT process_transfer('KZ00AIZHAN0000000001','KZ00BAURZHA000000001', 100000, 'KZT', 'Test same-currency transfer') AS result;

-- 8.2 Successful transfer (USD -> KZT)
SELECT process_transfer('KZ00AIZHAN0000000002','KZ00LAILA0000000007', 50, 'USD', 'USD to USD acct') AS result;

-- 8.3 Fail: source account not found
SELECT process_transfer('NONEXIST','KZ00BAURZHA000000001', 1000, 'KZT','Should fail') AS result;

-- 8.4 Fail: insufficient funds
-- Use a high amount to trigger insufficient funds
SELECT process_transfer('KZ00DINA00000000003','KZ00NAZIRA0000000009', 5000000, 'KZT', 'Should fail insufficient') AS result;

-- 8.5 Fail: daily limit exceeded (simulate by trying large multiple transfers)
-- Attempt a transfer that exceeds customer daily_limit_kzt for customer 3 if they are set low (seeded 500,000)
SELECT process_transfer('KZ00DINA00000000003','KZ00BAURZHA000000001', 450000, 'KZT', 'Large triggering daily limit') AS result;

-- 8.6 Salary batch: build JSON array and run
-- Prepare payments for iin 870101123456 (customer 1), 880202123457 (2), and a non-existent iin to test partial failure
DO $$
DECLARE
    batch JSONB := '[
      {"iin":"870101123456","amount":200000,"description":"Monthly salary Jan"},
      {"iin":"880202123457","amount":150000,"description":"Monthly salary Jan"},
      {"iin":"000000000000","amount":100000,"description":"Unknown employee"}
    ]';
    res JSONB;
BEGIN
    res := process_salary_batch('KZ00QAIRAT0000000012', batch); -- company account is Qairat (account 12, USD) which may fail if balance insufficient
    RAISE INFO 'Salary batch result: %', res;
END;
$$;

-- 8.7 Refresh materialized view
REFRESH MATERIALIZED VIEW salary_batch_summary;
SELECT * FROM salary_batch_summary LIMIT 10;

--------------------------------------------------------------------------------------
-- 9. Concurrency demonstration notes (to execute manually)
-- Open two psql sessions:
-- Session A:
-- BEGIN;
-- SELECT * FROM accounts WHERE account_number='KZ00AIZHAN0000000001' FOR UPDATE;
-- -- hold the transaction and sleep
-- (wait here)
--

-- Session B:
-- Attempt a transfer that debits the same account:
-- SELECT process_transfer('KZ00AIZHAN0000000001','KZ00BAURZHA000000001', 50000, 'KZT','Concurrent test');
-- -- This will block until session A releases the FOR UPDATE lock if needed.
--
-- This demonstrates SELECT ... FOR UPDATE preventing race conditions.


-------------------------------------------------------------------------------
-- 7. Test calls (success / fail)
-- success transfer
SELECT process_transfer(
  'KZ00AIZHAN0000000001',
  'KZ00BAURZHA000000001',
  50000,
  'KZT',
  'test ok transfer'
);

-- failed transfer (no money)
SELECT process_transfer(
  'KZ00DINA00000000003',
  'KZ00BAURZHA000000001',
  9999999,
  'KZT',
  'test fail no money'
);

-- salary batch: one payment
SELECT process_salary_batch(
  'KZ00AIZHAN0000000001',
  '[{"iin":"880202123457","amount":50000,"description":"salary test"}]'::jsonb
);

------------------------------------------------------------------------
-- 8. EXPLAIN ANALYZE examples
EXPLAIN ANALYZE
SELECT *
FROM transactions t
JOIN accounts a ON a.account_id = t.from_account_id
WHERE a.customer_id = 1;

EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE lower(email) = lower('aizhan@example.com');