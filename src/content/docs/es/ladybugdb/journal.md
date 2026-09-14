---
title: Diario
description: Notas de progreso fechadas — datos, ejecuciones de CI, bugs encontrados en LadybugDB 0.20.4 y puntos por verificar.
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
- [ ] Lección 5: LadybugDB desde C#
- [ ] Lección 6: LadybugDB desde Java
- [ ] Lección 7: algoritmos de grafos y búsqueda de texto completo
- [ ] Lección 8: persistencia, transacciones y concurrencia

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

## 2026-09-14 — Bugs encontrados en la 0.20.4

Cinco bugs silenciosos: ningún error, un resultado incorrecto. Ninguno tenía un issue en el [tracker de LadybugDB](https://github.com/LadybugDB/ladybug/issues) cuando busqué el 2026-09-14; no los he reportado. Cada reproducción de abajo se ejecuta en una base de datos en memoria vacía (`lbug -m csv < repro.cypher`) y solo se ejecutó en Windows, salvo que se indique lo contrario.

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

## Por verificar

- El script de instalación (`curl -s https://install.ladybugdb.com | bash`) y `brew install ladybug`: no se ejecutaron para este curso.
- Las reproducciones mínimas solo se ejecutaron en Windows. Los scripts del curso que muestran los bugs 1, 2, 4 y 5 sobre los datos del sitio dan la misma salida en los tres runners de la CI.
- Si estos bugs ya están corregidos en la rama principal de LadybugDB, después de la 0.20.4.
