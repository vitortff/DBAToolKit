--Executar leitura de um arquivo de TRACE
SELECT * FROM ::fn_trace_gettable('C:\Trace\Trace_SQL.trc', default)
order by starttime
GO


--Executar leitura de um arquivo de TRACE
SELECT HostName,SPID,DatabaseName, TextData,Reads,Writes,CPU 
FROM ::fn_trace_gettable('C:\Users\te46840\Desktop\TraceFile.trc', default)
where TextData like '%select%'
order by 5 desc
GO
