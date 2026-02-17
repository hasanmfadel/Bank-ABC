
# T24_ Batch + SQL Step Logging Package (REPORT schema)

All objects are created in the **REPORT** schema and prefixed with **T24_**.

## Contents

- `install/00_create_logging_objects.sql` — Creates/updates REPORT.T24_ tables, procs, and view.
- `examples/01_Demo_LoadAndMerge.sql` — Example using `REPORT.T24_usp_BatchStep_Exec`.
- `examples/02_Demo_Cleanup.sql` — Example cleanup step.
- `reporting/inspect_latest_run.sql` — Quick query to inspect the latest run.
- `uninstall/99_drop_logging_objects.sql` — Clean-up script (drops REPORT.T24_ objects and demo tables).
- `run_job.bat` — Example batch file wiring everything together.

## Quick Start

1. Edit `run_job.bat` and set:
   ```bat
   set SERVER=YourServerNameOrInstance
   set DB=YourDatabaseName
   set BATCH_NAME=T24_YourBatchName
   ```
2. Run `run_job.bat`. It will install/refresh objects, start a run, execute sample scripts, end the run.
3. Review logs:
   ```sql
   SELECT * FROM REPORT.T24_vw_BatchRunTimeline ORDER BY RunID DESC, StartTime;
   ```

## Using in your scripts

```sql
:setvar SqlFile 10_LoadProducts.sql

DECLARE @rows BIGINT;
EXEC REPORT.T24_usp_BatchStep_Exec
     @RunID        = $(RunID),
     @StepName     = N'Load: Products from source',
     @Command      = N'
        INSERT INTO dbo.Products (ProductID, Name)
        SELECT ProductID, Name FROM dbo.SourceProducts;
     ',
     @SqlFile      = N'$(SqlFile)',
     @RowsAffected = @rows OUTPUT;
```

> Replace `dbo.Products` with your real schema/object names as needed; logging objects stay under `REPORT`.

## Uninstall

Run `uninstall/99_drop_logging_objects.sql` in the database to remove all REPORT.T24_ objects.
