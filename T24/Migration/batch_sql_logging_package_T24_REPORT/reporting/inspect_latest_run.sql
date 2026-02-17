
/* Inspect latest run and its steps */
DECLARE @RunID INT = (
    SELECT TOP (1) RunID FROM REPORT.T24_BatchRunLog ORDER BY StartTime DESC
);

PRINT CONCAT('Latest RunID = ', @RunID);

SELECT * FROM REPORT.T24_BatchRunLog WHERE RunID = @RunID;

SELECT *
FROM REPORT.T24_BatchStepLog
WHERE RunID = @RunID
ORDER BY StartTime;

/* Timeline view */
SELECT * FROM REPORT.T24_vw_BatchRunTimeline WHERE RunID = @RunID ORDER BY StartTime;
