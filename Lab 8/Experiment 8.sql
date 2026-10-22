-- ============================================================
-- EXPERIMENT 8
-- Transactions, SAVEPOINT, ROLLBACK, Isolation Levels
-- and Concurrency Anomalies
--
-- Database: ByteXL sandbox_db
-- NOTE:
--   The two-session concurrency demonstrations are included at
--   the end of this file as separate SESSION 1 / SESSION 2 blocks.
--   Run those blocks simultaneously in two SQL tabs/sessions.
-- ============================================================

-- ------------------------------------------------------------
-- 0. Select the ByteXL database
-- ------------------------------------------------------------
SELECT DATABASE();

-- Expected: sandbox_db


-- ------------------------------------------------------------
-- 1. CLEAN SETUP
-- ------------------------------------------------------------
DROP TABLE IF EXISTS bank_transactions;
DROP TABLE IF EXISTS accounts;

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(100) NOT NULL,
    balance DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_account_balance CHECK (balance >= 0)
) ENGINE = InnoDB;

CREATE TABLE bank_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT NOT NULL,
    to_account INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    transaction_status VARCHAR(20) NOT NULL,

    CONSTRAINT chk_transaction_amount CHECK (amount > 0),

    CONSTRAINT fk_transaction_from
        FOREIGN KEY (from_account)
        REFERENCES accounts(account_id),

    CONSTRAINT fk_transaction_to
        FOREIGN KEY (to_account)
        REFERENCES accounts(account_id)
) ENGINE = InnoDB;


-- ------------------------------------------------------------
-- 2. INSERT SAMPLE BANK ACCOUNTS
-- ------------------------------------------------------------
INSERT INTO accounts (account_id, account_holder, balance)
VALUES
(101, 'Rahul', 10000.00),
(102, 'Anjali', 8000.00),
(103, 'Kiran', 5000.00);

SELECT * FROM accounts ORDER BY account_id;


-- ============================================================
-- 3. BEGIN + COMMIT
-- Transfer ₹1000 from Rahul (101) to Anjali (102)
-- ============================================================

START TRANSACTION;

UPDATE accounts
SET balance = balance - 1000.00
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 1000.00
WHERE account_id = 102;

INSERT INTO bank_transactions
    (from_account, to_account, amount, transaction_status)
VALUES
    (101, 102, 1000.00, 'SUCCESS');

COMMIT;

SELECT * FROM accounts
WHERE account_id IN (101, 102)
ORDER BY account_id;

SELECT * FROM bank_transactions
ORDER BY transaction_id;


-- ============================================================
-- 4. ROLLBACK
-- Simulate a failed transfer of ₹2000 from Rahul to Kiran.
-- The changes are NOT committed.
-- ============================================================

START TRANSACTION;

UPDATE accounts
SET balance = balance - 2000.00
WHERE account_id = 101;

-- Simulated failure:
-- Money has been deducted, but the credit operation fails.

ROLLBACK;

-- Rahul's balance should be unchanged by this failed transfer.
SELECT * FROM accounts
WHERE account_id = 101;


-- ============================================================
-- 5. SAVEPOINT + ROLLBACK TO SAVEPOINT
-- First transfer succeeds.
-- Second transfer is rolled back.
-- ============================================================

START TRANSACTION;

-- Transfer ₹500 from Rahul to Kiran
UPDATE accounts
SET balance = balance - 500.00
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 500.00
WHERE account_id = 103;

SAVEPOINT after_first_transfer;

-- Second transfer: ₹1000 from Rahul to Anjali
UPDATE accounts
SET balance = balance - 1000.00
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 1000.00
WHERE account_id = 102;

-- Simulate failure of the second operation.
-- Keep the first transfer but undo the second transfer.
ROLLBACK TO SAVEPOINT after_first_transfer;

-- Save the first transfer.
INSERT INTO bank_transactions
    (from_account, to_account, amount, transaction_status)
VALUES
    (101, 103, 500.00, 'SUCCESS');

COMMIT;

SELECT * FROM accounts ORDER BY account_id;
SELECT * FROM bank_transactions ORDER BY transaction_id;


