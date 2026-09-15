---
title: 2. Types and modeling
description: The course model, and PostgreSQL's native types seen from SQL Server — numeric and float, text and varchar, timestamptz and what it doesn't store, intervals, uuid version 7, json and jsonb, arrays and ranges — with CHECK constraints, domains, exclusion constraints, UNIQUE and NULL, and virtual generated columns; and what the constraints find in Guitar Alchemist's project references.
sidebar:
  order: 2
---

The model of the course is [`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql); every script from this lesson on loads it first. The lesson's own script is [`sql/02-types.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql), the exercises are in [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql), and `check.sh` compares their output with [`expected/02-types.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-types.txt) and [`expected/02-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-exercises.txt).

## From SQL Server's types

| SQL Server | PostgreSQL | Watch out |
|---|---|---|
| `int`, `bigint`, `smallint` | `integer`, `bigint`, `smallint` | no `tinyint`, no unsigned types |
| `bit` | `boolean` | a real type, with `true`, `false` and `NULL` |
| `decimal(p,s)`, `money` | `numeric(p,s)` | PostgreSQL's `money` exists, and depends on the `lc_monetary` setting |
| `float`, `real` | `double precision` (`float8`), `real` (`float4`) | |
| `nvarchar(n)`, `varchar(n)` | `text`, or `varchar(n)` | every string is in the database's encoding, UTF-8 here: no `n` prefix, no `N'…'` literals |
| `nvarchar(max)` | `text` | up to 1 GB |
| `varbinary(max)` | `bytea` | |
| `datetime2` | `timestamp` | |
| `datetimeoffset` | `timestamptz` | doesn't keep the offset |
| `time`, `date` | `time`, `date` | |
| no equivalent | `interval` | a duration |
| `uniqueidentifier` | `uuid` | sorts by bytes, not SQL Server's odd byte order |
| JSON in `nvarchar(max)`, or the `json` type of SQL Server 2025 | `jsonb` | |
| table-valued parameter, delimited string | arrays: `text[]`, `integer[]` | |
| no equivalent | ranges: `tstzrange`, `int4range`, `daterange` | |
| computed column, `PERSISTED` | generated column, virtual or `STORED` | |
| alias type (`CREATE TYPE … FROM`) | domain (`CREATE DOMAIN`) | a domain can carry a `CHECK` |

