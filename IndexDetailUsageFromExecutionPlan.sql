----Getting the specifc index from Plan Cache
--WITH XMLNAMESPACES
--(
--    DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
--)
--, QueryPlans
--AS
--(SELECT 
--    t.text AS QueryText,
--    CAST(p.query_plan AS XML) AS ExecutionPlan,
--	CAST(p.query_plan AS XML).value('(//RelOp/@NodeId)[1]', 'INT') AS NodeId,
--	CAST(p.query_plan AS XML).value('(//RelOp/@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
--	CAST(p.query_plan AS XML).value('(//RelOp/@LogicalOp)[1]', 'VARCHAR(128)') AS LogicalOp,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateRows)[1]', 'FLOAT') AS EstimateRows,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedRowsRead)[1]', 'FLOAT') AS EstimatedRowsRead,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateIO)[1]', 'FLOAT') AS EstimateIO ,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimateCPU)[1]', 'FLOAT') AS EstimateCPU,
--	CAST(p.query_plan AS XML).value('(//RelOp/@AvgRowSize)[1]', 'FLOAT') AS AvgRowSize,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedTotalSubtreeCost)[1]', 'FLOAT') AS EstimatedTotalSubtreeCost,
--	CAST(p.query_plan AS XML).value('(//RelOp/@TableCardinality)[1]', 'FLOAT') AS TableCardinality,
--	CAST(p.query_plan AS XML).value('(//RelOp/@Parallel)[1]', 'FLOAT') AS Parallel,
--	CAST(p.query_plan AS XML).value('(//RelOp/@EstimatedExecutionMode)[1]', 'VARCHAR(128)') AS EstimatedExecutionMode
--FROM 
--    sys.dm_exec_query_stats AS qs
--CROSS APPLY 
--    sys.dm_exec_sql_text(qs.sql_handle) AS t
--CROSS APPLY 
--    sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS p

----Add the index name to check
--WHERE 
--    CAST(p.query_plan AS XML).exist(N'//RelOp//*[@Index="[PK_Person_BusinessEntityID]"]') = 1
--)
--SELECT 
--	*
--FROM 
--	QueryPlans AS qpo;
go
--DECLARE @IndexName NVARCHAR(128) = '[PK_Person_BusinessEntityID]';  -- Replace with your index name

--WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
--SELECT 
--    qs.query_id,
--    qs.plan_id,
--    qt.query_sql_text,
--    qp.query_plan,  -- XML of the query execution plan
--    n.value('(./@PhysicalOp)[1]', 'NVARCHAR(128)') AS PhysicalOperation,
--    n.value('(./IndexScan/@Index)[1]', 'NVARCHAR(128)') AS IndexUsed
--FROM sys.query_store_plan AS qs
--INNER JOIN sys.query_store_query AS q
--    ON qs.query_id = q.query_id
--INNER JOIN sys.query_store_query_text AS qt
--    ON q.query_text_id = qt.query_text_id
--CROSS APPLY sys.dm_exec_query_plan(qs.plan_id) AS qp
--CROSS APPLY qp.query_plan.nodes('//RelOp[IndexScan/@Index or IndexSeek/@Index or IndexUpdate/@Index or ClusteredIndexInsert/@Index or ClusteredIndexUpdate/@Index]') AS r(n)
--WHERE 
--    n.value('(./IndexScan/@Index)[1]', 'NVARCHAR(128)') = @IndexName
--    OR n.value('(./IndexSeek/@Index)[1]', 'NVARCHAR(128)') = @IndexName
--    OR n.value('(./IndexUpdate/@Index)[1]', 'NVARCHAR(128)') = @IndexName
--    OR n.value('(./ClusteredIndexInsert/@Index)[1]', 'NVARCHAR(128)') = @IndexName
--    OR n.value('(./ClusteredIndexUpdate/@Index)[1]', 'NVARCHAR(128)') = @IndexName
--ORDER BY qs.query_id, qs.plan_id;

