-- Ultima altera��o da senha de SA
--
--
USE Master
GO
SELECT [name], sid, create_date, modify_date
FROM sys.sql_logins
WHERE [name] = 'sa'
GO