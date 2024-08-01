DROP TABLE IF EXISTS CustList;
GO
CREATE TABLE CustList
(
	CustID						int IDENTITY PRIMARY KEY,
	CustName					varchar(50),
	FirstChars					int,
	LastChars					int,
	FunkyTuesdays				bit,
	LastEmail					datetime,
	LastEmailSuperFunnyName		varchar(50)
);
INSERT INTO CustList (CustName, FirstChars, LastChars, FunkyTuesdays)
	VALUES('Acme Company', 1, 3, 0), ('Test Company', 3, 2, 1), ('Best Company Ever', 5, 2, 1), ('Riley''s Company', 18, 6, 0);
SELECT * FROM CustList;
GO