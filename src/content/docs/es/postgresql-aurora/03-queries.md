---
title: "3. Consultas: CTE, ventanas, LATERAL, upserts y MERGE"
description: El SQL que PostgreSQL escribe de otra forma que T-SQL, sobre el modelo del curso — CTE y WITH RECURSIVE con un ciclo y la cláusula CYCLE, funciones de ventana y FILTER, LATERAL para CROSS APPLY, DISTINCT ON, RETURNING con old y new, INSERT … ON CONFLICT y MERGE con merge_action(); y lo que encuentran en el historial de CI de este sitio y en las dependencias de Guitar Alchemist.
sidebar:
  order: 3
---

El script de la lección es [`sql/03-queries.sql`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql), los ejercicios están en [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql), y `check.sh` compara su salida con [`expected/03-queries.txt`](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/expected/03-queries.txt) y [`expected/03-exercises.txt`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/expected/03-exercises.txt). Ambos scripts empiezan cargando el modelo de la [lección 2](../02-types/).

Los joins, `GROUP BY` y las subconsultas se escriben igual en ambos dialectos, así que esta lección los omite. Cubre lo que un desarrollador de SQL Server escribe de otra forma, o no puede escribir en absoluto.

| T-SQL | PostgreSQL |
|---|---|
| `SELECT TOP (1) …` en una subconsulta, o `ROW_NUMBER()` y un filtro | `DISTINCT ON (…)` |
| `CROSS APPLY`, `OUTER APPLY` | `CROSS JOIN LATERAL`, `LEFT JOIN LATERAL … ON true` |
| `OPTION (MAXRECURSION n)` | `statement_timeout`, `UNION`, la cláusula `CYCLE` |
| `SUM(CASE WHEN … THEN 1 END)` | `count(*) FILTER (WHERE …)` |
| `OUTPUT inserted.*, deleted.*` | `RETURNING new.*, old.*` |
| `MERGE … WITH (HOLDLOCK)` para insertar o actualizar | `INSERT … ON CONFLICT DO UPDATE` |
| `MERGE … OUTPUT $action` | `MERGE … RETURNING merge_action()` |

## CTE

Una expresión de tabla común da nombre a una consulta para la instrucción que sigue, como en T-SQL ([líneas 7-16](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L7-L16)):

```sql
WITH failed_runs AS (
    SELECT run_id, workflow_name FROM ci.runs WHERE conclusion = 'failure'
)
SELECT f.workflow_name, count(DISTINCT f.run_id) AS failed_runs,
       count(j.job_id) FILTER (WHERE j.conclusion = 'failure') AS failed_jobs
FROM failed_runs AS f
LEFT JOIN ci.jobs AS j USING (run_id)
GROUP BY f.workflow_name
ORDER BY failed_runs DESC, f.workflow_name
LIMIT 5;
```

```text
            workflow_name            | failed_runs | failed_jobs
-------------------------------------+-------------+-------------
 GHA 05: exercise checks             |           3 |           3
 Rust course examples                |           3 |           7
 Deploy to GitHub Pages              |           2 |           2
 GHA 03: triggers                    |           2 |           0
 GHA 04: data between steps and jobs |           1 |           1
(5 rows)
```

- `USING (run_id)` une por la columna de ese nombre en ambas tablas, y deja una sola columna `run_id` en el resultado.
- [`FILTER (WHERE …)`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES) restringe un agregado a algunas filas. T-SQL escribe `COUNT(CASE WHEN j.conclusion = 'failure' THEN 1 END)`.
- `GHA 03: triggers` tiene dos ejecuciones fallidas y ningún job fallido: esas dos ejecuciones no tienen ningún job en la instantánea.

