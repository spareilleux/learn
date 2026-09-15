---
title: 4. Méthodes, tableaux et listes
description: Découper un programme en méthodes avec paramètres et valeurs de retour, ranger de nombreuses valeurs dans des tableaux et des List<T>, et découvrir null, la valeur qui veut dire « rien ».
sidebar:
  order: 4
---

Code : les exemples [`examples/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), les extraits refusés [`compile_fail/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) et les solutions [`exercises/l04_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

Les programmes de la leçon 3 répétaient les mêmes douze noms de notes à plusieurs endroits. Cette leçon supprime cette répétition de deux façons : une **méthode** donne un nom à un travail, pour l'écrire une fois et l'appeler autant de fois que tu veux, et un **tableau** ou une **liste** range de nombreuses valeurs sous un seul nom.

## Méthodes

Tu appelles des méthodes depuis la leçon 1 : `Console.WriteLine`, `Math.Pow`, `int.TryParse`. Maintenant, tu écris les tiennes.

```csharp
// Appel des méthodes déclarées plus bas
PrintTitle("Methods");
Console.WriteLine(Square(12));
Console.WriteLine(FretFrequency(110.0, 7));
Console.WriteLine(FretFrequency(82.41, 5));
Console.WriteLine(Describe(0));
Console.WriteLine(Describe(12));
Console.WriteLine(Repeat("la"));                 // valeur par défaut pour times
Console.WriteLine(Repeat("la", 3));
Console.WriteLine(Repeat(times: 2, text: "do")); // arguments nommés, dans n'importe quel ordre

// Une méthode sans résultat : son type de retour est void
void PrintTitle(string title)
{
    Console.WriteLine($"== {title} ==");
}

// Une méthode qui renvoie un int
int Square(int x)
{
    return x * x;
}

// Une méthode à deux paramètres, arrondie à deux décimales
double FretFrequency(double openString, int fret)
{
    double frequency = openString * Math.Pow(2, fret / 12.0);
    return Math.Round(frequency, 2);
}

// return quitte la méthode immédiatement
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    return $"fret {fret}";
}

// Un paramètre facultatif, et un corps écrit en une seule expression avec =>
string Repeat(string text, int times = 2) => string.Concat(Enumerable.Repeat(text, times));
```

```text
== Methods ==
144
164.81
110
open string
fret 12
lala
lalala
dodo
```

Une déclaration de méthode a quatre parties, nommées en anglais sur ce schéma :

```text
double  FretFrequency  (double openString, int fret)  { … return …; }
  │          │                    │                         │
return     name              parameters                   body
 type
```

- Le **type de retour** (*return type*) est le type du résultat : `int`, `double`, `string`… ou `void` quand la méthode ne renvoie rien et se contente de faire quelque chose, comme afficher.
- Le **nom** (*name*) commence par une majuscule, par convention, et en général par un verbe : `PrintTitle`, `Describe`.
- Les **paramètres** (*parameters*) sont des variables qui reçoivent les valeurs données par l'appelant, les *arguments*. `FretFrequency(110.0, 7)` met `110.0` dans `openString` et `7` dans `fret`, dans cet ordre.
- Le **corps** (*body*) fait le travail. [`return`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements#the-return-statement) rend le résultat à l'appelant et quitte la méthode immédiatement : dans `Describe(0)`, le second `return` n'est jamais atteint.

La case 5 de la corde de mi grave, à 82,41 Hz, est un la à 110 Hz : la note de la corde de la à vide. C'est comme ça que les guitaristes accordent la cinquième corde à partir de la sixième.

Trois commodités :

- Un paramètre avec une **valeur par défaut**, `int times = 2`, peut être omis : `Repeat("la")` utilise 2.
- Les **arguments nommés**, `times: 2, text: "do"`, disent quel paramètre reçoit quelle valeur, dans n'importe quel ordre.
- Quand le corps est une seule expression, `=>` remplace les accolades et le `return` : c'est un [membre expression-bodied](https://learn.microsoft.com/dotnet/csharp/programming-guide/statements-expressions-operators/expression-bodied-members) (corps d'expression). `Enumerable.Repeat(text, times)` produit une suite de `times` copies de `text`, et `string.Concat` les colle.

Dans un fichier avec des instructions de niveau supérieur, les méthodes peuvent être déclarées après les lignes qui les appellent, comme ici. La documentation C# les appelle [fonctions locales](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions) : elles appartiennent au code de niveau supérieur du programme. La [leçon 5](../#plan) place les méthodes dans des classes, leur place habituelle dans les programmes plus gros.

### Ce que vérifie le compilateur

Le compilateur vérifie chaque appel par rapport à la déclaration. Un argument manquant :

```csharp
Console.WriteLine(FretFrequency(110.0));

