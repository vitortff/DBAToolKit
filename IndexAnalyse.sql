-- verifica desfragmentação 
SELECT 
'ALTER INDEX ['+name+'] ON ['+OBJECT_NAME(A.object_id)+'] REBUILD PARTITION = ALL WITH ( FILLFACTOR = 80, 
PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, 
ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, ONLINE = ON, 
SORT_IN_TEMPDB = ON )', avg_fragmentation_in_percent
--TOP 10 OBJECT_NAME(A.object_id) AS [TableName],
--a.index_id, name, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(),NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id =
b.index_id 
WHERE A.index_id <> 0
ORDER BY avg_fragmentation_in_percent DESC;



---Lista os índices NÃO UTILIZADOS em um banco de dados
WITH IndexUsage AS (
    SELECT 
        SCHEMA_NAME(o.schema_id) AS SchemaName, -- Nome do schema
        OBJECT_NAME(i.object_id) AS TableName,
        i.name AS IndexName,
        i.type_desc AS IndexType,
        o.create_date AS IndexCreationDate, -- Adicionando a data de criação do índice
        u.user_seeks,
        u.user_scans,
        u.user_lookups,
        u.user_updates,
        u.system_seeks,
        u.system_scans,
        u.system_lookups,
        u.last_user_seek,
        u.last_user_scan,
        u.last_user_lookup,
        u.last_user_update
    FROM 
        sys.indexes i
    LEFT JOIN 
        sys.dm_db_index_usage_stats u
    ON 
        i.object_id = u.object_id AND i.index_id = u.index_id
    INNER JOIN 
        sys.objects o
    ON 
        i.object_id = o.object_id
    WHERE 
        i.is_disabled = 0 -- Índices habilitados
        AND i.is_hypothetical = 0 -- Exclui índices "hipotéticos" usados para tuning
        AND i.is_primary_key = 0 -- Exclui índices de chave primária
        AND i.is_unique = 0 -- Exclui índices únicos
)
SELECT 
    SchemaName,
    TableName,
    IndexName,
    IndexType,
    IndexCreationDate, -- Exibindo a data de criação do índice
    ISNULL(user_seeks, 0) AS UserSeeks,
    ISNULL(user_scans, 0) AS UserScans,
    ISNULL(user_lookups, 0) AS UserLookups,
    ISNULL(user_updates, 0) AS UserUpdates,		
    ISNULL(system_seeks, 0) AS SystemSeeks,
    ISNULL(system_scans, 0) AS SystemScans,
    ISNULL(system_lookups, 0) AS SystemLookups,
    last_user_seek,
    last_user_scan,
    last_user_lookup,
    last_user_update,
    'ALTER INDEX [' + IndexName + '] ON [' + SchemaName + '].[' + TableName + '] DISABLE;' AS DisableIndexScript -- Script para desabilitar o índice com schema
FROM 
    IndexUsage
WHERE 
    ISNULL(user_seeks, 0) = 0
    AND ISNULL(user_scans, 0) = 0
    AND ISNULL(user_lookups, 0) = 0
ORDER BY 
    UserUpdates DESC;





--Verifica índices duplicados e utilização de cada um
WITH IndexColumns AS (
    SELECT 
        OBJECT_NAME(i.object_id) AS TableName,
        i.name AS IndexName,
        c.name AS ColumnName,
        ic.index_id,
        ic.object_id
    FROM 
        sys.indexes i
    INNER JOIN 
        sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN 
        sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE 
        i.is_primary_key = 0 -- Ignorar índices de chave primária
        AND i.is_unique = 0 -- Ignorar índices únicos
        AND i.type IN (1, 2) -- Apenas clustered e nonclustered
),
IndexDefinitions AS (
    SELECT 
        TableName,
        IndexName,
        index_id,
        object_id,
        STRING_AGG(ColumnName, ',') WITHIN GROUP (ORDER BY ColumnName) AS ColumnList
    FROM 
        IndexColumns
    GROUP BY 
        TableName, IndexName, index_id, object_id
),
DuplicateIndexes AS (
    SELECT 
        t1.TableName,
        t1.IndexName AS DuplicateIndex,
        t2.IndexName AS OriginalIndex,
        t1.ColumnList,
        t1.index_id AS DuplicateIndexId,
        t2.index_id AS OriginalIndexId,
        t1.object_id AS TableObjectId
    FROM 
        IndexDefinitions t1
    INNER JOIN 
        IndexDefinitions t2 
        ON t1.TableName = t2.TableName 
        AND t1.ColumnList = t2.ColumnList
        AND t1.IndexName <> t2.IndexName
),
IndexUsage AS (
    SELECT 
        OBJECT_NAME(u.object_id) AS TableName,
        i.name AS IndexName,
        ISNULL(u.user_seeks, 0) AS UserSeeks,
        ISNULL(u.user_scans, 0) AS UserScans,
        ISNULL(u.user_lookups, 0) AS UserLookups,
        ISNULL(u.system_seeks, 0) AS SystemSeeks,
        ISNULL(u.system_scans, 0) AS SystemScans,
        ISNULL(u.system_lookups, 0) AS SystemLookups,
        ISNULL(u.user_seeks, 0) + ISNULL(u.user_scans, 0) + ISNULL(u.user_lookups, 0) AS TotalUserOperations,
        ISNULL(u.system_seeks, 0) + ISNULL(u.system_scans, 0) + ISNULL(u.system_lookups, 0) AS TotalSystemOperations,
        u.last_user_seek,
        u.last_user_scan,
        u.last_user_lookup
    FROM 
        sys.indexes i
    LEFT JOIN 
        sys.dm_db_index_usage_stats u 
        ON i.object_id = u.object_id AND i.index_id = u.index_id
    WHERE 
        i.is_primary_key = 0 -- Ignorar índices de chave primária
        AND i.is_unique = 0 -- Ignorar índices únicos
)
SELECT DISTINCT
    di.TableName,
    di.DuplicateIndex,
    di.OriginalIndex,
    di.ColumnList,
    iu1.TotalUserOperations AS DuplicateIndexUsage,
	iu1.UserSeeks AS DuplicateIndexSeeks,
	iu1.UserScans AS DuplicateIndexScans,
	iu1.UserLookups AS DuplicateIndexLookups,
    iu1.last_user_seek AS DuplicateLastUserSeek,
    iu1.last_user_scan AS DuplicateLastUserScan,
    iu1.last_user_lookup AS DuplicateLastUserLookup,
    iu2.TotalUserOperations AS OriginalIndexUsage,
	iu2.UserSeeks AS OriginalIndexSeeks,
	iu2.UserScans AS OriginalIndexScans,
	iu2.UserLookups AS OriginalIndexLookups,
    iu2.last_user_seek AS OriginalLastUserSeek,
    iu2.last_user_scan AS OriginalLastUserScan,
    iu2.last_user_lookup AS OriginalLastUserLookup
