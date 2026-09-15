---
title: "Leçon 1 : la mémoire — valeurs, références et spans"
description: Quelle est la taille réelle d'une valeur et d'un objet, où le boxing se cache dans l'IL et quand le JIT de .NET 10 le supprime, les copies défensives avec in, les variables locales ref, les ref structs, Span<T> et stackalloc — le tout mesuré sur les objets valeur de Guitar Alchemist.
sidebar:
  label: 1. Mémoire, valeurs et spans
  order: 1
---

Vous connaissez la règle des livres de C# : les types valeur sont stockés en place, les types référence vivent sur le tas, et le boxing copie une valeur sur le tas. Cette leçon mesure chaque partie de cette règle. Elle compte les octets des valeurs et des objets, lit l'IL qu'émet le compilateur, et montre où le JIT de .NET 10 ignore ce que demande l'IL. Elle examine ensuite les outils que C# vous donne pour éviter les copies : `in`, les variables locales `ref`, `ref struct` et `Span<T>`, avec les erreurs du compilateur qui garantissent leur sûreté.

Les liens vers GA pointent vers le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) de `GuitarAlchemist/ga` ; les liens vers le runtime pointent vers le commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, qui porte le tag `v10.0.12`.

## Exécuter le programme de la leçon

Le code se trouve dans [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) clone GA à ce commit (seulement les trois projets que le programme référence), compile, exécute chaque leçon et compare la sortie avec [`expected/`](https://github.com/spareilleux/learn/tree/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected). Il vous faut le [SDK .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) et Git ; sous Windows, lancez-le depuis Git Bash.

```bash
bash code/csharp-advanced/check.sh                                   # chaque leçon, l'IL et les erreurs du compilateur
dotnet run --project code/csharp-advanced/Advanced -c Release -- l1  # cette leçon seulement, après check.sh
```

Les petites méthodes dont la leçon montre l'IL vivent dans leur propre projet, [`Snippets/Memory.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Snippets/Memory.cs), afin que leur IL ne bouge pas quand le reste du programme change. Mesurez toujours une build Release : une build Debug garde des variables locales supplémentaires et désactive la plupart des optimisations du JIT.

## Quelle est la taille d'une valeur, et celle d'un objet ?

Deux nombres comptent. [`Unsafe.SizeOf<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof) donne la taille *en place* : ce qu'occupe un champ ou un élément de tableau de type `T`. Pour un type référence, c'est la taille de la référence, 8 octets dans un processus 64 bits. La taille *sur le tas* est ce que coûte une allocation, et le programme la mesure avec [`GC.GetAllocatedBytesForCurrentThread()`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) autour d'un deuxième appel du code qui alloue, afin que le JIT et les constructeurs statiques aient déjà fait leur travail ([`Report.cs#L17-L24`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Report.cs#L17-L24)).

```text
== Inline size (Unsafe.SizeOf) and heap size of one allocation, in bytes
type                       inline   heap  what the heap bytes are
int                             4     24  a boxed int
long                            8     24  a boxed long
decimal                        16     32  a boxed decimal
Guid                           16     32  a boxed Guid
Point (2 ints)                  8     24  a boxed Point
Padded (byte, long)            16     32  a boxed Padded
(byte, long)                   16     32  a boxed tuple
object                          8     24  new object()
Node (class, 1 int)             8     24  new Node(1)
string                          8     32  a 5-char string
int[]                           8     24  an empty int[]
int[]                           8     64  an int[10]
GA PitchClass                   4     24  a boxed PitchClass
GA PitchClassSetId              4     24  a boxed PitchClassSetId
```

Chaque objet du tas 64 bits commence par deux mots de la taille d'un pointeur : l'en-tête de l'objet (utilisé pour les verrous et les codes de hachage) et le pointeur vers la table des méthodes, qui identifie le type. Viennent ensuite les champs, et le total est arrondi au multiple de 8 supérieur. Le minimum est de 24 octets, même pour `new object()`, qui n'a aucun champ.

- Un `int` boxé fait 8 + 8 + 4 = 20 octets, arrondis à 24. Un `long` boxé tient exactement dans 24 octets.
- `Padded` contient un `byte` et un `long`, mais occupe 16 octets en place : le `long` doit commencer sur une frontière de 8 octets, donc la disposition séquentielle par défaut du compilateur laisse 7 octets de remplissage après le `byte`.
- Un tableau ajoute sa longueur (4 octets, complétés à 8) à l'en-tête : 24 octets quand il est vide, et 24 + 10 × 4 = 64 pour dix `int`.
- Une chaîne stocke sa longueur, ses caractères UTF-16 et un caractère nul final : 8 + 8 + 4 + 5 × 2 + 2 = 32 octets pour cinq caractères.

GA modélise la musique avec de petits objets valeur. [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L26-L59) est un `readonly record struct` qui enveloppe un seul `int`, et [`PitchClassSetId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L8-L20) aussi : 4 octets chacun, aussi peu coûteux que l'`int` lui-même, tant qu'ils ne sont pas boxés.

## Le boxing : dans l'IL, et après le JIT

Le boxing convertit une valeur en `object` ou en interface : le runtime alloue un objet et y copie la valeur ([Boxing et unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)). Le compilateur émet une instruction `box` partout où cela se produit. Voici cinq petites méthodes, et l'IL de trois d'entre elles, désassemblé avec [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) `-il` par `check.sh` ([`expected/snippets-il.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/snippets-il.txt)).

```csharp
public static int ToObjectAndBack(int value)
{
    object boxed = value;
    return (int)boxed;
}

public static bool ThroughInterface<T>(T left, T right) where T : struct, IEquatable<T>
{
    IEquatable<T> equatable = left;
    return equatable.Equals(right);
}

public static bool ThroughConstraint<T>(T left, T right) where T : IEquatable<T> =>
    left.Equals(right);

public static string Format(int value) => string.Format("{0}", value);

public static string Interpolate(int value) => $"{value}";
```

```text
		IL_0000: ldarg.0
		IL_0001: box !!T
		IL_0006: ldarg.1
		IL_0007: callvirt instance bool class [System.Runtime]System.IEquatable`1<!!T>::Equals(!0)
		IL_000c: ret
	} // end of method Boxing::ThroughInterface

		IL_0000: ldarga.s left
		IL_0002: ldarg.1
		IL_0003: constrained. !!T
		IL_0009: callvirt instance bool class [System.Runtime]System.IEquatable`1<!!T>::Equals(!0)
		IL_000e: ret
	} // end of method Boxing::ThroughConstraint

		IL_0000: ldstr "{0}"
		IL_0005: ldarg.0
		IL_0006: box [System.Runtime]System.Int32
		IL_000b: call string [System.Runtime]System.String::Format(string, object)
		IL_0010: ret
	} // end of method Boxing::Format
```

