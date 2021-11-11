DECLARE @HADRName  varchar(25)
SET @HADRName = @@SERVERNAME
select n.group_name,n.replica_server_name,n.node_name,rs.role_desc,
db_name(drs.database_id) as 'DBName',drs.synchronization_state_desc,drs.synchronization_health_desc
from sys.dm_hadr_availability_replica_cluster_nodes n
join sys.dm_hadr_availability_replica_cluster_states cs
on n.replica_server_name = cs.replica_server_name
join sys.dm_hadr_availability_replica_states rs 
on rs.replica_id = cs.replica_id
join sys.dm_hadr_database_replica_states drs
on rs.replica_id=drs.replica_id
where n.replica_server_name <> @HADRName