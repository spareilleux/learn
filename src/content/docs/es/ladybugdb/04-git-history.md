---
title: 4. El historial de Git y las ejecuciones de CI como grafo
description: Cargar los commits, los archivos y las ejecuciones de CI de este repositorio en un grafo, recorrer el historial con caminos largos, encontrar los archivos modificados juntos y relacionar los fallos con los archivos que tocaron — con dos bugs más de LadybugDB 0.20.4 y sus soluciones alternativas.
sidebar:
  order: 4
---

Un segundo grafo, del mismo repositorio: su historial de Git hasta el commit `cbcbb42`, y las ejecuciones de CI de la instantánea del curso de DuckDB. Todas las consultas están en [`cypher/04-git-history.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-git-history.cypher).

## El modelo

| Tabla | Tipo | Origen |
|---|---|---|
| `Commit(sha, committed_at, subject)` | nodo | `commits.csv` |
| `File(path)` | nodo | los archivos distintos de `changes.csv` |
| `PARENT` | relación, de `Commit` a `Commit` | `parents.csv`: cada commit apunta a su padre |
| `CHANGED` | relación, de `Commit` a `File` | `changes.csv` |
| `Run(databaseId, workflowName, conclusion, headBranch)` | nodo | `code/duckdb/data/runs.json` |
| `RAN_ON` | relación, de `Run` a `Commit` | `runs.json`: el commit del que cada ejecución hizo checkout |

En SQL, `PARENT` y `CHANGED` serían tablas de unión, y `RAN_ON` una columna de clave foránea en la tabla de ejecuciones. En el grafo, las tres son relaciones, y una consulta puede seguirlas en un solo patrón.

Las primeras líneas del script crean y cargan la parte de Git ([líneas 3-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L3-L10)):

```cypher
CREATE NODE TABLE Commit(sha STRING PRIMARY KEY, committed_at TIMESTAMP, subject STRING);
CREATE NODE TABLE File(path STRING PRIMARY KEY);
CREATE REL TABLE PARENT(FROM Commit TO Commit);
CREATE REL TABLE CHANGED(FROM Commit TO File);
COPY Commit FROM 'data/commits.csv' (HEADER = true, QUOTE = '"');
COPY File FROM (LOAD FROM 'data/changes.csv' (HEADER = true) RETURN DISTINCT file);
COPY PARENT FROM 'data/parents.csv' (HEADER = true);
COPY CHANGED FROM 'data/changes.csv' (HEADER = true);
```

74 commits, 710 archivos, 73 relaciones `PARENT` y 1.019 relaciones `CHANGED`. El archivo tiene 74 líneas, así que el sniffer de CSV de la lección 2 las lee todas y encuentra por sí solo los asuntos entre comillas; `QUOTE = '"'` solo lo hace explícito, para un historial más largo.

## Marcas de tiempo

[Línea 13](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L13):

```cypher
MATCH (c:Commit) RETURN count(*) AS commits, min(c.committed_at) AS first_commit, max(c.committed_at) AS last_commit;
```

```text
┌─────────┬─────────────────────┬─────────────────────┐
│ commits │ first_commit        │ last_commit         │
│ INT64   │ TIMESTAMP           │ TIMESTAMP           │
├─────────┼─────────────────────┼─────────────────────┤
│ 74      │ 2026-09-13 15:52:51 │ 2026-09-14 16:03:28 │
└─────────┴─────────────────────┴─────────────────────┘
```

El archivo tiene `2026-09-13T11:52:51-04:00`, la hora local del commit con su desfase. [`TIMESTAMP`](https://docs.ladybugdb.com/cypher/data-types/) no tiene zona horaria: LadybugDB convirtió el valor a UTC y descartó el desfase. Todo el historial del sitio, hasta este commit, cabe en poco más de un día.

## Un camino largo que no devuelve nada

Del último commit al primero: un camino de relaciones `PARENT` hasta un commit sin padre ([líneas 16-22](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L16-L22)):

```cypher
MATCH (last:Commit)-[p:PARENT*1..30]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT*1..100]->(first:Commit)
WHERE last.sha STARTS WITH 'cbcbb42' AND NOT EXISTS { MATCH (first)-[:PARENT]->(:Commit) }
RETURN first.subject, length(p) AS commits_between;
```

```text
┌───────────────┬─────────────────┐
│ first.subject │ commits_between │
│ STRING        │ INT64           │
├───────────────┼─────────────────┤
└───────────────┴─────────────────┘
┌───────────────────────────────────────────────────────────────────────┬─────────────────┐
│ first.subject                                                         │ commits_between │
│ STRING                                                                │ INT64           │
├───────────────────────────────────────────────────────────────────────┼─────────────────┤
│ Initial learn site: Starlight, bilingual en/fr, WSL containers course │ 73              │
└───────────────────────────────────────────────────────────────────────┴─────────────────┘
```

**La primera consulta no devuelve ninguna fila, ni ningún error.** El primer commit está a 73 relaciones, más allá de las 30 de `*1..30`: ningún camino encaja en el patrón. Con el límite subido a 100 ([lección 3](../03-paths/#el-límite-de-profundidad)), el mismo patrón lo encuentra. Cuando un patrón de longitud variable no encuentra nada, comprueba su cota superior antes que los datos. Este historial no tiene ramas, así que hay un solo camino: ningún riesgo de la explosión de recorridos de la lección 3.

`STARTS WITH 'cbcbb42'` coincide con el hash abreviado, como `git show cbcbb42`.

## Padres por commit, y un bug en las subconsultas `COUNT`

Un commit de fusión tiene dos padres. ¿Hay alguno? [Líneas 26-27](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L26-L27):

```cypher
MATCH (c:Commit) RETURN COUNT { MATCH (c)-[:PARENT]->(:Commit) } AS parents, count(*) AS commits ORDER BY parents;
MATCH (c:Commit) OPTIONAL MATCH (c)-[:PARENT]->(p:Commit) WITH c, count(p) AS parents RETURN parents, count(*) AS commits ORDER BY parents;
```

```text
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 1       │ 73      │
└─────────┴─────────┘
┌─────────┬─────────┐
│ parents │ commits │
│ INT64   │ INT64   │
├─────────┼─────────┤
│ 0       │ 1       │
│ 1       │ 73      │
└─────────┴─────────┘
```

Ningún commit de fusión: el historial es lineal. Pero la primera consulta cuenta 73 commits de 74. El commit raíz, cuyo `COUNT` es 0, falta en el resultado agrupado, aunque la misma subconsulta devuelve 0 para ese commit cuando la consulta no agrupa por ella. La segunda consulta cuenta lo mismo con `OPTIONAL MATCH` y `count(p)`, y obtiene los dos grupos. Otro bug de la 0.20.4, silencioso como los de las lecciones 2 y 3: cuando una consulta agrupa por una subconsulta `COUNT`, comprueba que la suma de los grupos dé el número de nodos.

## Archivos modificados juntos

Los archivos que cambian en los mismos commits que `astro.config.mjs`, donde se registran los cursos ([líneas 30-33](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L30-L33)):

```cypher
MATCH (a:File {path: 'astro.config.mjs'})<-[:CHANGED]-(c:Commit)-[:CHANGED]->(b:File)
RETURN b.path, count(*) AS commits
ORDER BY commits DESC, b.path
LIMIT 5;
```

```text
┌───────────────────────────────┬─────────┐
│ b.path                        │ commits │
│ STRING                        │ INT64   │
├───────────────────────────────┼─────────┤
│ astro.config.mjs              │ 11      │
│ src/content/docs/fr/index.mdx │ 9       │
│ src/content/docs/index.mdx    │ 9       │
│ AGENTS.md                     │ 7       │
│ README.md                     │ 7       │
└───────────────────────────────┴─────────┘
```

La primera fila es el propio archivo. El patrón tiene dos relaciones `CHANGED`, y nada impide que sean la misma: con la [semántica de recorrido](https://docs.ladybugdb.com/cypher/difference/) de la lección 3, `b` puede ser `a`. `WHERE b <> a` elimina esa fila; las siguientes son las páginas de inicio, que también enumeran los cursos, y `AGENTS.md`, donde viven las convenciones de los cursos. La versión SQL, una autocombinación de la tabla de cambios sobre el commit, tiene la misma trampa y la misma corrección (`b.file <> a.file`).

## Los archivos modificados más a menudo

[Líneas 36-39](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L36-L39):

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN f.path, count(*) AS commits
ORDER BY commits DESC, f.path
LIMIT 5;
```

