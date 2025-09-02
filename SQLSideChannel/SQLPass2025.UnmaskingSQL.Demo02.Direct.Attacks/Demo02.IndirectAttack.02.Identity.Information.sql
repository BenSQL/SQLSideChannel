/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.IndirectAttack.02.Identity.Information.sql
*	Notes:		Identity column information can be used to simplify attacks
*				against tables protected with RLS.
********************************************************************/
USE WWISideChannel
GO

CREATE TABLE dbo.TestData (
	TestDataID		int				NOT NULL		CONSTRAINT PK_dboTestData		PRIMARY KEY CLUSTERED		IDENTITY
	,TestData		varchar(255)	NOT NULL
)

INSERT INTO dbo.TestData (
	TestData
)
SELECT TOP 100
	name
FROM sys.objects
GO

DROP SECURITY POLICY IF EXISTS RLS.SecurityPolicy_TestDataID_dboTestData
GO
--Create a security function that doesn't return rows for any user
CREATE OR ALTER FUNCTION RLS.AccessPredicate_TestDataID_dboTestData(@TestDataID int)
RETURNS TABLE
WITH SCHEMABINDING
AS

RETURN
	SELECT 1 AccessResult
	FROM dbo.TestData
	WHERE TestDataID	= @TestDataID
		AND SESSION_CONTEXT(N'RLSKey') = 0x99

GO

--Enforce the access predicate defined above
--The same security policy is used
CREATE SECURITY POLICY RLS.SecurityPolicy_TestDataID_dboTestData
ADD FILTER PREDICATE RLS.AccessPredicate_TestDataID_dboTestData(TestDataID) ON dbo.TestData
,ADD BLOCK PREDICATE RLS.AccessPredicate_TestDataID_dboTestData(TestDataID) ON dbo.TestData AFTER UPDATE
WITH (STATE = ON, SCHEMABINDING = ON)
GO

SELECT *
FROM dbo.TestData
GO

--Identity information is still available:
SELECT IDENT_CURRENT ('dbo.TestData') 
GO

--Grant access to SideChannelUser for possible testing later
GRANT SELECT ON dbo.TestData TO SideChannelUser
GO

/*

SELECT *
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id	= SO.schema_id
	INNER JOIN sys.columns SC
		ON SO.object_id	= SC.object_id
WHERE is_identity = 1
ORDER BY
	SS.name
	,SO.name
	,SC.name

*/