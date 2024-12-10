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
GROUP BY [database_id]
ORDER BY MBUsed DESC
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

--Uso da Buffer Pool
SELECT
      (committed_kb)/1024.0 as BPool_Committed_MB,
      (committed_target_kb)/1024.0 as BPool_Commit_Tgt_MB,
      (visible_target_kb)/1024.0 as BPool_Visible_MB
FROM  sys.dm_os_sys_info;

--Uso de memória pelo SO
select
      total_physical_memory_kb/1024 AS total_physical_memory_mb,
      available_physical_memory_kb/1024 AS available_physical_memory_mb,
      total_page_file_kb/1024 AS total_page_file_mb,
      available_page_file_kb/1024 AS available_page_file_mb,
      100 - (100 * CAST(available_physical_memory_kb AS DECIMAL(18,3))/CAST(total_physical_memory_kb AS DECIMAL(18,3))) 
      AS 'Percentage_Used',
      system_memory_state_desc
from  sys.dm_os_sys_memory;

-- Uso de memória pelo processo do SQL Server 
select
      physical_memory_in_use_kb/1048576.0 AS 'physical_memory_in_use (GB)',
      locked_page_allocations_kb/1048576.0 AS 'locked_page_allocations (GB)',
      virtual_address_space_committed_kb/1048576.0 AS 'virtual_address_space_committed (GB)',
      available_commit_limit_kb/1048576.0 AS 'available_commit_limit (GB)',
      page_fault_count as 'page_fault_count'
from  sys.dm_os_process_memory;

--Uso de memória por cada banco de dados da instancia
DECLARE @total_buffer INT;
SELECT  @total_buffer = cntr_value 
FROM   sys.dm_os_performance_counters
WHERE  RTRIM([object_name]) LIKE '%Buffer Manager' 
       AND counter_name = 'Database Pages';

;WITH DBBuffer AS
(
SELECT  database_id,
        COUNT_BIG(*) AS db_buffer_pages,
        SUM (CAST ([free_space_in_bytes] AS BIGINT)) / (1024 * 1024) AS [MBEmpty]
FROM    sys.dm_os_buffer_descriptors
GROUP BY database_id
)
SELECT
       CASE [database_id] WHEN 32767 THEN 'Resource DB' ELSE DB_NAME([database_id]) END AS 'db_name',
       db_buffer_pages AS 'db_buffer_pages',
       db_buffer_pages / 128 AS 'db_buffer_Used_MB',
       [mbempty] AS 'db_buffer_Free_MB',
       CONVERT(DECIMAL(6,3), db_buffer_pages * 100.0 / @total_buffer) AS 'db_buffer_percent'
FROM   DBBuffer
ORDER BY db_buffer_Used_MB DESC;

--Uso de memória por objeto
;WITH obj_buffer AS
(
SELECT
       [Object] = o.name,
       [Type] = o.type_desc,
       [Index] = COALESCE(i.name, ''),
       [Index_Type] = i.type_desc,
       p.[object_id],
       p.index_id,
       au.allocation_unit_id
FROM
       sys.partitions AS p
       INNER JOIN sys.allocation_units AS au ON p.hobt_id = au.container_id
       INNER JOIN sys.objects AS o ON p.[object_id] = o.[object_id]
       INNER JOIN sys.indexes AS i ON o.[object_id] = i.[object_id] AND p.index_id = i.index_id
WHERE
       au.[type] IN (1,2,3) AND o.is_ms_shipped = 0
)
SELECT
       obj.[Object],
       obj.[Type],
       obj.[Index],
       obj.Index_Type,
       COUNT_BIG(b.page_id) AS 'buffer_pages',
       COUNT_BIG(b.page_id) / 128 AS 'buffer_mb'
FROM
       obj_buffer obj 
       INNER JOIN sys.dm_os_buffer_descriptors AS b ON obj.allocation_unit_id = b.allocation_unit_id
WHERE
       b.database_id = DB_ID()
GROUP BY
       obj.[Object],
       obj.[Type],
       obj.[Index],
       obj.Index_Type
ORDER BY
       buffer_pages DESC;