```text
┌───────────────────────────────────────────────┬─────────┐
│ f.path                                        │ commits │
│ STRING                                        │ INT64   │
├───────────────────────────────────────────────┼─────────┤
│ src/content/docs/fr/wsl-containers/journal.md │ 16      │
│ src/content/docs/wsl-containers/journal.md    │ 15      │
│ README.md                                     │ 13      │
│ astro.config.mjs                              │ 11      │
│ src/content/docs/fr/index.mdx                 │ 9       │
└───────────────────────────────────────────────┴─────────┘
```

El diario del curso WSL containers va primero: 16 commits modificaron el francés, 15 el inglés.

## Ejecuciones de CI: una relación hacia un commit ausente

Las ejecuciones vienen de JSON, así que primero la extensión json ([líneas 42-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L42-L45)):

```cypher
LOAD json;
CREATE NODE TABLE Run(databaseId INT64 PRIMARY KEY, workflowName STRING, conclusion STRING, headBranch STRING);
CREATE REL TABLE RAN_ON(FROM Run TO Commit);
COPY Run FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, workflowName, conclusion, headBranch);
```

125 ejecuciones. Luego las relaciones, del id de la ejecución al commit sobre el que se ejecutó ([líneas 48-52](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L48-L52)):

```cypher
COPY RAN_ON FROM (LOAD FROM '../duckdb/data/runs.json' RETURN databaseId, headSha);
LOAD FROM '../duckdb/data/runs.json'
WITH headBranch, headSha
WHERE NOT EXISTS { MATCH (c:Commit) WHERE c.sha = headSha }
RETURN headBranch, count(*) AS runs;
```

