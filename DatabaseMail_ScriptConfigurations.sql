 
use master 
go 
sp_configure 'show advanced options',1 
go 
reconfigure with override 
go 
sp_configure 'Database Mail XPs',1 
--go 
--sp_configure 'SQL Mail XPs',0 
go 
reconfigure 
go 
 
-------------------------------------------------------------------------------------------------- 
-- BEGIN Mail Settings BD_EMAIL_ENVIO 
-------------------------------------------------------------------------------------------------- 
IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'BD_EMAIL_ENVIO')  
  BEGIN 
    --CREATE Profile [BD_EMAIL_ENVIO] 
    EXECUTE msdb.dbo.sysmail_add_profile_sp 
      @profile_name = 'BD_EMAIL_ENVIO', 
      @description  = ''; 
  END --IF EXISTS profile 
   
  IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'AUTOMACAO') 
  BEGIN 
    --CREATE Account [AUTOMACAO] 
    EXECUTE msdb.dbo.sysmail_add_account_sp 
    @account_name            = 'AUTOMACAO', 
    @email_address           = 'automacao@intrumbrasil.com', 
    @display_name            = 'Automação', 
    @replyto_address         = '', 
    @description             = '', 
    @mailserver_name         = 'smtp.office365.com', 
    @mailserver_type         = 'SMTP', 
    @port                    = '587', 
    @username                = 'automacao@intrumbrasil.com', 
    @password                = 'NotTheRealPassword',  
    @use_default_credentials =  0 , 
    @enable_ssl              =  1 ; 
  END --IF EXISTS  account 
   
IF NOT EXISTS(SELECT * 
              FROM msdb.dbo.sysmail_profileaccount pa 
                INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id 
                INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id   
              WHERE p.name = 'BD_EMAIL_ENVIO' 
                AND a.name = 'AUTOMACAO')  
  BEGIN 
    -- Associate Account [AUTOMACAO] to Profile [BD_EMAIL_ENVIO] 
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp 
      @profile_name = 'BD_EMAIL_ENVIO', 
      @account_name = 'AUTOMACAO', 
      @sequence_number = 1 ; 
  END  
--IF EXISTS associate accounts to profiles 
--------------------------------------------------------------------------------------------------- 
-- Drop Settings For BD_EMAIL_ENVIO 
-------------------------------------------------------------------------------------------------- 
/* 
IF EXISTS(SELECT * 
            FROM msdb.dbo.sysmail_profileaccount pa 
              INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id 
              INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id   
            WHERE p.name = 'BD_EMAIL_ENVIO' 
              AND a.name = 'AUTOMACAO') 
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = 'BD_EMAIL_ENVIO',@account_name = 'AUTOMACAO' 
  END  
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'AUTOMACAO') 
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = 'AUTOMACAO' 
  END 
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'BD_EMAIL_ENVIO')  
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_profile_sp @profile_name = 'BD_EMAIL_ENVIO' 
  END 
*/ 
  