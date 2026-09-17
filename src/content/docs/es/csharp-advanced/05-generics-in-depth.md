---
title: "Lección 5: genéricos en profundidad"
description: Los genéricos reificados medidos en bytes, lo que cada restricción escribe en los metadatos y cuáles comprueba solo el compilador, default(T) y T?, los miembros abstractos estáticos y las matemáticas genéricas, la varianza, allows ref struct, las cachés estáticas por tipo y el código máquina que el JIT comparte entre los tipos de referencia, sobre IStaticValueObjectList<TSelf> de Guitar Alchemist, comparados con el borrado de tipos de Java.
sidebar:
  label: 5. Genéricos en profundidad
  order: 5
---

Usas genéricos todos los días, y la lección 1 ya mostró una cosa que hacen bajo el capó: una llamada a través de una restricción se emite con el prefijo `constrained.` y no hace boxing. Esta lección va más allá. Examina qué es un tipo genérico en tiempo de ejecución, qué escribe cada restricción en los metadatos, qué significan realmente `default(T)` y `T?`, cómo los miembros abstractos estáticos permiten que una interfaz describa un tipo en lugar de un objeto, y cuándo el JIT da el mismo código máquina a dos instanciaciones. Cada punto lo imprime un programa, o se compila, se desensambla o se mide.

El ejemplo conductor es una familia de interfaces de Guitar Alchemist. `PitchClass`, `Fret`, `IntervalClass` y una docena de structs pequeños más implementan [`IStaticValueObjectList<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), que usa casi todas las características de esta lección a la vez: un parámetro de tipo que se refiere al tipo que lo implementa, una restricción `struct`, miembros abstractos estáticos y una clase genérica estática que sirve de caché.

Los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6); los enlaces al runtime apuntan al commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, etiquetado `v10.0.12`.

## Ejecutar el programa de la lección

```bash
bash code/csharp-advanced/check.sh                                   # todas las lecciones, comparadas con expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- l5  # solo esta lección, después de check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*GenericMathBenchmarks*"   # una clase de benchmarks
```

El programa es [`Advanced/Lesson5.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs); los cuatro métodos cuyo IL muestra la lección están en [`Snippets/Generics.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs); los fragmentos rechazados son los archivos `l5_*.cs` de [`CompileFail/snippets`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets). `check.sh` lo compara todo con [`expected/`](https://github.com/spareilleux/learn/tree/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/expected) en tres sistemas operativos. Los tiempos provienen de [`Benchmarks/GenericBenchmarks.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Benchmarks/GenericBenchmarks.cs), ejecutados en la máquina del autor, la que describe la [lección 4](../04-measured-performance/).

## Genéricos reificados: un tipo por instanciación

En .NET, un tipo genérico está *reificado*: `List<int>` y `List<string>` son dos tipos distintos en tiempo de ejecución, cada uno con su propio objeto `Type`, y un método genérico puede pedir `typeof(T)` o crear un `new T[n]`. El runtime construye cada tipo cerrado a partir de la definición abierta `List<T>` la primera vez que lo necesita ([Genéricos en el runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time)). Para un tipo de valor, eso significa que los elementos se guardan en línea, sin boxing ([`Lesson5.cs#L33-L62`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L33-L62)):

```text
== Reified generics: every instantiation is a type of its own
typeof(List<int>) == typeof(List<string>): False
typeof(List<PitchClass>): System.Collections.Generic.List`1[GA.Domain.Core.Theory.Atonal.PitchClass]
new List<PitchClass>() is List<int>: False
NameOf<PitchClass>(): PitchClass; new T[3] is GA.Domain.Core.Theory.Atonal.PitchClass[]
12 pitch classes in a List<PitchClass>: 104 bytes
12 pitch classes in a List<object>:     440 bytes
```

Los 104 bytes son el objeto `List`, 32 bytes, y un array de 12 valores `PitchClass` de cuatro bytes, 24 + 48. La `List<object>` tiene los mismos 32 bytes, un array de 12 referencias, 24 + 96, y doce objetos con boxing de 24 bytes cada uno: 440 bytes, más de cuatro veces más, y trece objetos para el recolector de basura en lugar de dos. Esa segunda lista es el aspecto que tiene en Java cualquier colección genérica de números, como muestra la última sección.

## Restricciones: lo que comprueba el compilador y lo que comprueba el runtime

Una restricción hace dos trabajos: limita los argumentos de tipo que un llamador puede pasar, y permite que el código genérico use lo que la restricción promete, ya sea un constructor, un operador o un método. La referencia de C# las enumera todas ([Restricciones de tipos de parámetros](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters)). Sin restricción, `T` solo ofrece lo que tiene `object`, y el compilador lo dice:

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

El segundo error fue el límite clásico de los genéricos de C# hasta C# 11; las matemáticas genéricas, más abajo, lo eliminan. Pero antes, ¿en qué se convierten las restricciones una vez compiladas? El programa declara un método vacío por restricción y vuelve a leer su parámetro de tipo con reflexión, a través de [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes) ([`Lesson5.cs#L66-L92`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L66-L92)):

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

