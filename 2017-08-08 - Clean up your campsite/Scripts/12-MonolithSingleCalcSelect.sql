USE Test;
GO

DROP PROCEDURE IF EXISTS MonolithProcessSingleCaseSelect;
GO

CREATE PROCEDURE MonolithProcessSingleCaseSelect

	@Now datetimeoffset = NULL

AS
BEGIN

	SET NOCOUNT ON;

	SET @Now = isNull(@Now,SYSDATETIMEOFFSET());

	DECLARE
		@OrderStatusNew int,
		@OrderStatusPrepared int,
		@OrderStatusInvoiced int,
		@OrderStatusRejected int,
		@OrderStatusProcessed int;
	SELECT
		@OrderStatusNew = CASE WHEN OrderStatus = 'New' Then OrderStatusID ELSE @OrderStatusNew END,
		@OrderStatusPrepared = CASE WHEN OrderStatus = 'Prepared' Then OrderStatusID ELSE @OrderStatusPrepared END,
		@OrderStatusInvoiced = CASE WHEN OrderStatus = 'Invoiced' Then OrderStatusID ELSE @OrderStatusInvoiced END,
		@OrderStatusRejected = CASE WHEN OrderStatus = 'Rejected' Then OrderStatusID ELSE @OrderStatusRejected END,
		@OrderStatusProcessed  = CASE WHEN OrderStatus = 'Processed' Then OrderStatusID ELSE @OrderStatusProcessed END
	FROM		OrderStatuses
	WHERE		OrderStatus IN ('New','Prepared','Invoiced','Rejected','Processed');

	DECLARE
		/* Retrieved from Orders */
		@OrderID int,
		@OrderStatusID int,
		@CustomerID int,
		/* Retrieved from Customers */
		@Customer varchar(100),
		@CustomerMarkup numeric(19,6),
		@CustomerEmail varchar(500),
		@CustomerVolumeDiscountThreshold int,
		@CustomerVolumeDiscount numeric(19,6),
		@CustomerInactive bit,
		/* Retrieved from OrderDetails */
		@OrderTotalQuantity int,
		@ArugulaCount int,
		@BeanCount int,
		/* Computed */
		@OrderStatusIDNew int,
		@OrderGrossCharges numeric(19,2),
		@OrderInvoiceAmount numeric(19,2),
		@OrderInvoiceDate datetimeoffset,
		@EmailTo varchar(500),
		@EmailSubject varchar(500),
		@EmailBody varchar(8000);

	DECLARE OrderList CURSOR LOCAL STATIC FORWARD_ONLY FOR
		SELECT
			o.OrderID,
			o.OrderStatusID,
			o.CustomerID,
			c.Customer,
			c.CustomerMarkup,
			c.CustomerEmail,
			c.CustomerVolumeDiscountThreshold,
			c.CustomerVolumeDiscount,
			c.CustomerInactive,
			osummary.OrderGrossCharges,
			osummary.OrderTotalQuantity,
			osummary.ArugulaCount,
			osummary.BeanCount
		FROM		Orders AS o
		JOIN		Customers AS c
		ON			c.CustomerID = o.CustomerID
		CROSS APPLY	(
						/* Have you wrap some calcs in an extra layer or you get this error:
							Msg 8124, Level 16, State 1, Procedure MonolithProcessFancySQL, Line 71 [Batch Start Line 5]
							Multiple columns are specified in an aggregated expression containing an outer reference. If an expression being aggregated contains an outer reference, then that outer reference must be the only column referenced in the expression.
						*/
						SELECT
							OrderGrossCharges = SUM(OrderDetailCalc.OrderDetailGrossCharges),
							OrderTotalQuantity = SUM(OrderDetailCalc.OrderTotalQuantity),
							ArugulaCount = SUM(OrderDetailCalc.OrderDetailArugulaCount),
							BeanCount = SUM(OrderDetailCalc.OrderDetailBeanCount)
						FROM		(
										SELECT
											OrderDetailGrossCharges = c.CustomerMarkup * od.Qty * p.ProductPrice,
											OrderTotalQuantity = od.Qty,
											OrderDetailArugulaCount = CASE WHEN p.Product = 'Arugula' THEN od.Qty ELSE 0 END,
											OrderDetailBeanCount = CASE WHEN p.Product LIKE '%bean%' THEN od.Qty ELSE 0 END
										FROM		OrderDetails AS od
										JOIN		Products AS p
										ON			p.ProductID = od.ProductID
										WHERE		od.OrderID = o.OrderID
									) AS OrderDetailCalc
					) AS osummary
		WHERE		o.OrderStatusID IN (@OrderStatusNew,@OrderStatusPrepared);

	OPEN OrderList;

	FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusID, @CustomerID, @Customer, @CustomerMarkup, @CustomerEmail, @CustomerVolumeDiscountThreshold, @CustomerVolumeDiscount, @CustomerInactive, @OrderGrossCharges, @OrderTotalQuantity, @ArugulaCount, @BeanCount;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		/*
			Clear out calculated variables so they don't carry over from one iteration of the loop to the next.
			Don't clear out @OrderGrossCharges, as it's calculated as part of the data retrieval.
		*/
		SELECT
			@OrderStatusIDNew = NULL,
			@OrderInvoiceAmount = NULL,
			@OrderInvoiceDate = NULL,
			@EmailTo = NULL,
			@EmailSubject = NULL,
			@EmailBody = NULL;

		SELECT
			@OrderStatusIDNew = OrderStatusNext.OrderStatusIDNew,
			@OrderInvoiceDate = InvoiceInfoFinal.OrderInvoiceDate,
			@OrderInvoiceAmount = InvoiceInfoFinal.OrderInvoiceAmount,
			@EmailTo = Email.EmailTo,
			@EmailSubject = Email.EmailSubject,
			@EmailBody = Email.EmailBody
					/* Why convert these variables to fields? 2 Reasons:
						1. It makes it clear what all is needed for the below calculations.
						2. It makes sure that there is a row in this result set, which allows the WHERE trick used elsewhere.
					*/
		FROM		(
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
							OrderGrossCharges = @OrderGrossCharges,
							OrderStatusNew = @OrderStatusNew,
							OrderStatusPrepared = @OrderStatusPrepared,
							OrderStatusInvoiced = @OrderStatusInvoiced,
							OrderStatusRejected = @OrderStatusRejected,
							OrderStatusProcessed = @OrderStatusProcessed,
							ArugulaThresholdCustomerVolumeDiscountTrigger = 0.1,
							ArugulaThreshold = 5,
							BeanThreshold = 2
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
						WHERE		v.OrderStatusID = v.OrderStatusPrepared
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
											v.CustomerVolumeDiscount > v.ArugulaThresholdCustomerVolumeDiscountTrigger
										AND
											v.ArugulaCount > v.ArugulaThreshold
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
										WHEN v.BeanCount > v.BeanThreshold THEN
											1
										ELSE
											0
									END
								)			
						WHERE		v.OrderStatusID = v.OrderStatusNew
					) AS CalcRejections
		OUTER APPLY	(
						SELECT
							OrderStatusIDNew =
								CASE v.OrderStatusID
									WHEN v.OrderStatusPrepared THEN v.OrderStatusInvoiced
									WHEN v.OrderStatusNew THEN
										CASE
											WHEN 1 IN (CalcRejections.InactiveReject, CalcRejections.ArugulaReject, CalcRejections.BeanReject) THEN
												v.OrderStatusRejected
											ELSE
												v.OrderStatusProcessed
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
									WHEN v.OrderStatusInvoiced THEN 'Invoice'
									WHEN v.OrderStatusRejected THEN 'Rejected'
									ELSE ''
								END +
								' - #' + CONVERT(varchar(50),@OrderID),
							EmailBody =
								CASE OrderStatusNext.OrderStatusIDNew
									WHEN v.OrderStatusInvoiced THEN
										'Your order of ' + CONVERT(varchar(50),v.OrderTotalQuantity) + ' items has been prepared for shipping.' +
										CASE
											WHEN InvoiceInfoFinal.OrderNetCharges IS NOT NULL THEN
												' Your total charges are ' + CONVERT(varchar(50),InvoiceInfoFinal.OrderNetCharges) + '. Your volume discount of ' + CalcText.CustomerVolumeDiscountText + ' has saved you $' + CONVERT(varchar(50),(v.OrderGrossCharges - InvoiceInfoFinal.OrderNetCharges)) + '!'
											ELSE
												' Your total charges are ' + CONVERT(varchar(50),v.OrderGrossCharges) + '. Your volume discount did not apply as your total order quantity of ' + CONVERT(varchar(50),v.OrderTotalQuantity) + ' items did not meet your discount threshold of ' + CONVERT(varchar(50),v.CustomerVolumeDiscountThreshold) + ' items.'
										END +
										' Thank you for shopping with us!'
									WHEN v.OrderStatusRejected THEN
										CASE
											WHEN CalcRejections.InactiveReject <> 0 THEN
												'We''re sorry, but customer ' + v.Customer + ' is marked inactive in our system. Please contact your sales representative.'
											WHEN CalcRejections.ArugulaReject <> 0 THEN
												'We''re sorry, but at your discount level (' + CalcText.CustomerVolumeDiscountText + '), you may not order more than ' + CONVERT(varchar(50),v.ArugulaThreshold) + ' Arugula and your order contains ' + CONVERT(varchar(50),v.ArugulaCount) + ' Arugula. Your order has therefore been rejected.'
											WHEN CalcRejections.BeanReject <> 0 THEN
												'We''re sorry, but due to local air quality regulations, we cannot allow you to purchase so many beans. (Your request for ' + CONVERT(varchar(50),v.BeanCount) + ' bean-related items exceeds our limit of ' + CONVERT(varchar(50),v.BeanThreshold) + '.)'
											ELSE
												''											
										END
									ELSE ''
								END
						FROM		(
										SELECT
											CustomerVolumeDiscountText = CONVERT(varchar(50),CONVERT(numeric(19,0),ROUND(v.CustomerVolumeDiscount*100,0))) + '%'
									) AS CalcText
						WHERE		OrderStatusNext.OrderStatusIDNew IN (v.OrderStatusInvoiced,v.OrderStatusRejected)
					) AS Email;

		OrderComplete:

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

		FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusID, @CustomerID, @Customer, @CustomerMarkup, @CustomerEmail, @CustomerVolumeDiscountThreshold, @CustomerVolumeDiscount, @CustomerInactive, @OrderGrossCharges, @OrderTotalQuantity, @ArugulaCount, @BeanCount;

	END

	CLOSE OrderList;

	DEALLOCATE OrderList;

END
GO
