USE PseudoConstants;
GO

SET NOCOUNT ON;
SET STATISTICS IO ON;

DECLARE @SpecialDates TABLE (SpecialDate datetime);
INSERT INTO @SpecialDates (SpecialDate) VALUES ('2012-01-07');
INSERT INTO @SpecialDates (SpecialDate) VALUES ('2012-10-03');

SET NOCOUNT OFF;
SET STATISTICS IO ON;

PRINT 'JOIN using Hard-coded Numbers';

SELECT
	OpenOrdersByDate.*
FROM		@SpecialDates AS s
JOIN		(
				SELECT		o.OrderDate,
							COUNT(*) AS OrderCount,
							MAX(OrderID) AS MaxOrderID
				FROM		Orders AS o
				WHERE		o.OrderStatusID IN (1,2)
				GROUP BY	o.OrderDate
			) OpenOrdersByDate
ON			OpenOrdersByDate.OrderDate = s.SpecialDate;

/*

You can't use JOIN if you are referring to fields from previous tables (or table constructs).

DECLARE @SpecialDates TABLE (SpecialDate datetime);
INSERT INTO @SpecialDates (SpecialDate) VALUES ('2012-01-07');
INSERT INTO @SpecialDates (SpecialDate) VALUES ('2012-10-03');

SELECT
	OpenOrdersByDate.*
FROM		dbo.CalcConstOrderStatuses() AS os
CROSS JOIN	@SpecialDates s
JOIN		(
				SELECT		OrderDate,
							COUNT(*) AS OrderCount,
							MAX(OrderID) AS MaxOrderID
				FROM		Orders
				WHERE		OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned)
				GROUP BY	OrderDate
			) AS OpenOrdersByDate
ON			OrderDate = SpecialDate;

Msg 4104, Level 16, State 1, Line 28
The multi-part identifier "os.OrderStatusAssigned" could not be bound.
Msg 4104, Level 16, State 1, Line 28
The multi-part identifier "os.OrderStatusCreated" could not be bound.

*/

PRINT 'CROSS APPLY using Hard-coded Numbers';

SELECT
	s.SpecialDate,
	OpenOrdersByDate.*
FROM		@SpecialDates AS s
CROSS APPLY	(
				SELECT		COUNT(*) AS OrderCount,
							MAX(o.OrderID) AS MaxOrderID
				FROM		Orders AS o
				WHERE		o.OrderStatusID IN (1,2)
				AND			o.OrderDate = s.SpecialDate
			) AS OpenOrdersByDate;

PRINT 'CROSS APPLY Referencing Pseudo-Constants From Outside';

SELECT
	s.SpecialDate,
	OpenOrdersByDate.*
FROM		dbo.CalcConstOrderStatuses() AS os
CROSS JOIN	@SpecialDates s
CROSS APPLY	(
				SELECT		COUNT(*) AS OrderCount,
							MAX(o.OrderID) AS MaxOrderID
				FROM		Orders AS o
				WHERE		OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned)
				AND			o.OrderDate = s.SpecialDate
			) AS OpenOrdersByDate;

PRINT 'CROSS APPLY Referencing Pseudo-Constants Inside';

-- The optimizer is able to leverage the index on Orders when the pseudo-constants are inside the CROSS APPLY.
-- Unfortunately, that means that for best performance, you might end up reproducing the pseudo-constant application multiple times in a single statement

SELECT
	s.SpecialDate,
	OpenOrdersByDate.*
FROM		@SpecialDates s
CROSS APPLY	(
				SELECT		COUNT(*) AS OrderCount,
							MAX(o.OrderID) AS MaxOrderID
				FROM		dbo.CalcConstOrderStatuses() AS os
				CROSS JOIN	Orders AS o
				WHERE		OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned)
				AND			o.OrderDate = s.SpecialDate
			) AS OpenOrdersByDate;