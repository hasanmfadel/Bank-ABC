@echo off
REM Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set datetime=%%I
set "S_DATE=%datetime:~0,8%"

 
rem 1)======================= CONFIG =======================
set BATCH_NAME=ACCOUNTS
rem ======================================================

:: === Load parameters from config.env ===
for /f "usebackq tokens=1,2 delims==" %%A in ("config.env") do (
    set %%A=%%B
)


:: === PRINT PARAMETERS ===
echo ENV=%ENV%
echo SERVER=%SERVER%
echo DATABASE=%DATABASE%
echo USERNAME=%USERNAME%
echo DATE_XRDN=%DATE_XRDN%
:: ===========================
	

rem 2) Start run and capture RunID ===========================
    echo Starting run for %BATCH_NAME% ...
    for /f "usebackq delims=" %%R in (`sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -h -1 -W -r1 -m-1 -Q "SET NOCOUNT ON; DECLARE @id INT; EXEC REPORT.T24_usp_BatchRun_Start @BatchName=N'%BATCH_NAME%', @RunID=@id OUTPUT; SELECT @id;"`) do set RunID=%%R

    if "%RunID%"=="" (
        echo Failed to obtain RunID.
        goto :fail_no_runid
    )

    echo RunID = %RunID%
rem ============================================================




echo Executing .\Scripts\ACCOUNTS\T24_AAA.sql ...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -i ".\Scripts\ACCOUNTS\T24_AAA.sql" -o ".\logs\T24_AAA.log" -W
if errorlevel 1 goto :fail


REM sqlcmd -S cbs-migration.cv1ukx7wjryy.eu-west-1.rds.amazonaws.com -d cbs_migration -U hasan_hasan -P %SQLCMD_PASS% -Q "SET NOCOUNT ON; exec select_y @table_name = '[dbo].[T24_AAA_DETAILED]'"  -s "|" -o ".\output\ACCOUNTS\T24.AAA.%S_DATE%.csv" -W
REM .\python\MIG\ACCOUNTS\ACCOUNTS.py



REM echo PUT .\output\ACCOUNTS\T24.AAA.%S_DATE%.csv /fs-0554ae78d67b5bc8a/LIVE/AA.ACCOUNT/ACCOUNT | sftp -i ".\Keys\prodsftp.pem" transact-sftp-prod-user@10.28.5.136


REM DEL ".\output\ACCOUNTS\T24.AAA.%S_DATE%.csv"





rem 3) Mark success ============================================
    sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -b -Q "EXEC REPORT.T24_usp_BatchRun_End @RunID=%RunID%, @Status='Completed';"
    echo Job completed successfully. RunID=%RunID%
	PAUSE
    goto :eof
rem ============================================================

:fail
    echo Error encountered. Marking run failed...
    sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -b -Q "EXEC REPORT.T24_usp_BatchRun_End @RunID=%RunID%, @Status='Failed', @Notes='Terminated due to error';"
	PAUSE
    exit /b 1

:fail_no_runid
    echo Setup failed before RunID could be created.
	PAUSE
    exit /b 2


:eof
PAUSE