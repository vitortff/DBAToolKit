 
USE MASTER
GO
 
 
DECLARE @DML1 nvarchar(MAX),
@DML2 nvarchar(MAX),
@DML3 nvarchar(MAX),
@DML4 nvarchar(MAX)
 
DECLARE @SQLShackIOStatistics TABLE
(
[I/ORank] [int] NULL,
[DBName] [nvarchar](128) NULL,
[driveLetter] [nvarchar](1) NULL,
[totalNumOfWrites] [bigint] NULL,
[totalNumOfBytesWritten] [bigint] NULL,
[totalNumOfReads] [bigint] NULL,
totalNumOfBytesRead [bigint] NULL,
[totalI/O(MB)] [decimal](12,2) NULL,
[I/O(%)] [decimal](5, 2) NULL,
[SizeOfFile] [decimal](10,2) NULL
)
SET @DML1='
WITH SQLShackIOStatistics
AS
(
select 
db_name(mf.database_id) as dbname, 
left(mf.physical_name, 1) as driveLetter, 
sum(vfs.num_of_writes) [totalNumOfWrites],
sum(vfs.num_of_bytes_written) [totalNumOfBytesWritten],
sum(vfs.num_of_reads) [totalNumOfReads], 
sum(vfs.num_of_bytes_read) [totalNumOfBytesRead], 
cast(SUM(num_of_bytes_read + num_of_bytes_written)/1024 AS DECIMAL(12, 2)) AS [TotIO(MB)],
MAX(cast(vfs.size_on_disk_bytes/1024/1024.00 as decimal(10,2))) SizeMB
from sys.master_files mf
join sys.dm_io_virtual_file_stats(NULL, NULL) vfs
on mf.database_id=vfs.database_id and mf.file_id=vfs.file_id
GROUP BY mf.database_id,left(mf.physical_name, 1))
SELECT 
	ROW_NUMBER() OVER(ORDER BY [TotIO(MB)] DESC) AS [I/ORank],
	[dbname],
	driveLetter,
	[totalNumOfWrites],
	totalNumOfBytesWritten,
	totalNumOfReads,
	totalNumOfBytesRead,
	[TotIO(MB)] AS [I/O(MB)],
	CAST([TotIO(MB)]/ SUM([TotIO(MB)]) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O(%)],
	SizeMB
	FROM SQLShackIOStatistics
	ORDER BY [I/ORank]
OPTION (RECOMPILE)
'
INSERT INTO @SQLShackIOStatistics
EXEC sp_executesql @DML1
 
 
--SQL 2017 
 
--select [Database Name],
--STRING_AGG( [I/O Rank],',')  [I/O Rank],
--STRING_AGG(physicalName,',') physicalName,
--STRING_AGG(total_num_of_writes,',') total_num_of_writes,
--STRING_AGG(total_num_of_bytes_written,',') total_num_of_bytes_written,
--STRING_AGG(total_num_of_reads,',') total_num_of_reads,
--STRING_AGG([Total I/O (MB)],',') [Total I/O (MB)],
--STRING_AGG([I/O Percent],',') WITHIN GROUP (ORDER BY [Database Name] ASC) [I/O Percent]
--from @Aggregate_IO_Statistics
--group by [Database Name]
 
 
 
 
SELECT * FROM @SQLShackIOStatistics
 
--User Connections
 
DECLARE @SQLShackUserConn TABLE
(
DBName [nvarchar](128) NULL,
No_Of_Connections [int] NULL
)
 
SET @DML2='
SELECT DB_NAME(dbid) DBName,COUNT(*) No_Of_Connections FROM sys.sysprocesses --where kpid>0
group by DB_NAME(dbid)
ORDER BY DB_NAME(dbid) DESC OPTION (RECOMPILE)
'
 
INSERT INTO @SQLShackUserConn
EXEC sp_executesql @DML2
 
select * from @SQLShackUserConn
 
--Memory
 
DECLARE @SQLShackCacheMemory TABLE(
[Database_Name] [nvarchar](128) NULL,
BufferPageCnt int,
BufferSizeMB [decimal](10, 2) NULL,
PageStatus varchar(10)
)
 
 
SET @DML3='SELECT DBName = CASE WHEN database_id = 32767 THEN ''RESOURCEDB''
				ELSE DB_NAME(database_id) END,
	Bufferpage=count_BIG(*),
	BufferSizeMB = COUNT(1)/128,
	PageStatus = max(CASE WHEN is_modified = 1 THEN ''Dirty'' 
				ELSE ''Clean'' END)
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY 2 DESC'
 
INSERT INTO @SQLShackCacheMemory
EXEC sp_executesql @DML3
 
SELECT * FROM @SQLShackCacheMemory
 
--SELECT * FROM @CacheMemoryDB
 
--CPU
 
