/*
O FTS possui um arquivo de log de erros localizado em 
P:\SRVSQLPRD12\MSSQL10_50.ISTCRP2\MSSQL\Log\SQLFT*
*/

--Parar o processo de atualização do índice FT
--ALTER FULLTEXT INDEX ON PES
--STOP POPULATION;

--Pausar o processo de atualização do índice FT
--ALTER FULLTEXT INDEX ON PES
--PAUSE POPULATION;

--Recomeçar o processo de atualização do índice FT
--ALTER FULLTEXT INDEX ON PES
--RESUME POPULATION;

--Iniciar uma população completa
--ALTER FULLTEXT INDEX ON PES
--START FULL POPULATION;

--Iniciar uma população incremental
--ALTER FULLTEXT INDEX ON PES
--START INCREMENTAL POPULATION;

--Reorganizar o Catálogo (TODOS OS ÍNDICES TAMBÉM)
--ALTER FULLTEXT CATALOG CTLPESDIN
--REORGANIZE;

--Reconstruir o Catálogo (TODOS OS ÍNDICES TAMBÉM)
--ALTER FULLTEXT CATALOG CTLPESDIN
--REBUILD;

SELECT * FROM SYS.fulltext_catalogs
SELECT * FROM SYS.fulltext_indexes
SELECT * FROM SYS.fulltext_index_catalog_usages
SELECT * FROM SYS.fulltext_index_fragments
SELECT * FROM sys.data_spaces

SELECT
  SCHEMA_NAME(t.schema_id) AS user_table_schema,
  OBJECT_NAME(fti.object_id) AS user_table,
  fti.object_id AS user_table_name,
  it.name AS internal_table_name,
  it.object_id AS internal_table_id,
  it.internal_type_desc
FROM sys.internal_tables AS it
INNER JOIN sys.fulltext_indexes AS fti 
  ON it.parent_id = fti.object_id
INNER JOIN sys.tables t
  ON t.object_id = fti.object_id
WHERE it.internal_type_desc LIKE 'FULLTEXT%'
ORDER BY user_table;

--Consulta para Testar o FTS
--SELECT * FROM LGRGEO
--WHERE FREETEXT(LgrGeoNom,'AV DR TIMOTEO PENTEADO')