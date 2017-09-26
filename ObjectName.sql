select schema_name(schema_id) as schemaname, name as table_name, create_date, modify_date, type, object_id 
from sys.objects 
where schema_id = schema_id('SchCRP') and type = 'U'
order by name