---
title: 2. Variables, types et saisie
description: Ranger des valeurs dans des variables de type int, double, decimal, string et bool, convertir d'un type à l'autre, mettre en forme du texte par interpolation, et lire ce que tape l'utilisateur avec Console.ReadLine.
sidebar:
  order: 2
---

Code : les exemples [`examples/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/examples), les extraits refusés [`compile_fail/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/compile_fail) et les solutions [`exercises/l02_*.cs`](https://github.com/spareilleux/learn/tree/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises). Exécute un exemple depuis le dossier `code/csharp-beginner` avec `dotnet run examples/l02_variables.cs`.

## Variables

Une **variable** est une boîte qui porte un nom et contient une valeur. En C#, chaque boîte a aussi un **type**, fixé à sa création : la sorte de valeurs qu'elle accepte.

```csharp
// Une variable est une boîte nommée qui contient une valeur d'un seul type
int strings = 6;
string tuning = "E A D G B E";
double scaleLength = 64.8;     // centimètres, un diapason de guitare courant
bool isAcoustic = true;
char lowest = 'E';

Console.WriteLine(strings);
Console.WriteLine(tuning);
Console.WriteLine(scaleLength);
Console.WriteLine(isAcoustic);
Console.WriteLine(lowest);

// La valeur peut changer ; le type, non
strings = 7;
Console.WriteLine(strings);

// var : le compilateur déduit le type à partir de la valeur
var frets = 22;                // int
var name = "Stratocaster";     // string
Console.WriteLine(frets.GetType());
Console.WriteLine(name.GetType());

// const : une valeur qui ne change jamais
const int SemitonesPerOctave = 12;
Console.WriteLine(SemitonesPerOctave * 2);
```

```text
6
E A D G B E
64.8
True
E
7
System.Int32
System.String
24
```

`int strings = 6;` est une **déclaration** : le type, le nom, `=`, puis la première valeur. Elle se lit « crée une boîte nommée `strings` pour un `int`, et mets-y 6 ». Plus loin, `strings = 7;` est une **affectation** : elle remplace la valeur dans la boîte. Le signe `=` veut dire « mettre dans », pas « est égal à ».

Les noms suivent quelques règles : des lettres, des chiffres et `_`, sans commencer par un chiffre, et pas un mot-clé du langage comme `int` ou `if`. Par convention, une variable locale commence par une minuscule et chaque mot suivant par une majuscule : `scaleLength`. Ce style s'appelle *camelCase* ; les [règles de nommage des identificateurs C#](https://learn.microsoft.com/dotnet/csharp/fundamentals/coding-style/identifier-names) listent les autres.

## Les types de base

| Type | Contient | Exemples | Plage et précision |
|---|---|---|---|
| `int` | des nombres entiers | `6`, `-12`, `2_000_000` | environ -2,1 à 2,1 milliards |
| `long` | des entiers plus grands | `9_000_000_000` | environ ±9,2 milliards de milliards |
| `double` | des nombres à virgule, approchés | `64.8`, `1e-3` | 15 à 17 chiffres significatifs |
| `decimal` | des nombres à virgule, exacts | `19.99m` | 28 à 29 chiffres significatifs |
| `bool` | vrai ou faux | `true`, `false` | |
| `char` | un caractère | `'E'`, `'#'` | entre apostrophes droites |
| `string` | du texte | `"E A D G B E"`, `""` | entre guillemets doubles |

Les pages sur les [types numériques intégraux](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types) et les [types numériques à virgule flottante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types) listent les autres, comme `byte`, `short` ou `float`. Tu en auras rarement besoin en débutant. Le `_` dans `2_000_000` sert seulement à rendre le nombre plus lisible. En C#, le séparateur décimal est toujours un point : `64.8`.

`GetType()` a affiché `System.Int32` et `System.String` : `int` est le mot-clé C# pour le type .NET `Int32`, un entier sur 32 bits, et `string` est le mot-clé pour `String`. Les deux noms désignent exactement le même type.

### `var`

Avec [`var`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/declarations#implicitly-typed-local-variables), le compilateur lit la valeur et donne son type à la variable : `var frets = 22;` crée un `int`. La variable garde un seul type toute sa vie. `var` évite de taper le type quand la valeur le rend évident ; écris le type quand il aide le lecteur.

### `const`

Une [`const`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/const) est une valeur fixée au moment où tu écris le programme : 12 demi-tons par octave, ça ne changera jamais. Son nom commence par une majuscule.

### Ce que le compilateur refuse

Chacun de ces petits programmes est refusé. Le type d'une variable ne peut pas changer, donc une chaîne n'entre pas dans une boîte `int` :

```csharp
var frets = 22;
frets = "twenty-two";
```

```text
l02_type_change.cs(2,9): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

Une variable doit avoir une valeur avant d'être lue :

```csharp
int strings;
Console.WriteLine(strings);
```

```text
l02_unassigned.cs(2,19): error CS0165: Use of unassigned local variable 'strings'
```

`var` a besoin d'une valeur pour trouver le type :

```csharp
var tuning;
tuning = "E A D G B E";
```

```text
l02_var_without_value.cs(1,5): error CS0818: Implicitly-typed variables must be initialized
```

Et une constante reste constante :

```csharp
const int SemitonesPerOctave = 12;
SemitonesPerOctave = 13;
```

```text
l02_const_change.cs(2,1): error CS0131: The left-hand side of an assignment must be a variable, property or indexer
```

## Nombres et calculs

`+`, `-`, `*` et `/` fonctionnent comme en mathématiques, et `%` donne le reste d'une division. Le type des nombres change le résultat :

```csharp
// Entiers : la division laisse tomber les décimales
Console.WriteLine(7 / 2);
Console.WriteLine(7 % 2);      // le reste
Console.WriteLine(7 / 2.0);    // un double dans l'opération : le résultat est un double

// Chaque type entier a une plage ; int va d'environ -2,1 milliards à 2,1 milliards
Console.WriteLine(int.MaxValue);
int big = int.MaxValue;
big = big + 1;                 // repart à l'autre bout sans erreur
Console.WriteLine(big);
Console.WriteLine(long.MaxValue);

// double est rapide mais approché : 0.1 n'a pas d'écriture binaire exacte
Console.WriteLine(0.1 + 0.2);
Console.WriteLine(0.1 + 0.2 == 0.3);

// decimal est exact pour les fractions décimales : utilise-le pour l'argent
Console.WriteLine(0.1m + 0.2m);
Console.WriteLine(0.1m + 0.2m == 0.3m);
decimal price = 19.99m;
Console.WriteLine(price * 3);
```

```text
3
1
3.5
2147483647
-2147483648
9223372036854775807
0.30000000000000004
False
0.3
True
59.97
```

Trois surprises pour un débutant :

1. **`7 / 2` vaut `3`.** Quand les deux nombres sont entiers, la division est une division entière : les décimales sont supprimées, pas arrondies. `7 % 2` donne ce qui reste, `1`. Si l'un des nombres est un `double`, comme `2.0`, le résultat est un `double` : `3.5`.
2. **Un `int` qui dépasse son maximum repart** de la valeur la plus négative, sans aucune erreur. Le compilateur ne le détecte que quand tout le calcul est fait de constantes :

   ```csharp
   int big = int.MaxValue + 1;
   ```

   ```text
   l02_overflow_constant.cs(1,11): error CS0220: The operation overflows at compile time in checked mode
   ```

   Le mot-clé [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) fait échouer le programme au lieu de repartir, quand les nombres ne sont connus qu'à l'exécution.
3. **`0.1 + 0.2` ne vaut pas exactement `0.3` avec `double`.** Un `double` stocke les nombres en binaire, où 0,1 n'a pas d'écriture exacte, de même que 1/3 n'a pas d'écriture décimale exacte. Pour de l'argent, utilise `decimal`, où `0.1m + 0.2m` vaut exactement `0.3`. Le `m` après le nombre en fait un `decimal` ; sans lui, le compilateur refuse :

   ```csharp
   decimal price = 19.99;
   ```

   ```text
   l02_decimal_literal.cs(1,17): error CS0664: Literal of type double cannot be implicitly converted to type 'decimal'; use an 'M' suffix to create a literal of this type
   ```

### Un vrai calcul : la fréquence d'une case

Chaque case (*frette*) d'une guitare monte la note d'un demi-ton, ce qui multiplie la fréquence de la corde par la racine douzième de 2, environ 1,0595. Douze cases doublent la fréquence : une octave. [`Math.Pow(x, y)`](https://learn.microsoft.com/dotnet/api/system.math.pow) calcule x puissance y :

```csharp
// La corde de la à vide vibre à 110 Hz. Chaque case monte la note d'un demi-ton,
// ce qui multiplie la fréquence par la racine douzième de 2.
double openA = 110.0;
int fret = 7;

double wrong = openA * Math.Pow(2, fret / 12);     // 7 / 12 est une division entière : 0
double right = openA * Math.Pow(2, fret / 12.0);   // 7 / 12.0 vaut 0.5833...

Console.WriteLine($"Fret {fret}, wrong: {wrong} Hz");
Console.WriteLine($"Fret {fret}, right: {right} Hz");
Console.WriteLine($"Rounded: {right:F2} Hz");
Console.WriteLine($"Fret 12: {openA * Math.Pow(2, 12 / 12.0)} Hz");
```

```text
Fret 7, wrong: 110 Hz
Fret 7, right: 164.81377845643496 Hz
Rounded: 164.81 Hz
Fret 12: 220 Hz
```

`fret / 12` vaut `0`, parce que les deux sont des `int`, et 2 puissance 0 vaut 1 : la fréquence « fausse » est celle de la corde à vide. Cette erreur ne donne ni erreur ni avertissement, seulement un résultat faux. Écrire `12.0` en fait une division de `double`. La case 7 de la corde de la est un mi, à environ 164,81 Hz.

## Conversions

Certaines conversions se font toutes seules ; d'autres doivent être demandées.

```csharp
// Conversion implicite : aucune information ne peut être perdue
int semitones = 7;
double asDouble = semitones;
Console.WriteLine(asDouble);

// Conversion explicite (un cast) : les décimales sont coupées, pas arrondies
double hertz = 164.81;
int truncated = (int)hertz;
Console.WriteLine(truncated);

// Arrondi : par défaut, les valeurs à mi-chemin vont au nombre pair le plus proche
Console.WriteLine(Math.Round(2.5));
Console.WriteLine(Math.Round(3.5));
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero));

