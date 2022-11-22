SELECT
	ES.session_id,
	ES.login_name,
	UPPER(ES.[Status]) AS [Status],
	(SELECT DB_NAME(ER.database_id)) as databasename,
	ES.last_request_end_time,
		(SELECT [Text] FROM master.sys.dm_exec_sql_text(EC.most_recent_sql_handle )) as sqlscript,
	ES.last_request_start_time,
	ES.[host_name],
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
	ER.wait_type,
	ER.wait_time,
	ER.wait_resource,
	blocking_session_id 
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
UPPER(ES.[Status])not in ('SLEEPING','DORMANT')
ORDER BY
	Status ASC, last_request_start_time desc
	
	