@echo off
REM Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set datetime=%%I
set "S_DATE=%datetime:~0,8%"

@echo on

sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Transformation','S',getdate())"
sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -i ".\Scripts\ACCOUNTS\T24_AAA.sql" -o ".\logs\T24_AAA.log" -W
sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Transformation','F',getdate())"


sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Extration','S',getdate())"
REM sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "SET NOCOUNT ON; exec select_y @table_name = '[dbo].[T24_AAA_DETAILED]'"  -s "|" -o ".\output\ACCOUNTS\T24.AAA.%S_DATE%.csv" -W
.\python\MIG\ACCOUNTS\ACCOUNTS.py
sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Accounts Extration','F',getdate())"

sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Upload/SFTP Accounts File','S',getdate())"
echo PUT .\output\ACCOUNTS\T24.AAA.%S_DATE%.csv /fs-0554ae78d67b5bc8a/LIVE/AA.ACCOUNT/ACCOUNT | sftp -i ".\Keys\prodsftp.pem" transact-sftp-prod-user@10.28.5.136
sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "INSERT INTO dbo.MIG_LOG (Application,Step,Event,DateStamp) Values ('ACCOUNTS','Upload/SFTP Accounts File','F',getdate())"

REM DEL ".\output\ACCOUNTS\T24.AAA.%S_DATE%.csv"
PAUSE