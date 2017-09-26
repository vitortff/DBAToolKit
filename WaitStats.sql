WITH [Waits] 
     AS (SELECT [wait_type], 
                [wait_time_ms] / 1000.0                             AS [WaitS], 
                ( [wait_time_ms] - [signal_wait_time_ms] ) / 1000.0 AS 
                [ResourceS], 
                [signal_wait_time_ms] / 1000.0                      AS [SignalS] 
                , 
                [waiting_tasks_count] 
                AS [WaitCount], 
                100.0 * [wait_time_ms] / Sum ([wait_time_ms]) 
                                           OVER()                   AS 
                [Percentage], 
                Row_number() 
                  OVER( 
                    ORDER BY [wait_time_ms] DESC)                   AS [RowNum] 
         FROM   sys.dm_os_wait_stats 
         WHERE  [wait_type] NOT IN ( 
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', 
        N'BROKER_TASK_STOP', 
                           N'BROKER_TO_FLUSH', 
                     N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE', 
        N'CHKPT', 
                             N'CLR_AUTO_EVENT', 
                     N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE', 
                     -- Maybe uncomment these four if you have mirroring issues 
                     N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', 
                     N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD', 
                             N'DIRTY_PAGE_POLL', 
        N'DISPATCHER_QUEUE_SEMAPHORE', 
                     N'EXECSYNC', N'FSAGENT', 
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', 
                             N'FT_IFTSHC_MUTEX', 
                     -- Maybe uncomment these six if you have AG issues 
                     N'HADR_CLUSAPI_CALL', 
        N'HADR_FILESTREAM_IOMGR_IOCOMPLETION' 
                             , 
        N'HADR_LOGCAPTURE_WAIT', 
        N'HADR_NOTIFICATION_DEQUEUE', 
                     N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE', 
        N'KSOURCE_WAKEUP', 
                             N'LAZYWRITER_SLEEP' 
                                                , 
                     N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT', 
                             N'ONDEMAND_TASK_QUEUE', 
        N'PREEMPTIVE_XE_GETTARGETSTATE', 
                     N'PWAIT_ALL_COMPONENTS_INITIALIZED', 
                             N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', 
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP' 
        , 
                                                N'QDS_ASYNC_QUEUE', 
                     N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', 
        N'QDS_SHUTDOWN_QUEUE', 
        N'REDO_THREAD_PENDING_WORK', 
        N'REQUEST_FOR_DEADLOCK_SEARCH', 
                     N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', 
        N'SLEEP_BPOOL_FLUSH', 
                                                N'SLEEP_DBSTARTUP', 
                     N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', 
        N'SLEEP_MASTERMDREADY', 
                                                N'SLEEP_MASTERUPGRADED', 
                     N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', 
        N'SLEEP_TASK', 
                                                N'SLEEP_TEMPDBSTARTUP', 
                     N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP', 
        N'SQLTRACE_BUFFER_FLUSH', 
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', 
                     N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS', 
        N'WAITFOR', 
                                                N'WAITFOR_TASKSHUTDOWN', 
                     N'WAIT_XTP_RECOVERY', N'WAIT_XTP_HOST_WAIT', 
        N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', 
                                                N'WAIT_XTP_CKPT_CLOSE', 
                     N'XE_DISPATCHER_JOIN', N'XE_DISPATCHER_WAIT', 
        N'XE_TIMER_EVENT' ) 
                AND [waiting_tasks_count] > 0) 
SELECT Max ([W1].[wait_type]) 
       AS 
       [WaitType], 
       Cast (Max ([W1].[waits]) AS DECIMAL (16, 2)) 
       AS [Wait_S], 
       Cast (Max ([W1].[resources]) AS DECIMAL (16, 2)) 
       AS [Resource_S], 
       Cast (Max ([W1].[signals]) AS DECIMAL (16, 2)) 
       AS [Signal_S], 
       Max ([W1].[waitcount]) 
       AS [WaitCount], 
       Cast (Max ([W1].[percentage]) AS DECIMAL (5, 2)) 
       AS [Percentage], 
       Cast (( Max ([W1].[waits]) / Max ([W1].[waitcount]) ) AS DECIMAL (16, 4)) 
       AS 
       [AvgWait_S], 
       Cast (( Max ([W1].[resources]) / Max ([W1].[waitcount]) ) AS 
             DECIMAL (16, 4)) AS 
       [AvgRes_S], 
       Cast (( Max ([W1].[signals]) / Max ([W1].[waitcount]) ) AS 
             DECIMAL (16, 4))   AS 
       [AvgSig_S], 
       Cast ('https://www.sqlskills.com/help/waits/' 
             + Max ([W1].[wait_type]) AS XML) 
       AS [Help/Info URL] 
