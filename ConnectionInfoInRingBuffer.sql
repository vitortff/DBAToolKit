Declare @LanguageID int;

Select @LanguageID = lcid
From sys.syslanguages
Where name = @@Language;

WITH RingBufferXML
As (SELECT CAST(record as xml) AS RecordXML
	FROM sys.dm_os_ring_buffers
	WHERE ring_buffer_type= 'RING_BUFFER_CONNECTIVITY'),
RingBufferConnectivity
As (SELECT x.y.value('(/Record/@id)[1]', 'int') AS [RecordID],
		x.y.value('(/Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(max)') AS RecordType,
		x.y.value('(/Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') AS RecordTime,
		x.y.value('(/Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') AS Error,
		x.y.value('(/Record/ConnectivityTraceRecord/State)[1]', 'int') AS State,
		x.y.value('(/Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS SPID,
		x.y.value('(/Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(max)') AS RemoteHost,
		x.y.value('(/Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(max)') AS RemotePort,
		x.y.value('(/Record/ConnectivityTraceRecord/LocalHost)[1]', 'varchar(max)') AS LocalHost,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/TotalTime)[1]', 'int') AS TotalTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/EnqueueTime)[1]', 'int') AS EnqueueTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/NetWritesTime)[1]', 'int') AS NetWritesTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/NetReadsTime)[1]', 'int') AS NetReadsTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Ssl/TotalTime)[1]', 'int') AS SslTotalTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/Sspi/TotalTime)[1]', 'int') AS SspiTotalTime,
		x.y.value('(/Record/ConnectivityTraceRecord/LoginTimersInMilliseconds/TriggerAndResGovTime)[1]', 'int') AS TriggerAndResGovTime
	FROM RingBufferXML
	CROSS APPLY RecordXML.nodes('//Record') AS x(y))
SELECT RBC.*, m.text
FROM RingBufferConnectivity RBC
LEFT JOIN sys.messages M ON
	RBC.Error = M.message_id AND M.language_id = @LanguageID
WHERE RBC.RecordType IN ('Error', 'LoginTimers')
ORDER BY RBC.RecordTime DESC;