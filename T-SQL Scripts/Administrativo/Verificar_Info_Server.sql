--Verificar informações sobre o servidor 
--xp_msver 

--Step 1: Setting NULLs and quoted identifiers to ON and checking the version of SQL Server 
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'prodver') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)                        
drop table prodver
create table prodver ([index] int, Name nvarchar(50),Internal_value int, Charcater_Value nvarchar(50))
insert into prodver exec xp_msver 'ProductVersion'
	if (select substring(Charcater_Value,1,1)from prodver)!=8
	begin
	
                   
-- Step 2: This code will be used if the instance is Not SQL Server 2000 

		Declare @image_path nvarchar(100)                        
		Declare @startup_type int                        
		Declare @startuptype nvarchar(100)                        
		Declare @start_username nvarchar(100)                        
		Declare @instance_name nvarchar(100)                        
		Declare @system_instance_name nvarchar(100)                        
		Declare @log_directory nvarchar(100)                        
		Declare @key nvarchar(1000)                        
		Declare @registry_key nvarchar(100)                        
		Declare @registry_key1 nvarchar(300)                        
		Declare @registry_key2 nvarchar(300)                        
		Declare @IpAddress nvarchar(20)                        
		Declare @domain nvarchar(50)                        
		Declare @cluster int                        
		Declare @instance_name1 nvarchar(100)                        
-- Step 3: Reading registry keys for IP,Binaries,Startup type ,startup username, errorlogs location and domain.
		SET @instance_name = coalesce(convert(nvarchar(100), serverproperty('InstanceName')),'MSSQLSERVER');                        
		If @instance_name!='MSSQLSERVER'                        
		Set @instance_name=@instance_name                       
	 
    		Set @instance_name1= coalesce(convert(nvarchar(100), serverproperty('InstanceName')),'MSSQLSERVER');                        
		If @instance_name1!='MSSQLSERVER'                        
		Set @instance_name1='MSSQL$'+@instance_name1                        
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL', @instance_name, @system_instance_name output;                        
                        
		Set @key=N'SYSTEM\CurrentControlSet\Services\' +@instance_name1;                        
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer\Parameters';                        
		If @registry_key is NULL                        
		set @instance_name=coalesce(convert(nvarchar(100), serverproperty('InstanceName')),'MSSQLSERVER');                        
		EXEC master.dbo.xp_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\Microsoft SQL Server\Instance Names\SQL', @instance_name, @system_instance_name output;                        

		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer\Parameters';                        
		SET @registry_key1 = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer\supersocketnetlib\TCP\IP1';                        
		SET @registry_key2 = N'SYSTEM\ControlSet001\Services\Tcpip\Parameters\';                        
                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='ImagePath',@value=@image_path OUTPUT                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='Start',@value=@startup_type OUTPUT                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='ObjectName',@value=@start_username OUTPUT                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key,@value_name='SQLArg1',@value=@log_directory OUTPUT                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key1,@value_name='IpAddress',@value=@IpAddress OUTPUT                        
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key2,@value_name='Domain',@value=@domain OUTPUT                        
                        
		Set @startuptype= 	(select 'Start Up Mode' =                        
					CASE                        
					WHEN @startup_type=2 then 'AUTOMATIC'                        
					WHEN @startup_type=3 then 'MANUAL'                        
					WHEN @startup_type=4 then 'Disabled'                        
					END)                        
                        
--Step 4: Getting the cluster node names if the server is on cluster .else this value will be NULL.

		declare @Out nvarchar(400)                        
		SELECT @Out = COALESCE(@Out+'' ,'') + Nodename                        
		from sys.dm_os_cluster_nodes                        
                        
