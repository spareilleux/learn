---
title: 2. Cargar archivos
description: Mirar archivos CSV con LOAD FROM, cargar nodos y relaciones con COPY, conservar como avisos las filas que no encajan, llenar tablas desde una subconsulta y cargar JSON con la extensión json.
sidebar:
  order: 2
---

El sitio como grafo: un nodo `Page` por página, una relación `LINKS_TO` por enlace entre dos páginas. Los datos son los seis archivos CSV descritos en la [página Misión](../#los-datos); todas las consultas de esta lección están en [`cypher/02-loading.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-loading.cypher).

## Mirar un archivo antes de cargarlo

[`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/) lee un archivo como filas, sin crear nada, como `OPENROWSET(BULK …)` en SQL Server o `FROM 'file.csv'` en DuckDB ([líneas 5-6](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L5-L6)):

```cypher
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN * ORDER BY url LIMIT 3;
LOAD FROM 'data/pages.csv' (HEADER = true) RETURN locale, count(*) AS pages ORDER BY locale;
```

```text
┌─────────────┬────────┬───────────┬──────────────────┬───────┐
│ url         │ locale │ course    │ title            │ lines │
│ STRING      │ STRING │ STRING    │ STRING           │ INT64 │
├─────────────┼────────┼───────────┼──────────────────┼───────┤
│ /           │ en     │           │ learn            │ 90    │
│ /artifacts/ │ en     │ artifacts │ Artifacts        │ 32    │
│ /duckdb/    │ en     │ duckdb    │ DuckDB — Mission │ 70    │
└─────────────┴────────┴───────────┴──────────────────┴───────┘
┌────────┬───────┐
│ locale │ pages │
│ STRING │ INT64 │
├────────┼───────┤
│ en     │ 117   │
│ es     │ 101   │
│ fr     │ 101   │
└────────┴───────┘
```

`HEADER = true` indica que la primera línea contiene los nombres de las columnas; en este archivo, la detección automática también la habría encontrado. Los tipos se adivinan a partir del contenido: `lines` es un `INT64`. La página de inicio `/` no tiene curso: su `course` está vacío.

## Cargar nodos: `COPY FROM`

Las tablas, y luego [`COPY`](https://docs.ladybugdb.com/import/csv/), la carga masiva ([líneas 8-10](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L8-L10)):

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/pages.csv' (HEADER = true);
```

```text
┌────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                         │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                         │ INT64                      │ STRING[]              │
├────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 319 tuples have been copied to the Page table. │ 0                          │ []                    │
└────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
```

Las columnas del archivo van a las columnas de la tabla en orden; los nombres de la cabecera no tienen por qué coincidir. Las dos últimas columnas del resultado cuentan y listan las filas omitidas porque su clave ya estaba en la tabla, con la opción `SKIP_DUPLICATE_PK = true` ([`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111), no está en la documentación). Ejecutado dos veces sobre `pages.csv` con esa opción, `COPY` copia 0 filas y lista las 319 URL; sin ella, la segunda ejecución falla, y la última sección de esta lección muestra lo que ese fallo le hace a la tabla.

## Una relación necesita sus dos nodos

En `links.csv`, cada fila es un enlace: la página en la que está, la página a la que apunta y el ancla después de `#`, si la hay. Para una tabla de relaciones, las dos primeras columnas son las claves primarias de los nodos `FROM` y `TO`; el resto llena las columnas propias de la relación ([líneas 14-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L14-L16)):

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/.
┌───────┐
│ links │
│ INT64 │
├───────┤
│ 0     │
└───────┘
```

Un enlace apunta a una página que no está en `pages.csv`, y todo el `COPY` falla: cero enlaces cargados, ni siquiera las filas anteriores a la incorrecta. `COPY` es todo o nada, como un `BULK INSERT` dentro de una transacción.

¿Por qué `CALL threads = 1`? `COPY` lee el archivo con varios hilos (24 en mi máquina, siendo el [valor por defecto](https://docs.ladybugdb.com/cypher/configuration/) todos los núcleos), y se detiene en la primera página que falta que encuentra *un hilo*. Dos ejecuciones dieron dos páginas distintas en el mensaje. Con un solo hilo, siempre es la primera fila incorrecta del archivo, la línea 127, y la salida se puede comparar en la CI.

## Conservar las filas que no encajan: `IGNORE_ERRORS`

Con `IGNORE_ERRORS = true`, `COPY` omite las filas incorrectas y guarda un aviso por cada una ([líneas 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L19-L21)):

```cypher
COPY LINKS_TO FROM 'data/links.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN count(*) AS warnings;
CALL show_warnings() RETURN message, file_path, line_number ORDER BY line_number LIMIT 2;
```

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ result                                                                                                            │
│ STRING                                                                                                            │
├───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ 648 tuples have been copied to the LINKS_TO table.                                                                │
│ 64 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 8 │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
┌──────────┐
│ warnings │
│ INT64    │
├──────────┤
│ 64       │
└──────────┘
┌──────────────────────────────────────────────────────────────────────────────────────────────────┬────────────────┬─────────────┐
│ message                                                                                          │ file_path      │ line_number │
│ STRING                                                                                           │ STRING         │ UINT64      │
├──────────────────────────────────────────────────────────────────────────────────────────────────┼────────────────┼─────────────┤
│ Unable to find primary key value /es/streeling/computer-science/cs-001-governing-agentic-loops/. │ data/links.csv │ 127         │
│ Unable to find primary key value /es/streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/.   │ data/links.csv │ 129         │
└──────────────────────────────────────────────────────────────────────────────────────────────────┴────────────────┴─────────────┘
```

648 + 64 = 712, todas las filas del archivo. `show_warnings()` también devuelve el identificador de la consulta y la propia línea omitida. Los avisos se quedan en la conexión hasta `CALL clear_warnings()`, hasta el límite de `warning_limit`, 8.192 por defecto.

Los 64 mensajes contienen la URL que falta después de `value `. Para agruparlos por locale, divide la URL por `/` ([líneas 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L24-L28)):

```cypher
RETURN split_part('/es/streeling/', '/', 1) AS part_1, split_part('/es/streeling/', '/', 2) AS part_2;
CALL show_warnings()
WITH split_part(message, 'value ', 2) AS missing
RETURN split_part(missing, '/', 1) AS locale, split_part(missing, '/', 2) AS course, count(*) AS links
ORDER BY locale, course;
```

```text
┌────────┬───────────┐
│ part_1 │ part_2    │
│ STRING │ STRING    │
├────────┼───────────┤
│ es     │ streeling │
└────────┴───────────┘
┌────────┬───────────┬───────┐
│ locale │ course    │ links │
│ STRING │ STRING    │ INT64 │
├────────┼───────────┼───────┤
│ es     │ streeling │ 32    │
│ fr     │ streeling │ 32    │
└────────┴───────────┴───────┘
```

**La parte 1 de `/es/streeling/` es `es`**: el [`split_part`](https://docs.ladybugdb.com/cypher/expressions/text-functions/) de LadybugDB ignora la cadena vacía antes de la `/` inicial. DuckDB y PostgreSQL devuelven esa cadena vacía como parte 1, y `es` como parte 2. Mi primera versión de esta consulta usaba 2 y 3, y agrupaba por curso bajo una columna llamada `locale`; la primera consulta de arriba está ahí para detectarlo.

`WITH` pasa filas de una parte de la consulta a la siguiente, como una CTE: aquí, la URL `missing` calculada una sola vez para las dos llamadas a `split_part`.

Las 64 páginas que faltan son todas módulos de la Universidad Streeling en francés y en español. [Starlight](https://starlight.astro.build/guides/i18n/#fallback-content) sirve la página en inglés en una URL traducida que no tiene página propia, así que estos enlaces funcionan en el sitio, pero no hay archivo en francés ni en español para estos módulos, ni nodo.

## Archivos y grafo en la misma consulta

¿A qué páginas en inglés apuntan esos enlaces franceses? La consulta vuelve a leer `links.csv` y contrasta cada fila con el grafo ([líneas 31-36](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L31-L36)):

```cypher
LOAD FROM 'data/links.csv' (HEADER = true)
WITH `from`, `to`
WHERE `to` STARTS WITH '/fr/' AND NOT EXISTS { MATCH (p:Page) WHERE p.url = `to` }
MATCH (en:Page) WHERE en.url = substring(`to`, 4, size(`to`))
RETURN DISTINCT en.url AS english_page
ORDER BY english_page;
```

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ english_page                                                            │
│ STRING                                                                  │
├─────────────────────────────────────────────────────────────────────────┤
│ /streeling/computer-science/cs-001-governing-agentic-loops/             │
│ /streeling/cybernetics/cyb-001-vsm-ai-governance-mapping/               │
│ /streeling/cybernetics/cyb-002-active-dampening-cross-repo-oscillation/ │
│ /streeling/cybernetics/cyb-003-measuring-variety-ratio-quantitatively/  │
│ /streeling/guitar-alchemist-academy/gaa-002-training-your-ear/          │
│ /streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/  │
│ /streeling/information-theory/inf-001-entropy-of-governance/            │
│ /streeling/music/mus-002-beyond-tonality/                               │
│ /streeling/music/mus-003-functional-harmony/                            │
│ /streeling/music/mus-004-rhythm-and-groove/                             │
│ /streeling/music/mus-005-jazz-harmony/                                  │
│ /streeling/music/mus-006-the-scale-universe/                            │
│ /streeling/musicology/mcl-002-musical-form/                             │
│ /streeling/network-science/net-001-scale-free-tool-networks/            │
│ /streeling/psychohistory/psy-002-governance-phase-transitions/          │
│ /streeling/semiotics/sem-001-signs-in-governance/                       │
└─────────────────────────────────────────────────────────────────────────┘
```

Tres cosas en esta consulta:

- Las comillas invertidas delimitan un nombre, como los corchetes en T-SQL. `from` y `to` funcionarían sin ellas en esta consulta, pero son palabras clave de `CREATE REL TABLE … (FROM Page TO Page)`, y delimitarlos evita la duda.
- `substring` cuenta desde 1, como SQL: `substring('/fr/streeling/…', 4, …)` empieza en la `/` después de `fr`.
- Una consulta puede empezar en un archivo y continuar en el grafo: `LOAD FROM`, luego `WITH … WHERE`, luego `MATCH`. Para cada fila del archivo que queda tras el filtro, `MATCH` encuentra la página en inglés.

## Tablas de nodos desde una subconsulta

Los enlaces externos, las 3.712 filas de `external_links.csv` (`from`, `url`, `domain`), se convierten en un nodo `Domain` por sitio y una relación `CITES` por página y sitio, con el número de enlaces como propiedad. [`COPY` puede leer una subconsulta](https://docs.ladybugdb.com/import/copy-from-subquery/) en lugar de un archivo ([líneas 39-41](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L39-L41)):

```cypher
CREATE NODE TABLE Domain(name STRING PRIMARY KEY);
CREATE REL TABLE CITES(FROM Page TO Domain, links INT64);
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true) RETURN DISTINCT domain);
```

```text
Error: Copy exception: Error in file data/external_links.csv on line 591: expected 3 values per row, but got more. Line/record containing the error: '/es/java-for-csharp/02-types-and-operators/,"https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/Math.html#addExact(int,int)",docs.oracle.com'
```

La línea 591 es la primera línea del archivo con comillas: el módulo `csv` de Python solo pone entre comillas los campos que lo necesitan, como esta URL con una coma en `addExact(int,int)`. Por defecto, LadybugDB detecta el delimitador, el carácter de comillas y el de escape a partir de las primeras 256 líneas del archivo ([`auto_detect` y `sample_size`](https://docs.ladybugdb.com/import/csv/), [`constants.h`](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144)). No vio ninguna comilla en esas líneas, leyó el archivo sin ellas y encontró cuatro campos en la línea 591. Indícalo explícitamente ([líneas 44-46](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L44-L46)):

```cypher
COPY Domain FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN DISTINCT domain);
COPY CITES FROM (LOAD FROM 'data/external_links.csv' (HEADER = true, QUOTE = '"') RETURN `from`, domain, count(*));
MATCH (d:Domain) RETURN count(*) AS domains;
```

```text
┌─────────────────────────────────────────────────┬────────────────────────────┬───────────────────────┐
│ result                                          │ skipped_duplicate_pk_count │ skipped_duplicate_pks │
│ STRING                                          │ INT64                      │ STRING[]              │
├─────────────────────────────────────────────────┼────────────────────────────┼───────────────────────┤
│ 85 tuples have been copied to the Domain table. │ 0                          │ []                    │
└─────────────────────────────────────────────────┴────────────────────────────┴───────────────────────┘
┌──────────────────────────────────────────────────┐
│ result                                           │
│ STRING                                           │
├──────────────────────────────────────────────────┤
│ 1054 tuples have been copied to the CITES table. │
└──────────────────────────────────────────────────┘
┌─────────┐
│ domains │
│ INT64   │
├─────────┤
│ 85      │
└─────────┘
```

Las columnas de la subconsulta hacen el papel de las del archivo: `from` y `domain` son las claves de los dos nodos, `count(*)` llena `links`. 1.054 pares de una página y un sitio.

## Qué sitios citan las páginas de los cursos

[Líneas 47-51](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L47-L51):

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(*) AS pages, sum(c.links) AS links
ORDER BY links DESC, domain
LIMIT 8;
```

```text
┌─────────────────────┬───────┬────────┐
│ domain              │ pages │ links  │
│ STRING              │ INT64 │ INT128 │
├─────────────────────┼───────┼────────┤
│ learn.microsoft.com │ 44    │ 198    │
│ doc.rust-lang.org   │ 16    │ 192    │
│ github.com          │ 88    │ 189    │
│ docs.oracle.com     │ 28    │ 171    │
│ duckdb.org          │ 9     │ 140    │
│ docs.github.com     │ 12    │ 51     │
│ openjdk.org         │ 15    │ 49     │
│ docs.rs             │ 5     │ 30     │
└─────────────────────┴───────┴────────┘
```

Una variable de relación, `c`, da acceso a las propiedades de la relación como una variable de nodo. `sum` de un `INT64` devuelve un `INT128`, un tipo más amplio. GitHub es el sitio citado por más páginas; Microsoft Learn, por más enlaces.

## Un bug de la 0.20.4: `count(DISTINCT …)` antes de `sum(…)`

Los mismos agregados, con `count(DISTINCT p)` en lugar de `count(*)`, para dos dominios ([líneas 54-61](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L54-L61)):

```cypher
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, count(DISTINCT p) AS pages, sum(c.links) AS links
ORDER BY domain;
MATCH (p:Page)-[c:CITES]->(d:Domain)
WHERE p.locale = 'en' AND d.name IN ['duckdb.org', 'openjdk.org']
RETURN d.name AS domain, sum(c.links) AS links, count(DISTINCT p) AS pages
ORDER BY domain;
```

```text
┌─────────────┬───────┬────────┐
│ domain      │ pages │ links  │
│ STRING      │ INT64 │ INT128 │
├─────────────┼───────┼────────┤
│ duckdb.org  │ 9     │        │
│ openjdk.org │ 15    │        │
└─────────────┴───────┴────────┘
┌─────────────┬────────┬───────┐
│ domain      │ links  │ pages │
│ STRING      │ INT128 │ INT64 │
├─────────────┼────────┼───────┤
│ duckdb.org  │ 140    │ 9     │
│ openjdk.org │ 49     │ 15    │
└─────────────┴────────┴───────┘
```

Las dos consultas solo difieren en el orden de las columnas. En la primera, `links` es `NULL` (una celda vacía) para los dos dominios; en la segunda, vale 140 y 49, los números de la consulta anterior. No hay ni error ni aviso: un resultado incorrecto parece uno correcto. El [diario](../journal/) guarda los detalles. Hasta que se corrija, pon `count(DISTINCT …)` al final, o compara un agregado con una segunda consulta cuando el resultado importe.

## JSON: la extensión json

Las ejecuciones de CI del curso de DuckDB están en un archivo JSON ([líneas 64-66](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L64-L66)):

```cypher
LOAD FROM '../duckdb/data/runs.json' RETURN count(*);
LOAD json;
LOAD FROM '../duckdb/data/runs.json' RETURN conclusion, count(*) AS runs ORDER BY runs DESC, conclusion;
```

```text
Error: Binder exception: Cannot load from file type json. If this file type is part of a lbug extension please load the extension then try again.
┌──────────────────────────────────┐
│ result                           │
│ STRING                           │
├──────────────────────────────────┤
│ Extension: json has been loaded. │
└──────────────────────────────────┘
┌─────────────────┬───────┐
│ conclusion      │ runs  │
│ STRING          │ INT64 │
├─────────────────┼───────┤
│ success         │ 104   │
│ failure         │ 16    │
│ cancelled       │ 4     │
│ startup_failure │ 1     │
└─────────────────┴───────┘
```

El soporte de JSON es una [extensión](https://docs.ladybugdb.com/extensions/json/), en dos pasos:

- `INSTALL json;` la descarga una vez por máquina, desde `https://extension.ladybugdb.com/`. En mi máquina, se guardó en `~/.lbdb/extension/0.20.0/win_amd64/json/libjson.lbug_extension`. `check.sh` la ejecuta antes de los scripts, porque su mensaje es distinto la primera vez (`Extension: json installed from the repo: https://extension.ladybugdb.com/.`) y las siguientes (`Extension: json is already installed.`).
- `LOAD json;` la carga en la base de datos actual, cada vez que arranca la CLI.

125 ejecuciones, los mismos recuentos que en el curso de DuckDB. Los objetos del array JSON se convierten en filas, y sus campos en columnas.

## Un bug de la 0.20.4: un `COPY` fallido vacía el índice de clave primaria

Un último `COPY` de una página que ya está, [líneas 69-72](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-loading.cypher#L69-L72):

```cypher
COPY Page FROM (LOAD FROM 'data/pages.csv' (HEADER = true) WHERE url = '/duckdb/' RETURN *);
MATCH (p:Page) RETURN count(*) AS pages;
MATCH (p:Page {url: '/duckdb/'}) RETURN count(*) AS found_by_key;
MATCH (p:Page) WHERE lower(p.url) = '/duckdb/' RETURN count(*) AS found_by_scan;
```

```text
Error: Copy exception: Found duplicated primary key value /duckdb/, which violates the uniqueness constraint of the primary key column.
┌───────┐
│ pages │
│ INT64 │
├───────┤
│ 319   │
└───────┘
┌──────────────┐
│ found_by_key │
│ INT64        │
├──────────────┤
│ 0            │
└──────────────┘
┌───────────────┐
│ found_by_scan │
│ INT64         │
├───────────────┤
│ 1             │
└───────────────┘
```

El error es el esperado, y las 319 páginas siguen ahí. Pero la página ya no se encuentra por su clave: `{url: '/duckdb/'}` y `WHERE p.url = '/duckdb/'` pasan ambos por el índice de clave primaria, y no encuentran nada. `lower(p.url)` no puede usar el índice, lee todos los nodos y encuentra la página. No es solo `/duckdb/`: tras el `COPY` fallido, no se encuentra ninguna de las 319 claves, y un `CREATE` con una clave existente tiene éxito, creando un duplicado.

En un archivo de base de datos, la misma secuencia funciona: el índice sigue encontrando la página tras el `COPY` fallido, y el `CREATE` se rechaza. Los scripts de este curso usan una base de datos en memoria, donde falla. El [diario](../journal/) tiene la reproducción mínima, con tres filas, y una variante peor que rompe también los archivos de base de datos, cuando los nodos se crearon con `CREATE` en lugar de cargarse con `COPY`. Hasta que se corrija, considera un `COPY` fallido en una tabla de nodos como el final de esa tabla: vuelve a crearla.

## Puntos clave

- `LOAD FROM` lee un archivo como filas; `COPY FROM` carga de forma masiva un archivo o una subconsulta en una tabla de nodos o de relaciones.
- Para una tabla de relaciones, las dos primeras columnas son las claves de los nodos; un nodo que falta hace fallar todo el `COPY`.
- `IGNORE_ERRORS = true` conserva las filas incorrectas como avisos, que `CALL show_warnings()` devuelve como filas.
- El dialecto CSV se detecta a partir de las primeras 256 líneas: pasa `QUOTE`, `DELIM` y `ESCAPE` cuando los conozcas.
- `split_part` cuenta las partes de forma distinta a SQL, `count(DISTINCT …)` antes de `sum(…)` devuelve `NULL`, y un `COPY` fallido vacía el índice de clave de una tabla en memoria en la 0.20.4: comprueba de otra forma los resultados que importan.
- JSON necesita `INSTALL json` una vez y `LOAD json` en cada sesión.

## Ejercicios

Las soluciones están en [`cypher/02-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/02-exercises.cypher), comprobado por la CI. Parten de las tablas `Page`, `LINKS_TO`, `Domain` y `CITES`, cargadas como en esta lección.

1. ¿Qué páginas en inglés no tienen versión en francés, por curso?

<details>
<summary>Solución</summary>

De [`02-exercises.cypher`, líneas 13-16](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L13-L16):

```cypher
MATCH (en:Page)
WHERE en.locale = 'en' AND NOT EXISTS { MATCH (fr:Page) WHERE fr.url = '/fr' + en.url }
RETURN en.course, count(*) AS pages
ORDER BY pages DESC, en.course;
```

```text
┌───────────┬───────┐
│ en.course │ pages │
│ STRING    │ INT64 │
├───────────┼───────┤
│ streeling │ 16    │
└───────────┴───────┘
```

Los 16 módulos de Streeling de la lección, y nada más: cada página de curso tiene su espejo en francés. `+` concatena cadenas.

</details>

2. ¿Cuántos enlaces tienen un ancla (una parte `#`)? Compara `anchor IS NULL` y `anchor = ''`.

<details>
<summary>Solución</summary>

De [`02-exercises.cypher`, líneas 19-21](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L19-L21):

```cypher
MATCH ()-[l:LINKS_TO]->()
RETURN l.anchor IS NULL AS no_anchor, l.anchor = '' AS empty_anchor, count(*) AS links
ORDER BY no_anchor;
```

```text
┌───────────┬──────────────┬───────┐
│ no_anchor │ empty_anchor │ links │
│ BOOL      │ BOOL         │ INT64 │
├───────────┼──────────────┼───────┤
│ False     │ False        │ 3     │
│ True      │              │ 645   │
└───────────┴──────────────┴───────┘
```

Tres enlaces tienen un ancla. Para los otros 645, el campo vacío del archivo CSV se convirtió en `NULL`, no en `''`: la opción `NULL_STRINGS` de `COPY` vale por defecto la cadena vacía. Así que `l.anchor = ''` es `NULL` (la celda vacía), y un filtro `WHERE l.anchor = ''` no encontraría nada. Pasa `NULL_STRINGS = ['NA']`, o cualquier valor que el archivo no use, para conservar las cadenas vacías.

</details>

3. ¿Qué sitios citan más cursos en inglés?

<details>
<summary>Solución</summary>

De [`02-exercises.cypher`, líneas 24-28](https://github.com/spareilleux/learn/blob/711d62a/code/ladybugdb/cypher/02-exercises.cypher#L24-L28):

```cypher
MATCH (p:Page)-[:CITES]->(d:Domain)
WHERE p.locale = 'en'
RETURN d.name AS domain, count(DISTINCT p.course) AS courses
ORDER BY courses DESC, domain
LIMIT 5;
```

```text
┌──────────────────────┬─────────┐
│ domain               │ courses │
│ STRING               │ INT64   │
├──────────────────────┼─────────┤
│ github.com           │ 6       │
│ learn.microsoft.com  │ 5       │
│ www.nuget.org        │ 4       │
│ central.sonatype.com │ 3       │
│ docs.oracle.com      │ 3       │
└──────────────────────┴─────────┘
```

`count(DISTINCT p.course)` cuenta cursos, no páginas. Solo en el `RETURN`, no provoca el bug de esta lección, que necesita un `sum` después. La página de inicio, el método y la página de artifacts cuentan aquí como cursos (`''`, `method` y `artifacts`), por eso GitHub llega a 6.

</details>

## Fuentes

- [`LOAD FROM`](https://docs.ladybugdb.com/cypher/query-clauses/load-from/)
- [Importación de CSV](https://docs.ladybugdb.com/import/csv/): opciones, `IGNORE_ERRORS`, detección del dialecto
- [`COPY FROM` una subconsulta](https://docs.ladybugdb.com/import/copy-from-subquery/)
- [Configuración](https://docs.ladybugdb.com/cypher/configuration/): `threads`, `warning_limit`
- [Funciones de texto](https://docs.ladybugdb.com/cypher/expressions/text-functions/) y [funciones de agregación](https://docs.ladybugdb.com/cypher/expressions/aggregate-functions/)
- [Extensión JSON](https://docs.ladybugdb.com/extensions/json/)
- Código fuente de LadybugDB 0.20.4: [constantes CSV](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L138-L144), [errores del lector CSV](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/reader/csv/driver.cpp#L38)
