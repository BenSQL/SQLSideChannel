/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		TRACE.01.Running.Traces.sql
*	Notes:		View running traces
********************************************************************/
--Currently running traces.

SELECT 
	traceid
	,property
	,value
	,T.path
FROM ::fn_trace_getinfo(0) TGI
	INNER JOIN sys.traces T
		ON TGI.traceid		= T.id
WHERE TGI.property = 5


--
DECLARE @TraceID	int = 2
SELECT *
FROM ::fn_trace_geteventinfo(@TraceID) TGE
	INNER JOIN sys.trace_events TE
		ON TGE.eventid		= TE.trace_event_id
	INNER JOIN sys.trace_categories TC
		ON TE.category_id	= TC.category_id
	INNER JOIN sys.trace_columns TCO
		ON TGE.columnid		= TCO.trace_column_id
ORDER BY 
	TC.name
	,TGE.columnid


SELECT *
FROM sys.fn_trace_getfilterinfo(@TraceID)
GO
