--Informações mais detalhadas sobre os jobs existentes
--na Instância de SQL
SELECT 
	SJ.name as job_name, 
	SJ.enabled as is_job_enabled,
	SS.enabled as is_schedule_enabled,
	SS.name as schedule_name, 
CASE freq_type
WHEN 1 THEN 'Occurs on ' + STUFF(RIGHT(active_start_date, 4), 3,0, '/') + '/' + LEFT(active_start_date, 4) + ' at '
+ REPLACE( RIGHT(CONVERT(varchar(30),
CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime) /* hh:mm:ss 24H */
, 9), 14), ':000', ' ') /* HH:mm:ss:000AM/PM then replace the :000 with space.*/
WHEN 4 THEN 'Occurs every ' + CAST(freq_interval as varchar(10))
+ ' day(s) '
+ CASE freq_subday_type
WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
ELSE '' END
+ CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
+ ' and '
+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
ELSE ''
END
WHEN 8 THEN
'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
+ ' week(s) on '
+
REPLACE( CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
+ CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
+ CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
+ CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
+ CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
+ CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
+ CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
+ '|', ', |', ' ') /* get rid of trailing comma */

+ CASE freq_subday_type
WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
ELSE '' END
+ CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
+ ' and '
+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
ELSE ''
END
WHEN 16 THEN
'Occurs every ' + CAST(freq_recurrence_factor as varchar(10))
+ ' month(s) on '
+ 'day ' + CAST(freq_interval as varchar(10)) + ' of that month ' 
+ CASE freq_subday_type
WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
ELSE '' END
+ CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
+ ' and '
+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
ELSE ''
END
WHEN 32 THEN
'Occurs ' +
CASE freq_relative_interval
WHEN 1 THEN 'every first '
WHEN 2 THEN 'every second '
WHEN 4 THEN 'every third '
WHEN 8 THEN 'every fourth '
WHEN 16 THEN 'on the last '
END
+ CASE freq_interval WHEN 1 THEN 'Sunday'
WHEN 2 THEN 'Monday'
WHEN 3 THEN 'Tuesday'
WHEN 4 THEN 'Wednesday'
WHEN 5 THEN 'Thursday'
WHEN 6 THEN 'Friday'
WHEN 7 THEN 'Saturday'
WHEN 8 THEN 'day'
WHEN 9 THEN 'weekday'
WHEN 10 THEN 'weekend'
END

+ ' of every ' + CAST(freq_recurrence_factor as varchar(10)) + ' month(s) '
+ CASE freq_subday_type
WHEN 1 THEN 'at '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
WHEN 2 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' second(s)'
WHEN 4 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' minute(s)'
WHEN 8 THEN 'every ' + CAST(freq_subday_interval as varchar(10)) + ' hour(s)'
ELSE '' END
+ CASE WHEN freq_subday_type in (2,4,8) /* repeat seconds/mins/hours */
THEN ' between '+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
+ ' and '
+ LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' '))
ELSE ''
END
WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
WHEN 128 THEN 'Runs when the computer is idle'

END as [Description]
, CASE freq_type
WHEN 1 THEN 'One Time'
WHEN 4 THEN CASE freq_subday_type WHEN 1 THEN 'Daily'
WHEN 2 THEN 'Second-ly'
WHEN 4 THEN 'Minutely'
WHEN 8 THEN 'Hourly'
ELSE ''
END
WHEN 8 THEN 'Weekly'
WHEN 16 THEN 'Monthly'
WHEN 32 THEN 'Monthly, relative to freq_interval'
WHEN 64 THEN 'Runs when the SQL Server Agent service starts'
WHEN 128 THEN 'Runs when the computer is idle'
END As [Freq_Type]
, CASE freq_subday_type
WHEN 1 THEN 'At the specified time'
WHEN 2 THEN 'Every ' + CAST(freq_subday_interval as varchar(10)) + ' Second(s)'
WHEN 4 THEN 'Every ' + CAST(freq_subday_interval as varchar(10)) + ' Minute(s)'
WHEN 8 THEN 'Every ' + CAST(freq_subday_interval as varchar(10)) + ' Hour(s)'
ELSE ''
END AS freq_subday_type

, CASE
WHEN freq_type = 4 /* (daily) */ THEN 'Every ' + CAST(freq_interval as varchar(10)) + ' Day(s)'
WHEN freq_type = 8 /* (weekly) */ THEN 
REPLACE( CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
+ CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
+ CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
+ CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
+ CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
+ CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
+ CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
+ '|', ', |', ' ') /* get rid of trailing comma */
WHEN freq_type = 16 THEN 'On Day ' + CAST(freq_interval as varchar(10)) + ' of Every Month'
WHEN freq_type = 32 /* (monthly) */ THEN 'Every ' +
CASE freq_interval WHEN 1 THEN 'Sunday'
WHEN 2 THEN 'Monday'
WHEN 3 THEN 'Tuesday'
WHEN 4 THEN 'Wednesday'
WHEN 5 THEN 'Thursday'
WHEN 6 THEN 'Friday'
WHEN 7 THEN 'Saturday'
WHEN 8 THEN 'Day'
WHEN 9 THEN 'Weekday'
WHEN 10 THEN 'Weekend day'
END
ELSE ''
END as [freq_interval]
, CASE WHEN freq_type = 8 /* (weekly) */ THEN 'Every ' + CAST(freq_recurrence_factor as varchar(10)) + ' Week(s)'
WHEN freq_type = 16 /* (monthly) */ THEN 'Every ' + CAST(freq_recurrence_factor as varchar(10)) + ' Month(s)'
WHEN freq_type = 32 /* (monthly relative) */ THEN 'Every ' + CAST(freq_recurrence_factor as varchar(10)) + ' Week(s)'
ELSE ''
END as freq_recurrence_factor
, LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_start_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' ')) as starttime
, LTRIM(REPLACE( RIGHT(CONVERT(varchar(30), CAST(convert(varchar(8), STUFF(STUFF(RIGHT('000000' + CAST(active_end_time as varchar(10)), 6), 3, 0, ':' ), 6, 0, ':' ), 8) as datetime), 9), 14), ':000', ' ')) as endtime
, STUFF(STUFF(active_start_date, 5, 0, '/'), 8, 0, '/') as schedule_start_date
, STUFF(STUFF(active_end_date, 5, 0, '/'), 8, 0, '/') as schedule_end_date
FROM 
	msdb.dbo.sysjobs SJ
INNER JOIN 
	msdb.dbo.sysjobschedules SJS
ON 
	SJ.job_id = SJS.job_id
INNER JOIN 
	msdb.dbo.sysschedules SS
ON 
	SJS.schedule_id = SS.schedule_id


