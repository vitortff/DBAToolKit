
------------------------------------------------------------------------------------------------------------
--
-- Script para checar o que foi alterado no database após as 18:00 horas
---
---
USE DB_Mundo_1;
CREATE TABLE Nova_Tabela(cod int, descricao varchar(100));

SELECT name, 
 TYPE, 
 type_desc, 
 create_date, 
 modify_date 
FROM sys.objects 
WHERE TYPE IN ('U','V','PK','F','D','P') 
AND modify_date >= Dateadd(HOUR,18,Cast((Cast(Getdate() - 1 AS VARCHAR(12)))AS SMALLDATETIME)) 
ORDER BY modify_date 

--U - Table
--V - View
--PK - Primary Key
--F - Foreign Key
--D - Default Constraint
--P - Procedure
