--Verificar Locks no banco de dados
SELECT 
CASE WHEN o.name IS NULL THEN 'INDX Row' ELSE o.name END AS table_name, 
	resource_associated_entity_id, 
	request_mode, 
	request_type, 
	request_status, 
	request_session_id, 
	request_owner_type, 
	request_owner_id, 
	resource_type, 
	resource_subtype, 
	resource_database_id 
FROM 
	sys.dm_tran_locks t 
LEFT OUTER JOIN 
	sys.sysobjects o 
ON 
	t.resource_associated_entity_id = o.id
WHERE 
	request_mode in ('X','IX') 
AND 
	resource_type in ('OBJECT')--, 'KEY')  
AND
	resource_database_id = DB_ID(DB_NAME()) 
ORDER BY 
	request_session_id 
go
