-- This script contains demo code for Module 1 of the Transact-SQL course


-- BASIC QUERIES

-- Select all columns
SELECT * FROM SalesLT.Customer;

-- Select specific columns
SELECT CustomerID, FirstName, LastName
FROM SalesLT.Customer;

-- Select an expression
SELECT CustomerID, FirstName || ' ' || LastName
FROM SalesLT.Customer;

-- Apply an alias
SELECT CustomerID, FirstName || ' ' || LastName AS CustomerName
FROM SalesLT.Customer;




-- DATA TYPES

-- Try to combine incompatible data types (results in error)
SELECT CustomerID || ':' || EmailAddress AS CustomerIdentifier
FROM SalesLT.Customer;

-- Use cast
SELECT CAST(CustomerID AS varchar) || ':' || EmailAddress AS CustomerIdentifier
FROM SalesLT.Customer;

-- Use convert
SELECT CustomerID::varchar || ':' || EmailAddress AS CustomerIdentifier
FROM SalesLT.Customer;

-- convert dates
SELECT CustomerID,
       ModifiedDate::nvarchar(30)                 AS ConvertedDate,
	   TO_VARCHAR(ModifiedDate, 'mon dd, yyyy')    AS CustomDateFormat
FROM SalesLT.Customer;




-- NULL VALUES

-- See the effect of expressions with NULL values
SELECT CustomerID, Title, LastName, Title || ' ' || LastName AS Greeting
FROM SalesLT.Customer;

-- Replace NULL value (use ? if Title is NULL)
SELECT CustomerID, IFNULL(Title, '?') || ' ' || LastName AS Greeting
FROM SalesLT.Customer;

-- Coalesce (use first non-NULL value)
SELECT CustomerID, COALESCE(Title, FirstName) || ' ' || LastName AS Greeting
FROM SalesLT.Customer;

-- Convert specific values to NULL
SELECT SalesOrderID, ProductID, UnitPrice, NULLIF(UnitPriceDiscount, 0) AS Discount
FROM SalesLT.SalesOrderDetail;




-- CASE statement

--Simple case
SELECT  CustomerID,
        CASE
            WHEN Title IS NOT NULL AND MiddleName IS NOT NULL
                THEN Title || ' ' || FirstName || ' ' || MiddleName || ' ' || LastName
            WHEN Title IS NOT NULL AND MiddleName IS NULL
                THEN Title || ' ' || FirstName || ' ' || LastName
            ELSE FirstName || ' ' || LastName
        END AS CustomerName
FROM SalesLT.Customer;

-- Searched case
SELECT  FirstName, LastName,
        CASE Suffix
            WHEN 'Sr.' THEN 'Senior'
            WHEN 'Jr.' THEN 'Junior'
            ELSE IFNULL(Suffix, '')
        END AS NameSuffix
FROM SalesLT.Customer;