-- ============================================================
-- 6. ATOMICITY DEMONSTRATION
-- A transaction contains two updates.
-- ROLLBACK undoes BOTH updates.
-- ============================================================

START TRANSACTION;

UPDATE accounts
SET balance = balance - 750.00
WHERE account_id = 102;

UPDATE accounts
SET balance = balance + 750.00
WHERE account_id = 103;

-- Simulate failure before COMMIT.
ROLLBACK;

SELECT * FROM accounts ORDER BY account_id;


-- ============================================================
-- 7. DURABILITY / COMMIT VERIFICATION
-- A committed transfer remains after the transaction ends.
-- ============================================================

START TRANSACTION;

UPDATE accounts
SET balance = balance - 250.00
WHERE account_id = 102;

UPDATE accounts
SET balance = balance + 250.00
WHERE account_id = 103;

INSERT INTO bank_transactions
    (from_account, to_account, amount, transaction_status)
VALUES
    (102, 103, 250.00, 'SUCCESS');

COMMIT;

SELECT * FROM accounts ORDER BY account_id;


-- ============================================================
-- 8. CHECK CURRENT ISOLATION LEVEL
-- ============================================================

SELECT @@session.transaction_isolation;
SELECT @@global.transaction_isolation;


-- ============================================================
-- 9. READ UNCOMMITTED
-- Dirty Read demonstration
--
-- IMPORTANT:
-- This section must be executed in TWO separate SQL sessions.
-- See the SESSION 1 / SESSION 2 blocks at the end.
-- ============================================================


-- ============================================================
-- 10. READ COMMITTED
-- Non-Repeatable Read demonstration
--
-- IMPORTANT:
-- Execute the SESSION 1 and SESSION 2 blocks simultaneously
-- in two separate SQL sessions.
-- ============================================================


-- ============================================================
-- 11. REPEATABLE READ
-- Demonstrates consistent repeated reads in MySQL InnoDB.
-- ============================================================


-- ============================================================
-- 12. SERIALIZABLE
-- Demonstrates the strongest standard isolation level.
-- ============================================================


-- ============================================================
-- 13. FINAL VERIFICATION
-- ============================================================

SELECT * FROM accounts ORDER BY account_id;

SELECT
    transaction_id,
    from_account,
    to_account,
    amount,
    transaction_status
FROM bank_transactions
ORDER BY transaction_id;

SELECT SUM(balance) AS total_bank_balance
FROM accounts;


-- ============================================================
-- TWO-SESSION CONCURRENCY TESTS
-- ============================================================
--
-- IMPORTANT:
-- The following blocks are intentionally separated.
-- Open TWO ByteXL SQL sessions/tabs connected to sandbox_db.
--
-- SESSION 1 = run the SESSION 1 block.
-- SESSION 2 = run the SESSION 2 block.
--
-- Do NOT run both sessions as one sequential script.
-- ============================================================


-- ============================================================
-- TEST A: DIRTY READ
-- Isolation level: READ UNCOMMITTED
-- ============================================================

-- ---------------- SESSION 1 ----------------
-- Run these statements in SQL TAB / SESSION 1:
--
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
--
-- UPDATE accounts
-- SET balance = balance - 2000.00
-- WHERE account_id = 101;
--
-- SELECT account_id, account_holder, balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- DO NOT COMMIT OR ROLLBACK YET.
-- Leave this transaction open.
--
-- -------------------------------------------


-- ---------------- SESSION 2 ----------------
-- Run these statements in SQL TAB / SESSION 2:
--
-- SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- START TRANSACTION;
--
-- SELECT account_id, account_holder, balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- Under READ UNCOMMITTED, Session 2 can see Session 1's
-- uncommitted balance.
--
-- This demonstrates:
--                 DIRTY READ
--
-- After observing the result:
-- COMMIT;
--
-- -------------------------------------------


-- ---------------- SESSION 1 CLEANUP ----------------
-- After Session 2 has performed its SELECT:
--
-- ROLLBACK;
--
-- This restores Rahul's balance.
-- ============================================================


-- ============================================================
-- TEST B: NON-REPEATABLE READ
-- Isolation level: READ COMMITTED
-- ============================================================