- `struct` se escribe como dos indicadores, «no es un tipo de valor que acepta null» y «tiene un constructor predeterminado», más el tipo base `ValueType`: para el runtime, un struct siempre tiene un constructor sin parámetros.
- `unmanaged` se escribe exactamente igual que `struct`, más un `IsUnmanagedAttribute` que solo lee el compilador.
- `notnull` no deja nada que el runtime lea: es una anotación de nulabilidad, que el compilador comprueba con una advertencia.
- `allows ref struct`, nuevo en C# 13, es un indicador propio, y es una *anti-restricción*: amplía lo que el llamador puede pasar en lugar de restringirlo.

Así que el runtime puede comprobar unas restricciones y otras no. [`MethodInfo.MakeGenericMethod`](https://learn.microsoft.com/dotnet/api/system.reflection.methodinfo.makegenericmethod) instancia un método en tiempo de ejecución, sin pasar por el compilador:

```text
== Constraints the compiler checks and the runtime doesn't
MakeGenericMethod((int, string)) on 'where T : unmanaged': accepted
MakeGenericMethod(string) on 'where T : unmanaged':        ArgumentException
MakeGenericMethod(int?) on 'where T : struct':            ArgumentException
sizeof(T) with T : unmanaged: PitchClass 4, (byte, long) 16
IsReferenceOrContainsReferences: PitchClass False, (int, string) True
new T() with T : new(): StringBuilder, Str 0
```

El runtime acepta `(int, string)` para `unmanaged`, porque lo que comprueba es «un tipo de valor que no acepta null», y una tupla que contiene un `string` lo es. El compilador rechaza lo mismo, porque `unmanaged` también significa «ninguna referencia en ningún nivel de anidamiento», que es lo que hace seguros `sizeof(T)` y los punteros a `T`:

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

Cuando el código debe decidir en tiempo de ejecución si un `T` contiene referencias, por ejemplo para saber si hay que limpiar un búfer para el recolector de basura, la respuesta la da [`RuntimeHelpers.IsReferenceOrContainsReferences<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.runtimehelpers.isreferenceorcontainsreferences), y el JIT la convierte en una constante para cada tipo de valor. La restricción `struct`, en cambio, excluye `Nullable<T>` tanto en el compilador como en el runtime:

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

Y `notnull`, que solo existe en el compilador, solo produce una advertencia; `Dictionary<TKey, TValue>` declara su clave `notnull`:

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

Por último, ¿qué emite el compilador para `new T()`? No una llamada a un constructor, porque no puede saber a cuál. El IL de [`Generics.Create`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L11) llama a [`Activator.CreateInstance<T>()`](https://learn.microsoft.com/dotnet/api/system.activator.createinstance), y para un struct eso devuelve el valor cero sin ejecutar ninguna validación. `Str` de GA, una cuerda de guitarra numerada de 1 a 26, sale como la cuerda 0 en la última línea de arriba:

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

## `default(T)`, y lo que significa `T?`

[`default(T)`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default) son todos los bits a cero: `null` para un tipo de referencia, `0` para un número y, para un struct, todos sus campos a cero. El IL es `initobj !!T`, sea cual sea `T`. La sorpresa es `T?`. Sobre un `T` sin restricciones, `T?` solo dice «puede ser el valor predeterminado»; no convierte `int` en `int?`. Con `where T : struct`, `T?` es `Nullable<T>` ([`Lesson5.cs#L113-L141`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L113-L141)):

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

`FirstOrDefault<int>` no puede distinguir «no encontrado» de «encontrado 0»: su tipo de retorno es un simple `Int32`. Así se comporta también el `FirstOrDefault` de LINQ. Las líneas de GA muestran la misma trampa en los tipos de dominio. `default(PitchClass)` es 0, un do perfectamente válido, así que una clase de altura que falta parece un do. `default(Str)` es la cuerda 0, que [`Str`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Primitives/Str.cs#L16-L17) se niega a crear: su descriptor de acceso `init` comprueba el rango, pero `default`, `new Str[6]` y `new T()` nunca lo ejecutan. Un struct con un invariante no puede imponerlo frente a memoria puesta a cero; los objetos de valor de GA con un mínimo de 1, `Str` y los grados de la escala, pueden aparecer todos como 0 de esta forma.

## Miembros abstractos estáticos

Un método de interfaz describe lo que puede hacer un *objeto*. Un [miembro abstracto estático](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), desde C# 11, describe lo que puede hacer un *tipo*: crearse a partir de un `int`, dar su mínimo, sumar dos de sus valores. El código genérico lo llama sobre el parámetro de tipo, como en `T.FromValue(3)`. [`IValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47) e [`IRangeValueObject<TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L23) de GA están construidas así:

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

La restricción `where TSelf : IRangeValueObject<TSelf>` es el patrón *autorreferencial*: `PitchClass` implementa `IRangeValueObject<PitchClass>`, así que dentro de la interfaz `TSelf` significa «el tipo que la implementa», y `FromValue` puede devolver un `PitchClass` en lugar de una interfaz. Con eso, un único método genérico sirve para todos los objetos de valor de GA ([`Lesson5.cs#L160-L177`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L160-L177)):

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

En el IL, una llamada a un miembro abstracto estático es un `call` con el mismo prefijo `constrained.` que en la lección 1, sobre el método de la interfaz. No hay ningún objeto sobre el que despachar: el runtime la resuelve a partir del argumento de tipo y, en el código compilado para un tipo de valor, el JIT la resuelve una sola vez y puede insertarla en línea ([`Generics.FromValue`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Snippets/Generics.cs#L15)):

```text
IL_0000: ldarg.0
IL_0001: constrained. !!T
IL_0007: call !0 class Snippets.IFromValue`1<!!T>::FromValue(int32)
IL_000c: ret
```

El precio de los miembros abstractos estáticos es que la interfaz deja de ser un tipo del que el código genérico pueda contener un valor. Sus miembros estáticos no tienen ninguna implementación a la que llamar, así que no puede ser un argumento de tipo:

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

## Matemáticas genéricas

.NET 7 usó los miembros abstractos estáticos para dar a cada tipo numérico un conjunto de interfaces: [`INumber<T>`](https://learn.microsoft.com/dotnet/api/system.numerics.inumber-1) y sus partes, `IAdditionOperators<TSelf, TOther, TResult>`, `INumberBase<T>` con `Zero` y `One`, y las demás ([Matemáticas genéricas](https://learn.microsoft.com/dotnet/standard/generics/math)). Un operador es un método estático, así que `left + right` sobre `T : IAdditionOperators<T, T, T>` se compila en una llamada restringida a `op_Addition`, que es el IL de `Generics.Add`:

```text
IL_0000: ldarg.0
IL_0001: ldarg.1
IL_0002: constrained. !!T
IL_0008: call !2 class [System.Runtime]System.Numerics.IAdditionOperators`3<!!T, !!T, !!T>::op_Addition(!0, !1)
IL_000d: ret
```

Un único `Sum` y un único `Mean` sirven entonces para todos los tipos numéricos ([`Lesson5.cs#L181-L205`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L181-L205)):

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

El código genérico conserva la semántica de cada tipo. La media entera de 1, 2, 3 y 4 es 2, y la media `double` es 2.5; `decimal` suma 0.1 y 0.2 exactamente, y `double` no. Una expresión [`checked`](https://learn.microsoft.com/dotnet/csharp/language-reference/statements/checked-and-unchecked) en código genérico llama al operador *checked* del tipo, `op_CheckedAddition`, otra novedad de C# 11: `byte` e `int` lanzan una excepción, y `double`, que no tiene desbordamiento, da infinito. Convertir entre tipos numéricos tiene tres variantes explícitas: [`CreateChecked`](https://learn.microsoft.com/dotnet/api/system.numerics.inumberbase-1.createchecked) lanza una excepción cuando el valor no cabe, `CreateSaturating` lo recorta a los límites del tipo, y `CreateTruncating` conserva los bits bajos: 300 es `0x12C`, y `0x2C` es 44.

¿Es `Sum<int>` tan rápido como un bucle escrito para `int`? `GenericMathBenchmarks` suma 1024 valores:

| Method        | Mean     | Error   | StdDev  | Ratio | RatioSD |
|-------------- |---------:|--------:|--------:|------:|--------:|
| IntLoop       | 205.7 ns | 1.60 ns | 1.50 ns |  1.00 |    0.01 |
| IntGeneric    | 208.7 ns | 1.46 ns | 2.81 ns |  1.01 |    0.02 |
| DoubleLoop    | 363.3 ns | 4.44 ns | 4.16 ns |  1.77 |    0.02 |
| DoubleGeneric | 360.3 ns | 6.87 ns | 6.43 ns |  1.75 |    0.03 |

La versión genérica y el bucle escrito a mano tardan lo mismo, para `int` y para `double`, dentro de sus márgenes de error: el JIT compila un `Sum<int>` propio, en el que `T.Zero` y `+=` son los de `int`. Eso solo es cierto porque `int` y `double` son tipos de valor, que es el tema de la sección siguiente.

## Cómo comparte el JIT el código genérico

El runtime no puede compilar un único cuerpo de código máquina para todos los `T`: un `Describe<int>` recibe 4 bytes en un registro, un `Describe<long>` 8 bytes, y un `Describe<PitchClass>` un struct. Lo que *sí* puede es compartir código entre los tipos de referencia, porque toda referencia es un puntero del mismo tamaño, y el recolector de basura las trata todas igual. Así que el JIT compila una versión por tipo de valor, y una sola versión para todos los tipos de referencia, instanciada sobre un tipo marcador de posición llamado `System.__Canon` ([Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md)).

No hace falta creérselo. El JIT imprime la lista de los métodos que compila cuando se define `DOTNET_JitDisasmSummary=1`, y la escribe en un archivo con `DOTNET_JitStdOutFile`; ambos funcionan en el runtime publicado ([Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md)). El programa llama a `Shared<T>.Describe` para seis argumentos de tipo, y `check.sh` conserva las líneas de esa lista que lo mencionan ([`Lesson5.cs#L291-L348`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L291-L348), [`check.sh`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/check.sh)):

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

Seis instanciaciones, cuatro compilaciones: `int`, `long` y `PitchClass` obtienen cada uno la suya, y `string`, `object` y `List<int>` comparten la de `__Canon`. El programa también cuenta los métodos que el JIT compiló en su subproceso durante cada primera llamada, con [`JitInfo.GetCompiledMethodCount`](https://learn.microsoft.com/dotnet/api/system.runtime.jitinfo). La cifra depende del runtime, así que se imprime en líneas que dependen de la máquina; en la máquina del autor, coincide:

```text
# Shared<String>.Describe: 1 methods compiled on this thread by the first call
# Shared<Object>.Describe: 0 methods compiled on this thread by the first call
# Shared<List`1>.Describe: 0 methods compiled on this thread by the first call
```

Aun así, cada instanciación sigue teniendo su propio campo `Calls`, y `typeof(T)` sigue devolviendo `String` u `Object`. El código compartido los encuentra a través de un argumento oculto, el *contexto genérico*, que apunta al *diccionario genérico* de la instanciación: una tabla de los identificadores de tipo, los campos estáticos y los métodos que dependen de `T`. Esa búsqueda es el coste de compartir. Aquí tienes `ReadStatic<T>`, que suma un campo estático de `Counter<T>` en un bucle. El modo `l5-tiers` del programa lo llama 5000 veces para `int` y para `string`, y `DOTNET_JitDisasm=ReadStatic` imprime su código máquina en cada nivel; estas son las versiones finales, de nivel 1, en x64, recortadas al bucle:

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

Para `int`, el JIT conoce la dirección de `Counter<int>.Value`, e incluso lee el campo una sola vez, antes del bucle: el bucle son tres instrucciones. Para `__Canon`, lee el identificador de clase del diccionario, a través del contexto genérico pasado en `rcx`, y después llama a una función auxiliar del runtime para encontrar la dirección del campo estático *en cada iteración*. Con la compilación por niveles desactivada, el bucle de `__Canon` sale igual. `SharedGenericBenchmarks` mide 1000 lecturas:

| Method                     | Mean     | Error   | StdDev  | Ratio | RatioSD |
|--------------------------- |---------:|--------:|--------:|------:|--------:|
| ValueTypeInstantiation     | 199.8 ns | 2.61 ns | 2.44 ns |  1.00 |    0.02 |
| ReferenceTypeInstantiation | 292.2 ns | 5.79 ns | 5.42 ns |  1.46 |    0.03 |

El código compartido es 1.46 veces más lento, unos 0.09 ns más por lectura. Es menos de lo que esperaba para una llamada por iteración; no he medido por qué cuesta tan poco, *por verificar*. Se trata del peor caso, un bucle alrededor de una búsqueda y nada más; la mayor parte del código genérico compartido hace trabajo real entre búsquedas. Lo que conviene retener es la dirección: sobre tipos de valor, el código genérico se compila como si lo hubieras escrito a mano; sobre tipos de referencia, se comparte y paga por lo que depende de `T`.

## Un campo estático por tipo cerrado: cachés genéricas

Como cada tipo cerrado tiene sus propios campos estáticos, una clase genérica estática es un diccionario indexado por `T` que el runtime mantiene por ti, sin búsqueda y sin bloqueo después de la inicialización. El `TypeCache<T>` del programa tiene un constructor estático explícito, para que el runtime lo inicialice exactamente en su primer uso y no en el momento que elija ([constructores estáticos](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors)) ([`Lesson5.cs#L263-L287`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L263-L287)):

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

`TypeCache<string>` y `TypeCache<object>` comparten su código pero no sus campos estáticos. La biblioteca base usa el patrón en todas partes: [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default) elige una sola vez el mejor comparador para `T`, ya sea uno que llama directamente a `IEquatable<T>.Equals` para `PitchClass`, uno que desenvuelve `Nullable<T>` o uno para los enums, y lo guarda en caché en un campo estático de `EqualityComparer<T>`.

[`ValueObjectCache<T>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52) de GA es la misma idea, indexada por tipo de objeto de valor, y llama a los miembros abstractos estáticos para llenarse:

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

Todos los campos estáticos de una clase se inicializan juntos, en el orden en que están escritos. Por tanto, una primera lectura de `ItemsSpan` para las 26 cuerdas de GA construye también dos `FrozenSet`, los use alguien o no. El programa mide ese primer acceso en una línea que depende de la máquina:

```text
# first access to ValueObjectUtils<Str>.ItemsSpan (26 items) allocated 4592 bytes
```

Un array de 26 `Str` ocupa 128 bytes; la mayor parte de los 4592 bytes son los dos conjuntos congelados y el array inmutable. Se paga una vez por tipo, y es poco, pero conviene saber que una caché genérica inicializa de golpe todo lo que declara. En los tres proyectos de GA que descarga el curso, nada salvo `ValueObjectUtils<TSelf>` lee esos dos conjuntos, y `ValueObjectUtils` se limita a exponerlos.

## Caso práctico: `IStaticValueObjectList<TSelf>` de GA

La interfaz es corta:

```csharp
public interface IStaticValueObjectList<TSelf> : IStaticReadonlyCollectionFromValues<TSelf>
    where TSelf : struct, IRangeValueObject<TSelf>
{
    public static abstract IReadOnlyList<int> Values { get; }
}
```

Hereda `static abstract IReadOnlyCollection<TSelf> Items` de [`IStaticReadonlyCollection<out TSelf>`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticReadonlyCollection.cs#L6-L13), y cada implementación delega en `ValueObjectUtils<TSelf>`, como hace [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156):

```csharp
public static IReadOnlyCollection<PitchClass> Items => ValueObjectUtils<PitchClass>.Items;
public static IReadOnlyList<int> Values => ValueObjectUtils<PitchClass>.Values;
public static ReadOnlySpan<PitchClass> ItemsSpan => ValueObjectUtils<PitchClass>.ItemsSpan;
```

La caché se calcula una sola vez, pero ¿cuánto cuesta cada *acceso*? El programa mide los bytes asignados por una lectura, después de que una primera lectura haya ejecutado el JIT y los constructores estáticos ([`Lesson5.cs#L352-L406`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L352-L406)):

```text
== GA: what IStaticValueObjectList<TSelf> costs per access
PitchClass.Items:                        32 bytes, the same object twice: False
foreach over PitchClass.Items:           72 bytes
PitchClass.Values[3]:                    24 bytes, Values is ImmutableArray`1
ValueObjectUtils<PitchClass>.Values[3]:  0 bytes
PitchClass.ItemsSpan[3]:                 0 bytes
SumAll<PitchClass>() over ItemsSpan:     66, 0 bytes
```

- **`Items` asigna un contenedor en cada lectura.** [`ValueObjectUtils<TSelf>.Items`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L10) llama a `ValueObjectCollection<TSelf>.Create()`, que devuelve con `new` una colección de 32 bytes sobre el array en caché. Su documentación dice «automatically memoized»; el array lo está, pero la colección no.
- **Un `foreach` sobre ella asigna 72 bytes**: el contenedor, y su enumerador struct con boxing a `IEnumerator<PitchClass>`, de 40 bytes, porque `Items` tiene como tipo la interfaz.
- **`Values` hace boxing de un `ImmutableArray<int>` en cada lectura.** `ValueObjectUtils<TSelf>.Values` devuelve un [`ImmutableArray<int>`](https://learn.microsoft.com/dotnet/api/system.collections.immutable.immutablearray-1), que es un struct; `IStaticValueObjectList<TSelf>.Values` está declarado como `IReadOnlyList<int>`, así que la propiedad de cada implementación convierte el struct en la interfaz: un boxing de 24 bytes, y una llamada a la interfaz por cada índice. Leído directamente, el mismo `ImmutableArray` no cuesta nada.
- **`ItemsSpan`, que la interfaz solo menciona en un comentario, es gratuito**, y también lo es un método genérico que lee `ValueObjectUtils<T>.ItemsSpan`: `SumAll<T>` sirve para todos los objetos de valor de GA sin ninguna llamada a una interfaz.

`ValueObjectListBenchmarks` pone tiempos a esos bytes:

| Method               | Mean      | Error     | StdDev    | Ratio | RatioSD | Gen0   | Allocated | Alloc Ratio |
|--------------------- |----------:|----------:|----------:|------:|--------:|-------:|----------:|------------:|
| ItemsForeach         | 14.473 ns | 0.2975 ns | 0.2783 ns |  1.00 |    0.03 | 0.0021 |      40 B |        1.00 |
| ItemsSpanForeach     |  3.871 ns | 0.0757 ns | 0.0708 ns |  0.27 |    0.01 |      - |         - |        0.00 |
| GenericSumAll        |  3.720 ns | 0.0655 ns | 0.0613 ns |  0.26 |    0.01 |      - |         - |        0.00 |
| ValuesIndexer        | 41.796 ns | 0.8563 ns | 1.8796 ns |  2.89 |    0.14 | 0.0153 |     288 B |        7.20 |
| ImmutableArrayValues |  3.134 ns | 0.0705 ns | 0.0659 ns |  0.22 |    0.01 |      - |         - |        0.00 |

Sumar las doce clases de altura a través de `Items` tarda 14.5 ns; a través de `ItemsSpan`, o del genérico `SumAll<PitchClass>`, 3.8 ns. Leer los doce valores a través de `PitchClass.Values` tarda 41.8 ns y asigna 288 bytes, doce objetos con boxing de 24 bytes; a través del propio `ImmutableArray`, 3.1 ns y nada: 13 veces más rápido. El benchmark muestra también el JIT en acción una vez más: optimizado con la PGO dinámica, el `foreach` sobre `Items` asigna 40 bytes en lugar de los 72 que midieron las primeras llamadas del programa. 40 bytes es el tamaño del enumerador con boxing, así que el contenedor es probablemente el objeto que el JIT ya no asigna; no he comprobado cuál es, *por verificar*.

El patrón es habitual y fácil de pasar por alto: una propiedad abstracta estática cuyo tipo es una interfaz convierte un struct o un array en caché en una asignación por llamada, aunque la maquinaria genérica que la rodea no cueste nada.

El programa encontró dos cosas más en estas interfaces. Primero, el `out` de `IStaticReadonlyCollection<out TSelf>` es covarianza, que explica la sección siguiente; el programa buscó las implementaciones en los dos ensamblados de GA que carga:

```text
== GA: who implements IStaticReadonlyCollection<TSelf>
13 structs, 4 classes: ModalFamily, PitchClassSet, Scale, SetClass
```

Segundo, GA tiene dos comprobaciones de rango que normalizan un valor dentro de su rango, y no coinciden. [`IRangeValueObject<TSelf>.EnsureValueInRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L55-L63), un método estático con cuerpo en la interfaz genérica, toma el resto módulo `max - min`, uno menos que el número de valores, y luego suma 1; [`ValueObjectUtils<TSelf>.EnsureValueRange`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L42-L47) usa `max - min + 1`:

```text
== GA: the two range checks with normalize: true
 -1: IRangeValueObject<PitchClass>.EnsureValueInRange 11, ValueObjectUtils<PitchClass>.EnsureValueRange 11
 12: IRangeValueObject<PitchClass>.EnsureValueInRange  2, ValueObjectUtils<PitchClass>.EnsureValueRange  0
 13: IRangeValueObject<PitchClass>.EnsureValueInRange  3, ValueObjectUtils<PitchClass>.EnsureValueRange  1
```

La clase de altura 12 es 0; la versión de la interfaz dice 2. `PitchClass` usa la correcta, y los objetos de valor que llaman a la versión de la interfaz, como `Fret` y `Finger`, no pasan `normalize: true`, así que el error está latente: ningún código de GA en los proyectos descargados llega a él.

## Varianza: `in`, `out`, y por qué `List<T>` no tiene ninguna de las dos

Un `string` es un `object`; ¿es entonces una secuencia de cadenas una secuencia de objetos? Para leer, sí: todo lo que sale de un `IEnumerable<string>` es un objeto. Para escribir, no: una `List<object>` acepta un `PitchClass`, que una `List<string>` no debe aceptar. C# permite que una interfaz o un delegado indique cuál de los dos casos se aplica a cada parámetro de tipo ([Covarianza y contravarianza](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance)): `out T` si `T` solo sale, lo que hace la interfaz *covariante*, e `in T` si `T` solo entra, lo que la hace *contravariante* ([`Lesson5.cs#L209-L242`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L209-L242)):

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

- La conversión es una conversión de referencia: el `IEnumerable<object>` es el *mismo objeto* que el `IEnumerable<string>`, sin copia.
- `IList<T>` devuelve y acepta `T` a la vez, así que no puede ser variante, y las clases no pueden serlo nunca: `List<T>` es invariante, y el compilador rechaza la asignación directamente.
- **La varianza solo funciona con tipos de referencia.** Una `List<int>` no es un `IEnumerable<object>`: cada `int` necesitaría un boxing, y una conversión de referencia no puede crear objetos con boxing. La misma regla hace inútil el `out` de `IStaticReadonlyCollection<out TSelf>` de GA para sus 13 implementaciones struct, e inofensivo para las 4 clases, ya que una interfaz con solo miembros estáticos no tiene nada a lo que llamar a través de una referencia convertida.
- Los arrays también son covariantes, desde .NET 1.0, pero escribir en ellos no es seguro, así que cada escritura de una referencia en un array se comprueba en tiempo de ejecución, y falla con [`ArrayTypeMismatchException`](https://learn.microsoft.com/dotnet/api/system.arraytypemismatchexception).

El compilador comprueba la varianza en ambos lados. Primero, la asignación de una clase invariante:

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

Y después, un parámetro covariante usado como entrada:

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

La lección 1 mostró que `List<Span<int>>` no compila: un `ref struct` no puede ser argumento de tipo a menos que el parámetro de tipo declare `allows ref struct`, añadido en C# 13 ([anti-restricción ref struct](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters#allows-ref-struct)). .NET 9 lo añadió allí donde era seguro, así que el programa pregunta al runtime qué parámetros de tipo llevan el indicador ([`Lesson5.cs#L246-L257`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L246-L257)):

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

Los delegados y las interfaces pequeñas lo permiten; las colecciones, que guardan sus elementos en arrays en el montón, no. Un método genérico también puede aceptarlo:

```csharp
static TResult Apply<T, TResult>(T value, Func<T, TResult> func) where T : allows ref struct => func(value);
```

La llamada del programa le pasa un `ReadOnlySpan<char>` sobre una cadena de voicing, y compila porque tanto el `T` de `Apply` como el `T` de `Func` lo permiten. A cambio, el cuerpo del método debe tratar `T` como un posible `ref struct`: sin boxing, sin guardarlo en un campo de una clase y sin capturarlo en una lambda.

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

## Si conoces Spring y Reactor

Los genéricos de Java parecen iguales sobre el papel y son lo contrario por debajo: el compilador los comprueba y después los [borra](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html). El [curso de Java para desarrolladores C#](../../java-for-csharp/04-generics-and-erasure/) muestra las consecuencias desde el lado de Java, con los mensajes de error de javac; aquí está la misma lista desde el lado de C#, fila a fila con esta lección.

| C# (.NET 10) | Java, Spring y Reactor |
|---|---|
| `typeof(List<int>) != typeof(List<string>)`; `typeof(T)` funciona dentro de un método genérico | una sola clase `ArrayList` para todas las `List<…>` ([JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html)); un método que necesita el tipo recibe un `Class<T>`, y Spring recupera los argumentos de tipo declarados a partir de las firmas con [`ResolvableType`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ResolvableType.html), o de una subclase anónima con [`ParameterizedTypeReference`](https://docs.spring.io/spring-framework/docs/current/javadoc-api/org/springframework/core/ParameterizedTypeReference.html) |
| `List<PitchClass>`: los valores en línea, en un solo array | solo `List<Integer>`: [los argumentos de tipo deben ser tipos de referencia](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html), y cada elemento es un objeto con boxing; [`IntStream`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/util/stream/IntStream.html) y sus hermanos existen para evitarlo, el [`Flux`](https://projectreactor.io/docs/core/release/api/reactor/core/publisher/Flux.html) de Reactor no tiene esa variante, y [JEP 218](https://openjdk.org/jeps/218), los genéricos sobre tipos primitivos, sigue siendo un *candidato* |
| `where T : struct`, `unmanaged`, `new()`, `notnull`, `allows ref struct` | solo cotas: `T extends Comparable<T>`, con `&` para varias; ninguna restricción de constructor (se pasa un `Supplier<T>`), y nada sobre tipos de valor, porque todavía no existen (las clases de valor de [JEP 401](https://openjdk.org/jeps/401) son una versión preliminar prevista para el JDK 28) |
| `default(T)`: bits a cero, `0` para `int`, `null` para `string` | siempre `null`, porque todo `T` es una referencia |
| miembros abstractos estáticos: `T.FromValue(3)`, `T.Zero`, `left + right` sobre `T : INumber<T>` | ningún miembro estático a través de una variable de tipo; la respuesta habitual es pasar como argumento una fábrica o un objeto estrategia, como `Comparator<T>` |
| varianza en el sitio de declaración: `IEnumerable<out T>`, `Action<in T>`, comprobada por el compilador (CS1961) | varianza en el sitio de uso con comodines: `List<? extends Number>` para leer, `List<? super Integer>` para escribir, las variables «in» y «out» de las [pautas sobre comodines](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) |
| los arrays son covariantes y se comprueban en tiempo de ejecución: `ArrayTypeMismatchException` | el mismo diseño y el mismo fallo, [`ArrayStoreException`](https://docs.oracle.com/javase/specs/jls/se25/html/jls-10.html) |
| un campo estático por tipo cerrado: `TypeCache<string>` y `TypeCache<object>` son dos cachés | un solo campo estático para toda la clase, sea cual sea el argumento de tipo; una caché por tipo es un [`ClassValue`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/ClassValue.html) o un `Map<Class<?>, …>` |
| las instanciaciones sobre tipos de valor tienen su propio código máquina; los tipos de referencia comparten el código de `__Canon` | todas las instanciaciones ejecutan el mismo bytecode, como el código compartido de .NET para los tipos de referencia, y el JIT especializa a partir del perfil |

La última fila es donde más se acercan las dos plataformas. HotSpot nunca ve `List<String>`, solo `List`, y se apoya en su perfil para insertar en línea y desvirtualizar, de forma muy parecida a como la PGO dinámica de .NET desvirtualizó una llamada de interfaz en la lección 4. Lo que añade .NET es la ruta de los tipos de valor: el código de `Sum<int>` se compila para `int`, algo que Java hoy solo obtiene de una clase escrita para `int`, como `IntStream`.

## Ejercicios

1. GA normaliza los valores con un módulo que nunca devuelve un número negativo. Escribe `Wrap<T>(T value, T size)` una sola vez para todos los tipos numéricos, y compruébalo con `-1` módulo `12`, `-13L` módulo `12L`, `-0.5` módulo `12.0` y `25` módulo `12`.
2. `PitchClass` de GA implementa [`IParsable<TSelf>`](https://learn.microsoft.com/dotnet/api/system.iparsable-1), una interfaz abstracta estática de la biblioteca base. Escribe `ParseAll<T>(string text)`, que divide una lista separada por espacios y analiza cada parte con `T.Parse`, y úsalo para `"0 4 7 T"` como clases de altura y `"0 4 7 10"` como enteros.
3. ¿Cuáles de estos campos compilan, y por qué?

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
<summary>Soluciones</summary>

1. `INumber<T>` aporta `%`, `+`, la comparación y `T.Zero` ([`Lesson5.cs#L411-L415`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L411-L415)):

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

    `%` en C# conserva el signo del dividendo, así que `-1 % 12` es `-1`, y sumar el tamaño una vez lo devuelve al rango. El mismo código sirve para `double`, donde `%` también está definido.

2. `IParsable<T>` declara `static abstract T Parse(string s, IFormatProvider? provider)`, así que el método genérico lo llama sobre `T` ([`Lesson5.cs#L418-L419`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/Advanced/Lesson5.cs#L418-L419)):

    ```csharp
    public static List<T> ParseAll<T>(string text) where T : IParsable<T> =>
        [.. text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Select(s => T.Parse(s, null))];
    ```

    ```text
    2. ParseAll<PitchClass>("0 4 7 T") [0 4 7 T], ParseAll<int>("0 4 7 10") sum 21
    ```

3. `A` y `D` compilan; `B`, `C` y `E` no. `IReadOnlyList<out T>` es covariante, así que una lista de cadenas es una lista de solo lectura de objetos. `IList<T>` es invariante (`B`). `List<int>` contiene valores, y la varianza solo convierte referencias (`C`). `Func<in T, out TResult>` acepta una función de `object` a `string` donde se espera una de `string` a `object`: recibe más y devuelve menos (`D`). `Action<in T>` va en sentido contrario: una acción sobre cadenas no puede aceptar cualquier objeto (`E`). El compilador lo comprobó ([`l5_exercise_variance.cs`](https://github.com/spareilleux/learn/blob/378eec1333390889e29fd0c42af0fae47512035e/code/csharp-advanced/CompileFail/snippets/l5_exercise_variance.cs)):

    ```text
    l5_exercise_variance.cs(5,37): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<string>' to 'System.Collections.Generic.IList<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(6,43): error CS0266: Cannot implicitly convert type 'System.Collections.Generic.List<int>' to 'System.Collections.Generic.IEnumerable<object>'. An explicit conversion exists (are you missing a cast?)
    l5_exercise_variance.cs(8,38): error CS0266: Cannot implicitly convert type 'System.Action<string>' to 'System.Action<object>'. An explicit conversion exists (are you missing a cast?)
    ```

    Dice «An explicit conversion exists» porque un `List<string>` podría, en teoría, convertirse a una interfaz en tiempo de ejecución; esa conversión lanzaría `InvalidCastException`.

</details>

## Puntos clave

- Los genéricos de .NET están reificados: `List<PitchClass>` guarda sus valores en línea, 104 bytes para doce, donde una lista de objetos ocupa 440.
- Las restricciones son metadatos. El runtime comprueba `class`, `struct` y `new()`; `unmanaged` y `notnull` solo los comprueba el compilador, y `allows ref struct` amplía en lugar de restringir.
- `default(T)` y `new T()` producen structs a cero sin ejecutar su validación. Sobre un `T` sin restricciones, `T?` no es `Nullable<T>`.
- Los miembros abstractos estáticos describen un tipo, no un objeto: `T.FromValue`, `T.Zero`, `left + right`. Una interfaz que los tiene no puede ser un argumento de tipo.
- Las matemáticas genéricas conservan la semántica de cada tipo, incluidos los operadores checked, y `Sum<int>` se ejecutó tan rápido como un bucle escrito para `int`.
- El JIT compila el código genérico una vez por tipo de valor y una sola vez para todos los tipos de referencia, sobre `__Canon`. El código compartido encuentra lo que depende de `T` a través de un diccionario genérico, y pagó una llamada auxiliar por iteración para leer un campo estático: 1.46 veces más lento en ese bucle.
- Una clase genérica estática es una caché por tipo, que se inicializa de golpe. La caché de GA es sólida, pero sus interfaces asignan memoria en cada acceso: 32 bytes para `Items`, 24 para `Values` y nada para `ItemsSpan`.
- La varianza es para interfaces y delegados sobre tipos de referencia: `out` para leer, `in` para escribir, nunca ambos.

## Fuentes

- Microsoft Learn: [Restricciones de tipos de parámetros](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters), [Genéricos en el runtime](https://learn.microsoft.com/dotnet/csharp/programming-guide/generics/generics-in-the-run-time), [Operador `default`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/default), [Miembros de interfaz virtuales estáticos](https://learn.microsoft.com/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members), [Matemáticas genéricas](https://learn.microsoft.com/dotnet/standard/generics/math), [Covarianza y contravarianza](https://learn.microsoft.com/dotnet/standard/generics/covariance-and-contravariance), [`GenericParameterAttributes`](https://learn.microsoft.com/dotnet/api/system.reflection.genericparameterattributes), [`EqualityComparer<T>.Default`](https://learn.microsoft.com/dotnet/api/system.collections.generic.equalitycomparer-1.default), [Constructores estáticos](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/static-constructors).
- dotnet/runtime en `v10.0.12` (commit `4271d88`): [Shared generics design](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/botr/shared-generics.md), [Viewing JIT dumps](https://github.com/dotnet/runtime/blob/4271d88e0aebf3d04f188f1334c2220d80555ef6/docs/design/coreclr/jit/viewing-jit-dumps.md).
- Java: [Borrado de tipos](https://docs.oracle.com/javase/tutorial/java/generics/erasure.html), [Restricciones de los genéricos](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html) y [Pautas sobre comodines](https://docs.oracle.com/javase/tutorial/java/generics/wildcardGuidelines.html) en los tutoriales de Java, [JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html), [JEP 218](https://openjdk.org/jeps/218), [JEP 401](https://openjdk.org/jeps/401).
- Guitar Alchemist en `a826864`: [`IStaticValueObjectList.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Collections/Abstractions/IStaticValueObjectList.cs#L46-L58), [`IValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IValueObject.cs#L33-L47), [`IRangeValueObject.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Abstractions/IRangeValueObject.cs#L12-L81), [`ValueObjectCache.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L38-L52), [`ValueObjectUtils.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L6-L64), [`PitchClass.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L146-L156).
