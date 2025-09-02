/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		TRACE.04.DROP.sql
*	Notes:		Drop the specified trace
********************************************************************/
USE master
GO

DECLARE @intTraceID		int = 2

EXEC sp_trace_setstatus @traceid = @intTraceID , @status = 0	--Stop the trace
EXEC sp_trace_setstatus @traceid = @intTraceID , @status = 2	--Delete the trace
