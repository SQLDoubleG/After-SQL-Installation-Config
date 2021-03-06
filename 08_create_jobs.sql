--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================
--=============================================
-- Author:		RAG
-- Create date: ???
-- Description:	Creates the 'Transaction Log Backup' and 'Database Maintenance' jobs
--
-- Change Log:
--				SZO	11/01/2017	Updated the command for step 2 of 'Database Maintenance' to the most recent version.
--				SZO 16/02/2017	Added script for job 'Persist Index Usage Information'.
--				SZO 30/06/2017	Fixed broken comment section at the very start causing script failure
-- =============================================
--:CONNECT SQL01

/*
 _____                               _   _               _                  ____             _                
|_   _| __ __ _ _ __  ___  __ _  ___| |_(_) ___  _ __   | |    ___   __ _  | __ )  __ _  ___| | ___   _ _ __  
  | || '__/ _` | '_ \/ __|/ _` |/ __| __| |/ _ \| '_ \  | |   / _ \ / _` | |  _ \ / _` |/ __| |/ / | | | '_ \ 
  | || | | (_| | | | \__ \ (_| | (__| |_| | (_) | | | | | |__| (_) | (_| | | |_) | (_| | (__|   <| |_| | |_) |
  |_||_|  \__,_|_| |_|___/\__,_|\___|\__|_|\___/|_| |_| |_____\___/ \__, | |____/ \__,_|\___|_|\_\\__,_| .__/ 
                                                                    |___/                              |_|    
*/

USE [msdb]
GO

DECLARE @owner_login_name_param SYSNAME = N'sa'

/****** Object:  Job [Transaction Log Backup]    Script Date: 05/12/2013 14:50:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 05/12/2013 14:50:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name=N'Transaction Log Backup') BEGIN
	EXECUTE msdb.dbo.sp_delete_job @job_name = N'Transaction Log Backup'
END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Transaction Log Backup', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=@owner_login_name_param, 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Log Backup]    Script Date: 05/12/2013 14:50:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Log Backup', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @dbname		sysname	= NULL
DECLARE @skipUsageValidation	bit	= 1
DECLARE @debugging		bit	= 0

EXECUTE [dbo].[DBA_runLogBackup] 
	@dbname		= @dbname
	,@skipUsageValidation	= @skipUsageValidation
	,@debugging		= @debugging

GO', 
		@database_name=N'master', 
		@flags=0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Working Days - Hourly - 7 to 19', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20130726, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=190001, 
		@schedule_uid=N'd89a50b6-74d9-4094-be09-497c995eab47'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION

GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================
--=============================================
-- Author:		RAG
-- Create date: ???
-- Description:	Creates the 'Transaction Log Backup' and 'Database Maintenance' jobs
--
-- Change Log:
--				SZO	11/01/2017	Updated the command for step 2 of 'Database Maintenance' to the most recent version.
--				SZO 16/02/2017	Added script for job 'Persist Index Usage Information'.
--				SZO 30/06/2017	Fixed broken comment section at the very start causing script failure
-- =============================================

-- DO NOT USE SQLCMD to run this script, connect to the server.
-- SQL Agent tokens do not work in SQLCMD mode.

/*
 ____        _        _                      __  __       _       _                                  
|  _ \  __ _| |_ __ _| |__   __ _ ___  ___  |  \/  | __ _(_)_ __ | |_ ___ _ __   __ _ _ __   ___ ___ 
| | | |/ _` | __/ _` | '_ \ / _` / __|/ _ \ | |\/| |/ _` | | '_ \| __/ _ \ '_ \ / _` | '_ \ / __/ _ \
| |_| | (_| | || (_| | |_) | (_| \__ \  __/ | |  | | (_| | | | | | ||  __/ | | | (_| | | | | (_|  __/
|____/ \__,_|\__\__,_|_.__/ \__,_|___/\___| |_|  |_|\__,_|_|_| |_|\__\___|_| |_|\__,_|_| |_|\___\___|
                                                                                                     
*/

USE [msdb]
GO

DECLARE @owner_login_name_param SYSNAME = N'sa'
DECLARE @output_file_path				NVARCHAR(256) = (SELECT ErrorlogPath FROM DBA.dbo.getInstanceDefaultPaths(@@SERVERNAME))
DECLARE @output_file_index_maintenance	NVARCHAR(256) = @output_file_path + N'Database_Maintenance_Step_01_Index_Maintenance.log'
DECLARE @output_file_stats_maintenance	NVARCHAR(256) = @output_file_path + N'Database_Maintenance_Step_02_Statistics_Maintenance.log'
DECLARE @output_file_run_checkdb		NVARCHAR(256) = @output_file_path + N'Database_Maintenance_Step_03_Run_CheckDB.log'
DECLARE @output_file_backup_databases	NVARCHAR(256) = @output_file_path + N'Database_Maintenance_Step_04_Backup_Databases.log'

