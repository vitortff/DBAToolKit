Select * FROM msdb.dbo.sysjobservers                sjh  

select DISTINCT job_name, run_duration
from
(
    select job_name, run_datetime,
        SUBSTRING(run_duration, 1, 2) + ':' + SUBSTRING(run_duration, 3, 2) + ':' +
        SUBSTRING(run_duration, 5, 2) AS run_duration
    from
    (
        select DISTINCT
            j.name as job_name, 
            run_datetime = CONVERT(DATETIME, RTRIM(run_date)) +  
                (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4,
            run_duration = RIGHT('000000' + CONVERT(varchar(6), run_duration), 6)
        from msdb..sysjobhistory h
        inner join msdb..sysjobs j
        on h.job_id = j.job_id
    ) t
) t
--order by job_name, run_datetime

SELECT dbo.sysjobs.name, CAST(dbo.sysschedules.active_start_time / 10000 AS VARCHAR(10))  
+ ':' + RIGHT('00' + CAST(dbo.sysschedules.active_start_time % 10000 / 100 AS VARCHAR(10)), 2) AS active_start_time,  
dbo.udf_schedule_description(dbo.sysschedules.freq_type, 
dbo.sysschedules.freq_interval, 
dbo.sysschedules.freq_subday_type, 
dbo.sysschedules.freq_subday_interval, 
dbo.sysschedules.freq_relative_interval, 
dbo.sysschedules.freq_recurrence_factor, 
dbo.sysschedules.active_start_date, 
dbo.sysschedules.active_end_date, 
dbo.sysschedules.active_start_time, 
dbo.sysschedules.active_end_time) AS ScheduleDscr, dbo.sysjobs.enabled 
FROM dbo.sysjobs INNER JOIN 
dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id INNER JOIN 
dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id  
ORDER BY name ASC

exec msdb.dbo.sp_help_jobhistory
	@job_id = 'f3d2fa78-891a-45e3-a056-1c60f68a648d',
	@mode='FULL' 
		