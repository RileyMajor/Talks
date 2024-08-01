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

	Show customers and their last order information (date and status).

*/

PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'JOIN with sub-query';

SELECT					/* JOIN with sub-query */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
JOIN		Orders AS o
ON			o.CustomerID = c.CustomerID
AND			o.OrderDate =
				(
					SELECT
						max(OrderDate)
					FROM		Orders o2
					WHERE		o2.CustomerID = c.CustomerID
				)
ORDER BY	c.CustomerID;


PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'JOIN with derived table';

SELECT					/* JOIN with derived table */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
JOIN		(
				SELECT
					*
				FROM		Orders o1
				WHERE		o1.OrderDate =
								(
									SELECT
										max(o2.OrderDate)
									FROM		Orders o2
									WHERE		o2.CustomerID = o1.CustomerID
								)
			) o
ON			o.CustomerID = c.CustomerID
ORDER BY	c.CustomerID;


PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'Window then JOIN with Filter';

SELECT					/* Window then JOIN with Filter */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
JOIN		(
				SELECT
					CustOrder = RANK() OVER (PARTITION BY o2.CustomerID ORDER BY o2.OrderDate DESC),
					*
				FROM		Orders o2
			) AS o
ON			o.CustomerID = c.CustomerID
AND			o.CustOrder = 1
ORDER BY	c.CustomerID;


PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'Window with Filter then JOIN';

SELECT					/* Window then Filter then JOIN */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
JOIN		(
				SELECT
					*
				FROM		(
								/* You can't filter by a window function. You have to wrap it in another layer of derived table. */
								SELECT
									CustOrder = RANK() OVER (PARTITION BY o2.CustomerID ORDER BY o2.OrderDate DESC),
									*
								FROM		Orders o2
							) AS OrdersWithRank
				WHERE		OrdersWithRank.CustOrder = 1
			) AS o
ON			o.CustomerID = c.CustomerID
ORDER BY	c.CustomerID;

PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'JOIN then Window';

SELECT					/* JOIN then Window */
	t.Customer,
	t.CustomerEmail,
	t.OrderDate,
	t.OrderStatusID
FROM		(
				SELECT
					/* We have to specify the columns twice, because using * results in dupe column names from the two tables. */
					c.CustomerID,
					c.Customer,
					c.CustomerEmail,
					o.OrderDate,
					o.OrderStatusID,
					CustOrder = RANK() OVER (PARTITION BY o.CustomerID ORDER BY o.OrderDate DESC)
				FROM		Customers AS c
				JOIN		Orders o
				ON			o.CustomerID = c.CustomerID
			) AS t
WHERE		t.CustOrder = 1
ORDER BY	t.CustomerID;


/* What about duplicate order dates? Try these. */

PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'CROSS APPLY TOP 1';

SELECT				/* CROSS APPLY TOP 1 */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
CROSS APPLY	(
				SELECT
					TOP 1 *
				FROM		Orders o2
				WHERE		o2.CustomerID = c.CustomerID
				ORDER BY	OrderDate DESC
			) AS o
ORDER BY	c.CustomerID;


PRINT CHAR(13) + CHAR(10) + '************************************* ' + 'Window then JOIN';

SELECT				/* Window then JOIN */
	c.Customer,
	c.CustomerEmail,
	o.OrderDate,
	o.OrderStatusID
FROM		Customers AS c
JOIN		(
				SELECT
					CustOrder = RANK() OVER (PARTITION BY o2.CustomerID ORDER BY o2.OrderDate DESC, o2.OrderID DESC),
					*
				FROM		Orders o2
			) AS o
ON			o.CustomerID = c.CustomerID
AND			o.CustOrder = 1
ORDER BY	c.CustomerID;