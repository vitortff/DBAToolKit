DECLARE @ts_now bigint
 
SELECT @ts_now = cpu_ticks / (cpu_ticks/ms_ticks)  FROM sys.dm_os_sys_info
SELECT top 20 record_id, EventTime,
CASE WHEN system_cpu_utilization_post_sp2 IS NOT NULL THEN system_cpu_utilization_post_sp2 ELSE system_cpu_utilization_pre_sp2 END AS system_cpu_utilization,
CASE WHEN sql_cpu_utilization_post_sp2 IS NOT NULL THEN sql_cpu_utilization_post_sp2 ELSE sql_cpu_utilization_pre_sp2 END AS sql_cpu_utilization
FROM
(
SELECT
record.value('(Record/@id)[1]', 'int') AS record_id,
DATEADD (ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS EventTime,
100-record.value('(Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS system_cpu_utilization_post_sp2,
record.value('(Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS sql_cpu_utilization_post_sp2 ,
100-record.value('(Record/SchedluerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS system_cpu_utilization_pre_sp2,
record.value('(Record/SchedluerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS sql_cpu_utilization_pre_sp2
FROM (
SELECT timestamp, CONVERT (xml, record) AS record
FROM sys.dm_os_ring_buffers
WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
AND record LIKE '%SystemHealth%') AS t
) AS t
ORDER BY record_id desc