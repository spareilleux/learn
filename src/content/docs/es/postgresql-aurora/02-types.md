---
title: 2. Tipos y modelado
description: El modelo del curso, y los tipos nativos de PostgreSQL vistos desde SQL Server — numeric y float, text y varchar, timestamptz y lo que no guarda, intervalos, uuid versión 7, json y jsonb, arrays y rangos — con restricciones CHECK, dominios, restricciones de exclusión, UNIQUE y NULL, y columnas generadas virtuales; y lo que las restricciones encuentran en las referencias de proyectos de Guitar Alchemist.
sidebar:
  order: 2
---

El modelo del curso es [`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql); todos los scripts, a partir de esta lección, lo cargan primero. El script de la propia lección es [`sql/02-types.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql), los ejercicios están en [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql), y `check.sh` compara su salida con [`expected/02-types.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-types.txt) y [`expected/02-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/02-exercises.txt).

## Desde los tipos de SQL Server

| SQL Server | PostgreSQL | Cuidado |
|---|---|---|
| `int`, `bigint`, `smallint` | `integer`, `bigint`, `smallint` | no hay `tinyint` ni tipos sin signo |
| `bit` | `boolean` | un tipo de verdad, con `true`, `false` y `NULL` |
| `decimal(p,s)`, `money` | `numeric(p,s)` | el `money` de PostgreSQL existe, y depende del parámetro `lc_monetary` |
| `float`, `real` | `double precision` (`float8`), `real` (`float4`) | |
| `nvarchar(n)`, `varchar(n)` | `text`, o `varchar(n)` | toda cadena está en la codificación de la base, aquí UTF-8: sin prefijo `n`, sin literales `N'…'` |
| `nvarchar(max)` | `text` | hasta 1 GB |
| `varbinary(max)` | `bytea` | |
| `datetime2` | `timestamp` | |
| `datetimeoffset` | `timestamptz` | no conserva el desfase |
| `time`, `date` | `time`, `date` | |
| sin equivalente | `interval` | una duración |
| `uniqueidentifier` | `uuid` | se ordena por bytes, no con el extraño orden de bytes de SQL Server |
| JSON en un `nvarchar(max)`, o el tipo `json` de SQL Server 2025 | `jsonb` | |
| parámetro con valores de tabla, cadena delimitada | arrays: `text[]`, `integer[]` | |
| sin equivalente | rangos: `tstzrange`, `int4range`, `daterange` | |
| columna calculada, `PERSISTED` | columna generada, virtual o `STORED` | |
| tipo alias (`CREATE TYPE … FROM`) | dominio (`CREATE DOMAIN`) | un dominio puede llevar un `CHECK` |

