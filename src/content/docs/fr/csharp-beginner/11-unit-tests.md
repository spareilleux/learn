---
title: 11. Tests unitaires
description: Déplacer des méthodes dans une bibliothèque, les tester avec xUnit et dotnet test, lire le message d'un test qui échoue, donner plusieurs lignes de données à un test, tester les exceptions et les nombres double, et voir ce que laissent passer les propres tests de Guitar Alchemist.
sidebar:
  order: 11
---

Jusqu'ici, `check.sh` vérifiait les programmes de ce cours en comparant toute leur sortie avec un fichier. Un **test unitaire** vérifie directement une méthode : il l'appelle avec des arguments connus et compare le résultat avec la valeur qu'elle devrait renvoyer. Un test est lui aussi un petit programme. Un **framework de test** trouve les tests, exécute chacun d'eux, compte les échecs et dit quel test a échoué et pourquoi. Cette leçon utilise [xUnit](https://xunit.net/), le framework du modèle `dotnet new xunit`, pour tester des méthodes des leçons 4, 8 et 10.

Le code de cette leçon se trouve dans [`code/csharp-beginner`](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner) : `examples/l11_by_hand.cs`, et le dossier `l11-tests` avec trois projets. `Fretboard` est une bibliothèque, `Fretboard.Tests` contient ses tests et les solutions des exercices, et les tests de `Pitfalls.Tests` échouent exprès. `check.sh` exécute [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test) sur les deux projets de test et compare un résumé avec les fichiers de `expected/`.

## Un test à la main

Un test n'a pas besoin de framework. Ce programme appelle quatre fois la méthode `FretFrequency` de la leçon 4 et compare chaque résultat avec la valeur qu'il attend :

```csharp
// Un test à la main : appeler une méthode, comparer son résultat avec la valeur attendue, et dire quelle vérification a échoué
int failed = 0;
Check("fret 12 of A2", FretFrequency(110.0, 12), 220.0);
Check("fret 7 of A2", FretFrequency(110.0, 7), 164.81);
Check("fret 5 of E2", FretFrequency(82.41, 5), 110.0);
Check("fret 1 of B3", FretFrequency(246.94, 1), 261.63);   // C4 dans une table des fréquences des notes
Console.WriteLine($"{failed} failed");

void Check(string name, double actual, double expected)
{
    if (actual == expected)
    {
        Console.WriteLine($"ok   {name}");
    }
    else
    {
        Console.WriteLine($"FAIL {name}: expected {expected}, got {actual}");
        failed++;
    }
}

// La méthode de la leçon 4
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}
```

```text
ok   fret 12 of A2
ok   fret 7 of A2
ok   fret 5 of E2
FAIL fret 1 of B3: expected 261.63, got 261.62
1 failed
```

La dernière vérification échoue, et pourtant la méthode n'est pas fausse. La valeur attendue, 261,63 Hz, est le do central (do4) dans une table de fréquences. La méthode part de 246,94, la corde de si à vide déjà arrondie à deux décimales, et une case plus haut donne 261,62. Un test qui échoue dit seulement que deux valeurs diffèrent : le code peut être faux, ou bien la valeur attendue, et c'est à toi de trouver lequel.

Le programme se termine aussi avec le code de sortie 0, comme si tout avait réussi : un script qui le lance ne peut pas savoir qu'une vérification a échoué. `check.sh` fonctionne de la même façon, avec ses lignes `ok` et `FAIL`, mais il fixe lui-même son code de sortie. Un framework de test fait ce travail pour toi.

## Une bibliothèque et un projet de test

Un projet de test ne peut pas appeler les méthodes d'une application basée sur un fichier. Les méthodes vont dans une **bibliothèque de classes**, un projet sans instructions de niveau supérieur que d'autres projets utilisent, et les tests vont dans un second projet qui la référence. Trois commandes créent les deux à partir d'un dossier vide, avec les [modèles du SDK](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates) :

```sh
dotnet new classlib -n Fretboard
dotnet new xunit -n Fretboard.Tests
dotnet add Fretboard.Tests reference Fretboard
```

Les deux premières affichent `The template "Class Library" was created successfully.` et `The template "xUnit Test Project" was created successfully.`, puis restaurent les packages ; la troisième affiche ``Reference `..\Fretboard\Fretboard.csproj` added to the project.`` sous Windows. Chaque modèle ajoute aussi un fichier d'exemple, `Class1.cs` et `UnitTest1.cs`, que cette leçon a supprimés.

La bibliothèque contient les méthodes des leçons précédentes, inchangées, sous forme de méthodes `public static` d'une classe de l'espace de noms `Fretboard` :

```csharp
namespace Fretboard;

// Des méthodes des leçons précédentes, déplacées dans une bibliothèque pour qu'un projet de test puisse les appeler
public static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

    // Leçon 4 : la fréquence d'une case, arrondie à deux décimales
    public static double FretFrequency(double openString, int fret)
    {
        double frequency = openString * Math.Pow(2, fret / 12.0);
        return Math.Round(frequency, 2);
    }

    // Leçon 4, exercice 2 : une nouvelle liste où chaque note est déplacée d'un nombre de demi-tons
    public static List<string> Transpose(List<string> notes, int semitones)
    {
        List<string> result = [];
        foreach (string note in notes)
        {
            int index = Array.IndexOf(Chromatic, note);
            int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 garde les déplacements négatifs dans 0..11
            result.Add(Chromatic[moved]);
        }
        return result;
    }

    // Leçon 8, exercice 2 : un numéro de case lu dans du texte, de 0 à 24
    public static int ParseFret(string text)
    {
        int fret = int.Parse(text);
        ArgumentOutOfRangeException.ThrowIfNegative(fret);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(fret, 24);
        return fret;
    }
}
```

Un second fichier, `Project.cs`, contient le record `Project` de la leçon 10, avec une méthode `Parse` pour une ligne de `data/ga-projects.csv`. Le fichier du projet de test, `Fretboard.Tests.csproj`, liste ce que le modèle a choisi avec le SDK 10.0.112 :

```xml
<ItemGroup>
  <PackageReference Include="coverlet.collector" Version="6.0.4" />
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
  <PackageReference Include="xunit" Version="2.9.3" />
  <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
</ItemGroup>

<ItemGroup>
  <Using Include="Xunit" />
</ItemGroup>

<ItemGroup>
  <ProjectReference Include="..\Fretboard\Fretboard.csproj" />
</ItemGroup>
```

- `xunit` apporte les attributs et `Assert`, et `<Using Include="Xunit" />` les rend disponibles dans tous les fichiers du projet sans `using`.
- `xunit.runner.visualstudio` et `Microsoft.NET.Test.Sdk` permettent à `dotnet test` et aux éditeurs de trouver et d'exécuter les tests ; `coverlet.collector` mesure quelles lignes les tests ont exécutées, quand tu le demandes.
- `ProjectReference` est la ligne qu'a écrite `dotnet add reference` : les tests peuvent maintenant utiliser les classes publiques de la bibliothèque.

Le modèle crée un projet xUnit **v2**. Le [site de xUnit](https://xunit.net/docs/getting-started/v2/netcore/cmdline) dit que la v2 est en mode maintenance, et encourage à utiliser la v3 pour tout nouveau travail ; cette leçon garde ce que donne le modèle.

## Un premier test

Un test est une méthode `public` avec l'attribut `[Fact]`, dans une classe `public` :

```csharp
    // Un fait : un seul cas, sans paramètre
    [Fact]
    public void FretFrequency_TwelfthFret_DoublesTheFrequency()
    {
        // Arrange : la corde de la à vide
        double openA = 110.0;

        // Act
        double result = Guitar.FretFrequency(openA, 12);

        // Assert : la valeur attendue vient en premier, la valeur réelle en second
        Assert.Equal(220.0, result);
    }
```

La plupart des tests ont trois étapes : **arrange**, préparer les données ; **act**, agir en appelant la méthode ; **assert**, vérifier que le résultat est celui attendu. [`Assert.Equal`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) lève une exception quand ses deux valeurs diffèrent, et xUnit compte alors le test comme échoué. Le nom du test dit ce qu'il teste, dans quelle situation, et ce qui doit se passer : quand il échoue, le nom suffit à dire ce qui est cassé.

`dotnet test` compile la bibliothèque et le projet de test, puis exécute tous les tests :

```sh
dotnet test l11-tests/Fretboard.Tests
```

La commande affiche les lignes de la restauration et de la compilation, puis une ligne par projet de test. `check.sh` garde cette dernière ligne, sans sa durée, qui change à chaque exécution :

```text
Passed!  - Failed:     0, Passed:    26, Skipped:     0, Total:    26 - Fretboard.Tests.dll (net10.0)
```

Les 26 tests sont ceux de cette leçon et les solutions de ses exercices. La commande se termine avec le code de sortie 0, et avec 1 dès qu'un test échoue : un script ou une tâche de CI voit l'échec sans lire le texte.

Les records se comparent par valeur (leçon 6), donc un seul `Assert.Equal` vérifie les quatre champs que lit `Project.Parse`, et [`Assert.Throws`](https://xunit.net/docs/getting-started/v2/netcore/cmdline) vérifie qu'une méthode lève une exception :

```csharp
    [Fact]
    public void Parse_ReadsTheFourFields()
    {
        Project project = Project.Parse("GA.Core,C#,67,0");

        // Les records se comparent par valeur : un seul Assert vérifie les quatre champs
        Assert.Equal(new Project("GA.Core", "C#", 67, 0), project);
    }

    [Fact]
    public void Parse_RefusesALineWithoutNumbers()
    {
        Assert.Throws<FormatException>(() => Project.Parse("GA.Core,C#,many,0"));
    }
```

La lambda, `() => Project.Parse(...)`, donne à `Assert.Throws` l'appel à faire au lieu de le faire : l'exception se produit à l'intérieur d'`Assert.Throws`, qui l'attrape et vérifie son type.

## Plusieurs cas dans un seul test

Une théorie, `[Theory]`, est un test avec des paramètres, et chaque attribut `[InlineData]` lui donne une ligne d'arguments :

```csharp
    // Une théorie : le même test avec plusieurs lignes de données, chaque ligne étant un test à part
    [Theory]
    [InlineData(110.0, 0, 110.0)]
    [InlineData(110.0, 7, 164.81)]
    [InlineData(82.41, 5, 110.0)]
    [InlineData(110.0, 12, 220.0)]
    public void FretFrequency_RoundsToTwoDecimals(double openString, int fret, double expected)
    {
        Assert.Equal(expected, Guitar.FretFrequency(openString, fret));
    }
```

xUnit compte chaque ligne comme un test à part : avec cette théorie, la première version du projet avait 15 tests, pas 12. Une ligne qui échoue est signalée avec ses arguments, comme le montre la section suivante, et les autres lignes s'exécutent quand même.

## Quand un test échoue

Les quatre tests de `Pitfalls.Tests` échouent exprès. Chacun fait une erreur que font les débutants, et `dotnet test` l'explique :

```csharp
    // 0.1 + 0.2 ne vaut pas exactement 0.3 dans un double
    [Fact]
    public void Doubles_ComparedBitForBit()
    {
        Assert.Equal(0.3, 0.1 + 0.2);
    }

    // ParseFret lève ArgumentOutOfRangeException, un type dérivé d'ArgumentException
    [Fact]
    public void Throws_WithTheBaseType()
    {
        Assert.Throws<ArgumentException>(() => Guitar.ParseFret("25"));
    }

    // Les arguments sont inversés : le message appelle « Expected » le résultat de la méthode
    [Fact]
    public void Equal_WithTheArgumentsSwapped()
    {
        Assert.Equal(Guitar.FretFrequency(110.0, 7), 164.8);
    }

    // Une ligne de la théorie est fausse : E monté d'un demi-ton donne F
    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F#")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

`check.sh` garde les avertissements de la compilation, le message de chaque test échoué et la dernière ligne. Il retire les chemins, les durées et la *pile d'appels* (*stack trace*), la liste des appels de méthodes qui ont mené à l'échec, et il trie les tests échoués par nom : xUnit ne les signale pas dans l'ordre du fichier.

```text
PitfallTests.cs(26,9): warning xUnit2000: The literal or constant value 164.8 should be passed as the 'expected' argument in the call to 'Assert.Equal(expected, actual)' in method 'Equal_WithTheArgumentsSwapped' on type 'PitfallTests'. Swap the parameter values. (https://xunit.net/xunit.analyzers/rules/xUnit2000)
  Failed Pitfalls.Tests.PitfallTests.Doubles_ComparedBitForBit
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 0.29999999999999999
Actual:   0.30000000000000004
  Failed Pitfalls.Tests.PitfallTests.Equal_WithTheArgumentsSwapped
  Error Message:
   Assert.Equal() Failure: Values differ
Expected: 164.81
Actual:   164.80000000000001
  Failed Pitfalls.Tests.PitfallTests.Throws_WithTheBaseType
  Error Message:
   Assert.Throws() Failure: Exception type was not an exact match
Expected: typeof(System.ArgumentException)
Actual:   typeof(System.ArgumentOutOfRangeException)
---- System.ArgumentOutOfRangeException : fret ('25') must be less than or equal to '24'. (Parameter 'fret')
Actual value was 25.
  Failed Pitfalls.Tests.PitfallTests.Transpose_OneNote(note: "E", semitones: 1, expected: "F#")
  Error Message:
   Assert.Equal() Failure: Collections differ
           ↓ (pos 0)
Expected: ["F#"]
Actual:   ["F"]
           ↑ (pos 0)
Failed!  - Failed:     4, Passed:     2, Skipped:     0, Total:     6 - Pitfalls.Tests.dll (net10.0)
```

Les 2 tests qui passent sont les deux premières lignes de la théorie. Lis chaque message depuis le haut :

- **Les nombres double.** Un `double` ne peut représenter exactement ni 0,1 ni 0,2 ni 0,3, donc `0.1 + 0.2` et `0.3` sont deux nombres légèrement différents. xUnit affiche les deux avec 17 chiffres pour montrer la différence : même `0.3` devient `0.29999999999999999`. Compare les double à un nombre de décimales près, `Assert.Equal(0.3, 0.1 + 0.2, 10)`, qui passe. Les tests de `FretFrequency` n'en ont pas besoin : la méthode arrondit avec `Math.Round`, et le résultat arrondi est le même `double` que le littéral `164.81` du test.
- **Les types d'exception.** `Assert.Throws<ArgumentException>` veut exactement ce type. `ParseFret` lève [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), une classe dérivée d'`ArgumentException` (leçon 8) : le message montre les deux types, et l'exception qui a été levée. Donne le type exact, ou utilise `Assert.ThrowsAny<ArgumentException>`, qui accepte aussi les types dérivés.
- **Les arguments inversés.** La valeur attendue vient en premier. Ici, le littéral est en second, donc le message appelle « Expected » le résultat de la méthode, 164,81, et « Actual » la valeur fausse, 164,8 : le contraire de la vérité. Le compilateur a averti avant que les tests ne s'exécutent : [xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000) vient d'un *analyseur*, une vérification que le package `xunit` ajoute au compilateur.
- **Une ligne fausse.** Le nom du test montre les arguments de la ligne qui a échoué, et les flèches pointent vers le premier élément qui diffère. Cette fois, le code est juste et le test est faux : mi (E) monté d'un demi-ton donne fa (F).

Les corrections des deux premiers sont dans `Fretboard.Tests` ; les deux derniers sont l'exercice 3 :

```csharp
    // Assert.ThrowsAny accepte aussi un type qui en dérive : ArgumentOutOfRangeException est une ArgumentException
    [Fact]
    public void ParseFret_RefusesANegativeFret()
    {
        Assert.ThrowsAny<ArgumentException>(() => Guitar.ParseFret("-1"));
    }

    // Ici, deux double sont comparés à 10 décimales près, pas bit à bit
    [Fact]
    public void Doubles_CompareWithAPrecision()
    {
        Assert.Equal(0.3, 0.1 + 0.2, 10);
    }
```

## Un objet par test

xUnit crée un nouvel objet de la classe de test pour chaque test. Un champ ne transporte rien d'un test au suivant :

```csharp
// xUnit crée un nouvel objet de la classe de test pour chaque test, donc un champ repart de 0 dans chaque test
public class InstanceTests
{
    int _count;

    [Fact]
    public void FirstTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }

    [Fact]
    public void SecondTest()
    {
        _count++;
        Assert.Equal(1, _count);
    }
}
```

Les deux tests passent : chacun voit `_count` à 0. Un test ne peut pas compter sur le fait qu'un autre s'est exécuté avant lui, et il n'en a pas besoin : chaque test prépare ses propres données.

## Tester ce que la bibliothèque rend public

Le projet de test est un autre programme : il appelle la bibliothèque de l'extérieur, et ne voit que ses membres `public`. Un membre sans `public` est privé à sa classe, comme dans cet extrait, où les instructions de niveau supérieur jouent le rôle du test :

```csharp
// Un test appelle la bibliothèque de l'extérieur : il ne voit que ce que la bibliothèque rend public
Console.WriteLine(Guitar.Chromatic.Length);

static class Guitar
{
    static readonly string[] Chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
}
```

```text
l11_private.cs(2,26): error CS0122: 'Guitar.Chromatic' is inaccessible due to its protection level
```

[CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122) dit que le membre existe mais qu'on ne peut pas l'atteindre d'ici. Depuis un projet de test, un membre marqué `internal`, visible seulement dans son propre projet, donne une autre erreur : dans une paire de projets d'essai, le compilateur a répondu [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117), `'Lab' does not contain a definition for 'Secret'`, comme si la méthode n'existait pas. L'attribut [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute) peut ouvrir les membres internes d'une bibliothèque à ses tests. Tester à travers les méthodes publiques vaut en général mieux : les tests vérifient alors ce qu'utilisent les autres projets, et ils passent encore quand tu réécris l'intérieur d'une méthode.

## Dans Guitar Alchemist

Au commit `5c3a52a`, Guitar Alchemist a 18 projets de test. 16 fichiers de projet référencent [NUnit](https://docs.nunit.org/), un autre framework de test, et 3 référencent xUnit. Les idées sont les mêmes, avec d'autres noms : `[Test]` pour `[Fact]`, `[TestCase]` pour `[InlineData]`, `Assert.That(actual, Is.EqualTo(expected))` pour `Assert.Equal(expected, actual)`, et `[Ignore("reason")]` pour ignorer un test.

**Les tests des fichiers YAML.** La leçon 9 a trouvé que trois des quatre fichiers YAML des services de connaissances musicales de GA ne se chargent pas, ce qui est maintenant l'[issue GA n° 797](https://github.com/GuitarAlchemist/ga/issues/797). GA a des tests pour ces services, dans [`MusicalKnowledgeServiceTests.cs`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs). Trois de ses huit tests sont ignorés avec [`[Ignore("Configuration files not loaded in test environment")]`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L108-L110), et parmi les cinq autres, trois vérifient seulement qu'un nombre est [supérieur à zéro](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/Configuration/MusicalKnowledgeServiceTests.cs#L28-L33) ou qu'une liste n'est pas vide. Une [sonde](https://github.com/spareilleux/learn/tree/main/code/csharp-beginner/ga-probes/knowledge-tests) a compilé ce fichier sans le modifier, avec les services de GA et les mêmes packages NUnit, et l'a exécuté : 5 tests ont réussi, 3 ont été ignorés, aucun n'a échoué. La recherche de « jazz » a réussi avec un résultat : la progression d'accords par défaut que le chargeur garde après son échec. Un test qui vérifie « plus que zéro » ne peut pas voir un chargeur qui échoue et renvoie un seul élément par défaut ; un test qui vérifie le vrai nombre d'éléments, ou que le chargement ne signale aucune erreur, le pourrait.

**Une préparation qui ne s'exécute jamais.** Le même projet de test a une classe, [`TestEnvironment`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/TestBootstrap/TestEnvironment.cs#L1-L14), marquée `[SetUpFixture]`, qui déplace le dossier courant à la racine du dépôt. Son commentaire dit qu'elle « ensures configuration-backed services can locate their YAML/JSON inputs during tests » (permet aux services qui dépendent de la configuration de trouver leurs fichiers YAML/JSON pendant les tests) : le problème de la leçon 10, résolu pour les tests. Mais NUnit n'exécute une *setup fixture* qu'avant les tests [de son propre espace de noms](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html), et celle-ci est seule dans `GA.Business.Core.Tests.TestBootstrap`. Un test de la sonde, placé à côté des tests YAML, a trouvé le dossier courant toujours dans son dossier `bin`, et `GA_TEST_MODE`, que la préparation définit, non défini. Les fichiers YAML sont trouvés quand même, à côté du programme, là où la compilation les copie.

**Des tests qui ne sont pas compilés.** Le fichier de projet [retire 35 fichiers de la compilation](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Tests/Common/GA.Business.Core.Tests/GA.Business.Core.Tests.csproj#L39-L75), sous le commentaire « Exclude test files with missing service implementations » (exclure les fichiers de test dont les implémentations de services manquent). Cinq des noms ne correspondent plus à aucun fichier ; les 30 autres fichiers contiennent 333 lignes qui commencent par `[Test]` ou `[TestCase]`. Un test qui n'est pas compilé n'échoue jamais, et `dotnet test` n'en parle pas.

Le [tableau QA du journal](../journal/#qa) consigne ces mesures.

## Exercices

Les solutions sont des tests de `Fretboard.Tests`, dans `ExerciseTests.cs` : `dotnet test` les exécute avec les autres.

### Exercice 1 — transpose vers le bas

Écris un test qui vérifie que `Guitar.Transpose(["A", "C", "E"], -3)` renvoie F#, A et C#.

<details>
<summary>Solution</summary>

```csharp
    // Exercice 1 : transposer vers le bas
    [Fact]
    public void Transpose_MovesEachNoteDown()
    {
        List<string> result = Guitar.Transpose(["A", "C", "E"], -3);

        Assert.Equal(["F#", "A", "C#"], result);
    }
```

`Assert.Equal` compare deux listes élément par élément ; l'expression de collection `["F#", "A", "C#"]` prend le type de l'autre argument.

</details>

### Exercice 2 — les limites de `ParseFret`

Les bogues se cachent aux limites. Teste que `ParseFret` accepte `"0"` et `"24"`, refuse `"-1"` et `"25"` avec `ArgumentOutOfRangeException`, et refuse `"seven"` avec `FormatException`. Utilise des théories là où un test a plusieurs lignes.

<details>
<summary>Solution</summary>

```csharp
    // Exercice 2 : les limites de ParseFret
    [Theory]
    [InlineData("0", 0)]
    [InlineData("24", 24)]
    public void ParseFret_AcceptsTheFirstAndLastFret(string text, int expected)
    {
        Assert.Equal(expected, Guitar.ParseFret(text));
    }

    [Theory]
    [InlineData("-1")]
    [InlineData("25")]
    public void ParseFret_RefusesTheFretsJustOutside(string text)
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Guitar.ParseFret(text));
    }

    [Fact]
    public void ParseFret_RefusesAWord()
    {
        Assert.Throws<FormatException>(() => Guitar.ParseFret("seven"));
    }
```

Chaque limite a une valeur juste à l'intérieur, 0 et 24, et une valeur juste à l'extérieur, -1 et 25. Si quelqu'un écrit `ThrowIfGreaterThan(fret, 23)` par erreur, la ligne `"24"` échoue.

</details>

### Exercice 3 — corrige les deux tests faux

Deux tests de `Pitfalls.Tests` attendent la mauvaise valeur : `Equal_WithTheArgumentsSwapped` et la ligne `"E", 1, "F#"` de `Transpose_OneNote`. Écris une version correcte de chacun.

<details>
<summary>Solution</summary>

```csharp
    // Exercice 3 : les deux pièges dont la valeur attendue était fausse, corrigés
    [Fact]
    public void Equal_WithTheExpectedValueFirst()
    {
        Assert.Equal(164.81, Guitar.FretFrequency(110.0, 7));
    }

    [Theory]
    [InlineData("C", 2, "D")]
    [InlineData("B", 1, "C")]
    [InlineData("E", 1, "F")]
    public void Transpose_OneNote(string note, int semitones, string expected)
    {
        Assert.Equal([expected], Guitar.Transpose([note], semitones));
    }
```

La première correction met le littéral en premier et utilise la bonne valeur, 164,81 : l'avertissement xUnit2000 disparaît aussi. Dans la seconde, le code était juste : la correction est dans le test.

</details>

### Exercice 4 — un test qui lit un fichier

Écris un test qui lit `data/ga-projects.csv` avec `Project.Parse` et vérifie qu'il contient 12 projets et 632 fichiers source, `.cs` et `.fs` ensemble. Deux points de la leçon 10 comptent ici : le fichier doit être copié à côté des tests compilés, et un test ne devrait pas dépendre du dossier courant.

<details>
<summary>Solution</summary>

Un [élément `None`](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none) dans `Fretboard.Tests.csproj` copie le fichier dans le dossier de sortie, sous `data` :

```xml
<ItemGroup>
  <None Include="..\..\data\ga-projects.csv" Link="data\ga-projects.csv" CopyToOutputDirectory="PreserveNewest" />
</ItemGroup>
```

Le test construit le chemin à partir d'[`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), le dossier des tests compilés :

