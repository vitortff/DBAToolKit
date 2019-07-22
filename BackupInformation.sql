--Lista os backups
SELECT bs.database_name,
       bs.type,
       Max(bs.backup_start_date) AS backup_start_date
FROM   master..sysdatabases sd
       LEFT JOIN msdb..backupset bs
              ON bs.database_name = sd.NAME
       LEFT JOIN msdb..backupmediafamily bmf
              ON bs.media_set_id = bmf.media_set_id
GROUP  BY sd.NAME,
          bs.type,
          bs.database_name
ORDER  BY backup_start_date ASC,
          bs.database_name,
          bs.type 

--Tamanho do banco de dados pelo backup
SELECT
[database_name] AS "Database",
DATEPART(month,[backup_start_date]) AS "Month",
AVG([backup_size]/1024/1024) AS "Backup Size MB",
AVG([compressed_backup_size]/1024/1024) AS "Compressed Backup Size MB",
AVG([backup_size]/[compressed_backup_size]) AS "Compression Ratio"
FROM msdb.dbo.backupset
WHERE [database_name] = N'AdventureWorks'
AND [type] = 'D'
GROUP BY [database_name],DATEPART(mm,[backup_start_date]);

--Backup estimation time
SELECT 
	dmr.session_id,
	dmr.command,
	CONVERT(NUMERIC(6,2),dmr.percent_complete)AS [Percent Complete],
	CONVERT(VARCHAR(20),DATEADD(ms,dmr.estimated_completion_time,GetDate()),20) AS [ETA Completion Time],
	CONVERT(NUMERIC(10,2),dmr.total_elapsed_time/1000.0/60.0) AS [Elapsed Min],
	CONVERT(NUMERIC(10,2),dmr.estimated_completion_time/1000.0/60.0) AS [ETA Min],
	CONVERT(NUMERIC(10,2),dmr.estimated_completion_time/1000.0/60.0/60.0) AS [ETA Hours]
	,CONVERT(VARCHAR(1000),(SELECT SUBSTRING(text,dmr.statement_start_offset/2,	
								   CASE WHEN dmr.statement_end_offset = -1 THEN 1000 
								   ELSE (dmr.statement_end_offset-dmr.statement_start_offset)/2 END) 
							FROM sys.dm_exec_sql_text(sql_handle)
							)
					) [sqltxt]
FROM sys.dm_exec_requests dmr WHERE command IN ('RESTORE DATABASE','BACKUP DATABASE')