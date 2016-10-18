DECLARE @Customers TABLE (CustomerName varchar(50), Phone1 varchar(50), Phone2 varchar(50));
INSERT INTO @Customers (CustomerName, Phone1, Phone2)
	VALUES
		('Bill', '555-123-4567', '666-123-4567'),
		('Ted', '777-123-4556', '123-999-1244');

SELECT
	CustomerName,
	n AS PhoneCounter,
	CASE
		WHEN n = 1 THEN
			Phone1
		ELSE
			Phone2
	END AS Phone
FROM		@Customers
CROSS JOIN	(SELECT 1 AS n UNION ALL SELECT 2) AS Numbers;