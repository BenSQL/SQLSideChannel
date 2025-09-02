/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo01.Setup.03.Add.Masking.sql
*	Notes:		Add basic masking for demonstrations.
*				Shows a few different masking functions.
********************************************************************/
USE WWISideChannel
GO

/*
* Add various masking functions
* This is the syntax for a manual ALTER statement
*
* Adding masking to:
* sales.Customers
* Purchasing.PurchaseOrders
* Application.People
* Purchasing.SupplierTransactions
*/
ALTER TABLE sales.Customers
ALTER COLUMN CreditLimit
ADD MASKED WITH (FUNCTION = 'default()')
GO

ALTER TABLE sales.Customers
ALTER COLUMN CustomerName
ADD MASKED WITH (FUNCTION = 'default()')
GO

ALTER TABLE sales.Customers
ALTER COLUMN PhoneNumber
ADD MASKED WITH (FUNCTION = 'partial(6,"123-456",1)')
GO


--Random mask
ALTER TABLE Purchasing.PurchaseOrders
ALTER COLUMN SupplierID
ADD MASKED WITH (FUNCTION = 'random(1,100)')
GO

--Custom string
ALTER TABLE Application.People
ALTER COLUMN PhoneNumber
ADD MASKED WITH (FUNCTION = 'partial(6,"555-555",1)')
GO

--Datetime (SQL Server 2022 functionality)
ALTER TABLE Purchasing.PurchaseOrders
ALTER COLUMN ExpectedDeliveryDate
ADD MASKED WITH (FUNCTION = 'datetime("M")')
GO

--Default mask
--RLS is not applied later allowing full 
--Attack demo without combining RLS
ALTER TABLE Purchasing.SupplierTransactions
ALTER COLUMN TransactionAmount
ADD MASKED WITH (FUNCTION = 'default()')
GO


--Alter phone number for clarity in the example
;
WITH CUSTOMER_CTE AS (
	SELECT
		CustomerID
		,PhoneNumber
		,SUBSTRING(PhoneNumber,1,LEN(PhoneNumber) - LEN(convert(varchar(4),CustomerID))) + convert(varchar(4),CustomerID) PhoneNumberV2
		,ROW_NUMBER() OVER(ORDER BY CustomerID)		SELECT_CRITERIA
	FROM Sales.Customers
	WHERE CustomerID IN (74,84,116,431,454,488,560,821,1050,1051)
)

UPDATE CUSTOMER_CTE
SET
--SELECT
--	CustomerID,
	PhoneNumber = REPLACE(PhoneNumberV2,'(787)','(' + CASE LEN(SELECT_CRITERIA) 
											WHEN 1 THEN '(78' + CONVERT(varchar(2),SELECT_CRITERIA) + ')'
											WHEN 2 THEN '(7' + CONVERT(varchar(2),SELECT_CRITERIA) + ')'
										END)
FROM CUSTOMER_CTE


--Sales.Customers masking
SELECT --TOP 5
	USER_NAME()		[USER_NAME()]
	,CustomerID
	,CustomerName
	,PhoneNumber
FROM Sales.Customers
WHERE CustomerID IN (74,84,116,431,454,488,560,821,1050,1051)
GO
