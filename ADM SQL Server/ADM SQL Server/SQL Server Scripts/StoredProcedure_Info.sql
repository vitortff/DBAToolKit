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
        END AS avg_wait_time,wait_time_ms 
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