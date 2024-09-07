REM Finalidade: liberar espaço em disco para DBBackup
REM - Mantendo anterior Fase A
REM - USERS Databases
Del /Q S:\STINWRK1\DBBackup1\Amd_Fin_Apoio_Prod\*.*
Del /Q S:\STINWRK1\DBBackup1\Amd_Fin_Prod\*.*
Del /Q S:\STINWRK1\DBBackup1\Amd_Orc_Prod\*.*
Del /Q S:\STINWRK1\DBBackup1\Amd_Pat_Prod\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\Amd_Prev_Dirf2011\*.*
Del /Q S:\STINWRK1\DBBackup1\Amd_Prev_Teste\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\Amd_Prev_Prod\*.*
Del /Q S:\STINWRK1\DBBackup1\Amd_Tsr_Prod\*.*
Del /Q S:\STINWRK1\DBBackup1\DRLock\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\DRLock_Dirf2011\*.*
Del /Q S:\STINWRK1\DBBackup1\DRLock_Teste\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\Banespinv\*.*
Del /Q S:\STINWRK1\DBBackup1\DbGefin_Bprev\*.*
Del /Q S:\STINWRK1\DBBackup1\DbSeab\*.*
Del /Q S:\STINWRK1\DBBackup1\DbSectr\*.*
Del /Q S:\STINWRK1\DBBackup1\Serel\*.*
REM -- 
Del /Q S:\STINWRK1\DBBackup1\DBAService\*.*
Del /Q S:\STINWRK1\DBBackup1\Intranet\*.*
Del /Q S:\STINWRK1\DBBackup1\IntranetService\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\Isosystem\*.*
REM --
Del /Q S:\STINWRK1\DBBackup1\Ymf_Sac_Prod\*.*
REM -- SYSTEM Databases
Del /Q S:\STINWRK1\DBBackup1\master\*.*
Del /Q S:\STINWRK1\DBBackup1\model\*.*
Del /Q S:\STINWRK1\DBBackup1\msdb\*.*
REM - Mantendo anterior Fase B
MOVE /Y L:\STINWRK\DBBackup\Amd_Fin_Apoio_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Fin_Apoio_Prod
MOVE /Y L:\STINWRK\DBBackup\Amd_Fin_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Fin_Prod
MOVE /Y L:\STINWRK\DBBackup\Amd_Orc_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Orc_Prod
MOVE /Y L:\STINWRK\DBBackup\Amd_Pat_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Pat_Prod
REM -- 
MOVE /Y L:\STINWRK\DBBackup\Amd_Prev_Dirf2010\*.* S:\STINWRK1\DBBackup1\Amd_Prev_Dirf2011
MOVE /Y L:\STINWRK\DBBackup\Amd_Prev_Teste\*.* S:\STINWRK1\DBBackup1\Amd_Prev_Teste
REM -- 
MOVE /Y L:\STINWRK\DBBackup\Amd_Prev_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Prev_Prod
MOVE /Y L:\STINWRK\DBBackup\Amd_Tsr_Prod\*.* S:\STINWRK1\DBBackup1\Amd_Tsr_Prod
MOVE /Y L:\STINWRK\DBBackup\DRLock\*.* S:\STINWRK1\DBBackup1\DRLock
REM -- 
MOVE /Y L:\STINWRK\DBBackup\DRLock_Dirf2011\*.* S:\STINWRK1\DBBackup1\DRLock_Dirf2011
MOVE /Y L:\STINWRK\DBBackup\DRLock_Teste\*.* S:\STINWRK1\DBBackup1\DRLock_Teste
REM --
MOVE /Y L:\STINWRK\DBBackup\Banespinv\*.* S:\STINWRK1\DBBackup1\Banespinv
MOVE /Y L:\STINWRK\DBBackup\DbGefin_Bprev\*.* S:\STINWRK1\DBBackup1\DbGefin_Bprev
MOVE /Y L:\STINWRK\DBBackup\DbSeab\*.* S:\STINWRK1\DBBackup1\DbSeab
MOVE /Y L:\STINWRK\DBBackup\DbSectr\*.* S:\STINWRK1\DBBackup1\DbSectr
MOVE /Y L:\STINWRK\DBBackup\Serel\*.* S:\STINWRK1\DBBackup1\Serel
REM --
MOVE /Y L:\STINWRK\DBBackup\DBAService\*.* S:\STINWRK1\DBBackup1\DBAService
MOVE /Y L:\STINWRK\DBBackup\Intranet\*.* S:\STINWRK1\DBBackup1\Intranet
MOVE /Y L:\STINWRK\DBBackup\IntranetService\*.* S:\STINWRK1\DBBackup1\IntranetService
REM --
MOVE /Y L:\STINWRK\DBBackup\Isosystem\*.* S:\STINWRK1\DBBackup1\Isosystem
REM --
MOVE /Y L:\STINWRK\DBBackup\Ymf_Sac_Prod\*.* S:\STINWRK1\DBBackup1\Ymf_Sac_Prod
REM --
MOVE /Y L:\STINWRK\DBBackup\master\*.* S:\STINWRK1\DBBackup1\master
MOVE /Y L:\STINWRK\DBBackup\model\*.* S:\STINWRK1\DBBackup1\model
MOVE /Y L:\STINWRK\DBBackup\msdb\*.* S:\STINWRK1\DBBackup1\msdb
REM - Final
EXIT
