USE PseudoConstants;
GO

SET STATISTICS IO ON;

PRINT '---------------------------
Hard-coded Numbers'

-- Hard-coded Numbers

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (1,2);

-- Hard-coded Numbers End

PRINT '---------------------------
Hard-coded Variables'

-- Hard-coded Variables

DECLARE
	@OrderStatusCreated int,
	@OrderStatusAssigned int;
SELECT
	@OrderStatusCreated = 1,
	@OrderStatusAssigned = 2;
SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (@OrderStatusCreated, @OrderStatusAssigned);

-- Hard-coded Variables End

PRINT '---------------------------
Hard-coded Variables with Optimize'

-- Hard-coded Variables with Optimize

DECLARE
	@OrderStatusCreatedOptimized int,
	@OrderStatusAssignedOptimized int;
SELECT
	@OrderStatusCreatedOptimized = 1,
	@OrderStatusAssignedOptimized = 2;
SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (@OrderStatusCreatedOptimized, @OrderStatusAssignedOptimized)
OPTION		(OPTIMIZE FOR (@OrderStatusCreatedOptimized = 1, @OrderStatusAssignedOptimized = 2));

-- Hard-coded Variables with Optimize End

PRINT '---------------------------
Derived Variables'

-- Derived Variables

DECLARE
	@OrderStatusCreatedFunc int,
	@OrderStatusAssignedFunc int;
SELECT
	@OrderStatusCreatedFunc = dbo.GetOrderStatusID('Created'),
	@OrderStatusAssignedFunc = dbo.GetOrderStatusID('Assigned');
SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (@OrderStatusCreatedFunc, @OrderStatusAssignedFunc);

-- Derived Variables End

PRINT '---------------------------
Scalar in WHERE Clause'

-- Scalar in WHERE Clause

-- In this very simple example, with a covering index, the performance is similar.
-- Include even a single field which isn't in the index and the performance becomes abysmal.

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (dbo.GetOrderStatusID('Created'), dbo.GetOrderStatusID('Assigned'));

-- Scalar in WHERE Clause End

PRINT '---------------------------
No Touch Scalar in WHERE Clause'

-- No Touch Scalar in WHERE Clause

SELECT
	o.OrderID
FROM		Orders AS o
WHERE		o.OrderStatusID IN (dbo.GetOrderStatusIDNoIO('Created'), dbo.GetOrderStatusIDNoIO('Assigned'));

-- No Touch Scalar in WHERE Clause End

PRINT '---------------------------
Simple JOIN with Hard-Coded List'

-- Simple JOIN with Hard-Coded List

SELECT
	o.OrderID
FROM		Orders AS o
JOIN		OrderStatuses AS os
ON			o.OrderStatusID = os.OrderStatusID
WHERE		os.OrderStatus IN ('Created','Assigned');

-- Simple JOIN with Hard-Coded List End

PRINT '---------------------------
Simple JOIN with Specialized Field'

-- Simple JOIN with Specialized Field

SELECT
	o.OrderID
FROM		Orders AS o
JOIN		OrderStatuses AS os
ON			o.OrderStatusID = os.OrderStatusID
WHERE		os.OrderStatusIsOpen = 1;

-- Simple JOIN with Specialized Field End

PRINT '---------------------------
Table Function'

-- Table Function

SELECT
	o.OrderID
FROM		Orders AS o
JOIN		dbo.GetOrderStatuses() AS os
ON			o.OrderStatusID = os.OrderStatusID
WHERE		os.OrderStatus IN ('Created','Assigned');

-- Table Function End

PRINT '---------------------------
Pseudo-Constants (Syntax #1)'

-- Pseudo-Constants (Syntax #1)

SELECT
	o.OrderID
FROM		Orders AS o
CROSS APPLY	dbo.CalcConstOrderStatuses() os
WHERE		o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);

-- Pseudo-Constants (Syntax #1) End

PRINT '---------------------------
Pseudo-Constants (Syntax #2)'

-- Pseudo-Constants (Syntax #2)

SELECT
	o.OrderID
FROM		dbo.CalcConstOrderStatuses() os
JOIN		Orders AS o
ON			o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);

-- Pseudo-Constants (Syntax #2) End

PRINT '---------------------------
Pseudo-Constants (Syntax #3)'

-- Pseudo-Constants (Syntax #3)

SELECT
	o.OrderID
FROM		dbo.CalcConstOrderStatuses() os
CROSS JOIN	Orders AS o
WHERE		o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);

-- Pseudo-Constants (Syntax #3) End

PRINT '---------------------------
Pseudo-Constants (View)'

-- Pseudo-Constants (View)

SELECT
	o.OrderID
FROM		vOrderStatuses os
JOIN		Orders AS o
ON			o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);

-- Pseudo-Constants (View) End

PRINT '---------------------------
Specialized Table Function';

-- Specialized Table Function

SELECT
	o.OrderID
FROM		dbo.GetOrderStatusesOpen() os
JOIN		Orders o
ON			o.OrderStatusID = os.OrderStatusID;

-- Specialized Table Function End