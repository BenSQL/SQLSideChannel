/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Mitigation.01.Views.sql
*	Notes:		Show how a view can be used to bypass the masking issues
********************************************************************/
USE WWISideChannel
GO


--Create user without RLS or masking access
CREATE USER MitigationUser WITHOUT LOGIN
GO

--New schema
CREATE SCHEMA protected
AUTHORIZATION dbo
GO

--Grant direct SELECT access to the new schema
GRANT SELECT ON SCHEMA::protected
TO MitigationUser
GO

--Create view that simulates masking
--The masking logic can be changed
--Standard performance considerations apply
CREATE OR ALTER VIEW protected.DeliveryMethods
AS

SELECT
	DeliveryMethodID
	,CASE WHEN IS_ROLEMEMBER('db_owner') = 1 THEN DeliveryMethodName
		ELSE 'xyz'
	END DeliveryMethodName
	,LastEditedBy
	,ValidFrom
	,ValidTo
FROM Application.DeliveryMethods
GO


--Output from the view
--Running as dbo
SELECT 
	USER_NAME()		[USER_NAME()]
	,*
FROM protected.DeliveryMethods
GO


--Output from the view
--User only has SELECT access to 
--the new schema - no other roles or access
EXEC AS USER = 'MitigationUser'
GO

SELECT
	USER_NAME()		[USER_NAME()]
	,*
FROM protected.DeliveryMethods
GO

REVERT
GO


--Side-channel attack attempt against
--the view
--DeliveryMethodID = 8 starts with 'A'
EXEC AS USER = 'MitigationUser'
GO

SELECT
	USER_NAME()		[USER_NAME()]
	,*
FROM protected.DeliveryMethods
WHERE SUBSTRING(DeliveryMethodName,1,1) = 'A'
GO

REVERT
GO

--Elevated access - function works as expected
SELECT 
	USER_NAME()		[USER_NAME()]
	,*
FROM protected.DeliveryMethods
WHERE SUBSTRING(DeliveryMethodName,1,1) = 'A'
GO