double FretFrequency(double openString, int fret)
```

```text
l04_missing_argument.cs(1,19): error CS7036: There is no argument given that corresponds to the required parameter 'fret' of 'FretFrequency(double, int)'
```

Un argument du mauvais type :

```csharp
Console.WriteLine(Square("12"));

int Square(int x)
```

```text
l04_wrong_argument_type.cs(1,26): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

Utiliser le résultat d'une méthode `void` :

```csharp
string title = PrintTitle("Methods");

void PrintTitle(string text)
```

```text
l04_void_result.cs(1,16): error CS0029: Cannot implicitly convert type 'void' to 'string'
```

Et une méthode qui peut se terminer sans renvoyer de valeur. Ici, un `fret` négatif passe à côté des deux `return` :

```csharp
string Describe(int fret)
{
    if (fret == 0)
    {
        return "open string";
    }
    else if (fret > 0)
    {
        return $"fret {fret}";
    }
}
```

```text
l04_not_all_paths.cs(3,8): error CS0161: 'Describe(int)': not all code paths return a value
```

Le compilateur n'essaie pas de deviner que `fret` n'est jamais négatif : chaque chemin dans la méthode doit se terminer par un `return` ou une exception.

### Les arguments sont des copies

```csharp
int fret = 5;
AddOctave(fret);
Console.WriteLine($"After AddOctave: {fret}");       // inchangé : la méthode a reçu une copie

int[] frets = [0, 2, 2, 1, 0, 0];                    // un accord de mi majeur
AddOctaveToAll(frets);
Console.WriteLine($"After AddOctaveToAll: {string.Join(" ", frets)}");  // modifié : la méthode a reçu le même tableau

void AddOctave(int value)
{
    value += 12;
    Console.WriteLine($"Inside AddOctave: {value}");
}

void AddOctaveToAll(int[] values)
{
    for (int i = 0; i < values.Length; i++)
    {
        values[i] += 12;
    }
}
```

```text
Inside AddOctave: 17
After AddOctave: 5
After AddOctaveToAll: 12 14 14 13 12 12
```

Un paramètre reçoit une **copie** de l'argument. Modifier `value` dans `AddOctave` ne modifie pas `fret`. Mais une variable de tableau ne contient pas le tableau lui-même : elle contient une *référence*, l'adresse où se trouve le tableau. La copie est une copie de l'adresse, donc `values` et `frets` désignent le même tableau, et la méthode le modifie. L'accord de mi majeur est monté d'une octave, à la 12e case. Les types qui se comportent comme `int` sont des **types valeur** ; ceux qui se comportent comme les tableaux sont des **types référence**. La [leçon 6](../#plan) revient sur la différence.

## Tableaux

Un **tableau** contient un nombre fixe de valeurs du même type, les unes à la suite des autres, chacune à une position numérotée, son **indice**.

