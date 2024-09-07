--Tabela temporaria que ira guardar os usuários orfãs encontrados
CREATE TABLE #temp 
(
	DatabaseName NVARCHAR(50),
	UserName NVARCHAR(50)
)

--Através da stored procedure SP_MSforeachDB, executaremos uma query que irá mostrar
--quais os usuários que estão em orfãos em cada database
DECLARE @sql NVARCHAR(500)
SET @sql='SELECT ''?'' AS DBName
, name AS UserName
FROM [?]..sysusers
WHERE (sid  IS NOT NULL AND sid <> 0x0)
AND suser_sname(sid) IS NULL AND
(issqlrole <> 1) AND 
(isapprole <> 1) AND 
(name <> ''INFORMATION_SCHEMA'') AND 
(name <> ''guest'') AND 
(name <> ''sys'') AND 
(name <> ''dbo'') AND 
(name <> ''system_function_schema'')
ORDER BY name
'
--Insert dos resultados da stored procedure SP_MSforeachDB na tabela #temp
INSERT INTO #temp
EXEC SP_MSforeachDB @sql

--Verificando os resultados
SELECT * FROM #temp
DROP TABLE #temp

--Stored Procedure utilizada para a correção dos usuários orfãos encontrados
SP_CHANGE_USERS_LOGIN 'UPDATE_ONE','Alexandre','Alexandre'
