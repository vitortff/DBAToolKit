DECLARE @ParentTable NVARCHAR(128) = 'Processo';  -- Nome da tabela pai
DECLARE @ParentSchema NVARCHAR(128) = 'dbo';             -- Esquema da tabela pai
DECLARE @ParentIDs NVARCHAR(MAX) = '';            -- Conjunto de IDs da tabela pai (lista separada por vírgulas)
DECLARE @ParentKeyColumn NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX) = '';

-- 1. Obter o nome da coluna que é chave primária da tabela pai
SELECT 
	@ParentKeyColumn = c.name
FROM 
	sys.key_constraints kc
INNER JOIN 
	sys.index_columns ic 
ON 
	kc.unique_index_id = ic.index_id 
AND 
	kc.parent_object_id = ic.object_id
INNER JOIN 
	sys.columns c 
ON 
	c.object_id = ic.object_id 
AND 
	c.column_id = ic.column_id
INNER JOIN 
	sys.objects o ON kc.parent_object_id = o.object_id
WHERE 
	o.name = @ParentTable
AND 
	kc.type = 'PK';

-- 2. Construir os comandos DELETE para as tabelas filhas, baseado nas chaves estrangeiras
SELECT @SQL = @SQL + '
DELETE FROM [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + parentTable.name + ']
WHERE [' + parentTable.name + '].[' + fkCols.name + '] IN (
    SELECT [' + @ParentKeyColumn + '] FROM [' + @ParentSchema + '].[' + @ParentTable + ']
    WHERE [' + @ParentKeyColumn + '] IN (' + @ParentIDs + ')
);'
FROM 
	sys.foreign_keys fk
INNER JOIN 
	sys.objects parentTable 
ON 
	fk.parent_object_id = parentTable.object_id
INNER JOIN 
	sys.foreign_key_columns fkc 
ON 
	fk.object_id = fkc.constraint_object_id
INNER JOIN 
	sys.columns fkCols 
ON 
	fkCols.object_id = fkc.parent_object_id 
AND 
	fkCols.column_id = fkc.parent_column_id
WHERE 
	fk.referenced_object_id = OBJECT_ID(@ParentSchema + '.' + @ParentTable);

-- 3. Adicionar o comando DELETE para a tabela pai
SET @SQL = @SQL + '
DELETE FROM [' + @ParentSchema + '].[' + @ParentTable + ']
WHERE [' + @ParentTable + '].[' + @ParentKeyColumn + '] IN (' + @ParentIDs + ');';

-- 4. Exibir o SQL gerado
PRINT @SQL;