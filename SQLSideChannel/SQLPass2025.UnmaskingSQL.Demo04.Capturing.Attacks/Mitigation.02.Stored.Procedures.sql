/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Mitigation.02.Stored.Procedures.sql
*	Notes:		Show how stored procedures can be used to protect against
*				RLS side channel attacks and
*				masking attacks
********************************************************************/
USE WWISideChannel
GO

GRANT EXEC ON SCHEMA::Protected TO MitigationUser
GO

--Grant the test user access to a single supplier ID
INSERT INTO RLS.UsersSuppliers (
	UserID
	,SupplierID
)
VALUES (
	'MitigationUser'
	,5
)
GO


CREATE PROCEDURE protected.PurchasingSuppliers_SELECT

AS
SET NOCOUNT ON

SELECT 
	SupplierID
	,SupplierName
	,SupplierCategoryID
	,PrimaryContactPersonID
	,AlternateContactPersonID
	,DeliveryMethodID
	,DeliveryCityID
	,PostalCityID
FROM Purchasing.Suppliers PS
GO

--Execute as dbo
EXEC protected.PurchasingSuppliers_SELECT
GO

--Exec as mitigation user
--RLS applies
EXEC AS USER = 'MitigationUser'
GO

EXEC protected.PurchasingSuppliers_SELECT
GO

REVERT
GO


--This is how an RLS attack would work against
--Purchasing.Suppliers
SELECT *
FROM Purchasing.Suppliers PS
WHERE PS.SupplierID = 1
	AND 1/(SupplierID - 1) = 0
GO


--The same attack
--With a user that doesn't have direct
--SELECT access
--No information is given via the error message.
--Standard security error only.
EXEC AS USER = 'MitigationUser'
GO

SELECT *
FROM Purchasing.Suppliers PS
WHERE PS.SupplierID = 1
	AND 1/(SupplierID - 1) = 0
GO

REVERT
GO


--Procedure based on the table used in 
--previous examples.
CREATE PROCEDURE protected.prc_salesCustomers_SELECT

AS
SET NOCOUNT ON

SELECT
	CustomerID
	,CustomerName
	,CreditLimit
	,PhoneNumber
FROM sales.Customers
GO

--The new user has no RLS access
GRANT EXEC ON SCHEMA::Protected TO SideChannelUser
GO

EXEC AS USER = 'MitigationUser'
GO

EXEC protected.prc_salesCustomers_SELECT

REVERT
GO

--DBO has full RLS access
EXEC protected.prc_salesCustomers_SELECT
GO
