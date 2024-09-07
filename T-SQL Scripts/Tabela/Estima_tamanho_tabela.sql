/**************************************************************************
Descrição: Procedure para estimar o espaço necessário para o armazenamento
de dados na tabela.

Autor: Nilton Pinheiro
HomePage: www.mcdbabrasil.com.br
***************************************************************************/
--Exemplo:

--USE PUBS
--GO
--CREATE TABLE tbsize (col1 int, col2 char(500), col3 varchar(500))
--GO
--sp_tablespace tbsize,10000


-- Estimando o espaço a ser ocupado pelos dados de uma tabela
USE MASTER
GO
CREATE PROCEDURE sp_tablespace
@Tabela varchar(50),
@Num_Rows int, -- Número de linhas estimado
@ClusterIndex int = 1 -- Se 1, será criado clustered index 
		      -- Se 0, não será criado clustered index
           	      -- ** Se nenhum valor for passado, assume 1 como default	
AS

SET NOCOUNT ON

declare @Num_Cols int
declare @Num_Cols_Fix int
declare @Num_Cols_Var int
declare @Null_Bitmap int
declare @Fixed_Data_Size int
declare @Max_Var_Size int
declare @Variable_Data_Size int
declare @Row_Size int
declare @Rows_Per_Page int
declare @Free_Rows_Per_Page int
declare @Num_Pages int
declare @Num_Ext int
declare @Data_Space_Used int

-- Número de colunas da tabela
select @Num_Cols= count(*) 
from syscolumns a,sysobjects b where a.id=b.id
and b.name=@Tabela

-- Número de colunas de tamanho fixo
select @Num_Cols_Fix=count(*) 
from syscolumns a,sysobjects b,systypes c 
where a.id=b.id and c.xusertype=a.xtype 
and b.name=@Tabela and c.variable<>1

-- Número de colunas de tamanho variável
select @Num_Cols_Var=count(*) 
from syscolumns a,sysobjects b,systypes c 
where a.id=b.id and c.xusertype=a.xtype 
and b.name=@Tabela and c.variable=1

-- Soma de bytes de todas as colunas de tamanho fixo
select @Fixed_Data_Size= sum(a.length) 
from syscolumns a,sysobjects b,systypes c 
where a.id=b.id and c.xusertype=a.xtype 
and b.name=@Tabela and c.variable<>1

-- Tamanho máximo de todas as colunas de tamanho variável
select @Max_Var_Size= sum(a.length) 
from syscolumns a,sysobjects b,systypes c 
where a.id=b.id and c.xusertype=a.xtype 
and b.name=@Tabela and c.variable=1

-- Espaço reservado para gerenciar a nulabilidade das colunas de tamanho fixo
select @Null_Bitmap = Convert(int,2 + (( @Num_Cols_Fix + 7) / 8 ))

-- Calcula espaço usado para armazenar as colunas de tamanho variável dentro da linha
-- Este cálcula assume que todas as colunas de tamanho variável estarão 100% full
IF @Num_Cols_Var > 0
   select @Variable_Data_Size = 2 + (@Num_Cols_Var * 2) + @Max_Var_Size
else
   -- Se não existe coluna de tamanho variável, define valor como 0
   select @Variable_Data_Size = 0

-- Calcula o tamanho do registro
-- O final 4 representa o tamanho do cabeçalho do registro
select @Row_Size = @Fixed_Data_Size + @Variable_Data_Size + @Null_Bitmap + 4

-- Quantidade de registros por página.
select @Rows_Per_Page = FLOOR((8096)/(@Row_Size + 2))

-- Calcula o número de linhas livres que será reservado por página de dados
If @ClusterIndex = 1
   --Se tiver clustered índex, assume um FillFactor default de 70
   Select @Free_Rows_Per_Page = FLOOR(8096 * ((100 - 70)/100)/(@Row_Size + 2))
ELSE
   --Se não tiver clustered índex, assume um FillFactor default de 100
   select @Free_Rows_Per_Page = FLOOR(8096 * ((100 - 100)/100)/(@Row_Size + 2))

-- Número de págins para armazenar todas as linhas
SELECT @Num_Pages = CEILING(@Num_Rows/(@Rows_Per_Page-@Free_Rows_Per_Page))

-- Número de extend necessárias para armazenar os dados
select @Num_Ext = CEILING((@Num_Pages)/8)

-- Espaço estimado para armazenar os dados na tabela
select @Data_Space_Used = CEILING(8 * @Num_Pages)

PRINT '==== Espaço estimado para armazenar os dados da tabela: ' + @Tabela +' ===='
PRINT ''
SELECT
'Reg_Por_Pagina'=@Rows_Per_Page,
'Num_Paginas'=@Num_Pages,
'Num_Extend'=@Num_Ext,
'Espaço_Estimado_KB'=@Data_Space_Used
GO