/***************************
Script para migrar logins do SQL 70 para 2000 ou entre servidores SQL 2000

Artigo Original: http://support.microsoft.com/default.aspx?scid=http://support.microsoft.com:80/support/kb/articles/Q246/1/33.ASP&NoWebContent=1

Como utilizar :
Passo 1: Execute este script no servidor de origem. Será criada as procedures sp_hexadecimal e sp_help_revlogin

Passo 2: Após criar as procedures, execute a sp_help_revlogin no Query Analyzer do servidor de origem como exemplo:

EXEC master..sp_help_revlogin -- pega todos os logins do servidor

EXEC master..sp_help_revlogin 'loginname' - Pega um login específico

Passo 3: Execute o script gerado no servidor de destino

**************/

----- Begin Script, Create sp_help_revlogin procedure -----
USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar(256) OUTPUT
AS
DECLARE @charvalue varchar(256)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF' 
WHILE (@i <= @length) 
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END
SELECT @hexvalue = @charvalue
GO

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin 
GO

CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name    sysname
DECLARE @xstatus int
DECLARE @binpwd  varbinary (256)
DECLARE @txtpwd  sysname
DECLARE @tmpstr  varchar (256)
DECLARE @SID_varbinary varbinary(85)
DECLARE @SID_string varchar(256)

IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR 
    SELECT sid, name, xstatus, password FROM master..sysxlogins 
    WHERE srvid IS NULL AND name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR 
    SELECT sid, name, xstatus, password FROM master..sysxlogins 
    WHERE srvid IS NULL AND name = @login_name
OPEN login_curs 
FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs 
  DEALLOCATE login_curs 
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script ' 
PRINT @tmpstr
SET @tmpstr = '** Generated ' 
  + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
PRINT 'DECLARE @pwd sysname'
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr 
    IF (@xstatus & 4) = 4
    BEGIN -- NT authenticated account/group
      IF (@xstatus & 1) = 1
      BEGIN -- NT login is denied access
        SET @tmpstr = 'EXEC master..sp_denylogin ''' + @name + ''''
        PRINT @tmpstr 
      END
      ELSE BEGIN -- NT login has access
        SET @tmpstr = 'EXEC master..sp_grantlogin ''' + @name + ''''
        PRINT @tmpstr 
      END
    END
    ELSE BEGIN -- SQL Server authentication
      IF (@binpwd IS NOT NULL)
      BEGIN -- Non-null password
        EXEC sp_hexadecimal @binpwd, @txtpwd OUT
        IF (@xstatus & 2048) = 2048
          SET @tmpstr = 'SET @pwd = CONVERT (varchar(256), ' + @txtpwd + ')'
        ELSE
          SET @tmpstr = 'SET @pwd = CONVERT (varbinary(256), ' + @txtpwd + ')'
        PRINT @tmpstr
	EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
        SET @tmpstr = 'EXEC master..sp_addlogin ''' + @name 
          + ''', @pwd, @sid = ' + @SID_string + ', @encryptopt = '
      END
      ELSE BEGIN 
        -- Null password
	EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
        SET @tmpstr = 'EXEC master..sp_addlogin ''' + @name 
          + ''', NULL, @sid = ' + @SID_string + ', @encryptopt = '
      END
      IF (@xstatus & 2048) = 2048
        -- login upgraded from 6.5
        SET @tmpstr = @tmpstr + '''skip_encryption_old''' 
      ELSE 
        SET @tmpstr = @tmpstr + '''skip_encryption'''
      PRINT @tmpstr 
    END
  END
  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @xstatus, @binpwd
  END
CLOSE login_curs 
DEALLOCATE login_curs 
RETURN 0
GO
