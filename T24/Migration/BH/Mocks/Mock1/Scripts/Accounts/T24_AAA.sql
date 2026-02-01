
--/* LOG */ INSERT INTO dbo.MIG_LOG (Application,Step,Sub_Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Transformation','Delete Account IDs from Table T24_ACCOUNT_ID','S',getdate());
DELETE FROM [REPORT].[XBALC_SCF_170225] WHERE XRDN = $(DATE_XRDN);
--/* LOG */ INSERT INTO dbo.MIG_LOG (Application,Step,Sub_Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Transformation','Delete Account IDs from Table T24_ACCOUNT_ID','F',getdate());

-----------------------------------------
-- Insert Branch 91 accounts
-----------------------------------------
--/* LOG */ INSERT INTO dbo.MIG_LOG (Application,Step,Sub_Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Transformation','Insert Urbis Accounts into Table T24_ACCOUNT_ID for Conv.','S',getdate());

INSERT INTO [REPORT].[XBALC_SCF_170225]
SELECT * FROM URBIS.XBALC WHERE XRDN = $(DATE_XRDN) AND C_TYPE = 'LADL'  AND CONTRACTNO LIKE '24%' AND CNT_STATUS = 'A'