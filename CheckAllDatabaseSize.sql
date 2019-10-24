SELECT [Database Name] = DB_NAME(database_id),

       [Type] = CASE WHEN Type_Desc = 'ROWS' THEN 'Data File(s)'

                     WHEN Type_Desc = 'LOG'  THEN 'Log File(s)'

                     ELSE Type_Desc END,

       [Size in MB] = CAST( ((SUM(Size)* 8) / 1024.0) AS DECIMAL(18,2) )

FROM   sys.master_files

-- Uncomment if you need to query for a particular database

-- WHERE      database_id = DB_ID(‘Database Name’)

GROUP BY      GROUPING SETS

              (

                     (DB_NAME(database_id), Type_Desc),

                     (DB_NAME(database_id))

              )

ORDER BY      DB_NAME(database_id), Type_Desc DESC

GO