USE TempDB;
GO

SET NOCOUNT ON;
GO

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS OrderDetails;
DROP VIEW IF EXISTS OrdersWithProfit;
DROP FUNCTION IF EXISTS CalcOrderProfitXML;
DROP FUNCTION IF EXISTS GetOrdersWithProfitXML;
DROP FUNCTION IF EXISTS CalcOrderProfitJSON;
DROP FUNCTION IF EXISTS GetOrdersWithProfitJSON;
GO

CREATE TABLE Orders (OrderID INT IDENTITY PRIMARY KEY, OrderDate date);
CREATE TABLE OrderDetails (OrderDetailID INT IDENTITY PRIMARY KEY, OrderID int, OrderDetailCharge numeric(19,2), OrderDetailCost numeric(19,2));
GO

INSERT INTO Orders (OrderDate) VALUES (getdate()), (getdate()-1), (getdate()-3);
GO

INSERT INTO OrderDetails (OrderID, OrderDetailCharge, OrderDetailCost) VALUES (1, 200, 100), (2, 100, 50), (2, 200, 100), (3, 300, 200);
GO 1000

GO


CREATE VIEW OrdersWithProfit AS
SELECT OrderID,
	(
		SELECT
			SUM(OrderDetailCharge - CASE WHEN odlc.OrderDetailLineCount > 1 THEN 0.9 ELSE 1 END * OrderDetailCost)
		FROM		(
						SELECT
							*,
							COUNT(*) OVER (PARTITION BY (SELECT 1)) AS OrderDetailLineCount
						FROM		OrderDetails od
						WHERE		od.OrderID = o.OrderID
					) AS odlc
	) AS OrderProfit
FROM Orders o;
GO

CREATE FUNCTION CalcOrderProfitXML
(
	@OrderDetails xml
)
RETURNS TABLE AS RETURN
	SELECT
		SUM(OrderDetailCharge - CASE WHEN od.OrderDetailLineCount > 1 THEN 0.9 ELSE 1 END * OrderDetailCost) AS OrderProfit
	FROM	(
				SELECT
					COUNT(*) OVER (PARTITION BY (SELECT 1)) AS OrderDetailLineCount,
					OrderDetailsNodes.OrderDetailXML.value('(./OrderDetailCharge)[1]','numeric(19,2)') AS OrderDetailCharge,
					OrderDetailsNodes.OrderDetailXML.value('(./OrderDetailCost)[1]','numeric(19,2)') AS OrderDetailCost
				FROM		@OrderDetails.nodes('/OrderDetails/OrderDetail') AS OrderDetailsNodes(OrderDetailXML)
			) AS od;
GO

CREATE FUNCTION GetOrdersWithProfitXML()
RETURNS TABLE AS RETURN
SELECT OrderID, OrderProfitCalc.OrderProfit
FROM		Orders o
CROSS APPLY	CalcOrderProfitXML
			(
				(
					SELECT
						OrderDetailCharge,
						OrderDetailCost
					FROM		OrderDetails od
					WHERE		od.OrderID = o.OrderID
					FOR XML PATH('OrderDetail'), TYPE, ROOT('OrderDetails')
				)
			) AS OrderProfitCalc;
GO

CREATE FUNCTION CalcOrderProfitJSON
(
	@OrderDetails varchar(max)
)
RETURNS TABLE AS RETURN
	SELECT
		SUM(OrderDetailCharge - CASE WHEN od.OrderDetailLineCount > 1 THEN 0.9 ELSE 1 END * OrderDetailCost) AS OrderProfit
	FROM	(
				SELECT
					COUNT(*) OVER (PARTITION BY (SELECT 1)) AS OrderDetailLineCount,
					CONVERT(numeric(19,2),JSON_VALUE(OrderDetailsJSON.[value],'$.OrderDetailCharge')) AS OrderDetailCharge,
					CONVERT(numeric(19,2),JSON_VALUE(OrderDetailsJSON.[value],'$.OrderDetailCost')) AS OrderDetailCost
				FROM		OPENJSON (@OrderDetails) AS OrderDetailsJSON
			) AS od;
GO

CREATE FUNCTION GetOrdersWithProfitJSON()
RETURNS TABLE AS RETURN
SELECT OrderID, OrderProfitCalc.OrderProfit
FROM		Orders o
CROSS APPLY	CalcOrderProfitJSON
			(
				(
					SELECT
						OrderDetailCharge,
						OrderDetailCost
					FROM		OrderDetails od
					WHERE		od.OrderID = o.OrderID
					FOR JSON PATH
				)
			) AS OrderProfitCalc;
GO

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Raw:
'; SELECT * FROM OrdersWithProfit;
PRINT 'XML:
'; SELECT * FROM GetOrdersWithProfitXML();
PRINT 'JSON:
'; SELECT * FROM GetOrdersWithProfitJSON();

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS OrderDetails;
DROP VIEW IF EXISTS OrdersWithProfit;
DROP FUNCTION IF EXISTS CalcOrderProfitXML;
DROP FUNCTION IF EXISTS GetOrdersWithProfitXML;
DROP FUNCTION IF EXISTS CalcOrderProfitJSON;
DROP FUNCTION IF EXISTS GetOrdersWithProfitJSON;
GO

SET NOCOUNT OFF;
GO