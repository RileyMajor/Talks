USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

/*

	List customers who have a phone in the block list.

*/

DECLARE
	@CustInfo TABLE
	(
		CustomerID int,
		Phone1 varchar(100),
		Phone2 varchar(100)
	);
INSERT INTO @CustInfo
	(
		CustomerID,
		Phone1,
		Phone2
	)
VALUES
	(1, '555-1212', '555-1213'),
	(2, '555-1214', '555-1215'),
	(3, '555-1216', '555-1217'),
	(4, '555-1218', '555-1219'),
	(5, '555-1220', '555-1221');

DECLARE
	@BlockList TABLE
	(
		Phone varchar(100),
		BlockExpires datetime
	);
INSERT INTO @BlockList
	(
		Phone,
		BlockExpires
	)
VALUES
	('555-1212',getdate()+1),
	('555-1217',getdate()+1),
	('555-1219',getdate()-1),
	('555-1220',getdate()+1),
	('555-1221',getdate()+1);

PRINT CHAR(13) + CHAR(10) + '********************' + 'Quadruple IN';

SELECT			/* Quadruple IN */
	CustomerID,
	Phone1Block = CASE WHEN Phone1 IN (SELECT Phone FROM @BlockList WHERE BlockExpires > getdate()) THEN 1 ELSE 0 END,
	Phone2Block = CASE WHEN Phone2 IN (SELECT Phone FROM @BlockList WHERE BlockExpires > getdate()) THEN 1 ELSE 0 END
FROM		@CustInfo
WHERE		Phone1 IN (SELECT Phone FROM @BlockList WHERE BlockExpires > getdate())
OR			Phone2 IN (SELECT Phone FROM @BlockList WHERE BlockExpires > getdate());

PRINT CHAR(13) + CHAR(10) + '********************' + 'CTE';

WITH CurrentBlocks AS		/* CTE */
(
	SELECT
		Phone
	FROM		@BlockList
	WHERE		BlockExpires > getdate()
)
SELECT			
	CustomerID,
	Phone1Block = CASE WHEN Phone1 IN (SELECT Phone FROM CurrentBlocks) THEN 1 ELSE 0 END,
	Phone2Block = CASE WHEN Phone2 IN (SELECT Phone FROM CurrentBlocks) THEN 1 ELSE 0 END
FROM		@CustInfo
WHERE		Phone1 IN (SELECT Phone FROM CurrentBlocks)
OR			Phone2 IN (SELECT Phone FROM CurrentBlocks);

PRINT CHAR(13) + CHAR(10) + '********************' + 'Explode and Squish';

SELECT			/* Explode and Squish */
	CustomerID,
	Phone1Block = SUM(CASE WHEN Exploder.n = 1 THEN 1 ELSE 0 END),
	Phone2Block = SUM(CASE WHEN Exploder.n = 2 THEN 1 ELSE 0 END)
FROM		@CustInfo
CROSS JOIN	(SELECT n = 1 UNION ALL SELECT 2) AS Exploder
CROSS APPLY	(
				SELECT
					Phone =
						CASE
							WHEN Exploder.n = 1 THEN
								Phone1
							ELSE
								Phone2
						END
			) AS p
JOIN		@BlockList b
ON			p.Phone = b.Phone
AND			b.BlockExpires > getdate()
GROUP BY	CustomerID;