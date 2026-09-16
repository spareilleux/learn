---
title: "Lesson 1: Memory — values, references and spans"
description: How big a value and an object really are, where boxing hides in the IL and when the .NET 10 JIT removes it, defensive copies with in, ref locals, ref structs, Span<T> and stackalloc — measured on Guitar Alchemist's value objects.
sidebar:
  label: 1. Memory, values and spans
  order: 1
---

You know the rule from the C# books: value types live inline, reference types live on the heap, and boxing copies a value to the heap. This lesson measures each part of that rule. It counts the bytes of values and objects, reads the IL the compiler emits, and shows where the .NET 10 JIT ignores what the IL asks for. Then it looks at the tools C# gives you to avoid copies: `in`, `ref` locals, `ref struct` and `Span<T>`, with the compiler errors that keep them safe.

GA links point to commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) of `GuitarAlchemist/ga`; runtime links point to commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) of `dotnet/runtime`, tagged `v10.0.12`.

## Running the lesson's program

The code is in [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) clones GA at that commit (only the three projects the program references), builds, runs every lesson and compares the output with [`expected/`](https://github.com/spareilleux/learn/tree/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected). You need the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) and Git; on Windows, run it from Git Bash.

```bash
bash code/csharp-advanced/check.sh                                   # every lesson, IL and compiler error
dotnet run --project code/csharp-advanced/Advanced -c Release -- l1  # this lesson only, after check.sh
```

The small methods whose IL the lesson shows live in their own project, [`Snippets/Memory.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Snippets/Memory.cs), so that their IL doesn't move when the rest of the program changes. Always measure a Release build: a Debug build keeps extra locals and disables most JIT optimizations.

## How big is a value, how big is an object?

Two numbers matter. [`Unsafe.SizeOf<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof) is the *inline* size: what a field or an array element of type `T` takes. For a reference type, that is the size of the reference, 8 bytes on a 64-bit process. The *heap* size is what one allocation costs, and the program measures it with [`GC.GetAllocatedBytesForCurrentThread()`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) around a second call of the allocating code, so that the JIT and the static constructors have already run ([`Report.cs#L17-L24`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Report.cs#L17-L24)).

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

Every object on the 64-bit heap starts with two pointer-sized words: the object header (used for locks and hash codes) and the method table pointer, which identifies the type. Then come the fields, and the total is rounded up to a multiple of 8. The minimum is 24 bytes, even for `new object()`, which has no field at all.

- A boxed `int` is 8 + 8 + 4 = 20 bytes, rounded to 24. A boxed `long` fits exactly in 24.
- `Padded` holds a `byte` and a `long`, but takes 16 bytes inline: the `long` must start on an 8-byte boundary, so the compiler's default sequential layout leaves 7 bytes of padding after the `byte`.
- An array adds its length (4 bytes, padded to 8) to the header: 24 bytes when empty, and 24 + 10 × 4 = 64 for ten `int`s.
- A string stores its length, its UTF-16 characters and a terminating null character: 8 + 8 + 4 + 5 × 2 + 2 = 32 bytes for five characters.

GA models music with small value objects. [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L26-L59) is a `readonly record struct` wrapping one `int`, and [`PitchClassSetId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L8-L20) too: 4 bytes each, as cheap as the `int` itself, as long as they are not boxed.

## Boxing: in the IL, and after the JIT

Boxing converts a value to `object` or to an interface: the runtime allocates an object and copies the value into it ([Boxing and unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)). The compiler emits a `box` instruction wherever that happens. Here are five small methods, and the IL of three of them, disassembled with [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) `-il` by `check.sh` ([`expected/snippets-il.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/snippets-il.txt)).

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

- Casting a value to an interface is a `box`, even when the interface is generic.
- Calling the same method through a generic constraint is not: the [`constrained.`](https://learn.microsoft.com/dotnet/api/system.reflection.emit.opcodes.constrained) prefix lets the runtime call `Equals` directly on the value. This is why generic code over `T : IEquatable<T>` doesn't box, and why GA can declare its value objects' behaviour in static abstract interfaces such as `IStaticValueObjectList<TSelf>` without paying for it.
- `string.Format(string, object)` takes an `object`: the `int` is boxed. An interpolated string compiles to a [`DefaultInterpolatedStringHandler`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.defaultinterpolatedstringhandler), whose `AppendFormatted<T>` is generic: no `box` at all.
- `ToObjectAndBack` contains `box` followed by `unbox.any` of the same type.

Now the bytes each call allocates. The program runs the table twice: once normally, where these methods run in the JIT's first, unoptimized tier; and once with `DOTNET_TieredCompilation=0`, where every method is compiled fully optimized at once ([`Lesson1.cs#L103-L116`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L103-L116)).

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

Three things happened that the IL doesn't say.

1. `ToObjectAndBack` never allocates, even in the first tier: the JIT recognizes `box` immediately followed by `unbox.any` and removes both.
2. With full optimization, `BoxAndHash` (which boxes, then calls `GetHashCode()` on the box) and `ThroughInterface` allocate nothing. The JIT proved that the box doesn't *escape* the method, and put it on the stack. Stack allocation of boxes arrived in [.NET 9](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), and [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation) extends escape analysis to small arrays, struct fields and delegates. In a normal run, a method called often enough is recompiled with these optimizations after a few dozen calls; lesson 4 measures tiered compilation.
3. `Format` still allocates 56 bytes: 24 for the boxed `int`, 32 for the string `"12345"`. The box is passed to `string.Format`, a large method the JIT doesn't inline, so it escapes. `Interpolate` allocates only the string.

So "boxing allocates" is true of the IL, and only sometimes of the machine code. The IL tells you where to look; a measurement tells you what it costs.

## `in` and `ref`: copies you don't see

A struct passed by value is copied. [`ref`, `in` and `ref readonly` parameters](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters#reference-parameters) pass a reference to it instead. `in` promises the caller that the method won't modify the argument. To keep that promise when the struct is mutable, the compiler must assume any method call might modify it, and calls the method on a hidden copy.

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

No warning, no error: the increment is silently lost. The IL of `ByIn` shows the copy, `ldobj` into local 0, and the call on that local's address:

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

The same defensive copy happens when you call a method on a `readonly` field of a mutable struct type. The fix is to make the struct, or at least the method, `readonly`: then the compiler knows the call can't modify the value and passes the reference directly. `ref readonly` parameters (C# 12) behave like `in` inside the method, but ask the caller to pass a variable with `ref` or `in`, and warn when it passes a temporary value: use them for APIs that need a reference to an existing location, not just a way to avoid a copy. Assigning to a field of an `in` parameter is a compile-time error:

```csharp
public static void Reset(in Counter counter) => counter.Value = 0;
```

```text
l1_in_assign.cs(9,53): error CS8332: Cannot assign to a member of variable 'counter' or use it as the right hand side of a ref assignment because it is a readonly variable
```

Every rejected snippet of the course is compiled alone by [`CompileFail/Program.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), which uses Roslyn 5.0.0, the compiler of the .NET 10.0.1xx SDK; the messages are identical to those of `dotnet build` ([`expected/compile-fail.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/compile-fail.txt)).

## `ref` locals and returns

A `ref` local is an alias for a storage location: an array element, a field, a dictionary slot. [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) returns a reference to the value of a `Dictionary` entry, adding the entry if it's missing. Incrementing a counter then takes one hash lookup instead of two (`TryGetValue`, then the indexer's set). The program counts GA's 4,096 pitch-class sets by number of notes:

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

These are the binomial coefficients C(12, k): one empty set, 12 single notes, 66 intervals, 220 three-note sets. The reference is valid only until the dictionary changes: adding another key may resize it and move the entries, which is why the method lives in `CollectionsMarshal` and not on `Dictionary` itself.

The compiler tracks where a reference points to. Returning a reference to a local variable, whose storage disappears with the method's stack frame, is rejected:

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

## `ref struct`, `Span<T>` and `stackalloc`

[`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) is a reference plus a length: a window over an array, a string, native memory or the stack. To be safe, it must never outlive the memory it points to, so it is a [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct): a struct that can only live on the stack. The compiler enforces that with a family of errors. A `ref struct` can't be a field of a class:

```csharp
public class FretBuffer
{
    private Span<int> _frets; // a Span can live only on the stack
}
```

```text
l1_ref_struct_field.cs(4,13): error CS8345: Field or auto-implemented property cannot be of type 'Span<int>' unless it is an instance member of a ref struct.
```

It can't be captured by a lambda, which would store it in a closure object on the heap:

```csharp
public static Func<int> Sum(Span<int> frets) => () => frets[0] + frets[1];
```

```text
l1_span_lambda.cs(4,59): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
l1_span_lambda.cs(4,70): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
```

It can't be a type argument of a generic type that doesn't opt in. Since C# 13, a generic parameter can declare `allows ref struct`; `List<T>` doesn't, because it stores its items in an array:

```csharp
public static List<Span<int>> Shapes = [];
```

```text
l1_span_type_argument.cs(4,35): error CS9244: The type 'Span<int>' may not be a ref struct or a type parameter allowing ref structs in order to use it as parameter 'T' in the generic type or method 'List<T>'
```

And memory from [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc) can't leave the method that allocated it:

```csharp
public static Span<int> Empty()
{
    Span<int> frets = stackalloc int[6];
    return frets; // the memory disappears when the method returns
}
```

```text
l1_stackalloc_escape.cs(7,16): error CS8352: Cannot use variable 'frets' in this context because it may expose referenced variables outside of their declaration scope
```

When the data must outlive the stack frame, across an `await` or in a field, use [`Memory<T>`](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), an ordinary struct that can be stored anywhere and turned into a `Span<T>` where the work is done.

Within those rules, spans remove allocations. A guitar voicing is often written as six frets, `x 3 2 0 1 0` for an open C chord. The first version splits the string; the second slices it with [`MemoryExtensions.Split`](https://learn.microsoft.com/dotnet/api/system.memoryextensions.split), which returns ranges, parses each slice with `int.Parse(ReadOnlySpan<char>)`, and stores the frets in six `int`s on the stack ([`Lesson1.cs#L126-L155`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L126-L155)).

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

The 216 bytes are the `string[]` of six elements (24 + 6 × 8 = 72 bytes) and six one-character strings of 24 bytes each. For one voicing that's nothing; for the millions of voicings a chord search enumerates, it's garbage-collector work, which lesson 2 measures.

## A copy per call in GA

GA's value objects expose their possible values as a span. For `PitchClass`, `ItemsSpan` returns a cached array ([`ValueObjectCache.cs#L45-L49`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L45-L49)). `PitchClassSetId` has its own implementation ([`PitchClassSetId.cs#L59`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59), [`#L70-L71`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)):

```csharp
public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items is PitchClassSetId[] arr ? arr : [.. Items];

public static IReadOnlyCollection<PitchClassSetId> Items { get; } =
    [.. Enumerable.Range(_minValue, _maxValue - _minValue + 1).Select(i => new PitchClassSetId(i))];
```

The intent is clear: return the array without copying it. But `Items` is initialized with a collection expression whose target is the interface `IReadOnlyCollection<T>`, and for that target the compiler is free to build a type of its own ([collection expressions, non-mutable interface translation](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md#non-mutable-interface-translation)). The test `Items is PitchClassSetId[]` is therefore always false, and every read of `ItemsSpan` copies 4,096 ids into a new array:

```text
== GA: ItemsSpan of two value objects
PitchClass.ItemsSpan: 12 items, 0 bytes
PitchClassSetId.ItemsSpan: 4096 items, 16408 bytes
PitchClassSetId.Items is <>z__ReadOnlyList`1
```

16,408 bytes is 24 bytes of array header plus 4,096 × 4. The code compiles, runs and returns the right values; only a measurement shows the cost. The fix is exercise 3.

## If you know Spring and Reactor

This lesson has almost no Java counterpart, and that is what it teaches. On the JVM every type you declare is a reference type: `PitchClass`, four bytes inline here, would be an object with a header there, and a list of them a list of references. C# gives you tools to keep values off the heap; Java asks its collector to clear them away quickly, which lesson 2 compares.

| C# | Java, Spring and Reactor |
|---|---|
| `struct`, `readonly record struct`: 4 bytes, inline, no header | no user-defined value type; a `record` is an ordinary heap object. [Project Valhalla](https://openjdk.org/projects/valhalla/)'s value objects are a *preview* targeted at JDK 28 ([JEP 401](https://openjdk.org/jeps/401)), so they are in no released JDK |
| boxing is a `box` instruction, which the JIT sometimes removes | autoboxing calls `Integer.valueOf` ([generics restrictions](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)); HotSpot's escape analysis, `-XX:+DoEscapeAnalysis`, [enabled by default](https://docs.oracle.com/en/java/javase/25/docs/specs/man/java.html), may remove the allocation |
| generics are reified: `PitchClass[]` holds 4-byte values | generics are erased ([JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html)): `List<Integer>` holds references to boxed objects, and `List<int>` doesn't compile at all |
| `Span<T>` over an array, a string, native memory or the stack | [`ByteBuffer`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/ByteBuffer.html), Netty's [`ByteBuf`](https://netty.io/wiki/reference-counted-objects.html), WebFlux's [`DataBuffer`](https://docs.spring.io/spring-framework/reference/core/databuffer-codec.html): objects, and none of them a window over a `String` |
| `stackalloc` | nothing equivalent. `ByteBuffer.allocateDirect` allocates outside the heap, and its Javadoc recommends it "primarily for large, long-lived buffers" |
| CS8345, CS8352 and the other ref-safety errors: the compiler proves the span can't outlive its memory | reference counting, checked at run time: `release()`, `IllegalReferenceCountException`, and a leak detector that samples about 1% of allocations |
| `Memory<T>` for data that crosses an `await` | a pooled buffer retained across an operator boundary, released by whoever reads it last |
| a silent defensive copy when you call a method on an `in` parameter | doesn't arise: objects are always passed by reference |

The row that costs real debugging time is ownership. A `Span<T>` owns nothing and the compiler rejects the code that would let it outlive its memory. A `PooledDataBuffer` starts at a reference count of 1, `retain()` and `release()` move it, and Spring's documentation is explicit that "special care must be taken to ensure buffers are released since they may be pooled" — with a rule per case: release each buffer you read, and add `doOnDiscard(DataBuffer.class, DataBufferUtils::release)` when an operator may drop items. You only own that job when you handle `DataBuffer` yourself; decode to a `String` or a record and the codec has already released it. The two runtimes solve the same problem, one with a type system, the other with a discipline and a leak detector.

GA's `ItemsSpan` has a Java shape too. A property that returns `collection.toArray()` copies on every read, returns the right values, and no test notices; the measurement that found the 16,408 bytes here is the one to run there.

## Exercises

1. Predict `Unsafe.SizeOf` of the tuple `(bool, int, bool)`, of a struct with the fields `bool Muted; int Fret; bool Barre;` in that order, and of the same struct marked [`[StructLayout(LayoutKind.Auto)]`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.layoutkind).
2. Make the compiler catch the lost increment of `ByIn`: what do you change in `Counter`, and what does the compiler then say about `Increment`?
3. Rewrite `PitchClassSetId.ItemsSpan` so that it doesn't allocate, and check that it returns the same ids.

<details>
<summary>Solutions</summary>

1. The struct in declaration order takes **12** bytes: `bool` (1 byte, 3 of padding), `int` (4), `bool` (1, 3 of padding), because a struct's size is a multiple of its largest field's alignment. With `LayoutKind.Auto`, the runtime may reorder the fields: `int`, `bool`, `bool`, 2 of padding, **8** bytes. `ValueTuple` is declared with `LayoutKind.Auto`, so the tuple takes **8** bytes too. Sequential layout is the C# default for structs because it matches native code in interop; for a struct that never crosses to native code, `Auto` can save space.

    ```text
    1. (bool, int, bool) 8 bytes, SequentialFlags 12, AutoFlags 8
    ```

2. Mark `Increment` as a `readonly` member, or the whole struct as `readonly struct`. The compiler then rejects the increment inside the method, and the call on an `in` parameter no longer needs a defensive copy. To keep a mutating method, take the parameter by `ref` instead.

    ```csharp
    public readonly void Increment() => Value++;
    ```

    ```text
    l1_readonly_member.cs(6,41): error CS1604: Cannot assign to 'Value' because it is read-only
    ```

3. Store the ids in an array once, and return the array as a span: the conversion from `T[]` to `ReadOnlySpan<T>` doesn't copy ([`Lesson1.cs#L94-L100`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L94-L100)). In GA itself, declaring `Items` with a concrete array, or going through `ValueObjectUtils<PitchClassSetId>.ItemsSpan` like the other value objects, would do the same.

    ```csharp
    private static readonly PitchClassSetId[] Items = [.. PitchClassSetId.Items];

    public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items;
    ```

    ```text
    3. cached ItemsSpan: 4096 items, 0 bytes, same ids True
    ```

</details>

## Key takeaways

- A 64-bit object costs at least 24 bytes: header, method table pointer, then the fields rounded up to 8. `Unsafe.SizeOf<T>()` gives the inline size; `GC.GetAllocatedBytesForCurrentThread()` around a warmed-up call gives the heap cost.
- The IL shows boxing as `box`. Generic constraints call through `constrained.` without boxing, and interpolated strings format without boxing.
- The JIT may remove a box the IL asks for: always for `box` followed by `unbox.any`, and, in optimized code, whenever the box doesn't escape the method. Measure the optimized code, not the IL.
- Calling a method on an `in` parameter or a `readonly` field of a mutable struct runs it on a silent copy. Make the struct or the method `readonly`.
- `Span<T>` and `stackalloc` parse and slice without allocating. The compiler's ref-safety errors (CS8345, CS8352, CS9108, CS9244, CS8168) are what keeps them from pointing to memory that no longer exists; `Memory<T>` is for data that must outlive the stack frame.
- A collection expression assigned to an interface is not an array. GA's `PitchClassSetId.ItemsSpan` copies 16 KB on every call because of it.

## Sources

- Microsoft Learn: [`Unsafe.SizeOf`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof), [Boxing and unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing), [Method parameters](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [ref struct types](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc), [Memory and span usage guidelines](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), [Collection expressions](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions).
- What's new in the runtime: [.NET 9, object stack allocation for boxes](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), [.NET 10, stack allocation](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation).
- [ECMA-335](https://www.ecma-international.org/publications-and-standards/standards/ecma-335/), partition III, for `box`, `unbox.any` and the `constrained.` prefix.
- The C# language proposal for [collection expressions](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md).
