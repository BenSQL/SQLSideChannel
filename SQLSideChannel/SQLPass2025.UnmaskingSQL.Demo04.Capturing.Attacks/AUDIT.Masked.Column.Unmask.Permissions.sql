USE WWISideChannel
GO

/*
* The following can be used to validate masking security for users
* It requires a basic understanding of the security structure
* used by the application and database.
* It can be expanded for SQL Server 2022 to include column level masking.
*/
SELECT
	@@SERVERNAME		COLLATE Latin1_General_100_CI_AS		ServerName
	,DB_NAME()			COLLATE Latin1_General_100_CI_AS 		DatabaseName
	,SU.name			COLLATE Latin1_General_100_CI_AS 		UserName
	,SR.name			COLLATE Latin1_General_100_CI_AS 		RoleName
	,'Database role'	COLLATE Latin1_General_100_CI_AS 		SecurityType
FROM sys.database_role_members DRM
	INNER JOIN sys.sysusers SU
		ON DRM.member_principal_id			= SU.uid
	INNER JOIN sys.sysusers SR
		ON DRM.role_principal_id			= SR.uid
wHERE SR.name			IN ('db_owner')

UNION

SELECT
	@@SERVERNAME				COLLATE Latin1_General_100_CI_AS 		ServerName
	,'master'					COLLATE Latin1_General_100_CI_AS 		DatabaseName
	,SP.name					COLLATE Latin1_General_100_CI_AS 		LoginName
	,ROL.name					COLLATE Latin1_General_100_CI_AS 		RoleName
	,'Server role'				COLLATE Latin1_General_100_CI_AS 		SecurityType
FROM master.sys.server_role_members SRM
	INNER JOIN master.sys.server_principals SP
		ON SRM.member_principal_id			= SP.principal_id
	INNER JOIN master.sys.server_principals ROL
		ON SRM.role_principal_id			= ROL.principal_id
WHERE ROL.name		IN ('sysadmin')
--AND SP.name = 'sa'
UNION

SELECT
	@@SERVERNAME				COLLATE Latin1_General_100_CI_AS 		ServerName
	,db_name()					COLLATE Latin1_General_100_CI_AS 		DatabaseName
	,SUGR.name					COLLATE Latin1_General_100_CI_AS 		UserName
	,DP.permission_name			COLLATE Latin1_General_100_CI_AS 		RoleName
	,'Database permission'		COLLATE Latin1_General_100_CI_AS 		SecurityType
FROM sys.database_permissions DP
	INNER JOIN sys.sysusers SUGR
		ON DP.grantee_principal_id		= SUGR.uid
WHERE DP.permission_name	IN ('ALTER ANY MASK','CONTROL','UNMASK')


/*
GRANT UNMASK TO UnmaskedReader
GRANT CONTROL TO UnmaskedReader
GRANT ALTER ANY MASK TO UnmaskedReader

*/
