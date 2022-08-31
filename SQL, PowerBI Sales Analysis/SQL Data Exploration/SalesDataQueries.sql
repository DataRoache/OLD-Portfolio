--For viewing all tables
SELECT *
FROM Sales;
SELECT *
FROM Customers;
SELECT *
FROM Employees;
SELECT *
FROM Locations;
SELECT *
FROM Regions;
SELECT *
FROM Products;

--Getting rid of unnecessary columns
ALTER TABLE Sales
DROP COLUMN CurrencyCode;

/* 
	FIRST SECTION IS GOING TO SHOW TOP & BOTTOM PRODUCTS BY REVENUE, PROFIT, AMOUNT OF ORDERS, AND QUANTITY SOLD
	WILL ALSO SHOW TOP 5 PRODUCTS IN REVENUE FOR EACH STATE,
	AND THE TOP PRODUCT IN REVENUE AND PROFIT FOR EACH YEAR
	MAIN QUERIES ARE LINES 75 THROUGH 169
*/

--Creating stateproducts temp table
SELECT p.[Product Name],
    	l.[State],
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS ProductRevenue,
		RANK() OVER(PARTITION BY l.[State] ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) DESC) AS StateRevenueRank,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS TotalProductProfit,
		RANK() OVER(PARTITION BY l.[State] ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) DESC) AS ProfitRank,
		COUNT(s._StoreID) AS OrderCount,
		RANK() OVER (PARTITION BY l.[State] ORDER BY COUNT(s._StoreID) DESC) AS OrderCountRank,
		SUM(s.[Order Quantity]) AS TotalQuantitySold,
		RANK() OVER(PARTITION BY l.[State] ORDER BY SUM(s.[Order Quantity]) DESC) AS QuantitySoldRank
INTO #stateproducts
FROM Sales s
JOIN Products p
	ON s._ProductID = p._ProductID
JOIN Locations l
	ON s._StoreID = l._StoreID
GROUP BY p.[Product Name], l.[State]
ORDER BY 2, 3 DESC;

--Checking if worked
SELECT *
FROM #stateproducts;

--Creating statetotals temp table
SELECT  l.[State],
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS TotalStateRevenue,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]))DESC) AS StateRevRank,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS TotalStateProfit,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) DESC) AS StateProfitRank
INTO #StateTotals
FROM Sales s
JOIN Locations l
	ON s._StoreID = l._StoreID
GROUP BY l.[State]
ORDER BY 3;

--Creating a table to query off of thats a join of the 2 temp tables I already made
SELECT a.*, b.TotalStateRevenue, b.StateRevRank, b.TotalStateProfit, b.StateProfitRank
INTO #StateQueryTable
FROM #stateproducts a
JOIN #statetotals b
	ON a.State = b.State;

--Checking if it worked
SELECT *
FROM #statequerytable
ORDER BY 2, 3 DESC;

--Top 10 products by revenue
SELECT TOP(10) [Product Name], FORMAT(SUM(ProductRevenue), 'C') AS ProductRevenue
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2 DESC;
--Bottom 10 products by revenue
SELECT TOP(10) [Product Name], FORMAT(SUM(ProductRevenue), 'C') AS ProductRevenue
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2;

--Top 10 most profitable products
SELECT TOP(10) [Product Name], FORMAT(SUM(TotalProductProfit), 'C') AS ProductProfit
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2 DESC;
--Bottom 10 least profitable products
SELECT TOP(10) [Product Name], FORMAT(SUM(TotalProductProfit), 'C') AS ProductProfit
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2;

--Top 10 most ordered products
SELECT TOP(10) [Product Name], SUM(OrderCount) AS OrderCount
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2 DESC;
--Bottom 10 least ordered products
SELECT TOP(10) [Product Name], SUM(OrderCount) AS OrderCount
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2;

--Top 10 products by quantity sold
SELECT TOP(10) [Product Name], SUM(TotalQuantitySold) AS QuantitySold
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2 DESC;
--Bottom 10 products by quantity sold
SELECT TOP(10) [Product Name], SUM(TotalQuantitySold) AS QuantitySold
FROM #statequerytable
GROUP BY [Product Name]
ORDER BY 2;

--TOP 5 Products in each state by revenue
SELECT [Product Name], State, FORMAT(ProductRevenue, 'C') AS ProductRevenue, StateRevenueRank AS RevRank
FROM #statequerytable
WHERE StateRevenueRank < 6
ORDER BY 2, 3 DESC;

