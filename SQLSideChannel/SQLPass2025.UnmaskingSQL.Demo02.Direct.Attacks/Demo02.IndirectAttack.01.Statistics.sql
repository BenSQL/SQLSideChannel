/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.IndirectAttack.01.Statistics.sql
*	Notes:		DBCC SHOW_STATISTICS can be used to get basic
*				information about indexed columns.
*				Can be used to simplify attacks.
********************************************************************/
USE WWISideChannel
GO

DBCC SHOW_STATISTICS ('Purchasing.Suppliers','PK_Purchasing_Suppliers') --WITH HISTOGRAM

--Key information is available, even though all rows are blocked via RLS
DBCC SHOW_STATISTICS ('Purchasing.PurchaseOrders','PK_Purchasing_PurchaseOrders') --WITH HISTOGRAM

--We know that the keys shown are out-of-date. This will allow us to see all of them
UPDATE STATISTICS Purchasing.PurchaseOrders WITH FULLSCAN, ALL;

--Same command. Updated statistics with all keys.
DBCC SHOW_STATISTICS ('Purchasing.PurchaseOrders','PK_Purchasing_PurchaseOrders') --WITH HISTOGRAM
GO

SELECT
	SS.name		SchemaName
	,SO.name	ObjectName
	,ST.name	StatisticName
	,SO.object_id
	,PRP.*
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id		= SO.schema_id
	INNER JOIN sys.stats ST
		ON SO.object_id		= ST.object_id
	OUTER APPLY sys.dm_db_stats_properties(SO.object_id,1) PRP
WHERE SS.name				= 'Purchasing'
	AND SO.name				= 'PurchaseOrders'

SELECT
	SS.name		SchemaName
	,SO.name	ObjectName
	,ST.name	StatisticName
	,SO.object_id
	,HST.*
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id		= SO.schema_id
	INNER JOIN sys.stats ST
		ON SO.object_id		= ST.object_id
	OUTER APPLY sys.dm_db_stats_histogram(SO.object_id,1) HST
WHERE SS.name				= 'Purchasing'
	AND SO.name				= 'PurchaseOrders'
