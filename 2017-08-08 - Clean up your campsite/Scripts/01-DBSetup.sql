USE Test;
GO

DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS OrderStatuses;
DROP TABLE IF EXISTS Emails;

CREATE TABLE Emails
(
	EmailTo varchar(500),
	EmailBody varchar(8000),
	EmailSubject varchar(500),
	EmailOrderIDCalc AS (CONVERT(int,RIGHT(EmailSubject,CHARINDEX('#',REVERSE(EmailSubject))-1))) PERSISTED
);

CREATE CLUSTERED INDEX IDX_EmailOrderCalc ON Emails(EmailOrderIDCalc);

CREATE TABLE Customers
(
	CustomerID int PRIMARY KEY IDENTITY,
	Customer varchar(100),
	CustomerEmail varchar(500),
	CustomerMarkup numeric(19,6), /* Multiply product price by this value to determine gross charges. */
	CustomerVolumeDiscountThreshold int, /* If total quantity of products meets or exceeds this value, then apply the discount. */
	CustomerVolumeDiscount numeric(19,6), /* Percentage discount off the gross charges. */
	CustomerInactive bit,
	CONSTRAINT CK_CustomerVolumeDiscountThreshold CHECK (CustomerVolumeDiscountThreshold > 0),
	CONSTRAINT CK_CustomerVolumeDiscount CHECK (CustomerVolumeDiscount >= 0 AND CustomerVolumeDiscount < 1)
);

CREATE TABLE Products
(
	ProductID int PRIMARY KEY IDENTITY,
	Product varchar(100),
	ProductPrice numeric(19,4)
)

CREATE TABLE OrderStatuses
(
	OrderStatusID int PRIMARY KEY IDENTITY,
	OrderStatus varchar(100)
);

CREATE TABLE Orders
(
	OrderID int PRIMARY KEY IDENTITY,
	OrderDate datetimeoffset,
	CustomerID int,
	OrderStatusID int,
	OrderInvoiceAmount numeric(19,2),
	OrderInvoiceDate datetimeoffset,
	CONSTRAINT FK_CustomerID FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
	CONSTRAINT FK_OrderStatusID FOREIGN KEY (OrderStatusID) REFERENCES OrderStatuses(OrderStatusID)
);

CREATE INDEX IX_Orders_CustomerID ON Orders(CustomerID);
CREATE INDEX IX_Order_OrderStatusID ON Orders(OrderStatusID);

