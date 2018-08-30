--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================================================
--CHANGE TO SQLCMD Mode
--=====================================================================================================================================
--================================================================
-- Grant permissions to [dbaMonitoringUser]
--================================================================

--:SETVAR subscriber "SQL02"

--:CONNECT $(subscriber)

USE [DBA]
GO
GRANT EXECUTE ON OBJECT::[dbo].[DBA_auditGetDatabaseInformation]	TO [dbaMonitoringUser] 
GO
GRANT EXECUTE ON OBJECT::[dbo].[DBA_auditGetServerConfigurations]	TO [dbaMonitoringUser] 
GO
GRANT EXECUTE ON OBJECT::[dbo].[DBA_auditGetServerDisksInformation] TO [dbaMonitoringUser] 
GO
GRANT EXECUTE ON OBJECT::[dbo].[DBA_auditGetServerInformation]		TO [dbaMonitoringUser] 
GO
GRANT EXECUTE ON OBJECT::[dbo].[DBA_auditGetServerProperties]		TO [dbaMonitoringUser] 
GO


