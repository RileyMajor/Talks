USE Test;
GO

DROP PROCEDURE IF EXISTS MonolithProcessOrdersDateFix;
GO

CREATE PROCEDURE MonolithProcessOrdersDateFix

	@Now datetimeoffset = NULL

AS
BEGIN

	SET NOCOUNT ON;

	SET @Now = isNull(@Now,SYSDATETIMEOFFSET());

	CREATE TABLE #OrdersToProcess
		(
			OrderID int,
			OrderStatusID int
		);

	INSERT INTO #OrdersToProcess
		(
			OrderID,
			OrderStatusID
		)
	SELECT
		o.OrderID,
		o.OrderStatusID
	FROM		Orders AS o
	JOIN		OrderStatuses AS ostat
	ON			ostat.OrderStatusID = o.OrderStatusID
	WHERE		ostat.OrderStatus IN ('New','Prepared');

	DECLARE
		@OrderID int,
		@OrderStatusID int;

	DECLARE OrderList CURSOR LOCAL STATIC FORWARD_ONLY FOR
		SELECT
			OrderID,
			OrderStatusID
		FROM		#OrdersToProcess;

	OPEN OrderList;

	FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusID;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		DECLARE
			@CustomerID int;

		SELECT
			@CustomerID = CustomerID
		FROM		Orders
		WHERE		OrderID = @OrderID;

		IF @OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Prepared')
		BEGIN

			/* Order has been pulled from inventory and prepared, so calculate invoice and ship. */

			DECLARE
				@CustomerMarkup numeric(19,6),
				@OrderGrossCharges numeric(19,2);

			SELECT
				@CustomerMarkup = CustomerMarkup
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

			SELECT
				@OrderGrossCharges = SUM(@CustomerMarkup * od.Qty * p.ProductPrice)
			FROM		OrderDetails AS od
			JOIN		Products AS p
			ON			p.ProductID = od.ProductID
			WHERE		od.OrderID = @OrderID;

			UPDATE		Orders
			SET			OrderInvoiceAmount = @OrderGrossCharges,
						OrderInvoiceDate = @Now
			WHERE		OrderID = @OrderID;

			/* Apply discount if necessary. */

			DECLARE
				@CustomerVolumeDiscountThreshold int,
				@CustomerVolumeDiscount numeric(19,6);
			SELECT
				@CustomerVolumeDiscountThreshold = CustomerVolumeDiscountThreshold,
				@CustomerVolumeDiscount = CustomerVolumeDiscount
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

			DECLARE
				@OrderTotalQuantity int,
				@OrderNetCharges numeric(19,2);
			SELECT
				@OrderTotalQuantity = SUM(Qty)
			FROM		OrderDetails AS od
			WHERE		od.OrderID = @OrderID;

			IF @OrderTotalQuantity > @CustomerVolumeDiscountThreshold
			BEGIN
				SET @OrderNetCharges = @OrderGrossCharges * (1 - @CustomerVolumeDiscount);
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

			DECLARE
				@Customer varchar(100),
				@CustomerEmail varchar(500);
			SELECT
				@Customer = Customer,
				@CustomerEmail = CustomerEmail
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

			DECLARE
				@EmailTo varchar(500),
				@EmailSubject varchar(500),
				@EmailBody varchar(8000);

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
			SET			OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Invoiced')
			WHERE		OrderID = @OrderID;

		END
				
		IF @OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'New')
		BEGIN

			/* Protect against inactive customers. */

			DECLARE
				@CustomerInactive bit;

			SELECT
				@Customer = Customer,
				@CustomerInactive = CustomerInactive,
				@CustomerEmail = CustomerEmail
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

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
				SET			OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Rejected')
				WHERE		OrderID = @OrderID;

				GOTO OrderComplete;

			END

			/* Protect against Arugula speculators. */

			SELECT
				@CustomerVolumeDiscount = CustomerVolumeDiscount,
				@CustomerEmail = CustomerEmail
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

			IF @CustomerVolumeDiscount > 0.1
			BEGIN

				DECLARE
					@ArugulaCount int;

				SELECT
					@ArugulaCount = SUM(od.Qty)
				FROM		OrderDetails AS od
				JOIN		Products AS p
				ON			p.ProductID = od.ProductID
				WHERE		p.Product = 'Arugula'
				AND			od.OrderID = @OrderID;

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
					SET			OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Rejected')
					WHERE		OrderID = @OrderID;

					GOTO OrderComplete;

				END

			END

			/* Protect against stinky customers. */

			SELECT
				@CustomerEmail = CustomerEmail
			FROM		Customers
			WHERE		CustomerID = @CustomerID;

			DECLARE
				@BeanCount int;

			SELECT
				@BeanCount = SUM(od.Qty)
			FROM		OrderDetails AS od
			JOIN		Products AS p
			ON			p.ProductID = od.ProductID
			WHERE		p.Product LIKE '%bean%'
			AND			od.OrderID = @OrderID;

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
				SET			OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Rejected')
				WHERE		OrderID = @OrderID;

				GOTO OrderComplete;

			END

			UPDATE		Orders
			SET			OrderStatusID = (SELECT OrderStatusID FROM OrderStatuses WHERE OrderStatus = 'Processed')
			WHERE		OrderID = @OrderID;

		END

		OrderComplete:

		FETCH NEXT FROM OrderList INTO @OrderID, @OrderStatusID;

	END

	CLOSE OrderList;

	DEALLOCATE OrderList;

END
GO