--Top Product in each year by revenue
WITH prodtable AS
(
	SELECT YEAR(s.OrderDate) AS Year,
			p.[Product Name],
			SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS TotalRevenue,
			SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS TotalProfit
	FROM Sales s
	JOIN Products p
		ON s._ProductID = p._ProductID
	GROUP BY YEAR(s.OrderDate), p.[Product Name]
)
SELECT a.Year, a.[Product Name], FORMAT(a.TotalRevenue, 'C') AS TotalRevenue
FROM prodtable a
INNER JOIN 
(
	SELECT Year, MAX(TotalRevenue) AS TotalRevenue
	FROM prodtable
	GROUP BY Year
) b
	ON a.TotalRevenue = b.TotalRevenue
ORDER BY 3 DESC;

--Top product in each year by profit
WITH prodtable2 AS
(
	SELECT YEAR(s.OrderDate) AS Year,
			p.[Product Name],
			SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS TotalRevenue,
			SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS TotalProfit
	FROM Sales s
	JOIN Products p
		ON s._ProductID = p._ProductID
	GROUP BY YEAR(s.OrderDate), p.[Product Name]
)
SELECT a.Year, a.[Product Name], FORMAT(a.TotalProfit, 'C') AS TotalProfit
FROM prodtable2 a
INNER JOIN 
(
	SELECT Year, MAX(TotalProfit) AS TotalProfit
	FROM prodtable2
	GROUP BY Year
) b
	ON a.TotalProfit = b.TotalProfit
ORDER BY 3 DESC;

/*
	NEXT SECTION WILL SHOW THE TOP AND BOTTOM CUSTOMERS BY REVENUE, PROFITABILITY, ORDERS, AND QUANTITY PURCHASED
	MAIN QUERIES ARE LINES 196 THROUGH 230
*/

--Creating temp table for customer rankings queries
SELECT	c.[Customer Names],
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS Revenue,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) DESC) AS RevenueRank,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS Profit,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) DESC) AS ProfitRank,
		COUNT(s._CustomerID) AS OrderCount,
		RANK() OVER(ORDER BY COUNT(s._CustomerID) DESC) AS OrderCountRank,
		SUM(s.[Order Quantity]) AS TotalQuantityBought,
		RANK() OVER(ORDER BY SUM(s.[Order Quantity]) DESC) AS QuantityBoughtRank
INTO #customer_rankings
FROM Sales s
JOIN Customers c
	ON s._CustomerID = c._CustomerID
GROUP BY c.[Customer Names], s._CustomerID
ORDER BY 2 DESC;

--Make sure temp table worked
SELECT *
FROM #customer_rankings
ORDER BY 2 DESC;

--Top 10 customers by revenue
SELECT TOP(10) [Customer Names], FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #customer_rankings
ORDER BY 2 DESC;
--Bottom 10 customers by revenue
SELECT TOP(10) [Customer Names], FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #customer_rankings
ORDER BY 2;

--Top 10 most profitable customers
SELECT TOP(10) [Customer Names], FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #customer_rankings
ORDER BY 2 DESC;
--Bottom 10 least profitable customers
SELECT TOP(10) [Customer Names], FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #customer_rankings
ORDER BY 2;

--Top 10 customers by amount of orders placed
SELECT TOP(10) [Customer Names], OrderCount, OrderCountRank
FROM #customer_rankings
ORDER BY 2 DESC;
--Bottom 10 customers by amount of orders placed
SELECT TOP(10) [Customer Names], OrderCount, OrderCountRank
FROM #customer_rankings
ORDER BY 2;

--Top 10 customers by total products bought
SELECT TOP(10) [Customer Names], TotalQuantityBought, QuantityBoughtRank
FROM #customer_rankings
ORDER BY 2 DESC;
--Bottom 10 customers by total products bought
SELECT TOP(10) [Customer Names], TotalQuantityBought, QuantityBoughtRank
FROM #customer_rankings
ORDER BY 2;

/*
	NEXT SECTION WILL SHOW TOP AND BOTTOM EMPLOYEES BY SALES, PROFIT, ORDERS COMPLETED, AND QUANTITY SOLD
	ALSO SHOWS THE DIFFERENT REGIONS OF SALES TEAMS AND THEIR RESPECTIVE TOTAL REVENUES, PROFITS, ORDERS, AND QUANTITIES
	MAIN QUERIES ARE LINES 259 THROUGH 303
*/

