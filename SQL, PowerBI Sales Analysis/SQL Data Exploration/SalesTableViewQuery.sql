CREATE VIEW salesview AS
(
	SELECT s.Order#, s.[Sales Channel] AS SalesChannel, s.ProcuredDate, s.OrderDate, s.ShipDate, s.DeliveryDate, s.[Discount Applied] AS Discount, s.[Order Quantity] AS OrderQuantity, s.[Unit Price] AS UnitPrice, s.[Unit Cost] AS UnitCost,
			(s.[Unit Price] * s.[Order Quantity] * (1-s.[Discount Applied])) AS Revenue, 
			(s.[Unit Price] * s.[Order Quantity] * (1-s.[Discount Applied]))-(s.[Unit Cost] * s.[Order Quantity]) AS Profit,
			l.[City Name] AS City, l.State, l.Type, l.Latitude, l.Longitude, l.AreaCode, l.Population, l.[Household Income] AS HouseholdIncome, l.[Median Income] AS MedianIncome, 
			c.[Customer Names] AS Customer, e.[Sales Team] AS Employee, e.Region AS EmployeeRegion, p.[Product Name] AS Product
	FROM Sales s
	JOIN Locations l
		ON s._StoreID = l._StoreID
	JOIN Customers c
		ON s._CustomerID = c._CustomerID
	JOIN Employees e
		ON s._SalesTeamID = e._SalesTeamID
	JOIN Products p
		ON s._ProductID = p._ProductID
);

SELECT *
FROM salesview;

