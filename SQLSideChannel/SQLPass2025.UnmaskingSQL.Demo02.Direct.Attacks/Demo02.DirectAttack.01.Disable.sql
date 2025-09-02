/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo02.DirectAttack.01.Disable.sql
*	Notes:		Direct attack. Disable the security policy.
*				This would normally happen in an automated deployment
*				or with an elevated account.
*				Emphasizes importance of proper security
********************************************************************/
USE WWISideChannel
GO

SELECT USER_NAME()
GO

--RLS restricts all rows
SELECT *
FROM Purchasing.PurchaseOrders
GO

--Disable RLS
ALTER SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingPurchaseOrders
WITH (STATE = OFF)
GO

SELECT
	USER_NAME()		[USER_NAME()]
	,*
FROM Purchasing.PurchaseOrders


--Re-enable RLS
ALTER SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingPurchaseOrders
WITH (STATE = ON)
GO

--Confirm access after re-enabling
SELECT *
FROM Purchasing.PurchaseOrders
GO

