--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--=====================================================================================================================================
--CHANGE TO SQLCMD Mode
--=====================================================================================================================================
--=============================================
-- Author:		???
-- Create date: ???
-- Description:	Creates the [DBA] database, required functions and principals, and replication from SQLCMS.
--
-- Change Log:
--				SZO	11/01/2017	Changed the publication from 'DBA' to 'DBA_programmability' to match up with SQLCMS.
--									Removed creation of DBCC_History table as it will be created by replication
--				SZO 27/01/2017	Changed the comment to reinitalize subscription from 'DBA' to 'DBA_programmability' to match up with [SQLCMS].
--				RAG 26/10/2017	Changed the path to be with user databases not system databases
--
-- =============================================
--:CONNECT SQL01

USE [master]
GO

IF DB_ID('DBA') IS NOT NULL BEGIN
	ALTER DATABASE [DBA] SET SINGLE_USER WITH ROLLBACK AFTER 10
	DROP DATABASE DBA
END

-- Create the folder for DBA database.
USE master;
GO

DECLARE @createStmt NVARCHAR(MAX) 
DECLARE @dataPath NVARCHAR(1024) = CONVERT(NVARCHAR(512), SERVERPROPERTY('InstanceDefaultDataPath')) + 'DBA\'
DECLARE @LogPath NVARCHAR(1024) = CONVERT(NVARCHAR(512), SERVERPROPERTY('InstanceDefaultLogPath')) + 'DBA\'

-- Create folder 
PRINT 'EXEC master..xp_cmdshell ''if not exist "' + @dataPath + '". md "' + @dataPath + '".'''
PRINT 'EXEC master..xp_cmdshell ''if not exist "' + @LogPath + '". md "' + @LogPath + '".'''

EXEC ('EXEC master..xp_cmdshell ''if not exist "' + @dataPath + '". md "' + @dataPath + '".''')
EXEC ('EXEC master..xp_cmdshell ''if not exist "' + @LogPath + '". md "' + @LogPath + '".''')

SELECT @dataPath	+= 'DBA.mdf'
SELECT @LogPath		+= 'DBA.ldf'

SELECT @dataPath AS DataPath, @LogPath AS LogPath

