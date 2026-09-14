---
title: 6. LadybugDB desde Java
description: El paquete Maven com.ladybugdb:lbug sobre el grafo de proyectos de GuitarAlchemist/ga — resultados que no lanzan excepciones, tuplas que comparten un búfer, parámetros conservados entre ejecuciones, nodos y caminos, listas, structs y mapas, fechas, varias sentencias, tiempos límite y una biblioteca nativa olvidada en el directorio temporal.
sidebar:
  order: 6
---

El mismo grafo que en la [lección 5](../05-csharp/), desde Java, con el paquete Maven [`com.ladybugdb:lbug`](https://central.sonatype.com/artifact/com.ladybugdb/lbug). Como el paquete de .NET, no es un driver [JDBC](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html), y está más lejos de JDBC que el paquete de .NET de ADO.NET:

| JDBC | `com.ladybugdb:lbug` 0.20.4 |
|---|---|
| `DriverManager.getConnection(url)` | `new Database(path)`, luego `new Connection(database)` |
| `Statement.executeQuery(sql)` | `connection.query(cypher)` devuelve un `QueryResult` |
| `ResultSet.next()` y `getLong(i)` | `hasNext()`, `getNext()` devuelve un `FlatTuple`, `getValue(i).getValue()` |
| `PreparedStatement.setString(1, …)` | `connection.prepare(cypher)`, luego `connection.execute(statement, map)` |
| una `SQLException` cuando la consulta falla | **ninguna excepción**: `result.isSuccess()` y `result.getErrorMessage()` |

El programa de esta lección es [`java/src/main/java/graph/ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), ejecutado desde `code/ladybugdb` con `mvn -q -f java/pom.xml exec:java -Dexec.args=check` y comparado con [`java/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/expected.txt) en los tres sistemas operativos. La [página de Java de la documentación](https://docs.ladybugdb.com/client-apis/java/) es breve; la referencia es el código fuente de [`ladybug-java`](https://github.com/LadybugDB/ladybug-java), en el commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f), el que compila la versión 0.20.4 de LadybugDB.

## El proyecto

```xml
<dependency>
  <groupId>com.ladybugdb</groupId>
  <artifactId>lbug</artifactId>
  <version>0.20.4</version>
</dependency>
```

Una dependencia, y **la misma versión que la CLI**: Maven Central tiene las versiones de la 0.12.0 a la 0.20.4, donde NuGet se detiene en la 0.19.1. Lo que trae consigo:

- `lbug-0.20.4.jar`, 29 MB: las clases Java y la biblioteca nativa para cuatro plataformas, `linux_amd64`, `linux_arm64`, `osx_arm64` y `windows_amd64`. No hay ninguna para macOS en Intel.
- 13 jars más, 7 MB: `kotlin-stdlib`, y Apache Arrow con Jackson y FlatBuffers. Arrow sirve a los métodos Arrow de `Connection` y `QueryResult`, que esta lección no usa.

```java
System.out.println("LadybugDB " + Version.getVersion() + ", storage version " + Version.getStorageVersion());
// Una ruta vacía: una base de datos en memoria, como la CLI iniciada sin nombre de archivo
try (var database = new Database(""); var conn = new Connection(database)) {
```

```text
LadybugDB 0.20.4, storage version 47
```

`Database`, `Connection`, `QueryResult`, `PreparedStatement`, `FlatTuple` y `Value` son [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html): cada uno retiene memoria nativa, y try-with-resources la libera. Cerrar uno dos veces lanza `RuntimeException: Connection has been destroyed.`

## Una consulta fallida no lanza excepciones

[Líneas 35-47](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L35-L47):

```java
run("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
// Una consulta fallida no lanza excepciones: el resultado dice que falló
try (var result = connection.query("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true)")) {
    System.out.println("isSuccess: " + result.isSuccess() + ", " + result.getErrorMessage());
}
run("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true)");
```

```text
111 tuples have been copied to the Project table.
isSuccess: false, Copy exception: Unable to find primary key value Experiments/React/reactapp1.client/reactapp1.client.esproj.
265 tuples have been copied to the REFERENCES table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 6
```

El error de la lección 5, pero sin excepción: `query` devuelve un resultado cuyo `isSuccess()` es `false`. El código JNI solo lanza una excepción cuando el motor no produce ningún resultado ([`lbug_java.cpp`, líneas 735-748](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L735-L748)). Un programa que olvida comprobarlo sigue adelante con medio grafo, por eso cada sentencia de este pasa por `run` ([líneas 279-289](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L279-L289)):

```java
// Ejecuta una sentencia, imprime la primera columna de sus filas y lanza una excepción si falla
static void run(String cypher) {
    try (var result = connection.query(cypher)) {
        if (!result.isSuccess()) {
            throw new IllegalStateException(result.getErrorMessage());
        }
        while (result.hasNext()) {
            System.out.println((Object) result.getNext().getValue(0).getValue());
        }
    }
}
```

`getValue()` está declarado como `<T> T getValue()`: el tipo es el que pida quien llama, sin comprobación. `println(result.getNext().getValue(0).getValue())` no compila, porque `println(char[])` y `println(String)` encajan las dos; la conversión `(Object)` elige.

## Filas, y tuplas que comparten un búfer

[Líneas 49-69](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L49-L69):

```java
var kept = new ArrayList<FlatTuple>();
while (result.hasNext()) {
    FlatTuple row = result.getNext();
    Object count = row.getValue(1).getValue();
    System.out.printf("%-20s %2s (%s)%n", row.getValue(0).getValue(), count, count.getClass().getName());
    kept.add(row);
}
// Las tuplas devueltas por getNext() comparten un búfer: las conservadas contienen todas la última fila
System.out.println("kept rows: " + kept.stream().map(row -> (String) row.getValue(0).getValue()).toList());
result.resetIterator();
System.out.println("after resetIterator: " + result.getNext().getValue(0).getValue());
```

```text
core.name STRING, referenced_by INT64: 3 rows
GA.Domain.Core       57 (java.lang.Long)
GA.Domain.Services   48 (java.lang.Long)
GA.Core              32 (java.lang.Long)
kept rows: [GA.Core, GA.Core, GA.Core]
after resetIterator: GA.Domain.Core
```

- `getColumnDataType(i).getID()` da el tipo Cypher, `getNumTuples()` el número de filas antes de leerlas.
- **Cada `getNext()` devuelve un nuevo objeto `FlatTuple` sobre el mismo búfer del motor.** Las tres tuplas conservadas leen todas `GA.Core`, la última fila. La [documentación lo advierte](https://docs.ladybugdb.com/client-apis/java/): copia los valores antes de la siguiente llamada. `ResultSet` tiene la misma regla, pero ahí no puedes conservar un objeto fila por error.
- `resetIterator()` vuelve a la primera fila: a diferencia de `Rows()` en C#, el resultado se puede leer dos veces.

## Parámetros

[Líneas 71-105](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L71-L105). El bucle sobre cuatro proyectos da los recuentos de la lección 5 (`GaApi depends on 20 projects`…); luego los tipos y las trampas:

```java
try (var statement = connection.prepare(
        "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)")) {
    for (Object value : List.of(2, "2", new BigDecimal("2.5"), 2.5)) {
        try (var result = connection.execute(statement, Map.of("n", value))) {
            System.out.println(value.getClass().getSimpleName() + " " + value + ": " + result.getNext().getValue(0).getValue() + " projects");
        }
    }
    // Un nombre mal escrito se ignora, y la sentencia conserva el valor de su ejecución anterior
    try (var result = connection.execute(statement, Map.of("nom", 5))) {
        System.out.println("{nom=5} after {n=2.5}: " + result.getNext().getValue(0).getValue() + " projects");
    }
    var withNull = new HashMap<String, Object>();
    withNull.put("n", null);
    attempt(() -> connection.execute(statement, withNull));
}
```

```text
Integer 2: 42 projects
String 2: 42 projects
BigDecimal 2.5: 42 projects
Double 2.5: 42 projects
{nom=5} after {n=2.5}: 42 projects
IllegalArgumentException: Parameter 'n' is null; use Value.createNull() to bind SQL NULL.
{nom=5}, new statement: Parameter n not found.
prepare COPY FROM $file: false, Binder exception: Cannot find parameter file. This should not happen.
IllegalArgumentException: Parameter 't' has unsupported type java.time.LocalDateTime. Accepted types: Value, Boolean, Byte, Short, Integer, Long, BigInteger, Float, Double, BigDecimal, String, InternalID, UUID, LocalDate, Instant, Duration
```

- `execute` recibe un `Map<String, ?>`, convertido por `Connection.coerceParam` ([`Connection.java`, líneas 156-192](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Connection.java#L156-L192)). `BigDecimal` se acepta, a diferencia de `decimal` en C#; `LocalDateTime` y `null` no, y esos dos lanzan una excepción.
- **Una sentencia preparada recuerda sus parámetros.** `{nom=5}` asigna un parámetro que la sentencia no tiene, sin error, y `$n` conserva 2.5 de la ejecución anterior: 42 proyectos, no los 0 que daría `n = 5`. El mismo mapa en una sentencia nueva falla con `Parameter n not found.` El `PreparedStatement` de JDBC también conserva sus parámetros, hasta `clearParameters()`, pero rechaza un índice que no existe. El [ejercicio 2](#ejercicios) cierra la trampa.
- Un parámetro tampoco puede ser aquí un nombre de archivo, y `prepare` no lanza excepciones: `isSuccess()` sobre la sentencia.

## Nodos, relaciones y caminos

El paquete de Java no tiene clase `Node` ni `Rel`: un nodo es un `Value`, leído con los métodos estáticos de `ValueNodeUtil`, `ValueRelUtil` y `ValueRecursiveRelUtil` ([líneas 107-134](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L107-L134)):

```java
Value app = row.getValue(0);
appId = ValueNodeUtil.getID(app);
if (paths.isEmpty()) {
    System.out.println(ValueNodeUtil.getLabelName(app) + " (" + appId.getClass().getSimpleName() + "): " + properties(app));
}
Value path = row.getValue(1);
var nodes = new LbugList(ValueRecursiveRelUtil.getNodeList(path)).toArray();
var rels = new LbugList(ValueRecursiveRelUtil.getRelList(path)).toArray();
paths.add(rels.length + " relationships: " + String.join(" -> ",
        Arrays.stream(nodes).map(node -> (String) properties(node).get("name")).toList()));
if (firstSource == null) {
    firstSource = ValueRelUtil.getSrcID(rels[0]);
    System.out.println("first relationship: " + ValueRelUtil.getLabelName(rels[0]) + ", starts at GaApi: " + firstSource.equals(appId));
}
```

```text
Project (InternalID): {path=Apps/ga-server/GaApi/GaApi.csproj, name=GaApi, language=C#, sdk=Microsoft.NET.Sdk.Web, frameworks=net10.0, in_solution=true}
first relationship: REFERENCES, starts at GaApi: true
3 relationships: GaApi -> GA.Business.AI -> GA.Data.MongoDB -> GA.Business.Assets
3 relationships: GaApi -> GA.Business.ML -> GA.Data.MongoDB -> GA.Business.Assets
```

`properties` ([líneas 318-324](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L318-L324)) construye un mapa a partir de `getPropertySize`, `getPropertyNameAt` y `getPropertyValueAt`. `InternalID` tiene `equals`, así que la relación se puede emparejar con su nodo. La consulta es la de la lección 5, con `ALL SHORTEST` y una ordenación, por las mismas razones: mientras se escribía esta lección, `GaApi` estaba en el desplazamiento 47 en Java en Windows, donde el programa de C# lo había encontrado en el 11 en la misma máquina, y `SHORTEST` eligió `GA.Business.ML`.

## Listas, structs y mapas

`Value.getValue()` maneja números, cadenas, fechas, `DECIMAL`, `UUID` y `BLOB`, pero no los tipos anidados ([líneas 136-157](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L136-L157)):

```java
var versions = Arrays.stream(new LbugList(row.getValue(1)).toArray()).map(v -> (String) v.getValue()).sorted().toList();
var usage = new LbugStruct(row.getValue(2));
System.out.println(row.getValue(0).getValue() + ": " + String.join(", ", versions)
        + " (" + usage.getValueByFieldName("projects").getValue() + " projects)");
```

```text
Microsoft.Extensions.Hosting: 10.0.0, 10.0.5, 9.0.0, 9.0.10, 9.0.4 (12 projects)
MongoDB.Driver: 2.29.0, 2.30.0, 3.2.0, 3.2.1, 3.5.0 (14 projects)
Microsoft.Extensions.DependencyInjection: 10.0.0, 10.0.2, 9.0.0, 9.0.10 (12 projects)
RuntimeException: Type of value is not supported in value_get_value
RuntimeException: Type of value is not supported in value_get_value
LbugMap: projects = 12
DISTINCT first: MongoDB.Driver, 5 versions, 0 projects
```

`getValue()` sobre la `LIST` y sobre el `MAP` lanza una excepción ([`lbug_java.cpp`, línea 2071](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2071)); `LbugList`, `LbugStruct` y `LbugMap` los leen, un `Value` cada vez. El `toJava` del programa ([líneas 291-316](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L291-L316)) lo hace de forma recursiva, con un `switch` sobre `getDataType().getID()`, y devuelve `List`, `LinkedHashMap` y los valores de `getValue()`: lo que el paquete de C# hace por ti.

La última línea es el bug de agregación de la lección 5, en el motor 0.20.4: 0 proyectos.

## Filas como records

Con `toJava`, una función auxiliar copia las filas en listas, y una `Function` las mapea ([líneas 169-174](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L169-L174)):

```java
record Project(String name, String path, String language) {}
```

```java
query("MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
        row -> new Project((String) row.get(0), (String) row.get(1), (String) row.get(2)))
        .forEach(System.out::println);
```

```text
Project[name=FloorManager, path=Apps/FloorManager/FloorManager.csproj, language=C#]
Project[name=GaChatbot, path=Apps/GaChatbot/GaChatbot.csproj, language=C#]
Project[name=InteractiveTutorial, path=Apps/InteractiveTutorial/InteractiveTutorial.csproj, language=C#]
38 projects are not in AllProjects.slnx
```

`query` lee todo antes de devolver ([`rows`, líneas 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347)): un `Stream` perezoso sobre el resultado tendría que mantenerlo abierto, y no podría conservar las tuplas.

## Fechas y horas

Las [líneas 176-191](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L176-L191) envían las 9:30 en Nueva York como un [`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) y 90 minutos como una [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html):

```text
instant   TIMESTAMP    Instant 2026-09-14T13:30:00Z
literal   TIMESTAMP    Instant 2026-09-14T09:30:00Z
tz        TIMESTAMP_TZ Instant 2026-09-14T13:30:00Z
day       DATE         LocalDate 2026-09-14
duration  INTERVAL     Duration PT1H30M
month     INTERVAL     Duration PT768H
```

- Java no tiene `DateTime` de tipo desconocido: un `Instant` es un punto en el tiempo, almacenado como `TIMESTAMP` en UTC, y `TIMESTAMP` y `TIMESTAMP_TZ` vuelven los dos como `Instant`. `LocalDate` corresponde a `DATE`.
- `timestamp('…-04:00')` devuelve las 9:30, el bug de la lección 5, en la 0.20.4; `CAST(… AS TIMESTAMP_TZ)` devuelve las 13:30.
- **`interval('1 month 2 days')` vuelve como 768 horas**, 32 días: el binding convierte el intervalo a segundos, contando un mes como 30 días, y construye una `Duration` ([`lbug_java.cpp`, líneas 2035-2043](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2035-L2043)). Una `Duration` no tiene meses; [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html) sí, pero no horas. Una `Duration` enviada como parámetro solo conserva los milisegundos.

## Errores, varias sentencias, tiempos límite

[Líneas 193-216](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L193-L216):

```text
Binder exception: Table Projet does not exist.
RuntimeException: Binder exception: Table Projet does not exist.
Binder exception: Cannot find property nam for p.
RuntimeException: Binder exception: Cannot find property nam for p.
Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
RuntimeException: Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
projects = 111
packages = 136
timeout of 1 ms: Interrupted.
no timeout: 7793 walks
```

- Los mensajes son los del motor, como en C#. Llamar a `getNext()` sobre un resultado fallido lanza una simple `RuntimeException` con el mismo mensaje: el paquete no tiene clase de excepción propia. La documentación todavía menciona una `ObjectRefDestroyedException` que la 0.20.4 no tiene.
- **Varias sentencias dan varios resultados**: `hasNextQueryResult()` y `getNextQueryResult()` leen el segundo recuento, que el paquete de C# pierde.
- `connection.setQueryTimeout(1)` detiene los recorridos sin límite de la lección 3 tras un milisegundo, y el resultado falla con `Interrupted.`; `setQueryTimeout(0)` quita el límite. `connection.interrupt()` hace lo mismo desde otro hilo. El paquete de C# no tiene ninguno de los dos.

## Compartir un archivo, y una biblioteca nativa en el directorio temporal

[`check.sh`](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/check.sh) crea un archivo de base de datos desde Java, lo abre en lectura-escritura con la CLI, y luego otra vez desde Java:

```text
Table Project has been created.
created out/java/ga.lbdb with LadybugDB 0.20.4
-- the CLI, read-write
p.name
GA.Core
opened out/java/ga.lbdb: GA.Core
```

Mismo motor, misma versión de almacenamiento: nada que convertir, a diferencia del paquete de C# y la CLI en la lección 5.

`check.sh` ejecuta luego el modo `temp`, que cuenta los archivos llamados `liblbug_java_native…` en el directorio temporal ([líneas 419-428](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L419-L428)). La CI imprime, tras tres ejecuciones del programa:

| Runner | Copias restantes |
|---|---|
| Windows | 3 copias, 43 MB |
| Linux | 0 |
| macOS | 0 |

Al cargarse la clase `Native`, copia la biblioteca nativa del jar a un nuevo archivo temporal, la carga y pide que el archivo se borre cuando la JVM termine ([`Native.java`, líneas 53-59](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Native.java#L53-L59)). En Linux y macOS, borrar una biblioteca cargada funciona. En Windows, una DLL cargada no se puede borrar, [`deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29) falla sin decir nada, y cada arranque de la JVM deja 14,6 MB en `%TEMP%`: 13 copias, 190 MB, en mi máquina tras las ejecuciones de esta lección. Un servicio de Windows que se reinicia cada día deja 5 GB al año. El nombre del archivo es aleatorio, así que las copias no se pueden reutilizar; borra `%TEMP%\liblbug_java_native*.so` cuando ningún proceso Java use LadybugDB.

## Hilos y conexiones

Modo `timings`, de la ejecución de CI de esta lección y de mi máquina, en milisegundos ([líneas 247-271](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L247-L271)):

| | una consulta | 4 consultas, 1 conexión, 4 hilos | 4 consultas, 4 conexiones, 4 hilos |
|---|---|---|---|
| mi máquina (Windows, 24 hilos) | 7 | 45 | 23 |
| runner Linux | 10 | 42 | 22 |
| runner macOS | 16 | 35 | 37 |
| runner Windows | 14 | 91 | 55 |

La `Connection` de Java no tiene bloqueo propio, y cuatro hilos sobre una conexión siguen tardando unas cuatro veces una consulta: el motor bloquea cada conexión mientras dura una consulta ([`client_context.cpp`, líneas 405-407](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/main/client_context.cpp#L405-L407)), así que el bloqueo del paquete de C# no le añade nada. Una conexión por hilo es más rápido, como en C#, salvo en el runner de macOS, donde los dos tardaron más o menos lo mismo. `getQuerySummary()` separa la compilación, unos 0,5 ms, de la ejecución.

## Puntos clave

- `com.ladybugdb:lbug` sigue las versiones del motor: 0.20.4, como la CLI. Un único jar de 29 MB contiene la biblioteca nativa para cuatro plataformas, sin macOS en Intel.
- Una consulta fallida devuelve un resultado con `isSuccess() == false`; nada lanza una excepción hasta que lo lees. Comprueba cada resultado.
- `getNext()` reutiliza el búfer del motor: copia los valores antes de la siguiente llamada. `resetIterator()` vuelve a leer el resultado.
- Una sentencia preparada conserva los parámetros de su ejecución anterior, e ignora los nombres desconocidos.
- `getValue()` no lee listas, structs ni mapas: `LbugList`, `LbugStruct`, `LbugMap`, o un conversor recursivo.
- `Instant` y `LocalDate` para las fechas; un `INTERVAL` se convierte en una `Duration` con meses de 30 días.
- `getNextQueryResult()`, `setQueryTimeout()` e `interrupt()` existen en Java, no en el paquete de C#.
- En Windows, cada arranque de la JVM deja una copia de 14,6 MB de la biblioteca nativa en el directorio temporal.

## Ejercicios

Las soluciones están en [`ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), y su salida en `expected.txt`: la CI las comprueba con el resto.

1. Escribe `List<List<Object>> rows(String cypher)`, que devuelve las filas de una consulta como objetos Java que siguen siendo válidos después de cerrar el resultado, y lanza una excepción cuando la consulta falla.

<details>
<summary>Solución</summary>

[Líneas 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347):

```java
// Ejercicio 1: copiar cada fila mientras su tupla es la actual
static List<List<Object>> rows(String cypher) {
    try (var result = connection.query(cypher)) {
        if (!result.isSuccess()) {
            throw new IllegalStateException(result.getErrorMessage());
        }
        var rows = new ArrayList<List<Object>>();
        while (result.hasNext()) {
            var tuple = result.getNext();
            var row = new ArrayList<Object>();
            for (long i = 0; i < result.getNumColumns(); i++) {
                row.add(toJava(tuple.getValue(i)));
            }
            rows.add(row);
        }
        return rows;
    }
}
```

```text
[[AllProjects.AppHost, C#], [AllProjects.ServiceDefaults, C#], [FloorManager, C#]]
```

Tres reglas a la vez: comprobar `isSuccess()`, leer cada tupla antes del siguiente `getNext()`, y convertir cada valor, listas y structs incluidos, con `toJava`, antes de que `close()` libere el resultado. `String`, `Long` y los demás objetos de `getValue()` son objetos Java, independientes del resultado.

</details>

2. Escribe una clase `Statement` alrededor de `PreparedStatement` que encuentre los nombres de los parámetros en el texto Cypher y rechace una ejecución cuyo mapa no tenga exactamente esos nombres.

<details>
<summary>Solución</summary>

[Líneas 349-388](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L349-L388), abreviadas:

```java
static final class Statement implements AutoCloseable {
    private static final Pattern PARAMETER = Pattern.compile("\\$(\\w+)");
    final Set<String> names = new TreeSet<>();
    private final PreparedStatement prepared;

    Statement(String cypher) {
        PARAMETER.matcher(cypher).results().forEach(match -> names.add(match.group(1)));
        prepared = connection.prepare(cypher);
        if (!prepared.isSuccess()) {
            throw new IllegalStateException(prepared.getErrorMessage());
        }
    }

    List<List<Object>> execute(Map<String, ?> parameters) {
        if (!parameters.keySet().equals(names)) {
            throw new IllegalArgumentException("expected parameters " + names + ", got " + new TreeSet<>(parameters.keySet()));
        }
        // … ejecutar, comprobar isSuccess(), copiar las filas como en el ejercicio 1
    }
}
```

```text
parameters: [name]
GA.Core: 85 dependents
IllegalArgumentException: expected parameters [name], got [nom]
IllegalArgumentException: expected parameters [name], got []
```

`Set.equals` compara los nombres sea cual sea el orden y el tipo de conjunto. La expresión regular también encuentra un `$` dentro de un literal de cadena, como `'US$'`: suficiente para las sentencias de este programa, no para cualquier Cypher. 85 de los 111 proyectos dependen de `GA.Core`, directa o indirectamente.

</details>

3. El ejercicio 2 de la lección 5 buscaba conflictos de versión mayor en dos paquetes. Cuenta, para cada paquete, los proyectos en un conflicto así, dejando fuera los 14 paquetes que el `Directory.Build.props` de ga fija en una sola versión. Pasa esa lista como parámetro.

<details>
<summary>Solución</summary>

[Líneas 230-245](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L230-L245):

```java
try (var statement = new Statement("""
        MATCH (a:Project)-[ua:USES]->(k:Package), (a)-[:REFERENCES*1..10]->(b:Project)-[ub:USES]->(k)
        WHERE split_part(ua.version, '.', 1) <> split_part(ub.version, '.', 1) AND NOT list_contains($aligned, k.name)
        WITH DISTINCT k.name AS package, a.path AS project
        RETURN package, count(*) AS projects
        ORDER BY projects DESC, package
        """);
     var list = new LbugList(aligned.stream().map(Value::new).toArray(Value[]::new))) {
    statement.execute(Map.of("aligned", list.getValue())).forEach(row -> System.out.println(row.get(0) + ": " + row.get(1) + " projects"));
}
```

```text
Microsoft.Extensions.DependencyInjection: 5 projects
Microsoft.Extensions.Configuration: 4 projects
MongoDB.Driver: 4 projects
Microsoft.Extensions.Logging.Abstractions: 3 projects
Microsoft.Extensions.AI: 1 projects
Microsoft.ML.Tokenizers: 1 projects
NUnit3TestAdapter: 1 projects
```

Una `List<String>` no está entre los tipos de parámetro aceptados, pero un `Value` sí: `new LbugList(Value[])` construye una lista Cypher, y `getValue()` la devuelve como `Value`. `WITH DISTINCT k.name, a.path` cuenta cada proyecto una vez por paquete, tenga las dependencias en conflicto que tenga, y evita un agregado `DISTINCT` antes de otro, el bug de la sección 6. La mayoría de los conflictos mezclan `Microsoft.Extensions.*` 9 y 10; `Microsoft.Extensions.AI` es la `9.4.0-preview` de `GaChatbot` frente a la 10.5.1. Si estos conflictos rompen la compilación o la ejecución de ga está *por verificar*.

</details>

## Fuentes

- [`com.ladybugdb:lbug` en Maven Central](https://central.sonatype.com/artifact/com.ladybugdb/lbug), y el [repositorio `ladybug-java`](https://github.com/LadybugDB/ladybug-java) en el commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f)
- [API de Java](https://docs.ladybugdb.com/client-apis/java/) en la documentación de LadybugDB
- [Concurrencia](https://docs.ladybugdb.com/concurrency/) y [tipos de datos](https://docs.ladybugdb.com/cypher/data-types/)
- [`java.time.Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html), [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html) y [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html)
- [`File.deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29), [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html), y el [tutorial de JDBC](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html)
