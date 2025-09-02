/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SERVER.Extended.Event.CREATE.sql
*	Notes:		Create server XEvent to capture divide by zero errors (RLS attacks)
********************************************************************/
IF EXISTS (SELECT * FROM sys.server_event_sessions WHERE name = 'SideChannelAttacks')
BEGIN
	DROP EVENT SESSION SideChannelAttacks ON SERVER
END
GO

CREATE EVENT SESSION SideChannelAttacks
ON SERVER
 ADD EVENT sqlserver.error_reported
 (
   ACTION 
   (
     sqlserver.client_hostname
	 --,sqlserver.client_app_name
     ,sqlserver.username
	 ,sqlserver.session_id
	 --,sqlserver.sql_text
	 --,sqlserver.database_id
	 --,sqlserver.plan_handle
	 --,sqlserver.task_time
	 --,sqlserver.query_hash 
    )
    WHERE error_number = 8134 --Divide by zero
  )
ADD TARGET package0.ring_buffer(SET max_events_limit=(10000))
WITH (
	MAX_MEMORY=4096 KB
	--MAX_MEMORY=8192 KB
	,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS
	,MAX_DISPATCH_LATENCY=30 SECONDS
	,MAX_EVENT_SIZE=0 KB
	,MEMORY_PARTITION_MODE=NONE
	,TRACK_CAUSALITY=ON
	,STARTUP_STATE=OFF
)
GO

ALTER EVENT SESSION SideChannelAttacks ON SERVER
STATE = START;
GO