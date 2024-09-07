/********************************************************************************************************
* ESTE SCRIPT CRIA 9 PROCEDURES, UMA FUNÇÃO E UM JOB QUE SÃO UTILIZADOS PARA REALIZAR A DOCUMENTAÇÃO 	*
* DE UM	SERVIDOR SQL Server 2005.																		*
* 																										*
* Ele também cria um Job que faz o seguinte:															*
* 1. Executa a documentação diariamente as 17:00hs														*
* 2. Salva os script no caminho C:\temp\doc_servidor													*
* 3. Cria o arquivo de output "Documenta_Servidor.log" no caminho C:\temp\doc_servidor					*
*																										*
* Por default todas as procedures (exceto a proc sp_hexadecimal que DEVE ser criada na MASTER)			*
* e função são criadas na base de dados perfdb. No entanto, as mesmas podem ser criadas			*
* em qualquer base de sua preferência. Basta alterar o nome da base no início do script e dentro		*
* da procedure principal.																				*
*																										*
* Autor: Nilton Pinheiro																				*
* WebSite: http://www.mcdbabrasil.com.br																*
*																										*
* ATENÇÃO: NÃO ESQUEÇAM DE TESTAR ESTE SCRIPT EM UM AMBIENTE DE TESTES ANTES DE COLOCÁ-LO EM PRODUÇÃO.	*
* QUALQUER PROBLEMA RESULTANTE DA EXECUÇÃO DESTE SCRIPT É DE INTEIRA RESPONSABILIDADE DO EXECUTOR.		*
*																										*
* FIQUEM A VONTADE PARA ADAPTAR ESTE SCRIPT ÀS SUAS REAIS NECESSIDADES.									*
*																										*
* Esta versão do script é suportado apenas no SQL SERVER 2005 (qualquer edição)							*
* para obter uma versão compatível com SQL SERVER 2000, visite o website acima.							*
********************************************************************************************************/
-- Se pretende criar as objetos em uma banco diferente de "perfdb", substitua este pelo nome 
-- do banco onde pretende criar. Faça um "Find and Replace - Ctrl+H".

-- Exemplo de execução
--====================
-- Salva todos os scripts de documentação no caminho C:\temp\doc_servidor
--		EXEC perfdb..usp_docservidor 'C:\temp\doc_servidor' 
-- Executada documentação apenas dos logins
--		EXEC perfdb..usp_doclogins 'C:\temp\doc_servidor' 
-- Executada documentação apenas dos usuários existentes nos DBs
--		EXEC perfdb..usp_docusers 'C:\temp\doc_servidor' 

USE perfdb
GO
-- Exclui procedure caso exista
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_docservidor]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_docservidor]
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_doclogins]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_doclogins]
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_docusers]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_docusers]
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_docdbs]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_docdbs]
GO
IF EXISTS (select * from dbo.sysobjects where id = object_id(N'[dbo].[usp_docdevices]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_docdevices]
GO
IF EXISTS (SELECT name FROM dbo.sysobjects WHERE name = 'fn_substchar')
	DROP FUNCTION [dbo].[fn_substchar]
GO
IF EXISTS(SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_docjobs]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE[dbo].[usp_docjobs]
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_doclinkedsrv]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_doclinkedsrv]
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[usp_docconfig]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[usp_docconfig]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_doclogins 				  					*
* Proposito : Documenta Logins do Servidor, é chamada pela		*
* procedure usp_docservidor mas também pode ser usada			*
* separadamente como no exemplo abaixo.							*
* 																*
* Criada por default no perfdb							*
* Ex.: exec perfdb..usp_doclogins 'C:\temp\doc_servidor'*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE proc dbo.usp_doclogins
@Caminho	varchar(255)
AS
SET NOCOUNT ON
--> Declaracao de Variaveis
DECLARE @str		varchar(2000)
DECLARE @tmpstr  	varchar (500)
DECLARE @err 		int
DECLARE @name    	sysname
DECLARE @xstatus 	int
DECLARE @binpwd  	varbinary (500)
DECLARE @txtpwd  	varchar (500)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)
DECLARE @type varchar (1)
DECLARE @is_disabled int
DECLARE @hasaccess int
DECLARE @denylogin int

--> Limpa Tabela
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' and xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

--> Inicio do Processo de Documentacao
print '2.1. Inicio do Processo de Documentação do Logins'
INSERT INTO tempdb..tbdocaux(cmd) values('-- Logins do servidor: ' + @@SERVERNAME)
INSERT INTO tempdb..tbdocaux(cmd) values(' ')

DECLARE login_curs CURSOR FOR 
SELECT p.name, p.type, p.is_disabled, l.hasaccess, l.denylogin 
FROM sys.server_principals p LEFT JOIN sys.syslogins l
ON ( l.name = p.name )
WHERE p.type IN ( 'S', 'G', 'U' ) 
--AND p.name <> 'sa' 
--AND p.name <> 'BUILTIN\Administrators'
--AND p.name <> 'NT AUTHORITY\SYSTEM'
AND p.principal_id not between 257 AND 261 AND p.principal_id<>1

OPEN login_curs 
FETCH NEXT FROM login_curs INTO @name, @type, @is_disabled, @hasaccess, @denylogin
IF (@@fetch_status = -1)
	BEGIN
		PRINT 'Não existe logins para ser documentado!'
		INSERT INTO tempdb..tbdocaux(cmd) VALUES('Não existe logins para ser documentado!')		
	END

WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
			BEGIN
				IF (@type IN ( 'G', 'U'))
					BEGIN -- NT authenticated account/group
						SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS'	  
					END
				ELSE 
					BEGIN -- SQL Server authentication
						-- obtain password
						SET @binpwd = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
						EXEC sp_hexadecimal @binpwd, @txtpwd OUT
        
						-- obtain password policy state
						SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
						SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
						SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @txtpwd + ' HASHED'
						IF ( @is_policy_checked IS NOT NULL )
							BEGIN
								SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
							END
						IF ( @is_expiration_checked IS NOT NULL )
							BEGIN
								SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
							END
					END
					IF (@denylogin = 1)
						BEGIN -- login is denied access
							SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
						END
					ELSE IF (@hasaccess = 0)
						BEGIN -- login exists but does not have access
							SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
						END
					
					IF (@is_disabled = 1)
						BEGIN -- login is disabled
							SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
						END
				INSERT INTO tempdb..tbdocaux(cmd) VALUES( @tmpstr )
				INSERT INTO tempdb..tbdocaux(cmd) VALUES(' ')
			END
	FETCH NEXT FROM login_curs INTO @name, @type, @is_disabled, @hasaccess, @denylogin
	END
