/* Five Week Assessment - Part A
   Student name: Richmond Panyin Assafuah
   Student ID: 1010125
*/
USE FiveWeekAssessmentDB;
GO

/* A1 Product selection and sorting */
-- A1 grain: One Row per active product priced from 25.00 to 200.00
SELECT ProductID, 
	ProductName, 
	Category, 
	UnitPrice AS CurrentPrice
FROM Sales.Products
WHERE IsActive = 1
	AND UnitPrice >= 25.00 
	AND UnitPrice <= 200.00
ORDER BY CurrentPrice DESC;

GO

/* A2 Distinct customer locations */
-- A2 grain: one row per unique Region and Country combination
SELECT DISTINCT Region, 
	Country
FROM Sales.Customers
ORDER BY Region, Country;
GO

/* A3 Missing contact values */
-- A3 grain: one row per customer
SELECT CustomerID, 
	CustomerName, 
	Region, 
	COALESCE(Email, 'Not provided') AS Email, 
	YEAR(SignupDate) AS SignupYear
FROM Sales.Customers
ORDER BY CustomerID;

GO

/* A4 Calculated order-line values */
-- A4 grain: one row per order line with LineRevenue of at least 100.00
SELECT OrderID,
	LineNumber,
	ProductID,
	Quantity,
	UnitPrice,
	DiscountRate,
	ROUND(Quantity * UnitPrice * (1 - DiscountRate), 2) AS LineRevenue
FROM Sales.OrderItems
WHERE ROUND(Quantity * UnitPrice * (1 - DiscountRate), 2) >= 100.00
ORDER BY OrderID, LineNumber;
GO

/* A5 Combining the four tables */
-- A5 grain: one row per order line on a completed order
SELECT
    o.OrderID,
    o.OrderDate,
    c.CustomerName,
    c.Region,
    p.ProductName,
    p.Category,
    ROUND(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate), 2) AS LineRevenue
FROM Sales.OrderItems AS oi
JOIN Sales.Orders AS o
    ON o.OrderID = oi.OrderID
JOIN Sales.Customers AS c
    ON c.CustomerID = o.CustomerID
JOIN Sales.Products AS p
    ON p.ProductID = oi.ProductID
WHERE o.Status = 'Completed'
ORDER BY o.OrderDate, o.OrderID, oi.LineNumber;
-- Explanation: an order with three order lines produces three rows because the join
-- returns one result row for every matching row in OrderItems, so the order's details are repeated once per line.
GO

/* A6 Category summary */
-- A6 grain: one row per product category (completed orders only)
SELECT
    p.Category,
    COUNT(DISTINCT o.OrderID) AS OrderCount,
    SUM(oi.Quantity) AS TotalUnits,
    ROUND(AVG(oi.UnitPrice), 2) AS AvgSellingUnitPrice,
    ROUND(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate)), 2) AS TotalRevenue
FROM Sales.OrderItems AS oi 
JOIN Sales.Orders AS o ON  o.OrderID = oi.OrderID
JOIN Sales.Products AS p ON p.ProductID = oi.ProductID
WHERE o.Status = 'Completed'
GROUP BY p.Category
ORDER BY TotalRevenue DESC;
-- Interpretation: The category with the greatest revenue (8699.9900) is Office.
-- units sold (61) and the most orders (23), helped by the high-priced Ergonomic Chair.
-- Check grain: a single row holding total completed-order revenue

GO

/* A7 Filtering grouped customer results */
-- A7 grain: one row per customer with completed-order revenue above 600.00
SELECT c.CustomerID,
		c.CustomerName,
		COUNT(DISTINCT o.OrderID) AS OrderCount,
		ROUND(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate)), 2) AS TotalRevenue
FROM Sales.Customers AS c
JOIN Sales.Orders AS o ON o.CustomerID = c.CustomerID
JOIN Sales.OrderItems AS oi ON oi.OrderID = o.OrderID
WHERE o.Status = 'Completed'
GROUP BY c.CustomerID, c.CustomerName
HAVING ROUND(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate)), 2) > 600.00
ORDER BY TotalRevenue Desc;

GO

/* A8 Scalar subquery */
-- A8 grain: one row per active product priced above the average active price
SELECT
    ProductID,
    ProductName,
    Category,
    UnitPrice
FROM Sales.Products AS p
WHERE  p.IsActive = 1 
	AND UnitPrice >
	(SELECT AVG(p.UnitPrice) AS Averageprice
	FROM Sales.Products AS p
	WHERE p.IsActive = 1)
ORDER BY UnitPrice DESC;

GO

/* A9 CTE and customer categories */
-- A9 grain: one row per customer with completed orders, labelled by value category
WITH CustomerRevenue AS (
    SELECT
        c.CustomerID,
        c.CustomerName,
        c.Region,
        ROUND(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate)), 2) AS TotalRevenue
    FROM Sales.Customers AS c
    JOIN Sales.Orders AS o ON O.CustomerID = C.CustomerID
    JOIN Sales.OrderItems AS oi ON oi.OrderID = o.OrderID
    WHERE o.Status = 'Completed'
    GROUP BY c.CustomerID,
        c.CustomerName,
        c.Region
)
SELECT
    CustomerID,
    CustomerName,
    Region,
    TotalRevenue,
    CASE
        WHEN TotalRevenue >= 1500 THEN 'High Value'
        WHEN TotalRevenue >= 700 THEN 'Medium Value'
        ELSE 'Standard'
    END AS ValueCategory
FROM CustomerRevenue
ORDER BY TotalRevenue DESC;

GO


/* A10 Monthly revenue and running total */
-- A10 grain: one row per calendar month of completed-order revenue
WITH MonthlyRevenueCTE AS (
    SELECT
        DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1) AS MonthStart,
        ROUND(SUM(oi.Quantity * oi.UnitPrice * (1 - oi.DiscountRate)), 2) AS MonthlyRevenue
    FROM Sales.Orders AS o
    JOIN Sales.OrderItems AS oi ON oi.OrderID = o.OrderID
    WHERE o.Status = 'Completed'
    GROUP BY DATEFROMPARTS(YEAR(o.OrderDate), MONTH(o.OrderDate), 1)
)
SELECT
    MonthStart,
    MonthlyRevenue,
    SUM(MonthlyRevenue) OVER (ORDER BY MonthStart) AS RunningTotal
FROM MonthlyRevenueCTE
ORDER BY MonthStart;
-- Interpretation: Monthly revenue rose from 4632.9500 in January to  7380.9900 in March and fell to 6863.3500 in
-- April, then fell again to 4511.1900 in May

GO

