--
-- Scripts para identificar tabelas sem Primary Key ou com Primary Key
--
-- Script que apresenta tabelas sem Primary Key: 
USE DB_Mundo; 
SELECT u.name, o.name
FROM sysobjects o
INNER JOIN sysusers u ON o.uid = u.uid
WHERE xtype = 'U' AND NOT EXISTS
(SELECT i.name FROM sysindexes i WHERE o.id = i.id AND (i.status & 2048)<>0)


-- Script que apresenta tabelas com Primary Key e seus nomes:
 
SELECT u.name, o.name, i.name
FROM sysobjects o
INNER JOIN sysindexes i ON o.id = i.id
INNER JOIN sysusers u ON o.uid = u.uid
WHERE (i.status & 2048)<>0

