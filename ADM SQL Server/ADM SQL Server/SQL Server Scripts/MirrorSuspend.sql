-- no principal ou no mirror para suspender o mirror

ALTER DATABASE DTCORP SET PARTNER SUSPEND
go
ALTER DATABASE SIOPMCRP SET PARTNER SUSPEND
go

-- no principal, para continuar o mirror

--ALTER DATABASE DTCORP SET PARTNER RESUME
--go
--ALTER DATABASE SIOPMCRP SET PARTNER RESUME
--go

-- verificar estado do mirror

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