// Du texte au nombre
int frets = int.Parse("22");
Console.WriteLine(frets + 2);

// TryParse n'échoue pas sur un texte invalide : il renvoie false
bool ok = int.TryParse("twenty-two", out int parsed);
Console.WriteLine($"{ok} {parsed}");
ok = int.TryParse("24", out parsed);
Console.WriteLine($"{ok} {parsed}");

// Du nombre au texte
string text = frets.ToString();
Console.WriteLine(text + "2");   // + sur des chaînes les met bout à bout
Console.WriteLine(frets + 2);    // + sur des nombres les additionne
```

```text
7
164
2
4
3
24
False 0
True 24
222
24
```

### Entre types numériques

Tout `int` tient dans un `double`, donc le compilateur convertit pour toi : c'est une **conversion implicite**. Dans l'autre sens, un `double` peut contenir des décimales qu'un `int` ne peut pas garder, donc le compilateur refuse de convertir en silence :

```csharp
double hertz = 164.81;
int rounded = hertz;
```

```text
l02_double_to_int.cs(2,15): error CS0266: Cannot implicitly convert type 'double' to 'int'. An explicit conversion exists (are you missing a cast?)
```

Le message suggère un **cast** (une conversion explicite) : le type entre parenthèses devant la valeur, `(int)hertz`. Il dit au compilateur « je sais que je peux perdre quelque chose ». Un cast en `int` coupe les décimales : 164,81 devient 164.

Pour arrondir, utilise plutôt [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round). Par défaut, il arrondit une valeur située exactement à mi-chemin vers le nombre **pair** le plus proche : `2.5` donne `2` et `3.5` donne `4`. On appelle ça l'arrondi bancaire, et il évite de pousser toutes les valeurs à mi-chemin vers le haut. `MidpointRounding.AwayFromZero` donne l'arrondi appris à l'école.

### Du texte au nombre

Une chaîne qui contient des chiffres reste du texte : `"22"` ne peut pas aller dans une boîte `int`.

```csharp
int frets = "22";
```

```text
l02_string_to_int.cs(1,13): error CS0029: Cannot implicitly convert type 'string' to 'int'
```

[`int.Parse`](https://learn.microsoft.com/dotnet/api/system.int32.parse) lit le nombre contenu dans une chaîne, et arrête le programme avec une erreur si le texte n'est pas un nombre. [`int.TryParse`](https://learn.microsoft.com/dotnet/api/system.int32.tryparse) n'arrête jamais le programme : il renvoie `true` ou `false`, et donne le nombre par son paramètre `out`. `out int parsed` déclare la variable `parsed` sur place, dans l'appel. Quand le texte n'est pas un nombre, `parsed` vaut `0` et le résultat est `false`. Utilise `TryParse` pour tout ce qu'une personne tape : on fait tous des fautes de frappe.

`double.Parse`, `decimal.Parse` et leurs versions `TryParse` fonctionnent de la même façon pour les autres types.

### Du nombre au texte

`ToString()` transforme n'importe quelle valeur en texte. Et là, `+` change de sens : entre deux chaînes, `+` les **colle**. `"22" + "2"` donne `"222"`, alors que `22 + 2` donne `24`. Quand un côté est une chaîne et l'autre un nombre, C# transforme le nombre en texte et les colle, de gauche à droite : c'est pour ça que `"Frets played: " + 3 + 2 + 1` donne `Frets played: 321`.

## Chaînes et interpolation

Coller des chaînes avec `+` devient vite difficile à lire. L'**interpolation de chaînes** place les valeurs directement dans le texte : un `$` avant le guillemet ouvrant, et chaque expression entre accolades.

```csharp
string note = "A";
int octave = 4;
double frequency = 440;