```text
Error: Copy exception: Unable to find primary key value bd17932fe35899909b8d983ab289e1ea4ff344a8.
┌────────────────┬───────┐
│ headBranch     │ runs  │
│ STRING         │ INT64 │
├────────────────┼───────┤
│ gha-06-invalid │ 2     │
└────────────────┴───────┘
```

Dos ejecuciones se ejecutaron sobre un commit de la rama `gha-06-invalid`, una rama temporal del [curso de GitHub Actions](../../github-actions/journal/), usada para probar un workflow no válido sin ponerlo en `main`: sus commits no están en este historial. La respuesta de la lección 2 sería `IGNORE_ERRORS`, pero no está soportado en un `COPY` desde una subconsulta: el intento falla con `bad variant access`. La alternativa obvia es quedarse solo con las ejecuciones cuyo commit existe.

## Un bug de la 0.20.4: un `MATCH` en una subconsulta de `COPY`

Esa alternativa, con un `MATCH` en la subconsulta ([líneas 55-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L55-L61)):

```cypher
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha
  MATCH (c:Commit) WHERE c.sha = headSha
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 1     │ 64      │
└───────┴───────┴─────────┘
```

123 relaciones, el número correcto, hacia los 64 commits correctos, pero **todas desde la misma ejecución**. La subconsulta sola, ejecutada como consulta, devuelve 123 ids de ejecución distintos; dentro de `COPY`, la columna `FROM` de cada relación recibe uno de ellos. El mismo `COPY` funciona con un archivo CSV en lugar de JSON, y con JSON cuando el filtro no usa `MATCH`. La solución alternativa mantiene JSON y filtra por una columna: los dos commits que faltan son los de la otra rama ([líneas 64-71](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L64-L71)):

```cypher
MATCH ()-[x:RAN_ON]->() DELETE x;
COPY RAN_ON FROM (
  LOAD FROM '../duckdb/data/runs.json'
  WITH databaseId, headSha, headBranch
  WHERE headBranch = 'main'
  RETURN databaseId, headSha
);
MATCH (r:Run)-[:RAN_ON]->(c:Commit) RETURN count(*) AS links, count(DISTINCT r) AS runs, count(DISTINCT c) AS commits;
```

