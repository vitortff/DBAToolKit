-- verifica uso de �ndices
-- first select DB, then execute the task below
select object_name(dmi.object_id) as tbl_name, i.name as idx_name, dmi.* 
from sys.dm_db_index_usage_stats dmi join 
sys.indexes i on 
dmi.index_id = i.index_id and 
dmi.object_id = i.object_id
where database_id = DB_ID() 
--AND object_name(dmi.object_id) IN('estoque')
order by user_updates DESC
GO

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


sp_helpindex tellog


-- verifica desfragmenta��o 
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

SELECT OBJECT_NAME(A.object_id) AS [TableName],
a.index_id, name, avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats (DB_ID(),NULL, NULL, NULL, NULL) AS a
JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id =
b.index_id 
WHERE A.index_id <> 0
ORDER BY 4 DESC;

-- verifica parti��o

SELECT *
FROM sys.dm_db_index_physical_stats (DB_ID(),OBJECT_ID(N'HSHPES'), NULL , NULL, NULL);


--desfragmentando a pk (dbcc indexdefrag)
alter index IOCRGUA_PK on OCRGUA reorganize;

--desfragmentando a pk particionada
alter index ITELLOG_PK on TELLOG reorganize partition = 5

--reindexa��o on-line
alter index INCTA on NCT rebuild with (online=on, sort_in_tempdb=on);

--Rebuild only partition 
--ALTER INDEX IOCR_PK ON OCR REBUILD Partition = 2


--identifica indice
select * from sys.indexes where object_id = 1285579618

--atualiza estat�sticas
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
