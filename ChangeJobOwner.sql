DECLARE 
    @CmdUpdateJob VARCHAR(MAX) = '',
    @LoginDestino VARCHAR(100) = 'sa'
 
 
SELECT @CmdUpdateJob += '
EXEC msdb.dbo.sp_update_job @job_id = ''' + CAST(A.job_id AS VARCHAR(50)) + ''', @owner_login_name = ''' + @LoginDestino + ''';'
FROM
    msdb.dbo.sysjobs A
 
 
EXEC(@CmdUpdateJob)