```text
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 123 tuples have been copied to the RAN_ON table. │
└──────────────────────────────────────────────────┘
┌───────┬───────┬─────────┐
│ links │ runs  │ commits │
│ INT64 │ INT64 │ INT64   │
├───────┼───────┼─────────┤
│ 123   │ 123   │ 64      │
└───────┴───────┴─────────┘
```

123 enlaces desde 123 ejecuciones. `MATCH ()-[x:RAN_ON]->() DELETE x` borró primero las relaciones erróneas: las relaciones se pueden borrar sin `DETACH`. La consulta de comprobación es lo importante de esta sección: `count(*)` solo era correcto en ambos casos; `count(DISTINCT r)` mostró el bug.

## Los fallos y los archivos que tocaron

Todo el grafo en un solo patrón: ejecuciones, commits, archivos ([líneas 74-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L74-L78)):

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE r.conclusion = 'failure'
RETURN f.path, count(DISTINCT c) AS failed_commits
ORDER BY failed_commits DESC, f.path
LIMIT 5;
```

```text
┌────────────────────────────────────────┬────────────────┐
│ f.path                                 │ failed_commits │
│ STRING                                 │ INT64          │
├────────────────────────────────────────┼────────────────┤
│ .github/workflows/gha-03-triggers.yml  │ 2              │
│ .github/workflows/gha-05-exercises.yml │ 2              │
│ astro.config.mjs                       │ 2              │
│ code/github-actions/.gitignore         │ 2              │
│ src/content/docs/fr/index.mdx          │ 2              │
└────────────────────────────────────────┴────────────────┘
```

`count(DISTINCT c)`, no `count(*)`: un commit con tres ejecuciones fallidas cuenta una vez. Los archivos de workflow de las lecciones de GitHub Actions van primero; los archivos del sitio que los acompañan se modificaron en los mismos commits. Un grafo de cambios muestra qué falló junto, no qué causó el fallo: para eso, los logs de las ejecuciones.

## Ejecuciones por workflow en los commits que modificaron el código del curso

[Líneas 81-84](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-git-history.cypher#L81-L84):

```cypher
MATCH (r:Run)-[:RAN_ON]->(c:Commit)-[:CHANGED]->(f:File)
WHERE f.path STARTS WITH 'code/github-actions/'
RETURN r.workflowName, count(DISTINCT r) AS runs
ORDER BY runs DESC, r.workflowName;
```

```text
┌─────────────────────────────────────┬───────┐
│ r.workflowName                      │ runs  │
│ STRING                              │ INT64 │
├─────────────────────────────────────┼───────┤
│ Deploy to GitHub Pages              │ 2     │
│ GHA 02: build and test              │ 2     │
│ Rust course examples                │ 2     │
│ GHA 01: hello                       │ 1     │
│ GHA 03: triggers                    │ 1     │
│ GHA 04: data between steps and jobs │ 1     │
│ GHA 05: caches and artifacts        │ 1     │
│ GHA 05: exercise checks             │ 1     │
└─────────────────────────────────────┴───────┘
```

Qué workflows desencadenó un cambio en `code/github-actions/`: los workflows de GitHub Actions, pero también el despliegue y los ejemplos del curso de Rust, que se ejecutaron sobre los mismos commits porque otros archivos cambiaron con ellos. `count(DISTINCT r)` otra vez: a una ejecución se llega una vez por cada archivo de su commit.

## Puntos clave

- Un historial de Git es un grafo: los commits, los archivos y las ejecuciones son nodos; los padres, los cambios y «se ejecutó sobre» son relaciones.
- Un patrón de longitud variable cuya cota superior es demasiado pequeña no devuelve nada, sin error.
- `TIMESTAMP` almacena UTC: un desfase en el archivo se aplica y luego se descarta.
- En un patrón con dos relaciones de la misma tabla, ambas pueden ser la misma relación: exclúyela con `WHERE b <> a`.
- Dos bugs silenciosos más de la 0.20.4: agrupar por una subconsulta `COUNT` pierde el grupo cero, y un `MATCH` dentro de una subconsulta de `COPY` desde JSON asigna todas las relaciones a un solo nodo. `IGNORE_ERRORS` tampoco está disponible con subconsultas. `count(DISTINCT …)` en cada extremo es una comprobación barata después de una carga.

## Ejercicios

Las soluciones están en [`cypher/04-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/04-exercises.cypher), comprobadas por la CI. Cargan el mismo grafo, con la solución alternativa de `main` para `RAN_ON`.

