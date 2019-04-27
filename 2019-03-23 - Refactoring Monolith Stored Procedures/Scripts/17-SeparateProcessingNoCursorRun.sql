/*

Cursor Removal Comparison

-- With a function returning a single set of data, can eliminate cursor for Order table update.
-- Still need a cursor for external effect (emailing).

We use this testing framework to ensure we didn't break anything,
	and to see the relative performance.

*/

USE Test;
GO

DECLARE
	@Now datetimeoffset = SYSDATETIMEOFFSET(),
	@Start datetimeoffset,
	@Elapsed1 int,
	@Elapsed2 int;

DECLARE
	@OrderCompare TABLE
	(
		OrderCompareOrderID int,
		OrigOrderStatusID int,
		OrigOrderInvoiceAmount numeric(19,2),
		OrigOrderInvoiceDate datetimeoffset,
		MonoOrderStatusID int,
		MonoOrderInvoiceAmount numeric(19,2),
		MonoOrderInvoiceDate datetimeoffset,
		MonoOrderEmailTo varchar(500),
		MonoOrderEmailSubject varchar(500),
		MonoOrderEmailBody varchar(8000),
		NewOrderStatusID int,
		NewOrderInvoiceAmount numeric(19,2),
		NewOrderInvoiceDate datetimeoffset,
		NewOrderEmailTo varchar(500),
		NewOrderEmailSubject varchar(500),
		NewOrderEmailBody varchar(8000)
	)

INSERT INTO @OrderCompare
(
	OrderCompareOrderID, OrigOrderStatusID, OrigOrderInvoiceAmount, OrigOrderInvoiceDate
)
SELECT
	OrderCompareOrderID, OrigOrderStatusID, OrigOrderInvoiceAmount, OrigOrderInvoiceDate
FROM		(
				SELECT
					OrderCompareOrderID = o.OrderID,
					OrigOrderStatusID = o.OrderStatusID,
					OrigOrderInvoiceAmount = o.OrderInvoiceAmount,
					OrigOrderInvoiceDate = o.OrderInvoiceDate
				FROM		Orders AS o
			) AS t;

BEGIN TRAN;

SELECT
	@Start = SYSDATETIMEOFFSET();

EXEC ProcessOrders @Now = @Now;

SELECT
	@Elapsed1 = DATEDIFF(millisecond,@Start,SYSDATETIMEOFFSET());

UPDATE		@OrderCompare
SET			MonoOrderStatusID = o.OrderStatusID,
			MonoOrderInvoiceAmount = o.OrderInvoiceAmount,
			MonoOrderInvoiceDate = o.OrderInvoiceDate,
			MonoOrderEmailTo = e.EmailTo,
			MonoOrderEmailSubject = e.EmailSubject,
			MonoOrderEmailBody = e.EmailBody
FROM		Orders o
LEFT JOIN	Emails e
ON			e.EmailOrderIDCalc = o.OrderID
WHERE		OrderCompareOrderID = o.OrderID;

ROLLBACK TRAN;

BEGIN TRAN;

SELECT
	@Start = SYSDATETIMEOFFSET();

EXEC ProcessOrdersNoCursor @Now = @Now;

SELECT
	@Elapsed2 = DATEDIFF(millisecond,@Start,SYSDATETIMEOFFSET());

UPDATE		@OrderCompare
SET			NewOrderStatusID = o.OrderStatusID,
			NewOrderInvoiceAmount = o.OrderInvoiceAmount,
			NewOrderInvoiceDate = o.OrderInvoiceDate,
			NewOrderEmailTo = e.EmailTo,
			NewOrderEmailSubject = e.EmailSubject,
			NewOrderEmailBody = e.EmailBody
FROM		Orders o
LEFT JOIN	Emails e
ON			e.EmailOrderIDCalc = o.OrderID
WHERE		OrderCompareOrderID = o.OrderID;

ROLLBACK TRAN;

DROP TABLE IF EXISTS #OrderCompare;

SELECT		*
INTO		#OrderCompare
FROM		@OrderCompare;

SELECT
	Differences =
		CASE WHEN isNull(MonoOrderStatusID,-1) <> isNull(NewOrderStatusID,-1) THEN 'StatusID-' ELSE '' END +
		CASE WHEN isNull(MonoOrderInvoiceAmount,-1) <> isNull(NewOrderInvoiceAmount,-1) THEN 'InvoiceAmt-' ELSE '' END +
		CASE WHEN isNull(MonoOrderInvoiceDate,'') <> isNull(NewOrderInvoiceDate,'') THEN 'InvoiceDate-' ELSE '' END +
		CASE WHEN isNull(MonoOrderEmailTo,'NULL') <> isNull(NewOrderEmailTo,'NULL') THEN 'EmailTo-' ELSE '' END +
		CASE WHEN isNull(MonoOrderEmailSubject,'NULL') <> isNull(NewOrderEmailSubject,'NULL') THEN 'EmailSubject-' ELSE '' END +
		CASE WHEN isNull(MonoOrderEmailBody,'NULL') <> isNull(NewOrderEmailBody,'NULL') THEN 'EmailBody' ELSE '' END,
	*
FROM		#OrderCompare
WHERE		isNull(MonoOrderStatusID,-1) <> isNull(NewOrderStatusID,-1)
OR			isNull(MonoOrderInvoiceAmount,-1) <> isNull(NewOrderInvoiceAmount,-1)
OR			isNull(MonoOrderInvoiceDate,'') <> isNull(NewOrderInvoiceDate,'')
OR			isNull(MonoOrderEmailTo,'NULL') <> isNull(NewOrderEmailTo,'NULL')
OR			isNull(MonoOrderEmailSubject,'NULL') <> isNull(NewOrderEmailSubject,'NULL')
OR			isNull(MonoOrderEmailBody,'NULL') <> isNull(NewOrderEmailBody,'NULL');

SELECT
	Elapsed1 = @Elapsed1,
	Elapsed2 = @Elapsed2;

/*
	For 100k rows:

	Elapsed1	Elapsed2
	3242		2707

	17% savings

	For 100k rows against original:

	Elapsed1	Elapsed2
	3496		2717

	22% savings

	For 1M rows against original:

	Elapsed1	Elapsed2
	40245		30530

	24% savings

*/