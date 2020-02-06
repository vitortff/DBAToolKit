--Create Table
CREATE TABLE ConnectionDetails (InstanceName NVARCHAR(500), HostName NVARCHAR(500), dbname NVARCHAR(500),
login_name NVARCHAR(500), ConnectionMonth INT, ConnectionDay INT, ConnectionHour INT, TotalConnections INT)

ALTER PROCEDURE PR_GET_CONNECTION_DETAILS
AS
DECLARE @ServerName NVARCHAR(500)
DECLARE @SQL NVARCHAR(MAX)

DECLARE ServerList CURSOR FAST_FORWARD FOR
SELECT
	InstanceName
FROM 
	[SQLdmRepository]..[MonitoredSQLServers]
WHERE 
	MaintenanceModeEnabled = 0 
AND 
	ServerVersion NOT LIKE '8.%'

OPEN ServerList 
FETCH NEXT FROM ServerList INTO @ServerName

WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQL = '
		INSERT INTO msdb..ConnectionDetails 
		SELECT *  
			FROM OPENROWSET(''SQLNCLI'', ''Server='+@ServerName+';Trusted_Connection=yes;'',''  
			   SELECT 
			@@SERVERNAME AS InstanceName,
			host_name, 
			DB_NAME(c.database_id) AS dbname,
			login_name, 
			DATEPART(MONTH,login_time) AS ConnectionMonth, 
			DATEPART(DAY,login_time) AS ConnectionDay, 
			DATEPART(HH,login_time) AS ConnectionHour,
			count(*) AS TotalConnections
		FROM 
			sys.dm_exec_sessions A
		INNER JOIN 
			sys.dm_exec_connections B ON A.session_id = b.session_Id
		INNER JOIN
			sys.dm_exec_requests C ON B.session_id = C.session_Id
		WHERE 
			host_name IS NOT NULL AND DB_NAME(c.database_id) NOT IN (''''master'''', ''''tempdb'''',''''model'''',''''msdb'''', ''''distribution'''')
			AND login_name NOT IN(''''_sqlsvc'''',''''_sqlmetrics'''',''''CROWLEY\_sqlsvc'''',''''CROWLEY\_sqlmetrics'''',''''CROWLEY\_sqlrepl'''')
		GROUP BY DATEPART(MONTH,login_time),DATEPART(DAY,login_time), DATEPART(HH,login_time), login_name, host_name, c.database_id'') AS a;'
		BEGIN TRY
			EXEC(@SQL)
			SET @SQL = ''
			FETCH NEXT FROM ServerList INTO @ServerName
		END TRY
		BEGIN CATCH
			PRINT(@ServerNAme)
			FETCH NEXT FROM ServerList INTO @ServerName
		END CATCH
	END

CLOSE ServerList
DEALLOCATE ServerList