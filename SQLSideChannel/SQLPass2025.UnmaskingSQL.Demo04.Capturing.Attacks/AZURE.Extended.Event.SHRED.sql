/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AZURE.Extended.Event.SHRED.sql
*	Notes:		Shred Azure EE events, looking for Errors
********************************************************************/
DECLARE @EVENT_DATA XML 

SELECT @EVENT_DATA = CONVERT(xml,target_data)
FROM sys.dm_xe_database_sessions S
	INNER JOIN sys.dm_xe_database_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name				= 'SideChannelAttacks'
	AND ST.target_name		= 'ring_buffer'

;
WITH ERRORS_CTE AS (
	SELECT 
		EventName = s.value('(@name)[1]','varchar(500)')
		,EventDateStamp = s.value('(@timestamp)[1]','datetime')
		--,DatabaseID = s.value('(action[(@name)[1] eq "database_id"]/value/text())[1]','varchar(255)')
		,ErrorNumber = s.value('(data[(@name)[1] eq "error_number"]/value/text())[1]','int')
		--,ErrorSeverity = s.value('(data[(@name)[1] eq "severity"]/value/text())[1]','int')
		--,ErrorState = s.value('(data[(@name)[1] eq "state"]/value/text())[1]','int')
		--,ErrorMessage = s.value('(data[(@name)[1] eq "message"]/value/text())[1]','varchar(255)')
		--,CollectSystemTime = s.value('(action[(@name)[1] eq "collect_system_time"]/text/text())[1]','varchar(255)')
		--,ClientAppName = s.value('(action[(@name)[1] eq "client_app_name"]/value/text())[1]','varchar(255)')
		--,ClientHostName = s.value('(action[(@name)[1] eq "client_hostname"]/value/text())[1]','varchar(255)')
		--,PlanHandle = CONVERT(xml, s.value('(action[(@name)[1] eq "plan_handle"]/value/text())[1]','varchar(255)')).value('(plan/@handle)[1]', 'varchar(255)')
		--,SqlText = s.value('(action[(@name)[1] eq "sql_text"]/value/text())[1]','nvarchar(max)')
		--,UserName = s.value('(action[(@name)[1] eq "username"]/value/text())[1]','varchar(128)')
		--,SessionID = s.value('(action[(@name)[1] eq "session_id"]/value/text())[1]','int')
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
FROM sys.dm_xe_database_sessions S
	INNER JOIN sys.dm_xe_database_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name				= 'SideChannelAttacks'
	AND ST.target_name		= 'ring_buffer'

SELECT @EVENT_DATA
GO
*/
