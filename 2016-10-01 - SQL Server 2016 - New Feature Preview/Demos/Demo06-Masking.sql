USE SS16Test; -- must be in database with appropriate compatability level

DROP TABLE IF EXISTS #Zorro;
DROP TABLE IF EXISTS #ZorroCopy;

CREATE TABLE #Zorro
(
	ZorroID INT MASKED WITH (FUNCTION = 'random(11111,22222)') IDENTITY PRIMARY KEY ,
	CreateDate datetime MASKED WITH (FUNCTION = 'default()'),
	Person varchar(50) MASKED WITH (FUNCTION = 'default()'),
	CreditCardNumber varchar(16) MASKED WITH (FUNCTION = 'partial(1,"XYZCYZABC",4)'),
	Email varchar(500) MASKED WITH (FUNCTION = 'email()'),
	CardType int MASKED WITH (FUNCTION = 'random(1,4)')
);

INSERT INTO #Zorro
(
	CreateDate, Person, CreditCardNumber, Email, CardType
)
SELECT
	CreateDate, Person, CreditCardNumber, Email, CardType
FROM	(
			SELECT
				getdate()-n AS CreateDate,
				'Amigo #' + CONVERT(varchar(50),n) AS Person,
				REPLICATE(LEFT(n,1),16) AS CreditCardNumber,
				'test' + CONVERT(varchar(50),n) + '@example.com' AS Email,
				n*n AS CardType
			FROM		(
							SELECT		ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS n
							FROM STRING_SPLIT(SPACE(20),' ')
						) AS exploder
		) as t;

SELECT * FROM #Zorro;

CREATE USER TestUser WITHOUT LOGIN;
EXECUTE AS USER = 'TestUser';  
SELECT * FROM #Zorro; 
SELECT * INTO #ZorroCopy FROM #Zorro;
REVERT;
DROP USER TestUser;

SELECT * FROM #ZorroCopy WHERE ZorroID = 0;