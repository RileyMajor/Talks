USE Test;
GO

/*

SELECT 'OrderStatus' + OrderStatus + ' = ' + CONVERT(varchar(50), OrderStatusID) + ',' FROM OrderStatuses;

*/

DROP FUNCTION IF EXISTS CalcConstOrderStatus;
GO

CREATE FUNCTION CalcConstOrderStatus()
RETURNS TABLE AS
RETURN
	SELECT
		OrderStatusNew = 1,
		OrderStatusProcessed = 2,
		OrderStatusRejected = 3,
		OrderStatusPrepared = 4,
		OrderStatusInvoiced = 5,
		OrderStatusShipped = 6,
		OrderStatusComplete = 7;
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

DROP FUNCTION IF EXISTS CalcOrderProcessing;
GO

CREATE FUNCTION CalcOrderProcessing
(
		@Now datetimeoffset,
		@OrderID int,
		@OrderStatusID int,
		@Customer varchar(100),
		@CustomerEmail varchar(500),
		@CustomerVolumeDiscountThreshold int,
		@CustomerVolumeDiscount numeric(19,6),
		@CustomerInactive bit,
		@OrderTotalQuantity int,
		@ArugulaCount int,
		@BeanCount int,
		@OrderGrossCharges numeric(19,2)
)
RETURNS TABLE AS
RETURN
		SELECT
			OrderStatusIDNew = OrderStatusNext.OrderStatusIDNew,
			OrderInvoiceDate = InvoiceInfoFinal.OrderInvoiceDate,
			OrderInvoiceAmount = InvoiceInfoFinal.OrderInvoiceAmount,
			EmailTo = Email.EmailTo,
			EmailSubject = Email.EmailSubject,
			EmailBody = Email.EmailBody
		FROM		CalcConstSettings() AS s
		CROSS JOIN	CalcConstOrderStatus() AS os
		CROSS JOIN	(
						SELECT
							CurrentDateTime = @Now,
							OrderID = @OrderID,
							OrderStatusID = @OrderStatusID,
							Customer = @Customer,
							CustomerEmail = @CustomerEmail,
							CustomerVolumeDiscountThreshold = @CustomerVolumeDiscountThreshold,
							CustomerVolumeDiscount = @CustomerVolumeDiscount,
							CustomerInactive = @CustomerInactive,
							OrderTotalQuantity = @OrderTotalQuantity,
							ArugulaCount = @ArugulaCount,
							BeanCount = @BeanCount,
							OrderGrossCharges = @OrderGrossCharges
					) AS v
		OUTER APPLY	(
						SELECT
							OrderInvoiceDate =
								v.CurrentDateTime,
							OrderInvoiceAmount =
								isNull(CalcNetCharges.OrderNetCharges,v.OrderGrossCharges),
							OrderNetCharges =
								CalcNetCharges.OrderNetCharges,
							OrderDiscountAmount = 
								v.OrderGrossCharges - CalcNetCharges.OrderNetCharges
						FROM		(
										SELECT
											OrderNetCharges =
												CASE
													WHEN v.OrderTotalQuantity > v.CustomerVolumeDiscountThreshold THEN
														/*
															Now that we're not using variables to store intermediary values, we don't get the benefit of the implicit conversion during assignment.
															So we have to be more explicit about type conversions.
														*/
														CONVERT(numeric(19,2),v.OrderGrossCharges * (1 - v.CustomerVolumeDiscount))
													ELSE
														NULL
												END
									) CalcNetCharges
						WHERE		v.OrderStatusID = os.OrderStatusPrepared
					) AS InvoiceInfoFinal
		OUTER APPLY	(
						SELECT
							InactiveReject =
								CONVERT
								(
									tinyint,
									CASE
										WHEN v.CustomerInactive > 0 THEN
											1
										ELSE
											0
									END
								),
							ArugulaReject =
								CONVERT
								(
									tinyint,
									CASE
										WHEN
											v.CustomerVolumeDiscount > s.ArugulaThresholdCustomerVolumeDiscountTrigger
										AND
											v.ArugulaCount > s.ArugulaThreshold
										THEN
											1
										ELSE
											0
									END
								),
							BeanReject =
								CONVERT
								(
									tinyint,
									CASE
										WHEN v.BeanCount > s.BeanThreshold THEN
											1
										ELSE
											0
									END
								)			
						WHERE		v.OrderStatusID = os.OrderStatusNew
					) AS CalcRejections
		OUTER APPLY	(
						SELECT
							OrderStatusIDNew =
								CASE v.OrderStatusID
									WHEN os.OrderStatusPrepared THEN os.OrderStatusInvoiced
									WHEN os.OrderStatusNew THEN
										CASE
											WHEN 1 IN (CalcRejections.InactiveReject, CalcRejections.ArugulaReject, CalcRejections.BeanReject) THEN
												os.OrderStatusRejected
											ELSE
												os.OrderStatusProcessed
										END
									ELSE NULL
								END
					) AS OrderStatusNext
		OUTER APPLY	(
						SELECT
							EmailTo = v.CustomerEmail,
							EmailSubject = 
								'Order ' +
								CASE OrderStatusNext.OrderStatusIDNew
									WHEN os.OrderStatusInvoiced THEN 'Invoice'
									WHEN os.OrderStatusRejected THEN 'Rejected'
									ELSE ''
								END +
								' - #' + CONVERT(varchar(50),@OrderID),
							EmailBody =
								CASE OrderStatusNext.OrderStatusIDNew
									WHEN os.OrderStatusInvoiced THEN
										'Your order of ' + CONVERT(varchar(50),v.OrderTotalQuantity) + ' items has been prepared for shipping.' +
										CASE
											WHEN InvoiceInfoFinal.OrderNetCharges IS NOT NULL THEN
												' Your total charges are ' + CONVERT(varchar(50),InvoiceInfoFinal.OrderNetCharges) + '. Your volume discount of ' + CalcText.CustomerVolumeDiscountText + ' has saved you $' + CONVERT(varchar(50),(v.OrderGrossCharges - InvoiceInfoFinal.OrderNetCharges)) + '!'
											ELSE
												' Your total charges are ' + CONVERT(varchar(50),v.OrderGrossCharges) + '. Your volume discount did not apply as your total order quantity of ' + CONVERT(varchar(50),v.OrderTotalQuantity) + ' items did not meet your discount threshold of ' + CONVERT(varchar(50),v.CustomerVolumeDiscountThreshold) + ' items.'
										END +
										' Thank you for shopping with us!'
									WHEN os.OrderStatusRejected THEN
										CASE
											WHEN CalcRejections.InactiveReject <> 0 THEN
												'We''re sorry, but customer ' + v.Customer + ' is marked inactive in our system. Please contact your sales representative.'
											WHEN CalcRejections.ArugulaReject <> 0 THEN
												'We''re sorry, but at your discount level (' + CalcText.CustomerVolumeDiscountText + '), you may not order more than ' + CONVERT(varchar(50),s.ArugulaThreshold) + ' ' + s.ArugulaProductName + ' and your order contains ' + CONVERT(varchar(50),v.ArugulaCount) + ' ' + s.ArugulaProductName + '. Your order has therefore been rejected.'
											WHEN CalcRejections.BeanReject <> 0 THEN
												'We''re sorry, but due to local air quality regulations, we cannot allow you to purchase so many ' + s.BeanProductString + 's (your request for ' + CONVERT(varchar(50),v.BeanCount) + ' ' + s.BeanProductString + '-related items exceeds our limit of ' + CONVERT(varchar(50),s.BeanThreshold) + '.)'
											ELSE
												''											
										END
									ELSE ''
								END
						FROM		(
										SELECT
											CustomerVolumeDiscountText = CONVERT(varchar(50),CONVERT(numeric(19,0),ROUND(v.CustomerVolumeDiscount*100,0))) + '%'
									) AS CalcText
						WHERE		OrderStatusNext.OrderStatusIDNew IN (os.OrderStatusInvoiced,os.OrderStatusRejected)
					) AS Email;
