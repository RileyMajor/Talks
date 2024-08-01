DROP FUNCTION IF EXISTS CalcNameIsSuperFunny;
GO
CREATE FUNCTION CalcNameIsSuperFunny 
(	
	@TestName varchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		IsSuperFunny =
			CONVERT(bit,CASE WHEN @TestName NOT LIKE 'y%' THEN 1 ELSE 0 END)
)
GO
