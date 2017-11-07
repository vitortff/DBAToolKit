SET NOCOUNT ON

-- Store the XML data in a temporary table
SELECT CAST(xet.target_data as xml) as XMLDATA
INTO #SystemHealthSessionData
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xe
ON (xe.address = xet.event_session_address)
WHERE xe.name = 'system_health'

-- Get statistical information about all the errors reported
;WITH CTE_HealthSession (EventXML) AS
(
SELECT C.query('.') EventXML
FROM #SystemHealthSessionData a
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event') as T(C)
),

CTE_ErrorReported (EventTime, ErrorNum) AS
(
SELECT EventXML.value('(/event/@timestamp)[1]', 'datetime') as EventTime,
EventXML.value('(/event/data/value)[1]', 'int') as ErrorNum
FROM CTE_HealthSession
WHERE EventXML.value('(/event/@name)[1]', 'varchar(255)') = 'error_reported'
)
SELECT ErrorNum,
MAX(EventTime) as LastRecordedEvent,
MIN(EventTime) as FirstRecordedEvent,
COUNT(*) as Occurrences,
b.[text] as ErrDescription
FROM CTE_ErrorReported a
INNER JOIN sys.messages b
ON a.ErrorNum = b.message_id
WHERE b.language_id = SERVERPROPERTY('LCID')
GROUP BY a.ErrorNum,b.[text]

-- Get information about each of the errors reported
;WITH CTE_HealthSession (EventXML) AS
(
SELECT C.query('.') EventXML
FROM #SystemHealthSessionData a
CROSS APPLY a.XMLDATA.nodes('/RingBufferTarget/event') as T(C)
WHERE C.query('.').value('(/event/@name)[1]', 'varchar(255)') = 'error_reported'

)
SELECT
EventXML.value('(/event/@timestamp)[1]', 'datetime') as EventTime,
EventXML.value('(/event/data/value)[1]', 'int') as ErrNum,
EventXML.value('(/event/data/value)[2]', 'int') as ErrSeverity,
EventXML.value('(/event/data/value)[3]', 'int') as ErrState,
EventXML.value('(/event/data/value)[5]', 'varchar(max)') as ErrText,
EventXML.value('(/event/action/value)[2]', 'varchar(10)') as Session_ID
FROM CTE_HealthSession

-- Drop the temporary table
DROP TABLE #SystemHealthSessionData