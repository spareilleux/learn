---
title: 6. LadybugDB depuis Java
description: Le paquet Maven com.ladybugdb:lbug sur le graphe des projets de GuitarAlchemist/ga — des résultats qui ne lèvent pas d'exception, des tuples qui partagent un tampon, des paramètres gardés d'une exécution à l'autre, nœuds et chemins, listes, structs et maps, dates, plusieurs instructions, délais d'expiration, et une bibliothèque native laissée dans le répertoire temporaire.
sidebar:
  order: 6
---

Le même graphe que la [leçon 5](../05-csharp/), depuis Java, avec le paquet Maven [`com.ladybugdb:lbug`](https://central.sonatype.com/artifact/com.ladybugdb/lbug). Comme le paquet .NET, ce n'est pas un pilote [JDBC](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html), et il est plus éloigné de JDBC que le paquet .NET ne l'est d'ADO.NET :

| JDBC | `com.ladybugdb:lbug` 0.20.4 |
|---|---|
| `DriverManager.getConnection(url)` | `new Database(path)`, puis `new Connection(database)` |
| `Statement.executeQuery(sql)` | `connection.query(cypher)` renvoie un `QueryResult` |
| `ResultSet.next()` et `getLong(i)` | `hasNext()`, `getNext()` renvoie un `FlatTuple`, `getValue(i).getValue()` |
| `PreparedStatement.setString(1, …)` | `connection.prepare(cypher)`, puis `connection.execute(statement, map)` |
| une `SQLException` quand la requête échoue | **aucune exception** : `result.isSuccess()` et `result.getErrorMessage()` |

Le programme de cette leçon est [`java/src/main/java/graph/ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), lancé depuis `code/ladybugdb` avec `mvn -q -f java/pom.xml exec:java -Dexec.args=check` et comparé à [`java/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/expected.txt) sur les trois systèmes d'exploitation. La [page Java de la documentation](https://docs.ladybugdb.com/client-apis/java/) est courte ; la référence est le code source de [`ladybug-java`](https://github.com/LadybugDB/ladybug-java), au commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f), celui que construit la version 0.20.4 de LadybugDB.

## Le projet

```xml
<dependency>
  <groupId>com.ladybugdb</groupId>
  <artifactId>lbug</artifactId>
  <version>0.20.4</version>
</dependency>
```

Une seule dépendance, et **la même version que la CLI** : Maven Central a les versions de 0.12.0 à 0.20.4, là où NuGet s'arrête à 0.19.1. Ce qui vient avec :

- `lbug-0.20.4.jar`, 29 Mo : les classes Java et la bibliothèque native pour quatre plateformes, `linux_amd64`, `linux_arm64`, `osx_arm64` et `windows_amd64`. Il n'y en a aucune pour macOS sur Intel.
- 13 autres jars, 7 Mo : `kotlin-stdlib`, et Apache Arrow avec Jackson et FlatBuffers. Arrow sert aux méthodes Arrow de `Connection` et de `QueryResult`, que cette leçon n'utilise pas.

```java
System.out.println("LadybugDB " + Version.getVersion() + ", storage version " + Version.getStorageVersion());
// Un chemin vide : une base de données en mémoire, comme la CLI lancée sans nom de fichier
try (var database = new Database(""); var conn = new Connection(database)) {
```

```text
LadybugDB 0.20.4, storage version 47
```

`Database`, `Connection`, `QueryResult`, `PreparedStatement`, `FlatTuple` et `Value` sont [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html) : chacun détient de la mémoire native, et try-with-resources la libère. En fermer un deux fois lève `RuntimeException: Connection has been destroyed.`

## Une requête en échec ne lève pas d'exception

[Lignes 35-47](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L35-L47) :

```java
run("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
// Une requête en échec ne lève pas d'exception : le résultat dit qu'elle a échoué
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

L'erreur de la leçon 5, mais aucune exception : `query` renvoie un résultat dont `isSuccess()` vaut `false`. Le code JNI ne lève d'exception que quand le moteur ne produit aucun résultat ([`lbug_java.cpp`, lignes 735-748](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L735-L748)). Un programme qui oublie de vérifier continue avec la moitié d'un graphe ; c'est pourquoi chaque instruction de celui-ci passe par `run` ([lignes 279-289](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L279-L289)) :

```java
// Exécute une instruction, affiche la première colonne de ses lignes, et lève une exception quand elle échoue
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

`getValue()` est déclarée `<T> T getValue()` : le type est celui que demande l'appelant, sans vérification. `println(result.getNext().getValue(0).getValue())` ne compile pas, car `println(char[])` et `println(String)` correspondent toutes les deux ; le cast `(Object)` choisit.

## Des lignes, et des tuples qui partagent un tampon

[Lignes 49-69](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L49-L69) :

```java
var kept = new ArrayList<FlatTuple>();
while (result.hasNext()) {
    FlatTuple row = result.getNext();
    Object count = row.getValue(1).getValue();
    System.out.printf("%-20s %2s (%s)%n", row.getValue(0).getValue(), count, count.getClass().getName());
    kept.add(row);
}
// Les tuples renvoyés par getNext() partagent un seul tampon : ceux qu'on a gardés contiennent tous la dernière ligne
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

- `getColumnDataType(i).getID()` donne le type Cypher, `getNumTuples()` le nombre de lignes avant de les lire.
- **Chaque `getNext()` renvoie un nouvel objet `FlatTuple` sur le même tampon du moteur.** Les trois tuples gardés lisent tous `GA.Core`, la dernière ligne. La [documentation le signale](https://docs.ladybugdb.com/client-apis/java/) : copie les valeurs avant l'appel suivant. `ResultSet` a la même règle, mais on ne peut pas y garder un objet ligne par erreur.
- `resetIterator()` revient à la première ligne : contrairement à `Rows()` en C#, le résultat peut être lu deux fois.

## Paramètres

[Lignes 71-105](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L71-L105). La boucle sur quatre projets donne les décomptes de la leçon 5 (`GaApi depends on 20 projects`…) ; viennent ensuite les types et les pièges :

```java
try (var statement = connection.prepare(
        "MATCH (p:Project) WHERE COUNT { MATCH (p)-[:REFERENCES]->(:Project) } > $n RETURN count(*)")) {
    for (Object value : List.of(2, "2", new BigDecimal("2.5"), 2.5)) {
        try (var result = connection.execute(statement, Map.of("n", value))) {
            System.out.println(value.getClass().getSimpleName() + " " + value + ": " + result.getNext().getValue(0).getValue() + " projects");
        }
    }
    // Un nom mal orthographié est ignoré, et l'instruction garde la valeur de son exécution précédente
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

- `execute` prend une `Map<String, ?>`, convertie par `Connection.coerceParam` ([`Connection.java`, lignes 156-192](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Connection.java#L156-L192)). `BigDecimal` est accepté, contrairement à `decimal` en C# ; `LocalDateTime` et `null` ne le sont pas, et ces deux-là lèvent une exception.
- **Une instruction préparée se souvient de ses paramètres.** `{nom=5}` lie un paramètre que l'instruction n'a pas, sans erreur, et `$n` garde 2.5 de l'exécution précédente : 42 projets, pas les 0 que donnerait `n = 5`. La même map sur une nouvelle instruction échoue avec `Parameter n not found.` Le `PreparedStatement` de JDBC garde lui aussi ses paramètres, jusqu'à `clearParameters()`, mais il refuse un indice qui n'existe pas. L'[exercice 2](#exercices) referme le piège.
- Un paramètre ne peut pas non plus être un nom de fichier ici, et `prepare` ne lève pas d'exception : `isSuccess()` sur l'instruction.

## Nœuds, relations et chemins

Le paquet Java n'a pas de classe `Node` ni `Rel` : un nœud est une `Value`, lue avec les méthodes statiques de `ValueNodeUtil`, `ValueRelUtil` et `ValueRecursiveRelUtil` ([lignes 107-134](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L107-L134)) :

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

`properties` ([lignes 318-324](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L318-L324)) construit une map à partir de `getPropertySize`, `getPropertyNameAt` et `getPropertyValueAt`. `InternalID` a `equals`, donc la relation peut être rapprochée de son nœud. La requête est celle de la leçon 5, avec `ALL SHORTEST` et un tri, pour les mêmes raisons : pendant l'écriture de cette leçon, `GaApi` était à l'offset 47 en Java sous Windows, alors que le programme C# l'avait trouvé à 11 sur la même machine, et `SHORTEST` a choisi `GA.Business.ML`.

## Listes, structs et maps

`Value.getValue()` gère les nombres, les chaînes, les dates, `DECIMAL`, `UUID` et `BLOB`, mais pas les types imbriqués ([lignes 136-157](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L136-L157)) :

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

`getValue()` sur la `LIST` et sur la `MAP` lève une exception ([`lbug_java.cpp`, ligne 2071](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2071)) ; `LbugList`, `LbugStruct` et `LbugMap` les lisent, une `Value` à la fois. Le `toJava` du programme ([lignes 291-316](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L291-L316)) le fait récursivement, avec un `switch` sur `getDataType().getID()`, et renvoie des `List`, des `LinkedHashMap` et les valeurs de `getValue()` : ce que le paquet C# fait pour toi.

La dernière ligne est le bug d'agrégat de la leçon 5, dans le moteur 0.20.4 : 0 projet.

## Des lignes en records

Avec `toJava`, une fonction utilitaire copie les lignes dans des listes, et une `Function` les transforme ([lignes 169-174](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L169-L174)) :

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

`query` lit tout avant de rendre la main ([`rows`, lignes 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347)) : un `Stream` paresseux sur le résultat devrait le garder ouvert, et ne pourrait pas garder les tuples.

## Dates et heures

Les [lignes 176-191](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L176-L191) envoient 9 h 30 à New York sous forme d'[`Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html) et 90 minutes sous forme de [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html) :

```text
instant   TIMESTAMP    Instant 2026-09-14T13:30:00Z
literal   TIMESTAMP    Instant 2026-09-14T09:30:00Z
tz        TIMESTAMP_TZ Instant 2026-09-14T13:30:00Z
day       DATE         LocalDate 2026-09-14
duration  INTERVAL     Duration PT1H30M
month     INTERVAL     Duration PT768H
```

- Java n'a pas de `DateTime` au type inconnu : un `Instant` est un point dans le temps, stocké comme `TIMESTAMP` en UTC, et `TIMESTAMP` comme `TIMESTAMP_TZ` reviennent en `Instant`. `LocalDate` correspond à `DATE`.
- `timestamp('…-04:00')` renvoie 9 h 30, le bug de la leçon 5, en 0.20.4 ; `CAST(… AS TIMESTAMP_TZ)` renvoie 13 h 30.
- **`interval('1 month 2 days')` revient en 768 heures**, 32 jours : le binding convertit l'intervalle en secondes, en comptant un mois pour 30 jours, et construit une `Duration` ([`lbug_java.cpp`, lignes 2035-2043](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/jni/lbug_java.cpp#L2035-L2043)). Une `Duration` n'a pas de mois ; [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html) en a, mais pas d'heures. Une `Duration` envoyée en paramètre ne garde que les millisecondes.

## Erreurs, plusieurs instructions, délais d'expiration

[Lignes 193-216](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L193-L216) :

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

- Les messages sont ceux du moteur, comme en C#. Appeler `getNext()` sur un résultat en échec lève une simple `RuntimeException` avec le même message : le paquet n'a pas de classe d'exception à lui. La documentation mentionne encore une `ObjectRefDestroyedException` que la 0.20.4 n'a pas.
- **Plusieurs instructions donnent plusieurs résultats** : `hasNextQueryResult()` et `getNextQueryResult()` lisent le second décompte, que le paquet C# perd.
- `connection.setQueryTimeout(1)` arrête les marches sans borne de la leçon 3 au bout d'une milliseconde, et le résultat échoue avec `Interrupted.` ; `setQueryTimeout(0)` supprime la limite. `connection.interrupt()` fait de même depuis un autre thread. Le paquet C# n'a ni l'un ni l'autre.

## Partager un fichier, et une bibliothèque native dans le répertoire temporaire

[`check.sh`](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/check.sh) crée un fichier de base de données depuis Java, l'ouvre en lecture-écriture avec la CLI, puis de nouveau depuis Java :

```text
Table Project has been created.
created out/java/ga.lbdb with LadybugDB 0.20.4
-- the CLI, read-write
p.name
GA.Core
opened out/java/ga.lbdb: GA.Core
```

Même moteur, même version de stockage : rien à convertir, contrairement au paquet C# et à la CLI de la leçon 5.

`check.sh` lance ensuite le mode `temp`, qui compte les fichiers nommés `liblbug_java_native…` dans le répertoire temporaire ([lignes 419-428](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L419-L428)). La CI affiche, après trois exécutions du programme :

| Runner | Copies restantes |
|---|---|
| Windows | 3 copies, 43 Mo |
| Linux | 0 |
| macOS | 0 |

Au chargement de la classe `Native`, elle copie la bibliothèque native du jar dans un nouveau fichier temporaire, la charge, et demande que le fichier soit supprimé à la sortie de la JVM ([`Native.java`, lignes 53-59](https://github.com/LadybugDB/ladybug-java/blob/f2fb39f/src/main/java/com/lbugdb/Native.java#L53-L59)). Sous Linux et macOS, supprimer une bibliothèque chargée fonctionne. Sous Windows, une DLL chargée ne peut pas être supprimée, [`deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29) échoue sans un mot, et chaque démarrage de la JVM laisse 14,6 Mo dans `%TEMP%` : 13 copies, 190 Mo, sur ma machine après les exécutions de cette leçon. Un service Windows qui redémarre chaque jour laisse 5 Go par an. Le nom du fichier est aléatoire, donc les copies ne peuvent pas être réutilisées ; supprime `%TEMP%\liblbug_java_native*.so` quand aucun processus Java n'utilise LadybugDB.

## Threads et connexions

Le mode `timings`, depuis l'exécution de CI de cette leçon et sur ma machine, en millisecondes ([lignes 247-271](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L247-L271)) :

| | une requête | 4 requêtes, 1 connexion, 4 threads | 4 requêtes, 4 connexions, 4 threads |
|---|---|---|---|
| ma machine (Windows, 24 threads) | 7 | 45 | 23 |
| runner Linux | 10 | 42 | 22 |
| runner macOS | 16 | 35 | 37 |
| runner Windows | 14 | 91 | 55 |

La `Connection` Java n'a pas de verrou à elle, et quatre threads sur une connexion prennent quand même environ quatre fois une requête : le moteur verrouille chaque connexion pendant la durée d'une requête ([`client_context.cpp`, lignes 405-407](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/main/client_context.cpp#L405-L407)), donc le verrou du paquet C# n'y ajoute rien. Une connexion par thread est plus rapide, comme en C#, sauf sur le runner macOS, où les deux ont pris à peu près le même temps. `getQuerySummary()` sépare la compilation, environ 0,5 ms, de l'exécution.

## À retenir

- `com.ladybugdb:lbug` suit les versions du moteur : 0.20.4, comme la CLI. Un seul jar de 29 Mo contient la bibliothèque native pour quatre plateformes, pas macOS sur Intel.
- Une requête en échec renvoie un résultat avec `isSuccess() == false` ; rien ne lève d'exception tant que tu ne le lis pas. Vérifie chaque résultat.
- `getNext()` réutilise le tampon du moteur : copie les valeurs avant l'appel suivant. `resetIterator()` relit le résultat.
- Une instruction préparée garde les paramètres de son exécution précédente, et ignore les noms inconnus.
- `getValue()` ne lit pas les listes, les structs ni les maps : `LbugList`, `LbugStruct`, `LbugMap`, ou un convertisseur récursif.
- `Instant` et `LocalDate` pour les dates ; un `INTERVAL` devient une `Duration` avec des mois de 30 jours.
- `getNextQueryResult()`, `setQueryTimeout()` et `interrupt()` existent en Java, pas dans le paquet C#.
- Sous Windows, chaque démarrage de la JVM laisse une copie de 14,6 Mo de la bibliothèque native dans le répertoire temporaire.

## Exercices

Les solutions sont dans [`ProjectGraph.java`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java), et leur sortie dans `expected.txt` : la CI les vérifie avec le reste.

1. Écris `List<List<Object>> rows(String cypher)`, qui renvoie les lignes d'une requête sous forme d'objets Java qui restent valides après la fermeture du résultat, et lève une exception quand la requête échoue.

<details>
<summary>Solution</summary>

[Lignes 330-347](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L330-L347) :

```java
// Exercice 1 : copier chaque ligne tant que son tuple est le courant
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

Trois règles à la fois : vérifier `isSuccess()`, lire chaque tuple avant le `getNext()` suivant, et convertir chaque valeur, listes et structs compris, avec `toJava`, avant que `close()` libère le résultat. `String`, `Long` et les autres objets de `getValue()` sont des objets Java, indépendants du résultat.

</details>

2. Écris une classe `Statement` autour de `PreparedStatement` qui trouve les noms des paramètres dans le texte Cypher et refuse une exécution dont la map n'a pas exactement ces noms.

<details>
<summary>Solution</summary>

[Lignes 349-388](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L349-L388), abrégées :

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
        // … exécuter, vérifier isSuccess(), copier les lignes comme dans l'exercice 1
    }
}
```

```text
parameters: [name]
GA.Core: 85 dependents
IllegalArgumentException: expected parameters [name], got [nom]
IllegalArgumentException: expected parameters [name], got []
```

`Set.equals` compare les noms quels que soient l'ordre et le type d'ensemble. L'expression régulière trouve aussi un `$` dans une chaîne littérale, comme `'US$'` : assez bien pour les instructions de ce programme, pas pour n'importe quel Cypher. 85 des 111 projets dépendent de `GA.Core`, directement ou non.

</details>

3. L'exercice 2 de la leçon 5 cherchait des conflits de version majeure dans deux paquets. Compte, pour chaque paquet, les projets pris dans un tel conflit, en laissant de côté les 14 paquets que le `Directory.Build.props` de ga fixe à une seule version. Passe cette liste en paramètre.

<details>
<summary>Solution</summary>

[Lignes 230-245](https://github.com/spareilleux/learn/blob/2d76f0c/code/ladybugdb/java/src/main/java/graph/ProjectGraph.java#L230-L245) :

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

Une `List<String>` ne fait pas partie des types de paramètres acceptés, mais une `Value`, si : `new LbugList(Value[])` construit une liste Cypher, et `getValue()` la renvoie sous forme de `Value`. `WITH DISTINCT k.name, a.path` compte chaque projet une fois par paquet, quel que soit le nombre de ses dépendances en conflit, et évite un agrégat `DISTINCT` suivi d'un autre, le bug de la section 6. La plupart des conflits mélangent `Microsoft.Extensions.*` 9 et 10 ; `Microsoft.Extensions.AI` est la `9.4.0-preview` de `GaChatbot` contre la 10.5.1. Si ces conflits cassent la compilation ou l'exécution de ga est *à vérifier*.

</details>

## Sources

- [`com.ladybugdb:lbug` sur Maven Central](https://central.sonatype.com/artifact/com.ladybugdb/lbug), et le [dépôt `ladybug-java`](https://github.com/LadybugDB/ladybug-java) au commit [`f2fb39f`](https://github.com/LadybugDB/ladybug-java/tree/f2fb39f)
- [API Java](https://docs.ladybugdb.com/client-apis/java/) dans la documentation de LadybugDB
- [Concurrence](https://docs.ladybugdb.com/concurrency/) et [types de données](https://docs.ladybugdb.com/cypher/data-types/)
- [`java.time.Instant`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Instant.html), [`Duration`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Duration.html) et [`Period`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/time/Period.html)
- [`File.deleteOnExit`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/io/File.html#deleteOnExit%28%29), [`AutoCloseable`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/AutoCloseable.html), et le [tutoriel JDBC](https://docs.oracle.com/javase/tutorial/jdbc/basics/index.html)
