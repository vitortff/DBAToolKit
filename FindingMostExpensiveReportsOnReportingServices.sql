--https://blogs.msdn.microsoft.com/robertbruckner/2009/01/06/executionlog2-view-analyzing-and-optimizing-reports/

USE ReportServer;
SELECT *
FROM ExecutionLog2
ORDER BY TimeStart DESC;