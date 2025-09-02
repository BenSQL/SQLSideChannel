/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.Masking.01.Exact.Match.sql
*	Notes:		Shows how values can be exposed if an exact match is found
********************************************************************/
USE WWISideChannel
GO
SET NOCOUNT ON
GO

EXECUTE AS USER = 'SideChannelUser'
GO

SELECT
	USER_NAME()		[USER_NAME()]
	,CustomerID
	,CustomerName
	,CreditLimit
FROM Sales.Customers
WHERE CreditLimit = 2400.00
GO

REVERT
GO
