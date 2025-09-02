/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo01.Setup.05.SELECT.Masked.sql
*	Notes:		Show masking output
*				Baseline output with the restricted user
********************************************************************/
USE WWISideChannel
GO

EXEC AS USER = 'SideChannelUser'
GO

--sales.Customers maksing
SELECT
	CustomerID
	,CustomerName
	,CreditLimit
	,PhoneNumber
FROM sales.Customers


--Purchasing.Suppliers masking - on by default in WideWorldImporters
SELECT 
	USER_NAME()		[USER_NAME()]
	,SupplierID
	,SupplierName
	,BankAccountName
	,BankAccountBranch
	,BankAccountCode
	,BankAccountNumber
	,BankInternationalCode
FROM Purchasing.Suppliers
GO


--Sales.Customers masking
SELECT --TOP 5
	USER_NAME()		[USER_NAME()]
	,CustomerID
	,CustomerName
	,PhoneNumber
FROM Sales.Customers
WHERE CustomerID IN (74,84,116,431,454,488,560,821,1050,1051)
GO

REVERT
GO