GO

DROP FUNCTION IF EXISTS GetOrderProcessing;
GO

CREATE FUNCTION GetOrderProcessing
(
	@Now datetimeoffset
)
RETURNS TABLE AS
RETURN
		SELECT
			OrderID = o.OrderID,
			OrderStatusID = o.OrderStatusID,
			CustomerID = o.CustomerID,
			Customer = c.Customer,
			CustomerMarkup = c.CustomerMarkup,
			CustomerEmail = c.CustomerEmail,
			CustomerVolumeDiscountThreshold = c.CustomerVolumeDiscountThreshold,
			CustomerVolumeDiscount = c.CustomerVolumeDiscount,
			CustomerInactive = c.CustomerInactive,
			OrderGrossCharges = osummary.OrderGrossCharges,
			OrderTotalQuanity = osummary.OrderTotalQuantity,
			ArugulaCount = osummary.ArugulaCount,
			BeanCount = osummary.BeanCount,
			OrderStatusIDNew = op.OrderStatusIDNew,
			OrderInvoiceDate = op.OrderInvoiceDate,
			OrderInvoiceAmount = op.OrderInvoiceAmount,
			EmailTo = op.EmailTo,
			EmailSubject = op.EmailSubject,
			EmailBody = op.EmailBody
		FROM		CalcConstSettings() AS s
		CROSS JOIN	CalcConstOrderStatus() AS os
		CROSS JOIN	(
						SELECT
							CurrentDateTime = @Now
					) AS v
		CROSS JOIN	Orders AS o
		JOIN		Customers AS c
		ON			c.CustomerID = o.CustomerID
		CROSS APPLY	(
						SELECT
							OrderGrossCharges = SUM(OrderDetailCalc.OrderDetailGrossCharges),
							OrderTotalQuantity = SUM(OrderDetailCalc.OrderTotalQuantity),
							ArugulaCount = SUM(OrderDetailCalc.OrderDetailArugulaCount),
							BeanCount = SUM(OrderDetailCalc.OrderDetailBeanCount)
						FROM		(
										SELECT
											OrderDetailGrossCharges = c.CustomerMarkup * od.Qty * p.ProductPrice,
											OrderTotalQuantity = od.Qty,
											OrderDetailArugulaCount = CASE WHEN p.Product = s.ArugulaProductName THEN od.Qty ELSE 0 END,
											OrderDetailBeanCount = CASE WHEN p.Product LIKE '%' + s.BeanProductString + '%' THEN od.Qty ELSE 0 END
										FROM		OrderDetails AS od
										JOIN		Products AS p
										ON			p.ProductID = od.ProductID
										WHERE		od.OrderID = o.OrderID
									) AS OrderDetailCalc
					) AS osummary
		CROSS APPLY	CalcOrderProcessing
					(
						v.CurrentDateTime,					/* @Now datetimeoffset,						*/
						o.OrderID,							/* @OrderID int,							*/
						o.OrderStatusID,					/* @OrderStatusID int,						*/
						c.Customer,							/* @Customer varchar(100),					*/
						c.CustomerEmail,					/* @CustomerEmail varchar(500),				*/
						c.CustomerVolumeDiscountThreshold,	/* @CustomerVolumeDiscountThreshold int,	*/
						c.CustomerVolumeDiscount,			/* @CustomerVolumeDiscount numeric(19,6),	*/
						c.CustomerInactive,					/* @CustomerInactive bit,					*/
						osummary.OrderTotalQuantity,		/* @OrderTotalQuantity int,					*/
						osummary.ArugulaCount,				/* @ArugulaCount int,						*/
						osummary.BeanCount,					/* @BeanCount int,							*/
						osummary.OrderGrossCharges			/* @OrderGrossCharges numeric(19,2)			*/
					) AS op
		WHERE		o.OrderStatusID IN (os.OrderStatusNew,os.OrderStatusPrepared);
