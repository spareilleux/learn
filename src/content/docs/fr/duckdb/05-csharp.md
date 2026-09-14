---
title: 5. DuckDB depuis C#
description: DuckDB.NET comme fournisseur ADO.NET — connexion, data reader, paramètres, les types .NET des valeurs DuckDB, listes et structs, erreurs, Dapper, et chargement en masse avec l'appender.
sidebar:
  order: 5
---

La CLI exécute DuckDB dans son propre processus. Depuis C#, DuckDB tourne **dans ton processus**, comme une bibliothèque native appelée via [DuckDB.NET](https://duckdb.net/), un fournisseur [ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/) : `DbConnection`, `DbCommand`, `DbDataReader`, les classes que tu utilises déjà avec SQL Server ou SQLite. Le programme de cette leçon est [`csharp/CiQueries/Program.cs`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/CiQueries/Program.cs), lancé depuis `code/duckdb` et comparé à [`csharp/expected.txt`](https://github.com/spareilleux/learn/blob/main/code/duckdb/csharp/expected.txt) sur les trois systèmes d'exploitation.

## Le projet

```xml
<ItemGroup>
  <PackageReference Include="Dapper" Version="2.1.86" />
  <PackageReference Include="DuckDB.NET.Data.Full" Version="1.5.5" />
</ItemGroup>
```

DuckDB.NET existe en [quatre paquets](https://duckdb.net/docs/getting-started.html) : le fournisseur ADO.NET (`DuckDB.NET.Data`) ou les bindings de bas niveau, chacun avec ou sans la bibliothèque native de DuckDB. `.Full` l'inclut, pour toutes les plateformes, et cela a un coût :

| | Taille |
|---|---|
| `duckdb.net.bindings.full` 1.5.5 dans le cache NuGet | 420 Mo |
| `bin/Debug/net10.0` après `dotnet build` | 316 Mo |
| `dotnet publish -r linux-x64` | 69 Mo |

Un simple build copie la bibliothèque native des cinq runtimes : `win-x64` (37 Mo), `win-arm64` (43 Mo), `linux-x64` (71 Mo), `linux-arm64` (63 Mo) et `osx` (117 Mo, un seul fichier pour Intel et Apple Silicon). Publier pour un identificateur de runtime ne garde que la sienne. La version du paquet suit celle de DuckDB : 1.5.5 embarque DuckDB 1.5.5.

## Une requête avec un data reader

```csharp
// Une base de données en mémoire, comme la CLI lancée sans nom de fichier
using var connection = new DuckDBConnection("Data Source=:memory:");
connection.Open();
Console.WriteLine($"DuckDB {connection.ServerVersion}");
```

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = """
        SELECT workflowName, count(*) AS runs, count(*) FILTER (conclusion = 'failure') AS failures
        FROM 'data/runs.json'
        GROUP BY ALL
        ORDER BY runs DESC, workflowName
        LIMIT 3
        """;
    using var reader = command.ExecuteReader();
    while (reader.Read())
    {
        Console.WriteLine($"{reader.GetString(0),-24} {reader.GetInt64(1),3} runs {reader.GetInt64(2),2} failures");
    }
}
```

```text
DuckDB v1.5.5

