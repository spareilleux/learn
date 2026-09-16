---
title: "5. Índices y planes"
description: Leer EXPLAIN (ANALYZE, BUFFERS) en PostgreSQL 18 y elegir un índice sobre una tabla de 440 800 filas — índices B-tree, multicolumna, parciales, de expresión y de cobertura, escaneos solo de índice y el mapa de visibilidad, GIN sobre arrays, BRIN y el orden físico, y estadísticas extendidas para columnas correlacionadas; comparado con los planes de ejecución, los índices filtrados y las columnas incluidas de SQL Server.
sidebar:
  order: 5
---

El script de la lección es [`sql/05-indexes.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql), los ejercicios están en [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), y `check.sh` compara su salida con [`expected/05-indexes.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-indexes.txt) y [`expected/05-exercises.txt`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/expected/05-exercises.txt).

La instantánea de CI es demasiado pequeña para que los índices importen: 2204 pasos caben en unas pocas decenas de páginas, y leerlas todas es el plan más rápido. La lección construye una tabla más grande, `ci.step_history`, a partir de [`sql/history.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/history.sql): cada paso de la instantánea, repetido en cada uno de los 200 días hasta el 2026-09-14, en orden cronológico.

| SQL Server | PostgreSQL |
|---|---|
| plan de ejecución real, `SET STATISTICS IO ON` | `EXPLAIN (ANALYZE, BUFFERS)` |
| índice clúster: la propia tabla, ordenada por su clave | un heap sin orden; `CLUSTER` la ordena una vez |
| índice no clúster con `INCLUDE` | B-tree con `INCLUDE` |
| índice filtrado, `WHERE …` | índice parcial, `WHERE …` |
| índice sobre una columna calculada persistida | índice sobre una expresión |
| índices de texto completo y XML, índices JSON (preview en SQL Server 2025) | GIN, GiST, SP-GiST |
| eliminación de segmentos de columnstore | BRIN |
| estadísticas multicolumna, `CREATE STATISTICS` | `CREATE STATISTICS (dependencies, ndistinct, mcv)` |

## Planes estables para una lección

Un plan tiene tiempos, costes y recuentos de búferes que cambian de una ejecución a otra, y `check.sh` compara las salidas línea a línea. [`sql/explain.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql) los hace reproducibles ([líneas 3-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/explain.sql#L3-L30)):

```sql
-- Planes y recuentos de filas que son los mismos en cada ejecución:
-- sin workers paralelos, cuya parte de las filas varía, y estadísticas calculadas a partir de todas las filas, no de una muestra
SET max_parallel_workers_per_gather = 0;
SET default_statistics_target = 1500;

-- EXPLAIN ANALYZE sin lo que cambia entre ejecuciones: costes, tiempos, el uso de búferes del propio planificador, y el reparto de
-- las páginas entre shared buffers (hit) y disco (read), que depende de lo que las consultas anteriores dejaron en memoria
CREATE FUNCTION pg_temp.plan(query text) RETURNS TABLE ("QUERY PLAN" text) LANGUAGE plpgsql AS $$
DECLARE
    line text;
    planning boolean := false;
    pages bigint;
BEGIN
    FOR line IN EXECUTE 'EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF) ' || query LOOP
        IF line = 'Planning:' THEN
            planning := true;
        ELSIF NOT (planning AND line LIKE ' %') THEN
            planning := false;
            IF line ~ 'Buffers: shared ' THEN
                pages := coalesce(substring(line FROM 'hit=(\d+)')::bigint, 0) + coalesce(substring(line FROM 'read=(\d+)')::bigint, 0);
                line := substring(line FROM '^\s*') || 'Buffers: shared hit+read=' || pages;
            END IF;
            "QUERY PLAN" := line;
            RETURN NEXT;
        END IF;
    END LOOP;
END
$$;
```

- [`max_parallel_workers_per_gather`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-MAX-PARALLEL-WORKERS-PER-GATHER) `= 0` desactiva la consulta en paralelo: con workers, la parte de las filas de cada proceso cambiaba en cada ejecución.
- [`default_statistics_target`](https://www.postgresql.org/docs/18/runtime-config-query.html#GUC-DEFAULT-STATISTICS-TARGET) `= 1500` hace que `ANALYZE` muestree 300 filas por unidad de objetivo, 450 000 filas, más de las que tiene la tabla: las estadísticas salen de todas las filas, y las estimaciones son las mismas en cada ejecución. Con el valor por defecto de 100, `ANALYZE` lee una muestra aleatoria de 30 000 filas.
- `pg_temp.plan` ejecuta [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html) `(ANALYZE, COSTS OFF, TIMING OFF, SUMMARY OFF)` y suma en un solo número las páginas encontradas en memoria (`hit`) y las leídas del disco (`read`): cómo se reparten depende de lo que las consultas anteriores dejaron en la caché, el total no.

`EXPLAIN ANALYZE` ejecuta la consulta. Desde PostgreSQL 18, también muestra `BUFFERS` sin pedirlo, da los recuentos de filas con dos decimales, que importan cuando un nodo ejecuta muchos bucles, y cuenta los `Index Searches` de cada escaneo de índice ([notas de versión de PostgreSQL 18](https://www.postgresql.org/docs/18/release-18.html)). En tu propio `psql`, `EXPLAIN (ANALYZE, BUFFERS)` muestra los mismos planes con sus costes y tiempos.

## La tabla

[Líneas 8-11](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L8-L11):

```sql
-- La tabla: 2204 pasos repetidos en 200 días
SELECT count(*) AS rows, pg_size_pretty(pg_relation_size('ci.step_history')) AS size,
       min(started_at)::date AS first_day, max(started_at)::date AS last_day
FROM ci.step_history;
```

```text
  rows  | size  | first_day  |  last_day
--------+-------+------------+------------
 440800 | 76 MB | 2026-02-26 | 2026-09-14
(1 row)
```

## Un escaneo secuencial

Los pasos fallidos del día, sin índice ([líneas 13-17](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L13-L17)):

```sql
-- Una consulta, sin índice: se lee cada página de la tabla
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
                                                           QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=9667
   ->  Seq Scan on step_history (actual rows=15.00 loops=1)
         Filter: ((started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone) AND ((conclusion)::text = 'failure'::text))
         Rows Removed by Filter: 440785
         Buffers: shared hit+read=9667
(6 rows)
```

Un plan se lee desde el nodo más sangrado hacia arriba: cada nodo alimenta al de encima. `Seq Scan` leyó las 9667 páginas de la tabla, de 8 kB cada una, conservó 15 filas y descartó 440 785. `Buffers` es la cifra que hay que vigilar en esta lección: en un servidor real, las páginas que no están en memoria son lecturas de disco.

## B-tree

Un [B-tree](https://www.postgresql.org/docs/18/indexes-types.html#INDEXES-TYPES-BTREE) sobre `started_at`, y la misma consulta ([líneas 19-24](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L19-L24)):

```sql
-- Un B-tree sobre started_at
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
```

```text
CREATE INDEX
                                         QUERY PLAN
--------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=47
   ->  Index Scan using step_history_started_at on step_history (actual rows=15.00 loops=1)
         Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Index Searches: 1
         Buffers: shared hit+read=47
(8 rows)
```

47 páginas en lugar de 9667. `Index Cond` es lo que encuentra el índice: los 1533 pasos del 14 de septiembre. `Filter` se comprueba en cada fila que devolvió el índice, en la tabla: 1518 de ellas no eran fallos.

El mismo índice, desde el 1 de julio: un tercio de la tabla ([líneas 26-30](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L26-L30)):

```sql
-- El mismo índice, un rango que cubre un tercio de la tabla
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-07-01' AND conclusion = 'failure'
$$);
```

```text
                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4396
   ->  Index Scan using step_history_started_at on step_history (actual rows=1665.00 loops=1)
         Index Cond: (started_at >= '2026-07-01 00:00:00+00'::timestamp with time zone)
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 165168
         Index Searches: 1
         Buffers: shared hit+read=4396
(8 rows)
```

El planificador siguió eligiendo el índice, y leyó 4396 páginas, menos de la mitad de la tabla. Sabe que las filas con valores de `started_at` cercanos están en páginas cercanas, porque la tabla se llenó en orden cronológico: el escaneo de índice lee las páginas de la tabla casi en secuencia. En una tabla cuyas filas no siguen ningún orden, un tercio de las filas estaría repartido por la mayoría de las páginas, y un escaneo secuencial ganaría. La [sección BRIN](#brin) muestra la estadística que usa el planificador.

SQL Server guarda una tabla con índice clúster en el orden del índice. Una tabla de PostgreSQL es un heap: las filas van donde hay sitio, y [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html) la ordena una vez, sin mantenerla ordenada después.

## Índices multicolumna

Los cinco fallos más recientes, todos los días juntos ([líneas 32-39](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L32-L39)):

```sql
-- Los fallos más recientes, todos los días: primero la columna de igualdad, después la columna de ordenación
CREATE INDEX step_history_conclusion_started_at ON ci.step_history (conclusion, started_at);
SELECT * FROM pg_temp.plan($$
    SELECT started_at, workflow_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure'
    ORDER BY started_at DESC
    LIMIT 5
$$);
```

```text
CREATE INDEX
                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Limit (actual rows=5.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Scan Backward using step_history_conclusion_started_at on step_history (actual rows=5.00 loops=1)
         Index Cond: ((conclusion)::text = 'failure'::text)
         Index Searches: 1
         Buffers: shared hit+read=6
(6 rows)
```

El índice sobre `(conclusion, started_at)` mantiene juntos los fallos, ordenados por tiempo: `Index Scan Backward` los lee desde el más reciente, y `Limit` se detiene tras cinco. Seis páginas, y ningún nodo `Sort`. La regla es la misma que en SQL Server: primero las columnas comparadas con `=`, después la columna del rango o de la ordenación ([índices multicolumna](https://www.postgresql.org/docs/18/indexes-multicolumn.html)).

## Índices parciales

Un [índice parcial](https://www.postgresql.org/docs/18/indexes-partial.html) solo contiene las filas que acepta su `WHERE`, como un índice filtrado en SQL Server ([líneas 41-50](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L41-L50)):

```sql
-- Un índice parcial solo contiene las filas que acepta su WHERE
CREATE INDEX step_history_not_success ON ci.step_history (started_at) WHERE conclusion <> 'success';
SELECT indexrelid::regclass AS index, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_index WHERE indrelid = 'ci.step_history'::regclass
ORDER BY pg_relation_size(indexrelid) DESC, 1;

SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE conclusion <> 'success' AND started_at >= '2026-09-01'
$$);
```

```text
CREATE INDEX
                 index                 |  size
---------------------------------------+---------
 ci.step_history_conclusion_started_at | 9792 kB
 ci.step_history_pkey                  | 9688 kB
 ci.step_history_started_at            | 7504 kB
 ci.step_history_not_success           | 368 kB
(4 rows)

                                             QUERY PLAN
----------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=6
   ->  Index Only Scan using step_history_not_success on step_history (actual rows=1527.00 loops=1)
         Index Cond: (started_at >= '2026-09-01 00:00:00+00'::timestamp with time zone)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=6
(7 rows)
```

- 368 kB, frente a 7,5 MB para el índice sobre todas las filas: el 95 % de los pasos tuvo éxito, y el índice solo tiene el 5 % que se omitió, falló o se canceló.
- La consulta repite el predicado del índice, `conclusion <> 'success'`, así que el planificador sabe que todas las filas que busca están en el índice. Una consulta sin condición sobre `conclusion` no puede usarlo.
- `Index Only Scan`: el recuento no necesita ninguna columna de la tabla, y `Heap Fetches: 0` dice que no visitó la tabla en absoluto. La [sección de índices de cobertura](#índices-de-cobertura-y-escaneos-solo-de-índice) explica cuándo tiene que hacerlo.

## Índices sobre expresiones

Un índice sobre el día de `started_at` ([líneas 52-58](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L52-L58)):

```sql
-- Un índice sobre una expresión: la expresión debe ser inmutable
CREATE INDEX step_history_day ON ci.step_history ((started_at::date));
CREATE INDEX step_history_day ON ci.step_history (((started_at AT TIME ZONE 'UTC')::date));
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE (started_at AT TIME ZONE 'UTC')::date = '2026-09-14'
$$);
```

```text
ERROR:  functions in index expression must be marked IMMUTABLE
CREATE INDEX
                                           QUERY PLAN
------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=41
   ->  Bitmap Heap Scan on step_history (actual rows=1533.00 loops=1)
         Recheck Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
         Heap Blocks: exact=37
         Buffers: shared hit+read=41
         ->  Bitmap Index Scan on step_history_day (actual rows=1533.00 loops=1)
               Index Cond: (((started_at AT TIME ZONE 'UTC'::text))::date = '2026-09-14'::date)
               Index Searches: 1
               Buffers: shared hit+read=4
(10 rows)
```

El primer `CREATE INDEX` falla: la fecha de un `timestamptz` depende del `TimeZone` de la sesión, así que la conversión es `STABLE`, no `IMMUTABLE`, y un índice solo puede guardar lo que nunca cambia ([volatilidad de las funciones](https://www.postgresql.org/docs/18/xfunc-volatility.html)). `AT TIME ZONE 'UTC'` fija la zona, y el segundo índice funciona. SQL Server tiene la misma regla para un índice sobre una columna calculada, que debe ser determinista.

La consulta debe repetir la expresión tal como la escribe el índice. El planificador eligió un `Bitmap Heap Scan`: el índice da las posiciones de las 1533 filas, ordenadas por página en un mapa de bits, y la tabla se lee página a página, 37 páginas.

## Índices de cobertura y escaneos solo de índice

`INCLUDE` añade columnas a las entradas hoja de un B-tree, como en SQL Server ([líneas 60-72](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L60-L72)):

```sql
-- Un índice de cobertura y escaneos solo de índice
CREATE INDEX step_history_step_name ON ci.step_history (step_name) INCLUDE (duration);
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
UPDATE ci.step_history SET duration = duration WHERE step_name = 'Compile-fail doctests' AND started_at >= '2026-09-01';
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
VACUUM ci.step_history;
SELECT * FROM pg_temp.plan($$
    SELECT sum(duration) FROM ci.step_history WHERE step_name = 'Compile-fail doctests'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=70
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=70
(7 rows)

UPDATE 622
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=426
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 1244
         Index Searches: 1
         Buffers: shared hit+read=426
(7 rows)

VACUUM
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=71
   ->  Index Only Scan using step_history_step_name on step_history (actual rows=9200.00 loops=1)
         Index Cond: (step_name = 'Compile-fail doctests'::text)
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=71
(7 rows)
```

El índice tiene todas las columnas que necesita la suma, pero un índice de PostgreSQL no sabe si la transacción puede ver una fila: esa información está en la versión de la fila, en la tabla ([lección 6](../06-transactions/)). Un [escaneo solo de índice](https://www.postgresql.org/docs/18/indexes-index-only-scans.html) evita la tabla para las páginas que el [mapa de visibilidad](https://www.postgresql.org/docs/18/storage-vm.html) marca como totalmente visibles, cosa que hace `VACUUM`.

1. Después de `VACUUM ANALYZE`, todas las páginas son totalmente visibles: 70 páginas de índice, `Heap Fetches: 0`.
2. El `UPDATE` no cambia nada, pero escribe una nueva versión de 622 filas. Sus páginas dejan de ser totalmente visibles, y el índice tiene ahora 1244 entradas que apuntan a ellas, una para la versión antigua y otra para la nueva: 1244 lecturas en la tabla, 426 páginas.
3. `VACUUM` elimina las versiones antiguas y sus entradas de índice, y vuelve a marcar las páginas como totalmente visibles: de vuelta a 71 páginas.

En una tabla con actualizaciones constantes, y un autovacuum que va con retraso, un escaneo «solo de índice» lee la tabla de todos modos. Un índice no clúster de cobertura en SQL Server nunca vuelve a la tabla por esto; en PostgreSQL, el índice no contiene lo que una transacción necesita saber para ver una fila.

## GIN

[GIN](https://www.postgresql.org/docs/18/gin.html) indexa los elementos de un valor, aquí las etiquetas del runner, un array ([líneas 74-81](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L74-L81)):

```sql
-- GIN sobre un array: ¿qué elementos contiene una fila?
CREATE INDEX step_history_labels ON ci.step_history USING gin (labels);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE labels @> '{macos-latest}' AND step_name = 'Toolchain'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE 'macos-latest' = ANY (labels) AND step_name = 'Toolchain'
$$);
```

```text
CREATE INDEX
                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=3631
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: ((step_name = 'Toolchain'::text) AND (labels @> '{macos-latest}'::text[]))
         Heap Blocks: exact=3532
         Buffers: shared hit+read=3631
         ->  BitmapAnd (actual rows=0.00 loops=1)
               Buffers: shared hit+read=99
               ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
                     Index Cond: (step_name = 'Toolchain'::text)
                     Index Searches: 1
                     Buffers: shared hit+read=84
               ->  Bitmap Index Scan on step_history_labels (actual rows=80400.00 loops=1)
                     Index Cond: (labels @> '{macos-latest}'::text[])
                     Index Searches: 1
                     Buffers: shared hit+read=15
(16 rows)

                                       QUERY PLAN
----------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=5548
   ->  Bitmap Heap Scan on step_history (actual rows=4200.00 loops=1)
         Recheck Cond: (step_name = 'Toolchain'::text)
         Filter: ('macos-latest'::text = ANY (labels))
         Rows Removed by Filter: 9200
         Heap Blocks: exact=5464
         Buffers: shared hit+read=5548
         ->  Bitmap Index Scan on step_history_step_name (actual rows=13400.00 loops=1)
               Index Cond: (step_name = 'Toolchain'::text)
               Index Searches: 1
               Buffers: shared hit+read=84
(12 rows)
```

- `labels @> '{macos-latest}'`, «contiene», usa el índice GIN. El planificador combinó dos índices en un `BitmapAnd`: 13 400 pasos `Toolchain` y 80 400 pasos en macOS, 4200 en ambos.
- `'macos-latest' = ANY (labels)` significa lo mismo, pero ningún operador de índice le corresponde: el plan lee todos los pasos `Toolchain` y descarta 9200.

Un índice sirve a los operadores de su [clase de operadores](https://www.postgresql.org/docs/18/indexes-opclass.html), no al significado de una condición. La lección 7 usa GIN para `jsonb` y la búsqueda de texto. [GiST](https://www.postgresql.org/docs/18/gist.html), el otro tipo de índice de uso general, guarda rangos, formas geométricas y otros valores que se solapan o se contienen: es el índice que hay detrás de la restricción de exclusión de `ci.steps` en la [lección 2](../02-types/).

## BRIN

Un índice [BRIN](https://www.postgresql.org/docs/18/brin.html) guarda, para cada rango de 128 páginas, el valor más pequeño y el más grande de la columna ([líneas 83-93](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L83-L93)):

```sql
-- BRIN: un resumen por rango de páginas, útil cuando la columna sigue el orden físico
DROP INDEX ci.step_history_started_at, ci.step_history_conclusion_started_at, ci.step_history_not_success;
CREATE INDEX step_history_started_at_brin ON ci.step_history USING brin (started_at);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_started_at_brin')) AS brin_size;
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history
    WHERE started_at >= '2026-09-14' AND conclusion = 'failure'
$$);
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history' AND attname IN ('id', 'started_at', 'step_name')
ORDER BY attname;
```

```text
DROP INDEX
CREATE INDEX
 brin_size
-----------
 24 kB
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=87
   ->  Bitmap Heap Scan on step_history (actual rows=15.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 2094
         Filter: ((conclusion)::text = 'failure'::text)
         Rows Removed by Filter: 1518
         Heap Blocks: lossy=82
         Buffers: shared hit+read=87
         ->  Bitmap Index Scan on step_history_started_at_brin (actual rows=820.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(13 rows)

  attname   | correlation
------------+-------------
 id         |        1.00
 started_at |        1.00
 step_name  |        0.06
(3 rows)
```

- 24 kB, donde el B-tree sobre la misma columna ocupaba 7,5 MB.
- El índice da rangos de páginas, no filas: `Heap Blocks: lossy=82`, y cada fila de esas páginas se vuelve a comprobar, `Rows Removed by Index Recheck: 2094`. 87 páginas, frente a 47 con el B-tree.
- Solo funciona porque la tabla se llenó en orden cronológico. [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html)`.correlation` mide hasta qué punto una columna sigue el orden físico de las filas: 1,00 para `id` y `started_at`, 0,06 para `step_name`. El ejercicio 3 construye la misma tabla en otro orden.

BRIN es para tablas grandes que crecen en el orden de una columna: registros, eventos, mediciones. La idea más cercana en SQL Server es un índice columnstore que se salta grupos de filas por su mínimo y su máximo.

## Estadísticas sobre columnas correlacionadas

El planificador multiplica la selectividad de cada condición, como si las columnas fueran independientes ([líneas 95-106](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-indexes.sql#L95-L106)):

```sql
-- Estadísticas: dos columnas que dependen una de otra
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
CREATE STATISTICS step_history_workflow_job (dependencies) ON workflow_name, job_name FROM ci.step_history;
ANALYZE ci.step_history;
SELECT * FROM pg_temp.estimate($$
    SELECT * FROM ci.step_history
    WHERE workflow_name = 'Java course examples' AND job_name = 'java-for-csharp (ubuntu-latest)'
$$);
SELECT dependencies FROM pg_stats_ext WHERE statistics_name = 'step_history_workflow_job';
```

```text
 estimated | actual
-----------+--------
      2254 |  18200
(1 row)

CREATE STATISTICS
ANALYZE
 estimated | actual
-----------+--------
     17896 |  18200
(1 row)

               dependencies
------------------------------------------
 {"2 => 3": 0.010889, "3 => 2": 0.980944}
(1 row)
```

`pg_temp.estimate` pone la estimación de filas del planificador junto al recuento real. Un job llamado `java-for-csharp (ubuntu-latest)` solo se ejecuta en el workflow `Java course examples`, así que la segunda condición no elimina nada. El planificador estimó 2254 filas, ocho veces menos; una estimación errónea elige un nested loop donde hacía falta un hash join, o el índice equivocado.

[`CREATE STATISTICS … (dependencies)`](https://www.postgresql.org/docs/18/planner-stats.html#PLANNER-STATS-EXTENDED) mide cuánto determina una columna a otra. Las columnas 2 y 3 son `workflow_name` y `job_name`: el nombre del job determina el workflow en el 98 % de las filas, y la estimación pasa a 17 896. `ndistinct` ayuda a un `GROUP BY` sobre varias columnas, `mcv` enumera sus combinaciones más frecuentes.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Aurora PostgreSQL usa el planificador y los tipos de índice de PostgreSQL, así que los planes de esta lección se leen igual allí, y `EXPLAIN (ANALYZE, BUFFERS)` funciona como en cualquier PostgreSQL. Tres cosas cambian a su alrededor.

- **Estabilidad de los planes.** La [gestión de planes de consulta](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), la extensión `apg_plan_mgmt` (versión 3.0 en Aurora PostgreSQL 18.4), captura los planes de las instrucciones que ejecuta una aplicación. Con [`apg_plan_mgmt.capture_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html) a `manual` o `automatic`, «the optimizer sets the status of a managed statement's first captured plan to `approved`», y los siguientes a `unapproved` ([capturar planes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html)). Con `apg_plan_mgmt.use_plan_baselines` activado, el optimizador elige entre los planes aprobados, y [`evolve_plan_baselines`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html) compara los demás antes de aprobarlos. El Query Store de SQL Server fuerza planes con el mismo espíritu; PostgreSQL comunitario no trae nada integrado. Una estimación errónea como la de la sección de estadísticas de arriba es el tipo de regresión contra la que protege.
- **Supervisión.** Performance Insights ha sido sustituido por [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html): «AWS announced that the end-of-life date for Performance Insights was July 31, 2026, and has migrated Performance Insights users to Database Insights». El [historial del documento de la Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html) sigue dando el 30 de noviembre de 2025. Database Insights muestra la carga por evento de espera y por instrucción SQL; los planes de ejecución y el análisis de bloqueos solo están en su modo Advanced. El evento de espera [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html) es la parte `read` de `Buffers`: «a connection waits on a backend process to read a required page from storage because the page isn't available in shared memory».
- **Memoria.** [AWS escribe](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html) que «the value for `shared_buffers` in the default parameter group is usually set to around 75% of the available memory». PostgreSQL comunitario viene con 128 MB, y su documentación sugiere el 25 % de la memoria como punto de partida en un servidor dedicado ([`shared_buffers`](https://www.postgresql.org/docs/18/runtime-config-resource.html#GUC-SHARED-BUFFERS)). La [referencia de parámetros](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html) da la fórmula `SUM(DBInstanceClassMemory/12038,-50003)`, en una tabla para Aurora PostgreSQL 14; el valor para 18 está *por verificar*. Mi lectura, que no encontré afirmada por AWS, es que el almacenamiento de Aurora no se lee a través de la caché de archivos del sistema operativo, con la que PostgreSQL comunitario cuenta para el resto de la memoria.

## Puntos clave

- `EXPLAIN (ANALYZE, BUFFERS)` ejecuta la consulta; léelo desde el nodo más interno, y compara páginas, no solo tiempos.
- Un B-tree sirve a `=`, a los rangos y a las ordenaciones; en un índice multicolumna, primero las columnas de igualdad.
- Los índices parciales son pequeños; los índices de expresión necesitan expresiones `IMMUTABLE` y la misma expresión en la consulta.
- Los escaneos solo de índice dependen del mapa de visibilidad, es decir, de `VACUUM`.
- GIN indexa los elementos de arrays, `jsonb` y texto; un índice sirve a operadores, no a significados.
- BRIN es diminuto y solo útil cuando la columna sigue el orden físico.
- Las columnas correlacionadas engañan al planificador; `CREATE STATISTICS` corrige la estimación.

## Ejercicios

Las soluciones están en [`sql/05-exercises.sql`](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql), tras la misma preparación que la lección.

1. Muestra los 20 pasos fallidos más recientes del workflow `Rust course examples`, con un plan sin nodo `Sort`, y un índice de menos de un megabyte.

<details>
<summary>Solución</summary>

De las [líneas 8-16](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L8-L16):

```sql
-- Ejercicio 1: los 20 pasos fallidos más recientes del workflow del curso de Rust, sin ordenación
CREATE INDEX step_history_failures ON ci.step_history (workflow_name, started_at) WHERE conclusion = 'failure';
SELECT * FROM pg_temp.plan($$
    SELECT started_at, job_name, step_name FROM ci.step_history
    WHERE conclusion = 'failure' AND workflow_name = 'Rust course examples'
    ORDER BY started_at DESC
    LIMIT 20
$$);
SELECT pg_size_pretty(pg_relation_size('ci.step_history_failures')) AS size;
```

```text
CREATE INDEX
                                            QUERY PLAN
---------------------------------------------------------------------------------------------------
 Limit (actual rows=20.00 loops=1)
   Buffers: shared hit+read=15
   ->  Index Scan Backward using step_history_failures on step_history (actual rows=20.00 loops=1)
         Index Cond: (workflow_name = 'Rust course examples'::text)
         Index Searches: 1
         Buffers: shared hit+read=15
(6 rows)

  size
--------
 232 kB
(1 row)
```

Un índice parcial sobre `(workflow_name, started_at)`, solo para los fallos: 232 kB. El `conclusion = 'failure'` de la consulta coincide con el predicado, así que el plan ni siquiera lo muestra como condición; `workflow_name` es la columna de igualdad, y `started_at` da el orden, leído hacia atrás.

</details>

2. Cuenta los pasos del 10 de septiembre de 2026, primero con `date_trunc('day', started_at) = '2026-09-10'`, después con un rango, ambos con un B-tree sobre `started_at`. Compara los planes.

<details>
<summary>Solución</summary>

De las [líneas 18-25](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L18-L25):

```sql
-- Ejercicio 2: un día de pasos, escrito de dos formas
CREATE INDEX step_history_started_at ON ci.step_history (started_at);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE date_trunc('day', started_at) = '2026-09-10'
$$);
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history WHERE started_at >= '2026-09-10' AND started_at < '2026-09-11'
$$);
```

```text
CREATE INDEX
                                                 QUERY PLAN
------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=935
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Filter: (date_trunc('day'::text, started_at) = '2026-09-10 00:00:00+00'::timestamp with time zone)
         Rows Removed by Filter: 438596
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=935
(8 rows)

                                                                           QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=8
   ->  Index Only Scan using step_history_started_at on step_history (actual rows=2204.00 loops=1)
         Index Cond: ((started_at >= '2026-09-10 00:00:00+00'::timestamp with time zone) AND (started_at < '2026-09-11 00:00:00+00'::timestamp with time zone))
         Heap Fetches: 0
         Index Searches: 1
         Buffers: shared hit+read=8
(7 rows)
```

Con `date_trunc`, el índice no es más que una copia más pequeña de la columna: el plan lo lee entero, 935 páginas, y filtra 438 596 entradas. `date_trunc` sobre un `timestamptz` depende de la zona horaria de la sesión, así que tampoco podría indexarse sin `AT TIME ZONE`. El rango sobre la propia columna es un `Index Cond`: 8 páginas. SQL Server llama *sargable* a la segunda forma; la regla es la misma.

</details>

3. Copia `ci.step_history` en una tabla ordenada por `step_name` y después por `started_at`. Construye un índice BRIN sobre `started_at` y cuenta los pasos del 14 de septiembre. ¿Qué ha pasado?

<details>
<summary>Solución</summary>

De las [líneas 27-35](https://github.com/spareilleux/learn/blob/a5e397e/code/postgresql-aurora/sql/05-exercises.sql#L27-L35):

```sql
-- Ejercicio 3: las mismas filas en otro orden físico, y un índice BRIN sobre started_at
CREATE TABLE ci.step_history_by_name AS SELECT * FROM ci.step_history ORDER BY step_name, started_at;
CREATE INDEX step_history_by_name_brin ON ci.step_history_by_name USING brin (started_at);
VACUUM ANALYZE ci.step_history_by_name;
SELECT attname, round(correlation::numeric, 2) AS correlation
FROM pg_stats WHERE schemaname = 'ci' AND tablename = 'step_history_by_name' AND attname = 'started_at';
SELECT * FROM pg_temp.plan($$
    SELECT count(*) FROM ci.step_history_by_name WHERE started_at >= '2026-09-14'
$$);
```

```text
SELECT 440800
CREATE INDEX
VACUUM
  attname   | correlation
------------+-------------
 started_at |        0.06
(1 row)

                                          QUERY PLAN
----------------------------------------------------------------------------------------------
 Aggregate (actual rows=1.00 loops=1)
   Buffers: shared hit+read=4869
   ->  Bitmap Heap Scan on step_history_by_name (actual rows=1533.00 loops=1)
         Recheck Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
         Rows Removed by Index Recheck: 212661
         Heap Blocks: lossy=4864
         Buffers: shared hit+read=4869
         ->  Bitmap Index Scan on step_history_by_name_brin (actual rows=48640.00 loops=1)
               Index Cond: (started_at >= '2026-09-14 00:00:00+00'::timestamp with time zone)
               Index Searches: 1
               Buffers: shared hit+read=5
(11 rows)
```

La correlación de `started_at` cae a 0,06. Un rango de páginas contiene ahora los pasos de uno o unos pocos nombres, a lo largo de muchos días: la mitad de los rangos puede contener el 14 de septiembre, así que el índice conserva 4864 de las 9667 páginas de la tabla, y la nueva comprobación descarta 212 661 filas. Un escaneo secuencial habría hecho poco más trabajo. Un índice BRIN necesita datos que lleguen en el orden de su columna y se queden así.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [`EXPLAIN`](https://www.postgresql.org/docs/18/sql-explain.html), [usar `EXPLAIN`](https://www.postgresql.org/docs/18/using-explain.html), [tipos de índices](https://www.postgresql.org/docs/18/indexes-types.html), [índices multicolumna](https://www.postgresql.org/docs/18/indexes-multicolumn.html), [índices parciales](https://www.postgresql.org/docs/18/indexes-partial.html), [índices sobre expresiones](https://www.postgresql.org/docs/18/indexes-expressional.html), [escaneos solo de índice e índices de cobertura](https://www.postgresql.org/docs/18/indexes-index-only-scans.html), [clases de operadores](https://www.postgresql.org/docs/18/indexes-opclass.html), [GIN](https://www.postgresql.org/docs/18/gin.html), [GiST](https://www.postgresql.org/docs/18/gist.html), [BRIN](https://www.postgresql.org/docs/18/brin.html), [el mapa de visibilidad](https://www.postgresql.org/docs/18/storage-vm.html), [estadísticas usadas por el planificador](https://www.postgresql.org/docs/18/planner-stats.html), [`pg_stats`](https://www.postgresql.org/docs/18/view-pg-stats.html), [volatilidad de las funciones](https://www.postgresql.org/docs/18/xfunc-volatility.html), [`CLUSTER`](https://www.postgresql.org/docs/18/sql-cluster.html), [notas de versión](https://www.postgresql.org/docs/18/release-18.html)
- SQL Server: [índices filtrados](https://learn.microsoft.com/sql/relational-databases/indexes/create-filtered-indexes), [índices con columnas incluidas](https://learn.microsoft.com/sql/relational-databases/indexes/create-indexes-with-included-columns), [índices columnstore y eliminación de grupos de filas](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-query-performance)
- Amazon Aurora: [gestión de planes de consulta](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.overview.html), [capturar planes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.CapturePlans.html), [sus parámetros](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Parameters.html), [mantener los planes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Optimize.Maintenance.html), [CloudWatch Database Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html), [historial del documento](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/WhatsNew.html), [`IO:DataFileRead`](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/apg-waits.iodatafileread.html), [parámetros de memoria](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.BestPractices.Tuning-memory-parameters.html), [referencia de parámetros](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Reference.ParameterGroups.html), todas consultadas el 2026-09-16
