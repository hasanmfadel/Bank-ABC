@echo off
REM Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set datetime=%%I
set "S_DATE=%datetime:~0,8%"


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


@echo on
REM sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -Q "SET NOCOUNT ON; SELECT * FROM URBIS.DATES"  -s "|" -o ".\Output\Accounts\T24.AAA.%S_DATE%.csv" -W
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %SQLCMD_PASS% -v DATE_XRDN=%DATE_XRDN% -i ".\Scripts\ACCOUNTS\T24_AAA.sql" -o ".\logs\T24_AAA.log" -W 
@echo off

IF ERRORLEVEL 1 (
    echo Process failed.
    REM exit /b 1
)

echo Process completed successfully!
endlocal

PAUSE