- Convertir une valeur en interface produit un `box`, même quand l'interface est générique.
- Appeler la même méthode à travers une contrainte générique n'en produit pas : le préfixe [`constrained.`](https://learn.microsoft.com/dotnet/api/system.reflection.emit.opcodes.constrained) permet au runtime d'appeler `Equals` directement sur la valeur. C'est pourquoi le code générique sur `T : IEquatable<T>` ne boxe pas, et pourquoi GA peut déclarer le comportement de ses objets valeur dans des interfaces à membres abstraits statiques comme `IStaticValueObjectList<TSelf>` sans en payer le prix.
- `string.Format(string, object)` prend un `object` : l'`int` est boxé. Une chaîne interpolée est compilée en un [`DefaultInterpolatedStringHandler`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.defaultinterpolatedstringhandler), dont la méthode `AppendFormatted<T>` est générique : aucun `box`.
- `ToObjectAndBack` contient un `box` suivi d'un `unbox.any` du même type.

Voyons maintenant les octets qu'alloue chaque appel. Le programme produit le tableau deux fois : une fois normalement, où ces méthodes s'exécutent dans le premier niveau du JIT, non optimisé ; et une fois avec `DOTNET_TieredCompilation=0`, où chaque méthode est compilée d'emblée avec toutes les optimisations ([`Lesson1.cs#L103-L116`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L103-L116)).

```text
== Boxing: bytes allocated by the second call (tiered JIT, first tier)
Boxing.ToObjectAndBack(42)                0
Escape.BoxAndHash(42)                    24
Boxing.ThroughInterface(pc, pc)          24
Boxing.ThroughConstraint(pc, pc)          0
Boxing.Format(12345)                     56
Boxing.Interpolate(12345)                32
```

