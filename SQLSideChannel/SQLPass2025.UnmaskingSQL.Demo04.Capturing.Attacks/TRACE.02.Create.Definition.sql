/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		TRACE.02.Create.Definition.sql
*	Notes:		Create trace to capture errors
********************************************************************/
USE master
GO

-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
declare @traceoptions int
declare @stoptime datetime
set @traceoptions = 2
set @maxfilesize = 128 
set @stoptime = NULL
DECLARE @strFileName nvarchar(256)

SELECT @strFileName = 'C:\Temp\SideChannelAttacks_' + replace(replace(replace(replace(convert(varchar(50),getdate(),100),'-',''),' ','_'),':',''),'__','_')

-- Create the trace with the name of the output file - .trc extension is added to filename
exec @rc = sp_trace_create @TraceID output, 2, @strFileName, @maxfilesize, NULL 
--if (@rc != 0) goto error

-- Set the events
DECLARE @on bit = 1

--Query Exception
exec sp_trace_setevent @TraceID, 33, 1, @on		--TextData 
exec sp_trace_setevent @TraceID, 33, 3, @on		--DatabaseID
exec sp_trace_setevent @TraceID, 33, 4, @on		--TransactionID
exec sp_trace_setevent @TraceID, 33, 6, @on		--NTUserName
exec sp_trace_setevent @TraceID, 33, 7, @on		--NTDomainName
exec sp_trace_setevent @TraceID, 33, 8, @on		--HostName
exec sp_trace_setevent @TraceID, 33, 9, @on		--ClientProcessID
exec sp_trace_setevent @TraceID, 33, 10, @on	--ApplicationName
exec sp_trace_setevent @TraceID, 33, 11, @on	--LoginName
exec sp_trace_setevent @TraceID, 33, 12, @on	--SPID
exec sp_trace_setevent @TraceID, 33, 14, @on	--StartTime
exec sp_trace_setevent @TraceID, 33, 15, @on	--EndTime
exec sp_trace_setevent @TraceID, 33, 20, @on	--Severity
exec sp_trace_setevent @TraceID, 33, 26, @on	--ServerName
exec sp_trace_setevent @TraceID, 33, 30, @on	--State
exec sp_trace_setevent @TraceID, 33, 31, @on	--Error
exec sp_trace_setevent @TraceID, 33, 35, @on	--DatabaseName
exec sp_trace_setevent @TraceID, 33, 41, @on	--LoginSid
exec sp_trace_setevent @TraceID, 33, 49, @on	--RequestID
exec sp_trace_setevent @TraceID, 33, 64, @on	--SessionLoginName


-- Filter out the SQL Profiler events
exec sp_trace_setfilter @TraceID, 10, 0, 7, N'SQL Profiler'		-- Column 10 (ApplicationName), operator 7 (NOT LIKE), SQL Profiler
exec sp_trace_setfilter @TraceID, 10, 0, 7, N'Report Server'	
exec sp_trace_setfilter @TraceID, 31, 0, 0, 8134

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
	,TraceName=@strFileName + '.trc'
goto finish

error: 
select ErrorCode=@rc

finish: 
PRINT 'TRACE ' + convert(varchar(5),@TraceID) + ' created successfully'
PRINT 'TRACE name: ' + @strFileName + '.trc'
go


/****************************************
* return code values
0	No error.
1	Unknown error.
10	Invalid options. Returned when options specified are incompatible.
12	File not created.
13	Out of memory. Returned when there is not enough memory to perform the specified action.
14	Invalid stop time. Returned when the stop time specified has already happened.
15	Invalid parameters. Returned when the user supplied incompatible parameters.
*******************************************/