El resto de la lección ejecuta las filas donde la diferencia importa. El [capítulo de tipos de datos](https://www.postgresql.org/docs/18/datatype.html) los enumera todos.

## El modelo del curso

[`sql/schema.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql) convierte los archivos JSON y CSV del curso en tablas tipadas, en dos esquemas. Primero, el historial de CI ([líneas 7-50](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L7-L50)):

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

-- btree_gist permite que un índice GiST compare bigint con =, junto al && de los rangos
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
    -- los pasos de un mismo job nunca se ejecutan al mismo tiempo
    EXCLUDE USING gist (job_id WITH =, ran WITH &&)
);
```

La parte de carga ([líneas 52-73](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L52-L73)) lee `runs.json` con `jsonb_to_recordset`, como en la lección 1, y `jobs.json`, un array de 315 jobs con sus pasos anidados, con el operador `->>`, que extrae un campo como texto. La lección 7 trata de JSON; aquí es un medio. Los proyectos y referencias de Guitar Alchemist vienen de archivos CSV, cargados con [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), y sus acordes icónicos de JSON ([líneas 75-134](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L75-L134)). Las secciones siguientes explican cada decisión.

## Números

[Líneas 7-9](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L7-L9):

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

- Un literal con punto decimal, como `0.1`, es un [`numeric`](https://www.postgresql.org/docs/18/datatype-numeric.html#DATATYPE-NUMERIC-DECIMAL), exacto, y `0.1 + 0.2` es exactamente `0.3`. En SQL Server, el literal también sería un `decimal`. `float8` muestra el error de redondeo binario, como `double` en C#.
- La división entera trunca, como en SQL Server, C# y Java. `7 / 2.0` es `numeric`, y PostgreSQL eligió 16 dígitos decimales para el resultado.
- El desbordamiento es un error, no una vuelta: `int` + `int` sigue siendo `int`. SQL Server lanza «Arithmetic overflow error» en el mismo sitio.
- `numeric(5, 2)` significa 5 dígitos en total, 2 de ellos decimales: como mucho 999.99.

Usa `numeric` para el dinero y todo lo que se cuenta en unidades decimales, `bigint` para los identificadores, y `double precision` para las medidas.

## Texto

[Líneas 12-15](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L12-L15):

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

- Una **conversión explícita** a `varchar(7)` trunca sin error, como exige el estándar SQL. **Guardar** un valor más largo es un error. SQL Server se comporta igual: `CAST` trunca, e `INSERT` falla con «String or binary data would be truncated».
- `char(4)` rellena con espacios, y el relleno desaparece en cuanto el valor se convierte en texto: `'ab'::char(4) || '|'` es `ab|`. La [documentación](https://www.postgresql.org/docs/18/datatype-character.html) recomienda `text` o `varchar` antes que `char(n)`.
- `length` cuenta caracteres, `octet_length` bytes: `é` ocupa dos bytes en UTF-8.

`text` y `varchar(n)` se guardan igual y son igual de rápidos; la documentación lo dice en un consejo de la misma página. El límite de `varchar(n)` es una restricción: subirlo más tarde no reescribe la tabla, pero sigue siendo un `ALTER TABLE` para una regla que un `CHECK` expresaría mejor. El modelo del curso usa `text`, y un `CHECK` cuando existe una regla de verdad, como para `head_sha`.

## Marcas de tiempo: lo que guarda timestamptz

`timestamp with time zone`, `timestamptz` para abreviar, es el tipo que hay que usar para instantes. Su nombre engaña: **no guarda una zona horaria**. Guarda un instante, en UTC, convierte la entrada a UTC con el desfase indicado o con el parámetro `TimeZone` de la sesión, y convierte la salida al `TimeZone` de la sesión ([líneas 18-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L18-L24)):

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

- La misma fila, dos presentaciones: `14:01:09+00` en UTC, `10:01:09-04` en Toronto durante el horario de verano. Nada se convirtió en la tabla; solo cambió la salida.
- `AT TIME ZONE` sobre un `timestamptz` da la hora de reloj en esa zona, como `timestamp` sin zona horaria.
- **La trampa**: la misma cadena convertida a `timestamp` conserva `10:01:09` y descarta `+02` sin avisar. La [documentación](https://www.postgresql.org/docs/18/datatype-datetime.html#DATATYPE-TIMEZONES) dice que PostgreSQL «will silently ignore any time zone indication» en un literal de `timestamp without time zone`. Convertida a `timestamptz`, la misma cadena es el instante 08:01:09 UTC, que se muestra como 04:01:09 en Toronto.

La diferencia con el `datetimeoffset` de SQL Server: ese tipo conserva el desfase que recibió, y devuelve `10:01:09 +02:00`. `timestamptz` devuelve el instante en la zona horaria de quien lee. Si el desfase original importa, por ejemplo la hora local de un usuario, guarda el nombre de la zona en una columna al lado.

Todos los scripts del curso se ejecutan con `TimeZone=UTC`: `server.sh` lo fija en `PGOPTIONS`, para que las salidas sean las mismas en cualquier máquina. El valor por defecto de la imagen también es `Etc/UTC`, pero un servidor instalado en un portátil toma la zona del sistema operativo. La lección 4 muestra lo que eligen los drivers: Npgsql y el driver JDBC no coinciden.

## Intervalos y columnas generadas

Un `interval` es una duración. `ci.jobs.duration` es una **columna generada**, calculada a partir de otras dos columnas ([líneas 27-31](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L27-L31)):

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

Un job de Windows de la CI de este sitio tarda de media cuatro veces y media más que un job de Linux. `avg` y `max` funcionan directamente sobre intervalos.

Desde [PostgreSQL 18](https://www.postgresql.org/docs/18/ddl-generated-columns.html), una columna generada es **virtual** por defecto: se calcula al leerla, no se guarda, como una columna calculada de SQL Server sin `PERSISTED`. Hasta PostgreSQL 17 solo existía `STORED`, y los tutoriales antiguos lo escriben en todas partes. El ejercicio 3 encuentra un límite de las columnas virtuales. `ci.steps.ran` es `STORED`, porque la restricción de exclusión de más abajo necesita un índice sobre ella.

## Booleanos

[Línea 34](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L34):

```sql
SELECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::boolean;
```

```text
ERROR:  invalid input syntax for type boolean: "maybe"
LINE 1: ...ECT 'yes'::boolean AS yes, 'off'::boolean AS off, 'maybe'::b...
                                                             ^
```

La sentencia falla entera, así que las dos primeras columnas nunca se muestran. [`boolean`](https://www.postgresql.org/docs/18/datatype-boolean.html) acepta como entrada `true`, `yes`, `on`, `1` y sus contrarios, muestra `t` y `f`, y aparece como `bool` en los drivers, mientras que el `bit` de SQL Server es un número. `WHERE is_active` es una condición completa; sin `= 1`.

## uuid, versión 7

[`uuid`](https://www.postgresql.org/docs/18/datatype-uuid.html) es un tipo de 16 bytes. PostgreSQL 18 añadió [`uuidv7()`](https://www.postgresql.org/docs/18/functions-uuid.html), que genera UUID de versión 7: los primeros 48 bits son una marca de tiempo Unix en milisegundos, así que los valores generados después se ordenan después, y las filas nuevas llegan al final del índice de la clave primaria en lugar de a sitios aleatorios ([líneas 37-49](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L37-L49)):

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

El script no muestra los UUID: cambian en cada ejecución. Muestra lo que no cambia, su versión y el hecho de que su marca de tiempo es del último minuto. Ordenadas por `annotation_id`, las filas salen en orden de inserción: en una misma conexión, PostgreSQL hace que cada valor de versión 7 sea mayor que el anterior, incluso dentro del mismo milisegundo ([`uuid.c`, líneas 563-604](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/utils/adt/uuid.c#L563-L604)). `DISTINCT ON`, que aquí elige el job más lento de cada sistema operativo, es cosa de la lección 3.

`gen_random_uuid()`, o `uuidv4()` desde PostgreSQL 18, los genera aleatorios. El `NEWSEQUENTIALID()` de SQL Server tiene el mismo objetivo que la versión 7 con otra disposición, y SQL Server ordena `uniqueidentifier` empezando por sus últimos bytes; un `Guid` de .NET enviado a PostgreSQL se ordena por sus primeros bytes. .NET 9 añadió `Guid.CreateVersion7()`.

## json y jsonb

[Línea 52](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L52):

```sql
SELECT '{"b": 1, "a": [1, 2], "a": 3}'::json AS json, '{"b": 1, "a": [1, 2], "a": 3}'::jsonb AS jsonb;
```

```text
             json              |      jsonb
-------------------------------+------------------
 {"b": 1, "a": [1, 2], "a": 3} | {"a": 3, "b": 1}
(1 row)
```

[`json`](https://www.postgresql.org/docs/18/datatype-json.html) guarda el texto tal como llega, validado pero no analizado: claves duplicadas, orden de las claves y espacios se conservan, y cada operación lo vuelve a analizar. `jsonb` guarda un valor binario, analizado: gana la última clave duplicada, las claves se reordenan, y se puede indexar. Usa `jsonb`, salvo que debas devolver exactamente el documento recibido. La lección 7 cubre los operadores y los índices.

## Arrays

Una columna puede contener un [array](https://www.postgresql.org/docs/18/arrays.html) de cualquier tipo. `ci.jobs.labels` es `text[]`, porque GitHub da a cada job una lista de etiquetas de runner ([líneas 55-57](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L55-L57)):

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

- Los arrays se muestran entre llaves, con comillas dobles alrededor de los elementos que las necesitan. **Los índices empiezan en 1**: `labels[1]` es la primera etiqueta.
- `= ANY (array)` comprueba la pertenencia. También sustituye a las listas `IN (…)` en las consultas parametrizadas, como muestra la lección 4.
- En esta instantánea, cada job tiene exactamente una etiqueta; el tipo admite más, como GitHub.

Guitar Alchemist también tiene listas. Su modelo de EF Core, [`MusicalKnowledgeDbContext`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs#L32-L45), guarda el `List<int> PitchClasses` de un acorde como una cadena unida por comas, y su `List<string> AlternateNames` unida por `|`, mediante convertidores de valores de EF Core: SQLite, el proveedor que referencia, no tiene arrays. La última consulta de arriba muestra dos cosas que una cadena unida no dice: que los números son números, y que un nombre vacío entre dos separadores es un elemento. El convertidor de GA lee con `StringSplitOptions.RemoveEmptyEntries`, que lo descarta; la lección 4 ejecuta ese convertidor contra PostgreSQL. El modelo del curso guarda en cambio los acordes con arrays ([`schema.sql`, líneas 98-112](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/schema.sql#L98-L112)):

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
    -- un traste por cuerda, del mi grave al mi agudo; -1 para una cuerda que no se toca
    guitar_voicing   smallint[] CHECK (cardinality(guitar_voicing) = 6),
    alternate_names  text[] NOT NULL
);
```

Un array de un dominio comprueba cada elemento: el ejercicio 1 prueba una clase de altura 12. El coste de los arrays: no hay clave foránea sobre un elemento, y una tabla de notas del acorde sigue siendo el diseño correcto cuando los elementos tienen atributos propios o hay que unirlos a menudo. Para una lista corta que pertenece a su fila, un array es más simple que una tabla hija y más seguro que una cadena unida.

## Rangos y restricciones de exclusión

Un [rango](https://www.postgresql.org/docs/18/rangetypes.html) es un único valor con un límite inferior y uno superior, cada uno incluido (`[` `]`) o excluido (`(` `)`). `ci.steps.ran` es el `tstzrange` que va del inicio de un paso a su final ([líneas 60-68](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L60-L68)):

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

Las decisiones del modelo, y por qué:

- **Semiabierto, `[)`.** La API de GitHub da las horas al segundo, y cada paso empieza en el segundo en que termina el anterior. Con los dos límites incluidos, el paso 1 `[02:50:32, 02:50:33]` y el paso 2 `[02:50:33, 02:50:40]` comparten 02:50:33, y 2.798 pares de pasos de un mismo job se «solaparían». Con el final excluido, ninguno.
- **El precio de `[)`.** 857 de los 2.204 pasos, el 39 %, empezaron y terminaron en el mismo segundo, y `[t, t)` es un **rango vacío**: no contiene nada, y sus límites desaparecen (`lower()` de un rango vacío es `NULL`). Por eso la tabla conserva `started_at` y `completed_at`, y deriva `ran` de ellas.
- **La restricción de exclusión.** `EXCLUDE USING gist (job_id WITH =, ran WITH &&)` rechaza dos filas cuyos `job_id` son iguales *y* cuyos rangos se solapan (`&&`): una restricción de unicidad generalizada a cualquier operador. La aplica un índice GiST, y la extensión [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html) enseña a GiST el `=` de `bigint`. El paso insertado, de 02:50:35 a 02:50:36, cae dentro del paso 2, y el error nombra las dos filas. SQL Server no tiene equivalente; la solución habitual es un trigger.

## Dominios y restricciones CHECK

[Líneas 71-72](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L71-L72):

```sql
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'neutral', 'main', repeat('a', 40), 1, '2026-09-15', '2026-09-15', '2026-09-15');
INSERT INTO ci.runs VALUES (1, 'Test', 'push', 'success', 'main', 'not-a-sha', 1, '2026-09-15', '2026-09-15', '2026-09-15');
```

```text
ERROR:  value for domain ci.conclusion violates check constraint "conclusion_check"
ERROR:  new row for relation "runs" violates check constraint "runs_head_sha_check"
DETAIL:  Failing row contains (1, Test, push, success, main, not-a-sha, 1, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00, 2026-09-15 00:00:00+00).
```

Un [dominio](https://www.postgresql.org/docs/18/domains.html) es un tipo con restricciones, definido una vez y usado por varias columnas: `ci.conclusion` en tres tablas. Las alternativas son un [tipo enumerado](https://www.postgresql.org/docs/18/datatype-enum.html), al que se pueden añadir valores pero no quitarlos sin recrearlo, y una tabla de consulta con clave foránea, la opción correcta cuando los valores tienen atributos o cambian a menudo. `neutral` es una conclusión real de GitHub que esta instantánea no contiene; cuando aparezca, `ALTER DOMAIN` sustituirá la restricción.

Un `CHECK` sobre una columna puede usar cualquier expresión de la fila, aquí una [expresión regular](https://www.postgresql.org/docs/18/functions-matching.html#FUNCTIONS-POSIX-REGEXP) con `~`. El `CHECK` de SQL Server no tiene expresiones regulares antes del `REGEXP_LIKE` de SQL Server 2025. El `DETAIL` muestra la fila que falla; la lección 4 muestra que Npgsql lo oculta por defecto.

## UNIQUE y NULL

[Líneas 75-79](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L75-L79):

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

Aquí ocurre lo contrario que en SQL Server. Una restricción `UNIQUE` de SQL Server admite **un** `NULL`, y la solución habitual para «único cuando tiene valor» es un índice único filtrado, `WHERE email IS NOT NULL`. PostgreSQL sigue el estándar SQL: `NULL` no es igual a `NULL`, así que una columna `UNIQUE` acepta **cualquier número** de `NULL`. [`NULLS NOT DISTINCT`](https://www.postgresql.org/docs/18/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS), desde PostgreSQL 15, da el comportamiento de SQL Server. Un esquema migrado conserva sus restricciones y cambia su significado en silencio.

## Lo que las restricciones encuentran en Guitar Alchemist

`schema.sql` carga las referencias de proyectos de Guitar Alchemist a través de un `DISTINCT` y una unión, y su comentario explica por qué. Sin ellos ([líneas 82-87](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-types.sql#L82-L87)):

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

1. `HEADER match`, desde PostgreSQL 15, compara la cabecera del CSV con las columnas de la tabla, y el archivo dice `from,to`. `HEADER true` solo se salta la primera línea.
2. La clave primaria encuentra una referencia listada dos veces: [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj#L26-L31) referencia `GA.Business.Config.fsproj` en la línea 26 y otra vez en la línea 31, todavía en el commit `32f143c`. MSBuild acepta el duplicado; un modelo relacional, no. `COPY` se detiene en el primer error, y no se conserva ninguna fila del archivo: un `COPY` es una sentencia, y una sentencia es atómica.
3. Sin la clave primaria, la clave foránea encuentra una referencia a `reactapp1.client.esproj`, un proyecto JavaScript de la plantilla React de Visual Studio, que la extracción no contó como proyecto .NET. Ese es un límite de los datos, no un fallo.

[`LIKE … INCLUDING ALL`](https://www.postgresql.org/docs/18/sql-createtable.html) copia columnas, valores por defecto, restricciones e índices, pero no las claves foráneas, que el `ALTER TABLE` vuelve a añadir.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Aurora PostgreSQL ejecuta el propio motor de PostgreSQL, así que los tipos, dominios, restricciones y columnas generadas de esta lección son los de PostgreSQL 18. Dos diferencias que comprobar antes de fiarse de la lección:

- **La versión menor.** El 2026-09-15, la versión más reciente de Aurora es la 18.4.1, compatible con PostgreSQL 18.4; el curso usa la 18.6. Las correcciones entre 18.4 y 18.6 todavía no están en Aurora.
- **Las versiones de las extensiones.** La [tabla de extensiones de Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) indica `btree_gist` 1.6 para Aurora PostgreSQL 18.4, mientras que PostgreSQL 18.6 en la imagen ofrece la 1.8 (`SELECT default_version FROM pg_available_extensions WHERE name = 'btree_gist'`). La restricción de exclusión de `ci.steps` solo necesita el soporte de `bigint` que ya tenían las versiones anteriores, pero una función más reciente de la extensión podría faltar. Solo se pueden instalar las extensiones de esa lista.

## Puntos clave

- `numeric` es exacto, `float8` no; la división entera trunca y el desbordamiento es un error.
- Prefiere `text` con un `CHECK` a `varchar(n)`, y nunca uses `char(n)`.
- `timestamptz` guarda un instante, no una zona horaria; una cadena convertida a `timestamp` pierde su desfase en silencio.
- Las columnas generadas son virtuales por defecto desde PostgreSQL 18; los índices y las restricciones de exclusión necesitan `STORED`.
- `uuidv7()` da UUID ordenados; `jsonb` antes que `json`.
- Arrays y rangos son tipos de columna: `= ANY`, `&&` y las restricciones de exclusión sustituyen tablas hijas, cadenas unidas y triggers cuando encajan.
- `UNIQUE` admite muchos `NULL` salvo con `NULLS NOT DISTINCT`: lo contrario que SQL Server.
- Las restricciones también son una herramienta de calidad de datos: encontraron un `ProjectReference` duplicado en Guitar Alchemist.

## Ejercicios

Las soluciones están en [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql).

1. Lista los acordes icónicos que contienen a la vez mi (clase de altura 4) y si (clase de altura 11), con su número de notas y su primer nombre alternativo. Después intenta añadir la clase de altura 12 al Power Chord.

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 7-11](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L7-L11):

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

`@>` significa «contiene»: cada elemento del array de la derecha está en el de la izquierda, en cualquier orden. `cardinality` cuenta los elementos; `array_length(a, 1)` también, pero devuelve `NULL` para un array vacío. `||` añade un elemento, y el dominio lo comprueba: la restricción de `ga.pitch_class` se aplica a cada elemento del array. La lección 7 indexa `@>` con GIN.

</details>

2. Cuenta las ejecuciones por día natural, una vez según la fecha UTC y otra según la fecha de un reloj de pared en Toronto. ¿Por qué hay tres filas para dos días?

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 14-19](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L14-L19):

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

23 ejecuciones empezaron el 14 de septiembre en UTC, entre medianoche y las 04:00, cuando en Toronto todavía era 13 de septiembre. `started_at::date` convierte en la zona horaria de la sesión, UTC en los scripts del curso; la misma consulta en una sesión con `America/Toronto` daría las fechas de Toronto en la primera columna. Un informe «por día» debe decir de qué día se trata, y `AT TIME ZONE` lo hace explícito en lugar de depender de la conexión.

</details>

3. Crea un índice sobre `ci.jobs.duration` para encontrar los jobs largos. ¿Qué pasa? ¿Cómo se consigue un índice que pueda usar la consulta `WHERE completed_at - started_at > interval '4 minutes'`?

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 22-24](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/02-exercises.sql#L22-L24):

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

Una columna virtual no tiene un valor en disco que indexar. Dos soluciones: declarar la columna `STORED`, o crear un **índice sobre expresión** con la misma expresión, que es lo que hace la segunda sentencia, con doble paréntesis alrededor de la expresión. El plan sigue leyendo toda la tabla: con 315 filas en unas pocas páginas, un recorrido secuencial es más barato que el índice, y el planificador lo sabe. [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) muestra el plan sin ejecutar la consulta; la lección 5 trata de cuándo usa el planificador un índice.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [tipos de datos](https://www.postgresql.org/docs/18/datatype.html), [tipos numéricos](https://www.postgresql.org/docs/18/datatype-numeric.html), [tipos de caracteres](https://www.postgresql.org/docs/18/datatype-character.html), [tipos de fecha y hora](https://www.postgresql.org/docs/18/datatype-datetime.html), [boolean](https://www.postgresql.org/docs/18/datatype-boolean.html), [uuid](https://www.postgresql.org/docs/18/datatype-uuid.html) y [funciones UUID](https://www.postgresql.org/docs/18/functions-uuid.html), [tipos JSON](https://www.postgresql.org/docs/18/datatype-json.html), [arrays](https://www.postgresql.org/docs/18/arrays.html), [tipos de rango](https://www.postgresql.org/docs/18/rangetypes.html), [`btree_gist`](https://www.postgresql.org/docs/18/btree-gist.html), [restricciones](https://www.postgresql.org/docs/18/ddl-constraints.html), [dominios](https://www.postgresql.org/docs/18/domains.html), [columnas generadas](https://www.postgresql.org/docs/18/ddl-generated-columns.html), [`COPY`](https://www.postgresql.org/docs/18/sql-copy.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html)
- [Notas de la versión de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html): columnas generadas virtuales, `uuidv7()`
- Guitar Alchemist en el commit `32f143c`: [`MusicalKnowledgeDbContext.cs`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Infrastructure/Persistence/EntityFramework/MusicalKnowledgeDbContext.cs), [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml), [`GA.Knowledge.Service.csproj`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Apps/ga-server/GA.Knowledge.Service/GA.Knowledge.Service.csproj)
- [Extensiones compatibles con Aurora PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html)
- SQL Server: [tipos de datos](https://learn.microsoft.com/sql/t-sql/data-types/data-types-transact-sql), [`datetimeoffset`](https://learn.microsoft.com/sql/t-sql/data-types/datetimeoffset-transact-sql), [restricciones de unicidad](https://learn.microsoft.com/sql/relational-databases/tables/unique-constraints-and-check-constraints)