DECLARE @SQLShackCPUStats TABLE (
[row_num] [bigint] NULL,
[DatabaseName] [nvarchar](128) NULL,
[CPU_Time_Ms] [bigint] NULL,
[CPUPercent] [decimal](5, 2) NULL,
[RowsReturned] bigint,
ExecutionCount bigint
)
 
SET @DML4='WITH DBCPUStats
AS
(SELECT DatabaseID, DB_Name(DatabaseID) AS [DatabaseName], SUM(total_worker_time) AS [CPU_Time_Ms],  SUM(execution_count)  AS [ExecutionCount],
SUM(total_rows)  AS [RowsReturned]
FROM sys.dm_exec_query_stats AS qs WITH (NOLOCK)
CROSS APPLY (SELECT CONVERT(int, value) AS [DatabaseID]
FROM sys.dm_exec_plan_attributes(qs.plan_handle)
WHERE attribute = N''dbid'') AS F_DB
GROUP BY DatabaseID)
SELECT ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
DatabaseName, [CPU_Time_Ms],
CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent],
[RowsReturned],
[ExecutionCount]
FROM DBCPUStats
WHERE DatabaseID > 4 -- system databases
AND DatabaseID <> 32767 -- ResourceDB
ORDER BY row_num OPTION (RECOMPILE)'
 
--How many Virtual Log Files or VLFs are present in your log file.
INSERT INTO @SQLShackCPUStats
EXEC sp_executesql @DML4
 
 
SELECT * FROM @SQLShackCPUStats
 
 
--VLF
 
CREATE TABLE #VLFInfo(
	  [RecoveryUnitId] int NULL,
      [FileId] [tinyint] NULL,
      [FileSize] [bigint] NULL,
      [StartOffset] [bigint] NULL,
      [FSeqNo] [int] NULL,
      [Status] [tinyint] NULL,
      [Parity] [tinyint] NULL,
      [CreateLSN] [numeric](25, 0) NULL
) ON [PRIMARY]
 
CREATE TABLE #VLFCountResults(databasename sysname,fileid int, Free int, InUse int, VLFCount int)
 
EXEC sp_MSforeachdb N'Use [?];
INSERT INTO #VLFInfo
EXEC sp_executesql N''DBCC LOGINFO([?])''
;with vlfUse as
(
select max(db_name()) databasename,fileid,
sum(case when status = 0 then 1 else 0 end) as Free,
sum(case when status != 0 then 1 else 0 end) as InUse,
count(*) cnt
from #VLFInfo
group by fileid
)
INSERT INTO #VLFCountResults
select *  from vlfUse
TRUNCATE TABLE #VLFInfo
'
-- SQL 2017
 
--;WITH DatbaseVLF AS(
--SELECT 
--DB_ID(dbs.[name]) AS DatabaseID,
--dbs.[name] AS dbName, 
--CONVERT(DECIMAL(18,2), p2.cntr_value/1024.0) AS [Log Size (MB)],
--CONVERT(DECIMAL(18,2), p1.cntr_value/1024.0) AS [Log Size Used (MB)]
--FROM sys.databases AS dbs WITH (NOLOCK)
--INNER JOIN sys.dm_os_performance_counters AS p1  WITH (NOLOCK) ON dbs.name = p1.instance_name
--INNER JOIN sys.dm_os_performance_counters AS p2 WITH (NOLOCK) ON dbs.name = p2.instance_name
--WHERE p1.counter_name LIKE N'Log File(s) Used Size (KB)%' 
--AND p2.counter_name LIKE N'Log File(s) Size (KB)%'
--AND p2.cntr_value > 0 
--)
--SELECT	[dbName],
--		[Log Size (MB)], 
--		[Log Size Used (MB)], 
--		[Log Size (MB)]-[Log Size Used (MB)] [Log Free (MB)], 
--		cast([Log Size Used (MB)]/[Log Size (MB)]*100 as decimal(10,2)) [Log Space Used %],
--		COUNT(b.database_id) AS [Number of VLFs] ,
--		sum(case when b.vlf_status = 0 then 1 else 0 end) as Free,
--		sum(case when b.vlf_status != 0 then 1 else 0 end) as InUse		
--FROM DatbaseVLF AS vlf  
--CROSS APPLY sys.dm_db_log_info(vlf.DatabaseID) b
--GROUP BY dbName, [Log Size (MB)],[Log Size Used (MB)]
 
--select * from #VLFCountResults
 
