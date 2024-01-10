---
lab:
    title: 'Implement transactions with Snowflake SQL'
    module: 'Additional exercises'
---

# Implement transactions with Snowflake SQL

In this lab, you'll use SQL statements to see the impact of using transactions in the **AdventureWorks** database. For your reference, the following diagram shows the tables in the database (you may need to resize the pane to see them clearly).

![An entity relationship diagram of the AdventureWorks database](./Images/adventureworks-erd.png)

> **Note**: If you're familiar with the standard **AdventureWorks** sample database, you may notice that in this lab we are using a simplified version that makes it easier to focus on learning Snowflake SQL syntax.

## Insert data without transactions

Consider a website that needs to store customer information. As part of the customer registration, data about a customer and their address need to stored. A customer without an address will cause problems for the shipping when orders are made.

In this exercise you'll use a transaction to ensure that when a row is inserted into the **Customer** and **Address** tables, a row is also added to the **CustomerAddress** table. If one insert fails, then all will fail.

1. Create a new worksheet and connect to the database and warehouse.
1. Enter the following T-SQL code into the query window:

    ```
    INSERT INTO SalesLT.Customer (CustomerID, NameStyle, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt) 
    VALUES (DEFAULT, 0,  'Norman','Newcustomer','norman0@adventure-works.com','U1/CrPqSzwLTtwgBehfpIl7f1LHSFpZw1qnG1sMzFjo=','QhHP+y8=');
    
    INSERT INTO SalesLT.Address (AddressID, AddressLine1, City, StateProvince, CountryRegion, PostalCode) 
    VALUES (DEFAULT, '6388 Lake City Way', 'Burnaby','British Columbia','Canada','V5A 3A6');

    SET CustomerID = (SELECT MAX(CustomerID)FROM SalesLT.Customer);
    SET AddressID = (SELECT MAX(AddressID)FROM SalesLT.Address);
    
    INSERT INTO SalesLT.CustomerAddress (CustomerID, AddressID, AddressType, ModifiedDate)
    VALUES ($CustomerID, $AddressID, 'Home', '12-1-20212'); 
    ```

1. Select **&#x23f5;Run** at the top of the query window, or press the <kbd>Ctrl+Enter</kbd> keys to run the code.
1. Note the output messages, which should look like this:

    > Timestamp '12-1-20212' is not recognized

    Four of the statements appear to have succeeded, but the fifth failed.

1. Enter the following SQL code below the current code and run it:

    ```
    SELECT * FROM SalesLT.Customer ORDER BY ModifiedDate DESC;
    ```

    A row for *Norman Newcustomer* was inserted into the Customer table (and another was inserted into the Address table). However, the insert for the CustomerAddress table failed with a duplicate key error. The database is now inconsistent as there's no link between the new customer and their address.

    To fix this, you'll need to delete the two rows that were inserted.

1. Enter the following SQL code into the worksheet and run it to delete the inconsistent data:

    ```
    DELETE FROM SalesLT.Customer
    WHERE CustomerID = $CustomerID;

    DELETE FROM SalesLT.Address
    WHERE AddressID = $AddressID;
    ```

    > **Note**: This code only works because you are the only user working in the database. In a real scenario, you would need to ascertain the IDs of the records that were inserted and specify them explicitly in case new customer and address records had been inserted since you ran your original code.

## Insert data as using a transaction

All of these statements need to run as a single atomic transaction. If any one of them fails, then all statements should fail. Let's group them together in a transaction.

1. Replace the original INSERT query script, and modify the transaction as follows:

    ```
    EXECUTE IMMEDIATE 
    $$
        BEGIN
        
            BEGIN TRANSACTION;
            
            INSERT INTO SalesLT.Customer (CustomerID, NameStyle, FirstName, LastName, EmailAddress, PasswordHash, PasswordSalt) 
            VALUES (DEFAULT, 0,  'Norman','Newcustomer','norman0@adventure-works.com','U1/CrPqSzwLTtwgBehfpIl7f1LHSFpZw1qnG1sMzFjo=','QhHP+y8=');
            
            INSERT INTO SalesLT.Address (AddressID, AddressLine1, City, StateProvince, CountryRegion, PostalCode) 
            VALUES (DEFAULT, '6388 Lake City Way', 'Burnaby','British Columbia','Canada','V5A 3A6');
        
            SET CustomerID = (SELECT MAX(CustomerID)FROM SalesLT.Customer);
            SET AddressID = (SELECT MAX(AddressID)FROM SalesLT.Address);
            
            INSERT INTO SalesLT.CustomerAddress (CustomerID, AddressID, AddressType, ModifiedDate)
            VALUES ($CustomerID, $AddressID, 'Home', '12-1-20212'); 
        
            COMMIT;
            RETURN 'Transaction committed';
        EXCEPTION
            WHEN OTHER THEN
                ROLLBACK;
                RETURN 'Transaction rolled back';
        END;
    $$
    ;
    ``` 

1. Run the modified code. The output message this time is:

    > Transaction rolled back

