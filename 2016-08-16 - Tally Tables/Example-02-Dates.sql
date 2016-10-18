DECLARE @Orders TABLE (OrderID int PRIMARY KEY IDENTITY, OrderDate date);
INSERT INTO @Orders(OrderDate) VALUES (getdate()-1),(getdate()-2),(getdate()-2),(getdate()-4);


DECLARE @StartDate date = getdate()-4;
SELECT
	DATEADD(DAY,n-1,@StartDate) AS OrderDate,
	isNull(COUNT(OrderID),0) AS OrderCount
FROM		(SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) AS Numbers
LEFT JOIN	@Orders
ON			DATEADD(DAY,n-1,@StartDate) = OrderDate
GROUP BY	n
ORDER BY	n;