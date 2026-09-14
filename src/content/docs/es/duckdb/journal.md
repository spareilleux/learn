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
- [x] Lección 5: DuckDB desde C#
- [x] Lección 6: DuckDB desde Java
- [x] Lección 7: rendimiento
- [x] Lección 8: persistencia, transacciones y concurrencia

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

## 2026-09-14 — Sorpresas al escribir las lecciones 5-6

- `DuckDB.NET.Data.Full` 1.5.5 ocupa 420 MB en la caché de NuGet, 316 MB en `bin/Debug` y 69 MB una vez publicado solo para `linux-x64`. El jar de JDBC ocupa 85 MB, con cuatro bibliotecas nativas y ninguna build para Windows on Arm.
- DuckDB.NET asocia un `STRUCT` a una clase por nombre de propiedad, sin distinguir mayúsculas pero sí guiones bajos: `StartedAt` se queda en silencio con su valor por defecto, `Started_At` se rellena. Un record posicional lanza `MissingMethodException`.
- `TIMESTAMPTZ` vuelve como un `DateTime` que contiene el valor UTC con `Kind` `Unspecified`, así que `ToUniversalTime` lo desplaza una segunda vez. En Java es un `OffsetDateTime` en la zona horaria por defecto de la JVM, diga lo que diga `SET TimeZone`.
- `(long)` y `Convert.ToInt64` lanzan una excepción con el `BigInteger` de un `HUGEINT`; `(long)(BigInteger)value` funciona.
- Con JDBC, un `Statement` se cierra tras una consulta fallida: un bucle que captura el error y sigue hace fallar todas las sentencias siguientes con `Statement was closed`.
- El JDK 25 muestra cuatro advertencias de acceso nativo al cargar el driver, salvo con `--enable-native-access=ALL-UNNAMED`; el lanzador de Maven ya lo pasa.
- Tiempos en la CI, no comparados: el appender de C# cargó 1.000.000 de filas en 226 a 331 ms y 10.000 sentencias `INSERT` sueltas tardaron de 1,3 a 3,9 s; en Java, un batch de JDBC no fue más rápido que las sentencias sueltas (de 690 ms a 2,4 s para 10.000 filas).
- Las rutas relativas en el SQL son relativas al directorio de trabajo del proceso, no al proyecto: los dos programas se ejecutan desde `code/duckdb`.

## 2026-09-14 — Sorpresas al escribir las lecciones 7-8

- La salida de `EXPLAIN` no depende del número de hilos, y las estimaciones fueron las mismas en los tres runners, así que la CI puede comparar los planes.
- El writer de Parquet usa varios hilos, y el tamaño del mismo archivo de 11 millones de filas cambió entre ejecuciones: 119.021.205 y luego 119.392.814 bytes en local, de 118.714.412 a 119.120.557 bytes en los runners.
- El optimizador reescribe `started_at::DATE = …` y `date_trunc('day', started_at) = …` como un rango que se salta row groups; `strftime(started_at, …) = …` sigue siendo una expresión y lee todas las filas: 0,47 s frente a 0,003 s en el archivo ordenado.
- Las descargas del Parquet remoto fueron idénticas byte a byte en las cuatro máquinas, y coinciden exactamente con los metadatos: los tres bloques de `trip_distance` para la media, el row group 0 desde el byte 4 para `SELECT * … LIMIT 1`.
- Una ordenación de 11 millones de filas con `memory_limit = '100MB'` falla con 4 hilos y funciona con 1 (de 6,3 a 9,9 s). El `COPY` fallido dejó un archivo parcial.
- `COMMIT` tras un error dentro de una transacción no muestra ningún error y lo deshace todo, en el CLI y en JDBC. Las cadenas con varias sentencias tampoco son atómicas: `-c "a; b; c"` y `statement.execute("a; b; c")` conservaron las dos primeras filas cuando falló la tercera, aunque la página de transacciones describe una transacción implícita.
- Un conflicto de escritura falla en el segundo `UPDATE`; una clave duplicada entre dos transacciones, solo en el segundo commit.
- Un proceso que tiene abierto un archivo de base de datos bloquea a todos los demás procesos, incluidos los de solo lectura, con un mensaje distinto en cada sistema operativo. Los archivos escritos por DuckDB 1.5.5 llevan la etiqueta `storage_version=v1.0.0+` y el CLI de DuckDB 1.0.0 los leyó; con `STORAGE_VERSION 'v1.5.0'`, la 1.0.0 los rechazó (número de versión 68, solo sabe leer 64).
- La CI también ejecuta `timings/07-performance.sql` (no comparado: 17 s en Ubuntu, 32 s en Windows, con un archivo CSV de 1 GB) y `shell/08-*.sh`.

## Por verificar

- Por qué falta el step número 4 en los jobs de `Deploy to GitHub Pages` (step `withastro/action`): ¿un step interno de la acción compuesta?
- La ruta de instalación de las extensiones en Linux y macOS (`~/.duckdb/extensions/v1.5.5/<platform>/`), deducida a partir de la de Windows.
- Los comandos de Linux y macOS para ejecutar el programa Java sin Maven (lección 6).
- Los conflictos de escritura y las conexiones de solo lectura con DuckDB.NET (lección 8): probados solo con JDBC.
- Abrir, escribir y cerrar un archivo de base de datos desde varios procesos bajo carga (lección 8, ejercicio 3).
- El protocolo remoto Quack y DuckLake, para varios procesos que escriben: mencionados, no probados.
