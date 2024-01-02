---
lab:
    title: 'Introduction to programming with T-SQL'
    module: 'Additional exercises'
---

# Introduction to programming with SQL

In this lab, you'll use get an introduction to programming using SQL techniques using the **adventureworks** database. For your reference, the following diagram shows the tables in the database (you may need to resize the pane to see them clearly).

![An entity relationship diagram of the adventureworks database](./Images/adventureworks-erd.png)

> **Note**: If you're familiar with the standard **AdventureWorks** sample database, you may notice that in this lab we are using a simplified version that makes it easier to focus on learning Snowflake SQL syntax.

## Declare variables and retrieve values

1. Create a new worksheet and connect to the database and warehouse.
1. In the query pane, type the following T-SQL code:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE
      num INTEGER;
    BEGIN
      num := 5;
      RETURN num;
    END;
    $$
;
    ```

1. Highlight the above T-SQL code and select **&#x23f5;Run**.
1. This will give the result:

   | anonymous block |
   | -------- |
   | 5 |

1. In the query pane, type the following T-SQL code after the previous one:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE
      num1 INTEGER;
      num2 INTEGER;
      totalnum INTEGER;
    BEGIN
      num1 := 4;
      num2 := 6;
      totalnum := num1 + num2;
      RETURN totalnum;
    END;
    $$
    ;
    ```

1. Highlight the written T-SQL code and select **&#x23f5;Run**.
1. This will give the result:

   | anonymous block |
   | -------- |
   | 10 |

   You've now seen how to call a snowflake script, declare and assign variables and how to retrieve values.

## Use variables with batches

Now, we'll look at how to declare variables in batches.

1. In worksheet, type the following Snowflake scripting code:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE
      empname NVARCHAR(30);
      empid INTEGER;
    BEGIN
      empid := 5;
      empname := (SELECT FirstName || ' ' || LastName FROM SalesLT.Customer WHERE CustomerID = :empid);
      RETURN empname;
    END;
    $$
    ;
    ```

1. Highlight the written SQL script and Select **&#x23f5;Run**.
1. This will give you this result:

   | anonymous block |
   | -------- |
   | Lucy Harrington |

1. Change the @empid variable’s value from 5 to 2 and execute the modified SQL script you'll get:

   | anonymous block |
   | -------- |
   | Keith Harris |

1. Now, in the code you just copied, add this statement:

   ```
   SELECT :empname AS employee;
   ```

1. Make sure your SQL script looks like this:

   ```
    EXECUTE IMMEDIATE $$
    DECLARE
      empname NVARCHAR(50);
      empid INTEGER;
    BEGIN
      empid := 2;
      empname := (SELECT FirstName || ' ' || LastName FROM SalesLT.Customer WHERE CustomerID = :empid);
      RETURN empname;
    END;
    $$
    ;
    SELECT :empname AS employee;
    ```

1. Highlight the written SQL script and select **&#x23f5;Run****.
1. Observe the error:

    Error: Bind variable :empname not set. (line 12)

Variables are local to the block in which they're defined. If you try to refer to a variable that was defined in another block, you get an error saying that the variable wasn't defined. 

## Write basic conditional logic

1. In the query pane, type the following SQL script:

    ```
    EXECUTE IMMEDIATE $$
    BEGIN
      LET i := 8;
      IF (i < 5) THEN
          return 'Less than 5';
      ELSEIF (i <= 10) THEN
          return 'Between 5 and 10';
      ELSEIF (i > 10) THEN
          return 'More than 10';
      ELSE
          return 'Unknown';
      END IF;
    END;
    $$
    ;
    ```

1. Highlight the written SQL script and select **&#x23f5;Run**. The LET keyword lets you declare and assign a variable in one statement.
1. Which should result in:

   | anonymous block |
   | -------- |
   | Between 5 and 10 |

1. In the query pane, type the following SQL script after the previous code:

    ```
    EXECUTE IMMEDIATE $$
    BEGIN
      LET i := 8;
      CASE 
        WHEN i < 5 THEN
          return 'Less than 5';
        WHEN i <= 10 THEN
          return 'Between 5 and 10';
        WHEN (i > 10) THEN
          return 'More than 10';
      ELSE
          return 'Unknown';
      END;
    END;
    $$
    ;
    ```

This code uses a CASE expression to get the same result as the previous SQL script. Both variations allow you to retun an expression or execute multiple statements for each branch.

1. Highlight the written SQL script and select **&#x23f5;Run**.
1. Which should result in the same answer that we had before:

   | anonymous block |
   | -------- |
   | Between 5 and 10 |

## Execute loops with WHILE statements

1. Right click on the TSQL connection and select **New Query**
1. In the query pane, type the following T-SQL code:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
    rs_out RESULTSET;
    BEGIN
      create or replace temporary table temp_result (i int);
      LET i := 1;
      WHILE (i <= 10) DO
        EXECUTE IMMEDIATE 'insert into temp_result SELECT ' || i;
        i := i + 1;
      END WHILE;
      rs_out := (select* from temp_result);
      return TABLE(rs_out);
    END;
    $$
    ;
    ```

