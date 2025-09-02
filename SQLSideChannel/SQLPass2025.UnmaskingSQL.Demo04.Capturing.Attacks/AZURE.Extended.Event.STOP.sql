/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AZURE.Extended.Event.STOP.sql
*	Notes:		Stop Azure EE session
********************************************************************/
-- Disable Event
ALTER EVENT SESSION SideChannelAttacks ON DATABASE
STATE=STOP
GO