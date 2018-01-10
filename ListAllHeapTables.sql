/*
A heap table is a table without a clusteres index. 
In common, using heap tables isn't best practice, only in some less szenarios a heap is acceptable.
In SQL Azure heap tables are not allowed, every table must have a clustered index. So if you want to migrate you SQL Server database to SQL Azure you have to define a clustered index or modify an existing index for all table, where no CI exists.
With this simple Transact-SQL statement you can query all heap tables.

Works with SQL Server 2005 and higher version with all editions.

Links:
- MSDN SQL Server Best Practices Article: 
  http://msdn.microsoft.com/en-us/library/cc917672.aspx
- MSDN Heap Structures
  http://msdn.microsoft.com/en-us/library/ms188270.aspx

*/

-- List all heap tables
SELECT SCH.name + '.' + TBL.name AS TableName
FROM sys.tables AS TBL
     INNER JOIN sys.schemas AS SCH
         ON TBL.schema_id = SCH.schema_id
     INNER JOIN sys.indexes AS IDX
         ON TBL.object_id = IDX.object_id
            AND IDX.type = 0 -- = Heap
ORDER BY TableName