1. Run the SELECT customer query to see if the *Norman Newcustomer* row was added.

    Note that the most recently modified customer record is <u>not</u> for *Norman Newcustomer* - the INSERT statement that succeeded has been rolled back to ensure the database remains consistent.

## Challenge

Now it's time to try using what you've learned.

> **Tip**: Try to determine the appropriate solution for yourself. If you get stuck, a suggested solution is provided at the end of this lab.

### Use a transaction to insert data into multiple tables

When a sales order header is inserted, it must have at least one corresponding sales order detail record. Currently, you use the following code to accomplish this:

```
EXECUTE IMMEDIATE 
$$
    BEGIN
        -- Get the highest order ID and add 1        
        LET SalesOrderID INT := (SELECT MAX(SalesOrderID) + 1 FROM SalesLT.SalesOrderHeader);
         
        -- Insert the order header
        EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderHeader (SalesOrderID, OrderDate, DueDate, CustomerID, ShipMethod)
            VALUES (?, GETDATE(), DATEADD(month, 1, GETDATE()), 1, \'CARGO TRANSPORT\')' USING (SalesOrderID);
        
        -- Insert one or more order details
        EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderDetail (SalesOrderID, OrderQty, ProductID, UnitPrice)
            VALUES (?, 1, 712, 8.99)' USING (SalesOrderID);

        RETURN 'Transaction committed';
    END;
$$
;
```

You need to encapsulate this code in a transaction so that all inserts succeed or fail as an atomic unit or work.

## Challenge solution

### Use a transaction to insert data into multiple tables

The following code encloses the logic to insert a new order and order detail in a transaction, rolling back the transaction if an error occurs.

```
    EXECUTE IMMEDIATE 
    $$
        BEGIN
        
            BEGIN TRANSACTION;
            
            -- Get the highest order ID and add 1        
            LET SalesOrderID INT := (SELECT MAX(SalesOrderID) + 1 FROM SalesLT.SalesOrderHeader);
             
            -- Insert the order header
            EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderHeader (SalesOrderID, OrderDate, DueDate, CustomerID, ShipMethod)
                VALUES (?, GETDATE(), DATEADD(month, 1, GETDATE()), 1, \'CARGO TRANSPORT\')' USING (SalesOrderID);
            
            -- Insert one or more order details
            EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderDetail (SalesOrderID, OrderQty, ProductID, UnitPrice)
                VALUES (?, 1, 712, 8.99)' USING (SalesOrderID);

            COMMIT;
            RETURN 'Transaction committed';
        EXCEPTION
            WHEN OTHER THEN
                ROLLBACK;
                RETURN 'Transaction rolled back';
        END;
    $$
    ;
```

To test the transaction, try to insert an order detail with an invalid product ID, like this:

```
    EXECUTE IMMEDIATE 
    $$
        BEGIN
        
            BEGIN TRANSACTION;
            
            -- Get the highest order ID and add 1        
            LET SalesOrderID INT := (SELECT MAX(SalesOrderID) + 1 FROM SalesLT.SalesOrderHeader);
             
            -- Insert the order header
            EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderHeader (SalesOrderID, OrderDate, DueDate, CustomerID, ShipMethod)
                VALUES (?, GETDATE(), DATEADD(month, 1, GETDATE()), 1, \'CARGO TRANSPORT\')' USING (SalesOrderID);
            
            -- Insert one or more order details
            EXECUTE IMMEDIATE 'INSERT INTO SalesLT.SalesOrderDetail (SalesOrderID, OrderQty, ProductID, UnitPrice)
                VALUES (?, 1, \'Invalid product\', 8.99)' USING (SalesOrderID);

            COMMIT;
            RETURN 'Transaction committed';
        EXCEPTION
            WHEN OTHER THEN
                ROLLBACK;
                RETURN 'Transaction rolled back';
        END;
    $$
    ;
```

## Overzicht
Dit was de laatste module. Hieronder vind je een overzicht van alle modules:

1. [Get Started with Snowflake SQL](./01-get-started-with-snowflake-sql.md)
2. [Sort and Filter Query Results](./02-filter-sort.md)
3. [Query Multiple Tables with Joins](./03a-joins.md)
4. [Use Subqueries](./03b-subqueries.md)
5. [Use Built-in Functions](./04-built-in-functions.md)
6. [Modify Data](./05-modify-data.md)
7. [Create queries with table expressions](./06-use-table-expressions.md)
8. [Combine query results with set operators](./07-combine-query-results.md)
9. [Use window functions](./08-create-window-query-functions.md)
10. [Use pivoting and grouping sets](./09-transform-data.md)
11. [Introduction to programming with SQL](./10-program-with-sql.md)
12. [Create stored procedures in Snowflake SQL](./11-create-stored-procedures.md)
13. [Implement error handling with Snowflake SQL](./12-implement-error-handling.md)
14. [Implement transactions with Snowflake SQL](./13-implement-transitions-in-tsql.md) (huidige module)
