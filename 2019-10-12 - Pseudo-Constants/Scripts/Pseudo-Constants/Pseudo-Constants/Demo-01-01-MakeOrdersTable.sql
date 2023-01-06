USE PseudoConstants;
GO

SET STATISTICS IO ON;

-- Clear out all remnants of previous demos. (Order matters; I didn't test exhaustively. Just run it multiple times if you get errors.)

IF OBJECT_ID('OrdersCalcColumnTest') IS NOT NULL BEGIN DROP TABLE OrdersCalcColumnTest; END;
IF OBJECT_ID('OrderIsOpen') IS NOT NULL BEGIN DROP FUNCTION OrderIsOpen; END;
IF OBJECT_ID('CalcConstOrderStatusesSchemaBound') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesSchemaBound; END;
IF OBJECT_ID('vOrdersOpen') IS NOT NULL BEGIN DROP VIEW vOrdersOpen; END;
IF OBJECT_ID('vOrderStatusesSchemaBound') IS NOT NULL BEGIN DROP VIEW vOrderStatusesSchemaBound; END;
IF OBJECT_ID('CalcConstOrderStatusesCalcColumn') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesCalcColumn; END;
IF OBJECT_ID('GetOrderStatusID') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusID; END;
IF OBJECT_ID('CalcConstOrderStatuses') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatuses; END;
IF OBJECT_ID('GetOrderStatusIDNoIO') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusIDNoIO; END;
IF OBJECT_ID('GetOrderStatuses') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatuses; END;
IF OBJECT_ID('GetOrderStatusesOpen') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusesOpen; END;
IF OBJECT_ID('vOrderStatuses') IS NOT NULL BEGIN DROP VIEW vOrderStatuses; END;
IF OBJECT_ID('Orders') IS NOT NULL BEGIN DROP TABLE Orders; END;
IF OBJECT_ID('OrderStatuses') IS NOT NULL BEGIN DROP TABLE OrderStatuses; END;

-- Create and populate OrderStatuses table. This should be nearly instant.

CREATE TABLE OrderStatuses
(
    OrderStatusID int PRIMARY KEY CLUSTERED,
    OrderStatus varchar(50),
	OrderStatusIsOpen bit
);

INSERT INTO OrderStatuses
(
	OrderStatusID,
    OrderStatus,
	OrderStatusIsOpen
)
SELECT 1, 'Created', 1 UNION ALL
SELECT 2, 'Assigned', 1 UNION ALL
SELECT 3, 'Completed', 0;

-- Create and populate Orders table. This will take about 30 seconds for 10 million rows.

CREATE TABLE Orders
(
    OrderID int IDENTITY NOT NULL,
    OrderDate datetime,
    OrderStatusID int
);

WITH BaseData AS
(
	SELECT 1 AS inCounter UNION ALL
	SELECT 2 UNION ALL
	SELECT 3 UNION ALL
	SELECT 4 UNION ALL
	SELECT 5 UNION ALL
	SELECT 6 UNION ALL
	SELECT 7 UNION ALL
	SELECT 8 UNION ALL
	SELECT 9 UNION ALL
	SELECT 10
), Exploder AS
(
	SELECT
		ABS(CHECKSUM(NEWID())) AS RandomInt
	FROM		BaseData AS t1
	CROSS JOIN	BaseData AS t2
	CROSS JOIN	BaseData AS t3
	CROSS JOIN	BaseData AS t4
	CROSS JOIN	BaseData AS t5
	CROSS JOIN	BaseData AS t6
	CROSS JOIN	BaseData AS t7
--	CROSS JOIN	BaseData AS t8
), ModulatedRandoms AS
(
	SELECT
		RandomInt % 10000 AS Random10k,
		RandomInt % 365 AS Random365
	FROM		Exploder
), OrderData AS
(
	SELECT
		DATEADD(dd, Random365, getdate()-365) AS OrderDate,
		CASE
			WHEN Random10k > 1 THEN 3
			WHEN Random10k > 0 THEN 2
			ELSE 1
		END AS OrderStatusID
	FROM		ModulatedRandoms
)
INSERT INTO Orders
(
	OrderDate, OrderStatusID
)
SELECT
	OrderDate, OrderStatusID
FROM		OrderData;

IF OBJECT_ID('IDX_OrderStatus') IS NOT NULL BEGIN DROP INDEX Orders.IDX_OrderStatus; END;

-- Use this index to show how all of the queries perform pretty much the same even using pseudo-constants.
-- This will take about 20 seconds.
CREATE INDEX IDX_OrderStatus ON Orders(OrderStatusID) INCLUDE (OrderID);

-- Use these indexes to highlight the different performance using scalar functions in the WHERE clause.
--CREATE INDEX IDX_OrderStatus ON Orders(OrderStatusID);
--CREATE CLUSTERED INDEX IDX_OrderStatus ON Orders(OrderStatusID);

-- Show the distribution of status types and dates.
SELECT
	OrderStatusID,
	COUNT(*) AS StatusCount,
	COUNT(DISTINCT OrderDate) AS StatusOrderDateCount
FROM		Orders
GROUP BY	OrderStatusID;