1. Highlight the written T-SQL code and select **&#x23f5;Run**.
1. This will result in:

    | I |
    | ------------- |
    | 1 |
    | 2 |
    | 3 |
    | 4 |
    | 5 |
    | 6 |
    | 7 |
    | 8 |
    | 9 |
    | 10 |

## Challenges

Now it's time to try using what you've learnt.

> **Tip**: Try to determine the appropriate solutions for yourself. If you get stuck, suggested answers are provided at the end of this lab.

### Challenge 1: Assignment of values to variables

You are developing a new SQL application that needs to temporarily store values drawn from the database, and depending on their values, display the outcome to the user.

1. Create your variables.
    - Write a SQL script to declare two variables. The first is an nvarchar with length 30 called salesOrderNumber, and the other is an integer called customerID.
1. Assign a value to the integer variable.
    - Extend your SQL script to assign the value 29847 to the customerID.
1. Assign a value from the database and display the result.
    - Extend your SQL script to set the value of the variable salesOrderNumber using the column **salesOrderNUmber** from the SalesOrderHeader table, filter using the **customerID** column and the customerID variable.  Display the result to the user.

### Challenge 2: Aggregate product sales

The sales manager would like a list of the first 10 customers that registered and made purchases online as part of a promotion. You've been asked to build the list.

1. Declare the variables:
   - Write a SQL script to declare a variable called **rs_out** of type **RESULTSET** and one called **CustomerID** of type **INT**.
1. Create a temporary table to house results and set variables
  - Extend your SQL script and add a temp table called **temp_result** with columns **fname** and **lname** of type **NVARCHAR(30)**.
  - Assign value **1** to variable **CustomerID**.
1. Construct a terminating loop:
   - Extend your SQL script and create a WHILE loop that will stop when the customerID variable reaches 10.
1. Select the customer first name and last name and display:
   - Extend the SQL script, filling the temp table from a SELECT statement retrieving the **FirstName** and **LastName** columns. Filter using the **customerID** column and the customerID variable. Assign the temp table contents to the **rs_out** variable and return the resultset.  

## Challenge Solutions

This section contains suggested solutions for the challenge queries.

### Challenge 1

1. Create your variables

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
    salesOrderNUmber NVARCHAR(30);
    customerID INT;
    BEGIN
      
    END;
    $$
    ;
    ```

1. Assign a value to the integer variable.

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
    salesOrderNUmber NVARCHAR(30);
    customerID INT;
    BEGIN
      customerID := 29847;
    END;
    $$
    ;
    ```

1. Assign a value from the database and display the result

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
    salesOrderNUmber NVARCHAR(30);
    customerID INT;
    BEGIN
      customerID := 29847;
      salesOrderNUmber := (SELECT salesOrderNumber FROM SalesLT.SalesOrderHeader WHERE CustomerID = :customerID);
      RETURN salesOrderNUmber;
    END;
    $$
    ;
    ```

### Challenge 2

The sales manager would like a list of the first 10 customers that registered and made purchases online as part of a promotion. You've been asked to build the list.

1. Declare the variables:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
      rs_out RESULTSET;
      CustomerID INT;
    BEGIN

    END;
    $$
    ;
    ```

1. Construct a terminating loop:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
      rs_out RESULTSET;
      CustomerID INT;
    BEGIN
      CREATE OR REPLACE TEMPORARY TABLE temp_result (fname NVARCHAR(30), lname NVARCHAR(30));
      LET customerID := 1;
    END;
    $$
    ;
    ```

1. Construct a terminating loop:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
      rs_out RESULTSET;
      CustomerID INT;
    BEGIN
      CREATE OR REPLACE TEMPORARY TABLE temp_result (fname NVARCHAR(30), lname NVARCHAR(30));
      LET customerID := 1;
      WHILE (customerID <= 10) DO
        customerID := customerID + 1;
      END WHILE;
    END;
    $$
    ;
    ```

1. Select the customer first name and last name and display:

    ```
    EXECUTE IMMEDIATE $$
    DECLARE 
      rs_out RESULTSET;
      CustomerID INT;
    BEGIN
      CREATE OR REPLACE TEMPORARY TABLE temp_result (fname NVARCHAR(30), lname NVARCHAR(30));
      customerID := 1;
      WHILE (customerID <= 10) DO
        EXECUTE IMMEDIATE 'insert into temp_result SELECT FirstName, LastName FROM SalesLT.Customer WHERE CustomerID = ' || customerID;
        customerID := customerID + 1;
      END WHILE;
      rs_out := (SELECT * FROM temp_result);
      return TABLE(rs_out);
    END;
    $$
    ;
    ```
