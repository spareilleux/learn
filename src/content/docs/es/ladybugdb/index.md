---
title: LadybugDB — Misión
description: Aprender LadybugDB, la base de datos de grafos embebida que continúa Kuzu, consultando con Cypher los enlaces entre las páginas de este sitio, su historial de Git, sus ejecuciones de CI y los proyectos de una solución .NET — desde la línea de comandos, y luego desde C# y Java.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada consulta de este curso está en [`code/ladybugdb/cypher`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/cypher), junto a su salida esperada. [`.github/workflows/ladybugdb-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ladybugdb-examples.yml) las ejecuta todas con la CLI de LadybugDB en Linux, Windows y macOS y compara los resultados, y hace lo mismo con el programa C# de la lección 5, los programas Java de las lecciones 6 y 8, y el script de la lección 8 que arranca y mata procesos de la CLI sobre un archivo de base de datos. Las salidas de las lecciones se capturaron con LadybugDB 0.20.4 en septiembre de 2026, con la CLI 0.19.1 para las extensiones de la lección 7, con el paquete NuGet `LadybugDB` 0.19.1 para C#, y con el paquete Maven `com.ladybugdb:lbug` 0.20.4 para Java.
:::

## Por qué estoy aprendiendo esto

El [curso de DuckDB](../duckdb/) responde a preguntas sobre filas: cuántas ejecuciones, cuánto tiempo, qué step. Otras preguntas sobre este sitio tratan de conexiones. ¿Cuántos clics hay desde la página de inicio hasta una lección? ¿Qué archivos cambian juntos? ¿Sobre qué commits se ejecutó un workflow que falló? En SQL, cada una de ellas es una cadena de self-joins, o una CTE recursiva cuya profundidad tengo que adivinar.

Una base de datos de grafos almacena las propias conexiones, y su lenguaje de consulta describe los caminos directamente. [LadybugDB](https://ladybugdb.com/) es una que se ejecuta dentro de tu proceso, como DuckDB y SQLite: sin servidor que instalar.

## A quién va dirigido este curso

Conoces SQL: `SELECT`, `JOIN`, `GROUP BY`, quizá una CTE recursiva. Escribes C# o Java. No necesitas saber nada de bases de datos de grafos ni de [Cypher](https://opencypher.org/).

## Qué es LadybugDB, en una tabla

| | Tablas de grafos de SQL Server | Neo4j | LadybugDB |
|---|---|---|---|
| Se ejecuta | como un servidor | como un servidor | dentro de tu proceso |
| Esquema | tablas creadas `AS NODE` y `AS EDGE` | opcional: las etiquetas y las propiedades aparecen cuando las escribes | obligatorio: tablas de nodos y tablas de relaciones, con columnas tipadas |
| Lenguaje de consulta | T-SQL con `MATCH` | Cypher | Cypher |
| Caminos de cualquier longitud | `SHORTEST_PATH` | patrones de longitud variable | patrones de longitud variable, caminos más cortos |
| Desde .NET | `Microsoft.Data.SqlClient` | driver .NET de Neo4j | paquete NuGet `LadybugDB` |
| Desde Java | driver JDBC | driver Java de Neo4j | paquete Maven `com.ladybugdb:lbug` |

Fuentes: [arquitectura de SQL Graph](https://learn.microsoft.com/sql/relational-databases/graphs/sql-graph-architecture), [manual de Cypher de Neo4j](https://neo4j.com/docs/cypher-manual/current/introduction/), [diferencias entre LadybugDB y Neo4j](https://docs.ladybugdb.com/cypher/difference/).

LadybugDB se llamaba [antes Kuzu](https://github.com/LadybugDB/ladybug#readme). Los autores de Kuzu [archivaron su repositorio](https://github.com/kuzudb/kuzu); LadybugDB continúa el código base bajo la licencia MIT, con nombres nuevos: la CLI es `lbug`, y la documentación nombra los archivos de base de datos `.lbdb`.

## Los datos

[`code/ladybugdb/data/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py) lee este repositorio en el commit [`cbcbb42`](https://github.com/spareilleux/learn/commit/cbcbb42) (2026-09-14) y escribe seis archivos CSV en [`code/ladybugdb/data`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data):

- `pages.csv`: las 319 páginas del sitio (117 en inglés, 101 en francés, 101 en español), con su locale, su curso, su título y su número de líneas;
- `links.csv`: los 712 enlaces de una página del sitio a otra, encontrados en enlaces Markdown y atributos `href` fuera de los bloques de código;
- `external_links.csv`: los 3.712 enlaces a otros 85 sitios;
- `commits.csv`, `parents.csv` y `changes.csv`: los 74 commits hasta `cbcbb42`, el padre de cada uno, y los 1.019 cambios que hicieron en 710 archivos.

La lección 4 añade las 125 ejecuciones de CI de [`code/duckdb/data/runs.json`](https://github.com/spareilleux/learn/blob/main/code/duckdb/data/runs.json), la instantánea que consulta el curso de DuckDB.

Las lecciones 5 y 6 consultan otro repositorio: los proyectos .NET de [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en el commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893), extraídos por [`code/ladybugdb/data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py): 111 proyectos, 266 referencias de proyecto y 478 referencias de paquete.

## Al final de este curso, sabré

- modelar datos como tablas de nodos y tablas de relaciones, y consultarlos con patrones de Cypher;
- cargar archivos CSV y JSON, y encontrar las filas que no encajan en el esquema;
- escribir caminos de longitud variable y caminos más cortos, y conocer la semántica de caminos que usan;
- reconocer los bugs y los límites de LadybugDB, y comprobar un resultado de otra manera;
- usar LadybugDB desde C# y desde Java.

## Plan

| # | Lección | Si conoces SQL |
|---|---|---|
| 1 | [Un primer grafo: tablas, `CREATE`, `MATCH`, `MERGE`](01-first-graph/) | `CREATE TABLE`, `INSERT`, `MERGE`, `JOIN` |
| 2 | [Cargar archivos: `LOAD FROM`, `COPY`, advertencias](02-loading/) | `OPENROWSET`, `BULK INSERT` |
| 3 | [Caminos: longitud variable y caminos más cortos](03-paths/) | CTE recursivas |
| 4 | [El historial de Git y las ejecuciones de CI como grafo](04-git-history/) | self-joins, tablas intermedias |
| 5 | [LadybugDB desde C#](05-csharp/) | ADO.NET |
| 6 | [LadybugDB desde Java](06-java/) | JDBC |
| 7 | [Algoritmos de grafos y búsqueda de texto completo](07-algorithms/) | índices de texto completo, `CONTAINSTABLE` |
| 8 | [Persistencia, transacciones y concurrencia](08-persistence/) | aislamiento, bloqueos, el registro de transacciones |
| — | [Diario](journal/) | |

## Recursos

- [Documentación de LadybugDB](https://docs.ladybugdb.com/)
- [Cypher en LadybugDB](https://docs.ladybugdb.com/get-started/cypher-intro/)
- [CLI de LadybugDB](https://docs.ladybugdb.com/client-apis/cli/)
- [Código fuente de LadybugDB](https://github.com/LadybugDB/ladybug), y la [versión 0.20.4](https://github.com/LadybugDB/ladybug/releases/tag/v0.20.4) que usa este curso
- [openCypher](https://opencypher.org/): la especificación abierta de Cypher
