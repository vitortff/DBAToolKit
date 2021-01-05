--Verifica o PLE de dentro do SQL Server
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SELECT 
 ple.[Node] 
,LTRIM(STR([PageLife_S]/3600))+':'+REPLACE(STR([PageLife_S]%3600/60,2),SPACE(1),'0')+':'+REPLACE(STR([PageLife_S]%60,2),SPACE(1),'0') [PageLife] 
,ple.[PageLife_S] 
,dp.[DatabasePages] [BufferPool_Pages] 
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125) [BufferPool_MiB] 
,CONVERT(DECIMAL(15,3),dp.[DatabasePages]*0.0078125/[PageLife_S]) [BufferPool_MiB_S] 
FROM 
( 
SELECT [instance_name] [node],[cntr_value] [PageLife_S] FROM sys.dm_os_performance_counters 
WHERE [counter_name] = 'Page life expectancy' 
) ple 
INNER JOIN 
( 
SELECT [instance_name] [node],[cntr_value] [DatabasePages] FROM sys.dm_os_performance_counters 
WHERE [counter_name] = 'Database pages' 
) dp ON ple.[node] = dp.[node]


--identifica os MemObje que mais consomem memória
select * 
from sys.dm_os_memory_objects mo join 
     sys.dm_os_memory_clerks mc 
on mo.page_allocator_address = mc.page_allocator_address 
where mc.type = 'MEMORYCLERK_SQLGENERAL' 
order by pages_in_bytes desc

-- Script to for Examining Buffer Pool Usage demo
-- How about aggregating the empty space?
SELECT
	COUNT (*) * 8 / 1024 AS [MBUsed],
	SUM ([free_space_in_bytes]) / (1024 * 1024) AS [MBEmpty]
FROM sys.dm_os_buffer_descriptors;
GO

-- And by database
SELECT 
	(CASE WHEN ([database_id] = 32767)
		THEN N'Resource Database'
		ELSE DB_NAME ([database_id]) END) AS [DatabaseName],
	COUNT (*) * 8 / 1024 AS [MBUsed],
	SUM ([free_space_in_bytes]) / (1024 * 1024) AS [MBEmpty]
FROM sys.dm_os_buffer_descriptors
GROUP BY [database_id];
GO

--Check what is the table using most memory with empty pages
USE DATABASE;
GO

SELECT
	[s].[name] AS [Schema],
    [o].[name] AS [Object],
    [p].[index_id],
    [i].[name] AS [Index],
    [i].[type_desc] AS [Type],
    (DPCount + CPCount) * 8 / 1024 AS [TotalMB],
    ([DPFreeSpace] + [CPFreeSpace]) / 1024 / 1024 AS [FreeSpaceMB],
    CAST (ROUND (100.0 * (([DPFreeSpace] + [CPFreeSpace]) / 1024) /
		(([DPCount] + [CPCount]) * 8), 1) AS DECIMAL (4, 1)) AS [FreeSpacePC]
FROM
    (SELECT
        allocation_unit_id,
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 1 ELSE 0 END) AS [DPCount], 
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 0 ELSE 1 END) AS [CPCount],
        SUM (CASE WHEN ([is_modified] = 1)
            THEN CAST ([free_space_in_bytes] AS BIGINT) ELSE 0 END) AS [DPFreeSpace], 
        SUM (CASE WHEN ([is_modified] = 1)
            THEN 0 ELSE CAST ([free_space_in_bytes] AS BIGINT) END) AS [CPFreeSpace]
    FROM sys.dm_os_buffer_descriptors
    WHERE [database_id] = DB_ID ('Company')
    GROUP BY [allocation_unit_id]) AS [buffers]
INNER JOIN sys.allocation_units AS [au]
    ON [au].[allocation_unit_id] = [buffers].[allocation_unit_id]
INNER JOIN sys.partitions AS [p]
    ON [au].[container_id] = [p].[partition_id]
INNER JOIN sys.indexes AS [i]
    ON [i].[index_id] = [p].[index_id] AND [p].[object_id] = [i].[object_id]
INNER JOIN sys.objects AS [o]
    ON [o].[object_id] = [i].[object_id]
INNER JOIN sys.schemas AS [s]
    ON [s].[schema_id] = [o].[schema_id]
WHERE [o].[is_ms_shipped] = 0
--AND [p].[object_id] > 100 AND ([DPCount] + [CPCount]) > 12800 -- Taking up more than 100MB
ORDER BY [FreeSpaceMB] DESC;
