DECLARE @SchemaName VARCHAR(100);
DECLARE @TableName VARCHAR(256);
DECLARE @IndexName VARCHAR(256);
DECLARE @ColumnName VARCHAR(100);
DECLARE @is_unique VARCHAR(100);
DECLARE @IndexTypeDesc VARCHAR(100);
DECLARE @FileGroupName VARCHAR(100);
DECLARE @is_disabled VARCHAR(100);
DECLARE @IndexOptions VARCHAR(MAX);
DECLARE @IndexColumnId INT;
DECLARE @IsDescendingKey INT;
DECLARE @IsIncludedColumn INT;
DECLARE @TSQLScripCreationIndex VARCHAR(MAX);
DECLARE @TSQLScripDisableIndex VARCHAR(MAX);
DECLARE @CreateDate VARCHAR(100) = '20201101'
DECLARE CursorIndex CURSOR
FOR SELECT SCHEMA_NAME(t.schema_id) [schema_name], 
           t.name, 
           ix.name,
           CASE
               WHEN ix.is_unique = 1
               THEN 'UNIQUE '
               ELSE ''
           END, 
           ix.type_desc,
           CASE
               WHEN ix.is_padded = 1
               THEN 'PAD_INDEX = ON, '
               ELSE 'PAD_INDEX = OFF, '
           END + CASE
                     WHEN ix.allow_page_locks = 1
                     THEN 'ALLOW_PAGE_LOCKS = ON, '
                     ELSE 'ALLOW_PAGE_LOCKS = OFF, '
                 END + CASE
                           WHEN ix.allow_row_locks = 1
                           THEN 'ALLOW_ROW_LOCKS = ON, '
                           ELSE 'ALLOW_ROW_LOCKS = OFF, '
                       END + CASE
                                 WHEN INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1
                                 THEN 'STATISTICS_NORECOMPUTE = ON, '
                                 ELSE 'STATISTICS_NORECOMPUTE = OFF, '
                             END + CASE
                                       WHEN ix.ignore_dup_key = 1
                                       THEN 'IGNORE_DUP_KEY = ON, '
                                       ELSE 'IGNORE_DUP_KEY = OFF, '
                                   END + 'SORT_IN_TEMPDB = OFF, FILLFACTOR =' + CAST(ix.fill_factor AS VARCHAR(3)) AS IndexOptions, 
           ix.is_disabled, 
           FILEGROUP_NAME(ix.data_space_id) FileGroupName
    FROM sys.tables t
         INNER JOIN sys.indexes ix ON t.object_id = ix.object_id
         INNER JOIN sys.objects o ON ix.object_id = o.object_id
    WHERE ix.type > 0
          AND ix.is_primary_key = 0
          AND ix.is_unique_constraint = 0 --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName
          AND t.is_ms_shipped = 0
          AND t.name <> 'sysdiagrams'
          AND o.create_date > @Createdate
    ORDER BY SCHEMA_NAME(t.schema_id), 
             t.name, 
             ix.name;
OPEN CursorIndex;
FETCH NEXT FROM CursorIndex INTO @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions, @is_disabled, @FileGroupName;
WHILE(@@fetch_status = 0)
    BEGIN
        DECLARE @IndexColumns VARCHAR(MAX);
        DECLARE @IncludedColumns VARCHAR(MAX);
        SET @IndexColumns = '';
        SET @IncludedColumns = '';
        DECLARE CursorIndexColumn CURSOR
        FOR SELECT col.name, 
                   ixc.is_descending_key, 
                   ixc.is_included_column
            FROM sys.tables tb
                 INNER JOIN sys.indexes ix ON tb.object_id = ix.object_id
                 INNER JOIN sys.index_columns ixc ON ix.object_id = ixc.object_id
                                                     AND ix.index_id = ixc.index_id
                 INNER JOIN sys.columns col ON ixc.object_id = col.object_id
                                               AND ixc.column_id = col.column_id
            WHERE ix.type > 0
                  AND (ix.is_primary_key = 0
                       OR ix.is_unique_constraint = 0)
                  AND SCHEMA_NAME(tb.schema_id) = @SchemaName
                  AND tb.name = @TableName
                  AND ix.name = @IndexName
            ORDER BY ixc.index_column_id;
        OPEN CursorIndexColumn;
        FETCH NEXT FROM CursorIndexColumn INTO @ColumnName, @IsDescendingKey, @IsIncludedColumn;
        WHILE(@@fetch_status = 0)
            BEGIN
                IF @IsIncludedColumn = 0
                    SET @IndexColumns = @IndexColumns + @ColumnName + CASE
                                                                          WHEN @IsDescendingKey = 1
                                                                          THEN ' DESC, '
                                                                          ELSE ' ASC, '
                                                                      END;
                    ELSE
                    SET @IncludedColumns = @IncludedColumns + @ColumnName + ', ';
                FETCH NEXT FROM CursorIndexColumn INTO @ColumnName, @IsDescendingKey, @IsIncludedColumn;
            END;
        CLOSE CursorIndexColumn;
        DEALLOCATE CursorIndexColumn;
        SET @IndexColumns = SUBSTRING(@IndexColumns, 1, LEN(@IndexColumns) - 1);
        SET @IncludedColumns = CASE
                                   WHEN LEN(@IncludedColumns) > 0
                                   THEN SUBSTRING(@IncludedColumns, 1, LEN(@IncludedColumns) - 1)
                                   ELSE ''
                               END;
        --  print @IndexColumns
        --  print @IncludedColumns

        SET @TSQLScripCreationIndex = '';
        SET @TSQLScripDisableIndex = '';
        SET @TSQLScripCreationIndex = 'CREATE ' + @is_unique + @IndexTypeDesc + ' INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '(' + @IndexColumns + ') ' + CASE
                                                                                                                                                                                                                     WHEN LEN(@IncludedColumns) > 0
                                                                                                                                                                                                                     THEN CHAR(13) + 'INCLUDE (' + @IncludedColumns + ')'
                                                                                                                                                                                                                     ELSE ''
                                                                                                                                                                                                                 END + CHAR(13) + 'WITH (' + @IndexOptions + ') ON ' + QUOTENAME(@FileGroupName) + ';';
        IF @is_disabled = 1
            SET @TSQLScripDisableIndex = CHAR(13) + 'ALTER INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + ' DISABLE;' + CHAR(13);
        PRINT @TSQLScripCreationIndex;
        PRINT @TSQLScripDisableIndex;
        FETCH NEXT FROM CursorIndex INTO @SchemaName, @TableName, @IndexName, @is_unique, @IndexTypeDesc, @IndexOptions, @is_disabled, @FileGroupName;
    END;
CLOSE CursorIndex;
DEALLOCATE CursorIndex;