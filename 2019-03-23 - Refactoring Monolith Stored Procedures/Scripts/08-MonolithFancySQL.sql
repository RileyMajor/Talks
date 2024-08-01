USE Test;
GO

DROP PROCEDURE IF EXISTS MonolithProcessFancySQL;
GO

CREATE PROCEDURE MonolithProcessFancySQL

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
		@OrderGrossCharges numeric(19,2),
		@OrderNetCharges numeric(19,2),
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

		IF @OrderStatusID = @OrderStatusPrepared
		BEGIN

			/* Order has been pulled from inventory and prepared, so calculate invoice and ship. */

			UPDATE		Orders
			SET			OrderInvoiceAmount = @OrderGrossCharges,
						OrderInvoiceDate = @Now
			WHERE		OrderID = @OrderID;

			/* Apply discount if necessary. */
			
			IF @OrderTotalQuantity > @CustomerVolumeDiscountThreshold
			BEGIN
				SET @OrderNetCharges = @OrderGrossCharges * (1 - @CustomerVolumeDiscount)
				UPDATE		Orders
				SET			OrderInvoiceAmount = @OrderNetCharges,
							OrderInvoiceDate = @Now
				WHERE		OrderID = @OrderID;
			END
			ELSE
			BEGIN
				SET @OrderNetCharges = NULL;
			END

			/* Email invoice to customer */

			SET @EmailTo = @CustomerEmail;

			SET @EmailSubject = 'Order Invoice - #' + CONVERT(varchar(50),@OrderID);

			SET @EmailBody = 'Your order of ' + CONVERT(varchar(50),@OrderTotalQuantity) + ' items has been prepared for shipping.';

			IF @OrderNetCharges IS NOT NULL
			BEGIN
				SET @EmailBody = @EmailBody + ' Your total charges are ' + CONVERT(varchar(50),@OrderNetCharges) + '. Your volume discount of ' + CONVERT(varchar(50),CONVERT(numeric(19,0),ROUND(@CustomerVolumeDiscount*100,0))) + '% has saved you $' + CONVERT(varchar(50),(@OrderGrossCharges - @OrderNetCharges)) + '!';
			END
			ELSE
			BEGIN
				SET @EmailBody = @EmailBody + ' Your total charges are ' + CONVERT(varchar(50),@OrderGrossCharges) + '. Your volume discount did not apply as your total order quantity of ' + CONVERT(varchar(50),@OrderTotalQuantity) + ' items did not meet your discount threshold of ' + CONVERT(varchar(50),@CustomerVolumeDiscountThreshold) + ' items.';
			END
			SET @EmailBody = @EmailBody + ' Thank you for shopping with us!';

			EXEC sp_send_dbmail_pretend
				@recipients = @EmailTo,
				@body = @EmailBody,
				@subject = @EmailSubject;

			UPDATE		Orders
			SET			OrderStatusID = @OrderStatusInvoiced
			WHERE		OrderID = @OrderID;

		END
				
		IF @OrderStatusID = @OrderStatusNew
		BEGIN

			/* Protect against inactive customers. */

			IF @CustomerInactive > 0
			BEGIN

				SET @EmailTo = @CustomerEmail;

				SET @EmailSubject = 'Order Rejected - #' + CONVERT(varchar(50),@OrderID);

				SET @EmailBody = 'We''re sorry, but customer ' + @Customer + ' is marked inactive in our system. Please contact your sales representative.';

				EXEC sp_send_dbmail_pretend
					@recipients = @EmailTo,
					@body = @EmailBody,
					@subject = @EmailSubject;
					
				UPDATE		Orders
				SET			OrderStatusID = @OrderStatusRejected
				WHERE		OrderID = @OrderID;

				GOTO OrderComplete;

			END

			/* Protect against Arugula speculators. */
			
			IF @CustomerVolumeDiscount > 0.1
			BEGIN

				IF @ArugulaCount > 5
				BEGIN

					SET @EmailTo = @CustomerEmail;

					SET @EmailSubject = 'Order Rejected - #' + CONVERT(varchar(50),@OrderID);

					SET @EmailBody = 'We''re sorry, but at your discount level (' + CONVERT(varchar(50),CONVERT(numeric(19,0),ROUND(@CustomerVolumeDiscount*100,0))) + '%), you may not order more than 5 Arugula and your order contains ' + CONVERT(varchar(50),@ArugulaCount) + ' Arugula. Your order has therefore been rejected.';

					EXEC sp_send_dbmail_pretend
						@recipients = @EmailTo,
						@body = @EmailBody,
						@subject = @EmailSubject;
					
					UPDATE		Orders
					SET			OrderStatusID = @OrderStatusRejected
					WHERE		OrderID = @OrderID;

					GOTO OrderComplete;

				END

			END

			/* Protect against stinky customers. */
			
			IF @BeanCount > 2
			BEGIN

				SET @EmailTo = @CustomerEmail;

				SET @EmailSubject = 'Order Rejected - #' + CONVERT(varchar(50),@OrderID);

				SET @EmailBody = 'We''re sorry, but due to local air quality regulations, we cannot allow you to purchase so many beans. (Your request for ' + CONVERT(varchar(50),@BeanCount) + ' bean-related items exceeds our limit of 2.)';

				EXEC sp_send_dbmail_pretend
					@recipients = @EmailTo,
					@body = @EmailBody,
					@subject = @EmailSubject;
					
				UPDATE		Orders
				SET			OrderStatusID = @OrderStatusRejected
				WHERE		OrderID = @OrderID;

				GOTO OrderComplete;

			END

			UPDATE		Orders
			SET			OrderStatusID = @OrderStatusProcessed
			WHERE		OrderID = @OrderID;

		END

		OrderComplete:

		FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusID, @CustomerID, @Customer, @CustomerMarkup, @CustomerEmail, @CustomerVolumeDiscountThreshold, @CustomerVolumeDiscount, @CustomerInactive, @OrderGrossCharges, @OrderTotalQuantity, @ArugulaCount, @BeanCount;

	END

	CLOSE OrderList;

	DEALLOCATE OrderList;

END
GO
