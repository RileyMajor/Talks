/*

Monolith Comparison with Date

This shows the same procedure can be run multiple times with identical results.

This is possible because we feed in the "current" date.

Beware that it will result in many records sharing the same "current" date.
	We're not much concerned about that.
	Yes, it destroys the ordering of successive actions, but
		(1) it groups together actions which occurred together,
				which can be valuable during debugging and
		(2) our long term goal is a set-based operation,
				which will have the same date-sharing behavior.

(Its idempotency still relies on there being no other processes which affect the underlying data at the same time.)

Next, we will start adjusting the monolith procedure
	and we will use this testing framework to ensure that we don't change its behavior.

*/

USE Test;
GO

DECLARE
	@Now datetimeoffset = SYSDATETIMEOFFSET();

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

EXEC MonolithProcessOrdersDateFix @Now = @Now;

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

EXEC MonolithProcessOrdersDateFix @Now = @Now;

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
		CASE WHEN isNull(MonoOrderEmailTo,'') <> isNull(NewOrderEmailTo,'') THEN 'EmailTo-' ELSE '' END +
		CASE WHEN isNull(MonoOrderEmailSubject,'') <> isNull(NewOrderEmailSubject,'') THEN 'EmailSubject-' ELSE '' END +
		CASE WHEN isNull(MonoOrderEmailBody,'') <> isNull(NewOrderEmailBody,'') THEN 'EmailBody' ELSE '' END,
	*
FROM		#OrderCompare
WHERE		isNull(MonoOrderStatusID,-1) <> isNull(NewOrderStatusID,-1)
OR			isNull(MonoOrderInvoiceAmount,-1) <> isNull(NewOrderInvoiceAmount,-1)
OR			isNull(MonoOrderInvoiceDate,'') <> isNull(NewOrderInvoiceDate,'')
OR			isNull(MonoOrderEmailTo,'') <> isNull(NewOrderEmailTo,'')
OR			isNull(MonoOrderEmailSubject,'') <> isNull(NewOrderEmailSubject,'')
OR			isNull(MonoOrderEmailBody,'') <> isNull(NewOrderEmailBody,'');