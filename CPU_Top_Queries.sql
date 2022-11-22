;WITH eqs
AS (
    SELECT 
         [execution_count]
        ,[total_worker_time]/1000  AS [TotalCPUTime_ms]
        ,[total_elapsed_time]/1000  AS [TotalDuration_ms]
        ,query_hash
        ,plan_handle
        ,[sql_handle]
    FROM sys.dm_exec_query_stats
    )
SELECT TOP 10 est.[text], eqp.query_plan AS SQLStatement
    ,eqs.*
FROM eqs
OUTER APPLY sys.dm_exec_query_plan(eqs.plan_handle) eqp
OUTER APPLY sys.dm_exec_sql_text(eqs.sql_handle) AS est
ORDER BY [TotalCPUTime_ms] DESC


SELECT
	ES.session_id,
	ES.cpu_time,
	ES.total_scheduled_time,
	ES.total_elapsed_time,
	ES.last_request_start_time,
	ES.last_request_end_time,
	ES.[host_name],
	ES.[program_name],
	ES.client_interface_name,
	ES.login_name,
	EC.net_transport,
	ES.nt_domain,
	ES.nt_user_name,
	EC.client_net_address,
	EC.local_net_address,
	(SELECT [Text] FROM master.sys.dm_exec_sql_text(EC.most_recent_sql_handle )) as sqlscript,
	UPPER(ES.[Status]) AS [Status],
	(SELECT DB_NAME([dbid]) FROM master.sys.dm_exec_sql_text(EC.most_recent_sql_handle )) as databasename,
	(SELECT OBJECT_ID([objectid]) FROM master.sys.dm_exec_sql_text(EC.most_recent_sql_handle )) as objectname
FROM
	sys.dm_exec_sessions ES
INNER JOIN 
	sys.dm_exec_connections EC
ON 
	EC.session_id = ES.session_id
--WHERE
--	UPPER(ES.[Status]) = 'RUNNING'
ORDER BY
	ES.cpu_time DESC


