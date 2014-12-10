-- Automatically Create Pseudo-Constant Function from Underlying Table

-- Must use two separate statements.

-- Be careful that textual IDs don't have special characters.

DECLARE
	@DropFunc varchar(max),
	@CreateFunc varchar(max);
SELECT

	@DropFunc = 'IF OBJECT_ID(''CalcConstOrderStatusesAutoCreate'') IS NOT NULL BEGIN DROP FUNCTION CalcConstOrderStatusesAutoCreate; END;',

	@CreateFunc = 

'CREATE FUNCTION CalcConstOrderStatusesAutoCreate ()
RETURNS TABLE
AS
	RETURN
		SELECT
			' +
			STUFF
			(
				(
					SELECT
						', ' + CONVERT(varchar(50),OrderStatusID) + char(9) + ' AS OrderStatus' + OrderStatus
					FROM		OrderStatuses
					FOR XML PATH(''), TYPE
				).value('.','varchar(max)'),
				1,
				2,
				''
			) + ';';

/*

DECLARE
	@Combo varchar(max);
SELECT
	@Combo = @DropFunc + 'GO' + CHAR(13) + CHAR(10) + @CreateFunc;
EXEC (@Combo);

Msg 102, Level 15, State 1, Line 1
Incorrect syntax near 'GO'.
Msg 111, Level 15, State 1, Line 2
'CREATE FUNCTION' must be the first statement in a query batch.

*/

EXEC(@DropFunc);
EXEC(@CreateFunc);

SELECT
	o.*
FROM		dbo.CalcConstOrderStatusesAutoCreate() os
CROSS JOIN	Orders AS o
WHERE		o.OrderStatusID IN (os.OrderStatusCreated,os.OrderStatusAssigned);