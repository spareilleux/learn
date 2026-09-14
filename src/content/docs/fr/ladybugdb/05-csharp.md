---
title: 5. LadybugDB depuis C#
description: Le paquet NuGet LadybugDB sur le graphe des projets de GuitarAlchemist/ga — paquets natifs, lignes, paramètres et instructions préparées, nœuds et chemins, listes et structs, dates, erreurs, partage d'un fichier avec la CLI, et threads — avec un bug d'agrégat de plus et un bug de dates.
sidebar:
  order: 5
---

Depuis C#, LadybugDB s'exécute **dans ton processus**, comme une bibliothèque native appelée par le paquet NuGet [`LadybugDB`](https://www.nuget.org/packages/LadybugDB). Le paquet n'est pas un fournisseur [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/) : pas de `DbConnection`, pas de `DbDataReader`, et donc pas de [Dapper](https://www.nuget.org/packages/Dapper). Ses classes en sont pourtant proches :

| ADO.NET | `LadybugDB` 0.19.1 |
|---|---|
| une chaîne de connexion | `new Database(path, config)` : la base de données elle-même, dans ton processus |
| `DbConnection` | `new Connection(database)` : plusieurs connexions peuvent partager une même `Database` |
| `DbCommand.ExecuteReader()` | `connection.Query(cypher)` renvoie un `QueryResult` |
| `DbDataReader.Read()` et `GetInt64(i)` | `result.Rows()` : un `IEnumerable<object?[]>` |
| `DbParameter` | `connection.Execute(cypher, dictionary)` ou `Prepare(cypher)` puis `Bind(name, value)` |
| `DbException` | `LadybugException` et `LadybugQueryException` |

