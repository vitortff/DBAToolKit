-- Database size growth as a list

-- Transact-SQL script to analyse the database size growth using backup history.

/*
This Transact-SQL script uses the backup history to analyse the growth of the databases size over a given period.
Additional to the minimul, maximum and average size per month the growth of average size related to the former month is calculated.
The values are useful for future resource planning of the storage and backup system.

Works with MS SQL Server 2005 and higher versions in all editions.
Requires access and select permissions to the msdb system database.
*/

-- Transact-SQL script to analyse the database size growth using backup history.
DECLARE @endDate datetime, @months smallint;
SET @endDate = GetDate();  -- Include in the statistic all backups from today
SET @months = 6;           -- back to the last 6 months.

;WITH HIST AS
   (SELECT BS.database_name AS DatabaseName
          ,YEAR(BS.backup_start_date) * 100
           + MONTH(BS.backup_start_date) AS YearMonth
          ,CONVERT(numeric(10, 1), MIN(BF.file_size / 1048576.0)) AS MinSizeMB
          ,CONVERT(numeric(10, 1), MAX(BF.file_size / 1048576.0)) AS MaxSizeMB
          ,CONVERT(numeric(10, 1), AVG(BF.file_size / 1048576.0)) AS AvgSizeMB
    FROM msdb.dbo.backupset as BS
         INNER JOIN
         msdb.dbo.backupfile AS BF
             ON BS.backup_set_id = BF.backup_set_id
    WHERE NOT BS.database_name IN
              ('master', 'msdb', 'model', 'tempdb')
          AND BF.file_type = 'D'
          AND BS.backup_start_date BETWEEN DATEADD(mm, - @months, @endDate) AND @endDate
    GROUP BY BS.database_name
            ,YEAR(BS.backup_start_date)
            ,MONTH(BS.backup_start_date))
SELECT MAIN.DatabaseName
      ,MAIN.YearMonth
      ,MAIN.MinSizeMB
      ,MAIN.MaxSizeMB
      ,MAIN.AvgSizeMB
      ,MAIN.AvgSizeMB 
       - (SELECT TOP 1 SUB.AvgSizeMB
          FROM HIST AS SUB
          WHERE SUB.DatabaseName = MAIN.DatabaseName
                AND SUB.YearMonth < MAIN.YearMonth
          ORDER BY SUB.YearMonth DESC) AS GrowthMB
FROM HIST AS MAIN
ORDER BY MAIN.DatabaseName
        ,MAIN.YearMonth