SELECT 'KILL '+ CAST(ES.SESSION_ID AS VARCHAR),* FROM SYS.dm_exec_sessions ES
INNER JOIN 
	sys.dm_exec_connections EC
ON 
	EC.session_id = ES.session_id
--WHERE login_name = 'abacos_ep'
WHERE login_name LIKE 'NETSHOES\%' AND login_name NOT IN ('NETSHOES\vitor.fava',
'NETSHOES\tatiana.girao','NETSHOES\elcio.sato','NETSHOES\MSSQLService','NETSHOES\MSSQLAGENT','NETSHOES\marcelo.tomiyama')
--SELECT login_name, COUNT(*) FROM SYS.dm_exec_sessions
--GROUP BY login_name
--ORDER BY 2 DESC
