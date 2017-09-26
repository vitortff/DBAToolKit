-- Do not use DBCC SHIRINKFILE on mirror system, instead:
alter database SIOPMCRP modify file 
(name = 'TELLOG_Data2', size = 5120000KB)

-- to verify transactions
dbcc opentran

-- status = 2 means "open tran"
dbcc loginfo('SIOPMCRP')
