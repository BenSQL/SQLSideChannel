/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo01.Setup.04.Add.RLS.sql
*	Notes:		Add RLS for demonstrations.
*				RLS table, roles, no access shown
********************************************************************/
USE WWISideChannel
GO

/*
* Add RLS
* Reminder - RLS is non-prescriptive.
* Your business rules determine how to implement
*
* Adding RLS to:
* Purchasing.Suppliers
* Purchasing.PurchaseOrders
*/


/*
* Example showing RLS using a control table
* The "business rules" for this restrict data
* returned based on the SupplierID for each user.
*/
CREATE SCHEMA RLS
AUTHORIZATION dbo
GO


--Create the table to hold the RLS rules
CREATE TABLE RLS.UsersSuppliers (
	UsersSuppliersID		int				NOT NULL CONSTRAINT PK_RLSUsersSuppliers PRIMARY KEY CLUSTERED		identity
	,UserID					nvarchar(255)	NOT NULL
	,SupplierID				int				NOT NULL
)
GO

--With this strategy, it is important that the lookups are indexed
CREATE UNIQUE NONCLUSTERED INDEX UNQ_RLSUsersSuppliers_NaturalKey
ON RLS.UsersSuppliers (
	UserID
	,SupplierID
)
GO

CREATE NONCLUSTERED INDEX IX_RLSUsersSuppliers_UserID
ON RLS.UsersSuppliers (
	UserID
)
GO

--Grant SELECT access to the entire Purchasing schema
GRANT SELECT ON SCHEMA::Purchasing TO SideChannelUser
GO

--Deny SELECT on the RLS schema
--This makes it a little more difficult to probe security
--and makes the intention clear
DENY SELECT ON SCHEMA::RLS TO SideChannelUser
GO

--Grant the test user access to a single supplier ID
INSERT INTO RLS.UsersSuppliers (
	UserID
	,SupplierID
)
VALUES (
	'SideChannelUser'
	,4
)
GO

--Define the security function
--Note that all members of db_owner get access to all suppliers
CREATE FUNCTION RLS.AccessPredicate_SupplierID_PurchasingSuppliers(@SupplierID	int)
RETURNS TABLE
WITH SCHEMABINDING
AS

RETURN

	SELECT 1 AccessResult
	WHERE IS_MEMBER('db_owner') = 1 

	UNION

	SELECT 
		1 AccessResult
	FROM RLS.UsersSuppliers US
		INNER JOIN Purchasing.Suppliers PS
			ON US.SupplierID	= PS.SupplierID
	WHERE US.SupplierID			= @SupplierID
		AND US.UserID			= USER_NAME()
GO

--Enforce the access predicate defined above
--It is enabled. It also blocks updates that would violate the RLS rules
CREATE SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
ADD FILTER PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers
,ADD BLOCK PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers AFTER UPDATE
WITH (STATE = ON, SCHEMABINDING = ON)
GO

DROP SECURITY POLICY IF EXISTS RLS.SecurityPolicy_SupplierID_PurchasingPurchaseOrders
GO
--Create a security function that doesn't return rows for any user
--This would never be used in an actual system - it denies row access for all users.
--Used for the brute-force attack demonstration
--In theory it could return rows if you set the SESSION_CONTEXT
CREATE OR ALTER FUNCTION RLS.AccessPredicate_SupplierID_PurchasingPurchaseOrders(@PurchaseOrderID int)
RETURNS TABLE
WITH SCHEMABINDING
AS

RETURN
	SELECT 1 AccessResult
	FROM Purchasing.PurchaseOrders PS
	WHERE PS.PurchaseOrderID		= @PurchaseOrderID
		AND SESSION_CONTEXT(N'RLSExample') = 0x411
GO

--Enforce the access predicate defined above
--Since it blocks after update, there is no access allowed, even new inserts
CREATE SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingPurchaseOrders
ADD FILTER PREDICATE RLS.AccessPredicate_SupplierID_PurchasingPurchaseOrders(PurchaseOrderID) ON Purchasing.PurchaseOrders
,ADD BLOCK PREDICATE RLS.AccessPredicate_SupplierID_PurchasingPurchaseOrders(PurchaseOrderID) ON Purchasing.PurchaseOrders AFTER UPDATE
WITH (STATE = ON, SCHEMABINDING = ON)
GO

