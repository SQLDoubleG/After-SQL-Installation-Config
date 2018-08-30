--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--======================================================================
-- @servername --> this is the node where we want to create the master keys 
-- @filePath1 --> the SQL service account must have permission to read/write in this folder
--
-- if using TDE with Availability Groups the wizard wont work and the database will need to manually be restored with the appropriate certificates/key
--
--======================================================================

USE master;
GO

DECLARE @share NVARCHAR(1024) = '\\Shared\'+(CAST(SERVERPROPERTY('ServerName') AS NVARCHAR(1024)))

DECLARE @filepath1 NVARCHAR(1024)
DECLARE @filepath2 NVARCHAR(1024)
DECLARE @p1 NVARCHAR(100) = $(service_master_key_password) -- service_master_key_password
DECLARE @p2 NVARCHAR(100) = $(database_master_key_password) -- database_master_key_password
--DECLARE @StrongPassword3 NVARCHAR(100) = '<BackupEncryptionCert_password>' -- BackupEncryptionCert_password
--DECLARE @StrongPassword4 NVARCHAR(100) = '<TDEServerCert_password>' -- TDEServerCert_password

--Service master key created during instance install. make sure it is backed up.
--create password and record somewhere safe.

PRINT 'EXEC master..xp_cmdshell ''if not exist "' + @share + '\_certificates\' + '". md "' + @share + '\_certificates\' + '".'''

-- Grant full control on the folder before doing this
EXEC ('EXEC master..xp_cmdshell ''if not exist "' + @share + '\_certificates\' + '". md "' + @share + '\_certificates\' + '".''')

SET @filepath1 = @share +'\_certificates\ServiceMasterKey.key'
PRINT 'BACKUP SERVICE MASTER KEY TO FILE = '''+@filepath1+''' ENCRYPTION BY PASSWORD = '''+@p1+''''

EXEC('BACKUP SERVICE MASTER KEY TO FILE = '''+@filepath1+''' ENCRYPTION BY PASSWORD = '''+@p1+'''');

--create the Master Key, once per instance (if not already created)
--CREATE MASTER KEY ENCRYPTION BY SERVICE MASTER KEY
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
	EXEC('CREATE MASTER KEY ENCRYPTION BY PASSWORD = '''+@p2+'''');
END

--open the master key to back it up.
EXEC('OPEN MASTER KEY DECRYPTION BY PASSWORD = '''+@p2+'''');

SET @filepath1 = @share +'\_certificates\MasterKey.key'
PRINT 'BACKUP MASTER KEY TO FILE = ''' + @filepath1 + ''' ENCRYPTION BY PASSWORD = ''' + @p2 +''''

EXEC('BACKUP MASTER KEY TO FILE = ''' + @filepath1 + ''' ENCRYPTION BY PASSWORD = ''' + @p2 +'''')

--create backup certificate (not required if using TDE)

--CREATE CERTIFICATE BackupEncryptionCert WITH SUBJECT = 'Backup Encryption Certificate';

--SET @filepath1 = @share +'\_certificates\BackupEncryptionCert.cer'
--SET @filepath2 = @share +'\_certificates\BackupEncryptionCert.private.key'
--EXEC('BACKUP CERTIFICATE BackupEncryptionCert TO FILE = '''+@filepath1+'''
--    WITH PRIVATE KEY 
--      ( 
--        FILE = '''+@filepath2+''',
--        ENCRYPTION BY PASSWORD = '''+@StrongPassword3+'''
--      )')

----Create TDE certificate
--CREATE CERTIFICATE TDEServerCert WITH SUBJECT = 'TDE Certificate';

--SET @filepath1 = @share +'\_certificates\TDEServerCert.cer'
--SET @filepath2 = @share +'\_certificates\TDEServerCert.private.key'
--EXEC('BACKUP CERTIFICATE TDEServerCert TO FILE = '''+@filepath1+'''
--    WITH PRIVATE KEY 
--      ( 
--        FILE = '''+@filepath2+''',
--        ENCRYPTION BY PASSWORD = '''+@StrongPassword4+'''
--      )')
--GO
----create database encryption keys (relies on master key)
--USE Test;
--GO
--CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE TDEServerCert;
--GO
--USE master;
--GO
--ALTER DATABASE Test SET ENCRYPTION ON;
--GO



