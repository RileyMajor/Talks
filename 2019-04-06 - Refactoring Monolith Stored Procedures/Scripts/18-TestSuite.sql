/*

Build Test Suite

*/

USE Test;
GO

DROP TABLE IF EXISTS TestSuite;

WITH r AS
(
	SELECT rn = ROW_NUMBER() OVER (ORDER BY (SELECT 1)) FROM (VALUES (1),(1),(1),(1)) AS r(n)
), TestTextValues AS
(
	SELECT TestTestValue = ''
	UNION ALL SELECT NULL
	UNION ALL SELECT 'Test Value'
), TestEmailValues AS
(
	SELECT TestEmailValue = ''
	UNION ALL SELECT NULL
	UNION ALL SELECT 'TestEmail1@example.com'
), TestDateValues AS
(
	SELECT TestDateValue = DATEADD(day,1,SYSDATETIMEOFFSET())
	UNION ALL
	SELECT DATEADD(day,-1,SYSDATETIMEOFFSET())
	UNION ALL
	SELECT NULL
	UNION ALL
	SELECT ''
), TestNumVals AS
(
	SELECT TestIntVal = r.rn, TestNumVal = r.rn * .1 FROM r
	UNION ALL
	SELECT NULL, NULL
	UNION ALL
	SELECT 0, 0
), TestBitVals AS
(
	SELECT TestBitVal = CONVERT(bit,1)
	UNION ALL SELECT CONVERT(bit,0)
	UNION ALL SELECT CONVERT(bit,NULL)
), TestVals AS
(
	SELECT
		CurrentDateValue = DateValues.TestDateValue,
		OrderID = OrderIDVals.TestIntVal,
		OrderStatusID = OrderStatusIDVals.TestIntVal,
		Customer = CustNames.TestTestValue,
		CustomerEmail = Emails.TestEmailValue,
		CustomerVolumeDiscountThreshold = VolDiscountThreshVals.TestIntVal,
		CustomerVolumeDiscount = VolDiscountVals.TestNumVal,
		CustomerInactive = CustInactiveVals.TestBitVal,
		OrderTotalQuantity = OrderTotalQtyVals.TestIntVal,
		ArugulaCount = ArugulaCountVals.TestIntVal * 2,
		BeanCount = BeanCountVals.TestIntVal * 2,
		OrderGrossCharges = OrderGrossChargeVals.TestNumVal * 15.7
	FROM		TestNumVals AS OrderIDVals
	CROSS JOIN	TestNumVals AS OrderStatusIDVals
	CROSS JOIN	TestTextValues AS CustNames
	CROSS JOIN	TestEmailValues AS Emails
	CROSS JOIN	TestDateValues AS DateValues
	CROSS JOIN	TestNumVals AS VolDiscountThreshVals
	CROSS JOIN	TestNumVals AS VolDiscountVals
	CROSS JOIN	TestBitVals AS CustInactiveVals
	CROSS JOIN	TestNumVals AS OrderTotalQtyVals
	CROSS JOIN	TestNumVals AS ArugulaCountVals
	CROSS JOIN	TestNumVals AS BeanCountVals
	CROSS JOIN	TestNumVals AS OrderGrossChargeVals
)
SELECT		TOP 1000000 *
INTO		TestSuite
FROM		TestVals
CROSS APPLY	CalcOrderProcessing
			(
				TestVals.CurrentDateValue,					/* @Now datetimeoffset,							*/
				TestVals.OrderID,							/* @OrderID int,								*/
				TestVals.OrderStatusID,						/* @OrderStatusID int,							*/
				TestVals.Customer,							/* @Customer varchar(100),						*/
				TestVals.CustomerEmail,						/* @CustomerEmail varchar(500),					*/
				TestVals.CustomerVolumeDiscountThreshold,	/* @CustomerVolumeDiscountThreshold int,		*/
				TestVals.CustomerVolumeDiscount,			/* @CustomerVolumeDiscount numeric(19,6),		*/
				TestVals.CustomerInactive,					/* @CustomerInactive bit,						*/
				TestVals.OrderTotalQuantity,				/* @OrderTotalQuantity int,						*/
				TestVals.ArugulaCount,						/* @ArugulaCount int,							*/
				TestVals.BeanCount,							/* @BeanCount int,								*/
				TestVals.OrderGrossCharges					/* @OrderGrossCharges numeric(19,2)				*/
			)
WHERE		TestVals.ArugulaCount >= 2
AND			TestVals.ArugulaCount <= 6
AND			TestVals.CustomerVolumeDiscount >= 0.2
AND			TestVals.CustomerVolumeDiscount < 0.4;
GO

DROP FUNCTION IF EXISTS CalcConstSettings;
GO

CREATE FUNCTION CalcConstSettings()
RETURNS TABLE AS
RETURN
	SELECT
		ArugulaProductName = 'Arugula',
		ArugulaThresholdCustomerVolumeDiscountTrigger = 0.3,
		ArugulaThreshold = 2,
		BeanProductString = 'bean',
		BeanThreshold = 2;
GO

SELECT		*
FROM		TestSuite AS TestVals
OUTER APPLY	CalcOrderProcessing
			(
				TestVals.CurrentDateValue,					/* @Now datetimeoffset,							*/
				TestVals.OrderID,							/* @OrderID int,								*/
				TestVals.OrderStatusID,						/* @OrderStatusID int,							*/
				TestVals.Customer,							/* @Customer varchar(100),						*/
				TestVals.CustomerEmail,						/* @CustomerEmail varchar(500),					*/
				TestVals.CustomerVolumeDiscountThreshold,	/* @CustomerVolumeDiscountThreshold int,		*/
				TestVals.CustomerVolumeDiscount,			/* @CustomerVolumeDiscount numeric(19,6),		*/
				TestVals.CustomerInactive,					/* @CustomerInactive bit,						*/
				TestVals.OrderTotalQuantity,				/* @OrderTotalQuantity int,						*/
				TestVals.ArugulaCount,						/* @ArugulaCount int,							*/
				TestVals.BeanCount,							/* @BeanCount int,								*/
				TestVals.OrderGrossCharges					/* @OrderGrossCharges numeric(19,2)				*/
			) AS op
WHERE		isNull(op.EmailTo,'NULL') <> isNull(TestVals.EmailTo,'NULL')
OR			isNull(op.EmailSubject,'NULL') <> isNull(TestVals.EmailSubject,'NULL')
OR			isNull(op.EmailBody,'NULL') <> isNull(TestVals.EmailBody,'NULL')
OR			isNull(op.OrderInvoiceAmount,-1) <> isNull(TestVals.OrderInvoiceAmount,-1)
OR			isNull(op.OrderInvoiceDate,CONVERT(datetime,-1)) <> isNull(TestVals.OrderInvoiceDate,CONVERT(datetime,-1))
OR			isNull(op.OrderStatusIDNew,-1) <> isNull(TestVals.OrderStatusIDNew,-1);

GO


DROP FUNCTION IF EXISTS CalcConstSettings;
GO

CREATE FUNCTION CalcConstSettings()
RETURNS TABLE AS
RETURN
	SELECT
		ArugulaProductName = 'Arugula',
		ArugulaThresholdCustomerVolumeDiscountTrigger = 0.1,
		ArugulaThreshold = 5,
		BeanProductString = 'bean',
		BeanThreshold = 2;
GO