DECLARE @DataDeploy DATETIME2(0) = '2013-02-28 23:00:00'

SELECT 'OBJETO '+name+' ALTERADO EM '+CONVERT(VARCHAR,modify_date,120),type_desc FROM 
ABACOS.sys.objects
WHERE modify_date >= @DataDeploy
UNION ALL
SELECT 'OBJETO '+name+' ALTERADO EM '+CONVERT(VARCHAR,modify_date,120),
type_desc FROM 
ABACOS_RPL.sys.objects
WHERE modify_date >= @DataDeploy
UNION ALL
SELECT 'OBJETO '+name+' ALTERADO EM '+CONVERT(VARCHAR,modify_date,120),
type_desc FROM 
ABACOS_SAC.sys.objects
WHERE modify_date >= @DataDeploy