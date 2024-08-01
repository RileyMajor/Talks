USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/*

	Expand the flattened customer phones into one phone per row.

*/

DECLARE
	@CustInfo TABLE
	(
		CustomerID int,
		Phone1 varchar(100),
		Phone2 varchar(100)
	);
INSERT INTO @CustInfo
	VALUES
		(1, '555-1212', '555-1213'),
		(2, '555-1214', '555-1215'),
		(3, '555-1216', '555-1217');

SELECT			/* UNION Method */
	CustomerID,
	Phone = Phone1
FROM		@CustInfo
UNION ALL
SELECT
	CustomerID,
	Phone2
FROM		@CustInfo;


SELECT			/* CROSS JOIN */
	CustomerID,
	Phone =
		CASE
			WHEN Exploder.n = 1 THEN
				Phone1
			ELSE
				Phone2
		END
FROM		@CustInfo
CROSS JOIN	(SELECT n = 1 UNION ALL SELECT 2) AS Exploder;