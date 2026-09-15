---
title: Diario
description: Notas de progreso fechadas — versiones, lo que probé, sorpresas, hallazgos sobre los datos de Guitar Alchemist y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Misión y un plan de 13 lecciones
- [x] Código: scripts SQL ejecutados por `psql`, programas C# y Java, todos comparados con su salida esperada por `check.sh`
- [ ] CI: el workflow está escrito y pasa en local; aún no está en GitHub
- [x] Lección 1: un contenedor, `psql`, bases de datos, esquemas y roles
- [x] Lección 2: tipos y modelado
- [x] Lección 3: CTE, ventanas, `LATERAL`, upserts y `MERGE`
- [x] Lección 4: PostgreSQL desde C# y Java
- [ ] Lecciones 5 a 13
- [ ] Todo lo relativo a AWS: cada sección de Aurora sigue *por verificar*

## 2026-09-15 — Versiones

- La [página de versiones de PostgreSQL](https://www.postgresql.org/support/versioning/) indica 18.6 como versión menor actual de PostgreSQL 18, con soporte hasta el 14 de noviembre de 2030. PostgreSQL 19 está en beta. El curso fija la etiqueta de imagen `postgres:18.6-trixie` y anota su digest en la página de misión.
- La versión de Aurora PostgreSQL más reciente en las notas de versión de AWS es 18.4.1, del 21 de agosto de 2026. Su tabla de extensiones da `btree_gist` 1.6; PostgreSQL 18.6 en la imagen ofrece 1.8.
- Clientes: Npgsql 10.0.3 y su proveedor EF Core 10.0.3, que requiere EF Core 10.0.4 o posterior; pgjdbc 42.7.13, HikariCP 7.1.0. `pgvector` no está en la imagen oficial: la lección 8 necesitará otra imagen o una compilación.

## 2026-09-15 — Arrancar el servidor

- El primer arranque de la imagen ejecuta un servidor temporal para crear el clúster, que escucha solo en el socket Unix. `pg_isready` por el socket respondía «accepting connections» durante ese intervalo, y el comando siguiente se topaba con un servidor que se estaba apagando. `pg_isready -h 127.0.0.1` pasa por TCP. `server.sh` y el health check del servicio de CI lo usan.
- Los errores de `psql` salían antes que los resultados de las instrucciones anteriores en las salidas guardadas: `psql` usa un búfer para la salida estándar, no para la de errores. `server.sh` ejecuta `psql` bajo `stdbuf -o0`, dentro del contenedor, con ambos flujos fusionados allí.
- Cada script se ejecuta con `TimeZone=UTC`, `DateStyle=ISO, MDY` y `lc_messages=C`, fijados en `PGOPTIONS`, y cada consulta tiene un `ORDER BY`. `\conninfo` muestra el identificador del proceso servidor, que cambia en cada ejecución: los scripts no lo usan.

## 2026-09-15 — Modelar el historial de CI

- Un rango cerrado `[started_at, completed_at]` para los pasos hacía que se solaparan 2798 pares de pasos del mismo job: las horas de GitHub van al segundo, y un paso empieza en el segundo en que termina el anterior. Los rangos semiabiertos `[)` lo resuelven, pero 857 de los 2204 pasos se convierten en rangos vacíos, que pierden sus límites. La tabla conserva ambas marcas de tiempo y deriva el rango como columna generada almacenada.
- Un `CHECK` cuyo mensaje de error incluía `now()` daba una salida distinta en cada ejecución; las filas de prueba usan fechas fijas.
- `WITH TIES` devolvía las filas empatadas en un orden distinto de una ejecución a otra: un `ORDER BY` externo fija el orden.

## 2026-09-15 — Hallazgos en Guitar Alchemist

Nada de esto se ha comunicado al proyecto; son notas, con las consultas que los reproducen en las lecciones.

- `GA.Knowledge.Service.csproj` referencia `GA.Business.Config.fsproj` dos veces, en las líneas 26 y 31, en el commit `32f143c`. La clave primaria de `ga.project_refs` rechaza la segunda (lección 2).
- `MusicalKnowledgeDbContext.cs` existe en tres copias que solo difieren en su namespace, en `Common/GA.Data.EntityFramework/`, `Common/GA.Data.EntityFramework/Data/` y `Common/GA.Infrastructure/Persistence/EntityFramework/`. No encontré ninguna llamada a `AddDbContext` o `UseSqlite` para él en ese commit, aunque hay servicios que lo inyectan.
- Sus convertidores de valores guardan las listas como cadenas unidas y las vuelven a leer con `StringSplitOptions.RemoveEmptyEntries`: un nombre alternativo vacío se pierde. Tres nombres guardados, dos leídos (lección 4).
- En `IconicChords.yaml`, tres digitaciones no tocan sus clases de altura declaradas: Blackbird no toca si y añade do♯, mi y la; la digitación Hendrix no tiene si; la digitación del Mu Major, `Cadd9(no3)`, toca mi (lección 3, ejercicio 1).
- Versiones de paquetes: `Microsoft.Extensions.Hosting` se referencia en 5 versiones y `MongoDB.Driver` en 5; 16 paquetes tienen un máximo textual que no es su versión más alta; 13 versiones distintas no son números simples, entre ellas las flotantes `0.*` y `8.*-*` (lección 3).
- Dos proyectos se llaman `GaApi.Tests.csproj`, en `Tests/Apps/GaApi.Tests` y `Tests/GaApi.Tests`.

## 2026-09-15 — Los drivers

- Npgsql: un `DateTime` con `Kind=Unspecified` no lanzó una excepción, como esperaba, sino que se envió como `timestamp` y se convirtió en la zona horaria de la sesión: 82 ejecuciones o 59 según `Timezone`. Un `DateTimeOffset` con un desfase de −4 horas lanza `ArgumentException`.
- `pg_prepared_statements` contaba la propia consulta de recuento una vez preparada; una expresión regular que no coincide con su propio texto corrigió el recuento.
- EF Core construye un modelo una vez por tipo de contexto: dos configuraciones de la misma entidad en una sola clase de contexto, elegidas por un argumento del constructor, daban dos veces el primer modelo. Una subclase por configuración.
- pgjdbc envía la zona horaria de la JVM como `TimeZone` de la sesión, así que `getString` sobre un `timestamptz` dependía de la máquina. `check.sh` ejecuta Java con `-Duser.timezone=America/Toronto`.
- PowerShell 7.6 sigue cortando `-Duser.timezone=Asia/Tokyo` en el punto: Java respondía «Could not find or load main class .timezone=Asia.Tokyo». Entre comillas, funciona.
- Npgsql rechaza `Target Session Attributes=standby` con un solo host: `NotSupportedException: Target Session Attributes other then Any is only supported with multiple hosts`. pgjdbc acepta `targetServerType=secondary` con un host y falla al conectarse.
- Una ejecución de `l04-timings`: 478 comandos `INSERT` en un segundo aproximadamente, un `NpgsqlBatch` en 5 a 7 ms, un `COPY` binario en unos 50 ms. Ejecuciones anteriores ese mismo día tardaron hasta 2,2 segundos en el bucle de `INSERT`.

## Por verificar

- Los comandos de Linux y macOS de las lecciones 1 y 4, en esos sistemas.
- Cada sección «En Aurora»: `pg_read_file` y el requisito de `CONNECT` para `rds_superuser`, `btree_gist` 1.6, el error de solo lectura en una réplica, TLS por defecto, los tokens IAM con el proveedor de contraseña periódico de Npgsql, la fijación de RDS Proxy con el `DISCARD ALL` de Npgsql y con las sentencias preparadas a nivel de protocolo, y `pg_is_in_recovery()` en una Aurora Replica.
