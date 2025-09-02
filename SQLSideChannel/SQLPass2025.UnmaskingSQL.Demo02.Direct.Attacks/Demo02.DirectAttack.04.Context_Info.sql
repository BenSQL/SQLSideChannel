/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo02.DirectAttack.04.Context_Info.sql
*	Notes:		Shows the difference between CONTEXT_INFO and SESSION_CONTEXT
*				Only use SESSION_CONTEXT with READ_ONLY = 1 if you use
*				this for RLS
********************************************************************/
USE WWISideChannel
GO

SET CONTEXT_INFO 0x0;
SELECT USER_NAME(), CONTEXT_INFO()

SET CONTEXT_INFO 0x1;
SELECT USER_NAME(), CONTEXT_INFO()


--User with minimal access, not DBO
EXECUTE AS USER = 'SideChannelUser'

SELECT USER_NAME(), CONTEXT_INFO()

SET CONTEXT_INFO 0x2

SELECT USER_NAME(), CONTEXT_INFO()

REVERT

EXEC sys.sp_set_session_context @key = N'RLSDemo', @value = 0x411;
SELECT USER_NAME(), SESSION_CONTEXT(N'RLSDemo')

EXEC sys.sp_set_session_context @key = N'RLSDemo', @value = 0x412;
SELECT USER_NAME(), SESSION_CONTEXT(N'RLSDemo')

--User with minimal access, not DBO
EXECUTE AS USER = 'SideChannelUser'
GO

EXEC sys.sp_set_session_context @key = N'RLSDemo', @value = 0x413;
SELECT USER_NAME(), SESSION_CONTEXT(N'RLSDemo')
GO

--This is the mitigation for this type of attack
--If this is used for security, it needs to be set as READ ONLY
EXEC sys.sp_set_session_context @key = N'RLSDemo', @value = 0x414, @read_only = 1;
SELECT USER_NAME(), SESSION_CONTEXT(N'RLSDemo')
GO

EXEC sys.sp_set_session_context @key = N'RLSDemo', @value = 0x415;
SELECT USER_NAME(), SESSION_CONTEXT(N'RLSDemo')
GO

REVERT
GO