-- Step 5: printing Server details 
                        
			SELECT                       
			@domain as 'Domain',                      
			serverproperty('ComputerNamePhysicalNetBIOS') as 'MachineName',                      
			CPU_COUNT as 'CPUCount',
			(physical_memory_in_bytes/1048576) as 'PhysicalMemoryMB',                      
			@Ipaddress as 'IP_Address',                      
			@instance_name1 as 'InstanceName',
			@image_path as 'BinariesPath',                      
			@log_directory as 'ErrorLogsLocation',                      
			@start_username as 'StartupUser',                      
			@Startuptype as 'StartupType',                      
			serverproperty('Productlevel') as 'ServicePack',                      
			serverproperty('edition') as 'Edition',                      
			serverproperty('productversion') as 'Version',                      
			serverproperty('collation') as 'Collation',                      
			serverproperty('Isclustered') as 'ISClustered',                      
			@out as 'ClusterNodes',                      
			serverproperty('IsFullTextInstalled') as 'ISFullText'                       
			From sys.dm_os_sys_info                         
                      

-- Step 6: Printing database details 
				
			SELECT                       
			serverproperty ('ComputerNamePhysicalNetBIOS') as 'Machine'                      
			,@instance_name1 as InstanceName,                      
			(SELECT 'file_type' =                      
		 		CASE                      
		 			WHEN s.groupid <> 0 THEN 'data'                      
		 			WHEN s.groupid = 0 THEN 'log'                      
		 		END) AS 'fileType'                      
		 	, d.dbid as 'DBID'                      
		 	, d.name AS 'DBName'                      
		 	, s.name AS 'LogicalFileName'                      
		 	, s.filename AS 'PhysicalFileName'                      
 		 	, (s.size * 8 / 1024) AS 'FileSizeMB' -- file size in MB                      
 		 	, d.cmptlevel as 'CompatibilityLevel'                      
 		 	, DATABASEPROPERTYEX (d.name,'Recovery') as 'RecoveryModel'                      
 		 	, DATABASEPROPERTYEX (d.name,'Status') as 'DatabaseStatus' ,                     
 		 	--, d.is_published as 'Publisher'                      
 		 	--, d.is_subscribed as 'Subscriber'                      
 		 	--, d.is_distributor as 'Distributor' 
 		 	(SELECT 'is_replication' =                      
			 CASE                      
			WHEN d.category = 1 THEN 'Published'                      
			WHEN d.category = 2 THEN 'subscribed'                      
			WHEN d.category = 4 THEN 'Merge published'
			WHEN d.category = 8 THEN 'merge subscribed'
			Else 'NO replication'
			END) AS 'Is_replication'                      
 		 	, m.mirroring_state as 'MirroringState'                      
			--INTO master.[dbo].[databasedetails]                      
			FROM                      
			sys.sysdatabases d INNER JOIN sys.sysaltfiles s                      
			ON                      
			d.dbid=s.dbid                      
			INNER JOIN sys.database_mirroring m                      
			ON                      
			d.dbid=m.database_id                      
			ORDER BY                      
			d.name                      
          
          
          


--Step 7 :printing Backup details                       

			Select distinct                             
			b.machine_name as 'ServerName',                        
			b.server_name as 'InstanceName',                        
			b.database_name as 'DatabaseName',                            
			d.database_id 'DBID',                            
			CASE b.[type]                                  
			WHEN 'D' THEN 'Full'                                  
			WHEN 'I' THEN 'Differential'                                  
			WHEN 'L' THEN 'Transaction Log'                                  
			END as 'BackupType'                                 
			--INTO [dbo].[backupdetails]                        
			from sys.databases d inner join msdb.dbo.backupset b                            
			On b.database_name =d.name                        


End
else

	begin