1. ¿Qué tres commits modificaron más archivos?

<details>
<summary>Solución</summary>

De [`04-exercises.cypher`, líneas 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L23-L26):

```cypher
MATCH (c:Commit)-[:CHANGED]->(f:File)
RETURN substring(c.sha, 1, 7) AS sha, c.subject, count(*) AS files
ORDER BY files DESC, sha
LIMIT 3;
```

```text
┌─────────┬──────────────────────────────────────────────────────────────┬───────┐
│ sha     │ c.subject                                                    │ files │
│ STRING  │ STRING                                                       │ INT64 │
├─────────┼──────────────────────────────────────────────────────────────┼───────┤
│ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site     │ 160   │
│ f43ba7e │ Import Streeling University modules from Demerzel            │ 103   │
│ 529c946 │ Java for C# developers: lessons 1-4, tested code and journal │ 80    │
└─────────┴──────────────────────────────────────────────────────────────┴───────┘
```

El commit que añadió la configuración regional española añadió 75 páginas en español de una vez. `substring(c.sha, 1, 7)` es el hash abreviado.

</details>

2. ¿Cuántos commits antes de `cbcbb42` se modificó `AGENTS.md` por última vez, y en qué commit?

<details>
<summary>Solución</summary>

De [`04-exercises.cypher`, líneas 29-34](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L29-L34):

```cypher
CALL var_length_extend_max_depth = 100;
MATCH (last:Commit)-[p:PARENT* SHORTEST 1..100]->(c:Commit)-[:CHANGED]->(:File {path: 'AGENTS.md'})
WHERE last.sha STARTS WITH 'cbcbb42'
RETURN length(p) AS commits_before, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY commits_before
LIMIT 1;
```

```text
┌────────────────┬─────────┬──────────────────────────────────────────────────────────┐
│ commits_before │ sha     │ c.subject                                                │
│ INT64          │ STRING  │ STRING                                                   │
├────────────────┼─────────┼──────────────────────────────────────────────────────────┤
│ 42             │ d32b186 │ Java lessons 5-8 and a Spanish locale for the whole site │
└────────────────┴─────────┴──────────────────────────────────────────────────────────┘
```

42 commits: `git log --oneline cbcbb42` muestra `d32b186` en la posición 43. `SHORTEST` encuentra un camino por cada commit que modificó `AGENTS.md`, y `ORDER BY … LIMIT 1` se queda con el más cercano. El límite de 100 vuelve a ser necesario: el historial es más largo que 30. La cota inferior 1 excluye al propio `cbcbb42`, que de todos modos no modificó el archivo.

</details>

3. ¿Qué commits no tienen ninguna ejecución de CI? Para cada uno, ¿cuánto tiempo pasó hasta el commit siguiente, y tuvo este ejecuciones?

<details>
<summary>Solución</summary>

