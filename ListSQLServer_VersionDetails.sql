DECLARE @ProductVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
DECLARE @ProductLevel NVARCHAR(128) = CAST(SERVERPROPERTY('ProductLevel') AS NVARCHAR(128));
DECLARE @Edition NVARCHAR(128) = CAST(SERVERPROPERTY('Edition') AS NVARCHAR(128));
DECLARE @ProductUpdateLevel NVARCHAR(128) = CAST(SERVERPROPERTY('ProductUpdateLevel') AS NVARCHAR(128));
DECLARE @MajorVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductMajorVersion') AS NVARCHAR(128));
DECLARE @MinorVersion NVARCHAR(128) = CAST(SERVERPROPERTY('ProductMinorVersion') AS NVARCHAR(128));
DECLARE @BuildNumber NVARCHAR(128) = CAST(SERVERPROPERTY('ProductBuild') AS NVARCHAR(128));

DECLARE @VersionDescription NVARCHAR(128);

SET @VersionDescription = CASE 
    WHEN @MajorVersion = '8' THEN 'SQL Server 2000'
    WHEN @MajorVersion = '9' THEN 'SQL Server 2005'
    WHEN @MajorVersion = '10' AND @MinorVersion = '0' THEN 'SQL Server 2008'
    WHEN @MajorVersion = '10' AND @MinorVersion = '50' THEN 'SQL Server 2008 R2'
    WHEN @MajorVersion = '11' THEN 'SQL Server 2012'
    WHEN @MajorVersion = '12' THEN 'SQL Server 2014'
    WHEN @MajorVersion = '13' THEN 'SQL Server 2016'
    WHEN @MajorVersion = '14' THEN 'SQL Server 2017'
    WHEN @MajorVersion = '15' THEN 'SQL Server 2019'
    WHEN @MajorVersion = '16' THEN 'SQL Server 2022'
    ELSE 'Unknown SQL Server version'
END;

SELECT 
    @VersionDescription AS [SQL Server Version],
    @ProductVersion AS [BuildVersion],
    @ProductLevel AS [ServicePack],
    @Edition AS [Edition],
    @ProductUpdateLevel AS [CU],
    @MajorVersion AS [MajorVersion],
    @MinorVersion AS [MinorVersion],
    @BuildNumber AS [BuildNumber]
ORDER BY 
	1 ASC