// Interpolation : $ avant les guillemets, expressions entre accolades
Console.WriteLine($"{note}{octave} vibrates at {frequency} Hz");
Console.WriteLine($"One octave higher: {frequency * 2} Hz");

// Format et alignement : {value,width:format}
Console.WriteLine($"[{note,-5}] [{octave,5}] [{frequency,8:F1}]");
Console.WriteLine($"{1234567.891:N2}");

// Quelques méthodes de chaîne
string model = "Les Paul";
Console.WriteLine(model.Length);
Console.WriteLine(model.ToUpper());
Console.WriteLine(model.Contains("Paul"));
Console.WriteLine(model.Replace("Paul", "Standard"));
Console.WriteLine(model[0]);          // le premier caractère : un char

// Caractères spéciaux
Console.WriteLine("Tab:\tafter\nNew line, and a quote: \"");
Console.WriteLine(@"C:\Users\ada\music");     // verbatim : \ n'est qu'un caractère
Console.WriteLine("""
    A raw string literal keeps "quotes"
    and line breaks as they are.
    """);
```

```text
A4 vibrates at 440 Hz
One octave higher: 880 Hz
[A    ] [    4] [   440.0]
1,234,567.89
8
LES PAUL
True
Les Standard
L
Tab:	after
New line, and a quote: "
C:\Users\ada\music
A raw string literal keeps "quotes"
and line breaks as they are.
```

- Entre les accolades, n'importe quelle expression fonctionne : `frequency * 2` est calculé, puis inséré.
- Après une virgule, une **largeur** : `{octave,5}` occupe 5 caractères, aligné à droite ; une largeur négative, `{note,-5}`, aligne à gauche. Après deux-points, un **format** : `F1` affiche une décimale, `N2` deux décimales avec des séparateurs de milliers. Les [chaînes de format numériques standard](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings) les listent toutes.
- Une chaîne connaît sa longueur, `Length`, et a des méthodes comme `ToUpper`, `Contains` ou `Replace`. Aucune ne modifie `model` : elles renvoient une nouvelle chaîne. `model[0]` est le caractère à la position 0, le premier : les positions commencent à 0.
- Une barre oblique inverse commence une **séquence d'échappement** : `\t` est une tabulation, `\n` un retour à la ligne, `\"` un guillemet dans la chaîne. Avec `@` devant la chaîne, une barre oblique inverse n'est qu'une barre oblique inverse, pratique pour les chemins Windows. Entre trois guillemets, un [littéral de chaîne brut](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/reference-types#string-literals) garde les guillemets et les retours à la ligne tels quels, et retire l'indentation du `"""` fermant.

Le [tutoriel sur l'interpolation de chaînes](https://learn.microsoft.com/dotnet/csharp/tutorials/string-interpolation) va plus loin.

## Lire ce que tape l'utilisateur

[`Console.ReadLine()`](https://learn.microsoft.com/dotnet/api/system.console.readline) attend que l'utilisateur tape une ligne et appuie sur <kbd>Entrée</kbd>, puis renvoie cette ligne sous forme de chaîne, sans l'<kbd>Entrée</kbd>.

```csharp
Console.Write("What is your name? ");
string? name = Console.ReadLine();

