---
title: Diario
description: Notas de progreso fechadas — datos, ejecuciones de CI, bugs encontrados en LadybugDB 0.20.4 y en el paquete NuGet 0.19.1, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Datos: las páginas, los enlaces y el historial de Git de este repositorio en el commit `cbcbb42`, y las ejecuciones de CI del curso de DuckDB
- [x] CI: el Cypher de cada lección comparado con su salida esperada en tres sistemas operativos, y una verificación cruzada en SQL con DuckDB
- [x] Lección 1: un primer grafo
- [x] Lección 2: cargar archivos
- [x] Lección 3: caminos
- [x] Lección 4: el historial de Git y las ejecuciones de CI como grafo
- [x] Datos: los proyectos .NET de GuitarAlchemist/ga en el commit `a26a7893`
- [x] Lección 5: LadybugDB desde C#
- [x] Lección 6: LadybugDB desde Java
- [x] Lección 7: algoritmos de grafos y búsqueda de texto completo
- [x] Lección 8: persistencia, transacciones y concurrencia

## QA

LadybugDB 0.20.4 es la base de datos de otros, y escribir ocho lecciones sobre ella sacó nueve hallazgos. Seis son bugs silenciosos — sin error, un resultado equivocado — cada uno con una reproducción que corre en una base en memoria vacía; ninguno tenía incidencia aguas arriba cuando se buscó en el tracker el 14 de septiembre de 2026, y ninguno se ha reportado. Los tres últimos vienen de las lecciones mismas, y uno de ellos ya estaba abierto aguas arriba.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| Un `COPY` a una tabla de relaciones desde una subconsulta conecta los nodos que encontró el `MATCH` | Conecta los nodos equivocados: las claves se emparejan por posición en lugar de por el `MATCH` | `COPY … FROM (LOAD FROM … MATCH …)` | Reproducción 1 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| `count(DISTINCT …)` junto a `sum(…)` deja la suma en paz | La `sum` vuelve como `NULL` en cuanto un `count(DISTINCT …)` la precede | Agregación | Reproducción 2 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| `ACYCLIC` descarta todo camino que repite un nodo | Conserva algunos | Patrones de caminos recursivos | Reproducción 3 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| Un `COPY` que falla deja la tabla de nodos como estaba | La corrompe | `COPY` a una tabla de nodos | Reproducción 4 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| Agrupar por una subconsulta `COUNT` conserva el grupo cuyo recuento es 0 | Ese grupo desaparece | `GROUP BY` sobre una subconsulta | Reproducción 5 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| `timestamp()` y `CAST(… AS TIMESTAMP)` respetan el desfase escrito en el literal | Ambos lo ignoran | Conversión temporal | Reproducción 6 [2026-09-14](#2026-09-14--bugs-encontrados-en-la-0204) | Reproducido, ninguna incidencia aguas arriba, no reportado |
| `INSTALL algo` obtiene la build que corresponde a la CLI | La CLI 0.20.4 descarga la build 0.20.0, y `LOAD algo` falla después en los tres ejecutores, con rutas de la máquina de build de LadybugDB en el mensaje | extensión `algo`, CLI 0.20.4 | `libnetworkit.so: cannot open shared object file` en Linux, `Library not loaded: @rpath/libnetworkit.dylib` en macOS, `The specified module could not be found.` en Windows | Abierto aguas arriba como [incidencia #857](https://github.com/LadybugDB/ladybug/issues/857), no abierta por este curso [2026-09-14](#2026-09-14--lección-7-extensiones-algoritmos-y-búsqueda-de-texto-completo) |
| Louvain da las mismas comunidades para el mismo grafo y el mismo número de hilos | Los tamaños cambian de un proceso a otro, con `CALL threads = 1` puesto | extensión `algo`, Louvain | `[27,20,17,14,14]` en un proceso, `[25,20,18,18,11]` en los dos siguientes; tres llamadas dentro de un mismo proceso coinciden. Los nodos sin relación reciben `louvain_id` -1 | Reproducido, no reportado [2026-09-14](#2026-09-14--lección-7-extensiones-algoritmos-y-búsqueda-de-texto-completo) |
| Un proceso de solo lectura y un escritor sobre el mismo archivo se comportan como dice la documentación | La [página sobre concurrencia](https://docs.ladybugdb.com/concurrency/) dice que la combinación no está permitida, pero es justo lo que pasa: un proceso de solo lectura abre el archivo de un escritor en Linux y macOS y ve sus cambios confirmados a través del `.wal`; un escritor abre y hace checkpoint de un archivo que tiene un lector, en los tres, y el lector sigue respondiendo desde el estado antiguo | [`storage_manager.cpp` 87-91](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/storage/storage_manager.cpp#L87-L91) | En Windows el `LockFileEx` del escritor hace que la lectura falle con `Error 33` | Reproducido; la documentación y el comportamiento se contradicen [2026-09-14](#2026-09-14--lección-8-transacciones-archivos-y-procesos) |

## 2026-09-14 — Los datos

- [`extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/extract.py), ejecutado con el commit `cbcbb42` como argumento, lee los archivos Markdown y el historial de Git en ese commit, con `git ls-tree`, `git show` y `git log`, no la copia de trabajo: los archivos CSV no cambian cuando cambia el sitio.
- 319 páginas, 712 enlaces internos, 3.712 enlaces externos, 74 commits, 73 enlaces de parentesco y 1.019 archivos modificados.
- Las ejecuciones son el `runs.json` del [curso de DuckDB](../../duckdb/journal/), 125 ejecuciones exportadas hacia las 14:04 UTC, reutilizadas tal cual.
- Las fechas de los commits conservan su desfase `-04:00` en `commits.csv`; LadybugDB las guarda en UTC.

## 2026-09-14 — Instalar LadybugDB

- Windows: `lbug_cli-windows-x86_64.zip` de la release v0.20.4 solo contiene `lbug.exe`, 14.772.736 bytes. `lbug --version` imprime `Lbug 0.20.4`.
- CI: el workflow descarga el asset de la release de cada sistema operativo (`linux-x86_64`, `windows-x86_64`, `osx-arm64`) y añade la carpeta a `GITHUB_PATH`. Instala DuckDB 1.5.5 de la misma manera, para la verificación cruzada en SQL de la lección 3.
- `INSTALL json` puso la extensión en `~/.lbdb/extension/0.20.0/win_amd64/json/`: la carpeta lleva el nombre de 0.20.0, no de 0.20.4. El historial del shell está en `~/.lbdb/history.txt`.
- En una ventana de Git Bash, `lbug.exe` no encuentra las rutas `/c/Users/…`, y las barras invertidas en una cadena de Cypher son caracteres de escape: los scripts usan rutas relativas a `code/ladybugdb`, y `C:/…` funciona cuando hace falta una ruta completa.

## 2026-09-14 — La CI

- La CLI termina con 0 incluso cuando una consulta falla, e imprime los errores en la salida estándar ([`embedded_shell.cpp`, líneas 608-611](https://github.com/LadybugDB/ladybug/blob/v0.20.4/tools/shell/embedded_shell.cpp#L608-L611)): `check.sh` compara toda la salida, errores incluidos, así que un error inesperado sigue haciendo fallar el job.
- La barra de progreso escribe códigos de escape incluso cuando la salida va a un pipe: `check.sh` pasa `--no_progress_bar` y `--no_stats`.
- Primer push: falló en Linux, pasó en Windows y macOS. Borrar una lección que aún tenía relaciones daba un mensaje que nombraba `HAS_LESSON` en Windows y macOS, y `LINKS_TO` en Linux: el ejecutor nombra la primera tabla de relaciones que comprueba ([`delete_executor.cpp`, líneas 33-42](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/processor/operator/persistent/delete_executor.cpp#L33-L42)), y su orden difiere. Ahora la lección 1 borra una lección cuyas relaciones están todas en una sola tabla.
- Mismo push: `ACYCLIC` dio 14 caminos en Windows y 29 en Linux y macOS (ver más abajo). La lección 3 usa `is_acyclic(p)`, igual en los tres.
- Dos salidas podían variar de una ejecución a otra: un `LOAD FROM … LIMIT 3` sin `ORDER BY`, y la primera clave que falta según un `COPY` fallido, que depende del hilo que la encuentra. Los scripts ordenan, y ejecutan `CALL threads = 1` antes de ese `COPY`.
- Un recorrido `LINKS_TO*` sin límite sobre el grafo del sitio estuvo más de cinco minutos en marcha antes de que lo detuviera; `* SHORTEST` sobre el mismo patrón responde al instante.

## 2026-09-14 — Sorpresas al escribir las lecciones 1-4

- `MERGE` hace coincidir el patrón entero: sin la clave primaria falla en la fase de enlace, y con la clave y otra propiedad que difiere, intenta crear el nodo y falla por la clave duplicada.
- `:schema` imprime sentencias `CREATE`, con `MANY_MANY` en cada tabla de relaciones.
- La cabecera del CSV se detecta sin `HEADER = true`, y sus nombres no tienen que coincidir con las columnas de la tabla.
- `SKIP_DUPLICATE_PK = true` funciona en un `COPY` desde un archivo ([`constants.h`, línea 111](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L111)) pero no aparece en la documentación, y no se admite en un `COPY` desde una subconsulta ([`bind_copy_from.cpp`, línea 149](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/binder/bind/copy/bind_copy_from.cpp#L149)).
- El detector de formato CSV lee las primeras 256 líneas ([`constants.h`, línea 144](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/common/constants.h#L144)); un campo entre comillas más abajo hace fallar el `COPY`, salvo que se indique `QUOTE`.
- Los campos CSV vacíos se convierten en `NULL` por defecto; `NULL_STRINGS = ['NA']` los conserva como `''`.
- `split_part('/es/streeling/', '/', 1)` devuelve `es`: la parte vacía antes del separador inicial se omite. DuckDB devuelve `''`.
- `nodes(e)` sobre una lista de relaciones solo devuelve los nodos intermedios; las listas se indexan desde 1; `ORDER BY` sobre un `STRING[]` falla, un cast a `STRING` funciona.
- Los patrones de longitud variable son recorridos por defecto, así que dos relaciones `CHANGED` de un mismo patrón pueden ser la misma.
- El límite superior de un patrón de longitud variable está limitado a 30 ([`client_config.h`, línea 32](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/main/client_config.h#L32)) hasta un `CALL var_length_extend_max_depth = …`; un patrón que necesita más no devuelve nada, sin error.
- Los recuentos de caminos de 4 enlaces de la lección 3 se comprobaron dos veces fuera de LadybugDB: un script de Python sobre `links.csv` (recorridos 1, 5, 12, 29; senderos 26; acíclicos 1, 5, 9, 10), y una CTE recursiva en DuckDB (recorridos 1, 5, 12, 29), que la CI ejecuta.

## 2026-09-14 — Lección 5: los datos de ga y el paquete de C#

- [`data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) solo necesita los archivos de proyecto: un clon con `--filter=blob:none` y un sparse checkout de `*.csproj`, `*.fsproj` y `*.slnx` descarga los archivos de proyecto de ga sin el resto de su contenido. Omite las copias que hay en las carpetas `.claude`.
- 111 proyectos, 266 referencias de proyecto, 478 referencias de paquete, 136 paquetes. Una referencia apunta a `reactapp1.client.esproj`, un proyecto JavaScript que la extracción no conserva: la lección carga las referencias con `IGNORE_ERRORS`.
- La columna `version` es lo que dice cada archivo de proyecto. El `Directory.Build.props` de ga sobrescribe 14 paquetes con `PackageReference Update`, y la extracción no lo aplica; las consultas de la lección evitan esos paquetes.
- Dos proyectos se llaman `GaApi.Tests`, en `Tests/Apps/GaApi.Tests` y `Tests/GaApi.Tests`; el segundo no está en `AllProjects.slnx`. En total, 38 proyectos no están en él.
- NuGet: `LadybugDB` tiene tres versiones, `0.17.0-alpha.1`, `0.18.2` y `0.19.1`; la 0.19.1 incluye el motor 0.19.1, versión de almacenamiento 43. El binding no es ADO.NET y no tiene página en docs.ladybugdb.com: leí su código fuente en el commit [`0f58f1a`](https://github.com/LadybugDB/ladybug-dotnet/tree/0f58f1a).
- Primer push de CI: el job de C# falló en los tres sistemas operativos. El ID interno de `GaApi` era `0:11` en Windows y `0:47` en Linux y macOS, a partir del mismo CSV; `SHORTEST` eligió un camino que pasaba por `GA.Business.ML` en mi máquina y por `GA.Business.AI` en los runners, entre dos de la misma longitud; y la CLI del runner de Linux imprimía `Warning: failed to create directory: /home/runner/.lbdb/` al abrir un archivo en solo lectura. Ahora el programa compara los IDs en lugar de imprimirlos y lista los caminos `ALL SHORTEST` ordenados; `check.sh` filtra la advertencia.
- La CLI 0.20.4, al abrir en lectura-escritura un archivo de base de datos 0.19.1, lo reescribe a la versión de almacenamiento 47 sin ningún mensaje; después, el paquete 0.19.1 falla con `Failed to open Ladybug database at '…'`, sin la causa. `--read_only` deja el archivo legible por ambos.
- El binding no expone `lbug_query_result_has_next_query_result`, `lbug_connection_interrupt` ni `lbug_connection_set_query_timeout` de la API de C: un `Query` con varias sentencias solo devuelve el primer resultado, y una consulta larga no se puede detener desde C#.

## 2026-09-14 — Lección 6: el paquete de Java

- `com.ladybugdb:lbug` 0.20.4 en Maven Central: un único jar de 29.339.834 bytes con la biblioteca nativa para `linux_amd64`, `linux_arm64`, `osx_arm64` y `windows_amd64`, sin `osx_amd64`. Arrastra 13 jars más, 7 MB: `kotlin-stdlib` 2.3.20, Apache Arrow 18.2.0, Jackson, FlatBuffers, commons-codec y SLF4J.
- El jar de fuentes coincide con el repositorio [`ladybug-java`](https://github.com/LadybugDB/ladybug-java) en `f2fb39f`, el commit del submódulo de LadybugDB v0.20.4. Las fuentes están en una carpeta `com/lbugdb`, pero el paquete es `com.ladybugdb`.
- La [página de Java de la documentación](https://docs.ladybugdb.com/client-apis/java/) todavía muestra `throws ObjectRefDestroyedException`; la 0.20.4 lanza `RuntimeException` con mensajes como `Connection has been destroyed.`
- Una consulta fallida devuelve un resultado con `isSuccess()` a false; `getNext()` sobre él lanza `RuntimeException` con el mismo mensaje.
- Un `PreparedStatement` conserva los valores de su última ejecución: `execute(statement, Map.of("nom", 5))` después de `Map.of("n", 2.5)` se ejecuta con `n = 2.5` y sin error. Sobre una sentencia nueva, el mismo mapa falla con `Parameter n not found.`
- `Value.getValue()` lanza `Type of value is not supported in value_get_value` para `LIST` y `MAP`, y tampoco maneja `STRUCT`, `NODE`, `REL` ni `RECURSIVE_REL`; las clases `LbugList`, `LbugStruct`, `LbugMap` y `Value…Util` los leen.
- `interval('1 month 2 days')` vuelve como `PT768H`: el código JNI convierte el intervalo a segundos con meses de 30 días.
- `setQueryTimeout(1)` detiene los recorridos de la lección 3 con `Interrupted.`, y `getNextQueryResult()` lee la segunda sentencia de una consulta: ambos faltan en el paquete .NET.
- La biblioteca nativa se copia a un nuevo archivo temporal en cada arranque de la JVM, y `deleteOnExit` no puede borrar una DLL cargada en Windows: 13 copias, 190 MB, en `%TEMP%` tras las ejecuciones de esta lección en mi máquina, 3 copias en el runner de Windows tras tres ejecuciones, ninguna en los runners de Linux y macOS.
- El primer push de CI del job de Java pasó en los tres sistemas operativos: la lección 5 ya había hecho la salida independiente de los IDs internos y del camino que elige `SHORTEST`.

## 2026-09-14 — Lección 7: extensiones, algoritmos y búsqueda de texto completo

- Con la CLI 0.20.4, `INSTALL algo` descarga la build para 0.20.0, y `LOAD algo` falla en los tres runners de la CI: `libnetworkit.so: cannot open shared object file` en Linux, `Library not loaded: @rpath/libnetworkit.dylib` en macOS, con rutas de la propia máquina de build de LadybugDB en el mensaje, y `The specified module could not be found.` en Windows. El [issue #857](https://github.com/LadybugDB/ladybug/issues/857) está abierto.
- `LOAD fts` funciona con 0.20.4 en los tres runners, pero en mi máquina Windows la CLI termina con `0xC0000409`, sin imprimir nada, en el primer `CREATE_FTS_INDEX`, incluso sobre una tabla de una sola fila. En Linux (WSL), el mismo script funciona con 0.20.4.
- La CLI 0.19.1 descarga las builds para 0.19.0; `algo` y `fts` se cargan y dan la misma salida en Windows, Linux y macOS. La CI la instala como `lbug19`; `check.sh` imprime el resultado de `LOAD algo` y `LOAD fts` con 0.20.4 en cada ejecución, sin compararlo.
- La CLI de Windows, 0.19.1 y 0.20.4, importa `libssl-3-x64.dll` y `libcrypto-3-x64.dll`, que no están en el archivo zip; con solo `C:\Windows\System32` en el `PATH`, termina con `0xC0000135`. Git for Windows proporciona ambas DLL. La lección 1 ya lo indica.
- `project_graph_cypher` no está en la documentación. Crea un grafo de tipo `CYPHER`, y `page_rank` y `weakly_connected_components` sobre él fallan con `Binder exception: AA`: [`gds.cpp`, línea 72](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/function/gds/gds.cpp#L72), todavía presente en 0.20.4. El test del motor para esta función solo crea el grafo. Reproducción mínima, con 0.19.1 en Windows:

```cypher
LOAD algo;
CREATE NODE TABLE P(id INT64 PRIMARY KEY, age INT64);
CREATE REL TABLE E(FROM P TO P);
CREATE (:P {id: 1, age: 5}), (:P {id: 2, age: 20}), (:P {id: 3, age: 7});
MATCH (a:P {id: 1}), (b:P {id: 3}) CREATE (a)-[:E]->(b);
CALL project_graph_cypher('G1', 'MATCH (n:P) WHERE n.age < 10 RETURN n');
CALL page_rank('G1') RETURN node.id, rank;
```

- Louvain sobre el grafo de ga: 5 comunidades de tamaños `[27,20,17,14,14]` en un proceso de la CLI, `[25,20,18,18,11]` en los dos siguientes, con `CALL threads = 1`; tres llamadas en un mismo proceso dan los mismos tamaños. Los nodos sin ninguna relación reciben `louvain_id` -1.
- Los rangos de PageRank suman 0,3534 sobre el grafo de ga: los 25 proyectos sin referencia saliente no transmiten su rango. El ejercicio 1 recalcula dos rangos con `(1 - 0.85) / N + 0.85 × Σ rank / out_degree`, con cuatro decimales.
- `RETURN n + sum(x)`, con `n` procedente de `WITH count(*) AS n`, falla con `Cannot evaluate expression with type AGGREGATE_FUNCTION.`; `RETURN n, n + sum(x)` funciona, y también `RETURN 2 * sum(x)`.
- FTS: el stemmer inglés hace coincidir *queries* con *query* y *Persistance* con *persistant*; el stemmer francés no hace coincidir *Persistence*. Las mayúsculas se ignoran, los acentos no (`donnees` no encuentra nada). Las stop words por defecto son inglesas sea cual sea el stemmer. Tras un `CREATE`, el índice incluye el nuevo nodo y las demás puntuaciones cambian. `DROP_FTS_INDEX` informa `Table 3_titles_fr_terms has been dropped.`, una tabla interna.

## 2026-09-14 — Lección 8: transacciones, archivos y procesos

- Un error dentro de una transacción manual deshace toda la transacción y la termina, sin ningún mensaje que lo diga: los errores de ejecución (una clave duplicada), los errores del binder, los errores del catálogo, un `BEGIN` dentro de una transacción y `CHECKPOINT` dentro de una transacción lo hacen todos. Las sentencias siguientes se ejecutan en auto-commit; `ROLLBACK` y `COMMIT` fallan entonces con `No active transaction`. La única excepción encontrada: una escritura dentro de `BEGIN TRANSACTION READ ONLY` falla, y la transacción sigue abierta. La [página de transacciones](https://docs.ladybugdb.com/cypher/transaction/) promete que no persiste nada de una transacción fallida, y no dice que las sentencias posteriores al error se ejecutan por su cuenta.
- Una segunda transacción de escritura se rechaza de inmediato, `Cannot start a new write transaction in the system. Only one write transaction at a time is allowed in the system.`, incluso cuando toca otros nodos; no hay espera ni tiempo límite. Una sentencia en auto-commit rechazada deja la conexión utilizable.
- Java, **un `BEGIN TRANSACTION` rechazado rompe la conexión**: la consulta siguiente lanza `RuntimeException: Unknown Error` en Windows, y hace caer la JVM con `SIGSEGV` en Linux (`CatalogSet::traverseVersionChainsForTransactionNoLock`) y macOS (`CatalogSet::containsEntry`), código de salida 134. Un `BEGIN` que tiene éxito repara la conexión en Windows; un `BEGIN` reintentado no hace caer nada en ninguno de los tres runners (ejercicio 2: 153, 155 y 24 rechazos). Reproducción mínima, un `Database` en memoria y dos conexiones: `first` ejecuta `BEGIN TRANSACTION`, `second` ejecuta `BEGIN TRANSACTION` (rechazado), `first` ejecuta `COMMIT`, `second` ejecuta cualquier `MATCH`. El paquete de C# y los demás bindings no se probaron.
- Los archivos: `.wal` aparece en el primer commit y desaparece en el checkpoint al cerrar la base de datos; ningún `.wal` para una transacción sin confirmar. `kill -9` después de un commit deja el `.wal`, que la siguiente apertura vuelve a aplicar; `kill -9` dentro de una transacción pierde la transacción. Cerrar un `Database` de Java con una transacción abierta la deshace.
- Un segundo proceso de lectura-escritura falla con `Could not set lock on file`, seguido de `(Error: 33)` en Windows y `(Error: Resource temporarily unavailable)` en Linux. El código POSIX cierra el descriptor de archivo antes de `F_GETLK`, así que su mensaje `Lock is held by PID` no puede aparecer ([`local_file_system.cpp`, líneas 147-172](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/common/file_system/local_file_system.cpp#L147-L172)).
- **Una base de datos de solo lectura no toma ningún bloqueo** ([`storage_manager.cpp`, líneas 87-91](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/storage/storage_manager.cpp#L87-L91)). Un proceso de solo lectura abre un archivo que tiene un escritor en Linux y macOS, y ve los cambios confirmados del escritor a partir del `.wal`; no en Windows, donde el `LockFileEx` del escritor hace fallar la lectura con `Error 33`. Un escritor abre, escribe y hace checkpoint de un archivo que tiene un proceso de solo lectura, en los tres sistemas operativos, y el lector sigue respondiendo desde el estado antiguo. La [página de concurrencia](https://docs.ladybugdb.com/concurrency/) dice que esta combinación no está permitida.
- En un mismo proceso Java, un segundo `Database` de lectura-escritura, o uno de solo lectura, sobre un archivo que tiene un `Database` de lectura-escritura: rechazado en Windows, abierto en Linux y macOS (los bloqueos `fcntl` pertenecen al proceso).
- `new Database(path)` lanza `java.lang.Exception`, una excepción comprobada que no declara ([`lbug_java.cpp`, líneas 618-636](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L618-L636)).
- `EXPORT DATABASE` en CSV escribe las macros en `schema.cypher`; la [página de migración](https://docs.ladybugdb.com/migrate/) enumera un archivo `macro.cypher` que no se crea. Las cabeceras CSV llevan el prefijo `a.`. El orden de las opciones en `copy.cypher` difiere entre Windows y Linux o macOS. `IMPORT DATABASE` en una base de datos no vacía falla con `Project already exists in catalog.`
- La 0.20.4 abierta en solo lectura deja un archivo 0.19.1 como está; abierta en lectura-escritura, lo actualiza de la versión de almacenamiento 43 a la 47 sin ningún mensaje, y la CLI 0.19.1 dice entonces `Database file version: 47, Current build storage version: 43`.
- CI: la primera ejecución falló en los tres jobs `cypher`, porque `files.sh`, ejecutado con `set -e`, devolvía el código de salida de la última CLI 0.19.1; ahora `check.sh` lo ignora y compara la salida. Los jobs `java` de Linux y macOS caían en el `BEGIN` rechazado, que ahora tiene un modo propio. La segunda ejecución falló solo en macOS: `ls` ordenaba `Project.csv` después de `copy.cypher`; el script ordena con `LC_ALL=C`.
- Con su salida redirigida a un archivo, la CLI no escribe nada hasta que termina: `files.sh` espera al archivo `.wal`, o un tiempo fijo, en lugar de una línea de salida.

## 2026-09-14 — Bugs encontrados en la 0.20.4

Seis bugs silenciosos: ningún error, un resultado incorrecto. Ninguno tenía un issue en el [tracker de LadybugDB](https://github.com/LadybugDB/ladybug/issues) cuando busqué el 2026-09-14; no los he reportado. Cada reproducción de abajo se ejecuta en una base de datos en memoria vacía (`lbug -m csv < repro.cypher`) y solo se ejecutó en Windows, salvo que se indique lo contrario.

### 1. `COPY` desde una subconsulta JSON con `MATCH` conecta los nodos equivocados

Con `r.json` conteniendo `[{"id":1,"k":"a"},{"id":2,"k":"b"},{"id":3,"k":"c"}]`:

```cypher
LOAD json;
CREATE NODE TABLE K(k STRING PRIMARY KEY);
CREATE NODE TABLE R(id INT64 PRIMARY KEY);
CREATE REL TABLE ON_K(FROM R TO K);
CREATE (:K {k: 'a'}), (:K {k: 'b'}), (:K {k: 'c'}), (:R {id: 1}), (:R {id: 2}), (:R {id: 3});
COPY ON_K FROM (LOAD FROM 'r.json' WITH id, k MATCH (x:K) WHERE x.k = k RETURN id, k);
MATCH (r:R)-[:ON_K]->(x:K) RETURN r.id, x.k ORDER BY x.k;
```

```text
3 tuples have been copied to the ON_K table.
r.id,x.k
1,a
1,b
1,c
```

Esperaba `1,a`, `2,b`, `3,c`, que es lo que da el mismo `COPY` desde un archivo CSV con las mismas filas. Añadiendo `(IGNORE_ERRORS = true)`, las tres relaciones van en cambio a `a`: `1,a`, `2,a`, `3,a`. La lección 4 se topó con él con 123 ejecuciones: las 123 relaciones salían todas de la misma ejecución; filtrar con `WHERE` y sin `MATCH` funciona.

`IGNORE_ERRORS = true` en un `COPY` desde una subconsulta, cuando falta una clave, falla con `Error: bad variant access` en lugar de omitir la fila.

### 2. `count(DISTINCT …)` antes de `sum(…)` deja la suma en `NULL`

```cypher
CREATE NODE TABLE P(id INT64 PRIMARY KEY, g STRING, n INT64);
CREATE (:P {id: 1, g: 'x', n: 10}), (:P {id: 2, g: 'x', n: 20}), (:P {id: 3, g: 'y', n: 5});
MATCH (p:P) RETURN p.g, count(DISTINCT p) AS ps, sum(p.n) AS total ORDER BY p.g;
MATCH (p:P) RETURN p.g, sum(p.n) AS total, count(DISTINCT p) AS ps ORDER BY p.g;
```

```text
p.g,ps,total
x,2,""
y,1,""
p.g,total,ps
x,30,2
y,5,1
```

Los mismos agregados, en el otro orden, dan los totales correctos.

La lección 5 encontró una forma más general, también en el motor 0.19.1 del paquete NuGet: con una clave de agrupación, un agregado después de un agregado `DISTINCT` en la misma proyección es incorrecto. `RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects` da 0 proyectos para `MongoDB.Driver` en lugar de 14.

### 3. `ACYCLIC` conserva caminos que repiten un nodo

Tres nodos, `a` y `b` enlazados en ambos sentidos, `b` enlazado con `c`:

```cypher
CREATE NODE TABLE V(id STRING PRIMARY KEY);
CREATE REL TABLE E(FROM V TO V);
CREATE (:V {id: 'a'}), (:V {id: 'b'}), (:V {id: 'c'});
MATCH (x:V {id: 'a'}), (y:V {id: 'b'}) CREATE (x)-[:E]->(y), (y)-[:E]->(x);
MATCH (x:V {id: 'b'}), (y:V {id: 'c'}) CREATE (x)-[:E]->(y);
MATCH p = (x:V {id: 'a'})-[e:E* ACYCLIC 1..4]->(y:V {id: 'c'}) RETURN properties(nodes(p), 'id') AS path;
MATCH p = (x:V {id: 'a'})-[e:E*1..4]->(y:V {id: 'c'}) WHERE is_acyclic(p) RETURN properties(nodes(p), 'id') AS path;
```

```text
path
"[a,b,a,b,c]"
"[a,b,c]"
path
"[a,b,c]"
```

`[a,b,a,b,c]` pasa dos veces por `b`. La comprobación de `ACYCLIC` está en [`output_writer.cpp`, línea 280](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/function/gds/output_writer.cpp#L280); no he encontrado la causa. En el grafo del sitio de la lección 3, `LINKS_TO* ACYCLIC 1..4` desde el índice de GitHub Actions hasta su lección 7 devolvió 14 caminos en Windows, incluido uno que pasa dos veces por la misma lección, y 29, todos los recorridos, en los runners de Linux y macOS. Una enumeración en Python da 25 caminos cuyos nodos intermedios son distintos, y 10 con la definición de `is_acyclic`, ambos extremos incluidos.

### 4. Un `COPY` fallido en una tabla de nodos la corrompe

Cargada con `COPY`, y luego un `COPY` que falla por una clave duplicada, con `n.csv` conteniendo la cabecera `k` y las filas `a`, `b`, `c`:

```cypher
CREATE NODE TABLE N(k STRING PRIMARY KEY);
COPY N FROM 'n.csv' (HEADER = true);
COPY N FROM (RETURN 'a' AS k);
MATCH (n:N {k: 'b'}) RETURN count(*) AS b_by_key;
CREATE (:N {k: 'b'});
MATCH (n:N) RETURN n.k ORDER BY n.k;
```

En memoria:

```text
Error: Copy exception: Found duplicated primary key value a, which violates the uniqueness constraint of the primary key column.
b_by_key
0
n.k
a
a
b
c
```

`b` está ahí, pero su clave no encuentra nada; el `CREATE` de una clave existente tiene éxito, y el nuevo nodo contiene `a`, la clave que rechazó el `COPY` fallido, en lugar de `b`. En un archivo de base de datos (`lbug -m csv d/x.lbdb`), esta secuencia funciona: `b_by_key` vale 1 y el `CREATE` falla con `Runtime exception: Found duplicated primary key value b`.

Cuando los tres nodos se crean con `CREATE` en lugar de `COPY`, el `COPY` fallido también estropea un archivo de base de datos: después, `CREATE (:N {k: 'z', v: 26})` sobre una tabla `N(k STRING PRIMARY KEY, v INT64)` añade un nodo que se lee como `a,9`, la fila rechazada, tanto en memoria como en disco.

### 5. Agrupar por una subconsulta `COUNT` pierde el grupo de 0

```cypher
CREATE NODE TABLE C(id INT64 PRIMARY KEY);
CREATE REL TABLE PARENT(FROM C TO C);
CREATE (:C {id: 1}), (:C {id: 2}), (:C {id: 3});
MATCH (a:C {id: 2}), (b:C {id: 1}) CREATE (a)-[:PARENT]->(b);
MATCH (a:C {id: 3}), (b:C {id: 2}) CREATE (a)-[:PARENT]->(b);
MATCH (c:C) RETURN c.id, COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents ORDER BY c.id;
MATCH (c:C) RETURN COUNT { MATCH (c)-[:PARENT]->(:C) } AS parents, count(*) AS cs ORDER BY parents;
```

```text
c.id,parents
1,0
2,1
3,1
parents,cs
1,2
```

La subconsulta devuelve 0 para el nodo 1, pero la consulta agrupada no tiene fila `0,1`. `OPTIONAL MATCH` con `count(…)` da los dos grupos (lección 4).

### 6. `timestamp()` y `CAST(… AS TIMESTAMP)` ignoran el desfase

```cypher
RETURN timestamp('2026-09-14T09:30:00-04:00') AS f, CAST('2026-09-14T09:30:00-04:00' AS TIMESTAMP) AS c, CAST('2026-09-14T09:30:00-04:00' AS TIMESTAMP_TZ) AS tz;
```

```text
f,c,tz
2026-09-14 09:30:00,2026-09-14 09:30:00,2026-09-14 13:30:00+00
```

Esperaba 13:30 también para los dos primeros: `COPY` y `LOAD FROM` convierten el mismo texto de un archivo CSV a 13:30 UTC (lección 4). El desfase se descarta sin aplicarse. `timestamp(…)` en el paquete C# 0.19.1 también devuelve 09:30 (lección 5).

## Por verificar

- El script de instalación (`curl -s https://install.ladybugdb.com | bash`) y `brew install ladybug`: no se ejecutaron para este curso.
- Las reproducciones mínimas solo se ejecutaron en Windows. Los scripts del curso que muestran los bugs 1, 2, 4 y 5 sobre los datos del sitio dan la misma salida en los tres runners de la CI.
- Si estos bugs ya están corregidos en la rama principal de LadybugDB, después de la 0.20.4.
- Si los conflictos de versión mayor del ejercicio 2 de la lección 5 (`MongoDB.Driver` 2 y 3, `Microsoft.ML.Tokenizers` 1 y 2) rompen ga en tiempo de ejecución: no he compilado ni ejecutado ga.
- El programa C# en `linux-arm64` y `osx-x64`, y el programa Java en `linux_arm64`: los runners de la CI son `linux-x64`, `win-x64` y `osx-arm64`.
- Si `CREATE_FTS_INDEX` también hace fallar la CLI 0.20.4 en el runner de Windows: la CI ejecuta la lección 7 solo con 0.19.1.
- Si los dos proyectos aislados de `Common`, `GA.Business.DSL.SourceGen` y `GA.Business.Core.Generated`, se usan en ga de alguna otra forma que un `ProjectReference`.
- Si un proceso de solo lectura que sigue abierto mientras un escritor hace checkpoint devuelve datos incorrectos, y no solo datos antiguos, cuando lee páginas que no tenía en caché (lección 8).
- En Linux y macOS, si cerrar el segundo `Database` de un proceso libera el bloqueo `fcntl` del primero, como cerrar cualquier descriptor de un archivo libera los bloqueos del proceso sobre él, y deja que otro proceso abra el archivo en lectura-escritura.
- Si un `BEGIN` rechazado también rompe una conexión del paquete de C# y de los demás bindings.
