---
lab:
    title: 'Implement error handling with Snowflake SQL'
    module: 'Additional exercises'
---

# Implement error handling with Snowflake SQL

In this lab, you'll use Snowflake SQL statements to test various error handling techniques in the **adventureworks** database. For your reference, the following diagram shows the tables in the database (you may need to resize the pane to see them clearly).

![An entity relationship diagram of the adventureworks database](./Images/adventureworks-erd.png)

> **Note**: If you're familiar with the standard **AdventureWorks** sample database, you may notice that in this lab we are using a simplified version that makes it easier to focus on learning Snowflake SQL syntax.

## Use TRY_<conversion function> to prevent a conversion error

1. Create a new worksheet and connect to the database and warehouse.
1. In the worksheet, type the following SQL code:

    ```
    SELECT CAST('Some text' AS int);
    ```

1. Select **&#x23f5;Run** to run the code.
1. Notice the conversion error:

    | Result|
    |-------|
    | Numeric value 'Some text' is not recognized |

1. Add **TRY_** to the **CAST** function. Your SQL code should look like this:

    ```
    SELECT TRY_CAST('Some text' AS int);
    ```

1. Run the modified code, and review the response. The result should include a row with a **null** value, indicating the casting was unsuccessful.

## Declare and raise your own exception

1. Replace the code in your worksheet with the following SQL code:

    ```
    EXECUTE IMMEDIATE 
    $$
    DECLARE
      my_exception EXCEPTION (-20002, 'Raised MY_EXCEPTION.');
      integer_variable INT;
    BEGIN
      SELECT TRY_TO_NUMBER('Some text') INTO :integer_variable;
      IF (integer_variable IS NULL) THEN
        RAISE my_exception;
      END IF;
      RETURN integer_variable;
    END;
    $$
    ;
    ```

1. Select **&#x23f5;Run**. Notice that you get an error message containing your own error code and message.

## Construct your own error message object

1. Extend the SQL code you used previously so it looks like this:

    ```
    EXECUTE IMMEDIATE 
    $$
    DECLARE
      my_exception EXCEPTION (-20002, 'Raised MY_EXCEPTION.');
      integer_variable INT;
    BEGIN
      SELECT TRY_TO_NUMBER('Some text') INTO :integer_variable;
      IF (integer_variable IS NULL) THEN
        RAISE my_exception;
      END IF;
      RETURN integer_variable;
    EXCEPTION
      WHEN my_exception THEN
        RETURN OBJECT_CONSTRUCT('Error type', 'MY_EXCEPTION',
                                'SQLCODE', sqlcode,
                                'SQLERRM', sqlerrm,
                                'SQLSTATE', sqlstate);
    END;
    $$
    ;
    ```

1. Run the modified code.  You'll see that message returned now contains more information:

    | anonymous block|
    | ------ |
    | {   "Error type": "MY_EXCEPTION",   "SQLCODE": -20002,   "SQLERRM": "Raised MY_EXCEPTION.",   "SQLSTATE": "P0001" } |

## Create a stored procedure to display an error message

1. Enter the following SQL code:

    ```
    CREATE OR REPLACE PROCEDURE dbo.GetErrorInfo (code int, message NVARCHAR(200), state NVARCHAR(5))
    RETURNS OBJECT
    LANGUAGE SQL
    AS
    $$
    BEGIN
        RETURN OBJECT_CONSTRUCT('Error type', 'EXCEPTION',
                            'SQLCODE', code,
                            'SQLERRM', message,
                            'SQLSTATE', state);
    END;
    $$
    ```

