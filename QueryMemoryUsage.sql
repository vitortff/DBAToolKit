--Top 10 high memory consuming queries
SELECT TOP 10 OBJECT_NAME(qt.objectid) AS 'SP Name', 
              SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1, ((CASE qs.statement_end_offset
                                                                            WHEN -1
                                                                            THEN DATALENGTH(qt.text)
                                                                            ELSE qs.statement_end_offset
                                                                        END - qs.statement_start_offset) / 2) + 1) AS statement_text, 
              total_logical_reads, 
              qs.execution_count AS 'Execution Count', 
              total_logical_reads / qs.execution_count AS 'AvgLogicalReads', 
              qs.execution_count / DATEDIFF(minute, qs.creation_time, GETDATE()) AS 'Calls/minute', 
              qs.total_worker_time / qs.execution_count AS 'AvgWorkerTime', 
              qs.total_worker_time AS 'TotalWorkerTime', 
              qs.total_elapsed_time / qs.execution_count AS 'AvgElapsedTime', 
              qs.total_logical_writes, 
              qs.max_logical_reads, 
              qs.max_logical_writes, 
              qs.total_physical_reads, 
              qt.dbid, 
              qp.query_plan
FROM sys.dm_exec_query_stats AS qs
     CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
     OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qt.dbid = DB_ID() -- Filter by current database 
ORDER BY total_logical_reads DESC;

/**********************************************************
*   top procedures memory consumption per execution
*   (this will show mostly reports &amp; jobs)
***********************************************************/

SELECT TOP 100 *
FROM
(
    SELECT DatabaseName = DB_NAME(qt.dbid), 
           ObjectName = OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid), 
           DiskReads = SUM(qs.total_physical_reads)
           ,   -- The worst reads, disk reads 
           MemoryReads = SUM(qs.total_logical_reads)
           ,    --Logical Reads are memory reads 
           Executions = SUM(qs.execution_count), 
           IO_Per_Execution = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count), 
           CPUTime = SUM(qs.total_worker_time), 
           DiskWaitAndCPUTime = SUM(qs.total_elapsed_time), 
           MemoryWrites = SUM(qs.max_logical_writes), 
           DateLastExecuted = MAX(qs.last_execution_time)
    FROM sys.dm_exec_query_stats AS qs
         CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    GROUP BY DB_NAME(qt.dbid), 
             OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY IO_Per_Execution DESC;

/**********************************************************
*   top procedures memory consumption total
*   (this will show more operational procedures)
***********************************************************/

SELECT TOP 100 *
FROM
(
    SELECT DatabaseName = DB_NAME(qt.dbid), 
           ObjectName = OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid), 
           DiskReads = SUM(qs.total_physical_reads)
           ,   -- The worst reads, disk reads 
           MemoryReads = SUM(qs.total_logical_reads)
           ,    --Logical Reads are memory reads 
           Total_IO_Reads = SUM(qs.total_physical_reads + qs.total_logical_reads), 
           Executions = SUM(qs.execution_count), 
           IO_Per_Execution = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count), 
           CPUTime = SUM(qs.total_worker_time), 
           DiskWaitAndCPUTime = SUM(qs.total_elapsed_time), 
           MemoryWrites = SUM(qs.max_logical_writes), 
           DateLastExecuted = MAX(qs.last_execution_time)
    FROM sys.dm_exec_query_stats AS qs
         CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    GROUP BY DB_NAME(qt.dbid), 
             OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY Total_IO_Reads DESC;

/**********************************************************
*   top adhoc queries memory consumption total
***********************************************************/

SELECT TOP 100 *
FROM
(
    SELECT DatabaseName = DB_NAME(qt.dbid), 
           QueryText = qt.text, 
           DiskReads = SUM(qs.total_physical_reads)
           ,   -- The worst reads, disk reads 
           MemoryReads = SUM(qs.total_logical_reads)
           ,    --Logical Reads are memory reads 
           Total_IO_Reads = SUM(qs.total_physical_reads + qs.total_logical_reads), 
           Executions = SUM(qs.execution_count), 
           IO_Per_Execution = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count), 
           CPUTime = SUM(qs.total_worker_time), 
           DiskWaitAndCPUTime = SUM(qs.total_elapsed_time), 
           MemoryWrites = SUM(qs.max_logical_writes), 
           DateLastExecuted = MAX(qs.last_execution_time)
    FROM sys.dm_exec_query_stats AS qs
         CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    WHERE OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) IS NULL
    GROUP BY DB_NAME(qt.dbid), 
             qt.text, 
             OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY Total_IO_Reads DESC;

/**********************************************************
*   top adhoc queries memory consumption per execution
***********************************************************/

SELECT TOP 100 *
FROM
(
    SELECT DatabaseName = DB_NAME(qt.dbid), 
           QueryText = qt.text, 
           DiskReads = SUM(qs.total_physical_reads)
           ,   -- The worst reads, disk reads 
           MemoryReads = SUM(qs.total_logical_reads)
           ,    --Logical Reads are memory reads 
           Total_IO_Reads = SUM(qs.total_physical_reads + qs.total_logical_reads), 
           Executions = SUM(qs.execution_count), 
           IO_Per_Execution = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count), 
           CPUTime = SUM(qs.total_worker_time), 
           DiskWaitAndCPUTime = SUM(qs.total_elapsed_time), 
           MemoryWrites = SUM(qs.max_logical_writes), 
           DateLastExecuted = MAX(qs.last_execution_time)
    FROM sys.dm_exec_query_stats AS qs
         CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    WHERE OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) IS NULL
    GROUP BY DB_NAME(qt.dbid), 
             qt.text, 
             OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY IO_Per_Execution DESC;

/*************************************************************
*Extract information about the condition of OS memory and SQL memory
**************************************************************/

SELECT CONVERT(VARCHAR(30), GETDATE(), 121) AS [RunTime], 
       dateadd(MS, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) AS [Notification_Time], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type], 
       CAST(record AS XML).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %], 
       CAST(record AS XML).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [Process_Indicator], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [System_Indicator], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') AS [reserved], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') AS [reserved], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') AS [reserved], 
       CAST(record AS XML).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect], 
       CAST(record AS XML).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB], 
       CAST(record AS XML).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB], 
       CAST(record AS XML).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory], 
       CAST(record AS XML).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory], 
       CAST(record AS XML).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory], 
       CAST(record AS XML).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB], 
       CAST(record AS XML).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB], 
       CAST(record AS XML).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB], 
       CAST(record AS XML).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB], 
       CAST(record AS XML).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB], 
       CAST(record AS XML).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB], 
       CAST(record AS XML).value('(//Record/@id)[1]', 'bigint') AS [Record Id], 
       CAST(record AS XML).value('(//Record/@type)[1]', 'varchar(30)') AS [Type], 
       CAST(record AS XML).value('(//Record/@time)[1]', 'bigint') AS [Record Time], 
       tme.ms_ticks AS [Current Time]
FROM sys.dm_os_ring_buffers rbf
     CROSS JOIN sys.dm_os_sys_info tme
WHERE rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
ORDER BY rbf.timestamp ASC;

/*************************************************************
*Check the health of SQL Server including SQL Server working set
**************************************************************/

SELECT CONVERT(VARCHAR(30), GETDATE(), 121) AS runtime, 
       DATEADD(MS, a.[Record Time] - sys.ms_ticks, GETDATE()) AS Notification_time, 
       a.*, 
       sys.ms_ticks AS [Current Time]
FROM
(
    SELECT x.value('(//Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [ProcessUtilization], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle %], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/UserModeTime) [1]', 'bigint') AS [UserModeTime], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime) [1]', 'bigint') AS [KernelModeTime], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/PageFaults) [1]', 'bigint') AS [PageFaults], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta) [1]', 'bigint') / 1024 AS [WorkingSetDelta], 
           x.value('(//Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization) [1]', 'bigint') AS [MemoryUtilization (%workingset)], 
           x.value('(//Record/@time)[1]', 'bigint') AS [Record Time]
    FROM
(
    SELECT CAST(record AS XML)
    FROM sys.dm_os_ring_buffers
    WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
) AS R(x)
) a
CROSS JOIN sys.dm_os_sys_info sys
ORDER BY DATEADD(MS, a.[Record Time] - sys.ms_ticks, GETDATE());

--Listando os objetos que mais consomem memória
;WITH src AS
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
   INNER JOIN
       sys.allocation_units AS au
       ON p.hobt_id = au.container_id
   INNER JOIN
       sys.objects AS o
       ON p.[object_id] = o.[object_id]
   INNER JOIN
       sys.indexes AS i
       ON o.[object_id] = i.[object_id]
       AND p.index_id = i.index_id
   WHERE
       au.[type] IN (1,2,3)
       AND o.is_ms_shipped = 0
)
SELECT
   src.[Object],
   src.[Type],
   src.[Index],
   src.Index_Type,
   buffer_pages = COUNT_BIG(b.page_id),
   buffer_mb = COUNT_BIG(b.page_id) / 128
FROM
   src
INNER JOIN
   sys.dm_os_buffer_descriptors AS b
   ON src.allocation_unit_id = b.allocation_unit_id
WHERE
   b.database_id = DB_ID()
GROUP BY
   src.[Object],
   src.[Type],
   src.[Index],
   src.Index_Type
ORDER BY
   buffer_pages DESC;


--Analisar o plano de execução utilizando o indice listado na query anterior
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    DECLARE @IndexName AS NVARCHAR(128) = 'PK__Product__E1A99A1987FFF6EC';
    IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']') SET @IndexName = QUOTENAME(@IndexName);
    --Handle the case where the left or right was quoted manually but not the opposite side
    IF LEFT(@IndexName, 1) <> '[' SET @IndexName = '['+@IndexName;
    IF RIGHT(@IndexName, 1) <> ']' SET @IndexName = @IndexName + ']';
    ;WITH XMLNAMESPACES
       (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
    SELECT
    stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text,
    obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
    obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
    obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
    obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
    obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind,
    cp.plan_handle,
    query_plan
    FROM sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
    CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj)
    OPTION(MAXDOP 1, RECOMPILE);





    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    DECLARE @IndexName AS NVARCHAR(128) = 'IN1_SIAP_GlobalProductID';
    IF (LEFT(@IndexName, 1) <> '[' AND RIGHT(@IndexName, 1) <> ']') SET @IndexName = QUOTENAME(@IndexName);
    --Handle the case where the left or right was quoted manually but not the opposite side
    IF LEFT(@IndexName, 1) <> '[' SET @IndexName = '['+@IndexName;
    IF RIGHT(@IndexName, 1) <> ']' SET @IndexName = @IndexName + ']';
    ;WITH XMLNAMESPACES
       (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT * FROM (
    SELECT
    stmt.value('(@StatementText)[1]', 'varchar(max)') AS SQL_Text,
    obj.value('(@Database)[1]', 'varchar(128)') AS DatabaseName,
    obj.value('(@Schema)[1]', 'varchar(128)') AS SchemaName,
    obj.value('(@Table)[1]', 'varchar(128)') AS TableName,
    obj.value('(@Index)[1]', 'varchar(128)') AS IndexName,
    obj.value('(@IndexKind)[1]', 'varchar(128)') AS IndexKind,
    cp.plan_handle,
    query_plan
    FROM sys.dm_exec_cached_plans AS cp
    CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp
    CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt)
    CROSS APPLY stmt.nodes('.//IndexScan/Object[@Index=sql:variable("@IndexName")]') AS idx(obj)
	) A INNER JOIN sys.dm_exec_query_stats B ON A.plan_handle=B.plan_handle
	where A.databaseName='[SpringCommunications]' and max_logical_reads>200000
	    OPTION(MAXDOP 1, RECOMPILE);