---
title: 3. Datos anidados
description: Listas y structs a partir de JSON, unnest para convertir una lista en filas, lambdas para filtrar listas en su sitio, ANTI JOIN y construcción de valores anidados — sobre los jobs y steps de la CI de este sitio.
sidebar:
  order: 3
---

Las ejecuciones de las lecciones 1 y 2 son planas: un valor por campo. Sus jobs, no. Las consultas están en [`sql/03-nested-data.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-nested-data.sql).

## El archivo de jobs

`data/jobs.json` contiene los 315 jobs de las ejecuciones, tal como los devuelve el endpoint de la API REST de GitHub [List jobs for a workflow run](https://docs.github.com/rest/actions/workflow-jobs), con un subconjunto de los campos. Para una ejecución que se volvió a lanzar, la API devuelve solo los jobs del último intento: 4 jobs para la ejecución `GHA 09: debugging`, intentada tres veces, donde `?filter=all` devuelve 12. Un job, abreviado:

```json
{
  "id": 104004920113,
  "run_id": 34852867099,
  "name": "build",
  "conclusion": "success",
  "started_at": "2026-09-14T14:01:14Z",
  "labels": ["ubuntu-latest"],
  "steps": [
    {"number": 1, "name": "Set up job", "conclusion": "success", "started_at": "2026-09-14T14:01:15Z", "completed_at": "2026-09-14T14:01:19Z"},
    …
  ]
}
```

```sql
CREATE TABLE runs AS FROM 'data/runs.json';
CREATE TABLE jobs AS FROM 'data/jobs.json';
DESCRIBE jobs;
```

```text
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                          jobs                                                          │
│                                                                                                                        │
│ id           bigint                                                                                                    │
│ run_id       bigint                                                                                                    │
│ name         varchar                                                                                                   │
│ status       varchar                                                                                                   │
│ conclusion   varchar                                                                                                   │
│ created_at   timestamp                                                                                                 │
│ started_at   timestamp                                                                                                 │
│ completed_at timestamp                                                                                                 │
│ runner_name  varchar                                                                                                   │
│ labels       varchar[]                                                                                                 │
│ steps        struct(number bigint, "name" varchar, conclusion varchar, started_at timestamp, completed_at timestamp)[] │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

El lector de JSON convirtió los arrays en tipos [`LIST`](https://duckdb.org/docs/current/sql/data_types/list), escritos `type[]`, y los objetos en tipos [`STRUCT`](https://duckdb.org/docs/current/sql/data_types/struct), con campos con nombre y tipo. `steps` es una lista de structs. En C#, es una propiedad `List<Step>` en un record `Job`; en SQL Server, el JSON seguiría siendo una cadena `nvarchar(max)` y cada consulta volvería a pasar por `OPENJSON`.

## Leer listas y structs

De [`sql/03-nested-data.sql`, líneas 6-9](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L6-L9):

```sql
SELECT name, labels, labels[1] AS os, labels[0] AS index_zero, len(steps) AS steps, steps[1].name AS first_step
FROM jobs
ORDER BY id
LIMIT 3;
```

```text
┌─────────┬─────────────────┬───────────────┬────────────┬───────┬────────────┐
│  name   │     labels      │      os       │ index_zero │ steps │ first_step │
│ varchar │    varchar[]    │    varchar    │  varchar   │ int64 │  varchar   │
├─────────┼─────────────────┼───────────────┼────────────┼───────┼────────────┤
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
│ deploy  │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     3 │ Set up job │
│ build   │ [ubuntu-latest] │ ubuntu-latest │ NULL       │     6 │ Set up job │
└─────────┴─────────────────┴───────────────┴────────────┴───────┴────────────┘
```

- **Las listas empiezan en 1**, como en todo SQL. `labels[0]` no es un error, solo `NULL`, igual que cualquier índice más allá del final: un hábito de C# o Java que falla en silencio.
- `steps[1].name` lee un campo de un struct con un punto, como una propiedad.
- `len` cuenta los elementos de una lista.

## `unnest`: una fila por elemento

[`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest) convierte una lista en filas. Colocado en la cláusula `FROM` después de la tabla, se ejecuta una vez por job, con acceso a las columnas de ese job: el `CROSS APPLY OPENJSON(...)` de SQL Server, o `SelectMany` en LINQ.

De [`sql/03-nested-data.sql`, líneas 12-15](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L12-L15):

```sql
SELECT j.name AS job, s.number, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j, unnest(j.steps) AS t(s)
WHERE j.id = 104004920113
ORDER BY s.number;
```

```text
┌─────────┬────────┬──────────────────────────────────────┬──────────┐
│   job   │ number │                 step                 │   took   │
│ varchar │ int64  │               varchar                │ interval │
├─────────┼────────┼──────────────────────────────────────┼──────────┤
│ build   │      1 │ Set up job                           │ 00:00:04 │
│ build   │      2 │ Checkout                             │ 00:00:02 │
│ build   │      3 │ Install, build, and upload site      │ 00:00:48 │
│ build   │      5 │ Post Install, build, and upload site │ 00:00:00 │
│ build   │      6 │ Post Checkout                        │ 00:00:01 │
│ build   │      7 │ Complete job                         │ 00:00:00 │
└─────────┴────────┴──────────────────────────────────────┴──────────┘
```

`AS t(s)` nombra la tabla `t` y su única columna `s`, un struct. Es el job de build del despliegue de este sitio: 48 de sus 58 segundos se van en el step `withastro/action`. El step 4 falta en la propia respuesta de la API (`gh run view 34852867099 --json jobs` muestra los mismos números); probablemente sea un step interno de esa action compuesta, *por verificar*.

## Agregar datos anidados

El mismo patrón que con datos planos, una vez desplegada la lista. Las marcas de tiempo de los jobs dan una duración mejor que los campos de las ejecuciones de la lección 2, y una más: el tiempo que se pasa **esperando** un runner, de `created_at` a `started_at`.

De [`sql/03-nested-data.sql`, líneas 18-22](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L18-L22):

```sql
SELECT labels[1] AS os, count(*) AS jobs,
       avg(started_at - created_at) AS avg_wait, avg(completed_at - started_at) AS avg_run
FROM jobs
GROUP BY ALL
ORDER BY os;
```

```text
┌────────────────┬───────┬─────────────────┬────────────────┐
│       os       │ jobs  │    avg_wait     │    avg_run     │
│    varchar     │ int64 │    interval     │    interval    │
├────────────────┼───────┼─────────────────┼────────────────┤
│ macos-latest   │    34 │ 00:00:08.470596 │ 00:00:55.67649 │
│ ubuntu-latest  │   246 │ 00:00:03.5      │ 00:00:21.43097 │
│ windows-latest │    35 │ 00:00:03.4      │ 00:01:36.71431 │
└────────────────┴───────┴─────────────────┴────────────────┘
```

Los runners de macOS tardan más del doble en arrancar; los jobs de Windows duran más de cuatro veces más que los de Ubuntu. No es una comparación justa, porque la mayoría de los jobs de Ubuntu son pequeños, como el despliegue del sitio; el ejercicio 3 compara el mismo job en los tres sistemas.

## Lambdas: trabajar con una lista sin desplegarla

¿Qué steps fallan más? Cada job guarda sus steps fallidos en su propia lista; [`list_filter`](https://duckdb.org/docs/current/sql/functions/list) conserva los elementos para los que una [lambda](https://duckdb.org/docs/current/sql/functions/lambda) es verdadera, antes de que `unnest` convierta lo que queda en filas ([líneas 25-31](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L25-L31)):

```sql
SELECT f.name AS failed_step, count(*) AS failures, list(DISTINCT r.workflowName ORDER BY r.workflowName) AS workflows
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(list_filter(j.steps, lambda s: s.conclusion = 'failure')) AS t(f)
GROUP BY ALL
ORDER BY failures DESC, failed_step
LIMIT 5;
```

```text
┌───────────────────────────────────────┬──────────┬───────────────────────────────────────────────────────┐
│              failed_step              │ failures │                       workflows                       │
│                varchar                │  int64   │                       varchar[]                       │
├───────────────────────────────────────┼──────────┼───────────────────────────────────────────────────────┤
│ Formatting                            │        6 │ [Rust course examples]                                │
│ Run actions/setup-dotnet@v6           │        3 │ ['GHA 05: exercise checks']                           │
│ Run exit 3                            │        3 │ ['GHA 09: debugging', 'GHA 09: exercise checks']      │
│ Run ./.github/actions/hello-container │        2 │ ['GHA 10: custom actions', 'GHA 10: exercise checks'] │
│ Compile-fail doctests                 │        1 │ [Rust course examples]                                │
└───────────────────────────────────────┴──────────┴───────────────────────────────────────────────────────┘
```

- Dos de los tres fallos de Rust de la lección 2 fueron de formato, `cargo fmt --check`, en cada uno de los tres sistemas operativos; el tercero fue un doctest compile-fail. `Run actions/setup-dotnet@v6` es el archivo de bloqueo que faltaba en el curso de GitHub Actions, lección 5.
- `lambda s: s.conclusion = 'failure'` es la lambda de C# `s => s.Conclusion == "failure"`. `list_transform` es `Select`, `list_filter` es `Where`, `list_reduce` es `Aggregate`.
- `list(… ORDER BY …)` es un agregado que construye una lista: `STRING_AGG` sin la cadena. Algunos valores aparecen entre comillas simples en la salida (`'GHA 05: exercise checks'`) y otros no (`Rust course examples`): las comillas pertenecen a la visualización, no a los valores.

La sintaxis de flecha que aparece en ejemplos más antiguos sigue funcionando en 1.5.5, con una advertencia:

```text
WARNING:
Deprecated lambda arrow (->) detected. Please transition to the new lambda syntax, i.e.., lambda x, i: x + i, before DuckDB's next release.
Use SET lambda_syntax='ENABLE_SINGLE_ARROW' to revert to the deprecated behavior.
For more information, see https://duckdb.org/docs/stable/sql/functions/lambda.html.
```

## `ANTI JOIN`: filas sin coincidencia

125 ejecuciones en `runs.json`, pero `count(DISTINCT run_id)` en `jobs` da 121. ¿Qué ejecuciones no tienen ningún job? `NOT EXISTS` funciona, y también el [`ANTI JOIN`](https://duckdb.org/docs/current/sql/query_syntax/from) de DuckDB, que se lee como lo que hace ([líneas 34-37](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L34-L37)):

```sql
SELECT r.workflowName, r.event, r.conclusion, r.createdAt
FROM runs r
ANTI JOIN jobs j ON j.run_id = r.databaseId
ORDER BY r.createdAt;
```

```text
┌──────────────────────────┬───────────────────┬─────────────────┬─────────────────────┐
│       workflowName       │       event       │   conclusion    │      createdAt      │
│         varchar          │      varchar      │     varchar     │      timestamp      │
├──────────────────────────┼───────────────────┼─────────────────┼─────────────────────┤
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:24 │
│ GHA 03: triggers         │ push              │ failure         │ 2026-09-14 12:45:38 │
│ GHA 03: triggers         │ workflow_dispatch │ cancelled       │ 2026-09-14 12:47:19 │
│ GHA 06: undeclared input │ push              │ startup_failure │ 2026-09-14 13:24:30 │
└──────────────────────────┴───────────────────┴─────────────────┴─────────────────────┘
```

Las cuatro están en el [diario del curso de GitHub Actions](../../github-actions/journal/): los dos push de un archivo de workflow con YAML inválido, una ejecución manual cancelada por otra más reciente antes de que empezara su job, y el workflow que llamaba a otro con un input no declarado. Una ejecución puede fallar sin ejecutar nada. `SEMI JOIN` es lo contrario: las filas que **sí tienen** coincidencia, cada una una sola vez, como `EXISTS`.

## Construir valores anidados

La dirección contraria: agrupar filas en una lista de structs, con un literal de struct `{'key': value}` ([líneas 40-43](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-nested-data.sql#L40-L43)):

```sql
SELECT run_id, list({'job': name, 'conclusion': conclusion} ORDER BY name) AS jobs
FROM jobs
WHERE run_id = (SELECT databaseId FROM runs WHERE workflowName = 'GHA 10: exercise checks')
GROUP BY ALL;
```

```text
┌─────────────┬──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│   run_id    │                                                                   jobs                                                                   │
│    int64    │                                                struct(job varchar, conclusion varchar)[]                                                 │
├─────────────┼──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 34852035176 │ [{'job': commonjs, 'conclusion': failure}, {'job': container-on-windows, 'conclusion': failure}, {'job': inputs, 'conclusion': success}] │
└─────────────┴──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

`to_json` convierte cualquier valor en texto JSON, para una respuesta de API o un archivo: `to_json({'job': 'commonjs', 'steps': [1, 2]})` da `{"job":"commonjs","steps":[1,2]}`.

## Puntos clave

- Los arrays de JSON se convierten en `LIST` y los objetos en `STRUCT`, con tipos; los datos anidados siguen siendo consultables sin analizar cadenas.
- Las listas se indexan desde 1, y un índice fuera de rango es `NULL`, no un error.
- `unnest` en la cláusula `FROM` convierte una lista en filas, como `CROSS APPLY` o `SelectMany`.
- `list_filter` y `list_transform` con `lambda x: …` trabajan sobre una lista en su sitio.
- `ANTI JOIN` y `SEMI JOIN` dicen directamente «sin coincidencia» y «con coincidencia».
- `list(…)` y `{'key': value}` vuelven a construir valores anidados.

## Ejercicios

Las soluciones están en [`sql/03-exercises.sql`](https://github.com/spareilleux/learn/blob/main/code/duckdb/sql/03-exercises.sql), comprobadas por la CI.

1. Algunos jobs no tienen ningún step. ¿Cuáles son, y qué hay en su `runner_name`?

<details>
<summary>Solución</summary>

De [`sql/03-exercises.sql`, líneas 6-10](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L6-L10):

```sql
SELECT r.workflowName, j.name AS job, j.conclusion, j.runner_name, j.runner_name IS NULL AS runner_is_null
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id
WHERE len(j.steps) = 0
ORDER BY j.id;
```

```text
┌─────────────────────────────────────┬──────────────┬────────────┬─────────────┬────────────────┐
│            workflowName             │     job      │ conclusion │ runner_name │ runner_is_null │
│               varchar               │   varchar    │  varchar   │   varchar   │    boolean     │
├─────────────────────────────────────┼──────────────┼────────────┼─────────────┼────────────────┤
│ GHA 04: data between steps and jobs │ consume      │ skipped    │ NULL        │ true           │
│ Deploy to GitHub Pages              │ deploy       │ failure    │             │ false          │
│ GHA 09: exercise checks             │ job-timeout  │ skipped    │ NULL        │ true           │
│ GHA 09: exercise checks             │ step-timeout │ skipped    │ NULL        │ true           │
└─────────────────────────────────────┴──────────────┴────────────┴─────────────┴────────────────┘
```

Tres jobs omitidos (skipped), que nunca obtuvieron un runner: `NULL`. Y un job `deploy` que falló sin ningún step: el despliegue desde una rama distinta de `main`, rechazado por la regla de rama del entorno en el curso de GitHub Actions. Recibió una **cadena vacía** como nombre de runner, no `NULL`. `WHERE runner_name IS NULL` no lo detectaría: comprueba ambos casos, o `coalesce(runner_name, '') = ''`, siempre que la fuente sea el JSON de otra persona.

</details>

2. `SELECT name, unnest(steps, recursive := true) FROM jobs` expande cada struct de step en columnas. El job tiene un `name`, y cada step también. ¿Cómo se llaman las columnas?

<details>
<summary>Solución</summary>

En la salida de la CLI, las dos columnas se llaman `name`. Referenciarlas desde una consulta externa muestra los nombres reales ([`sql/03-exercises.sql`, líneas 13-16](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L13-L16)):

```sql
SELECT name, name_1, conclusion
FROM (SELECT name, unnest(steps, recursive := true) FROM jobs WHERE id = 104004920113)
ORDER BY number
LIMIT 3;
```

```text
┌─────────┬─────────────────────────────────┬────────────┐
│  name   │             name_1              │ conclusion │
│ varchar │             varchar             │  varchar   │
├─────────┼─────────────────────────────────┼────────────┤
│ build   │ Set up job                      │ success    │
│ build   │ Checkout                        │ success    │
│ build   │ Install, build, and upload site │ success    │
└─────────┴─────────────────────────────────┴────────────┘
```

La [regla de deduplicación](https://duckdb.org/docs/current/sql/dialect/keywords_and_identifiers) conserva el primer `name` y renombra el siguiente como `name_1`. Y `conclusion` es la **del step**: el job no tiene `conclusion` en esta subconsulta, ya que solo se seleccionó `name`. Cuando ambos lados tienen campos en común, ponles alias explícitos, como hace la lección con `j.name AS job, s.name AS step`.

</details>

3. `GHA 02: build and test` compila los mismos proyectos .NET y Java en tres sistemas operativos. ¿Cuál es el step más lento en cada uno?

<details>
<summary>Solución</summary>

De [`sql/03-exercises.sql`, líneas 19-25](https://github.com/spareilleux/learn/blob/93f6f82/code/duckdb/sql/03-exercises.sql#L19-L25):

```sql
SELECT j.labels[1] AS os, j.name AS job, s.name AS step, s.completed_at - s.started_at AS took
FROM jobs j
JOIN runs r ON r.databaseId = j.run_id,
     unnest(j.steps) AS t(s)
WHERE r.workflowName = 'GHA 02: build and test'
QUALIFY row_number() OVER (PARTITION BY os ORDER BY took DESC, j.id, s.number) = 1
ORDER BY os;
```

```text
┌────────────────┬─────────────────────────┬─────────────────────────────┬──────────┐
│       os       │           job           │            step             │   took   │
│    varchar     │         varchar         │           varchar           │ interval │
├────────────────┼─────────────────────────┼─────────────────────────────┼──────────┤
│ macos-latest   │ dotnet (macos-latest)   │ Run actions/setup-dotnet@v6 │ 00:00:11 │
│ ubuntu-latest  │ java (ubuntu-latest)    │ Run mvn -B verify           │ 00:00:11 │
│ windows-latest │ dotnet (windows-latest) │ Run actions/setup-dotnet@v6 │ 00:00:31 │
└────────────────┴─────────────────────────┴─────────────────────────────┴──────────┘
```

En Windows y macOS, instalar el SDK de .NET cuesta más que cualquier compilación o prueba. En Ubuntu, donde es más rápido, la compilación y las pruebas de Maven van primero. `j.id, s.number` en el `ORDER BY` de la ventana deshacen los empates: varios steps pueden tardar el mismo número entero de segundos, y sin un criterio de desempate `row_number()` elegiría uno arbitrariamente, quizá uno distinto en la siguiente ejecución.

</details>

## Fuentes

- Tipos [lista](https://duckdb.org/docs/current/sql/data_types/list) y [struct](https://duckdb.org/docs/current/sql/data_types/struct)
- [`unnest`](https://duckdb.org/docs/current/sql/query_syntax/unnest)
- [Funciones de lista](https://duckdb.org/docs/current/sql/functions/list) y [funciones lambda](https://duckdb.org/docs/current/sql/functions/lambda)
- [`FROM` y joins, incluidos `SEMI` y `ANTI`](https://duckdb.org/docs/current/sql/query_syntax/from)
- [Cargar JSON](https://duckdb.org/docs/current/data/json/overview)
- [API REST de GitHub: jobs de workflow](https://docs.github.com/rest/actions/workflow-jobs)
