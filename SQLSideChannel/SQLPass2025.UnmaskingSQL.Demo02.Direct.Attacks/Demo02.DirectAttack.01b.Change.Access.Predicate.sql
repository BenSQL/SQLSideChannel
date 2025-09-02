/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo02.DirectAttack.01b.Change.Access.Predicate.sql
*	Notes:		Direct attack. Alter the Access predicate.
*				This also would normally happen in an automated deployment
*				or with an elevated account.
*				Emphasizes importance of proper security
********************************************************************/
USE WWISideChannel
GO

--Attempt to directly alter the AP
--Can't be done with a security policy
CREATE OR ALTER FUNCTION RLS.AccessPredicate_SupplierID_PurchasingSuppliers(@SupplierID	int)
RETURNS TABLE
WITH SCHEMABINDING
AS

RETURN

	SELECT 1 AccessResult
	WHERE (
			IS_MEMBER('db_owner') = 1 
			OR USER_NAME() = 'SideChannelUser'
			)

	UNION

	SELECT 
		1 AccessResult
	FROM RLS.UsersSuppliers US
		INNER JOIN Purchasing.Suppliers PS
			ON US.SupplierID	= PS.SupplierID
	WHERE US.SupplierID			= @SupplierID
		AND US.UserID			= USER_NAME()
GO

--Setting the policy state to OFF doesn't work either
ALTER SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
WITH (STATE = OFF)
GO

--Must remove it before changing the access policy
DROP SECURITY POLICY IF EXISTS RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
GO

CREATE OR ALTER FUNCTION RLS.AccessPredicate_SupplierID_PurchasingSuppliers(@SupplierID	int)
RETURNS TABLE
WITH SCHEMABINDING
AS

RETURN

	SELECT 1 AccessResult
	WHERE (
			IS_MEMBER('db_owner') = 1 
			OR USER_NAME() = 'SideChannelUser'
			)

	UNION

	SELECT 
		1 AccessResult
	FROM RLS.UsersSuppliers US
		INNER JOIN Purchasing.Suppliers PS
			ON US.SupplierID	= PS.SupplierID
	WHERE US.SupplierID			= @SupplierID
		AND US.UserID			= USER_NAME()
GO


--Recreate the security policy
CREATE SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
ADD FILTER PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers
,ADD BLOCK PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers AFTER UPDATE
WITH (STATE = ON, SCHEMABINDING = ON)
GO



--Show the updated / bypassed RLS access
EXEC AS USER = 'SideChannelUser'
GO

--RLS for purchasing suppliers
--Restrict by SupplierID and User
SELECT 
	USER_NAME()	[USER_NAME()]
	,*
FROM Purchasing.Suppliers
GO

REVERT
GO




/*******************************************************************
*	Reset security back to demo baseline
********************************************************************/

--Must remove it before changing the access policy
DROP SECURITY POLICY IF EXISTS RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
GO

--Set back to demo baseline
CREATE OR ALTER FUNCTION RLS.AccessPredicate_SupplierID_PurchasingSuppliers(@SupplierID	int)
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


--Recreate the security policy
CREATE SECURITY POLICY RLS.SecurityPolicy_SupplierID_PurchasingSuppliers
ADD FILTER PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers
,ADD BLOCK PREDICATE RLS.AccessPredicate_SupplierID_PurchasingSuppliers(SupplierID) ON Purchasing.Suppliers AFTER UPDATE
WITH (STATE = ON, SCHEMABINDING = ON)
GO

