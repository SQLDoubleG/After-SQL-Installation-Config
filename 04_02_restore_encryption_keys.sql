--=====================================================================================================
--
-- This script is meant to run from powershell script
-- 
--======================================================================
-- @servername --> this is the node where we have created the master keys at first
-- @filePath1 --> the SQL service account must have permission to read/write in this folder
--
--
--======================================================================
--:CONNECT SQL01
USE master;
GO

-- To restore master key to all nodes for the cluster 
-- The keys are stored 
DECLARE @servername SYSNAME = REPLACE(@@SERVERNAME, '-HA', '')

DECLARE @share NVARCHAR(1024) = '\\Share\'+@servername

DECLARE @filepath1 NVARCHAR(1024)
DECLARE @filepath2 NVARCHAR(1024)
DECLARE @p1 NVARCHAR(100) = $(service_master_key_password) -- service_master_key_password	
DECLARE @p2 NVARCHAR(100) = $(database_master_key_password) -- database_master_key_password	
--DECLARE @StrongPassword3 NVARCHAR(100) = '<BackupEncryptionCert_password>' -- BackupEncryptionCert_password
--DECLARE @StrongPassword4 NVARCHAR(100) = '<TDEServerCert_password>' -- TDEServerCert_password

--restoring everything on another server
USE master;

--https://msdn.microsoft.com/en-us/library/ms187972.aspx
SET @filepath1 = @share +'\_certificates\ServiceMasterKey.key'
PRINT 'RESTORE SERVICE MASTER KEY FROM FILE = '''+@filepath1+''' DECRYPTION BY PASSWORD = '''+@p1+''' FORCE';
EXEC('RESTORE SERVICE MASTER KEY FROM FILE = '''+@filepath1+''' DECRYPTION BY PASSWORD = '''+@p1+''' FORCE');

--https://msdn.microsoft.com/en-us/library/ms186336.aspx
SET @filepath1 = @share +'\_certificates\MasterKey.key'
EXEC('RESTORE MASTER KEY FROM FILE = '''+@filepath1+'''
               DECRYPTION BY PASSWORD = '''+@p2+'''
               ENCRYPTION BY PASSWORD = '''+@p2+''' FORCE');

EXEC('OPEN MASTER KEY DECRYPTION BY PASSWORD = '''+@p2+'''');

--SET @filepath1 = @share +'\_certificates\BackupEncryptionCert.cer'
--SET @filepath2 = @share +'\_certificates\BackupEncryptionCert.private.key'
--EXEC('CREATE CERTIFICATE BackupEncryptionCert 
--    FROM FILE = '''+@filepath1+'''
--    WITH PRIVATE KEY (FILE = '''+@filepath2+''', 
--    DECRYPTION BY PASSWORD = '''+@StrongPassword3+''')');

--SET @filepath1 = @share +'\_certificates\TDEServerCert.cer'
--SET @filepath2 = @share +'\_certificates\TDEServerCert.private.key'
--EXEC('CREATE CERTIFICATE TDEServerCert
--               FROM FILE = '''+@filepath1+'''
--               WITH PRIVATE KEY (FILE = '''+@filepath2+''',
--        DECRYPTION BY PASSWORD = '''+@StrongPassword4+''')');


--execute sp_configure 'show advanced options', 1
--reconfigure

--execute sp_configure 'xp_cmdshell', 1
--reconfigure


