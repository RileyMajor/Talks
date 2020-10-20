USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/*

SELECT
	TOP 100 *
FROM		Orders;

SELECT
	OrderStatusID,
	COUNT(*)
FROM		Orders
GROUP BY	OrderStatusID;

SELECT
	TOP 100 *
FROM		Customers;

*/

/*

	Show customers starting with "Ad" and the number of orders in each status.
		
*/

SELECT							/* Sub-Queries */
	c.CustomerID,
	c.Customer,
	Status1 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 1),
	Status2 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 2),
	Status3 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 3),
	Status4 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 4),
	Status5 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 5),
	Status6 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 6),
	Status7 = (SELECT COUNT(*) FROM Orders o1 WHERE o1.CustomerID = c.CustomerID AND o1.OrderStatusID = 7)
FROM		Customers AS c
WHERE		c.Customer LIKE 'Ad%'
ORDER BY	c.CustomerID;

SELECT							/* OUTER APPLY */
	c.CustomerID,
	c.Customer,
	OrderInfo.Status1,
	OrderInfo.Status2,
	OrderInfo.Status3,
	OrderInfo.Status4,
	OrderInfo.Status5,
	OrderInfo.Status6,
	OrderInfo.Status7
FROM		Customers AS c
CROSS APPLY	(
				SELECT
					Status1 = SUM(CASE WHEN o.OrderStatusID = 1 THEN 1 ELSE 0 END),
					Status2 = SUM(CASE WHEN o.OrderStatusID = 2 THEN 1 ELSE 0 END),
					Status3 = SUM(CASE WHEN o.OrderStatusID = 3 THEN 1 ELSE 0 END),
					Status4 = SUM(CASE WHEN o.OrderStatusID = 4 THEN 1 ELSE 0 END),
					Status5 = SUM(CASE WHEN o.OrderStatusID = 5 THEN 1 ELSE 0 END),
					Status6 = SUM(CASE WHEN o.OrderStatusID = 6 THEN 1 ELSE 0 END),
					Status7 = SUM(CASE WHEN o.OrderStatusID = 7 THEN 1 ELSE 0 END)
				FROM		Orders o
				WHERE		o.CustomerID = c.CustomerID
			) OrderInfo
WHERE		c.Customer LIKE 'Ad%'
ORDER BY	c.CustomerID;


SELECT							/* GROUP THEN JOIN */
	c.CustomerID,
	c.Customer,
	OrderInfo.Status1,
	OrderInfo.Status2,
	OrderInfo.Status3,
	OrderInfo.Status4,
	OrderInfo.Status5,
	OrderInfo.Status6,
	OrderInfo.Status7
FROM		Customers AS c
JOIN		(
				SELECT
					o.CustomerID,
					Status1 = SUM(CASE WHEN o.OrderStatusID = 1 THEN 1 ELSE 0 END),
					Status2 = SUM(CASE WHEN o.OrderStatusID = 2 THEN 1 ELSE 0 END),
					Status3 = SUM(CASE WHEN o.OrderStatusID = 3 THEN 1 ELSE 0 END),
					Status4 = SUM(CASE WHEN o.OrderStatusID = 4 THEN 1 ELSE 0 END),
					Status5 = SUM(CASE WHEN o.OrderStatusID = 5 THEN 1 ELSE 0 END),
					Status6 = SUM(CASE WHEN o.OrderStatusID = 6 THEN 1 ELSE 0 END),
					Status7 = SUM(CASE WHEN o.OrderStatusID = 7 THEN 1 ELSE 0 END)
				FROM		Orders o
				GROUP BY	o.CustomerID
			) AS OrderInfo
ON			OrderInfo.CustomerID = c.CustomerID
WHERE		c.Customer LIKE 'Ad%'
ORDER BY	c.CustomerID;

SELECT							/* PIVOT */
	c.CustomerID,
	c.Customer,
	OrderInfo.Status1,
	OrderInfo.Status2,
	OrderInfo.Status3,
	OrderInfo.Status4,
	OrderInfo.Status5,
	OrderInfo.Status6,
	OrderInfo.Status7
FROM		Customers AS c
JOIN		(
				SELECT
					CustomerID = pvt.CustomerID,
					Status1 = [1],
					Status2 = [2],
					Status3 = [3],
					Status4 = [4],
					Status5 = [5],
					Status6 = [6],
					Status7 = [7]
				FROM		(
								SELECT
									o.OrderID,
									o.CustomerID,
									o.OrderStatusID
								FROM		Orders o
							) AS p
							PIVOT
							(
								COUNT(p.OrderID)
								FOR p.OrderStatusID IN ([1],[2],[3],[4],[5],[6],[7])
							) AS pvt
			) AS OrderInfo
ON			OrderInfo.CustomerID = c.CustomerID
WHERE		c.Customer LIKE 'Ad%'
ORDER BY	c.CustomerID;