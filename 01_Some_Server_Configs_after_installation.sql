/*
CREATE a file connection.udl to test connectivity
*/
--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================

USE master

--SELECT * FROM sys.configurations
--WHERE name IN (
--  'Show advanced options'
--, 'backup checksum default'
--, 'backup compression default'
--, 'blocked process threshold (s)' 
--, 'cost threshold for parallelism'
--, 'Database Mail XPs'
--, 'max degree of parallelism'
--, 'min server memory (MB)'
--, 'max server memory (MB)'
--, 'optimize for ad hoc workloads'
--, 'remote admin connections'
--, 'xp_cmdshell'
--)

EXECUTE sp_configure 'Show advanced options', 1
RECONFIGURE
-- Only 2014
IF CONVERT(INT, LEFT(CONVERT(SYSNAME, SERVERPROPERTY('ProductVersion')), 2)) > 11 BEGIN
	EXECUTE sp_configure 'backup checksum default', '1'
	RECONFIGURE
END

EXECUTE sp_configure 'backup compression default', '1'
RECONFIGURE

EXECUTE sp_configure 'blocked process threshold (s)', 5
RECONFIGURE

--EXECUTE sp_configure 'clr enabled', '1'
--RECONFIGURE

EXECUTE sp_configure 'cost threshold for parallelism', '50'
RECONFIGURE

EXECUTE sp_configure 'Database Mail XPs', '1'
RECONFIGURE

EXECUTE sp_configure 'optimize for ad hoc workloads', '1'
RECONFIGURE

EXECUTE sp_configure 'remote admin connections', '1'
RECONFIGURE

EXECUTE sp_configure 'xp_cmdshell', '1'
RECONFIGURE

/*
-- maxdop and max memory are now part of the powershell script that configures SQL Server

-- MAXDOP
EXECUTE sp_configure 'max degree of parallelism', '4'
RECONFIGURE

---- Max workers threads
SELECT * FROM sys.configurations
WHERE name  = 'Max Worker Threads'
SELECT max_workers_count FROM sys.dm_os_sys_info

*/

-- MIN and MAX Memory
EXECUTE sp_configure 'min server memory (MB)', '$(MinServerMemory)'
RECONFIGURE

EXECUTE sp_configure 'max server memory (MB)', '$(MaxServerMemory)'
RECONFIGURE
GO

-- Configure retention for ERRORLOG
USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 30
GO

/*
:CONNECT SQL01

-- 
-- MAX memory 
-- https://www.sqlskills.com/blogs/jonathan/wow-an-online-calculator-to-misconfigure-your-sql-server-memory/
-- 

DECLARE @TotalVisibleMemorySizeGB	INT 
DECLARE @TotalVisibleMemorySizeMB	INT
DECLARE @MaxServerMemory			INT

DECLARE @psTable					TABLE(data NVARCHAR(512) NULL)

INSERT INTO @psTable
		EXECUTE xp_cmdshell 'powershell.exe "Get-WmiObject -Class Win32_OperatingSystem | Select-Object Caption, Version, CSDVersion, OSArchitecture, TotalVisibleMemorySize | format-list *"' 

DELETE @psTable WHERE data IS NULL

SELECT @TotalVisibleMemorySizeGB	= CEILING(CONVERT(INT, CEILING(SUM(CONVERT(BIGINT, SUBSTRING(data, CHARINDEX(':', data) + 2, LEN(data))) / 1024.))) / 1024.) FROM @psTable WHERE data LIKE 'TotalVisibleMemorySize%'

-- 1GB + 1GB per each 4GB between 4GB and 16GB + 1GB for each 8GB between 16GB and 256GB + 1GB for each 16GB between 256GB and infinite
SELECT 
		@MaxServerMemory = (
		@TotalVisibleMemorySizeGB - 
		CASE 
			WHEN @TotalVisibleMemorySizeGB < 4					THEN 1
			WHEN @TotalVisibleMemorySizeGB BETWEEN 4 AND 16		THEN 1 + ((@TotalVisibleMemorySizeGB - 4) / 4)
			WHEN @TotalVisibleMemorySizeGB BETWEEN 17 AND 256	THEN 1 + ((16 - 4) / 4) + ((@TotalVisibleMemorySizeGB - 16) / 8)
			WHEN @TotalVisibleMemorySizeGB > 257				THEN 1 + ((16 - 4) / 4) + ((256 - 16) / 8) + ((@TotalVisibleMemorySizeGB - 256) / 16)
		END
		) * 1024

SELECT @TotalVisibleMemorySizeGB AS TotalVisibleMemorySizeGB, @MaxServerMemory AS MaxMemoryMB, @MaxServerMemory / 1024 AS MaxMemoryGB

EXECUTE sp_configure 'max server memory (MB)', @MaxServerMemory 
RECONFIGURE

--xp_cmdshell', '1 [sys].[xp_create_subdir] [sys].[xp_dirtree] [sys].[xp_delete_file]

--*/

--- Change power option to High Performance
EXECUTE xp_cmdshell N'powershell.exe "$GUID = (powercfg /l | ? { $_.Contains(''High'') -and $_.Contains(''GUID'')}).Split()[3];powercfg /setactive $GUID;"'


