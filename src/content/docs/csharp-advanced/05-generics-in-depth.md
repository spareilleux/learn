---
title: "Lesson 5: Generics in depth"
description: Reified generics measured in bytes, what each constraint puts in the metadata and which ones only the compiler checks, default(T) and T?, static abstract members and generic math, variance, allows ref struct, per-type static caches, and the machine code the JIT shares between reference types, on Guitar Alchemist's IStaticValueObjectList<TSelf>, with Java's erasure for comparison.
sidebar:
  label: 5. Generics in depth
  order: 5
---

You use generics every day, and lesson 1 already showed one thing they do under the hood: a call through a constraint is emitted with the `constrained.` prefix, and doesn't box. This lesson goes further. It looks at what a generic type is at run time, what each constraint writes into the metadata, what `default(T)` and `T?` really mean, how static abstract members let an interface describe a type rather than an object, and when the JIT gives two instantiations the same machine code. Each point is printed by a program, compiled, disassembled or measured.

The running example is a family of interfaces from Guitar Alchemist. `PitchClass`, `Fret`, `IntervalClass` and a dozen other small structs implement [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), which uses nearly every feature of this lesson at once: a type parameter that refers to the implementing type, a `struct` constraint, static abstract members, and a static generic class used as a cache.

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6); runtime links point to commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) of `dotnet/runtime`, tagged `v10.0.12`.

## Running the lesson's program

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, compared with expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l5  # this lesson only, after check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*GenericMathBenchmarks*"   # one benchmark class
```

The program is [`Advanced/Lesson5.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs); the four methods whose IL the lesson shows are in [`Snippets/Generics.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs); the rejected snippets are the `l5_*.cs` files of [`CompileFail/snippets`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets). `check.sh` compares all of it with [`expected/`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/expected) on three OSes. The timings come from [`Benchmarks/GenericBenchmarks.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Benchmarks/GenericBenchmarks.cs), run on the author's machine, the one described in [lesson 4](../04-measured-performance/).

## Reified generics: a type per instantiation

In .NET, a generic type is *reified*: `List<int>` and `List<string>` are two distinct types at run time, each with its own `Type` object, and a generic method can ask for `typeof(T)` or create a `new T[n]`. The runtime builds each closed type from the open definition `List<T>` the first time it's needed ([Generics in the runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time)). For a value type, that means the elements are stored inline, without boxes ([`Lesson5.cs#L33-L62`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L33-L62)):

```text
== Reified generics: every instantiation is a type of its own
typeof(List<int>) == typeof(List<string>): False
typeof(List<PitchClass>): System.Collections.Generic.List`1[GA.Domain.Core.Theory.Atonal.PitchClass]
new List<PitchClass>() is List<int>: False
NameOf<PitchClass>(): PitchClass; new T[3] is GA.Domain.Core.Theory.Atonal.PitchClass[]
12 pitch classes in a List<PitchClass>: 104 bytes
12 pitch classes in a List<object>:     440 bytes
```

The 104 bytes are the `List` object, 32 bytes, and an array of 12 four-byte `PitchClass` values, 24 + 48. The `List<object>` has the same 32 bytes, an array of 12 references, 24 + 96, and twelve boxes of 24 bytes each: 440 bytes, more than four times as much, and thirteen objects for the garbage collector instead of two. That second list is what every generic collection of numbers looks like in Java, as the last section shows.

## Constraints: what the compiler checks, and what the runtime checks

A constraint does two jobs: it restricts the type arguments a caller may pass, and it lets the generic code use what the constraint promises, a constructor, an operator, a method. The C# reference lists them all ([Constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)). Without a constraint, `T` offers only what `object` has, and the compiler says so:

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

The second error was the classic limit of C# generics until C# 11; generic math, below, removes it. First, what do constraints become once compiled? The program declares one empty method per constraint and reads its type parameter back with reflection, through [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes) ([`Lesson5.cs#L66-L92`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L66-L92)):

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

