# Experiment 8: Transactions, Savepoints, Isolation Levels and Concurrency

## 🎯 Objective

Implement banking-style transactions using SQL transaction control commands such as `BEGIN`, `COMMIT`, `ROLLBACK`, and `SAVEPOINT`.

The experiment also demonstrates partial transaction failures, transaction recovery, isolation levels, and concurrency anomalies using two independent database sessions.

---

## 🧠 Concepts Covered

- Database Transactions
- ACID Properties
- `BEGIN` / `START TRANSACTION`
- `COMMIT`
- `ROLLBACK`
- `SAVEPOINT`
- `ROLLBACK TO SAVEPOINT`
- Transaction Failure and Recovery
- Transaction Isolation Levels
- Concurrent Transactions
- Dirty Read
- Non-Repeatable Read
- Phantom Read
- MySQL InnoDB

---

## 🏦 Problem Statement

Consider a banking system where customers transfer money between accounts.

A money transfer consists of multiple database operations:

1. Deduct money from the sender's account.
2. Add money to the receiver's account.
3. Record the transaction.

All these operations should be treated as a **single logical transaction**.

If any operation fails, the transaction should be rolled back so that the database does not enter an inconsistent state.

The experiment also investigates how multiple transactions running simultaneously can affect each other under different isolation levels.

---

# 1. Database Used

This experiment is designed for the ByteXL-provided database:

```text
sandbox_db
```

Verify the selected database:

```sql
SELECT DATABASE();
```

Expected:

```text
sandbox_db
```

No separate database needs to be created.

---

# 2. Database Tables

Two tables are used.

### Accounts

```text
accounts(
    account_id,
    account_holder,
    balance
)
```

### Bank Transactions

```text
bank_transactions(
    transaction_id,
    from_account,
    to_account,
    amount,
    transaction_status
)
```

The `accounts` table stores the current account balance.

The `bank_transactions` table stores the history of money transfers.

---

# 3. Creating the Accounts Table

```sql
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    account_holder VARCHAR(100) NOT NULL,
    balance DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_account_balance CHECK (balance >= 0)
) ENGINE = InnoDB;
```

---

# 4. Creating the Transactions Table

```sql
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
```

---

# 5. Sample Data

The following accounts are inserted:

| Account ID | Account Holder | Balance |
|---:|---|---:|
| 101 | Rahul | ₹10,000 |
| 102 | Anjali | ₹8,000 |
| 103 | Kiran | ₹5,000 |

SQL:

```sql
INSERT INTO accounts
(account_id, account_holder, balance)
VALUES
(101, 'Rahul', 10000.00),
(102, 'Anjali', 8000.00),
(103, 'Kiran', 5000.00);
```

Verify:

```sql
SELECT * FROM accounts;
```

---

# 6. BEGIN and COMMIT

A transaction can contain multiple SQL operations.

Consider Rahul transferring ₹1,000 to Anjali.

Start the transaction:

```sql
START TRANSACTION;
```

Deduct ₹1,000 from Rahul:

```sql
UPDATE accounts
SET balance = balance - 1000.00
WHERE account_id = 101;
```

Credit ₹1,000 to Anjali:

```sql
UPDATE accounts
SET balance = balance + 1000.00
WHERE account_id = 102;
```

Record the transfer:

```sql
INSERT INTO bank_transactions
(from_account, to_account, amount, transaction_status)
VALUES
(101, 102, 1000.00, 'SUCCESS');
```

Commit:

```sql
COMMIT;
```

After `COMMIT`, all changes become permanent.

---

# 7. ROLLBACK

`ROLLBACK` cancels all changes made during the current uncommitted transaction.

For example, Rahul attempts to transfer ₹2,000 to Kiran:

```sql
START TRANSACTION;

UPDATE accounts
SET balance = balance - 2000.00
WHERE account_id = 101;

ROLLBACK;
```

The deduction is cancelled.

Therefore, Rahul's balance returns to its previous value.

Verify:

```sql
SELECT *
FROM accounts
WHERE account_id = 101;
```

This demonstrates transaction recovery after failure.

---

# 8. SAVEPOINT

A `SAVEPOINT` creates a point inside a transaction to which we can partially roll back.

Example:

```sql
START TRANSACTION;
```

First transfer ₹500 from Rahul to Kiran:

```sql
UPDATE accounts
SET balance = balance - 500.00
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 500.00
WHERE account_id = 103;
```

Create a savepoint:

```sql
SAVEPOINT after_first_transfer;
```

