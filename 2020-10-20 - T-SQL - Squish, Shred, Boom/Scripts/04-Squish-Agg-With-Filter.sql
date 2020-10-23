USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/*

SELECT
	TOP 100 *
FROM		Orders;

SELECT
	TOP 100 *
FROM		Customers;

*/

/*

	Show top 5 customers by order count starting with M.

	Note that these might not return the same data,
		because only 1 level of sorting is specified and ties for the last record will be split arbitrarily.
		
*/

SELECT							/* Sub-queries */
	c.CustomerID,
	c.Customer,
	c.CustomerEmail,
	OrderCount =
		(
			SELECT
				COUNT(*)
			FROM		Orders AS o1
			WHERE		o1.CustomerID = c.CustomerID
		),
	LastOrder =
		(
			SELECT
				MAX(o2.OrderDate)
			FROM		Orders AS o2
			WHERE		o2.CustomerID = c.CustomerID
		)
FROM		Customers  AS c
WHERE		c.CustomerID IN
				(
					SELECT
						TOP 5
						o3.CustomerID
					FROM		Orders AS o3
					JOIN		Customers AS c2
					ON			c2.CustomerID = o3.CustomerID
					WHERE		c2.Customer LIKE 'M%'
					GROUP BY	o3.CustomerID
					ORDER BY	COUNT(*) DESC
				)
ORDER BY	OrderCount DESC,
			LastOrder DESC;


SELECT							/* JOIN then GROUP */
	TOP 5
	c.CustomerID,
	c.Customer,
	c.CustomerEmail,
	OrderCount = COUNT(*),
	LastOrder = MAX(o.OrderDate)
FROM		Customers  AS c
JOIN		Orders o
ON			o.CustomerID = c.CustomerID
WHERE		c.Customer LIKE 'M%'
GROUP BY	c.CustomerID,
			c.Customer,
			c.CustomerEmail
ORDER BY	OrderCount DESC,
			LastOrder DESC;


SELECT							/* GROUP then JOIN */
	TOP 5
	c.CustomerID,
	c.Customer,
	c.CustomerEmail,
	OrderInfo.OrderCount,
	OrderInfo.LastOrder
FROM		Customers  AS c
JOIN		(
				SELECT
					TOP 5
					o.CustomerID,
					OrderCount = COUNT(*),
					LastOrder = MAX(o.OrderDate)
				FROM		Orders AS o
				JOIN		Customers AS c2
				ON			c2.CustomerID = o.CustomerID
				WHERE		c2.Customer LIKE 'M%'
				GROUP BY	o.CustomerID
				ORDER BY	OrderCount DESC,
							LastOrder DESC
			) OrderInfo
ON			OrderInfo.CustomerID = c.CustomerID
ORDER BY	OrderCount DESC;


SELECT							/* CROSS APPLY */
	TOP 5
	c.CustomerID,
	c.Customer,
	c.CustomerEmail,
	OrderInfo.OrderCount,
	OrderInfo.LastOrder
FROM		Customers  AS c
CROSS APPLY	(
				SELECT
					OrderCount = COUNT(*),
					LastOrder = MAX(o.OrderDate)
				FROM		Orders AS o
				WHERE		o.CustomerID = c.CustomerID
			) AS OrderInfo
WHERE		c.Customer LIKE 'M%'
ORDER BY	OrderCount DESC,
			LastOrder DESC;