--Step 8: If the instance is 2000 this code will be used.

	declare @registry_key4 nvarchar(100)                        
	declare @Host_Name varchar(100)
	declare @CPU varchar(3)
	declare @nodes nvarchar(400)
	set @nodes =null /* We are not able to trap the node names for SQL Server 2000 so far*/
	declare @mirroring varchar(15)
	set @mirroring ='NOT APPLICABLE' /*Mirroring does not exist in SQL Server 2000*/
	Declare @reg_node1 varchar(100)
	Declare @reg_node2 varchar(100)
	Declare @reg_node3 varchar(100)
	Declare @reg_node4 varchar(100)
	  
	SET @reg_node1 = N'Cluster\Nodes\1'
	SET @reg_node2 = N'Cluster\Nodes\2'
	SET @reg_node3 = N'Cluster\Nodes\3'
	SET @reg_node4 = N'Cluster\Nodes\4'
	  
	Declare @image_path1 varchar(100)
	Declare @image_path2 varchar(100)
	Declare @image_path3 varchar(100)
	Declare @image_path4 varchar(100)
	
	set @image_path1=null
	set @image_path2=null
	set @image_path3=null
	set @image_path4=null
	
	
	Exec master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@reg_node1, @value_name='NodeName',@value=@image_path1 OUTPUT
	Exec master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@reg_node2, @value_name='NodeName',@value=@image_path2 OUTPUT
	Exec master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@reg_node3, @value_name='NodeName',@value=@image_path3 OUTPUT
	Exec master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@reg_node4, @value_name='NodeName',@value=@image_path4 OUTPUT
	
    IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'nodes') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)                        
	drop table nodes
	Create table nodes (name varchar (20))
		  insert into nodes values (@image_path1)
		  insert into nodes values (@image_path2)
		  insert into nodes values (@image_path3)
		  insert into nodes values (@image_path4)
		  --declare @Out nvarchar(400)                        
		  --declare @value nvarchar (20)
		  SELECT @Out = COALESCE(@Out+'/' ,'') + name from nodes where name is not null
	  	  
-- Step 9: Reading registry keys for Number of CPUs,Binaries,Startup type ,startup username, errorlogs location and domain.
	
	SET @instance_name = coalesce(convert(nvarchar(100), serverproperty('InstanceName')),'MSSQLSERVER');
	IF @instance_name!='MSSQLSERVER'

	BEGIN
		set @system_instance_name=@instance_name
		set @instance_name='MSSQL$'+@instance_name

		SET @key=N'SYSTEM\CurrentControlSet\Services\' +@instance_name;
		SET @registry_key = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\MSSQLServer\Parameters';
		SET @registry_key1 = N'Software\Microsoft\Microsoft SQL Server\' + @system_instance_name + '\Setup';
		SET @registry_key2 = N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\';
		SET @registry_key4 = N'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
	

		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key1,@value_name='SQLPath',@value=@image_path OUTPUT
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='Start',@value=@startup_type OUTPUT
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='ObjectName',@value=@start_username OUTPUT
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key,@value_name='SQLArg1',@value=@log_directory OUTPUT
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key2,@value_name='Domain',@value=@domain OUTPUT
		EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key4,@value_name='NUMBER_OF_PROCESSORS',@value=@CPU OUTPUT                        
	

	END

	IF @instance_name='MSSQLSERVER'
		BEGIN
			SET @key=N'SYSTEM\CurrentControlSet\Services\' +@instance_name;
			SET @registry_key = N'Software\Microsoft\MSSQLSERVER\MSSQLServer\Parameters';
			SET @registry_key1 = N'Software\Microsoft\MSSQLSERVER\Setup';
			SET @registry_key2 = N'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\';
			SET @registry_key4 = N'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'	                                               

 

			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key1,@value_name='SQLPath',@value=@image_path OUTPUT
			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='Start',@value=@startup_type OUTPUT
			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@key,@value_name='ObjectName',@value=@start_username OUTPUT
			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key,@value_name='SQLArg1',@value=@log_directory OUTPUT
			--EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key1,@value_name='IpAddress',@value=@IpAddress OUTPUT
			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key2,@value_name='Domain',@value=@domain OUTPUT
			EXEC master.dbo.xp_regread 'HKEY_LOCAL_MACHINE',@registry_key4,@value_name='NUMBER_OF_PROCESSORS',@value=@CPU OUTPUT                        	

		END
			set @startuptype= (select 'Start Up Mode' =
					CASE
					WHEN @startup_type=2 then 'AUTOMATIC'
					WHEN @startup_type=3 then 'MANUAL'
					WHEN @startup_type=4 then 'Disabled'
					END)