Le programme de cette leçon est [`csharp/ProjectGraph/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), exécuté depuis `code/ladybugdb` et comparé à [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/expected.txt) sur les trois systèmes d'exploitation. Le paquet n'a pas de page dans la documentation de LadybugDB : sa référence est le [README de `ladybug-dotnet`](https://github.com/LadybugDB/ladybug-dotnet) et son code source.

## Un nouveau graphe : les projets de GuitarAlchemist/ga

Les leçons 1 à 4 interrogeaient ce site. Les leçons 5 et 6 interrogent une solution .NET : [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga), une application de théorie musicale de 111 projets C# et F#. [`data/ga/extract.py`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/data/ga/extract.py) lit ses fichiers projet au commit [`a26a7893`](https://github.com/GuitarAlchemist/ga/commit/a26a7893) et écrit trois fichiers CSV dans [`data/ga`](https://github.com/spareilleux/learn/tree/main/code/ladybugdb/data/ga) :

| Table | Type | Source |
|---|---|---|
| `Project(path, name, language, sdk, frameworks, in_solution)` | nœud | `projects.csv` : chaque `.csproj` et `.fsproj`, et si `AllProjects.slnx` le liste |
| `Package(name)` | nœud | les paquets distincts de `package_refs.csv` |
| `REFERENCES` | relation, de `Project` à `Project` | `project_refs.csv` : les éléments `<ProjectReference>` |
| `USES(version)` | relation, de `Project` à `Package` | `package_refs.csv` : les éléments `<PackageReference>`, avec leur version |

Un graphe de dépendances, c'est ce que parcourt `dotnet build`, et ce que dessinent les diagrammes de dépendances de Visual Studio ; ici, c'est un graphe que tu peux interroger.

`version` est la version écrite dans chaque fichier projet. Le [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/a26a7893/Directory.Build.props) de ga en change certaines pour tous les projets, avec des éléments `<PackageReference Update="…" Version="…"/>` : `Microsoft.Extensions.Options`, `System.Numerics.Tensors` et douze autres. L'extraction ne les applique pas ; les requêtes de cette leçon utilisent des paquets que ce fichier ne touche pas.

## Le projet

```xml
<ItemGroup>
  <PackageReference Include="LadybugDB" Version="0.19.1" />
  <PackageReference Include="LadybugDB.Native" Version="0.19.1" />
</ItemGroup>
```

`LadybugDB` est le code managé, qui appelle l'API C du moteur avec P/Invoke. Le moteur lui-même est dans un [paquet natif par identificateur de runtime](https://learn.microsoft.com/dotnet/core/rid-catalog) : `LadybugDB.Native.win-x64`, `linux-x64`, `linux-arm64`, `osx-x64` et `osx-arm64`. `LadybugDB.Native` référence les cinq :

| | Taille |
|---|---|
| les cinq paquets natifs dans le cache NuGet | de 25 Mo (`win-x64`) à 38 Mo (`linux-x64`) chacun |
| `bin/Release/net10.0` après `dotnet build` | 131 Mo, dont 19 à 28 Mo par runtime |
| `dotnet publish -r win-x64` | 20 Mo |

Une application pour une seule plateforme peut référencer `LadybugDB.Native.win-x64` seul au lieu du méta-paquet.

**La version est en retard sur la CLI.** 0.19.1 est la dernière version sur NuGet, et le README indique que les trois premiers nombres de la version du paquet sont ceux du moteur : ce programme exécute le moteur 0.19.1, la CLI des leçons 1 à 4 est la 0.20.4. Le programme affiche les deux versions qu'il connaît ([lignes 10-14](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L10-L14)) :

```csharp
Console.WriteLine($"LadybugDB {LadybugVersion.Version}, storage version {LadybugVersion.StorageVersion}");
// Un chemin vide : une base de données en mémoire, comme la CLI lancée sans nom de fichier
using var database = new Database("");
using var connection = new Connection(database);
```

```text
LadybugDB 0.19.1, storage version 43
```

La version de stockage est le format des fichiers de base de données. Elle compte quand le programme et la CLI ouvrent le même fichier, [plus bas](#partager-un-fichier-avec-la-cli).

## Chargement : une référence vers un projet absent

Le schéma et les instructions `COPY` sont ceux de la leçon 2, envoyés un par un avec `connection.Query` ([lignes 16-32](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L16-L32)) :

```csharp
Execute("COPY Project FROM 'data/ga/projects.csv' (HEADER = true)");
try
{
    Execute("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true)");
}
catch (LadybugQueryException e)
{
    Console.WriteLine($"{e.GetType().Name}: {e.Message}");
    Execute("COPY REFERENCES FROM 'data/ga/project_refs.csv' (HEADER = true, IGNORE_ERRORS = true)");
}
```

```text
111 tuples have been copied to the Project table.
LadybugQueryException: Copy exception: Unable to find primary key value Experiments/React/reactapp1.client/reactapp1.client.esproj.
265 tuples have been copied to the REFERENCES table.
1 warnings encountered during copy. Use 'CALL show_warnings() RETURN *' to view the actual warnings. Query ID: 6
```

`Execute` est une fonction utilitaire du programme qui affiche la première colonne de chaque ligne. `ReactApp1.Server.csproj` référence `reactapp1.client.esproj`, un projet JavaScript que l'extraction n'a pas gardé : l'erreur de la [leçon 2](../02-loading/), devenue une exception .NET. La CLI affichait l'erreur et continuait ; en C#, le `COPY` en échec lève une exception et rien n'est chargé avant la nouvelle tentative avec `IGNORE_ERRORS`.

## Lignes

[Lignes 34-48](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L34-L48) :

```csharp
using (var result = connection.Query("""
    MATCH (p:Project)-[:REFERENCES]->(core:Project)
    RETURN core.name, count(*) AS referenced_by
    ORDER BY referenced_by DESC, core.name
    LIMIT 3
    """))
{
    Console.WriteLine($"{string.Join(", ", result.ColumnNames)}: {result.RowCount} rows");
    foreach (var row in result.Rows())
    {
        Console.WriteLine($"{row[0],-20} {row[1],2} ({row[1]?.GetType()})");
    }
    Console.WriteLine($"a second foreach: {result.Rows().Count()} rows");
}
```

```text
core.name, referenced_by: 3 rows
GA.Domain.Core       57 (System.Int64)
GA.Domain.Services   48 (System.Int64)
GA.Core              32 (System.Int64)
a second foreach: 0 rows
```

- `RowCount` est connu avant la première ligne : le moteur a calculé tout le résultat.
- Chaque ligne est un `object?[]`, et un `INT64` arrive boxé en `long`.
- **`Rows()` ne peut être énuméré qu'une fois**, comme un `DbDataReader`, mais sans le dire : le second `foreach` ne trouve aucune ligne, et aucune exception. `Rows()` est un itérateur sur un curseur du résultat natif ([`QueryResult.cs`, lignes 117-133](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/QueryResult.cs#L117-L133)). Appelle `.ToList()` quand tu as besoin des lignes deux fois.
- `QueryResult` est `IDisposable` : il garde de la mémoire native jusqu'à `Dispose`.

57 des 111 projets référencent `GA.Domain.Core`.

## Paramètres

Deux façons, avec un dictionnaire ou avec une instruction préparée ([lignes 51-67](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L51-L67)) :

```csharp
using (var result = connection.Execute(
    "MATCH (p:Project {name: $name})-[:REFERENCES*1..10]->(d:Project) RETURN count(DISTINCT d) AS dependencies",
    new Dictionary<string, object?> { ["name"] = "GaApi" }))
{
    Console.WriteLine($"GaApi depends on {result.Rows().Single()[0]} projects");
}
using (var statement = connection.Prepare("""
    MATCH (p:Project {name: $name})-[:REFERENCES*1..10]->(d:Project)
    RETURN count(DISTINCT d) AS dependencies
    """))
{
    foreach (var name in new[] { "GaCli", "GaMcpServer", "GA.Domain.Core" })
    {
        using var result = statement.Bind("name", name).Execute();
        Console.WriteLine($"{name} depends on {result.Rows().Single()[0]} projects");
    }
}
```

```text
GaApi depends on 20 projects
GaCli depends on 7 projects
GaMcpServer depends on 13 projects
GA.Domain.Core depends on 2 projects
```

`$name` en Cypher, `"name"` sans le `$` en C#. `Execute` avec un dictionnaire prépare l'instruction à chaque appel ; `Prepare` une fois, puis `Bind` et `Execute` pour chaque valeur, évite ce travail, comme `DbCommand.Prepare()`. `Bind` renvoie l'instruction, donc les appels s'enchaînent. L'API web, `GaApi`, dépend de 20 projets, directement ou non : le motif de longueur variable de la leçon 3 les trouve tous.

Ce que le binding accepte, et ce qu'il signale ([lignes 68-83](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L68-L83)) :

```text
int 2: 42 projects reference more than 2 projects
string "2": 42 projects reference more than 2 projects
decimal 2m: NotSupportedException: Cannot bind a parameter of type System.Decimal.
LadybugQueryException: Parameter name not found.
LadybugQueryException: Binder exception: Cannot find parameter file. This should not happen.
```

- La requête compare `COUNT { … } > $n`. Un `int` fonctionne, et la chaîne `"2"` aussi : le moteur la convertit en nombre. SQL Server fait de même avec un paramètre `nvarchar` comparé à une colonne `int`.
- Un `decimal` échoue dans le binding, avant que le moteur le voie ([`PreparedStatement.cs`, ligne 198](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L198)) : passe un `double`, ou une chaîne convertie en Cypher.
- Un dictionnaire avec `nom` au lieu de `name` échoue avec `Parameter name not found.`, sans le nom.
- Un paramètre ne peut pas être un nom de fichier : `COPY Package FROM $file` échoue à la liaison, avec un message qui dit que cela ne devrait pas arriver. Construis le nom de fichier dans l'instruction, à partir d'une valeur sûre.

## Nœuds, relations et chemins

Une requête peut renvoyer un nœud entier ou un chemin entier ([lignes 85-104](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L85-L104)) :

```csharp
using (var result = connection.Query("""
    MATCH path = (app:Project {name: 'GaApi'})-[:REFERENCES* ALL SHORTEST 1..10]->(assets:Project {name: 'GA.Business.Assets'})
    RETURN app, path
    """))
{
    var rows = result.Rows().ToList();
    var app = (Node)rows[0][0]!;
    // L'ID interne (table:position) dépend du chargement, qui diffère selon les exécutions et les machines : n'afficher que son type
    Console.WriteLine($"{app.Label} ({app.Id.GetType().Name}): {string.Join(", ", app.Properties.Select(p => $"{p.Key}={p.Value}"))}");
    // Plusieurs plus courts chemins, dans un ordre quelconque : les trier avant de les afficher
    foreach (var path in rows.Select(row => (RecursiveRel)row[1]!)
                             .Select(path => $"{path.Rels.Count} relationships: {string.Join(" -> ", path.Nodes.Select(n => n.Properties["name"]))}")
                             .Order())
    {
        Console.WriteLine(path);
    }
    var first = ((RecursiveRel)rows[0][1]!).Rels[0];
    Console.WriteLine($"first relationship: {first.Label}, starts at GaApi: {first.Source == app.Id}");
}
```

```text
Project (InternalId): path=Apps/ga-server/GaApi/GaApi.csproj, name=GaApi, language=C#, sdk=Microsoft.NET.Sdk.Web, frameworks=net10.0, in_solution=True
3 relationships: GaApi -> GA.Business.AI -> GA.Data.MongoDB -> GA.Business.Assets
3 relationships: GaApi -> GA.Business.ML -> GA.Data.MongoDB -> GA.Business.Assets
first relationship: REFERENCES, starts at GaApi: True
```

Le binding convertit les valeurs de graphe en records ([`GraphTypes.cs`](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/GraphTypes.cs)) : `Node(Id, Label, Properties)`, `Rel(Id, Source, Destination, Label, Properties)`, et `RecursiveRel(Nodes, Rels)` pour un chemin. `Properties` est un dictionnaire ; `Source` et `Destination` sont les `InternalId` des nœuds, pas les nœuds. Les `Nodes` d'un chemin nommé comprennent les deux extrémités.

La première version de cette section affichait `app.Id` et utilisait `SHORTEST`, et la CI a échoué sur les trois runners :

- l'ID de `GaApi` était `0:11` sur ma machine et sur le runner Windows, `0:47` sous Linux et macOS, avec le même fichier CSV. Un ID interne est la table et la position où le nœud a été stocké : utilise-le au sein d'un résultat, pour relier un `Rel` à ses nœuds, jamais comme une clé que tu conserves ;
- il y a deux plus courts chemins, par `GA.Business.AI` ou par `GA.Business.ML`, et `SHORTEST` a renvoyé l'un sur ma machine et l'autre sur les runners. `ALL SHORTEST` renvoie les deux, que le programme trie.

## Listes et structs

Quels paquets sont utilisés en plusieurs versions ? ([lignes 106-121](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L106-L121))

```csharp
using (var result = connection.Query("""
    MATCH (p:Project)-[u:USES]->(k:Package)
    WITH k, count(*) AS projects, collect(DISTINCT u.version) AS versions
    WHERE size(versions) > 1
    RETURN k.name, versions, {projects: projects, versions: size(versions)} AS usage
    ORDER BY size(versions) DESC, k.name
    LIMIT 3
    """))
{
    foreach (var row in result.Rows())
    {
        var versions = (object?[])row[1]!;
        var usage = (Dictionary<string, object?>)row[2]!;
        Console.WriteLine($"{row[0]}: {string.Join(", ", versions.Order())} ({usage["projects"]} projects)");
    }
}
```

```text
Microsoft.Extensions.Hosting: 10.0.0, 10.0.5, 9.0.0, 9.0.10, 9.0.4 (12 projects)
MongoDB.Driver: 2.29.0, 2.30.0, 3.2.0, 3.2.1, 3.5.0 (14 projects)
Microsoft.Extensions.DependencyInjection: 10.0.0, 10.0.2, 9.0.0, 9.0.10 (12 projects)
```

Une `LIST` arrive en `object?[]`, pas en `string[]` : convertis chaque élément. Un `STRUCT` arrive en `Dictionary<string, object?>`. `collect` ne garantit aucun ordre, donc le programme trie ; `Order()` sur des chaînes place `10.0.0` avant `9.0.0`.

`MongoDB.Driver` est utilisé en cinq versions, sur deux versions majeures. L'[exercice 2](#exercices) regarde ce que cela signifie pour les projets qui se référencent entre eux.

### Le bug d'agrégat, en 0.19.1 aussi

`count(*)` vient avant `collect(DISTINCT …)` dans la requête ci-dessus, et pas par hasard ([lignes 123-130](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L123-L130)) :

```cypher
MATCH (p:Project)-[u:USES]->(k:Package {name: 'MongoDB.Driver'})
RETURN k.name, collect(DISTINCT u.version) AS versions, count(*) AS projects
```

```text
DISTINCT first: MongoDB.Driver, 5 versions, 0 projects
```

0 projet au lieu de 14. C'est le bug du [journal](../journal/#2-countdistinct--avant-sum-rend-la-somme-null), sous une forme plus générale : avec une clé de regroupement, un agrégat qui suit un agrégat `DISTINCT` dans la même projection est faux, `NULL` pour `sum` et 0 pour `count`. Il est dans le moteur 0.19.1 du paquet comme dans la CLI 0.20.4. Le contournement est le même : mets les agrégats `DISTINCT` en dernier.

## Des lignes en records

Pas de Dapper, mais une fonction utilitaire de dix lignes convertit les lignes en record ([lignes 138-145](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L138-L145) et [249-256](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L249-L256)) :

```csharp
IEnumerable<T> Query<T>(string cypher, Func<object?[], T> map)
{
    using var result = connection.Query(cypher);
    foreach (var row in result.Rows())
    {
        yield return map(row);
    }
}
```

```csharp
foreach (var project in Query(
    "MATCH (p:Project) WHERE NOT p.in_solution RETURN p.name, p.path, p.language ORDER BY p.path LIMIT 3",
    row => new Project((string)row[0]!, (string)row[1]!, (string)row[2]!)))
{
    Console.WriteLine(project);
}
```

```text
Project { Name = FloorManager, Path = Apps/FloorManager/FloorManager.csproj, Language = C# }
Project { Name = GaChatbot, Path = Apps/GaChatbot/GaChatbot.csproj, Language = C# }
Project { Name = InteractiveTutorial, Path = Apps/InteractiveTutorial/InteractiveTutorial.csproj, Language = C# }
38 projects are not in AllProjects.slnx
```

Le `using` à l'intérieur de l'itérateur libère le résultat quand le `foreach` se termine, même quand il se termine plus tôt avec `break` ou `Single()`. 38 des 111 projets ne sont pas dans `AllProjects.slnx` : une compilation de la solution ne les compile pas.

## Dates et heures

Les [lignes 147-167](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L147-L167) envoient un `DateTimeOffset` et un `DateTime` pour 9 h 30 à New York, et comparent avec un littéral :

```csharp
using (var result = connection.Execute(
    "RETURN $offset AS offset, $local AS local, timestamp('2026-09-14T09:30:00-04:00') AS literal",
    new Dictionary<string, object?>
    {
        ["offset"] = new DateTimeOffset(2026, 9, 14, 9, 30, 0, TimeSpan.FromHours(-4)),
        ["local"] = new DateTime(2026, 9, 14, 9, 30, 0),
    }))
```

```text
offset   DateTimeOffset 2026-09-14 13:30:00 +00:00
local    DateTime 2026-09-14 09:30:00, Kind = Utc
literal  DateTime 2026-09-14 09:30:00, Kind = Utc
```

- Un `DateTimeOffset` devient un `TIMESTAMP_TZ`, stocké en UTC : il revient en 13:30 à `+00:00`, le même instant.
- Un `DateTime` devient un `TIMESTAMP`. Son [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) est ici `Unspecified`, et le binding le prend pour de l'UTC ([`PreparedStatement.cs`, lignes 168-171](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/PreparedStatement.cs#L168-L171)) ; un `DateTime` `Local` est converti avec `ToUniversalTime()`. Il revient avec `Kind = Utc`.
- **Le littéral est faux.** `timestamp('…-04:00')` renvoie 9:30 : le décalage est ignoré sans conversion, alors que le `COPY` de la leçon 4 convertissait le même texte en UTC. La CLI 0.20.4 fait de même, et `CAST(… AS TIMESTAMP)` aussi ; `CAST(… AS TIMESTAMP_TZ)` donne 13:30. Un sixième bug pour le [journal](../journal/).

## Erreurs

[Lignes 169-178](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L169-L178) :

```text
LadybugQueryException: Binder exception: Table Projet does not exist.
LadybugQueryException: Binder exception: Cannot find property nam for p.
LadybugQueryException: Runtime exception: Found duplicated primary key value Common/GA.Core/GA.Core.csproj, which violates the uniqueness constraint of the primary key column.
two statements, one result: COUNT_STAR() = 111
packages created by two statements: Test.A, Test.B
```

Chaque erreur de requête est une `LadybugQueryException`, avec le type au début du message : `Binder exception` pour ce que le moteur rejette avant l'exécution, `Runtime exception` pour ce qui échoue pendant l'exécution. Il n'y a pas de code d'erreur à tester, contrairement à `SqlException.Number`.

**Plusieurs instructions dans un même `Query` ne renvoient que le premier résultat**, et elles s'exécutent toutes : `MATCH (p:Project) RETURN count(*); MATCH (k:Package) RETURN count(*)` donne le nombre de projets, et le nombre de paquets est perdu ; les deux instructions `CREATE` ont chacune créé leur nœud. L'API C a `lbug_query_result_has_next_query_result` pour les résultats suivants ([`lbug.h`, ligne 771](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h#L771)), et `lbug_connection_interrupt` et `lbug_connection_set_query_timeout` pour arrêter une longue requête (lignes 465 et 472) ; le binding 0.19.1 n'en expose aucune. Envoie une instruction par appel.

## Partager un fichier avec la CLI

`new Database("out/net/ga.lbdb")` crée ou ouvre un fichier de base de données. [`check.sh`, lignes 14-24](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/check.sh#L14-L24), en crée un depuis C#, l'interroge avec la CLI, puis le rouvre depuis C#, deux fois :

```text
created out/net/ga.lbdb with LadybugDB 0.19.1
-- the CLI, read-only
p.name
GA.Core
opened out/net/ga.lbdb: GA.Core
-- the CLI, read-write
p.name
GA.Core
LadybugException: Failed to open Ladybug database at 'out/net/ga.lbdb'.
```

La CLI 0.20.4 lit le fichier écrit par la 0.19.1 dans les deux modes. Mais ouvert en lecture-écriture, elle convertit le fichier vers sa propre version de stockage, 47 au lieu de 43 ([`storage_version_info.h`, lignes 46-49](https://github.com/LadybugDB/ladybug/blob/v0.20.4/src/include/storage/storage_version_info.h#L46-L49)), sans message : ensuite, le programme C# ne peut plus l'ouvrir, et l'exception ne dit pas pourquoi. Avec `--read_only`, le fichier reste tel quel. Depuis C#, `new SystemConfig { ReadOnly = true }` fait de même.

Tant que le paquet est en retard sur la CLI, ouvre les fichiers de l'application avec `lbug --read_only`. Plusieurs processus peuvent ouvrir un fichier en lecture seule en même temps ; un seul peut l'ouvrir en lecture-écriture ([concurrence](https://docs.ladybugdb.com/concurrency/)).

## Threads et connexions

Le mode `timings` exécute la même requête, les 7 793 marches du graphe des projets jusqu'à 10 relations, de trois façons ([lignes 221-236](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L221-L236)). Temps en millisecondes, tirés de l'exécution de CI de cette leçon et de ma machine ; ils varient d'une exécution à l'autre, donc la CI les affiche sans les comparer :

| | une requête | 4 requêtes, 1 connexion, 4 threads | 4 requêtes, 4 connexions, 4 threads |
|---|---|---|---|
| ma machine (Windows, 24 threads) | 12 | 49 | 25 |
| runner Linux | 9 | 49 | 20 |
| runner macOS | 10 | 53 | 27 |
| runner Windows | 17 | 76 | 42 |

Une `Connection` peut être utilisée depuis plusieurs threads, mais elle prend un verrou à chaque appel ([`Connection.cs`, ligne 40](https://github.com/LadybugDB/ladybug-dotnet/blob/0f58f1a/src/LadybugDB/Connection.cs#L40)) : quatre requêtes sur une connexion prennent quatre fois plus longtemps qu'une seule. Une connexion par thread, sur la même `Database`, les exécute côte à côte. Dans une application ASP.NET Core, cela signifie une `Database` pour le processus, un singleton, et une `Connection` par requête HTTP ou par unité de travail.

## À retenir

- Le paquet `LadybugDB` n'est pas ADO.NET : `Database`, `Connection`, `Query` ou `Execute`, et `Rows()` en `object?[]`. Pas de Dapper ; un petit itérateur convertit les lignes en records.
- `LadybugDB.Native` embarque le moteur pour cinq runtimes ; un seul `LadybugDB.Native.<rid>` ou `dotnet publish -r` n'en garde qu'un. Le paquet est sur le moteur 0.19.1, en retard sur la CLI 0.20.4.
- `Rows()` s'énumère une fois : la deuxième fois, il est vide, en silence.
- Paramètres : un dictionnaire, ou `Prepare` et `Bind` pour réutiliser l'instruction. Pas de `decimal`, pas de noms de fichiers.
- Les valeurs de graphe reviennent en records `Node`, `Rel` et `RecursiveRel`. Les ID internes et le chemin choisi par `SHORTEST` peuvent différer d'une machine à l'autre.
- Un agrégat `DISTINCT` avant un autre agrégat casse ce dernier en 0.19.1 aussi ; `timestamp()` ignore le décalage de son argument.
- `Query` avec plusieurs instructions renvoie le premier résultat et les exécute toutes.
- Une ouverture en lecture-écriture par une CLI plus récente met le fichier à niveau au-delà de ce que le paquet sait lire : utilise `--read_only`.
- Une `Database` par processus, une `Connection` par thread.

## Exercices

Les solutions sont à la fin de [`Program.cs`](https://github.com/spareilleux/learn/blob/main/code/ladybugdb/csharp/ProjectGraph/Program.cs), et leur sortie est dans `expected.txt` : la CI les vérifie avec le reste.

1. Écris `List<string> Dependents(PreparedStatement statement, string name)`, qui renvoie les noms des projets qui dépendent d'un projet, directement ou non. Prépare l'instruction une fois et appelle la méthode pour `GA.Business.Assets`, `GA.Data.MongoDB` et `GaApi`. Combien de projets dépendent de `GA.Business.Assets` ?

<details>
<summary>Solution</summary>

[Lignes 180-192](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L180-L192) et [258-262](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L258-L262) :

```csharp
using (var dependents = connection.Prepare("""
    MATCH (d:Project)-[:REFERENCES*1..10]->(:Project {name: $name})
    RETURN DISTINCT d.name
    ORDER BY d.name
    """))
{
    foreach (var name in new[] { "GA.Business.Assets", "GA.Data.MongoDB", "GaApi" })
    {
        var names = Dependents(dependents, name);
        Console.WriteLine($"{name}: {names.Count} dependents{(names.Count > 0 ? $", from {names[0]} to {names[^1]}" : "")}");
    }
}
```

```csharp
static List<string> Dependents(PreparedStatement statement, string name)
{
    using var result = statement.Bind("name", name).Execute();
    return result.Rows().Select(row => (string)row[0]!).ToList();
}
```

```text
GA.Business.Assets: 31 dependents, from AllProjects.AppHost to VectorSearchBenchmark
GA.Data.MongoDB: 29 dependents, from AllProjects.AppHost to VectorSearchBenchmark
GaApi: 4 dependents, from AllProjects.AppHost to VectorSearchBenchmark
```

La flèche est inversée par rapport à la section 4 : `(d)-[…]->(:Project {name: $name})`. `ToList()` lit les lignes avant que le résultat soit libéré, et renvoie une liste que l'appelant peut énumérer autant de fois qu'il veut.

31 noms, mais 32 projets : `count(DISTINCT d)` donne 32. Deux projets s'appellent `GaApi.Tests`, dans `Tests/Apps/GaApi.Tests` et dans `Tests/GaApi.Tests`, et `DISTINCT d.name` les fusionne. `name` n'est pas la clé : `{name: $name}` peut correspondre à plusieurs nœuds, ce que `path`, la clé primaire, ne peut pas.

</details>

2. Un projet qui utilise une version majeure d'un paquet et référence, directement ou non, un projet qui en utilise une autre version majeure n'obtient qu'une seule version à la compilation : [NuGet en choisit une](https://learn.microsoft.com/nuget/concepts/dependency-resolution) pour tout le graphe de dépendances du projet. Trouve ces conflits pour `MongoDB.Driver` et `Microsoft.ML.Tokenizers`, avec une instruction préparée qui prend le nom du paquet.

<details>
<summary>Solution</summary>

[Lignes 194-210](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L194-L210) :

```csharp
using (var conflicts = connection.Prepare("""
    MATCH (a:Project)-[ua:USES]->(k:Package {name: $package}), (a)-[:REFERENCES*1..10]->(b:Project)-[ub:USES]->(k)
    WHERE split_part(ua.version, '.', 1) <> split_part(ub.version, '.', 1)
    RETURN DISTINCT a.name, ua.version, b.name, ub.version
    ORDER BY a.name, b.name
    """))
{
    foreach (var package in new[] { "MongoDB.Driver", "Microsoft.ML.Tokenizers" })
    {
        using var result = conflicts.Bind("package", package).Execute();
        foreach (var row in result.Rows())
        {
            Console.WriteLine($"{package}: {row[0]} {row[1]}, but {row[2]} {row[3]}");
        }
    }
}
```

```text
MongoDB.Driver: GA.Analytics.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GA.BSP.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GA.DocumentProcessing.Service 3.2.0, but GA.Data.MongoDB 2.30.0
MongoDB.Driver: GaApi 3.5.0, but GA.Data.MongoDB 2.30.0
Microsoft.ML.Tokenizers: GaApi 1.0.2, but GA.Business.ML 2.0.0
Microsoft.ML.Tokenizers: GaApi 1.0.2, but GA.Domain.Services 2.0.0
```

Le motif nomme `k` deux fois, donc les deux relations `USES` vont vers le même paquet. `split_part(…, 1)` extrait la version majeure.

La règle de NuGet est qu'une référence directe l'emporte. `GaApi` obtient `MongoDB.Driver` 3.5.0, et `GA.Data.MongoDB`, compilé avec la 2.30.0, s'exécute avec la 3.5.0 : une nouvelle version majeure peut avoir supprimé ce qu'appelle l'ancien code. Pour `Microsoft.ML.Tokenizers`, la référence directe est la plus basse : `GaApi` obtient la 1.0.2 alors que deux de ses dépendances demandent au moins la 2.0.0. NuGet signale cette rétrogradation avec [NU1605](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1605), une erreur par défaut dans les projets SDK, mais le `Directory.Build.props` de ga supprime NU1605 pour toute la solution. Si ces projets échouent à l'exécution, sur une méthode manquante par exemple, est *à vérifier* : je n'ai ni compilé ni exécuté ga pour cette leçon.

</details>

3. `(long)row[0]!` lit un décompte. Pourquoi `(int)row[0]!` lève-t-il une exception, et quelles sont deux façons d'obtenir un `int` ?

<details>
<summary>Solution</summary>

[Lignes 212-219](https://github.com/spareilleux/learn/blob/f6d2d07/code/ladybugdb/csharp/ProjectGraph/Program.cs#L212-L219) :

```csharp
using (var result = connection.Query("MATCH (p:Project) RETURN count(*)"))
{
    var count = result.Rows().Single()[0];
    Try(() => Console.WriteLine((int)count!));
    Console.WriteLine((int)(long)count!);
    Console.WriteLine(Convert.ToInt32(count));
}
```

```text
InvalidCastException: Unable to cast object of type 'System.Int64' to type 'System.Int32'.
111
111
```

`count(*)` est un `INT64`, et la ligne contient un `long` boxé. L'unboxing doit nommer le type exact : `(int)` sur un `object` est un unboxing, pas une [conversion numérique](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/numeric-conversions). `(int)(long)count` fait l'unboxing, puis convertit ; `Convert.ToInt32` fait les deux, et lève `OverflowException` si la valeur ne tient pas. `DbDataReader.GetInt32` a le même piège sur une colonne `bigint`, avec une autre exception.

</details>

## Sources

- [`LadybugDB` sur NuGet](https://www.nuget.org/packages/LadybugDB), [`LadybugDB.Native`](https://www.nuget.org/packages/LadybugDB.Native), et le [dépôt `ladybug-dotnet`](https://github.com/LadybugDB/ladybug-dotnet) au commit [`0f58f1a`](https://github.com/LadybugDB/ladybug-dotnet/tree/0f58f1a)
- [En-tête de l'API C de LadybugDB, `lbug.h`](https://github.com/LadybugDB/ladybug/blob/v0.19.1/src/include/c_api/lbug.h)
- [Concurrence](https://docs.ladybugdb.com/concurrency/) : bases de données en lecture seule et en lecture-écriture, connexions
- [Types de données](https://docs.ladybugdb.com/cypher/data-types/) : `TIMESTAMP`, `TIMESTAMP_TZ`, `LIST`, `STRUCT`
- [`MATCH`](https://docs.ladybugdb.com/cypher/query-clauses/match/) : plus courts chemins
- [Vue d'ensemble d'ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/), [identificateurs de runtime](https://learn.microsoft.com/dotnet/core/rid-catalog), [résolution des dépendances NuGet](https://learn.microsoft.com/nuget/concepts/dependency-resolution)
