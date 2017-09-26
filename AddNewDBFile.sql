USE master;
GO
-- Get the SQL Server datafile os path
DECLARE @osdata_path nvarchar(256);
SET @osdata_path = (
SELECT 
SUBSTRING
(physical_name, 1, 
CHARINDEX(N'FGITEL_Indx.ndf', 
LOWER(physical_name)) - 1)
FROM master.sys.master_files 
WHERE database_id = DB_ID('SIOPMCRP') AND file_id = 26
);
EXECUTE (
'ALTER DATABASE [SIOPMCRP] 
ADD FILE 
( 
	NAME = TEL_Indx, 
	FILENAME = '''+ @osdata_path + 'TEL_Indx.ndf'' , 
	SIZE = 5120000KB , 
	FILEGROWTH = 0
) 
TO FILEGROUP [FGITEL]'
);
GO

