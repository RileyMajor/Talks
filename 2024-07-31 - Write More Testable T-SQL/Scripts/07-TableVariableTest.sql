DECLARE @CustDataBefore TABLE (CustID int, LastEmail datetime, LastEmailSuperFunnyName varchar(50));
DECLARE @CustDataAfter TABLE (CustID int, LastEmail datetime, LastEmailSuperFunnyName varchar(50));

INSERT INTO @CustDataBefore
(
	CustID, LastEmail, LastEmailSuperFunnyName
)
SELECT
	CustID, LastEmail, LastEmailSuperFunnyName
FROM	CustList;

BEGIN TRAN;

--EXEC MailSuperFunnyCustomers @EffectiveDate = '2024-07-30';
EXEC MailSuperFunnyCustomers @EffectiveDate = '2024-07-31';

INSERT INTO @CustDataAfter
(
	CustID, LastEmail, LastEmailSuperFunnyName
)
SELECT
	CustID, LastEmail, LastEmailSuperFunnyName
FROM	CustList;

ROLLBACK TRAN;

SELECT		*
FROM		@CustDataBefore b
JOIN		@CustDataAfter a
ON			b.CustID = a.CustID;