```text
== Boxing: bytes allocated by the second call (DOTNET_TieredCompilation=0)
Boxing.ToObjectAndBack(42)                0
Escape.BoxAndHash(42)                     0
Boxing.ThroughInterface(pc, pc)           0
Boxing.ThroughConstraint(pc, pc)          0
Boxing.Format(12345)                     56
Boxing.Interpolate(12345)                32
```

Il s'est passé trois choses que l'IL ne dit pas.

1. `ToObjectAndBack` n'alloue jamais, même au premier niveau : le JIT reconnaît un `box` immédiatement suivi d'un `unbox.any` et supprime les deux.
2. Avec l'optimisation complète, `BoxAndHash` (qui boxe, puis appelle `GetHashCode()` sur la boîte) et `ThroughInterface` n'allouent rien. Le JIT a prouvé que la boîte ne *s'échappe* pas de la méthode, et l'a placée sur la pile. L'allocation des boîtes sur la pile est arrivée avec [.NET 9](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), et [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation) étend l'analyse d'échappement aux petits tableaux, aux champs de structs et aux délégués. Lors d'une exécution normale, une méthode appelée assez souvent est recompilée avec ces optimisations après quelques dizaines d'appels ; la leçon 4 mesure la compilation par niveaux.
3. `Format` alloue toujours 56 octets : 24 pour l'`int` boxé, 32 pour la chaîne `"12345"`. La boîte est passée à `string.Format`, une grande méthode que le JIT n'intègre pas dans l'appelant, donc elle s'échappe. `Interpolate` n'alloue que la chaîne.

Ainsi, « le boxing alloue » est vrai de l'IL, et seulement parfois du code machine. L'IL vous dit où regarder ; une mesure vous dit ce que cela coûte.

## `in` et `ref` : les copies que vous ne voyez pas

Une struct passée par valeur est copiée. Les [paramètres `ref`, `in` et `ref readonly`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters#reference-parameters) passent à la place une référence vers elle. `in` promet à l'appelant que la méthode ne modifiera pas l'argument. Pour tenir cette promesse quand la struct est mutable, le compilateur doit supposer que tout appel de méthode peut la modifier, et il appelle donc la méthode sur une copie cachée.

```csharp
public struct Counter
{
    public int Value;

    public void Increment() => Value++;
}

public static class DefensiveCopy
{
    public static int ByIn(in Counter counter)
    {
        counter.Increment();
        return counter.Value;
    }

    public static int ByRef(ref Counter counter)
    {
        counter.Increment();
        return counter.Value;
    }
}
```

```text
== in and ref: a method called on an in parameter runs on a copy
ByIn returns 0, counter.Value is now 0
ByRef returns 1, counter.Value is now 1
```

Aucun avertissement, aucune erreur : l'incrément est perdu en silence. L'IL de `ByIn` montre la copie, `ldobj` dans la variable locale 0, puis l'appel sur l'adresse de cette variable :

```text
		IL_0000: ldarg.0
		IL_0001: ldobj Snippets.Counter
		IL_0006: stloc.0
		IL_0007: ldloca.s 0
		IL_0009: call instance void Snippets.Counter::Increment()
		IL_000e: ldarg.0
		IL_000f: ldfld int32 Snippets.Counter::Value
		IL_0014: ret
	} // end of method DefensiveCopy::ByIn
```

La même copie défensive se produit quand vous appelez une méthode sur un champ `readonly` dont le type est une struct mutable. La solution consiste à rendre la struct, ou au moins la méthode, `readonly` : le compilateur sait alors que l'appel ne peut pas modifier la valeur et passe directement la référence. Les paramètres `ref readonly` (C# 12) se comportent comme `in` à l'intérieur de la méthode, mais demandent à l'appelant de passer une variable avec `ref` ou `in`, et produisent un avertissement quand il passe une valeur temporaire : utilisez-les pour les API qui ont besoin d'une référence vers un emplacement existant, pas simplement pour éviter une copie. Affecter un champ d'un paramètre `in` est une erreur de compilation :

```csharp
public static void Reset(in Counter counter) => counter.Value = 0;
```

```text
l1_in_assign.cs(9,53): error CS8332: Cannot assign to a member of variable 'counter' or use it as the right hand side of a ref assignment because it is a readonly variable
```

Chaque extrait rejeté du cours est compilé seul par [`CompileFail/Program.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), qui utilise Roslyn 5.0.0, le compilateur du SDK .NET 10.0.1xx ; les messages sont identiques à ceux de `dotnet build` ([`expected/compile-fail.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/compile-fail.txt)).

