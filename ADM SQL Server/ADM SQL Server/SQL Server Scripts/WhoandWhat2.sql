--Utilizando as DMVs e DMFs da categoria sys.dm_exec, podemos listar informações
--detalhadas sobre as conexões existentes em uma instância de SQL Server, inclusive
--quais as queries que cada Login está executando no momento
SELECT
	ES.session_id,
	blocking_session_id as blking_id,
	ES.[host_name],
	ES.login_name,
	UPPER(ES.[Status]) AS [SesStatus], ER.[status] AS [ReqStatus],
	(SELECT DB_NAME(ER.database_id)) as databasename,
	ER.wait_time,
	ER.wait_type,
	ER.wait_resource,
		(SELECT [Text] FROM master.sys.dm_exec_sql_text(EC.most_recent_sql_handle )) as sqlscript,
	ES.last_request_end_time,
	ES.last_request_start_time,
	ES.[program_name],
	ES.client_interface_name,
	ES.cpu_time,
	ES.total_scheduled_time,
	ES.total_elapsed_time,
	EC.net_transport,
	ES.nt_domain,
	ES.nt_user_name,
	EC.client_net_address,
	EC.local_net_address,
	ER.row_count 
FROM
	sys.dm_exec_sessions ES
INNER JOIN 
	sys.dm_exec_connections EC
ON 
	EC.session_id = ES.session_id
INNER JOIN 
	sys.dm_exec_requests ER 
ON
	EC.session_id = ER.session_id
WHERE
EC.session_id <> @@SPID --and  
--UPPER(ES.[Status])not in ('SLEEPING','DORMANT')
--login_name = 'W3$GWMAP'
--UPPER(ES.[Status]) = 'RUNNING'
--ES.session_id = 572
ORDER BY
	ES.Status ASC, wait_time desc
	
/*

SELECT TOP 20 QS.*, 
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
    ((CASE statement_end_offset 
        WHEN -1 THEN DATALENGTH(st.text)
        ELSE QS.statement_end_offset END 
            - QS.statement_start_offset)/2) + 1) AS statement_text
     FROM sys.dm_exec_query_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST
     ORDER BY last_elapsed_time DESC
*/
GO

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
  WHERE t1.scheduler_id IS NOT NULL and session_id <> @@SPID
  ORDER BY t1.session_id DESC;
GO

--sp_who2 active
go


--sp_who active


-- dbcc inputbuffer (413)
-- dbcc sqlperf(logspace)
-- sp_who W3$GWMAP
-- sp_who2 664
-- sp_configure
-- kill 413
/*
select * from sys.dm_exec_sessions  
where host_name not like 'VM%'
and host_name not like 'SR%' 
and host_name not like 'CT%' 
and host_name not like 'DL%' 
and host_name not like 'DP%' 
and program_name not like 'SIPL%'
and host_name is not null
order by host_name
*/
/*
select * from sys.dm_exec_requests
select * from sys.dm_exec_sessions
select * from sys.dm_tran_locks
*/
