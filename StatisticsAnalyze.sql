--Desabilitar o AUTO UPDATE STATISTICS de uma tabela especifica
DECLARE @TableName SYSNAME = '';
DECLARE @SchemaName SYSNAME = 'dbo';
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL += 
    'UPDATE STATISTICS [' + @SchemaName + '].[' + @TableName + '] ([' + s.name + ']) WITH NORECOMPUTE;' + CHAR(13)
FROM sys.stats s
WHERE s.object_id = OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName));

PRINT @SQL;
-- Para executar diretamente, descomente a linha abaixo:
-- EXEC sp_executesql @SQL;