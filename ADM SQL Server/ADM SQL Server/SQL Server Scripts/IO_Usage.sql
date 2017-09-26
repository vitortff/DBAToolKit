SELECT SUM(pending_disk_io_count) AS [Number of pending I/Os] FROM sys.dm_os_schedulers 


SELECT *  FROM sys.dm_io_pending_io_requests



SELECT 
	
	DB_NAME(database_id) AS [Database],
	
	[file_id], 
	
	[io_stall_read_ms],
	
	[io_stall_write_ms],
	
	[io_stall] 

FROM 
	
	sys.dm_io_virtual_file_stats(NULL,NULL) 

ORDER BY 
	[io_stall_read_ms] DESC
	


SELECT TOP 10
creation_time
, last_execution_time
, total_logical_reads AS [LogicalReads] , total_logical_writes AS [LogicalWrites] , execution_count
, total_logical_reads+total_logical_writes AS [AggIO] , (total_logical_reads+total_logical_writes)/(execution_count+0.0) AS [AvgIO] , st.TEXT
, DB_NAME(st.dbid) AS database_name
, st.objectid AS OBJECT_ID
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_logical_reads+total_logical_writes > 0
AND sql_handle IS NOT NULL
ORDER BY [AggIO] DESC