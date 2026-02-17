
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*===============================================
  Package: T24_ Batch + SQL Step Logging (REPORT schema)
  Contents: Tables + Procs + View (T24_*, in REPORT schema)
  Safe to run multiple times (idempotent for objects)
===============================================*/

-- Ensure REPORT schema exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'REPORT')
BEGIN
    EXEC('CREATE SCHEMA REPORT AUTHORIZATION dbo');
END
GO

-- 1) Tables ------------------------------------------------------------
IF OBJECT_ID('REPORT.T24_BatchRunLog','U') IS NULL
BEGIN
    CREATE TABLE REPORT.T24_BatchRunLog (
        RunID           INT IDENTITY(1,1) PRIMARY KEY,
        BatchName       SYSNAME           NOT NULL,
        StartTime       DATETIME2(3)      NOT NULL CONSTRAINT T24_DF_BatchRunLog_Start DEFAULT SYSDATETIME(),
        EndTime         DATETIME2(3)      NULL,
        Status          VARCHAR(50)       NOT NULL CONSTRAINT T24_DF_BatchRunLog_Status DEFAULT 'Started',
        Notes           VARCHAR(500)      NULL
    );
    CREATE INDEX T24_IX_BatchRunLog_StartTime ON REPORT.T24_BatchRunLog(StartTime DESC);
    CREATE INDEX T24_IX_BatchRunLog_BatchName ON REPORT.T24_BatchRunLog(BatchName, StartTime DESC);
END
GO

IF OBJECT_ID('REPORT.T24_BatchStepLog','U') IS NULL
BEGIN
    CREATE TABLE REPORT.T24_BatchStepLog (
        StepLogID     INT IDENTITY(1,1) PRIMARY KEY,
        RunID         INT              NOT NULL,
        SqlFile       SYSNAME          NULL,
        StepName      NVARCHAR(256)    NOT NULL,
        StartTime     DATETIME2(3)     NOT NULL CONSTRAINT T24_DF_BatchStepLog_Start DEFAULT SYSDATETIME(),
        EndTime       DATETIME2(3)     NULL,
        DurationMs    AS DATEDIFF(MILLISECOND, StartTime, EndTime) PERSISTED,
        Status        VARCHAR(50)      NOT NULL CONSTRAINT T24_DF_BatchStepLog_Status DEFAULT 'Started',
        RowsAffected  BIGINT           NULL,
        ErrorMessage  NVARCHAR(MAX)    NULL,
        CONSTRAINT T24_FK_BatchStepLog_Run FOREIGN KEY (RunID) REFERENCES REPORT.T24_BatchRunLog(RunID)
    );
    CREATE INDEX T24_IX_BatchStepLog_Run ON REPORT.T24_BatchStepLog(RunID, StartTime);
    CREATE INDEX T24_IX_BatchStepLog_Status ON REPORT.T24_BatchStepLog(Status);
END
GO

-- 2) Procedures --------------------------------------------------------
CREATE OR ALTER PROCEDURE REPORT.T24_usp_BatchRun_Start
    @BatchName SYSNAME,
    @RunID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO REPORT.T24_BatchRunLog (BatchName) VALUES (@BatchName);
    SET @RunID = SCOPE_IDENTITY();
END
GO

CREATE OR ALTER PROCEDURE REPORT.T24_usp_BatchRun_End
    @RunID INT,
    @Status VARCHAR(50) = 'Completed',
    @Notes VARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE REPORT.T24_BatchRunLog
    SET EndTime = SYSDATETIME(),
        Status  = @Status,
        Notes   = @Notes
    WHERE RunID = @RunID;
END
GO

/* Core step logger + executor (REPORT schema) */
CREATE OR ALTER PROCEDURE REPORT.T24_usp_BatchStep_Exec
    @RunID        INT,
    @StepName     NVARCHAR(256),
    @Command      NVARCHAR(MAX),
    @SqlFile      SYSNAME = NULL,
    @RowsAffected BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StepLogID INT;
    INSERT INTO REPORT.T24_BatchStepLog (RunID, SqlFile, StepName, Status)
    VALUES (@RunID, @SqlFile, @StepName, 'Started');
    SET @StepLogID = SCOPE_IDENTITY();

    DECLARE @prevXactAbort INT = CAST(SESSIONPROPERTY('XACT_ABORT') AS INT);
    IF (@prevXactAbort = 0) SET XACT_ABORT ON;  -- ensure atomic failure inside a step

    BEGIN TRY
        EXEC sys.sp_executesql @Command;
        SET @RowsAffected = @@ROWCOUNT; -- last statement only

        UPDATE REPORT.T24_BatchStepLog
        SET EndTime = SYSDATETIME(),
            Status = 'Success',
            RowsAffected = @RowsAffected
        WHERE StepLogID = @StepLogID;
    END TRY
    BEGIN CATCH
        UPDATE REPORT.T24_BatchStepLog
        SET EndTime = SYSDATETIME(),
            Status = 'Failed',
            ErrorMessage = CONCAT(
                'Msg ', ERROR_NUMBER(), ', Level ', ERROR_SEVERITY(),
                ', State ', ERROR_STATE(), '. Line ', ERROR_LINE(), '. ',
                ERROR_MESSAGE()
            )
        WHERE StepLogID = @StepLogID;

        IF (@prevXactAbort = 0) SET XACT_ABORT OFF;  -- restore before rethrow
        THROW;
    END CATCH

    IF (@prevXactAbort = 0) SET XACT_ABORT OFF;
END
GO

-- 3) Reporting view ----------------------------------------------------
CREATE OR ALTER VIEW REPORT.T24_vw_BatchRunTimeline
AS
SELECT r.RunID,
       r.BatchName,
       r.StartTime AS BatchStart,
       r.EndTime   AS BatchEnd,
       r.Status    AS BatchStatus,
       s.StepLogID,
       s.SqlFile,
       s.StepName,
       s.StartTime,
       s.EndTime,
       s.DurationMs,
       s.Status     AS StepStatus,
       s.RowsAffected,
       s.ErrorMessage
FROM REPORT.T24_BatchRunLog r
LEFT JOIN REPORT.T24_BatchStepLog s
  ON s.RunID = r.RunID;
GO
