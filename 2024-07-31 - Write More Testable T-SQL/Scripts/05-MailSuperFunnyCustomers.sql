DROP PROCEDURE IF EXISTS MailSuperFunnyCustomers;
GO
CREATE PROCEDURE MailSuperFunnyCustomers 
	@EffectiveDate datetime,
	@Debug bit
AS
BEGIN

	DECLARE @SuperFunnyCustList TABLE (CustID int PRIMARY KEY, FunnyName varchar(50));

	INSERT INTO @SuperFunnyCustList (CustID, FunnyName)
		SELECT c.CustID, fn.FunnyName FROM CustList AS c CROSS APPLY GetCustFunnyName(c.CustID,@EffectiveDate) AS fn
		WHERE IsSuperFunny <> 0;
	
	DECLARE @CustID int, @FunnyName varchar(50)

	DECLARE CustList CURSOR FAST_FORWARD FOR
		SELECT CustID, FunnyName FROM @SuperFunnyCustList;

	OPEN CustList;

	FETCH NEXT FROM CustList INTO @CustID, @FunnyName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @Debug <> 0
		BEGIN
			PRINT 'Mail queued';
		END
		ELSE
		BEGIN
			PRINT 'Debug mode: Mail skipped';
		END

		UPDATE		CustList
		SET			LastEmail					= getdate()		,
					LastEmailSuperFunnyName		= @FunnyName
		WHERE		CustID = @CustID;

		FETCH NEXT FROM CustList INTO @CustID, @FunnyName;

	END

	CLOSE CustList;

	DEALLOCATE CustList;

END
GO

/*

		DECLARE @EffectiveDate datetime = '2024-07-31';

		SELECT c.CustID, fn.FunnyName FROM CustList AS c CROSS APPLY GetCustFunnyName(c.CustID,@EffectiveDate) AS fn
		WHERE IsSuperFunny <> 0;

*/