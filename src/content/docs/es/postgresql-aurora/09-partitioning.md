---
title: "9. Particionado y tablas grandes"
description: Particionado declarativo en PostgreSQL 18 para desarrolladores SQL Server — particiones por rango, por lista y por hash del historial de 440 800 pasos, claves primarias que incluyen la clave de partición, poda en la planificación y en la ejecución, índices particionados, retención con DETACH y DROP en lugar de DELETE, particiones por defecto, ATTACH con una restricción CHECK equivalente, y pg_partman en Aurora.
sidebar:
  order: 9
---

El script de la lección es [`sql/09-partitioning.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql), y los ejercicios están en [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql). `check.sh` compara su salida con [`expected/09-partitioning.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-partitioning.txt) y [`expected/09-exercises.txt`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/expected/09-exercises.txt). Ambos cargan `ci.step_history`, la tabla de la lección 5 con 440 800 pasos a lo largo de 200 días.

| SQL Server | PostgreSQL |
|---|---|
| función de partición y esquema de partición | `PARTITION BY RANGE`, `LIST` o `HASH` sobre la tabla, una tabla por partición |
| valores límite `RANGE LEFT` o `RANGE RIGHT` | `FOR VALUES FROM (…) TO (…)`: el límite inferior incluido, el superior excluido |
| grupos de archivos | tablespaces, rara vez necesarios; cada partición es su propio conjunto de archivos |
| índices alineados | un índice sobre la tabla particionada, creado en cada partición |
| `ALTER TABLE … SWITCH PARTITION` | `ALTER TABLE … ATTACH PARTITION` y `DETACH PARTITION` |
| `$PARTITION.function(value)` | `tableoid::regclass`, la partición de la que se leyó una fila |
| hasta 15 000 particiones | sin límite fijo; el tiempo de planificación y la memoria crecen con las particiones que conserva una consulta |

## Una tabla particionada

