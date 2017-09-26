USE msdb
Go


SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE active_start_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),active_start_date),1,4) + '/' + 
		substring(convert(varchar(15),active_start_date),5,2) + '/' + 
		substring(convert(varchar(15),active_start_date),7,2)
	END,
	'Start Time' = CASE len(active_start_time)
		WHEN 1 THEN cast('00:00:0' + right(active_start_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(active_start_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(active_start_time,3),1)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(active_start_time,5),1) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(active_start_time,6),2) 
				+':' + Left(right(active_start_time,4),2)  
				+':' + right(active_start_time,2) as char (8))
	END,
--	active_start_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules 
ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time = 0

UNION

SELECT dbo.sysjobs.Name AS 'Job Name', 
	'Job Enabled' = CASE dbo.sysjobs.Enabled
		WHEN 1 THEN 'Yes'
		WHEN 0 THEN 'No'
	END,
	'Frequency' = CASE dbo.sysschedules.freq_type
		WHEN 1 THEN 'Once'
		WHEN 4 THEN 'Daily'
		WHEN 8 THEN 'Weekly'
		WHEN 16 THEN 'Monthly'
		WHEN 32 THEN 'Monthly relative'
		WHEN 64 THEN 'When SQLServer Agent starts'
	END, 
	'Start Date' = CASE next_run_date
		WHEN 0 THEN null
		ELSE
		substring(convert(varchar(15),next_run_date),1,4) + '/' + 
		substring(convert(varchar(15),next_run_date),5,2) + '/' + 
		substring(convert(varchar(15),next_run_date),7,2)
	END,
	'Start Time' = CASE len(next_run_time)
		WHEN 1 THEN cast('00:00:0' + right(next_run_time,2) as char(8))
		WHEN 2 THEN cast('00:00:' + right(next_run_time,2) as char(8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(next_run_time,3),1)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 5 THEN cast('0' + Left(right(next_run_time,5),1) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
		WHEN 6 THEN cast(Left(right(next_run_time,6),2) 
				+':' + Left(right(next_run_time,4),2)  
				+':' + right(next_run_time,2) as char (8))
	END,
--	next_run_time as 'Start Time',
	CASE len(run_duration)
		WHEN 1 THEN cast('00:00:0'
				+ cast(run_duration as char) as char (8))
		WHEN 2 THEN cast('00:00:'
				+ cast(run_duration as char) as char (8))
		WHEN 3 THEN cast('00:0' 
				+ Left(right(run_duration,3),1)  
				+':' + right(run_duration,2) as char (8))
		WHEN 4 THEN cast('00:' 
				+ Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 5 THEN cast('0' 
				+ Left(right(run_duration,5),1) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
		WHEN 6 THEN cast(Left(right(run_duration,6),2) 
				+':' + Left(right(run_duration,4),2)  
				+':' + right(run_duration,2) as char (8))
	END as 'Max Duration',
    CASE(dbo.sysschedules.freq_subday_interval)
		WHEN 0 THEN 'Once'
		ELSE cast('Every ' 
				+ right(dbo.sysschedules.freq_subday_interval,2) 
				+ ' '
				+     CASE(dbo.sysschedules.freq_subday_type)
							WHEN 1 THEN 'Once'
							WHEN 4 THEN 'Minutes'
							WHEN 8 THEN 'Hours'
						END as char(16))
    END as 'Subday Frequency'
FROM dbo.sysjobs 
LEFT OUTER JOIN dbo.sysjobschedules ON dbo.sysjobs.job_id = dbo.sysjobschedules.job_id
INNER JOIN dbo.sysschedules ON dbo.sysjobschedules.schedule_id = dbo.sysschedules.schedule_id 
LEFT OUTER JOIN (SELECT job_id, max(run_duration) AS run_duration
		FROM dbo.sysjobhistory
		GROUP BY job_id) Q1
ON dbo.sysjobs.job_id = Q1.job_id
WHERE Next_run_time <> 0

ORDER BY [Start Date],[Start Time]
