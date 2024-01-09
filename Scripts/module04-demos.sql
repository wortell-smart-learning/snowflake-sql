-- This script contains demo code for Module 5 of the Snowflake SQL course



-- Basic scalar functions

-- Dates
SELECT  SalesOrderID,
	    OrderDate,
        YEAR(OrderDate) AS OrderYear,
        MONTHNAME(OrderDate) AS OrderMonth,
        DAY(OrderDate) AS OrderDay,
        DAYNAME(OrderDate) AS OrderWeekDay,
        DATEDIFF(yy,OrderDate, GETDATE()) AS YearsSinceOrder
FROM SalesLT.SalesOrderHeader;


-- Math
SELECT TaxAmt,
       ROUND(TaxAmt, 0) AS Rounded,
       FLOOR(TaxAmt) AS Floor,
       CEIL(TaxAmt) AS Ceiling,
       SQUARE(TaxAmt) AS Squared,
       SQRT(TaxAmt) AS Root,
       LN(TaxAmt) AS Log,
       TaxAmt * UNIFORM(0::float,1::float,RANDOM()) AS Randomized
FROM SalesLT.SalesOrderHeader;


-- Text
SELECT  CompanyName,
        UPPER(CompanyName) AS UpperCase,
        LOWER(CompanyName) AS LowerCase,
        LEN(CompanyName) AS Length,
        REVERSE(CompanyName) AS Reversed,
        CHARINDEX(' ', CompanyName) AS FirstSpace,
        LEFT(CompanyName, CHARINDEX(' ', CompanyName)) AS FirstWord,
        SUBSTRING(CompanyName, CHARINDEX(' ', CompanyName) + 1, LEN(CompanyName)) AS RestOfName
FROM SalesLT.Customer;




-- Logical

-- IFF
SELECT AddressType, -- Evaluation       if True    if False    
       IFF(AddressType = 'Main Office', 'Billing', 'Mailing') AS UseAddressFor
FROM SalesLT.CustomerAddress;




-- RANKING Functions

-- Ranking
SELECT TOP 100 ProductID, Name, ListPrice,
	RANK() OVER(ORDER BY ListPrice DESC) AS RankByPrice
FROM SalesLT.Product AS p
ORDER BY RankByPrice;

-- Partitioning
SELECT c.Name AS Category, p.Name AS Product, ListPrice,
	RANK() OVER(PARTITION BY c.Name ORDER BY ListPrice DESC) AS RankByPrice
FROM SalesLT.Product AS p
JOIN SalesLT.ProductCategory AS c
ON p.ProductCategoryID = c.ProductcategoryID
ORDER BY Category, RankByPrice;




-- Use PARSE_XML to read data from an XML document into a rowset. XMLGET to navigate the XML object.
SELECT PARSE_XML('<Reviews>
             <Review ProductID="1" Reviewer="Paul Henriot">
               <ReviewText>This is a really great product!</ReviewText>
             </Review>
             <Review ProductID="7" Reviewer="Carlos Gonzlez">
               <ReviewText>Fantasic - I love this product!!</ReviewText>
             </Review>
            </Reviews>') AS column1;


-- Use OPENJSON to read a JSON document
-- First prepare a JSON document
SET jsonCustomer = '{
                      "id" : 1,
                      "firstName": "John",
                      "lastName": "Smith",
                      "dateOfBirth": "2015-03-25T12:00:00"
                    }';
-- Now parse the JSON values into an object  
SELECT PARSE_JSON($jsonCustomer);

-- We can use the colon to navigate the object  
SELECT PARSE_JSON($jsonCustomer):firstName;


-- Aggregate functions and GROUP BY

-- Aggregate functions
SELECT COUNT(*) AS ProductCount,
       MIN(ListPrice) AS MinPrice,
       MAX(ListPrice) AS MaxPrice,
       AVG(ListPrice) AS AvgPrice
FROM SalesLT.Product;


-- Group by
SELECT c.Name AS Category,
       COUNT(*) AS ProductCount,
       MIN(p.ListPrice) AS MinPrice,
       MAX(p.ListPrice) AS MaxPrice,
       AVG(p.ListPrice) AS AvgPrice
FROM SalesLT.ProductCategory AS c
JOIN SalesLT.Product AS p
    ON p.ProductCategoryID = c.ProductCategoryID
GROUP BY Category
ORDER BY Category;

-- Filter aggregated groups
-- How NOT to do it!
SELECT c.Name AS Category,
       COUNT(*) AS ProductCount,
       MIN(p.ListPrice) AS MinPrice,
       MAX(p.ListPrice) AS MaxPrice,
       AVG(p.ListPrice) AS AvgPrice
FROM SalesLT.ProductCategory AS c
JOIN SalesLT.Product AS p
    ON p.ProductCategoryID = c.ProductCategoryID
WHERE COUNT(*) > 1 -- Attempt to filter on grouped aggregate = error!
GROUP BY c.Name
ORDER BY Category;

-- How to do it
SELECT c.Name AS Category,
       COUNT(*) AS ProductCount,
       MIN(p.ListPrice) AS MinPrice,
       MAX(p.ListPrice) AS MaxPrice,
       AVG(p.ListPrice) AS AvgPrice
FROM SalesLT.ProductCategory AS c
JOIN SalesLT.Product AS p
    ON p.ProductCategoryID = c.ProductCategoryID
GROUP BY c.Name
HAVING COUNT(*) > 1 -- Use HAVING to filter after grouping
ORDER BY Category;
