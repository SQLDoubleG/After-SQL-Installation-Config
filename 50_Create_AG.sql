=============================================
-- Author:		???
-- Create date: ???
-- Description:	
--				Creates an AG (Availability Group) connecting the servers [SQL01] and [SQL02\DR],
--					and adds specified databases to the AG. 
--
-- Change Log:
--				SZO	30/01/2017	Commented out certain databases from joining the AG based on them having the status
--									of OFFLINE at the present moment ([OCRPDFConverter], [patentbaseUS]).
--
-- =============================================

--- YOU MUST EXECUTE THE FOLLOWING SCRIPT IN SQLCMD MODE.
:Connect SQL01

USE [master]

GO

CREATE LOGIN [domain\ServiceAccount] FROM WINDOWS

GO

:Connect SQL02\DR

USE [master]

GO

CREATE LOGIN [domain\ServiceAccount] FROM WINDOWS

GO

:Connect SQL01

USE [master]

GO

CREATE ENDPOINT [Hadr_endpoint] 
	AS TCP (LISTENER_PORT = 5022)
	FOR DATA_MIRRORING (ROLE = ALL, ENCRYPTION = REQUIRED ALGORITHM AES)

GO

IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END


GO

use [master]

GO

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [domain\ServiceAccount]

GO

:Connect SQL02\DR

USE [master]


IF NOT EXISTS (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') 
BEGIN
	CREATE ENDPOINT [Hadr_endpoint] 
		AS TCP (LISTENER_PORT = 5022)
		FOR DATA_MIRRORING (ROLE = ALL, ENCRYPTION = REQUIRED ALGORITHM AES)
END


IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [domain\ServiceAccount]

GO

:Connect SQL01

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END

GO

:Connect SQL02\DR

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END

GO

:Connect SQL01

USE [master]

GO

CREATE AVAILABILITY GROUP [SQLAG01]
WITH (AUTOMATED_BACKUP_PREFERENCE = PRIMARY)
FOR DATABASE [TEST]
REPLICA ON N'SQL02\DR' WITH (ENDPOINT_URL = N'TCP://SQL02.domain.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO)),
	N'SQL01' WITH (ENDPOINT_URL = N'TCP://SQL01.domain.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));

GO

:Connect SQL01

USE [master]

GO

ALTER AVAILABILITY GROUP [SQLAG01]
ADD LISTENER N'SQLLN01' (
WITH IP
((N'10.0.0.255', N'255.255.248.0')
)
, PORT=1433);

GO


---- IF THE replica does not exist in the AG, add it

--:Connect SQL01

--USE [master]

--GO

--ALTER AVAILABILITY GROUP [SQLAG01]
--ADD REPLICA ON N'SQL02\DR' WITH (ENDPOINT_URL = N'TCP://SQL02.domain.com:5022', FAILOVER_MODE = MANUAL, AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = NO));

--GO



:Connect SQL02\DR

ALTER AVAILABILITY GROUP [SQLAG01] JOIN;

GO

:Connect SQL02\DR


-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'SQLAG01'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch

GO


:Connect SQL01

ALTER AVAILABILITY GROUP [SQLAG01] ADD DATABASE [TEST2]
GO

:Connect SQL02\DR

ALTER DATABASE [TEST2] SET HADR AVAILABILITY GROUP = [SQLAG01];
GO
