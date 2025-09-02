/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.Masking.02.Histogram.sql
*	Notes:		Example showing static histogram bucket generation.
*				Also shows how functions and comparison operators
*				can be used directly on columns.
********************************************************************/
USE WWISideChannel
SET NOCOUNT ON
GO

EXECUTE AS USER = 'SideChannelUser'
GO

SELECT
	USER_NAME()		[USER_NAME()]
	,CustomerID
	,CreditLimit
	,CASE 
		WHEN CreditLimit > 3000 THEN '3000+'
		WHEN CreditLimit > 2500 THEN '2500+'
		WHEN CreditLimit > 2000 THEN '2000+'
		WHEN CreditLimit > 1500 THEN '1500+'
		WHEN CreditLimit > 1000 THEN '1000+'
		ELSE '<1000'
	END CreditLimitHistogram
FROM sales.Customers
WHERE CreditLimit IS NOT NULL
ORDER BY CustomerID
GO

REVERT
GO
