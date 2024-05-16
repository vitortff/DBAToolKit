DECLARE @HADRName VARCHAR(25)

SET @HADRName = @@SERVERNAME

SELECT n.group_name,
       n.replica_server_name,
       n.node_name,
       rs.role_desc,
       Db_name(drs.database_id) AS 'DBName',
       drs.synchronization_state_desc,
       drs.synchronization_health_desc
FROM   sys.dm_hadr_availability_replica_cluster_nodes n
       JOIN sys.dm_hadr_availability_replica_cluster_states cs
         ON n.replica_server_name = cs.replica_server_name
       JOIN sys.dm_hadr_availability_replica_states rs
         ON rs.replica_id = cs.replica_id
       JOIN sys.dm_hadr_database_replica_states drs
         ON rs.replica_id = drs.replica_id
WHERE  n.replica_server_name <> @HADRName 