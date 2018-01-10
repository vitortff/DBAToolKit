-- Number of connections
Select count(*) As Connections
From sys.dm_exec_connections;

-- Threads by CPU
Select S.cpu_id As CPUID, count(*) As Threads
From sys.dm_os_threads As T
Inner Join sys.dm_os_schedulers As S On S.scheduler_address = T.scheduler_address
Group By S.cpu_id;

-- Threads by NUMA Nodes
Select S.parent_node_id As NUMANode, count(*) As Threads
From sys.dm_os_threads As T
Inner Join sys.dm_os_schedulers As S On S.scheduler_address = T.scheduler_address
Group By S.parent_node_id;