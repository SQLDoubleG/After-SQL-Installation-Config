--https://msdn.microsoft.com/en-us/library/hh213291.aspx
USE [master]
GO
CREATE LOGIN [##MS_SSISServerCleanupJobLogin##] WITH PASSWORD=N'Your.Strong.Password.Here.123', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO
    CREATE PROCEDURE [dbo].[sp_ssis_startup]
    AS
    SET NOCOUNT ON
        /* Currently, the IS Store name is 'SSISDB' */
        IF DB_ID('SSISDB') IS NULL
            RETURN
        
        IF NOT EXISTS(SELECT name FROM [SSISDB].sys.procedures WHERE name=N'startup')
            RETURN
         
        /*Invoke the procedure in SSISDB  */
        EXEC [SSISDB].[catalog].[startup] 

GO
EXEC sp_procoption N'[dbo].[sp_ssis_startup]', 'startup', '1'
GO
CREATE Asymmetric key MS_SQLEnableSystemAssemblyLoadingKey
FROM Executable File = 'C:\Program Files\Microsoft SQL Server\120\DTS\Binn\Microsoft.SqlServer.IntegrationServices.Server.dll' 
GO
CREATE Login MS_SQLEnableSystemAssemblyLoadingUser FROM Asymmetric key MS_SQLEnableSystemAssemblyLoadingKey 
GO
Grant unsafe Assembly to MS_SQLEnableSystemAssemblyLoadingUser
GO
EXEC sp_procoption N'sp_ssis_startup','startup','on'
GO

 --To be run on the primary replica.
BACKUP DATABASE [SSISDB] 
TO  DISK = N'\\Shared\SSISDB\SSISDB.bak'
WITH NOFORMAT, NOINIT,  NAME = N'SSISDB-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
BACKUP LOG [SSISDB] 
TO  DISK = N'\\Shared\SSISDB\SSISDB.trn'
WITH NOFORMAT, NOINIT,  NAME = N'SSISDB-Log Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO



--example RESTORE DATABASE commands
RESTORE FILELISTONLY FROM  DISK = N'\\Shared\SSISDB\SSISDB.bak'

RESTORE DATABASE [SSISDB] FROM  DISK = N'\\Shared\SSISDB\SSISDB.bak' 
WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
, MOVE 'data' TO 'F:\SQL\MSSQL12.DR\MSSQL\DATA\SSISDB.mdf'
, MOVE 'log' TO 'F:\SQL\MSSQL12.DR\MSSQL\DATA\SSISDB.ldf'

RESTORE LOG [SSISDB] FROM  DISK = N'\\Shared\SSISDB\SSISDB.trn' 
WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 5
GO

--manually add SSISDB to Availability Group by JOIN ONLY option.
--:Connect SQL01
--GO
--USE [master]
--GO
--ALTER AVAILABILITY GROUP [SQLAG01] ADD DATABASE [SSISDB];
--GO

--:Connect SQL02\DR
--GO
--ALTER DATABASE [SSISDB] SET HADR AVAILABILITY GROUP = [SQLAG01];
--GO


USE [msdb]
GO

/****** Object:  Job [SSIS Server Maintenance Job]    Script Date: 26/08/2015 15:18:39 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 26/08/2015 15:18:39 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SSIS Server Maintenance Job', 
                              @enabled=1, 
                              @notify_level_eventlog=2, 
                              @notify_level_email=0, 
                              @notify_level_netsend=0, 
                              @notify_level_page=0, 
                              @delete_level=0, 
                              @description=N'Runs every day. The job removes operation records from the database that are outside the retention window and maintains a maximum number of versions per project.', 
                              @category_name=N'[Uncategorized (Local)]', 
                              @owner_login_name=N'##MS_SSISServerCleanupJobLogin##', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSIS Server Operation Records Maintenance]    Script Date: 26/08/2015 15:18:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SSIS Server Operation Records Maintenance', 
                              @step_id=1, 
                              @cmdexec_success_code=0, 
                              @on_success_action=3, 
                              @on_success_step_id=0, 
                              @on_fail_action=2, 
                              @on_fail_step_id=0, 
                              @retry_attempts=3, 
                              @retry_interval=3, 
                              @os_run_priority=0, @subsystem=N'TSQL', 
                              @command=N'EXEC [internal].[cleanup_server_retention_window]', 
                              @database_name=N'SSISDB', 
                              @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SSIS Server Max Version Per Project Maintenance]    Script Date: 26/08/2015 15:18:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SSIS Server Max Version Per Project Maintenance', 
                              @step_id=2, 
                              @cmdexec_success_code=0, 
                              @on_success_action=1, 
                              @on_success_step_id=0, 
                              @on_fail_action=2, 
                              @on_fail_step_id=0, 
                              @retry_attempts=3, 
                              @retry_interval=3, 
                              @os_run_priority=0, @subsystem=N'TSQL', 
                              @command=N'EXEC [internal].[cleanup_server_project_version]', 
                              @database_name=N'SSISDB', 
                              @flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SSISDB Scheduler', 
                              @enabled=1, 
                              @freq_type=4, 
                              @freq_interval=1, 
                              @freq_subday_type=1, 
                              @freq_subday_interval=0, 
                              @freq_relative_interval=0, 
                              @freq_recurrence_factor=0, 
                              @active_start_date=20001231, 
                              @active_end_date=99991231, 
                              @active_start_time=0, 
                              @active_end_time=120000
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO