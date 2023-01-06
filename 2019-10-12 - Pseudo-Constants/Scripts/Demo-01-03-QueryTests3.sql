USE PseudoConstants;
GO

SET STATISTICS IO ON;

---------------------------------------------
-- Example of mistake handling
---------------------------------------------

-- Correct query.

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (1,2);
GO

-- Example of mistake

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (1,0);
GO

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (dbo.GetOrderStatusID('Created'), dbo.GetOrderStatusID('Asigned'));
GO

SELECT
	o.OrderID
FROM		Orders AS o
JOIN		OrderStatuses AS os
ON			o.OrderStatusID = os.OrderStatusID
WHERE		os.OrderStatus IN ('Created','Asigned');
GO

SELECT
	o.OrderID, o.OrderDate
FROM		dbo.CalcConstOrderStatuses() os
CROSS JOIN	Orders AS o
WHERE		o.OrderStatusID IN (os.OrderStatusCreated, os.OrderStatusAsigned);
GO

---------------------------------------------
-- Example of abysmal performance
---------------------------------------------

-- Canonical Pseduo-Constant Method (~2k reads)
SELECT
	o.OrderID, o.OrderDate
FROM		dbo.CalcConstOrderStatuses() os
CROSS JOIN	Orders AS o
WHERE		o.OrderStatusID IN (os.OrderStatusCreated, os.OrderStatusAssigned);

-- Scalar Function in WHERE clause
SELECT
	o.OrderID, o.OrderDate
FROM		Orders AS o
WHERE		o.OrderStatusID IN (dbo.GetOrderStatusID('Created'), dbo.GetOrderStatusID('Assigned'));

-- Ouch. 9 minutes. ~31k reads.
	-- Table 'Orders'. Scan count 1, logical reads 30960, physical reads 791, read-ahead reads 28179, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

-- Scalar Function in WHERE clause, but Remove IO from Lookups for better (but still bad) performance.
SELECT
	o.OrderID, o.OrderDate
FROM		Orders AS o
WHERE		o.OrderStatusID IN (dbo.GetOrderStatusIDNoIO('Created'), dbo.GetOrderStatusIDNoIO('Assigned'));

--	Still ~31k reads. 50 seconds in test. Starts returning results more quickly.