CLOSE login_curs 
DEALLOCATE login_curs

--> Gera o Arquivo texto 
print '2.1. Gera Arquivo Texto com os Logins'
      set @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\Logins_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      set @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\Logins.err'
      exec @err = master..xp_cmdshell @str, no_output

print '2.2. Verifica se ocorreu erro no BCP do Logins'
if @err =  0
begin	
	set @str = 'findstr -i Error '+@Caminho+'\Logins.err"'
	exec @err = master..xp_cmdshell @str, no_output
	if @err = 0
	begin
		RAISERROR ('Ocorreu erro no BCP da documenração dos Logins',16, 1)WITH LOG
		goto erro	
	end
	else
	begin
		goto sucesso
	end				
end
else
begin	
	RAISERROR ('Ocorreu erro na documenração dos Logins',16, 1)WITH LOG
	goto erro
end
sucesso:    	
return(0)
erro:
return(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_docusers 				  						*
* Proposito : Documenta os usuários de cada database, é chamada *
* pela procedure usp_docservidor mas também pode ser usada		*
* separadamente como no exemplo abaixo.							*
* 																*
* Criada por default no perfdb							*
* Ex.: exec perfdb..usp_docusers 'C:\temp\doc_servidor'	*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE PROCEDURE dbo.usp_docusers
@Caminho	varchar(255)
AS
SET NOCOUNT ON

--> Declara variaveis 
DECLARE @nomebanco 	varchar(50)
DECLARE @str 		varchar(500)
DECLARE @grupo		varchar(100)
DECLARE @schema		varchar(200)
DECLARE @usuario	varchar(500)
DECLARE @qtdusr		int
DECLARE @totalusr	int
DECLARE @err		int

--> Atribui valor as variaveis 
SET @qtdusr=0
SET @totalusr=0
SET @err=0

--> Inicio do processo 
PRINT '3.1. Inicio do Processo de Documentação dos usuários'

--> Cria as tabelas temporarias
CREATE TABLE #tbAux( ColAux varchar(1000) null )

--> Limpa Tabela
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' and xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

--> Seleciona o primeiro banco
SELECT  @nomebanco = min( name ) FROM sys.databases 
WHERE name NOT IN ('tempdb','msdb')
WHILE @nomebanco is not null
BEGIN
	BEGIN TRY
		IF DATABASEPROPERTY(@nomebanco, 'IsInLoad') = 0 -- Não faz documentação para banco em loading
		BEGIN
			--> Insere o nome do banco
			INSERT tempdb..tbdocaux(cmd ) VALUES ('-- Usuarios para a base : ' + @nomebanco)	
			INSERT tempdb..tbdocaux(cmd ) VALUES ('')	
			SELECT @str = 'USE ' + @nomebanco
			INSERT tempdb..tbdocaux(cmd ) VALUES ( @str )  
			INSERT tempdb..tbdocaux(cmd ) VALUES ( 'GO' ) 
        
			--> Seleciona os grupos 
			DELETE #tbAux
			SET @str = 'Use '+@nomebanco+';INSERT INTO #tbAux( ColAux ) ' 
			SET @str = @str + 'select name from sys.database_principals WHERE type = ''R'' AND principal_id<>0 AND is_fixed_role=0'
			EXEC (@str)  
			SELECT @grupo = min( ColAux ) FROM #tbAux
			WHILE @grupo is not null        
			BEGIN
				--> Insere comando para inclusao dos grupos 
				INSERT tempdb..tbdocaux(cmd ) VALUES ('CREATE ROLE '+@grupo) 
				INSERT tempdb..tbdocaux(cmd ) VALUES ('GO') 
				SELECT @grupo = min( ColAux ) FROM #tbAux WHERE ColAux > @grupo       
			END

			--> Inclui usuario no banco 
			DELETE #tbAux
			IF @nomebanco = 'master'
				BEGIN
				SET @str = 'Use '+@nomebanco+';SELECT +''CREATE USER ''+ quotename(dbp.name)+'' FOR LOGIN ''+quotename(ISNULL(srvp.name,dbp.name))+ 
				CASE WHEN default_schema_name IS NULL THEN '''' 
				WHEN default_schema_name=''dbo'' THEN '''' 
				ELSE +'' WITH DEFAULT_SCHEMA = ''+ quotename(default_schema_name) END FROM sys.database_principals dbp '
				SET @str = @str + 'LEFT OUTER JOIN sys.server_principals srvp ON dbp.sid = srvp.sid WHERE dbp.principal_id > 4 AND dbp.type NOT IN (''R'',''C'') '
				SET @str = @str + 'AND dbp.principal_id <>6'
				END
			ELSE
				BEGIN
				SET @str = 'Use '+@nomebanco+';SELECT +''CREATE USER ''+ quotename(dbp.name)+'' FOR LOGIN ''+quotename(ISNULL(srvp.name,dbp.name))+ 
				CASE WHEN default_schema_name IS NULL THEN '''' 
				WHEN default_schema_name=''dbo'' THEN '''' 
				ELSE +'' WITH DEFAULT_SCHEMA = ''+ quotename(default_schema_name) END FROM sys.database_principals dbp '
				SET @str = @str + 'LEFT OUTER JOIN sys.server_principals srvp ON dbp.sid = srvp.sid WHERE dbp.principal_id > 4 and dbp.type NOT IN (''R'',''C'')'
				END
	
			INSERT INTO #tbAux( ColAux ) EXEC ( @str ) 
     
			SELECT @usuario = min( ColAux ) FROM #tbAux
			WHILE @usuario is not null        
			BEGIN
				--> Insere comando para cria usuário
				INSERT tempdb..tbdocaux(cmd ) VALUES ( @usuario ) 
				INSERT tempdb..tbdocaux(cmd ) VALUES ( 'GO' ) 
				SET @qtdusr = @qtdusr + 1
				SELECT @usuario = min( ColAux ) FROM #tbAux WHERE ColAux > @usuario       
			END

			--> Seleciona Schemas
			DELETE #tbAux
			IF @nomebanco = 'master'
				SET @str = 'Use '+@nomebanco+';SELECT +''CREATE SCHEMA ''+ quotename(name)+
				CASE WHEN principal_id=1 THEN '''' 
				ELSE +'' AUTHORIZATION ''+ quotename(user_name(principal_id)) END FROM sys.schemas WHERE (schema_id>4 AND schema_id<16384) AND schema_id<>6 '
		    ELSE
				SET @str = 'Use '+@nomebanco+';SELECT +''CREATE SCHEMA ''+ quotename(name)+
				CASE WHEN principal_id=1 THEN '''' 
				ELSE +'' AUTHORIZATION ''+ quotename(user_name(principal_id)) END FROM sys.schemas WHERE schema_id>4 AND schema_id<16384 '

			INSERT INTO #tbAux( ColAux ) EXEC ( @str ) 
			SELECT @schema = min( ColAux ) FROM #tbAux
			WHILE @schema IS NOT NULL        
			BEGIN
				--> Insere comando para inclusao dos grupos 
				INSERT tempdb..tbdocaux(cmd ) VALUES (@schema) 
				INSERT tempdb..tbdocaux(cmd ) VALUES ('GO') 
				SELECT @schema = min( ColAux ) FROM #tbAux WHERE ColAux > @schema       
			END
						
			--> Seleciona grupos/usuarios
			DELETE #tbAux
        	SET @str = 'Use '+@nomebanco+';SELECT quotename(user_name(role_principal_id))+'',''+quotename(user_name(member_principal_id)) FROM sys.database_role_members WHERE member_principal_id>1'
			INSERT INTO #tbAux(ColAux) EXEC(@str) 

			SELECT @usuario = min( ColAux ) FROM #tbAux
			WHILE @usuario is not null        
			BEGIN
				--> Insere linha de comando para inclusao de usuarios nos grupos
				INSERT tempdb..tbdocaux(cmd ) VALUES ('EXEC sp_addrolemember '+@usuario) 
				INSERT tempdb..tbdocaux(cmd ) VALUES ('GO') 
				SELECT @usuario = min( ColAux ) FROM #tbAux WHERE ColAux > @usuario       
			END
			INSERT tempdb..tbdocaux(cmd ) VALUES ('---------------------------------------------------------------')  
			INSERT  tempdb..tbdocaux(cmd ) VALUES ('-- Total de Usuarios para a base ' + @nomebanco + ': '+ convert(varchar(6), @qtdusr ))
			INSERT  tempdb..tbdocaux(cmd ) VALUES ('')  
			INSERT  tempdb..tbdocaux(cmd ) VALUES ('')  

			SET @totalusr = @totalusr + @qtdusr
			SET @qtdusr = 0
		END
		SELECT @nomebanco = min( name ) FROM sys.databases 
		WHERE name NOT IN ('tempdb','msdb') AND name > @nomebanco
	END TRY
	BEGIN CATCH
        -- Em casos de erros, segue em frente com os demais  bancos.
		SELECT ERROR_NUMBER() AS ErrorNumber,CONVERT(varchar(200),ERROR_MESSAGE()) AS ErrorMessage
		insert tempdb..tbdocaux( cmd ) EXEC ('SELECT ERROR_MESSAGE() AS ErrorMessage')
		insert tempdb..tbdocaux( cmd ) values ( '---------------------------------------------------------------' )  
        insert tempdb..tbdocaux( cmd ) values ( '--> Quantidade de Usuarios = ' + convert(varchar(6), @qtdusr ))
	    insert tempdb..tbdocaux( cmd ) values ( '---------------------------------------------------------------' )  

		SELECT  @nomebanco = min( name ) FROM sys.databases 
		WHERE name NOT IN ('tempdb') AND name > @nomebanco
	END CATCH   	
END
INSERT tempdb..tbdocaux(cmd ) VALUES( '-- Quantidade Total de Usuarios do Servidor ' + 
                                      substring(@@servername,1,20)+ ': ' + 
                                      convert(char(5), @totalusr) )
--> Gera o Arquivo texto 
print '3.2. Gera arquivo texto com os usuários'
      set @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\Users_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      set @str = @str +'.sql -c -T -S'+@@servername+' -e'+@Caminho+'\Users.err'

      exec @err = master..xp_cmdshell @str, no_output
       
print '3.3. Verifica se ocorreu erro no BCP dos usuários'
	if @err =  0
	begin	
		set @str = 'findstr -i Error '+@Caminho+'\Users.err"'
		exec @err = master..xp_cmdshell @str, no_output
		if @err = 0	
		begin
 		 	RAISERROR ('Ocorreu erro no BCP da documenração dos Usuários',16, 1)WITH LOG
  			goto erro
		end
		else
		begin
			goto sucesso
		end				
	end
	else
	begin	
	 	RAISERROR ('Ocorreu erro na documenração dos Usuários',16, 1)WITH LOG
		goto erro
	end
sucesso:    	
drop table #tbAux
return(0)
erro:
drop table #tbAux
return(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_docdbs 				  						*
* Proposito : Gera script de attach para todos os database, é	*
* chamada pela procedure usp_docservidor mas também pode ser	*
* usada separadamente como no exemplo abaixo.					*
* 																*
* Criada por default no perfdb							*
* Ex.: exec perfdb..usp_docdbs 'C:\temp\doc_servidor'	*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE PROCEDURE dbo.usp_docdbs
@Caminho	varchar(255)
AS
SET NOCOUNT ON
--> Declaracao de Variaveis
DECLARE @cont 		int
DECLARE @banco 		sysname
DECLARE @str 		varchar(1000)
DECLARE @err		int
DECLARE @bco 		int
DECLARE @def 		int
DECLARE @usuario	sysname
DECLARE @fileid as varchar (200)
DECLARE @filename as varchar (200)

--> Cria as tabelas temporarias
CREATE TABLE #tbAux( FileId smallint, FileName  nvarchar(520) )

--> Limpa Tabela
IF EXISTS(SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' and xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

--> Inicio do Processo de Documentacao dos Databases
PRINT '4.1. Inicio do Processo de Documentação dos Databases' 
SELECT @cont = min(database_id) FROM sys.databases WHERE name NOT IN ('master','model','msdb','tempdb')
WHILE  @cont is not null
BEGIN
	SET @banco = convert(sysname, db_name(@cont))
	SET @str =  '-- Attach do database: '+@banco+' (database_id '+ltrim(str(db_id(@banco)))+')'
	INSERT tempdb..tbdocaux VALUES(@str)	
	--SET @str = 'SELECT fileid,filename from '+@banco+'..sysfiles'
	SET @str = 'SELECT file_id,physical_name FROM '+@banco+'.sys.database_files'
	INSERT INTO #tbAux EXEC(@str)
	SET @str = 'sp_attach_db '+ @banco +','
	SET rowcount 0 
	SET rowcount 1 
	SELECT @fileid= FileId, @filename= FileName FROM #tbAux 
	WHILE @@rowcount <> 0 
		BEGIN 
		    SET rowcount 0 
		    SET @str =  @str +'''' + RTRIM(@filename)
	        SET @str =  @str + ''',
'
	        DELETE #tbAux WHERE FileId=@fileid
	        SET rowcount 1 
	        SELECT @fileid= FileId, @filename= FileName FROM #tbAux 
	    END
	    SET rowcount 0
		SET @str= LEFT (@str, len(RTRIM(@str))-3)
		SET @str= @str + '
GO'
		INSERT INTO tempdb..tbdocaux VALUES (@str)
		SELECT @cont = min(database_id) FROM sys.databases WHERE name NOT IN('master','model','msdb','tempdb')
		AND database_id > @cont
		TRUNCATE TABLE #tbAux
END

-- Gera o Arquivo texto 
PRINT '4.2. Gera arquivo texto com os Databases'
      SET @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\Databases_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      SET @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\Databases.err'
      EXEC @err = master..xp_cmdshell @str, no_output
       
PRINT '4.3. Verifica se ocorreu erro no BCP dos Databases'
	IF @err =  0
	BEGIN
		SET @str = 'findstr -i Error '+@Caminho+'\Databases.err"'
		EXEC @err = master..xp_cmdshell @str, no_output
	
		IF @err = 0	
			BEGIN
 		 		RAISERROR ('Ocorreu erro no BCP da documenração dos Databases',16, 1)WITH LOG
				SET @bco = 1
			END
		ELSE
			BEGIN --Sucesso 		
				SET @bco = 0
			END			
	END
	ELSE
	BEGIN
	 	RAISERROR ('Ocorreu erro na documenração dos Databases',16, 1)WITH LOG
		SET @bco = 1
	END

--> Inicio do Processo de Documentacao dos DEFAULT Databases
PRINT '4.4. Inicio do Processo de Documentação dos Default Database' 
TRUNCATE TABLE tempdb..tbdocaux 

SELECT name,default_database_name INTO tempdb..tbdoclogins FROM sys.server_principals
WHERE type IN ( 'S', 'G', 'U' ) 
AND principal_id not between 257 AND 261 AND principal_id<>1

SELECT @usuario = min(name) FROM tempdb..tbdoclogins
WHILE  @usuario is not null
BEGIN
	SELECT @banco = default_database_name FROM tempdb..tbdoclogins WHERE name = @usuario
	SET @str =  'EXEC sp_defaultdb '''+@usuario+''','''+@banco+''''
	INSERT tempdb..tbdocaux VALUES(@str)
	INSERT tempdb..tbdocaux VALUES('GO')

	SELECT @usuario = min(name) FROM tempdb..tbdoclogins WHERE name > @usuario
END
DROP TABLE tempdb..tbdoclogins
print '4.5. Gera arquivo texto dos Default Databases'
	set @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\Defaultdb_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      	set @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\Defaultdb.err'
      	exec @err = master..xp_cmdshell @str, no_output

print '4.6. Verifica se ocorreu erro no BCP dos Default Databases'
	if @err =  0
	begin
		set @str = 'findstr -i Error '+@Caminho+'\Defaultdb.err"'
		exec @err = master..xp_cmdshell @str, no_output
	
		if @err = 0	
		begin
 		 	RAISERROR ('Ocorreu erro no BCP da documentação dos Default Databases',16, 1)WITH LOG
			set @def = 1
           	end
		else
		begin
			-- Sucesso
			set @def = 0
		end
	end
	else	
	begin			
	 	RAISERROR ('Ocorreu erro na documenração dos Default Databases',16, 1)WITH LOG
		set @def = 1
	end

if @bco = 1 or @def = 1
	return(1)
else
begin
	return(0)
end

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_docdevices 				  	*
* Proposito : Gera script dos Devices de Backup existentes no	*
* servidor. É chamada pela procedure usp_docservidor mas também	*
* pode ser usada separadamente como no exemplo abaixo.		*
* 								*
* Criada por default no perfdb					*
* Ex.: exec perfdb..usp_docdevices 'C:\temp\doc_servidor'		*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE PROCEDURE dbo.usp_docdevices
@Caminho	varchar(255)
AS 
SET NOCOUNT ON
--> Declaracao de Variaveis
DECLARE @nomefis 	varchar(255)
DECLARE @str 		varchar(255)
DECLARE @dev 		varchar(100)
DECLARE @err		int

print '5.1 Inicio do Processo de Documentação dos Devices de Backup'
--> Limpa Tabela Auxiliar
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' AND xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

SELECT @dev = MIN(name) FROM sys.backup_devices
WHILE @dev IS NOT NULL
BEGIN
 	SELECT @nomefis = physical_name FROM sys.backup_devices WHERE name = @dev
	SET @str = 'EXEC sp_addumpdevice ''DISK'',''' + @dev + ''','''+ @nomefis + '''' 
    INSERT INTO tempdb..tbdocaux(cmd) VALUES(@str)
    INSERT INTO tempdb..tbdocaux(cmd) VALUES ('GO')
	SELECT @dev = MIN(name) FROM sys.backup_devices WHERE name > @dev
END

--> Gera o Arquivo texto 
print '5.2. Gera arquivo texto com os Devices de Backup'
      set @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\DevicesBackup_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      set @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\DevicesBackup.err'

      exec @err = master..xp_cmdshell @str, no_output
       
PRINT '5.3. Verifica se ocorreu erro no BCP dos Devices de Backup'
	IF @err =  0
	BEGIN
		SET @str = 'findstr -i Error '+@Caminho+'\DevicesBackup.err'''
		EXEC @err = master..xp_cmdshell @str, no_output	
		IF @err = 0	
		BEGIN
 		 	RAISERROR ('Ocorreu erro no BCP da documenração dos Devices de Backup',16, 1)WITH LOG
  			GOTO erro
		END
	END
	ELSE
	BEGIN
	 	RAISERROR ('Ocorreu erro na documenração dos Device de Backup',16, 1)WITH LOG
		GOTO erro
	END
RETURN(0)
erro:
RETURN(1)
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
CREATE FUNCTION dbo.fn_substchar (@String nvarchar(4000))
RETURNS nvarchar(4000)
AS
BEGIN
	DECLARE @str  nvarchar(4000)
	DECLARE @PosIni int

	IF CHARINDEX (char(39),@string,1) > 0 
	BEGIN
		SET @PosIni = 1
		WHILE @PosIni <> 0
		BEGIN
			SELECT @string = substring(@string,1,charindex(char(39),@string,1)-1)+'"'+substring(@string,charindex(char(39),@string,1)+1,len(@string)-charindex(char(39),@string,1))
			SELECT @PosIni = charindex(char(39),@string,1)
		END
	END
	RETURN ltrim(rtrim((@string)))
END
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_docjobs 				  						*
* Proposito : Gera script de todos os jobs do servidor			*
* É chamada pela procedure usp_docservidor mas também pode ser	*
* usada separadamente como no exemplo abaixo.					*
* 																*
* Criada por default no perfdb							*
* Ex.: exec perfdb..usp_docjobs 'C:\temp\doc_servidor'	*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE PROCEDURE dbo.usp_docjobs
@Caminho	varchar(255)
AS
SET NOCOUNT ON

--> Declara variaveis 
DECLARE @job		char(36)
DECLARE @str 		nvarchar(4000)
DECLARE @err		int
DECLARE @steps		int
DECLARE @sched		int
DECLARE @login 		varchar(20)
DECLARE @jobname	varchar(200)

--> Atribui valor as variaveis 
set @err 	= 0

--> Inicio do processo 
print '6.1. Inicio do Processo de documentação dos Jobs'
--> Limpa Tabela
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' AND xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

INSERT tempdb..tbdocaux(cmd) VALUES( 'Use MSDB
GO' ) 
 
--> Seleciona o primeiro banco
   SELECT @job = min( cast(job_id as varchar(36)) ) FROM msdb..sysjobs
   WHILE @job IS NOT NULL
   BEGIN
	SELECT @login = lg.name FROM msdb..sysjobs jb JOIN sys.server_principals lg ON jb.owner_sid = lg.sid
	WHERE jb.job_id = @job
	SELECT @jobname = dbo.fn_substchar(name) FROM msdb..sysjobs WHERE job_id = @job

	SELECT @str = 'EXEC sp_add_job  @job_name = '+char(39)+@jobname+char(39)+',
		 @enabled =  '+cast(enabled as varchar(10))+',
		 @description =  '+char(39)+description+char(39)+',
		 @start_step_id =  '+cast(start_step_id as varchar(10)) +',
		 @category_id =  '+cast(category_id as varchar(10))+',
		 @owner_login_name =  '+char(39)+@login+char(39)+',
		 @notify_level_eventlog =  '+cast(notify_level_eventlog as varchar(5))+',
		 @notify_level_email =  '+cast(notify_level_email as varchar(5))+',
		 @notify_level_netsend =  '+cast(notify_level_netsend as varchar(5))+',
		 @notify_level_page =  '+cast(notify_level_page as varchar(5)) +',
		 @delete_level =  '+cast(delete_level as varchar(5))
	FROM msdb..sysjobs WHERE job_id = @job
    INSERT INTO tempdb..tbdocaux(cmd) VALUES( @str+'
GO' ) 

	-->  Adiciona os steps do Job	
	SELECT @steps = min(step_id) FROM msdb.dbo.sysjobsteps WHERE job_id = @job 
	WHILE @steps IS NOT NULL
	BEGIN
		SELECT @str = 'EXEC sp_add_jobstep  @job_name = '+char(39)+@jobname+char(39)+',
			 @step_id =  '+cast(step_id  as varchar(5))+',
			 @step_name =  '+char(39)+step_name+char(39)+', 
			 @subsystem = '+char(39)+subsystem+char(39)+',
			 @command =  '+char(39)+dbo.fn_substchar(command)+char(39)+ 
			 CASE 
			    WHEN server IS NOT NULL THEN ',
			 @additional_parameters =  '+char(39)+cast(additional_parameters as varchar(2000))+char(39)
			    ELSE ''
			 END+',
			 @cmdexec_success_code =  '+cast(cmdexec_success_code as varchar(5))+', 
			 @on_success_action = '+cast(on_success_action  as varchar(5))+',
			 @on_success_step_id =  '+cast(on_success_step_id as varchar(5))+',
			 @on_fail_action =  '+cast(on_fail_action   as varchar(5))+
			 CASE 
			    WHEN server IS NOT NULL THEN ',
			 @server =  '+server
			    ELSE ''
			 END+',
			 @database_name =  '+char(39)+database_name+char(39)+
			 CASE 
			    WHEN server IS NOT NULL THEN ',
			 @database_user_name =  '+database_user_name
			    ELSE ''
			 END+',
			 @retry_attempts =  '+cast(retry_attempts as varchar(5))+',
			 @retry_interval =  '+cast(retry_interval as varchar(5))+',
			 @os_run_priority = '+cast(os_run_priority as varchar(5))+',
			 @on_fail_step_id = '+cast(on_fail_step_id as varchar(5))+
			 CASE 
			    WHEN output_file_name IS NOT NULL THEN ',
			 @output_file_name = '''+output_file_name +''''
			    ELSE ''
			 END+',
			 @flags = '+cast( flags as varchar(5))
			 FROM msdb..sysjobsteps
			 WHERE @steps = step_id AND job_id = @job

        	INSERT INTO tempdb..tbdocaux(cmd) VALUES( @str+'
GO' ) 
		SELECT @steps = min(step_id) FROM msdb..sysjobsteps WHERE job_id = @job  and  step_id  > @steps
	END

	-->  Adiciona os schedules do Job
	SELECT  @sched = min(schedule_id) FROM msdb..sysjobschedules WHERE job_id = @job	
	WHILE @sched IS NOT NULL
	BEGIN
		SELECT @str = 'EXEC sp_add_jobschedule  @job_name =  '+char(39)+@jobname+char(39)+', 
			@name =  '+char(39)+name+char(39)+',
			@enabled = '+cast( enabled  as char(01))+',
			@freq_type =  '+cast( freq_type   as varchar(10))+',
			@freq_interval = '+cast(freq_interval as varchar(10))+',
			@freq_subday_type =  '+cast(freq_subday_type as varchar(05))+',
			@freq_subday_interval = '+cast(freq_subday_interval as varchar(05))+',
			@freq_relative_interval = '+cast(freq_relative_interval as varchar(05))+',
			@freq_recurrence_factor = '+ cast(freq_recurrence_factor as varchar(05))+',
			@active_start_date = '+char(39)+cast(active_start_date as varchar(08))+char(39)+',
			@active_end_date = '+char(39)+cast(active_end_date as varchar(08))+char(39)+',
			@active_start_time = '+char(39)+cast(active_start_time as varchar(08))+char(39)+',
			@active_end_time = '+char(39)+cast(active_end_time as varchar(08))+char(39)
		FROM msdb..sysschedules WHERE @sched = schedule_id
        INSERT INTO tempdb..tbdocaux(cmd) VALUES( @str+'
GO' ) 
		SELECT @sched = min(schedule_id) FROM msdb..sysjobschedules 
		WHERE job_id = @job AND schedule_id  > @sched

	END
	SELECT @str = 'EXEC sp_add_jobserver  @job_name = '+char(39)+@jobname+char(39)+',
	@server_name =  '+char(39)+@@servername+char(39)
    INSERT tempdb..tbdocaux(cmd) VALUES( @str+'
GO' ) 
    SELECT @job = min( cast(job_id as char(36)) ) FROM msdb..sysjobs
    WHERE cast(job_id as char(36))  > @job
  END

PRINT '6.2. Gera arquivo texto com os Jobs'
      SET @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\Jobs_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      SET @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\Jobs.err'
      EXEC @err = master..xp_cmdshell @str, no_output
       
print '6.3. Verificando se ocorreu ERRO no BCP dos Jobs'
	if @err =  0
	begin
		set @str = 'findstr -i Error '+@Caminho+'\Jobs.err"'
		exec @err = master..xp_cmdshell @str, no_output
		if @err = 0
		begin
 		 	RAISERROR ('Ocorreu erro no BCP da documenração dos Jobs',16, 1)WITH LOG
			goto erro	
		end
		else
		begin
			-- Sucesso
			goto sucesso
		end
	end
	else
	begin	
	 	RAISERROR ('Ocorreu erro na documenração dos Jobs',16, 1)WITH LOG
		goto erro
	end
sucesso:    	
return(0)
erro:
return(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_doclinkedsrv 				  					*
* Proposito : Gera script de todos os linked servers do servidor*
* É chamada pela procedure usp_docservidor mas também pode ser	*
* usada separadamente como no exemplo abaixo.					*
* 																*
* Criada por default no perfdb							*
* Ex.: exec perfdb..usp_doclinkedsrv 'C:\temp\doc_servidor'	*
****************************************************************/

-- Compatibilidade SQL Server 2005
--=================================

CREATE procedure dbo.usp_doclinkedsrv
@Caminho	varchar(255)
AS
SET NOCOUNT ON

--> Declara variaveis 
DECLARE @srv		int
DECLARE @str 		nvarchar(4000)
DECLARE @err		int

--> Atribui valor as variaveis 
set @err 	= 0

--> Inicio do processo 
print '7.1. Inicio do Processo de documentação dos Linked Servers'

--> Limpa Tabela
IF EXISTS (SELECT name FROM tempdb..sysobjects WHERE name='tbdocaux' and xtype='U')
	TRUNCATE TABLE tempdb..tbdocaux
ELSE
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

INSERT tempdb..tbdocaux(cmd) VALUES( 'USE MASTER'+'
GO' ) 

--> Seleciona o primeiro banco
SELECT  @srv = min( srvid ) FROM master.dbo.sysservers WHERE srvname <> @@servername
WHILE @srv is not null
BEGIN
	IF (SELECT srvproduct FROM master.dbo.sysservers WHERE srvid=@srv)='SQL Server'
		BEGIN
			SELECT @str = 'EXEC sp_addlinkedserver @server = '''+srvname+''''
			FROM master.dbo.sysservers where srvname <> @@servername and srvid = @srv
		END
	ELSE
		BEGIN
		SELECT @str = 'EXEC sp_addlinkedserver @server =  '+char(39)+srvname+char(39)+',
		@srvproduct =  '+char(39)+srvproduct+char(39)+',
		@provider =  '+char(39)+providername+char(39)+
		CASE 
		WHEN datasource IS not NULL THEN ',
		@datasrc =  '+char(39)+datasource+char(39)
		ELSE ''
		END+
		CASE 
		WHEN location IS not NULL THEN ',
		@location =  '+char(39)+location+char(39)
		ELSE ''
		END+
		CASE 
		WHEN providerstring IS not NULL THEN ',
		@provstr =  '+char(39)+providerstring+char(39)
		ELSE ''
		END+
		CASE 
		WHEN catalog IS not NULL THEN ',
		@catalog =  '+char(39)+catalog+char(39)
		ELSE ''
		END
		FROM master.dbo.sysservers where srvname <> @@servername and srvid = @srv
	END
	INSERT tempdb..tbdocaux(cmd) values( @str+'
GO') 

SELECT @srv = min( srvid ) FROM master.dbo.sysservers WHERE srvname <> @@servername
AND srvid > @srv

END

SET @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\LinkedServers_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
SET  @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\LinkedServers.err'
EXEC @err = master..xp_cmdshell @str, no_output
      
	print '7.2. Verifica se ocorreu erro no BCP dos Linked Servers'
	if @err =  0
	begin
		set @str = 'findstr -i Error '+@Caminho+'\LinkedServers.err"'
		exec @err = master..xp_cmdshell @str, no_output
		if @err = 0
		begin
 		 	RAISERROR ('Ocorreu erro no BCP da documenração dos Linked Servers',16, 1)WITH LOG
			goto erro	
		end
		else
		begin
			-- Sucesso
			goto sucesso
		end
	end
	else
	begin	
	 	RAISERROR ('Ocorreu erro da documenração dos Linked Servers',16, 1)WITH LOG
		goto erro
	end
sucesso:    	
return(0)
erro:
return(1)

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/****************************************************************
* Procedure : usp_docconfig 				  	*
* Proposito : Gera arquivo texto com o resultado da execução	*
* da sp_configure						*
* 								*
* É chamada pela procedure usp_docservidor mas também		*
* pode ser usada separadamente como no exemplo abaixo.		*
* 								*
* Criada por default no perfdb					*
* Ex.: exec perfdb..usp_docconfig 'C:\temp\doc_servidor'		*
****************************************************************/

CREATE procedure dbo.usp_docconfig
@Caminho	varchar(255)
AS 
SET NOCOUNT ON

-- Declaracao de Variaveis
DECLARE @str 		nvarchar(4000)
DECLARE @name		varchar (40)
DECLARE @minimum 	int
DECLARE @maximum 	int
DECLARE @config 	int
DECLARE @run	 	int
DECLARE @err		int

print '8.1 Inicio do Processo de Documentação da sp_configure'

--> Limpa Tabela
IF exists (select name from tempdb..sysobjects where name='tbdocaux' and xtype='U')
	truncate table tempdb..tbdocaux
else
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

--> Insere linha 
insert tempdb..tbdocaux(cmd ) values ('/* ')
insert tempdb..tbdocaux(cmd ) values ('-- Configuracao atual da sp_configure')
insert tempdb..tbdocaux(cmd ) values (' ')
insert tempdb..tbdocaux(cmd ) values ('name                                minimum     maximum     config_value run_value')
insert tempdb..tbdocaux(cmd ) values ('----------------------------------- ----------- ----------- ------------ ----------- ')

-- Cria tabela auxiliar
IF exists (select name from tempdb..sysobjects where name='tbspconfigure' and xtype='U')
DROP TABLE tempdb..tbspconfigure

CREATE TABLE tempdb..tbspconfigure(names varchar(40), minimum int,	maximum int,
config_value int,run_value int)

-- Carrega a tabela com o conteúdo da sp_configure
INSERT INTO tempdb..tbspconfigure exec sp_configure

SET rowcount 0 
SET rowcount 1 
SELECT @name=names,@minimum=minimum,@maximum=maximum,@config=config_value, @run=run_value
FROM tempdb..tbspconfigure
while @@rowcount <> 0 
BEGIN 
     SET rowcount 0 
     SET @str =  CONVERT(CHAR(36),@name) + convert(char(12),@minimum) + 	
     convert(char(12),@maximum)+ convert(char(13),@config)+ convert(char(13),@run)
     INSERT tempdb..tbdocaux values(@str)	
     DELETE tempdb..tbspconfigure WHERE names=@name
     set rowcount 1 
     SELECT @name=names,@minimum=minimum,@maximum=maximum,@config=config_value, @run=run_value
     FROM tempdb..tbspconfigure
end 
set rowcount 0 
INSERT tempdb..tbdocaux(cmd ) VALUES ('*/ ')
INSERT tempdb..tbdocaux(cmd ) VALUES (' ')
INSERT tempdb..tbdocaux(cmd ) VALUES ('-- Script para configuracao da sp_configure (valores para run_value)')
INSERT tempdb..tbdocaux(cmd ) VALUES (' ')

-- Recarrega a tabela com o conteúdo da sp_configure
INSERT INTO tempdb..tbspconfigure EXEC sp_configure

SET ROWCOUNT 0 
SET ROWCOUNT 1 
SELECT @name=names, @run=run_value FROM tempdb..tbspconfigure ORDER BY names
WHILE @@rowcount <> 0 
BEGIN 
     SET rowcount 0 
     SET @str =  'sp_configure '''+ @name + ''', '+ convert(varchar(10),@run)
     INSERT tempdb..tbdocaux VALUES(@str)	
     INSERT tempdb..tbdocaux VALUES('GO')	
     DELETE tempdb..tbspconfigure WHERE names=@name
     SET ROWCOUNT 1 
     SELECT @name=names,@run=run_value FROM tempdb..tbspconfigure ORDER BY names
END
SET ROWCOUNT 0 
DROP TABLE tempdb..tbspconfigure

-- Gera o Arquivo texto 
PRINT '8.2. Gera arquivo texto com o resultado da sp_configure'
      SET @str = 'bcp tempdb..tbdocaux out '+@Caminho+'\sp_configure_'+datename(dw,getdate())+ '_'+ REPLACE(@@servername,'\','')
      SET @str = @str +'.sql -c -T -S'+@@servername+ ' -e'+@Caminho+'\sp_configure.err'

      EXEC @err = master..xp_cmdshell @str, no_output
       
print '8.3. Verifica se ocorreu erro no BCP da sp_configure'
	if @err =  0
	begin
		set @str = 'findstr -i Error '+@Caminho+'\sp_configure.err"'
		exec @err = master..xp_cmdshell @str, no_output
	
		if @err = 0	
		begin
 		 	RAISERROR ('Ocorreu erro no BCP de documenração da sp_configure',16, 1)WITH LOG
  			goto erro
		end
	end
	else
	begin
	 	RAISERROR ('Ocorreu erro na documenração da sp_configure',16, 1)WITH LOG
		goto erro
	end

return(0)
erro:
return(1)
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
/************************************************************************
* Procedure Principal: usp_docservidor									*
* Objetivo  : Realizar documentação do servidor							*
*             															*
* Criada por default no perfdb									*
* Ex.: perfdb..usp_docservidor 'C:\temp\doc_servidor'           *
************************************************************************/

-- ATENÇÃO !!
-- ESTA É A PROCEDURE PRINCIPAL
-- Se estiver criando as procedures em uma base <> da perfdb, altere o nome da base também nas linhas abaixo.

CREATE procedure dbo.usp_docservidor
@Caminho 	varchar(255) = null
AS
SET NOCOUNT ON

--> Declaracao de Variaveis
DECLARE @lgn 		int
DECLARE @usr 		int
DECLARE @dbs 		int
DECLARE @dev 		int
DECLARE @job 		int
DECLARE @lnk 		int
DECLARE @spconf		int
DECLARE @status		int

-- Verifica se o caminho informado é válido
CREATE TABLE #direxiste (file_exists bit, file_is_dir bit, parent_directory_exists bit)
INSERT INTO #direxiste EXEC master..xp_fileexist @caminho 
IF (SELECT file_is_dir FROM #direxiste) = 0
    BEGIN
	-- O diretório informado não existe
	DROP TABLE #direxiste
	RAISERROR ('O caminho informado para a documentação do servidor não existe! ',16, 1)WITH LOG	
	RETURN	
    END
ELSE
-- Cria uma tabela auxiliar no TEMPDB
IF exists (select name from tempdb..sysobjects where name='tbdocaux' and xtype='U')
	DROP TABLE tempdb..tbdocaux
else
	CREATE TABLE tempdb..tbdocaux (cmd varchar(8000))

print '2. Executando Documentacao dos *** Logins ***'
exec @lgn = perfdb.dbo.usp_doclogins @Caminho

print '3. Executando Documentacao dos *** Usuários ***'
exec @usr = perfdb.dbo.usp_docusers @Caminho

print '4. Executando Documentacao dos *** Banco de Dados ***'
exec @dbs = perfdb.dbo.usp_docdbs @Caminho

print '5. Executando Documentacao dos *** Devices de Backup ***'
exec @dev = perfdb.dbo.usp_docdevices @Caminho

print '6. Executando Documentacao dos *** Jobs ***'
exec @job = perfdb.dbo.usp_docjobs @Caminho

print '7. Executando Documentacao dos *** Linked Servers ***'
exec @lnk = perfdb.dbo.usp_doclinkedsrv @Caminho

print '8. Executando Documentacao da *** sp_configure ***'
exec @spconf = perfdb.dbo.usp_docconfig @Caminho

DROP TABLE tempdb..tbdocaux 

print '9. Verifica se ocorreu erro no processo de documentação'
if @lgn = 0 and @usr = 0 and @dbs = 0 and @dev = 0 and @job = 0 and @lnk = 0 and @spconf = 0
begin
	-- Processo Realizado com Sucesso
	select @status = 0
	select @status as Sucesso_no_Processo
	PRINT ''
	PRINT'**** DOCUMENTAÇÃO DO SERVIDOR REALIZADA COM SUCESSO!! ****'
	return(@status)
end
else
begin
	-- Ocorreu Erro
	select @status = 1
	select @status as Erro_no_Processo
	PRINT ''
	PRINT '**** OCORRERAM ERROS DURANTE O PROCESSO DE DOCUMENTAÇÃO DO SERVIDOR!! ****'
	return(@status)
end

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

USE master
GO
/****************************************************************
* Script para migrar logins entre servidores com SQL 2000 		*
*																*
* Obs: Esta proc é chamada pela procedure de documentação de	*
* logins (usp_doclogins) 										* 
****************************************************************/

-- ESTA PROCEDURE DEVE SER CRIADA NO DB MASTER	
IF EXISTS (SELECT name FROM master.dbo.sysobjects WHERE id = object_id(N'[dbo].[sp_hexadecimal]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE [dbo].[sp_hexadecimal]
GO

CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(500),
    @hexvalue varchar(500) OUTPUT
AS
DECLARE @charvalue varchar(500)
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
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****************************************************************
* Script para criar o job "Documenta_Servidor" que executa a	* 
* procedure de  documentação do servidor.			*
*								*
* O Job faz o seguinte:						*
* 1. Executa o job diariamente as 17:00hs			*
* 2. Salva os script no caminho C:\temp\doc_servidor		*
* 3. Cria o arquivo de output Documenta_Servidor.log no caminho	*
* C:\temp\doc_servidor						*
*								*
* Obs: Se preferir, altere o caminho para um de sua preferência	*
****************************************************************/
BEGIN TRANSACTION            
  DECLARE @JobID BINARY(16)  
  DECLARE @ReturnCode INT    
  SELECT @ReturnCode = 0     
IF (SELECT COUNT(*) FROM msdb.dbo.syscategories WHERE name = N'[Uncategorized (Local)]') < 1 
  EXECUTE msdb.dbo.sp_add_category @name = N'[Uncategorized (Local)]'

  -- Delete the job with the same name (if it exists)
  SELECT @JobID = job_id     
  FROM   msdb.dbo.sysjobs    
  WHERE (name = N'Documenta_Servidor')       
  IF (@JobID IS NOT NULL)    
  BEGIN  
  -- Check if the job is a multi-server job  
  IF (EXISTS (SELECT  * 
              FROM    msdb.dbo.sysjobservers 
              WHERE   (job_id = @JobID) AND (server_id <> 0))) 
  BEGIN 
    -- There is, so abort the script 
    RAISERROR (N'Unable to import job ''Documenta_Servidor'' since there is already a multi-server job with this name.', 16, 1) 
    GOTO QuitWithRollback  
  END 
  ELSE 
    -- Delete the [local] job 
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'Documenta_Servidor' 
    SELECT @JobID = NULL
  END 

BEGIN 

  -- Add the job
  EXECUTE @ReturnCode = msdb.dbo.sp_add_job @job_id = @JobID OUTPUT , @job_name = N'Documenta_Servidor', @owner_login_name = N'sa', @description = N'Realiza documentação do servidor', @category_name = N'[Uncategorized (Local)]', @enabled = 1, @notify_level_email = 0, @notify_level_page = 0, @notify_level_netsend = 0, @notify_level_eventlog = 2, @delete_level= 0
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the job steps
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @JobID, @step_id = 1, @step_name = N'Documenta_Servidor', @command = N'EXEC perfdb..usp_docservidor ''C:\temp\doc_servidor''', @database_name = N'master', @server = N'', @database_user_name = N'', @subsystem = N'TSQL', @cmdexec_success_code = 0, @flags = 0, @retry_attempts = 0, @retry_interval = 1, @output_file_name = N'C:\temp\doc_servidor\Documenta_Servidor.log', @on_success_step_id = 0, @on_success_action = 1, @on_fail_step_id = 0, @on_fail_action = 2
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 
  EXECUTE @ReturnCode = msdb.dbo.sp_update_job @job_id = @JobID, @start_step_id = 1 

  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the job schedules
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @JobID, @name = N'Documenta_Servidor', @enabled = 1, @freq_type = 4, @active_start_date = 20050906, @active_start_time = 170000, @freq_interval = 1, @freq_subday_type = 1, @freq_subday_interval = 0, @freq_relative_interval = 0, @freq_recurrence_factor = 0, @active_end_date = 99991231, @active_end_time = 235959
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

  -- Add the Target Servers
  EXECUTE @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @JobID, @server_name = N'(local)' 
  IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback 

END
COMMIT TRANSACTION          
GOTO   EndSave              
QuitWithRollback:
  IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 
EndSave: