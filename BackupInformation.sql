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