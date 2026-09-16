-- Lesson 13, exercise 2: the columns whose type needs a decision before the conversion, from SQL Server's catalog
SET NOCOUNT ON;
USE ci;
SELECT t.name AS [table], c.name AS [column], ty.name AS type, c.scale, c.is_computed, c.is_identity
FROM sys.columns AS c
JOIN sys.tables AS t ON t.object_id = c.object_id
JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE ty.name IN ('datetime', 'smalldatetime', 'datetime2', 'datetimeoffset', 'money', 'smallmoney', 'tinyint',
                  'uniqueidentifier', 'timestamp', 'sql_variant', 'hierarchyid', 'xml', 'image', 'text', 'ntext')
   OR c.is_computed = 1 OR c.is_identity = 1
ORDER BY t.name, c.column_id;

-- Collations other than the database's, and the strings that differ only by case or trailing spaces
SELECT t.name AS [table], c.name AS [column], c.collation_name
FROM sys.columns AS c JOIN sys.tables AS t ON t.object_id = c.object_id
WHERE c.collation_name IS NOT NULL AND c.collation_name <> CAST(DATABASEPROPERTYEX('ci', 'Collation') AS sysname)
ORDER BY t.name, c.column_id;
SELECT Author COLLATE Latin1_General_BIN2 AS author, COUNT(*) AS notes
FROM dbo.Notes
GROUP BY Author COLLATE Latin1_General_BIN2
ORDER BY author;
GO
