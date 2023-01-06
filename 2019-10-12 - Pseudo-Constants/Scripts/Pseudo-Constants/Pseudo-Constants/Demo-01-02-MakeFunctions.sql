USE PseudoConstants;
GO

-- Scalar Function for ID, Hitting Table

IF OBJECT_ID('GetOrderStatusID') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusID; END;
GO

CREATE FUNCTION dbo.GetOrderStatusID
(
	@OrderStatus varchar(50)
)
RETURNS int
AS
	BEGIN
		RETURN
		(
			SELECT
				OrderStatusID
			FROM		OrderStatuses
			WHERE		OrderStatus = @OrderStatus
		);
	END
GO

-- Scalar Function for ID, Values in Code

IF OBJECT_ID('GetOrderStatusIDNoIO') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusIDNoIO; END;
GO

CREATE FUNCTION GetOrderStatusIDNoIO
(
	@OrderStatus varchar(50)
)
RETURNS int
AS
	BEGIN
		RETURN
			(
				SELECT
						OrderStatusID
				FROM		(
								SELECT NULL AS OrderStatusID, NULL AS OrderStatus WHERE 1 = 0 UNION ALL
								SELECT 1, 'Created' UNION ALL
								SELECT 2, 'Assigned'
							) AS OrderStatuses
				WHERE		OrderStatus = @OrderStatus
			);
	END
GO

-- Inline Function, Values in Code

IF OBJECT_ID('GetOrderStatuses') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatuses; END;
GO

CREATE FUNCTION GetOrderStatuses ()
RETURNS TABLE
AS
	RETURN
		SELECT NULL AS OrderStatusID, NULL AS OrderStatus WHERE 1 = 0 UNION ALL
		SELECT 1, 'Created' UNION ALL
		SELECT 2, 'Assigned' UNION ALL
		SELECT 3, 'Completed';
GO

-- Pseudo-Constant (Function)

IF OBJECT_ID('CalcConstOrderStatuses') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatuses; END;
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

-- Pseudo-Constant (View)

IF OBJECT_ID('vOrderStatuses') IS NOT NULL BEGIN DROP VIEW vOrderStatuses; END;
GO

CREATE VIEW vOrderStatuses
AS
SELECT
			1 AS OrderStatusCreated,
			2 AS OrderStatusAssigned,
			3 AS OrderStatusCompleted;
GO

-- Specialized List in Code

IF OBJECT_ID('GetOrderStatusesOpen') IS NOT NULL BEGIN DROP FUNCTION GetOrderStatusesOpen; END;
GO

CREATE FUNCTION GetOrderStatusesOpen ()
RETURNS TABLE
AS
	RETURN
		SELECT NULL AS OrderStatusID, NULL AS OrderStatus WHERE 1 = 0 UNION ALL
		SELECT 1, 'Created' UNION ALL
		SELECT 2, 'Assigned';
GO