--Creating a temp table for employee ranking queries
SELECT e._SalesTeamID, e.[Sales Team] AS Employee, 
		e.Region, 
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS Revenue,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) DESC) AS RevenueRank,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS Profit,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) DESC) AS ProfitRank,
		COUNT(s._SalesTeamID) AS OrderCount,
		RANK() OVER(ORDER BY COUNT(s._SalesTeamID) DESC) AS OrderCountRank,
		SUM(s.[Order Quantity]) AS TotalQuantitySold,
		RANK() OVER(ORDER BY SUM(s.[Order Quantity]) DESC) AS QuantitySoldRank
INTO #employee_rankings
FROM Sales s
JOIN Employees e
	ON s._SalesTeamID = e._SalesTeamID
GROUP BY e.[Sales Team], e.Region, e._SalesTeamID
ORDER BY 4 DESC;

--Double checking temp table
SELECT *
FROM #employee_rankings
ORDER BY 4 DESC;

--Top 10 employees by sales
SELECT TOP(10) Employee, Region, FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #employee_rankings
ORDER BY 3 DESC;
--Bottom 10 employees by sales
SELECT TOP(10) Employee, Region, FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #employee_rankings
ORDER BY 3;

--Top 10 employees generating most profit
SELECT TOP(10) Employee, Region, FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #employee_rankings
ORDER BY 3 DESC;
--Bottom 10 employees generating least profit
SELECT TOP(10) Employee, Region, FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #employee_rankings
ORDER BY 3;

--Top 10 employees by amount of orders
SELECT TOP(10) Employee, Region, OrderCount, OrderCountRank
FROM #employee_rankings
ORDER BY 3 DESC;
--Bottom 10 employees by amount of orders
SELECT TOP(10) Employee, Region, OrderCount, OrderCountRank
FROM #employee_rankings
ORDER BY 3;

--Top 10 employees by total products sold
SELECT TOP(10) Employee, Region, TotalQuantitySold, QuantitySoldRank
FROM #employee_rankings
ORDER BY 3 DESC;
--Bottom 10 employees by total products sold
SELECT TOP(10) Employee, Region, TotalQuantitySold, QuantitySoldRank
FROM #employee_rankings
ORDER BY 3;

--Sales team region in order from highest to lowest revenue. Showing total profits, total orders and total quantity sold as well.
SELECT Region, 
		FORMAT(SUM(Revenue), 'C') AS RegionRevenue, 
		FORMAT(SUM(Profit), 'C') AS RegionProfit, 
		SUM(OrderCount) AS RegionTotalOrders, 
		SUM(TotalQuantitySold) AS RegionTotalQuantitySold
FROM #employee_rankings
GROUP BY Region
ORDER BY 2 DESC;

/*
	NEXT SECTION WILL SHOW TOP AND BOTTOM STORE LOCATIONS BASED ON REVENUE, PROFIT, ORDERS MADE, AND QUANTITY SOLD
	BREAKS DOWN TOP/BOTTOM CITIES AND STATES IN SIMILAR FASHIONS
	MAIN QUERIES ON LINES 333 THROUGH 411
*/

--Creating temp table for store rankings
SELECT  s._StoreID,
		l.[City Name],
		l.State,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) AS Revenue,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied])) DESC) AS RevenueRank,
		SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) AS Profit,
		RANK() OVER(ORDER BY SUM(s.[Unit Price] * s.[Order Quantity] * (1 - s.[Discount Applied]) - (s.[Unit Cost] * s.[Order Quantity])) DESC) AS ProfitRank,
		COUNT(s._StoreID) AS OrderCount,
		RANK() OVER (ORDER BY COUNT(s._StoreID) DESC) AS OrderCountRank,
		SUM(s.[Order Quantity]) AS TotalQuantitySold,
		RANK() OVER(ORDER BY SUM(s.[Order Quantity]) DESC) AS QuantitySoldRank
INTO #store_rankings
FROM Sales s
JOIN Locations l
	ON s._StoreID = l._StoreID
GROUP BY s._StoreID, l.[City Name], l.State
ORDER BY 4 DESC;

