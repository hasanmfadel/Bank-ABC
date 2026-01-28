@echo off
REM Get the current date in YYYYMMDD format
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value ^| find "="') do set datetime=%%I
set "S_DATE=%datetime:~0,8%"

@echo on

sqlcmd -S 10.150.160.29 -d URBISDBLN -U REPORT -P %SQLCMD_PASS% -Q "SET NOCOUNT ON; SELECT * FROM URBIS.DATES"  -s "|" -o ".\Output\Accounts\T24.AAA.%S_DATE%.csv" -W

PAUSE

Added now

Added new feature