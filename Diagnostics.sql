sp_cycle_errorlog

--HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL.1\MSSQLServer\SuperSocketNetLib\AdminConnection\Tcp
--sqlcmd -Stcp:127.0.0.1,3842 -U sa -P XXXX -W
--sqlcmd -Sadmin:SRV-DTBS\ISTDPTS -U sa -P XXXX -W
/*
A typical debugging scenario for query time-out may look like the following:
Check overall system memory status using sys.dm_os_memory_clerks, sys.dm_os_sys_info, and various performance counters.
Check for query-execution memory reservations in sys.dm_os_memory_clerks where type = 'MEMORYCLERK_SQLQERESERVATIONS'.
Check for queries waiting for grants using sys.dm_exec_query_memory_grants.
Further examine memory-intensive queries using sys.dm_exec_requests.
If a runaway query is suspected, examine the Showplan from sys.dm_exec_query_plan and batch text from sys.dm_exec_sql_text.
Queries that use dynamic management views that include ORDER BY or aggregates may increase memory consumption and thus contribute to the problem they are troubleshooting.
*/

SELECT * FROM sys.dm_os_waiting_tasks -- amount wait types
SELECT * FROM sys.dm_os_wait_stats -- for amount threads wait types
SELECT request_session_id, request_mode FROM sys.dm_tran_locks -- for the locking status 
SELECT * FROM sys.dm_os_memory_cache_counters -- to check the health of caches
SELECT * FROM sys.dm_exec_requests -- for active requests
SELECT * FROM sys.dm_exec_sessions -- for active sessions
SELECT * FROM sys.dm_os_tasks WHERE session_id = <spid> -- tasks assigned to this session 
KILL <spid>

DBCC FREESYSTEMCACHE ('ALL')
SELECT * FROM sys.dm_os_memory_clerks 
DBCC FREESYSTEMCACHE(TokenAndPermUserStore)

DBCC FREEPROCCACHE -- Removes all elements from the procedure cache
DBCC DROPCLEANBUFFERS -- to test queries with a cold buffer cache without shutting down and restarting the server
DBCC SQLPERF(LOGSPACE)
DBCC PROCCACHE
DBCC MEMORYSTATUS


SELECT * FROM sys.dm_db_missing_index_details

-- tempdb usage/acess

SELECT * FROM sys.dm_db_file_space_usage

SELECT
SUM (user_object_reserved_page_count)*8 as usr_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

SELECT top 5 * 
FROM sys.dm_db_session_space_usage  
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC

SELECT top 5 * 
FROM sys.dm_db_task_space_usage
ORDER BY (user_objects_alloc_page_count + internal_objects_alloc_page_count) DESC

SELECT t1.session_id, t1.request_id, t1.task_alloc,
  t1.task_dealloc, t2.sql_handle, t2.statement_start_offset, 
  t2.statement_end_offset, t2.plan_handle
FROM (Select session_id, request_id,
    SUM(internal_objects_alloc_page_count) AS task_alloc,
    SUM (internal_objects_dealloc_page_count) AS task_dealloc 
  FROM sys.dm_db_task_space_usage 
  GROUP BY session_id, request_id) AS t1, 
  sys.dm_exec_requests AS t2
WHERE t1.session_id = t2.session_id
  AND (t1.request_id = t2.request_id)
ORDER BY t1.task_alloc DESC

SELECT top 5 transaction_id, transaction_sequence_num, 
elapsed_time_seconds 
FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds DESC

SELECT * FROM sys.dm_tran_active_transactions 

SELECT top 10 (total_logical_reads/execution_count),
  (total_logical_writes/execution_count),
  (total_physical_reads/execution_count),
  Execution_count, sql_handle, plan_handle
FROM sys.dm_exec_query_stats  
ORDER BY (total_logical_reads + total_logical_writes) Desc

SELECT text 
FROM sys.dm_exec_sql_text (0x02000000F4672D358C9983A9B5C5439740F549BAC1672BF6) --sql_handle

SELECT *
FROM sys.dm_exec_query_plan (0x06000500F4672D354003918C010000000000000000000000) --plan_handle


SELECT * 
FROM sys.sysprocesses  
WHERE lastwaittype like 'PAGE%LATCH_%' AND waitresource like '5:%'

SELECT session_id, wait_duration_ms, resource_description
FROM sys.dm_os_waiting_tasks
WHERE wait_type like 'PAGE%LATCH_%' AND resource_description like '5:%'

/*
SELECT P.object_id, object_name(P.object_id) as object_name, 
       P.index_id, BD.page_type
FROM 	 sys.dm_os_buffer_descriptors BD, sys.allocation_units A,
     	 sys.partitions P 
WHERE  BD.allocation_unit_id = A.allocation_unit_id and  
       A.container_id = P.partition_id
*/