1. Select **&#x23f5;Run**. to run the code, which creates a stored procedure named **dbo.GetErrorInfo**.
1. Return to the query that previously resulted in a your custom error, and modify it as follows:

    ```
EXECUTE IMMEDIATE 
$$
DECLARE
  my_exception EXCEPTION (-20002, 'Raised MY_EXCEPTION.');
  integer_variable INT;
BEGIN
  SELECT TRY_TO_NUMBER('Some text') INTO :integer_variable;
  IF (integer_variable IS NULL) THEN
    RAISE my_exception;
  END IF;
  RETURN integer_variable;
EXCEPTION
  WHEN my_exception THEN
    BEGIN
        LET rs RESULTSET;
        LET statement VARCHAR := 'CALL dbo.GetErrorInfo(' || sqlcode || ',\'' || sqlerrm  || '\',\'' || sqlstate || '\')'; 
        rs := (EXECUTE IMMEDIATE :statement);
        RETURN table(rs);
    END;
END;
$$
;
    ```

1. Run the code.  This will trigger the stored procedure and display:

    | GetErrorInfo |
    | ------ |
    | {   "Error type": "EXCEPTION",   "SQLCODE": -20002,   "SQLERRM": "Raised MY_EXCEPTION.",   "SQLSTATE": "P0001" }|

## Add an Error Handling Routine

1. Modify your code to look like this:

    ```
    EXECUTE IMMEDIATE 
    $$
    DECLARE
      my_exception EXCEPTION (-20002, 'Raised MY_EXCEPTION.');
      integer_variable INT;
    BEGIN
      SELECT TRY_TO_NUMBER('1') INTO :integer_variable;
      IF (integer_variable IS NULL) THEN
        RAISE my_exception;
      END IF;
      LET other_error := 1/0;
      RETURN integer_variable;
    EXCEPTION
      WHEN my_exception THEN
        BEGIN
            LET rs RESULTSET;
            LET statement VARCHAR := 'CALL dbo.GetErrorInfo(' || sqlcode || ',\'' || sqlerrm  || '\',\'' || sqlstate || '\')'; 
            rs := (EXECUTE IMMEDIATE :statement);
            RETURN table(rs);
        END;
      WHEN OTHER THEN
        BEGIN
            LET rs RESULTSET;
            LET statement VARCHAR := 'CALL dbo.GetErrorInfo(' || sqlcode || ',\'' || sqlerrm  || '\',\'' || sqlstate || '\')'; 
            rs := (EXECUTE IMMEDIATE :statement);
            RETURN table(rs);
        END;
    END;
    $$
    ;
    ```

1. Run the modified code. The text fed to the TRY_TO_NUMBER function is valid now, so your custom exception is not raised. Another error is added though, and handled in the OTHER exception block. It executes the stored procedure to display the error.

    |  GetErrorInfo |
    | ------ |
    | {   "Error type": "EXCEPTION",   "SQLCODE": 100051,   "SQLERRM": "Division by zero",   "SQLSTATE": "22012" }|

## Challenges

Now it's time to try using what you've learned.

> **Tip**: Try to determine the appropriate solutions for yourself. If you get stuck, suggested answers are provided at the end of this lab.

### Challenge 1: Catch errors and display only valid records

The marketing manager is using the following T-SQL query, but they are getting unexpected results. They have asked you to make the code more resilient, to stop it crashing and to not display duplicates when there is no data.

```
DECLARE @customerID AS INT = 30110;
DECLARE @fname AS NVARCHAR(20);
DECLARE @lname AS NVARCHAR(30);
DECLARE @maxReturns AS INT = 1; 

WHILE @maxReturns <= 10
BEGIN
    SELECT @fname = FirstName, @lname = LastName FROM SalesLT.Customer
        WHERE CustomerID = @CustomerID;
    PRINT @fname + N' ' + @lname;
    SET @maxReturns += 1;
    SET @CustomerID += 1;
END;
```

1. Catch the error
    - Add a TRY .. CATCH block around the SELECT query.
2. Warn the user that an error has occurred
    - Extend your TSQL code to display a warning to the user that their is an error.
3. Only display valid customer records
    - Extend the T-SQL using the @@ROWCOUNT > 0 check to only display a result if the customer ID exists.

