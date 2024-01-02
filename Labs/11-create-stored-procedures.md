---
lab:
    title: 'Create stored procedures in Snowflake SQL'
    module: 'Additional exercises'
---

# Create stored procedures in  Snowflake SQL

In this lab, you'll use SQL statements to create and understand stored procedure techniques in the **adventureworks** database. For your reference, the following diagram shows the tables in the database (you may need to resize the pane to see them clearly).

![An entity relationship diagram of the adventureworks database](./Images/adventureworks-erd.png)

> **Note**: If you're familiar with the standard **AdventureWorks** sample database, you may notice that in this lab we are using a simplified version that makes it easier to focus on learning Snowflake SQL syntax.

## Create and execute stored procedures

1. Create a new worksheet and connect to the database and warehouse.
1. Type the following SQL code:
    
    ``` 
    CREATE OR REPLACE PROCEDURE SalesLT.TopProducts ()
    RETURNS TABLE (name NVARCHAR(50), listprice NUMBER(10,4))
    LANGUAGE SQL
    AS
    $$
    DECLARE
      res RESULTSET DEFAULT (
                SELECT TOP 10  name, listprice
        		FROM SalesLT.Product
        		GROUP BY name, listprice
        		ORDER BY listprice DESC
                );
    BEGIN
      RETURN TABLE(res);
    END;
    $$
    ```
    
1. Select **&#x23f5;Run**. You've created a stored procedure named SalesLT.TopProducts.
1. In the worksheet, type the following SQL code after the previous code:

    ```
    CALL SalesLT.TopProducts();
    ```

1. Highlight the written SQL code and click **&#x23f5;Run**. You've now executed the stored procedure.
1. Now modify the stored procedure so that it returns only products from a specific product category by adding an input parameter. In the query pane, type the following SQL code:

    ```
    CREATE OR REPLACE PROCEDURE SalesLT.TopProducts (ProductCategoryID int)
    RETURNS TABLE (name NVARCHAR(50), listprice NUMBER(10,4))
    LANGUAGE SQL
    AS
    $$
    DECLARE
      select_statement VARCHAR;
      res RESULTSET;
    BEGIN
      select_statement := 'SELECT TOP 10  name, listprice
        		FROM SalesLT.Product
                WHERE ProductCategoryID = ' || ProductCategoryID ||
        	   'GROUP BY name, listprice
        		ORDER BY listprice DESC';
      res := (EXECUTE IMMEDIATE :select_statement);
      RETURN TABLE(res);
    END;
    $$
    ```
    
1. In the query pane, type the following T-SQL code:

    ```
    CALL SalesLT.TopProducts(18);
    ```

1. Highlight the written SQL code and click **&#x23f5;Run** to execute the stored procedure, passing the parameter value.

## Create an inline table valued function

1. In the query pane, type the following SQL code:

    ```
    CREATE OR REPLACE FUNCTION SalesLT.GetFreightbyCustomer(p_orderyear INT) 
    RETURNS TABLE (CustomerID INT, TotalFreight NUMBER(10,4))
    LANGUAGE SQL
    AS
    $$
    SELECT   CustomerID, 
             SUM(freight) AS totalfreight
    FROM     SalesLT.SalesOrderHeader
    WHERE    YEAR(orderdate) = p_orderyear
    GROUP BY customerid
    $$
    ```

1. Highlight the written SQL code and click **&#x23f5;Run** to create the table-valued function.

### Challenge

1. Run the table-valued function to return data for the year 2008.

### Challenge answer

```
SELECT * FROM TABLE(SalesLT.GetFreightbyCustomer(2008))
```