;WITH DatbaseVLF AS(
SELECT 
DB_ID(dbs.[name]) AS DatabaseID,
dbs.[name] AS dbName, 
CONVERT(DECIMAL(18,2), p2.cntr_value/1024.0) AS [Log Size (MB)],
CONVERT(DECIMAL(18,2), p1.cntr_value/1024.0) AS [Log Size Used (MB)]
FROM sys.databases AS dbs WITH (NOLOCK)
INNER JOIN sys.dm_os_performance_counters AS p1  WITH (NOLOCK) ON dbs.name = p1.instance_name
INNER JOIN sys.dm_os_performance_counters AS p2 WITH (NOLOCK) ON dbs.name = p2.instance_name
WHERE p1.counter_name LIKE N'Log File(s) Used Size (KB)%' 
AND p2.counter_name LIKE N'Log File(s) Size (KB)%'
AND p2.cntr_value > 0 
)
SELECT
		db.Servername,
		cs.DatabaseName DatabaseName,
		db.Status,
		db.DataFiles [DataFile(s)],
		db.[Data MB],
		db.LogFiles [LogFile(s)],
		db.[Log MB],
		db.TotalSizeMB [DatabaseSize (MB)],
		db.RecoveryModel,
		db.Version,
		isnull(cs.CPU_Time_Ms,0) CPUTimeMs,
		isnull(cs.CPUPercent,0) [CPU (%)],
		cs.RowsReturned,
		cs.ExecutionCount,
		isnull(cm.BufferSizeMB ,0) BufferSizeMB,
		cm.BufferPageCnt ,
		cm.PageStatus,
		isnull(uc.No_Of_connections,0) NumberOfConnections,
		AIS.physicalName,
		AIS.total_num_of_writes,
		AIS.total_num_of_bytes_written,
		AIS.total_num_of_reads,
		AIS.[Total I/O (MB)],
		AIS.[I/O Percent],
		VR.[Log Size (MB)], 
		VR.[Log Size Used (MB)], 
		VR.[Log Free (MB)], 
		VR.[Log Space Used %],
		VR.[Number of VLFs]  VirtualLogCnt,
		VR.Free,
		VR.InUse
FROM @SQLShackCPUStats cs
left join @SQLShackCacheMemory CM on cm.Database_Name=cs.DatabaseName
left join @SQLShackUserConn uc on uc.dbname=cs.DatabaseName
left join 
(
SELECT	[dbName],
		[Log Size (MB)], 
		[Log Size Used (MB)], 
		[Log Size (MB)]-[Log Size Used (MB)] [Log Free (MB)], 
		cast([Log Size Used (MB)]/[Log Size (MB)]*100 as decimal(10,2)) [Log Space Used %],
		max(VLFCount) AS [Number of VLFs] ,
		max(Free) Free,
		Max(InUse) InUse
FROM DatbaseVLF AS vlf  
INNER JOIN #VLFCountResults b on vlf.dbName=b.databasename
GROUP BY dbName, [Log Size (MB)],[Log Size Used (MB)]
)
VR on VR.[dbName]=cs.DatabaseName
left join (
 
 
select [DBName],
[I/O Rank] = 
   STUFF(
(SELECT ',' + cast(s.[I/ORank] as varchar(3))
FROM @SQLShackIOStatistics s
WHERE s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
physicalName=STUFF(
(SELECT ',' + s.driveLetter
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,'') ,
FileSizeMB=STUFF(
(SELECT ',' + cast(s.SizeOfFile as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,'') ,
total_num_of_writes=STUFF(
(SELECT ',' + cast(s.[totalNumOfWrites] as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
total_num_of_bytes_written=STUFF(
(SELECT ',' + cast(s.[totalNumOfBytesWritten] as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
total_num_of_reads=STUFF(
(SELECT ',' + cast(s.totalnumofreads as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
total_num_of_Bytes_reads=STUFF(
(SELECT ',' + cast(s.totalNumOfBytesRead as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
[Total I/O (MB)]=STUFF(
(SELECT ',' + cast(s.[TotalI/O(MB)] as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,''),
[I/O Percent]=STUFF(
(SELECT ',' + cast(s.[I/O(%)] as varchar(20))
FROM @SQLShackIOStatistics s
WHERE  s.[DBName] = t.[DBName]
FOR XML PATH('')),1,1,'')
from @SQLShackIOStatistics t
group by [DBName]
)AIS on AIS.DBName=cs.DatabaseName
inner join
(
SELECT @@SERVERNAME Servername,
CONVERT(VARCHAR(25), DB.name) AS dbName,
CONVERT(VARCHAR(10), DATABASEPROPERTYEX(name, 'status')) AS [Status],
(SELECT COUNT(1) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid !=0 ) AS DataFiles,
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid!=0) AS [Data MB],
(SELECT COUNT(1) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) AS LogFiles,
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) AS [Log MB],
(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid!=0)+(SELECT SUM((size*8)/1024) FROM sysaltfiles WHERE DB_NAME(dbid) = DB.name AND groupid=0) TotalSizeMB,
convert(sysname,DatabasePropertyEx(name,'Recovery')) RecoveryModel ,
convert(sysname,DatabasePropertyEx(name,'Version')) Version 
FROM sys.databases DB
) DB on DB.dbName=cs.DatabaseName
--order by io.[I/O Percent],cs.CPUPercent,cm.[Cached Size (MB)]desc
 
 
 
DROP TABLE #VLFInfo;
DROP TABLE #VLFCountResults;
-------------------------------------------