Now perform another transfer:

```sql
UPDATE accounts
SET balance = balance - 1000.00
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 1000.00
WHERE account_id = 102;
```

Suppose the second transfer fails.

Instead of cancelling the entire transaction:

```sql
ROLLBACK TO SAVEPOINT after_first_transfer;
```

The second transfer is undone while the first transfer remains.

Finally:

```sql
COMMIT;
```

This demonstrates **partial rollback**.

---

# 9. Partial Failure Simulation

A banking transaction must be atomic.

Consider:

```text
Rahul
  │
  │ ₹1,000
  ▼
Anjali
```

The transfer requires:

```text
1. Deduct ₹1,000 from Rahul
2. Credit ₹1,000 to Anjali
```

If step 1 succeeds but step 2 fails, the database would become inconsistent if there were no transaction mechanism.

Using:

```sql
START TRANSACTION;
```

and:

```sql
ROLLBACK;
```

ensures that the incomplete transaction is cancelled.

Example:

```sql
START TRANSACTION;

UPDATE accounts
SET balance = balance - 1000.00
WHERE account_id = 101;

-- Simulated failure

ROLLBACK;
```

The deduction is removed.

---

# 10. ACID Properties

Transactions provide the four important ACID properties.

## Atomicity

All operations in a transaction succeed or none of them are permanently applied.

```sql
START TRANSACTION;

UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 101;

UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 102;

ROLLBACK;
```

Both changes are cancelled.

---

## Consistency

A transaction should take the database from one valid state to another valid state.

For example, when ₹1,000 is transferred:

```text
Before:
Rahul + Anjali = ₹17,000

After:
Rahul + Anjali = ₹17,000
```

The total money remains unchanged.

---

## Isolation

Concurrent transactions should not incorrectly interfere with one another.

The experiment demonstrates different isolation levels to observe their effects.

---

## Durability

Once a transaction is committed:

```sql
COMMIT;
```

the changes become permanent.

---

# 11. Transaction Isolation Levels

MySQL supports four standard transaction isolation levels:

```text
READ UNCOMMITTED
READ COMMITTED
REPEATABLE READ
SERIALIZABLE
```

Check the current isolation level:

```sql
SELECT @@session.transaction_isolation;
```

Check the global isolation level:

```sql
SELECT @@global.transaction_isolation;
```

---

# 12. READ UNCOMMITTED — Dirty Read

`READ UNCOMMITTED` allows a transaction to potentially read changes made by another transaction before those changes are committed.

This can result in a **Dirty Read**.

Two separate SQL sessions are required.

### Session 1

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

UPDATE accounts
SET balance = balance - 2000.00
WHERE account_id = 101;
```

Do not commit or rollback yet.

### Session 2

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE account_id = 101;
```

Session 2 may see the uncommitted balance from Session 1.

This demonstrates:

```text
DIRTY READ
```

After the observation:

### Session 1

```sql
ROLLBACK;
```

### Session 2

```sql
COMMIT;
```

---

# 13. READ COMMITTED — Non-Repeatable Read

Under `READ COMMITTED`, a transaction only reads committed data.

However, the same query may return different results during one transaction if another transaction modifies and commits the data.

### Session 1

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE account_id = 101;
```

Remember the returned balance.

### Session 2

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

UPDATE accounts
SET balance = balance + 1000.00
WHERE account_id = 101;

COMMIT;
```

### Session 1

Run the same query again:

```sql
SELECT balance
FROM accounts
WHERE account_id = 101;
```

The result can now be different.

This demonstrates:

```text
NON-REPEATABLE READ
```

Finish Session 1:

```sql
COMMIT;
```

---

# 14. READ COMMITTED — Phantom Read

A phantom read occurs when a repeated query returns a different set of rows because another transaction inserted or deleted rows matching the query condition.

### Session 1

```sql
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT COUNT(*) AS account_count
FROM accounts
WHERE balance >= 5000;
```

Remember the count.

### Session 2

```sql
START TRANSACTION;

INSERT INTO accounts
(account_id, account_holder, balance)
VALUES
(104, 'Priya', 7000.00);

COMMIT;
```

### Session 1

Run the same query again:

```sql
SELECT COUNT(*) AS account_count
FROM accounts
WHERE balance >= 5000;
```

The count may increase because the new row now satisfies the condition.

This demonstrates:

```text
PHANTOM READ
```

---

# 15. REPEATABLE READ

`REPEATABLE READ` provides a consistent transaction snapshot for normal consistent reads in MySQL InnoDB.

