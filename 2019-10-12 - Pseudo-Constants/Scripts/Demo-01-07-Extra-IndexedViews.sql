/* Using Pseudo-Constant Functions in Indexed Views seems Impossible.

Perhaps you wanted to persist a view of your open orders with various calculations.
	You might want to reference your pseudo-constants to avoid hard-coding your status values.
	I was unable to get this to work.

*/

USE PseudoConstants;
GO

-- Pseudo-Constants in Indexed View (Psuedo-Constant *Function*)

IF OBJECT_ID('CalcConstOrderStatusesSchemaBound') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesSchemaBound; END;
GO

IF OBJECT_ID('vOrdersOpen') IS NOT NULL BEGIN DROP VIEW vOrdersOpen; END;
GO

CREATE FUNCTION CalcConstOrderStatusesSchemaBound ()
RETURNS TABLE
WITH SCHEMABINDING
AS
	RETURN
		SELECT
			1 AS OrderStatusCreated,
			2 AS OrderStatusAssigned,
			3 AS OrderStatusCompleted;
GO

CREATE VIEW vOrdersOpen WITH SCHEMABINDING
AS
	SELECT
		o.OrderID,
		o.OrderDate
		FROM		dbo.CalcConstOrderStatusesSchemaBound() os
		CROSS JOIN	dbo.Orders AS o
		WHERE		o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);
GO

CREATE UNIQUE CLUSTERED INDEX IDX_vOrdersOpen ON vOrdersOpen (OrderID);
GO

/*

Msg 10129, Level 16, State 1, Line 41
Cannot create index on view "PseudoConstants.dbo.vOrdersOpen" because it references the inline or multistatement table-valued function "dbo.CalcConstOrderStatusesSchemaBound". Consider expanding the function definition by hand in the view definition, or not indexing the view.

*/

---------------------------------------------------

-- Pseudo-Constants in Indexed View (Psuedo-Constant *View*)

IF OBJECT_ID('vOrderStatusesSchemaBound') IS NOT NULL BEGIN DROP VIEW vOrderStatusesSchemaBound; END;
GO

IF OBJECT_ID('vOrdersOpen') IS NOT NULL BEGIN DROP VIEW vOrdersOpen; END;
GO

CREATE VIEW vOrderStatusesSchemaBound WITH SCHEMABINDING
AS
	SELECT
		1 AS OrderStatusCreated,
		2 AS OrderStatusAssigned,
		3 AS OrderStatusCompleted;
GO

CREATE VIEW vOrdersOpen WITH SCHEMABINDING
AS
	SELECT
		o.OrderID,
		o.OrderDate
		FROM		dbo.vOrderStatusesSchemaBound os
		CROSS JOIN	dbo.Orders AS o
		WHERE		o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);
GO

CREATE UNIQUE CLUSTERED INDEX IDX_vOrdersOpen ON vOrdersOpen (OrderID);
GO

/*

Msg 1937, Level 16, State 1, Line 79
Cannot create index on view 'PseudoConstants.dbo.vOrdersOpen' because it references another view 'dbo.vOrderStatusesSchemaBound'. Consider expanding referenced view's definition by hand in indexed view definition.

*/