- `struct` is written as two flags, "not a nullable value type" and "has a default constructor", plus the base type `ValueType`: a struct always has a parameterless constructor as far as the runtime is concerned.
- `unmanaged` is written exactly like `struct`, plus an `IsUnmanagedAttribute` that only the compiler reads.
- `notnull` leaves nothing the runtime reads: it is a nullable annotation, checked by the compiler as a warning.
- `allows ref struct`, new in C# 13, is a flag of its own, and it's an *anti-constraint*: it widens what the caller may pass instead of restricting it.

So the runtime can check some constraints and not others. [`MethodInfo.MakeGenericMethod`](https://learn.microsoft.com/dotnet/api/system.reflection.methodinfo.makegenericmethod) instantiates a method at run time, without the compiler:

```text
== Constraints the compiler checks and the runtime doesn't
MakeGenericMethod((int, string)) on 'where T : unmanaged': accepted
MakeGenericMethod(string) on 'where T : unmanaged':        ArgumentException
MakeGenericMethod(int?) on 'where T : struct':            ArgumentException
sizeof(T) with T : unmanaged: PitchClass 4, (byte, long) 16
IsReferenceOrContainsReferences: PitchClass False, (int, string) True
new T() with T : new(): StringBuilder, Str 0
```

The runtime accepts `(int, string)` for `unmanaged`, because what it checks is "a non-nullable value type", and a tuple containing a `string` is one. The compiler rejects the same thing, because `unmanaged` also means "no references at any depth", which is what makes `sizeof(T)` and pointers to `T` safe:

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

When code must decide at run time whether a `T` holds references, for example to know whether a buffer must be cleared for the garbage collector, [`RuntimeHelpers.IsReferenceOrContainsReferences<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.runtimehelpers.isreferenceorcontainsreferences) answers, and the JIT turns it into a constant for each value type. The `struct` constraint, on the other hand, excludes `Nullable<T>` both in the compiler and in the runtime:

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

And `notnull`, which exists only in the compiler, gives only a warning; `Dictionary<TKey, TValue>` declares its key `notnull`:

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

Finally, what does the compiler emit for `new T()`? Not a constructor call: it can't know which constructor. The IL of [`Generics.Create`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L11) calls [`Activator.CreateInstance<T>()`](https://learn.microsoft.com/dotnet/api/system.activator.createinstance), and for a struct that returns the zero value without running any validation. GA's `Str`, a guitar string numbered 1 to 26, comes out as string 0 in the last line above:

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

## `default(T)`, and what `T?` means

[`default(T)`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default) is all bits zero: `null` for a reference type, `0` for a number, and for a struct, every field zeroed. The IL is `initobj !!T`, whatever `T` is. The surprise is `T?`. On an unconstrained `T`, `T?` only says "may be the default"; it doesn't turn `int` into `int?`. With `where T : struct`, `T?` is `Nullable<T>` ([`Lesson5.cs#L113-L141`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L113-L141)):

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

`FirstOrDefault<int>` can't tell "not found" from "found 0": its return type is plain `Int32`. That's how LINQ's `FirstOrDefault` behaves too. The GA lines show the same trap on domain types. `default(PitchClass)` is 0, a perfectly valid C, so a missing pitch class looks like a C. `default(Str)` is string 0, which [`Str`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L16-L17) refuses to create: its `init` accessor checks the range, but `default`, `new Str[6]` and `new T()` never run it. A struct with an invariant can't enforce it against zeroed memory; GA's value objects with a minimum of 1, `Str` and the scale degrees, can all appear as 0 this way.

## Static abstract members

An interface method describes what an *object* can do. A [static abstract member](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), since C# 11, describes what a *type* can do: create itself from an `int`, give its minimum, add two of its values. Generic code calls it on the type parameter, `T.FromValue(3)`. GA's [`IValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47) and [`IRangeValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L23) are built that way:

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

The constraint `where TSelf : IRangeValueObject<TSelf>` is the *self-referencing* pattern: `PitchClass` implements `IRangeValueObject<PitchClass>`, so inside the interface, `TSelf` means "the implementing type", and `FromValue` can return a `PitchClass` rather than an interface. With that, one generic method works for every GA value object ([`Lesson5.cs#L160-L177`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L160-L177)):

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

In the IL, a call to a static abstract member is a `call` with the same `constrained.` prefix as in lesson 1, on the interface's method. It has no object to dispatch on: the runtime resolves it from the type argument, and in code compiled for a value type, the JIT resolves it once and can inline it ([`Generics.FromValue`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L15)):

```text
IL_0000: ldarg.0
IL_0001: constrained. !!T
IL_0007: call !0 class Snippets.IFromValue`1<!!T>::FromValue(int32)
IL_000c: ret
```

The price of static abstract members is that the interface is no longer a type you can hold a value of in generic code. Its static members have no implementation to call, so it can't be a type argument:

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

## Generic math

.NET 7 used static abstract members to give every number type a set of interfaces: [`INumber<T>`](https://learn.microsoft.com/dotnet/api/system.numerics.inumber-1) and its parts, `IAdditionOperators<TSelf, TOther, TResult>`, `INumberBase<T>` with `Zero` and `One`, and the rest ([Generic math](https://learn.microsoft.com/dotnet/standard/generics/math)). An operator is a static method, so `left + right` on `T : IAdditionOperators<T, T, T>` compiles to a constrained call to `op_Addition`, which is the IL of `Generics.Add`:

```text
IL_0000: ldarg.0
IL_0001: ldarg.1
IL_0002: constrained. !!T
IL_0008: call !2 class [System.Runtime]System.Numerics.IAdditionOperators`3<!!T, !!T, !!T>::op_Addition(!0, !1)
IL_000d: ret
```

One `Sum` and one `Mean` then serve every number type ([`Lesson5.cs#L181-L205`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L181-L205)):

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

Generic code keeps each type's semantics. The integer mean of 1, 2, 3 and 4 is 2, the `double` mean is 2.5; `decimal` adds 0.1 and 0.2 exactly, `double` doesn't. A [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) expression in generic code calls the type's *checked* operator, `op_CheckedAddition`, a C# 11 addition too: `byte` and `int` throw, and `double`, which has no overflow, gives infinity. Converting between number types has three explicit flavours: [`CreateChecked`](https://learn.microsoft.com/dotnet/api/system.numerics.inumberbase-1.createchecked) throws when the value doesn't fit, `CreateSaturating` clamps it, and `CreateTruncating` keeps the low bits: 300 is `0x12C`, and `0x2C` is 44.

Is `Sum<int>` as fast as a loop written for `int`? `GenericMathBenchmarks` sums 1,024 values:

| Method        | Mean     | Error   | StdDev  | Ratio | RatioSD |
|-------------- |---------:|--------:|--------:|------:|--------:|
| IntLoop       | 205.7 ns | 1.60 ns | 1.50 ns |  1.00 |    0.01 |
| IntGeneric    | 208.7 ns | 1.46 ns | 2.81 ns |  1.01 |    0.02 |
| DoubleLoop    | 363.3 ns | 4.44 ns | 4.16 ns |  1.77 |    0.02 |
| DoubleGeneric | 360.3 ns | 6.87 ns | 6.43 ns |  1.75 |    0.03 |

The generic version and the hand-written loop run in the same time, for `int` and for `double`, within their error margins: the JIT compiles a `Sum<int>` of its own, in which `T.Zero` and `+=` are the `int` ones. That is only true because `int` and `double` are value types, which is the next section.

## How the JIT shares generic code

The runtime can't compile one body of machine code for every `T`: a `Describe<int>` receives 4 bytes in a register, a `Describe<long>` 8 bytes, a `Describe<PitchClass>` a struct. It *can* share code between reference types, because every reference is a pointer of the same size, and the garbage collector treats them all alike. So the JIT compiles one version per value type, and one version for all reference types, instantiated over a placeholder type called `System.__Canon` ([Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md)).

You don't have to take that on faith. The JIT prints the list of methods it compiles when `DOTNET_JitDisasmSummary=1` is set, and writes it to a file with `DOTNET_JitStdOutFile`; both work in the shipped runtime ([Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md)). The program calls `Shared<T>.Describe` for six type arguments, and `check.sh` keeps the lines of that list that mention it ([`Lesson5.cs#L291-L348`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L291-L348), [`check.sh`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/check.sh)):

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

Six instantiations, four compilations: `int`, `long` and `PitchClass` each get their own, and `string`, `object` and `List<int>` share the `__Canon` one. The program also counts the methods the JIT compiled on its thread during each first call, with [`JitInfo.GetCompiledMethodCount`](https://learn.microsoft.com/dotnet/api/system.runtime.jitinfo). The count depends on the runtime, so it's printed on machine-dependent lines; on the author's machine, it agrees:

```text
# Shared<String>.Describe: 1 methods compiled on this thread by the first call
# Shared<Object>.Describe: 0 methods compiled on this thread by the first call
# Shared<List`1>.Describe: 0 methods compiled on this thread by the first call
```

Yet each instantiation still has its own `Calls` field, and `typeof(T)` still returns `String` or `Object`. The shared code finds them through a hidden argument, the *generic context*, which points to the instantiation's *generic dictionary*: a table of the type handles, statics and methods that depend on `T`. That lookup is the cost of sharing. Here is `ReadStatic<T>`, which adds a static field of `Counter<T>` in a loop. The program's `l5-tiers` mode calls it 5,000 times for `int` and for `string`, and `DOTNET_JitDisasm=ReadStatic` prints its machine code at each tier; these are the final, tier-1 versions, on x64, cut down to the loop:

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

For `int`, the JIT knows the address of `Counter<int>.Value`, and even reads the field once, before the loop: the loop is three instructions. For `__Canon`, it reads the class handle from the dictionary, through the generic context passed in `rcx`, and then calls a runtime helper to find the static field's address *on every iteration*. Compiled with tiered compilation off, the `__Canon` loop is the same. `SharedGenericBenchmarks` measures 1,000 reads:

| Method                     | Mean     | Error   | StdDev  | Ratio | RatioSD |
|--------------------------- |---------:|--------:|--------:|------:|--------:|
| ValueTypeInstantiation     | 199.8 ns | 2.61 ns | 2.44 ns |  1.00 |    0.02 |
| ReferenceTypeInstantiation | 292.2 ns | 5.79 ns | 5.42 ns |  1.46 |    0.03 |

The shared code is 1.46 times slower, about 0.09 ns more per read. That is less than I expected for a call per iteration; I haven't measured why it costs so little, *to verify*. This is a worst case, a loop around a lookup and nothing else; most shared generic code does real work between lookups. The lesson to keep is the direction: over value types, generic code is compiled as if you had written it by hand; over reference types, it is shared and pays for what depends on `T`.

## A static field per closed type: generic caches

Since each closed type has its own static fields, a static generic class is a dictionary keyed by `T` that the runtime maintains for you, with no lookup and no lock after initialization. The program's `TypeCache<T>` has an explicit static constructor, so that the runtime initializes it exactly at its first use rather than at a time of its choosing ([static constructors](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors)) ([`Lesson5.cs#L263-L287`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L263-L287)):

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

`TypeCache<string>` and `TypeCache<object>` share their code but not their statics. The base library uses the pattern everywhere: [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default) picks the best comparer for `T` once, a comparer that calls `IEquatable<T>.Equals` directly for `PitchClass`, one that unwraps `Nullable<T>`, one for enums, and caches it in a static field of `EqualityComparer<T>`.

GA's [`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) is the same idea, keyed by value-object type, and it calls the static abstract members to fill itself:

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

All the static fields of a class are initialized together, in the order they're written. A first read of `ItemsSpan` for GA's 26 strings therefore also builds two `FrozenSet`s, whether anyone uses them or not. The program measures that first access on a machine-dependent line:

```text
# first access to ValueObjectUtils<Str>.ItemsSpan (26 items) allocated 4592 bytes
```

An array of 26 `Str` is 128 bytes; most of the 4,592 bytes are the two frozen sets and the immutable array. It's paid once per type, and it's small, but it's worth knowing that a generic cache initializes everything it declares at once. In the three GA projects the course fetches, nothing but `ValueObjectUtils<TSelf>` reads those two sets, and `ValueObjectUtils` only exposes them.

## Case study: GA's `IStaticValueObjectList<TSelf>`

The interface is short:

```csharp
public interface IStaticValueObjectList<TSelf> : IStaticReadonlyCollectionFromValues<TSelf>
    where TSelf : struct, IRangeValueObject<TSelf>
{
    public static abstract IReadOnlyList<int> Values { get; }
}
```

It inherits `static abstract IReadOnlyCollection<TSelf> Items` from [`IStaticReadonlyCollection<out TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticReadonlyCollection.cs#L6-L13), and each implementer forwards to `ValueObjectUtils<TSelf>`, as [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156) does:

```csharp
public static IReadOnlyCollection<PitchClass> Items => ValueObjectUtils<PitchClass>.Items;
public static IReadOnlyList<int> Values => ValueObjectUtils<PitchClass>.Values;
public static ReadOnlySpan<PitchClass> ItemsSpan => ValueObjectUtils<PitchClass>.ItemsSpan;
```

The cache is computed once, but what does each *access* cost? The program measures the bytes allocated by one read, after a first read has run the JIT and the static constructors ([`Lesson5.cs#L352-L406`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L352-L406)):

```text
== GA: what IStaticValueObjectList<TSelf> costs per access
PitchClass.Items:                        32 bytes, the same object twice: False
foreach over PitchClass.Items:           72 bytes
PitchClass.Values[3]:                    24 bytes, Values is ImmutableArray`1
ValueObjectUtils<PitchClass>.Values[3]:  0 bytes
PitchClass.ItemsSpan[3]:                 0 bytes
SumAll<PitchClass>() over ItemsSpan:     66, 0 bytes
```

- **`Items` allocates a wrapper on every read.** [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) calls `ValueObjectCollection<TSelf>.Create()`, which returns a `new` 32-byte collection over the cached array. Its documentation says "automatically memoized"; the array is, the collection isn't.
- **A `foreach` over it allocates 72 bytes**: the wrapper, and its struct enumerator boxed to `IEnumerator<PitchClass>`, 40 bytes, because `Items` is typed as the interface.
- **`Values` boxes an `ImmutableArray<int>` on every read.** `ValueObjectUtils<TSelf>.Values` returns an [`ImmutableArray<int>`](https://learn.microsoft.com/dotnet/api/system.collections.immutable.immutablearray-1), a struct; `IStaticValueObjectList<TSelf>.Values` is declared `IReadOnlyList<int>`, so each implementer's property converts the struct to the interface: a 24-byte box, and an interface call for each index. Read directly, the same `ImmutableArray` costs nothing.
- **`ItemsSpan`, which the interface only mentions in a comment, is free**, and so is a generic method that reads `ValueObjectUtils<T>.ItemsSpan`: `SumAll<T>` works for every GA value object without any interface call.

`ValueObjectListBenchmarks` puts times on those bytes:

| Method               | Mean      | Error     | StdDev    | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------- |----------:|----------:|----------:|------:|--------:|-------:|----------:|------------:|
| ItemsForeach         | 14.473 ns | 0.2975 ns | 0.2783 ns |  1.00 |    0.03 | 0.0021 |      40 B |        1.00 |
| ItemsSpanForeach     |  3.871 ns | 0.0757 ns | 0.0708 ns |  0.27 |    0.01 |      - |         - |        0.00 |
| GenericSumAll        |  3.720 ns | 0.0655 ns | 0.0613 ns |  0.26 |    0.01 |      - |         - |        0.00 |
| ValuesIndexer        | 41.796 ns | 0.8563 ns | 1.8796 ns |  2.89 |    0.14 | 0.0153 |     288 B |        7.20 |
| ImmutableArrayValues |  3.134 ns | 0.0705 ns | 0.0659 ns |  0.22 |    0.01 |      - |         - |        0.00 |

Summing the twelve pitch classes through `Items` takes 14.5 ns; through `ItemsSpan`, or the generic `SumAll<PitchClass>`, 3.8 ns. Reading the twelve values through `PitchClass.Values` takes 41.8 ns and allocates 288 bytes, twelve boxes of 24 bytes; through the `ImmutableArray` itself, 3.1 ns and nothing: 13 times faster. The benchmark also shows the JIT at work once more: optimized with dynamic PGO, the `foreach` over `Items` allocates 40 bytes instead of the 72 that the program's first calls measured. 40 bytes is the size of the boxed enumerator, so the wrapper is probably the object the JIT no longer allocates; I haven't checked which one it is, *to verify*.

The pattern is common and easy to miss: a static abstract property typed as an interface turns a cached struct or array into an allocation per call, even though the generic machinery around it costs nothing.

Two more things the program found in these interfaces. First, the `out` on `IStaticReadonlyCollection<out TSelf>` is covariance, which the next section explains; the program looked for implementers in the two GA assemblies it loads:

```text
== GA: who implements IStaticReadonlyCollection<TSelf>
13 structs, 4 classes: ModalFamily, PitchClassSet, Scale, SetClass
```

Second, GA has two range checks that normalize a value into its range, and they disagree. [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63), a static method with a body on the generic interface, takes the remainder modulo `max - min`, one less than the number of values, then adds 1; [`ValueObjectUtils<TSelf>.EnsureValueRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L42-L47) uses `max - min + 1`:

```text
== GA: the two range checks with normalize: true
 -1: IRangeValueObject<PitchClass>.EnsureValueInRange 11, ValueObjectUtils<PitchClass>.EnsureValueRange 11
 12: IRangeValueObject<PitchClass>.EnsureValueInRange  2, ValueObjectUtils<PitchClass>.EnsureValueRange  0
 13: IRangeValueObject<PitchClass>.EnsureValueInRange  3, ValueObjectUtils<PitchClass>.EnsureValueRange  1
```

Pitch class 12 is 0; the interface's version says 2. `PitchClass` uses the correct one, and the value objects that call the interface's version, like `Fret` and `Finger`, don't pass `normalize: true`, so the bug is latent: no GA code in the fetched projects reaches it.

## Variance: `in`, `out`, and why `List<T>` has neither

A `string` is an `object`; is a sequence of strings a sequence of objects? For reading, yes: everything that comes out of an `IEnumerable<string>` is an object. For writing, no: a `List<object>` accepts a `PitchClass`, which a `List<string>` mustn't. C# lets an interface or a delegate say which applies to each type parameter ([Covariance and contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)): `out T` if `T` only comes out, which makes the interface *covariant*, `in T` if `T` only goes in, *contravariant* ([`Lesson5.cs#L209-L242`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L209-L242)):

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

- The conversion is a reference conversion: `IEnumerable<object>` is the *same object* as the `IEnumerable<string>`, no copy.
- `IList<T>` both returns and accepts `T`, so it can't be variant, and classes can never be: `List<T>` is invariant, and the compiler refuses the assignment outright.
- **Variance only works with reference types.** A `List<int>` is not an `IEnumerable<object>`: each `int` would need a box, and a reference conversion can't create boxes. The same rule makes GA's `out` on `IStaticReadonlyCollection<out TSelf>` useless for its 13 struct implementers, and harmless for the 4 classes, since an interface with only static members has nothing to call through a converted reference.
- Arrays are covariant too, since .NET 1.0, but writing into them is unsafe, so every write of a reference into an array is checked at run time, and fails with [`ArrayTypeMismatchException`](https://learn.microsoft.com/dotnet/api/system.arraytypemismatchexception).

The compiler checks variance on both sides. The assignment of an invariant class:

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

And a covariant parameter used as input:

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

Lesson 1 showed that `List<Span<int>>` doesn't compile: a `ref struct` can't be a type argument unless the type parameter says `allows ref struct`, added in C# 13 ([ref struct anti-constraint](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters#allows-ref-struct)). .NET 9 added it where it was safe, so the program asks the runtime which type parameters carry the flag ([`Lesson5.cs#L246-L257`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L246-L257)):

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

The delegates and the small interfaces allow it; the collections, which store their items in arrays on the heap, don't. A generic method can opt in too:

```csharp
static TResult Apply<T, TResult>(T value, Func<T, TResult> func) where T : allows ref struct => func(value);
```

The program's call passes it a `ReadOnlySpan<char>` over a voicing string, which compiles because both `Apply`'s `T` and `Func`'s `T` allow it. In exchange, the method's body must treat `T` as possibly a `ref struct`: no boxing, no field in a class, no capture in a lambda.

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

## If you know Spring and Reactor

Java generics look the same on the page and are the opposite underneath: the compiler checks them, then [erases](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html) them. The [Java for C# developers course](../../java-for-csharp/04-generics-and-erasure/) shows the consequences from the Java side, with javac's error messages; here is the same list from the C# side, row by row with this lesson.

| C# (.NET 10) | Java, Spring and Reactor |
|---|---|
| `typeof(List<int>) != typeof(List<string>)`; `typeof(T)` works inside a generic method | one `ArrayList` class for every `List<…>` ([JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html)); a method that needs the type takes a `Class<T>`, and Spring recovers declared type arguments from signatures with [`ResolvableType`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ResolvableType.html), or from an anonymous subclass with [`ParameterizedTypeReference`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ParameterizedTypeReference.html) |
| `List<PitchClass>`: the values inline, one array | `List<Integer>` only: [type arguments must be reference types](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html), each element a boxed object; [`IntStream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/IntStream.html) and its siblings exist to avoid it, Reactor's [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) has no such variant, and [JEP 218](https://openjdk.org/jeps/218), generics over primitive types, is still a *candidate* |
| `where T : struct`, `unmanaged`, `new()`, `notnull`, `allows ref struct` | only bounds: `T extends Comparable<T>`, with `&` for several; no constructor constraint (pass a `Supplier<T>`), nothing about value types, since there are none yet ([JEP 401](https://openjdk.org/jeps/401) value classes are a preview targeted at JDK 28) |
| `default(T)`: zero bits, `0` for `int`, `null` for `string` | always `null`, since every `T` is a reference |
| static abstract members: `T.FromValue(3)`, `T.Zero`, `left + right` on `T : INumber<T>` | no static members through a type variable; the usual answer is a factory or a strategy object passed in, as `Comparator<T>` is |
| declaration-site variance: `IEnumerable<out T>`, `Action<in T>`, checked by the compiler (CS1961) | use-site variance with wildcards: `List<? extends Number>` to read, `List<? super Integer>` to write, the "in" and "out" variables of the [wildcard guidelines](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) |
| arrays are covariant and checked at run time: `ArrayTypeMismatchException` | the same design and the same failure, [`ArrayStoreException`](https://docs.oracle.com/javase/specs/jls/se25/html/jls-10.html) |
| one static field per closed type: `TypeCache<string>` and `TypeCache<object>` are two caches | one static field for the whole class, whatever the type argument; a per-type cache is a [`ClassValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassValue.html) or a `Map<Class<?>, …>` |
| value-type instantiations get their own machine code; reference types share `__Canon` code | every instantiation runs the same bytecode, like .NET's shared code for reference types, and the JIT specializes from the profile instead |

The last row is the closest the two platforms come. HotSpot never sees `List<String>`, only `List`, and relies on its profile to inline and devirtualize, much as .NET's dynamic PGO devirtualized an interface call in lesson 4. What .NET adds is the value-type path: the code for `Sum<int>` is compiled for `int`, which Java only gets today from a class written for `int`, like `IntStream`.

## Exercises

1. GA normalizes values with a modulo that never returns a negative number. Write `Wrap<T>(T value, T size)` once for every number type, and check it on `-1` modulo `12`, `-13L` modulo `12L`, `-0.5` modulo `12.0` and `25` modulo `12`.
2. GA's `PitchClass` implements [`IParsable<TSelf>`](https://learn.microsoft.com/dotnet/api/system.iparsable-1), a static abstract interface from the base library. Write `ParseAll<T>(string text)`, which splits a space-separated list and parses each part with `T.Parse`, and use it for `"0 4 7 T"` as pitch classes and `"0 4 7 10"` as integers.
3. Which of these fields compile, and why?

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

1. `INumber<T>` gives `%`, `+`, the comparison and `T.Zero` ([`Lesson5.cs#L411-L415`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L411-L415)):

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

    `%` in C# keeps the sign of the dividend, so `-1 % 12` is `-1`, and adding the size once brings it into range. The same code works for `double`, where `%` is defined too.

2. `IParsable<T>` declares `static abstract T Parse(string s, IFormatProvider? provider)`, so the generic method calls it on `T` ([`Lesson5.cs#L418-L419`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L418-L419)):

    ```csharp
    public static List<T> ParseAll<T>(string text) where T : IParsable<T> =>
        [.. text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(s => T.Parse(s, null))];
    ```

    ```text
    2. ParseAll<PitchClass>("0 4 7 T") [0 4 7 T], ParseAll<int>("0 4 7 10") sum 21
    ```

3. `A` and `D` compile; `B`, `C` and `E` don't. `IReadOnlyList<out T>` is covariant, so a list of strings is a read-only list of objects. `IList<T>` is invariant (`B`). `List<int>` holds values, and variance only converts references (`C`). `Func<in T, out TResult>` accepts a function from `object` to `string` where one from `string` to `object` is expected: it takes more and returns less (`D`). `Action<in T>` goes the other way: an action on strings can't accept every object (`E`). The compiler checked it ([`l5_exercise_variance.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets/l5_exercise_variance.cs)):

    ```text
    l5_exercise_variance.cs(5,37): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<string>' to 'System.Collections.Generic.IList<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(6,43): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<int>' to 'System.Collections.Generic.IEnumerable<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(8,38): error CS0266: Cannot implicitly convert type 'System.Action<string>' to 'System.Action<object>'. An explicit conversion exists (are you missing a cast?)
    ```

    "An explicit conversion exists" because a `List<string>` could, in theory, be cast to an interface at run time; the cast would throw `InvalidCastException`.

</details>

## Key takeaways

- .NET generics are reified: `List<PitchClass>` stores its values inline, 104 bytes for twelve, where a list of objects takes 440.
- Constraints are metadata. The runtime checks `class`, `struct` and `new()`; `unmanaged` and `notnull` are checked only by the compiler, and `allows ref struct` widens instead of restricting.
- `default(T)` and `new T()` produce zeroed structs without running their validation. On an unconstrained `T`, `T?` isn't `Nullable<T>`.
- Static abstract members describe a type, not an object: `T.FromValue`, `T.Zero`, `left + right`. An interface that has them can't be a type argument.
- Generic math keeps each type's semantics, including checked operators, and `Sum<int>` ran as fast as a loop written for `int`.
- The JIT compiles generic code once per value type and once for all reference types, over `__Canon`. Shared code finds what depends on `T` through a generic dictionary, and paid a helper call per iteration to read a static field: 1.46 times slower in that loop.
- A static generic class is a per-type cache, initialized all at once. GA's cache is sound, but its interfaces allocate on every access: 32 bytes for `Items`, 24 for `Values`, nothing for `ItemsSpan`.
- Variance is for interfaces and delegates over reference types: `out` to read, `in` to write, never both.

## Sources

- Microsoft Learn: [Constraints on type parameters](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Generics in the runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time), [`default` operator](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default), [Static virtual interface members](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), [Generic math](https://learn.microsoft.com/dotnet/standard/generics/math), [Covariance and contravariance](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes), [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default), [Static constructors](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors).
- dotnet/runtime at `v10.0.12` (commit `4271d88`): [Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md), [Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md).
- Java: [Type erasure](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Restrictions on generics](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html) and [Wildcard guidelines](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) in the Java tutorials, [JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [JEP 218](https://openjdk.org/jeps/218), [JEP 401](https://openjdk.org/jeps/401).
- Guitar Alchemist at `a826864`: [`IStaticValueObjectList.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), [`IValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47), [`IRangeValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L81), [`ValueObjectCache.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52), [`ValueObjectUtils.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L6-L64), [`PitchClass.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156).
