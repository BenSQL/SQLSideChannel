/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SERVER.Extended.Event.STOP.sql
*	Notes:		Stop server XEvent session
********************************************************************/
-- Disable Event
IF EXISTS (SELECT *
      FROM sys.server_event_sessions
      WHERE name = 'SideChannelAttacks')
BEGIN
	ALTER EVENT SESSION SideChannelAttacks ON SERVER
	STATE=STOP
END
GO
