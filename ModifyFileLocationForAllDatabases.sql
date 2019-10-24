SELECT 'ALTER DATABASE '+ DB_NAME(database_id) +' MODIFY FILE ( NAME = '''+name+''', FILENAME ='''+REPLACE(physical_name,'F:\Log','E:\Log')+''')',* FROM SYS.master_files
--WHERE type = 1 and DB_NAME(database_id) NOT IN('tempdb','master','model','msdb') 
ORDER BY DB_NAME(database_id) asc