```csharp
    // Exercice 4 : un test qui lit data/ga-projects.csv, copié à côté des tests par Fretboard.Tests.csproj
    [Fact]
    public void GaProjects_HoldSixHundredThirtyTwoSourceFiles()
    {
        string path = Path.Combine(AppContext.BaseDirectory, "data", "ga-projects.csv");

        List<Project> projects = File.ReadLines(path).Skip(1).Select(Project.Parse).ToList();

        Assert.Equal(12, projects.Count);
        Assert.Equal(632, projects.Sum(p => p.SourceFiles));
    }
```

`Select(Project.Parse)` donne à LINQ la méthode elle-même, comme `Count(IsFSharp)` à la leçon 9. 632, ce sont les 557 fichiers C# et les 75 fichiers F# de la leçon 10.

</details>

## Ce qu'il faut retenir

- Un test unitaire appelle une méthode avec des arguments connus et compare son résultat avec la valeur attendue. Un framework de test exécute tous les tests, compte les échecs et fixe le code de sortie.
- Les tests vont dans un projet de test qui référence une bibliothèque de classes : `dotnet new classlib`, `dotnet new xunit`, `dotnet add reference`. `dotnet test` compile les deux et exécute les tests.
- `[Fact]` marque un test ; `[Theory]` avec `[InlineData]` exécute le même test une fois par ligne, et chaque ligne compte comme un test.
- `Assert.Equal(expected, actual)` : la valeur attendue en premier. Compare les double à un nombre de décimales près. `Assert.Throws<T>` veut le type exact ; `Assert.ThrowsAny<T>` accepte les types dérivés.
- Un test qui échoue dit que deux valeurs diffèrent : vérifie si c'est le code ou le test qui est faux avant de changer l'un ou l'autre.
- xUnit crée un nouvel objet pour chaque test, et ne promet aucun ordre. Un projet de test ne voit que les membres publics de la bibliothèque.
- Un test ignoré, non compilé, ou qui vérifie seulement « plus que zéro » peut passer alors que le code est cassé.

