---
title: 12. Un petit projet
description: Réunir la bibliothèque de la leçon 11, une application console et leurs tests dans une solution, utiliser un package de NuGet, créer ton propre package, jeter un premier regard sur async et await, et voir ce que laissent passer la solution, les versions de packages et l'outil en ligne de commande de Guitar Alchemist.
sidebar:
  order: 12
---

Jusqu'ici, les programmes de ce cours tenaient dans un seul fichier, et la leçon 11 a ajouté une bibliothèque et ses tests. Un vrai programme compte en général plusieurs projets : une bibliothèque qui contient la logique, une application que les gens lancent, et des tests. Cette dernière leçon les réunit dans une **solution**. Elle ajoute un package de [NuGet](https://learn.microsoft.com/nuget/what-is-nuget), le gestionnaire de packages de .NET, fait de la bibliothèque ton propre package, et jette un premier regard sur `async` et `await`, la façon dont C# attend un fichier ou le réseau sans bloquer.

Le code de cette leçon se trouve dans [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) : le dossier `l12-project` avec la solution et ses trois projets, et les fichiers `l12_*.cs` de `examples`, `exercises` et `compile_fail`. `check.sh` exécute les tests, compile la solution, lance l'application console avec quelques commandes et fait un package de la bibliothèque, puis compare chaque sortie avec les fichiers de `expected/`.

## Une solution pour trois projets

Une solution est un fichier qui liste des projets, pour qu'une seule commande les compile ou les teste tous. À partir d'un dossier vide, ces commandes créent la solution, les trois projets et les références entre eux :

```sh
dotnet new sln -n Fretboard
dotnet new classlib -o Fretboard
dotnet new console -o Fretboard.App
dotnet new xunit -o Fretboard.Tests
dotnet sln add Fretboard Fretboard.App Fretboard.Tests
dotnet add Fretboard.App reference Fretboard
dotnet add Fretboard.Tests reference Fretboard
```

Avec le SDK 10, `dotnet new sln` crée `Fretboard.slnx`, une solution écrite en XML. Les SDK précédents créaient un fichier `.sln` dans un format texte plus ancien, que [`dotnet sln migrate`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln) convertit. Après `dotnet sln add`, le fichier liste les trois projets :

```xml
<Solution>
  <Project Path="Fretboard.App/Fretboard.App.csproj" />
  <Project Path="Fretboard.Tests/Fretboard.Tests.csproj" />
  <Project Path="Fretboard/Fretboard.csproj" />
</Solution>
```

Une solution ne fait que lister des projets. Ce sont les fichiers de projet qui disent quel projet en utilise quel autre, grâce à `dotnet add reference`, comme à la leçon 11. Dans le dossier de la solution, [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) compile les trois projets. `check.sh` garde leurs noms, triés, et les totaux de la fin ; la vraie sortie donne le chemin de chaque fichier compilé :

```text
Fretboard
Fretboard.App
Fretboard.Tests
0 Warning(s)
0 Error(s)
```

`dotnet test`, dans le même dossier, exécute les tests du seul projet de test :

```text
Passed!  - Failed:     0, Passed:     6, Skipped:     0, Total:     6 - Fretboard.Tests.dll (net10.0)
```

`dotnet test` ne compile que ce dont les tests ont besoin : le projet de test et la bibliothèque. Après `dotnet clean` et `dotnet test`, `check.sh` ne trouve aucun `Fretboard.App` compilé. Avec une erreur de compilation ajoutée au `Program.cs` de l'application, `dotnet test` a quand même réussi et s'est terminé avec 0, alors que `dotnet build` a échoué. Des tests qui passent ne prouvent pas que toute la solution compile : exécute aussi `dotnet build`.

La bibliothèque est le `Fretboard` de la leçon 11, avec `Guitar` inchangée, `Project` sans sa méthode `Parse`, et une nouvelle classe, `ProjectFile`, présentée plus bas. Le projet de test contient deux tests de `Guitar` et deux de `ProjectFile`.

## L'application console

`Fretboard.App` est un petit outil en ligne de commande construit sur la bibliothèque. Son premier argument nomme une commande, et les autres sont les arguments de cette commande :

