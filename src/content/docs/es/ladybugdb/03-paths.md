---
title: 3. Caminos
description: Patrones de varios saltos, OPTIONAL MATCH y subconsultas COUNT, luego relaciones de longitud variable — recorridos, senderos y caminos acíclicos —, caminos más cortos, filtros a lo largo de un camino y el límite de profundidad, comprobados con una CTE recursiva.
sidebar:
  order: 3
---

El grafo de la lección 2, nodos `Page` y relaciones `LINKS_TO`, se carga al principio de [`cypher/03-paths.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-paths.cypher) con las mismas sentencias `COPY`. Esta lección le hace preguntas sobre caminos (*paths*): cuántos clics, a través de qué páginas.

## Varios saltos

Un patrón puede encadenar relaciones. Las lecciones del curso de DuckDB, alcanzadas desde la página de inicio a través del índice del curso ([líneas 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L9-L12)):

```cypher
MATCH (home:Page {url: '/'})-[:LINKS_TO]->(course:Page)-[:LINKS_TO]->(lesson:Page)
WHERE course.course = 'duckdb'
RETURN course.url, lesson.url
ORDER BY lesson.url;
```

```text
┌────────────┬───────────────────────────┐
│ course.url │ lesson.url                │
│ STRING     │ STRING                    │
├────────────┼───────────────────────────┤
│ /duckdb/   │ /duckdb/01-first-queries/ │
│ /duckdb/   │ /duckdb/02-friendly-sql/  │
│ /duckdb/   │ /duckdb/03-nested-data/   │
│ /duckdb/   │ /duckdb/04-files/         │
│ /duckdb/   │ /duckdb/05-csharp/        │
│ /duckdb/   │ /duckdb/06-java/          │
│ /duckdb/   │ /duckdb/07-performance/   │
│ /duckdb/   │ /duckdb/08-persistence/   │
│ /duckdb/   │ /duckdb/journal/          │
│ /duckdb/   │ /github-actions/          │
└────────────┴───────────────────────────┘
```

En SQL, dos joins de la tabla de enlaces consigo misma, y dos joins con las páginas. La última fila no es una lección de DuckDB: el índice de DuckDB enlaza al curso de GitHub Actions, cuyas ejecuciones consulta. El filtro está en la página del medio, no en la lección.

## `OPTIONAL MATCH`: el `LEFT JOIN`

`MATCH` descarta las filas donde el patrón no encaja. [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) las conserva con `NULL`, como un `LEFT JOIN` ([líneas 15-20](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L15-L20)):

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND p.course = 'github-actions'
OPTIONAL MATCH (p)-[:LINKS_TO]->(target:Page)
RETURN p.url, count(target) AS links
ORDER BY links, p.url
LIMIT 4;
```

```text
┌────────────────────────────────────┬───────┐
│ p.url                              │ links │
│ STRING                             │ INT64 │
├────────────────────────────────────┼───────┤
│ /github-actions/journal/           │ 0     │
│ /github-actions/02-build-and-test/ │ 1     │
│ /github-actions/09-debugging/      │ 1     │
│ /github-actions/01-first-workflow/ │ 2     │
└────────────────────────────────────┴───────┘
```

`count(target)` cuenta los valores no `NULL`, así que el diario, que no enlaza a ninguna página del sitio, obtiene 0. Con `MATCH` en lugar de `OPTIONAL MATCH`, faltaría en el resultado; con `count(*)`, contaría 1.

## Subconsultas `COUNT`

Las páginas en inglés con al menos cinco enlaces entrantes. Una [subconsulta `COUNT { … }`](https://docs.ladybugdb.com/cypher/subquery/) cuenta las filas de un patrón para cada página, en el filtro y en el resultado ([líneas 23-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L23-L26)):

```cypher
MATCH (p:Page)
WHERE p.locale = 'en' AND COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } >= 5
RETURN p.url, COUNT { MATCH (:Page)-[:LINKS_TO]->(p) } AS incoming
ORDER BY incoming DESC, p.url;
```

```text
┌──────────────────────────────────────────────────────┬──────────┐
│ p.url                                                │ incoming │
│ STRING                                               │ INT64    │
├──────────────────────────────────────────────────────┼──────────┤
│ /streeling/journal/                                  │ 32       │
│ /wsl-containers/journal/                             │ 13       │
│ /streeling/music/mus-001-what-is-a-chord/            │ 8        │
│ /github-actions/01-first-workflow/                   │ 6        │
│ /github-actions/05-caches-and-artifacts/             │ 6        │
│ /github-actions/07-security/                         │ 6        │
│ /streeling/guitar-studies/gtr-001-the-fretboard-map/ │ 6        │
│ /github-actions/04-expressions-and-outputs/          │ 5        │
└──────────────────────────────────────────────────────┴──────────┘
```

Es la subconsulta correlacionada `(SELECT count(*) FROM links WHERE target = p.url)` de SQL. El diario de Streeling va primero: 32 páginas de Streeling en inglés enlazan a él.

## Longitud variable: recorridos (*walks*)

`-[e:LINKS_TO*1..4]->` coincide con una cadena de 1 a 4 relaciones `LINKS_TO`. Todas las formas de ir del índice de GitHub Actions a su lección 7 en cuatro clics como máximo ([líneas 29-31](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L29-L31)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 5     │
│ 3     │ 12    │
│ 4     │ 29    │
└───────┴───────┘
```

`e` es la cadena entera, una *relación recursiva*, y [`length(e)`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) su número de relaciones.

**Por defecto, la cadena es un recorrido: puede pasar varias veces por la misma página, e incluso por el mismo enlace.** Entre los 29 recorridos de cuatro enlaces, algunos van a la lección 7, la dejan por otra lección y vuelven. Es la principal [diferencia con Neo4j](https://docs.ladybugdb.com/cypher/difference/), cuyos patrones nunca repiten una relación. También es lo que hace necesaria la cota superior: en un grafo con ciclos, el número de recorridos crece sin fin.

El mismo recuento en SQL, con una CTE recursiva en DuckDB ([`sql/03-walks.sql`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/sql/03-walks.sql), también comparado por la CI):

```sql
WITH RECURSIVE
  links AS (
    SELECT l."from" AS source, l."to" AS target
    FROM 'data/links.csv' l
    WHERE l."to" IN (SELECT url FROM 'data/pages.csv')
  ),
  walks(page, length) AS (
    SELECT target, 1 FROM links WHERE source = '/github-actions/'
    UNION ALL
    SELECT links.target, walks.length + 1
    FROM walks JOIN links ON links.source = walks.page
    WHERE walks.length < 4
  )
SELECT length AS links, count(*) AS walks
FROM walks
WHERE page = '/github-actions/07-security/'
GROUP BY length
ORDER BY length;
```

```text
links,walks
1,1
2,5
3,12
4,29
```

Los mismos números. Una CTE recursiva también calcula recorridos: no recuerda por dónde ha pasado, y el `WHERE walks.length < 4` es su cota superior. El filtro `IN` descarta los 64 enlaces a páginas inexistentes, que `COPY … IGNORE_ERRORS` omitió en LadybugDB.

## Senderos (*trails*) y caminos acíclicos

`TRAIL` después del asterisco prohíbe repetir una relación ([líneas 34-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L34-L36)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO* TRAIL 1..4]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS trails
ORDER BY links;
```

```text
┌───────┬────────┐
│ links │ trails │
│ INT64 │ INT64  │
├───────┼────────┤
│ 1     │ 1      │
│ 2     │ 5      │
│ 3     │ 12     │
│ 4     │ 26     │
└───────┴────────┘
```

Tres recorridos de cuatro enlaces toman un enlace dos veces. Índice → lección 1 → lección 7 → lección 1 → lección 7 toma dos veces el enlace de la lección 1 a la lección 7. Índice → lección 4 → lección 7 → lección 4 → lección 7 hace lo mismo con el enlace de la lección 4 a la lección 7, y cuenta dos veces, porque la lección 7 enlaza a la lección 4 en dos sitios: dos relaciones, dos recorridos. Para prohibir repetir una *página*, la función de camino [`is_acyclic`](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) filtra el camino entero, nombrado con `p =` ([líneas 40-43](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L40-L43)):

```cypher
MATCH p = (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4]->(b:Page {url: '/github-actions/07-security/'})
WHERE is_acyclic(p)
RETURN length(e) AS links, count(*) AS acyclic_paths
ORDER BY links;
```

```text
┌───────┬───────────────┐
│ links │ acyclic_paths │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 1     │ 1             │
│ 2     │ 5             │
│ 3     │ 9             │
│ 4     │ 10            │
└───────┴───────────────┘
```

De 29 recorridos a 10 caminos que nunca visitan dos veces una página, ambos extremos incluidos. Un script de Python que enumera los caminos de `links.csv` encuentra los mismos 29, 26 y 10.

La [documentación de `MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) también tiene una palabra clave `ACYCLIC`, que se usa como `TRAIL` y solo comprueba los nodos entre los dos extremos: aquí debería encontrar 25 caminos de cuatro enlaces. **No lo hace en 0.20.4**: `LINKS_TO* ACYCLIC 1..4` devuelve 14 en Windows, incluido un camino que pasa dos veces por la misma página, y 29, todos los recorridos, en Linux y macOS. Por eso esta lección usa `is_acyclic`; el [diario](../journal/) tiene los detalles.

## Caminos más cortos

`SHORTEST` conserva, para cada par de nodos, un camino de longitud mínima. Cuántos clics hay desde la página de inicio hasta cada página en inglés ([líneas 46-56](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L46-L56)):

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en'
RETURN length(e) AS clicks, count(*) AS pages
ORDER BY clicks;

MATCH (p:Page)
WHERE p.locale = 'en' AND p.url <> '/'
  AND NOT EXISTS { MATCH (:Page {url: '/'})-[:LINKS_TO* SHORTEST 1..10]->(p) }
RETURN p.url
ORDER BY p.url;
```

```text
┌────────┬───────┐
│ clicks │ pages │
│ INT64  │ INT64 │
├────────┼───────┤
│ 1      │ 7     │
│ 2      │ 77    │
│ 3      │ 32    │
└────────┴───────┘
┌────────┐
│ p.url  │
│ STRING │
├────────┤
└────────┘
```

7 + 77 + 32 = 116: todas las páginas en inglés salvo la propia página de inicio están a tres clics como máximo, y la segunda consulta, vacía, confirma que ninguna es inalcanzable. La misma pregunta en SQL es una CTE recursiva que conserva la longitud mínima por página y que hay que detener a mano; en LadybugDB, es una palabra clave.

¿Qué páginas hay en el camino? [Líneas 59-63](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L59-L63):

```cypher
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN length(e) AS links, size(nodes(e)) AS pages_between;
MATCH (a:Page {url: '/github-actions/09-debugging/'})-[e:LINKS_TO* ALL SHORTEST 1..10]->(b:Page {url: '/github-actions/02-build-and-test/'})
RETURN cast(properties(nodes(e), 'url') AS STRING) AS through
ORDER BY through;
```

```text
┌───────┬───────────────┐
│ links │ pages_between │
│ INT64 │ INT64         │
├───────┼───────────────┤
│ 4     │ 3             │
└───────┴───────────────┘
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ through                                                                                                                   │
│ STRING                                                                                                                    │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ [/github-actions/04-expressions-and-outputs/,/github-actions/01-first-workflow/,/github-actions/05-caches-and-artifacts/] │
│ [/github-actions/04-expressions-and-outputs/,/github-actions/07-security/,/github-actions/05-caches-and-artifacts/]       │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

- `nodes(e)` devuelve los nodos *entre* los dos extremos, no los extremos: 3 páginas para 4 enlaces.
- `properties(nodes(e), 'url')` extrae una propiedad de una lista de nodos, como `STRING[]`.
- `ALL SHORTEST` devuelve todos los caminos de longitud mínima: dos aquí, que se diferencian por la página del medio.
- La primera consulta no devuelve las páginas de su camino: con dos candidatos, cuál elige `SHORTEST` no está especificado, y una salida comparada no puede depender de ello. El cast a `STRING` está ahí porque `ORDER BY` sobre un `STRING[]` falla en 0.20.4 (`Binder exception`).

## Dirección

De una lección de DuckDB al curso de Rust ([líneas 66-69](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L66-L69)):

```cypher
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]->(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
MATCH (a:Page {url: '/duckdb/04-files/'})-[e:LINKS_TO* SHORTEST 1..10]-(b:Page {url: '/rust-for-csharp-java/'})
RETURN length(e) AS links;
```

```text
┌───────┐
│ links │
│ INT64 │
├───────┤
└───────┘
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 3     │
└───────┘
```

Siguiendo los enlaces, el curso de Rust no se puede alcanzar desde esa lección: el Markdown de ninguna página enlaza de vuelta a la página de inicio (la cabecera del sitio sí, pero no está en los datos). Sin la punta de flecha, `-[…]-`, las relaciones se pueden seguir en ambas direcciones, y bastan tres pasos: la lección está enlazada *desde* el índice de DuckDB, que está enlazado desde la página de inicio, que enlaza al curso de Rust.

## Un filtro en cada paso

Una relación de longitud variable puede filtrar las relaciones y los nodos por los que pasa: `(r, n | WHERE …)`, donde `r` representa cada relación y `n` cada nodo intermedio. Los dos extremos no se filtran: con `n.url <> '/github-actions/'`, la consulta de abajo sigue encontrando sus recorridos. Los recorridos de la primera consulta de longitud variable, sin pasar por la lección 4 ([líneas 72-74](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L72-L74)):

```cypher
MATCH (a:Page {url: '/github-actions/'})-[e:LINKS_TO*1..4 (r, n | WHERE n.url <> '/github-actions/04-expressions-and-outputs/')]->(b:Page {url: '/github-actions/07-security/'})
RETURN length(e) AS links, count(*) AS walks
ORDER BY links;
```

```text
┌───────┬───────┐
│ links │ walks │
│ INT64 │ INT64 │
├───────┼───────┤
│ 1     │ 1     │
│ 2     │ 4     │
│ 3     │ 7     │
│ 4     │ 14    │
└───────┴───────┘
```

De 29 recorridos de cuatro enlaces a 14, el recuento que también encuentra el script de Python.

## El límite de profundidad

[Líneas 77-78](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-paths.cypher#L77-L78):

```cypher
MATCH (a:Page {url: '/'})-[e:LINKS_TO*1..50]->(b:Page {url: '/duckdb/journal/'})
RETURN count(*);
```

```text
Error: Binder exception: Upper bound of rel e exceeds maximum: 30.
```

Una cota superior mayor que 30 se rechaza antes de ejecutar la consulta, y `*` sin cotas significa `*1..30`. El límite es el parámetro `var_length_extend_max_depth` ([`client_config.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)), que `CALL var_length_extend_max_depth = 100;` eleva para la conexión ([configuración](https://docs.ladybugdb.com/cypher/configuration/)). La lección 4 lo necesita: el historial de Git es una cadena de 74 commits. Antes de elevar el límite, pregúntate si quieres recorridos o `SHORTEST`: en mi máquina, los recorridos de la primera consulta con `*` en lugar de `*1..4`, es decir, hasta 30 enlaces, se seguían contando tras cinco minutos, mientras que `* SHORTEST` responde al instante.

## Puntos clave

- `OPTIONAL MATCH` es el `LEFT JOIN`; `COUNT { MATCH … }` y `EXISTS { MATCH … }` son subconsultas correlacionadas.
- `-[:LINKS_TO*1..4]->` coincide por defecto con recorridos: páginas y enlaces pueden repetirse. `TRAIL` prohíbe las relaciones repetidas, `is_acyclic(p)` los nodos repetidos.
- `ACYCLIC` devuelve recuentos erróneos en 0.20.4, y distintos en Windows y en Linux o macOS.
- `SHORTEST` y `ALL SHORTEST` calculan caminos más cortos en el patrón; `nodes(e)` devuelve los nodos entre los extremos.
- Sin punta de flecha, un patrón sigue las relaciones en ambos sentidos; `(r, n | WHERE …)` filtra cada paso.
- La profundidad está limitada a 30 salvo que se eleve `var_length_extend_max_depth`.

## Ejercicios

Las soluciones están en [`cypher/03-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/03-exercises.cypher), comprobadas por la CI.

1. Las 32 páginas en inglés a tres clics de la página de inicio: ¿en qué cursos están?

<details>
<summary>Solución</summary>

De [`03-exercises.cypher`, líneas 9-12](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L9-L12):

```cypher
MATCH (home:Page {url: '/'})-[e:LINKS_TO* SHORTEST 1..10]->(p:Page)
WHERE p.locale = 'en' AND length(e) = 3
RETURN p.course, count(*) AS pages
ORDER BY pages DESC, p.course;
```

```text
┌───────────┬───────┐
│ p.course  │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 31    │
│ method    │ 1     │
└───────────┴───────┘
```

Los módulos de Streeling (página de inicio → índice de Streeling → departamento → módulo) y la página Método, a la que la página de inicio no enlaza directamente. Cada lección de un curso está a dos clics, a través del índice de su curso.

</details>

2. ¿Qué páginas en inglés enlazan a una página de otro curso? Cuenta los enlaces por par de cursos.

<details>
<summary>Solución</summary>

De [`03-exercises.cypher`, líneas 15-18](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L15-L18):

```cypher
MATCH (a:Page)-[:LINKS_TO]->(b:Page)
WHERE a.locale = 'en' AND b.locale = 'en' AND a.course <> b.course AND a.course <> '' AND b.course <> ''
RETURN a.course AS from_course, b.course AS to_course, count(*) AS links
ORDER BY links DESC, from_course, to_course;
```

```text
┌────────────────┬─────────────────┬───────┐
│ from_course    │ to_course       │ links │
│ STRING         │ STRING          │ INT64 │
├────────────────┼─────────────────┼───────┤
│ duckdb         │ github-actions  │ 2     │
│ duckdb         │ java-for-csharp │ 1     │
│ github-actions │ method          │ 1     │
└────────────────┴─────────────────┴───────┘
```

Cuatro enlaces, tres de ellos desde el curso de DuckDB, que se apoya en las ejecuciones de GitHub Actions y remite al curso de Java. Los cursos son islas unidas por la página de inicio: por eso el camino no dirigido de la lección pasa por ella.

</details>

3. A dos enlaces del índice de DuckDB: ¿cuántos recorridos, cuántas páginas distintas? Encuentra la página alcanzada dos veces, y a través de qué páginas.

<details>
<summary>Solución</summary>

De [`03-exercises.cypher`, líneas 21-26](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/03-exercises.cypher#L21-L26):

```cypher
MATCH (a:Page {url: '/duckdb/'})-[:LINKS_TO*2..2]->(b:Page)
RETURN count(*) AS walks, count(DISTINCT b) AS pages;
MATCH (a:Page {url: '/duckdb/'})-[e:LINKS_TO*2..2]->(b:Page)
WITH b, count(*) AS walks, collect(properties(nodes(e), 'url')[1]) AS through
WHERE walks > 1
RETURN b.url, walks, cast(list_sort(through) AS STRING) AS through;
```

```text
┌───────┬───────┐
│ walks │ pages │
│ INT64 │ INT64 │
├───────┼───────┤
│ 16    │ 15    │
└───────┴───────┘
┌──────────────────────────┬───────┬────────────────────────────────────────────┐
│ b.url                    │ walks │ through                                    │
│ STRING                   │ INT64 │ STRING                                     │
├──────────────────────────┼───────┼────────────────────────────────────────────┤
│ /github-actions/journal/ │ 2     │ [/duckdb/03-nested-data/,/github-actions/] │
└──────────────────────────┴───────┴────────────────────────────────────────────┘
```

16 recorridos alcanzan 15 páginas: el diario de GitHub Actions se alcanza a través de la lección 3 de DuckDB y a través del índice de GitHub Actions. `WITH … WHERE` filtra sobre un agregado, el `HAVING` de SQL. Las listas se indexan desde 1, así que `[1]` es la única página entre los dos extremos; `collect` las reúne en una lista, y `list_sort` hace estable la salida.

</details>

## Fuentes

- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): relaciones de longitud variable, semántica de caminos, caminos más cortos, filtros
- [`OPTIONAL MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/optional-match/) y [subconsultas](https://docs.ladybugdb.com/cypher/subquery/)
- [Funciones de relaciones recursivas](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/): `length`, `nodes`, `is_trail`, `is_acyclic`
- [Diferencias entre LadybugDB y Neo4j](https://docs.ladybugdb.com/cypher/difference/): semántica de recorridos, cota superior por defecto
- [Configuración](https://docs.ladybugdb.com/cypher/configuration/): `var_length_extend_max_depth`
- [CTE recursivas de DuckDB](https://duckdb.org/docs/current/sql/query_syntax/with)