La suite : [un petit projet](../12-small-project/), une solution avec cette bibliothèque, une application console et ces tests, un package NuGet, et un premier regard sur `async`.

## Sources

- xUnit : [premiers pas avec xUnit.net v2](https://xunit.net/docs/getting-started/v2/netcore/cmdline), [règle d'analyseur xUnit2000](https://xunit.net/xunit.analyzers/rules/xUnit2000)
- .NET : [tests unitaires C# avec xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), [bonnes pratiques des tests unitaires](https://learn.microsoft.com/dotnet/core/testing/unit-testing-best-practices), [`dotnet test`](https://learn.microsoft.com/dotnet/core/tools/dotnet-test), [modèles `dotnet new`](https://learn.microsoft.com/dotnet/core/tools/dotnet-new-sdk-templates), [`dotnet add reference`](https://learn.microsoft.com/dotnet/core/tools/dotnet-reference-add), [`InternalsVisibleTo`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.internalsvisibletoattribute), [`ArgumentOutOfRangeException`](https://learn.microsoft.com/dotnet/api/system.argumentoutofrangeexception), [`AppContext.BaseDirectory`](https://learn.microsoft.com/dotnet/api/system.appcontext.basedirectory), [éléments MSBuild](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#none)
- NUnit : [documentation](https://docs.nunit.org/), [`SetUpFixture`](https://docs.nunit.org/articles/nunit/writing-tests/attributes/setupfixture.html)
- Erreurs du compilateur [CS0122](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/cs0122) et [CS0117](https://learn.microsoft.com/dotnet/csharp/misc/cs0117)
