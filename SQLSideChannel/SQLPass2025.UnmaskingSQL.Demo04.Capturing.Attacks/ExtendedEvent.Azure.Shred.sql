	SELECT
		CONVERT(xml,target_data) TargetDataXML
		,*
	FROM sys.dm_xe_database_sessions S
		INNER JOIN sys.dm_xe_database_session_targets ST
			ON S.address = st.event_session_address
	WHERE S.name = 'RLSErrors'	