FROM 
    DuplicateIndexes di
LEFT JOIN 
    IndexUsage iu1 
    ON di.TableObjectId = OBJECT_ID(iu1.TableName) AND di.DuplicateIndex = iu1.IndexName
LEFT JOIN 
    IndexUsage iu2 
    ON di.TableObjectId = OBJECT_ID(iu2.TableName) AND di.OriginalIndex = iu2.IndexName
ORDER BY 
    di.TableName, di.ColumnList;


--Verifica uso de indices criados pelo DTA
SELECT 
	DB_NAME() AS DatabaseName,
	OBJECT_NAME(i.object_id) AS TableName,
	name AS IndexName,
	dmi.user_seeks,
	dmi.last_user_seek,
	dmi.user_scans,
	dmi.last_user_scan,
	dmi.user_lookups,
	dmi.last_user_lookup,
	dmi.user_updates,
	dmi.last_user_update
from 
	sys.dm_db_index_usage_stats dmi 
JOIN 
	sys.indexes i 
ON 
	dmi.index_id = i.index_id 
AND 
	dmi.object_id = i.object_id
--WHERE 
--	name LIKE '_dta%'
ORDER by dmi.last_user_seek ASC


SELECT OBJECT_NAME(A.object_id) AS [TableName],
a.index_id, name, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(),NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id =
b.index_id 
WHERE A.index_id <> 0
ORDER BY 4 DESC;

-- verifica partição
SELECT *
FROM sys.dm_db_index_physical_stats (DB_ID(),OBJECT_ID(N'HSHPES'), NULL , NULL, NULL);


--identifica indice
select * from sys.indexes where object_id = 1285579618

--atualiza estatísticas
update statistics IU

SELECT name AS index_name, 
    STATS_DATE(object_id, index_id) AS statistics_update_date
FROM sys.indexes 
WHERE object_id = OBJECT_ID('QUA');
GO

sp_updatestats -- all objects in sys.indexes

sp_autostats [ocr] -- to view information

-- view no index usage
SELECT TOP 10 *
FROM sys.dm_db_missing_index_group_stats
--WHERE group_handle in (38066)
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)DESC;

SELECT migs.group_handle, mid.*, migs.user_seeks, migs.last_user_seek, 
migs.user_scans, migs.last_user_scan,migs.*
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle) 
--order by object_id
order by 
migs.user_seeks DESC
--migs.avg_user_impact DESC
--migs.last_user_seek desc, migs.last_user_scan desc
--WHERE migs.group_handle in (36082, 36115, 36085, 36078, 36080);
go
sp_helpindex iu

-- Returns information about all the data pages that are currently in the SQL Server buffer pool
SELECT count(*)AS cached_pages_count 
    ,name ,index_id 
FROM sys.dm_os_buffer_descriptors AS bd 
    INNER JOIN 
    (
        SELECT object_name(object_id) AS name 
            ,index_id ,allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND (au.type = 1 OR au.type = 3)
        UNION ALL
        SELECT object_name(object_id) AS name   
            ,index_id, allocation_unit_id
        FROM sys.allocation_units AS au
            INNER JOIN sys.partitions AS p 
                ON au.container_id = p.hobt_id 
                    AND au.type = 2
    ) AS obj 
        ON bd.allocation_unit_id = obj.allocation_unit_id
WHERE database_id = db_id()
GROUP BY name, index_id 
ORDER BY cached_pages_count DESC, name
