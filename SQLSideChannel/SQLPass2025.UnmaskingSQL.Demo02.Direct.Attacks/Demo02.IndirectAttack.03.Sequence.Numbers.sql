/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo04.IndirectAttack.03.Sequence.Numbers.sql
*	Notes:		
********************************************************************/
USE WWISideChannel
GO

--Note the sequence number information for PurchaseOrderID, current value
SELECT
	SS.name				SchemaName
	,SEQ.name			SequenceName
	,SEQ.start_value
	,SEQ.increment
	,SEQ.current_value
	,SEQ.last_used_value
FROM sys.schemas SS
	INNER JOIN sys.sequences SEQ
		ON SS.schema_id	= SEQ.schema_id
ORDER BY
	SS.name
	,SEQ.name