## Variables locales et retours `ref`

Une variable locale `ref` est un alias vers un emplacement de stockage : un élément de tableau, un champ, une entrée de dictionnaire. [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) renvoie une référence vers la valeur d'une entrée de `Dictionary`, en ajoutant l'entrée si elle manque. Incrémenter un compteur ne demande alors qu'une recherche par hachage au lieu de deux (`TryGetValue`, puis l'affectation par l'indexeur). Le programme compte les 4 096 ensembles de classes de hauteurs de GA par nombre de notes :

```csharp
var byCardinality = new Dictionary<int, int>();
foreach (var id in PitchClassSetId.Items)
{
    ref var count = ref CollectionsMarshal.GetValueRefOrAddDefault(byCardinality, id.Cardinality, out _);
    count++;
}
```

```text
== ref locals: one dictionary lookup per update (CollectionsMarshal)
sets by number of notes: 1 12 66 220 495 792 924 792 495 220 66 12 1
```

Ce sont les coefficients binomiaux C(12, k) : un ensemble vide, 12 notes seules, 66 intervalles, 220 ensembles de trois notes. La référence n'est valide que tant que le dictionnaire ne change pas : ajouter une autre clé peut le redimensionner et déplacer les entrées, c'est pourquoi la méthode se trouve dans `CollectionsMarshal` et non sur `Dictionary` lui-même.

Le compilateur suit l'endroit vers lequel pointe une référence. Renvoyer une référence vers une variable locale, dont le stockage disparaît avec le cadre de pile de la méthode, est refusé :

```csharp
public static ref int Next()
{
    var count = 0;
    return ref count;
}
```

```text
l1_ref_to_local.cs(7,20): error CS8168: Cannot return local 'count' by reference because it is not a ref local
```

## `ref struct`, `Span<T>` et `stackalloc`