```csharp
using System.Globalization;
using Fretboard;

// Un petit outil en ligne de commande construit sur la bibliothèque : le premier argument est la commande
const string Usage = "usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>";

if (args.Length == 0)
{
    Console.Error.WriteLine(Usage);
    return 1;
}

try
{
    switch (args[0])
    {
        case "fret" when args.Length == 3:
            double openString = double.Parse(args[1], CultureInfo.InvariantCulture);
            int fret = Guitar.ParseFret(args[2]);
            Console.WriteLine(Guitar.FretFrequency(openString, fret).ToString(CultureInfo.InvariantCulture));
            return 0;

        case "transpose" when args.Length >= 3:
            List<string> notes = [.. args[2..]];
            Console.WriteLine(string.Join(" ", Guitar.Transpose(notes, int.Parse(args[1]))));
            return 0;

        case "projects" when args.Length == 2:
            List<Project> projects = await ProjectFile.ReadAsync(args[1]);
            Console.WriteLine($"{projects.Count} projects, {projects.Sum(p => p.SourceFiles)} source files");
            return 0;

        default:
            Console.Error.WriteLine(Usage);
            return 1;
    }
}
catch (Exception e) when (e is FormatException or ArgumentException or IOException)
{
    // Un message et le code de sortie 1 : un script qui lance l'outil voit qu'il a échoué
    Console.Error.WriteLine($"error: {e.Message}");
    return 1;
}
```

