
select case f.type 
when 'R' then 'RIGHT' when 'L' then 'LEFT' else f.type end as PTTSideValues, 
f.name as PTTFunction, rv.value as PTTValues, 
rv.boundary_id as ValuesID, ps.name as PTTScheme, fl.name as PTTFilegroup
from sys.data_spaces ds 
join sys.destination_data_spaces dds on 
ds.data_space_id = dds.partition_scheme_id 
join sys.filegroups fl on
dds.data_space_id = fl.data_space_id 
join sys.partition_schemes ps on
ds.data_space_id = ps.data_space_id 
join sys.partition_functions f on
ps.function_id = f.function_id 
join sys.partition_range_values rv on 
f.function_id = rv.function_id and 
dds.destination_id = rv.boundary_id
order by fl.name

/*
select * from sys.partition_functions

select * from sys.partition_parameters

select * from sys.partition_range_values

select * from sys.partition_schemes

select * from sys.data_spaces

select * from sys.filegroups

select * from sys.destination_data_spaces 

select * from sys.sysfiles

USE [SIOPMCRP]
GO
CREATE PARTITION FUNCTION [RangeTELLOG](datetime) 
AS RANGE RIGHT 
FOR VALUES (N'2007-01-01T00:00:00', N'2007-07-01T00:00:00', N'2008-01-01T00:00:00', N'2008-07-01T00:00:00')
GO
CREATE PARTITION SCHEME [PTTSchTELLOG] 
AS PARTITION [RangeTELLOG] 
TO ([FGTELLOG1], [FGTELLOG2], [FGTELLOG3], [FGTELLOG4], [FGTELLOG5])
GO
*/
/*
USE [SIOPMCRP]
GO
ALTER PARTITION SCHEME PTTSchTELLOG 
NEXT USED FGTELLOG6;
GO
ALTER PARTITION FUNCTION RangeTELLOG ()
SPLIT RANGE ('2009-01-01T00:00:00');
GO
*/
SELECT $PARTITION.RangeTELLOG ('2010-07-01T00:00:00') ; --deve retornar 8
GO

SELECT top 100 * FROM dbo.TELLOG
WHERE $PARTITION.RangeTELLOG(TelLogDat) = 9 ;

--INSERT INTO TELLOG
SELECT TOP 1 
MunCod,
TelLogNum,
'2010-07-01',
TelLogHor,
EvtChmCod,
TelLogCls,
TelLogExn,
TelLogEvt,
TelLogUsrCod,
TelLogUsrTip,
TelLogCpl,
TelLogPa,
TelLogFlg,
TelLogCat,
MunCadCod
FROM TELLOG


