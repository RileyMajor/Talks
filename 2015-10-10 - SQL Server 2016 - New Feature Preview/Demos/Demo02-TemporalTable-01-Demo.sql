USE SS16Test;

IF OBJECT_ID('dbo.Orders','U') IS NOT NULL
BEGIN
	DROP TABLE dbo.Orders;
END
IF OBJECT_ID('dbo.OrderDetails','U') IS NOT NULL
BEGIN
	ALTER TABLE dbo.OrderDetails SET ( SYSTEM_VERSIONING = OFF );
	DROP TABLE dbo.OrderDetails;
END
IF OBJECT_ID('dbo.OrderDetailsHistory','U') IS NOT NULL
BEGIN
	DROP TABLE dbo.OrderDetailsHistory;
END

CREATE TABLE Orders
	(
		OrderID bigint IDENTITY PRIMARY KEY,
		OrderDate datetime
	);

CREATE TABLE OrderDetails
	(
		OrderDetailID bigint IDENTITY PRIMARY KEY,
		OrderID bigint,
		ProductID varchar(50),
		Qty int,
		EffectiveStart datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
		EffectiveStop datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
		PERIOD FOR SYSTEM_TIME (EffectiveStart, EffectiveStop)
	)
	WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.OrderDetailsHistory));

INSERT INTO Orders
(
	OrderDate
)
VALUES
	('2015-10-10'),
	('2015-10-09');

INSERT INTO OrderDetails (OrderID, ProductID, Qty)
	VALUES
		(1,'Bike',2),
		(1,'Helmet',2),
		(1,'Wheels',4),
		(2,'Ball',10);

WAITFOR DELAY '00:00:01';

DECLARE
	@dt datetime2 = getUTCdate();

WAITFOR DELAY '00:00:01';

SELECT		*
FROM		OrderDetails
ORDER BY	OrderDetailID;

UPDATE OrderDetails
SET Qty *= 2
WHERE OrderID = 1;

SELECT		*
FROM		OrderDetails
ORDER BY	OrderDetailID;

INSERT INTO OrderDetails (OrderID, ProductID, Qty)
	VALUES
		(1,'Seat',2);

SELECT		*
FROM		OrderDetails
ORDER BY	OrderDetailID;

DELETE OrderDetails
WHERE OrderID = 1
AND ProductID = 'Helmet';

SELECT		*
FROM		OrderDetails
ORDER BY	OrderDetailID;

/*
UPDATE		OrderDetails
SET			EffectiveStop = getUTCdate();
*/

SELECT		*
FROM		OrderDetailsHistory
ORDER BY	OrderDetailID;

SELECT		*
FROM		OrderDetails
FOR SYSTEM_TIME AS OF @dt
ORDER BY	OrderDetailID;

SELECT st.name, st.object_id, sp.partition_id, sp.partition_number, sp.data_compression, 
sp.data_compression_desc FROM sys.partitions SP
INNER JOIN sys.tables ST ON
st.object_id = sp.object_id
WHERE data_compression <> 0