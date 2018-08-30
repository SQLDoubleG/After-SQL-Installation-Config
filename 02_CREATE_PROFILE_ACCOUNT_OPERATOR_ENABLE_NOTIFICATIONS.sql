--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================

USE master

SELECT * FROM sys.configurations
WHERE name IN (
  'Show advanced options'
, 'Agent XPs'
, 'Database Mail XPs'
)

IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'show advanced options' AND value_in_use = 1) 
	EXECUTE sp_configure 'show advanced options',1
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'Agent XPs' AND value_in_use = 1) 
	EXECUTE sp_configure 'Agent XPs',1
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = 'Database Mail XPs' AND value_in_use = 1) 
	EXECUTE sp_configure 'Database Mail XPs',1

RECONFIGURE
GO

USE msdb

IF NOT EXISTS (SELECT * FROM dbo.sysoperators WHERE name = N'DatabaseAdministrators') BEGIN 
	EXECUTE msdb.dbo.sp_add_operator @name=N'DatabaseAdministrators', 
			@enabled=1, 
			@weekday_pager_start_time=90000, 
			@weekday_pager_end_time=180000, 
			@saturday_pager_start_time=90000, 
			@saturday_pager_end_time=180000, 
			@sunday_pager_start_time=90000, 
			@sunday_pager_end_time=180000, 
			@pager_days=0, 
			@email_address=N'DatabaseAdministrators@yourdomain.com', 
			@category_name=N'[Uncategorized]'
END 

IF NOT EXISTS (SELECT * FROM dbo.sysmail_account WHERE name = N'Admin Account') BEGIN 

	DECLARE @SERVERNAME SYSNAME = @@SERVERNAME + N' SQL SERVER'
	DECLARE @description SYSNAME = @@SERVERNAME + N' Mail account for administrative e-mail.'

	EXECUTE msdb.dbo.sysmail_add_account_sp
		@account_name = 'Admin Account',
		@description = @description,
		@email_address = 'sqlserver@yourdomain.com',
		@display_name = @SERVERNAME,
		@mailserver_name = 'your.mail.com',
		@port = 25 ;
END 

IF NOT EXISTS (SELECT * 
					FROM dbo.sysmail_profileaccount AS pa 
						INNER JOIN dbo.sysmail_account AS a
							ON a.account_id = pa.account_id
					WHERE a.name = N'Admin Account') BEGIN 

	EXECUTE sysmail_add_profile_sp @profile_name = 'Admin Profile'


	EXECUTE sysmail_add_profileaccount_sp @profile_name = 'Admin Profile'
			, @account_name = 'Admin Account'
			, @sequence_number = 1
END 

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
	@profile_name	=  'Admin Profile'
	, @principal_id = 0
	, @is_default	= 1



/*
Update 
*/

-- Parameter name has changed, so different 
DECLARE @NumVersion INT = CONVERT(INT, LEFT(CONVERT(SYSNAME, SERVERPROPERTY('ProductVersion')), CHARINDEX('.',CONVERT(SYSNAME, SERVERPROPERTY('ProductVersion'))) - 1 ))

IF @NumVersion >= 11 BEGIN
	EXECUTE msdb.dbo.sp_set_sqlagent_properties @databasemail_profile=N'Admin Profile'
END 
ELSE BEGIN 
	EXECUTE msdb.dbo.sp_set_sqlagent_properties @email_profile=N'Admin Profile'
END 

-- Enable agent to use database mail
--EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail'
EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1

EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N'Admin Profile'


GO

-- Configure SLQAgent to keep more history 
USE [msdb]
GO
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000
GO