--Step 10 : Using ipconfig and xp_msver to get physical memory and IP

			IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'tmp') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)                      
			DROP TABLE tmp
			create table tmp (server varchar(100)default cast( serverproperty ('Machinename') as varchar),[index] int, name sysname,internal_value int,character_value varchar(30))
			insert into tmp([index],name,internal_value,character_value) exec xp_msver PhysicalMemory
	
			IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'ipadd') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)                      
			drop table ipadd
			create table ipadd (server varchar(100)default cast( serverproperty ('Machinename') as varchar),IP varchar (100))
			insert into ipadd (IP)exec xp_cmdshell 'ipconfig'
			delete from ipadd where ip not like '%IP Address.%' or IP is null


-- Step 11 : Getting the Server details 

			SELECT  top 1              
			@domain as 'Domain',                      
			serverproperty('Machinename') as 'MachineName',                      
			@CPU as 'CPUCount',
			cast (t.internal_value as bigint) as PhysicalMemoryMB,
			cast(substring ( I.IP , 44,41) as nvarchar(20))as IP_Address,
			serverproperty('Instancename') as 'InstanceName',                      
			@image_path as 'BinariesPath',                      
			@log_directory as 'ErrorLogsLocation',                      
			@start_username as 'StartupUser',                      
			@Startuptype as 'StartupType',                      
			serverproperty('Productlevel') as 'ServicePack',                      
			serverproperty('edition') as 'Edition',                      
			serverproperty('productversion') as 'Version',                      
			serverproperty('collation') as 'Collation',                      
			serverproperty('Isclustered') as 'ISClustered',                      
			@Out as 'ClustreNodes',
			serverproperty('IsFullTextInstalled') as 'ISFullText'                       
			From tmp t inner join IPAdd I
			on t.server = I.server

-- Step 12 : Getting the instance details 

			SELECT                       
			serverproperty ('Machinename') as 'Machine',                      
			serverproperty ('Instancename') as 'InstanceName',                      
			(SELECT 'file_type' =                      
				 CASE                      
				 WHEN s.groupid <> 0 THEN 'data'                      
				 WHEN s.groupid = 0 THEN 'log'                      
			 END) AS 'fileType'                      
			 , d.dbid as 'DBID'                      
			 , d.name AS 'DBName'                      
			 , s.name AS 'LogicalFileName'                      
			 , s.filename AS 'PhysicalFileName'                      
			 , (s.size * 8 / 1024) AS 'FileSizeMB' -- file size in MB                      
			 ,d.cmptlevel as 'CompatibilityLevel'                      
			 , DATABASEPROPERTYEX (d.name,'Recovery') as 'RecoveryModel'                      
			 , DATABASEPROPERTYEX (d.name,'Status') as 'DatabaseStatus' ,                     
			 (SELECT 'is_replication' =                      
			 CASE                      
			 WHEN d.category = 1 THEN 'Published'                      
			 WHEN d.category = 2 THEN 'subscribed'                      
			 WHEN d.category = 4 THEN 'Merge published'
			 WHEN d.category = 8 THEN 'merge subscribed'
			 Else 'NO replication'
			  END) AS 'Is_replication',
			  @Mirroring as 'MirroringState'
			 FROM                      
			sysdatabases d INNER JOIN sysaltfiles s                      
			ON                      
			d.dbid=s.dbid                      
			ORDER BY                      
			d.name                      

-- Step 13 : Getting backup details 

			Select distinct                             
			b.machine_name as 'ServerName',                        
			b.server_name as 'InstanceName',                        
			b.database_name as 'DatabaseName',                            
			d.dbid 'DBID',                            
			CASE b.[type]                                  
			WHEN 'D' THEN 'Full'                                  
			WHEN 'I' THEN 'Differential'                                  
			WHEN 'L' THEN 'Transaction Log'                                  
			END as 'BackupType'                                 
			from sysdatabases d inner join msdb.dbo.backupset b                            
			On b.database_name =d.name   


-- Step 14: Dropping the table we created for IP and Physical memory

			Drop Table TMP
			Drop Table IPADD
			drop table Nodes
		
			end
			go

-- Step 15 : Setting Nulls and Quoted identifier back to Off 

			SET ANSI_NULLS OFF
			GO
			SET QUOTED_IDENTIFIER OFF
			GO



