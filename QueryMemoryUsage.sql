/**********************************************************
*   top procedures memory consumption per execution
*   (this will show mostly reports &amp; jobs)
***********************************************************/
SELECT TOP 100 *
FROM
(
    SELECT
         DatabaseName       = DB_NAME(qt.dbid)
        ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
        ,DiskReads          = SUM(qs.total_physical_reads)   -- The worst reads, disk reads
        ,MemoryReads        = SUM(qs.total_logical_reads)    --Logical Reads are memory reads
        ,Executions         = SUM(qs.execution_count)
        ,IO_Per_Execution   = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
        ,CPUTime            = SUM(qs.total_worker_time)
        ,DiskWaitAndCPUTime = SUM(qs.total_elapsed_time)
        ,MemoryWrites       = SUM(qs.max_logical_writes)
        ,DateLastExecuted   = MAX(qs.last_execution_time)
       
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    GROUP BY DB_NAME(qt.dbid), OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)

) T
ORDER BY IO_Per_Execution DESC

/**********************************************************
*   top procedures memory consumption total
*   (this will show more operational procedures)
***********************************************************/
SELECT TOP 100 *
FROM
(
    SELECT
         DatabaseName       = DB_NAME(qt.dbid)
        ,ObjectName         = OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
        ,DiskReads          = SUM(qs.total_physical_reads)   -- The worst reads, disk reads
        ,MemoryReads        = SUM(qs.total_logical_reads)    --Logical Reads are memory reads
        ,Total_IO_Reads     = SUM(qs.total_physical_reads + qs.total_logical_reads)
        ,Executions         = SUM(qs.execution_count)
        ,IO_Per_Execution   = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
        ,CPUTime            = SUM(qs.total_worker_time)
        ,DiskWaitAndCPUTime = SUM(qs.total_elapsed_time)
        ,MemoryWrites       = SUM(qs.max_logical_writes)
        ,DateLastExecuted   = MAX(qs.last_execution_time)
       
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    GROUP BY DB_NAME(qt.dbid), OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY Total_IO_Reads DESC



/**********************************************************
*   top adhoc queries memory consumption total
***********************************************************/
SELECT TOP 100 *
FROM
(
    SELECT
         DatabaseName       = DB_NAME(qt.dbid)
        ,QueryText          = qt.text      
        ,DiskReads          = SUM(qs.total_physical_reads)   -- The worst reads, disk reads
        ,MemoryReads        = SUM(qs.total_logical_reads)    --Logical Reads are memory reads
        ,Total_IO_Reads     = SUM(qs.total_physical_reads + qs.total_logical_reads)
        ,Executions         = SUM(qs.execution_count)
        ,IO_Per_Execution   = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
        ,CPUTime            = SUM(qs.total_worker_time)
        ,DiskWaitAndCPUTime = SUM(qs.total_elapsed_time)
        ,MemoryWrites       = SUM(qs.max_logical_writes)
        ,DateLastExecuted   = MAX(qs.last_execution_time)
       
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    WHERE OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) IS NULL
    GROUP BY DB_NAME(qt.dbid), qt.text, OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY Total_IO_Reads DESC


/**********************************************************
*   top adhoc queries memory consumption per execution
***********************************************************/
SELECT TOP 100 *
FROM
(
    SELECT
         DatabaseName       = DB_NAME(qt.dbid)
        ,QueryText          = qt.text      
        ,DiskReads          = SUM(qs.total_physical_reads)   -- The worst reads, disk reads
        ,MemoryReads        = SUM(qs.total_logical_reads)    --Logical Reads are memory reads
        ,Total_IO_Reads     = SUM(qs.total_physical_reads + qs.total_logical_reads)
        ,Executions         = SUM(qs.execution_count)
        ,IO_Per_Execution   = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
        ,CPUTime            = SUM(qs.total_worker_time)
        ,DiskWaitAndCPUTime = SUM(qs.total_elapsed_time)
        ,MemoryWrites       = SUM(qs.max_logical_writes)
        ,DateLastExecuted   = MAX(qs.last_execution_time)
       
    FROM sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
    WHERE OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid) IS NULL
    GROUP BY DB_NAME(qt.dbid), qt.text, OBJECT_SCHEMA_NAME(qt.objectid,dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
) T
ORDER BY IO_Per_Execution DESC


/*************************************************************
*Extract information about the condition of OS memory and SQL memory
**************************************************************/
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as [Notification_Time],
cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type],
cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %],
cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [Process_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [System_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB],
cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB],
cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory],
cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory],
cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory],
cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB],
cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB],
cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB],
cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
FROM sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
where rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
ORDER BY rbf.timestamp ASC

/*************************************************************
*Check the health of SQL Server including SQL Server working set
**************************************************************/
SELECT  CONVERT (varchar(30), GETDATE(), 121) as runtime, DATEADD (ms, a.[Record Time] - sys.ms_ticks, GETDATE()) AS Notification_time,    a.* , sys.ms_ticks AS [Current Time]
FROM   (SELECT x.value('(//Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS [ProcessUtilization],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS [SystemIdle %],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/UserModeTime) [1]', 'bigint') AS [UserModeTime],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime) [1]', 'bigint') AS [KernelModeTime],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/PageFaults) [1]', 'bigint') AS [PageFaults],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta) [1]', 'bigint')/1024 AS [WorkingSetDelta],
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization) [1]', 'bigint') AS [MemoryUtilization (%workingset)],
x.value('(//Record/@time)[1]', 'bigint') AS [Record Time]  FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR') AS R(x)) a  CROSS JOIN sys.dm_os_sys_info sys ORDER BY DATEADD (ms, a.[Record Time] - sys.ms_ticks, GETDATE())