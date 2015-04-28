/*  Using Pseudo-Constant Functions in Filtered Indexes seems Impossible.

Let's say you wanted to index only open orders.
	You would have to hard-code the numeric values as the pseudo-constant functons cannot be referenced.

*/

USE PseudoConstants;
GO

/*

In case you are running this separately, you will need these base table and function...

CREATE TABLE Orders (OrderID int IDENTITY, OrderStatus int)
GO
CREATE FUNCTION CalcConstOrderStatuses ()
RETURNS TABLE
AS
	RETURN
		SELECT
			1 AS OrderStatusCreated,
			2 AS OrderStatusAssigned,
			3 AS OrderStatusCompleted;
GO

*/

IF OBJECT_ID('OrderIsOpen') IS NOT NULL BEGIN DROP FUNCTION OrderIsOpen; END;
GO

CREATE FUNCTION OrderIsOpen(@OrderStatus int)
RETURNS int
AS
BEGIN
  RETURN
  isNull(
      (
         SELECT 1
          FROM dbo.CalcConstOrderStatuses()
          WHERE @OrderStatus IN (OrderStatusCreated, OrderStatusAssigned)
      )
    ,0)
END
GO

CREATE NONCLUSTERED INDEX OrderStatusOpen ON Orders(OrderStatusID) INCLUDE (OrderID)
WHERE EXISTS (SELECT * FROM dbo.CalcConstOrderStatuses() WHERE OrderStatusID IN (OrderStatusCreated, OrderStatusAssigned));
GO
/*
Msg 156, Level 15, State 1, Line 2
Incorrect syntax near the keyword 'EXISTS'.
*/

CREATE NONCLUSTERED INDEX OrderStatusOpen ON Orders(OrderStatusID) INCLUDE (OrderID)
WHERE dbo.OrderIsOpen(OrderStatusID) = 1;
GO
/*
Msg 10735, Level 15, State 1, Line 2
Incorrect WHERE clause for filtered index 'OrderStatusOpen' on table 'Orders'.
*/

CREATE NONCLUSTERED INDEX OrderStatusOpen ON Orders(OrderStatusID) INCLUDE (OrderID)
WHERE OrderStatus IN
  (
      (SELECT OrderStatusCreated FROM dbo.CalcConstOrderStatuses()),
      (SELECT OrderStatusAssigned FROM dbo.CalcConstOrderStatuses())
  );
GO
/*

Msg 1046, Level 15, State 1, Line 4
Subqueries are not allowed in this context. Only scalar expressions are allowed.
Msg 102, Level 15, State 1, Line 6
Incorrect syntax near ')'.

*/


IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'OrderStatusOpen' AND object_id = OBJECT_ID('Orders')) BEGIN DROP INDEX OrderStatusOpen ON Orders; END;
GO

CREATE NONCLUSTERED INDEX OrderStatusOpen ON Orders(OrderStatusID) INCLUDE (OrderID)
WHERE OrderStatusID IN
  (
      1,
      2
  );
GO