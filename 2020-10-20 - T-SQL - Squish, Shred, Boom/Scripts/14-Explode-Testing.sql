USE Test;
GO

CREATE OR ALTER FUNCTION CalcTestComplex
(
	@n1 int,
	@n2 int,
	@text varchar(50)
)
RETURNS TABLE
RETURN
(
	SELECT
		CalcResult = 
			CASE
				WHEN @n1 < 10 THEN
					'Break many things. '
				WHEN @text IS NULL THEN
					'Break some things. '
				WHEN @n2 > 10 THEN
					'Break only one thing. '
				ELSE
					'Break nothing. '
			END
			+
			CASE
				WHEN @n2 IS NULL THEN
					'Do the good thing. '
				WHEN LEN(@text) > 0 THEN
					'Do the medium thing. '
				WHEN @n1 > 10 THEN
					'Do the bad thing. '
				ELSE
					'What should I do?'
			END
);

GO

WITH nums AS
(
	SELECT n = CONVERT(int,NULL)
	UNION ALL SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 100
), txt AS
(
	SELECT t = ''
	UNION ALL SELECT NULL UNION ALL SELECT 'This is a test.'
)
SELECT		*
FROM		nums n1
CROSS JOIN	nums n2
CROSS JOIN	txt t
OUTER APPLY	CalcTestComplex
			(
				n1.n,
				n2.n,
				t.t
			);