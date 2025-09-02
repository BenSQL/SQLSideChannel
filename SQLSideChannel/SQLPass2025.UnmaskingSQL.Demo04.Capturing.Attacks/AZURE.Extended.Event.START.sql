/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AZURE.Extended.Event.START.sql
*	Notes:		Start Azure XEvent session
********************************************************************/
--Enable event
IF EXISTS (SELECT *
      FROM sys.database_event_sessions
      WHERE name = 'SideChannelAttacks')
BEGIN TRY
	ALTER EVENT SESSION SideChannelAttacks ON DATABASE
	STATE=START
END TRY
BEGIN CATCH
	PRINT 'SideChannelAttacks already started'
END CATCH
GO
