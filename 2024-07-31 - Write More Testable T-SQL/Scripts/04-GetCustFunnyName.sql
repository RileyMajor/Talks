DROP FUNCTION IF EXISTS GetCustFunnyName
GO
CREATE FUNCTION GetCustFunnyName
(	
	@CustID		int			,
	@Today		datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		FunnyName.*,
		SuperFunny.*
	FROM		CustList c
	CROSS APPLY	CalcFunnyName
				(
					/*	@text				varchar(50)		*/	c.CustName		,
					/*	@NumLeadingChars	int				*/	c.FirstChars	,
					/*	@NumTrailingChars	int				*/	c.LastChars		,
					/*	@FunkyTuesdays		bit				*/	c.FunkyTuesdays	,
					/*	@Today				datetime		*/	@Today
				) AS FunnyName
	CROSS APPLY	CalcNameIsSuperFunny
				(
					/*	@TestName			varchar(50)		*/	FunnyName.FunnyName
				) AS SuperFunny
	WHERE		c.CustID = @CustID
)
GO