```csharp
// Un tableau : un nombre fixe de valeurs du même type
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];

Console.WriteLine(strings.Length);
Console.WriteLine(strings[0]);          // les indices commencent à 0
Console.WriteLine(strings[5]);          // le dernier indice est Length - 1
Console.WriteLine(strings[^1]);         // ^1 : le premier en partant de la fin
Console.WriteLine(string.Join(", ", strings[1..3]));   // une plage : indices 1 et 2

strings[0] = "D2";                      // accordage drop D : les valeurs peuvent changer
Console.WriteLine(string.Join(" ", strings));

// new int[4] : quatre int, tous à 0 au départ
int[] minutes = new int[4];
minutes[1] = 30;
Console.WriteLine(string.Join(" ", minutes));

// Parcourir les valeurs
int[] practice = [30, 45, 0, 60, 20];
int total = 0;
foreach (int m in practice)
{
    total += m;
}
Console.WriteLine($"Total: {total} minutes over {practice.Length} days");

// Sort modifie le tableau lui-même
Array.Sort(practice);
Console.WriteLine(string.Join(" ", practice));
```

```text
6
E2
E4
E4
A2, D3
D2 A2 D3 G3 B3 E4
0 30 0 0
Total: 155 minutes over 5 days
0 20 30 45 60
```

