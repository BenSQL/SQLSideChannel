/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo02.DirectAttack.02.INSERT.Control.Table.sql
*	Notes:		Direct attack. Add additional RLS criteria to the user.
********************************************************************/
USE WWISideChannel
GO


--Show base access before changes
EXEC AS USER = 'SideChannelUser'
GO

SELECT 
	USER_NAME()	[USER_NAME()]
	,*
FROM Purchasing.Suppliers
GO

REVERT
GO

--Grant the test user access to a single supplier ID
--Done as DBO
INSERT INTO RLS.UsersSuppliers (
	UserID
	,SupplierID
)
VALUES (
	'SideChannelUser'
	,5
)
GO


--Show new access after changing the control table
EXEC AS USER = 'SideChannelUser'
GO

SELECT 
	USER_NAME()	[USER_NAME()]
	,*
FROM Purchasing.Suppliers
GO

REVERT
GO