--Making sure it worked
SELECT *
FROM #store_rankings
ORDER BY 4 DESC;

--Top 10 stores/locations by revenue
SELECT TOP(10) _StoreID, [City Name], State, FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #store_rankings
ORDER BY 5;
--Bottom 10 stores/locations by revenue
SELECT TOP(10) _StoreID, [City Name], State, FORMAT(Revenue, 'C') AS Revenue, RevenueRank
FROM #store_rankings
ORDER BY 5 DESC;

--Top 10 most profitable stores
SELECT TOP(10) _StoreID, [City Name], State, FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #store_rankings
ORDER BY 5;
--Bottom 10 least profitable stores
SELECT TOP(10) _StoreID, [City Name], State, FORMAT(Profit, 'C') AS Profit, ProfitRank
FROM #store_rankings
ORDER BY 5 DESC;

--Top 10 stores/locations by amount of orders
SELECT TOP(10) _StoreID, [City Name], State, OrderCount, OrderCountRank
FROM #store_rankings
ORDER BY 4 DESC;
--Bottom 10 stores/locations by orders
SELECT TOP(10) _StoreID, [City Name], State, OrderCount, OrderCountRank
FROM #store_rankings
ORDER BY 4;

--Top 10 stores/locations by quantity sold
SELECT TOP(10) _StoreID, [City Name], State, TotalQuantitySold, QuantitySoldRank
FROM #store_rankings
ORDER BY 4 DESC;
--Bottom 10 stores/locations by quantity sold
SELECT TOP(10) _StoreID, [City Name], State, TotalQuantitySold, QuantitySoldRank
FROM #store_rankings
ORDER BY 4;

--Top 10 cities by revenue
SELECT TOP(10) [City Name], State, 
				FORMAT(SUM(Revenue), 'C') AS CityRevenue,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS CityRevRank
FROM #store_Rankings
GROUP BY [City Name], State
ORDER BY 4;
--Bottom 10 cities by revenue
SELECT TOP(10) [City Name], State, 
				FORMAT(SUM(Revenue), 'C') AS CityRevenue,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS CityRevRank
FROM #store_Rankings
GROUP BY [City Name], State
ORDER BY 4 DESC;

--Top 10 cities by profit
SELECT TOP(10) [City Name], State,
				FORMAT(SUM(Profit), 'C') AS CityProfit,
				RANK() OVER(ORDER BY SUM(Profit) DESC) AS CityProfitRank
FROM #store_Rankings
GROUP BY [City Name], State
ORDER BY 4;
--Bottom 10 cities by profit
SELECT TOP(10) [City Name], State, 
				FORMAT(SUM(Profit), 'C') AS CityProfit,
				RANK() OVER(ORDER BY SUM(Profit) DESC) AS CityProfitRank
FROM #store_Rankings
GROUP BY [City Name], State
ORDER BY 4 DESC;

--Top 10 states by revenue
SELECT TOP(10) State, 
				FORMAT(SUM(Revenue), 'C') AS StateRevenue,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS StateRevRank
FROM #store_Rankings
GROUP BY State
ORDER BY 3;
--Bottom 10 states by revenue
SELECT TOP(10) State, 
				FORMAT(SUM(Revenue), 'C') AS StateRevenue,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS StateRevRank
FROM #store_Rankings
GROUP BY State
ORDER BY 3 DESC;

--Top 10 states by profit
SELECT TOP(10) State,
				FORMAT(SUM(Profit), 'C') AS StateProfit,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS StateProfitRank
FROM #store_Rankings
GROUP BY State
ORDER BY 3;
--Bottom 10 states by profit
SELECT TOP(10) State,
				FORMAT(SUM(Profit), 'C') AS StateProfit,
				RANK() OVER(ORDER BY SUM(Revenue) DESC) AS StateProfitRank
FROM #store_Rankings
GROUP BY State
ORDER BY 3 DESC;

/*
	NEXT SECTION IS ALL ABOUT INVENTORY TIME METRICS, FROM DELIVERY TIMES BROKEN DOWN BY CUSTOMER/PRODUCT,
	TO INVENTORY TURNOVER TIMES AND PURCHASE LEAD TIMES BROKEN DOWN IN SIMILAR WAYS
	LINES 419 THROUGH 461
*/