== 1. A query with a data reader
Deploy to GitHub Pages    65 runs  2 failures
Rust course examples      18 runs  3 failures
Java course examples       7 runs  0 failures
```

Rien de nouveau pour un utilisateur d'ADO.NET, et le SQL est celui de la leçon 1, nom de fichier compris. `Data Source=file.duckdb` ouvre ou crée à la place un fichier de base de données ; c'est le sujet de la leçon 8.

`'data/runs.json'` est relatif au **répertoire de travail du processus**, pas au projet ni à l'exécutable. Lancée depuis le dossier du projet avec un chemin `../data`, la première version échouait :

```text
Unhandled exception. DuckDB.NET.Data.DuckDBException (0x80004005): IO Error: No files found that match the pattern "../data/runs.json"
```

`../data` depuis `csharp/CiQueries`, c'est `csharp/data`, qui n'existe pas. Une application qui lit des fichiers devrait construire des chemins absolus, à partir de sa configuration ou de `AppContext.BaseDirectory`.

## Paramètres

DuckDB [accepte trois syntaxes](https://duckdb.net/docs/basic-usage.html) : `?`, `$1` et `$name`. Avec `DuckDBParameter`, le nom s'écrit sans le `$` :

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT count(*) FROM read_json($path) WHERE workflowName = $workflow AND conclusion = $conclusion";
    command.Parameters.Add(new DuckDBParameter("path", "data/runs.json"));
    command.Parameters.Add(new DuckDBParameter("workflow", "Rust course examples"));
    command.Parameters.Add(new DuckDBParameter("conclusion", "failure"));
    Console.WriteLine($"Rust course failures: {command.ExecuteScalar()}");
}
```

```text
== 2. Parameters
Rust course failures: 3
```

Même le nom de fichier est un paramètre : `read_json($path)`, là où `OPENROWSET(BULK …)` de SQL Server n'accepte qu'un littéral et pousse à construire la chaîne SQL. Un chemin qui vient d'un utilisateur doit quand même être vérifié avant d'atteindre `read_json`, car DuckDB peut lire n'importe quel fichier accessible au processus.

## Les types DuckDB en types .NET

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = """
        SELECT workflowName, databaseId, createdAt, createdAt::DATE AS day, updatedAt - startedAt AS took,
               createdAt AT TIME ZONE 'UTC' AS created_utc, sum(databaseId) OVER () AS total,
               [event, conclusion] AS pair, {'event': event, 'attempt': attempt} AS info
        FROM 'data/runs.json'
        ORDER BY createdAt
        LIMIT 1
        """;
    using var reader = command.ExecuteReader();
    reader.Read();
    for (var i = 0; i < reader.FieldCount; i++)
    {
        Console.WriteLine($"{reader.GetName(i),-12} {reader.GetDataTypeName(i),-12} {reader.GetFieldType(i)}");
    }
    var createdUtc = reader.GetDateTime(5);
    Console.WriteLine($"created_utc as DateTime: {createdUtc.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture)}, Kind = {createdUtc.Kind}");
    Console.WriteLine($"created_utc as DateTimeOffset: {reader.GetFieldValue<DateTimeOffset>(5).ToString("yyyy-MM-dd HH:mm:ss zzz", CultureInfo.InvariantCulture)}");
    Console.WriteLine($"took: {reader.GetFieldValue<TimeSpan>(4)}");
}
```

```text
== 3. DuckDB types as .NET types
workflowName Varchar      System.String
databaseId   BigInt       System.Int64
createdAt    Timestamp    System.DateTime
day          Date         System.DateOnly
took         Interval     System.TimeSpan
created_utc  TimestampTz  System.DateTime
total        HugeInt      System.Numerics.BigInteger
pair         List         System.Collections.Generic.List`1[System.String]
info         Struct       System.Collections.Generic.Dictionary`2[System.String,System.Object]
created_utc as DateTime: 2026-09-13 15:53:16, Kind = Unspecified
created_utc as DateTimeOffset: 2026-09-13 15:53:16 +00:00
took: 00:00:39
```

- `DATE` devient `DateOnly`, et `INTERVAL` devient `TimeSpan`.
- `sum` d'un `BIGINT` est un `HUGEINT`, un entier sur 128 bits, donc `System.Numerics.BigInteger`, pas `long`. L'exercice 2 montre ce que cela coûte ; `CAST(sum(…) AS BIGINT)` dans le SQL évite la question.
- Un `TIMESTAMP WITH TIME ZONE` revient sous forme de `DateTime` contenant l'heure UTC, mais avec un [`Kind`](https://learn.microsoft.com/dotnet/api/system.datetime.kind) `Unspecified`, pas `Utc`. `ToUniversalTime()` traite une valeur `Unspecified` comme une heure locale et la décale : dans un programme d'essai sur cette machine (UTC−4), `15:53:16` est devenu `19:53:16`, quatre heures d'écart. `GetFieldValue<DateTimeOffset>` renvoie un `+00:00` explicite. Le réglage `TimeZone` de la session, vu à la leçon 2, ne change pas ce que reçoit C# : avec `SET TimeZone = 'Europe/Paris'`, c'est le même `15:53:16` qui est revenu.
- Les dates sont formatées avec `CultureInfo.InvariantCulture` : la première version affichait `2026-09-14 2:01:09 PM` sur cette machine, un format qui dépend des paramètres régionaux de l'utilisateur et ne correspondrait jamais à la sortie attendue par la CI.

## Listes et structs

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT labels, steps FROM 'data/jobs.json' WHERE id = 104004920113";
    using var reader = command.ExecuteReader();
    reader.Read();
    var labels = reader.GetFieldValue<List<string>>(0);
    Console.WriteLine($"labels: {string.Join(", ", labels)}");

    var asDictionaries = reader.GetFieldValue<List<Dictionary<string, object?>>>(1);
    Console.WriteLine($"first step as a dictionary: {string.Join(", ", asDictionaries[0].Select(kv => $"{kv.Key}={Format(kv.Value)}"))}");

    var steps = reader.GetFieldValue<List<Step>>(1);
    foreach (var step in steps.Take(3))
    {
        Console.WriteLine($"step {step.Number}: {step.Name}, {step.Conclusion}, {(step.Completed_At - step.Started_At).TotalSeconds} s, StartedAt = {Format(step.StartedAt)}");
    }
}
```