/****** Object:  Job [Database Maintenance]    Script Date: 28/06/2016 15:01:26 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 28/06/2016 15:01:26 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1) BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = 'Database Maintenance') BEGIN
	EXECUTE msdb.dbo.sp_delete_job @job_name = N'Database Maintenance'
END

DECLARE @jobId BINARY(16)

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Database Maintenance', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Runs database maintenance according to schedule per database basis

- Index Maintenance, according to schedule in DBA.dbo.DatabaseInformation -> IndexMaintenanceSchedule
- Statistics Maintenance, according to schedule in DBA.dbo.DatabaseInformation -> StatisticsMaintenanceSchedule
- Run DBCC CHECKDB, according to schedule in DBA.dbo.DatabaseInformation -> DBCCSchedule
- Run backups, according to schedule in DBA.dbo.DatabaseInformation -> BackupSchedule
- Rename log files', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DatabaseAdministrators', 
		@job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Index Maintenance]    Script Date: 28/06/2016 15:01:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Index Maintenance', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @dbname sysname
DECLARE @minFragReorganize FLOAT
DECLARE @minFragRebuild FLOAT
DECLARE @minPageCount BIGINT
DECLARE @maxdop TINYINT
DECLARE @batchNo TINYINT
DECLARE @weekDayOverride TINYINT
DECLARE @debugging bit = 0

EXECUTE [dbo].[DBA_indexMaintenance] 
   @dbname = @dbname
  ,@minFragReorganize = @minFragReorganize
  ,@minFragRebuild = @minFragRebuild
  ,@minPageCount = @minPageCount
  ,@maxdop = @maxdop
  ,@batchNo = @batchNo
  ,@weekDayOverride = @weekDayOverride
  ,@debugging = @debugging
GO
', 
		@database_name=N'master', 
		@output_file_name=@output_file_index_maintenance, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Statistics Maintenance]    Script Date: 28/06/2016 15:01:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Statistics Maintenance', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'USE [DBA]
GO

DECLARE @dbname sysname
DECLARE @rowsThreshold int 
DECLARE @percentThreshold decimal(4,1)
DECLARE @sample nvarchar(20)
DECLARE @batchNo TINYINT
DECLARE @weekDayOverride TINYINT
DECLARE @debugging bit = 0


EXECUTE [dbo].[DBA_statisticsMaintenance] 
   @dbname = @dbname
  ,@rowsThreshold = @rowsThreshold
  ,@percentThreshold = @percentThreshold
  ,@sample = @sample
  ,@batchNo = @batchNo
  ,@weekDayOverride = @weekDayOverride
  ,@debugging = @debugging
GO
',
		@database_name=N'master', 
		@output_file_name=@output_file_stats_maintenance, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run CheckDB]    Script Date: 28/06/2016 15:01:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run CheckDB', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @dbname sysname
DECLARE @batchNo TINYINT
DECLARE @weekDayOverride TINYINT
DECLARE @debugging bit = 0

EXECUTE [dbo].[DBA_runCHECKDB] 
   @dbname = @dbname
  ,@batchNo = @batchNo
  ,@weekDayOverride = @weekDayOverride
  ,@debugging = @debugging
GO', 
		@database_name=N'master', 
		@output_file_name=@output_file_run_checkdb, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup Databases]    Script Date: 28/06/2016 15:01:26 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup Databases', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @dbname sysname
DECLARE @isCopyOnly bit
DECLARE @path nvarchar(512)
DECLARE @deleteOldBackups bit
DECLARE @BackupType char(1)
DECLARE @batchNo TINYINT
DECLARE @weekDayOverride TINYINT
DECLARE @debugging bit = 0

EXECUTE [dbo].[DBA_runDatabaseBackup] 
   @dbname = @dbname
  ,@isCopyOnly = @isCopyOnly
  ,@path = @path
  ,@deleteOldBackups = @deleteOldBackups
  ,@BackupType = @BackupType
  ,@batchNo = @batchNo
  ,@weekDayOverride = @weekDayOverride
  ,@debugging = @debugging
GO
', 
		@database_name=N'master', 
		@output_file_name=@output_file_backup_databases, 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Rename Log Files]    Script Date: 18/10/2017 11:57:41 ******/
DECLARE @command NVARCHAR(MAX) = N'USE [DBA]

DECLARE @job_id uniqueidentifier = CONVERT(uniqueidentifier, ' + CHAR(36) + '(ESCAPE_NONE(JOBID))) -- tokens can only be used within job steps
DECLARE @debugging bit = 0

EXECUTE [DBA].[dbo].[DBA_renameJobLogFiles] 
	@job_id		= @job_id
	, @debugging	= @debugging
