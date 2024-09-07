---
-- Número de Linhas por tabela no database
--
USE DB_Mundo; 
SELECT *, o.name AS "Nome da Tabela", i.rowcnt AS "Total de Linhas"
FROM sysobjects o, sysindexes i WHERE i.id = o.id
AND indid IN(0,1) AND o.name <> 'sysdiagrams' AND o.xtype = 'U'

or

SELECT o.name AS "Nome da Tabela", i.rowcnt AS "Total de Linhas"
FROM sysobjects o, sysindexes i WHERE i.id = o.id
AND indid IN(0,1) AND o.name <> 'sysdiagrams' AND o.xtype = 'U' 
order by i.rowcnt desc 