- `string[]`, qui se lit *tableau de string*, est le type « tableau de chaînes ». `["E2", "A2", …]` est une [expression de collection](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions) : les valeurs entre crochets. `new int[4]` crée un tableau de quatre `int`, tous à `0`.
- **Les indices commencent à 0** : un tableau de six éléments va de `strings[0]` à `strings[5]`. `strings[^1]`, avec un accent circonflexe, compte depuis la fin, et `strings[1..3]` est un nouveau tableau avec les éléments de l'indice 1 jusqu'à l'indice 3, non compris. Voir [index et plages](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes).
- `Length` donne le nombre d'éléments. Il ne peut pas changer : un tableau n'a pas de `Add`.
- [`string.Join`](https://learn.microsoft.com/dotnet/api/system.string.join) construit une seule chaîne à partir de tous les éléments, avec un séparateur entre eux, et [`Array.Sort`](https://learn.microsoft.com/dotnet/api/system.array.sort) trie le tableau sur place.

Dépasser la fin est l'erreur la plus courante avec les tableaux. Le compilateur ne peut pas la voir, parce que l'indice n'est connu qu'à l'exécution :

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
for (int i = 0; i <= strings.Length; i++)     // <= va un cran trop loin
{
    Console.WriteLine($"{i}: {strings[i]}");
}
```

```text
0: E2
1: A2
2: D3
3: G3
4: B3
5: E4
Unhandled exception. System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l04_index_out_of_range.cs:line 4
```

Avec *inférieur ou égal*, `<=`, la boucle tourne aussi avec `i` égal à 6, et il n'y a pas de `strings[6]`. La condition de boucle d'un tableau est presque toujours *i inférieur à la longueur du tableau*, `i < array.Length`, ou mieux, un `foreach`, qui ne peut pas aller trop loin.

Et la taille d'un tableau est fixe :

```csharp
string[] strings = ["E2", "A2", "D3", "G3", "B3", "E4"];
strings.Add("B1");
```

```text
l04_array_fixed_size.cs(2,9): error CS1061: 'string[]' does not contain a definition for 'Add' and no accessible extension method 'Add' accepting a first argument of type 'string[]' could be found (are you missing a using directive or an assembly reference?)
```

Pour une collection qui grandit, utilise une liste.

## Listes

Une [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1) est comme un tableau qui peut grandir et rétrécir. Le `T` représente le type de ses éléments, écrit entre chevrons : `List<string>` est une liste de chaînes, `List<int>` une liste d'entiers.

```csharp
// Une List<string> grandit et rétrécit ; le type entre < > est le type de ses éléments
List<string> chord = ["C", "E", "G"];
Console.WriteLine($"{chord.Count} notes: {string.Join(" ", chord)}");

chord.Add("B");                         // Cmaj7
Console.WriteLine(string.Join(" ", chord));

chord.Insert(1, "D");                   // à l'indice 1, les autres se décalent
Console.WriteLine(string.Join(" ", chord));

chord.Remove("D");                      // retire le premier "D" trouvé
Console.WriteLine(string.Join(" ", chord));

Console.WriteLine(chord.Contains("G"));
Console.WriteLine(chord.IndexOf("B"));
Console.WriteLine(chord.IndexOf("F#"));  // -1 : absent de la liste

chord[3] = "Bb";                         // C7
Console.WriteLine(string.Join(" ", chord));

chord.RemoveAt(chord.Count - 1);
Console.WriteLine(string.Join(" ", chord));

// Une liste vide, remplie dans une boucle
List<int> octaves = [];
for (int midi = 12; midi <= 60; midi += 12)
{
    octaves.Add(midi);
}
Console.WriteLine($"The C notes in MIDI numbers: {string.Join(", ", octaves)}");
```

```text
3 notes: C E G
C E G B
C D E G B
C E G B
True
3
-1
C E G Bb
C E G
The C notes in MIDI numbers: 12, 24, 36, 48, 60
```

| | Tableau `string[]` | Liste `List<string>` |
|---|---|---|
| Taille | fixée à la création | grandit et rétrécit |
| Nombre d'éléments | `Length` | `Count` |
| Lire et modifier un élément | `a[i]`, `a[i] = x` | `list[i]`, `list[i] = x` |
| Ajouter, insérer, retirer | non | `Add`, `Insert`, `Remove`, `RemoveAt` |
| Chercher | `Array.IndexOf(a, x)` | `list.IndexOf(x)`, `list.Contains(x)` |
| À utiliser quand | le nombre d'éléments est connu et ne change pas | les éléments vont et viennent |

Un accord de do majeur, c'est do, mi et sol : C, E et G en notation anglaise. Ajouter si (B) donne un accord de *septième majeure*, Cmaj7 ; avec si bémol (écrit `Bb`), c'est une *septième de dominante*, C7. `IndexOf` renvoie `-1` quand l'élément n'est pas là.

La liste vérifie le type de ce que tu ajoutes :

```csharp
List<int> frets = [0, 2, 2];
frets.Add("1");
```

```text
l04_list_wrong_type.cs(2,11): error CS1503: Argument 1: cannot convert from 'string' to 'int'
```

## Méthodes, tableaux et listes ensemble : les projets de Guitar Alchemist

Guitar Alchemist est découpé en plus de cent projets. Le [cours LadybugDB](../../ladybugdb/05-csharp/) en a extrait la liste dans [`projects.csv`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/ladybugdb/data/ga/projects.csv), à partir du commit `a26a7893` de GA. Douze des projets de son dossier `Common`, recopiés à la main dans deux tableaux, suffisent pour s'entraîner :

```csharp
// Douze projets du dossier Common de GuitarAlchemist/ga, et leurs langages,
// recopiés depuis code/ladybugdb/data/ga/projects.csv
string[] names =
[
    "GA.Core", "GA.Domain.Core", "GA.Business.Config", "GA.Business.Core",
    "GA.Business.DSL", "GA.Business.AI", "GA.Business.ML", "GA.Business.ProbabilisticGrammar",
    "GA.Business.Core.Generated", "GA.Infrastructure", "GA.Presentation", "GA.Testing.Semantic",
];
string[] languages = ["C#", "C#", "F#", "C#", "F#", "C#", "C#", "F#", "F#", "C#", "C#", "C#"];

Console.WriteLine($"{CountStartingWith(names, "GA.Business.")} projects start with GA.Business.");

List<string> fsharp = ProjectsIn(names, languages, "F#");
Console.WriteLine($"{fsharp.Count} F# projects:");
foreach (string name in fsharp)
{
    Console.WriteLine($"  {name}");
}

Console.WriteLine($"Longest name: {Longest(names)}");

int CountStartingWith(string[] values, string prefix)
{
    int count = 0;
    foreach (string value in values)
    {
        if (value.StartsWith(prefix))
        {
            count++;
        }
    }
    return count;
}

// Les deux tableaux vont ensemble : names[i] est écrit en languages[i]
List<string> ProjectsIn(string[] projectNames, string[] projectLanguages, string language)
{
    List<string> result = [];
    for (int i = 0; i < projectNames.Length; i++)
    {
        if (projectLanguages[i] == language)
        {
            result.Add(projectNames[i]);
        }
    }
    return result;
}

string Longest(string[] values)
{
    string longest = values[0];
    foreach (string value in values)
    {
        if (value.Length > longest.Length)
        {
            longest = value;
        }
    }
    return longest;
}
```

```text
7 projects start with GA.Business.
4 F# projects:
  GA.Business.Config
  GA.Business.DSL
  GA.Business.ProbabilisticGrammar
  GA.Business.Core.Generated
Longest name: GA.Business.ProbabilisticGrammar
```

Chaque méthode fait une seule chose et porte un nom qui dit laquelle : compter, filtrer, trouver le plus long. `ProjectsIn` utilise un `for` au lieu d'un `foreach` parce qu'elle a besoin de l'indice `i` pour lire la même position dans les deux tableaux. Deux tableaux qui doivent rester alignés sont fragiles : ajoute un nom en oubliant son langage, et tous les langages suivants sont faux. La [leçon 5](../#plan) les remplace par une seule liste de projets, chacun avec un nom et un langage. La [leçon 10](../#plan) lit le fichier CSV entier au lieu de le recopier à la main.

## `null` : aucune valeur

Certaines variables ont besoin d'un moyen de dire « il n'y a rien ici » : pas de capodastre sur la guitare, plus de lignes à lire. C# utilise [`null`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/null) pour ça. Un type suivi d'un point d'interrogation, comme `string?`, une chaîne ou null, accepte `null` ; un simple `string` n'est pas censé en contenir.

```csharp
// string? : une chaîne, ou null (pas de chaîne du tout)
string? capo = null;
Console.WriteLine(capo == null);
Console.WriteLine(capo is null);

// ?. donne null au lieu de lire un membre de null ; ?? donne une valeur à utiliser à la place de null
Console.WriteLine(capo?.Length);
Console.WriteLine(capo ?? "no capo");
Console.WriteLine(capo?.Length ?? 0);

capo ??= "fret 2";                       // affecte seulement si capo est null
Console.WriteLine(capo);
Console.WriteLine(capo.Length);          // le compilateur sait qu'ici capo n'est pas null

// Console.ReadLine renvoie null quand il n'y a plus rien à lire
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    if (!string.IsNullOrWhiteSpace(line))
    {
        lines.Add(line.Trim());
    }
}
Console.WriteLine($"{lines.Count} non-empty lines: {string.Join(" | ", lines)}");
```

Avec en entrée les lignes `Am`, une ligne vide, `  F  `, `C`, une ligne d'espaces, et `G` ([`input/l04_null.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_null.txt)) :

