
/* Drop objects created by the package (careful: deletes log history) */
IF OBJECT_ID('REPORT.T24_vw_BatchRunTimeline','V') IS NOT NULL DROP VIEW REPORT.T24_vw_BatchRunTimeline;
GO
IF OBJECT_ID('REPORT.T24_usp_BatchStep_Exec','P') IS NOT NULL DROP PROCEDURE REPORT.T24_usp_BatchStep_Exec;
GO
IF OBJECT_ID('REPORT.T24_usp_BatchRun_End','P') IS NOT NULL DROP PROCEDURE REPORT.T24_usp_BatchRun_End;
GO
IF OBJECT_ID('REPORT.T24_usp_BatchRun_Start','P') IS NOT NULL DROP PROCEDURE REPORT.T24_usp_BatchRun_Start;
GO

IF OBJECT_ID('REPORT.T24_BatchStepLog','U') IS NOT NULL DROP TABLE REPORT.T24_BatchStepLog;
IF OBJECT_ID('REPORT.T24_BatchRunLog','U')  IS NOT NULL DROP TABLE REPORT.T24_BatchRunLog;

-- Demo tables (optional)
IF OBJECT_ID('REPORT.T24_DemoCustomers_Stage','U') IS NOT NULL DROP TABLE REPORT.T24_DemoCustomers_Stage;
IF OBJECT_ID('REPORT.T24_DemoCustomers','U')       IS NOT NULL DROP TABLE REPORT.T24_DemoCustomers;