```csharp
// DuckDB.NET fait correspondre les champs d'une struct aux propriétés modifiables de même nom, sans tenir compte de la casse
class Step
{
    public long Number { get; set; }
    public string Name { get; set; } = "";
    public string Conclusion { get; set; } = "";
    public DateTime Started_At { get; set; }
    public DateTime Completed_At { get; set; }
    public DateTime StartedAt { get; set; }
}
```

```text
== 4. Lists and structs
labels: ubuntu-latest
first step as a dictionary: number=1, name=Set up job, conclusion=success, started_at=2026-09-14 14:01:15, completed_at=2026-09-14 14:01:19
step 1: Set up job, success, 4 s, StartedAt = 0001-01-01 00:00:00
step 2: Checkout, success, 2 s, StartedAt = 0001-01-01 00:00:00
step 3: Install, build, and upload site, success, 48 s, StartedAt = 0001-01-01 00:00:00
```

- Une `LIST` de `VARCHAR` se lit comme une `List<string>` ; une `STRUCT` comme un `Dictionary<string, object>`, ou comme une de tes classes.
- La correspondance se fait par nom de propriété, sans tenir compte de la casse : `Started_At` correspond à `started_at`. **`StartedAt`, non, et rien ne le signale** : la propriété garde sa valeur par défaut, `0001-01-01`. En C#, c'est le nom naturel qui échoue en silence. Renomme dans le SQL (exercice 1), ou vérifie les valeurs par défaut dans un test.
- Un record positionnel `record Step(long Number, …)` échoue à l'exécution : `MissingMethodException: Cannot dynamically create an instance of type 'Step'. Reason: No parameterless constructor defined.` Le type cible a besoin d'un constructeur sans paramètre et de setters, ou d'accesseurs `init`.

## Erreurs

```csharp
using (var command = connection.CreateCommand())
{
    command.CommandText = "SELECT workflow_name FROM 'data/runs.json'";
    try
    {
        command.ExecuteScalar();
    }
    catch (DuckDBException e)
    {
        Console.WriteLine($"{e.GetType().Name}, ErrorType = {e.ErrorType}");
        Console.WriteLine(e.Message.Split('\n')[0]);
    }
}
```

```text
== 5. Errors
DuckDBException, ErrorType = Invalid
Binder Error: Referenced column "workflow_name" not found in FROM clause!
```

