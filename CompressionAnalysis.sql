SELECT st.name, 
       st.object_id, 
       sp.partition_id, 
       sp.partition_number, 
       sp.data_compression, 
       sp.data_compression_desc
FROM sys.partitions SP
     INNER JOIN sys.tables ST ON st.object_id = sp.object_id
WHERE data_compression = 0;


/*
To compute U, use the statistics in the DMV sys.dm_db_index_operational_stats. 
U is the ratio (expressed in percent) of updates performed on a table or index
 to the sum of all operations (scans + DMLs + lookups) on that table or index. 
 The following query reports U for each table and index in the database. 
*/
 
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.leaf_update_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Update],
    8 * a.used_pages AS SizeKB
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o ON o.object_id = i.object_id
JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
JOIN sys.partitions AS p ON p.object_id = x.object_id AND p.index_id = x.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
AND o.name IN (SELECT st.name FROM sys.partitions SP
     INNER JOIN sys.tables st ON st.object_id = sp.object_id
WHERE data_compression = 0)
ORDER BY [Percent_Update] ASC

/*
To compute S, use the statistics in the DMV sys.dm_db_index_operational_stats. 
S is the ratio (expressed in percent) of scans performed on a table or index 
to the sum of all operations (scans + DMLs + lookups) on that table or index. 
In other words, S represents how heavily the table or index is scanned. 
The following query reports S for each table, index, and partition in the database.
*/
 
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.range_scan_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Scan],
			8 * a.used_pages AS SizeKB
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o ON o.object_id = i.object_id
JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
JOIN sys.partitions AS p ON p.object_id = x.object_id AND p.index_id = x.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
AND o.name IN (SELECT st.name FROM sys.partitions SP
     INNER JOIN sys.tables st ON st.object_id = sp.object_id
WHERE data_compression = 0)
ORDER BY [Percent_Scan] DESC