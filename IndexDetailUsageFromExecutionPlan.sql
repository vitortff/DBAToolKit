--Getting the specifc index from Plan Cache
WITH XMLNAMESPACES
(
    DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
, QueryPlans
AS
(SELECT 
    t.text AS QueryText,
    CAST(p.query_plan AS XML) AS ExecutionPlan,
	CAST(p.query_plan AS XML).value('(//RelOp/@NodeId)[1]', 'INT') AS NodeId,
	CAST(p.query_plan AS XML).value('(//RelOp/@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
	CAST(p.query_plan AS XML).value('(//RelOp/@LogicalOp)[1]', 'VARCHAR(128)') AS LogicalOp,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateRows)[1]', 'FLOAT') AS EstimateRows,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedRowsRead)[1]', 'FLOAT') AS EstimatedRowsRead,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateIO)[1]', 'FLOAT') AS EstimateIO ,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateCPU)[1]', 'FLOAT') AS EstimateCPU,
	CAST(p.query_plan AS XML).value('(//RelOp/@AvgRowSize)[1]', 'FLOAT') AS AvgRowSize,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedTotalSubtreeCost)[1]', 'FLOAT') AS EstimatedTotalSubtreeCost,
	CAST(p.query_plan AS XML).value('(//RelOp/@TableCardinality)[1]', 'FLOAT') AS TableCardinality,
	CAST(p.query_plan AS XML).value('(//RelOp/@Parallel)[1]', 'FLOAT') AS Parallel,
	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedExecutionMode)[1]', 'VARCHAR(128)') AS EstimatedExecutionMode
FROM 
    sys.dm_exec_query_stats AS qs
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) AS t
CROSS APPLY 
    sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS p

--Add the index name to check
WHERE 
    CAST(p.query_plan AS XML).exist(N'//RelOp//*[@Index="[PK_Person_BusinessEntityID]"]') = 1
)
SELECT 
	*
FROM 
	QueryPlans AS qpo;


--Getting the specifc index from Query Store
WITH XMLNAMESPACES
(
    DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
, QueryPlans
AS (SELECT 
		qsq.object_id,
        CAST(qsp.query_plan AS XML) AS query_plan,
        qsqt.query_sql_text
    FROM sys.query_store_query AS qsq
        JOIN sys.query_store_plan AS qsp
            ON qsp.query_id = qsq.query_id
        JOIN sys.query_store_query_text AS qsqt
            ON qsqt.query_text_id = qsq.query_text_id),
  QueryPlanObjects
AS (SELECT qp.object_id,
           qp.query_plan,
           qp.query_sql_text,
		CAST(qp.query_plan AS XML).value('(//RelOp/@NodeId)[1]', 'INT') AS NodeId,
		CAST(qp.query_plan AS XML).value('(//RelOp/@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
		CAST(qp.query_plan AS XML).value('(//RelOp/@LogicalOp)[1]', 'VARCHAR(128)') AS LogicalOp,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateRows)[1]', 'FLOAT') AS EstimateRows,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedRowsRead)[1]', 'FLOAT') AS EstimatedRowsRead,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateIO)[1]', 'FLOAT') AS EstimateIO ,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateCPU)[1]', 'FLOAT') AS EstimateCPU,
		CAST(qp.query_plan AS XML).value('(//RelOp/@AvgRowSize)[1]', 'FLOAT') AS AvgRowSize,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedTotalSubtreeCost)[1]', 'FLOAT') AS EstimatedTotalSubtreeCost,
		CAST(qp.query_plan AS XML).value('(//RelOp/@TableCardinality)[1]', 'FLOAT') AS TableCardinality,
		CAST(qp.query_plan AS XML).value('(//RelOp/@Parallel)[1]', 'FLOAT') AS Parallel,
		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedExecutionMode)[1]', 'VARCHAR(128)') AS EstimatedExecutionMode
    FROM QueryPlans AS qp
    WHERE qp.query_plan.exist(N'//RelOp//*[@Index="[PK_Person_BusinessEntityID]"]') = 1)
SELECT *
FROM QueryPlanObjects AS qpo;