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


SELECT 
		@@SERVERNAME AS ServerName,
		bs.database_name,
       CASE bs.type
		WHEN 'D' THEN 'Full'
		WHEN 'I' THEN 'Differential'
		WHEN 'L' THEN 'Log'
		WHEN 'F' THEN 'File or filegroup' 
		WHEN 'G' THEN 'Differential file'
		WHEN 'P' THEN 'Partial'
		WHEN 'Q' THEN 'Differential partial'
		END Backup_Type,
       Max(bs.backup_start_date) AS backup_start_date,
	   physical_device_name,
	   CASE device_type
		WHEN '2'	THEN 'Disk'
		WHEN '5'	THEN 'Tape'
		WHEN '7'	THEN 'Virtual device'
		WHEN '9'	THEN 'Azure Storage'
		WHEN '105'	THEN 'A permanent backup device'
		END device_type
FROM   master..sysdatabases sd
       LEFT JOIN msdb..backupset bs
              ON bs.database_name = sd.NAME
       LEFT JOIN msdb..backupmediafamily bmf
              ON bs.media_set_id = bmf.media_set_id
WHERE
	backup_start_date BETWEEN '20221101' AND '20221130'
GROUP  BY sd.NAME,
          bs.type,
          bs.database_name,
		  physical_device_name,
		  device_type
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


--Informação de inicio e fim dos backups
SELECT 
  bup.user_name AS [User],
  bup.database_name AS [Database],
  bup.server_name AS [Server],
  bup.backup_start_date AS [Backup Started],
  bup.backup_finish_date AS [Backup Finished]
  ,CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/3600 AS varchar) + ' hours, ' 
  + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))/60 AS varchar)+ ' minutes, '
  + CAST((CAST(DATEDIFF(s, bup.backup_start_date, bup.backup_finish_date) AS int))%60 AS varchar)+ ' seconds'
  AS [Total Time]
FROM msdb.dbo.backupset bup
WHERE bup.backup_set_id IN
  (SELECT MAX(backup_set_id) 
   FROM msdb.dbo.backupset
   --WHERE database_name = ISNULL(@dbname, database_name) --if no dbname, then return all
   --AND 
   WHERE type = 'D' --only interested in the time of last full backup
   GROUP BY database_name) 
/* COMMENT THE NEXT LINE IF YOU WANT ALL BACKUP HISTORY */
AND bup.database_name IN (SELECT name FROM master.dbo.sysdatabases)
ORDER BY bup.database_name