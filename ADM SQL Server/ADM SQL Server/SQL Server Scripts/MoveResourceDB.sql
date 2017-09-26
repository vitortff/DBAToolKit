-- select * from sys.master_files

-- PAY ATTENTION: Only for you know, Just remove remarks if you have problems ou need some migration

/*
ALTER DATABASE master 
MODIFY FILE( NAME = master , FILENAME = 'S:\MSSQL$ISTOPR1\MSSQL.1\MSSQL\DATA\master.mdf' )
go
ALTER DATABASE master 
MODIFY FILE( NAME = mastlog , FILENAME = 'S:\MSSQL$ISTOPR1\MSSQL.1\MSSQL\DATA\mastlog.ldf' )
go

-- NET START MSSQL$ISTOPR1 /f/T3608

USE master
GO
ALTER DATABASE mssqlsystemresource
MODIFY FILE
(
    NAME = data,
    FILENAME = N'S:\MSSQL$ISTOPR1\MSSQL.1\MSSQL\DATA\mssqlsystemresource.mdf'
);
GO
ALTER DATABASE mssqlsystemresource
MODIFY FILE
(
    NAME = log,
    FILENAME = N'S:\MSSQL$ISTOPR1\MSSQL.1\MSSQL\DATA\mssqlsystemresource.ldf'
);
GO


-- MSSQLSERVER /f /T3608

ALTER DATABASE mssqlsystemresource SET READ_ONLY
*/