Console.Write("How many years have you played the guitar? ");
string? answer = Console.ReadLine();

if (int.TryParse(answer, out int years))
{
    Console.WriteLine($"Hello {name}, {years} years is {years * 12} months of practice.");
}
else
{
    Console.WriteLine($"Hello {name}, \"{answer}\" is not a whole number.");
}
```

Quand je tape `Ada` et `3`, le terminal affiche :

```text
> dotnet run examples/l02_input.cs
What is your name? Ada
How many years have you played the guitar? 3
Hello Ada, 3 years is 36 months of practice.
```

La CI ne peut pas taper : `check.sh` envoie plutôt au programme les lignes de [`input/l02_input.txt`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/input/l02_input.txt), en redirigeant son entrée :

```text
dotnet run examples/l02_input.cs < input/l02_input.txt
```

Le texte tapé n'est alors pas affiché, et la sortie attendue tient en une ligne : `What is your name? How many years have you played the guitar? Hello Ada, 3 years is 36 months of practice.`

Deux nouveautés dans ce programme :

- Le type est `string?`, avec un point d'interrogation : `ReadLine` renvoie une chaîne, ou `null` quand il n'y a plus rien à lire. La [leçon 4](../04-methods-arrays-lists/#null--aucune-valeur) explique `null`. `int.TryParse` accepte un `null` et renvoie `false`.
- `if` et `else` choisissent entre deux blocs, selon le `bool` que renvoie `TryParse`. La [leçon 3](../03-conditions-and-loops/) leur est consacrée.

## Les nombres et la langue de l'utilisateur

Un et demi s'écrit `1.5` en anglais, mais `1,5` en français ou en espagnol. .NET suit la **culture** de l'ordinateur, ses réglages de langue et de région, quand il affiche et lit des nombres :

```csharp
using System.Globalization;

