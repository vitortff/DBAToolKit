-- Query com busca ao usuário W3$GWMAP' apresentando o result 
-- para posterior execução (RESULT TO TEXT - NO GRID)

-- substituir o GRANTREVOKE COPOMONLINE-CPMLAVL/W3$GWMAP
-- executar o GRANT e posterior o REVOKE
-- DTCORP: role CPMLAVL
-- SIOPMCRP: role COPOMONLINE

/*
select 'GRANT '+privilege_type+' ON [DBO].['+ TABLE_NAME+ '] TO [CPMLAVL]'+char(10)+'go'
from INFORMATION_SCHEMA.TABLE_PRIVILEGES WHERE 
GRANTEE = 'W3$GWMAP'
ORDER BY GRANTEE, TABLE_NAME


*/

SELECT dp.NAME,
	p.state_desc COLLATE Latin1_General_CS_AS + ' ' + p.permission_name
	+ ' ON ' + SCHEMA_NAME([schema_id]) + '.' + o.NAME + ' TO ' + dp.NAME AS 'Permissions'
FROM    
	sys.database_permissions p
LEFT JOIN 
	sys.all_objects o
ON     
	p.major_id = o.[OBJECT_ID]	
INNER JOIN 
	sys.database_principals dp
ON
	p.grantee_principal_id = dp.principal_id
WHERE 
dp.name IN ('NT$USERWEB')
ORDER BY dp.name, schema_id, o.NAME


/*
--Listar quais permissões cada usuário tem
--dentro do database
SELECT
	dp.NAME AS principal_name,
	dp.type_desc AS principal_type_desc,
	o.NAME AS [object_name],
	p.permission_name,
	p.state_desc AS permission_state_desc
FROM    
	sys.database_permissions p
LEFT JOIN 
	sys.all_objects o
ON     
	p.major_id = o.[OBJECT_ID]	
INNER JOIN 
	sys.database_principals dp
ON
	p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'DBOPR'


--Qual a database role?
SELECT 
	USR.name AS [User_Name], 
	USR1.name AS Database_Role
FROM 
	SYS.database_role_members DR
INNER JOIN 
	sys.sysusers USR
ON 
	DR.member_principal_id = USR.uid
INNER JOIN 
	sys.sysusers USR1
ON 
	USR1.uid = DR.role_principal_id
WHERE usr.name = 'DBOPR'
*/