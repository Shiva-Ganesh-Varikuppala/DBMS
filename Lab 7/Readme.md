# Lab 7: Database Normalization (UNF to BCNF)

## 🎯 Objective

Normalize a denormalized **Sales** table step-by-step from **Unnormalized Form (UNF)** to **First Normal Form (1NF)**, **Second Normal Form (2NF)**, **Third Normal Form (3NF)**, and **Boyce-Codd Normal Form (BCNF)**.

The experiment also identifies the **functional dependencies** and verifies:

- Lossless Join Decomposition
- Dependency Preservation
- Correctness of the normalized relations

---

## 🧠 Concepts Covered

- Functional Dependencies
- Candidate Keys
- Super Keys
- Unnormalized Form (UNF)
- First Normal Form (1NF)
- Second Normal Form (2NF)
- Third Normal Form (3NF)
- Boyce-Codd Normal Form (BCNF)
- Partial Dependency
- Transitive Dependency
- Lossless Join Decomposition
- Dependency Preservation

---

## 🏗️ Problem Statement

Given a denormalized Sales relation containing information about orders, customers, products, categories, and salespersons, identify the functional dependencies and normalize the relation systematically from UNF to BCNF.

The final normalized relations should minimize redundancy and prevent insertion, deletion, and update anomalies.

---

## 🗃️ Initial Sales Relation

The initial relation is:

```text
Sales(
    OrderID,
    ProductID,
    OrderDate,
    CustomerID,
    CustomerName,
    CustomerCity,
    ProductName,
    CategoryID,
    CategoryName,
    Quantity,
    UnitPrice,
    SalespersonID,
    SalespersonName
)
```

### Candidate Key

The candidate key is:

```text
(OrderID, ProductID)
```

An order can contain multiple products, so `OrderID` alone cannot uniquely identify a sales record.

---

## 🔗 Functional Dependencies

The following functional dependencies are identified:

```text
(OrderID, ProductID)
    → OrderDate, CustomerID, Quantity, UnitPrice, SalespersonID

CustomerID
    → CustomerName, CustomerCity

ProductID
    → ProductName, CategoryID

CategoryID
    → CategoryName

SalespersonID
    → SalespersonName
```

### Dependency Explanation

The composite key:

```text
(OrderID, ProductID)
```

determines the details of a particular product within an order.

Customer information depends only on:

```text
CustomerID
```

Product information depends only on:

```text
ProductID
```

Category information depends on:

```text
CategoryID
```

Salesperson information depends on:

```text
SalespersonID
```

---

# 1. Unnormalized Form (UNF)

In UNF, a relation may contain repeating groups or multiple values in a single attribute.

For example:

```text
OrderID | CustomerName | Products
-------------------------------------------
1001    | Rahul        | Laptop, Mouse
1002    | Anjali       | Keyboard, Chair
```

The `Products` attribute contains multiple values and is therefore not atomic.

Hence, the relation is in **UNF**.

---

# 2. First Normal Form (1NF)

A relation is in 1NF when:

1. Every attribute contains atomic values.
2. There are no repeating groups.
3. Each record can be uniquely identified.

The repeating product information is separated into individual rows.

Example:

```text
OrderID | ProductID | ProductName | Quantity
---------------------------------------------
1001    | 101       | Laptop      | 2
1001    | 102       | Mouse       | 3
1002    | 103       | Keyboard    | 2
1002    | 104       | Chair       | 1
```

The relation now has atomic values.

Therefore:

```text
UNF → 1NF
```

---

# 3. Second Normal Form (2NF)

A relation must:

- Be in 1NF.
- Have no partial dependency of a non-prime attribute on a part of a composite candidate key.

The candidate key is:

```text
(OrderID, ProductID)
```

However:

```text
OrderID → OrderDate, CustomerID, SalespersonID
```

and:

```text
ProductID → ProductName, CategoryID
```

These are partial dependencies because the attributes depend on only one part of the composite key.

Therefore, the relation is not in 2NF.

### Decomposition

The relation is decomposed into:

```text
Orders(
    OrderID,
    OrderDate,
    CustomerID,
    SalespersonID
)

Products(
    ProductID,
    ProductName,
    CategoryID
)

Sales_Items(
    OrderID,
    ProductID,
    Quantity,
    UnitPrice
)
```

Now the partial dependencies are removed.

Therefore:

```text
1NF → 2NF
```

---

# 4. Third Normal Form (3NF)

A relation must:

- Be in 2NF.
- Have no transitive dependencies.

The following dependencies create transitive dependencies:

```text
CustomerID → CustomerName, CustomerCity

CategoryID → CategoryName

SalespersonID → SalespersonName
```

For example:

```text
OrderID
   ↓
CustomerID
   ↓
CustomerName
CustomerCity
```

Therefore, customer details should be stored separately.

Similarly:

```text
ProductID
   ↓
CategoryID
   ↓
CategoryName
```

Therefore, category details should be separated.

### Final 3NF Decomposition

```text
Customers(
    CustomerID,
    CustomerName,
    CustomerCity
)

Salespersons(
    SalespersonID,
    SalespersonName
)

Categories(
    CategoryID,
    CategoryName
)

Products(
    ProductID,
    ProductName,
    CategoryID
)

Orders(
    OrderID,
    OrderDate,
    CustomerID,
    SalespersonID
)

Sales_Items(
    OrderID,
    ProductID,
    Quantity,
    UnitPrice
)
```

All transitive dependencies have been removed.

Therefore:

```text
2NF → 3NF
```

---

# 5. Boyce-Codd Normal Form (BCNF)

A relation is in BCNF if:

> For every non-trivial functional dependency X → Y, X must be a superkey.

The final relations satisfy this condition.

### Customers

```text
CustomerID → CustomerName, CustomerCity
```