The rest of the lesson runs the rows where the difference matters. The [data types chapter](https://www.postgresql.org/docs/18/datatype.html) lists them all.

## The course model

[`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql) turns the JSON and CSV files of the course into typed tables in two schemas. The CI history first ([lines 7-50](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L7-L50)):

```sql
CREATE DOMAIN ci.conclusion AS text
    CHECK (VALUE IN ('success', 'failure', 'cancelled', 'skipped', 'startup_failure'));

CREATE TABLE ci.runs (
    run_id        bigint PRIMARY KEY,
    workflow_name text NOT NULL,
    event         text NOT NULL,
    conclusion    ci.conclusion,
    head_branch   text NOT NULL,
    head_sha      text NOT NULL CHECK (head_sha ~ '^[0-9a-f]{40}$'),
    attempt       smallint NOT NULL CHECK (attempt >= 1),
    created_at    timestamptz NOT NULL,
    started_at    timestamptz NOT NULL,
    updated_at    timestamptz NOT NULL,
    CHECK (updated_at >= started_at)
);

CREATE TABLE ci.jobs (
    job_id       bigint PRIMARY KEY,
    run_id       bigint NOT NULL REFERENCES ci.runs,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    labels       text[] NOT NULL,
    runner_name  text,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL,
    duration     interval GENERATED ALWAYS AS (completed_at - started_at)
);

-- btree_gist lets a GiST index compare bigint with =, next to the && of ranges
CREATE EXTENSION btree_gist;

CREATE TABLE ci.steps (
    job_id       bigint NOT NULL REFERENCES ci.jobs,
    number       smallint NOT NULL,
    name         text NOT NULL,
    conclusion   ci.conclusion,
    started_at   timestamptz NOT NULL,
    completed_at timestamptz NOT NULL CHECK (completed_at >= started_at),
    ran          tstzrange GENERATED ALWAYS AS (tstzrange(started_at, completed_at, '[)')) STORED,
    PRIMARY KEY (job_id, number),
    -- the steps of one job never run at the same time
    EXCLUDE USING gist (job_id WITH =, ran WITH &&)
);
```

The loading part ([lines 52-73](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L52-L73)) reads `runs.json` with `jsonb_to_recordset`, as in lesson 1, and `jobs.json`, one array of 315 jobs with their steps nested inside, with the `->>` operator, which extracts a field as text. Lesson 7 is about JSON; here it's a means to an end. Guitar Alchemist's projects and references come from CSV files, loaded with [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), and its iconic chords from JSON ([lines 75-134](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L75-L134)). The sections below explain each choice.

## Numbers

[Lines 7-9](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L7-L9):

```sql
SELECT 0.1::float8 + 0.2::float8 AS float8, 0.1 + 0.2 AS numeric, 7 / 2 AS int_division, 7 / 2.0 AS numeric_division;
SELECT 2147483647 + 1;
SELECT 1234.5::numeric(5, 2);
```

```text
       float8        | numeric | int_division |  numeric_division
---------------------+---------+--------------+--------------------
 0.30000000000000004 |     0.3 |            3 | 3.5000000000000000
(1 row)

ERROR:  integer out of range
ERROR:  numeric field overflow
DETAIL:  A field with precision 5, scale 2 must round to an absolute value less than 10^3.
```

- A literal with a decimal point, such as `0.1`, is a [`numeric`](https://www.postgresql.org/docs/18/datatype-numeric.html#DATATYPE-NUMERIC-DECIMAL), exact, and `0.1 + 0.2` is exactly `0.3`. In SQL Server, the literal would be a `decimal` too. `float8` shows the binary rounding error, like `double` in C#.
- Integer division truncates, as in SQL Server, C# and Java. `7 / 2.0` is `numeric`, and PostgreSQL picked 16 digits after the point for the result.
- Overflow is an error, not a wrap-around: `int` + `int` stays `int`. SQL Server raises "Arithmetic overflow error" in the same place.
- `numeric(5, 2)` means 5 digits in total, 2 of them after the point: at most 999.99.

Use `numeric` for money and anything counted in decimal units, `bigint` for identifiers, and `double precision` for measurements.

## Text

[Lines 12-15](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L12-L15):

```sql
SELECT 'windows-latest'::varchar(7) AS cast_truncates;
CREATE TABLE ci.labels (label varchar(7));
INSERT INTO ci.labels VALUES ('windows-latest');
SELECT 'ab'::char(4) || '|' AS char_concat, length('é') AS characters, octet_length('é') AS bytes;
```

```text
 cast_truncates
----------------
 windows
(1 row)

CREATE TABLE
ERROR:  value too long for type character varying(7)
 char_concat | characters | bytes
-------------+------------+-------
 ab|         |          1 |     2
(1 row)
```

- An **explicit cast** to `varchar(7)` truncates without an error, as the SQL standard requires. **Storing** a longer value is an error. SQL Server behaves the same way: `CAST` truncates, and `INSERT` fails with "String or binary data would be truncated".
- `char(4)` pads with spaces, and the padding disappears as soon as the value becomes text: `'ab'::char(4) || '|'` is `ab|`. The [documentation](https://www.postgresql.org/docs/18/datatype-character.html) recommends `text` or `varchar` over `char(n)`.
- `length` counts characters, `octet_length` bytes: `é` is two bytes in UTF-8.

`text` and `varchar(n)` are stored the same way and are equally fast; the documentation says so in a tip on the same page. The limit of `varchar(n)` is a constraint: raising it later doesn't rewrite the table, but it's still an `ALTER TABLE` for a rule that a `CHECK` could state better. The course model uses `text`, and a `CHECK` when a real rule exists, as for `head_sha`.

## Timestamps: what timestamptz stores

`timestamp with time zone`, `timestamptz` for short, is the type to use for moments. Its name misleads: **it doesn't store a time zone**. It stores an instant, as UTC, converts input to UTC using the offset given or the session's `TimeZone` setting, and converts output to the session's `TimeZone` ([lines 18-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L18-L24)):

```sql
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SET TimeZone = 'America/Toronto';
SELECT run_id, started_at FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT started_at AT TIME ZONE 'Asia/Tokyo' AS tokyo_wall_clock, pg_typeof(started_at AT TIME ZONE 'Asia/Tokyo')
FROM ci.runs ORDER BY started_at DESC, run_id LIMIT 1;
SELECT '2026-09-14 10:01:09+02'::timestamptz AS timestamptz, '2026-09-14 10:01:09+02'::timestamp AS timestamp;
RESET TimeZone;
```

```text
   run_id    |       started_at
-------------+------------------------
 34852867099 | 2026-09-14 14:01:09+00
(1 row)

SET
   run_id    |       started_at
-------------+------------------------
 34852867099 | 2026-09-14 10:01:09-04
(1 row)

  tokyo_wall_clock   |          pg_typeof
---------------------+-----------------------------
 2026-09-14 23:01:09 | timestamp without time zone
(1 row)

      timestamptz       |      timestamp
------------------------+---------------------
 2026-09-14 04:01:09-04 | 2026-09-14 10:01:09
(1 row)

RESET
```

- The same row, two displays: `14:01:09+00` in UTC, `10:01:09-04` in Toronto during daylight saving time. Nothing was converted in the table; only the output changed.
- `AT TIME ZONE` on a `timestamptz` gives the wall-clock time in that zone, as a `timestamp` without time zone.
- **The trap**: the same string cast to `timestamp` keeps `10:01:09` and drops `+02` without a warning. The [documentation](https://www.postgresql.org/docs/18/datatype-datetime.html#DATATYPE-TIMEZONES) says that PostgreSQL "will silently ignore any time zone indication" in a literal for `timestamp without time zone`. Cast to `timestamptz`, the same string is the instant 08:01:09 UTC, displayed as 04:01:09 in Toronto.

The difference with SQL Server's `datetimeoffset`: that type keeps the offset it received, and gives back `10:01:09 +02:00`. `timestamptz` gives back the instant in the reader's time zone. If the original offset matters, for instance the local time of a user, store the time zone name in a column next to it.

Every script of the course runs with `TimeZone=UTC`: `server.sh` sets it in `PGOPTIONS`, so that the outputs are the same on every machine. The image's default is `Etc/UTC` as well, but a server installed on a laptop takes the operating system's zone. Lesson 4 shows the drivers' choices: Npgsql and the JDBC driver don't agree.

## Intervals and generated columns

An `interval` is a duration. `ci.jobs.duration` is a **generated column**, computed from two other columns ([lines 27-31](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L27-L31)):

```sql
SELECT labels[1] AS os, count(*) AS jobs, avg(duration) AS average, max(duration) AS longest
FROM ci.jobs
GROUP BY labels[1]
ORDER BY os;
UPDATE ci.jobs SET duration = interval '1 minute' WHERE job_id = 103842192310;
```

```text
       os       | jobs |     average     | longest
----------------+------+-----------------+----------
 macos-latest   |   34 | 00:00:55.676471 | 00:04:30
 ubuntu-latest  |  246 | 00:00:21.430894 | 00:03:39
 windows-latest |   35 | 00:01:36.714286 | 00:04:44
(3 rows)

ERROR:  column "duration" can only be updated to DEFAULT
DETAIL:  Column "duration" is a generated column.
```

A Windows job of this site's CI takes four and a half times as long as a Linux job, on average. `avg` and `max` work on intervals directly.

Since [PostgreSQL 18](https://www.postgresql.org/docs/18/ddl-generated-columns.html), a generated column is **virtual** by default: computed when it's read, not stored, like a SQL Server computed column without `PERSISTED`. Up to PostgreSQL 17, only `STORED` existed, and old tutorials write it everywhere. Exercise 3 finds a limit of virtual columns. `ci.steps.ran` is `STORED`, because the exclusion constraint below needs an index on it.

## Booleans

[Line 34](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L34):

```sql
SELECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::boolean;
```

```text
ERROR:  invalid input syntax for type boolean: "maybe"
LINE 1: ...ECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::b...
                                                             ^
```

The statement fails as a whole, so the first two columns are never shown. [`boolean`](https://www.postgresql.org/docs/18/datatype-boolean.html) accepts `true`, `yes`, `on`, `1` and their opposites as input, prints `t` and `f`, and appears as `bool` in drivers, where SQL Server's `bit` is a number. `WHERE is_active` is a complete condition; no `= 1`.

## uuid, version 7

[`uuid`](https://www.postgresql.org/docs/18/datatype-uuid.html) is a 16-byte type. PostgreSQL 18 added [`uuidv7()`](https://www.postgresql.org/docs/18/functions-uuid.html), which generates UUIDs of version 7: the first 48 bits are a Unix timestamp in milliseconds, so values generated later sort later, and new rows land at the end of the primary key's index instead of at random places ([lines 37-49](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L37-L49)):

```sql
CREATE TABLE ci.annotations (
    annotation_id uuid PRIMARY KEY DEFAULT uuidv7(),
    job_id        bigint NOT NULL REFERENCES ci.jobs,
    message       text NOT NULL
);
INSERT INTO ci.annotations (job_id, message)
SELECT job_id, 'slowest ' || labels[1] || ' job'
FROM (SELECT DISTINCT ON (labels[1]) job_id, labels FROM ci.jobs ORDER BY labels[1], duration DESC, job_id) AS slowest;
SELECT uuid_extract_version(annotation_id) AS version,
       uuid_extract_timestamp(annotation_id) BETWEEN now() - interval '1 minute' AND now() AS created_just_now,
       message
FROM ci.annotations
ORDER BY annotation_id;
```

```text
CREATE TABLE
INSERT 0 3
 version | created_just_now |          message
---------+------------------+----------------------------
       7 | t                | slowest macos-latest job
       7 | t                | slowest ubuntu-latest job
       7 | t                | slowest windows-latest job
(3 rows)
```

The script doesn't print the UUIDs: they change at every run. It prints what doesn't change, their version and the fact that their timestamp is from the last minute. Sorted by `annotation_id`, the rows come out in insertion order: within one connection, PostgreSQL makes each version 7 value greater than the previous one, even within the same millisecond ([`uuid.c`, lines 563-604](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/utils/adt/uuid.c#L563-L604)). `DISTINCT ON`, which picks the slowest job of each OS here, is lesson 3's.

`gen_random_uuid()`, or `uuidv4()` since PostgreSQL 18, generates random ones. SQL Server's `NEWSEQUENTIALID()` has the same goal as version 7 with a different layout, and SQL Server sorts `uniqueidentifier` by its last bytes first; a .NET `Guid` sent to PostgreSQL sorts by its first bytes. .NET 9 added `Guid.CreateVersion7()`.

## json and jsonb

[Line 52](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L52):

```sql
SELECT '{"b": 1, "a": [1, 2], "a": 3}'::json AS json, '{"b": 1, "a": [1, 2], "a": 3}'::jsonb AS jsonb;
```

```text
             json              |      jsonb
-------------------------------+------------------
 {"b": 1, "a": [1, 2], "a": 3} | {"a": 3, "b": 1}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) stores the text as received, checked but not parsed: duplicate keys, key order and spaces are kept, and every operation parses it again. `jsonb` stores a binary, parsed value: the last duplicate key wins, keys are reordered, and it can be indexed. Use `jsonb`, unless you must give back exactly the document you received. Lesson 7 covers the operators and the indexes.

## Arrays

A column can hold an [array](https://www.postgresql.org/docs/18/arrays.html) of any type. `ci.jobs.labels` is `text[]`, because GitHub gives each job a list of runner labels ([lines 55-57](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L55-L57)):

```sql
SELECT labels, count(*) AS jobs FROM ci.jobs GROUP BY labels ORDER BY jobs DESC, labels;
SELECT count(*) AS macos_jobs FROM ci.jobs WHERE 'macos-latest' = ANY (labels);
SELECT string_to_array('0,4,7,10', ',')::int[] AS pitch_classes, string_to_array('Jimi Hendrix||Prince', '|') AS artists;
```

```text
      labels      | jobs
------------------+------
 {ubuntu-latest}  |  246
 {windows-latest} |   35
 {macos-latest}   |   34
(3 rows)

 macos_jobs
------------
         34
(1 row)

 pitch_classes |          artists
---------------+----------------------------
 {0,4,7,10}    | {"Jimi Hendrix","",Prince}
(1 row)
```

- Arrays print between braces, with double quotes around elements that need them. **Indexes start at 1**: `labels[1]` is the first label.
- `= ANY (array)` tests membership. It also replaces `IN (…)` lists in parameterised queries, as lesson 4 shows.
- In this snapshot, every job has exactly one label; the type still allows more, as GitHub does.

Guitar Alchemist has lists too. Its EF Core model, [`MusicalKnowledgeDbContext`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs#L32-L45), stores a chord's `List<int> PitchClasses` as a string joined with commas, and its `List<string> AlternateNames` joined with `|`, through EF Core value converters: SQLite, the provider it references, has no arrays. The last query above shows two things a joined string doesn't say: that the numbers are numbers, and that an empty name between two separators is an element. GA's converter reads with `StringSplitOptions.RemoveEmptyEntries`, which drops it; lesson 4 runs that converter against PostgreSQL. The course model stores the chords with arrays instead ([`schema.sql`, lines 98-112](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L98-L112)):

```sql
CREATE DOMAIN ga.pitch_class AS smallint CHECK (VALUE BETWEEN 0 AND 11);

CREATE TABLE ga.iconic_chords (
    chord_id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             text NOT NULL UNIQUE,
    theoretical_name text NOT NULL,
    artist           text NOT NULL,
    song             text NOT NULL,
    era              text NOT NULL,
    genre            text NOT NULL,
    pitch_classes    ga.pitch_class[] NOT NULL,
    -- one fret per string, from low E to high E; -1 for a string not played
    guitar_voicing   smallint[] CHECK (cardinality(guitar_voicing) = 6),
    alternate_names  text[] NOT NULL
);
```

An array of a domain checks every element: exercise 1 tries a pitch class of 12. The cost of arrays: no foreign key on an element, and a table of chord notes is still the right design when the elements have their own attributes or must be joined often. For a short list that belongs to its row, an array is simpler than a child table and safer than a joined string.

## Ranges and exclusion constraints

A [range](https://www.postgresql.org/docs/18/rangetypes.html) is one value with a lower and an upper bound, each included (`[` `]`) or excluded (`(` `)`). `ci.steps.ran` is the `tstzrange` from a step's start to its end ([lines 60-68](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L60-L68)):

```sql
SELECT number, name, started_at, completed_at, ran, isempty(ran) AS empty
FROM ci.steps WHERE job_id = 103842192310 ORDER BY number LIMIT 4;
SELECT count(*) FILTER (WHERE isempty(ran)) AS zero_second_steps, count(*) AS steps FROM ci.steps;
SELECT count(*) AS overlapping_if_closed
FROM ci.steps AS a
JOIN ci.steps AS b ON a.job_id = b.job_id AND a.number < b.number
WHERE tstzrange(a.started_at, a.completed_at, '[]') && tstzrange(b.started_at, b.completed_at, '[]');
INSERT INTO ci.steps (job_id, number, name, conclusion, started_at, completed_at)
VALUES (103842192310, 99, 'Overlapping step', 'success', '2026-09-14 02:50:35+00', '2026-09-14 02:50:36+00');
```

```text
 number |            name             |       started_at       |      completed_at      |                         ran                         | empty
--------+-----------------------------+------------------------+------------------------+-----------------------------------------------------+-------
      1 | Set up job                  | 2026-09-14 02:50:32+00 | 2026-09-14 02:50:33+00 | ["2026-09-14 02:50:32+00","2026-09-14 02:50:33+00") | f
      2 | Run actions/checkout@v7     | 2026-09-14 02:50:33+00 | 2026-09-14 02:50:40+00 | ["2026-09-14 02:50:33+00","2026-09-14 02:50:40+00") | f
      3 | Run actions/setup-java@v6   | 2026-09-14 02:50:40+00 | 2026-09-14 02:50:41+00 | ["2026-09-14 02:50:40+00","2026-09-14 02:50:41+00") | f
      4 | Run actions/setup-dotnet@v6 | 2026-09-14 02:50:41+00 | 2026-09-14 02:51:13+00 | ["2026-09-14 02:50:41+00","2026-09-14 02:51:13+00") | f
(4 rows)

 zero_second_steps | steps
-------------------+-------
               857 |  2204
(1 row)

 overlapping_if_closed
-----------------------
                  2798
(1 row)

ERROR:  conflicting key value violates exclusion constraint "steps_job_id_ran_excl"
DETAIL:  Key (job_id, ran)=(103842192310, ["2026-09-14 02:50:35+00","2026-09-14 02:50:36+00")) conflicts with existing key (job_id, ran)=(103842192310, ["2026-09-14 02:50:33+00","2026-09-14 02:50:40+00")).
```

The model's choices, and why:

- **Half-open, `[)`.** GitHub's API gives times to the second, and each step starts the second the previous one ends. With both bounds included, step 1 `[02:50:32, 02:50:33]` and step 2 `[02:50:33, 02:50:40]` share 02:50:33, and 2,798 pairs of steps of the same job would "overlap". With the end excluded, none do.
- **The price of `[)`.** 857 of the 2,204 steps, 39%, started and ended in the same second, and `[t, t)` is an **empty range**: it contains nothing, and its bounds are gone (`lower()` of an empty range is `NULL`). That's why the table keeps `started_at` and `completed_at`, and derives `ran` from them.
- **The exclusion constraint.** `EXCLUDE USING gist (job_id WITH =, ran WITH &&)` refuses two rows whose `job_id` values are equal *and* whose ranges overlap (`&&`): a uniqueness constraint generalised to any operator. It's enforced by a GiST index, and the [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html) extension teaches GiST the `=` of `bigint`. The inserted step, 02:50:35 to 02:50:36, falls inside step 2, and the error names both rows. SQL Server has no equivalent; the usual workaround is a trigger.

## Domains and CHECK constraints

[Lines 71-72](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L71-L72):

```sql
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'neutral', 'main', repeat('a', 40), 1, '2026-09-15', '2026-09-15', '2026-09-15');
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'success', 'main', 'not-a-sha', 1, '2026-09-15', '2026-09-15', '2026-09-15');
```

```text
ERROR:  value for domain ci.conclusion violates check constraint "conclusion_check"
ERROR:  new row for relation "runs" violates check constraint "runs_head_sha_check"
DETAIL:  Failing row contains (1, Test, push, success, main, not-a-sha, 1, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00).
```

A [domain](https://www.postgresql.org/docs/18/domains.html) is a type with constraints, defined once and used by several columns: `ci.conclusion` in three tables. The alternatives are an [enum type](https://www.postgresql.org/docs/18/datatype-enum.html), whose values can be added but not removed without recreating it, and a lookup table with a foreign key, which is the right choice when the values have attributes or change often. `neutral` is a real GitHub conclusion that this snapshot doesn't contain; when it appears, `ALTER DOMAIN` replaces the constraint.

A `CHECK` on a column can use any expression of the row, here a [regular expression](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-POSIX-REGEXP) with `~`. SQL Server's `CHECK` has no regular expressions before SQL Server 2025's `REGEXP_LIKE`. The `DETAIL` prints the failing row; lesson 4 shows that Npgsql hides it by default.

## UNIQUE and NULL

[Lines 75-79](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L75-L79):

```sql
CREATE TABLE ga.owners (project text REFERENCES ga.projects, email text UNIQUE);
INSERT INTO ga.owners VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);
SELECT count(*) AS owners_without_email FROM ga.owners WHERE email IS NULL;
CREATE TABLE ga.maintainers (project text REFERENCES ga.projects, email text UNIQUE NULLS NOT DISTINCT);
INSERT INTO ga.maintainers VALUES ('Apps/ga-server/GaApi/GaApi.csproj', NULL), ('Common/GA.Core/GA.Core.csproj', NULL);
```

```text
CREATE TABLE
INSERT 0 2
 owners_without_email
----------------------
                    2
(1 row)

CREATE TABLE
ERROR:  duplicate key value violates unique constraint "maintainers_email_key"
DETAIL:  Key (email)=(null) already exists.
```

This one is the opposite of SQL Server. A SQL Server `UNIQUE` constraint allows **one** `NULL`, and the usual workaround for "unique when present" is a filtered unique index, `WHERE email IS NOT NULL`. PostgreSQL follows the SQL standard: `NULL` is not equal to `NULL`, so a `UNIQUE` column accepts **any number** of `NULL`s. [`NULLS NOT DISTINCT`](https://www.postgresql.org/docs/18/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS), since PostgreSQL 15, gives SQL Server's behaviour. A migrated schema keeps its constraints and silently changes their meaning.

## What the constraints find in Guitar Alchemist

`schema.sql` loads Guitar Alchemist's project references through a `DISTINCT` and a join, and its comment says why. Without them ([lines 82-87](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L82-L87)):

```sql
CREATE TABLE ga.raw_refs (LIKE ga.project_refs INCLUDING ALL);
ALTER TABLE ga.raw_refs ADD FOREIGN KEY (from_path) REFERENCES ga.projects, ADD FOREIGN KEY (to_path) REFERENCES ga.projects;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER match);
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
ALTER TABLE ga.raw_refs DROP CONSTRAINT raw_refs_pkey;
COPY ga.raw_refs FROM '/course/data/ga/project_refs.csv' (FORMAT csv, HEADER true);
```

```text
CREATE TABLE
ALTER TABLE
ERROR:  column name mismatch in header line field 1: got "from", expected "from_path"
CONTEXT:  COPY raw_refs, line 1: "from,to"
ERROR:  duplicate key value violates unique constraint "raw_refs_pkey"
DETAIL:  Key (from_path, to_path)=(Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj, Common/GA.Business.Config/GA.Business.Config.fsproj) already exists.
CONTEXT:  COPY raw_refs, line 61
ALTER TABLE
ERROR:  insert or update on table "raw_refs" violates foreign key constraint "raw_refs_to_path_fkey"
DETAIL:  Key (to_path)=(Experiments/React/reactapp1.client/reactapp1.client.esproj) is not present in table "projects".
```

1. `HEADER match`, since PostgreSQL 15, compares the CSV's header with the table's columns, and the file says `from,to`. `HEADER true` only skips the first line.
2. The primary key finds a reference listed twice: [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj#L26-L31) references `GA.Business.Config.fsproj` on line 26 and again on line 31, still at commit `32f143c`. MSBuild accepts the duplicate; a relational model doesn't. `COPY` stops at the first error, and no row of the file is kept: a `COPY` is one statement, and a statement is atomic.
3. Without the primary key, the foreign key finds a reference to `reactapp1.client.esproj`, a JavaScript project of Visual Studio's React template, which the extraction didn't count as a .NET project. That one is a limit of the data, not a bug.

[`LIKE … INCLUDING ALL`](https://www.postgresql.org/docs/18/sql-createtable.html) copies columns, defaults, constraints and indexes, but not foreign keys, which the `ALTER TABLE` adds back.

## On Aurora

*To verify: nothing in this section ran on AWS.* Aurora PostgreSQL runs PostgreSQL's own engine, so the types, domains, constraints and generated columns of this lesson are PostgreSQL 18's. Two differences to check before relying on the lesson:

- **The minor version.** On 2026-09-15, the newest Aurora release is 18.4.1, compatible with PostgreSQL 18.4; the course uses 18.6. Bug fixes between 18.4 and 18.6 are not in Aurora yet.
- **Extension versions.** The [Aurora PostgreSQL 18 extension table](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) lists `btree_gist` 1.6 for Aurora PostgreSQL 18.4, where PostgreSQL 18.6 in the image offers 1.8 (`SELECT default_version FROM pg_available_extensions WHERE name = 'btree_gist'`). The exclusion constraint of `ci.steps` only needs the `bigint` support that older versions already had, but a newer extension feature might not be there. Only the extensions on that list can be installed.

## Key takeaways

- `numeric` is exact, `float8` is not; integer division truncates and overflow is an error.
- Prefer `text` with a `CHECK` to `varchar(n)`, and never use `char(n)`.
- `timestamptz` stores an instant, not a time zone; a string cast to `timestamp` loses its offset silently.
- Generated columns are virtual by default since PostgreSQL 18; indexes and exclusion constraints need `STORED`.
- `uuidv7()` gives ordered UUIDs; `jsonb` rather than `json`.
- Arrays and ranges are column types: `= ANY`, `&&`, and exclusion constraints replace child tables, joined strings and triggers where they fit.
- `UNIQUE` allows many `NULL`s unless `NULLS NOT DISTINCT`: the opposite of SQL Server.
- Constraints are also a data-quality tool: they found a duplicated `ProjectReference` in Guitar Alchemist.

## Exercises

The solutions are in [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql).

1. List the iconic chords that contain both E (pitch class 4) and B (pitch class 11), with their number of notes and their first alternate name. Then try to add the pitch class 12 to the Power Chord.

<details>
<summary>Solution</summary>

From [`sql/02-exercises.sql`, lines 7-11](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L7-L11):

```sql
SELECT name, pitch_classes, cardinality(pitch_classes) AS notes, alternate_names[1] AS first_alias
FROM ga.iconic_chords
WHERE pitch_classes @> '{4,11}'
ORDER BY name;
UPDATE ga.iconic_chords SET pitch_classes = pitch_classes || 12::smallint WHERE name = 'Power Chord';
```

```text
       name       |  pitch_classes  | notes |     first_alias
------------------+-----------------+-------+---------------------
 Debussy Chord    | {0,4,7,11,2}    |     5 | Impressionist Chord
 Elektra Chord    | {4,8,11,2,5,10} |     6 | Strauss Chord
 Hendrix Chord    | {4,8,11,2,7}    |     5 | Purple Haze Chord
 James Bond Chord | {4,7,11,3}      |     4 | Spy Chord
 So What Chord    | {4,9,2,7,11}    |     5 | Em11
(5 rows)

ERROR:  value for domain ga.pitch_class violates check constraint "pitch_class_check"
```

`@>` means "contains": every element of the right-hand array is in the left-hand one, in any order. `cardinality` counts the elements; `array_length(a, 1)` does too, but returns `NULL` for an empty array. `||` appends an element, and the domain checks it: the constraint of `ga.pitch_class` applies to each element of the array. Lesson 7 indexes `@>` with GIN.

</details>

2. Count the runs per calendar day, once by UTC date and once by the date on a wall clock in Toronto. Why are there three rows for two days?

<details>
<summary>Solution</summary>

From [`sql/02-exercises.sql`, lines 14-19](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L14-L19):

```sql
SELECT started_at::date AS utc_day,
       (started_at AT TIME ZONE 'America/Toronto')::date AS toronto_day,
       count(*) AS runs
FROM ci.runs
GROUP BY 1, 2
ORDER BY 1, 2;
```

```text
  utc_day   | toronto_day | runs
------------+-------------+------
 2026-09-13 | 2026-09-13  |   43
 2026-09-14 | 2026-09-13  |   23
 2026-09-14 | 2026-09-14  |   59
(3 rows)
```

23 runs started on September 14 in UTC, between midnight and 04:00, while it was still September 13 in Toronto. `started_at::date` converts in the session's time zone, UTC in the course's scripts; the same query in a session set to `America/Toronto` would give Toronto's dates in the first column. A report "per day" must say whose day, and `AT TIME ZONE` makes it explicit instead of depending on the connection.

</details>

3. Create an index on `ci.jobs.duration` to find the long jobs. What happens? How do you get an index that the query `WHERE completed_at - started_at > interval '4 minutes'` can use?

<details>
<summary>Solution</summary>

From [`sql/02-exercises.sql`, lines 22-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L22-L24):

```sql
CREATE INDEX ON ci.jobs (duration);
CREATE INDEX jobs_duration_idx ON ci.jobs ((completed_at - started_at));
EXPLAIN (COSTS OFF) SELECT job_id FROM ci.jobs WHERE completed_at - started_at > interval '4 minutes';
```

```text
ERROR:  indexes on virtual generated columns are not supported
CREATE INDEX
                           QUERY PLAN
----------------------------------------------------------------
 Seq Scan on jobs
   Filter: ((completed_at - started_at) > '00:04:00'::interval)
(2 rows)
```

A virtual column has no value on disk to index. Two fixes: declare the column `STORED`, or create an **expression index** on the same expression, which is what the second statement does, with double parentheses around the expression. The plan still reads the whole table: with 315 rows in a few pages, a sequential scan is cheaper than the index, and the planner knows it. [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) shows the plan without running the query; lesson 5 is about when the planner uses an index.

</details>

## Sources

- PostgreSQL 18 documentation: [data types](https://www.postgresql.org/docs/18/datatype.html), [numeric types](https://www.postgresql.org/docs/18/datatype-numeric.html), [character types](https://www.postgresql.org/docs/18/datatype-character.html), [date/time types](https://www.postgresql.org/docs/18/datatype-datetime.html), [boolean](https://www.postgresql.org/docs/18/datatype-boolean.html), [uuid](https://www.postgresql.org/docs/18/datatype-uuid.html) and [UUID functions](https://www.postgresql.org/docs/18/functions-uuid.html), [JSON types](https://www.postgresql.org/docs/18/datatype-json.html), [arrays](https://www.postgresql.org/docs/18/arrays.html), [range types](https://www.postgresql.org/docs/18/rangetypes.html), [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html), [constraints](https://www.postgresql.org/docs/18/ddl-constraints.html), [domains](https://www.postgresql.org/docs/18/domains.html), [generated columns](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)
- [PostgreSQL 18 release notes](https://www.postgresql.org/docs/18/release-18.html): virtual generated columns, `uuidv7()`
- Guitar Alchemist at commit `32f143c`: [`MusicalKnowledgeDbContext.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs), [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml), [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj)
- [Extensions supported by Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html)
- SQL Server: [data types](https://learn.microsoft.com/sql/t-sql/data-types/data-types-transact-sql), [`datetimeoffset`](https://learn.microsoft.com/sql/t-sql/data-types/datetimeoffset-transact-sql), [unique constraints](https://learn.microsoft.com/sql/relational-databases/tables/unique-constraints-and-check-constraints)
