/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		SHOW.Object.Text.sql
*	Notes:		Reads sys.syscomments and shows output
********************************************************************/
USE WWISideChannel
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
GO

DECLARE @Object		varchar(255)		= '[RLS].[AccessPredicate_SupplierID_PurchasingSuppliers]'	--'[Application].[DetermineCustomerAccess]'	--

;
WITH COMMENT_CTE AS (
	SELECT
		CONVERT(varchar(max),SC.text) SPText
		,SO.object_id
		,SS.name		SchemaName
		,SO.name		ObjectName
		,CASE SO.type
			WHEN 'p' THEN 'Stored Procedure'
			WHEN 'tr' THEN 'DML trigger'
			WHEN 'fn' THEN 'Scalar function'
			WHEN 'if' THEN 'Inline table-valued function'
			WHEN 'tf' THEN 'Table-valued function'
		END				ObjectType
		,ROW_NUMBER() OVER(PARTITION BY SO.object_id ORDER BY SO.object_id, SC.colid) SELECT_CRITERIA
	FROM sys.objects SO
		INNER JOIN sys.schemas SS
			ON SO.schema_id = SS.schema_id
		INNER JOIN sys.syscomments SC
			ON SO.object_id	= SC.id
	WHERE SO.object_id	= OBJECT_ID(@Object)

)
, COMMENT_ANCHOR_CTE AS (
	SELECT
		CONVERT(varchar(max),SPText) SPText
		,Object_id
		,SchemaName
		,ObjectName
		,ObjectType
		,SELECT_CRITERIA
	FROM COMMENT_CTE
	WHERE SELECT_CRITERIA = 1
)
,COMMENT_RECURSIVE_CTE AS (
	SELECT
		SPText
		,object_id
		,SchemaName
		,ObjectName
		,ObjectType
		,SELECT_CRITERIA
	FROM COMMENT_ANCHOR_CTE
	UNION ALL
	SELECT
		CAC.SPText + CC.SPText
		,CC.object_id
		,CC.SchemaName
		,CC.ObjectName
		,CC.ObjectType
		,CC.SELECT_CRITERIA
	FROM COMMENT_CTE CC
		INNER JOIN COMMENT_RECURSIVE_CTE CAC
			ON CC.object_id = CAC.object_id
			AND CC.SELECT_CRITERIA = CAC.SELECT_CRITERIA + 1
)

SELECT
	SPText
FROM COMMENT_RECURSIVE_CTE CRC
WHERE SELECT_CRITERIA = (SELECT MAX(SELECT_CRITERIA) FROM COMMENT_CTE CC WHERE CC.object_id = CRC.object_id)
ORDER BY
	ObjectType
	,SchemaName
	,ObjectName