-- os schedulers queue
select * from sys.dm_os_sys_info
go
SELECT
    scheduler_id,
    cpu_id,
    parent_node_id,
    current_tasks_count,
    runnable_tasks_count,
    current_workers_count,
    active_workers_count,
    work_queue_count
  FROM sys.dm_os_schedulers;

-- to associate a session ID value with a Windows thread ID

SELECT STasks.session_id, SThreads.os_thread_id
  FROM sys.dm_os_tasks AS STasks
  INNER JOIN sys.dm_os_threads AS SThreads
    ON STasks.worker_address = SThreads.worker_address
  WHERE STasks.session_id IS NOT NULL
  ORDER BY STasks.session_id;
GO
-- to check raw log information

select * from ::fn_dblog(null,null)

-- find out how long a worker has been running in a SUSPENDED or RUNNABLE state
SELECT 
    t1.session_id,
    CONVERT(varchar(10), t1.status) AS status,
    CONVERT(varchar(15), t1.command) AS command,
    CONVERT(varchar(10), t2.state) AS worker_state,
    w_suspended = 
      CASE t2.wait_started_ms_ticks
        WHEN 0 THEN 0
        ELSE 
          t3.ms_ticks - t2.wait_started_ms_ticks
      END,
    w_runnable = 
      CASE t2.wait_resumed_ms_ticks
        WHEN 0 THEN 0
        ELSE 
          t3.ms_ticks - t2.wait_resumed_ms_ticks
      END
  FROM sys.dm_exec_requests AS t1
  INNER JOIN sys.dm_os_workers AS t2
    ON t2.task_address = t1.task_address
  CROSS JOIN sys.dm_os_sys_info AS t3
  WHERE t1.scheduler_id IS NOT NULL;


SELECT objtype AS 'Cached Object Type',
count(*) AS 'Number of Plans',
sum(cast(size_in_bytes AS BIGINT))/1024/1024 AS 'Plan Cache Size (MB)',
avg(usecounts) AS 'Avg Use Count'
FROM sys.dm_exec_cached_plans
GROUP BY objtype

--SELECT * FROM sys.dm_os_memory_cache_entries
/*
select [Store Address], [id], count (*) 'number of entries'
from  
	(select 
		 cast(entry_data as xml).value ('(//@store_address)[1]', 'varchar (100)') as [Store Address],
		 cast(entry_data as xml).value ('(//@id)[1]', 'bigint') as [id]
		 from sys.dm_os_memory_cache_entries
		where type = 'USERSTORE_TOKENPERM' and cast(entry_data as xml).value ('(//@name)[1]', 'varchar (100)') = 'TokenAccessResult' and 
			cast(entry_data as xml).value('(//@class)[1]', 'bigint') = 65535
	) R 
group by [Store Address], [id] 
having count (*) > 1
order by count (*) desc
*/



SELECT * FROM sys.dm_os_memory_cache_clock_hands 

SELECT type, virtual_memory_committed_kb, single_pages_kb, multi_pages_kb
FROM sys.dm_os_memory_clerks
WHERE virtual_memory_committed_kb > 0 OR multi_pages_kb > 0 OR single_pages_kb > 0
order by type

--dbcc sqlperf (spinlockstats)

SELECT SUM(single_pages_kb + multi_pages_kb) AS 
   'CurrentSizeOfTokenCache(kb)' 
   FROM sys.dm_os_memory_clerks 
   WHERE name = 'TokenAndPermUserStore'

SELECT SUM(single_pages_kb + multi_pages_kb)AS 
   'CurrentSizeOfSQLCLRCache(kb)'  
FROM sys.dm_os_memory_clerks 
WHERE [type] like 'MEMORYCLERK_SQLCLR'


SELECT  TOP 6
	LEFT([name], 20) as [name],
	LEFT([type], 20) as [type],
	[single_pages_kb] + [multi_pages_kb] AS cache_kb,
	[entries_count], [entries_in_use_count]
FROM sys.dm_os_memory_cache_counters 
order by single_pages_kb + multi_pages_kb DESC

--dbcc memorystatus


SELECT
    scheduler_id,
    cpu_id,
    parent_node_id,
    current_tasks_count,
    runnable_tasks_count,
    current_workers_count,
    active_workers_count,
    work_queue_count
  FROM sys.dm_os_schedulers;
  
  


SELECT name, type, SUM(single_pages_kb+ multi_pages_kb) AS cache_kb 
FROM sys.dm_os_memory_clerks 
GROUP BY name, type  
ORDER BY SUM(single_pages_kb+ multi_pages_kb) DESC

sp_configure 'show advanced options', 0
go
reconfigure


