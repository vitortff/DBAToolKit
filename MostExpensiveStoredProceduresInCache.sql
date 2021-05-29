SELECT TOP (25) p.name AS [SP Name], 
                qs.total_logical_reads AS [TotalLogicalReads], 
                qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads], 
                qs.execution_count, 
                ISNULL(qs.execution_count / DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second], 
                qs.total_elapsed_time, 
                qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time], 
                qs.cached_time
FROM sys.procedures AS p WITH(NOLOCK)
     INNER JOIN sys.dm_exec_procedure_stats AS qs WITH(NOLOCK) ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC OPTION(RECOMPILE);