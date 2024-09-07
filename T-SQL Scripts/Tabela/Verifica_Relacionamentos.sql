SELECT
	OBJECT_NAME(foreigns_columns.[referenced_object_id]) Parent_Table,
	OBJECT_NAME(foreigns_columns.[parent_object_id]) Child_Table,
	OBJECT_NAME(foreigns_columns.[constraint_object_id]) Key_Name_From_Child_Table,
	parent_columns.name Parent_Col,
	child_columns.name Child_KeyCol
FROM 
	sys.foreign_key_columns foreigns_columns
INNER JOIN 
	sys.columns parent_columns
ON 
	parent_columns.[object_id] = foreigns_columns.[parent_object_id]
AND 
	parent_columns.[column_id] = foreigns_columns.[parent_column_id]
INNER JOIN 
	sys.columns child_columns
ON 
	child_columns.[object_id] = foreigns_columns.[referenced_object_id]
AND 
	child_columns.[column_id] = foreigns_columns.[referenced_column_id]
ORDER BY 
	Parent_Table, 
	Child_Table