--Verifica posição de restore do LogShipping

DECLARE @LowRPOWarning INT = 5
DECLARE @MediumRPOWarning INT = 10
DECLARE @HighRPOWarning INT = 15

;WITH LastRestores AS
(
    SELECT
        d.name AS [Database],
        bmf.physical_device_name AS [LastFileRestored],
        r.restore_date AS [LastRestoreDate],
        ROW_NUMBER() OVER (PARTITION BY d.name ORDER BY r.restore_date DESC) AS RowNum
    FROM master.sys.databases d
    INNER JOIN msdb.dbo.restorehistory r ON r.destination_database_name = d.name
    INNER JOIN msdb.dbo.backupset bs ON r.backup_set_id = bs.backup_set_id
    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
)
SELECT 
    CASE 
        WHEN DATEDIFF(MINUTE, LastRestoreDate, GETDATE()) > @HighRPOWarning THEN 'RPO High Warning!'
        WHEN DATEDIFF(MINUTE, LastRestoreDate, GETDATE()) > @MediumRPOWarning THEN 'RPO Medium Warning!'
        WHEN DATEDIFF(MINUTE, LastRestoreDate, GETDATE()) > @LowRPOWarning THEN 'RPO Low Warning!'
        ELSE 'RPO Good'
    END AS [Status],
    [Database],
    [LastFileRestored],
    [LastRestoreDate] AS [LastLogRestoredAt],
    DATEDIFF(MINUTE, LastRestoreDate, GETDATE()) AS [RPO (Minutes)]
FROM LastRestores
WHERE RowNum = 1;
