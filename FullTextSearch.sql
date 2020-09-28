/*
O FTS possui um arquivo de log de erros localizado em 
P:\SRVSQLPRD12\MSSQL10_50.ISTCRP2\MSSQL\Log\SQLFT*
*/

SELECT DB_NAME(ftsac.[database_id]) AS [db_name]
    ,DATABASEPROPERTYEX(DB_NAME(ftsac.[database_id]), 'IsFulltextEnabled') AS [is_ft_enabled]
    ,ftsac.[name] AS [catalog_name]
    ,mfs.[name] AS [ft_catalog_file_logical_name]
    ,mfs.[physical_name] AS [ft_catalog_file_physical_name]
    ,OBJECT_NAME(ftsip.[table_id]) AS [table_name]
    ,FULLTEXTCATALOGPROPERTY(ftsac.[name], 'IndexSize') AS [ft_catalog_logical_index_size_in_mb]
    ,FULLTEXTCATALOGPROPERTY(ftsac.[name], 'AccentSensitivity') AS [is_accent_sensitive]
    ,FULLTEXTCATALOGPROPERTY(ftsac.[name], 'UniqueKeyCount') AS [unique_key_count]
    ,ftsac.[row_count_in_thousands]
    ,ftsip.[is_clustered_index_scan]
    ,ftsip.[range_count]
    ,FULLTEXTCATALOGPROPERTY(ftsac.[name], 'ImportStatus') AS [import_status]
    ,ftsac.[status_description] AS [current_state_of_fts_catalog]
    ,ftsac.[is_paused]
    ,(
        SELECT CASE FULLTEXTCATALOGPROPERTY(ftsac.[name], 'PopulateStatus')
                WHEN 0
                    THEN 'Idle'
                WHEN 1
                    THEN 'Full Population In Progress'
                WHEN 2
                    THEN 'Paused'
                WHEN 3
                    THEN 'Throttled'
                WHEN 4
                    THEN 'Recovering'
                WHEN 5
                    THEN 'Shutdown'
                WHEN 6
                    THEN 'Incremental Population In Progress'
                WHEN 7
                    THEN 'Building Index'
                WHEN 8
                    THEN 'Disk Full. Paused'
                WHEN 9
                    THEN 'Change Tracking'
                END
        ) AS [population_status]
    ,ftsip.[population_type_description] AS [ft_catalog_population_type]
    ,ftsip.[status_description] AS [status_of_population]
    ,ftsip.[completion_type_description]
    ,ftsip.[queued_population_type_description]
    ,ftsip.[start_time]
    ,DATEADD(ss, FULLTEXTCATALOGPROPERTY(ftsac.[name], 'PopulateCompletionAge'), '1/1/1990') AS [last_populated]
FROM [sys].[dm_fts_active_catalogs] ftsac
INNER JOIN [sys].[databases] dbs
    ON dbs.[database_id] = ftsac.[database_id]
LEFT JOIN [sys].[master_files] mfs
    ON mfs.[database_id] = dbs.[database_id]
        AND mfs.[physical_name] NOT LIKE '%.mdf'
        AND mfs.[physical_name] NOT LIKE '%.ndf'
        AND mfs.[physical_name] NOT LIKE '%.ldf'
CROSS JOIN [sys].[dm_fts_index_population] ftsip
WHERE ftsac.[database_id] = ftsip.[database_id]
    AND ftsac.[catalog_id] = ftsip.[catalog_id];

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