GO

DROP PROCEDURE IF EXISTS ProcessOrders;
GO

CREATE PROCEDURE ProcessOrders

	@Now datetimeoffset = NULL

AS
BEGIN

	SET NOCOUNT ON;

	SET @Now = isNull(@Now,SYSDATETIMEOFFSET());

	DECLARE
		/* Retrieved from Orders */
		@OrderID int,
		@OrderStatusIDNew int,
		@OrderInvoiceAmount numeric(19,2),
		@OrderInvoiceDate datetimeoffset,
		@EmailTo varchar(500),
		@EmailSubject varchar(500),
		@EmailBody varchar(8000);

	DECLARE OrderList CURSOR LOCAL STATIC FORWARD_ONLY FOR
		SELECT
			OrderID = op.OrderID,
			OrderStatusIDNew = op.OrderStatusIDNew,
			OrderInvoiceAmount = op.OrderInvoiceAmount,
			OrderInvoiceDate = op.OrderInvoiceDate,
			EmailTo = op.EmailTo,
			EmailSubject = op.EmailSubject,
			EmailBody = op.EmailBody
		FROM		GetOrderProcessing
					(
						@Now
					) AS op;

	OPEN OrderList;

	FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusIDNew, @OrderInvoiceAmount, @OrderInvoiceDate, @EmailTo, @EmailSubject, @EmailBody;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @EmailTo IS NOT NULL
		BEGIN
			EXEC sp_send_dbmail_pretend
				@recipients = @EmailTo,
				@body = @EmailBody,
				@subject = @EmailSubject;
		END

		UPDATE		Orders
		SET			OrderStatusID = isNull(@OrderStatusIDNew,OrderStatusID),
					OrderInvoiceAmount = isNull(@OrderInvoiceAmount,OrderInvoiceAmount),
					OrderInvoiceDate = isNull(@OrderInvoiceDate,OrderInvoiceDate)
		WHERE		OrderID = @OrderID;

		FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusIDNew, @OrderInvoiceAmount, @OrderInvoiceDate, @EmailTo, @EmailSubject, @EmailBody;

	END

	CLOSE OrderList;

	DEALLOCATE OrderList;

END
GO
