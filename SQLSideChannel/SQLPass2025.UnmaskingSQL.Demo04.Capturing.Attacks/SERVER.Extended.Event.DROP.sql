/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SERVER.Extended.Event.DROP.sql
*	Notes:		Drop server XEvent session
********************************************************************/
IF EXISTS (SELECT *
      FROM sys.server_event_sessions
      WHERE name = 'SideChannelAttacks')
BEGIN
	DROP EVENT SESSION SideChannelAttacks
	ON SERVER
END
GO
