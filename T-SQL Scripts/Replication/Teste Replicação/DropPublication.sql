DECLARE @publication AS sysname
DECLARE @publicationDB    AS sysname
SET @publication = N'Amd_Prev_Hmp_ATH_Publication' 
SET @publicationDB = N'Amd_Prev_Hmp_ATH'

-- Remove the merge publication.
USE Amd_Prev_Hmp_ATH
EXEC sp_dropmergepublication @publication = @publication;

-- Remove replication objects from the database.
USE master
EXEC sp_replicationdboption 
  @dbname = @publicationDB, 
  @optname = N'merge publish', 
  @value = N'false'
GO