[`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run) la lance : `--project` nomme le projet, et les mots après `--` vont au programme, dans `args`. `check.sh` exécute six commandes depuis le dossier du cours, comme `dotnet run --project l12-project/Fretboard.App -- fret 110 7`, et affiche le code de sortie après chacune. Il retire le dossier du nom du fichier manquant ; le vrai message donne son chemin complet :

```text
> fret 110 7
164.81
-> exit code 0
> transpose 2 C E G
D F# A
-> exit code 0
> projects data/ga-projects.csv
12 projects, 632 source files
-> exit code 0
> fret 110 25
error: fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
-> exit code 1
> projects missing.csv
error: Could not find file 'missing.csv'.
-> exit code 1
> (no arguments)
usage: fret <open-string-hz> <fret> | transpose <semitones> <notes...> | projects <file.csv>
-> exit code 1
```

- Le **code de sortie** dit au programme qui a lancé celui-ci s'il a réussi : 0 pour un succès, toute autre valeur pour un échec. Les instructions de niveau supérieur le renvoient avec `return`, comme le ferait `Main` ([`Main` et sa valeur de retour](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line)). Bash garde le code de la dernière commande dans `$?`, PowerShell dans `$LASTEXITCODE` ; les scripts et la CI le testent, comme le fait `check.sh`.
- Les erreurs vont sur [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), la sortie d'erreur standard, pour ne pas se mêler aux résultats quand la sortie va dans un fichier.
- `catch (Exception e) when (...)` est un [filtre d'exception](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement) : il n'attrape que les exceptions pour lesquelles la condition est vraie. Toute autre exception arrête quand même le programme, avec un code différent de zéro.
- `case "fret" when args.Length == 3` est une [garde de cas](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards) : le cas ne correspond que si le texte est `fret` et qu'il y a trois arguments.

## Un package de NuGet

La leçon 10 a lu une valeur CSV entre guillemets avec `TextFieldParser`. [CsvHelper](https://joshclose.github.io/CsvHelper/) est une bibliothèque pour les fichiers CSV, publiée sur [nuget.org](https://www.nuget.org/packages/CsvHelper/). Une application basée sur un fichier nomme un package avec une ligne `#:package`, la version après `@` ([applications basées sur des fichiers](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps)) :

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// La ligne de la leçon 10, lue cette fois par le package CsvHelper de NuGet
string line = "\"Crosby, Stills & Nash\",Suite: Judy Blue Eyes,1969";
using var parser = new CsvParser(new StringReader(line), CultureInfo.InvariantCulture);
parser.Read();
string[] fields = parser.Record!;
Console.WriteLine($"CsvHelper: {fields.Length} fields: {string.Join(" | ", fields)}");
```

```text
CsvHelper: 3 fields: Crosby, Stills & Nash | Suite: Judy Blue Eyes | 1969
```

Le premier `dotnet run` télécharge le package dans un dossier que partagent tous tes projets, le [dossier global des packages](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), `.nuget/packages` dans ton dossier personnel. La version est obligatoire : sans `@33.1.0`, la restauration s'arrête avec [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015). Le `.csproj` du message est le projet que le SDK compile en coulisse pour une application basée sur un fichier :

```text
l12_package_no_version.csproj : error NU1015: The following PackageReference item(s) do not have a version specified: CsvHelper
```

Dans un projet, [`dotnet add package`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add) écrit un `PackageReference` dans le fichier de projet. Le 3 octobre 2026, `dotnet add Fretboard package CsvHelper` a choisi la dernière version stable et a écrit ceci dans `Fretboard.csproj` :

```xml
<ItemGroup>
  <PackageReference Include="CsvHelper" Version="33.1.0" />
</ItemGroup>
```

La bibliothèque l'utilise dans `ProjectFile`, qui lit le `ga-projects.csv` de la leçon 10 et en fait des records `Project` :

```csharp
using System.Globalization;
using CsvHelper;

namespace Fretboard;

// Lit un fichier CSV de projets avec le package CsvHelper, qui connaît les valeurs entre guillemets
public static class ProjectFile
{
    // À partir de n'importe quel texte : un fichier, ou une chaîne dans un test
    public static List<Project> Read(TextReader text)
    {
        using var csv = new CsvReader(text, CultureInfo.InvariantCulture);
        return csv.GetRecords<Project>().ToList();
    }

    public static List<Project> Read(string path)
    {
        using var reader = new StreamReader(path);
        return Read(reader);
    }

    // La même chose, mais le programme peut faire autre chose pendant que le fichier est lu
    public static async Task<List<Project>> ReadAsync(string path)
    {
        string text = await File.ReadAllTextAsync(path);
        return Read(new StringReader(text));
    }
}
```

`GetRecords<Project>()` associe les colonnes de l'en-tête aux paramètres du constructeur du record, par leur nom : `Name`, `Language`, `CsFiles`, `FsFiles`. Il laisse de côté la propriété calculée `SourceFiles`. `Read` prend un [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), la classe de base de `StreamReader` et de `StringReader` : le programme lui donne un fichier, et un test peut lui donner une chaîne. Ce test vérifie les guillemets :

```csharp
    [Fact]
    public void Read_KeepsACommaInsideQuotes()
    {
        string text = """
            Name,Language,CsFiles,FsFiles
            "Demos, music theory",C#,3,0
            """;

        List<Project> projects = ProjectFile.Read(new StringReader(text));

        Assert.Equal([new Project("Demos, music theory", "C#", 3, 0)], projects);
    }
```

Le texte entre `"""` est un littéral de chaîne brute : il peut contenir des guillemets et des retours à la ligne, et son indentation, jusqu'à celle du `"""` de fermeture, est retirée ([littéraux de chaîne brute](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string)). Deux records avec les mêmes valeurs sont égaux, comme l'a montré la leçon 6, donc `Assert.Equal` peut comparer des listes de records.

**Un package avec une vulnérabilité connue.** Quand il restaure des packages, NuGet les compare à une base de données d'avis de sécurité ([audit des packages](https://learn.microsoft.com/nuget/concepts/auditing-packages)). La version 12.0.1 de Newtonsoft.Json, une bibliothèque JSON populaire, fait l'objet d'un de ces avis :

```csharp
#:package Newtonsoft.Json@12.0.1
using Newtonsoft.Json;

// Une ancienne version d'un package populaire : la restauration avertit qu'elle a une vulnérabilité connue
Console.WriteLine(JsonConvert.SerializeObject(new { Chord = "Am7", Frets = "x02010" }));
```

```text
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
l12_audit.csproj : warning NU1903: Package 'Newtonsoft.Json' 12.0.1 has a known high severity vulnerability, https://github.com/advisories/GHSA-5crp-9r3c-p9vr
{"Chord":"Am7","Frets":"x02010"}
```

L'avertissement apparaît deux fois, et le programme s'exécute. NU1903 correspond à une gravité élevée ; NU1901, NU1902 et NU1904 à une gravité faible, modérée et critique ([NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904)). La page de l'avis donne la première version corrigée : pour corriger, utilise celle-ci ou une version plus récente. Dans un projet, [`dotnet package list --vulnerable`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list) affiche un tableau de ces packages. La commande s'est terminée avec 0 même quand le tableau en listait un.

## Ton propre package

[`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack) transforme une bibliothèque en package, un fichier `.nupkg` :

