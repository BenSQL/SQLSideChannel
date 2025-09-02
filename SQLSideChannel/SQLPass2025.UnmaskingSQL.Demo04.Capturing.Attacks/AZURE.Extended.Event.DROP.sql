/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AZURE.Extended.Event.DROP.sql
*	Notes:		Drop Azure XEvent session
********************************************************************/
--SELECT SERVERPROPERTY('Edition')
IF EXISTS (
			SELECT * 
			FROM sys.database_event_sessions 
			WHERE name = 'SideChannelAttacks')
BEGIN
	DROP EVENT SESSION SideChannelAttacks ON DATABASE
END
GO