GO'

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
		@job_name='Database Maintenance', 
		--@job_id=@jobId, 
		@step_name=N'Rename Log Files', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'TSQL',
		@command=@command, 
		@database_name=N'master', 
		@flags=0

IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Day @ 10pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130724, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'91286b2f-c6f4-4daa-8fd0-592f894ecb13'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================
--=============================================
-- Author:		RAG
-- Create date: ???
-- Description:	Creates the 'Transaction Log Backup' and 'Database Maintenance' jobs
--
-- Change Log:
--				SZO	11/01/2017	Updated the command for step 2 of 'Database Maintenance' to the most recent version.
--				SZO 16/02/2017	Added script for job 'Persist Index Usage Information'.
--				SZO 30/06/2017	Fixed broken comment section at the very start causing script failure
-- =============================================
--:CONNECT SQL01


/*
______                   _       _     _____             _               _   _                            _____          __                                 _    _               
| ___ \                 (_)     | |   |_   _|           | |             | | | |                          |_   _|        / _|                               | |  (_)              
| |_/ /  ___  _ __  ___  _  ___ | |_    | |   _ __    __| |  ___ __  __ | | | | ___   __ _   __ _   ___    | |   _ __  | |_   ___   _ __  _ __ ___    __ _ | |_  _   ___   _ __  
|  __/  / _ \| '__|/ __|| |/ __|| __|   | |  | '_ \  / _` | / _ \\ \/ / | | | |/ __| / _` | / _` | / _ \   | |  | '_ \ |  _| / _ \ | '__|| '_ ` _ \  / _` || __|| | / _ \ | '_ \ 
| |    |  __/| |   \__ \| |\__ \| |_   _| |_ | | | || (_| ||  __/ >  <  | |_| |\__ \| (_| || (_| ||  __/  _| |_ | | | || |  | (_) || |   | | | | | || (_| || |_ | || (_) || | | |
\_|     \___||_|   |___/|_||___/ \__|  \___/ |_| |_| \__,_| \___|/_/\_\  \___/ |___/ \__,_| \__, | \___|  \___/ |_| |_||_|   \___/ |_|   |_| |_| |_| \__,_| \__||_| \___/ |_| |_|
                                                                                             __/ |                                                                               
                                                                                            |___/                                                                                
*/

USE [msdb]
GO

/****** Object:  Job [Persist Index Usage Information]    Script Date: 16/02/2017 11:38:15 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Engine Tuning Advisor]    Script Date: 16/02/2017 11:38:15 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Engine Tuning Advisor' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Engine Tuning Advisor'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name=N'Persist Index Usage Information') BEGIN
	EXECUTE msdb.dbo.sp_delete_job @job_name = N'Persist Index Usage Information'
END

DECLARE @jobId BINARY(16)

EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Persist Index Usage Information', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Engine Tuning Advisor', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DatabaseAdministrators', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Persists information into table]    Script Date: 16/02/2017 11:38:15 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Persists information into table', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [DBA]
GO

DECLARE @dbname		sysname
DECLARE @object_id	INT
DECLARE @index_id	INT
DECLARE @debugging	BIT = 0

EXECUTE [dbo].[DBA_indexUsageStatsPersistsHistory] 
   @dbname
  ,@object_id
  ,@index_id
  ,@debugging
GO


', 
		@database_name=N'master', 
		@output_file_name=N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\PersistIndexUsage.log', 
		@flags=2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'CollectorSchedule_Every_60min_half_past', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160629, 
		@active_end_date=99991231, 
		@active_start_time=3000, 
		@active_end_time=235959, 
		@schedule_uid=N'aaf35a10-87b8-4829-9266-10b0b9e3eab4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

--=============================================
-- Author:		RAG
-- Create date: ???
-- Description:	Creates a job that runs on SQL Agent startup to start perfmon data collector.
--
-- Change Log:
--				RAG	09/02/2018	Added email notification and operator when job completes. 
--								We've had problems with permissions from SQL to start the collectors, so this way we can check if that
--								actually has happened
-- =============================================
/*
  ____                   __                                 ____    ____       _                               __                                ____           _   _                 _                  
 |  _ \    ___   _ __   / _|  _ __ ___     ___    _ __     |  _ \  | __ )     / \       _ __     ___   _ __   / _|  _ __ ___     ___    _ __    / ___|   ___   | | | |   ___    ___  | |_    ___    _ __ 
 | |_) |  / _ \ | '__| | |_  | '_ ` _ \   / _ \  | '_ \    | | | | |  _ \    / _ \     | '_ \   / _ \ | '__| | |_  | '_ ` _ \   / _ \  | '_ \  | |      / _ \  | | | |  / _ \  / __| | __|  / _ \  | '__|
 |  __/  |  __/ | |    |  _| | | | | | | | (_) | | | | |   | |_| | | |_) |  / ___ \    | |_) | |  __/ | |    |  _| | | | | | | | (_) | | | | | | |___  | (_) | | | | | |  __/ | (__  | |_  | (_) | | |   
 |_|      \___| |_|    |_|   |_| |_| |_|  \___/  |_| |_|   |____/  |____/  /_/   \_\   | .__/   \___| |_|    |_|   |_| |_| |_|  \___/  |_| |_|  \____|  \___/  |_| |_|  \___|  \___|  \__|  \___/  |_|   
                                                                                       |_|                                                                                                               
*/