SELECT @createStmt = 
N'CREATE DATABASE [DBA]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N''DBA'', FILENAME = N''' + @dataPath + ''' , SIZE = 128MB , MAXSIZE = UNLIMITED, FILEGROWTH = 128MB )
 LOG ON 
( NAME = N''DBA_log'', FILENAME = N''' + @LogPath + ''' , SIZE = 64MB, MAXSIZE = 2048GB , FILEGROWTH = 64MB)
COLLATE Latin1_General_CI_AS'

EXECUTE sys.sp_executesql @createStmt
GO

ALTER DATABASE [DBA] SET COMPATIBILITY_LEVEL = 100
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
	EXEC [DBA].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [DBA] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [DBA] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [DBA] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [DBA] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [DBA] SET ARITHABORT OFF 
GO

ALTER DATABASE [DBA] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [DBA] SET AUTO_CREATE_STATISTICS ON 
GO

ALTER DATABASE [DBA] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [DBA] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [DBA] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [DBA] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [DBA] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [DBA] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [DBA] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [DBA] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [DBA] SET  DISABLE_BROKER 
GO

ALTER DATABASE [DBA] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [DBA] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [DBA] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [DBA] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [DBA] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [DBA] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [DBA] SET RECOVERY SIMPLE 
GO

ALTER DATABASE [DBA] SET  MULTI_USER 
GO

ALTER DATABASE [DBA] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [DBA] SET DB_CHAINING OFF 
GO

ALTER DATABASE [DBA] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [DBA] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO

ALTER DATABASE [DBA] SET  READ_WRITE 
GO



ALTER AUTHORIZATION ON DATABASE::DBA TO [sa]
GO

ALTER DATABASE [DBA] SET TRUSTWORTHY ON 
GO


--==========================================================================
-- Create replication agent process account from the central repository 
--	if this database is a subscriber
--==========================================================================

IF SUSER_ID('xxx') IS NULL CREATE LOGIN [xxx] FROM WINDOWS
GO
USE DBA

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'xxx') BEGIN
	CREATE USER [xxx] FROM LOGIN [xxx]
END

USE DBA

ALTER ROLE [db_owner] ADD MEMBER [xxx]
GO

--EXECUTE sp_addrolemember 'db_owner', 'xxx'


USE master

EXECUTE sp_configure 'show advanced option', 1
RECONFIGURE

EXECUTE sp_configure 'xp_cmdshell', 1
RECONFIGURE

EXECUTE sp_configure 'Database Mail XPs', 1
RECONFIGURE

--==============================================================================================
-- Create this function prior the subscriptions 
--==============================================================================================
USE [DBA]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_SQLVersion]    Script Date: 12/11/2014 10:10:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[fn_SQLVersion]
(	
	@ProductVersion NVARCHAR(128)
)

RETURNS NVARCHAR(50)

AS

-- =============================================
-- Author:		Raul Gonzalez
-- Create date: 25/06/2013
-- Description:	Function to return SQL Version (e.g. 2005, 2008 R2) from Version Number (e.g. 9.0, 10.5)
-- =============================================

BEGIN

DECLARE @Result NVARCHAR(50)

SELECT @Result = CASE 
		WHEN @ProductVersion LIKE '14.%' THEN 'SQL Server 2017'
		WHEN @ProductVersion LIKE '13.%' THEN 'SQL Server 2016'
		WHEN @ProductVersion LIKE '12.%' THEN 'SQL Server 2014'
		WHEN @ProductVersion LIKE '11.%' THEN 'SQL Server 2012'
		WHEN @ProductVersion LIKE '10.5%' THEN 'SQL Server 2008 R2'
		WHEN @ProductVersion LIKE '10.%' THEN 'SQL Server 2008'
		WHEN @ProductVersion LIKE '9.%' THEN 'SQL Server 2005'
		WHEN @ProductVersion LIKE '8.%' THEN 'SQL Server 2000'
		WHEN @ProductVersion IS NULL THEN NULL
		ELSE 'SQL 7 or earlier'
			
		END

RETURN @Result

END


GO

--==============================================================================================
-- Create this table prior the subscriptions 
--==============================================================================================

USE [DBA]
GO

/****** Object:  Table [dbo].[DBCC_History]    Script Date: 31/05/2016 08:16:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBCC_History](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[server_name] [sysname] NOT NULL,
	[name] [sysname] NOT NULL,
	[DBCC_datetime] [datetime2](0) NULL,
	[DBCC_duration] [varchar](24) NULL,
	[isPhysicalOnly] [bit] NULL,
	[isDataPurity] [bit] NULL,
	[ErrorNumber] [int] NULL,
	[command] [varchar](20) NOT NULL,
 CONSTRAINT [PK_DBCC_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DBCC_History] ADD  CONSTRAINT [DF_DBCC_History_command_CHECKDB]  DEFAULT ('CHECKDB') FOR [command]
GO



GO

SET ANSI_PADDING OFF
GO

--================================================================
-- Create monitoring user before running the snapshot agent for both publications
--================================================================

USE master
GO
IF SUSER_ID('dbaMonitoringUser') IS NULL BEGIN 
	CREATE LOGIN [dbaMonitoringUser] 
		WITH PASSWORD = N'Your.Strong.Pass.Here.123'
				, SID = 0x5631BAD7B0C1694CBFCF4EA3AFF4E88E
				, DEFAULT_DATABASE = [DBA]
				, CHECK_POLICY = ON
				, CHECK_EXPIRATION = OFF
END
GO

USE [DBA]
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'dbaMonitoringUser') BEGIN 
	CREATE USER [dbaMonitoringUser] FROM LOGIN [dbaMonitoringUser] 
END 
GO