--Getting the specifc index from Query Store
--WITH XMLNAMESPACES
--(
--    DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
--)
--, QueryPlans
--AS (SELECT 
--		qsq.object_id,
--        CAST(qsp.query_plan AS XML) AS query_plan,
--        qsqt.query_sql_text
--    FROM sys.query_store_query AS qsq
--        JOIN sys.query_store_plan AS qsp
--            ON qsp.query_id = qsq.query_id
--        JOIN sys.query_store_query_text AS qsqt
--            ON qsqt.query_text_id = qsq.query_text_id),
--  QueryPlanObjects
--AS (SELECT qp.object_id,
--           qp.query_plan,
--           qp.query_sql_text,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@NodeId)[1]', 'INT') AS NodeId,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@PhysicalOp)[1]', 'VARCHAR(128)') AS PhysicalOp,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@LogicalOp)[1]', 'VARCHAR(128)') AS LogicalOp,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateRows)[1]', 'FLOAT') AS EstimateRows,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedRowsRead)[1]', 'FLOAT') AS EstimatedRowsRead,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateIO)[1]', 'FLOAT') AS EstimateIO ,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimateCPU)[1]', 'FLOAT') AS EstimateCPU,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@AvgRowSize)[1]', 'FLOAT') AS AvgRowSize,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedTotalSubtreeCost)[1]', 'FLOAT') AS EstimatedTotalSubtreeCost,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@TableCardinality)[1]', 'FLOAT') AS TableCardinality,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@Parallel)[1]', 'FLOAT') AS Parallel,
--		CAST(qp.query_plan AS XML).value('(//RelOp/@EstimatedExecutionMode)[1]', 'VARCHAR(128)') AS EstimatedExecutionMode,
--     --Informações de Índice e Tabelas (para TableScan ou IndexScan)
--    CAST(qp.query_plan AS XML).value('(//IndexScan/Object/@Schema)[1]', 'NVARCHAR(128)') AS IndexSchema,    -- Esquema do Índice
--    CAST(qp.query_plan AS XML).value('(//IndexScan/Object/@Table)[1]', 'NVARCHAR(128)') AS TableName,        -- Nome da Tabela (IndexScan ou TableScan)
--    CAST(qp.query_plan AS XML).value('(//IndexScan/Object/@Index)[1]', 'NVARCHAR(128)') AS IndexName,        -- Nome do Índice (IndexScan)
--    CAST(qp.query_plan AS XML).value('(//TableScan/Object/@Schema)[1]', 'NVARCHAR(128)') AS ScanTableSchema,    -- Esquema da Tabela (TableScan)
--    CAST(qp.query_plan AS XML).value('(//TableScan/Object/@Table)[1]', 'NVARCHAR(128)') AS ScanTableName,    -- Nome da Tabela (TableScan)
    
