USE PseudoConstants;
GO

SET STATISTICS IO ON;

IF OBJECT_ID('Orders') IS NOT NULL BEGIN DROP TABLE Orders; END;
IF OBJECT_ID('OrderStatuses') IS NOT NULL BEGIN DROP TABLE OrderStatuses; END;

CREATE TABLE OrderStatuses
(
    OrderStatusID int,
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
		DATEADD(dd, Random365, CONVERT(datetime,'2012-01-01')) AS OrderDate,
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