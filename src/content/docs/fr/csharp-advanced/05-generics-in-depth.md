---
title: "Leçon 5 : les génériques en profondeur"
description: Des génériques réifiés mesurés en octets, ce que chaque contrainte inscrit dans les métadonnées et celles que seul le compilateur vérifie, default(T) et T?, les membres abstraits statiques et les mathématiques génériques, la variance, allows ref struct, les caches statiques par type, et le code machine que le JIT partage entre types référence, sur l'IStaticValueObjectList<TSelf> de Guitar Alchemist, avec l'effacement de Java en comparaison.
sidebar:
  label: 5. Les génériques en profondeur
  order: 5
---

Vous utilisez les génériques tous les jours, et la leçon 1 a déjà montré l'une des choses qu'ils font sous le capot : un appel à travers une contrainte est émis avec le préfixe `constrained.`, et ne provoque pas de boxing. Cette leçon va plus loin. Elle regarde ce qu'est un type générique à l'exécution, ce que chaque contrainte écrit dans les métadonnées, ce que `default(T)` et `T?` veulent vraiment dire, comment les membres abstraits statiques permettent à une interface de décrire un type plutôt qu'un objet, et quand le JIT donne le même code machine à deux instanciations. Chaque point est affiché par un programme, compilé, désassemblé ou mesuré.

L'exemple fil rouge est une famille d'interfaces de Guitar Alchemist. `PitchClass`, `Fret`, `IntervalClass` et une douzaine d'autres petites structs implémentent [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), qui utilise presque toutes les fonctionnalités de cette leçon à la fois : un paramètre de type qui désigne le type qui l'implémente, une contrainte `struct`, des membres abstraits statiques, et une classe générique statique utilisée comme cache.

Les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) ; les liens vers le runtime pointent sur le commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, étiqueté `v10.0.12`.

## Exécuter le programme de la leçon

```bash
bash code/csharp-advanced/check.sh                                   # toutes les leçons, comparées avec expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l5  # cette leçon seulement, après check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*GenericMathBenchmarks*"   # une seule classe de benchmarks
```