--     --Informações de Filtro (Predicados de busca)
--    CAST(qp.query_plan AS XML).value('(//Predicate/ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'NVARCHAR(128)') AS SchemaColumnFilter, -- Esquema da Coluna no Filtro
--    CAST(qp.query_plan AS XML).value('(//Predicate/ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'NVARCHAR(128)') AS TableFilterColumn,   -- Tabela da Coluna no Filtro
--    CAST(qp.query_plan AS XML).value('(//Predicate/ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'NVARCHAR(128)') AS FilterColumn,       -- Coluna no Filtro
    
--     --Condições de Pesquisa (SeekPredicates para Index Seek)
--    CAST(qp.query_plan AS XML).value('(SeekPredicates/SeekPredicateNew/RangeColumns/ColumnReference/@Column)[1]', 'NVARCHAR(128)') AS SeekColumn, -- Coluna usada para busca (Seek Predicate)
--    CAST(qp.query_plan AS XML).value('(SeekPredicates/SeekPredicateNew/RangeColumns/ColumnReference/@Table)[1]', 'NVARCHAR(128)') AS SeekTable, -- Tabela da coluna de busca

--     --Ordenações (caso exista uma operação de ordenação)
--    CAST(qp.query_plan AS XML).value('(OrderBy/OrderByColumn/ColumnReference/@Column)[1]', 'NVARCHAR(128)') AS OrderColumn,                  -- Coluna de ordenação (se houver)
--    CAST(qp.query_plan AS XML).value('(OrderBy/OrderByColumn/ColumnReference/@Table)[1]', 'NVARCHAR(128)') AS TableOrderColumn                    -- Tabela da coluna de ordenação (se houver)
--    FROM QueryPlans AS qp
--    WHERE qp.query_plan.exist(N'//RelOp//*[@Index="[PK_Pessoa]"]') = 1)
--SELECT *
--FROM QueryPlanObjects AS qpo;
--go

--WITH XMLData AS (
--    SELECT CAST('<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.564" Build="16.0.1000.6">
--  <BatchSequence>
--    <Batch>
--      <Statements>
--        <StmtSimple StatementText="INSERT INTO Pessoa&#xD;&#xA;SELECT&#xD;&#xA;	FirstName,&#xD;&#xA;	LastName,&#xD;&#xA;	LastName+@email.com&#xD;&#xA;FROM&#xD;&#xA;Person.Person" StatementId="1" StatementCompId="1" StatementType="INSERT" StatementSqlHandle="0x09002E1A7A6B4FD91838AACB78D855183C4A0000000000000000000000000000000000000000000000000000" DatabaseContextSettingsId="2" ParentObjectId="0" StatementParameterizationType="0" RetrievedFromCache="true" StatementSubTreeCost="26.245" StatementEstRows="19972" SecurityPolicyApplied="false" StatementOptmLevel="FULL" QueryHash="0x373526EBC8DF713F" QueryPlanHash="0xE0CFFB9B9ACEACC6" CardinalityEstimationModelVersion="160">
--          <StatementSetOptions QUOTED_IDENTIFIER="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" NUMERIC_ROUNDABORT="false" />
--          <QueryPlan CachedPlanSize="40" CompileTime="6" CompileCPU="4" CompileMemory="264">
--            <MemoryGrantInfo SerialRequiredMemory="0" SerialDesiredMemory="0" GrantedMemory="0" MaxUsedMemory="0" />
--            <OptimizerHardwareDependentProperties EstimatedAvailableMemoryGrant="235069" EstimatedPagesCached="205685" EstimatedAvailableDegreeOfParallelism="7" MaxCompileMemory="8226848" />
--            <RelOp NodeId="0" PhysicalOp="Index Insert" LogicalOp="Insert" EstimateRows="19972" EstimateIO="8.48678" EstimateCPU="0.019972" AvgRowSize="9" EstimatedTotalSubtreeCost="26.245" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--              <OutputList />
--              <Update WithUnorderedPrefetch="1" DMLRequestSort="0">
--                <Object Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Index="[IDX_SobreNomePessoa]" IndexKind="NonClustered" Storage="RowStore" />
--                <SetPredicate>
--                  <ScalarOperator ScalarString="[CodPessoa1010] = [AdventureWorks2022].[dbo].[Pessoa].[CodPessoa],[SobreNomePessoa1011] = [AdventureWorks2022].[dbo].[Pessoa].[SobreNomePessoa]">
--                    <ScalarExpressionList>
--                      <ScalarOperator>
--                        <MultipleAssign>
--                          <Assign>
--                            <ColumnReference Column="CodPessoa1010" />
--                            <ScalarOperator>
--                              <Identifier>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                              </Identifier>
--                            </ScalarOperator>
--                          </Assign>
--                          <Assign>
--                            <ColumnReference Column="SobreNomePessoa1011" />
--                            <ScalarOperator>
--                              <Identifier>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                              </Identifier>
--                            </ScalarOperator>
--                          </Assign>
--                        </MultipleAssign>
--                      </ScalarOperator>
--                    </ScalarExpressionList>
--                  </ScalarOperator>
--                </SetPredicate>
--                <RelOp NodeId="2" PhysicalOp="Clustered Index Insert" LogicalOp="Insert" EstimateRows="19972" EstimateIO="17.6128" EstimateCPU="0.019972" AvgRowSize="515" EstimatedTotalSubtreeCost="17.7383" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                  <OutputList>
--                    <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                    <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                  </OutputList>
--                  <Update WithUnorderedPrefetch="1" DMLRequestSort="0">
--                    <Object Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Index="[PK_Pessoa]" IndexKind="Clustered" Storage="RowStore" />
--                    <SetPredicate>
--                      <ScalarOperator ScalarString="[AdventureWorks2022].[dbo].[Pessoa].[NomePessoa] = [Expr1005],[AdventureWorks2022].[dbo].[Pessoa].[SobreNomePessoa] = [Expr1006],[AdventureWorks2022].[dbo].[Pessoa].[EmailPessoa] = [Expr1007],[AdventureWorks2022].[dbo].[Pessoa].[CodPessoa] = [Expr1004]">
--                        <ScalarExpressionList>
--                          <ScalarOperator>
--                            <MultipleAssign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="NomePessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1005" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1006" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="EmailPessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1007" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1004" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                            </MultipleAssign>
--                          </ScalarOperator>
--                        </ScalarExpressionList>
--                      </ScalarOperator>
--                    </SetPredicate>
--                    <RelOp NodeId="4" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="19972" EstimateIO="0" EstimateCPU="0.0019972" AvgRowSize="1069" EstimatedTotalSubtreeCost="0.105542" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                      <OutputList>
--                        <ColumnReference Column="Expr1004" />
--                        <ColumnReference Column="Expr1005" />
--                        <ColumnReference Column="Expr1006" />
--                        <ColumnReference Column="Expr1007" />
--                      </OutputList>
--                      <ComputeScalar>
--                        <DefinedValues>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1005" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(100),[AdventureWorks2022].[Person].[Person].[FirstName],0)">
--                              <Convert DataType="varchar" Length="100" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1006" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(1000),[AdventureWorks2022].[Person].[Person].[LastName],0)">
--                              <Convert DataType="varchar" Length="1000" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1007" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(1000),[AdventureWorks2022].[Person].[Person].[LastName]+N@email.com,0)">
--                              <Convert DataType="varchar" Length="1000" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Arithmetic Operation="ADD">
--                                    <ScalarOperator>
--                                      <Identifier>
--                                        <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                      </Identifier>
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="N@email.com" />
--                                    </ScalarOperator>
--                                  </Arithmetic>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                        </DefinedValues>
--                        <RelOp NodeId="5" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="19972" EstimateIO="0" EstimateCPU="0.0019972" AvgRowSize="117" EstimatedTotalSubtreeCost="0.103545" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                          <OutputList>
--                            <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                            <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                            <ColumnReference Column="Expr1004" />
--                          </OutputList>
--                          <ComputeScalar ComputeSequence="1">
--                            <DefinedValues>
--                              <DefinedValue>
--                                <ColumnReference Column="Expr1004" />
--                                <ScalarOperator ScalarString="getidentity((1575676661),(5),NULL)">
--                                  <Intrinsic FunctionName="getidentity">
--                                    <ScalarOperator>
--                                      <Const ConstValue="(1575676661)" />
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="(5)" />
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="NULL" />
--                                    </ScalarOperator>
--                                  </Intrinsic>
--                                </ScalarOperator>
--                              </DefinedValue>
--                            </DefinedValues>
--                            <RelOp NodeId="6" PhysicalOp="Index Scan" LogicalOp="Index Scan" EstimateRows="19972" EstimatedRowsRead="19972" EstimateIO="0.0794213" EstimateCPU="0.0221262" AvgRowSize="113" EstimatedTotalSubtreeCost="0.101547" TableCardinality="19972" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                              <OutputList>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                              </OutputList>
--                              <IndexScan Ordered="0" ForcedIndex="0" ForceSeek="0" ForceScan="0" NoExpandHint="0" Storage="RowStore">
--                                <DefinedValues>
--                                  <DefinedValue>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                  </DefinedValue>
--                                  <DefinedValue>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                  </DefinedValue>
--                                </DefinedValues>
--                                <Object Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Index="[IX_Person_LastName_FirstName_MiddleName]" IndexKind="NonClustered" Storage="RowStore" />
--                              </IndexScan>
--                            </RelOp>
--                          </ComputeScalar>
--                        </RelOp>
--                      </ComputeScalar>
--                    </RelOp>
--                  </Update>
--                </RelOp>
--              </Update>
--            </RelOp>
--          </QueryPlan>
--        </StmtSimple>
--      </Statements>
--    </Batch>
--  </BatchSequence>
--</ShowPlanXML>' AS XML) AS QueryPlanXML
--)
---- Recursively extracting elements and attributes
--, RecursiveXML AS (
--    SELECT 
--        QueryPlanXML AS CurrentXML,
--        CAST('/' AS NVARCHAR(MAX)) AS XPath,  -- Explicitly setting the type to NVARCHAR(MAX)
--        QueryPlanXML.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
--        QueryPlanXML.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
--        0 AS Depth
--    FROM XMLData

--    UNION ALL
--	--Window Function? (RowNumber) --
--    SELECT 
--        child.node.query('.') AS CurrentXML,
--        CAST(CONCAT(X.XPath, '/', child.node.value('local-name(.)', 'NVARCHAR(100)')) AS NVARCHAR(MAX)) AS XPath, -- Explicitly setting the type to NVARCHAR(MAX)
--        child.node.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
--        child.node.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
--        --Fix this value to NodeId 
--		X.Depth + 1 AS Depth
--    FROM RecursiveXML X
--    CROSS APPLY CurrentXML.nodes('/*/*') AS child(node)
--)
---- Extracting the attributes from each element
--SELECT --DISTINCT
--    R.XPath,
--    R.ElementName,
--    R.NamespaceURI,
--    --Check NodeId Values
--	R.Depth,
--	IIF(attr.value('local-name(.)', 'NVARCHAR(100)')='NodeId',attr.value('.', 'NVARCHAR(MAX)'),NULL) AS NodeId,
--	attr.value('local-name(.)', 'NVARCHAR(100)') AS AttrName,
--    attr.value('.', 'NVARCHAR(MAX)') AS AttrValue
--FROM RecursiveXML R
--CROSS APPLY R.CurrentXML.nodes('//@*') AS A(attr)  -- Selecting all attributes directly
--ORDER BY R.XPath, R.Depth;

--WITH XMLData AS (
--    SELECT CAST('<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.564" Build="16.0.1000.6">
--  <BatchSequence>
--    <Batch>
--      <Statements>
--        <StmtSimple StatementText="INSERT INTO Pessoa&#xD;&#xA;SELECT&#xD;&#xA;	FirstName,&#xD;&#xA;	LastName,&#xD;&#xA;	LastName+@email.com&#xD;&#xA;FROM&#xD;&#xA;Person.Person" StatementId="1" StatementCompId="1" StatementType="INSERT" StatementSqlHandle="0x09002E1A7A6B4FD91838AACB78D855183C4A0000000000000000000000000000000000000000000000000000" DatabaseContextSettingsId="2" ParentObjectId="0" StatementParameterizationType="0" RetrievedFromCache="true" StatementSubTreeCost="26.245" StatementEstRows="19972" SecurityPolicyApplied="false" StatementOptmLevel="FULL" QueryHash="0x373526EBC8DF713F" QueryPlanHash="0xE0CFFB9B9ACEACC6" CardinalityEstimationModelVersion="160">
--          <StatementSetOptions QUOTED_IDENTIFIER="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" NUMERIC_ROUNDABORT="false" />
--          <QueryPlan CachedPlanSize="40" CompileTime="6" CompileCPU="4" CompileMemory="264">
--            <MemoryGrantInfo SerialRequiredMemory="0" SerialDesiredMemory="0" GrantedMemory="0" MaxUsedMemory="0" />
--            <OptimizerHardwareDependentProperties EstimatedAvailableMemoryGrant="235069" EstimatedPagesCached="205685" EstimatedAvailableDegreeOfParallelism="7" MaxCompileMemory="8226848" />
--            <RelOp NodeId="0" PhysicalOp="Index Insert" LogicalOp="Insert" EstimateRows="19972" EstimateIO="8.48678" EstimateCPU="0.019972" AvgRowSize="9" EstimatedTotalSubtreeCost="26.245" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--              <OutputList />
--              <Update WithUnorderedPrefetch="1" DMLRequestSort="0">
--                <Object Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Index="[IDX_SobreNomePessoa]" IndexKind="NonClustered" Storage="RowStore" />
--                <SetPredicate>
--                  <ScalarOperator ScalarString="[CodPessoa1010] = [AdventureWorks2022].[dbo].[Pessoa].[CodPessoa],[SobreNomePessoa1011] = [AdventureWorks2022].[dbo].[Pessoa].[SobreNomePessoa]">
--                    <ScalarExpressionList>
--                      <ScalarOperator>
--                        <MultipleAssign>
--                          <Assign>
--                            <ColumnReference Column="CodPessoa1010" />
--                            <ScalarOperator>
--                              <Identifier>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                              </Identifier>
--                            </ScalarOperator>
--                          </Assign>
--                          <Assign>
--                            <ColumnReference Column="SobreNomePessoa1011" />
--                            <ScalarOperator>
--                              <Identifier>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                              </Identifier>
--                            </ScalarOperator>
--                          </Assign>
--                        </MultipleAssign>
--                      </ScalarOperator>
--                    </ScalarExpressionList>
--                  </ScalarOperator>
--                </SetPredicate>
--                <RelOp NodeId="2" PhysicalOp="Clustered Index Insert" LogicalOp="Insert" EstimateRows="19972" EstimateIO="17.6128" EstimateCPU="0.019972" AvgRowSize="515" EstimatedTotalSubtreeCost="17.7383" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                  <OutputList>
--                    <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                    <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                  </OutputList>
--                  <Update WithUnorderedPrefetch="1" DMLRequestSort="0">
--                    <Object Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Index="[PK_Pessoa]" IndexKind="Clustered" Storage="RowStore" />
--                    <SetPredicate>
--                      <ScalarOperator ScalarString="[AdventureWorks2022].[dbo].[Pessoa].[NomePessoa] = [Expr1005],[AdventureWorks2022].[dbo].[Pessoa].[SobreNomePessoa] = [Expr1006],[AdventureWorks2022].[dbo].[Pessoa].[EmailPessoa] = [Expr1007],[AdventureWorks2022].[dbo].[Pessoa].[CodPessoa] = [Expr1004]">
--                        <ScalarExpressionList>
--                          <ScalarOperator>
--                            <MultipleAssign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="NomePessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1005" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="SobreNomePessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1006" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="EmailPessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1007" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                              <Assign>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[dbo]" Table="[Pessoa]" Column="CodPessoa" />
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Column="Expr1004" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Assign>
--                            </MultipleAssign>
--                          </ScalarOperator>
--                        </ScalarExpressionList>
--                      </ScalarOperator>
--                    </SetPredicate>
--                    <RelOp NodeId="4" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="19972" EstimateIO="0" EstimateCPU="0.0019972" AvgRowSize="1069" EstimatedTotalSubtreeCost="0.105542" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                      <OutputList>
--                        <ColumnReference Column="Expr1004" />
--                        <ColumnReference Column="Expr1005" />
--                        <ColumnReference Column="Expr1006" />
--                        <ColumnReference Column="Expr1007" />
--                      </OutputList>
--                      <ComputeScalar>
--                        <DefinedValues>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1005" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(100),[AdventureWorks2022].[Person].[Person].[FirstName],0)">
--                              <Convert DataType="varchar" Length="100" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1006" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(1000),[AdventureWorks2022].[Person].[Person].[LastName],0)">
--                              <Convert DataType="varchar" Length="1000" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Identifier>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                  </Identifier>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                          <DefinedValue>
--                            <ColumnReference Column="Expr1007" />
--                            <ScalarOperator ScalarString="CONVERT_IMPLICIT(varchar(1000),[AdventureWorks2022].[Person].[Person].[LastName]+N@email.com,0)">
--                              <Convert DataType="varchar" Length="1000" Style="0" Implicit="1">
--                                <ScalarOperator>
--                                  <Arithmetic Operation="ADD">
--                                    <ScalarOperator>
--                                      <Identifier>
--                                        <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                      </Identifier>
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="N@email.com" />
--                                    </ScalarOperator>
--                                  </Arithmetic>
--                                </ScalarOperator>
--                              </Convert>
--                            </ScalarOperator>
--                          </DefinedValue>
--                        </DefinedValues>
--                        <RelOp NodeId="5" PhysicalOp="Compute Scalar" LogicalOp="Compute Scalar" EstimateRows="19972" EstimateIO="0" EstimateCPU="0.0019972" AvgRowSize="117" EstimatedTotalSubtreeCost="0.103545" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                          <OutputList>
--                            <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                            <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                            <ColumnReference Column="Expr1004" />
--                          </OutputList>
--                          <ComputeScalar ComputeSequence="1">
--                            <DefinedValues>
--                              <DefinedValue>
--                                <ColumnReference Column="Expr1004" />
--                                <ScalarOperator ScalarString="getidentity((1575676661),(5),NULL)">
--                                  <Intrinsic FunctionName="getidentity">
--                                    <ScalarOperator>
--                                      <Const ConstValue="(1575676661)" />
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="(5)" />
--                                    </ScalarOperator>
--                                    <ScalarOperator>
--                                      <Const ConstValue="NULL" />
--                                    </ScalarOperator>
--                                  </Intrinsic>
--                                </ScalarOperator>
--                              </DefinedValue>
--                            </DefinedValues>
--                            <RelOp NodeId="6" PhysicalOp="Index Scan" LogicalOp="Index Scan" EstimateRows="19972" EstimatedRowsRead="19972" EstimateIO="0.0794213" EstimateCPU="0.0221262" AvgRowSize="113" EstimatedTotalSubtreeCost="0.101547" TableCardinality="19972" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
--                              <OutputList>
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                              </OutputList>
--                              <IndexScan Ordered="0" ForcedIndex="0" ForceSeek="0" ForceScan="0" NoExpandHint="0" Storage="RowStore">
--                                <DefinedValues>
--                                  <DefinedValue>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="FirstName" />
--                                  </DefinedValue>
--                                  <DefinedValue>
--                                    <ColumnReference Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Column="LastName" />
--                                  </DefinedValue>
--                                </DefinedValues>
--                                <Object Database="[AdventureWorks2022]" Schema="[Person]" Table="[Person]" Index="[IX_Person_LastName_FirstName_MiddleName]" IndexKind="NonClustered" Storage="RowStore" />
--                              </IndexScan>
--                            </RelOp>
--                          </ComputeScalar>
--                        </RelOp>
--                      </ComputeScalar>
--                    </RelOp>
--                  </Update>
--                </RelOp>
--              </Update>
--            </RelOp>
--          </QueryPlan>
--        </StmtSimple>
--      </Statements>
--    </Batch>
--  </BatchSequence>
--</ShowPlanXML>' AS XML) AS QueryPlanXML
--)
-- Recursively extracting elements and attributes
--,
--RecursiveXML AS (
--    SELECT 
--        QueryPlanXML AS CurrentXML,
--        CAST('/' AS NVARCHAR(MAX)) AS XPath,
--        QueryPlanXML.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
--        QueryPlanXML.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
--        0 AS Depth
--    FROM XMLData

--    UNION ALL

--    SELECT 
--        child.node.query('.') AS CurrentXML,
--        CAST(CONCAT(X.XPath, '/', child.node.value('local-name(.)', 'NVARCHAR(100)')) AS NVARCHAR(MAX)) AS XPath,
--        child.node.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
--        child.node.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
--        X.Depth + 1 AS Depth
--    FROM RecursiveXML X
--    CROSS APPLY CurrentXML.nodes('/*/*') AS child(node)
--),
-- Extracting NodeId and other attributes
--ExtractedAttributes AS (
--    SELECT
--        R.XPath,
--        R.ElementName,
--        R.NamespaceURI,
--        R.Depth,
--	   Extract NodeId if present
--        CASE 
--            WHEN attr.value('local-name(.)', 'NVARCHAR(100)') = 'NodeId' 
--                THEN attr.value('.', 'NVARCHAR(MAX)')
--            ELSE NULL 
--        END AS NodeId,
--        attr.value('local-name(.)', 'NVARCHAR(100)') AS AttrName,
--        attr.value('.', 'NVARCHAR(MAX)') AS AttrValue
--    FROM RecursiveXML R
--    CROSS APPLY R.CurrentXML.nodes('//@*') AS A(attr)
--),
-- Generating a sequential number to keep the order and propagate NodeId correctly
--NumberedAttributes AS (
--    SELECT 
--        *,
--        ROW_NUMBER() OVER (ORDER BY Depth) AS RowNum
--    FROM ExtractedAttributes
--),
-- Propagating the NodeId value for all rows until a new one is found
--PropagateNodeId AS (
--    SELECT 
--        RowNum,
--        XPath,
--        ElementName,
--        NamespaceURI,
--        Depth,
--        AttrName,
--        AttrValue,
--         Filling NodeId with the last non-null occurrence
--        MAX(NodeId) OVER (ORDER BY RowNum ROWS UNBOUNDED PRECEDING) AS PropagatedNodeId
--    FROM NumberedAttributes
--)
--SELECT
--	XPath,
--	ElementName,
--	NamespaceURI,
--    PropagatedNodeId AS NodeId,
--    AttrName,
--    AttrValue
--FROM PropagateNodeId
--ORDER BY RowNum;

--SHOW THE EXECUTION PLAN ON ANOTHER RESULTS
--NAVIGATE USING THE QUERY STORE TO SELECT THE EXECUTION PLANS
--TRUCKENTRY OR AUDIT
SET STATISTICS TIME ON

--SELECT cpu, physical_io FROM sysprocesses WHERE spid = @@SPID

--Monitoring the "network time"
--Log on a table
--cursor to execute on multiple plans 
	--save on a table
DECLARE @start_one DATETIME = SYSDATETIME()
DECLARE @end_one DATETIME
--DECLARE @START_CPU
--DECLARE @END_CPU
--DECLARE @START_P_IO
--DECLARE @END_P_IO


	SELECT 
	CAST(query_plan AS XML) AS QueryPlanXML
	FROM sys.query_store_plan AS qs
	INNER JOIN sys.query_store_query AS q
		ON qs.query_id = q.query_id
	INNER JOIN sys.query_store_query_text AS qt
		ON q.query_text_id = qt.query_text_id
	WHERE plan_id = 792 

;WITH XMLData AS (
	SELECT 
	CAST(query_plan AS XML) AS QueryPlanXML
	FROM sys.query_store_plan AS qs
	INNER JOIN sys.query_store_query AS q
		ON qs.query_id = q.query_id
	INNER JOIN sys.query_store_query_text AS qt
		ON q.query_text_id = qt.query_text_id
	WHERE plan_id = 792 
	--query_plan LIKE '%SalesOrderHeader%'
)
-- Recursively extracting elements and attributes
,
RecursiveXML AS (
    SELECT 
        --QueryPlanXML AS FullExecutionPlan,
		QueryPlanXML AS CurrentXML,
        CAST('/' AS NVARCHAR(MAX)) AS XPath,
        QueryPlanXML.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
        QueryPlanXML.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
        0 AS Depth
    FROM XMLData

    UNION ALL

    SELECT 
        --FullExecutionPlan,
		child.node.query('.') AS CurrentXML,
        CAST(CONCAT(X.XPath, '/', child.node.value('local-name(.)', 'NVARCHAR(100)')) AS NVARCHAR(MAX)) AS XPath,
        child.node.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
        child.node.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
        X.Depth + 1 AS Depth
    FROM RecursiveXML X
    CROSS APPLY CurrentXML.nodes('/*/*') AS child(node)
),
-- Extracting NodeId and other attributes
ExtractedAttributes AS (
    SELECT
        --FullExecutionPlan,
		R.XPath,
        R.ElementName,
        R.NamespaceURI,
        R.Depth,
	  -- Extract NodeId if present
        CASE 
            WHEN attr.value('local-name(.)', 'NVARCHAR(100)') = 'NodeId' 
                THEN attr.value('.', 'NVARCHAR(MAX)')
            ELSE NULL 
        END AS NodeId,
        attr.value('local-name(.)', 'NVARCHAR(100)') AS AttrName,
        attr.value('.', 'NVARCHAR(MAX)') AS AttrValue
    FROM RecursiveXML R
    CROSS APPLY R.CurrentXML.nodes('//@*') AS A(attr)
),
-- Generating a sequential number to keep the order and propagate NodeId correctly
NumberedAttributes AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Depth) AS RowNum
    FROM ExtractedAttributes
),
-- Propagating the NodeId value for all rows until a new one is found
PropagateNodeId AS (
    SELECT 
        RowNum,
        XPath,
        ElementName,
        NamespaceURI,
        Depth,
        AttrName,
        AttrValue,
		--FullExecutionPlan,
        -- Filling NodeId with the last non-null occurrence
        MAX(NodeId) OVER (ORDER BY RowNum ROWS UNBOUNDED PRECEDING) AS PropagatedNodeId
    FROM NumberedAttributes
)
SELECT
	XPath,
	ElementName,
	NamespaceURI,
    PropagatedNodeId AS NodeId,
    AttrName,
    AttrValue--,
	--FullExecutionPlan
FROM PropagateNodeId
ORDER BY RowNum

SET @end_one = SYSDATETIME()


DECLARE @start_two DATETIME, @end_two DATETIME
SET @start_two = SYSDATETIME()



;WITH XMLData AS (
	SELECT 
	CAST(query_plan AS XML) AS QueryPlanXML
	FROM sys.query_store_plan AS qs
	INNER JOIN sys.query_store_query AS q
		ON qs.query_id = q.query_id
	INNER JOIN sys.query_store_query_text AS qt
		ON q.query_text_id = qt.query_text_id
	WHERE plan_id = 792 
	--query_plan LIKE '%SalesOrderHeader%'
)
-- Recursively extracting elements and attributes
,
RecursiveXML AS (
    SELECT 
        QueryPlanXML AS FullExecutionPlan,
		QueryPlanXML AS CurrentXML,
        CAST('/' AS NVARCHAR(MAX)) AS XPath,
        QueryPlanXML.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
        QueryPlanXML.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
        0 AS Depth
    FROM XMLData

    UNION ALL

    SELECT 
        FullExecutionPlan,
		child.node.query('.') AS CurrentXML,
        CAST(CONCAT(X.XPath, '/', child.node.value('local-name(.)', 'NVARCHAR(100)')) AS NVARCHAR(MAX)) AS XPath,
        child.node.value('local-name(.)', 'NVARCHAR(100)') AS ElementName,
        child.node.value('namespace-uri(.)', 'NVARCHAR(255)') AS NamespaceURI,
        X.Depth + 1 AS Depth
    FROM RecursiveXML X
    CROSS APPLY CurrentXML.nodes('/*/*') AS child(node)
),
-- Extracting NodeId and other attributes
ExtractedAttributes AS (
    SELECT
        FullExecutionPlan,
		R.XPath,
        R.ElementName,
        R.NamespaceURI,
        R.Depth,
	  -- Extract NodeId if present
        CASE 
            WHEN attr.value('local-name(.)', 'NVARCHAR(100)') = 'NodeId' 
                THEN attr.value('.', 'NVARCHAR(MAX)')
            ELSE NULL 
        END AS NodeId,
        attr.value('local-name(.)', 'NVARCHAR(100)') AS AttrName,
        attr.value('.', 'NVARCHAR(MAX)') AS AttrValue
    FROM RecursiveXML R
    CROSS APPLY R.CurrentXML.nodes('//@*') AS A(attr)
),
-- Generating a sequential number to keep the order and propagate NodeId correctly
NumberedAttributes AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Depth) AS RowNum
    FROM ExtractedAttributes
),
-- Propagating the NodeId value for all rows until a new one is found
PropagateNodeId AS (
    SELECT 
        RowNum,
        XPath,
        ElementName,
        NamespaceURI,
        Depth,
        AttrName,
        AttrValue,
		FullExecutionPlan,
        -- Filling NodeId with the last non-null occurrence
        MAX(NodeId) OVER (ORDER BY RowNum ROWS UNBOUNDED PRECEDING) AS PropagatedNodeId
    FROM NumberedAttributes
)
SELECT
	XPath,
	ElementName,
	NamespaceURI,
    PropagatedNodeId AS NodeId,
    AttrName,
    AttrValue,
	FullExecutionPlan
FROM PropagateNodeId
ORDER BY RowNum

SET @end_two = SYSDATETIME()

SELECT @start_one, @end_one, @start_two, @end_two,
DATEDIFF(MILLISECOND,@start_one,@end_one) AS WithoutFullPlan,
DATEDIFF(MILLISECOND,@start_two,@end_two) AS WithtFullPlan