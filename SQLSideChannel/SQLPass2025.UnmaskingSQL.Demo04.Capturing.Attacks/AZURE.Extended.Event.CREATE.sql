/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AZURE.Extended.Event.CREATE.sql
*	Notes:		Create Azure XEvent to capture divide by zero errors (RLS attacks)
********************************************************************/
IF EXISTS (SELECT * FROM sys.database_event_sessions WHERE name = 'SideChannelAttacks')
BEGIN
	DROP EVENT SESSION SideChannelAttacks ON DATABASE
END
GO

CREATE EVENT SESSION SideChannelAttacks
ON DATABASE
 ADD EVENT sqlserver.error_reported
 (
   ACTION 
   (
     sqlserver.client_app_name
     ,sqlserver.client_hostname
     ,sqlserver.username
	 ,sqlserver.session_id
	 --,sqlserver.sql_text
	 ,sqlserver.database_id
	 ,sqlserver.plan_handle
	 ,sqlserver.query_hash 
    )
    WHERE error_number = 8134
  )
ADD TARGET package0.ring_buffer(SET max_events_limit=(10000))
WITH (
	MAX_MEMORY=4096 KB
	,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS
	,MAX_DISPATCH_LATENCY=30 SECONDS
	,MAX_EVENT_SIZE=0 KB
	,MEMORY_PARTITION_MODE=NONE
	,TRACK_CAUSALITY=ON
	,STARTUP_STATE=OFF
)
GO

ALTER EVENT SESSION SideChannelAttacks ON DATABASE
STATE = START;
GO