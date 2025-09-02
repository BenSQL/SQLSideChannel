/*
MASKED COLUMN
*/
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
WHERE SS.name				= 'Sales'
	AND SO.name				= 'Customers'


CREATE STATISTICS ST_SalesCusomersName
ON Sales.Customers(CustomerName)
GO

DBCC SHOW_STATISTICS ('Sales.Customers','ST_SalesCusomersName') --WITH HISTOGRAM
GO


/*
RLS TABLE
*/
SELECT *
FROM Purchasing.PurchaseOrders

SELECT
	SS.name		SchemaName
	,SO.name	ObjectName
	,ST.name	StatisticName
	,SO.object_id
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id		= SO.schema_id
	INNER JOIN sys.stats ST
		ON SO.object_id		= ST.object_id
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

CREATE STATISTICS ST_PurchasingPurchaseOrders_Comments
ON Purchasing.PurchaseOrders(Comments)
GO

DBCC SHOW_STATISTICS ('Purchasing.PurchaseOrders','ST_PurchasingPurchaseOrders_Comments') --WITH HISTOGRAM
GO

CREATE STATISTICS ST_PurchasingPurchaseOrders_InternalComments
ON Purchasing.PurchaseOrders(InternalComments)
GO

DBCC SHOW_STATISTICS ('Purchasing.PurchaseOrders','ST_PurchasingPurchaseOrders_InternalComments') --WITH HISTOGRAM
GO

CREATE STATISTICS ST_PurchasingPurchaseOrders_SupplierReference
ON Purchasing.PurchaseOrders(SupplierReference)
GO

DBCC SHOW_STATISTICS ('Purchasing.PurchaseOrders','ST_PurchasingPurchaseOrders_SupplierReference') --WITH HISTOGRAM
GO
