-- Create the Event Session to track LOP_DELETE_SPLIT transaction_log operations in the server
CREATE EVENT SESSION [VitaDB_TrackPageSplits]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
    WHERE operation = 11  -- LOP_DELETE_SPLIT 
)
ADD TARGET package0.histogram(
    SET filtering_event_name = 'sqlserver.transaction_log',
        source_type = 0, -- Event Column
        source = 'alloc_unit_id');
GO
ALTER EVENT SESSION [VitaDB_TrackPageSplits] ON SERVER 
 WITH (STARTUP_STATE=ON)

USE [master]
go
CREATE VIEW VW_TRACKPAGESPLITS
AS
-- Query Target Data to get the top splitting objects in the database:
SELECT
    tab.database_name,
	o.name AS table_name,
    i.name AS index_name,
    tab.split_count,
    i.fill_factor
FROM (    SELECT
			DB_NAME(n.value('(value)[1]', 'bigint')) AS database_name, 
            n.value('(value)[1]', 'bigint') AS alloc_unit_id,
            n.value('(@count)[1]', 'bigint') AS split_count
        FROM
        (SELECT CAST(target_data as XML) target_data
         FROM sys.dm_xe_sessions AS s 
         JOIN sys.dm_xe_session_targets t
             ON s.address = t.event_session_address
         WHERE s.name = 'VitaDB_TrackPageSplits'
          AND t.target_name = 'histogram' ) as tab
        CROSS APPLY target_data.nodes('HistogramTarget/Slot') as q(n)
) AS tab
JOIN sys.allocation_units AS au
    ON tab.alloc_unit_id = au.allocation_unit_id
JOIN sys.partitions AS p
    ON au.container_id = p.partition_id
JOIN sys.indexes AS i
    ON p.object_id = i.object_id
        AND p.index_id = i.index_id
JOIN sys.objects AS o
    ON p.object_id = o.object_id
WHERE o.is_ms_shipped = 0;


-------------------------------------------
--Processar dados coletados
-------------------------------------------
CREATE TABLE TrackPageSplit (database_name NVARCHAR(300), table_name NVARCHAR(1000), index_name NVARCHAR(2000),
split_count INT, fill_factor int, date_collected DATETIME)
GO

exec sp_msforeachdb @command1 = 'set quoted_identifier on
USE [?] 
INSERT INTO [master]..TrackPageSplit
SELECT
    DB_NAME(),
	o.name AS table_name,
    i.name AS index_name,
    tab.split_count,
    i.fill_factor,
	getdate()
FROM (    SELECT
            n.value(''(value)[1]'', ''bigint'') AS alloc_unit_id,
            n.value(''(@count)[1]'', ''bigint'') AS split_count
        FROM
        (SELECT CAST(target_data as XML) target_data
         FROM sys.dm_xe_sessions AS s 
         JOIN sys.dm_xe_session_targets t
             ON s.address = t.event_session_address
         WHERE s.name = ''Pythian_TrackPageSplits''
          AND t.target_name = ''histogram'' ) as tab
        CROSS APPLY target_data.nodes(''HistogramTarget/Slot'') as q(n)
) AS tab
JOIN sys.allocation_units AS au
    ON tab.alloc_unit_id = au.allocation_unit_id
JOIN sys.partitions AS p
    ON au.container_id = p.partition_id
JOIN sys.indexes AS i
    ON p.object_id = i.object_id
        AND p.index_id = i.index_id
JOIN sys.objects AS o
    ON p.object_id = o.object_id
WHERE o.is_ms_shipped = 0;'






--Track Page splits without the XEvents Session
CREATE TABLE TrackPageSplit (ServerName NVARCHAR(50), database_name NVARCHAR(300), table_name NVARCHAR(1000), index_name NVARCHAR(2000),
PAGE_SPLIT_FOR_INDEX INT, PAGE_ALLOCATION_CAUSED_BYPAGESPLIT int)
GO

exec sp_msforeachdb @command1 = 'set quoted_identifier on
USE [?] 
INSERT INTO master..TrackPageSplit
SELECT
@@servername AS ServerName,
DB_NAME() as DatabaseName,
O.NAME AS OBJECT_NAME,
I.NAME AS INDEX_NAME,
IOS.LEAF_ALLOCATION_COUNT AS PAGE_SPLIT_FOR_INDEX,
IOS.NONLEAF_ALLOCATION_COUNT PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS(DB_ID(N''DB_NAME''),NULL,NULL,NULL) IOS JOIN
SYS.INDEXES I
ON
IOS.INDEX_ID=I.INDEX_ID
AND IOS.OBJECT_ID = I.OBJECT_ID JOIN
SYS.OBJECTS O
ON
IOS.OBJECT_ID=O.OBJECT_ID
WHERE O.TYPE_DESC=''USER_TABLE'''
GO
SELECT * FROM master..TrackPageSplit WHERE database_name NOT IN('tempdb', 'master','msdb')
ORDER BY PAGE_SPLIT_FOR_INDEX DESC


SELECT

IOS.INDEX_ID,
O.NAME AS OBJECT_NAME,
I.NAME AS INDEX_NAME,
IOS.LEAF_ALLOCATION_COUNT AS PAGE_SPLIT_FOR_INDEX,
IOS.NONLEAF_ALLOCATION_COUNT PAGE_ALLOCATION_CAUSED_BY_PAGESPLIT
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS(DB_ID(N'DB_NAME'),NULL,NULL,NULL) IOS
JOIN
SYS.INDEXES I
ON
IOS.INDEX_ID=I.INDEX_ID
AND IOS.OBJECT_ID = I.OBJECT_ID
JOIN
SYS.OBJECTS O
ON
IOS.OBJECT_ID=O.OBJECT_ID
WHERE O.TYPE_DESC='USER_TABLE'