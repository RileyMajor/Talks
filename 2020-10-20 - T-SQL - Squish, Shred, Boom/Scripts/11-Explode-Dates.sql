USE Test;

/*

SELECT		TOP 100 *
FROM		Orders;

*/

/*

	List every date between April 20 and April 30, 2019, inclusive, with all dates present, even if no orders.

*/

SELECT
	*
FROM		Orders o
WHERE		o.OrderDate >= TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190420'),'-05:00')
AND			o.OrderDate < DATEADD(DAY,1,TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190430'),'-05:00'))
ORDER BY	o.OrderDate;

SELECT
	CONVERT(date,o.OrderDate),
	OrdrerCount = COUNT(*)
FROM		Orders o
WHERE		o.OrderDate >= TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190420'),'-05:00')
AND			o.OrderDate < DATEADD(DAY,1,TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190430'),'-05:00'))
GROUP BY	CONVERT(date,o.OrderDate)
ORDER BY	CONVERT(date,o.OrderDate);

SELECT
	*
FROM		(
				SELECT
					FirstDate = CONVERT(date,'20190420')
			) AS c
CROSS JOIN	(
				SELECT n = 1 UNION ALL SELECT 2 UNION ALL SELECT 3
				UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
				UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
				UNION ALL SELECT 10 UNION ALL SELECT 11
			) AS Numbers;


SELECT
	*
FROM		(
				SELECT
					FirstDate = CONVERT(date,'20190420')
			) AS c
CROSS JOIN	(
				SELECT n = 1 UNION ALL SELECT 2 UNION ALL SELECT 3
				UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
				UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
				UNION ALL SELECT 10 UNION ALL SELECT 11
			) AS Numbers
CROSS APPLY	(
				SELECT
					DateCalc = DATEADD(DAY,n-1,FirstDate)
			) AS d;

SELECT
	*
FROM		(
				SELECT
					FirstDate = CONVERT(date,'20190420')
			) AS c
CROSS JOIN	(
				SELECT n = 1 UNION ALL SELECT 2 UNION ALL SELECT 3
				UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
				UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
				UNION ALL SELECT 10 UNION ALL SELECT 11
			) AS Numbers
CROSS APPLY	(
				SELECT
					DateCalc = DATEADD(DAY,n-1,FirstDate)
			) AS d
LEFT JOIN	(
				SELECT
					OrderDate = CONVERT(date,o.OrderDate),
					OrdrerCount = COUNT(*)
				FROM		Orders o
				WHERE		o.OrderDate >= TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190420'),'-05:00')
				AND			o.OrderDate < DATEADD(DAY,1,TODATETIMEOFFSET(CONVERT(datetimeoffset,'20190430'),'-05:00'))
				GROUP BY	CONVERT(date,o.OrderDate)
			) AS OrderCounts
ON			OrderCounts.OrderDate = d.DateCalc;