```sh
dotnet pack Fretboard
```

```text
The package Fretboard.1.0.0 is missing a readme. Go to https://aka.ms/nuget/authoring-best-practices/readme to learn why package readmes are important.
Successfully created package 'Fretboard.1.0.0.nupkg'.
```

`check.sh` retire le dossier ici aussi : le package est dans `Fretboard/bin/Release`.

- Sans option, `dotnet pack` compile en Release, pas en Debug.
- La version est 1.0.0 parce que le projet n'en fixe aucune. `<Version>` dans le fichier de projet la change, et le package prend le nom du projet, sauf si `<PackageId>` en donne un autre ([propriétés des packages](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)).
- Le message sur le readme est un conseil, pas une erreur : nuget.org affiche le readme d'un package sur sa page.
- Un `.nupkg` est un fichier zip. Il contient `lib/net10.0/Fretboard.dll` et `Fretboard.nuspec`, qui décrit le package et liste CsvHelper comme dépendance : un projet qui installe Fretboard reçoit aussi CsvHelper. L'exercice 4 regarde à l'intérieur.

[`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push) publie un package sur nuget.org, avec un compte et une clé d'API. Ce cours ne le publie pas.

## Un premier regard sur `async`

Lire un fichier ou appeler un service web prend du temps, et pendant ce temps le programme ne fait qu'attendre. Avec `await`, il attend sans bloquer son thread, qui peut faire autre chose entre-temps ([programmation asynchrone](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/)). Une méthode qui renvoie une [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task) représente un travail qui se termine plus tard ; `await` l'attend et donne son résultat :

```csharp
using System.Diagnostics;

// await : le programme attend le fichier sans bloquer son thread
string[] lines = await File.ReadAllLinesAsync(Path.Combine("data", "ga-projects.csv"));
Console.WriteLine($"{lines.Length - 1} projects");

// Deux attentes d'une demi-seconde, l'une après l'autre
var watch = Stopwatch.StartNew();
await Task.Delay(500);
await Task.Delay(500);
Console.WriteLine($"One after the other, at least 1 s: {watch.ElapsedMilliseconds >= 1000}");

// Les deux mêmes attentes lancées ensemble : Task.WhenAll se termine quand les deux sont finies
watch.Restart();
Task first = Task.Delay(500);
Task second = Task.Delay(500);
await Task.WhenAll(first, second);
Console.WriteLine($"Together, under 0.9 s: {watch.ElapsedMilliseconds < 900}");
```

```text
12 projects
One after the other, at least 1 s: True
Together, under 0.9 s: True
```

- [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync) est la version asynchrone du `File.ReadAllLines` de la leçon 10 ; `await` donne son `string[]`.
- [`Task.Delay(500)`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay) est une tâche qui se termine au bout de 500 millisecondes, et [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch) mesure le temps. Deux délais attendus l'un après l'autre prennent une seconde. Lancés d'abord, puis attendus ensemble avec [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), ils prennent une demi-seconde : les deux attentes se chevauchent. Cinq exécutions ont mesuré de 1014 à 1023 ms, puis de 508 à 514 ms. Le programme affiche `True` ou `False` par rapport à des limites fixes, parce que les temps exacts changent d'une exécution à l'autre.
- Une méthode qui utilise `await` est marquée `async` et renvoie `Task`, ou `Task<T>` pour un résultat de type `T`, comme `ProjectFile.ReadAsync` renvoie `Task<List<Project>>`. Des instructions de niveau supérieur qui contiennent `await` deviennent asynchrones sans mot-clé.

L'application console attend `ReadAsync` dans sa commande `projects`, et xUnit exécute un test asynchrone, une méthode de test qui renvoie `Task` :

```csharp
    // Un test asynchrone : xUnit attend la Task avant de lire le résultat
    [Fact]
    public async Task ReadAsync_GivesTheSameProjectsAsRead()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = await ProjectFile.ReadAsync(path);

        Assert.Equal(ProjectFile.Read(path), projects);
        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

**Un `await` oublié.** Appeler une méthode asynchrone la démarre, mais sans `await` rien n'attend qu'elle se termine :

```csharp
Console.WriteLine("Before");
WriteLater();   // pas d'await : le programme continue sans attendre
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
l12_forgotten_await.cs(2,1): warning CS4014: Because this call is not awaited, execution of the current method continues before the call is completed. Consider applying the 'await' operator to the result of the call.
Before
After
```

Le compilateur avertit avec [CS4014](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors). `WriteLater` s'exécute jusqu'à son premier `await`, puis renvoie une tâche que personne n'attend. Le programme affiche `After` et se termine, et `Later` n'est jamais écrit. L'exercice 3 le corrige.

**Un constructeur ne peut pas attendre.** Un constructeur ne peut pas être `async`, donc il ne peut pas contenir `await` :

```csharp
var index = new VoicingIndex();

class VoicingIndex
{
    public VoicingIndex()
    {
        await Task.Delay(100);   // un constructeur ne peut pas être async
    }
}
```

```text
l12_constructor_await.cs(7,9): error CS4033: The 'await' operator can only be used within an async method. Consider marking this method with the 'async' modifier and changing its return type to 'Task'.
```

Écrire `public async VoicingIndex()` n'aide pas : le compilateur lit alors `async` comme un type de retour et `VoicingIndex()` comme une méthode, et signale CS0246 et CS0542. On s'en sort d'habitude avec une méthode statique asynchrone qui fait l'attente, puis appelle un constructeur qui n'attend pas, comme `static async Task<VoicingIndex> CreateAsync()`.

## Dans Guitar Alchemist

Les mesures sont faites au commit `5c3a52a`, par un [script](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes) qui lit le commit avec `git`, et par des compilations des projets de GA.

**Des projets hors de la solution.** La solution de GA, [`AllProjects.slnx`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/AllProjects.slnx), liste 75 des 111 fichiers de projet du dépôt. La CI de GA [compile](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L43) et [teste](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L103) cette solution. Un projet qui n'y est pas n'est compilé que si un projet listé le référence, comme c'est le cas pour 7 d'entre eux, ou si un workflow le nomme, et ses tests ne s'exécutent que si un workflow le nomme. Six projets de test sont hors de la solution et ne sont nommés par aucun workflow ; leurs fichiers contiennent 102 lignes avec un attribut de test. L'un d'eux, [`GA.Business.Core.Graphiti.Tests`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Graphiti.Tests/GA.Business.Core.Graphiti.Tests.csproj), ne compile pas : ses tests utilisent l'espace de noms `GA.Business.Graphiti`, et son fichier de projet ne référence aucun projet. La compilation s'arrête avec CS0234 sur ses deux lignes `using GA.Business.Graphiti...`.

**Les versions des packages.** Chaque fichier de projet de GA donne ses propres versions de packages, et 35 packages apparaissent avec deux versions ou plus ; `MongoDB.Driver` en a cinq. [`Directory.Build.props`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L32-L58) est un fichier que MSBuild importe dans chaque projet situé sous son dossier ([personnaliser la compilation par dossier](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory)). Sous le commentaire « Centralized package version alignment and vulnerability remediation » (alignement centralisé des versions de packages et correction des vulnérabilités), il essaie d'aligner certaines versions avec des lignes comme `<PackageReference Update="Microsoft.Extensions.Http" Version="10.0.0"/>`. `Update` modifie un élément qui existe déjà ([éléments MSBuild](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)), mais `Directory.Build.props` est importé au début de chaque projet, avant que les éléments `PackageReference` du projet lui-même n'existent : il n'y a encore rien à modifier. Une sonde a restauré `GA.Business.Core.Graphiti.Tests`, dont le fichier de projet demande 9.0.10, et a obtenu 9.0.10. Avec la même ligne dans `Directory.Build.targets`, que MSBuild importe à la fin, elle a obtenu 10.0.0. Dans l'ensemble des fichiers de projet de GA, 23 déclarations de ces packages donnent une autre version que la version alignée, dont 13 dans des projets de la solution. La [gestion centralisée des packages](https://learn.microsoft.com/nuget/consume-packages/central-package-management) de NuGet garde une seule version par package dans un seul fichier, `Directory.Packages.props`.

**Des avertissements réduits au silence.** Le même fichier [désactive](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Directory.Build.props#L16-L17) NU1902, NU1903 et NU1904 pour tous les projets : l'avertissement de l'exemple Newtonsoft.Json, et ses voisins de gravité modérée et critique. La CI a une [analyse de sécurité](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/ci.yml#L398-L401) qui exécute `dotnet list AllProjects.slnx package --vulnerable --include-transitive` avec `continue-on-error: true`. Même sans cette ligne, elle ne pourrait pas échouer, puisque la commande se termine avec 0 quand elle liste un package vulnérable.

**L'outil en ligne de commande.** L'application console de GA, GaCLI, n'est pas non plus dans la solution. Son propre workflow, [*Quality Check*](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/.github/workflows/quality_check.yml#L26-L29), la compile et exécute `benchmark-quality --limit 50`. Dans son `Program.cs`, 12 des 28 commandes lèvent `NotImplementedException`, dont [`benchmark-quality`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L179-L182) et `analyze-chord`, le premier exemple de son aide. Dans l'exécution [37167745677](https://github.com/GuitarAlchemist/ga/actions/runs/37167745677) de GA, sur un commit plus récent avec le même workflow et le même `Program.cs`, l'étape se termine par une `NotImplementedException` non gérée et le code de sortie 134, et l'exécution est verte : l'étape a `continue-on-error: true`. La commande `sync-mongodb` [attrape ses exceptions](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/GaCLI/Program.cs#L364-L368), affiche `Error during sync: Unable to resolve service for type 'GA.Data.MongoDB.Services.MusicalObjectsService'...` et se termine avec 0 : un script ne peut donc pas savoir qu'elle a échoué. La leçon 10 a noté que GaCLI lit `appsettings.yaml` depuis le dossier courant. Lancé depuis un autre dossier, il s'exécute, et à ce commit le fichier ne change rien : seule `sync-mongodb` lit l'une de ses deux sections, dans des réglages qu'aucun service n'utilise.

**Attendre des tâches.** GA n'a aucune méthode `async void`. Son code compilé bloque sur une tâche avec `.Wait()`, `.Result` ou `GetAwaiter().GetResult()` à 11 endroits, dont 3 dans des constructeurs, qui ne peuvent pas utiliser `await` : [`QdrantVectorIndex`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Embeddings/QdrantVectorIndex.cs#L16-L21) appelle `InitializeCollectionAsync().Wait()`. Sept autres `.Result` lisent des tâches après `await Task.WhenAll`, quand elles sont déjà terminées, comme dans [`ProductionOrchestrator`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L269-L273) : c'est le schéma de l'exemple de cette leçon.

Le [tableau QA](../journal/#qa) et le [tableau des expériences](../journal/#expériences) du journal consignent ces mesures.

## Exercices

Les solutions sont des applications basées sur un fichier, dans `exercises` ; `check.sh` les exécute depuis le dossier du cours.

### Exercice 1 — un package dans une application basée sur un fichier

Affiche les projets F# de `data/ga-projects.csv`, avec leur nombre de fichiers F# et C#, depuis une application basée sur un fichier qui lit le fichier avec CsvHelper.

<details>
<summary>Solution</summary>

```csharp
#:package CsvHelper@33.1.0
using System.Globalization;
using CsvHelper;

// Exercice 1 : les projets F# de data/ga-projects.csv, lus avec CsvHelper dans une application basée sur un fichier
using var reader = new StreamReader(Path.Combine("data", "ga-projects.csv"));
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);
foreach (Project project in csv.GetRecords<Project>().Where(p => p.Language == "F#"))
{
    Console.WriteLine($"{project.Name}: F# {project.FsFiles}, C# {project.CsFiles}");
}

record Project(string Name, string Language, int CsFiles, int FsFiles);
```

```text
GA.Business.Config: F# 11, C# 8
GA.Business.DSL: F# 49, C# 0
GA.Business.ProbabilisticGrammar: F# 6, C# 0
GA.Business.Core.Generated: F# 1, C# 0
```

`GetRecords` lit le fichier à la demande, un record à la fois, au fur et à mesure que `foreach` les réclame : les lignes `using` gardent le fichier ouvert jusqu'à la fin du programme.

</details>

### Exercice 2 — deux fichiers à la fois

Écris une méthode asynchrone qui renvoie le nombre de lignes d'un fichier. Appelle-la sur `data/ga-projects.csv` et sur `l12-project/Fretboard/Guitar.cs`, et attends les deux appels ensemble avec `Task.WhenAll`.

<details>
<summary>Solution</summary>

```csharp
// Exercice 2 : compter les lignes de deux fichiers lus en même temps
string csv = Path.Combine("data", "ga-projects.csv");
string guitar = Path.Combine("l12-project", "Fretboard", "Guitar.cs");

// Task.WhenAll sur des Task<int> donne un int[], dans l'ordre des tâches
int[] counts = await Task.WhenAll(CountLinesAsync(csv), CountLinesAsync(guitar));
Console.WriteLine($"{Path.GetFileName(csv)}: {counts[0]} lines");
Console.WriteLine($"{Path.GetFileName(guitar)}: {counts[1]} lines");

async Task<int> CountLinesAsync(string path)
{
    string[] lines = await File.ReadAllLinesAsync(path);
    return lines.Length;
}
```

```text
ga-projects.csv: 13 lines
Guitar.cs: 36 lines
```

Les deux lectures démarrent avant le premier `await`. Les résultats reviennent dans l'ordre des tâches, quelle que soit la lecture qui se termine en premier.

</details>

### Exercice 3 — l'`await` oublié

Corrige le programme de l'`await` oublié pour qu'il affiche `Before`, `Later` et `After`, sans avertissement.

<details>
<summary>Solution</summary>

```csharp
// Exercice 3 : l'await oublié, corrigé
Console.WriteLine("Before");
await WriteLater();   // le programme attend ici que WriteLater ait fini
Console.WriteLine("After");

async Task WriteLater()
{
    await Task.Delay(100);
    Console.WriteLine("Later");
}
```

```text
Before
Later
After
```

Avec `await`, les instructions de niveau supérieur deviennent elles-mêmes asynchrones, et le programme ne se termine qu'après la dernière ligne.

</details>

### Exercice 4 — dans le package

Après `dotnet pack Fretboard`, écris un programme qui liste les fichiers de `Fretboard.1.0.0.nupkg` avec [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile), puis affiche les lignes `<dependency>` de son `.nuspec`.

<details>
<summary>Solution</summary>

```csharp
using System.IO.Compression;

// Exercice 4 : ce que dotnet pack a mis dans le package de la bibliothèque, qui est un fichier zip
string package = Path.Combine("l12-project", "Fretboard", "bin", "Release", "Fretboard.1.0.0.nupkg");
using ZipArchive zip = ZipFile.OpenRead(package);
foreach (ZipArchiveEntry entry in zip.Entries)
{
    // Le nom de ce fichier de métadonnées est aléatoire : afficher un nom de remplacement à la place
    string name = entry.FullName.EndsWith(".psmdcp") ? "package/services/metadata/core-properties/(random).psmdcp" : entry.FullName;
    Console.WriteLine(name);
}

// Les packages qu'un projet qui installe Fretboard reçoit aussi
using StreamReader nuspec = new StreamReader(zip.GetEntry("Fretboard.nuspec")!.Open());
foreach (string line in nuspec.ReadToEnd().Split('\n').Where(line => line.Contains("<dependency ")))
{
    Console.WriteLine(line.Trim());
}
```

```text
_rels/.rels
Fretboard.nuspec
lib/net10.0/Fretboard.dll
[Content_Types].xml
package/services/metadata/core-properties/(random).psmdcp
<dependency id="CsvHelper" version="33.1.0" exclude="Build,Analyzers" />
```

Dans un `.nuspec`, `version="33.1.0"` veut dire 33.1.0 ou une version plus récente ([plages de versions](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges)). Les autres fichiers appartiennent au format d'empaquetage lui-même : `_rels/.rels`, `[Content_Types].xml` et les métadonnées `.psmdcp`.

</details>

## Ce qu'il faut retenir

- Une solution liste des projets ; les fichiers de projet disent quel projet en référence quel autre. `dotnet build`, dans le dossier de la solution, les compile tous. `dotnet test` ne compile que les projets de test et ce qu'ils référencent, donc une erreur de compilation dans l'application peut se cacher derrière des tests qui passent.
- Une application console lit ses arguments dans `args` et signale un succès avec le code de sortie 0, un échec avec un autre code. Les erreurs vont sur `Console.Error`.
- Un package de NuGet s'accompagne d'une version : `#:package Name@version` dans une application basée sur un fichier, un `PackageReference` écrit par `dotnet add package` dans un projet. La restauration avertit des vulnérabilités connues (NU1901 à NU1904).
- `dotnet pack` crée un `.nupkg`, un zip qui contient la bibliothèque compilée et un `.nuspec` qui liste ses dépendances.
- `await` attend une `Task` sans bloquer le thread ; une méthode qui l'utilise est `async` et renvoie `Task` ou `Task<T>`. `Task.WhenAll` attend plusieurs tâches lancées ensemble.
- Sans `await`, un appel asynchrone s'exécute tout seul, et personne ne voit sa fin ni ses exceptions ; le compilateur avertit avec CS4014. Un constructeur ne peut pas utiliser `await`.
- Dans `Directory.Build.props`, un `PackageReference Update` arrive avant les éléments du projet et ne change rien. Une étape avec `continue-on-error: true` ne peut pas faire échouer une exécution de CI.

C'est la dernière leçon du cours. Le [plan](../#plan) liste les douze. Le cours [C# avancé](../../csharp-advanced/) continue avec la mémoire, le ramasse-miettes, [`async` sous le capot](../../csharp-advanced/03-async-under-the-hood/) et des performances mesurées.

## Sources

- CLI .NET : [`dotnet sln`](https://learn.microsoft.com/dotnet/core/tools/dotnet-sln), [`dotnet build`](https://learn.microsoft.com/dotnet/core/tools/dotnet-build), [`dotnet run`](https://learn.microsoft.com/dotnet/core/tools/dotnet-run), [`dotnet package add`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-add), [`dotnet package list`](https://learn.microsoft.com/dotnet/core/tools/dotnet-package-list), [`dotnet pack`](https://learn.microsoft.com/dotnet/core/tools/dotnet-pack), [`dotnet nuget push`](https://learn.microsoft.com/dotnet/core/tools/dotnet-nuget-push), [applications basées sur des fichiers](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps), [propriétés des packages](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#package-properties)
- NuGet : [qu'est-ce que NuGet](https://learn.microsoft.com/nuget/what-is-nuget), [dossier global des packages](https://learn.microsoft.com/nuget/consume-packages/managing-the-global-packages-and-cache-folders), [audit des packages](https://learn.microsoft.com/nuget/concepts/auditing-packages), [NU1015](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1015), [NU1901–NU1904](https://learn.microsoft.com/nuget/reference/errors-and-warnings/nu1901-nu1904), [plages de versions](https://learn.microsoft.com/nuget/concepts/package-versioning#version-ranges), [gestion centralisée des packages](https://learn.microsoft.com/nuget/consume-packages/central-package-management) ; [CsvHelper](https://joshclose.github.io/CsvHelper/) sur [nuget.org](https://www.nuget.org/packages/CsvHelper/)
- C# : [programmation asynchrone](https://learn.microsoft.com/dotnet/csharp/asynchronous-programming/), [filtres d'exception](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/exception-handling-statements#the-try-catch-statement), [gardes de cas](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#case-guards), [`Main` et arguments de ligne de commande](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/main-command-line), [littéraux de chaîne brute](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/raw-string), [erreurs et avertissements des méthodes asynchrones (CS4014, CS4033)](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/async-await-errors)
- API : [`Task`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task), [`Task.Delay`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.delay), [`Task.WhenAll`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.task.whenall), [`File.ReadAllLinesAsync`](https://learn.microsoft.com/dotnet/api/system.io.file.readalllinesasync), [`Stopwatch`](https://learn.microsoft.com/dotnet/api/system.diagnostics.stopwatch), [`Console.Error`](https://learn.microsoft.com/dotnet/api/system.console.error), [`TextReader`](https://learn.microsoft.com/dotnet/api/system.io.textreader), [`ZipFile`](https://learn.microsoft.com/dotnet/api/system.io.compression.zipfile)
- MSBuild : [personnaliser la compilation par dossier](https://learn.microsoft.com/visualstudio/msbuild/customize-by-directory), [éléments des projets du SDK .NET](https://learn.microsoft.com/dotnet/core/project-sdk/msbuild-props#items)
