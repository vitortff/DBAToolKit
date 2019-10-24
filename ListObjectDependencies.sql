--List Stored procedure parameters
select schema_name(obj.schema_id) as schema_name,
       obj.name as procedure_name,
       case type
            when 'P' then 'SQL Stored Procedure'
            when 'X' then 'Extended stored procedure'
        end as type,
        substring(par.parameters, 0, len(par.parameters)) as parameters
from sys.objects obj
join sys.sql_modules mod
     on mod.object_id = obj.object_id
cross apply (select p.name + ' ' + TYPE_NAME(p.user_type_id) + ', ' 
             from sys.parameters p
             where p.object_id = obj.object_id 
                   and p.parameter_id != 0 
             for xml path ('') ) par (parameters)
where obj.type in ('P', 'X')
order by schema_name,
         procedure_name;

--List stored procedure dependecies
SELECT referencing_id,OBJECT_SCHEMA_NAME ( referencing_id ) 
	+ '.' + 
    OBJECT_NAME(referencing_id) AS referencing_object_name, 
    obj.type_desc AS referencing_object_type, 
    referenced_schema_name + '.' + 
    referenced_entity_name As referenced_object_name
FROM sys.sql_expression_dependencies AS sed
INNER JOIN sys.objects AS obj ON sed.referencing_id = obj.object_id
WHERE referencing_id  IN (SELECT object_id FROM sys.objects WHERE type='P')
GO