---
title: 2. Friendly SQL
description: Intervalos y zonas horarias, funciones de ventana con QUALIFY, PIVOT y los atajos que DuckDB añade a SQL — sobre el historial de ejecuciones de este sitio.
sidebar:
  order: 2
---

Todas las consultas de esta lección están en [`sql/02-friendly-sql.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-friendly-sql.sql), ejecutadas desde `code/duckdb` como en la [lección 1](../01-first-queries/). El script empieza cargando las ejecuciones en una tabla ([línea 2](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L2)):

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
```

## Duraciones: timestamps e intervalos

Restar dos valores `TIMESTAMP` da un [`INTERVAL`](https://duckdb.org/docs/current/sql/functions/interval), que `avg` y `max` aceptan ([líneas 5-9](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L5-L9)):

```sql
SELECT workflowName, count(*) AS runs, avg(updatedAt - startedAt) AS avg_took, max(updatedAt - startedAt) AS max_took
FROM runs
GROUP BY ALL
HAVING runs >= 4
ORDER BY avg_took DESC;
```

```text
┌────────────────────────┬───────┬─────────────────┬──────────┐
│      workflowName      │ runs  │    avg_took     │ max_took │
│        varchar         │ int64 │    interval     │ interval │
├────────────────────────┼───────┼─────────────────┼──────────┤
│ Java course examples   │     7 │ 00:03:18.857148 │ 00:04:48 │
│ Rust course examples   │    18 │ 00:01:32.888904 │ 00:02:33 │
│ Deploy to GitHub Pages │    65 │ 00:00:47.230784 │ 00:02:29 │
│ GHA 03: triggers       │     5 │ 00:00:33.4      │ 00:01:25 │
│ GHA 07: security       │     4 │ 00:00:10.25     │ 00:00:11 │
└────────────────────────┴───────┴─────────────────┴──────────┘
```

`HAVING runs >= 4` usa el alias del `SELECT`: DuckDB lo permite en `WHERE`, `GROUP BY` y `HAVING`, donde SQL Server te obliga a repetir `count(*)`. Los ejemplos de Java son los que más tardan, ya que el [curso de Java](../../java-for-csharp/) compila y ejecuta el código de cada lección en tres sistemas operativos.

Dos cosas que los datos no te dicen directamente:

- `updatedAt` es la última vez que cambió la ejecución, y `startedAt` es el inicio del **último intento**. La ejecución de `GHA 09: debugging` que se relanzó dos veces se creó a las 13:40:10 y empezó a las 13:44:02: su duración solo cuenta el tercer intento. La lección 3 usa en su lugar las marcas de tiempo de los jobs.
- `sum` no acepta intervalos, aunque `avg` sí:

```text
Binder Error: No function matches the given name and argument types 'sum(INTERVAL)'. You might need to add explicit type casts.
	Candidate functions:
	sum(DECIMAL) -> DECIMAL
```

Convierte primero a segundos con `epoch(interval)` o `date_diff('second', startedAt, updatedAt)`, y vuelve con `to_seconds(…)` si quieres de nuevo un intervalo: `to_seconds(sum(epoch(updatedAt - startedAt)))` da `00:51:10` para los 65 despliegues de este sitio.

### Truncar: ejecuciones por hora

De [`sql/02-friendly-sql.sql`, líneas 12-16](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L12-L16):

```sql
SELECT date_trunc('hour', createdAt) AS hour, count(*) AS runs
FROM runs
GROUP BY ALL
ORDER BY hour
LIMIT 5;
```

```text
┌─────────────────────┬───────┐
│        hour         │ runs  │
│      timestamp      │ int64 │
├─────────────────────┼───────┤
│ 2026-09-13 15:00:00 │     1 │
│ 2026-09-13 16:00:00 │    10 │
│ 2026-09-13 17:00:00 │    16 │
│ 2026-09-13 18:00:00 │     7 │
│ 2026-09-13 19:00:00 │     9 │
└─────────────────────┴───────┘
```

[`date_trunc`](https://duckdb.org/docs/current/sql/functions/timestamp) es `DATETRUNC` en SQL Server 2022. Un cast a `DATE` (`createdAt::DATE`) trunca al día; `hour(…)`, `dayofweek(…)` y las demás [partes de fecha](https://duckdb.org/docs/current/sql/functions/datepart) extraen un número.

## Zonas horarias

GitHub escribe `2026-09-13T15:53:16Z`: UTC. DuckDB lo leyó como un [`TIMESTAMP`](https://duckdb.org/docs/current/sql/data_types/timestamp), una fecha y hora sin zona, como `datetime2` en SQL Server. `TIMESTAMP WITH TIME ZONE` (`TIMESTAMPTZ`) es un instante, como `DateTimeOffset` en C# o `Instant` en Java, **mostrado en la zona horaria de la sesión**. `AT TIME ZONE 'UTC'` indica en qué zona estaba un `TIMESTAMP` y lo convierte en un `TIMESTAMPTZ` ([líneas 19-23](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L19-L23)):

```sql
SET TimeZone = 'Europe/Paris';
SELECT createdAt, createdAt AT TIME ZONE 'UTC' AS created_utc, hour(createdAt AT TIME ZONE 'UTC') AS hour_in_paris
FROM runs
ORDER BY createdAt
LIMIT 1;
```

```text
┌─────────────────────┬──────────────────────────┬───────────────┐
│      createdAt      │       created_utc        │ hour_in_paris │
│      timestamp      │ timestamp with time zone │     int64     │
├─────────────────────┼──────────────────────────┼───────────────┤
│ 2026-09-13 15:53:16 │ 2026-09-13 17:53:16+02   │            17 │
└─────────────────────┴──────────────────────────┴───────────────┘
```

Sin el `SET`, la CLI usa la zona horaria del sistema operativo. Por eso el script la fija: los runners de GitHub están en UTC, y la salida esperada no coincidiría en ningún otro lugar. Cualquier salida que muestre un `TIMESTAMPTZ` depende de una configuración, no solo de los datos. El soporte de zonas horarias viene de la [extensión ICU](https://duckdb.org/docs/current/core_extensions/icu), integrada en la CLI.

## Funciones de ventana

Las [funciones de ventana](https://duckdb.org/docs/current/sql/functions/window_functions) funcionan como en SQL Server y PostgreSQL. La cláusula `WINDOW` le da nombre a una ventana una sola vez, para varias funciones ([líneas 26-33](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L26-L33)):

```sql
SELECT createdAt, conclusion,
       lag(conclusion) OVER w AS previous,
       createdAt - lag(createdAt) OVER w AS since_previous
FROM runs
WHERE workflowName = 'Rust course examples'
WINDOW w AS (PARTITION BY workflowName ORDER BY createdAt)
ORDER BY createdAt
LIMIT 9;
```

```text
┌─────────────────────┬────────────┬──────────┬────────────────┐
│      createdAt      │ conclusion │ previous │ since_previous │
│      timestamp      │  varchar   │ varchar  │    interval    │
├─────────────────────┼────────────┼──────────┼────────────────┤
│ 2026-09-13 16:20:06 │ success    │ NULL     │ NULL           │
│ 2026-09-13 16:21:09 │ success    │ success  │ 00:01:03       │
│ 2026-09-13 16:45:55 │ success    │ success  │ 00:24:46       │
│ 2026-09-13 17:13:25 │ success    │ success  │ 00:27:30       │
│ 2026-09-13 17:40:34 │ failure    │ success  │ 00:27:09       │
│ 2026-09-13 17:41:56 │ failure    │ failure  │ 00:01:22       │
│ 2026-09-13 17:42:49 │ success    │ failure  │ 00:00:53       │
│ 2026-09-13 19:09:08 │ failure    │ success  │ 01:26:19       │
│ 2026-09-13 19:12:56 │ success    │ failure  │ 00:03:48       │
└─────────────────────┴────────────┴──────────┴────────────────┘
```

La historia de la CI del curso de Rust se lee en los intervalos entre ejecuciones: un fallo a las 17:40, otro 82 segundos después, corregido 53 segundos más tarde. La lección 3 averigua qué step falló.

## `QUALIFY`: filtrar sobre una función de ventana

¿Qué workflows están en rojo ahora mismo, es decir, cuáles tienen una **última** ejecución que no tuvo éxito? En SQL Server, una función de ventana no puede aparecer en `WHERE`, así que hace falta una subconsulta o una CTE. [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify) es un `WHERE` que se evalúa después de las funciones de ventana ([líneas 36-40](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L36-L40)):

```sql
SELECT workflowName, conclusion, createdAt
FROM runs
QUALIFY row_number() OVER (PARTITION BY workflowName ORDER BY createdAt DESC) = 1
    AND conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┬─────────────────────┐
│            workflowName             │   conclusion    │      createdAt      │
│               varchar               │     varchar     │      timestamp      │
├─────────────────────────────────────┼─────────────────┼─────────────────────┤
│ GHA 04: data between steps and jobs │ failure         │ 2026-09-14 12:47:40 │
│ GHA 04: exercise checks             │ failure         │ 2026-09-14 13:05:23 │
│ GHA 05: exercise checks             │ failure         │ 2026-09-14 13:18:20 │
│ GHA 06: exercise checks             │ failure         │ 2026-09-14 13:24:13 │
│ GHA 06: undeclared input            │ startup_failure │ 2026-09-14 13:24:30 │
│ GHA 09: debugging                   │ cancelled       │ 2026-09-14 13:40:10 │
│ GHA 10: exercise checks             │ failure         │ 2026-09-14 13:53:12 │
└─────────────────────────────────────┴─────────────────┴─────────────────────┘
```

Las dos condiciones no pueden pasar a `WHERE`: `conclusion <> 'success'` en `WHERE` eliminaría las ejecuciones en verde **antes** de la numeración, y aparecería todo workflow con al menos un fallo. Los siete son ejercicios del curso de GitHub Actions, en rojo a propósito.

## `PIVOT`

[`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot) convierte los valores de una columna en columnas. A diferencia del [`PIVOT` de SQL Server](https://learn.microsoft.com/sql/t-sql/queries/from-using-pivot-and-unpivot), no necesita la lista de valores ([líneas 43-47](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L43-L47)):

```sql
PIVOT (FROM runs WHERE workflowName IN ('Deploy to GitHub Pages', 'Rust course examples', 'Java course examples', 'GHA 03: triggers'))
ON conclusion
USING count(*)
GROUP BY workflowName
ORDER BY workflowName;
```

```text
┌────────────────────────┬───────────┬─────────┬─────────┐
│      workflowName      │ cancelled │ failure │ success │
│        varchar         │   int64   │  int64  │  int64  │
├────────────────────────┼───────────┼─────────┼─────────┤
│ Deploy to GitHub Pages │         0 │       2 │      63 │
│ GHA 03: triggers       │         2 │       2 │       1 │
│ Java course examples   │         0 │       0 │       7 │
│ Rust course examples   │         0 │       3 │      15 │
└────────────────────────┴───────────┴─────────┴─────────┘
```

- Las columnas son los valores encontrados en los datos, así que cambian con los datos: `startup_failure` existe en `runs`, pero ninguno de estos cuatro workflows tuvo uno, y la columna no está. El código que lee un pivot por nombre de columna debe contar con ello.
- Sin `ORDER BY`, el orden de las filas no está definido. Un primer intento de `PIVOT runs ON event USING count(*) GROUP BY conclusion` devolvió `success`, `cancelled`, `startup_failure`, `failure`, sin ningún orden útil. Los scripts del curso siempre terminan con `ORDER BY`; si no, su salida no se podría comparar.

## Atajos para columnas

De [`sql/02-friendly-sql.sql`, líneas 50-54](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-friendly-sql.sql#L50-L54):

```sql
SELECT headSha[1:7] AS sha, min(COLUMNS('.*At'))
FROM runs
GROUP BY ALL
ORDER BY ALL
LIMIT 3;
```

```text
┌─────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│   sha   │      createdAt      │      startedAt      │      updatedAt      │
│ varchar │      timestamp      │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ 04c8770 │ 2026-09-13 17:52:33 │ 2026-09-13 17:52:33 │ 2026-09-13 17:53:19 │
│ 1adf60f │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:10 │ 2026-09-13 16:50:43 │
│ 1de721b │ 2026-09-14 12:46:38 │ 2026-09-14 12:46:38 │ 2026-09-14 12:47:29 │
└─────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

- `headSha[1:7]` extrae una porción de una cadena, ambos extremos incluidos, contando desde 1: el hash corto del commit.
- [`COLUMNS('.*At')`](https://duckdb.org/docs/current/sql/expressions/star) se expande a cada columna cuyo nombre coincide con la expresión regular, y `min(COLUMNS(…))` aplica `min` a cada una: un agregado escrito, tres calculados.
- `ORDER BY ALL` ordena por todas las columnas, de izquierda a derecha.
- `SELECT * EXCLUDE (headSha, status)` selecciona todo salvo algunas columnas, y `SELECT * REPLACE (headSha[1:7] AS headSha)` cambia una manteniendo su posición.

## Puntos clave

- Restar timestamps da intervalos; `avg` y `max` aceptan intervalos, `sum` no: pasa por `epoch`.
- Un `TIMESTAMP` no tiene zona; un `TIMESTAMPTZ` se muestra en la zona de la sesión, así que fija `TimeZone` en todo lo que compares.
- `QUALIFY` filtra sobre funciones de ventana sin subconsulta.
- `PIVOT` encuentra sus columnas en los datos; ordena tú las filas.
- `GROUP BY ALL`, `ORDER BY ALL`, `COLUMNS`, `EXCLUDE` y los alias en `HAVING` eliminan repeticiones.

## Ejercicios

Las soluciones están en [`sql/02-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/02-exercises.sql), comprobadas por la CI.

1. Para cada día UTC, ¿cuántas ejecuciones hubo y qué porcentaje no tuvo éxito, con un decimal?

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 5-9](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-exercises.sql#L5-L9):

```sql
SELECT createdAt::DATE AS day, count(*) AS runs,
       round(100 * count(*) FILTER (conclusion <> 'success') / count(*), 1) AS not_green_pct
FROM runs
GROUP BY ALL
ORDER BY day;
```

```text
┌────────────┬───────┬───────────────┐
│    day     │ runs  │ not_green_pct │
│    date    │ int64 │    double     │
├────────────┼───────┼───────────────┤
│ 2026-09-13 │    43 │           7.0 │
│ 2026-09-14 │    82 │          22.0 │
└────────────┴───────┴───────────────┘
```

El segundo día es el del curso de GitHub Actions y sus ejercicios que fallan. Fíjate en `100 * … / count(*)`: en DuckDB, `/` entre dos enteros devuelve un `DOUBLE` (`7 / 2` es `3.5`), y `//` es la división entera. En SQL Server y en C#, la misma expresión habría truncado a `6` y `21`.

</details>

2. Para cada ejecución fallida, ¿cuánto tiempo estuvo su workflow en rojo, es decir, hasta la siguiente ejecución exitosa del mismo workflow? Lista primero los fallos que nunca se corrigieron.

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 12-18](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-exercises.sql#L12-L18):

```sql
SELECT workflowName, createdAt AS failed_at,
       min(createdAt) FILTER (conclusion = 'success') OVER (
           PARTITION BY workflowName ORDER BY createdAt
           ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) - createdAt AS red_for
FROM runs
QUALIFY conclusion = 'failure'
ORDER BY red_for DESC NULLS FIRST, workflowName, failed_at;
```

```text
┌─────────────────────────────────────┬─────────────────────┬──────────┐
│            workflowName             │      failed_at      │ red_for  │
│               varchar               │      timestamp      │ interval │
├─────────────────────────────────────┼─────────────────────┼──────────┤
│ GHA 04: data between steps and jobs │ 2026-09-14 12:47:40 │ NULL     │
│ GHA 04: exercise checks             │ 2026-09-14 13:05:23 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:12:27 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:16:06 │ NULL     │
│ GHA 05: exercise checks             │ 2026-09-14 13:18:20 │ NULL     │
│ GHA 06: exercise checks             │ 2026-09-14 13:24:13 │ NULL     │
│ GHA 10: exercise checks             │ 2026-09-14 13:53:12 │ NULL     │
│ Rust course examples                │ 2026-09-13 19:09:08 │ 00:03:48 │
│ Deploy to GitHub Pages              │ 2026-09-14 13:36:16 │ 00:03:46 │
│ Rust course examples                │ 2026-09-13 17:40:34 │ 00:02:15 │
│ GHA 09: exercise checks             │ 2026-09-14 13:46:43 │ 00:02:13 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:24 │ 00:02:05 │
│ GHA 03: triggers                    │ 2026-09-14 12:45:38 │ 00:01:51 │
│ GHA 10: custom actions              │ 2026-09-14 13:53:04 │ 00:01:03 │
│ Deploy to GitHub Pages              │ 2026-09-14 12:45:39 │ 00:00:59 │
│ Rust course examples                │ 2026-09-13 17:41:56 │ 00:00:53 │
└─────────────────────────────────────┴─────────────────────┴──────────┘
```

- El marco de la ventana empieza en `1 FOLLOWING`, la ejecución posterior al fallo; `FILTER` dentro de un agregado de ventana conserva solo los éxitos. `min(createdAt)` es entonces la siguiente ejecución en verde.
- El filtro sobre los fallos tiene que estar en `QUALIFY`: en `WHERE`, eliminaría los éxitos antes de que la ventana los busque, y todos los `red_for` serían `NULL`.
- `NULLS FIRST` pone arriba los fallos nunca corregidos; DuckDB ordena `NULL` al final por defecto, en ambas direcciones.

</details>

3. Reescribe la consulta `QUALIFY` de esta lección, la de los workflows cuya última ejecución no está en verde, sin ninguna función de ventana.

<details>
<summary>Solución</summary>

De [`sql/02-exercises.sql`, líneas 21-25](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/02-exercises.sql#L21-L25):

```sql
SELECT workflowName, arg_max(conclusion, createdAt) AS last_conclusion
FROM runs
GROUP BY ALL
HAVING last_conclusion <> 'success'
ORDER BY workflowName;
```

```text
┌─────────────────────────────────────┬─────────────────┐
│            workflowName             │ last_conclusion │
│               varchar               │     varchar     │
├─────────────────────────────────────┼─────────────────┤
│ GHA 04: data between steps and jobs │ failure         │
│ GHA 04: exercise checks             │ failure         │
│ GHA 05: exercise checks             │ failure         │
│ GHA 06: exercise checks             │ failure         │
│ GHA 06: undeclared input            │ startup_failure │
│ GHA 09: debugging                   │ cancelled       │
│ GHA 10: exercise checks             │ failure         │
└─────────────────────────────────────┴─────────────────┘
```

[`arg_max(value, key)`](https://duckdb.org/docs/current/sql/functions/aggregates) devuelve `value` de la fila donde `key` es mayor: la conclusión de la ejecución más reciente. Los mismos siete workflows. `QUALIFY` es la herramienta general, ya que puede devolver filas completas o el top 3; `arg_max` es más corto cuando basta un valor por grupo.

</details>

## Fuentes

- [Funciones de intervalo](https://duckdb.org/docs/current/sql/functions/interval), [funciones de timestamp](https://duckdb.org/docs/current/sql/functions/timestamp) y [partes de fecha](https://duckdb.org/docs/current/sql/functions/datepart)
- [Tipos timestamp](https://duckdb.org/docs/current/sql/data_types/timestamp) y [zonas horarias](https://duckdb.org/docs/current/sql/data_types/timezones)
- [Funciones de ventana](https://duckdb.org/docs/current/sql/functions/window_functions), [`WINDOW`](https://duckdb.org/docs/current/sql/query_syntax/window) y [`QUALIFY`](https://duckdb.org/docs/current/sql/query_syntax/qualify)
- [`PIVOT`](https://duckdb.org/docs/current/sql/statements/pivot)
- [Expresiones de estrella: `COLUMNS`, `EXCLUDE`, `REPLACE`](https://duckdb.org/docs/current/sql/expressions/star)
- [`ORDER BY`](https://duckdb.org/docs/current/sql/query_syntax/orderby) y [funciones de agregado](https://duckdb.org/docs/current/sql/functions/aggregates)
