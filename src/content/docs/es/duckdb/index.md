---
title: DuckDB — Misión
description: Aprender DuckDB, la base de datos analítica que se ejecuta dentro de tu proceso, consultando el historial real de CI de este sitio — desde la línea de comandos, y luego desde C# y Java.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada consulta de este curso está en [`code/duckdb/sql`](https://github.com/spareilleux/learn/tree/main/code/duckdb/sql), junto a su salida esperada. [`.github/workflows/duckdb-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/duckdb-examples.yml) las ejecuta todas con la CLI de DuckDB en Linux, Windows y macOS y compara los resultados. Las salidas de las lecciones se capturaron con DuckDB 1.5.5 en septiembre de 2026.
:::

## Por qué estoy aprendiendo esto

Cada pregunta que me hago sobre la CI de este sitio — qué workflow falla más, cuánto tardan los jobs de Windows, qué step se volvió más lento — acaba en un montón de JSON salido de `gh run list` y `gh api`. Lo leo con `jq`, o lo pego en una hoja de cálculo. [DuckDB](https://duckdb.org/) promete responder a esas preguntas con SQL, directamente desde los archivos, sin instalar ningún servidor.

## A quién va dirigido este curso

Conoces el SQL de [SQL Server](https://learn.microsoft.com/sql/sql-server/), [PostgreSQL](https://www.postgresql.org/docs/current/) o [SQLite](https://www.sqlite.org/): `SELECT`, `JOIN`, `GROUP BY`. Escribes C# o Java. No necesitas saber nada de analítica ni de ingeniería de datos.

## Qué es DuckDB, en una tabla

| | SQL Server / PostgreSQL | SQLite | DuckDB |
|---|---|---|---|
| Se ejecuta | como un servidor | dentro de tu proceso | dentro de tu proceso |
| Pensado para | transacciones (OLTP) | transacciones, aplicaciones pequeñas | analítica (OLAP): recorridos, agregaciones, joins sobre muchas filas |
| Almacenamiento | por filas | por filas | por columnas |
| Base de datos | una instancia de servidor | un archivo | un archivo, o ninguno: también consulta directamente archivos CSV, JSON y Parquet |
| Desde .NET | `Microsoft.Data.SqlClient`, Npgsql | `Microsoft.Data.Sqlite` | DuckDB.NET (ADO.NET) |
| Desde Java | driver JDBC | driver JDBC | driver JDBC |

## Los datos

El curso consulta una instantánea del historial de GitHub Actions de este mismo repositorio, exportada el 2026-09-14 en [`code/duckdb/data`](https://github.com/spareilleux/learn/tree/main/code/duckdb/data):

- `runs.json`: 125 ejecuciones de workflows, obtenidas con `gh run list --limit 1000 --json databaseId,workflowName,event,status,conclusion,createdAt,updatedAt,startedAt,headBranch,headSha,attempt`;
- `jobs.json`: los 315 jobs de esas ejecuciones, con sus steps, obtenidos de la API REST de GitHub.

Son las ejecuciones que produjo el [curso de GitHub Actions](../github-actions/): fallos reales, tiempos reales, tres sistemas operativos.

## Al final de este curso, sabré

- consultar archivos CSV, JSON y Parquet con SQL desde la CLI de DuckDB;
- usar las extensiones SQL de DuckDB para escribir consultas analíticas más cortas;
- aplanar JSON anidado con `STRUCT`, `LIST` y `unnest`;
- convertir entre formatos y leer muchos archivos a la vez;
- usar DuckDB desde C# y desde Java;
- leer un plan de consulta y saber cuándo DuckDB no es la herramienta adecuada.

## Plan

| # | Lección | Si conoces SQL Server |
|---|---|---|
| 1 | [Primeras consultas](01-first-queries/) | `sqlcmd`, `OPENROWSET`, `SELECT INTO` |
| 2 | [Friendly SQL: fechas, ventanas, `QUALIFY`, `PIVOT`](02-friendly-sql/) | funciones de ventana, `PIVOT` |
| 3 | [Datos anidados: `STRUCT`, `LIST`, `unnest`](03-nested-data/) | `OPENJSON`, `CROSS APPLY` |
| 4 | [Archivos: CSV, Parquet, globs, archivos remotos](04-files/) | `BULK INSERT`, tablas externas |
| 5 | DuckDB desde C# | ADO.NET |
| 6 | DuckDB desde Java | JDBC |
| 7 | Rendimiento: planes y almacenamiento por columnas | planes de ejecución, índices columnstore |
| 8 | Persistencia, transacciones y concurrencia | aislamiento, bloqueos |
| — | [Diario](journal/) | |

## Recursos

- [Documentación de DuckDB](https://duckdb.org/docs/current/)
- [Por qué DuckDB](https://duckdb.org/why_duckdb)
- [CLI de DuckDB](https://duckdb.org/docs/current/clients/cli/overview)
- [Friendly SQL](https://duckdb.org/docs/current/sql/dialect/friendly_sql): las extensiones al SQL estándar
- [Código fuente de DuckDB](https://github.com/duckdb/duckdb)