SELECT * FROM sys.dm_os_process_memory


-- alter table pa disable trigger all


SELECT TOP 10 SUBSTRING(text, (statement_start_offset/2) + 1,
((CASE statement_end_offset
WHEN -1
THEN DATALENGTH(text) 
ELSE statement_end_offset
END - statement_start_offset)/2) + 1) AS query_text, * 
FROM sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle) 
ORDER BY total_elapsed_time DESC

SELECT usecounts, cacheobjtype, objtype, bucketid, text 
FROM sys.dm_exec_cached_plans
 	CROSS APPLY sys.dm_exec_sql_text(plan_handle) 
WHERE cacheobjtype = 'Compiled Plan' 
ORDER BY usecounts DESC, objtype;


select * from sys.dm_io_pending_io_requests

select * from sys.dm_os_wait_stats where wait_type like '%disk%'

-- transações

DECLARE @cntr_value bigint

SELECT @cntr_value = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE 'Transactions/sec%'
AND instance_name LIKE '_Total%'

WAITFOR DELAY '00:00:01'

SELECT cntr_value - @cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE 'Transactions/sec%'
AND instance_name LIKE '_Total%'

SELECT T.text, P.query_plan,
EQS.plan_generation_num, EQS.execution_count 
FROM sys.dm_exec_query_stats AS EQS
CROSS APPLY sys.dm_exec_sql_text(EQS.plan_handle) AS T
CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle) AS P
ORDER BY EQS.execution_count desc
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
 
WITH XMLNAMESPACES(DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
     SELECT query_plan AS CompleteQueryPlan, 
            n.value('(@StatementText)[1]', 'VARCHAR(4000)') AS StatementText, 
            n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)') AS StatementOptimizationLevel, 
            n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)') AS StatementSubTreeCost, 
            n.query('.') AS ParallelSubTreeXML, 
            ecp.usecounts, 
            ecp.size_in_bytes
     FROM sys.dm_exec_cached_plans AS ecp
          CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS eqp
          CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
     WHERE n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1
     ORDER BY StatementSubTreeCost DESC;

SELECT TOP (10) SUBSTRING(ST.text, (QS.statement_start_offset / 2) + 1, ((CASE statement_end_offset
                                                                              WHEN -1
                                                                              THEN DATALENGTH(st.text)
                                                                              ELSE QS.statement_end_offset
                                                                          END - QS.statement_start_offset) / 2) + 1) AS statement_text, 
                execution_count, 
                total_worker_time / 1000 AS total_worker_time_ms, 
                (total_worker_time / 1000) / execution_count AS avg_worker_time_ms, 
                total_logical_reads, 
                total_logical_reads / execution_count AS avg_logical_reads, 
                total_elapsed_time / 1000 AS total_elapsed_time_ms, 
                (total_elapsed_time / 1000) / execution_count AS avg_elapsed_time_ms, 
                qp.query_plan
FROM sys.dm_exec_query_stats qs
     CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
     CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY total_worker_time DESC;

select top 20
OBJECT_NAME(st.objectid) AS Objeto, st.dbid, total_worker_time/execution_count AS AverageCPUTime,
CASE statement_end_offset
WHEN -1 THEN st.text
ELSE
SUBSTRING(st.text,statement_start_offset/2,statement_end_offset/2)
END AS StatementText
from  sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY AverageCPUTime DESC

SELECT
DB_NAME(mf.database_id) AS databaseName,
name AS File_LogicalName,
CASE
WHEN type_desc = 'LOG' THEN 'Log File'
WHEN type_desc = 'ROWS' THEN 'Data File'
ELSE type_desc
END AS File_type_desc
,mf.physical_name
,num_of_reads
,num_of_bytes_read
,io_stall_read_ms
,num_of_writes
,num_of_bytes_written
,io_stall_write_ms
,io_stall
,size_on_disk_bytes
,size_on_disk_bytes/ 1024 AS size_on_disk_KB
,size_on_disk_bytes/ 1024 / 1024 AS size_on_disk_MB
,size_on_disk_bytes/ 1024 / 1024 / 1024 AS size_on_disk_GB
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id
AND mf.FILE_ID = divfs.FILE_ID
ORDER BY num_of_Reads DESC


SELECT mg.session_id
,mg.request_id
,mg.scheduler_id
,mg.request_time
,mg.grant_time
,mg.requested_memory_kb
,granted_memory_kb
,mg.query_cost
,c.TEXT
,t.query_plan
FROM sys.dm_exec_query_memory_grants mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS C
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS T


SELECT 
	login_name,
	COUNT(*) AS TotalCon 
FROM 
	SYS.dm_exec_sessions
GROUP BY
	login_name
ORDER BY
	TotalCon DESC