-- ---------------- SESSION 1 ----------------
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
--
-- SELECT balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- Remember the value.
-- Keep this transaction open.
--
-- -------------------------------------------


-- ---------------- SESSION 2 ----------------
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
--
-- UPDATE accounts
-- SET balance = balance + 1000.00
-- WHERE account_id = 101;
--
-- COMMIT;
--
-- -------------------------------------------


-- ---------------- SESSION 1 ----------------
-- Run the SAME SELECT again:
--
-- SELECT balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- The value can now be different from the first SELECT.
--
-- This demonstrates:
--              NON-REPEATABLE READ
--
-- Finish:
-- COMMIT;
-- ============================================================


-- ============================================================
-- TEST C: PHANTOM READ
-- Isolation level: READ COMMITTED
-- ============================================================

-- ---------------- SESSION 1 ----------------
-- SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- START TRANSACTION;
--
-- SELECT COUNT(*) AS account_count
-- FROM accounts
-- WHERE balance >= 5000;
--
-- Remember the count.
-- Keep this transaction open.
--
-- -------------------------------------------


-- ---------------- SESSION 2 ----------------
-- START TRANSACTION;
--
-- INSERT INTO accounts
--     (account_id, account_holder, balance)
-- VALUES
--     (104, 'Priya', 7000.00);
--
-- COMMIT;
--
-- -------------------------------------------


-- ---------------- SESSION 1 ----------------
-- Run the SAME query again:
--
-- SELECT COUNT(*) AS account_count
-- FROM accounts
-- WHERE balance >= 5000;
--
-- The result can now contain the newly inserted row.
--
-- This demonstrates:
--                  PHANTOM READ
--
-- Finish:
-- COMMIT;
--
-- -------------------------------------------


-- ============================================================
-- TEST D: REPEATABLE READ
-- MySQL InnoDB default isolation level
-- ============================================================

-- SESSION 1:
--
-- SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- START TRANSACTION;
--
-- SELECT balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- SESSION 2:
--
-- START TRANSACTION;
--
-- UPDATE accounts
-- SET balance = balance + 500.00
-- WHERE account_id = 101;
--
-- COMMIT;
--
-- SESSION 1:
--
-- SELECT balance
-- FROM accounts
-- WHERE account_id = 101;
--
-- In a consistent read under REPEATABLE READ, Session 1
-- continues to see its transaction snapshot.
--
-- Finish:
-- COMMIT;


-- ============================================================
-- TEST E: SERIALIZABLE
-- ============================================================

-- SESSION 1:
--
-- SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- START TRANSACTION;
--
-- SELECT *
-- FROM accounts
-- WHERE balance >= 5000;
--
-- Keep the transaction open.
--
-- SESSION 2:
--
-- SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- START TRANSACTION;
--
-- Try to insert:
--
-- INSERT INTO accounts
--     (account_id, account_holder, balance)
-- VALUES
--     (105, 'Suresh', 6000.00);
--
-- The operation may wait for Session 1 or encounter a
-- locking/deadlock-related result depending on timing.
--
-- This demonstrates the stronger concurrency control of
-- SERIALIZABLE isolation.
--
-- Cleanup:
-- SESSION 1:
-- COMMIT;
--
-- SESSION 2:
-- ROLLBACK;   -- if the insert did not complete
-- ============================================================


-- ============================================================
-- ISOLATION LEVEL SUMMARY
-- ============================================================
--
-- READ UNCOMMITTED
--     Dirty Read          -> Possible
--     Non-Repeatable Read -> Possible
--     Phantom Read        -> Possible
--
-- READ COMMITTED
--     Dirty Read          -> Prevented
--     Non-Repeatable Read -> Possible
--     Phantom Read        -> Possible
--
-- REPEATABLE READ
--     Dirty Read          -> Prevented
--     Non-Repeatable Read -> Prevented for consistent reads
--     Phantom Read        -> Generally prevented for consistent
--                            reads in MySQL InnoDB
--
-- SERIALIZABLE
--     Dirty Read          -> Prevented
--     Non-Repeatable Read -> Prevented
--     Phantom Read        -> Prevented through stronger locking
--
-- ============================================================
-- END OF EXPERIMENT 8
-- ============================================================
