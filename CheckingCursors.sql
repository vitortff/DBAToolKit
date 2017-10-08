--Checking the query used on a CURSOR
SELECT c.session_id, es.program_name, es.login_name, es.host_name, DB_NAME(es.database_id) AS DatabaseName, c.properties, c.creation_time, c.is_open, t.text
FROM sys.dm_exec_cursors (0) c
LEFT JOIN sys.dm_exec_sessions AS es ON c.session_id = es.session_id
CROSS APPLY sys.dm_exec_sql_text (c.sql_handle) t