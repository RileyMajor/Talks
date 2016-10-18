DECLARE @j nvarchar(max) = '{"Orders": [
{"OrderID":1, "OrderDate": "2015-10-10"},
{"OrderID":2, "OrderDate": "2015-10-09"},
{"OrderId":1, "OrderDate": "2015-10-11"}]}'; -- Note case sensitivity

SELECT
	OrderID, OrderDate
FROM OPENJSON (@j, '$.Orders')
WITH
(
	OrderID bigint,
	OrderDate datetime
) AS OrdersArray;