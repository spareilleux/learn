---
title: 9. Un laboratorio de grafos — traducciones, ciclos de prerrequisitos, alcanzabilidad acotada
description: Un laboratorio sobre unas pocas páginas inventadas, cada predicción escrita antes de ejecutar — un COPY fallido y el estado que deja, las traducciones que faltan encontradas por identidad de contenido y no por título, ciclos de prerrequisitos separados de la navegación, lo que una cota de profundidad prueba y lo que no, y un testigo de ciclo que la 0.20.4 imprime al revés.
sidebar:
  order: 9
---

Las lecciones [2](../02-loading/) y [3](../03-paths/) consultaban las páginas reales del sitio. Este laboratorio usa una docena de páginas inventadas bajo `/lab/`, pocas como para escribir cada respuesta esperada **antes** de ejecutar la consulta. Las predicciones están en [`data/lab/preregistration.md`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/lab/preregistration.md), con su hash tomado antes de la primera ejecución, y un anexo fechado para los dos puntos en que esa ejecución contradijo el fichero. Las consultas están en [`cypher/09-graph-lab.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-graph-lab.cypher).

Las salidas de abajo son lo que imprime `lbug --no_progress_bar --no_stats --mode csv`, el comando exacto que `check.sh` ejecuta antes de compararlas con [`cypher/expected/09-graph-lab.csv`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/expected/09-graph-lab.csv). Sin las dos primeras opciones, `--mode csv` imprime además un mensaje de apertura, barras de progreso, el número de tuplas y los tiempos, y la salida ya no coincidiría. Cada script se ejecuta en una base nueva en memoria, así que cada ejecución empieza vacía.

El esquema es el del curso. `Page` tiene su URL como clave primaria, y `LINKS_TO` guarda los enlaces de navegación. El laboratorio añade una tabla de relaciones, `REQUIRES`, para los prerrequisitos. **Las tres relaciones se mantienen separadas:**
- la navegación es `LINKS_TO`;
- los prerrequisitos son `REQUIRES`;
- la traducción no es una relación en absoluto.

Una nota sobre portabilidad: los patrones `MATCH` son [Cypher](https://opencypher.org/), pero `CREATE NODE TABLE`, `CREATE REL TABLE` y `COPY` son instrucciones de esquema e importación de LadybugDB, no de openCypher. `CALL` en sí es la cláusula de [llamada a procedimiento](https://s3.amazonaws.com/artifacts.opencypher.org/openCypher9.pdf) de openCypher; lo propio de LadybugDB es lo que esta lección llama con ella: `CALL threads = 1` fija una [opción de configuración](https://docs.ladybugdb.com/cypher/configuration/), y `show_warnings()` es una de las [funciones integradas](https://docs.ladybugdb.com/cypher/query-clauses/call/) de LadybugDB. La [página de diferencias](https://docs.ladybugdb.com/cypher/difference/) enumera lo que cambia respecto a Neo4j.

## El trazador: tres páginas, dos enlaces

La primera ejecución comprueba todo el ciclo: dos ficheros, y luego una pregunta cuya respuesta se conoce.

```cypher
CREATE NODE TABLE Page(url STRING PRIMARY KEY, locale STRING, course STRING, title STRING, lines INT64);
CREATE REL TABLE LINKS_TO(FROM Page TO Page, anchor STRING);
COPY Page FROM 'data/lab/tracer-pages.csv' (HEADER = true);
COPY LINKS_TO FROM 'data/lab/tracer-links.csv' (HEADER = true);
MATCH (a:Page {url: '/fr/lab/intro/'})-[e:LINKS_TO*1..3]->(b:Page)
WHERE b.locale = 'en'
RETURN length(e) AS links, properties(nodes(e), 'url') AS between, b.url AS reached;
```

```text
result,skipped_duplicate_pk_count,skipped_duplicate_pks
3 tuples have been copied to the Page table.,0,[]
result
2 tuples have been copied to the LINKS_TO table.
links,between,reached
2,[/fr/lab/paths/],/lab/paths/
```

Hay un recorrido de la introducción francesa a una página inglesa: dos enlaces, pasando por `/fr/lab/paths/`. Como en la [lección 2](../02-loading/), `HEADER = true` es explícito, y en un fichero de relaciones las dos primeras columnas son las claves de las páginas `FROM` y `TO` ([Import CSV](https://docs.ladybugdb.com/import/csv/)).

## Un extremo que falta, y lo que queda después

La lección 2 mostró que una sola página que falta hace fallar todo un `COPY`. Aquí la pregunta es más estrecha: **después del fallo, ¿qué hay en la tabla?** Una garantía transaccional lo respondería para todas las versiones; una medida solo lo responde para la 0.20.4. `links-missing.csv` tiene una fila buena y una fila que apunta a `/es/lab/paths/`, que no es una página.

```cypher
CALL threads = 1;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true);
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
MATCH (p:Page {url: '/lab/paths/'}) RETURN count(*) AS found_by_key;
COPY LINKS_TO FROM 'data/lab/links-missing.csv' (HEADER = true, IGNORE_ERRORS = true);
CALL show_warnings() RETURN message, line_number;
MATCH ()-[l:LINKS_TO]->() RETURN count(*) AS links;
```

```text
Error: Copy exception: Unable to find primary key value /es/lab/paths/.
links
2
found_by_key
1
result
1 tuples have been copied to the LINKS_TO table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 9
message,line_number
Unable to find primary key value /es/lab/paths/.,3
links
3
```

**Después del fallo:**
- Siguen los 2 enlaces del trazador: la fila buena del fichero fallido no se añadió.
- La página se sigue encontrando por su clave.

El [bug de índice de la lección 2](../02-loading/#un-bug-de-la-0204-un-copy-fallido-vacía-el-índice-de-clave-primaria) seguía a un `COPY` fallido en una tabla de *nodos*. Este iba a una tabla de relaciones, y no rompió el índice de nodos.

Con `IGNORE_ERRORS = true`, la fila buena entra y la mala se convierte en una advertencia, en la línea 3, siendo la cabecera la línea 1. Es una carga tolerante a propósito: la advertencia dice lo que se descartó, y no hace correcto el fichero.

## Traducciones que faltan: la identidad es la URL, no el título

`translations-pages.csv` tiene tres páginas inglesas. `/lab/intro/` y `/lab/cycles/` tienen sus páginas francesa y española, mientras que `/lab/paths/` solo tiene la francesa. Una página francesa o española lleva su URL inglesa detrás de `/fr` o `/es`, lo que da a cada grupo de traducciones una **identidad de contenido**. La consulta construye la URL hermana para cada idioma y la busca:

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.url = '/' + locale + en.url }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/paths/,es
```

