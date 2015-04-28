/* Using Pseudo-Constant Functions in Calculated Columns is Possible but Cumbersome.

Let's say you wanted to have an "OrderOpen" column which indicated whether an order
	was one of a list of statuses. Rather than hard-coding the statuses, you woudl
	prefer to use the pseudo-constant functions.
You can, but you have to wrap it in a scalar and if you want to perist it,
	you must use SCHEMABINDING, which introduces maintenance headaches.

*/

IF OBJECT_ID('CalcConstOrderStatusesCalcColumn') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesCalcColumn; END;
GO

IF OBJECT_ID('OrdersCalcColumnTest') IS NOT NULL BEGIN DROP TABLE OrdersCalcColumnTest; END;
GO

CREATE FUNCTION CalcConstOrderStatusesCalcColumn ()
RETURNS TABLE
AS
	RETURN
		SELECT
			1 AS OrderStatusCreated,
			2 AS OrderStatusAssigned,
			3 AS OrderStatusCompleted;
GO

CREATE TABLE OrdersCalcColumnTest
(
    OrderID int IDENTITY NOT NULL,
    OrderDate datetime,
    OrderStatusID int,
	OrderOpen AS
		(
			CASE
				WHEN
					EXISTS
					(
						SELECT		*
						FROM		dbo.CalcConstOrderStatusesCalcColumn()
						WHERE		OrderStatusID IN (OrderStatusCreated, OrderStatusAssigned)
					)
				THEN
					1
				ELSE
					0
			END
		)
);

/*

Msg 1046, Level 15, State 1, Line 13
Subqueries are not allowed in this context. Only scalar expressions are allowed.

*/

--------

IF OBJECT_ID('OrderIsOpen') IS NOT NULL BEGIN DROP FUNCTION OrderIsOpen; END;
GO

CREATE FUNCTION OrderIsOpen
(
	@OrderStatusID int
)
RETURNS int
AS
BEGIN
	RETURN
		CASE
			WHEN
				EXISTS
				(
					SELECT		*
					FROM		dbo.CalcConstOrderStatusesCalcColumn()
					WHERE		@OrderStatusID IN (OrderStatusCreated, OrderStatusAssigned)
				)
			THEN
				1
			ELSE
				0
		END
END
GO

IF OBJECT_ID('OrdersCalcColumnTest') IS NOT NULL BEGIN DROP TABLE OrdersCalcColumnTest; END;
GO

CREATE TABLE OrdersCalcColumnTest
(
    OrderID int IDENTITY NOT NULL,
    OrderDate datetime,
    OrderStatusID int,
	OrderOpen AS dbo.OrderIsOpen(OrderStatusID)
);

-- Success!

-------

IF OBJECT_ID('OrdersCalcColumnTest') IS NOT NULL BEGIN DROP TABLE OrdersCalcColumnTest; END;
GO

CREATE TABLE OrdersCalcColumnTest
(
    OrderID int IDENTITY NOT NULL,
    OrderDate datetime,
    OrderStatusID int,
	OrderOpen AS dbo.OrderIsOpen(OrderStatusID) PERSISTED 
);
GO

/*

Msg 4936, Level 16, State 1, Line 2
Computed column 'OrderOpen' in table 'OrdersCalcColumnTest' cannot be persisted because the column is non-deterministic.

*/

-------

IF OBJECT_ID('CalcConstOrderStatusesCalcColumn') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesCalcColumn; END;
GO

CREATE FUNCTION CalcConstOrderStatusesCalcColumn ()
RETURNS TABLE
WITH SCHEMABINDING
AS
	RETURN
		SELECT
			1 AS OrderStatusCreated,
			2 AS OrderStatusAssigned,
			3 AS OrderStatusCompleted;
GO

IF OBJECT_ID('OrderIsOpen') IS NOT NULL BEGIN DROP FUNCTION OrderIsOpen; END;
GO

CREATE FUNCTION OrderIsOpen
(
	@OrderStatusID int
)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN
	RETURN
		CASE
			WHEN
				EXISTS
				(
					SELECT		*
					FROM		dbo.CalcConstOrderStatusesCalcColumn()
					WHERE		@OrderStatusID IN (OrderStatusCreated, OrderStatusAssigned)
				)
			THEN
				1
			ELSE
				0
		END
END
GO

/*

Msg 1054, Level 15, State 6, Procedure OrderIsOpen, Line 15
Syntax '*' is not allowed in schema-bound objects.

*/

IF OBJECT_ID('OrderIsOpen') IS NOT NULL BEGIN DROP FUNCTION OrderIsOpen; END;
GO

CREATE FUNCTION OrderIsOpen
(
	@OrderStatusID int
)
RETURNS int
WITH SCHEMABINDING
AS
BEGIN
	RETURN
		CASE
			WHEN
				EXISTS
				(
					SELECT		1
					FROM		dbo.CalcConstOrderStatusesCalcColumn()
					WHERE		@OrderStatusID IN (OrderStatusCreated, OrderStatusAssigned)
				)
			THEN
				1
			ELSE
				0
		END
END
GO

IF OBJECT_ID('OrdersCalcColumnTest') IS NOT NULL BEGIN DROP TABLE OrdersCalcColumnTest; END;
GO

CREATE TABLE OrdersCalcColumnTest
(
    OrderID int IDENTITY NOT NULL,
    OrderDate datetime,
    OrderStatusID int,
	OrderOpen AS dbo.OrderIsOpen(OrderStatusID) PERSISTED 
);
GO

;WITH OrderList AS
(
	SELECT NULL AS OrderDate, NULL OrderStatusID WHERE 1 = 0
	UNION ALL SELECT getdate(), 1
	UNION ALL SELECT getdate()+1, 2
	UNION ALL SELECT getdate()+1, 3
	UNION ALL SELECT getdate()+2, 3
	UNION ALL SELECT getdate()+3, 3
)
INSERT INTO OrdersCalcColumnTest
(
	OrderDate, OrderStatusID
)
SELECT
	OrderDate, OrderStatusID
FROM	OrderList;


SELECT		*
FROM		OrdersCalcColumnTest;