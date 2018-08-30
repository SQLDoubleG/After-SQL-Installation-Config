--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================
--=====================================================================================================================================
--CHANGE TO SQLCMD Mode
--=====================================================================================================================================

--:SETVAR publisher "SQL01"
--:SETVAR subscriber "SQL02"

--:CONNECT $(publisher)

--/*
--================================================================
-- Create DBA_programmability susbcription
--================================================================

DECLARE @subscriber SYSNAME = '$(subscriber)'
DECLARE @publisher SYSNAME = '$(publisher)'

use [DBA]

EXECUTE sp_addsubscription @publication = N'DBA_programmability'
, @subscriber = @subscriber
, @destination_db = N'DBA'
, @subscription_type = N'Push'
, @sync_type = N'automatic'
, @article = N'all'
, @update_mode = N'read only'
, @subscriber_type = 0

EXECUTE sp_addpushsubscription_agent @publication = N'DBA_programmability'
, @subscriber = @subscriber
, @subscriber_db = N'DBA'
, @job_login = N'domain\login'
, @job_password = N'Your.Strong.Password.Here.123'
, @subscriber_security_mode = 1
, @frequency_type = 64
, @frequency_interval = 1
, @frequency_relative_interval = 1
, @frequency_recurrence_factor = 0
, @frequency_subday = 4
, @frequency_subday_interval = 5
, @active_start_time_of_day = 0
, @active_end_time_of_day = 235959
, @active_start_date = 0
, @active_end_date = 0
, @dts_package_location = N'Distributor'

--================================================================
-- Reinitialize DBA_programmability susbcription
--================================================================

EXECUTE sp_reinitsubscription @publication = 'DBA_programmability'
    , @article = 'All'   
    , @subscriber = @subscriber  
    , @destination_db =  'DBA'  
    , @for_schema_change =  0  
    , @publisher =  NULL   
    , @ignore_distributor_failure =  1    
    , @invalidate_snapshot =  0   

-- Start the Snapshot Agent job.
EXEC sp_startpublication_snapshot @publication = 'DBA_programmability';

--================================================================
-- Create DBA_tables susbcription
--================================================================

EXECUTE sp_addsubscription @publication = N'DBA_tables'
, @subscriber = @subscriber
, @destination_db = N'DBA'
, @subscription_type = N'Push'
, @sync_type = N'automatic'
, @article = N'all'
, @update_mode = N'read only'
, @subscriber_type = 0

EXECUTE sp_addpushsubscription_agent @publication = N'DBA_tables'
, @subscriber = @subscriber
, @subscriber_db = N'DBA'
, @job_login = N'domain\login'
, @job_password = N'Your.Strong.Password.Here.123'
, @subscriber_security_mode = 1
, @frequency_type = 64
, @frequency_interval = 1
, @frequency_relative_interval = 1
, @frequency_recurrence_factor = 0
, @frequency_subday = 4
, @frequency_subday_interval = 5
, @active_start_time_of_day = 0
, @active_end_time_of_day = 235959
, @active_start_date = 0
, @active_end_date = 0
, @dts_package_location = N'Distributor'


--================================================================
-- Reinitialize DBA_tables susbcription
--================================================================

EXECUTE sp_reinitsubscription @publication = 'DBA_tables'
    , @article = 'All'   
    , @subscriber = @subscriber  
    , @destination_db = 'DBA'  
    , @for_schema_change = 0  
    , @publisher =  NULL   
    , @ignore_distributor_failure = 1    
    , @invalidate_snapshot = 0 -- This will run the snapshot agent


-- Start the Snapshot Agent job.
EXEC sp_startpublication_snapshot @publication = 'DBA_tables';

--*/