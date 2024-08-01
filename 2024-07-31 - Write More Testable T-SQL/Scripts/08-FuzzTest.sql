WITH		Texts AS
(
	SELECT TextVal = 'Test Company' UNION ALL SELECT 'Really Really Really Really Really Really Really Long Name' UNION ALL SELECT NULL UNION ALL SELECT ''
),			Numbers AS
(
	SELECT NumVal = 0 UNION ALL SELECT 1 UNION ALL SELECT 100 --UNION ALL SELECT -1
),			Bits AS
(
	SELECT	BitVal = CONVERT(bit,0) UNION ALL SELECT CONVERT(bit,1) UNION ALL SELECT NULL
),			Dates AS
(
	SELECT DateVal = '2024-07-31' UNION ALL SELECT '2024-07-30' UNION ALL SELECT '' UNION ALL SELECT NULL
)
SELECT		*
FROM		Texts AS CustNames
CROSS JOIN	Numbers AS NumLeadingChars
CROSS JOIN	Numbers AS NumTrailingChars
CROSS JOIN	Bits AS FunkyTuesdays
CROSS JOIN	Dates AS Today
CROSS APPLY	CalcFunnyName 
			(
				/*	@text				varchar(50)		*/	CustNames.TextVal			,
				/*	@NumLeadingChars	int				*/	NumLeadingChars.NumVal		,
				/*	@NumTrailingChars	int				*/	NumTrailingChars.NumVal		,
				/*	@FunkyTuesdays		bit				*/	FunkyTuesdays.BitVal		,
				/*	@Today				datetime		*/	Today.DateVal
			) AS FunnyName
ORDER BY	CustNames.TextVal			,
			NumLeadingChars.NumVal		,
			NumTrailingChars.NumVal		,
			FunkyTuesdays.BitVal		,
			Today.DateVal				;

/* The error is intentional, to show the test's effectiveness. Remove the "-1" value and it will no longer error. */