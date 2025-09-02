/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		TRACE.03.SELECT.sql
*	Notes:		Select data from the trace file
********************************************************************/
SELECT 
	GT.*
FROM sys.traces T
	CROSS APPLY::fn_trace_gettable(T.path,default) GT
WHERE T.id	= 2
GO
