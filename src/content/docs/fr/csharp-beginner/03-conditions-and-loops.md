---
title: 3. Conditions et boucles
description: Prendre des décisions avec if, else et switch, répéter un travail avec while, for et foreach, arrêter ou sauter un tour avec break et continue, et suivre un programme ligne par ligne dans un débogueur.
sidebar:
  order: 3
---

Code : les exemples [`examples/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), les extraits refusés [`compile_fail/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) et les solutions [`exercises/l03_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises).

Jusqu'ici, les programmes exécutaient chaque ligne une fois, de haut en bas. Cette leçon change ça : une **condition** n'exécute certaines lignes que dans certains cas, et une **boucle** exécute des lignes plusieurs fois.

## Les comparaisons et `bool`

Une comparaison pose une question dont la réponse est un `bool` : `true` (vrai) ou `false` (faux).

```csharp
int fret = 12;

// Une comparaison donne un bool : true ou false
Console.WriteLine(fret == 12);
Console.WriteLine(fret != 12);
Console.WriteLine(fret > 5 && fret < 10);   // && : les deux doivent être vraies
Console.WriteLine(fret < 1 || fret > 11);   // || : au moins une doit être vraie
Console.WriteLine(!(fret > 5));             // !  : le contraire
```

```text
True
False
False
True
False
```

| Opérateur | Sens | | Opérateur | Sens |
|---|---|---|---|---|
| `==` | égal à | | `&&` | et |
| `!=` | différent de | | `\|\|` | ou |
| `<`, `<=` | inférieur, ou égal | | `!` | non |
| `>`, `>=` | supérieur, ou égal | | | |

Attention à `==`, deux signes égal, qui compare, et à `=`, un seul signe, qui affecte. Les pages sur les [opérateurs de comparaison](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators) et les [opérateurs logiques booléens](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators) donnent toutes les règles. Le *et* et le *ou* s'arrêtent dès qu'ils connaissent la réponse : dans `fret > 5 && fret < 10`, quand la première comparaison est `false`, la seconde n'est même pas calculée.

## `if`, `else if`, `else`

[`if`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-if-statement) exécute un **bloc**, les lignes entre accolades, seulement quand sa condition est `true` :

```csharp
// if exécute un bloc seulement quand la condition est vraie
if (fret == 0)
{
    Console.WriteLine("Open string");
}
else if (fret == 12)
{
    Console.WriteLine("One octave above the open string");
}
else
{
    Console.WriteLine("Somewhere else on the neck");
}

// Les chaînes sont comparées par leur contenu
string tuning = "E A D G B E";
if (tuning == "E A D G B E")
{
    Console.WriteLine("Standard tuning");
}

// Une variable déclarée dans un bloc n'existe que dans ce bloc
if (fret > 7)
{
    int distance = fret - 7;
    Console.WriteLine($"{distance} frets above the 7th");
}
```

```text
One octave above the open string
Standard tuning
5 frets above the 7th
```

Les conditions sont testées dans l'ordre, et seul le premier bloc dont la condition est `true` s'exécute. `else` attrape tous les autres cas. `else if` et `else` sont tous deux facultatifs.

La condition doit être un `bool`. Deux erreurs classiques sont refusées. Écrire un seul signe égal au lieu de deux :

```csharp
int fret = 5;
if (fret = 12)
{
    Console.WriteLine("Octave");
}
```

```text
l03_assign_in_if.cs(2,5): error CS0029: Cannot implicitly convert type 'int' to 'bool'
l03_assign_in_if.cs(1,5): warning CS0219: The variable 'fret' is assigned but its value is never used
```

`fret = 12` est une affectation, dont la valeur est l'`int` 12, pas un `bool`. Dans certains autres langages, ça compile et ça modifie `fret` en silence. Une chaîne n'est pas une condition non plus :

```csharp
string answer = "yes";
if (answer)
```

```text
l03_string_condition.cs(2,5): error CS0029: Cannot implicitly convert type 'string' to 'bool'
```

Écris `if (answer == "yes")`.

### Portée

Une variable déclarée dans un bloc n'existe que dans ce bloc, et dans les blocs qu'il contient. Cette zone est sa **portée** :

```csharp
int fret = 9;
if (fret > 7)
{
    int distance = fret - 7;
}
Console.WriteLine(distance);
```

```text
l03_out_of_scope.cs(6,19): error CS0103: The name 'distance' does not exist in the current context
```

Pour utiliser `distance` après le `if`, déclare-la avant le `if`.

## `switch`

Quand une valeur est comparée à une liste de valeurs possibles, un [`switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements#the-switch-statement) se lit plus facilement qu'une suite de `else if`.

```csharp
int semitone = 7;

// L'instruction switch : un case par valeur, chaque case se termine par break
switch (semitone)
{
    case 0:
        Console.WriteLine("Unison");
        break;
    case 7:
        Console.WriteLine("Perfect fifth");
        break;
    case 12:
        Console.WriteLine("Octave");
        break;
    default:
        Console.WriteLine("Another interval");
        break;
}
```

```text
Perfect fifth
```

L'**instruction switch** saute au `case` qui correspond, ou à `default` quand aucun ne correspond. Chaque section doit se terminer par `break` (ou `return`, [leçon 4](../04-methods-arrays-lists/)). En C et en JavaScript, un `break` oublié laisse le programme tomber dans le cas suivant ; C# le refuse :

```csharp
switch (semitone)
{
    case 7:
        Console.WriteLine("Perfect fifth");
    case 12:
        Console.WriteLine("Octave");
        break;
}
```

```text
l03_fall_through.cs(4,5): error CS0163: Control cannot fall through from one case label ('case 7:') to another
```

### L'expression `switch`

Souvent, chaque cas ne fait que calculer une valeur. L'[**expression switch**](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression) le dit en moins de lignes : la valeur, `switch`, puis une *branche* par cas, `motif => résultat`, séparées par des virgules.

```csharp
// L'expression switch calcule une valeur : une branche par motif, _ correspond à tout le reste
string name = semitone switch
{
    0 => "C",
    1 => "C#",
    2 => "D",
    3 => "D#",
    4 => "E",
    5 => "F",
    6 => "F#",
    7 => "G",
    8 => "G#",
    9 => "A",
    10 => "A#",
    11 => "B",
    _ => "not a semitone between 0 and 11",
};
Console.WriteLine($"Semitone {semitone} above C is {name}");

// Les motifs peuvent comparer : la première branche qui correspond l'emporte
foreach (int fret in new[] { 0, 3, 7, 12, 17, 30 })
{
    string zone = fret switch
    {
        0 => "open string",
        < 5 => "first position",
        < 12 => "middle of the neck",
        12 => "octave",
        <= 24 => "high on the neck",
        _ => "no such fret",
    };
    Console.WriteLine($"Fret {fret}: {zone}");
}
```

```text
Semitone 7 above C is G
Fret 0: open string
Fret 3: first position
Fret 7: middle of the neck
Fret 12: octave
Fret 17: high on the neck
Fret 30: no such fret
```

- Les branches sont essayées **de haut en bas**, et la première qui correspond donne la valeur. La case 3 correspond à la branche `< 5`, inférieur à 5, avant que la branche inférieur à 12 ne soit essayée.
- Un *motif* (*pattern*) peut être une valeur, comme `12`, ou une comparaison, comme `< 5`, inférieur à 5. La [page sur les motifs](https://learn.microsoft.com/dotnet/csharp/fundamentals/functional/pattern-matching) montre les autres : `and`, `or`, `not`, et bien d'autres.
- `_`, le *discard* (l'élément ignoré), correspond à tout : c'est le `default` d'une expression switch.
- La boucle `foreach (int fret in new[] { … })` exécute le bloc une fois pour chaque nombre ; les boucles arrivent [juste après](#les-boucles).

Sans `_`, une valeur qu'aucune branche ne reconnaît n'a rien à produire. Le compilateur avertit, et le programme échoue quand ça arrive :

```csharp
int stringNumber = 7;

// Pas de branche pour 7, ni de branche _ : le compilateur avertit, et le programme échoue à l'exécution
string open = stringNumber switch
{
    1 => "E4",
    2 => "B3",
    3 => "G3",
    4 => "D3",
    5 => "A2",
    6 => "E2",
};
Console.WriteLine(open);
```

```text
l03_switch_warning.cs(4,28): warning CS8509: The switch expression does not handle all possible values of its input type (it is not exhaustive). For example, the pattern '0' is not covered.
Unhandled exception. System.Runtime.CompilerServices.SwitchExpressionException: Non-exhaustive switch expression failed to match its input.
Unmatched value was 7.
   at <PrivateImplementationDetails>.ThrowSwitchExpressionException(Object unmatchedValue)
   at Program.<Main>$(String[] args) in C:\Users\spare\source\repos\learn\code\csharp-beginner\examples\l03_switch_warning.cs:line 4
```

Un **avertissement**, contrairement à une erreur, n'empêche pas la compilation : le programme s'exécute, et ici il s'arrête sur une **exception**, une erreur qui se produit pendant l'exécution. Les lignes qui commencent par `at` forment la *pile d'appels* (*stack trace*) : où en était le programme. La dernière indique la ligne 4 du fichier. La [leçon 8](../#plan) porte sur les exceptions.

Deux choses à savoir sur les avertissements. D'abord, lis-les : celui-ci annonçait le plantage. Ensuite, `dotnet run` ne les affiche que quand il compile ; si tu exécutes à nouveau le même fichier inchangé, il ne compile pas, et l'avertissement ne s'affiche plus. `dotnet clean l03_switch_warning.cs` oublie le programme compilé, et l'exécution suivante affiche à nouveau l'avertissement. Le `check.sh` du cours le fait avant chaque exécution.

## Les boucles

Une boucle répète un bloc. C# a quatre [instructions d'itération](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements) :

```csharp
// while : répète tant que la condition est vraie
int countdown = 3;
while (countdown > 0)
{
    Console.WriteLine($"{countdown}...");
    countdown--;                   // comme countdown = countdown - 1
}
Console.WriteLine("Play!");

// for : départ ; condition ; pas
for (int fret = 0; fret <= 12; fret += 3)
{
    Console.Write($"{fret} ");
}
Console.WriteLine();

// foreach : chaque élément d'une collection, ici chaque caractère d'une chaîne
foreach (char letter in "EADGBE")
{
    Console.Write($"[{letter}]");
}
Console.WriteLine();

// break quitte la boucle, continue passe au tour suivant
for (int i = 1; i <= 10; i++)
{
    if (i % 2 == 0)
    {
        continue;                  // saute les nombres pairs
    }
    if (i > 7)
    {
        break;                     // s'arrête après 7
    }
    Console.Write($"{i} ");
}
Console.WriteLine();

// do-while : le bloc s'exécute au moins une fois, la condition est testée après
int tries = 0;
do
{
    tries++;
    Console.WriteLine($"Try {tries}");
} while (tries < 2);
```

```text
3...
2...
1...
Play!
0 3 6 9 12 
[E][A][D][G][B][E]
1 3 5 7 
Try 1
Try 2
```

| Boucle | À utiliser quand | Teste la condition |
|---|---|---|
| `while (condition)` | tu ne sais pas à l'avance combien de tours | avant chaque tour |
| `do { … } while (condition);` | le bloc doit s'exécuter au moins une fois | après chaque tour |
| `for (start; condition; step)` | tu comptes : de 0 à 12, de 3 en 3 | avant chaque tour |
| `foreach (type item in collection)` | tu parcours chaque élément d'une collection | — |

- `countdown--` retire 1, `i++` ajoute 1, et `fret += 3` ajoute 3 : des formes courtes de `countdown = countdown - 1` et de `fret = fret + 3`.
- Un `for` a trois parties séparées par des points-virgules : ce qu'il faut faire **une fois** au début (`int fret = 0`), la condition testée **avant chaque tour** (`fret <= 12`), et ce qu'il faut faire **après chaque tour** (`fret += 3`). Sa variable `fret` n'existe que dans la boucle.
- `foreach` prend chaque élément à tour de rôle. Une chaîne est une collection de `char` ; les tableaux et les listes, de la [leçon 4](../04-methods-arrays-lists/), sont aussi des collections.
- `continue` saute le reste du bloc et commence le tour suivant ; `break` quitte la boucle immédiatement.

Un `while` dont la condition ne devient jamais `false` tourne sans fin. Si un programme semble bloqué, appuie sur <kbd>Ctrl</kbd>+<kbd>C</kbd> dans le terminal pour l'arrêter.

### Des boucles dans des boucles : le manche

Une boucle peut contenir une autre boucle. Pour chaque corde, la boucle intérieure parcourt chaque case. Ce programme affiche les notes des cinq premières cases d'une guitare en accordage standard, le `Tuning.Default` de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Tuning.cs#L20-L23) :

```csharp
// Les cinq premières cases d'une guitare en accordage standard (E2 A2 D3 G3 B3 E4, Tuning.Default dans GA).
// Chaque note est un nombre de demi-tons : C vaut 0, C# vaut 1, ... B vaut 11, et le C suivant revient à 12.
for (int stringNumber = 6; stringNumber >= 1; stringNumber--)
{
    // Demi-tons de la corde à vide au-dessus de C
    int open = stringNumber switch
    {
        6 => 4,    // E
        5 => 9,    // A
        4 => 2,    // D
        3 => 7,    // G
        2 => 11,   // B
        _ => 4,    // E (corde 1)
    };

    Console.Write($"String {stringNumber}:");
    for (int fret = 0; fret <= 5; fret++)
    {
        int semitone = (open + fret) % 12;     // % 12 ramène 12 à 0 : l'octave
        string name = semitone switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($" {name,-2}");
    }
    Console.WriteLine();
}
```

```text
String 6: E  F  F# G  G# A 
String 5: A  A# B  C  C# D 
String 4: D  D# E  F  F# G 
String 3: G  G# A  A# B  C 
String 2: B  C  C# D  D# E 
String 1: E  F  F# G  G# A 
```

Les guitaristes numérotent les cordes de la plus aiguë, la corde 1, à la plus grave, la corde 6 ; la boucle extérieure compte à rebours pour que la corde 6 s'affiche en premier. Sur la corde de si (B), la case 1 donne `(11 + 1) % 12`, c'est-à-dire `0` : C, un do. L'opérateur `%` fait tourner les nombres comme les heures sur une horloge, et c'est exactement ainsi que les noms de notes reviennent à chaque octave. Le [cours de théorie musicale](../../music-theory-ga/01-notes-and-the-fretboard/) va beaucoup plus loin avec la même idée.

### Lire jusqu'à la bonne réponse

Une boucle `while` peut redemander une saisie jusqu'à obtenir ce qu'il lui faut :

```csharp
// Devine la case : la boucle lit des réponses jusqu'à la bonne
int secret = 7;
int tries = 0;
bool found = false;

while (!found)
{
    Console.Write("Which fret? ");
    string? line = Console.ReadLine();
    if (line == null)
    {
        Console.WriteLine("No more input.");
        break;
    }
    if (!int.TryParse(line, out int guess))
    {
        Console.WriteLine($"\"{line}\" is not a number.");
        continue;
    }

    tries++;
    if (guess < secret)
    {
        Console.WriteLine("Higher.");
    }
    else if (guess > secret)
    {
        Console.WriteLine("Lower.");
    }
    else
    {
        found = true;
        Console.WriteLine($"Found in {tries} tries.");
    }
}
```

En tapant `12`, `five`, `5` et `7` :

```text
Which fret? 12
Lower.
Which fret? five
"five" is not a number.
Which fret? 5
Higher.
Which fret? 7
Found in 3 tries.
```

`continue` revient à la question sans compter la mauvaise réponse comme un essai. Quand l'entrée se termine, `ReadLine` renvoie `null` et `break` quitte la boucle : sans ça, un programme dont l'entrée vient d'un fichier, comme dans la CI, poserait la question à l'infini. Au clavier, <kbd>Ctrl</kbd>+<kbd>Z</kbd> puis <kbd>Entrée</kbd> sous Windows, ou <kbd>Ctrl</kbd>+<kbd>D</kbd> sous Linux et macOS, termine l'entrée.

## Trouver une erreur avec le débogueur

Quand un programme donne un résultat faux, il faut voir ce qu'il fait, ligne par ligne. Le moyen le plus simple est d'ajouter des appels à `Console.WriteLine` qui affichent les variables, de relancer, puis de les retirer. Ça marche partout.

Un **débogueur** fait mieux : il met le programme en pause sur une ligne que tu choisis, un **point d'arrêt**, montre la valeur de chaque variable, et te laisse exécuter une ligne à la fois. Les trois éditeurs de la [leçon 1](../01-first-program/#choisir-un-éditeur) en ont un :

| Action | Visual Studio Code | Visual Studio | Rider |
|---|---|---|---|
| Poser ou retirer un point d'arrêt | <kbd>F9</kbd>, ou clic à gauche du numéro de ligne | <kbd>F9</kbd> | clic à gauche de la ligne |
| Démarrer avec le débogueur | <kbd>F5</kbd> | <kbd>F5</kbd> | l'icône en forme d'insecte |
| Exécuter la ligne suivante | <kbd>F10</kbd> (pas à pas principal) | <kbd>F10</kbd> | step over |
| Entrer dans une méthode appelée sur cette ligne | <kbd>F11</kbd> (pas à pas détaillé) | <kbd>F11</kbd> | step into |
| Continuer jusqu'au point d'arrêt suivant | <kbd>F5</kbd> | <kbd>F5</kbd> | resume |

Essaie sur le programme du manche : pose un point d'arrêt sur la ligne `int semitone = (open + fret) % 12;`, démarre avec le débogueur, et regarde `stringNumber`, `open` et `fret` dans le panneau *Variables* ou *Locals*. Chaque fois que tu continues, le programme s'arrête à nouveau à la case suivante. Tu peux aussi taper une expression comme `(open + fret) % 12` dans le panneau *Watch* (espion) pour voir sa valeur.

Les touches de ce tableau sont les raccourcis par défaut de chaque éditeur sous Windows et Linux ; sous macOS, le jeu de raccourcis de Rider est différent. Voir [le débogage dans VS Code](https://code.visualstudio.com/docs/csharp/debugging), [le débogueur de Visual Studio pour débutants](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour), et [le débogage dans Rider](https://www.jetbrains.com/help/rider/Debugging_Code.html). *À vérifier* : je n'ai pas encore débogué ces exemples dans chacun des trois éditeurs, ni comme applications basées sur un fichier, ni dans un projet créé avec [`dotnet new console`](../01-first-program/#un-projet).

## À retenir

- Une comparaison donne un `bool` ; *et* (`&&`), *ou* (`||`) et *non* (`!`) les combinent. Deux signes égal comparent, un seul signe égal affecte.
- `if`, `else if` et `else` exécutent le premier bloc dont la condition est `true` ; une variable déclarée dans un bloc n'existe que dans ce bloc.
- Une instruction `switch` demande un `break` à la fin de chaque cas ; une expression `switch` calcule une valeur, essaie ses branches de haut en bas, et devrait se terminer par `_`.
- `while` répète tant qu'une condition est vraie, `for` compte, `foreach` parcourt chaque élément d'une collection ; `break` quitte la boucle et `continue` passe au tour suivant.
- Un avertissement n'empêche pas la compilation, mais annonce souvent un problème ; une exception non gérée arrête le programme et affiche où elle s'est produite.
- Un débogueur s'arrête sur les points d'arrêt et montre les variables, une ligne à la fois.

## Exercices

1. Affiche les nombres de 1 à 15 sur une ligne, mais affiche `Fizz` à la place des multiples de 3, `Buzz` à la place des multiples de 5, et `FizzBuzz` pour les multiples des deux. Indice : une expression switch peut regarder deux valeurs à la fois, écrites `(a, b) switch`.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_fizzbuzz.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_fizzbuzz.cs) :

```csharp
// Exercice 1 : FizzBuzz de 1 à 15, avec une expression switch sur deux restes
for (int i = 1; i <= 15; i++)
{
    string text = (i % 3, i % 5) switch
    {
        (0, 0) => "FizzBuzz",
        (0, _) => "Fizz",
        (_, 0) => "Buzz",
        _ => i.ToString(),
    };
    Console.Write($"{text} ");
}
Console.WriteLine();
```

```text
1 2 Fizz 4 Buzz Fizz 7 8 Fizz Buzz 11 Fizz 13 14 FizzBuzz 
```

`(i % 3, i % 5)` regroupe les deux restes dans un *tuple*, et chaque branche teste les deux. `(0, _)` veut dire « divisible par 3, quel que soit le second reste ». L'ordre compte : `(0, 0)` doit venir en premier, sinon 15 afficherait `Fizz`. Avec `if`, tu écrirais d'abord `if (i % 3 == 0 && i % 5 == 0)`, puis `else if (i % 3 == 0)`, et ainsi de suite.

</details>

2. Demande un nom de note (`C`, `C#`, … `B`) et affiche les 13 notes de la gamme chromatique à partir de cette note, jusqu'à la même note une octave plus haut. Affiche un message si la note est inconnue.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_chromatic.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_chromatic.cs) :

```csharp
// Exercice 2 : lire un nom de note et afficher les 13 notes de la gamme chromatique à partir d'elle, jusqu'à son octave
Console.Write("Starting note? ");
string? input = Console.ReadLine();

int start = input switch
{
    "C" => 0, "C#" => 1, "D" => 2, "D#" => 3, "E" => 4, "F" => 5,
    "F#" => 6, "G" => 7, "G#" => 8, "A" => 9, "A#" => 10, "B" => 11,
    _ => -1,
};

if (start == -1)
{
    Console.WriteLine($"Unknown note: {input}");
}
else
{
    for (int step = 0; step <= 12; step++)
    {
        string name = ((start + step) % 12) switch
        {
            0 => "C", 1 => "C#", 2 => "D", 3 => "D#", 4 => "E", 5 => "F",
            6 => "F#", 7 => "G", 8 => "G#", 9 => "A", 10 => "A#", _ => "B",
        };
        Console.Write($"{name} ");
    }
    Console.WriteLine();
}
```

Avec `A` :

```text
Starting note? A
A A# B C C# D D# E F F# G G# A 
```

La première expression switch transforme le nom en nombre, avec `-1` pour dire « inconnue » : une expression switch fonctionne aussi sur des chaînes. La boucle tourne 13 fois, `step` de 0 à 12, et `% 12` ramène au début les nombres au-dessus de 11. Taper deux fois les mêmes noms de notes n'est pas idéal : la [leçon 4](../04-methods-arrays-lists/) les range une seule fois, dans un tableau.

</details>

3. Lis des temps d'entraînement en minutes, un par ligne, jusqu'à une ligne vide ou la fin de l'entrée. Ignore les lignes qui ne sont pas des nombres entiers ou qui sont négatives, en le signalant. Affiche ensuite le nombre de jours valides, le total en minutes, et le total en heures et minutes.

<details>
<summary>Solution</summary>

[`exercises/l03_ex_total.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l03_ex_total.cs) :

```csharp
// Exercice 3 : additionner les minutes d'entraînement tapées une par ligne ; une ligne vide termine l'entrée
int total = 0;
int days = 0;
while (true)
{
    string? line = Console.ReadLine();
    if (line == null || line == "")
    {
        break;
    }
    if (!int.TryParse(line, out int minutes) || minutes < 0)
    {
        Console.WriteLine($"Skipped: {line}");
        continue;
    }
    total += minutes;
    days++;
}
Console.WriteLine($"{days} days, {total} minutes, {total / 60} h {total % 60} min");
```

Avec les lignes `30`, `45`, `forty`, `-5`, `60`, une ligne vide, puis `90` ([`input/l03_ex_total.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l03_ex_total.txt)), la sortie est :

```text
Skipped: forty
Skipped: -5
3 days, 135 minutes, 2 h 15 min
```

`while (true)` ne s'arrête jamais tout seul : c'est le `break` à l'intérieur qui décide. Le `90` après la ligne vide n'est jamais lu. Dans `!int.TryParse(line, out int minutes) || minutes < 0`, le `||` ne calcule `minutes < 0` que quand `TryParse` a réussi, donc `minutes` contient toujours la valeur lue au moment où on la compare.

</details>

## Sources

- [Instructions de sélection : `if`, `else` et `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/selection-statements), [l'expression `switch`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/switch-expression), [les motifs](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/patterns)
- [Instructions d'itération : `for`, `foreach`, `do` et `while`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/iteration-statements), [instructions de saut : `break` et `continue`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/jump-statements)
- [Opérateurs de comparaison](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/comparison-operators), [opérateurs logiques booléens](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/boolean-logical-operators)
- [Avertissement du compilateur CS8509](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/pattern-matching-warnings), [`SwitchExpressionException`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.switchexpressionexception)
- [Déboguer du C# dans VS Code](https://code.visualstudio.com/docs/csharp/debugging), [visite guidée du débogueur de Visual Studio](https://learn.microsoft.com/visualstudio/debugger/debugger-feature-tour), [Rider : déboguer du code](https://www.jetbrains.com/help/rider/Debugging_Code.html)
