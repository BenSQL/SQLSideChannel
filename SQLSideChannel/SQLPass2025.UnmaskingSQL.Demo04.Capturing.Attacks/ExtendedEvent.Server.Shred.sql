SELECT
	CONVERT(xml,target_data) TargetDataXML
	,*
FROM sys.dm_xe_sessions S
	INNER JOIN sys.dm_xe_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name = 'RLSErrors'	


DECLARE @EVENT_DATA XML 

SELECT @EVENT_DATA = CONVERT(xml,target_data)
FROM sys.dm_xe_sessions S
	INNER JOIN sys.dm_xe_session_targets ST
		ON S.address = st.event_session_address
WHERE S.name				= 'RLSErrors'
	AND ST.target_name		= 'event_file'

SELECT @EVENT_DATA

SELECT *
FROM
(
	SELECT td.query('.') as n
	FROM @EVENT_DATA.nodes('//RingBufferTarget/event') AS q(td)
) TAB
--Excluding this currently running query.
WHERE n.value('(event/action[@name="session_id"]/value)[1]', 'int') <> @@SPID
	OR n.value('(event/action[@name="session_id"]/value)[1]', 'int') IS NULL
--ORDER BY session_id

