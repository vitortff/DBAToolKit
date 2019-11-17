SELECT object_schema_name(stats.object_id) AS Object_Schema_Name,
    object_name(stats.object_id) AS Object_Name,
    indexes.name AS Index_Name, 
    STATS_DATE(stats.object_id, stats.stats_id) AS Stats_Last_Update 
FROM sys.stats
JOIN sys.indexes
    ON stats.object_id = indexes.object_id
    AND stats.name = indexes.name
ORDER BY Stats_Last_Update DESC