// Le format des nombres dépend de la culture : la langue et la région de l'utilisateur
double frequency = 1234.5;
foreach (string name in new[] { "en-US", "fr-FR", "es-ES" })
{
    CultureInfo.CurrentCulture = new CultureInfo(name);
    bool ok = double.TryParse("1.5", out double parsed);
    Console.WriteLine($"{name}: {frequency:F1}  \"1.5\" read as {parsed} ({ok})");
}

// La culture invariante donne le même résultat partout : utilise-la pour les fichiers et les données
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
Console.WriteLine(double.Parse("1.5"));
```

```text
en-US: 1234.5  "1.5" read as 1.5 (True)
fr-FR: 1234,5  "1.5" read as 0 (False)
es-ES: 1234,5  "1.5" read as 15 (True)
1.5
```

Avec la culture française, `"1.5"` n'est pas un nombre. Avec la culture espagnole, c'est pire : le point sépare les milliers en espagnol, donc `"1.5"` est lu comme **15**, sans aucune erreur. Les sorties de ce cours ont été capturées avec une culture anglaise ; sur un ordinateur réglé en français ou en espagnol, tes nombres décimaux peuvent s'afficher avec une virgule. Pour les données que les programmes s'échangent, comme les fichiers, utilise [`CultureInfo.InvariantCulture`](https://learn.microsoft.com/dotnet/api/system.globalization.cultureinfo.invariantculture), qui est la même sur tous les ordinateurs. Le [guide de la globalisation](https://learn.microsoft.com/dotnet/core/extensions/globalization) donne les détails.

`using System.Globalization;` en haut du fichier rend les noms de cet *espace de noms*, un groupe de types liés, utilisables sans leur long préfixe. `Console` et `Math` n'ont besoin d'aucun `using` : les applications basées sur un fichier et les nouveaux projets activent les [usings implicites](https://learn.microsoft.com/dotnet/core/project-sdk/overview#implicit-using-directives) pour les espaces de noms les plus courants.

## À retenir

- Une variable a un nom, un type et une valeur ; `=` y met une valeur. Le type ne change jamais, et `var` demande seulement au compilateur de le trouver.
- `int` et `long` contiennent des entiers, `double` des nombres à virgule approchés, `decimal` des nombres à virgule exacts (pour l'argent), `bool` vrai ou faux, `char` un caractère, `string` du texte.
- Diviser deux entiers supprime les décimales ; écris `12.0` pour obtenir une division de `double`.
- Les conversions qui élargissent sont automatiques ; celles qui rétrécissent demandent un cast, comme `(int)hertz`, qui coupe les décimales.
- `int.TryParse` transforme du texte en nombre sans arrêter le programme sur une mauvaise saisie.
- Une chaîne interpolée, `$"…{value,width:format}…"`, construit du texte à partir de valeurs ; `Console.ReadLine()` lit une ligne tapée par l'utilisateur.
- La culture change la façon d'afficher et de lire les nombres : utilise la culture invariante pour les données.

## Exercices

1. Un morceau dure 3725 secondes. Avec seulement des entiers, `/` et `%`, affiche sa durée sous la forme `1 h 02 min 05 s`. Le format `D2` affiche un entier avec au moins deux chiffres.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_duration.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_duration.cs) :

```csharp
// Exercice 1 : un morceau de 3725 secondes, en heures, minutes et secondes
int total = 3725;
int hours = total / 3600;
int minutes = total % 3600 / 60;
int seconds = total % 60;
Console.WriteLine($"{hours} h {minutes:D2} min {seconds:D2} s");
```

```text
1 h 02 min 05 s
```

`total / 3600` compte les heures entières. `total % 3600` est ce qui reste après elles, 125 secondes, et `/ 60` en compte les minutes entières. `%` et `/` ont la même priorité et se calculent de gauche à droite, donc `total % 3600 / 60` vaut `(total % 3600) / 60`.

</details>

2. Demande à l'utilisateur le prix d'un jeu de cordes et un nombre de jeux. Affiche le sous-total, une taxe de 15 % arrondie au centime, et le total, avec deux décimales. Si l'une des réponses n'est pas valide, affiche plutôt un message. Quel type utilises-tu pour le prix ?

<details>
<summary>Solution</summary>

`decimal`, puisque c'est de l'argent. [`exercises/l02_ex_order.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_order.cs) :

