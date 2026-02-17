
:setvar SqlFile 01_Demo_LoadAndMerge.sql

/* Demo data setup (safe/idempotent) */
IF OBJECT_ID('REPORT.T24_DemoCustomers','U') IS NULL
BEGIN
    CREATE TABLE REPORT.T24_DemoCustomers(
        CustomerID INT PRIMARY KEY,
        [Name]     NVARCHAR(100),
        City       NVARCHAR(100),
        Country    NVARCHAR(100)
    );
END

IF OBJECT_ID('REPORT.T24_DemoCustomers_Stage','U') IS NULL
BEGIN
    CREATE TABLE REPORT.T24_DemoCustomers_Stage(
        CustomerID INT PRIMARY KEY,
        [Name]     NVARCHAR(100),
        City       NVARCHAR(100),
        Country    NVARCHAR(100)
    );
END

-- Step 1: Stage load (truncate + insert sample rows)
DECLARE @rows BIGINT;
EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = $(RunID),
     @StepName     = N'Stage: load sample customers',
     @Command      = N'
        TRUNCATE TABLE REPORT.T24_DemoCustomers_Stage;
        INSERT INTO REPORT.T24_DemoCustomers_Stage(CustomerID, [Name], City, Country)
        VALUES (1,N''Ada Lovelace'',N''London'',N''UK''),
               (2,N''Grace Hopper'',N''New York'',N''USA''),
               (3,N''Linus Torvalds'',N''Helsinki'',N''Finland'');
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;

-- Step 2: Upsert into target
EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = $(RunID),
     @StepName     = N'Upsert: T24_DemoCustomers from stage',
     @Command      = N'
        MERGE REPORT.T24_DemoCustomers AS D
        USING (SELECT * FROM REPORT.T24_DemoCustomers_Stage) AS S
          ON S.CustomerID = D.CustomerID
        WHEN MATCHED THEN UPDATE SET
            [Name]   = S.[Name],
            City     = S.City,
            Country  = S.Country
        WHEN NOT MATCHED BY TARGET THEN
            INSERT (CustomerID, [Name], City, Country)
            VALUES (S.CustomerID, S.[Name], S.City, S.Country)
        WHEN NOT MATCHED BY SOURCE THEN
            DELETE;
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;