De [`04-exercises.cypher`, líneas 37-45](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/04-exercises.cypher#L37-L45):

```cypher
MATCH (c:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(c) }
RETURN c.committed_at, substring(c.sha, 1, 7) AS sha, c.subject
ORDER BY c.committed_at;
MATCH (c:Commit)-[:PARENT]->(p:Commit)
WHERE NOT EXISTS { MATCH (:Run)-[:RAN_ON]->(p) }
RETURN substring(p.sha, 1, 7) AS without_runs, substring(c.sha, 1, 7) AS next_commit, c.committed_at - p.committed_at AS gap,
       COUNT { MATCH (:Run)-[:RAN_ON]->(c) } AS next_commit_runs
ORDER BY without_runs;
```

```text
┌─────────────────────┬─────────┬──────────────────────────────────────────────────────────────────────────────────────┐
│ c.committed_at      │ sha     │ c.subject                                                                            │
│ TIMESTAMP           │ STRING  │ STRING                                                                               │
├─────────────────────┼─────────┼──────────────────────────────────────────────────────────────────────────────────────┤
│ 2026-09-13 17:13:23 │ 00f2ca4 │ Rust course: lessons 9-12 (lifetimes, modules, smart pointers, threads)              │
│ 2026-09-14 14:08:24 │ 3f3b219 │ DuckDB course: data snapshot of this repository's runs, lesson 1 SQL, CI on 3 OSes   │
│ 2026-09-14 14:24:14 │ 742c967 │ DuckDB course: SQL and expected output for lessons 1-4 and their exercises           │
│ 2026-09-14 14:25:34 │ 36207da │ DuckDB course: don't compare Parquet compressed sizes, they differ on macOS arm64    │
│ 2026-09-14 14:43:42 │ 3e9530f │ DuckDB course: mission, lessons 1-4 and journal (en/fr/es)                           │
│ 2026-09-14 15:13:02 │ a96fd27 │ DuckDB course: lesson 5 C# program (DuckDB.NET, Dapper) and CI on 3 OSes             │
│ 2026-09-14 15:16:11 │ 5a26d1a │ DuckDB course: lesson 6 Java program (JDBC) and CI on 3 OSes                         │
│ 2026-09-14 15:33:19 │ bdf2692 │ DuckDB course: lesson 7 scripts (plans, pushdown, row groups) and CI timings         │
│ 2026-09-14 15:48:40 │ 86e34d9 │ DuckDB course: lesson 7 exercises, lesson 8 persistence script and Java transactions │
│ 2026-09-14 16:03:28 │ cbcbb42 │ DuckDB course: lessons 5-8 (C#, Java, performance, persistence) in en/fr/es          │
└─────────────────────┴─────────┴──────────────────────────────────────────────────────────────────────────────────────┘
┌──────────────┬─────────────┬──────────┬──────────────────┐
│ without_runs │ next_commit │ gap      │ next_commit_runs │
│ STRING       │ STRING      │ INTERVAL │ INT64            │
├──────────────┼─────────────┼──────────┼──────────────────┤
│ 00f2ca4      │ 95a42da     │ 00:00:00 │ 2                │
│ 36207da      │ 3e9530f     │ 00:18:08 │ 0                │
│ 3e9530f      │ a96fd27     │ 00:29:20 │ 0                │
│ 3f3b219      │ 742c967     │ 00:15:50 │ 0                │
│ 5a26d1a      │ bdf2692     │ 00:17:08 │ 0                │
│ 742c967      │ 36207da     │ 00:01:20 │ 0                │
│ 86e34d9      │ cbcbb42     │ 00:14:48 │ 0                │
│ a96fd27      │ 5a26d1a     │ 00:03:09 │ 0                │
│ bdf2692      │ 86e34d9     │ 00:15:21 │ 0                │
└──────────────┴─────────────┴──────────┴──────────────────┘
```

Dos razones. Nueve commits son posteriores a la instantánea de las ejecuciones, cuya última ejecución se creó a las 14:01 UTC: tuvieron ejecuciones, después de tomar la instantánea. `00f2ca4` es el otro caso: `95a42da` lo siguió en el mismo segundo, se subieron juntos con un push, y GitHub Actions ejecuta los workflows de un push solo sobre su último commit. Restar dos valores `TIMESTAMP` da un `INTERVAL`. `cbcbb42` no tiene hijo en este historial, así que no está en el segundo resultado.

</details>

## Fuentes

- [Tipos de datos](https://docs.ladybugdb.com/cypher/data-types/): `TIMESTAMP`, `INTERVAL`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): relaciones de longitud variable y caminos más cortos
- [`COPY FROM` desde una subconsulta](https://docs.ladybugdb.com/import/copy-from-subquery/) y [extensión JSON](https://docs.ladybugdb.com/extensions/json/)
- [Subconsultas](https://docs.ladybugdb.com/cypher/subquery/) y [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/)
- [Diferencias entre LadybugDB y Neo4j](https://docs.ladybugdb.com/cypher/difference/)
- [Eventos que desencadenan workflows: `push`](https://docs.github.com/actions/reference/workflows-and-actions/events-that-trigger-workflows#push)
