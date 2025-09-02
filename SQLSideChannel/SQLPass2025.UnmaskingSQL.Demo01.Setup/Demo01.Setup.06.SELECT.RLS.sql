/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo01.Setup.06.SELECT.RLS.sql
*	Notes:		Show RLS output
********************************************************************/
USE WWISideChannel
GO


--Show access for user in db_owner
SELECT 
	USER_NAME()	[USER_NAME()]
	,*
FROM Purchasing.Suppliers
GO


EXEC AS USER = 'SideChannelUser'
GO

--RLS for purchasing suppliers
--Restrict by SupplierID and User
SELECT 
	USER_NAME()	[USER_NAME()]
	,*
FROM Purchasing.Suppliers
GO

--Show the table requiring session_context
--Expected output for all users is 0 rows
SELECT TOP 100
	USER_NAME() [USER_NAME()]
	,*
FROM Purchasing.PurchaseOrders
GO

REVERT
GO

--Confirm the current user since the expected
--output from the next query is 0 rows
SELECT USER_NAME() [USER_NAME()]

--Rls for Purchasing.PurchaseOrders
--Note that this RLS predicate restricts all access
SELECT TOP 100
	USER_NAME() [USER_NAME()]
	,*
FROM Purchasing.PurchaseOrders
GO