FROM   [Waits] AS [W1] 
       INNER JOIN [Waits] AS [W2] 
               ON [W2].[rownum] <= [W1].[rownum] 
GROUP  BY [W1].[rownum] 
HAVING Sum ([W2].[percentage]) - Max([W1].[percentage]) < 95; -- percentage threshold 
----------------------------------------------------------------------------------------------

select plan_handle,
      sum(total_worker_time) as total_worker_time, 
      sum(execution_count) as total_execution_count,
      count(*) as  number_of_statements 
from sys.dm_exec_query_stats
group by plan_handle
order by 
number_of_statements desc
--sum(total_worker_time), sum(execution_count) desc

SELECT * FROM SYS.dm_exec_sql_text(0x05000900B393975840A1B4390E0000000000000000000000)

SELECT  SUM(signal_wait_time_ms) AS TotalSignalWaitTime , 
        ( SUM(CAST(signal_wait_time_ms AS NUMERIC(20, 2))) 
          / SUM(CAST(wait_time_ms AS NUMERIC(20, 2))) * 100 ) 
                         AS PercentageSignalWaitsOfTotalTime 
FROM    sys.dm_os_wait_stats

SELECT TOP ( 10 ) 
        wait_type , 
        waiting_tasks_count , 
        ( wait_time_ms - signal_wait_time_ms ) AS resource_wait_time , 
        max_wait_time_ms , 
        CASE waiting_tasks_count 
          WHEN 0 THEN 0 
          ELSE wait_time_ms / waiting_tasks_count 
        END AS avg_wait_time 
FROM    sys.dm_os_wait_stats 
WHERE   wait_type NOT LIKE '%SLEEP%'   -- remove eg. SLEEP_TASK and 
                                       -- LAZYWRITER_SLEEP waits 
        AND wait_type NOT LIKE 'XE%' 
        AND wait_type NOT IN -- remove system waits    
( 'KSOURCE_WAKEUP', 'BROKER_TASK_STOP', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 
  'SQLTRACE_BUFFER_FLUSH', 'CLR_AUTO_EVENT', 'BROKER_EVENTHANDLER', 
  'BAD_PAGE_PROCESS', 'BROKER_TRANSMITTER', 'CHECKPOINT_QUEUE', 
  'DBMIRROR_EVENTS_QUEUE', 'SQLTRACE_BUFFER_FLUSH', 'CLR_MANUAL_EVENT', 
  'ONDEMAND_TASK_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'LOGMGR_QUEUE', 
  'BROKER_RECEIVE_WAITFOR', 'PREEMPTIVE_OS_GETPROCADDRESS', 
  'PREEMPTIVE_OS_AUTHENTICATIONOPS', 'BROKER_TO_FLUSH' ) 
ORDER BY wait_time_ms DESC 

SELECT TOP ( 10 ) 
        SUBSTRING(ST.text, ( QS.statement_start_offset / 2 ) + 1, 
                  ( ( CASE statement_end_offset 
                        WHEN -1 THEN DATALENGTH(st.text) 
                        ELSE QS.statement_end_offset 
                      END - QS.statement_start_offset ) / 2 ) + 1) 
                 AS statement_text , 
                         execution_count , 
        total_worker_time / 1000 AS total_worker_time_ms , 
        ( total_worker_time / 1000 ) / execution_count 
                 AS avg_worker_time_ms , 
        total_logical_reads , 
        total_logical_reads / execution_count AS avg_logical_reads , 
        total_elapsed_time / 1000 AS total_elapsed_time_ms , 
        ( total_elapsed_time / 1000 ) / execution_count 
                 AS avg_elapsed_time_ms , 
        qp.query_plan 
FROM    sys.dm_exec_query_stats qs 
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st 
        CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp 
ORDER BY total_worker_time DESC