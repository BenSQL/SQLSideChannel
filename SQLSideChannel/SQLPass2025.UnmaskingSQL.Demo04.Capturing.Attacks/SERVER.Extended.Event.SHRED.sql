/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SERVER.Extended.Event.SHRED.sql
*	Notes:		Shred server XEvent events, looking for Errors
********************************************************************/
DECLARE @EVENT_DATA XML 

SELECT @EVENT_DATA = CONVERT(xml,target_data)
FROM sys.dm_xe_sessions S
	INNER JOIN sys.dm_xe_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name				= 'SideChannelAttacks'
	AND ST.target_name		= 'ring_buffer'

;
WITH ERRORS_CTE AS (
	SELECT 
		EventName = s.value('(@name)[1]','varchar(500)')
		,EventDateStamp = s.value('(@timestamp)[1]','datetime')
		,ErrorNumber = s.value('(data[(@name)[1] eq "error_number"]/value/text())[1]','int')
	FROM @EVENT_DATA.nodes('/RingBufferTarget/event') AS xm(s)
)

SELECT
	ER.ErrorNumber
	,COUNT(*)		ErrorCount
FROM ERRORS_CTE ER
WHERE ER.EventDateStamp BETWEEN DATEADD(mi,-10,GETUTCDATE()) AND GETUTCDATE()
GROUP BY
	ER.ErrorNumber
GO

/*
--View entire output for troubleshooting
DECLARE @EVENT_DATA XML 

SELECT @EVENT_DATA = CONVERT(xml,target_data)
FROM sys.dm_xe_sessions S
	INNER JOIN sys.dm_xe_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name				= 'SideChannelAttacks'
	AND ST.target_name		= 'ring_buffer'

SELECT @EVENT_DATA
GO
*/
