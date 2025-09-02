/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SERVER.Extended.Event.START.sql
*	Notes:		Start server XEvent session
********************************************************************/
-- Enable
IF EXISTS (SELECT *
      FROM sys.server_event_sessions
      WHERE name = 'SideChannelAttacks')
BEGIN TRY
	ALTER EVENT SESSION SideChannelAttacks ON SERVER
	STATE=START
END TRY
BEGIN CATCH
	PRINT 'SideChannelAttacks already started'
END CATCH
GO

	
