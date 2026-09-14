---
title: Diario
description: Notas de progreso fechadas — datos, ejecuciones de CI, sorpresas y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Instantánea de los datos: 125 ejecuciones y 315 jobs de este repositorio
- [x] CI: el SQL de cada lección comparado con su salida esperada en tres sistemas operativos
- [x] Lección 1: primeras consultas
- [x] Lección 2: Friendly SQL
- [x] Lección 3: datos anidados
- [x] Lección 4: archivos
- [ ] Lección 5: DuckDB desde C#
- [ ] Lección 6: DuckDB desde Java
- [ ] Lección 7: rendimiento
- [ ] Lección 8: persistencia, transacciones y concurrencia

## 2026-09-14 — Los datos

- `runs.json`: `gh run list --limit 1000 --json databaseId,workflowName,event,status,conclusion,createdAt,updatedAt,startedAt,headBranch,headSha,attempt`, exportado hacia las 14:04 UTC. 125 ejecuciones, la más antigua del 2026-09-13 a las 15:53.
- `jobs.json`: una llamada por ejecución a `repos/spareilleux/learn/actions/runs/{id}/jobs?per_page=100`, conservando 11 campos de cada job y 5 de cada step. 315 jobs para 121 ejecuciones: 4 ejecuciones nunca tuvieron ningún job.
- El endpoint de jobs solo devuelve el último intento: 4 jobs para la ejecución que se intentó tres veces, 12 con `?filter=all`. Me di cuenta al escribir la lección 3; la instantánea se queda como está.

## 2026-09-14 — Instalar DuckDB

- En local, `winget` tenía instalado DuckDB 1.5.3 (`DuckDB.cli`), con la 1.5.5 disponible. El curso usa la 1.5.5, descomprimida de la release de GitHub.
- CI en Linux y macOS: `curl -fsSL https://install.duckdb.org | sh` → `Successfully installed DuckDB 1.5.5 to /home/runner/.duckdb/cli/1.5.5/duckdb`. El script lee `DUCKDB_VERSION` del entorno, que el workflow define, así que la versión queda fijada.
- CI en Windows: el script no lo admite; el workflow descarga `duckdb_cli-windows-amd64.zip` y añade la carpeta a `GITHUB_PATH`.
- `check.sh` ejecuta cada script con `duckdb -csv <` y hace un diff contra `sql/expected/`. Cada sistema operativo tarda uno o dos segundos en todos los scripts de las lecciones 1-4, incluida la consulta HTTPS.

## 2026-09-14 — Sorpresas al escribir las lecciones 1-4

- El `approx_unique` de `SUMMARIZE` daba 131 para 125 identificadores de ejecución únicos, y 17 para 21 nombres de workflow.
- La CLI usa la zona horaria del sistema operativo para mostrar `TIMESTAMPTZ` (`America/…` en local, UTC en los runners): el script de la lección 2 define `TimeZone` explícitamente.
- `sum(INTERVAL)` no existe, `avg(INTERVAL)` sí.
- `labels[0]` devuelve `NULL` sin error.
- La flecha de lambda `x -> …` imprime un aviso de obsolescencia en 1.5.5; las lecciones usan `lambda x: …`.
- Un job omitido tiene `runner_name` a `NULL`; el job de despliegue rechazado por la política de ramas del entorno tiene `''`.
- El detector de formato CSV (sniffer) lee en silencio `13/09/2026 15:53` como `VARCHAR`, y lo mismo pasa con un `timestampformat` incorrecto. Solo un tipo explícito lo hace fallar.
- `FROM 'data/*.json'` fusiona las ejecuciones y los jobs en una sola tabla de 20 columnas, sin ningún aviso.
- Primer push del script de la lección 4: falló solo en `macos-latest`. El `total_compressed_size` de Parquet de 8 bloques de columnas (column chunks) difería de 1 a 6 bytes respecto a Linux y Windows. Ahora el script compara `num_values` en su lugar.
- `COPY` a un archivo existente lo sobrescribe; `COPY … PARTITION_BY` a una carpeta no vacía falla sin `OVERWRITE`.

## Por verificar

- Por qué falta el step número 4 en los jobs de `Deploy to GitHub Pages` (step `withastro/action`): ¿un step interno de la acción compuesta?
- La ruta de instalación de las extensiones en Linux y macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), deducida a partir de la de Windows.
- Las peticiones de rango (range requests) al leer Parquet por HTTPS (lección 7).
- La poda de particiones (partition pruning) con `WHERE os = 'windows-latest'` (lección 7).