```csharp
// Exercice 2 : lire un prix et une quantité, afficher le total avec 15 % de taxe
Console.Write("Price of a set of strings? ");
string? priceText = Console.ReadLine();
Console.Write("How many sets? ");
string? quantityText = Console.ReadLine();

bool priceOk = decimal.TryParse(priceText, out decimal price);
bool quantityOk = int.TryParse(quantityText, out int quantity);

if (priceOk && quantityOk)
{
    decimal subtotal = price * quantity;
    decimal tax = Math.Round(subtotal * 0.15m, 2);
    Console.WriteLine($"Subtotal: {subtotal:F2}");
    Console.WriteLine($"Tax: {tax:F2}");
    Console.WriteLine($"Total: {subtotal + tax:F2}");
}
else
{
    Console.WriteLine("Please type a price such as 12.49 and a whole number.");
}
```

Avec `12.49` et `3` :

```text
Price of a set of strings? 12.49
How many sets? 3
Subtotal: 37.47
Tax: 5.62
Total: 43.09
```

`&&` veut dire « et » : les deux conversions doivent réussir. `Math.Round(…, 2)` arrondit à deux décimales ; 15 % de 37,47 font 5,6205, arrondi à 5,62. Sur un ordinateur réglé avec une culture française ou espagnole, tape le prix avec une virgule : `12,49`.