```text
True
True

no capo
0
fret 2
6
4 non-empty lines: Am | F | C | G
```

| Écriture | Sens |
|---|---|
| `x == null`, `x is null` | `x` est-il null ? |
| `x?.Length` | `null` si `x` est null, sinon `x.Length` |
| `x ?? other` | `x`, ou `other` si `x` est null |
| `x ??= value` | met `value` dans `x` seulement si `x` est null |

La troisième ligne de la sortie est vide : `capo?.Length` vaut `null`, et `WriteLine` n'affiche rien pour lui. Dans la boucle, `(line = Console.ReadLine()) != null` lit une ligne, la range dans `line`, puis la compare à `null` : la boucle s'arrête à la fin de l'entrée. [`string.IsNullOrWhiteSpace`](https://learn.microsoft.com/dotnet/api/system.string.isnullorwhitespace) vaut `true` pour `null`, une chaîne vide, ou seulement des espaces, et `Trim` retire les espaces autour du texte.

### Le compilateur surveille `null`

Lire un membre de `null`, comme sa longueur `Length`, est impossible : il n'y a pas de chaîne à mesurer. Le compilateur suit d'où peut venir `null` et **avertit** avant que ça n'arrive. Cette fonctionnalité s'appelle les [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references), activée par le `<Nullable>enable</Nullable>` vu dans le fichier projet de la leçon 1, et par défaut dans les applications basées sur un fichier.

