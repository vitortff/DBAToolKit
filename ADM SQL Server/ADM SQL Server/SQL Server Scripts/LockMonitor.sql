SELECT
request_session_id as session_id,
'ABACOS' AS DatabaseName,
CASE WHEN o.name IS NULL THEN 'INDX Row' ELSE o.name END as table_name, 
resource_associated_entity_id as table_id, request_mode, request_type, request_status, 
request_owner_type, request_owner_id, resource_type, resource_subtype, resource_database_id 
    FROM sys.dm_tran_locks t LEFT OUTER JOIN .sys.sysobjects o ON 
t.resource_associated_entity_id = o.id
where request_mode in ('X','IX') and resource_type in ('OBJECT')--, 'KEY')  
and resource_database_id = DB_ID('ABACOS') 
ORDER BY request_session_id, request_mode DESC


SELECT
request_session_id as session_id,
'ABACOS_RPL' AS DatabaseName, 
CASE WHEN o.name IS NULL THEN 'INDX Row' ELSE o.name END as table_name, 
resource_associated_entity_id as table_id, request_mode, request_type, request_status, 
request_owner_type, request_owner_id, resource_type, resource_subtype, resource_database_id 
    FROM ABACOS_RPL.sys.dm_tran_locks t LEFT OUTER JOIN ABACOS_RPL.sys.sysobjects o ON 
t.resource_associated_entity_id = o.id
where request_mode in ('X','IX') and resource_type in ('OBJECT')--, 'KEY')  
and resource_database_id = DB_ID('ABACOS_RPL') 
ORDER BY request_session_id, request_mode DESC