</details>

3. La case 7 est une *quinte* au-dessus de la corde à vide. Dans l'accord des instruments anciens, une quinte multipliait la fréquence par exactement 3/2. À quelle distance de 3/2 se trouve le rapport moderne, 2 puissance 7/12 ? Affiche les deux avec cinq décimales, et l'écart en pourcentage de 3/2.

<details>
<summary>Solution</summary>

[`exercises/l02_ex_fifth.cs`](https://github.com/spareilleux/learn/blob/b19a296d6edc70be634ba147e27fd2d0c66f395f/code/csharp-beginner/exercises/l02_ex_fifth.cs) :

```csharp
// Exercice 3 : la case 7 est une quinte au-dessus de la corde à vide. À quel point 2^(7/12) est-il proche de 3/2 ?
double tempered = Math.Pow(2, 7 / 12.0);
double pure = 3.0 / 2.0;
Console.WriteLine($"Equal temperament: {tempered:F5}");
Console.WriteLine($"Pure fifth:        {pure:F5}");
Console.WriteLine($"Difference:        {(pure - tempered) / pure * 100:F3} %");
```

```text
Equal temperament: 1.49831
Pure fifth:        1.50000
Difference:        0.113 %
```

Deux pièges : `7 / 12` vaudrait `0`, et `3 / 2` vaudrait `1`. Écrire `12.0` et `3.0` fait des deux divisions des divisions de `double`. L'accord moderne, le *tempérament égal*, donne la même taille à tous les demi-tons, pour qu'une guitare joue juste dans toutes les tonalités, au prix de quintes trop étroites d'environ 0,1 %.

</details>

## Sources

- [Types (notions fondamentales de C#)](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/), [types intégrés](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/built-in-types)
- [Types numériques intégraux](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/integral-numeric-types), [types numériques à virgule flottante](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/floating-point-numeric-types), [opérateurs arithmétiques](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/arithmetic-operators)
- [Conversions de types et casts](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/conversions), [`Math.Round`](https://learn.microsoft.com/dotnet/api/system.math.round)
- [Interpolation de chaînes](https://learn.microsoft.com/dotnet/csharp/language-reference/tokens/interpolated), [chaînes de format numériques standard](https://learn.microsoft.com/dotnet/standard/base-types/standard-numeric-format-strings)
- [`Console.ReadLine`](https://learn.microsoft.com/dotnet/api/system.console.readline), [globalisation](https://learn.microsoft.com/dotnet/core/extensions/globalization)
