--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=============================================
-- Author:		???
-- Create date: ???
-- Description:	Adds the newly created server to the CMS server [DBA].[dbo].[ServerList] to include it in DBA monitoring.
--
-- Change Log:
--				SZO	30/01/2017	Updated the variable to connect to [SQLCMS] instead of [SQLDEV].
--				SZO	30/06/2017	Added comment on which values to change. Fixed broken comment section at start of script causing failures.
-- =============================================

--:CONNECT SQLCMS

USE DBA

DECLARE 
		  @server_name			SYSNAME			= $(ConfigInstance) -- Change here for the newly installed server.
		, @server_ip_address	VARCHAR(30)		= NULL
		, @MonitoringActive		BIT				= 1
		, @Notes				NVARCHAR(1000)	= NULL
		, @isSQLServer			BIT				= 1
		, @isProduction			BIT				= 0				-- Potential change here...
		, @isDBAreplicated		BIT				= 1
		, @DBAreplicationType	SYSNAME			= NULL
		, @saPass				SYSNAME			= $(sapwd)

SELECT * FROM dbo.ServerList AS s WHERE s.server_name = @server_name

IF NOT EXISTS (SELECT 1 FROM dbo.ServerList AS s WHERE s.server_name = @server_name) BEGIN

		INSERT INTO [dbo].[ServerList]
				   ([server_name]
				   ,[server_ip_address]
				   ,[MonitoringActive]
				   ,[Notes]
				   ,[isSQLServer]
				   ,[isProduction]
				   ,[isDBAreplicated]
				   ,[DBAreplicationType]
				   ,[adminLogin]
				   ,[adminPassword]
				   ,[monitoringLogin]
				   ,[monitoringPassword])
			 VALUES( @server_name		
				   , @server_ip_address
				   , @MonitoringActive	
				   , @Notes			
				   , @isSQLServer		
				   , @isProduction		
				   , @isDBAreplicated	
				   , @DBAreplicationType
				   , NULL		
				   , NULL	
				   , NULL	
				   , NULL)

END

OPEN SYMMETRIC KEY PasswordColumns DECRYPTION BY CERTIFICATE DBA_Certificate;

UPDATE s
SET monitoringLogin			= 'dbaMonitoringUser'
	, monitoringPassword	= EncryptByKey(Key_GUID('PasswordColumns'), N'Your.Strong.Password.Here.123', 1, HashBytes('SHA1', CONVERT( varbinary, s.ID)))
-- SELECT * 
FROM dbo.ServerList AS s
		LEFT JOIN dbo.ServerProperties AS p
			ON p.server_name = s.server_name
		WHERE isSQLServer = 1
			AND MonitoringActive = 1
			AND s.server_name = @server_name

IF @server_ip_address IS NOT NULL BEGIN
	UPDATE s
	SET [adminLogin]		= 'sa'
		, [adminPassword]	= EncryptByKey(Key_GUID('PasswordColumns'), @saPass, 1, HashBytes('SHA1', CONVERT( varbinary, s.ID)))
	-- SELECT * 
	FROM dbo.ServerList AS s
			LEFT JOIN dbo.ServerProperties AS p
				ON p.server_name = s.server_name
			WHERE isSQLServer = 1
				AND MonitoringActive = 1
				AND s.server_name = @server_name
END
CLOSE SYMMETRIC KEY PasswordColumns
GO
