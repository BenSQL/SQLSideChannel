/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AUDIT.RLS.Tables.sql
*	Notes:		Returns a list of all tables using RLS,
*				security predicate names and access predicate names.
********************************************************************/
USE WWISideChannel
GO

SET NOCOUNT ON
;
WITH ACCESS_PREDICATES AS (
	SELECT DISTINCT
		SP.object_id
		,SP.target_object_id
		,SP.predicate_definition
		,SS.value				AccessPredicateName
	FROM sys.security_predicates SP
		CROSS APPLY string_split(SP.predicate_definition,N'(') SS
	WHERE SS.value <> ''
		AND SS.value NOT LIKE '%))'
)

SELECT DISTINCT
	@@SERVERNAME						ServerName
	,DB_NAME()							DatabaseName
	,SS.name							SchemaName
	,SO.name							TableName
	,SSSP.name							SecurityPolicySchema
	,SSP.name							SecurityPolicyName
	--,SSP.type_desc						SecurityPolicyDescription
	,SSP.is_enabled						SecurityPolicyIsEnabled
	,AP.AccessPredicateName
	,SP.operation_desc
	,SP.predicate_type_desc
	,SP.predicate_definition			AccessPredicateDefinition
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id			= SO.schema_id
	INNER JOIN sys.security_predicates SP
		ON SO.object_id			= SP.target_object_id
	INNER JOIN sys.security_policies SSP
		ON SP.object_id			= SSP.object_id
	INNER JOIN sys.schemas SSSP
		ON SSP.schema_id		= SSSP.schema_id
	LEFT JOIN ACCESS_PREDICATES AP
		ON SP.object_id			= AP.object_id
		AND SP.target_object_id	= AP.target_object_id
ORDER BY
	SS.name
	,SO.name
	,SSP.name
GO
