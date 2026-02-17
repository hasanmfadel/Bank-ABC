:setvar SqlFile T24_AAA.sql

DECLARE @rows BIGINT;
EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = N'$(RunID)',
     @StepName     = N'Stage: Delete Accounts',
     @Command      = N'
						DELETE FROM [REPORT].[XBALC_SCF_160226] WHERE XRDN = $(DATE_XRDN);
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;


EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = N'$(RunID)',
     @StepName     = N'Stage: Insert Accounts',
     @Command      = N'
INSERT INTO [REPORT].[XBALC_SCF_160226]
SELECT * FROM URBIS.XBALC WHERE XRDN = $(DATE_XRDN) AND C_TYPE = ''LADL''  AND CONTRACTNO LIKE ''24%'' AND CNT_STATUS = ''A''
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;