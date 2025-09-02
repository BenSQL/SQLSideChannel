/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo.01.Setup.01.Create.Restore.sql
*	Notes:		Setup environment using WideWorlImporters full sample
*				Restore using GUI or change directories in script as needed
*				https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
********************************************************************/
USE master
GO

ALTER DATABASE WWISideChannel
SET SINGLE_USER WITH
ROLLBACK IMMEDIATE
GO

USE master
RESTORE DATABASE WWISideChannel
FROM  DISK = N'C:\Temp\SQLPass.2025\WideWorldImporters-Full.bak' 
WITH  FILE = 1
	,MOVE N'WWI_Primary' TO N'C:\SQLData\WideWorldImporters.mdf'
	,MOVE N'WWI_UserData' TO N'C:\SQLData\WideWorldImporters_UserData.ndf'
	,MOVE N'WWI_Log' TO N'C:\SQLLog\WideWorldImporters.ldf'
	,MOVE N'WWI_InMemory_Data_1' TO N'C:\SQLData\WideWorldImporters_InMemory_Data_1'
	,NOUNLOAD
	,REPLACE
	,STATS = 5
GO

ALTER DATABASE WWISideChannel
SET MULTI_USER WITH
ROLLBACK IMMEDIATE
GO

