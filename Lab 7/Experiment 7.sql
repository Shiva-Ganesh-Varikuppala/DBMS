CREATE TABLE Sales (
    OrderID INT,
    ProductID INT,
    OrderDate DATE,

    CustomerID INT,
    CustomerName VARCHAR(100),
    CustomerCity VARCHAR(100),

    ProductName VARCHAR(100),

    CategoryID INT,
    CategoryName VARCHAR(100),

    Quantity INT,
    UnitPrice DECIMAL(10,2),

    SalespersonID INT,
    SalespersonName VARCHAR(100)
);

INSERT INTO Sales VALUES
(1001, 101, '2026-10-01',
 1, 'Rahul', 'Hyderabad',
 'Laptop',
 10, 'Electronics',
 2, 55000.00,
 501, 'Arun'),

(1001, 102, '2026-10-01',
 1, 'Rahul', 'Hyderabad',
 'Mouse',
 10, 'Electronics',
 3, 800.00,
 501, 'Arun'),

(1002, 103, '2026-10-02',
 2, 'Anjali', 'Delhi',
 'Keyboard',
 10, 'Electronics',
 2, 1500.00,
 502, 'Priya'),

(1002, 104, '2026-10-02',
 2, 'Anjali', 'Delhi',
 'Chair',
 20, 'Furniture',
 1, 7500.00,
 502, 'Priya'),

(1003, 101, '2026-10-03',
 3, 'Kiran', 'Mumbai',
 'Laptop',
 10, 'Electronics',
 1, 55000.00,
 501, 'Arun');


 SELECT * FROM Sales;