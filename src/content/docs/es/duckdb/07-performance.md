---
title: 7. Rendimiento
description: Leer un plan de consulta de DuckDB, projection pushdown y filter pushdown, los row groups de Parquet y por qué importa ordenar, la poda de particiones, los hilos, los bytes que descarga una consulta sobre un Parquet remoto, los límites de memoria y el volcado a disco, y cuándo DuckDB no es la herramienta adecuada.
sidebar:
  order: 7
---

En SQL Server, lees un [plan de ejecución](https://learn.microsoft.com/sql/relational-databases/performance/execution-plans) para ver por qué una consulta es lenta, y un [índice columnstore](https://learn.microsoft.com/sql/relational-databases/indexes/columnstore-indexes-overview) es lo que hace rápidos los escaneos analíticos. DuckDB almacena todo en columnas, y también tiene planes. Esta lección los lee y luego mide lo que predicen.

Dos scripts:

- [`sql/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-performance.sql) muestra planes y metadatos de Parquet. Su salida no depende de la máquina, así que la CI la compara como en las demás lecciones.
- [`timings/07-performance.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/timings/07-performance.sql) aplica las mismas ideas a una tabla más grande con `.timer on`. La CI lo ejecuta en los tres sistemas operativos sin comparar nada; los tiempos de abajo salen de sus logs y de mi máquina, un PC con Windows 11 y 24 hilos.

```bash
duckdb < timings/07-performance.sql
```

Escribe unos 1,5 GB en `out/`: un archivo CSV de 1 GB y varios archivos Parquet. Bórralos después.

## Una tabla más grande

315 jobs no bastan para medir nada. El script repite cada step de cada job, desplazando las marcas de tiempo un día por copia ([líneas 7-11](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-performance.sql#L7-L11)):

```sql
CREATE TABLE steps AS
SELECT j.id AS job_id, j.labels[1] AS os, s.number, s.name, s.conclusion,
       s.started_at + to_days(d.i) AS started_at, s.completed_at + to_days(d.i) AS completed_at
FROM jobs j, unnest(j.steps) AS t(s), range(500) AS d(i);
SELECT count(*) AS steps, min(started_at) AS first_step, max(started_at) AS last_step FROM steps;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│  steps  │     first_step      │      last_step      │
│  int64  │      timestamp      │      timestamp      │
├─────────┼─────────────────────┼─────────────────────┤
│ 1102000 │ 2026-09-13 15:53:20 │ 2028-01-26 14:03:35 │
└─────────┴─────────────────────┴─────────────────────┘
```

`range(500)` es una función de tabla que devuelve los números del 0 al 499; la coma la une a cada step. El script de tiempos usa `range(5000)`: 11.020.000 steps, creados en 1,1 s en mi máquina y entre 2,0 s (runner de Ubuntu) y 4,0 s (runner de Windows) en la CI.

## Leer un plan

[`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain) muestra el plan físico sin ejecutar la consulta. Aquí, una consulta sobre el archivo JSON ([línea 18](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-performance.sql#L18)):

```sql
EXPLAIN SELECT conclusion, count(*) FROM 'data/jobs.json' GROUP BY ALL;
```

```text
┌─────────────────────────────┐
│┌───────────────────────────┐│
││       Physical Plan       ││
│└───────────────────────────┘│
└─────────────────────────────┘
┌───────────────────────────┐
│       HASH_GROUP_BY       │
│    ────────────────────   │
│         Groups: #0        │
│                           │
│        Aggregates:        │
│        count_star()       │
│                           │
│         ~199 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│         PROJECTION        │
│    ────────────────────   │
│         conclusion        │
│                           │
│         ~315 rows         │
└─────────────┬─────────────┘
┌─────────────┴─────────────┐
│       READ_JSON_AUTO      │
│    ────────────────────   │
│         Function:         │
│       READ_JSON_AUTO      │
│                           │
│        Projections:       │
│         conclusion        │
│                           │
│         ~315 rows         │
└───────────────────────────┘
```

Léelo de abajo arriba, como un plan de SQL Server se lee de derecha a izquierda: el escaneo produce filas para el operador que tiene encima. Los números con `~` son las estimaciones del optimizador; `#0` es la primera columna del operador de abajo. La estimación para los grupos, 199, está lejos de las cuatro conclusiones reales: aquí no importa mucho, pero cuando una combinación es lenta, una estimación equivocada es lo primero que hay que buscar.

La línea en la que fijarse es `Projections: conclusion`. Los jobs tienen 11 campos, entre ellos el array `steps`; el lector solo construye la única columna que usa la consulta. Eso es la **projection pushdown**: la selección de columnas se empuja hasta la lectura. Con JSON, el lector aún tiene que analizar todo el texto para encontrar ese campo. Con Parquet, ni siquiera lee las demás columnas.

`EXPLAIN ANALYZE` ejecuta la consulta y añade el número real de filas y el tiempo pasado en cada operador. La [documentación de perfilado](https://duckdb.org/docs/current/dev/profiling) enumera las demás salidas, como JSON.

## Filter pushdown y row groups

El script escribe los steps dos veces: `out/steps.parquet` en orden de inserción, `out/steps-sorted.parquet` ordenado por hora de inicio.

De [`sql/07-performance.sql`, líneas 14-25](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-performance.sql#L14-L25):

```sql
COPY steps TO 'out/steps.parquet';
COPY (FROM steps ORDER BY started_at) TO 'out/steps-sorted.parquet';

EXPLAIN
SELECT name, avg(completed_at - started_at) AS took
FROM 'out/steps.parquet'
WHERE started_at < '2026-09-20'
GROUP BY ALL;
```

```text
┌─────────────┴─────────────┐
│        PARQUET_SCAN       │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│        Projections:       │
│         started_at        │
│            name           │
│        completed_at       │
│                           │
│          Filters:         │
│ started_at<'2026-09-20 00 │
│     :00:00'::TIMESTAMP    │
│                           │
│       ~220,400 rows       │
└───────────────────────────┘
```

Tres columnas de siete, y una sección `Filters:`: la cláusula `WHERE` se trasladó al escaneo. Eso es el **filter pushdown**, el filtro empujado hasta la lectura, y en Parquet hace más que ahorrarse un operador de filtro.

Un [archivo Parquet](https://parquet.apache.org/docs/file-format/) se divide en **row groups**; DuckDB escribe uno cada 122.880 filas. Para cada columna de cada row group, el pie del archivo guarda el valor mínimo y el máximo. Antes de leer un row group, el escaneo compara el filtro con esas estadísticas y se salta el row group si ninguna fila puede coincidir. [`parquet_metadata`](https://duckdb.org/docs/current/data/parquet/metadata) las muestra ([líneas 28-33](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-performance.sql#L28-L33)):

```sql
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups, sum(row_group_num_rows) AS rows,
       count(*) FILTER (stats_min::TIMESTAMP < '2026-09-20') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet'])
WHERE path_in_schema = 'started_at'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬─────────┬────────────────────┐
│           file           │ row_groups │  rows   │ row_groups_to_read │
│         varchar          │   int64    │ int128  │       int64        │
├──────────────────────────┼────────────┼─────────┼────────────────────┤
│ out/steps-sorted.parquet │          9 │ 1102000 │                  1 │
│ out/steps.parquet        │          9 │ 1102000 │                  9 │
└──────────────────────────┴────────────┴─────────┴────────────────────┘
```

Mismas filas, misma respuesta (13.895 steps en ambos archivos), pero no el mismo trabajo. En orden de inserción, cada row group mezcla steps de todo el periodo, así que cada mínimo cae en la primera semana y no se puede saltar ningún row group. Ordenado, solo el primer row group empieza antes del 2026-09-20.

El plan es el mismo para ambos archivos: `EXPLAIN` muestra que el filtro llega al escaneo, no cuántos row groups se saltará. Los tiempos sí lo muestran. Un hilo, un día de 2030, sobre los archivos de 11 millones de filas:

| Un día, un hilo | Mi máquina | Runner de Ubuntu | Runner de Windows | Runner de macOS |
|---|---|---|---|---|
| Parquet sin ordenar | 0,052 s | 0,061 s | 0,098 s | 0,059 s |
| Parquet ordenado | 0,003 s | 0,003 s | 0,007 s | 0,007 s |

`EXPLAIN ANALYZE` sobre el archivo ordenado confirma que el escaneo solo produjo las filas que coinciden, a partir de un solo archivo:

```text
┌─────────────┴─────────────┐
│         TABLE_SCAN        │
│    ────────────────────   │
│         Function:         │
│        PARQUET_SCAN       │
│                           │
│     Projections: name     │
│                           │
│          Filters:         │
│ started_at>='2030-01-01 00│
│   :00:00'::TIMESTAMP AND  │
│   started_at<='2030-01-02 │
│    00:00:00'::TIMESTAMP   │
│                           │
│    Total Files Read: 1    │
│                           │
│        Filename(s):       │
│    out/steps-big-sorted   │
│          .parquet         │
│                           │
│                           │
│                           │
│         2,204 rows        │
│           0.01s           │
└───────────────────────────┘
```

Las propias tablas de DuckDB funcionan igual: la [guía de indexación](https://duckdb.org/docs/current/guides/performance/indexing) llama a estas estadísticas por row group *zonemaps*, y dice que «cuanto más ordenados estén los datos dentro de una columna, más valiosos serán los índices zonemap». Si una columna se filtra a menudo, ordena por ella al escribir el archivo. Ordenar también comprime mejor: el archivo ordenado de 11 millones de filas ocupaba 106 MB frente a 119 MB en mi máquina.

:::note[Los tamaños de archivo cambian entre ejecuciones]
El writer de Parquet usa varios hilos, y los tamaños variaron unos cientos de kilobytes entre dos ejecuciones en la misma máquina, y unos pocos megabytes entre máquinas: el archivo ordenado ocupaba 102 MB en los tres runners. Por eso el script comparado muestra números de filas y estadísticas, nunca tamaños comprimidos.
:::

## Poda de particiones

La lección 4 decía que un filtro sobre una columna de partición se salta archivos enteros. `EXPLAIN` lo muestra sin ejecutar nada ([línea 41](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-performance.sql#L41)):

```sql
EXPLAIN SELECT count(*) FROM read_parquet('out/jobs-by-os/*/*.parquet') WHERE os = 'windows-latest';
```

```text
┌─────────────┴─────────────┐
│        READ_PARQUET       │
│    ────────────────────   │
│         Function:         │
│        READ_PARQUET       │
│                           │
│       File Filters:       │
│  (os = 'windows-latest')  │
│                           │
│    Scanning Files: 1/3    │
│                           │
│          ~34 rows         │
└───────────────────────────┘
```

Los `File Filters` se deciden solo a partir de los nombres de carpeta: los otros dos archivos no se abren. El [particionado Hive](https://duckdb.org/docs/current/data/partitioning/hive_partitioning) es a los archivos lo que las estadísticas de los row groups son a las filas.

## Tabla, Parquet o CSV

El mismo agregado, el step más lento en promedio, sobre los 11 millones de steps almacenados de tres formas, con todos los hilos ([`timings/07-performance.sql`, línea 19](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/timings/07-performance.sql#L19)):

```sql
SELECT os, name, avg(completed_at - started_at) AS took FROM steps GROUP BY ALL ORDER BY took DESC LIMIT 1;
```

| Origen | Mi máquina (24 hilos) | Ubuntu (4) | Windows (4) | macOS (3) |
|---|---|---|---|---|
| tabla `steps` en memoria | 0,042 s | 0,263 s | 0,420 s | 0,289 s |
| `out/steps-big.parquet`, 119 MB | 0,048 s | 0,237 s | 0,553 s | 0,415 s |
| `out/steps-big.csv`, 1,09 GB | 0,416 s | 1,676 s | 2,709 s | 2,403 s |
| filtro sobre una semana, Parquet | 0,009 s | 0,025 s | 0,034 s | 0,026 s |
| filtro sobre una semana, CSV | 0,383 s | 1,064 s | 1,698 s | 1,117 s |

Todas las consultas devolvieron la misma fila: `Lesson 10 builds` en `windows-latest`, 2 min 24,75 s. Parquet es tan rápido como una tabla en memoria, porque DuckDB solo lee tres columnas y las decodifica en bloque. CSV es de 5 a 9 veces más lento que Parquet en el agregado: cada valor es texto que analizar, y no hay estadísticas, así que el filtro de la semana lee el gigabyte entero. Escribir tardó 0,41 s para Parquet y 0,50 s para CSV en mi máquina. Si un archivo CSV se consulta más de una vez, conviértelo primero.

## Hilos

DuckDB ejecuta una consulta en tantos hilos como núcleos tiene la máquina: el [ajuste `threads`](https://duckdb.org/docs/current/configuration/overview) vale por defecto el número de núcleos de la CPU. Los runners mostraron 4, 4 y 3. El agregado sobre la tabla, con `SET threads = 1`:

| Agregado sobre la tabla | Mi máquina | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| todos los hilos | 0,042 s | 0,263 s | 0,420 s | 0,289 s |
| `SET threads = 1` | 0,530 s | 0,632 s | 1,089 s | 1,120 s |

12,6 veces más rápido con 24 hilos, de 2,4 a 3,9 veces con 3 o 4. Los escaneos y los agregados hash se reparten bien entre hilos. La otra cara: una consulta de DuckDB en un servidor web usa todos los núcleos por defecto, y varias a la vez compiten por ellos. Ajusta `threads` cuando DuckDB comparte la máquina.

## Un archivo Parquet remoto

La lección 4 leía Parquet por HTTPS y afirmaba que DuckDB solo descarga lo que necesita. El [log HTTP](https://duckdb.org/docs/current/operations_manual/logging/overview) lo demuestra, sobre enero de 2024 de los [viajes de taxi de Nueva York](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), un archivo de 49.961.641 bytes ([`timings/07-performance.sql`, líneas 46-49](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/timings/07-performance.sql#L46-L49)):

```sql
CALL enable_logging('HTTP', storage = 'memory');
SELECT count(*) FROM 'https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet';
SELECT count(*) AS requests, sum(response.headers['Content-Length']::BIGINT) AS bytes FROM duckdb_logs_parsed('HTTP') WHERE request.type = 'GET';
CALL truncate_duckdb_logs();
```

Activar el log imprime una advertencia en la CLI, porque ahora el log también recoge las advertencias:

```text
WARNING:
The logging settings have been changed so you may lose warnings printed in the CLI.
To continue printing warnings to the console, set storage='shell_log_storage'.
```

El script repite el conteo para otras dos consultas. Las descargas fueron las mismas en mi máquina y en los tres runners:

| Consulta | Resultado | Peticiones `GET` | Bytes descargados | Tiempo, mi máquina |
|---|---|---|---|---|
| `count(*)` | 2.964.624 | 1 | 65.536 | 0,25 s |
| `avg(trip_distance)` | 3.6521691789583146 | 3 | 4.082.947 | 0,63 s |
| `SELECT * … LIMIT 1` | un viaje | 1 | 17.612.330 | 1,64 s |

Cada consulta empieza con una petición `HEAD` para obtener el tamaño del archivo. La primera descarga después el final del archivo, donde está el pie, y no necesita nada más: los números de filas están en el pie. El promedio lee una columna, el `LIMIT 1` lee todas las columnas de un row group. El ejercicio 3 cuadra estos números con los metadatos.

En una red, la disposición de las columnas importa más que en un disco: `SELECT *` sobre un archivo remoto es la consulta cara, incluso con `LIMIT 1`.

## Memoria y volcado a disco

Por defecto, DuckDB puede usar el 80 % de la RAM (`memory_limit`). Cuando una ordenación, una combinación, un `GROUP BY` o una función de ventana necesita más, la [guía de ajuste](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads) dice que vuelca a archivos temporales, en `temp_directory`: `.tmp` junto al proceso para una base de datos en memoria, `<file>.tmp` junto a un archivo de base de datos. El script de tiempos ordena los 11 millones de steps del archivo Parquet con dos límites ([`timings/07-performance.sql`, líneas 59-64](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/timings/07-performance.sql#L59-L64)):

```sql
SET temp_directory = 'out/tmp';
SET memory_limit = '500MB';
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-500mb.parquet';
SET memory_limit = '100MB';
SET threads = 1;
COPY (FROM 'out/steps-big.parquet' ORDER BY started_at) TO 'out/steps-big-sorted-100mb.parquet';
```

| Ordenación de 11 millones de filas | Mi máquina | Ubuntu | Windows | macOS |
|---|---|---|---|---|
| 500 MB, todos los hilos | 2,21 s | 2,91 s | 4,62 s | 4,92 s |
| 100 MB, un hilo | 6,34 s | 6,96 s | 9,89 s | 7,94 s |

En mi máquina, la misma ordenación tardó 1,37 s con 1 GB. Con 100 MB y cuatro hilos, falló:

```text
Out of Memory Error: failed to pin block of size 256.0 KiB (95.4 MiB/95.3 MiB used)

Possible solutions:
* Reducing the number of threads (SET threads=X)
* Disabling insertion-order preservation (SET preserve_insertion_order=false)
* Increasing the memory limit (SET memory_limit='...GB')
```

Los hilos trabajan en paralelo, cada uno sobre su propia parte de los datos, así que menos hilos necesitan menos memoria a la vez: esa es la primera sugerencia, y por eso el script usa un solo hilo. El `COPY` fallido también dejó un archivo: 1,1 MB en una ejecución; vacío en otra, donde la consulta siguiente falló con `File 'out/steps-big-sorted-100mb.parquet' too small to be a Parquet file`. Comprueba que un `COPY` tuvo éxito antes de usar su archivo.

Dos trampas encontradas por el camino. Bajar el límite por debajo de lo que ya está en uso falla: en una sesión que contenía la tabla de 11 millones de filas, `SET memory_limit = '10MB'` respondió `Failed to change memory limit to 10000000: could not free up enough memory for the new limit`. Y una tabla en una base de datos en memoria también cuenta para el límite: tras `SET memory_limit = '100MB'` en esa sesión, las consultas fallaban con `failed to pin block`. Por eso el script elimina primero la tabla.

## Cuándo DuckDB no es la herramienta adecuada

DuckDB está [diseñado para consultas analíticas](https://duckdb.org/why_duckdb): unos pocos escaneos grandes, agregados y combinaciones. Lo que midió este curso, y lo que dice la documentación, apunta a otras herramientas para:

- **Muchas transacciones pequeñas.** Un `INSERT` por fila tardó de 0,07 a 0,4 ms en la CI de las lecciones 5 y 6, mientras que el appender cargó un millón de filas en 0,2 a 0,5 s. Un sistema de registro de pedidos corresponde a SQL Server o PostgreSQL.
- **Varios procesos que escriben en la misma base de datos.** Un proceso puede leer y escribir un archivo de base de datos; [varios procesos solo pueden leerlo](https://duckdb.org/docs/current/connect/concurrency). La lección 8 lo prueba.
- **Un servidor compartido por muchos usuarios.** DuckDB vive dentro de tu proceso; no hay servidor, ni usuarios, ni permisos que gestionar.
- **Un archivo de base de datos en una unidad de red compartida.** Las [preguntas frecuentes](https://duckdb.org/faq) desaconsejan firmemente las cargas de lectura y escritura sobre almacenamiento conectado en red.

Para leer archivos, un historial de CI, una exportación de datos o un notebook, tiene el tamaño adecuado.

## Puntos clave

- `EXPLAIN` muestra el plan; léelo de abajo arriba. `EXPLAIN ANALYZE` ejecuta la consulta y añade las filas y los tiempos reales.
- `Projections:` en un escaneo es la lista de columnas que realmente se leen; `Filters:` es la parte de la cláusula `WHERE` empujada al escaneo.
- Los row groups de Parquet llevan estadísticas mín./máx. por columna. Un filtro solo se salta row groups si los datos están ordenados por esa columna: ordena los archivos por la columna por la que filtras.
- Las carpetas de partición se saltan antes de abrir ningún archivo (`Scanning Files: 1/3`).
- Parquet es más o menos tan rápido como una tabla en memoria, y de 5 a 9 veces más rápido que CSV para estas consultas.
- DuckDB usa todos los núcleos por defecto; ajusta `threads` cuando comparte una máquina.
- Una consulta sobre un Parquet remoto descarga el pie y los bloques de columna que necesita; `SELECT *` descarga row groups enteros.
- Con un límite de memoria, las ordenaciones, las combinaciones y los agregados vuelcan a `temp_directory`; cada hilo necesita memoria, así que reduce `threads` con límites pequeños.

## Ejercicios

Las soluciones están en [`sql/07-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/07-exercises.sql); sus tiempos están en el script de tiempos.

1. Cuatro formas de quedarse con los steps del 2030-01-01, sobre el archivo ordenado. ¿Cuáles pueden saltarse row groups? ¿Te lo dice `EXPLAIN`?

De [`timings/07-performance.sql`, líneas 34-37](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/timings/07-performance.sql#L34-L37):

```sql
WHERE started_at >= '2030-01-01' AND started_at < '2030-01-02'
WHERE started_at::DATE = '2030-01-01'
WHERE date_trunc('day', started_at) = '2030-01-01'
WHERE strftime(started_at, '%Y-%m-%d') = '2030-01-01'
```

<details>
<summary>Solución</summary>

`EXPLAIN` muestra una sección `Filters:` en el escaneo para las cuatro, así que no responde. Pero lo que muestra es distinto. En el archivo pequeño, con el 2026-09-14, el cast y `date_trunc` se reescribieron como un rango:

```text
│          Filters:         │
│ started_at>='2026-09-14 00│
│   :00:00'::TIMESTAMP AND  │
│  started_at<'2026-09-15 00│
│     :00:00'::TIMESTAMP    │
```

El filtro con `strftime` sigue siendo una expresión, a la que ninguna estadística mín./máx. puede responder:

```text
│          Filters:         │
│ (strftime(started_at, '%Y-│
│  %m-%d') = '2026-09-14')  │
```

Los tiempos coinciden. Las cuatro devuelven 2.204 steps; con un hilo, el rango, el cast y `date_trunc` tardaron de 0,002 a 0,005 s en mi máquina y en los runners, mientras que `strftime` tardó 0,467 s en mi máquina, y 0,60 s (Ubuntu), 0,96 s (macOS) y 1,12 s (Windows) en la CI, porque formatea 11 millones de marcas de tiempo como texto. En SQL Server, envolver una columna en una función hace que el predicado no sea sargable; el optimizador de DuckDB deshace algunas de esas envolturas, no todas. Compara las columnas con valores de su propio tipo.

</details>

2. Los steps se filtran por `os = 'windows-latest'`. ¿Cuántos de los 9 row groups hay que leer en `out/steps.parquet`, en `out/steps-sorted.parquet` y en un archivo ordenado por `os, started_at`?

<details>
<summary>Solución</summary>

Escribe el tercer archivo y luego compara el filtro con las estadísticas de `os` ([`sql/07-exercises.sql`, líneas 16-22](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-exercises.sql#L16-L22)):

```sql
COPY (FROM steps ORDER BY os, started_at) TO 'out/steps-by-os.parquet';
SELECT replace(file_name, '\', '/') AS file, count(*) AS row_groups,
       count(*) FILTER (stats_min <= 'windows-latest' AND stats_max >= 'windows-latest') AS row_groups_to_read
FROM parquet_metadata(['out/steps.parquet', 'out/steps-sorted.parquet', 'out/steps-by-os.parquet'])
WHERE path_in_schema = 'os'
GROUP BY ALL
ORDER BY file;
```

```text
┌──────────────────────────┬────────────┬────────────────────┐
│           file           │ row_groups │ row_groups_to_read │
│         varchar          │   int64    │       int64        │
├──────────────────────────┼────────────┼────────────────────┤
│ out/steps-by-os.parquet  │          9 │                  2 │
│ out/steps-sorted.parquet │          9 │                  9 │
│ out/steps.parquet        │          9 │                  9 │
└──────────────────────────┴────────────┴────────────────────┘
```

Ordenar por hora ayuda a los filtros por hora y a nada más. Un archivo solo puede estar bien ordenado para una columna, o para una columna principal y, dentro de cada valor, la siguiente. Para una columna con pocos valores como `os`, el particionado (una carpeta por valor) es otra respuesta.

</details>

3. Explica los bytes descargados por las tres consultas remotas (65.536, luego 4.082.947, luego 17.612.330) con `parquet_metadata` sobre la misma URL.

<details>
<summary>Solución</summary>

De [`sql/07-exercises.sql`, líneas 25-29](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/07-exercises.sql#L25-L29):

```sql
SELECT row_group_id, max(row_group_num_rows) AS rows, sum(total_compressed_size) AS all_columns,
       sum(total_compressed_size) FILTER (path_in_schema = 'trip_distance') AS trip_distance
FROM parquet_metadata('https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet')
GROUP BY ALL
ORDER BY row_group_id;
```

```text
┌──────────────┬─────────┬─────────────┬───────────────┐
│ row_group_id │  rows   │ all_columns │ trip_distance │
│    int64     │  int64  │   int128    │    int128     │
├──────────────┼─────────┼─────────────┼───────────────┤
│            0 │ 1048576 │    17611010 │       1441439 │
│            1 │ 1048576 │    17522229 │       1451920 │
│            2 │  867472 │    14817869 │       1189588 │
└──────────────┴─────────┴─────────────┴───────────────┘
```

- `count(*)`: 65.536 bytes es una petición de rango de 64 KiB al final del archivo. El pie cabe en ella, y los números de filas (1.048.576 + 1.048.576 + 867.472 = 2.964.624) están en el pie.
- `avg(trip_distance)`: 1.441.439 + 1.451.920 + 1.189.588 = 4.082.947, exactamente los tres bloques de `trip_distance`, una petición por row group. No hubo petición para el pie: ya estaba en la caché de archivos remotos de DuckDB (`enable_external_file_cache`, `true` por defecto), desde la primera consulta de la sesión.
- `SELECT * … LIMIT 1`: todas las columnas del row group 0, 17.611.010 bytes, más 1.320 bytes. Una petición de rango cubre bytes contiguos: desde el byte 4, donde empieza el primer bloque tras el número mágico `PAR1`, hasta el final del último bloque. En los metadatos, `dictionary_page_offset` y `total_compressed_size` dan ese intervalo, 17.612.330 bytes; los 1.320 bytes son los huecos entre los bloques de las 19 columnas.

</details>

## Fuentes

- [`EXPLAIN`](https://duckdb.org/docs/current/guides/meta/explain), [`EXPLAIN ANALYZE`](https://duckdb.org/docs/current/guides/meta/explain_analyze) y [perfilado](https://duckdb.org/docs/current/dev/profiling)
- [Guía de rendimiento](https://duckdb.org/docs/current/guides/performance/overview): [formatos de archivo](https://duckdb.org/docs/current/guides/performance/file_formats), [indexación](https://duckdb.org/docs/current/guides/performance/indexing), [ajuste de cargas de trabajo](https://duckdb.org/docs/current/guides/performance/how_to_tune_workloads)
- [Metadatos de Parquet](https://duckdb.org/docs/current/data/parquet/metadata) y [consejos sobre Parquet](https://duckdb.org/docs/current/data/parquet/tips)
- [Formato de archivo de Apache Parquet](https://parquet.apache.org/docs/file-format/)
- [Ajustes de configuración](https://duckdb.org/docs/current/configuration/overview): `threads`, `memory_limit`, `temp_directory`
- [Registro de eventos](https://duckdb.org/docs/current/operations_manual/logging/overview)
- [Particionado Hive](https://duckdb.org/docs/current/data/partitioning/hive_partitioning)
- [Concurrencia](https://duckdb.org/docs/current/connect/concurrency), [Por qué DuckDB](https://duckdb.org/why_duckdb) y las [preguntas frecuentes](https://duckdb.org/faq)
- [TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page), New York City Taxi and Limousine Commission