Le programme est [`Advanced/Lesson5.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs) ; les quatre méthodes dont la leçon montre l'IL sont dans [`Snippets/Generics.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs) ; les extraits rejetés sont les fichiers `l5_*.cs` de [`CompileFail/snippets`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets). `check.sh` compare le tout avec [`expected/`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/expected) sur trois OS. Les durées viennent de [`Benchmarks/GenericBenchmarks.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Benchmarks/GenericBenchmarks.cs), exécuté sur la machine de l'auteur, celle que décrit la [leçon 4](../04-measured-performance/).

## Des génériques réifiés : un type par instanciation

En .NET, un type générique est *réifié* : `List<int>` et `List<string>` sont deux types distincts à l'exécution, chacun avec son propre objet `Type`, et une méthode générique peut demander `typeof(T)` ou créer un `new T[n]`. Le runtime construit chaque type fermé à partir de la définition ouverte `List<T>` la première fois qu'il en a besoin ([Génériques dans le runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time)). Pour un type valeur, cela veut dire que les éléments sont stockés en place, sans boîtes ([`Lesson5.cs#L33-L62`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L33-L62)) :

```text
== Reified generics: every instantiation is a type of its own
typeof(List<int>) == typeof(List<string>): False
typeof(List<PitchClass>): System.Collections.Generic.List`1[GA.Domain.Core.Theory.Atonal.PitchClass]
new List<PitchClass>() is List<int>: False
NameOf<PitchClass>(): PitchClass; new T[3] is GA.Domain.Core.Theory.Atonal.PitchClass[]
12 pitch classes in a List<PitchClass>: 104 bytes
12 pitch classes in a List<object>:     440 bytes
```

Les 104 octets sont l'objet `List`, 32 octets, et un tableau de 12 valeurs `PitchClass` de quatre octets, 24 + 48. La `List<object>` a les mêmes 32 octets, un tableau de 12 références, 24 + 96, et douze boîtes de 24 octets chacune : 440 octets, plus de quatre fois plus, et treize objets pour le ramasse-miettes au lieu de deux. Cette seconde liste montre à quoi ressemble toute collection générique de nombres en Java, comme on le verra dans la dernière section.

## Les contraintes : ce que vérifie le compilateur, et ce que vérifie le runtime

Une contrainte fait deux choses : elle restreint les arguments de type qu'un appelant peut passer, et elle permet au code générique d'utiliser ce que la contrainte promet, un constructeur, un opérateur, une méthode. La référence C# les liste toutes ([Contraintes sur les paramètres de type](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)). Sans contrainte, `T` n'offre que ce qu'offre `object`, et le compilateur le dit :

```csharp
// expect: CS0304
public static class Factory
{
    public static T Create<T>() => new T();
}
```

```text
l5_new_without_constraint.cs(4,36): error CS0304: Cannot create an instance of the variable type 'T' because it does not have the new() constraint
```

```csharp
// expect: CS0019
public static class Arithmetic
{
    public static T Add<T>(T left, T right) => left + right;
}
```

```text
l5_operator_without_constraint.cs(4,48): error CS0019: Operator '+' cannot be applied to operands of type 'T' and 'T'
```

La seconde erreur était la limite classique des génériques C# jusqu'à C# 11 ; les mathématiques génériques, plus bas, la lèvent. D'abord, que deviennent les contraintes une fois compilées ? Le programme déclare une méthode vide par contrainte et relit son paramètre de type par réflexion, avec [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes) ([`Lesson5.cs#L66-L92`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L66-L92)) :

```text
== Constraints in the metadata: what the runtime sees
Class            ReferenceTypeConstraint; types []; attributes []
Struct           NotNullableValueTypeConstraint, DefaultConstructorConstraint; types [ValueType]; attributes []
Unmanaged        NotNullableValueTypeConstraint, DefaultConstructorConstraint; types [ValueType]; attributes [IsUnmanagedAttribute]
NotNull          None; types []; attributes []
New              DefaultConstructorConstraint; types []; attributes []
Enum             NotNullableValueTypeConstraint, DefaultConstructorConstraint; types [Enum, ValueType]; attributes []
AllowsRefStruct  AllowByRefLike; types []; attributes []
```

- `struct` s'écrit sous la forme de deux indicateurs, « pas un type valeur nullable » et « a un constructeur par défaut », plus le type de base `ValueType` : pour le runtime, une struct a toujours un constructeur sans paramètre.
- `unmanaged` s'écrit exactement comme `struct`, plus un `IsUnmanagedAttribute` que seul le compilateur lit.
- `notnull` ne laisse rien que le runtime lise : c'est une annotation de nullabilité, que le compilateur vérifie sous la forme d'un avertissement.
- `allows ref struct`, nouveau en C# 13, est un indicateur à part entière, et c'est une *anti-contrainte* : il élargit ce que l'appelant peut passer au lieu de le restreindre.

Le runtime peut donc vérifier certaines contraintes et pas d'autres. [`MethodInfo.MakeGenericMethod`](https://learn.microsoft.com/dotnet/api/system.reflection.methodinfo.makegenericmethod) instancie une méthode à l'exécution, sans passer par le compilateur :

```text
== Constraints the compiler checks and the runtime doesn't
MakeGenericMethod((int, string)) on 'where T : unmanaged': accepted
MakeGenericMethod(string) on 'where T : unmanaged':        ArgumentException
MakeGenericMethod(int?) on 'where T : struct':            ArgumentException
sizeof(T) with T : unmanaged: PitchClass 4, (byte, long) 16
IsReferenceOrContainsReferences: PitchClass False, (int, string) True
new T() with T : new(): StringBuilder, Str 0
```

Le runtime accepte `(int, string)` pour `unmanaged`, parce que ce qu'il vérifie, c'est « un type valeur non nullable », et un tuple qui contient une `string` en est un. Le compilateur rejette la même chose, parce que `unmanaged` veut aussi dire « aucune référence, à quelque profondeur que ce soit », et c'est ce qui rend `sizeof(T)` et les pointeurs vers `T` sûrs :

```csharp
// expect: CS8377
public struct Voicing
{
    public int Root;
    public string Name;
}

public static class Buffers
{
    public static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

    public static int VoicingSize() => SizeOf<Voicing>();
}
```

```text
l5_unmanaged_reference_field.cs(12,40): error CS8377: The type 'Voicing' must be a non-nullable value type, along with all fields at any level of nesting, in order to use it as parameter 'T' in the generic type or method 'Buffers.SizeOf<T>()'
```

Quand du code doit décider à l'exécution si un `T` contient des références, par exemple pour savoir s'il faut effacer un tampon pour le ramasse-miettes, [`RuntimeHelpers.IsReferenceOrContainsReferences<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.runtimehelpers.isreferenceorcontainsreferences) répond, et le JIT en fait une constante pour chaque type valeur. La contrainte `struct`, en revanche, exclut `Nullable<T>` à la fois dans le compilateur et dans le runtime :

```csharp
// expect: CS0453
public static class Options
{
    public static T? Find<T>(T[] items) where T : struct => items.Length > 0 ? items[0] : null;

    public static int? First(int?[] items) => Find(items);
}
```

```text
l5_struct_nullable_argument.cs(6,47): error CS0453: The type 'int?' must be a non-nullable value type in order to use it as parameter 'T' in the generic type or method 'Options.Find<T>(T[])'
```

Et `notnull`, qui n'existe que dans le compilateur, ne donne qu'un avertissement ; `Dictionary<TKey, TValue>` déclare sa clé `notnull` :

```csharp
// expect: CS8714
public static class Chords
{
    public static Dictionary<string?, int> ByName = new();
}
```

```text
l5_notnull_nullable_key.cs(4,44): warning CS8714: The type 'string?' cannot be used as type parameter 'TKey' in the generic type or method 'Dictionary<TKey, TValue>'. Nullability of type argument 'string?' doesn't match 'notnull' constraint.
```

Enfin, qu'émet le compilateur pour `new T()` ? Pas un appel de constructeur : il ne peut pas savoir lequel appeler. L'IL de [`Generics.Create`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L11) appelle [`Activator.CreateInstance<T>()`](https://learn.microsoft.com/dotnet/api/system.activator.createinstance), et pour une struct, cette méthode renvoie la valeur zéro sans exécuter la moindre validation. Le `Str` de GA, une corde de guitare numérotée de 1 à 26, en sort comme la corde 0 à la dernière ligne ci-dessus :

```text
.method public hidebysig static
	!!T Create<.ctor T> () cil managed
{
	// Header size: 1
	// Code size: 6 (0x6)
	.maxstack 8

	IL_0000: call !!0 [System.Runtime]System.Activator::CreateInstance<!!T>()
	IL_0005: ret
} // end of method Generics::Create
```

## `default(T)`, et ce que veut dire `T?`

[`default(T)`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default) a tous ses bits à zéro : `null` pour un type référence, `0` pour un nombre, et pour une struct, chaque champ mis à zéro. L'IL est `initobj !!T`, quel que soit `T`. La surprise, c'est `T?`. Sur un `T` sans contrainte, `T?` dit seulement « peut valoir la valeur par défaut » ; il ne transforme pas `int` en `int?`. Avec `where T : struct`, `T?` est `Nullable<T>` ([`Lesson5.cs#L113-L141`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L113-L141)) :

```csharp
static T? FirstOrDefault<T>(IEnumerable<T> items, Func<T, bool> predicate)
{
    foreach (var item in items)
    {
        if (predicate(item)) return item;
    }
    return default;
}

static T? FirstOrNull<T>(IEnumerable<T> items, Func<T, bool> predicate) where T : struct
{
    foreach (var item in items)
    {
        if (predicate(item)) return item;
    }
    return null;
}
```

```text
== default(T), and what T? means
FirstOrDefault(1 2 3, > 5): 0
FirstOrDefault("C" "G", empty): null
FirstOrNull(1 2 3, > 5): null
return type of FirstOrDefault<int>: Int32; of FirstOrNull<int>: Nullable`1
default(PitchClass): 0, the pitch class C
default(Str).Value: 0; Str.FromValue(0): ArgumentOutOfRangeException
new Str[6]: 0 0 0 0 0 0
```

`FirstOrDefault<int>` ne peut pas distinguer « pas trouvé » de « trouvé 0 » : son type de retour est un simple `Int32`. C'est aussi le comportement du `FirstOrDefault` de LINQ. Les lignes de GA montrent le même piège sur des types du domaine. `default(PitchClass)` vaut 0, un do parfaitement valide, si bien qu'une classe de hauteurs manquante ressemble à un do. `default(Str)` est la corde 0, que [`Str`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L16-L17) refuse de créer : son accesseur `init` vérifie l'intervalle, mais `default`, `new Str[6]` et `new T()` ne l'exécutent jamais. Une struct qui a un invariant ne peut pas l'imposer à une mémoire mise à zéro ; les objets valeurs de GA dont le minimum est 1, `Str` et les degrés de gamme, peuvent tous apparaître avec la valeur 0 de cette façon.

## Les membres abstraits statiques

Une méthode d'interface décrit ce qu'un *objet* sait faire. Un [membre abstrait statique](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), depuis C# 11, décrit ce qu'un *type* sait faire : se créer à partir d'un `int`, donner son minimum, additionner deux de ses valeurs. Le code générique l'appelle sur le paramètre de type, `T.FromValue(3)`. Les interfaces [`IValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47) et [`IRangeValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L23) de GA sont construites ainsi :

```csharp
public interface IValueObject<TSelf> : IValueObject, IComparable<TSelf>, IEquatable<TSelf>
    where TSelf : IValueObject<TSelf>
{
    static abstract TSelf FromValue(int value);

    static abstract implicit operator TSelf(int value);
    static abstract implicit operator int(TSelf fret);
}

public interface IRangeValueObject<TSelf> : IValueObject<TSelf>
    where TSelf : IRangeValueObject<TSelf>
{
    static abstract TSelf Min { get; }

    static abstract TSelf Max { get; }
}
```

La contrainte `where TSelf : IRangeValueObject<TSelf>` est le motif *autoréférent* : `PitchClass` implémente `IRangeValueObject<PitchClass>`, donc à l'intérieur de l'interface, `TSelf` veut dire « le type qui implémente l'interface », et `FromValue` peut renvoyer un `PitchClass` plutôt qu'une interface. Grâce à cela, une seule méthode générique fonctionne pour tous les objets valeurs de GA ([`Lesson5.cs#L160-L177`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L160-L177)) :

```csharp
static string Range<T>() where T : IRangeValueObject<T> =>
    $"{typeof(T).Name,-13} {T.Min,2} to {T.Max,-2}  {T.Max.Value - T.Min.Value + 1,2} values";

static IEnumerable<T> AllOf<T>() where T : IRangeValueObject<T> =>
    Enumerable.Range(T.Min.Value, T.Max.Value - T.Min.Value + 1).Select(v => T.FromValue(v));
```

```text
== Static abstract members: GA's IRangeValueObject<TSelf>
PitchClass     0 to E   12 values
IntervalClass 0 (Unison) to 6 (A4, d5; Tritone)   7 values
Fret           x to 36  38 values
Str            1 to 26  26 values
AllOf<IntervalClass>(): 0 (Unison) 1 (m2, M7) 2 (M2, m7) 3 (m3, M6) 4 (M3, m6) 5 (P4, P5) 6 (A4, d5; Tritone)
CountItems<PitchClass>() through IStaticReadonlyCollection<T>.Items: 12
```

Dans l'IL, un appel à un membre abstrait statique est un `call` avec le même préfixe `constrained.` qu'à la leçon 1, sur la méthode de l'interface. Il n'a aucun objet sur lequel se répartir : le runtime le résout d'après l'argument de type, et dans le code compilé pour un type valeur, le JIT le résout une fois pour toutes et peut l'inliner ([`Generics.FromValue`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L15)) :

```text
IL_0000: ldarg.0
IL_0001: constrained. !!T
IL_0007: call !0 class Snippets.IFromValue`1<!!T>::FromValue(int32)
IL_000c: ret
```

Le prix des membres abstraits statiques, c'est que l'interface n'est plus un type dont on peut détenir une valeur dans du code générique. Ses membres statiques n'ont pas d'implémentation à appeler, donc elle ne peut pas servir d'argument de type :

```csharp
// expect: CS8920
public interface IFromValue<TSelf> where TSelf : IFromValue<TSelf>
{
    static abstract TSelf FromValue(int value);
}

public readonly record struct PitchClass(int Value) : IFromValue<PitchClass>
{
    public static PitchClass FromValue(int value) => new(value % 12);
}

public static class Registry
{
    public static List<IFromValue<PitchClass>> Factories = [];
}
```

```text
l5_static_abstract_type_argument.cs(14,48): error CS8920: The interface 'IFromValue<PitchClass>' cannot be used as type argument. Static member 'IFromValue<PitchClass>.FromValue(int)' does not have a most specific implementation in the interface.
```

## Les mathématiques génériques

.NET 7 a utilisé les membres abstraits statiques pour donner à chaque type numérique un ensemble d'interfaces : [`INumber<T>`](https://learn.microsoft.com/dotnet/api/system.numerics.inumber-1) et ses parties, `IAdditionOperators<TSelf, TOther, TResult>`, `INumberBase<T>` avec `Zero` et `One`, et les autres ([Mathématiques génériques](https://learn.microsoft.com/dotnet/standard/generics/math)). Un opérateur est une méthode statique, donc `left + right` sur `T : IAdditionOperators<T, T, T>` se compile en un appel contraint à `op_Addition`, et c'est l'IL de `Generics.Add` :

```text
IL_0000: ldarg.0
IL_0001: ldarg.1
IL_0002: constrained. !!T
IL_0008: call !2 class [System.Runtime]System.Numerics.IAdditionOperators`3<!!T, !!T, !!T>::op_Addition(!0, !1)
IL_000d: ret
```

Une seule méthode `Sum` et une seule méthode `Mean` servent alors tous les types numériques ([`Lesson5.cs#L181-L205`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L181-L205)) :

```csharp
public static T Sum<T>(ReadOnlySpan<T> values) where T : INumberBase<T>
{
    var sum = T.Zero;
    foreach (var value in values) sum += value;
    return sum;
}

static T Mean<T>(ReadOnlySpan<T> values) where T : INumber<T> => Sum(values) / T.CreateChecked(values.Length);

static T AddChecked<T>(T left, T right) where T : IAdditionOperators<T, T, T> => checked(left + right);
```

```text
== Generic math: one Sum and one Mean for every number type
int     sum 10, mean 2
double  sum 10, mean 2.5
decimal sum 0.3, double sum 0.30000000000000004
byte    250 + 10: unchecked 4, checked OverflowException
int     MaxValue + 1: unchecked -2147483648, checked OverflowException
double  MaxValue + MaxValue: checked Infinity
byte.CreateChecked(300) OverflowException, CreateSaturating 255, CreateTruncating 44
int.CreateSaturating(double.NaN) 0, int.CreateSaturating(1e10) 2147483647
```

Le code générique conserve la sémantique de chaque type. La moyenne entière de 1, 2, 3 et 4 est 2, la moyenne en `double` est 2,5 ; `decimal` additionne 0,1 et 0,2 exactement, `double` non. Une expression [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) dans du code générique appelle l'opérateur *checked* du type, `op_CheckedAddition`, un autre ajout de C# 11 : `byte` et `int` lèvent une exception, et `double`, qui ne connaît pas le dépassement, donne l'infini. La conversion entre types numériques existe en trois variantes explicites : [`CreateChecked`](https://learn.microsoft.com/dotnet/api/system.numerics.inumberbase-1.createchecked) lève une exception quand la valeur ne tient pas, `CreateSaturating` la borne, et `CreateTruncating` garde les bits de poids faible : 300 vaut `0x12C`, et `0x2C` vaut 44.

`Sum<int>` est-elle aussi rapide qu'une boucle écrite pour `int` ? `GenericMathBenchmarks` additionne 1 024 valeurs :

| Method        | Mean     | Error   | StdDev  | Ratio | RatioSD |
|-------------- |---------:|--------:|--------:|------:|--------:|
| IntLoop       | 205.7 ns | 1.60 ns | 1.50 ns |  1.00 |    0.01 |
| IntGeneric    | 208.7 ns | 1.46 ns | 2.81 ns |  1.01 |    0.02 |
| DoubleLoop    | 363.3 ns | 4.44 ns | 4.16 ns |  1.77 |    0.02 |
| DoubleGeneric | 360.3 ns | 6.87 ns | 6.43 ns |  1.75 |    0.03 |

La version générique et la boucle écrite à la main s'exécutent dans le même temps, pour `int` comme pour `double`, aux marges d'erreur près : le JIT compile une `Sum<int>` qui lui est propre, dans laquelle `T.Zero` et `+=` sont ceux d'`int`. Ce n'est vrai que parce que `int` et `double` sont des types valeur, ce qui est le sujet de la section suivante.

## Comment le JIT partage le code générique

Le runtime ne peut pas compiler un seul corps de code machine pour tous les `T` : un `Describe<int>` reçoit 4 octets dans un registre, un `Describe<long>` 8 octets, un `Describe<PitchClass>` une struct. Il *peut* partager du code entre types référence, parce que toute référence est un pointeur de même taille, et que le ramasse-miettes les traite toutes de la même façon. Le JIT compile donc une version par type valeur, et une seule version pour tous les types référence, instanciée sur un type de substitution appelé `System.__Canon` ([Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md)).

Inutile de le croire sur parole. Le JIT affiche la liste des méthodes qu'il compile quand `DOTNET_JitDisasmSummary=1` est défini, et l'écrit dans un fichier avec `DOTNET_JitStdOutFile` ; les deux fonctionnent dans le runtime livré ([Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md)). Le programme appelle `Shared<T>.Describe` pour six arguments de type, et `check.sh` garde les lignes de cette liste qui la mentionnent ([`Lesson5.cs#L291-L348`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L291-L348), [`check.sh`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/check.sh)) :

```csharp
public static class Shared<T>
{
    public static int Calls;

    [MethodImpl(MethodImplOptions.NoInlining)]
    public static string Describe(T value)
    {
        Calls++;
        return typeof(T).Name;
    }
}
```

```text
== How the JIT shares generic code: one Describe per value type, one for all reference types
Shared<Int32>.Describe: Calls 1
Shared<Int64>.Describe: Calls 1
Shared<PitchClass>.Describe: Calls 1
Shared<String>.Describe: Calls 1
Shared<Object>.Describe: Calls 1
Shared<List`1>.Describe: Calls 1
ReadStatic<int>(10) 10, ReadStatic<string>(10) 10
JIT summary:
Lesson5+Shared`1[GA.Domain.Core.Theory.Atonal.PitchClass]:Describe(GA.Domain.Core.Theory.Atonal.PitchClass)
Lesson5+Shared`1[System.__Canon]:Describe(System.__Canon)
Lesson5+Shared`1[int]:Describe(int)
Lesson5+Shared`1[long]:Describe(long)
```

Six instanciations, quatre compilations : `int`, `long` et `PitchClass` ont chacun la leur, et `string`, `object` et `List<int>` partagent celle de `__Canon`. Le programme compte aussi les méthodes que le JIT a compilées sur son thread pendant chaque premier appel, avec [`JitInfo.GetCompiledMethodCount`](https://learn.microsoft.com/dotnet/api/system.runtime.jitinfo). Ce nombre dépend du runtime, donc il est affiché sur des lignes dépendantes de la machine ; sur la machine de l'auteur, il concorde :

```text
# Shared<String>.Describe: 1 methods compiled on this thread by the first call
# Shared<Object>.Describe: 0 methods compiled on this thread by the first call
# Shared<List`1>.Describe: 0 methods compiled on this thread by the first call
```

Pourtant, chaque instanciation a toujours son propre champ `Calls`, et `typeof(T)` renvoie toujours `String` ou `Object`. Le code partagé les trouve grâce à un argument caché, le *contexte générique*, qui pointe vers le *dictionnaire générique* de l'instanciation : une table des handles de type, des statiques et des méthodes qui dépendent de `T`. Cette recherche est le coût du partage. Voici `ReadStatic<T>`, qui additionne un champ statique de `Counter<T>` dans une boucle. Le mode `l5-tiers` du programme l'appelle 5 000 fois pour `int` et pour `string`, et `DOTNET_JitDisasm=ReadStatic` affiche son code machine à chaque niveau ; voici les versions finales, de niveau 1, sur x64, réduites à la boucle :

```csharp
public static int ReadStatic<T>(int times)
{
    var sum = 0;
    for (var i = 0; i < times; i++) sum += Counter<T>.Value;
    return sum;
}
```

```text
; Assembly listing for method Advanced.Lesson5:ReadStatic[int](int):int (Tier1)
G_M000_IG03:
       mov      edx, dword ptr [(reloc 0x7ffdbe39b0e0)]
G_M000_IG04:
       add      eax, edx
       dec      ecx
       jne      SHORT G_M000_IG04

; Assembly listing for method Advanced.Lesson5:ReadStatic[System.__Canon](int):int (Tier1)
G_M000_IG03:
       mov      rdx, qword ptr [rcx+0x18]
       mov      rdi, qword ptr [rdx+0x10]
       test     rdi, rdi
       je       SHORT G_M000_IG07
G_M000_IG04:
       mov      rcx, rdi
       call     CORINFO_HELP_GET_NONGCSTATIC_BASE
       add      esi, dword ptr [rax]
       dec      ebx
       jne      SHORT G_M000_IG04
```

Pour `int`, le JIT connaît l'adresse de `Counter<int>.Value`, et lit même le champ une seule fois, avant la boucle : la boucle tient en trois instructions. Pour `__Canon`, il lit le handle de classe dans le dictionnaire, à travers le contexte générique passé dans `rcx`, puis appelle une fonction d'assistance du runtime pour trouver l'adresse du champ statique *à chaque itération*. Avec la compilation hiérarchisée désactivée, la boucle de `__Canon` est la même. `SharedGenericBenchmarks` mesure 1 000 lectures :

| Method                     | Mean     | Error   | StdDev  | Ratio | RatioSD |
|--------------------------- |---------:|--------:|--------:|------:|--------:|
| ValueTypeInstantiation     | 199.8 ns | 2.61 ns | 2.44 ns |  1.00 |    0.02 |
| ReferenceTypeInstantiation | 292.2 ns | 5.79 ns | 5.42 ns |  1.46 |    0.03 |

Le code partagé est 1,46 fois plus lent, soit environ 0,09 ns de plus par lecture. C'est moins que ce que j'attendais pour un appel par itération ; je n'ai pas mesuré pourquoi il coûte si peu, *à vérifier*. C'est le pire des cas, une boucle autour d'une recherche et rien d'autre ; la plupart du code générique partagé fait un vrai travail entre deux recherches. Ce qu'il faut retenir, c'est le sens de l'écart : sur des types valeur, le code générique est compilé comme si vous l'aviez écrit à la main ; sur des types référence, il est partagé et paie pour ce qui dépend de `T`.

## Un champ statique par type fermé : les caches génériques

Comme chaque type fermé a ses propres champs statiques, une classe générique statique est un dictionnaire indexé par `T` que le runtime entretient pour vous, sans recherche et sans verrou après l'initialisation. Le `TypeCache<T>` du programme a un constructeur statique explicite, pour que le runtime l'initialise exactement à sa première utilisation plutôt qu'au moment de son choix ([constructeurs statiques](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors)) ([`Lesson5.cs#L263-L287`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L263-L287)) :

```text
== A static field per closed type: a cache the runtime keys by T
  TypeCache<String> initialized
  TypeCache<Object> initialized
  TypeCache<Int32> initialized
Id: string 1, object 2, int 3; initializations 3
Hits: string 3, object 1, int 1
EqualityComparer<T>.Default: int GenericEqualityComparer`1, string StringEqualityComparer, PitchClass GenericEqualityComparer`1
                             int? NullableEqualityComparer`1, object ObjectEqualityComparer`1, DayOfWeek EnumEqualityComparer`1
the same instance each time: True
```

`TypeCache<string>` et `TypeCache<object>` partagent leur code mais pas leurs statiques. La bibliothèque de base utilise ce motif partout : [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default) choisit une fois pour toutes le meilleur comparateur pour `T`, un comparateur qui appelle directement `IEquatable<T>.Equals` pour `PitchClass`, un autre qui déballe `Nullable<T>`, un autre pour les énumérations, et le met en cache dans un champ statique d'`EqualityComparer<T>`.

Le [`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) de GA repose sur la même idée, indexé par type d'objet valeur, et il appelle les membres abstraits statiques pour se remplir :

```csharp
internal static class ValueObjectCache<T>
    where T : IRangeValueObject<T>
{
    internal static readonly int Min = T.Min.Value;
    internal static readonly int Max = T.Max.Value;
    private static readonly int _count = Max - Min + 1;
    internal static readonly T[] AllItems = CreateItems();
    internal static FrozenSet<T> ItemsSet { get; } = FrozenSet.Create<T>(AllItems);
    internal static readonly ImmutableArray<int> AllValues = CreateValues();
    internal static FrozenSet<int> ValuesSet { get; } = [..AllValues];
    internal static ReadOnlySpan<T> ItemsSpan => AllItems;
}
```

Tous les champs statiques d'une classe sont initialisés ensemble, dans l'ordre où ils sont écrits. Une première lecture d'`ItemsSpan` pour les 26 cordes de GA construit donc aussi deux `FrozenSet`, que quelqu'un s'en serve ou non. Le programme mesure ce premier accès sur une ligne dépendante de la machine :

```text
# first access to ValueObjectUtils<Str>.ItemsSpan (26 items) allocated 4592 bytes
```

Un tableau de 26 `Str` occupe 128 octets ; l'essentiel des 4 592 octets, ce sont les deux ensembles figés et le tableau immuable. C'est payé une fois par type, et c'est peu, mais il vaut la peine de savoir qu'un cache générique initialise d'un coup tout ce qu'il déclare. Dans les trois projets de GA que récupère le cours, rien d'autre que `ValueObjectUtils<TSelf>` ne lit ces deux ensembles, et `ValueObjectUtils` ne fait que les exposer.

## Étude de cas : l'`IStaticValueObjectList<TSelf>` de GA

L'interface est courte :

```csharp
public interface IStaticValueObjectList<TSelf> : IStaticReadonlyCollectionFromValues<TSelf>
    where TSelf : struct, IRangeValueObject<TSelf>
{
    public static abstract IReadOnlyList<int> Values { get; }
}
```

Elle hérite de `static abstract IReadOnlyCollection<TSelf> Items` depuis [`IStaticReadonlyCollection<out TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticReadonlyCollection.cs#L6-L13), et chaque type qui l'implémente délègue à `ValueObjectUtils<TSelf>`, comme le fait [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156) :

```csharp
public static IReadOnlyCollection<PitchClass> Items => ValueObjectUtils<PitchClass>.Items;
public static IReadOnlyList<int> Values => ValueObjectUtils<PitchClass>.Values;
public static ReadOnlySpan<PitchClass> ItemsSpan => ValueObjectUtils<PitchClass>.ItemsSpan;
```

Le cache est calculé une fois, mais que coûte chaque *accès* ? Le programme mesure les octets alloués par une lecture, après qu'une première lecture a exécuté le JIT et les constructeurs statiques ([`Lesson5.cs#L352-L406`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L352-L406)) :

```text
== GA: what IStaticValueObjectList<TSelf> costs per access
PitchClass.Items:                        32 bytes, the same object twice: False
foreach over PitchClass.Items:           72 bytes
PitchClass.Values[3]:                    24 bytes, Values is ImmutableArray`1
ValueObjectUtils<PitchClass>.Values[3]:  0 bytes
PitchClass.ItemsSpan[3]:                 0 bytes
SumAll<PitchClass>() over ItemsSpan:     66, 0 bytes
```

- **`Items` alloue une enveloppe à chaque lecture.** [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) appelle `ValueObjectCollection<TSelf>.Create()`, qui renvoie une nouvelle collection de 32 octets, créée par `new` au-dessus du tableau en cache. Sa documentation dit « automatically memoized » ; le tableau l'est, la collection ne l'est pas.
- **Un `foreach` sur cette propriété alloue 72 octets** : l'enveloppe, et son énumérateur struct boxé en `IEnumerator<PitchClass>`, 40 octets, parce que `Items` est typé comme l'interface.
- **`Values` boxe un `ImmutableArray<int>` à chaque lecture.** `ValueObjectUtils<TSelf>.Values` renvoie un [`ImmutableArray<int>`](https://learn.microsoft.com/dotnet/api/system.collections.immutable.immutablearray-1), qui est une struct ; `IStaticValueObjectList<TSelf>.Values` est déclaré `IReadOnlyList<int>`, donc la propriété de chaque type qui l'implémente convertit la struct vers l'interface : une boîte de 24 octets, et un appel d'interface pour chaque index. Lu directement, le même `ImmutableArray` ne coûte rien.
- **`ItemsSpan`, que l'interface ne mentionne que dans un commentaire, est gratuit**, tout comme une méthode générique qui lit `ValueObjectUtils<T>.ItemsSpan` : `SumAll<T>` fonctionne pour tous les objets valeurs de GA sans aucun appel d'interface.

`ValueObjectListBenchmarks` met des durées sur ces octets :

| Method               | Mean      | Error     | StdDev    | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------- |----------:|----------:|----------:|------:|--------:|-------:|----------:|------------:|
| ItemsForeach         | 14.473 ns | 0.2975 ns | 0.2783 ns |  1.00 |    0.03 | 0.0021 |      40 B |        1.00 |
| ItemsSpanForeach     |  3.871 ns | 0.0757 ns | 0.0708 ns |  0.27 |    0.01 |      - |         - |        0.00 |
| GenericSumAll        |  3.720 ns | 0.0655 ns | 0.0613 ns |  0.26 |    0.01 |      - |         - |        0.00 |
| ValuesIndexer        | 41.796 ns | 0.8563 ns | 1.8796 ns |  2.89 |    0.14 | 0.0153 |     288 B |        7.20 |
| ImmutableArrayValues |  3.134 ns | 0.0705 ns | 0.0659 ns |  0.22 |    0.01 |      - |         - |        0.00 |

Additionner les douze classes de hauteurs à travers `Items` prend 14,5 ns ; à travers `ItemsSpan`, ou la méthode générique `SumAll<PitchClass>`, 3,8 ns. Lire les douze valeurs à travers `PitchClass.Values` prend 41,8 ns et alloue 288 octets, douze boîtes de 24 octets ; à travers l'`ImmutableArray` lui-même, 3,1 ns et rien du tout : 13 fois plus rapide. Le benchmark montre aussi le JIT à l'œuvre une fois de plus : optimisé avec le PGO dynamique, le `foreach` sur `Items` alloue 40 octets au lieu des 72 que les premiers appels du programme avaient mesurés. 40 octets, c'est la taille de l'énumérateur boxé, donc l'enveloppe est probablement l'objet que le JIT n'alloue plus ; je n'ai pas vérifié lequel des deux c'est, *à vérifier*.

Le motif est courant et facile à manquer : une propriété abstraite statique typée comme une interface transforme une struct ou un tableau en cache en une allocation par appel, alors même que la mécanique générique qui l'entoure ne coûte rien.

Le programme a trouvé deux autres choses dans ces interfaces. D'abord, le `out` de `IStaticReadonlyCollection<out TSelf>` est de la covariance, que la section suivante explique ; le programme a cherché les types qui l'implémentent dans les deux assemblies de GA qu'il charge :

```text
== GA: who implements IStaticReadonlyCollection<TSelf>
13 structs, 4 classes: ModalFamily, PitchClassSet, Scale, SetClass
```

Ensuite, GA a deux vérifications d'intervalle qui ramènent une valeur dans son intervalle, et elles ne sont pas d'accord. [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63), une méthode statique avec un corps sur l'interface générique, prend le reste modulo `max - min`, un de moins que le nombre de valeurs, puis ajoute 1 ; [`ValueObjectUtils<TSelf>.EnsureValueRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L42-L47) utilise `max - min + 1` :

```text
== GA: the two range checks with normalize: true
 -1: IRangeValueObject<PitchClass>.EnsureValueInRange 11, ValueObjectUtils<PitchClass>.EnsureValueRange 11
 12: IRangeValueObject<PitchClass>.EnsureValueInRange  2, ValueObjectUtils<PitchClass>.EnsureValueRange  0
 13: IRangeValueObject<PitchClass>.EnsureValueInRange  3, ValueObjectUtils<PitchClass>.EnsureValueRange  1
```

La classe de hauteurs 12 vaut 0 ; la version de l'interface dit 2. `PitchClass` utilise la bonne, et les objets valeurs qui appellent la version de l'interface, comme `Fret` et `Finger`, ne passent pas `normalize: true`, donc le bug est latent : aucun code de GA dans les projets récupérés ne l'atteint.

## La variance : `in`, `out`, et pourquoi `List<T>` n'a ni l'un ni l'autre

Une `string` est un `object` ; une séquence de chaînes est-elle une séquence d'objets ? En lecture, oui : tout ce qui sort d'un `IEnumerable<string>` est un objet. En écriture, non : une `List<object>` accepte un `PitchClass`, ce qu'une `List<string>` ne doit pas accepter. C# permet à une interface ou à un délégué de dire lequel des deux cas s'applique à chaque paramètre de type ([Covariance et contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)) : `out T` si `T` ne fait que sortir, ce qui rend l'interface *covariante*, `in T` si `T` ne fait qu'entrer, ce qui la rend *contravariante* ([`Lesson5.cs#L209-L242`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L209-L242)) :

```text
== Variance: in, out, and why List<T> has neither
IEnumerable<string> as IEnumerable<object>: True
List<string> is IEnumerable<object>: True; is IList<object>: False
List<int> is IEnumerable<object>: False
Action<object> as Action<string>: True
object[] array = new string[1]; array[0] = PitchClass.C: ArrayTypeMismatchException
  IEnumerable`1                  Covariant
  IReadOnlyList`1                Covariant
  IList`1                        None
  Action`1                       Contravariant
  Func`2                         Contravariant, Covariant
  IComparer`1                    Contravariant
  IStaticReadonlyCollection`1    Covariant
GA ModalFamily (class) is IStaticReadonlyCollection<object>: True
GA PitchClass (struct) is IStaticReadonlyCollection<object>: False
```

- La conversion est une conversion de référence : l'`IEnumerable<object>` est le *même objet* que l'`IEnumerable<string>`, sans copie.
- `IList<T>` à la fois renvoie et accepte `T`, donc elle ne peut pas être variante, et les classes ne peuvent jamais l'être : `List<T>` est invariante, et le compilateur refuse purement et simplement l'affectation.
- **La variance ne fonctionne qu'avec les types référence.** Une `List<int>` n'est pas un `IEnumerable<object>` : chaque `int` aurait besoin d'une boîte, et une conversion de référence ne peut pas créer de boîtes. La même règle rend le `out` de GA sur `IStaticReadonlyCollection<out TSelf>` inutile pour ses 13 implémentations qui sont des structs, et inoffensif pour les 4 classes, puisqu'une interface qui n'a que des membres statiques n'a rien à appeler à travers une référence convertie.
- Les tableaux sont covariants eux aussi, depuis .NET 1.0, mais y écrire n'est pas sûr, donc chaque écriture d'une référence dans un tableau est vérifiée à l'exécution, et échoue avec [`ArrayTypeMismatchException`](https://learn.microsoft.com/dotnet/api/system.arraytypemismatchexception).

Le compilateur vérifie la variance des deux côtés. Voici l'affectation d'une classe invariante :

```csharp
// expect: CS0029
public static class Names
{
    public static List<object> All = new List<string> { "C", "G" };
}
```

```text
l5_invariant_list.cs(4,38): error CS0029: Cannot implicitly convert type 'System.Collections.Generic.List<string>' to 'System.Collections.Generic.List<object>'
```

Et un paramètre covariant utilisé en entrée :

```csharp
// expect: CS1961
public interface IProducer<out T>
{
    T Next();

    void Accept(T item);
}
```

```text
l5_unsafe_variance.cs(6,17): error CS1961: Invalid variance: The type parameter 'T' must be contravariantly valid on 'IProducer<T>.Accept(T)'. 'T' is covariant.
```

## `allows ref struct`

La leçon 1 a montré que `List<Span<int>>` ne se compile pas : une `ref struct` ne peut pas être un argument de type, sauf si le paramètre de type déclare `allows ref struct`, ajouté en C# 13 ([l'anti-contrainte ref struct](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters#allows-ref-struct)). .NET 9 l'a ajouté là où c'était sûr, donc le programme demande au runtime quels paramètres de type portent l'indicateur ([`Lesson5.cs#L246-L257`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L246-L257)) :

```text
== allows ref struct: which generic parameters accept a Span<T>
  Func`2               yes, yes
  Action`1             yes
  IEquatable`1         yes
  IComparable`1        yes
  IEnumerable`1        yes
  IEqualityComparer`1  yes
  List`1               no
  Dictionary`2         no, no
  Span`1               no
  Nullable`1           no
Apply("x 3 2 0 1 0".AsSpan(), span => span.Count(' ')): 5
```

Les délégués et les petites interfaces l'autorisent ; les collections, qui stockent leurs éléments dans des tableaux sur le tas, ne l'autorisent pas. Une méthode générique peut aussi l'adopter :

```csharp
static TResult Apply<T, TResult>(T value, Func<T, TResult> func) where T : allows ref struct => func(value);
```

L'appel du programme lui passe un `ReadOnlySpan<char>` sur une chaîne de voicing, ce qui se compile parce que le `T` d'`Apply` et le `T` de `Func` l'autorisent tous les deux. En contrepartie, le corps de la méthode doit traiter `T` comme une possible `ref struct` : pas de boxing, pas de champ dans une classe, pas de capture dans une lambda.

```csharp
// expect: CS0029
public static class Boxes
{
    public static object Box<T>(T value) where T : allows ref struct => value;
}
```

```text
l5_ref_struct_boxing.cs(4,73): error CS0029: Cannot implicitly convert type 'T' to 'object'
```

## Si vous connaissez Spring et Reactor

Les génériques de Java ressemblent à ceux de C# sur la page, et sont leur contraire en dessous : le compilateur les vérifie, puis les [efface](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html). Le [cours Java pour les développeurs C#](../../java-for-csharp/04-generics-and-erasure/) montre les conséquences du côté Java, avec les messages d'erreur de javac ; voici la même liste du côté C#, ligne par ligne avec cette leçon.

| C# (.NET 10) | Java, Spring et Reactor |
|---|---|
| `typeof(List<int>) != typeof(List<string>)` ; `typeof(T)` fonctionne dans une méthode générique | une seule classe `ArrayList` pour tous les `List<…>` ([JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html)) ; une méthode qui a besoin du type prend un `Class<T>`, et Spring retrouve les arguments de type déclarés à partir des signatures avec [`ResolvableType`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ResolvableType.html), ou à partir d'une sous-classe anonyme avec [`ParameterizedTypeReference`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ParameterizedTypeReference.html) |
| `List<PitchClass>` : les valeurs en place, dans un seul tableau | `List<Integer>` uniquement : [les arguments de type doivent être des types référence](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html), chaque élément est un objet boxé ; [`IntStream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/IntStream.html) et ses cousins existent pour l'éviter, le [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) de Reactor n'a pas de telle variante, et la [JEP 218](https://openjdk.org/jeps/218), des génériques sur les types primitifs, n'est encore qu'une *candidate* |
| `where T : struct`, `unmanaged`, `new()`, `notnull`, `allows ref struct` | seulement des bornes : `T extends Comparable<T>`, avec `&` pour en combiner plusieurs ; pas de contrainte de constructeur (passez un `Supplier<T>`), rien sur les types valeur, puisqu'il n'y en a pas encore (les classes valeur de la [JEP 401](https://openjdk.org/jeps/401) sont une préversion visée pour le JDK 28) |
| `default(T)` : tous les bits à zéro, `0` pour `int`, `null` pour `string` | toujours `null`, puisque tout `T` est une référence |
| membres abstraits statiques : `T.FromValue(3)`, `T.Zero`, `left + right` sur `T : INumber<T>` | pas de membres statiques à travers une variable de type ; la réponse habituelle est une fabrique ou un objet stratégie passé en argument, comme l'est `Comparator<T>` |
| variance à la déclaration : `IEnumerable<out T>`, `Action<in T>`, vérifiée par le compilateur (CS1961) | variance à l'utilisation avec des jokers : `List<? extends Number>` pour lire, `List<? super Integer>` pour écrire, les variables « in » et « out » des [recommandations sur les jokers](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) |
| les tableaux sont covariants et vérifiés à l'exécution : `ArrayTypeMismatchException` | la même conception et le même échec, [`ArrayStoreException`](https://docs.oracle.com/javase/specs/jls/se25/html/jls-10.html) |
| un champ statique par type fermé : `TypeCache<string>` et `TypeCache<object>` sont deux caches | un seul champ statique pour toute la classe, quel que soit l'argument de type ; un cache par type est un [`ClassValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassValue.html) ou une `Map<Class<?>, …>` |
| les instanciations sur des types valeur ont leur propre code machine ; les types référence partagent le code `__Canon` | chaque instanciation exécute le même bytecode, comme le code partagé de .NET pour les types référence, et c'est le JIT qui spécialise, d'après le profil |

La dernière ligne est le point où les deux plateformes se rapprochent le plus. HotSpot ne voit jamais `List<String>`, seulement `List`, et compte sur son profil pour inliner et dévirtualiser, un peu comme le PGO dynamique de .NET a dévirtualisé un appel d'interface à la leçon 4. Ce que .NET ajoute, c'est le chemin des types valeur : le code de `Sum<int>` est compilé pour `int`, ce que Java n'obtient aujourd'hui qu'avec une classe écrite pour `int`, comme `IntStream`.

## Exercices

1. GA normalise les valeurs avec un modulo qui ne renvoie jamais de nombre négatif. Écrivez `Wrap<T>(T value, T size)` une seule fois pour tous les types numériques, et vérifiez-la sur `-1` modulo `12`, `-13L` modulo `12L`, `-0.5` modulo `12.0` et `25` modulo `12`.
2. Le `PitchClass` de GA implémente [`IParsable<TSelf>`](https://learn.microsoft.com/dotnet/api/system.iparsable-1), une interface à membres abstraits statiques de la bibliothèque de base. Écrivez `ParseAll<T>(string text)`, qui découpe une liste séparée par des espaces et analyse chaque partie avec `T.Parse`, et utilisez-la pour `"0 4 7 T"` en tant que classes de hauteurs et `"0 4 7 10"` en tant qu'entiers.
3. Lesquels de ces champs se compilent, et pourquoi ?

    ```csharp
    public static class Quiz
    {
        public static IReadOnlyList<object> A = new List<string>();
        public static IList<object> B = new List<string>();
        public static IEnumerable<object> C = new List<int>();
        public static Func<string, object> D = (Func<object, string>)(o => o.ToString()!);
        public static Action<object> E = (Action<string>)(s => { });
    }
    ```

<details>
<summary>Solutions</summary>

1. `INumber<T>` fournit `%`, `+`, la comparaison et `T.Zero` ([`Lesson5.cs#L411-L415`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L411-L415)) :

    ```csharp
    public static T Wrap<T>(T value, T size) where T : INumber<T>
    {
        var remainder = value % size;
        return remainder < T.Zero ? remainder + size : remainder;
    }
    ```

    ```text
    1. Wrap(-1, 12) 11, Wrap(-13L, 12L) 11, Wrap(-0.5, 12.0) 11.5, Wrap(25, 12) 1
    ```

    En C#, `%` garde le signe du dividende, donc `-1 % 12` vaut `-1`, et ajouter la taille une fois ramène la valeur dans l'intervalle. Le même code fonctionne pour `double`, où `%` est défini aussi.

2. `IParsable<T>` déclare `static abstract T Parse(string s, IFormatProvider? provider)`, donc la méthode générique l'appelle sur `T` ([`Lesson5.cs#L418-L419`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L418-L419)) :

    ```csharp
    public static List<T> ParseAll<T>(string text) where T : IParsable<T> =>
        [.. text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(s => T.Parse(s, null))];
    ```

    ```text
    2. ParseAll<PitchClass>("0 4 7 T") [0 4 7 T], ParseAll<int>("0 4 7 10") sum 21
    ```

3. `A` et `D` se compilent ; `B`, `C` et `E` non. `IReadOnlyList<out T>` est covariante, donc une liste de chaînes est une liste d'objets en lecture seule. `IList<T>` est invariante (`B`). `List<int>` contient des valeurs, et la variance ne convertit que des références (`C`). `Func<in T, out TResult>` accepte une fonction d'`object` vers `string` là où l'on attend une fonction de `string` vers `object` : elle accepte plus et renvoie moins (`D`). `Action<in T>` va dans l'autre sens : une action sur des chaînes ne peut pas accepter n'importe quel objet (`E`). Le compilateur l'a vérifié ([`l5_exercise_variance.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets/l5_exercise_variance.cs)) :

    ```text
    l5_exercise_variance.cs(5,37): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<string>' to 'System.Collections.Generic.IList<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(6,43): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<int>' to 'System.Collections.Generic.IEnumerable<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(8,38): error CS0266: Cannot implicitly convert type 'System.Action<string>' to 'System.Action<object>'. An explicit conversion exists (are you missing a cast?)
    ```

    Le message dit « An explicit conversion exists » parce qu'une `List<string>` pourrait, en théorie, être convertie vers une interface par un cast à l'exécution ; ce cast lèverait une `InvalidCastException`.

</details>

## À retenir

- Les génériques de .NET sont réifiés : `List<PitchClass>` stocke ses valeurs en place, 104 octets pour douze, là où une liste d'objets en prend 440.
- Les contraintes sont des métadonnées. Le runtime vérifie `class`, `struct` et `new()` ; `unmanaged` et `notnull` ne sont vérifiées que par le compilateur, et `allows ref struct` élargit au lieu de restreindre.
- `default(T)` et `new T()` produisent des structs mises à zéro sans exécuter leur validation. Sur un `T` sans contrainte, `T?` n'est pas `Nullable<T>`.
- Les membres abstraits statiques décrivent un type, pas un objet : `T.FromValue`, `T.Zero`, `left + right`. Une interface qui en a ne peut pas servir d'argument de type.
- Les mathématiques génériques conservent la sémantique de chaque type, y compris les opérateurs checked, et `Sum<int>` s'est exécutée aussi vite qu'une boucle écrite pour `int`.
- Le JIT compile le code générique une fois par type valeur et une fois pour tous les types référence, sur `__Canon`. Le code partagé trouve ce qui dépend de `T` grâce à un dictionnaire générique, et a payé un appel de fonction d'assistance par itération pour lire un champ statique : 1,46 fois plus lent dans cette boucle.
- Une classe générique statique est un cache par type, initialisé d'un seul coup. Le cache de GA est sain, mais ses interfaces allouent à chaque accès : 32 octets pour `Items`, 24 pour `Values`, rien pour `ItemsSpan`.
- La variance est réservée aux interfaces et aux délégués sur des types référence : `out` pour lire, `in` pour écrire, jamais les deux.

## Sources

- Microsoft Learn : [Contraintes sur les paramètres de type](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Génériques dans le runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time), [Opérateur `default`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default), [Membres d'interface virtuels statiques](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), [Mathématiques génériques](https://learn.microsoft.com/dotnet/standard/generics/math), [Covariance et contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes), [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default), [Constructeurs statiques](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors).
- dotnet/runtime à `v10.0.12` (commit `4271d88`) : [Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md), [Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md).
- Java : [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html) et [Wildcard guidelines](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) dans les tutoriels Java, [JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [JEP 218](https://openjdk.org/jeps/218), [JEP 401](https://openjdk.org/jeps/401).
- Guitar Alchemist à `a826864` : [`IStaticValueObjectList.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), [`IValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47), [`IRangeValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L81), [`ValueObjectCache.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52), [`ValueObjectUtils.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L6-L64), [`PitchClass.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156).
