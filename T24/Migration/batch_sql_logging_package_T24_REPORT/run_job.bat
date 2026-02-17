
    @echo off
    setlocal enabledelayedexpansion

    rem ======================= CONFIG =======================
    set SERVER=YourServerNameOrInstance
    set DB=YourDatabaseName
    set BATCH_NAME=T24_NightlyDemo
    rem ======================================================

    rem Make sqlcmd return a non-zero errorlevel on errors
    set SQLCMDERRORLEVEL=1

    rem 1) Install logging (safe to run repeatedly)
    echo Installing/refreshing REPORT.T24_ logging objects...
    sqlcmd -S %SERVER% -d %DB% -b -i install\00_create_logging_objects.sql
    if errorlevel 1 goto :fail_no_runid

    rem 2) Start run and capture RunID
    echo Starting run for %BATCH_NAME% ...
    for /f "usebackq delims=" %%R in (`sqlcmd -S %SERVER% -d %DB% -h -1 -W -Q "DECLARE @id INT; EXEC REPORT.T24_usp_BatchRun_Start @BatchName=N'%BATCH_NAME%', @RunID=@id OUTPUT; SELECT @id;"`) do set RunID=%%R

    if "%RunID%"=="" (
        echo Failed to obtain RunID.
        goto :fail_no_runid
    )

    echo RunID = %RunID%

    rem 3) Execute SQL scripts (pass RunID into each)
    echo Executing examples/01_Demo_LoadAndMerge.sql ...
    sqlcmd -S %SERVER% -d %DB% -b -v RunID=%RunID% -i examples\01_Demo_LoadAndMerge.sql
    if errorlevel 1 goto :fail

    echo Executing examples/02_Demo_Cleanup.sql ...
    sqlcmd -S %SERVER% -d %DB% -b -v RunID=%RunID% -i examples\02_Demo_Cleanup.sql
    if errorlevel 1 goto :fail

    rem 4) Mark success
    sqlcmd -S %SERVER% -d %DB% -b -Q "EXEC REPORT.T24_usp_BatchRun_End @RunID=%RunID%, @Status='Completed';"
    echo Job completed successfully. RunID=%RunID%
    goto :eof

:fail
    echo Error encountered. Marking run failed...
    sqlcmd -S %SERVER% -d %DB% -b -Q "EXEC REPORT.T24_usp_BatchRun_End @RunID=%RunID%, @Status='Failed', @Notes='Terminated due to error';"
    exit /b 1

:fail_no_runid
    echo Setup failed before RunID could be created.
    exit /b 2