USE [msdb];
GO

/****** Object:  Job [Perfmon DBA_Collector]    Script Date: 25/01/2018 11:30:12 ******/
BEGIN TRANSACTION;
DECLARE @ReturnCode INT;
SELECT @ReturnCode = 0;
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 25/01/2018 11:30:12 ******/
IF NOT EXISTS (	  SELECT name
					  FROM msdb.dbo.syscategories
					  WHERE name			   = N'[Uncategorized (Local)]'
							AND category_class = 1) BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class = N'JOB'
	  , @type = N'LOCAL'
	  , @name = N'[Uncategorized (Local)]';
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

END;

IF NOT EXISTS (	  SELECT name
					  FROM msdb.dbo.sysjobs
					  WHERE name = N'Perfmon DBA_perfmonCollector') BEGIN

	DECLARE @jobId BINARY(16);
	EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name = N'Perfmon DBA_perfmonCollector'
	  , @enabled = 1
	  , @notify_level_eventlog = 0
	  ,	@notify_level_email=3
	  ,	@notify_level_netsend=2
	  ,	@notify_level_page=2
	  ,	@notify_email_operator_name=N'DatabaseAdministrators'
	  , @delete_level = 0
	  , @description = N'No description available.'
	  , @category_name = N'[Uncategorized (Local)]'
	  , @owner_login_name = N'sa'
	  , @job_id = @jobId OUTPUT;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	/****** Object:  Step [Start DBA_Collector]    Script Date: 25/01/2018 11:30:12 ******/
	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id = @jobId
	  , @step_name = N'Start DBA_Collector'
	  , @step_id = 1
	  , @cmdexec_success_code = 0
	  , @on_success_action = 1
	  , @on_success_step_id = 0
	  , @on_fail_action = 2
	  , @on_fail_step_id = 0
	  , @retry_attempts = 0
	  , @retry_interval = 0
	  , @os_run_priority = 0
	  , @subsystem = N'PowerShell'
	  , @command = N'logman start DBA_perfmonCollector'
	  , @database_name = N'master'
	  , @flags = 0;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId
	  , @start_step_id = 1;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
	EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id = @jobId
	  , @name = N'On SQL Agent Start'
	  , @enabled = 1
	  , @freq_type = 64
	  , @freq_interval = 0
	  , @freq_subday_type = 0
	  , @freq_subday_interval = 0
	  , @freq_relative_interval = 0
	  , @freq_recurrence_factor = 0
	  , @active_start_date = 20151210
	  , @active_end_date = 99991231
	  , @active_start_time = 0
	  , @active_end_time = 235959
	  , @schedule_uid = N'e05479e9-99c7-49e3-bf8c-ab06dc419efd';
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId
	  , @server_name = N'(local)';
END;


IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
COMMIT TRANSACTION;
GOTO EndSave;
QuitWithRollback:
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION;
EndSave:

GO


--=============================================
-- Author:		RAG
-- Create date: 29/08/2018
-- Description:	Creates a job that cycles the ERRORLOG.
--
-- Change Log:
--				29/08/2018	RAG	Created
--
-- =============================================

/*
█▀▀ █░░█ █▀▀ █░░ █▀▀   █▀▀ █▀▀█ █▀▀█ █▀▀█ █▀▀█ █░░ █▀▀█ █▀▀▀
█░░ █▄▄█ █░░ █░░ █▀▀   █▀▀ █▄▄▀ █▄▄▀ █░░█ █▄▄▀ █░░ █░░█ █░▀█
▀▀▀ ▄▄▄█ ▀▀▀ ▀▀▀ ▀▀▀   ▀▀▀ ▀░▀▀ ▀░▀▀ ▀▀▀▀ ▀░▀▀ ▀▀▀ ▀▀▀▀ ▀▀▀▀
------------------------*/



USE [msdb]
GO

/****** Object:  Job [Cycle ERRORLOG]    Script Date: 29/08/2018 09:01:27 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 29/08/2018 09:01:27 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Server Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Server Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Cycle ERRORLOG', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Cycles the ERRORLOG file every night.', 
		@category_name=N'Server Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cycle ERRORLOG]    Script Date: 29/08/2018 09:01:27 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cycle ERRORLOG', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE sp_cycle_errorlog', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Day @ 10pm', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20130724, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'91286b2f-c6f4-4daa-8fd0-592f894ecb13'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