SQL Server particiona una tabla mediante dos objetos separados, una [función de partición](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql) y un esquema. El [particionado declarativo](https://www.postgresql.org/docs/18/ddl-partitioning.html) de PostgreSQL pone el método y la clave en la tabla, y cada partición es una tabla en sí misma, con sus límites. El primer intento, con la misma clave primaria que `ci.step_history` ([líneas 8-18](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L8-L18)):

```sql
-- Una tabla particionada no tiene filas propias: cada fila va a la partición cuyos límites contienen su clave
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id)
) PARTITION BY RANGE (started_at);
```

```text
ERROR:  unique constraint on partitioned table must include all partitioning columns
DETAIL:  PRIMARY KEY constraint on table "step_log" lacks column "started_at" which is part of the partition key.
```

No existe ningún índice que abarque todas las particiones: cada partición tiene el suyo, que solo puede comprobar la unicidad entre sus propias filas. La regla de la documentación es que «the constraint's columns must include all of the partition key columns». Dos filas con el mismo `id` en dos meses distintos se aceptarían ambas, así que PostgreSQL rechaza la clave. Con `started_at` dentro, la clave se comprueba partición a partición y sigue siendo válida para toda la tabla ([líneas 20-46](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L20-L46)):

```sql
-- Una clave primaria debe incluir la clave de partición: cada partición comprueba la unicidad en sus propias filas
CREATE TABLE ci.step_log (
    id            bigint NOT NULL,
    workflow_name text NOT NULL,
    job_name      text NOT NULL,
    step_name     text NOT NULL,
    conclusion    ci.conclusion,
    started_at    timestamptz NOT NULL,
    duration      interval NOT NULL,
    PRIMARY KEY (id, started_at)
) PARTITION BY RANGE (started_at);

-- Una partición por mes, de febrero a septiembre de 2026, escritas por una consulta y ejecutadas por \gexec
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

INSERT INTO ci.step_log
SELECT id, workflow_name, job_name, step_name, conclusion, started_at, duration FROM ci.step_history;
VACUUM ANALYZE ci.step_log;

SELECT tableoid::regclass AS partition, count(*) AS rows, min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_log
GROUP BY tableoid
ORDER BY first_day;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 440800
VACUUM
      partition      | rows  | first_day  |  last_day
---------------------+-------+------------+------------
 ci.step_log_2026_02 |  5079 | 2026-02-26 | 2026-02-28
 ci.step_log_2026_03 | 68324 | 2026-03-01 | 2026-03-31
 ci.step_log_2026_04 | 66120 | 2026-04-01 | 2026-04-30
 ci.step_log_2026_05 | 68324 | 2026-05-01 | 2026-05-31
 ci.step_log_2026_06 | 66120 | 2026-06-01 | 2026-06-30
 ci.step_log_2026_07 | 68324 | 2026-07-01 | 2026-07-31
 ci.step_log_2026_08 | 68324 | 2026-08-01 | 2026-08-31
 ci.step_log_2026_09 | 30185 | 2026-09-01 | 2026-09-14
(8 rows)
```

- La consulta escribe ocho instrucciones [`CREATE TABLE … PARTITION OF`](https://www.postgresql.org/docs/18/sql-createtable.html), una por mes, y el [`\gexec`](https://www.postgresql.org/docs/18/app-psql.html#APP-PSQL-META-COMMAND-GEXEC) de `psql` ejecuta cada fila del resultado como una instrucción: las nueve líneas `CREATE TABLE` son la tabla y sus ocho particiones.
- `FROM` incluye su límite y `TO` lo excluye, así que `2026-03-01 00:00` pertenece solo a marzo.
- `tableoid::regclass` da el nombre de la partición en la que está guardada cada fila.
- Febrero solo tiene tres días, ya que el historial empieza el 26 de febrero.

Una fila que cae fuera de todas las particiones se rechaza ([líneas 48-49](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L48-L49)):

```sql
-- Una fila fuera de los límites de todas las particiones no tiene adónde ir
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
```

```text
ERROR:  no partition of relation "step_log" found for row
DETAIL:  Partition key of the failing row contains (started_at) = (2026-10-01 12:00:00+00).
```

## Poda de particiones

Con una condición sobre la clave de partición, el planificador deja fuera las particiones cuyos límites no pueden coincidir. `pg_temp.plan` es el `EXPLAIN (ANALYZE, BUFFERS)` de la lección 5 sin costes ni tiempos ([líneas 51-58](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L51-L58)):

```sql
-- Poda de particiones: una condición sobre la clave de partición deja fuera las particiones que no pueden coincidir
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE started_at >= '2026-09-14'
$$);
-- Sin condición sobre la clave, se leen todas las particiones
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_log WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=121
   ->  Index Only Scan using step_log_2026_09_pkey on step_log_2026_09 step_log (actual rows=1533.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=121
(7 rows)

                                    QUERY PLAN
-----------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=7453
   ->  Append (actual rows=9200.00 loops=1)
         Buffers: shared hit+read=7453
         ->  Seq Scan on step_log_2026_02 step_log_1 (actual rows=114.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 4965
               Buffers: shared hit+read=86
         ->  Seq Scan on step_log_2026_03 step_log_2 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_04 step_log_3 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_05 step_log_4 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_06 step_log_5 (actual rows=1380.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 64740
               Buffers: shared hit+read=1118
         ->  Seq Scan on step_log_2026_07 step_log_6 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_08 step_log_7 (actual rows=1426.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 66898
               Buffers: shared hit+read=1155
         ->  Seq Scan on step_log_2026_09 step_log_8 (actual rows=622.00 loops=1)
               Filter: (step_name = 'Compile-fail doctests'::text)
               Rows Removed by Filter: 29563
               Buffers: shared hit+read=511
(36 rows)
```

- La primera consulta lee una partición, la de septiembre, a través del índice de su clave primaria, cuya segunda columna es `started_at`: 121 páginas.
- La segunda no tiene condición sobre `started_at`: un nodo `Append` lee las ocho particiones, 7453 páginas. El particionado no acelera una consulta que no filtra por la clave; un índice sobre `step_name` sí lo haría.

Con un parámetro, el valor se desconoce cuando se construye el plan. Un plan genérico conserva todas las particiones, y el ejecutor elimina las que el valor excluye cuando se ejecuta la consulta ([líneas 60-65](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L60-L65)):

```sql
-- Un parámetro solo se conoce en la ejecución: el plan genérico poda entonces, e indica cuántas particiones se saltó
PREPARE failures_since (timestamptz) AS
    SELECT count(*) FROM ci.step_log WHERE started_at >= $1 AND conclusion = 'failure';
SET plan_cache_mode = force_generic_plan;
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF, BUFFERS OFF) EXECUTE failures_since('2026-09-01');
RESET plan_cache_mode;
```

```text
PREPARE
SET
                                      QUERY PLAN
---------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   ->  Append (actual rows=301.00 loops=1)
         Subplans Removed: 7
         ->  Seq Scan on step_log_2026_09 step_log_1 (actual rows=301.00 loops=1)
               Filter: ((started_at >= $1) AND ((conclusion)::text = 'failure'::text))
               Rows Removed by Filter: 29884
(6 rows)

RESET
```

`Subplans Removed: 7` es esa poda en la ejecución. [`plan_cache_mode`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-PLAN-CACHE-MODE) fuerza el plan genérico, al que una [sentencia preparada](https://www.postgresql.org/docs/18/sql-prepare.html) puede pasar tras sus cinco primeras ejecuciones, tanto si se preparó en SQL como si lo hicieron Npgsql y pgjdbc ([lección 4](../04-csharp-java/)). [`enable_partition_pruning`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-ENABLE-PARTITION-PRUNING), activado por defecto, controla ambos tipos de poda.

## Índices y filas que cambian de partición

Un índice creado sobre la tabla particionada es un *índice particionado*: PostgreSQL crea un índice en cada partición y lo vincula al padre ([líneas 67-72](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L67-L72)):

```sql
-- Un índice creado sobre la tabla particionada se crea en cada partición, y en las particiones añadidas después
CREATE INDEX step_log_step_name ON ci.step_log (step_name);
SELECT c.relname AS index, i.inhparent::regclass AS parent
FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
WHERE i.inhparent = 'ci.step_log_step_name'::regclass
ORDER BY c.relname;
```

```text
CREATE INDEX
             index              |        parent
--------------------------------+-----------------------
 step_log_2026_02_step_name_idx | ci.step_log_step_name
 step_log_2026_03_step_name_idx | ci.step_log_step_name
 step_log_2026_04_step_name_idx | ci.step_log_step_name
 step_log_2026_05_step_name_idx | ci.step_log_step_name
 step_log_2026_06_step_name_idx | ci.step_log_step_name
 step_log_2026_07_step_name_idx | ci.step_log_step_name
 step_log_2026_08_step_name_idx | ci.step_log_step_name
 step_log_2026_09_step_name_idx | ci.step_log_step_name
(8 rows)
```

Una partición creada más tarde recibe su propia copia del índice. Crearlo sobre una tabla grande bloquea la tabla; la documentación describe cómo construir primero el índice de cada partición con `CONCURRENTLY`, y después crear el índice del padre `ON ONLY` sobre el padre y vincularlos.

Un `UPDATE` que cambia la clave de partición mueve la fila: PostgreSQL la borra de una partición y la inserta en la otra ([líneas 74-77](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L74-L77)):

```sql
-- Un UPDATE de la clave de partición mueve la fila a otra partición
UPDATE ci.step_log SET started_at = started_at - interval '1 month'
WHERE id = (SELECT min(id) FROM ci.step_log WHERE started_at >= '2026-09-01')
RETURNING tableoid::regclass AS now_in, started_at;
```

```text
       now_in        |       started_at
---------------------+------------------------
 ci.step_log_2026_08 | 2026-08-01 01:37:05+00
(1 row)

UPDATE 1
```

## Retención: desvincular y luego eliminar

La razón habitual de las particiones mensuales es quitar un mes de una vez. Un `DELETE` de febrero deja tantas versiones de fila muertas que limpiar como filas ha borrado, como en la [lección 6](../06-transactions/). Quitar la partición toma un bloqueo y borra archivos ([líneas 79-87](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L79-L87)):

```sql
-- Retención: quitar un mes con DELETE deja filas muertas para vacuum; eliminar su partición borra un archivo
CREATE EXTENSION pgstattuple;
BEGIN;
DELETE FROM ci.step_log WHERE started_at < '2026-03-01';
SELECT pg_size_pretty(table_len) AS size, dead_tuple_count FROM pgstattuple('ci.step_log_2026_02');
ROLLBACK;
ALTER TABLE ci.step_log DETACH PARTITION ci.step_log_2026_02;
SELECT count(*) AS rows_left FROM ci.step_log;
DROP TABLE ci.step_log_2026_02;
```

```text
CREATE EXTENSION
BEGIN
DELETE 5079
  size  | dead_tuple_count
--------+------------------
 688 kB |             5079
(1 row)

ROLLBACK
ALTER TABLE
 rows_left
-----------
    435721
(1 row)

DROP TABLE
```

- [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html) cuenta 5079 tuplas muertas en el archivo de 688 kB de febrero, revertido aquí.
- [`DETACH PARTITION`](https://www.postgresql.org/docs/18/sql-altertable.html) convierte la partición en una tabla normal, que se puede archivar con `pg_dump` ([lección 11](../11-backup/)) antes del `DROP TABLE`.
- `DETACH PARTITION … CONCURRENTLY` toma un bloqueo más débil sobre el padre, pero «cannot be run in a transaction block and is not allowed if the partitioned table contains a default partition».

## Particiones por defecto, y vincular una tabla ya cargada

Una [partición por defecto](https://www.postgresql.org/docs/18/sql-createtable.html) recibe las filas que ninguna otra partición acepta: la fila de octubre rechazada más arriba entra. Después impide crear la partición a la que pertenece esa fila ([líneas 89-93](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L89-L93)):

```sql
-- Una partición por defecto recibe las filas que ninguna otra partición acepta
CREATE TABLE ci.step_log_default PARTITION OF ci.step_log DEFAULT;
INSERT INTO ci.step_log VALUES (0, 'Deploy to GitHub Pages', 'deploy', 'Checkout', 'success', '2026-10-01 12:00+00', '2 seconds');
-- ... y después bloquea una partición nueva a la que pertenecen sus filas
CREATE TABLE ci.step_log_2026_10 PARTITION OF ci.step_log FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
```

```text
CREATE TABLE
INSERT 0 1
ERROR:  updated partition constraint for default partition "step_log_default" would be violated by some row
```

Añadir una partición también recorre la partición por defecto, para comprobar que ninguna de sus filas pertenece a la nueva. Una partición por defecto es una red de seguridad, que debería quedarse vacía.

La costumbre de SQL Server de cargar una tabla de preparación y luego hacerle `SWITCH` se convierte en `ATTACH PARTITION` ([líneas 95-107](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L95-L107)):

```sql
-- Cargar un mes aparte y luego vincularlo: una restricción CHECK con los mismos límites ahorra el recorrido que los valida
DELETE FROM ci.step_log_default;
CREATE TABLE ci.step_log_2026_10 (LIKE ci.step_log INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
INSERT INTO ci.step_log_2026_10
SELECT id + 1000000, workflow_name, job_name, step_name, conclusion, started_at + interval '1 month', duration
FROM ci.step_log_2026_09;
ALTER TABLE ci.step_log_2026_10 ADD CONSTRAINT in_october
    CHECK (started_at >= '2026-10-01' AND started_at < '2026-11-01');
ALTER TABLE ci.step_log ATTACH PARTITION ci.step_log_2026_10 FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
SELECT relname AS partition, pg_get_expr(relpartbound, oid) AS bounds
FROM pg_class
WHERE oid IN (SELECT inhrelid FROM pg_inherits WHERE inhparent = 'ci.step_log'::regclass)
ORDER BY relname;
```

```text
DELETE 1
CREATE TABLE
INSERT 0 30184
ALTER TABLE
ALTER TABLE
    partition     |                                  bounds
------------------+--------------------------------------------------------------------------
 step_log_2026_03 | FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00')
 step_log_2026_04 | FOR VALUES FROM ('2026-04-01 00:00:00+00') TO ('2026-05-01 00:00:00+00')
 step_log_2026_05 | FOR VALUES FROM ('2026-05-01 00:00:00+00') TO ('2026-06-01 00:00:00+00')
 step_log_2026_06 | FOR VALUES FROM ('2026-06-01 00:00:00+00') TO ('2026-07-01 00:00:00+00')
 step_log_2026_07 | FOR VALUES FROM ('2026-07-01 00:00:00+00') TO ('2026-08-01 00:00:00+00')
 step_log_2026_08 | FOR VALUES FROM ('2026-08-01 00:00:00+00') TO ('2026-09-01 00:00:00+00')
 step_log_2026_09 | FOR VALUES FROM ('2026-09-01 00:00:00+00') TO ('2026-10-01 00:00:00+00')
 step_log_2026_10 | FOR VALUES FROM ('2026-10-01 00:00:00+00') TO ('2026-11-01 00:00:00+00')
 step_log_default | DEFAULT
(9 rows)
```

- Octubre se carga en una tabla fuera de la tabla particionada, una copia de septiembre un mes más tarde, donde se puede comprobar antes de que nadie la vea.
- `ATTACH PARTITION` recorre la tabla para comprobar sus límites, con un bloqueo `ACCESS EXCLUSIVE` sobre ella. La documentación recomienda «creating a `CHECK` constraint matching the expected partition constraint on the table prior to attaching it»: PostgreSQL confía entonces en la restricción y se salta el recorrido. La restricción se puede eliminar después.
- Sobre el padre, `ATTACH PARTITION` toma un bloqueo `SHARE UPDATE EXCLUSIVE`, más débil que el bloqueo `ACCESS EXCLUSIVE` de `CREATE TABLE … PARTITION OF`.
- [`pg_get_expr(relpartbound, oid)`](https://www.postgresql.org/docs/18/functions-info.html) imprime los límites de cada partición, en UTC en esta sesión.

## Lista y hash

[`PARTITION BY LIST`](https://www.postgresql.org/docs/18/ddl-partitioning.html) enumera los valores de cada partición; `PARTITION BY HASH` reparte las filas entre un número fijo de particiones según el hash de la clave ([líneas 109-125](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-partitioning.sql#L109-L125)):

```sql
-- Particionado por lista y por hash
CREATE TABLE ci.step_outcomes (LIKE ci.step_log) PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_outcomes_success PARTITION OF ci.step_outcomes FOR VALUES IN ('success');
CREATE TABLE ci.step_outcomes_other PARTITION OF ci.step_outcomes DEFAULT;
CREATE TABLE ci.step_buckets (LIKE ci.step_log) PARTITION BY HASH (job_name);
SELECT format('CREATE TABLE ci.step_buckets_%s PARTITION OF ci.step_buckets FOR VALUES WITH (MODULUS 4, REMAINDER %s)', r, r)
FROM generate_series(0, 3) AS r
ORDER BY r
\gexec
INSERT INTO ci.step_outcomes SELECT * FROM ci.step_log;
INSERT INTO ci.step_buckets SELECT * FROM ci.step_log;
SELECT tableoid::regclass AS partition, count(*) AS rows, count(DISTINCT job_name) AS jobs
FROM ci.step_outcomes GROUP BY tableoid
UNION ALL
SELECT tableoid::regclass, count(*), count(DISTINCT job_name)
FROM ci.step_buckets GROUP BY tableoid
ORDER BY 1;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 465905
INSERT 0 465905
        partition         |  rows  | jobs
--------------------------+--------+------
 ci.step_outcomes_success | 441875 |   64
 ci.step_outcomes_other   |  24030 |   17
 ci.step_buckets_0        |  83288 |   18
 ci.step_buckets_1        | 113779 |   15
 ci.step_buckets_2        | 175176 |   13
 ci.step_buckets_3        |  93662 |   18
(6 rows)
```

- La partición `success` contiene el 95 % de las filas: el particionado por lista sigue a los datos, estén equilibrados o no.
- El particionado por hash de 64 nombres de job distintos deja una partición con el doble de filas que otra. Un hash reparte *claves*, no filas: unos pocos jobs con mucha actividad pesan más que muchos jobs poco frecuentes. Las particiones hash no ayudan a la poda con rangos ni a la retención; dividen una tabla que no tiene un rango natural, para el mantenimiento o el trabajo en paralelo.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* El particionado declarativo es el de PostgreSQL, y Aurora no lo cambia. Lo que cambia son las herramientas a su alrededor.

- **pg_partman y pg_cron.** Las particiones del mes que viene tienen que existir antes de que empiece. [pg_partman](https://github.com/pgpartman/pg_partman) las crea por adelantado y elimina las antiguas, y [pg_cron](https://github.com/citusdata/pg_cron) ejecuta su mantenimiento según una programación. La [tabla de extensiones de Aurora PostgreSQL 18](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html) da pg_partman 5.4.3 en 18.4 (5.2.4 en 18.3) y pg_cron 1.6.7; la [página de pg_partman](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html) de AWS dice que «is supported on Aurora PostgreSQL versions 12.6 and higher».
- **Límites.** No encontré ninguna cuota de particiones ni de número de tablas en las [cuotas y límites de Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html). La misma página da un tamaño máximo de tabla de 32 TiB para Aurora PostgreSQL, y recomienda «table design best practices, such as partitioning of large tables»: cada partición es una tabla, así que el límite se aplica por partición.
- **Blue/Green Deployments.** Replican con replicación lógica ([lección 11](../11-backup/#en-aurora)), y las [consideraciones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html) de AWS indican que «creating new partitions on partitioned tables isn't supported during blue/green deployments for Aurora», y que «the pg_partman extension must be disabled in the blue environment».
- **Zero-ETL hacia Redshift.** Para las [integraciones zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), «the table partitions will be replicated to Amazon Redshift. However, the partitioned table itself isn't replicated».

## Puntos clave

- Una tabla particionada es un padre sin filas y una tabla por partición; `FROM` es inclusivo, `TO` exclusivo.
- Las claves primarias y las restricciones únicas deben incluir la clave de partición.
- La poda necesita una condición sobre la clave; con parámetros, ocurre en la ejecución (`Subplans Removed`).
- Los índices creados sobre el padre se crean en cada partición, presente y futura.
- La retención es `DETACH` y `DROP`, no `DELETE`: sin filas muertas, sin vacuum.
- Una partición por defecto recoge las filas perdidas, y obliga a recorrerla al añadir particiones.
- Cargar aparte, añadir una restricción `CHECK` equivalente, y luego `ATTACH`: el patrón `SWITCH` de SQL Server.
- Las particiones hash reparten claves, no filas.

## Ejercicios

Las soluciones están en [`sql/09-exercises.sql`](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql).

1. Particiona una copia de `ci.runs` por workflow: una partición para `Deploy to GitHub Pages`, otra para los tres workflows de ejemplos de los cursos, y una partición por defecto. ¿Cuántas ejecuciones contiene cada una, y qué particiones lee una consulta de `Rust course examples`?

<details>
<summary>Solución</summary>

[Líneas 8-19](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L8-L19):

```sql
-- Ejercicio 1: ejecuciones particionadas por workflow, con su propia partición para los despliegues y una por defecto para el resto,
-- y un plan que solo lee la partición de 'Rust course examples'
CREATE TABLE ci.runs_by_workflow (LIKE ci.runs) PARTITION BY LIST (workflow_name);
CREATE TABLE ci.runs_deploy PARTITION OF ci.runs_by_workflow FOR VALUES IN ('Deploy to GitHub Pages');
CREATE TABLE ci.runs_examples PARTITION OF ci.runs_by_workflow
    FOR VALUES IN ('Rust course examples', 'Java course examples', 'WSL containers examples');
CREATE TABLE ci.runs_other PARTITION OF ci.runs_by_workflow DEFAULT;
INSERT INTO ci.runs_by_workflow SELECT * FROM ci.runs;
SELECT tableoid::regclass AS partition, count(*) AS runs FROM ci.runs_by_workflow GROUP BY tableoid ORDER BY tableoid::regclass::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.runs_by_workflow WHERE workflow_name = 'Rust course examples'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 125
    partition     | runs
------------------+------
 ci.runs_deploy   |   65
 ci.runs_examples |   27
 ci.runs_other    |   33
(3 rows)

                                  QUERY PLAN
------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=1
   ->  Seq Scan on runs_examples runs_by_workflow (actual rows=18.00 loops=1)
         Filter: (workflow_name = 'Rust course examples'::text)
         Rows Removed by Filter: 9
         Buffers: shared hit+read=1
(6 rows)
```

`LIKE ci.runs` copia las columnas y sus restricciones `NOT NULL`, no la clave primaria. La poda conserva `runs_examples`, la partición cuya lista contiene el valor; la partición por defecto también queda fuera, ya que el valor está en la lista de otra partición.

</details>

2. Particiona los pasos de septiembre en dos niveles: por mes y, dentro del mes, por conclusión. Muestra el árbol con [`pg_partition_tree`](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), y el plan de una consulta de los fallos desde el 14 de septiembre.

<details>
<summary>Solución</summary>

[Líneas 21-31](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L21-L31):

```sql
-- Ejercicio 2: dos niveles, meses y luego conclusión, y el árbol que devuelve pg_partition_tree
CREATE TABLE ci.step_months (LIKE ci.step_history) PARTITION BY RANGE (started_at);
CREATE TABLE ci.step_months_2026_09 PARTITION OF ci.step_months
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01') PARTITION BY LIST (conclusion);
CREATE TABLE ci.step_months_2026_09_success PARTITION OF ci.step_months_2026_09 FOR VALUES IN ('success');
CREATE TABLE ci.step_months_2026_09_other PARTITION OF ci.step_months_2026_09 DEFAULT;
INSERT INTO ci.step_months SELECT * FROM ci.step_history WHERE started_at >= '2026-09-01';
SELECT relid, parentrelid, isleaf, level FROM pg_partition_tree('ci.step_months') ORDER BY level, relid::text;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_months WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 30185
             relid              |      parentrelid       | isleaf | level
--------------------------------+------------------------+--------+-------
 ci.step_months                 |                        | f      |     0
 ci.step_months_2026_09         | ci.step_months         | f      |     1
 ci.step_months_2026_09_other   | ci.step_months_2026_09 | t      |     2
 ci.step_months_2026_09_success | ci.step_months_2026_09 | t      |     2
(4 rows)

                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=36
   ->  Seq Scan on step_months_2026_09_other step_months (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 1512
         Buffers: shared hit+read=36
(6 rows)
```

Una partición declarada con su propio `PARTITION BY` está a su vez particionada: el nivel 1 tampoco tiene filas. Ambas condiciones podan, una por nivel, y la consulta solo lee la partición `other` de septiembre.

</details>

3. Escribe un procedimiento que desvincule y elimine las particiones mensuales de una tabla que terminan en una fecha dada o antes, y úsalo para conservar de junio a septiembre.

<details>
<summary>Solución</summary>

[Líneas 33-63](https://github.com/spareilleux/learn/blob/eb0303d795a88c25a467391c1f127befe75c98f8/code/postgresql-aurora/sql/09-exercises.sql#L33-L63):

```sql
-- Ejercicio 3: un procedimiento que desvincula y elimina las particiones mensuales que terminan antes de una fecha
CREATE TABLE ci.step_log (LIKE ci.step_history) PARTITION BY RANGE (started_at);
SELECT format('CREATE TABLE ci.step_log_%s PARTITION OF ci.step_log FOR VALUES FROM (%L) TO (%L)',
              to_char(m, 'YYYY_MM'), m, m + interval '1 month')
FROM generate_series(timestamptz '2026-02-01', '2026-09-01', interval '1 month') AS m
ORDER BY m
\gexec

CREATE PROCEDURE ci.drop_partitions_before(parent regclass, cutoff timestamptz)
LANGUAGE plpgsql AS $$
DECLARE
    part regclass;
BEGIN
    FOR part IN
        SELECT c.oid::regclass
        FROM pg_inherits AS i JOIN pg_class AS c ON c.oid = i.inhrelid
        -- el límite superior, leído de la definición de la partición: FOR VALUES FROM ('…') TO ('…')
        WHERE i.inhparent = parent
          AND substring(pg_get_expr(c.relpartbound, c.oid) FROM $re$TO \('([^']+)'\)$re$)::timestamptz <= cutoff
        ORDER BY c.relname
    LOOP
        -- primero el nombre: una vez eliminada la tabla, su regclass se imprime como un OID sin más
        RAISE NOTICE 'dropping %', part;
        EXECUTE format('ALTER TABLE %s DETACH PARTITION %s', parent, part);
        EXECUTE format('DROP TABLE %s', part);
    END LOOP;
END
$$;

CALL ci.drop_partitions_before('ci.step_log', '2026-06-01');
SELECT relid FROM pg_partition_tree('ci.step_log') WHERE isleaf ORDER BY relid::text;
```

```text
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE PROCEDURE
NOTICE:  dropping ci.step_log_2026_02
NOTICE:  dropping ci.step_log_2026_03
NOTICE:  dropping ci.step_log_2026_04
NOTICE:  dropping ci.step_log_2026_05
CALL
        relid
---------------------
 ci.step_log_2026_06
 ci.step_log_2026_07
 ci.step_log_2026_08
 ci.step_log_2026_09
(4 rows)
```

El límite superior vuelve del catálogo como texto, que se lee con una expresión regular y se convierte a `timestamptz`. Un `regclass` se imprime como un nombre mientras la tabla existe; después de `DROP TABLE`, el mismo valor se imprime como un número, y por eso el aviso va primero. Es el trabajo que los ajustes de retención de pg_partman hacen según una programación.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [particionado de tablas](https://www.postgresql.org/docs/18/ddl-partitioning.html), [`CREATE TABLE`](https://www.postgresql.org/docs/18/sql-createtable.html), [`ALTER TABLE`](https://www.postgresql.org/docs/18/sql-altertable.html), [ajustes de planificación de consultas](https://www.postgresql.org/docs/18/runtime-config-query.html), [`psql`](https://www.postgresql.org/docs/18/app-psql.html), [`pgstattuple`](https://www.postgresql.org/docs/18/pgstattuple.html), [funciones de información del sistema](https://www.postgresql.org/docs/18/functions-info.html), [funciones de información de particiones](https://www.postgresql.org/docs/18/functions-admin.html#FUNCTIONS-INFO-PARTITION), [notas de versión de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server: [tablas e índices particionados](https://learn.microsoft.com/sql/relational-databases/partitions/partitioned-tables-and-indexes), [`CREATE PARTITION FUNCTION`](https://learn.microsoft.com/sql/t-sql/statements/create-partition-function-transact-sql), [`ALTER TABLE … SWITCH`](https://learn.microsoft.com/sql/t-sql/statements/alter-table-transact-sql)
- AWS: [versiones de las extensiones](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraPostgreSQLReleaseNotes/AuroraPostgreSQL.Extensions.html), [pg_partman en Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/PostgreSQL_Partitions.html), [cuotas y límites](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_Limits.html), [consideraciones de blue/green](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/blue-green-deployments-considerations.html), [integraciones zero-ETL](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/zero-etl.html), todas consultadas el 2026-09-16
- [pg_partman](https://github.com/pgpartman/pg_partman), [pg_cron](https://github.com/citusdata/pg_cron)
