/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		AUDIT.Masked.Columns.sql
*	Notes:		Show tables and columns with masked data
********************************************************************/
SET NOCOUNT ON

SELECT
	@@SERVERNAME				ServerName
	,DB_NAME()					DatabaseName
	,SS.name					SchemaName
	,SO.name					ObjectName
	,SC.name					ColumnName
	,SC.is_masked				ColumnIsMasked
	,MC.masking_function		MaskingFunction
	,ST.name					ColumnTypeName
	,CASE
		WHEN st.is_table_type	= 1	THEN TT.name
		WHEN st.is_user_defined = 0 THEN st.name
		WHEN st.is_user_defined = 1	THEN st2.name
	END BaseTypeName
	,ST.system_type_id
	,ST.user_type_id
	,st.schema_id
	,CASE 
		WHEN sc.max_length = -1 THEN 0
		WHEN st.name IN ('nchar','nvarchar') THEN sc.max_length	/ 2
		ELSE sc.max_length
	END	MaxLength
	,st.precision
	,st.scale
	,st.collation_name
	,st.is_user_defined
	,st.is_assembly_type
	,st.is_table_type
	,AT.assembly_qualified_name
FROM sys.schemas SS
	INNER JOIN sys.objects SO
		ON SS.schema_id			= SO.schema_id
	INNER JOIN sys.columns SC
		ON SO.object_id			= SC.object_id
	INNER JOIN sys.types ST
		ON SC.system_type_id	= ST.system_type_id
		AND SC.user_type_id		= ST.user_type_id
	LEFT JOIN sys.masked_columns MC
		ON SC.object_id			= MC.object_id
		AND SC.column_id		= MC.column_id
	LEFT JOIN sys.table_types TT
		ON ST.system_type_id	= TT.system_type_id
		AND ST.user_type_id		= TT.user_type_id
	LEFT JOIN sys.types st2
		ON st.system_type_id		= st2.system_type_id 
		AND st2.system_type_id		= st2.user_type_id
		AND st.is_user_defined		= 1
	LEFT JOIN sys.assembly_types AT
		ON ST.system_type_id	= AT.system_type_id
		AND ST.user_type_id		= AT.user_type_id
WHERE SC.is_masked				= 1
ORDER BY
	SS.name
	,SO.name
	,SC.name
GO
