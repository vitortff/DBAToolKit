USE DTCORP
go

ALTER TABLE PAT NOCHECK CONSTRAINT ALL
go
ALTER TABLE ARM NOCHECK CONSTRAINT ALL
go
ALTER TABLE VTR NOCHECK CONSTRAINT ALL
go
ALTER TABLE Psi_Vtr NOCHECK CONSTRAINT ALL
go

DELETE FROM PAT 
go

-- (495403 row(s) affected)

DELETE FROM VTR
go

-- (18692 row(s) affected)

-- copia registros


ALTER TABLE PAT WITH CHECK CHECK CONSTRAINT ALL
go
ALTER TABLE ARM WITH CHECK CHECK CONSTRAINT ALL
go
ALTER TABLE VTR WITH CHECK CHECK CONSTRAINT ALL
go
ALTER TABLE Psi_Vtr WITH CHECK CHECK CONSTRAINT ALL
go


-- verifica integridade

USE [DTCORP]
GO


select distinct b.[MATCLECOD], b.[MATSCSCOD], b.[MATGRPCOD], b.[MATSBOCOD], b.[MATTIPCOD] 
from pat b left outer join mat a on 
a.[MATCLECOD] = b.[MATCLECOD] and
a.[MATSCSCOD] = b.[MATSCSCOD] and
a.[MATGRPCOD] = b.[MATGRPCOD] and
a.[MATSBOCOD] = b.[MATSBOCOD] and
a.[MATTIPCOD] = b.[MATTIPCOD] 
where a.[MATCLECOD] is null and a.[MATSCSCOD] is null and  a.[MATGRPCOD] is null 
and  a.[MATSBOCOD] is null and  a.[MATTIPCOD] is null


select a.vtrpatnum from psi_vtr a left outer join vtr b on 
a.vtrpatnum = b.vtrpatnum
where b.vtrpatnum is null


select distinct o.name, f.* from sys.foreign_keys f join sys.objects o on
f.parent_object_id = o.object_id
where is_not_trusted = 1

select * from sys.check_constraints where is_not_trusted = 1


-- extarir registros da MAT, pai da PAT

select * from mat where 
matclecod = 1 and matscscod = 1 and matgrpcod = 40 and matsbocod = 142 and mattipcod = 3


SELECT MATCLECOD
      ,MATSCSCOD
      ,MATGRPCOD
      ,MATSBOCOD
      ,MATTIPCOD
      ,MATTIPDES
      ,MATDGT
      ,MATDURTPON
      ,MATETQFLG
      ,MATHISFLG
      ,MATREMNT
      ,CASE WHEN MATDATMNT < '1753-01-01-00.00.00'
	THEN TIMESTAMP ('1753-01-01-00.00.00')
	ELSE MATDATMNT END AS MATDATMNT 
  FROM PMESP.MAT 
where 
matclecod = 1 and matscscod = 1 and matgrpcod = 40 and matsbocod = 142 and mattipcod = 3