Desde PostgreSQL 12, una CTE referenciada una sola vez y sin efectos secundarios se integra en la consulta, como una vista; `WITH … AS MATERIALIZED` impone el comportamiento anterior, que la calcula una vez ([consultas `WITH`](https://www.postgresql.org/docs/18/queries-with.html)).

## CTE recursivas

Las referencias entre proyectos de Guitar Alchemist forman un grafo. `WITH RECURSIVE` lo recorre desde `GaApi`: el primer `SELECT` da las referencias directas, y el segundo une las filas encontradas hasta ahora con las referencias de esos proyectos, hasta que una vuelta no encuentra nada nuevo ([líneas 19-29](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L19-L29)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS paths, count(DISTINCT to_path) AS projects, max(depth) AS longest_path
FROM deps;
```

```text
 paths | projects | longest_path
-------+----------+--------------
   435 |       20 |            7
(1 row)
```

`GaApi` depende de 20 proyectos, alcanzados por 435 caminos distintos: un rombo de dependencias cuenta una vez por camino. El camino más largo tiene 7 referencias.

El propio camino puede llevarse en un array. `DISTINCT ON` conserva la cadena más corta hacia cada proyecto; se explica más abajo ([líneas 32-49](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L32-L49)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, ARRAY[split_part(to_path, '/', -1)] AS chain
    FROM ga.project_refs
    WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.chain || split_part(r.to_path, '/', -1)
    FROM deps AS d
    JOIN ga.project_refs AS r ON r.from_path = d.to_path
),
shortest AS (
    SELECT DISTINCT ON (to_path) to_path, chain
    FROM deps
    ORDER BY to_path, cardinality(chain), chain
)
SELECT cardinality(chain) AS depth, array_to_string(chain, ' > ') AS chain
FROM shortest
WHERE cardinality(chain) >= 3
ORDER BY chain;
```

```text
 depth |                                   chain
-------+----------------------------------------------------------------------------
     3 | GA.Business.AI.csproj > GA.Data.MongoDB.csproj > GA.Business.Assets.csproj
(1 row)
```

[`split_part`](https://www.postgresql.org/docs/18/functions-string.html) con un índice negativo cuenta desde el final, desde PostgreSQL 14: `-1` es el nombre del archivo. Solo un proyecto está a tres referencias, incluso por el camino más corto: los otros 19 están a una o dos referencias de `GaApi`.

### Un ciclo

Las referencias entre proyectos .NET no pueden formar un ciclo: MSBuild se niega a compilarlo. Los datos, sí. El script añade la referencia `GA.Core → GaApi`, y vuelve a ejecutar la primera consulta ([líneas 52-60](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L52-L60)):

```sql
INSERT INTO ga.project_refs VALUES ('Common/GA.Core/GA.Core.csproj', 'Apps/ga-server/GaApi/GaApi.csproj');
SET statement_timeout = '3s';
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) FROM deps;
RESET statement_timeout;
```

```text
INSERT 0 1
SET
ERROR:  canceling statement due to statement timeout
RESET
```

La consulta nunca termina: cada vuelta vuelve a encontrar los mismos proyectos, un nivel más abajo, y `depth` hace que cada fila sea nueva, así que `UNION`, que elimina las filas duplicadas, no elimina nada. [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT) la detiene a los 3 segundos. SQL Server detiene una CTE recursiva tras 100 niveles por defecto, con un error que dice que se agotó la recursión máxima de 100, y [`MAXRECURSION`](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql) cambia el límite. PostgreSQL no tiene tal límite: sin tiempo máximo, esta consulta se ejecuta hasta que alguien la cancela o el servidor se queda sin memoria o sin disco.

Dos salidas ([líneas 62-76](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L62-L76)):

```sql
WITH RECURSIVE deps AS (
    SELECT to_path, 1 AS depth FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION ALL
    SELECT r.to_path, d.depth + 1 FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
) CYCLE to_path SET is_cycle USING path
SELECT count(*) AS paths, count(*) FILTER (WHERE is_cycle) AS cycles, max(depth) AS longest_path
FROM deps;

WITH RECURSIVE deps AS (
    SELECT to_path FROM ga.project_refs WHERE from_path = 'Apps/ga-server/GaApi/GaApi.csproj'
    UNION
    SELECT r.to_path FROM deps AS d JOIN ga.project_refs AS r ON r.from_path = d.to_path
)
SELECT count(*) AS projects FROM deps;
DELETE FROM ga.project_refs WHERE from_path = 'Common/GA.Core/GA.Core.csproj';
```

```text
 paths | cycles | longest_path
-------+--------+--------------
 15655 |   6982 |           13
(1 row)

 projects
----------
       21
(1 row)

DELETE 1
```

- La [cláusula `CYCLE`](https://www.postgresql.org/docs/18/queries-with.html#QUERIES-WITH-CYCLE), del estándar SQL y presente en PostgreSQL desde la versión 14, guarda la lista de valores `to_path` visitados en una columna llamada `path`, y pone `is_cycle` a verdadero en una fila que llega a un proyecto que ya está en su camino. Esa fila se conserva, y la recursión se detiene ahí. Con el ciclo, hay 15 655 caminos en lugar de 435: cada camino que pasa por `GA.Core` da ahora una vuelta más.
- Sin `depth`, un proyecto encontrado de nuevo es una fila duplicada, `UNION` la descarta, y la recursión se detiene cuando una vuelta no añade nada. 21 proyectos: las 20 dependencias, y el propio `GaApi`, alcanzado a través del ciclo. T-SQL no permite `UNION` en una CTE recursiva, solo `UNION ALL`.

La última instrucción elimina el ciclo.

## Funciones de ventana

Las funciones de ventana existen en ambos dialectos, con el mismo `OVER (PARTITION BY … ORDER BY …)`. Las ejecuciones del workflow del curso de Rust, en orden ([líneas 79-88](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L79-L88)):

```sql
SELECT run_id, started_at,
       updated_at - started_at AS took,
       lag(updated_at - started_at) OVER w AS previous_took,
       row_number() OVER w AS nth,
       count(*) FILTER (WHERE conclusion = 'failure') OVER w AS failures_so_far
FROM ci.runs
WHERE workflow_name = 'Rust course examples'
WINDOW w AS (PARTITION BY workflow_name ORDER BY started_at, run_id)
ORDER BY started_at, run_id
LIMIT 6;
```

```text
   run_id    |       started_at       |   took   | previous_took | nth | failures_so_far
-------------+------------------------+----------+---------------+-----+-----------------
 34768259924 | 2026-09-13 16:20:06+00 | 00:00:32 |               |   1 |               0
 34768314558 | 2026-09-13 16:21:09+00 | 00:00:20 | 00:00:32      |   2 |               0
 34769559799 | 2026-09-13 16:45:55+00 | 00:00:20 | 00:00:20      |   3 |               0
 34770934509 | 2026-09-13 17:13:25+00 | 00:00:33 | 00:00:20      |   4 |               0
 34772306529 | 2026-09-13 17:40:34+00 | 00:00:40 | 00:00:33      |   5 |               1
 34772373891 | 2026-09-13 17:41:56+00 | 00:00:31 | 00:00:40      |   6 |               2
(6 rows)
```

- La cláusula `WINDOW` da nombre a una ventana una vez para varias funciones. SQL Server la tiene desde SQL Server 2022.
- `FILTER` también funciona sobre un agregado usado como función de ventana: `failures_so_far` es un recuento acumulado de los fallos.
- Una ventana con `ORDER BY` y sin marco va desde el inicio de la partición hasta la fila actual, y sus pares: las filas con los mismos valores de `ORDER BY`. Por eso `run_id` está en el `ORDER BY`: dos ejecuciones iniciadas en el mismo segundo se contarían juntas si no.

Una función de ventana también puede aplicarse sobre el resultado de un `GROUP BY` ([líneas 91-95](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L91-L95)):

```sql
SELECT labels[1] AS os, count(*) AS jobs, sum(duration) AS total,
       round(100 * extract(epoch FROM sum(duration)) / sum(extract(epoch FROM sum(duration))) OVER (), 1) AS percent
FROM ci.jobs
GROUP BY labels[1]
ORDER BY total DESC;
```

```text
       os       | jobs |  total   | percent
----------------+------+----------+---------
 ubuntu-latest  |  246 | 01:27:52 |    50.0
 windows-latest |   35 | 00:56:25 |    32.1
 macos-latest   |   34 | 00:31:33 |    17.9
(3 rows)
```

`sum(duration)` es el agregado de cada grupo; `sum(…) OVER ()` suma esos agregados sobre todo el resultado. [`extract(epoch FROM …)`](https://www.postgresql.org/docs/18/functions-datetime.html#FUNCTIONS-DATETIME-EXTRACT) convierte un intervalo en segundos. Los jobs de Windows son el 11 % de los jobs y el 32 % del tiempo de CI. El [tutorial de funciones de ventana](https://www.postgresql.org/docs/18/tutorial-window.html) las presenta, y la [sintaxis de llamada a funciones de ventana](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-WINDOW-FUNCTIONS) enumera las opciones de marco.

## LATERAL

Una subconsulta en `FROM` normalmente no ve las otras tablas del mismo `FROM`. Con [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), sí las ve, y se ejecuta una vez por cada fila a su izquierda: el `CROSS APPLY` de SQL Server. El primer paso fallido de cada ejecución fallida ([líneas 98-117](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L98-L117)):

```sql
SELECT r.workflow_name, r.run_id, first_failure.job, first_failure.step
FROM ci.runs AS r
CROSS JOIN LATERAL (
    SELECT j.name AS job, s.name AS step
    FROM ci.jobs AS j
    JOIN ci.steps AS s USING (job_id)
    WHERE j.run_id = r.run_id AND s.conclusion = 'failure'
    ORDER BY s.started_at, j.job_id, s.number
    LIMIT 1
) AS first_failure
WHERE r.conclusion = 'failure'
ORDER BY r.workflow_name, r.run_id
LIMIT 6;

SELECT count(*) AS failed_runs,
       count(*) FILTER (WHERE NOT EXISTS (
           SELECT FROM ci.jobs AS j JOIN ci.steps AS s USING (job_id)
           WHERE j.run_id = r.run_id AND s.conclusion = 'failure')) AS without_failed_step
FROM ci.runs AS r
WHERE r.conclusion = 'failure';
```

```text
            workflow_name            |   run_id    |     job      |            step
-------------------------------------+-------------+--------------+-----------------------------
 Deploy to GitHub Pages              | 34845198191 | deploy       | Deploy to GitHub Pages
 GHA 04: data between steps and jobs | 34845384597 | produce      | Tests (fail on demand)
 GHA 04: exercise checks             | 34847078287 | produce      | Fail
 GHA 05: exercise checks             | 34847802892 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848189352 | no-lock-file | Run actions/setup-dotnet@v6
 GHA 05: exercise checks             | 34848421802 | no-lock-file | Run actions/setup-dotnet@v6
(6 rows)

 failed_runs | without_failed_step
-------------+---------------------
          16 |                   3
(1 row)
```

`CROSS JOIN LATERAL` descarta las filas de la izquierda para las que la subconsulta no devuelve nada, como `CROSS APPLY`; `LEFT JOIN LATERAL (…) ON true` las conserva, como `OUTER APPLY`, y el ejercicio 3 lo usa. Aquí, 3 de las 16 ejecuciones fallidas no tienen ningún paso fallido, así que faltan en el primer resultado: las dos ejecuciones sin jobs vistas antes, y una ejecución de `Deploy to GitHub Pages` cuyo job fallido solo tiene pasos correctos en la instantánea.

El `LIMIT 1` dentro de la subconsulta es la razón para usar `LATERAL`: «el primer … de cada …» es difícil de escribir con un join simple.

## DISTINCT ON

Las versiones de paquetes son texto en `ga.package_refs`, como en un `.csproj`. La versión más alta de un paquete, con `max` ([líneas 120-124](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L120-L124)):

```sql
SELECT package, max(version) AS text_max, count(DISTINCT version) AS versions
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.Hosting%'
GROUP BY package
ORDER BY package;
```

```text
                  package                  | text_max | versions
-------------------------------------------+----------+----------
 Microsoft.Extensions.Hosting              | 9.0.4    |        5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10   |        1
(2 rows)
```

`max` compara el texto carácter a carácter, y `'9'` es mayor que `'1'`: el máximo textual de `Microsoft.Extensions.Hosting` es 9.0.4, mientras que Guitar Alchemist también referencia 10.0.5. El mismo paquete se referencia en cinco versiones distintas en la solución.

Una versión se compara correctamente como un array de enteros, y [`DISTINCT ON`](https://www.postgresql.org/docs/18/sql-select.html#SQL-DISTINCT) conserva la primera fila de cada grupo en el orden del `ORDER BY` ([líneas 127-141](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L127-L141)):

```sql
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.%'
ORDER BY package, string_to_array(version, '.')::int[] DESC;

SELECT version, count(*) AS refs
FROM ga.package_refs
WHERE version !~ '^\d+(\.\d+)*$'
GROUP BY version
ORDER BY version;

SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package LIKE 'Microsoft.Extensions.H%' AND version ~ '^\d+(\.\d+)*$'
ORDER BY package, string_to_array(version, '.')::int[] DESC;
```

```text
ERROR:  invalid input syntax for type integer: "0-preview"
         version         | refs
-------------------------+------
 0.*                     |    1
 0.1.0-preview.10        |    1
 0.22.0-preview.24378.1  |    1
 1.0.0-alpha0031         |    1
 1.0.0-beta.24164.1      |   12
 1.0.0-preview.251028.1  |    1
 1.27.0-alpha            |    2
 13.0.0-preview.24       |    2
 2.0.0-beta5.25277.114   |    2
 2.2.0-beta.1            |    5
 4.0.0-preview.24478.1   |    2
 8.*-*                   |    1
 9.4.0-preview.1.25207.5 |    4
(13 rows)

                  package                  | version
-------------------------------------------+---------
 Microsoft.Extensions.Hosting              | 10.0.5
 Microsoft.Extensions.Hosting.Abstractions | 9.0.10
 Microsoft.Extensions.Http                 | 10.0.0
 Microsoft.Extensions.Http.Polly           | 9.0.10
 Microsoft.Extensions.Http.Resilience      | 9.1.0
(5 rows)
```

1. La conversión falla: una versión como `9.4.0-preview.1.25207.5` se divide en `9`, `4`, `0-preview`, … y `0-preview` no es un entero. Una sola fila mala hace fallar toda la instrucción.
2. `!~` significa «no coincide con la expresión regular». 13 versiones distintas no son números simples: previews y betas, y dos versiones flotantes, `0.*` y `8.*-*`, que dejan que NuGet elija un paquete distinto en cada restauración.
3. Filtrado a las versiones numéricas, `DISTINCT ON (package)` da una fila por paquete, la primera en el orden `package, version DESC`. Sus expresiones deben encabezar el `ORDER BY`.

T-SQL no tiene `DISTINCT ON`; el equivalente habitual es `ROW_NUMBER() OVER (PARTITION BY package ORDER BY …)` en una subconsulta, filtrado por `= 1`. La ordenación a dos niveles, texto para los paquetes y arrays para las versiones, es también algo que T-SQL no puede escribir sin dividir la cadena en columnas.

## RETURNING

`INSERT`, `UPDATE`, `DELETE` y `MERGE` pueden devolver las filas que modificaron, como hace el `OUTPUT` de T-SQL ([líneas 144-154](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L144-L154)):

```sql
CREATE TABLE ga.pinned_versions (
    package    text PRIMARY KEY,
    version    text NOT NULL CHECK (version ~ '^\d+(\.\d+)*$'),
    pinned_at  timestamptz NOT NULL DEFAULT '2026-09-14 00:00:00+00'
);
INSERT INTO ga.pinned_versions (package, version)
SELECT DISTINCT ON (package) package, version
FROM ga.package_refs
WHERE package IN ('Microsoft.Extensions.Hosting', 'MongoDB.Driver')
ORDER BY package, string_to_array(version, '.')::int[] DESC
RETURNING package, version, pinned_at;
```

```text
CREATE TABLE
           package            | version |       pinned_at
------------------------------+---------+------------------------
 Microsoft.Extensions.Hosting | 10.0.5  | 2026-09-14 00:00:00+00
 MongoDB.Driver               | 3.5.0   | 2026-09-14 00:00:00+00
(2 rows)

INSERT 0 2
```

La instrucción devuelve las filas como una consulta, y `psql` muestra `INSERT 0 2` después de ellas. `pinned_at` tiene un valor por defecto fijo para que la salida no cambie de un día a otro; una tabla real usaría `DEFAULT now()`. [`RETURNING`](https://www.postgresql.org/docs/18/dml-returning.html) es la forma en que un programa recupera una identidad o un `uuidv7()` generado por el servidor, en un solo viaje de ida y vuelta: la lección 4 lo usa desde C# y Java.

## INSERT … ON CONFLICT

«Insertar, o actualizar si existe» es una sola instrucción ([líneas 157-171](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L157-L171)):

```sql
INSERT INTO ga.pinned_versions (package, version, pinned_at)
VALUES ('MongoDB.Driver', '3.2.0', '2026-09-15 00:00:00+00'),
       ('Npgsql', '10.0.3', '2026-09-15 00:00:00+00')
ON CONFLICT (package) DO UPDATE
SET version = EXCLUDED.version, pinned_at = EXCLUDED.pinned_at
RETURNING package, old.version AS old_version, new.version AS new_version, old IS NULL AS inserted;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Dapper', '2.1.86'), ('Dapper', '2.1.72')
ON CONFLICT (package) DO UPDATE SET version = EXCLUDED.version;

INSERT INTO ga.pinned_versions (package, version)
VALUES ('Npgsql', '9.0.5')
ON CONFLICT (package) DO NOTHING
RETURNING package;
```

```text
    package     | old_version | new_version | inserted
----------------+-------------+-------------+----------
 MongoDB.Driver | 3.5.0       | 3.2.0       | f
 Npgsql         |             | 10.0.3      | t
(2 rows)

INSERT 0 2
ERROR:  ON CONFLICT DO UPDATE command cannot affect row a second time
HINT:  Ensure that no rows proposed for insertion within the same command have duplicate constrained values.
 package
---------
(0 rows)

INSERT 0 0
```

- [`ON CONFLICT (package) DO UPDATE`](https://www.postgresql.org/docs/18/sql-insert.html#SQL-ON-CONFLICT) necesita un índice o una restricción única sobre `package`, aquí la clave primaria. `EXCLUDED` es la fila que se propuso insertar.
- Desde PostgreSQL 18, `RETURNING` puede nombrar `old` y `new`, como `deleted` e `inserted` en el `OUTPUT` de T-SQL. Para una fila insertada, `old` es `NULL`, así que `old IS NULL` distingue una inserción de una actualización.
- La segunda instrucción propone `Dapper` dos veces, y falla: una fila no puede actualizarse dos veces en el mismo comando, porque el resultado dependería del orden de los `VALUES`. Elimina primero los duplicados de la entrada.
- `DO NOTHING` omite la fila en conflicto, y `RETURNING` solo devuelve las filas realmente insertadas: ninguna aquí.

La documentación garantiza un resultado atómico para `ON CONFLICT DO UPDATE`, una inserción o una actualización, incluso con mucha concurrencia: si otra transacción inserta el mismo `package` al mismo tiempo, la instrucción la espera y luego actualiza, en lugar de fallar con una clave duplicada. Para el mismo upsert, la [documentación de `MERGE` de SQL Server](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql) recomienda la sugerencia `HOLDLOCK`, sinónimo del nivel de aislamiento serializable.

## MERGE

[`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html) llegó en PostgreSQL 15; `WHEN NOT MATCHED BY SOURCE`, `RETURNING` y `merge_action()` en PostgreSQL 17. El script fija la versión numérica más alta de cada paquete referenciado por ocho proyectos o más, actualiza lo que cambió, y borra las fijaciones de los paquetes que ya no están en la lista ([líneas 174-195](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L174-L195)):

```sql
WITH changes AS (
    MERGE INTO ga.pinned_versions AS t
    USING (
        SELECT package, (array_agg(version ORDER BY string_to_array(version, '.')::int[] DESC))[1] AS version
        FROM ga.package_refs
        WHERE version ~ '^\d+(\.\d+)*$'
        GROUP BY package
        HAVING count(*) >= 8
    ) AS s
    ON t.package = s.package
    WHEN MATCHED AND t.version <> s.version THEN
        UPDATE SET version = s.version, pinned_at = '2026-09-16 00:00:00+00'
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (package, version) VALUES (s.package, s.version)
    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
    RETURNING merge_action() AS action, coalesce(new.package, old.package) AS package,
              old.version AS old_version, new.version AS new_version
)
SELECT * FROM changes ORDER BY action, package;

SELECT package, version, pinned_at FROM ga.pinned_versions ORDER BY package;
```

```text
 action |                  package                  | old_version | new_version
--------+-------------------------------------------+-------------+-------------
 DELETE | Npgsql                                    | 10.0.3      |
 INSERT | coverlet.collector                        |             | 6.0.4
 INSERT | JetBrains.Annotations                     |             | 2024.3.0
 INSERT | Microsoft.Extensions.DependencyInjection  |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging              |             | 10.0.0
 INSERT | Microsoft.Extensions.Logging.Abstractions |             | 10.0.2
 INSERT | Microsoft.Extensions.Logging.Console      |             | 10.0.0
 INSERT | Microsoft.NET.Test.Sdk                    |             | 17.14.0
 INSERT | NUnit                                     |             | 4.3.2
 INSERT | NUnit3TestAdapter                         |             | 5.0.0
 INSERT | NUnit.Analyzers                           |             | 4.7.0
 INSERT | Spectre.Console                           |             | 0.51.1
 INSERT | Swashbuckle.AspNetCore                    |             | 7.0.0
 INSERT | System.Numerics.Tensors                   |             | 10.0.2
 UPDATE | MongoDB.Driver                            | 3.2.0       | 3.5.0
(15 rows)

                  package                  | version  |       pinned_at
-------------------------------------------+----------+------------------------
 coverlet.collector                        | 6.0.4    | 2026-09-14 00:00:00+00
 JetBrains.Annotations                     | 2024.3.0 | 2026-09-14 00:00:00+00
 Microsoft.Extensions.DependencyInjection  | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Hosting              | 10.0.5   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging              | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Abstractions | 10.0.2   | 2026-09-14 00:00:00+00
 Microsoft.Extensions.Logging.Console      | 10.0.0   | 2026-09-14 00:00:00+00
 Microsoft.NET.Test.Sdk                    | 17.14.0  | 2026-09-14 00:00:00+00
 MongoDB.Driver                            | 3.5.0    | 2026-09-16 00:00:00+00
 NUnit                                     | 4.3.2    | 2026-09-14 00:00:00+00
 NUnit3TestAdapter                         | 5.0.0    | 2026-09-14 00:00:00+00
 NUnit.Analyzers                           | 4.7.0    | 2026-09-14 00:00:00+00
 Spectre.Console                           | 0.51.1   | 2026-09-14 00:00:00+00
 Swashbuckle.AspNetCore                    | 7.0.0    | 2026-09-14 00:00:00+00
 System.Numerics.Tensors                   | 10.0.2   | 2026-09-14 00:00:00+00
(15 rows)
```

- `(array_agg(version ORDER BY …))[1]` es «el primer valor en este orden» en forma de agregado, otra forma de escribir `DISTINCT ON`.
- `merge_action()` devuelve `INSERT`, `UPDATE` o `DELETE`, como `$action` en T-SQL. `coalesce(new.package, old.package)` es necesario porque `new` es `NULL` para una fila borrada.
- Un `MERGE` con `RETURNING` puede usarse en `WITH`, y la consulta externa ordena sus filas: el orden del `RETURNING` de una instrucción no está garantizado.
- `Npgsql` se borra: ningún proyecto de Guitar Alchemist lo referencia. `MongoDB.Driver`, 14 referencias, vuelve a pasar de 3.2.0 a 3.5.0 con una fecha nueva. `Microsoft.Extensions.Hosting`, 12 referencias, coincide con la misma versión 10.0.5: no se aplica ninguna cláusula `WHEN`, así que su fila queda como estaba y no se devuelve.

La documentación de PostgreSQL recomienda `INSERT … ON CONFLICT` en lugar de `MERGE` cuando son posibles inserciones concurrentes: `MERGE` puede fallar con una violación de unicidad donde `ON CONFLICT` actualizaría.

La lista final está ordenada por `package`, y `coverlet.collector` va antes que `JetBrains.Annotations`, `NUnit3TestAdapter` antes que `NUnit.Analyzers`. La base `learn` usa la [collation](https://www.postgresql.org/docs/18/collation.html) `en_US.utf8` de la biblioteca C de la imagen, que compara las letras antes que las mayúsculas y la puntuación. Con la collation `C`, las mayúsculas van antes que las minúsculas y `.` antes que las cifras. Un resultado ordenado por texto depende de la collation de la base: es parte de lo que «siempre un `ORDER BY`» no resuelve por sí solo.

## En Aurora

*Por verificar: nada de esta sección se ejecutó en AWS.* Aurora PostgreSQL ejecuta el motor de consultas de PostgreSQL, así que cada instrucción de esta lección es igual allí, desde `WITH RECURSIVE` hasta `MERGE … RETURNING` (PostgreSQL 17) y `old` y `new` en `RETURNING` (PostgreSQL 18, así que solo Aurora PostgreSQL 18). Lo que cambia es **dónde se ejecuta una consulta**.

- Un clúster Aurora tiene una instancia writer y hasta 15 Aurora Replicas, y varios [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html). El **cluster endpoint** se conecta al writer, para `INSERT`, `MERGE` y el DDL. El **reader endpoint** es para las consultas, y AWS escribe que Aurora «automatically performs connection-balancing among all the Aurora Replicas»: el reparto es por conexión, no por consulta. Un pool de conexiones abiertas en el reader endpoint se queda en las réplicas a las que llegó.
- Las réplicas comparten el volumen de almacenamiento del writer, y AWS da su retraso como «usually much less than 100 milliseconds» en la [página de replicación](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html), creciente con el ritmo de escrituras. Un programa que escribe por el cluster endpoint y lee enseguida por el reader endpoint puede no ver su propia escritura: lee tus propias escrituras en el writer.
- Informes como las consultas de ventanas y `LATERAL` de arriba son el tipo de trabajo que conviene enviar al reader endpoint, o a un custom endpoint para un grupo de réplicas más grandes.

Las réplicas son de solo lectura, y una escritura enviada a una de ellas falla. En PostgreSQL, un servidor en recuperación, como lo está un standby, empieza cada transacción en solo lectura ([`xact.c`, líneas 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)); una transacción de solo lectura en el servidor local da el mismo error ([líneas 197-201](https://github.com/spareilleux/learn/blob/15c2294/code/postgresql-aurora/sql/03-queries.sql#L197-L201)):

```sql
-- Una transacción de solo lectura rechaza las escrituras, como toda transacción en un standby
BEGIN TRANSACTION READ ONLY;
SELECT count(*) AS pinned FROM ga.pinned_versions;
DELETE FROM ga.pinned_versions WHERE package = 'Npgsql';
ROLLBACK;
```

```text
BEGIN
 pinned
--------
     15
(1 row)

ERROR:  cannot execute DELETE in a read-only transaction
ROLLBACK
```

Que una Aurora Replica devuelva exactamente este mensaje, SQLSTATE `25006`, está *por verificar*.

La lección 4 elige entre el writer y los readers desde una cadena de conexión, y la lección 12 vuelve sobre los endpoints y la conmutación por error.

## Puntos clave

- `WITH RECURSIVE` no tiene límite de recursión en PostgreSQL: protégelo con `UNION` sin columna de profundidad, la cláusula `CYCLE`, o `statement_timeout`.
- `FILTER (WHERE …)` restringe un agregado, en un `GROUP BY` y en las ventanas.
- `LATERAL` es `CROSS APPLY`; `LEFT JOIN LATERAL … ON true` es `OUTER APPLY`.
- `DISTINCT ON` conserva la primera fila de cada grupo en el orden del `ORDER BY`.
- Las versiones guardadas como texto se comparan como texto: `'9.0.4' > '10.0.5'`.
- `RETURNING old.*, new.*` sustituye a `OUTPUT deleted.*, inserted.*`; `INSERT … ON CONFLICT` es el upsert seguro con concurrencia, y `MERGE … RETURNING merge_action()` el general.
- Ordenar texto depende de la collation; en Aurora, las escrituras van al cluster endpoint, y las lecturas en las réplicas pueden ir con retraso.

## Ejercicios

Las soluciones están en [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql).

1. Guitar Alchemist da a cada acorde icónico sus clases de altura y una digitación de guitarra: un traste por cuerda, del mi grave al mi agudo, `-1` para una cuerda que no se toca. En afinación estándar, las cuerdas al aire son las clases de altura `4 9 2 7 11 4`. Calcula las clases de altura que toca realmente cada digitación, y compáralas con las declaradas.

<details>
<summary>Solución</summary>

De [`sql/03-exercises.sql`, líneas 8-23](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L8-L23):

```sql
WITH played AS (
    SELECT c.name, array_agg(DISTINCT (t.open_string + f.fret) % 12 ORDER BY (t.open_string + f.fret) % 12) AS voicing_pcs
    FROM ga.iconic_chords AS c
    CROSS JOIN LATERAL unnest(c.guitar_voicing) WITH ORDINALITY AS f(fret, string)
    JOIN unnest('{4,9,2,7,11,4}'::int[]) WITH ORDINALITY AS t(open_string, string) USING (string)
    WHERE f.fret >= 0
    GROUP BY c.name
)
SELECT p.name,
       ARRAY(SELECT unnest(c.pitch_classes) ORDER BY 1) AS declared,
       p.voicing_pcs AS played,
       ARRAY(SELECT unnest(c.pitch_classes) EXCEPT SELECT unnest(p.voicing_pcs) ORDER BY 1) AS missing,
       ARRAY(SELECT unnest(p.voicing_pcs) EXCEPT SELECT unnest(c.pitch_classes) ORDER BY 1) AS extra
FROM played AS p
JOIN ga.iconic_chords AS c USING (name)
ORDER BY p.name;
```

```text
       name       |   declared   |   played    | missing |  extra
------------------+--------------+-------------+---------+---------
 Blackbird Chord  | {2,7,11}     | {1,2,4,7,9} | {11}    | {1,4,9}
 Cowboy Chord     | {2,7,11}     | {2,7,11}    | {}      | {}
 Hendrix Chord    | {2,4,7,8,11} | {2,4,7,8}   | {11}    | {}
 James Bond Chord | {3,4,7,11}   | {3,4,7,11}  | {}      | {}
 Mu Major Chord   | {0,2,7}      | {0,2,4,7}   | {}      | {4}
 Power Chord      | {2,7}        | {2,7}       | {}      | {}
(6 rows)
```

`unnest(…) WITH ORDINALITY` numera los elementos de un array, lo que une cada traste con su cuerda. El traste más la cuerda al aire, módulo 12, es la clase de altura tocada. `ARRAY(SELECT … EXCEPT SELECT …)` calcula una diferencia de conjuntos entre dos arrays.

Solo seis de los 17 acordes tienen digitación. Tres son coherentes. Los otros tres son hallazgos sobre los datos de Guitar Alchemist, en [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml) en el commit `32f143c`:

- La digitación de Blackbird `{0,0,0,0,2,0}`, declarada como G/B, toca las cuerdas al aire y un do♯ en la cuerda de si: mi, la, re, sol, do♯, mi. Le falta si, y añade do♯, mi y la.
- El acorde Hendrix, E7♯9, declara si, su quinta, y la digitación `{0,7,6,7,8,0}` no la toca. Los guitarristas suelen omitir la quinta de ese acorde; el conjunto declarado y la digitación simplemente no coinciden.
- La digitación del Mu Major `{0,3,0,0,3,0}`, declarada como `Cadd9(no3)`, toca las cuerdas de mi al aire: mi, la tercera que `no3` dice omitida.

</details>

2. Enumera cada proyecto que depende de `GA.Data.MongoDB`, directamente o no, con su menor distancia. La ruta del proyecto es `GA.Data.MongoDB/GA.Data.MongoDB.csproj`.

<details>
<summary>Solución</summary>

De [`sql/03-exercises.sql`, líneas 26-38](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L26-L38):

```sql
WITH RECURSIVE dependents AS (
    SELECT from_path, 1 AS depth
    FROM ga.project_refs
    WHERE to_path = 'GA.Data.MongoDB/GA.Data.MongoDB.csproj'
    UNION
    SELECT r.from_path, d.depth + 1
    FROM dependents AS d
    JOIN ga.project_refs AS r ON r.to_path = d.from_path
)
SELECT min(depth) AS depth, from_path AS project
FROM dependents
GROUP BY from_path
ORDER BY depth, project;
```

```text
 depth |                                      project
-------+-----------------------------------------------------------------------------------
     1 | Apps/GaChatbotCli/GaChatbotCli.csproj
     1 | Apps/GaChatbot/GaChatbot.csproj
     1 | Apps/ga-server/GA.BSP.Service/GA.BSP.Service.csproj
     1 | Apps/ga-server/GA.DocumentProcessing.Service/GA.DocumentProcessing.Service.csproj
     1 | Common/GA.Business.AI/GA.Business.AI.csproj
     1 | Common/GA.Business.ML/GA.Business.ML.csproj
     1 | GaCLI/GaCLI.csproj
     2 | Apps/GaChatbot.Api/GaChatbot.Api.csproj
     2 | Apps/GaMemoryCli/GaMemoryCli.csproj
     2 | Apps/GaQaMcp/GaQaMcp.csproj
     2 | Apps/ga-server/GaApi/GaApi.csproj
     2 | Common/GA.Business.Core.Orchestration/GA.Business.Core.Orchestration.csproj
     2 | Common/GA.Business.Intelligence/GA.Business.Intelligence.csproj
     2 | Common/GA.Testing.Semantic/GA.Testing.Semantic.csproj
     2 | Demos/IntelligentAnalysis/IntelligentAnalysisDemo.csproj
     2 | Demos/Music Theory/FretboardVoicingsCLI/FretboardVoicingsCLI.csproj
     2 | GaMcpServer/GaMcpServer.csproj
     2 | GenerateNatData/GenerateNatData.csproj
     2 | Tests/Apps/GaChatbot.Tests/GaChatbot.Tests.csproj
     2 | Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj
     2 | Tests/Common/GA.Business.ML.Tests/GA.Business.ML.Tests.csproj
     2 | Tools/GaStructureInvariance/GaStructureInvariance.csproj
     3 | AllProjects.AppHost/AllProjects.AppHost.csproj
     3 | Apps/ga-server/GA.Analytics.Service/GA.Analytics.Service.csproj
     3 | Apps/InteractiveTutorial/InteractiveTutorial.csproj
     3 | Demos/Performance/VectorSearchBenchmark/VectorSearchBenchmark.csproj
     3 | Tests/Apps/GaApi.Tests/GaApi.Tests.csproj
     3 | Tests/Apps/GaChatbot.Api.Tests/GaChatbot.Api.Tests.csproj
     3 | Tests/Apps/GaMcpServer.Tests/GaMcpServer.Tests.csproj
     3 | Tests/GaApi.Tests/GaApi.Tests.csproj
(30 rows)
```

La recursión va en el otro sentido: de `to_path` a `from_path`. `UNION` la detiene en las filas ya encontradas, y `min(depth)` conserva la distancia más corta de un proyecto alcanzado por varios caminos. 30 proyectos dependen de la capa MongoDB, una cuarta parte de la solución. Dos de ellos se llaman `GaApi.Tests.csproj`, uno en `Tests/Apps/GaApi.Tests` y otro en `Tests/GaApi.Tests`: agrupar por el nombre del archivo en lugar de la ruta los habría fusionado.

</details>

3. Para cada ejecución fallida, ¿cuánto tardó el mismo workflow en volver a tener éxito? Pon primero los fallos que nunca fueron seguidos de un éxito en la instantánea.

<details>
<summary>Solución</summary>

De [`sql/03-exercises.sql`, líneas 41-51](https://github.com/spareilleux/learn/blob/f92b07e/code/postgresql-aurora/sql/03-exercises.sql#L41-L51):

```sql
SELECT f.workflow_name, f.started_at AS failed_at, next_success.started_at - f.started_at AS time_to_green
FROM ci.runs AS f
LEFT JOIN LATERAL (
    SELECT s.started_at
    FROM ci.runs AS s
    WHERE s.workflow_name = f.workflow_name AND s.conclusion = 'success' AND s.started_at > f.started_at
    ORDER BY s.started_at
    LIMIT 1
) AS next_success ON true
WHERE f.conclusion = 'failure'
ORDER BY time_to_green DESC NULLS FIRST, f.workflow_name, f.started_at;
```

```text
            workflow_name            |       failed_at        | time_to_green
-------------------------------------+------------------------+---------------
 GHA 04: data between steps and jobs | 2026-09-14 12:47:40+00 |
 GHA 04: exercise checks             | 2026-09-14 13:05:23+00 |
 GHA 05: exercise checks             | 2026-09-14 13:12:27+00 |
 GHA 05: exercise checks             | 2026-09-14 13:16:06+00 |
 GHA 05: exercise checks             | 2026-09-14 13:18:20+00 |
 GHA 06: exercise checks             | 2026-09-14 13:24:13+00 |
 GHA 10: exercise checks             | 2026-09-14 13:53:12+00 |
 Rust course examples                | 2026-09-13 19:09:08+00 | 00:03:48
 Deploy to GitHub Pages              | 2026-09-14 13:36:16+00 | 00:03:46
 Rust course examples                | 2026-09-13 17:40:34+00 | 00:02:15
 GHA 09: exercise checks             | 2026-09-14 13:46:43+00 | 00:02:13
 GHA 03: triggers                    | 2026-09-14 12:45:24+00 | 00:02:05
 GHA 03: triggers                    | 2026-09-14 12:45:38+00 | 00:01:51
 GHA 10: custom actions              | 2026-09-14 13:53:04+00 | 00:01:03
 Deploy to GitHub Pages              | 2026-09-14 12:45:39+00 | 00:00:59
 Rust course examples                | 2026-09-13 17:41:56+00 | 00:00:53
(16 rows)
```

`LEFT JOIN LATERAL (…) ON true` conserva las ejecuciones fallidas para las que la subconsulta no encuentra un éxito posterior, con columnas `NULL`: `OUTER APPLY`. `NULLS FIRST` las pone arriba de una ordenación descendente, donde PostgreSQL las pondría de todos modos: `NULL` se ordena como mayor que cualquier valor, lo contrario que SQL Server. Siete fallos no tuvieron ningún éxito después en la instantánea, seis de ellos en workflows de verificación de ejercicios.

</details>

## Fuentes

- Documentación de PostgreSQL 18: [consultas `WITH`](https://www.postgresql.org/docs/18/queries-with.html), [expresiones de agregado y `FILTER`](https://www.postgresql.org/docs/18/sql-expressions.html#SYNTAX-AGGREGATES), [funciones de ventana](https://www.postgresql.org/docs/18/tutorial-window.html) y [su referencia](https://www.postgresql.org/docs/18/functions-window.html), [`LATERAL`](https://www.postgresql.org/docs/18/queries-table-expressions.html#QUERIES-LATERAL), [`SELECT`](https://www.postgresql.org/docs/18/sql-select.html), [devolver datos de las filas modificadas](https://www.postgresql.org/docs/18/dml-returning.html), [`INSERT`](https://www.postgresql.org/docs/18/sql-insert.html), [`MERGE`](https://www.postgresql.org/docs/18/sql-merge.html), [soporte de collations](https://www.postgresql.org/docs/18/collation.html), [`statement_timeout`](https://www.postgresql.org/docs/18/runtime-config-client.html#GUC-STATEMENT-TIMEOUT)
- Código fuente de PostgreSQL en `REL_18_6`: [`xact.c`, líneas 2122-2130](https://github.com/postgres/postgres/blob/724edf9bde9d356724ad384a2e196edc3c9f80f7/src/backend/access/transam/xact.c#L2122-L2130)
- SQL Server: [expresión de tabla común `WITH`](https://learn.microsoft.com/sql/t-sql/queries/with-common-table-expression-transact-sql), [`FROM` y `APPLY`](https://learn.microsoft.com/sql/t-sql/queries/from-transact-sql), [`OUTPUT`](https://learn.microsoft.com/sql/t-sql/queries/output-clause-transact-sql), [`MERGE`](https://learn.microsoft.com/sql/t-sql/statements/merge-transact-sql)
- Amazon Aurora: [endpoints](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html), [replicación](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)
- Guitar Alchemist en el commit `32f143c`: [`IconicChords.yaml`](https://github.com/GuitarAlchemist/ga/blob/32f143c/Common/GA.Business.Config/IconicChords.yaml)
