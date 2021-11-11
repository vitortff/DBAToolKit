-- "PARA CRIAR MIRROR"

-- no principal
CREATE ENDPOINT [OPRMirror] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = (172.16.18.9))
	FOR DATA_MIRRORING (ROLE = PARTNER, ENCRYPTION = DISABLED)

-- no espelho
CREATE ENDPOINT [OPRMirror] 
	STATE=STARTED
	AS TCP (LISTENER_PORT = 5022, LISTENER_IP = (172.16.18.18))
	FOR DATA_MIRRORING (ROLE = PARTNER, ENCRYPTION = DISABLED)

-- verificar
SELECT role_desc, state_desc FROM sys.database_mirroring_endpoints

SELECT type_desc, port FROM sys.tcp_endpoints

-- no espelho
ALTER DATABASE DTCORP SET PARTNER = 'TCP://172.16.18.9:5022'
go
ALTER DATABASE SIOPMCRP SET PARTNER = 'TCP://172.16.18.9:5022'
go


-- no principal
ALTER DATABASE DTCORP SET PARTNER = 'TCP://172.16.18.18:5022'
go
ALTER DATABASE SIOPMCORP SET PARTNER = 'TCP://172.16.18.18:5022'
go


-- no principal

ALTER DATABASE DTCORP SET SAFETY FULL
go
ALTER DATABASE SIOPMCRP SET SAFETY FULL
go


-- para alterar valor de timeout do padrão de 10 segundos para 20 segundos
-- somente no principal

ALTER DATABASE DTCORP SET PARTNER TIMEOUT 20
go
ALTER DATABASE SIOPMCRP SET PARTNER TIMEOUT 20
go

-- para alterar o tamanho da fila de REDO com 100MBytes

-- no principal

ALTER DATABASE DTCORP SET PARTNER REDO_QUEUE 1000MB
go
ALTER DATABASE SIOPMCRP SET PARTNER REDO_QUEUE 1000MB
go



-- "PARA UTILIZAR O MIRROR"

-- para MANUAL failover e inverter papéis

-- no principal

ALTER DATABASE DTCORP SET PARTNER FAILOVER;
go
ALTER DATABASE SIOPMCRP SET PARTNER FAILOVER;
go


-- no principal ou no mirror para suspender o mirror

ALTER DATABASE DTCORP SET PARTNER SUSPEND
go
ALTER DATABASE SIOPMCRP SET PARTNER SUSPEND
go

-- no principal, para continuar o mirror

ALTER DATABASE DTCORP SET PARTNER RESUME
go
ALTER DATABASE SIOPMCRP SET PARTNER RESUME
go


-- para SYNCRONOUS MODE
-- para desfazer o mirror pelo principal ou espelho quando ambos estão SINCRONIZADOS, ou simplesmente remover mirror.
-- ou no espelho, quando principal falhar 

ALTER DATABASE AdventureWorks2019 SET PARTNER OFF
go
ALTER DATABASE SIOPMCRP SET PARTNER OFF
go


-- executar RECOVERY após quebrar o espelhamento 

RESTORE DATABASE DTCORP WITH RECOVERY
go
RESTORE DATABASE SIOPMCRP WITH RECOVERY
go

-- para ASSYNCRONOUS MODE
-- para FORÇAR SERVIÇO ("inverter papéis"), executar no espelho
-- quando o principal está OFF (Fail) e Inspetor também em OFF (High Safety without automatic Failover ou High Performance - Safety OFF)
-- com possível perda de transações 
-- Só se for realmente necessário, pois as tentativas de restabelecer o Principal falharam !!!!

-- no espelho

ALTER DATABASE SIOPMCRP SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS
GO
ALTER DATABASE DTCORP SET PARTNER FORCE_SERVICE_ALLOW_DATA_LOSS
GO

-- principal torna-se o Mirror e estado do espelhamento fica em SUSPENDED, é necessário o RESUME manual

-- Views do sistema para monitorar espelhamento

-- consultar sys.database_mirroring

SELECT 
      DB_NAME(database_id) AS 'DatabaseName'
    , mirroring_role_desc 
    , mirroring_safety_level_desc
    , mirroring_state_desc
    , mirroring_safety_sequence
    , mirroring_role_sequence
    , mirroring_partner_instance
    , mirroring_witness_name
    , mirroring_witness_state_desc
    , mirroring_failover_lsn
FROM sys.database_mirroring
WHERE mirroring_guid IS NOT NULL


-- para alterar modo do espelhamento
USE [master]
GO
ALTER DATABASE [DTCORP] SET SAFETY OFF
GO
ALTER DATABASE [SIOPMCRP] SET SAFETY OFF
GO