```csharp
string? FindTuning(string name)
{
    if (name == "standard")
    {
        return "E A D G B E";
    }
    return null;
}

string? tuning = FindTuning("drop D");
Console.WriteLine(tuning.Length);   // avertissement CS8602, puis une NullReferenceException à l'exécution
```

```text
l04_null_warning.cs(11,19): warning CS8602: Dereference of a possibly null reference.
Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l04_null_warning.cs:line 11
```

Ce n'est qu'un avertissement, donc le programme s'exécute, et plante à la ligne 11. La correction consiste à traiter le cas `null`, par exemple avec `tuning?.Length ?? 0`, ou avec un `if (tuning is null)` avant de l'utiliser. Dans le premier exemple, `capo.Length` après `capo ??= "fret 2"` ne déclenche aucun avertissement : le compilateur a compris que `capo` ne peut plus être `null`. La [leçon 8](../#plan) traite en profondeur des exceptions et de la sécurité face à null.

## À retenir

- Une méthode a un type de retour (`void` s'il n'y en a pas), un nom, des paramètres et un corps ; `return` rend le résultat et quitte la méthode.
- Le compilateur vérifie le nombre et le type des arguments, et que chaque chemin d'une méthode non `void` renvoie une valeur.
- Les arguments sont des copies : une méthode ne peut pas modifier une variable `int` de l'appelant, mais elle peut modifier les éléments d'un tableau qu'elle reçoit, parce que la copie est une référence au même tableau.
- Un tableau a une taille fixe, `Length`, et des indices de `0` à `Length - 1` ; dépasser la fin lève `IndexOutOfRangeException`.
- `List<T>` grandit et rétrécit avec `Add`, `Insert`, `Remove` et `RemoveAt`, et a un `Count`.
- `string?` peut valoir `null` ; `?.`, `??` et `??=` le gèrent, et le compilateur avertit quand tu risques d'utiliser un `null`.

## Exercices

1. Écris une méthode `Average` qui prend un `int[]` et renvoie sa moyenne sous forme de `double`, ou `null` quand le tableau est vide. Appelle-la sur une semaine de temps d'entraînement, `30, 45, 0, 60, 20, 0, 90`, et sur un tableau vide.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_average.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_average.cs) :

```csharp
// Exercice 1 : la moyenne d'un tableau, ou null quand le tableau est vide
int[] week = [30, 45, 0, 60, 20, 0, 90];
int[] nothing = [];

Console.WriteLine(Average(week));
Console.WriteLine(Average(nothing) ?? -1);
Console.WriteLine(Average(nothing) is null ? "no practice recorded" : "some practice");

double? Average(int[] values)
{
    if (values.Length == 0)
    {
        return null;
    }
    int total = 0;
    foreach (int value in values)
    {
        total += value;
    }
    return (double)total / values.Length;
}
```

```text
35
-1
no practice recorded
```

`double?` est un `double` qui peut aussi valoir `null` : le `?` fonctionne aussi sur les types valeur. `(double)total / values.Length` convertit avant de diviser ; `total / values.Length` serait une division entière. La division par zéro est évitée par le `return null` du début. La dernière ligne utilise l'*opérateur conditionnel* `condition ? a : b`, un `if`/`else` court qui donne une valeur.

</details>

2. Range les douze noms de notes (`C`, `C#`, … `B`) dans un tableau, une seule fois. Écris une méthode `Transpose` qui prend une `List<string>` de noms de notes et un nombre de demi-tons, positif ou négatif, et renvoie une **nouvelle** liste où chaque note est déplacée. Vérifie que la liste d'origine ne change pas.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_transpose.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_transpose.cs) :

```csharp
// Exercice 2 : transposer un accord, une liste de noms de notes, d'un nombre de demi-tons
string[] chromatic = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

List<string> cMajor = ["C", "E", "G"];
Console.WriteLine(string.Join(" ", Transpose(cMajor, 2)));
Console.WriteLine(string.Join(" ", Transpose(cMajor, 7)));
Console.WriteLine(string.Join(" ", Transpose(["A", "C", "E"], -3)));
Console.WriteLine(string.Join(" ", cMajor));        // inchangée : Transpose renvoie une nouvelle liste

List<string> Transpose(List<string> notes, int semitones)
{
    List<string> result = [];
    foreach (string note in notes)
    {
        int index = Array.IndexOf(chromatic, note);
        int moved = ((index + semitones) % 12 + 12) % 12;   // + 12 garde les pas négatifs dans 0..11
        result.Add(chromatic[moved]);
    }
    return result;
}
```

```text
D F# A
G B D
F# A C#
C E G
```

Do majeur monté de 2 demi-tons donne ré majeur, de 7 donne sol majeur ; la mineur descendu de 3 donne fa dièse mineur. En C#, `%` garde le signe du nombre de gauche : descendre C (indice 0) de 3 demi-tons donne `(0 - 3) % 12`, qui vaut `-3`, un indice invalide. Ajouter 12 puis reprendre `% 12` donne toujours un indice de 0 à 11 : ici 9, le A.

`Transpose` lit `chromatic`, une variable du code de niveau supérieur, sans la recevoir en paramètre : une fonction locale en a le droit. C'est pratique ici, mais ça cache ce dont la méthode dépend. La leçon 5 montre comment une classe contient ce genre de données partagées. Une note absente du tableau, comme `Bb`, donne `-1` avec `Array.IndexOf` et un résultat faux : corriger ça est un bon exercice supplémentaire.

</details>

3. Lis toutes les lignes de l'entrée jusqu'à sa fin, range-les dans une liste, puis affiche le nombre de lignes et la plus longue, ou `(no lines)` s'il n'y en avait aucune. Écris la recherche de la ligne la plus longue sous forme d'une méthode qui renvoie `string?`.

<details>
<summary>Solution</summary>

[`exercises/l04_ex_longest_line.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l04_ex_longest_line.cs) :

```csharp
// Exercice 3 : lire chaque ligne jusqu'à la fin de l'entrée, puis afficher le nombre de lignes et la plus longue
List<string> lines = [];
string? line;
while ((line = Console.ReadLine()) != null)
{
    lines.Add(line);
}

string? longest = Longest(lines);
Console.WriteLine($"{lines.Count} lines");
Console.WriteLine($"Longest: {longest ?? "(no lines)"}");

string? Longest(List<string> values)
{
    string? best = null;
    foreach (string value in values)
    {
        if (best == null || value.Length > best.Length)
        {
            best = value;
        }
    }
    return best;
}
```

Avec quatre accordages en entrée ([`input/l04_ex_longest_line.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l04_ex_longest_line.txt)) :

```text
4 lines
Longest: Standard: E2 A2 D3 G3 B3 E4
```

`best` commence à `null`, qui veut dire « aucune ligne vue pour l'instant ». `best == null || value.Length > best.Length` ne lit jamais `best.Length` quand `best` vaut `null`, parce que `||` s'arrête au premier `true` ; le compilateur le sait, et n'avertit pas. Avec une entrée vide, la méthode renvoie `null`, et `??` affiche `(no lines)`.

</details>

## Sources

- [Méthodes](https://learn.microsoft.com/dotnet/csharp/methods), [fonctions locales](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/local-functions), [paramètres de méthode](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [arguments nommés et facultatifs](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments)
- [Tableaux](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/arrays), [expressions de collection](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions), [index et plages](https://learn.microsoft.com/dotnet/csharp/tutorials/ranges-indexes)
- [`List<T>`](https://learn.microsoft.com/dotnet/api/system.collections.generic.list-1), [collections](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/collections)
- [Types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references), [opérateurs d'accès aux membres `?.`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/member-access-operators#null-conditional-operators--and-), [`??` et `??=`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/null-coalescing-operator)
- [Types valeur](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/value-types) et [types référence](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/reference-types)
