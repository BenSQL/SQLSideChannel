/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo01.Setup.02.Create.Users.sql
*	Notes:		Create users without logins
*				Grant basic access
*				Add user to role for RLS
********************************************************************/
USE WWISideChannel
GO

CREATE USER SideChannelUser WITHOUT LOGIN
GO

GRANT SELECT ON SCHEMA::Purchasing TO SideChannelUser
GO

GRANT SELECT ON SCHEMA::Sales TO SideChannelUser
GO

ALTER ROLE [External Sales]
ADD MEMBER SideChannelUser
GO

