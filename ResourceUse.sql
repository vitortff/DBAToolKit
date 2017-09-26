--------------Para listas as conexões ordenadas por maior leitura e escrita na sessão
SELECT 	
--sys.dm_exec_sessions as DM_ES
	DM_ES.Session_ID,
	DM_ES.Login_time,
	DM_ES.Host_Name,
	DM_ES.Program_Name,
	DM_ES.Login_name,
	DM_ES.Status,
	DM_ES.CPU_Time,
	DM_ES.Memory_usage,
	DM_ES.Total_Elapsed_Time,
	DM_ES.Reads,
	DM_ES.Writes,
	DM_ES.Logical_Reads,
	DM_ES.Transaction_Isolation_Level ,
--sys.dm_exec_connections as DM_EX1
	DM_EX1.Num_Reads	AS NumPckReadCnx, --Number of packet reads that have occurred over this connection. Is nullable
	DM_EX1.Num_Writes	AS NumPckWritCNX,--Number of data packet writes that have occurred over this connection. Is nullable.
	DM_EX1.Net_Transport,
	DM_EX1.Net_Packet_Size,
	DM_EX1.Last_Read, 
	DM_EX1.Last_Write,
	DM_EX1.Client_Net_Address,
	db_name (Database_Id) as DbName,
	DM_EX1.Local_Net_Address,
	(CASE DM_ES.transaction_isolation_level  
	WHEN 0 THEN  'Unspecified'
	WHEN 1 THEN  'ReadUncomitted'
	WHEN 2 THEN  'ReadCommitted'
	WHEN 3 THEN  'Repeatable'
	WHEN 4 THEN  'Serializable'
	WHEN 5 THEN  'Snapshot' END)AS Transaction_Isolation_Level,
	--DM_EX1.Most_Recent_Sql_Handle, --The SQL handle of the last request executed on this connection. The most_recent_sql_handle column is always in sync with the most_recent_session_id column. Is nullable
	/*(SELECT TOP 1 SUBSTRING(text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,*/
    DM_Er.Row_Count as NumRowsMoment,
	DM_ES.UnsuccessFul_Logons,
	DM_ER.lock_timeout,
(SELECT [Text] FROM master.sys.dm_exec_sql_text(DM_EX1.most_recent_sql_handle )) as sqlscript

FROM		  sys.dm_exec_connections	AS DM_EX1 
LEFT JOIN	  sys.dm_exec_connections	AS DM_EX2	ON DM_EX1.parent_connection_id = DM_EX2.connection_id 
LEFT JOIN	  sys.dm_exec_sessions		AS DM_ES	ON DM_ES.session_id			   = DM_EX1.session_id 
LEFT JOIN	  sys.dm_exec_requests		AS DM_ER	ON DM_EX1.connection_id		   = DM_ER.connection_id
LEFT JOIN	  sys.dm_broker_connections AS DM_BC	ON DM_EX1.connection_id		   = DM_BC.connection_id
OUTER  APPLY	  sys.dm_exec_sql_text(sql_handle)AS  st
order by DM_ES.Total_Elapsed_Time desc, NumPckWritCNX desc,NumPckReadCnx desc

/*
---------------
SELECT s2.dbid, 
    s1.sql_handle,  
    (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
    execution_count, 
    plan_generation_num, 
    last_execution_time,   
    total_worker_time, 
    last_worker_time, 
    min_worker_time, 
    max_worker_time,
    total_physical_reads, 
    last_physical_reads, 
    min_physical_reads,  
    max_physical_reads,  
    total_logical_writes, 
    last_logical_writes, 
    min_logical_writes, 
    max_logical_writes  
FROM sys.dm_exec_query_stats AS s1 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s2  
WHERE s2.objectid is null 
ORDER BY total_worker_time desc,s1.sql_handle, s1.statement_start_offset, s1.statement_end_offset;
----------------------------------------------------------------------------
SELECT TOP 10 total_worker_time/execution_count AS [Avg CPU Time],
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY total_worker_time/execution_count DESC;
----------------------------------------------------------------------------
*/