--identifica os MemObje que mais consomem memória
select * 
from sys.dm_os_memory_objects mo join 
     sys.dm_os_memory_clerks mc 
on mo.page_allocator_address = mc.page_allocator_address 
where mc.type = 'MEMORYCLERK_SQLGENERAL' 
order by pages_in_bytes desc