El control negativo aplica la misma prueba solo a los dos grupos completos, y no encuentra nada:

```text
missing_in_complete_groups
0
```

Ahora, la versión tentadora: «una página tiene traducción si una página del otro idioma tiene el mismo título».

```cypher
MATCH (en:Page) WHERE en.locale = 'en'
UNWIND ['es', 'fr'] AS locale
WITH en, locale WHERE NOT EXISTS { MATCH (t:Page) WHERE t.locale = locale AND t.title = en.title }
RETURN en.url AS english_page, locale AS missing ORDER BY english_page, missing;
```

```text
english_page,missing
/lab/cycles/,es
/lab/intro/,es
/lab/paths/,es
/lab/paths/,fr
```

Cuatro filas, de las que tres son falsas: esas traducciones existen, con títulos traducidos («Ciclos», «Introducción», «Chemins»). «Introduction» y «Cycles» se escriben igual en francés, así que la igualdad de títulos incluso parece correcta para parte de los datos. [El primer ejercicio de la lección 2](../02-loading/#ejercicios) usa la misma identidad por URL en el sitio real.

## Ciclos de prerrequisitos, separados de la navegación

Dos ficheros de prerrequisitos:
- `requires-dag.csv`: `/lab/paths/` requiere `/lab/intro/`, y `/lab/cycles/` requiere `/lab/paths/`;
- `requires-cycle.csv`: los mismos dos, más `/lab/intro/` requiere `/lab/cycles/`, que cierra un bucle.

Los enlaces de navegación van en los dos sentidos entre `/lab/intro/` y `/lab/paths/`, como lo harían un enlace «siguiente» y uno «anterior».

Un ciclo es un camino que vuelve a su punto de partida: `(a)-[…]->(a)`. `TRAIL` prohíbe repetir una relación, como en la [lección 3](../03-paths/#senderos-trails-y-caminos-acíclicos). Primero sobre los prerrequisitos acíclicos, luego sobre la navegación:

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a) RETURN count(*) AS prerequisite_cycles;
MATCH (a:Page)-[e:LINKS_TO* TRAIL 1..3]->(a) RETURN a.url AS page, length(e) AS links ORDER BY page;
```

```text
prerequisite_cycles
0
page,links
/lab/intro/,2
/lab/paths/,2
```

**Aquí, 0 filas es una prueba, gracias a la cota.** Tres páginas tienen relaciones `REQUIRES`. Todo ciclo contiene un ciclo simple, que pasa por páginas distintas, así que un ciclo entre tres páginas tiene un ciclo simple de longitud 3 como máximo. Una cota de 3 es, por tanto, completa: ningún sendero cerrado hasta 3 significa ningún ciclo. La misma consulta sobre `LINKS_TO` encuentra el bucle de navegación, que es normal y no debe leerse como un ciclo de prerrequisitos. Por eso los prerrequisitos tienen su propia tabla.

Con el fichero del ciclo, cada sendero cerrado es un **testigo**: las páginas que se le mostrarían a alguien para probar que el ciclo existe.

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
RETURN a.url AS page, length(e) AS length, properties(nodes(e), 'url') AS through ORDER BY page;
```

```text
page,length,through
/lab/cycles/,3,"[/lab/intro/,/lab/paths/]"
/lab/intro/,3,"[/lab/paths/,/lab/cycles/]"
/lab/paths/,3,"[/lab/cycles/,/lab/intro/]"
```

**Las tres páginas y la longitud son correctas, pero el orden está invertido.** Desde `/lab/cycles/`, las flechas van a `/lab/paths/`, luego a `/lab/intro/`, y vuelven; sin embargo, la lista pone `/lab/intro/` primero. Yo había predicho el orden de las flechas, y el anexo del prerregistro deja constancia del error. Un camino abierto, desde la misma página, lista sus páginas en el sentido correcto; el sendero cerrado las lista al revés:

```cypher
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES*2..2]->(b:Page) RETURN properties(nodes(p), 'url') AS open_path;
MATCH p = (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* TRAIL 3..3]->(a) RETURN properties(nodes(p), 'url') AS closed_path;
```

```text
open_path
"[/lab/cycles/,/lab/paths/,/lab/intro/]"
closed_path
"[/lab/cycles/,/lab/intro/,/lab/paths/,/lab/cycles/]"
```

La [documentación de las funciones de camino](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/) solo muestra `nodes(p)` sobre patrones abiertos, en el orden de las flechas. En la 0.20.4, por tanto, fíese de las páginas de un testigo cerrado, no de su orden: compruebe cada paso en la tabla de relaciones antes de imprimirlo como una cadena.

## Lo que una cota de profundidad prueba, y lo que no

La cota de 3 de arriba era completa porque era al menos el número de páginas implicadas. `requires-long.csv` forma un ciclo de seis páginas, `/lab/s1/` → … → `/lab/s6/` → `/lab/s1/`:

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..5]->(a) WHERE a.url STARTS WITH '/lab/s' RETURN count(*) AS closed_trails;
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..6]->(a) WHERE a.url STARTS WITH '/lab/s'
RETURN count(*) AS closed_trails, min(length(e)) AS min_length, max(length(e)) AS max_length;
```

```text
closed_trails
0
closed_trails,min_length,max_length
6,6,6
```

Con una cota de 5, no se encuentra nada. Eso no prueba nada, porque el único ciclo es más largo que 5. Con una cota de 6, el ciclo aparece, una vez desde cada una de sus seis páginas. Para probar así que un grafo es acíclico, la cota debe ser al menos el número de páginas que tienen la relación. Por debajo del límite por defecto de 30 ([lección 3](../03-paths/#el-límite-de-profundidad)), eso solo funciona para grafos pequeños. Mi primera versión de esta consulta llamaba `shortest` a una columna, que es una palabra clave en la 0.20.4: el analizador la rechazó, y los alias pasaron a ser `min_length` y `max_length`.

Lo mismo vale para la alcanzabilidad. Estos son los prerrequisitos de `/lab/cycles/` en el fichero acíclico, con `SHORTEST`, que da un camino más corto por página, primero con una cota de 2 y luego de 1:

```cypher
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..2]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/cycles/'})-[e:REQUIRES* SHORTEST 1..1]->(b:Page) RETURN b.url AS prerequisite, length(e) AS depth ORDER BY prerequisite;
MATCH (a:Page {url: '/lab/intro/'})-[e:LINKS_TO* SHORTEST 1..2]->(b:Page) RETURN b.url AS reached, length(e) AS clicks ORDER BY reached;
```

```text
prerequisite,depth
/lab/intro/,2
/lab/paths/,1
prerequisite,depth
/lab/paths/,1
reached,clicks
/lab/cycles/,2
/lab/paths/,1
```

- **Con una cota de 1,** `/lab/intro/` desaparece. Sigue siendo un prerrequisito, solo que más lejos de lo que la cota permite.
- **En el ciclo de seis páginas,** `SHORTEST 1..3` desde `/lab/s1/` lista `/lab/s2/`, `/lab/s3/` y `/lab/s4/`, y deja fuera `/lab/s5/` y `/lab/s6/`, a 4 y 5 pasos.
- **Estar ausente de una respuesta acotada significa «no dentro de la cota», no «inalcanzable».** La última consulta sigue la navegación desde `/lab/intro/` y alcanza `/lab/cycles/`, que no es uno de sus prerrequisitos. El tipo de relación decide lo que significa la pregunta.

## Para recordar

- **Escriba las respuestas esperadas antes de ejecutar.** Un conjunto de datos lo bastante pequeño para razonar sobre él lo permite, y los fallos son resultados: aquí, un testigo impreso al revés.
- **Un `COPY` fallido en una tabla de relaciones** dejó la tabla y el índice de claves como estaban, en la 0.20.4. Es algo observado, no una garantía documentada. `IGNORE_ERRORS` es una tolerancia deliberada, con advertencias que hay que leer.
- **Encuentre las traducciones por una identidad de contenido,** aquí la URL inglesa, no por el título.
- **Guarde los prerrequisitos en su propia tabla de relaciones.** Los bucles de navegación son normales; los de prerrequisitos son errores.
- **Un sendero cerrado hasta n encuentra todos los ciclos entre n páginas.** Por debajo de esa cota, 0 filas no prueba nada, y una respuesta de alcanzabilidad acotada no dice nada más allá de su cota.
- **En la 0.20.4, `nodes()` sobre un patrón cerrado `(a)-[…]->(a)` lista las páginas en contra de las flechas.**

## Ejercicios

La solución está en [`cypher/09-exercises.cypher`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/cypher/09-exercises.cypher), comprobada por la CI.

1. Con `translations-pages.csv` y `requires-cycle.csv` cargados, ¿qué páginas de un ciclo de prerrequisitos no tienen página hermana en español?

<details>
<summary>Solución</summary>

```cypher
MATCH (a:Page)-[e:REQUIRES* TRAIL 1..3]->(a)
WHERE a.locale = 'en' AND NOT EXISTS { MATCH (t:Page) WHERE t.url = '/es' + a.url }
RETURN DISTINCT a.url AS page;
```

```text
page
/lab/paths/
```

Las tres páginas del ciclo empiezan cada una un sendero cerrado. `DISTINCT` deja una fila por página, y la identidad de contenido, `'/es' + a.url`, encuentra la que no tiene página española. La cota de 3 es completa aquí, porque tres páginas tienen relaciones `REQUIRES`.

</details>

## Fuentes

- [Import CSV](https://docs.ladybugdb.com/import/csv/): `HEADER`, `IGNORE_ERRORS`, ficheros de relaciones cuyas dos primeras columnas son las claves de los nodos (leído el 2026-09-27)
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/): patrones de longitud variable, `TRAIL`, `SHORTEST` (leído el 2026-09-27)
- [Funciones de camino](https://docs.ladybugdb.com/cypher/expressions/recursive-rel-functions/): `nodes`, `length`, `properties` (leído el 2026-09-27)
- [Diferencias entre LadybugDB y Neo4j](https://docs.ladybugdb.com/cypher/difference/) y [openCypher](https://opencypher.org/)