CREATE TABLE OrderDetails
(
	OrderDetailID int PRIMARY KEY IDENTITY,
	OrderID int,
	ProductID int,
	Qty int,
	CONSTRAINT FK_OrderID FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
	CONSTRAINT FK_ProductID FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE INDEX IX_OrderDetails_OrderID ON OrderDetails(OrderID);
CREATE INDEX IX_OrderDetails_ProductID ON OrderDetails(ProductID);

/* If you don't put a "GO" here, and the tables already exist in an invalid form, the engine will throw errors for missing columns. */
GO

/* Add Order Statuses */
INSERT INTO OrderStatuses (OrderStatus) VALUES ('New'),('Processed'),('Rejected'),('Prepared'),('Invoiced'),('Shipped'),('Complete');

/* Add list of example customers */
INSERT INTO Customers (Customer) VALUES ('Lorem Associates'),('Purus In Molestie Associates'),('Non Nisi Corporation'),('Libero At Auctor PC'),('Nec Limited'),('Non Lobortis Corp.'),('Auctor Company'),('Semper Erat In Corporation'),('Consequat Auctor Company'),('Sapien Institute'),('Ut Odio Inc.'),('Mauris Morbi PC'),('Nunc Est Mollis Institute'),('Magna PC'),('Inceptos Hymenaeos Mauris LLC'),('Magnis Dis Parturient Foundation'),('Mus Associates'),('Malesuada Vel Industries'),('Sodales Nisi Limited'),('Tempor Est Ac Industries'),('Vehicula Risus Nulla Associates'),('Vitae LLP'),('Vehicula Institute'),('Tellus Faucibus PC'),('Dictum Augue Inc.'),('Dolor LLC'),('Lorem Industries'),('In Magna Phasellus Corporation'),('Ac Eleifend Ltd'),('Congue Elit Sed Institute'),('Ipsum Foundation'),('Malesuada Vel Industries'),('Aliquam Auctor Velit LLP'),('Cras LLC'),('Eu Limited'),('Tempor Foundation'),('Eget Lacus Inc.'),('Tempus Lorem Fringilla Foundation'),('Nec Enim PC'),('Velit In Consulting'),('Ut LLC'),('Scelerisque PC'),('Metus Ltd'),('Consectetuer PC'),('Nec Urna Consulting'),('Amet Risus Donec Ltd'),('In Mi Pede Corp.'),('Placerat Cras Ltd'),('Ultrices Duis Volutpat Limited'),('Porttitor Interdum Sed Corporation'),('Et Company'),('Rhoncus Nullam PC'),('Sit Corporation'),('Vel Est Tempor Corporation'),('Arcu Nunc LLP'),('Elit Incorporated'),('Vitae Consulting'),('Feugiat Incorporated'),('Non Vestibulum LLC'),('Commodo At Company'),('Adipiscing Corp.'),('Aenean Sed Pede Corp.'),('Odio Etiam PC'),('Dis Parturient Montes LLP'),('Ultricies Inc.'),('Sit PC'),('A Tortor Nunc Inc.'),('Nisi Nibh Foundation'),('Dui Company'),('Nunc LLC'),('Nunc Incorporated'),('Pellentesque Sed Foundation'),('Aliquam Adipiscing Inc.'),('Penatibus Et Magnis Inc.'),('Nunc Ac Company'),('Dapibus Ligula Aliquam Corp.'),('Nibh Enim Gravida PC'),('Urna LLC'),('Sit Corporation'),('Aenean LLP'),('Vel Quam Dignissim Company'),('Class Aptent LLC'),('Nam Interdum Foundation'),('Posuere Cubilia Curae; LLP'),('Pede Nonummy Ut Limited'),('Congue Inc.'),('Fames Ac Consulting'),('Magna Inc.'),('At Augue Limited'),('Justo Eu Arcu Consulting'),('Enim Consequat Company'),('Facilisis Industries'),('Eros Proin LLC'),('Consectetuer Mauris Id Institute'),('Parturient Montes Nascetur Foundation'),('Ut Associates'),('Lacus Aliquam Rutrum Corporation'),('Libero Morbi Accumsan Industries'),('Est Company'),('Nibh Sit Corporation');
UPDATE		Customers
SET			CustomerEmail = REPLACE(Customer,' ','') + '@example.com',
			CustomerInactive = CONVERT(bit,CONVERT(numeric(19,0),RAND(CHECKSUM(NEWID())))),
			CustomerVolumeDiscountThreshold = CONVERT(int,RAND(CHECKSUM(NEWID()))*50)+1,
			CustomerVolumeDiscount = RAND(CHECKSUM(NEWID()))*0.75,
			CustomerMarkup = RAND(CHECKSUM(NEWID())) + 1;

/* Add list of products (vegetables) with a random price under $11 */
INSERT INTO Products (Product, ProductPrice)
	SELECT		*
	FROM		(
					VALUES ('Artichoke'),('Arugula'),('Asparagus'),('Eggplant'),('Amaranth'),('Alfalfa sprouts'),('Azuki beans'),('Bean sprouts'),('Black beans'),('Black-eyed peas'),('Borlotti bean'),('Broad beans'),('Chickpeas'),('Green beans'),('Kidney beans'),('Lentils'),('Lima beans'),('Mung beans'),('Navy beans'),('Pinto beans'),('Runner beans'),('Split peas'),('Soy beans'),('Peas'),('Snap peas'),('Beet greens'),('Bok choy'),('Broccoli'),('Brussels sprouts'),('Cabbage'),('Calabrese'),('Carrots'),('Cauliflower'),('Celery'),('Chard'),('Collard greens'),('Corn salad'),('Endive'),('Fiddleheads'),('Frisee'),('Fennel'),('Kale'),('Kohlrabi'),('Lettuce'),('Corn'),('Mushrooms'),('Mustard greens'),('Nettles'),('Okra'),('Chives'),('Garlic'),('Leek'),('Onion'),('Shallot'),('Scallion'),('Green pepper'),('Red pepper'),('Chili pepper'),('Jalapeño'),('Habanero'),('Paprika'),('Tabasco pepper'),('Cayenne pepper'),('Radicchio'),('Rhubarb'),('Beet'),('Carrot'),('Celeriac'),('Daikon'),('Ginger'),('Parsnip'),('Turnip'),('Radish'),('Rutabaga'),('Wasabi'),('Horseradish'),('White radish'),('Salsify'),('Skirret'),('Spinach'),('Topinambur'),('Acorn squash'),('Butternut squash'),('Banana squash'),('Zucchini'),('Cucumber'),('Delicata'),('Gem squash'),('Hubbard squash'),('Squash'),('Patty pans'),('Pumpkin'),('Spaghetti squash'),('Tat soi'),('Tomato'),('Tubers'),('Jicama'),('Jerusalem artichoke'),('Potato'),('Sunchokes'),('Sweet potato'),('Taro'),('Yam'),('Turnip greens'),('Water chestnut'),('Watercress'),('Zucchini')
				) AS Vegetable(VegetableName)
	CROSS APPLY	(
					SELECT
						Price = CONVERT(numeric(19,4),RAND(CHECKSUM(NEWID()))*10)+1
				) AS t;

DECLARE
	@CustomerCount int,
	@ProductCount int,
	@OrderStatusCount int;
SELECT
	@CustomerCount = COUNT(*)
FROM		Customers;
SELECT
	@ProductCount = COUNT(*)
FROM		Products;
SELECT
	@OrderStatusCount = COUNT(*)
FROM		OrderStatuses;

WITH r AS
(
	SELECT * FROM (VALUES (1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1),(1)) AS r(n)
)
INSERT INTO Orders
(
	OrderDate, CustomerID, OrderStatusID
)
SELECT
	OrderDate, CustomerID, OrderStatusID
FROM		(
				SELECT
					TOP 1000
					OrderDate = DATEADD(SECOND,-1*CONVERT(numeric(19,4),RAND(CHECKSUM(NEWID()))*10000000),SYSDATETIMEOFFSET()),
					CustomerID = CONVERT(int,RAND(CHECKSUM(NEWID()))*@CustomerCount)+1,
					OrderStatusID = CONVERT(int,RAND(CHECKSUM(NEWID()))*@OrderStatusCount)+1
				FROM		r CROSS JOIN r r2 CROSS JOIN r r3 CROSS JOIN r r4 CROSS JOIN r r5 CROSS JOIN r r6 CROSS JOIN r r7
			) AS t;

INSERT INTO OrderDetails
(
	OrderID, ProductID,	Qty
)
SELECT
	OrderID, ProductID,	Qty
FROM		(
				SELECT
					OrderID = o.OrderID,
					ProductID = p.ProductID,
					Qty =  CONVERT(int,RAND(CHECKSUM(NEWID()))*20)+1
				FROM		Orders AS o
				CROSS JOIN	Products AS p
				CROSS APPLY	(
								SELECT
									RandNum = RAND(CHECKSUM(NEWID()))
							) AS RandNums
				WHERE		RandNums.RandNum < 0.05
			) AS t;


SELECT		TOP 100 *
FROM		OrderStatuses;

SELECT		TOP 100 *
FROM		Customers;

SELECT		TOP 100 *
FROM		Products;

SELECT		TOP 100 *
FROM		Orders;

SELECT		TOP 100 *
FROM		OrderDetails;