Un seul type d'exception, `DuckDBException`, avec le même message que la CLI, suggestions et position comprises. Son `ErrorType` indique `Invalid`, pas `Binder` : pour distinguer les genres d'erreurs, le préfixe du message est plus précis que la propriété. La commande reste utilisable après l'erreur : dans un programme d'essai, la même `DuckDBCommand` a ensuite exécuté `SELECT 42` et renvoyé `42`. La leçon 6 montre que le pilote Java se comporte différemment.

## Dapper

[Dapper](https://github.com/DapperLib/Dapper) étend n'importe quelle `DbConnection`, il fonctionne donc sur `DuckDBConnection` sans adaptateur :

```csharp
var failures = connection.Query<RunSummary>(
    """
    SELECT databaseId, workflowName, createdAt, updatedAt - startedAt AS took
    FROM 'data/runs.json'
    WHERE conclusion = $conclusion AND event = $event
    ORDER BY createdAt
    LIMIT 3
    """,
    new { conclusion = "failure", @event = "push" });
foreach (var run in failures)
{
    Console.WriteLine($"{run.DatabaseId} {run.WorkflowName,-24} {Format(run.CreatedAt)} {run.Took}");
}
```

```csharp
// Dapper fait correspondre les colonnes aux paramètres du constructeur, sans tenir compte de la casse
record RunSummary(long DatabaseId, string WorkflowName, DateTime CreatedAt, TimeSpan Took);
```

```text
== 6. Dapper
34772306529 Rust course examples     2026-09-13 17:40:34 00:00:40
34772373891 Rust course examples     2026-09-13 17:41:56 00:00:31
34776807003 Rust course examples     2026-09-13 19:09:08 00:01:55
```

Les propriétés de l'objet anonyme deviennent les paramètres `$conclusion` et `$event` ; `@event` est la façon dont C# écrit une propriété qui porte le nom d'un mot-clé. Contrairement à la correspondance des structs de DuckDB.NET, Dapper remplit un record positionnel via son constructeur. Les trois pushes en échec sont les échecs du cours Rust de la leçon 2.

## Chargement en masse : l'appender

Charger des lignes un `INSERT` à la fois est lent dans toutes les bases de données. DuckDB.NET expose l'[appender](https://duckdb.org/docs/current/data/appender) de DuckDB, qui écrit les lignes directement dans le stockage d'une table :

```csharp
    const int appended = 1_000_000;
    var stopwatch = Stopwatch.StartNew();
    using (var appender = connection.CreateAppender("numbers"))
    {
        for (var i = 0; i < appended; i++)
        {
            appender.CreateRow().AppendValue(i).AppendValue($"n{i}").EndRow();
        }
    }
```

Le mode `timings` du programme charge un million de lignes avec l'appender, puis 10 000 lignes avec un `INSERT` paramétré dans une transaction. La CI affiche les temps sans les comparer :

| Runner | Appender, 1 000 000 lignes | `INSERT`, 10 000 lignes |
|---|---|---|
| `ubuntu-latest` | 256 ms | 3 165 ms |
| `windows-latest` | 331 ms | 3 917 ms |
| `macos-latest` | 226 ms | 1 312 ms |
| Cette machine (Windows, Release) | 170 ms | 1 577 ms |

Avec 100 fois plus de lignes, l'appender reste 6 à 12 fois plus rapide : par ligne, 600 à 1 200 fois plus rapide. Les lignes sont écrites quand l'appender est libéré, d'où le `using` : dans un programme d'essai, `count(*)` sur la table valait `0` après l'ajout de 10 lignes, et `10` après `Dispose()`. Pour des données déjà dans un fichier, `INSERT INTO … SELECT * FROM 'file.parquet'` est encore plus simple et ne franchit pas la frontière entre code managé et code natif pour chaque valeur.

## À retenir

- DuckDB.NET est un fournisseur ADO.NET : `DuckDBConnection`, les commandes, les readers, les transactions et Dapper fonctionnent comme avec n'importe quelle autre base de données.
- Le paquet `.Full` embarque la bibliothèque native de toutes les plateformes ; publie pour un identificateur de runtime pour n'en livrer qu'une.
- Les chemins de fichiers relatifs dans le SQL sont relatifs au répertoire de travail du processus.
- `DATE` → `DateOnly`, `INTERVAL` → `TimeSpan`, `HUGEINT` → `BigInteger`, `TIMESTAMPTZ` → `DateTime` avec un `Kind` `Unspecified`.
- Les structs correspondent aux classes par nom de propriété, et une propriété sans correspondance garde en silence sa valeur par défaut.
- Pour beaucoup de lignes, utilise l'appender, ou laisse DuckDB lire le fichier.

## Exercices

1. Modifie la classe `Step` pour que `StartedAt` reçoive l'heure de début du step sans la renommer, en ne changeant que le SQL.

<details>
<summary>Solution</summary>

Reconstruis chaque struct avec les noms qu'attend la classe, avec `list_transform` de la leçon 3 :

```sql
SELECT list_transform(steps, lambda s: {'number': s.number, 'name': s.name, 'startedAt': s.started_at}) AS steps
FROM 'data/jobs.json'
WHERE id = 104004920113
```

Avec une classe `Step` qui n'a que `Number`, `Name` et `StartedAt`, le premier step donne :

```text
1 Set up job 2026-09-14 14:01:15
```

Le SQL devient le seul endroit où le format externe (le `snake_case` de l'API GitHub) rencontre le nommage C#. Cette vérification a été faite une fois dans un programme d'essai, pas dans le programme de la CI.

</details>

2. `ExecuteScalar` sur `SELECT sum(databaseId) FROM 'data/runs.json'` renvoie un `object`. Quel est son type, et que fait `(long)command.ExecuteScalar()!` ?

<details>
<summary>Solution</summary>

`sum` d'un `BIGINT` est un `HUGEINT`, lu comme `System.Numerics.BigInteger` (section 3 du programme). Le cast lève une exception :

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.Int64'.
```

L'unboxing ne fonctionne que vers le type exact de la valeur boxée. La porte de sortie habituelle, `Convert.ToInt64(value)`, échoue aussi, car `BigInteger` n'implémente pas `IConvertible` :

```text
InvalidCastException: Unable to cast object of type 'System.Numerics.BigInteger' to type 'System.IConvertible'.
```

Ce qui fonctionne : unboxer vers le vrai type, puis convertir, `(long)(BigInteger)value`, qui a donné `4351672497299` ; ou `CAST(sum(databaseId) AS BIGINT)` dans le SQL, pour que le reader renvoie un `long`. Vérifié dans un programme d'essai, pas dans le programme de la CI.

</details>

3. Pourquoi la section 5 affiche-t-elle `e.Message.Split('\n')[0]` plutôt que le message entier ?

<details>
<summary>Solution</summary>

Le message complet tient sur plusieurs lignes, comme dans la CLI : l'erreur, `Candidate bindings: "workflowName", "conclusion"`, une ligne vide, puis la requête avec un `^` sous la position. La première ligne suffit pour un log et garde la sortie attendue courte. Garde le message complet là où un développeur le lit : le marqueur de position est la partie la plus utile d'une erreur de syntaxe dans une longue requête.

</details>

## Sources

- [Documentation de DuckDB.NET](https://duckdb.net/) : [prise en main](https://duckdb.net/docs/getting-started.html) et [utilisation de base](https://duckdb.net/docs/basic-usage.html)
- [Code source de DuckDB.NET](https://github.com/Giorgi/DuckDB.NET)
- [`DuckDB.NET.Data.Full` sur NuGet](https://www.nuget.org/packages/DuckDB.NET.Data.Full)
- [Vue d'ensemble des clients DuckDB](https://duckdb.org/docs/current/clients/overview) et [appender](https://duckdb.org/docs/current/data/appender)
- [Dapper](https://github.com/DapperLib/Dapper)
- [Vue d'ensemble d'ADO.NET](https://learn.microsoft.com/dotnet/framework/data/adonet/)
