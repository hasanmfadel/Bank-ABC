
:setvar SqlFile 02_Demo_Cleanup.sql

-- Demo cleanup step: delete customers in a city (example criterion)
DECLARE @rows BIGINT;
EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = $(RunID),
     @StepName     = N'Cleanup: Delete customers in city = Helsinki',
     @Command      = N'
        DELETE D
          FROM REPORT.T24_DemoCustomers AS D
         WHERE D.City = N''Helsinki'';
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;
