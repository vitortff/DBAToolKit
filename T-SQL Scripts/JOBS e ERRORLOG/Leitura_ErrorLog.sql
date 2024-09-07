--Procedures para leitura dos arquivos de
--log da Instância de SQL
sp_enumerrorlogs 
sp_readerrorlog 6


--Utilizando as duas stored procedures para fazer uma busca nos arquivos
--de LOG do SQL SERVER
DECLARE @TSQL  NVARCHAR(2000)
DECLARE @lC    INT


CREATE TABLE #TempLog (
      LogDate     DATETIME,
      ProcessInfo NVARCHAR(50),
      [Text] NVARCHAR(MAX))


CREATE TABLE #logF (
      ArchiveNumber     INT,
      LogDate           DATETIME,
      LogSize           INT
)

INSERT INTO #logF  
EXEC sp_enumerrorlogs
SELECT @lC = MIN(ArchiveNumber) FROM #logF


WHILE @lC IS NOT NULL
BEGIN
      INSERT INTO #TempLog
      EXEC sp_readerrorlog @lC
      SELECT @lC = MIN(ArchiveNumber) FROM #logF
      WHERE ArchiveNumber > @lC
END

SELECT * FROM #TempLog

--Depois de carregarmos os arquivos de Log em uma tabela, podemos fazer um estudo
--muito mais detalhado do que acontece em nossa instância.

--Podemos contar as tentativas de Logon que falharam
SELECT 
	[Text],
	COUNT([Text]) AS Number_Of_Attempts
FROM 
	#TempLog 
WHERE
	[Text] LIKE '%failed%' AND ProcessInfo = 'LOGON']
 GROUP BY
	[Text]


--Quando foi o último Logon com sucesso?
--Podemos verificar essa informação, que é útil para descobrirmos
--quais logins não são mais utilizados.
SELECT DISTINCT 
	MAX(logdate) AS last_login, 
	[Text]
FROM 
	#TempLog
WHERE
	ProcessInfo = 'LOGON'
AND
	[Text] LIKE '%SUCCEEDED%']
AND
	[Text] NOT LIKE '%NT AUTHORITY%'
GROUP BY 
	[Text]

DROP TABLE #TempLog
DROP TABLE #logF