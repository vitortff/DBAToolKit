USE master 
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_WhoIsActive')
	EXEC ('CREATE PROC dbo.sp_WhoIsActive AS SELECT ''stub version, to be replaced''')
GO

/*********************************************************************************************
Who Is Active? v10.00 (2010-10-21)
(C) 2007-2010, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx
"Beta" Builds: http://sqlblog.com/files/folders/beta/tags/who+is+active/default.aspx

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
ALTER PROC dbo.sp_WhoIsActive
(
--~
	--Filters--Both inclusive and exclusive
	--Set either filter to '' to disable
	--Valid filter types are: session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used to indicate "all" sessions
	--All other filter types support % or _ as wildcards
	@filter sysname = '',
	@filter_type VARCHAR(10) = 'session',
	@not_filter sysname = '',
	@not_filter_type VARCHAR(10) = 'session',

	--Retrieve data about the calling session?
	@show_own_spid BIT = 0,

	--Retrieve data about system sessions?
	@show_system_spids BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@show_sleeping_spids TINYINT = 1,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Get information on active tasks, based on three interest levels
	--Level 0 does not pull any task-related information
	--Level 1 is a lightweight mode that pulls the top non-CXPACKET wait, giving preference to blockers
	--Level 2 pulls all available task-based metrics, including: 
	--number of active tasks, current wait stats, physical I/O, context switches, and blocker information
	@get_task_info TINYINT = 1,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Get additional non-performance-related information about the session or request
	--text_size, language, date_format, date_first, quoted_identifier, arithabort, ansi_null_dflt_on, 
	--ansi_defaults, ansi_warnings, ansi_padding, ansi_nulls, concat_null_yields_null, 
	--transaction_isolation_level, lock_timeout, deadlock_priority, row_count, original_login_name
	@get_additional_info BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	--Also enables task_info Level 1, if @get_task_info is set to 0
	@find_block_leaders BIT = 0,

	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',

	--Column(s) by which to sort output, optionally with sort directions. 
		--Valid column choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_allocations,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_allocations_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--tasks, tran_start_time, open_tran_count, blocking_session_id, blocked_session_count,
		--percent_complete, host_name, login_name, database_name, start_time
		--
		--Note that column names in the list must be bracket-delimited. Commas and/or white
		--space are not required. 
	@sort_order VARCHAR(500) = '[start_time] ASC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables outfput format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,

	--Help! What do I do?
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time the session has been connected

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NOT NULL
Non-Formatted:	[reads] [bigint] NOT NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NOT NULL
Non-Formatted:	[physical_reads] [bigint] NOT NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NOT NULL
Non-Formatted:	[writes] [bigint] NOT NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_allocations] [varchar](30) NOT NULL
Non-Formatted:	[tempdb_allocations] [bigint] NOT NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NOT NULL
Non-Formatted:	[tempdb_current] [bigint] NOT NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NOT NULL
Non-Formatted:	[CPU] [int] NOT NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_allocations_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)

Formatted/Non:	[wait_info] [nvarchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	If wait type E is CXPACKET, the nodeId from the query plan will be identified

Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [nvarchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:wB (C kB)
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	C is the number of log kilobytes consumed by the log records

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [smallint] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [nvarchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [nvarchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [sysname] NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [sysname] NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [sysname] NULL
	Shows the connected database

Formatted/Non:	[program_name] [sysname] NULL
	Shows the reported program/application name

Formatted/Non:	[additional_info] [xml] NULL
	(Requires @get_additional_info option)
	Returns additional non-performance-related session/request information

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the connection was made

Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @not_filter IS NULL
		OR @not_filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @show_system_spids IS NULL
		OR @show_sleeping_spids IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_transaction_info IS NULL
		OR @get_task_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @get_additional_info IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @sort_order IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type = 'session' AND @not_filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @show_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @show_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @get_task_info NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_task_info are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE 
			@params VARCHAR(MAX),
			@outputs VARCHAR(MAX);

		SELECT 
			@params =
				CHAR(13) +
					REPLACE
					(
						REPLACE
						(
							CONVERT
							(
								VARCHAR(MAX),
								SUBSTRING
								(
									t.text, 
									CHARINDEX('--~', t.text) + 5, 
									CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
								)
							),
							CHAR(13)+CHAR(10),
							CHAR(13)
						),
						'	',
						''
					) +
					CHAR(13),
				@outputs = 
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								REPLACE
								(
									CONVERT
									(
										VARCHAR(MAX),
										SUBSTRING
										(
											t.text, 
											CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
											CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
										)
									),
									CHAR(9),
									CHAR(255)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13)
			FROM sys.dm_exec_requests AS r
			CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
			WHERE
				r.session_id = @@SPID;

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@params) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CASE
					WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
					ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params)) 
				END AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY
						CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
						SUBSTRING(@params, number+1, 1)
					ORDER BY 
						number
				) AS group_order
			FROM numbers
			WHERE
				SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				MIN
				(
					CASE
						WHEN token LIKE '@%' THEN token
						ELSE NULL
					END
				) AS parameter,
				MIN
				(
					CASE
						WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
						ELSE NULL
					END
				) AS description,
				param_group,
				group_order
			FROM tokens
			WHERE
				NOT 
				(
					token = '' 
					AND group_order > 1
				)
			GROUP BY
				param_group,
				group_order
		)
		SELECT
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
				WHEN param_group = MAX(param_group) OVER() THEN parameter
				ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			param_group, 
			group_order;
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@outputs) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@outputs,
						number + 1,
						CASE
							WHEN 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) < 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255), @outputs, number + 1), 0), LEN(@outputs))
								THEN COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) - number - 1
							ELSE
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255), @outputs, number + 1), 0), LEN(@outputs)) - number - 1
						END
					)
				)) AS token,
				number,
				COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) AS output_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY 
						COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs))
					ORDER BY
						number
				) AS output_group_order
			FROM numbers
			WHERE
				SUBSTRING(@outputs, number, 10) = CHAR(13) + 'Formatted'
				OR SUBSTRING(@outputs, number, 2) = CHAR(13) + CHAR(255)
		),
		output_tokens AS
		(
			SELECT 
				*,
				CASE output_group_order
					WHEN 2 THEN MAX(CASE output_group_order WHEN 1 THEN token ELSE NULL END) OVER (PARTITION BY output_group)
					ELSE ''
				END COLLATE Latin1_General_Bin2 AS column_info
			FROM tokens
		)
		SELECT
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info)+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255), column_info)+2) - CHARINDEX(CHAR(255), column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info)+2, CHARINDEX(']', column_info, CHARINDEX(CHAR(255), column_info)+2) - CHARINDEX(CHAR(255), column_info)-1)
					END
				ELSE ''
			END AS formatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, LEN(column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
					END
				ELSE ''
			END AS formatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN
									SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX('>', column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info)))
								ELSE
									SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info)))
							END
					END
				ELSE ''
			END AS unformatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255), column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN ''
								ELSE
									SUBSTRING(column_info, CHARINDEX(']', column_info, CHARINDEX('Non-Formatted:', column_info))+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
							END
					END
				ELSE ''
			END AS unformatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE REPLACE(token, CHAR(255), '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM output_tokens
		WHERE
			NOT 
			(
				output_group_order = 1 
				AND output_group = LEN(@outputs)
			)
		ORDER BY
			output_group,
			CASE output_group_order
				WHEN 1 THEN 99
				ELSE output_group_order
			END;

		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@output_column_list))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output = 1
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output = 1
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_allocations]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
				AND @get_task_info = 2
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_allocations_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
				AND @get_task_info = 2
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[additional_info]', 40
			WHERE
				@get_additional_info = 1
			UNION ALL
			SELECT '[start_time]', 41
			UNION ALL
			SELECT '[request_id]', 42
			UNION ALL
			SELECT '[collection_time]', 43
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@sort_order))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@sort_order,
					number + 1,
					CHARINDEX(']', @sort_order, number) - number - 1
				) + '|]' AS token,
			SUBSTRING
			(
				@sort_order,
				CHARINDEX(']', @sort_order, number) + 1,
				COALESCE(NULLIF(CHARINDEX('[', @sort_order, CHARINDEX(']', @sort_order, number)), 0), LEN(@sort_order)) - CHARINDEX(']', @sort_order, number)
			) AS next_chunk,
			number
		FROM numbers
		WHERE
			SUBSTRING(@sort_order, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name +
				CASE
					WHEN tokens.next_chunk LIKE '%asc%' THEN ' ASC'
					WHEN tokens.next_chunk LIKE '%desc%' THEN ' DESC'
					ELSE ''
				END AS column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number
			) AS r,
			tokens.number
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name
			UNION ALL
			SELECT '[physical_io]'
			UNION ALL
			SELECT '[reads]'
			UNION ALL
			SELECT '[physical_reads]'
			UNION ALL
			SELECT '[writes]'
			UNION ALL
			SELECT '[tempdb_allocations]'
			UNION ALL
			SELECT '[tempdb_current]'
			UNION ALL
			SELECT '[CPU]'
			UNION ALL
			SELECT '[context_switches]'
			UNION ALL
			SELECT '[used_memory]'
			UNION ALL
			SELECT '[physical_io_delta]'
			UNION ALL
			SELECT '[reads_delta]'
			UNION ALL
			SELECT '[physical_reads_delta]'
			UNION ALL
			SELECT '[writes_delta]'
			UNION ALL
			SELECT '[tempdb_allocations_delta]'
			UNION ALL
			SELECT '[tempdb_current_delta]'
			UNION ALL
			SELECT '[CPU_delta]'
			UNION ALL
			SELECT '[context_switches_delta]'
			UNION ALL
			SELECT '[used_memory_delta]'
			UNION ALL
			SELECT '[tasks]'
			UNION ALL
			SELECT '[tran_start_time]'
			UNION ALL
			SELECT '[open_tran_count]'
			UNION ALL
			SELECT '[blocking_session_id]'
			UNION ALL
			SELECT '[blocked_session_count]'
			UNION ALL
			SELECT '[percent_complete]'
			UNION ALL
			SELECT '[host_name]'
			UNION ALL
			SELECT '[login_name]'
			UNION ALL
			SELECT '[database_name]'
			UNION ALL
			SELECT '[start_time]'
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@sort_order =
			COALESCE
			(
				STUFF
				(
					(
						SELECT
							',' + column_name as [text()]
						FROM ordered_columns
						WHERE
							r = 1
						ORDER BY
							number
						FOR XML PATH('')
					),
					1,
					1,
					''
				),
				''
			);

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NOT NULL,
		physical_reads BIGINT NOT NULL,
		writes BIGINT NOT NULL,
		tempdb_allocations BIGINT NOT NULL,
		tempdb_current BIGINT NOT NULL,
		CPU INT NOT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info NVARCHAR(4000) NULL,
		locks XML NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes NVARCHAR(4000) NULL,
		open_tran_count SMALLINT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name sysname NULL,
		login_name sysname NOT NULL,
		database_name sysname NULL,
		program_name sysname NULL,
		additional_info XML NULL,
		start_time DATETIME NOT NULL,
		last_request_start_time DATETIME NOT NULL,
		UNIQUE CLUSTERED (session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON)
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.db_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				COALESCE(s.request_id, -1) AS request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name
			INTO #locks
			FROM
			(
				SELECT
					sp.spid AS session_id,
					CASE sp.status
						WHEN 'sleeping' THEN CONVERT(INT, NULL)
						ELSE sp.request_id
					END AS request_id,
					CASE sp.status
						WHEN 'sleeping' THEN sp.login_time
						ELSE
						COALESCE
						(
							(
								SELECT	
									r.start_time
								FROM sys.dm_exec_requests AS r
								WHERE
									r.session_id = sp.spid
									AND r.request_id = sp.request_id
							),
							sp.login_time
						)
					END AS start_time,
					sp.dbid
				FROM sys.sysprocesses AS sp
				WHERE
					--Process inclusive filter
					1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(SMALLINT, @filter) = 0
												OR sp.spid = CONVERT(SMALLINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
					--Process exclusive filter
					AND 0 =
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN sp.spid = CONVERT(SMALLINT, @not_filter) THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @not_filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 0
						END
					AND 
					(
						@show_own_spid = 1
						OR sp.spid <> @@SPID
					)
					AND 
					(
						@show_system_spids = 1
						OR sp.hostprocess > ''
					)
					AND sp.ecid = 0
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), N'(null)') AS db_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = COALESCE(s.request_id, 0)
			OPTION (HASH GROUP);
			
			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_db_name ON #locks (db_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			--Column list
			CONVERT
			(
				VARCHAR(MAX),
				'DECLARE @blocker BIT; ' +
				'SET @blocker = 0; ' +
				'DECLARE @i INT; ' +
				'SET @i = 2147483647; ' +
				'' +
				'DECLARE @sessions TABLE ' +
				'( ' +
					'session_id SMALLINT NOT NULL, ' +
					'kpid SMALLINT NOT NULL, ' +
					'ecid SMALLINT NOT NULL, ' +
					'request_id INT, ' +
					'login_time DATETIME, ' +
					'status VARCHAR(30), ' +
					'statement_start_offset INT, ' +
					'statement_end_offset INT, ' +
					'sql_handle BINARY(20), ' +
					'host_name NVARCHAR(128), ' +
					'login_name NVARCHAR(128), ' +
					'program_name NVARCHAR(128), ' +
					'database_id SMALLINT, ' +
					'memory_usage INT, ' +
					'open_tran_count SMALLINT, ' +
					CASE
						WHEN @get_task_info = 1 OR @find_block_leaders = 1 THEN
							'wait_type NVARCHAR(32), ' +
							'wait_resource NVARCHAR(256), ' +
							'wait_time BIGINT, '
						ELSE ''
					END +
					'blocked SMALLINT, ' +
					'UNIQUE CLUSTERED (session_id, kpid, ecid)  WITH (IGNORE_DUP_KEY = ON) ' +
				'); ' +
				'' +
				'DECLARE @blockers TABLE ' +
				'( ' +
					'session_id INT NOT NULL PRIMARY KEY ' +
				'); ' +
				'' +
				'BLOCKERS:; ' +
				'' +
				'INSERT @sessions ' +
				'( ' +
					'session_id, ' +
					'kpid, ' +
					'ecid, ' +
					'request_id, ' +
					'login_time, ' +
					'status, ' +
					'statement_start_offset, ' +
					'statement_end_offset, ' +
					'sql_handle, ' +
					'host_name, ' +
					'login_name, ' +
					'program_name, ' +
					'database_id, ' +
					'memory_usage, ' +
					'open_tran_count, ' +
					CASE
						WHEN @get_task_info = 1 OR @find_block_leaders = 1 THEN
							'wait_type, ' +
							'wait_resource, ' +
							'wait_time, '
						ELSE ''
					END +
					'blocked ' +
				') ' +
				'SELECT TOP(@i) ' +
					'sp0.session_id, ' +
					'sp0.kpid, ' +
					'sp0.ecid, ' +
					'sp0.request_id, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.login_time ' +
						'ELSE NULL ' +
					'END AS login_time, ' +
					'LOWER(sp0.status) AS status, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN ' +
							'CASE ' +
								'WHEN sp0.cmd = ''CREATE INDEX'' THEN 0 ' +
								'ELSE sp0.stmt_start ' +
							'END ' + 
						'ELSE NULL ' +
					'END AS statement_start_offset, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN ' +
							'CASE ' +
								'WHEN sp0.cmd = ''CREATE INDEX'' THEN -1 ' +
								'ELSE COALESCE(NULLIF(sp0.stmt_end, 0), -1) ' +
							'END ' +
						'ELSE NULL ' +
					'END AS statement_end_offset, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.sql_handle ' +
						'ELSE NULL ' +
					'END AS sql_handle, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.host_name ' +
						'ELSE NULL ' +
					'END AS host_name, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.login_name ' +
						'ELSE NULL ' +
					'END AS login_name, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.program_name ' +
						'ELSE NULL ' +
					'END AS program_name, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.database_id ' +
						'ELSE NULL ' +
					'END AS database_id, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.memory_usage ' +
						'ELSE NULL ' +
					'END AS memory_usage, ' +
					'CASE sp0.ecid ' +
						'WHEN 0 THEN sp0.open_tran_count ' +
						'ELSE NULL ' +
					'END AS open_tran_count, ' +
					CASE
						WHEN @get_task_info = 1 OR @find_block_leaders = 1 THEN
							'CASE ' +
								'WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN sp0.wait_type ' +
								'ELSE NULL ' +
							'END AS wait_type, ' +
							'CASE ' +
								'WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN sp0.wait_resource ' +
								'ELSE NULL ' +
							'END AS wait_resource, ' +
							'CASE ' +
								'WHEN sp0.wait_type <> N''CXPACKET'' THEN sp0.wait_time ' +
								'ELSE 0 ' +
							'END AS wait_time, '
						ELSE ''
					END +
					'sp0.blocked ' +
				'FROM ' +
				'( ' +
					'SELECT TOP(@i) ' +
						'sp1.spid AS session_id, ' +
						'sp1.kpid, ' +
						'sp1.ecid, ' +
						'CASE sp1.status ' +
							'WHEN ''sleeping'' THEN CONVERT(INT, NULL) ' +
							'ELSE sp1.request_id ' +
						'END AS request_id, ' +
						'sp1.login_time, ' +
						'CONVERT(VARCHAR(30), RTRIM(sp1.status)) COLLATE Latin1_General_Bin2 AS status, ' +
						'CONVERT(VARCHAR(16), RTRIM(sp1.cmd)) COLLATE Latin1_General_Bin2 AS cmd, ' +
						'sp1.stmt_start, ' +
						'sp1.stmt_end, ' +
						'sp1.sql_handle, ' +
						'CONVERT(sysname, RTRIM(sp1.hostname)) COLLATE SQL_Latin1_General_CP1_CI_AS AS host_name, ' +
						CASE
							WHEN @filter_type = 'login' OR @not_filter_type = 'login' THEN
								'MAX(CONVERT(sysname, RTRIM(sp1.loginame)) COLLATE SQL_Latin1_General_CP1_CI_AS) OVER (PARTITION BY sp1.spid, sp1.request_id) AS login_name, '
							ELSE
								'CONVERT(sysname, RTRIM(sp1.loginame)) AS login_name, '
						END +
						'CONVERT(sysname, RTRIM(sp1.program_name)) COLLATE SQL_Latin1_General_CP1_CI_AS AS program_name, ' +
						'sp1.dbid AS database_id, ' +
						'sp1.memusage AS memory_usage, ' +
						'sp1.open_tran AS open_tran_count, ' +
						'RTRIM(sp1.lastwaittype) AS wait_type, ' +
						'RTRIM(sp1.waitresource) AS wait_resource, ' +
						'sp1.waittime AS wait_time, ' +
						'COALESCE(NULLIF(sp1.blocked, sp1.spid), 0) AS blocked, ' +
						'sp1.hostprocess ' +
					'FROM ' +
					'( ' +
						'SELECT TOP(@i) ' +
							'session_id ' +
						'FROM @blockers ' +
						'' +
						'UNION ALL ' +
						'' +
						'SELECT TOP(@i) ' +
							'0 ' +
						'WHERE ' +
							'@blocker = 0 ' +
					') AS blk (session_id) ' +
					'INNER LOOP JOIN sys.sysprocesses AS sp1 ON ' +
						'sp1.spid = blk.session_id ' +
						'OR @blocker = 0 ' +
					CASE 
						WHEN 
						(
							@get_task_info = 0 
							AND @find_block_leaders = 0
						) THEN
							'WHERE ' +
								'sp1.ecid = 0 ' 
						ELSE ''
					END +
				') AS sp0 ' +
				'WHERE ' +
					'@blocker = 1 ' +
					'OR ' +
					'(1=1 ' +
						--inclusive filter
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN CONVERT(SMALLINT, @filter) <> 0 THEN
												'AND sp0.session_id = CONVERT(SMALLINT, @filter) '
											ELSE ''
										END
									WHEN 'program' THEN
										'AND sp0.program_name LIKE @filter '
									WHEN 'login' THEN
										'AND sp0.login_name LIKE @filter '
									WHEN 'host' THEN
										'AND sp0.host_name LIKE @filter '
									WHEN 'database' THEN
										'AND DB_NAME(sp0.database_id) LIKE @filter '
									ELSE ''
								END
							ELSE ''
						END +
						--exclusive filter
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN CONVERT(SMALLINT, @not_filter) <> 0 THEN
												'AND sp0.session_id <> CONVERT(SMALLINT, @not_filter) '
											ELSE ''
										END
									WHEN 'program' THEN
										'AND sp0.program_name NOT LIKE @not_filter '
									WHEN 'login' THEN
										'AND sp0.login_name NOT LIKE @not_filter '
									WHEN 'host' THEN
										'AND sp0.host_name NOT LIKE @not_filter '
									WHEN 'database' THEN
										'AND DB_NAME(sp0.database_id) NOT LIKE @not_filter '
									ELSE ''
								END
							ELSE ''
						END +
						CASE @show_own_spid
							WHEN 1 THEN ''
							ELSE
								'AND sp0.session_id <> @@spid '
						END +
						CASE 
							WHEN @show_system_spids = 0 THEN
								'AND sp0.hostprocess > '''' ' 
							ELSE ''
						END +
						CASE @show_sleeping_spids
							WHEN 0 THEN
								'AND sp0.status <> ''sleeping'' '
							WHEN 1 THEN
								'AND ' +
								'( ' +
									'sp0.status <> ''sleeping'' ' +
									'OR sp0.open_tran_count > 0 ' +
								') '
							ELSE ''
						END + 
					'); ' +
				CASE @recursion
					WHEN 1 THEN 
						'IF @blocker = 0 ' +
						'BEGIN; ' +
							'INSERT @blockers ' +
							'( ' +
								'session_id ' +
							') ' +
							'SELECT TOP(@i) ' +
								'blocked ' +
							'FROM @sessions ' +
							'' +
							'EXCEPT ' +
							'' +
							'SELECT TOP(@i) ' +
								'session_id ' +
							'FROM @sessions; ' +
							'' +
							'IF @@ROWCOUNT > 0 ' +
							'BEGIN; ' +
								'SET @blocker = 1; ' +
								'GOTO BLOCKERS; ' +
							'END; ' +
						'END; '
					ELSE ''
				END +
				'SELECT TOP(@i) ' +
					'@recursion AS recursion, ' +
					'x.session_id, ' +
					'x.request_id, ' +
					'DENSE_RANK() OVER  ' +
					'( ' +
						'ORDER BY ' +
							'x.session_id ' +
					') AS session_number, ' +
					CASE
						WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 'x.elapsed_time '
						ELSE '0 '
					END + 'AS elapsed_time, ' +
					CASE
						WHEN
							(
								@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
								@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
							)
							AND @recursion = 1
								THEN 'x.avg_elapsed_time / 1000 '
						ELSE 'NULL '
					END + 'AS avg_elapsed_time, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
								THEN 'x.physical_io '
						ELSE 'NULL '
					END + 'AS physical_io, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
								THEN 'x.reads '
						ELSE '0 '
					END + 'AS reads, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
								THEN 'x.physical_reads '
						ELSE '0 '
					END + 'AS physical_reads, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
								THEN 'x.writes '
						ELSE '0 '
					END + 'AS writes, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tempdb_allocations|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[tempdb_allocations_delta|]%' ESCAPE '|'
								THEN 'x.tempdb_allocations '
						ELSE '0 '
					END + 'AS tempdb_allocations, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
								THEN 'x.tempdb_current '
						ELSE '0 '
					END + 'AS tempdb_current, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
								THEN 'x.CPU '
						ELSE '0 '
					END + 'AS CPU, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
								THEN 'x.context_switches '
						ELSE 'NULL '
					END + 'AS context_switches, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
							OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
								THEN 'x.used_memory '
						ELSE '0 '
					END + 'AS used_memory, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
							AND @recursion = 1
								THEN 'x.tasks '
						ELSE 'NULL '
					END + 'AS tasks, ' +
					CASE
						WHEN 
							(
								@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
								OR @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
							)
							AND @recursion = 1
								THEN 'x.status '
						ELSE ''''' '
					END + 'AS status, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.wait_info '
						ELSE 'NULL '
					END + 'AS wait_info, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 
								'CONVERT ' +
								'( ' +
									'DATETIME, ' +
									'LEFT ' +
									'( ' +
										'x.tran_log_writes, ' +
										'NULLIF(CHARINDEX(NCHAR(254), x.tran_log_writes) - 1, -1) ' +
									') ' +
								') '
						ELSE 'NULL '
					END + 'AS tran_start_time, ' +				
					CASE
						WHEN 
							@output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 
								'RIGHT ' +
								'( ' +
									'x.tran_log_writes, ' +
									'LEN(x.tran_log_writes) - CHARINDEX(NCHAR(254), x.tran_log_writes) ' +
								') '
						ELSE 'NULL '
					END + 'AS tran_log_writes, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.open_tran_count '
						ELSE 'NULL '
					END + 'AS open_tran_count, ' + 
					CASE
						WHEN 
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.sql_handle '
						ELSE 'NULL '
					END + 'AS sql_handle, ' +
					CASE
						WHEN 
							(
								@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
								OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
							)
							AND @recursion = 1
								THEN 'x.statement_start_offset '
						ELSE 'NULL '
					END + 'AS statement_start_offset, ' +
					CASE
						WHEN 
							(
								@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
								OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
							)
							AND @recursion = 1
								THEN 'x.statement_end_offset '
						ELSE 'NULL '
					END + 'AS statement_end_offset, ' +
					'NULL AS sql_text, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.plan_handle '
						ELSE 'NULL '
					END + 'AS plan_handle, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'NULLIF(x.blocking_session_id, 0) '
						ELSE 'NULL '
					END + 'AS blocking_session_id, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
							AND @recursion = 1
								THEN 'x.percent_complete '
						ELSE 'NULL '
					END + 'AS percent_complete, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.host_name '
						ELSE ''''' '
					END + 'AS host_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.login_name '
						ELSE ''''' '
					END + 'AS login_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'DB_NAME(x.database_id) '
						ELSE 'NULL '
					END + 'AS database_name, ' +
					CASE
						WHEN 
							@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
							AND @recursion = 1
								THEN 'x.program_name '
						ELSE ''''' '
					END + 'AS program_name, ' +
					CASE
						WHEN
							@output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
							AND @recursion = 1
								THEN
									'( ' +
										'SELECT TOP(@i) ' +
											'text_size, ' +
											'language, ' +
											'date_format, ' +
											'date_first, ' +
											'CASE quoted_identifier ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS quoted_identifier, ' +
											'CASE arithabort ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS arithabort, ' +
											'CASE ansi_null_dflt_on ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS ansi_null_dflt_on, ' +
											'CASE ansi_defaults ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS ansi_defaults, ' +
											'CASE ansi_warnings ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS ansi_warnings, ' +
											'CASE ansi_padding ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS ansi_padding, ' +
											'CASE ansi_nulls ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS ansi_nulls, ' +
											'CASE concat_null_yields_null ' +
												'WHEN 0 THEN ''OFF'' ' +
												'ELSE ''ON'' ' +
											'END AS concat_null_yields_null, ' +
											'CASE transaction_isolation_level ' +
												'WHEN 0 THEN ''Unspecified'' ' +
												'WHEN 1 THEN ''ReadUncomitted'' ' +
												'WHEN 2 THEN ''ReadCommitted'' ' +
												'WHEN 3 THEN ''Repeatable'' ' +
												'WHEN 4 THEN ''Serializable'' ' +
												'WHEN 5 THEN ''Snapshot'' ' +
											'END AS transaction_isolation_level, ' +
											'lock_timeout, ' +
											'deadlock_priority, ' +
											'row_count, ' +
											'original_login_name ' +
										'FOR XML ' +
											'PATH(''additional_info''), ' +
											'TYPE ' +
									') '
						ELSE 'NULL '
					END + 'AS additional_info, ' +
					'x.start_time, ' +
					'x.last_request_start_time '
			--End column list
			) +
			--Derived table "y"
			CONVERT
			(
				VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(@i) ' +
						'y.*, ' +
						'CASE ' +
							--if there are more than 24 days, return a negative number of seconds rather than
							--positive milliseconds, in order to avoid overflow errors
							'WHEN DATEDIFF(day, y.start_time, GETDATE()) > 24 THEN ' +
								'DATEDIFF(second, GETDATE(), y.start_time) ' +
							'ELSE DATEDIFF(ms, y.start_time, GETDATE()) ' +
						'END AS elapsed_time, ' +
						'tasks.physical_io, ' +
						'COALESCE(tempdb_info.tempdb_allocations, 0) AS tempdb_allocations, ' +
						'COALESCE ' +
						'( ' +
							'CASE ' +
								'WHEN tempdb_info.tempdb_current < 0 THEN 0 ' +
								'ELSE tempdb_info.tempdb_current ' + 
							'END, ' +
							'0 ' +
						') AS tempdb_current, ' +
						'tasks.context_switches, ' + 
						'tasks.tasks, ' +
						'tasks.wait_info, ' +
						'tasks.blocking_session_id, ' +
						CASE 
							WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN 'CONVERT(INT, NULL) '
							ELSE 'qs.total_elapsed_time / qs.execution_count '
						END + 'AS avg_elapsed_time ' +
					'FROM ' +
					'( ' +
						'SELECT TOP(@i) ' +
							'sp.session_id, ' +
							'sp.request_id, ' +
							'COALESCE(r.logical_reads, s.logical_reads) AS reads, ' +
							'COALESCE(r.reads, s.reads) AS physical_reads, ' +
							'COALESCE(r.writes, s.writes) AS writes, ' +
							'COALESCE(r.CPU_time, s.CPU_time) AS CPU, ' +
							'sp.memory_usage + COALESCE(r.granted_query_memory, 0) AS used_memory, ' +
							'LOWER(sp.status) AS status, ' +
							'sp.sql_handle, ' +
							'r.sql_handle AS request_sql_handle, ' +
							'sp.statement_start_offset, ' +
							'sp.statement_end_offset, ' +
							'r.plan_handle, ' +
							'NULLIF(r.percent_complete, 0) AS percent_complete, ' +
							'sp.host_name, ' +
							'sp.login_name, ' +
							'sp.program_name, ' +
							'COALESCE(r.text_size, s.text_size) AS text_size, ' +
							'COALESCE(r.language, s.language) AS language, ' +
							'COALESCE(r.date_format, s.date_format) AS date_format, ' +
							'COALESCE(r.date_first, s.date_first) AS date_first, ' +
							'COALESCE(r.quoted_identifier, s.quoted_identifier) AS quoted_identifier, ' +
							'COALESCE(r.arithabort, s.arithabort) AS arithabort, ' +
							'COALESCE(r.ansi_null_dflt_on, s.ansi_null_dflt_on) AS ansi_null_dflt_on, ' +
							'COALESCE(r.ansi_defaults, s.ansi_defaults) AS ansi_defaults, ' +
							'COALESCE(r.ansi_warnings, s.ansi_warnings) AS ansi_warnings, ' +
							'COALESCE(r.ansi_padding, s.ansi_padding) AS ansi_padding, ' +
							'COALESCE(r.ansi_nulls, s.ansi_nulls) AS ansi_nulls, ' +
							'COALESCE(r.concat_null_yields_null, s.concat_null_yields_null) AS concat_null_yields_null, ' +
							'COALESCE(r.transaction_isolation_level, s.transaction_isolation_level) AS transaction_isolation_level, ' +
							'COALESCE(r.lock_timeout, s.lock_timeout) AS lock_timeout, ' +
							'COALESCE(r.deadlock_priority, s.deadlock_priority) AS deadlock_priority, ' +
							'COALESCE(r.row_count, s.row_count) AS row_count, ' +
							's.original_login_name, ' +
							'COALESCE(r.start_time, sp.login_time) AS start_time, ' +
							'COALESCE(r.start_time, s.last_request_start_time) AS last_request_start_time, ' +
							'r.transaction_id, ' +
							'sp.database_id, ' +
							'sp.open_tran_count, ' +
							'( ' +
								CASE 
									WHEN NOT (@get_transaction_info = 1 AND @recursion = 1) THEN 'SELECT CONVERT(NVARCHAR(4000), NULL) '
									ELSE
										CONVERT
										(
											VARCHAR(MAX),
											'( ' +
												'SELECT TOP(@i) ' +
													'CONVERT ' +
													'( ' +
														'NVARCHAR(MAX), ' +
														'CASE ' +
															'WHEN u_trans.database_id IS NOT NULL THEN ' +
																'CASE u_trans.r ' +
																	'WHEN 1 THEN COALESCE(CONVERT(NVARCHAR, u_trans.transaction_start_time, 121) + NCHAR(254), N'''') ' +
																	'ELSE N'''' ' +
																'END + ' + 
																	'REPLACE ' +
																	'( ' +
																		'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
																		'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
																		'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
																			'CONVERT(VARCHAR(128), COALESCE(DB_NAME(u_trans.database_id), N''(null)'')), ' +
																			'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
																			'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
																			'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
																		'NCHAR(0), ' +
																		N'''?'' ' +
																	') + ' +
																	'N'': '' + ' +
																'CONVERT(NVARCHAR, u_trans.log_record_count) + N'' ('' + CONVERT(NVARCHAR, u_trans.log_kb_used) + N'' kB)'' + ' +
																'N'','' ' +
															'ELSE ' +
																'N''N/A,'' ' +
														'END COLLATE Latin1_General_BIN2 ' +
													') AS [text()] ' +
												'FROM ' +
												'( ' +
													'SELECT TOP(@i) ' +
														'trans.*, ' +
														'ROW_NUMBER() OVER (ORDER BY trans.transaction_start_time DESC) AS r ' +
													'FROM ' +
													'( ' +
														'SELECT TOP(@i) ' +
															's_tran.database_id, ' +
															'COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count, ' +
															'COALESCE(SUM(s_tran.database_transaction_log_bytes_used), 0) / 1024 AS log_kb_used, ' +
															'MIN(s_tran.database_transaction_begin_time) AS transaction_start_time ' +
														'FROM ' +
														'( ' +
															'SELECT TOP(@i) ' +
																'* ' +
															'FROM sys.dm_tran_database_transactions ' +
														') AS s_tran ' +
														'LEFT OUTER JOIN ' +
														'( ' +
															'SELECT TOP(@i) ' +
																'* ' +
															'FROM sys.dm_tran_session_transactions ' +
														') AS tst ON ' +
															's_tran.transaction_id = tst.transaction_id ' +
															'AND s_tran.database_id < 32767 ' +
														'WHERE ' +
															's_tran.transaction_id = r.transaction_id ' + 
															'OR ' +
															'( ' +
																'COALESCE(sp.request_id, 0) = 0 ' +
																'AND sp.session_id = tst.session_id ' +
															') ' +
														'GROUP BY ' +
															's_tran.database_id ' +
													') AS trans ' +
												') AS u_trans ' +
												'FOR XML PATH(''''), TYPE ' +
											').value(''.'', ''NVARCHAR(MAX)'') '
										)
								END +
							') COLLATE Latin1_General_Bin2 AS tran_log_writes ' +
						'FROM @sessions AS sp ' +
						'LEFT OUTER LOOP JOIN sys.dm_exec_requests AS r ON ' +
							'sp.status <> ''sleeping'' ' +
							'AND r.session_id = sp.session_id ' +
							'AND r.request_id = sp.request_id ' +
						'LEFT OUTER LOOP JOIN sys.dm_exec_sessions AS s ON ' +
							's.session_id = sp.session_id ' +
							'AND r.request_id IS NULL ' +
						'WHERE ' +
							'sp.ecid = 0 ' +
							'AND ' +
							'( ' +
								'( ' +
									'COALESCE(sp.request_id, 0) = 0 ' +
									'AND ' + 
									'( ' +
										'r.request_id IS NOT NULL ' +
										'OR s.session_id IS NOT NULL ' +
									') ' +
								') ' +
								'OR ' +
								'( ' +
									'COALESCE(sp.request_id, 0) > 0 ' +
									'AND r.request_id IS NOT NULL ' +
								') ' +
							') ' +
					') AS y '
				--End derived table "y"
				) +
				--Derived table "x"
				CONVERT
				(
					VARCHAR(MAX),
					CASE 
						WHEN 
							(
								@get_task_info = 0
								AND @find_block_leaders = 0
							) THEN
							'CROSS JOIN ' +
							'( ' +
								'SELECT TOP(@i) ' +
									'CONVERT(BIGINT, NULL) AS physical_io, ' +
									'CONVERT(BIGINT, NULL) AS context_switches, ' +
									'CONVERT(INT, NULL) AS tasks, ' +
									'CONVERT(SMALLINT, NULL) AS blocking_session_id, ' +
									'CONVERT(NVARCHAR(4000), NULL) AS wait_info ' +
							') AS tasks '
						WHEN @get_task_info = 2 THEN
							'LEFT OUTER HASH JOIN ' +
							'( ' +
								'SELECT TOP(@i) ' +
									'task_nodes.task_node.value(''(session_id/text())[1]'', ''SMALLINT'') AS session_id, ' +
									'task_nodes.task_node.value(''(request_id/text())[1]'', ''INT'') AS request_id, ' +
									'task_nodes.task_node.value(''(physical_io/text())[1]'', ''BIGINT'') AS physical_io, ' +
									'task_nodes.task_node.value(''(context_switches/text())[1]'', ''BIGINT'') AS context_switches, ' +
									'task_nodes.task_node.value(''(tasks/text())[1]'', ''INT'') AS tasks, ' +
									'task_nodes.task_node.value(''(blocking_session_id/text())[1]'', ''SMALLINT'') AS blocking_session_id, ' +
									'task_nodes.task_node.value(''(waits/text())[1]'', ''NVARCHAR(4000)'') AS wait_info ' +
								'FROM ' +
								'( ' +
									'SELECT TOP(@i) ' +
										'CONVERT ' +
										'( ' +
											'XML, ' +
											'REPLACE( ' +
												'CONVERT(NVARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2, ' +
												'N''</waits></tasks><tasks><waits>'', N'', '') ' +
										') AS task_xml ' +
									'FROM ' +
									'( ' +
										'SELECT TOP(@i) ' +
											'CASE waits.r ' +
												'WHEN 1 THEN waits.session_id ' +
												'ELSE NULL ' +
											'END AS [session_id], ' +
											'CASE waits.r ' +
												'WHEN 1 THEN waits.request_id ' +
												'ELSE NULL ' +
											'END AS [request_id], ' +											
											'CASE waits.r ' +
												'WHEN 1 THEN waits.physical_io ' +
												'ELSE NULL ' +
											'END AS [physical_io], ' +
											'CASE waits.r ' +
												'WHEN 1 THEN waits.context_switches ' +
												'ELSE NULL ' +
											'END AS [context_switches], ' +
											'CASE waits.r ' +
												'WHEN 1 THEN waits.tasks ' +
												'ELSE NULL ' +
											'END AS [tasks], ' +
											'CASE waits.r ' +
												'WHEN 1 THEN waits.blocking_session_id ' +
												'ELSE NULL ' +
											'END AS [blocking_session_id], ' +
											'REPLACE ' +
											'( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
												'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
													'CONVERT ' +
													'( ' +
														'NVARCHAR(MAX), ' +
														'N''('' + ' +
															'CONVERT(NVARCHAR, num_waits) + N''x: '' + ' +
															'CASE num_waits ' +
																'WHEN 1 THEN CONVERT(NVARCHAR, min_wait_time) + N''ms'' ' +
																'WHEN 2 THEN ' +
																	'CASE ' +
																		'WHEN min_wait_time <> max_wait_time THEN CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms'' ' +
																		'ELSE CONVERT(NVARCHAR, max_wait_time) + N''ms'' ' +
																	'END ' +
																'ELSE ' +
																	'CASE ' +
																		'WHEN min_wait_time <> max_wait_time THEN CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, avg_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms'' ' +
																		'ELSE CONVERT(NVARCHAR, max_wait_time) + N''ms'' ' +
																	'END ' +
															'END + ' +
														'N'')'' + wait_type COLLATE Latin1_General_BIN2 ' +
													'), ' +
													'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
													'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
													'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
												'NCHAR(0), ' +
												'N'''' ' +
											') AS [waits] ' +
										'FROM ' +
										'( ' +
											'SELECT TOP(@i) ' +
												'w1.*, ' +
												'ROW_NUMBER() OVER (PARTITION BY w1.session_id, w1.request_id ORDER BY w1.blocking_session_id DESC, w1.num_waits DESC, w1.wait_type) AS r ' +
											'FROM ' +
											'( ' +
												'SELECT TOP(@i) ' +
													'task_info.session_id, ' +
													'task_info.request_id, ' +
													'task_info.physical_io, ' +
													'task_info.context_switches, ' +
													'task_info.num_tasks AS tasks, ' +
													'wt2.wait_type, ' +
													'NULLIF(COUNT(wt2.waiting_task_address), 0) AS num_waits, ' +
													'MIN(wt2.wait_duration_ms) AS min_wait_time, ' +
													'AVG(wt2.wait_duration_ms) AS avg_wait_time, ' +
													'MAX(wt2.wait_duration_ms) AS max_wait_time, ' +
													'MAX(wt2.blocking_session_id) AS blocking_session_id ' +
												'FROM ' +
												'( ' +
													'SELECT TOP(@i) ' +
														'sp2.session_id, ' +
														'sp2.request_id, ' +
														'SUM(CONVERT(BIGINT, t.pending_io_count)) OVER (PARTITION BY sp2.session_id, sp2.request_id) AS physical_io, ' +
														'SUM(CONVERT(BIGINT, t.context_switches_count)) OVER (PARTITION BY sp2.session_id, sp2.request_id) AS context_switches, ' +
														'COUNT(*) OVER (PARTITION BY sp2.session_id, sp2.request_id) AS num_tasks, ' +
														't.task_address, ' +
														't.task_state ' +
													'FROM sys.dm_os_tasks AS t ' +
													'INNER LOOP JOIN @sessions AS sp2 ON ' +
														'sp2.session_id = t.session_id ' +
														'AND sp2.status <> ''sleeping'' ' +
													'INNER HASH JOIN ' +
													'( ' +
														'SELECT TOP(@i) ' +
															'* ' +
														'FROM sys.dm_os_threads ' +
													') AS th ON ' +
														'th.os_thread_id = sp2.kpid ' +
													'INNER HASH JOIN ' +
													'( ' +
														'SELECT TOP(@i) ' +
															'* ' +
														'FROM sys.dm_os_workers ' +
													') AS w ON ' +
														'w.thread_address = th.thread_address ' +
														'AND w.worker_address = t.worker_address ' +
												') AS task_info ' +
												'LEFT OUTER HASH JOIN ' +
												'( ' +
													'SELECT TOP(@i) ' +
														'wt1.wait_type, ' +
														'wt1.waiting_task_address, ' +
														'MAX(wt1.wait_duration_ms) AS wait_duration_ms, ' +
														'MAX(wt1.blocking_session_id) AS blocking_session_id ' +
													'FROM ' +
													'( ' +
														'SELECT DISTINCT TOP(@i) ' +
															'wt.wait_type + ' +
																--TODO: What else can be pulled from the resource_description?
																'CASE ' +
																	'WHEN wt.wait_type LIKE N''PAGE%LATCH_%'' THEN ' +
																		''':'' + ' +
																		--database name
																		'COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) - 1))), N''(null)'') + ' +
																		'N'':'' + ' +
																		--file id
																		'SUBSTRING(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX(N'':'', REVERSE(wt.resource_description)) - CHARINDEX(N'':'', wt.resource_description)) + ' +
																		--page # for special pages
																		'N''('' + ' +
																			'CASE ' +
																				'WHEN ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 1 OR ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0 THEN N''PFS'' ' +
																				'WHEN ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 2 OR ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 THEN N''GAM'' ' +
																				'WHEN ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 3 OR ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511233 = 0 THEN N''SGAM'' ' +
																				'WHEN ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 6 OR ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511238 = 0 THEN N''DCM'' ' +
																				'WHEN ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 7 OR ' +
																					'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511239 = 0 THEN N''BCM'' ' +
																				'ELSE N''*'' ' +
																			'END + ' +
																		'N'')'' ' +
																	'WHEN wt.wait_type = N''CXPACKET'' THEN ' +
																		'N'':'' + SUBSTRING(wt.resource_description, CHARINDEX(N''nodeId'', wt.resource_description) + 7, 4) ' +
																	'WHEN wt.wait_type LIKE N''LATCH[_]%'' THEN ' +
																		'N'' ['' + LEFT(wt.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 1) + N'']'' ' +
																	'ELSE N'''' ' +
																'END COLLATE Latin1_General_Bin2 AS wait_type, ' +
															'wt.wait_duration_ms, ' +
															'wt.waiting_task_address, ' +
															'wt.blocking_session_id ' +
														'FROM ' +
														'( ' +
															'SELECT TOP(@i) ' +
																'wt0.wait_type COLLATE Latin1_General_Bin2 AS wait_type, ' +
																'wt0.resource_description COLLATE Latin1_General_Bin2 AS resource_description, ' +
																'wt0.wait_duration_ms, ' +
																'wt0.waiting_task_address, ' +
																'CASE ' +
																	'WHEN wt0.blocking_session_id <> wt0.session_id THEN wt0.blocking_session_id ' +
																	'ELSE NULL ' +
																'END AS blocking_session_id ' +
															'FROM sys.dm_os_waiting_tasks AS wt0 ' +
															'CROSS APPLY ' +
															'( ' +
																'SELECT TOP(1)' +
																	's0.session_id ' +
																'FROM @sessions AS s0 ' +
																'WHERE ' +
																	's0.session_id = wt0.session_id ' +
															') AS p ' +
														') AS wt ' +
													') AS wt1 ' +
													'GROUP BY ' +
														'wt1.wait_type, ' +
														'wt1.waiting_task_address ' +
													'' +
													'UNION ALL ' + 
													'' + 
													'SELECT TOP(@i) ' +
														'state, ' +
														'task_address, ' +
														'( ' +
															'SELECT TOP(@i) ' +
																'ms_ticks ' +
															'FROM sys.dm_os_sys_info ' +
														') - ' +
															'wait_resumed_ms_ticks, ' +
														'NULL ' +
													'FROM sys.dm_os_workers ' +
													'WHERE ' +
														'state = ''RUNNABLE'' ' +
												') AS wt2 ON ' +
													'wt2.waiting_task_address = task_info.task_address ' +
													'AND wt2.wait_duration_ms > 0 ' +
													'AND ' +
													'( ' +
														'task_info.task_state <> ''RUNNABLE'' ' +
														'OR ' +
														'( ' +
															'task_info.task_state = ''RUNNABLE'' ' +
															'AND wt2.wait_type = ''RUNNABLE'' ' +
														') ' +
													') ' +
												'GROUP BY ' +
													'task_info.session_id, ' +
													'task_info.request_id, ' +
													'task_info.physical_io, ' +
													'task_info.context_switches, ' +
													'task_info.num_tasks, ' +
													'wt2.wait_type ' +
											') AS w1 ' +
										') AS waits ' +
										'ORDER BY ' +
											'waits.session_id, ' +
											'waits.request_id, ' +
											'waits.r ' +
										'FOR XML PATH(N''tasks''), TYPE ' +
									') AS tasks_raw (task_xml_raw) ' +
								') AS tasks_final ' +
								'CROSS APPLY tasks_final.task_xml.nodes(N''/tasks'') AS task_nodes (task_node) ' +
								'WHERE ' +
									'task_nodes.task_node.exist(N''session_id'') = 1 ' +
							') AS tasks ON ' +
								'tasks.session_id = y.session_id ' +
								'AND tasks.request_id = y.request_id '
						ELSE --@get_task_info = 1 OR @find_block_leaders = 1
							'LEFT OUTER HASH JOIN ' +
							'( ' +								
								'SELECT TOP(@i) ' +
									'w1.session_id, ' +
									'w1.request_id, ' +
									'w1.blocking_session_id, ' +
									'N''('' + CONVERT(NVARCHAR, w1.wait_duration_ms) + N''ms)'' + ' +
										'w1.wait_type + ' +
											--TODO: What else can be pulled from the resource_description?
											'CASE ' +
												'WHEN w1.wait_type LIKE N''PAGE%LATCH_%'' THEN ' +
													'N'':'' + ' +
													--database name
													'COALESCE(DB_NAME(CONVERT(INT, LEFT(w1.resource_description, CHARINDEX(N'':'', w1.resource_description) - 1))), N''(null)'') + ' +
													'N'':'' + ' +
													--file id
													'SUBSTRING(w1.resource_description, CHARINDEX(N'':'', w1.resource_description) + 1, LEN(w1.resource_description) - CHARINDEX(N'':'', REVERSE(w1.resource_description)) - CHARINDEX(N'':'', w1.resource_description)) + ' +
													--page # for special pages
													'N''('' + ' +
														'CASE ' +
															'WHEN ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) = 1 OR ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) % 8088 = 0 THEN N''PFS'' ' +
															'WHEN ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) = 2 OR ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) % 511232 = 0 THEN N''GAM'' ' +
															'WHEN ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) = 3 OR ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) % 511233 = 0 THEN N''SGAM'' ' +
															'WHEN ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) = 6 OR ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) % 511238 = 0 THEN N''DCM'' ' +
															'WHEN ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) = 7 OR ' +
																'CONVERT(INT, RIGHT(w1.resource_description, CHARINDEX(N'':'', REVERSE(w1.resource_description)) - 1)) % 511239 = 0 THEN N''BCM'' ' +
															'ELSE N''*'' ' +
														'END + ' +
													'N'')'' ' +
												'WHEN w1.wait_type = N''CXPACKET'' THEN ' +
													'N'':'' + SUBSTRING(w1.resource_description, CHARINDEX(N''nodeId'', w1.resource_description) + 7, 4)' +
												'WHEN w1.wait_type LIKE N''LATCH[_]%'' THEN ' +
													'N'' ['' + LEFT(w1.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', w1.resource_description), 0), LEN(w1.resource_description) + 1) - 1) + N'']'' ' +
												'ELSE N'''' ' +
											'END COLLATE Latin1_General_Bin2 AS wait_info, ' +
									'CONVERT(BIGINT, NULL) AS physical_io, ' +
									'CONVERT(BIGINT, NULL) AS context_switches, ' +
									'CONVERT(INT, NULL) AS tasks ' +
								'FROM ' +
								'( ' +
									'SELECT TOP(@i) ' +
										'sp2.session_id, ' +
										'sp2.request_id, ' +
										'sp2.wait_type COLLATE Latin1_General_Bin2 AS wait_type, ' +
										'sp2.wait_resource COLLATE Latin1_General_Bin2 AS resource_description, ' +
										'sp2.wait_time AS wait_duration_ms, ' +
										'NULLIF(sp2.blocked, 0) AS blocking_session_id, ' +
										'ROW_NUMBER() OVER ' +
										'( ' +
											'PARTITION BY sp2.session_id, sp2.request_id ' +
											'ORDER BY sp2.blocked DESC, sp2.wait_time DESC ' +
										') AS r ' +
									'FROM @sessions AS sp2 ' +
								') AS w1 ' +
								'WHERE ' +
									'w1.r = 1 ' +
							') AS tasks ON ' +
								'tasks.session_id = y.session_id ' +
								'AND tasks.request_id = y.request_id '
					END +
					CONVERT
					(
						VARCHAR(MAX), 
						'LEFT OUTER HASH JOIN ' +
						'( ' +
							'SELECT TOP(@i) ' +
								't_info.session_id, ' +
								't_info.request_id, ' +
								'SUM(t_info.tempdb_allocations) AS tempdb_allocations, ' +
								'SUM(t_info.tempdb_current) AS tempdb_current ' +
							'FROM ' +
							'( ' +
								'SELECT TOP(@i) ' +
									'tsu.session_id, ' +
									'tsu.request_id, ' +
									'tsu.user_objects_alloc_page_count + ' +
										'tsu.internal_objects_alloc_page_count AS tempdb_allocations,' +
									'tsu.user_objects_alloc_page_count + ' +
										'tsu.internal_objects_alloc_page_count - ' +
										'tsu.user_objects_dealloc_page_count - ' +
										'tsu.internal_objects_dealloc_page_count AS tempdb_current ' +
								'FROM sys.dm_db_task_space_usage AS tsu ' +
								'CROSS APPLY ' +
								'( ' +
									'SELECT TOP(1) ' +
										's0.session_id ' +
									'FROM @sessions AS s0 ' +
									'WHERE ' +
										's0.session_id = tsu.session_id ' +
								') AS p ' +
								'' +
								'UNION ALL ' +
								'' +
								'SELECT TOP(@i) ' +
									'ssu.session_id, ' +
									'NULL AS request_id, ' +
									'ssu.user_objects_alloc_page_count + ' +
										'ssu.internal_objects_alloc_page_count AS tempdb_allocations, ' +
									'ssu.user_objects_alloc_page_count + ' +
										'ssu.internal_objects_alloc_page_count - ' +
										'ssu.user_objects_dealloc_page_count - ' +
										'ssu.internal_objects_dealloc_page_count AS tempdb_current ' +
								'FROM sys.dm_db_session_space_usage AS ssu ' +
								'CROSS APPLY ' +
								'( ' +
									'SELECT TOP(1) ' +
										's0.session_id ' +
									'FROM @sessions AS s0 ' +
									'WHERE ' +
										's0.session_id = ssu.session_id ' +
								') AS p ' +
							') AS t_info ' +
							'GROUP BY ' +
								't_info.session_id, ' +
								't_info.request_id ' +
						') AS tempdb_info ON ' +
							'tempdb_info.session_id = y.session_id ' +
							'AND COALESCE(tempdb_info.request_id, -1) = COALESCE(y.request_id, -1) ' 
					) +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN CONVERT(VARCHAR(MAX), '')
						ELSE
							CONVERT(VARCHAR(MAX), '') +
							'LEFT OUTER HASH JOIN ' +
							'( ' +
								'SELECT TOP(@i) ' +
									'* ' +
								'FROM sys.dm_exec_query_stats ' +
							') AS qs ON ' +
								'qs.sql_handle = y.request_sql_handle ' + 
								'AND qs.plan_handle = y.plan_handle ' + 
								'AND qs.statement_start_offset = y.statement_start_offset ' +
								'AND qs.statement_end_offset = y.statement_end_offset '
						END + 
				') AS x ' +
				'OPTION (KEEPFIXED PLAN, OPTIMIZE FOR (@i = 1)); ' 
			--End derived table "x"
			);

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_allocations,
			tempdb_current,
			CPU,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			tran_start_time,
			tran_log_writes,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			additional_info,
			start_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter sysname, @not_filter sysname',
			@recursion, @filter, @not_filter;

		--Variables for text and plan collection
		DECLARE	
			@session_id SMALLINT,
			@request_id INT,
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT,
			@start_time DATETIME;

		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN
			DECLARE sql_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					request_id,
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@session_id,
				@request_id,
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										N'--' + NCHAR(13) + NCHAR(10) +
										CASE 
											WHEN @get_full_inner_text = 1 THEN est.text
											WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN est.text
											WHEN SUBSTRING(est.text, (@statement_start_offset/2), 2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
											ELSE
												CASE
													WHEN @statement_start_offset > 0 THEN
														SUBSTRING
														(
															est.text,
															((@statement_start_offset/2) + 1),
															(
																CASE
																	WHEN @statement_end_offset = -1 THEN 2147483647
																	ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																END
															)
														)
													ELSE RTRIM(LTRIM(est.text))
												END
										END +
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_BIN2,
										NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
										NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
										NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
									NCHAR(0),
									N''
								) AS [processing-instruction(query)]
							FOR XML PATH(''), TYPE
						),
						s.statement_start_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN 0
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN 0
								ELSE @statement_start_offset
							END,
						s.statement_end_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN -1
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN -1
								ELSE @statement_end_offset
							END
					FROM 
						#sessions AS s,
						(
							SELECT TOP(1)
								text
							FROM
							(
								SELECT 
									text, 
									0 AS row_num
								FROM sys.dm_exec_sql_text(@sql_handle)
								
								UNION ALL
								
								SELECT 
									NULL,
									1 AS row_num
							) AS est0
							ORDER BY
								row_num
						) AS est
					WHERE 
						s.session_id = @session_id
						AND COALESCE(s.request_id, -1) = COALESCE(@request_id, -1)
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND COALESCE(s.request_id, -1) = COALESCE(@request_id, -1)
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@session_id,
					@request_id,
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id SMALLINT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX),
									N'--' + NCHAR(13) + NCHAR(10) + br.EventInfo + NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_BIN2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								COALESCE(s.request_id, 0) = 0
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML PATH(''), TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE plan_cursor
			CURSOR LOCAL FORWARD_ONLY DYNAMIC OPTIMISTIC
			FOR 
				SELECT 
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
			FOR UPDATE OF 
				query_plan
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT CONVERT(xml, query_plan)
							FROM sys.dm_exec_text_query_plan(@plan_handle, @statement_start_offset, @statement_end_offset)
							WHERE
								@get_plans = 1

							UNION ALL

							SELECT query_plan
							FROM sys.dm_exec_query_plan(@plan_handle)
							WHERE
								@get_plans = 2
						)
					FROM #sessions AS s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.query_plan = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE @DB_NAME sysname;

			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					db_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND db_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT  FROM locks_cursor
			INTO @DB_NAME;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_BIN2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'index_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'i.name COLLATE Latin1_General_BIN2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_BIN2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'principal_name = ' + 
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'dp.name COLLATE Latin1_General_BIN2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.db_name = @DB_NAME ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@DB_NAME sysname',
						@DB_NAME;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET 
						object_name = '(db_inaccessible)'
					WHERE 
						db_name = @DB_NAME
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT  FROM locks_cursor
				INTO @DB_NAME;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, db_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX), 
									l1.db_name COLLATE Latin1_General_BIN2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [Database/@name],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.db_name = l1.db_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML PATH(''), TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										l4.index_name AS [Lock/@index_name],
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END AS [Lock/@schema_name],
										l4.principal_name AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.db_name = l4.db_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML PATH(''), TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.db_name = l1.db_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.db_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML PATH(''), TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = COALESCE(s.request_id, -1)
						AND 
						(
							(
								s.request_id IS NULL 
								AND l1.start_time = s.start_time
							)
							OR
							(
								s.request_id IS NOT NULL 
								AND l1.start_time = s.last_request_start_time
							)
						)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.db_name
					FOR XML PATH(''), TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE @format_output
						WHEN 1 THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'''00'' + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'2 ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'''00'' + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'2 ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE @format_output
						WHEN 1 THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_allocations
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_allocations, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					--physical_io_delta			
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND physical_io_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
									ELSE 'physical_io_delta '
								END +
						'ELSE NULL ' +
					'END AS physical_io_delta, ' +
					--reads_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND reads_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
									ELSE 'reads_delta '
								END +
						'ELSE NULL ' +
					'END AS reads_delta, ' +
					--physical_reads_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND physical_reads_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
									ELSE 'physical_reads_delta '
								END + 
						'ELSE NULL ' +
					'END AS physical_reads_delta, ' +
					--writes_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND writes_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
									ELSE 'writes_delta '
								END + 
						'ELSE NULL ' +
					'END AS writes_delta, ' +
					--tempdb_allocations_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND tempdb_allocations_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
									ELSE 'tempdb_allocations_delta '
								END + 
						'ELSE NULL ' +
					'END AS tempdb_allocations_delta, ' +
					--tempdb_current_delta
					--this is the only one that can (legitimately) go negative 
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
									ELSE 'tempdb_current_delta '
								END + 
						'ELSE NULL ' +
					'END AS tempdb_current_delta, ' +
					--CPU_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND CPU_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
									ELSE 'CPU_delta '
								END + 
						'ELSE NULL ' +
					'END AS CPU_delta, ' +
					--context_switches_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND context_switches_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
									ELSE 'context_switches_delta '
								END + 
						'ELSE NULL ' +
					'END AS context_switches_delta, ' +
					--used_memory_delta
					'CASE ' +
						'WHEN ' +
							'first_request_start_time = last_request_start_time ' + 
							'AND num_events = 2 ' +
							'AND used_memory_delta >= 0 ' +
								'THEN ' +
								CASE @format_output
									WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
									WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
									ELSE 'used_memory_delta '
								END + 
						'ELSE NULL ' +
					'END AS used_memory_delta, ' +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'additional_info, ' +
					'start_time, ' +
					'request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
						'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
						'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
						'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
						'MAX(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_allocations_delta, ' +
						'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
						'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
						'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
						'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
							'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
						'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, ' +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					CASE 
						WHEN @sort_order = '' THEN ''
						ELSE
							'ORDER BY ' +
								@sort_order
					END +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE ' +
											'WHEN DATA_TYPE LIKE ''%char'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;
GO