### Challenge 2: Create a simple error display procedure

Error messages and error handling are essential for good code. Your manager has asked you to develop a common error display procedure.  Use this sample code as your base.

```
DECLARE @num varchar(20) = 'Challenge 2';

PRINT 'Casting: ' + CAST(@num AS numeric(10,4));
```

1. Catch the error
   - Add a TRY...CATCH around the PRINT statement.
2. Create a stored procedure
   - Create a stored procedure called dbo.DisplayErrorDetails.  It should display a title and the value for **ERROR_NUMBER**, **ERROR_MESSAGE** and **ERROR_SEVERITY**.
3. Display the error information
   - Use the stored procedure to display the error information when an error occurs.

## Challenge Solutions

This section contains suggested solutions for the challenge queries.

### Challenge 1

1. Catch the error

```
DECLARE @customerID AS INT = 30110;
DECLARE @fname AS NVARCHAR(20);
DECLARE @lname AS NVARCHAR(30);
DECLARE @maxReturns AS INT = 1;

WHILE @maxReturns <= 10
BEGIN
    BEGIN TRY
        SELECT @fname = FirstName, @lname = LastName FROM SalesLT.Customer
            WHERE CustomerID = @CustomerID;

        PRINT CAST(@customerID as NVARCHAR(20)) + N' ' + @fname + N' ' + @lname;
    END TRY
    BEGIN CATCH

    END CATCH;

    SET @maxReturns += 1;
    SET @CustomerID += 1;
END;
```

2. Warn the user that an error has occurred

```
DECLARE @customerID AS INT = 30110;
DECLARE @fname AS NVARCHAR(20);
DECLARE @lname AS NVARCHAR(30);
DECLARE @maxReturns AS INT = 1;

WHILE @maxReturns <= 10
BEGIN
    BEGIN TRY
        SELECT @fname = FirstName, @lname = LastName FROM SalesLT.Customer
            WHERE CustomerID = @CustomerID;

            PRINT CAST(@customerID as NVARCHAR(20)) + N' ' + @fname + N' ' + @lname;
    END TRY
    BEGIN CATCH
        PRINT 'Unable to run query'
    END CATCH;

    SET @maxReturns += 1;
    SET @CustomerID += 1;
END;
```

3. Only display valid customer records

```
DECLARE @customerID AS INT = 30110;
DECLARE @fname AS NVARCHAR(20);
DECLARE @lname AS NVARCHAR(30);
DECLARE @maxReturns AS INT = 1;

WHILE @maxReturns <= 10
BEGIN
    BEGIN TRY
        SELECT @fname = FirstName, @lname = LastName FROM SalesLT.Customer
            WHERE CustomerID = @CustomerID;

        IF @@ROWCOUNT > 0 
        BEGIN
            PRINT CAST(@customerID as NVARCHAR(20)) + N' ' + @fname + N' ' + @lname;
        END
    END TRY
    BEGIN CATCH
        PRINT 'Unable to run query'
    END CATCH

    SET @maxReturns += 1;
    SET @CustomerID += 1;
END;
```

### Challenge 2

1. Catch the error

```
DECLARE @num varchar(20) = 'Challenge 2';

BEGIN TRY
    PRINT 'Casting: ' + CAST(@num AS numeric(10,4));
END TRY
BEGIN CATCH

END CATCH;
```

2. Create a stored procedure

```
CREATE PROCEDURE dbo.DisplayErrorDetails AS
PRINT 'ERROR INFORMATION';
PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS varchar(10));
PRINT 'Error Message: ' + ERROR_MESSAGE();
PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS varchar(10));
```

3. Display the error information

```
DECLARE @num varchar(20) = 'Challenge 2';

BEGIN TRY
    PRINT 'Casting: ' + CAST(@num AS numeric(10,4));
END TRY
BEGIN CATCH
    EXECUTE dbo.DisplayErrorDetails;
END CATCH;
```
