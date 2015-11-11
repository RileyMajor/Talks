/* JSON vs XML

Riley Major
2015-10-10

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

*/

DECLARE @Orders TABLE
(
	OrderID bigint IDENTITY,
	OrderDate datetime
);
DECLARE @OrderDetails TABLE
(
	OrderDetailsID bigint IDENTITY,
	OrderID bigint,
	ProductID varchar(50),
	Qty int
);
INSERT INTO @Orders
(
	OrderDate
)
VALUES
	('2015-10-10'),
	('2015-10-09');
INSERT INTO @OrderDetails
(
	OrderID,
	ProductID,
	Qty
)
VALUES
	(1,'Bike',2),
	(1,'Helmet',2),
	(1,'Wheels',4),
	(2,'Ball',10);

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	OrderDetails.ProductID,
	OrderDetails.Qty
FROM		@Orders AS Orders
JOIN		@OrderDetails AS OrderDetails
ON			Orders.OrderID = OrderDetails.OrderID;

SELECT 'Path (Default)';

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	OrderDetails.ProductID,
	OrderDetails.Qty
FROM		@Orders AS Orders
JOIN		@OrderDetails AS OrderDetails
ON			Orders.OrderID = OrderDetails.OrderID
FOR			XML PATH;

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	OrderDetails.ProductID,
	OrderDetails.Qty
FROM		@Orders AS Orders
JOIN		@OrderDetails AS OrderDetails
ON			Orders.OrderID = OrderDetails.OrderID
FOR			JSON PATH;

SELECT 'Full Auto';

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	OrderDetails.ProductID,
	OrderDetails.Qty
FROM		@Orders AS Orders
JOIN		@OrderDetails AS OrderDetails
ON			Orders.OrderID = OrderDetails.OrderID
FOR			XML AUTO;

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	OrderDetails.ProductID,
	OrderDetails.Qty
FROM		@Orders AS Orders
JOIN		@OrderDetails AS OrderDetails
ON			Orders.OrderID = OrderDetails.OrderID
FOR			JSON AUTO;

SELECT 'Path (Custom)';

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	(
		SELECT
			OrderDetails.ProductID,
			OrderDetails.Qty
		FROM		@OrderDetails AS OrderDetails
		WHERE		Orders.OrderID = OrderDetails.OrderID
		FOR XML PATH('OrderDetail'), TYPE
	) AS OrderDetails
FROM		@Orders Orders
FOR			XML PATH('Order'), ROOT('Orders');

SELECT
	Orders.OrderID,
	Orders.OrderDate,
	(
		SELECT
			OrderDetails.ProductID,
			OrderDetails.Qty
		FROM		@OrderDetails AS OrderDetails
		WHERE		Orders.OrderID = OrderDetails.OrderID
		FOR JSON PATH
	) AS OrderDetails
FROM		@Orders Orders
FOR			JSON PATH, ROOT('Orders');