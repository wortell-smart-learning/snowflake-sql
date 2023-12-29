-- This script contains demo code for Module 6 of the Transact-SQL course



-- CREATE A TABLE FOR THE DEMOS

CREATE OR REPLACE TABLE SalesLT.Promotion
(
    PromotionID int IDENTITY (3,1 )PRIMARY KEY,
    PromotionName varchar(20),
    StartDate datetime NOT NULL DEFAULT GETDATE(),
    ProductModelID int NOT NULL REFERENCES SalesLT.ProductModel(ProductModelID),
    Discount decimal(4,2) NOT NULL,
    Notes nvarchar(100) NULL
);

-- Show it's empty
SELECT * FROM SalesLT.Promotion;



-- INSERT

-- Basic insert with all columns by position
INSERT INTO SalesLT.Promotion
VALUES
(1, 'Clearance Sale', '01/01/2021', 23, 0.1, '10% discount');

SELECT * FROM SalesLT.Promotion;


-- Use defaults and NULLs
INSERT INTO SalesLT.Promotion
VALUES
(2, 'Pull your socks up', DEFAULT, 24, 0.25, NULL);

SELECT * FROM SalesLT.Promotion;


-- Explicit columns
INSERT INTO SalesLT.Promotion (PromotionName, ProductModelID, Discount)
VALUES
('Caps Locked', 2, 0.2);

SELECT * FROM SalesLT.Promotion;

-- Multiple rows
INSERT INTO SalesLT.Promotion (PromotionName, StartDate, ProductModelID, Discount, Notes)
VALUES
('The gloves are off!', DEFAULT, 3, 0.25, NULL),
('The gloves are off!', DEFAULT, 4, 0.25, NULL);

SELECT * FROM SalesLT.Promotion;


-- Insert from query
INSERT INTO SalesLT.Promotion (PromotionName, ProductModelID, Discount, Notes)
SELECT DISTINCT 'Get Framed', m.ProductModelID, 0.1, '10% off ' || m.Name
FROM SalesLT.ProductModel AS m
WHERE m.Name ILIKE '%frame%';

SELECT * FROM SalesLT.Promotion;


-- CREATE TABLE AS SELECT (CTAS)
CREATE TABLE SalesLT.Invoice
AS
SELECT SalesOrderID, CustomerID, OrderDate, PurchaseOrderNumber, TotalDue
FROM SalesLT.SalesOrderHeader;

SELECT * FROM SalesLT.Invoice;


-- Retrieve inserted identity value
INSERT INTO SalesLT.Promotion (PromotionName, ProductModelID, Discount)
VALUES
('A short sale',13, 0.3);

-- Use time travel to retrieve the identity value at time of the last query
select max(PromotionID) from SalesLT.Promotion AT(statement=>last_query_id());

SELECT * FROM SalesLT.Promotion;

-- Override Identity
INSERT INTO SalesLT.Promotion (PromotionID, PromotionName, ProductModelID, Discount)
VALUES
(20, 'Another short sale',37, 0.3);

SELECT * FROM SalesLT.Promotion;


-- Sequences

-- Create sequence
CREATE OR REPLACE SEQUENCE SalesLT.InvoiceNumbers
START WITH 72000 INCREMENT BY 1;

-- Get next value
SELECT SalesLT.InvoiceNumbers.nextval;

-- Get next value again (automatically increments on each retrieval)
SELECT SalesLT.InvoiceNumbers.nextval;

-- Insert using next sequence value
INSERT INTO SalesLT.Invoice
VALUES
(SalesLT.InvoiceNumbers.nextval, 2, GETDATE(), 'PO12345', 107.99);

SELECT * FROM SalesLT.Invoice;




-- UPDATE

-- Update a single field
UPDATE SalesLT.Promotion
SET Notes = '25% off socks'
WHERE PromotionID = 2;

SELECT * FROM SalesLT.Promotion;


-- Update multiple fields
UPDATE SalesLT.Promotion
SET Discount = 0.2, Notes = REPLACE(Notes, '10%', '20%')
WHERE PromotionName = 'Get Framed';

SELECT * FROM SalesLT.Promotion;

-- Update from query
UPDATE SalesLT.Promotion
SET Notes = (Discount * 100)::int || '% off ' || m.Name
FROM SalesLT.ProductModel AS m
WHERE Notes IS NULL
    AND SalesLT.Promotion.ProductModelID = m.ProductModelID;

SELECT * FROM SalesLT.Promotion;



-- Delete data
DELETE FROM SalesLT.Promotion
WHERE StartDate < DATEADD(dd, -7, GETDATE());

SELECT * FROM SalesLT.Promotion;

-- Truncate to remove all rows
TRUNCATE TABLE SalesLT.Promotion;

SELECT * FROM SalesLT.Promotion;




-- Merge insert and update
-- Create a source table with staged changes (don't worry about the details)
CREATE TEMPORARY TABLE SalesLT.InvoiceStaging
AS
SELECT SalesOrderID, CustomerID, OrderDate, PurchaseOrderNumber, TotalDue * 1.1 AS TotalDue
FROM SalesLT.SalesOrderHeader
WHERE PurchaseOrderNumber = 'PO29111718'
UNION
SELECT 79999, 1, GETDATE(), 'PO54321', 202.99;

-- Here's the staged data
SELECT * FROM SalesLT.InvoiceStaging;

-- Now merge the staged changes
MERGE INTO SalesLT.Invoice as i
USING SalesLT.InvoiceStaging as s
ON i.SalesOrderID = s.SalesOrderID
WHEN MATCHED THEN
    UPDATE SET i.CustomerID = s.CustomerID,
                i.OrderDate = GETDATE(),
                i.PurchaseOrderNumber = s.PurchaseOrderNumber,
                i.TotalDue = s.TotalDue
WHEN NOT MATCHED THEN
    INSERT (SalesOrderID, CustomerID, OrderDate, PurchaseOrderNumber, TotalDue)
    VALUES (s.SalesOrderID, s.CustomerID, s.OrderDate, s.PurchaseOrderNumber, s.TotalDue);

-- View the merged table
SELECT * FROM SalesLT.Invoice
ORDER BY OrderDate DESC;
