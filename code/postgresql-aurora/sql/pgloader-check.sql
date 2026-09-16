-- Lesson 13: what pgloader created from the SQL Server database, with its default cast rules
SELECT table_name, string_agg(column_name || ' ' || data_type
                              || coalesce('(' || character_maximum_length || ')', '')
                              || coalesce(' default ' || column_default, ''), ', ' ORDER BY ordinal_position) AS columns
FROM information_schema.columns
WHERE table_schema = 'dbo'
GROUP BY table_name
ORDER BY table_name;

-- The notes: money, datetime and datetimeoffset values
SELECT noteid, author, cost, writtenat, writtenlocal FROM dbo.notes ORDER BY noteid;

-- The sequence behind noteid, the constraints by kind (p primary key, f foreign key, n not null, c check), and the
-- indexes, with the OIDs and the hashes of SQL Server's generated names masked
SELECT last_value FROM dbo.notes_noteid_seq;
SELECT contype, count(*) FROM pg_constraint WHERE connamespace = 'dbo'::regnamespace GROUP BY contype ORDER BY contype;
SELECT regexp_replace(pg_get_indexdef(indexrelid), 'idx_[0-9]+_|__[0-9a-f]{8,}', '', 'g') AS index
FROM pg_index
WHERE indrelid::regclass::text LIKE 'dbo.%'
ORDER BY 1;
