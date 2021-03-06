USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @n int = 1234;

PRINT CHAR(13) + CHAR(10) + '**************************' + 'UNIONs';

WITH b10 AS
(
	SELECT n = 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
	UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
)
SELECT
	TOP (@n)
	n = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
FROM		b10
CROSS JOIN	b10 AS b100
CROSS JOIN	b10 AS b1000
CROSS JOIN	b10 AS b10000
CROSS JOIN	b10 AS b100000
CROSS JOIN	b10 AS b1000000;

PRINT CHAR(13) + CHAR(10) + '**************************' + 'String Split';

WITH b10 AS
(
	SELECT * FROM string_split('1,2,3,4,5,6,7,8,9,10',',')
)
SELECT
	TOP (@n)
	n = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
FROM		b10
CROSS JOIN	b10 AS b100
CROSS JOIN	b10 AS b1000
CROSS JOIN	b10 AS b10000
CROSS JOIN	b10 AS b100000
CROSS JOIN	b10 AS b1000000;

PRINT CHAR(13) + CHAR(10) + '**************************' + 'JSON';

WITH b10 AS
(
	SELECT [key] FROM OPENJSON(N'[1,2,3,4,5,6,7,8,9,10]')
)
SELECT
	TOP (@n)
	n = ROW_NUMBER() OVER (ORDER BY (SELECT 1))
FROM		b10
CROSS JOIN	b10 AS b100
CROSS JOIN	b10 AS b1000
CROSS JOIN	b10 AS b10000
CROSS JOIN	b10 AS b100000
CROSS JOIN	b10 AS b1000000;