[`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) est une référence plus une longueur : une fenêtre sur un tableau, une chaîne, de la mémoire native ou la pile. Pour être sûr, il ne doit jamais survivre à la mémoire vers laquelle il pointe, c'est donc une [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct) : une struct qui ne peut vivre que sur la pile. Le compilateur l'impose au moyen d'une famille d'erreurs. Une `ref struct` ne peut pas être un champ d'une classe :

```csharp
public class FretBuffer
{
    private Span<int> _frets; // un Span ne peut vivre que sur la pile
}
```

```text
l1_ref_struct_field.cs(4,13): error CS8345: Field or auto-implemented property cannot be of type 'Span<int>' unless it is an instance member of a ref struct.
```

Elle ne peut pas être capturée par une lambda, qui la stockerait dans un objet de fermeture sur le tas :

```csharp
public static Func<int> Sum(Span<int> frets) => () => frets[0] + frets[1];
```

```text
l1_span_lambda.cs(4,59): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
l1_span_lambda.cs(4,70): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
```

Elle ne peut pas être l'argument de type d'un type générique qui ne l'autorise pas explicitement. Depuis C# 13, un paramètre générique peut déclarer `allows ref struct` ; `List<T>` ne le fait pas, parce qu'il stocke ses éléments dans un tableau :

```csharp
public static List<Span<int>> Shapes = [];
```

```text
l1_span_type_argument.cs(4,35): error CS9244: The type 'Span<int>' may not be a ref struct or a type parameter allowing ref structs in order to use it as parameter 'T' in the generic type or method 'List<T>'
```

Et la mémoire obtenue par [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc) ne peut pas quitter la méthode qui l'a allouée :

```csharp
public static Span<int> Empty()
{
    Span<int> frets = stackalloc int[6];
    return frets; // la mémoire disparaît quand la méthode se termine
}
```

```text
l1_stackalloc_escape.cs(7,16): error CS8352: Cannot use variable 'frets' in this context because it may expose referenced variables outside of their declaration scope
```

Quand les données doivent survivre au cadre de pile, par-delà un `await` ou dans un champ, utilisez [`Memory<T>`](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), une struct ordinaire qui peut être stockée n'importe où et transformée en `Span<T>` là où le travail se fait.

Dans le cadre de ces règles, les spans suppriment des allocations. Un voicing de guitare s'écrit souvent sous la forme de six cases, `x 3 2 0 1 0` pour un accord de do ouvert. La première version découpe la chaîne ; la seconde la tranche avec [`MemoryExtensions.Split`](https://learn.microsoft.com/dotnet/api/system.memoryextensions.split), qui renvoie des plages, analyse chaque tranche avec `int.Parse(ReadOnlySpan<char>)`, et stocke les cases dans six `int` sur la pile ([`Lesson1.cs#L126-L155`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L126-L155)).

```csharp
public static int SumWithSplit(string voicing)
{
    var sum = 0;
    foreach (var part in voicing.Split(' '))
    {
        if (part != "x")
        {
            sum += int.Parse(part);
        }
    }
    return sum;
}

public static int SumWithSpans(string voicing)
{
    Span<int> frets = stackalloc int[6];
    var count = 0;
    var text = voicing.AsSpan();
    foreach (var range in text.Split(' '))
    {
        var part = text[range];
        frets[count++] = part is "x" ? -1 : int.Parse(part);
    }
    var sum = 0;
    foreach (var fret in frets[..count])
    {
        if (fret > 0) sum += fret;
    }
    return sum;
}
```

```text
== Parsing a voicing: string.Split versus spans
split: 6 frets, 216 bytes
spans: 6 frets, 0 bytes
```

Les 216 octets sont le `string[]` de six éléments (24 + 6 × 8 = 72 octets) et six chaînes d'un caractère, de 24 octets chacune. Pour un seul voicing, ce n'est rien ; pour les millions de voicings qu'énumère une recherche d'accords, c'est du travail pour le ramasse-miettes, que la leçon 2 mesure.

## Une copie par appel dans GA

Les objets valeur de GA exposent leurs valeurs possibles sous forme de span. Pour `PitchClass`, `ItemsSpan` renvoie un tableau mis en cache ([`ValueObjectCache.cs#L45-L49`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L45-L49)). `PitchClassSetId` a sa propre implémentation ([`PitchClassSetId.cs#L59`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59), [`#L70-L71`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)) :

```csharp
public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items is PitchClassSetId[] arr ? arr : [.. Items];

public static IReadOnlyCollection<PitchClassSetId> Items { get; } =
    [.. Enumerable.Range(_minValue, _maxValue - _minValue + 1).Select(i => new PitchClassSetId(i))];
```

L'intention est claire : renvoyer le tableau sans le copier. Mais `Items` est initialisée avec une expression de collection dont la cible est l'interface `IReadOnlyCollection<T>`, et pour cette cible le compilateur est libre de construire un type à lui ([expressions de collection, traduction vers une interface non mutable](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md#non-mutable-interface-translation)). Le test `Items is PitchClassSetId[]` est donc toujours faux, et chaque lecture d'`ItemsSpan` copie 4 096 identifiants dans un nouveau tableau :

```text
== GA: ItemsSpan of two value objects
PitchClass.ItemsSpan: 12 items, 0 bytes
PitchClassSetId.ItemsSpan: 4096 items, 16408 bytes
PitchClassSetId.Items is <>z__ReadOnlyList`1
```

Ces 16 408 octets, ce sont 24 octets d'en-tête de tableau plus 4 096 × 4. Le code compile, s'exécute et renvoie les bonnes valeurs ; seule une mesure en révèle le coût. La correction fait l'objet de l'exercice 3.

## Exercices

1. Prédisez `Unsafe.SizeOf` du tuple `(bool, int, bool)`, d'une struct avec les champs `bool Muted; int Fret; bool Barre;` dans cet ordre, et de la même struct marquée [`[StructLayout(LayoutKind.Auto)]`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.layoutkind).
2. Faites détecter par le compilateur l'incrément perdu de `ByIn` : que changez-vous dans `Counter`, et que dit alors le compilateur à propos d'`Increment` ?
3. Réécrivez `PitchClassSetId.ItemsSpan` pour qu'elle n'alloue pas, et vérifiez qu'elle renvoie les mêmes identifiants.

<details>
<summary>Solutions</summary>

1. La struct dans l'ordre de déclaration occupe **12** octets : `bool` (1 octet, plus 3 de remplissage), `int` (4), `bool` (1, plus 3 de remplissage), parce que la taille d'une struct est un multiple de l'alignement de son plus grand champ. Avec `LayoutKind.Auto`, le runtime peut réordonner les champs : `int`, `bool`, `bool`, 2 de remplissage, soit **8** octets. `ValueTuple` est déclaré avec `LayoutKind.Auto`, donc le tuple occupe lui aussi **8** octets. La disposition séquentielle est la valeur par défaut des structs en C# parce qu'elle correspond au code natif lors de l'interop ; pour une struct qui ne passe jamais au code natif, `Auto` peut faire gagner de la place.

    ```text
    1. (bool, int, bool) 8 bytes, SequentialFlags 12, AutoFlags 8
    ```

2. Marquez `Increment` comme membre `readonly`, ou la struct entière comme `readonly struct`. Le compilateur refuse alors l'incrément à l'intérieur de la méthode, et l'appel sur un paramètre `in` n'a plus besoin de copie défensive. Pour garder une méthode qui modifie la valeur, prenez plutôt le paramètre par `ref`.

    ```csharp
    public readonly void Increment() => Value++;
    ```

    ```text
    l1_readonly_member.cs(6,41): error CS1604: Cannot assign to 'Value' because it is read-only
    ```

3. Stockez une fois pour toutes les identifiants dans un tableau, et renvoyez le tableau sous forme de span : la conversion de `T[]` en `ReadOnlySpan<T>` ne copie pas ([`Lesson1.cs#L94-L100`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L94-L100)). Dans GA même, déclarer `Items` avec un tableau concret, ou passer par `ValueObjectUtils<PitchClassSetId>.ItemsSpan` comme les autres objets valeur, aurait le même effet.

    ```csharp
    private static readonly PitchClassSetId[] Items = [.. PitchClassSetId.Items];

    public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items;
    ```

    ```text
    3. cached ItemsSpan: 4096 items, 0 bytes, same ids True
    ```

</details>

## À retenir

- Un objet 64 bits coûte au moins 24 octets : l'en-tête, le pointeur vers la table des méthodes, puis les champs, le tout arrondi à un multiple de 8. `Unsafe.SizeOf<T>()` donne la taille en place ; `GC.GetAllocatedBytesForCurrentThread()` autour d'un appel déjà rodé donne le coût sur le tas.
- L'IL montre le boxing sous la forme d'un `box`. Les contraintes génériques appellent la méthode via `constrained.` sans boxing, et les chaînes interpolées se formatent sans boxing.
- Le JIT peut supprimer une boîte que l'IL demande : toujours pour un `box` suivi d'un `unbox.any`, et, dans le code optimisé, chaque fois que la boîte ne s'échappe pas de la méthode. Mesurez le code optimisé, pas l'IL.
- Appeler une méthode sur un paramètre `in` ou sur un champ `readonly` d'une struct mutable l'exécute sur une copie silencieuse. Rendez la struct ou la méthode `readonly`.
- `Span<T>` et `stackalloc` permettent d'analyser et de découper sans allouer. Les erreurs de sûreté des références du compilateur (CS8345, CS8352, CS9108, CS9244, CS8168) sont ce qui les empêche de pointer vers une mémoire qui n'existe plus ; `Memory<T>` sert aux données qui doivent survivre au cadre de pile.
- Une expression de collection affectée à une interface n'est pas un tableau. C'est pour cette raison que `PitchClassSetId.ItemsSpan` de GA copie 16 Ko à chaque appel.

## Sources

- Microsoft Learn : [`Unsafe.SizeOf`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof), [Boxing et unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing), [Paramètres de méthode](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [Types ref struct](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc), [Recommandations d'utilisation de Memory et Span](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), [Expressions de collection](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions).
- Nouveautés du runtime : [.NET 9, allocation sur la pile des objets boxés](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), [.NET 10, allocation sur la pile](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation).
- [ECMA-335](https://www.ecma-international.org/publications-and-standards/standards/ecma-335/), partition III, pour `box`, `unbox.any` et le préfixe `constrained.`.
- La proposition du langage C# pour les [expressions de collection](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md).