Set the isolation level:

```sql
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

Start a transaction:

```sql
START TRANSACTION;
```

Read Rahul's balance:

```sql
SELECT balance
FROM accounts
WHERE account_id = 101;
```

If another session changes and commits Rahul's balance, repeating the same consistent read within Session 1 continues to use its transaction snapshot.

Finish:

```sql
COMMIT;
```

---

# 16. SERIALIZABLE

`SERIALIZABLE` is the strongest standard isolation level.

Set it using:

```sql
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

Start:

```sql
START TRANSACTION;
```

Run:

```sql
SELECT *
FROM accounts
WHERE balance >= 5000;
```

Concurrent transactions attempting conflicting operations may have to wait or may encounter locking errors depending on the timing.

Finish:

```sql
COMMIT;
```

This provides the strongest isolation among the four standard levels.

---

# 17. Isolation Level Comparison

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|---|---|---|---|
| READ UNCOMMITTED | Possible | Possible | Possible |
| READ COMMITTED | Prevented | Possible | Possible |
| REPEATABLE READ | Prevented | Prevented | Generally prevented for consistent reads in MySQL InnoDB |
| SERIALIZABLE | Prevented | Prevented | Prevented |

---

# 18. Two-Session Concurrency

The concurrency demonstrations require **two independent SQL sessions**.

```text
+----------------------+       +----------------------+
|      SESSION 1       |       |      SESSION 2       |
+----------------------+       +----------------------+
| BEGIN                |       | BEGIN                |
| UPDATE               |       | SELECT               |
|                      |       |                      |
|       Concurrent Transactions                       |
|                      |       |                      |
| COMMIT / ROLLBACK    |       | COMMIT / ROLLBACK    |
+----------------------+       +----------------------+
```

The two sessions allow us to observe how one transaction behaves while another transaction is executing.

---

# 19. Important SQL Commands

| Command | Purpose |
|---|---|
| `START TRANSACTION` | Starts a transaction |
| `BEGIN` | Starts a transaction |
| `COMMIT` | Permanently saves changes |
| `ROLLBACK` | Cancels uncommitted changes |
| `SAVEPOINT` | Creates a rollback point |
| `ROLLBACK TO SAVEPOINT` | Partially rolls back a transaction |
| `SET TRANSACTION ISOLATION LEVEL` | Changes transaction isolation |

---

# 20. Verification Queries

View all accounts:

```sql
SELECT *
FROM accounts
ORDER BY account_id;
```

View transaction history:

```sql
SELECT *
FROM bank_transactions
ORDER BY transaction_id;
```

Calculate total money:

```sql
SELECT SUM(balance) AS total_bank_balance
FROM accounts;
```

View transaction details:

```sql
SELECT
    transaction_id,
    from_account,
    to_account,
    amount,
    transaction_status
FROM bank_transactions
ORDER BY transaction_id;
```

---

# 21. Expected Results

The experiment demonstrates:

```text
BEGIN / START TRANSACTION
        ↓
     Transaction
        ↓
   ┌────┴────┐
   ↓         ↓
COMMIT    ROLLBACK
   ↓         ↓
Save       Undo
Changes    Changes
```

Savepoint behavior:

```text
START TRANSACTION
       ↓
Operation 1
       ↓
SAVEPOINT
       ↓
Operation 2
       ↓
Failure
       ↓
ROLLBACK TO SAVEPOINT
       ↓
Operation 1 remains
Operation 2 is undone
       ↓
COMMIT
```

Concurrency anomalies demonstrated:

```text
READ UNCOMMITTED
       ↓
   Dirty Read

READ COMMITTED
       ↓
Non-Repeatable Read
       +
   Phantom Read

REPEATABLE READ
       ↓
Consistent transaction snapshot

SERIALIZABLE
       ↓
Strongest isolation
```

---

# 22. Conclusion

Banking-style transactions were successfully implemented using `BEGIN`, `COMMIT`, `ROLLBACK`, and `SAVEPOINT`.

`COMMIT` was used to permanently save successful transactions, while `ROLLBACK` was used to recover from failed transactions. `SAVEPOINT` was used to demonstrate partial rollback within a larger transaction.

Different isolation levels were investigated using two concurrent sessions. The experiment demonstrated important concurrency anomalies including dirty reads, non-repeatable reads, and phantom reads.

Thus, the experiment demonstrates how transaction management, recovery mechanisms, and isolation levels help maintain database consistency and reliability in a concurrent banking environment.