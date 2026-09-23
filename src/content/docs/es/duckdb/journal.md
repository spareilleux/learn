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

## QA

DuckDB 1.5.5, su driver de .NET y su driver de JDBC son software de otros. Dos filas de abajo pierden datos sin decirlo: por eso la columna Estado las separa de las que describen un comportamiento documentado con el que choca una costumbre de C# o Java. Nada se ha reportado aguas arriba.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| DuckDB.NET rellena una clase desde un `STRUCT` por nombre de propiedad | Ignora las mayúsculas pero no los guiones bajos: `StartedAt` conserva su valor por defecto sin decir nada, mientras `Started_At` sí se rellena | DuckDB.NET 1.5.5 | Silencioso, ninguna excepción. Un record posicional en cambio lanza `MissingMethodException` | Reproducido, no reportado [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-5-6) |
| Un `TIMESTAMPTZ` sobrevive a una ida y vuelta por el driver | Vuelve como `DateTime` con el valor UTC y un `Kind` `Unspecified`, así que `ToUniversalTime` lo desplaza una segunda vez. En Java es un `OffsetDateTime` en la zona de la JVM, diga lo que diga `SET TimeZone` | DuckDB.NET 1.5.5, duckdb_jdbc 1.5.5.1 | Valores equivocados, en silencio, en ambos drivers | Reproducido, no reportado [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-5-6) |
| Una cadena de varias sentencias es atómica, como la página de transacciones de DuckDB describe una transacción implícita | No lo es: las dos primeras filas se quedaron cuando la tercera sentencia falló, en la CLI y por JDBC | CLI de DuckDB 1.5.5 y duckdb_jdbc | 2 de 3 filas conservadas, tanto con `-c "a; b; c"` como con `statement.execute("a; b; c")`. Un `COMMIT` tras un error no imprime nada y deshace | Reproducido; la documentación y el comportamiento se contradicen [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| Una consulta fallida deja el `Statement` utilizable | El statement queda cerrado: un bucle que captura el error y sigue falla en todas las sentencias posteriores | duckdb_jdbc 1.5.5.1 | `Statement was closed` | Reproducido, no reportado [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-5-6) |
| El sniffer de CSV avisa de una columna que no supo analizar | Lee en silencio `13/09/2026 15:53` como `VARCHAR`, y un `timestampformat` equivocado también; solo un tipo explícito lo hace fallar | DuckDB 1.5.5 | Toda comparación de fechas posterior pasa a ser comparación de cadenas | Reproducido; las palabras del diario: «This isn't an error» [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-1-4) |
| Un glob sobre archivos de formas distintas avisa o falla | `FROM 'data/*.json'` fusiona los runs y los jobs en una tabla sin decir nada | DuckDB 1.5.5 | 20 columnas sacadas de dos formas sin relación | Reproducido, no reportado [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-1-4) |
| El `approx_unique` de `SUMMARIZE` cuenta los valores distintos | Cuenta de más y de menos | CLI de DuckDB 1.5.5 | 131 para 125 identificadores de ejecución, 17 para 21 nombres de workflow | Por diseño: HyperLogLog cambia exactitud por memoria constante [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-1-4) |
| `labels[0]` es un error | Devuelve `NULL`, igual que cualquier índice pasado el final | DuckDB 1.5.5 | Ningún error | Por diseño: las listas empiezan en 1. Una costumbre de C# o Java que falla en silencio [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-1-4) |
| El escritor de Parquet produce los mismos bytes para los mismos datos | No — escribe con varios hilos | escritura Parquet de DuckDB 1.5.5 | 119 021 205 y luego 119 392 814 bytes en local para un archivo de 11 millones de filas; 118 714 412 a 119 120 557 en los ejecutores. En el primer push el script de la lección 4 falló solo en macOS: 8 fragmentos de columna diferían de 1 a 6 bytes en `total_compressed_size` | Reproducido; un fallo real de CI, sorteado comparando `num_values` [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| Predicados de fecha equivalentes obtienen planes equivalentes | `started_at::DATE = …` y `date_trunc('day', started_at) = …` se reescriben en un rango que salta grupos de filas; `strftime(started_at, …) = …` sigue siendo una expresión y lee todas las filas | optimizador de DuckDB 1.5.5 | 0,47 s frente a 0,003 s en el archivo ordenado | Reproducido; una reescritura realmente perdida [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| Una ordenación que no cabe en `memory_limit` se vuelca a disco | Falla con 4 hilos y funciona con 1, y el `COPY` fallido deja un archivo parcial | DuckDB 1.5.5 | 11 M de filas con `memory_limit = '100MB'`; 6,3 a 9,9 s en el caso de un hilo | Reproducido, dependiente del número de hilos [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| Un proceso de solo lectura puede abrir un archivo que otro tiene | Un proceso que tiene el archivo bloquea a todos los demás, los de solo lectura incluidos, con un mensaje distinto en cada sistema | DuckDB 1.5.5 | Tres sistemas, tres mensajes; Linux y macOS añaden una pista sobre `-readonly` que Windows no da | Reproducido; por diseño [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| El jar de JDBC y el paquete de .NET llevan lo que la plataforma necesita | El jar pesa 85 MB, con cuatro bibliotecas nativas y ninguna build de Windows sobre Arm | duckdb_jdbc 1.5.5.1, DuckDB.NET 1.5.5 | `DuckDB.NET.Data.Full` pesa 420 MB en la caché de NuGet, 316 MB en `bin/Debug`, 69 MB publicado solo para `linux-x64` | Medido; la ausencia de build win-arm64 es una carencia real [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-5-6) |
| El script de instalación de una línea cubre los tres sistemas | `curl -fsSL https://install.duckdb.org | sh` no admite Windows | install.duckdb.org | El workflow descarga `duckdb_cli-windows-amd64.zip` en su lugar | Reproducido [2026-09-14](#2026-09-14--instalar-duckdb) |
| Un lote de JDBC es más rápido que sentencias una a una | No lo era | duckdb_jdbc 1.5.5.1, en CI | 690 ms a 2,4 s para 10 000 filas, frente a 226 a 331 ms para 1 000 000 de filas con el appender de C# | Medido, causa no investigada [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-5-6) |

## Experimentos

Cuatro preguntas que el curso se hizo antes de medir. Ninguna es una hipótesis que el autor inventara y luego pusiera a prueba — dos se apoyan en documentación leída de antemano, una en un valor leído del propio archivo — y la tabla lo dice en lugar de disfrazarlas. La tercera es la que volvió refutada.

| Pregunta | Hipótesis | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Puede la CI comparar planes `EXPLAIN` entre tres ejecutores? | El diario plantea la pregunta y saca su conclusión de la respuesta; ninguna predicción escrita | La salida no depende del número de hilos, y las estimaciones fueron las mismas en los tres ejecutores | Confirmada: los planes son comparables | [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| ¿Puede un DuckDB más antiguo leer un archivo escrito por la 1.5.5? | La etiqueta `storage_version=v1.0.0+` del propio archivo, leída antes de la prueba | La CLI 1.0.0 leyó los archivos escritos por defecto. Con `STORAGE_VERSION 'v1.5.0'` los rechazó: `version number 68, can only read 64` | Confirmada, con su control negativo | [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| ¿Es atómica una cadena de varias sentencias? | Sí — la página de transacciones de DuckDB describe una transacción implícita. Un supuesto documentado y citado antes de la prueba | `-c "a; b; c"` y `statement.execute("a; b; c")` conservaron ambos las dos primeras filas cuando la tercera falló | Refutada | [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |
| ¿Se cumple la predicción del plan en tiempo real? | El plan dice que `::DATE` y `date_trunc` saltan grupos de filas y que `strftime` no; la lección 7 lee los planes y luego mide lo que predicen | 0,47 s frente a 0,003 s en el archivo ordenado | Confirmada | [2026-09-14](#2026-09-14--sorpresas-al-escribir-las-lecciones-7-8) |

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