--Avg. delivery time per product in days, longest to shortest
--Compared to overall avg. delivery time in days
SELECT p.[Product Name], 
		ROUND(AVG(CAST(DATEDIFF(DAY, s.ShipDate, s.DeliveryDate) AS FLOAT)), 3) + 1 AS [Avg. Delivery Time - DAYS],
		AVG(AVG(CAST(DATEDIFF(DAY, ShipDate, DeliveryDate) AS DECIMAL(2)))) OVER() + 1 AS [Overall Avg. Delivery Time - DAYS]
FROM Sales s
JOIN Products p
	ON s._ProductID = p._ProductID
GROUP BY p.[Product Name]
ORDER BY 2 DESC;

--Avg. delivery time per customer in days, longest to shortest
--Compared to overall avg. delivery time in days
SELECT c.[Customer Names], 
		ROUND(AVG(CAST(DATEDIFF(DAY, s.ShipDate, s.DeliveryDate) AS FLOAT)), 3) + 1 AS [Avg. Delivery Time - DAYS],
		AVG(AVG(CAST(DATEDIFF(DAY, ShipDate, DeliveryDate) AS DECIMAL(2)))) OVER() + 1 AS [Overall Avg. Delivery Time - DAYS]
FROM Sales s
JOIN Customers c
	ON s._CustomerID = c._CustomerID
GROUP BY c.[Customer Names]
ORDER BY 2 DESC;

--Avg. purchase lead time per product (time from order to delivery) in days, longest to shortest
--Compared with overall purchase lead time in days
SELECT p.[Product Name], 
		ROUND(AVG(CAST(DATEDIFF(DAY, s.OrderDate, s.DeliveryDate) AS FLOAT)), 3) + 1 AS [Avg. Purchase Lead Time - DAYS],
		AVG(AVG(CAST(DATEDIFF(DAY, OrderDate, DeliveryDate) AS DECIMAL(2)))) OVER() + 1 AS [Overall Avg. Purchase Lead Time - DAYS]
FROM Sales s
JOIN Products p
	ON s._ProductID = p._ProductID
GROUP BY p.[Product Name]
ORDER BY 2 DESC;

--Avg. inventory turnover time per product in months, longest to shortest
--Compared with overall Avg. Inventory Turnover in Months
SELECT p.[Product Name], 
		ROUND(AVG(CAST(DATEDIFF(MONTH, s.ProcuredDate, s.OrderDate) AS FLOAT)), 3) + 1 AS [Avg. Inventory Turnover - MONTHS],
		AVG(AVG(CAST(DATEDIFF(MONTH, s.ProcuredDate, s.OrderDate) AS DECIMAL(2)))) OVER() + 1 AS [Overall Avg. Inventory Turnover - MONTHS]
FROM Sales s
JOIN Products p
	ON s._ProductID = p._ProductID
GROUP BY p.[Product Name]
ORDER BY 2 DESC;

/*
	NEXT SECTION GOES THROUGH AVG. DISCOUNTS, BROKEN DOWN BY PRODUCTS AND CUSTOMERS
	LINES 468 THROUGH 496
*/

--Overall avg. discount given
SELECT FORMAT(AVG([Discount Applied]), 'P') AS [Overall Discount Given]
FROM Sales;

--Avg. discount per product from largest to smallest
SELECT p.[Product Name], FORMAT(AVG(s.[Discount Applied]), 'P') AS  [Avg. Discount]
FROM Sales s
JOIN Products p
	ON s._ProductID = p._ProductID
GROUP BY p.[Product Name]
ORDER BY 2 DESC;

--Avg. discount per customer from largest to smallest
--'OUR Ltd' has an average discount rate of 9.91%, but the query is bugging when I include it and I cannot figure out why
SELECT c.[Customer Names], FORMAT(AVG(s.[Discount Applied]), 'P') AS [Avg. Discount]
FROM Sales s
JOIN Customers c
	ON s._CustomerID = c._CustomerID
WHERE c.[Customer Names] NOT LIKE 'OUR Ltd'
GROUP BY c.[Customer Names]
ORDER BY 2 DESC;

--Avg. discount given per employee, largest to smallest
SELECT e.[Sales Team], FORMAT(AVG(s.[Discount Applied]), 'P') AS [Avg. Discount]
FROM Sales s
JOIN Employees e
	ON s._SalesTeamID = e._SalesTeamID
GROUP BY e.[Sales Team]
ORDER BY 2 DESC;