`CustomerID` is the primary key.

Therefore, the relation is in BCNF.

### Salespersons

```text
SalespersonID → SalespersonName
```

`SalespersonID` is the primary key.

Therefore, the relation is in BCNF.

### Categories

```text
CategoryID → CategoryName
```

`CategoryID` is the primary key.

Therefore, the relation is in BCNF.

### Products

```text
ProductID → ProductName, CategoryID
```

`ProductID` is the primary key.

Therefore, the relation is in BCNF.

### Orders

```text
OrderID → OrderDate, CustomerID, SalespersonID
```

`OrderID` is the primary key.

Therefore, the relation is in BCNF.

### Sales_Items

```text
(OrderID, ProductID) → Quantity, UnitPrice
```

`(OrderID, ProductID)` is the primary key.

Therefore, the relation is in BCNF.

---

# 6. Final Normalized Schema

```text
CUSTOMERS
---------
CustomerID PK
CustomerName
CustomerCity


SALESPERSONS
------------
SalespersonID PK
SalespersonName


CATEGORIES
----------
CategoryID PK
CategoryName


PRODUCTS
--------
ProductID PK
ProductName
CategoryID FK


ORDERS
------
OrderID PK
OrderDate
CustomerID FK
SalespersonID FK


SALES_ITEMS
-----------
OrderID PK/FK
ProductID PK/FK
Quantity
UnitPrice
```

---

# 7. Lossless Join Verification

The decomposed relations should be joinable to reconstruct the original Sales relation without losing information or generating spurious tuples.

The relations can be joined using:

```text
Orders
   ↓
CustomerID
   ↓
Customers

Orders
   ↓
SalespersonID
   ↓
Salespersons

Orders
   ↓
OrderID
   ↓
Sales_Items
   ↓
ProductID
   ↓
Products
   ↓
CategoryID
   ↓
Categories
```

SQL verification:

```sql
SELECT
    o.OrderID,
    si.ProductID,
    o.OrderDate,
    c.CustomerID,
    c.CustomerName,
    c.CustomerCity,
    p.ProductName,
    cat.CategoryID,
    cat.CategoryName,
    si.Quantity,
    si.UnitPrice,
    sp.SalespersonID,
    sp.SalespersonName
FROM Orders o
JOIN Customers c
    ON o.CustomerID = c.CustomerID
JOIN Salespersons sp
    ON o.SalespersonID = sp.SalespersonID
JOIN Sales_Items si
    ON o.OrderID = si.OrderID
JOIN Products p
    ON si.ProductID = p.ProductID
JOIN Categories cat
    ON p.CategoryID = cat.CategoryID;
```

The reconstructed result should contain the same logical information as the original Sales relation.

---

# 8. Dependency Preservation Verification

The important functional dependencies can be verified directly in their respective relations.

### Customer Dependency

```text
CustomerID → CustomerName, CustomerCity
```

```sql
SELECT CustomerID
FROM Customers
GROUP BY CustomerID
HAVING COUNT(DISTINCT CustomerName) > 1
    OR COUNT(DISTINCT CustomerCity) > 1;
```

Expected:

```text
Empty set
```

---

### Product Dependency

```text
ProductID → ProductName, CategoryID
```

```sql
SELECT ProductID
FROM Products
GROUP BY ProductID
HAVING COUNT(DISTINCT ProductName) > 1
    OR COUNT(DISTINCT CategoryID) > 1;
```

Expected:

```text
Empty set
```

---

### Category Dependency

```text
CategoryID → CategoryName
```

```sql
SELECT CategoryID
FROM Categories
GROUP BY CategoryID
HAVING COUNT(DISTINCT CategoryName) > 1;
```

Expected:

```text
Empty set
```

---

### Salesperson Dependency

```text
SalespersonID → SalespersonName
```

```sql
SELECT SalespersonID
FROM Salespersons
GROUP BY SalespersonID
HAVING COUNT(DISTINCT SalespersonName) > 1;
```

Expected:

```text
Empty set
```

---

### Order Dependency

```text
OrderID → OrderDate, CustomerID, SalespersonID
```

```sql
SELECT OrderID
FROM Orders
GROUP BY OrderID
HAVING COUNT(DISTINCT OrderDate) > 1
    OR COUNT(DISTINCT CustomerID) > 1
    OR COUNT(DISTINCT SalespersonID) > 1;
```

Expected:

```text
Empty set
```

---

# 9. Normalization Summary

```text
UNF
 ↓
Remove repeating groups
 ↓
1NF
 ↓
Remove partial dependencies
 ↓
2NF
 ↓
Remove transitive dependencies
 ↓
3NF
 ↓
Ensure every determinant is a superkey
 ↓
BCNF
```

### Final Result

| Normal Form | Condition Satisfied |
|---|---|
| UNF | Repeating/multiple-valued groups may exist |
| 1NF | All values are atomic |
| 2NF | No partial dependencies |
| 3NF | No transitive dependencies |
| BCNF | Every determinant is a superkey |

### Verification

```text
Functional Dependencies       → Identified
1NF                           → Achieved
2NF                           → Achieved
3NF                           → Achieved
BCNF                          → Achieved
Lossless Join                 → Verified
Dependency Preservation       → Verified
```

---

## 📝 Conclusion

The denormalized Sales relation was successfully analyzed using functional dependencies and normalized step-by-step from UNF to 1NF, 2NF, 3NF, and BCNF.

The final decomposition separates customer, product, category, salesperson, order, and sales-item information into independent relations. This reduces redundancy and prevents update, insertion, and deletion anomalies.

The normalized relations can be joined to reconstruct the original Sales information, demonstrating lossless decomposition. The identified functional dependencies are also represented within the decomposed relations, demonstrating dependency preservation.
