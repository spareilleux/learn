---
title: "Lección 1: Memoria — valores, referencias y spans"
description: Cuánto ocupan de verdad un valor y un objeto, dónde se esconde el boxing en el IL y cuándo lo elimina el JIT de .NET 10, las copias defensivas con in, las variables locales ref, los ref structs, Span<T> y stackalloc — medido en los objetos de valor de Guitar Alchemist.
sidebar:
  label: 1. Memoria, valores y spans
  order: 1
---

Conoces la regla de los libros de C#: los tipos de valor viven en línea, los tipos de referencia viven en el montón, y el boxing copia un valor al montón. Esta lección mide cada parte de esa regla. Cuenta los bytes de valores y objetos, lee el IL que emite el compilador y muestra dónde el JIT de .NET 10 ignora lo que pide el IL. Después examina las herramientas que C# te da para evitar copias: `in`, las variables locales `ref`, `ref struct` y `Span<T>`, con los errores del compilador que las mantienen seguras.

Los enlaces de GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) de `GuitarAlchemist/ga`; los enlaces del runtime apuntan al commit [`4271d88`](https://github.com/dotnet/runtime/tree/4271d88e0aebf3d04f188f1334c2220d80555ef6) de `dotnet/runtime`, con la etiqueta `v10.0.12`.

## Ejecutar el programa de la lección

El código está en [`code/csharp-advanced`](https://github.com/spareilleux/learn/tree/main/code/csharp-advanced). [`check.sh`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/check.sh) clona GA en ese commit (solo los tres proyectos a los que hace referencia el programa), compila, ejecuta cada lección y compara la salida con [`expected/`](https://github.com/spareilleux/learn/tree/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected). Necesitas el [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y Git; en Windows, ejecútalo desde Git Bash.

```bash
bash code/csharp-advanced/check.sh                                   # cada lección, el IL y los errores del compilador
dotnet run --project code/csharp-advanced/Advanced -c Release -- l1  # solo esta lección, después de check.sh
```

Los métodos pequeños cuyo IL muestra la lección viven en su propio proyecto, [`Snippets/Memory.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Snippets/Memory.cs), para que su IL no cambie cuando cambia el resto del programa. Mide siempre una compilación Release: una compilación Debug conserva variables locales adicionales y desactiva la mayoría de las optimizaciones del JIT.

## ¿Cuánto ocupa un valor, y cuánto un objeto?

Importan dos números. [`Unsafe.SizeOf<T>()`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof) es el tamaño *en línea*: lo que ocupa un campo o un elemento de array de tipo `T`. Para un tipo de referencia, es el tamaño de la referencia, 8 bytes en un proceso de 64 bits. El tamaño *en el montón* es lo que cuesta una asignación, y el programa lo mide con [`GC.GetAllocatedBytesForCurrentThread()`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) alrededor de una segunda llamada al código que asigna, para que el JIT y los constructores estáticos ya se hayan ejecutado ([`Report.cs#L17-L24`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Report.cs#L17-L24)).

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

Todo objeto del montón de 64 bits empieza con dos palabras del tamaño de un puntero: el encabezado del objeto (que se usa para los bloqueos y los códigos hash) y el puntero a la tabla de métodos, que identifica el tipo. Después vienen los campos, y el total se redondea al múltiplo de 8 superior. El mínimo es de 24 bytes, incluso para `new object()`, que no tiene ningún campo.

- Un `int` con boxing ocupa 8 + 8 + 4 = 20 bytes, redondeados a 24. Un `long` con boxing cabe exactamente en 24.
- `Padded` contiene un `byte` y un `long`, pero ocupa 16 bytes en línea: el `long` debe empezar en un límite de 8 bytes, así que la disposición secuencial predeterminada del compilador deja 7 bytes de relleno después del `byte`.
- Un array añade su longitud (4 bytes, rellenados hasta 8) al encabezado: 24 bytes cuando está vacío, y 24 + 10 × 4 = 64 para diez `int`.
- Una cadena guarda su longitud, sus caracteres UTF-16 y un carácter nulo final: 8 + 8 + 4 + 5 × 2 + 2 = 32 bytes para cinco caracteres.

GA modela la música con pequeños objetos de valor. [`PitchClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L26-L59) es un `readonly record struct` que envuelve un único `int`, y [`PitchClassSetId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L8-L20) también: 4 bytes cada uno, tan baratos como el propio `int`, siempre que no se les aplique boxing.

## Boxing: en el IL y después del JIT

El boxing convierte un valor en `object` o en una interfaz: el runtime asigna un objeto y copia el valor dentro ([Boxing y unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing)). El compilador emite una instrucción `box` allí donde ocurre. Aquí tienes cinco métodos pequeños, y el IL de tres de ellos, desensamblado con [`ilspycmd`](https://www.nuget.org/packages/ilspycmd) `-il` por `check.sh` ([`expected/snippets-il.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/snippets-il.txt)).

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

- Convertir un valor en una interfaz es un `box`, incluso cuando la interfaz es genérica.
- Llamar al mismo método a través de una restricción genérica no lo es: el prefijo [`constrained.`](https://learn.microsoft.com/dotnet/api/system.reflection.emit.opcodes.constrained) permite al runtime llamar a `Equals` directamente sobre el valor. Por eso el código genérico sobre `T : IEquatable<T>` no hace boxing, y por eso GA puede declarar el comportamiento de sus objetos de valor en interfaces abstractas estáticas como `IStaticValueObjectList<TSelf>` sin pagar por ello.
- `string.Format(string, object)` recibe un `object`: el `int` sufre boxing. Una cadena interpolada se compila en un [`DefaultInterpolatedStringHandler`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.defaultinterpolatedstringhandler), cuyo `AppendFormatted<T>` es genérico: ningún `box`.
- `ToObjectAndBack` contiene un `box` seguido de un `unbox.any` del mismo tipo.

Ahora, los bytes que asigna cada llamada. El programa ejecuta la tabla dos veces: una normalmente, donde estos métodos se ejecutan en el primer nivel del JIT, sin optimizar; y otra con `DOTNET_TieredCompilation=0`, donde cada método se compila completamente optimizado desde el principio ([`Lesson1.cs#L103-L116`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L103-L116)).

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

Ocurrieron tres cosas que el IL no dice.

1. `ToObjectAndBack` nunca asigna, ni siquiera en el primer nivel: el JIT reconoce un `box` seguido inmediatamente de `unbox.any` y elimina ambos.
2. Con la optimización completa, `BoxAndHash` (que hace boxing y luego llama a `GetHashCode()` sobre el objeto resultante) y `ThroughInterface` no asignan nada. El JIT demostró que el objeto con boxing no *escapa* del método, y lo colocó en la pila. La asignación en la pila de los objetos con boxing llegó en [.NET 9](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), y [.NET 10](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation) extiende el análisis de escape a los arrays pequeños, los campos de structs y los delegados. En una ejecución normal, un método al que se llama con suficiente frecuencia se vuelve a compilar con estas optimizaciones tras unas pocas decenas de llamadas; la lección 4 mide la compilación por niveles.
3. `Format` sigue asignando 56 bytes: 24 para el `int` con boxing y 32 para la cadena `"12345"`. El objeto con boxing se pasa a `string.Format`, un método grande que el JIT no inserta en línea, así que escapa. `Interpolate` solo asigna la cadena.

Así que «el boxing asigna memoria» es cierto para el IL, y solo a veces para el código máquina. El IL te dice dónde mirar; una medición te dice lo que cuesta.

## `in` y `ref`: copias que no ves

Un struct pasado por valor se copia. Los [parámetros `ref`, `in` y `ref readonly`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters#reference-parameters) pasan en su lugar una referencia a él. `in` promete al llamador que el método no modificará el argumento. Para cumplir esa promesa cuando el struct es mutable, el compilador debe suponer que cualquier llamada a un método podría modificarlo, y llama al método sobre una copia oculta.

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

Ni advertencia ni error: el incremento se pierde en silencio. El IL de `ByIn` muestra la copia, `ldobj` en la variable local 0, y la llamada sobre la dirección de esa variable local:

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

La misma copia defensiva se produce cuando llamas a un método sobre un campo `readonly` de un tipo struct mutable. La solución es hacer `readonly` el struct, o al menos el método: así el compilador sabe que la llamada no puede modificar el valor y pasa la referencia directamente. Los parámetros `ref readonly` (C# 12) se comportan como `in` dentro del método, pero piden al llamador que pase una variable con `ref` o `in`, y advierten cuando pasa un valor temporal: úsalos en las API que necesitan una referencia a una ubicación existente, no solo como forma de evitar una copia. Asignar a un campo de un parámetro `in` es un error en tiempo de compilación:

```csharp
public static void Reset(in Counter counter) => counter.Value = 0;
```

```text
l1_in_assign.cs(9,53): error CS8332: Cannot assign to a member of variable 'counter' or use it as the right hand side of a ref assignment because it is a readonly variable
```

Cada fragmento rechazado del curso se compila por separado con [`CompileFail/Program.cs`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/CompileFail/Program.cs), que usa Roslyn 5.0.0, el compilador del SDK de .NET 10.0.1xx; los mensajes son idénticos a los de `dotnet build` ([`expected/compile-fail.txt`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/expected/compile-fail.txt)).

## Variables locales y retornos `ref`

Una variable local `ref` es un alias de una ubicación de almacenamiento: un elemento de array, un campo, una entrada de diccionario. [`CollectionsMarshal.GetValueRefOrAddDefault`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.collectionsmarshal.getvaluereforadddefault) devuelve una referencia al valor de una entrada de un `Dictionary`, y añade la entrada si falta. Incrementar un contador cuesta entonces una sola búsqueda hash en lugar de dos (`TryGetValue` y luego la asignación mediante el indexador). El programa cuenta los 4,096 conjuntos de clases de altura de GA por número de notas:

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

Son los coeficientes binomiales C(12, k): un conjunto vacío, 12 notas sueltas, 66 intervalos, 220 conjuntos de tres notas. La referencia solo es válida hasta que el diccionario cambia: añadir otra clave puede redimensionarlo y mover las entradas, y por eso el método vive en `CollectionsMarshal` y no en el propio `Dictionary`.

El compilador sigue la pista de a dónde apunta una referencia. Devolver una referencia a una variable local, cuyo almacenamiento desaparece con el marco de pila del método, se rechaza:

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

## `ref struct`, `Span<T>` y `stackalloc`

[`Span<T>`](https://learn.microsoft.com/dotnet/api/system.span-1) es una referencia más una longitud: una ventana sobre un array, una cadena, memoria nativa o la pila. Para ser seguro, nunca debe sobrevivir a la memoria a la que apunta, así que es un [`ref struct`](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct): un struct que solo puede vivir en la pila. El compilador lo impone con una familia de errores. Un `ref struct` no puede ser un campo de una clase:

```csharp
public class FretBuffer
{
    private Span<int> _frets; // un Span solo puede vivir en la pila
}
```

```text
l1_ref_struct_field.cs(4,13): error CS8345: Field or auto-implemented property cannot be of type 'Span<int>' unless it is an instance member of a ref struct.
```

No puede capturarlo una lambda, que lo guardaría en un objeto de clausura en el montón:

```csharp
public static Func<int> Sum(Span<int> frets) => () => frets[0] + frets[1];
```

```text
l1_span_lambda.cs(4,59): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
l1_span_lambda.cs(4,70): error CS9108: Cannot use parameter 'frets' that has ref-like type inside an anonymous method, lambda expression, query expression, or local function
```

No puede ser argumento de tipo de un tipo genérico que no lo permita expresamente. Desde C# 13, un parámetro genérico puede declarar `allows ref struct`; `List<T>` no lo hace, porque guarda sus elementos en un array:

```csharp
public static List<Span<int>> Shapes = [];
```

```text
l1_span_type_argument.cs(4,35): error CS9244: The type 'Span<int>' may not be a ref struct or a type parameter allowing ref structs in order to use it as parameter 'T' in the generic type or method 'List<T>'
```

Y la memoria obtenida con [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc) no puede salir del método que la asignó:

```csharp
public static Span<int> Empty()
{
    Span<int> frets = stackalloc int[6];
    return frets; // la memoria desaparece cuando el método retorna
}
```

```text
l1_stackalloc_escape.cs(7,16): error CS8352: Cannot use variable 'frets' in this context because it may expose referenced variables outside of their declaration scope
```

Cuando los datos deben sobrevivir al marco de pila, a través de un `await` o en un campo, usa [`Memory<T>`](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), un struct normal que puede guardarse en cualquier sitio y convertirse en un `Span<T>` allí donde se hace el trabajo.

Dentro de esas reglas, los spans eliminan asignaciones. Un voicing de guitarra se escribe a menudo como seis trastes, `x 3 2 0 1 0` para un acorde de do mayor abierto. La primera versión divide la cadena; la segunda la trocea con [`MemoryExtensions.Split`](https://learn.microsoft.com/dotnet/api/system.memoryextensions.split), que devuelve rangos, analiza cada trozo con `int.Parse(ReadOnlySpan<char>)` y guarda los trastes en seis `int` en la pila ([`Lesson1.cs#L126-L155`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L126-L155)).

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

Los 216 bytes son el `string[]` de seis elementos (24 + 6 × 8 = 72 bytes) y seis cadenas de un carácter de 24 bytes cada una. Para un solo voicing no es nada; para los millones de voicings que enumera una búsqueda de acordes, es trabajo para el recolector de basura, y la lección 2 lo mide.

## Una copia por llamada en GA

Los objetos de valor de GA exponen sus valores posibles como un span. Para `PitchClass`, `ItemsSpan` devuelve un array en caché ([`ValueObjectCache.cs#L45-L49`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectCache.cs#L45-L49)). `PitchClassSetId` tiene su propia implementación ([`PitchClassSetId.cs#L59`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L59), [`#L70-L71`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)):

```csharp
public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items is PitchClassSetId[] arr ? arr : [.. Items];

public static IReadOnlyCollection<PitchClassSetId> Items { get; } =
    [.. Enumerable.Range(_minValue, _maxValue - _minValue + 1).Select(i => new PitchClassSetId(i))];
```

La intención es clara: devolver el array sin copiarlo. Pero `Items` se inicializa con una expresión de colección cuyo destino es la interfaz `IReadOnlyCollection<T>`, y para ese destino el compilador es libre de construir un tipo propio ([expresiones de colección, traducción a interfaces no mutables](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md#non-mutable-interface-translation)). Por tanto, la prueba `Items is PitchClassSetId[]` siempre es falsa, y cada lectura de `ItemsSpan` copia 4,096 identificadores en un array nuevo:

```text
== GA: ItemsSpan of two value objects
PitchClass.ItemsSpan: 12 items, 0 bytes
PitchClassSetId.ItemsSpan: 4096 items, 16408 bytes
PitchClassSetId.Items is <>z__ReadOnlyList`1
```

16,408 bytes son 24 bytes de encabezado del array más 4,096 × 4. El código compila, se ejecuta y devuelve los valores correctos; solo una medición revela el coste. La solución es el ejercicio 3.

## Si conoces Spring y Reactor

Esta lección casi no tiene equivalente en Java, y eso es justamente lo que enseña. En la JVM todo tipo que declaras es un tipo por referencia: `PitchClass`, que aquí ocupa 4 bytes en línea, allí sería un objeto con cabecera, y una lista de ellos una lista de referencias. C# te da herramientas para mantener los valores fuera del montón; Java le pide a su recolector que los haga desaparecer pronto, algo que compara la lección 2.

| C# | Java, Spring y Reactor |
|---|---|
| `struct`, `readonly record struct`: 4 bytes, en línea, sin cabecera | ningún tipo por valor definido por el usuario; un `record` es un objeto corriente del montón. Los objetos valor del [proyecto Valhalla](https://openjdk.org/projects/valhalla/) son una *versión preliminar* prevista para el JDK 28 ([JEP 401](https://openjdk.org/jeps/401)), así que no están en ningún JDK publicado |
| el boxing es una instrucción `box`, que el JIT a veces elimina | el autoboxing llama a `Integer.valueOf` ([restricciones de los genéricos](https://docs.oracle.com/javase/tutorial/java/generics/restrictions.html)); el análisis de escape de HotSpot, `-XX:+DoEscapeAnalysis`, [activado por defecto](https://docs.oracle.com/en/java/javase/25/docs/specs/man/java.html), puede eliminar la asignación |
| los genéricos están reificados: un `PitchClass[]` contiene valores de 4 bytes | los genéricos se borran ([JLS §4.6](https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html)): una `List<Integer>` contiene referencias a objetos boxeados, y `List<int>` ni siquiera compila |
| `Span<T>` sobre un arreglo, una cadena, memoria nativa o la pila | [`ByteBuffer`](https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/nio/ByteBuffer.html), el [`ByteBuf`](https://netty.io/wiki/reference-counted-objects.html) de Netty, el [`DataBuffer`](https://docs.spring.io/spring-framework/reference/core/databuffer-codec.html) de WebFlux: objetos, y ninguno es una ventana sobre un `String` |
| `stackalloc` | nada equivalente. `ByteBuffer.allocateDirect` asigna fuera del montón, y su Javadoc lo reserva «primarily for large, long-lived buffers» |
| CS8345, CS8352 y los demás errores de seguridad de referencias: el compilador demuestra que un span no sobrevive a su memoria | un conteo de referencias comprobado en ejecución: `release()`, `IllegalReferenceCountException`, y un detector de fugas que muestrea alrededor del 1 % de las asignaciones |
| `Memory<T>` para los datos que cruzan un `await` | un búfer del pool retenido más allá de un operador, liberado por quien lo lee al final |
| una copia defensiva silenciosa al llamar a un método sobre un parámetro `in` | no ocurre: los objetos siempre se pasan por referencia |

La fila que cuesta tiempo de depuración es la propiedad. Un `Span<T>` no posee nada, y el compilador rechaza el código que lo dejaría sobrevivir a su memoria. Un `PooledDataBuffer` empieza con un conteo de referencias de 1, que `retain()` y `release()` mueven, y la documentación de Spring es explícita: «special care must be taken to ensure buffers are released since they may be pooled», con una regla por caso: liberar cada búfer leído y añadir `doOnDiscard(DataBuffer.class, DataBufferUtils::release)` cuando un operador pueda descartar elementos. Esa tarea solo es tuya si manejas `DataBuffer` directamente: si decodificas a un `String` o a un record, el códec ya los liberó. Las dos plataformas resuelven el mismo problema, una con un sistema de tipos y otra con disciplina y un detector de fugas.

El `ItemsSpan` de GA también tiene forma Java. Una propiedad que devuelve `collection.toArray()` copia en cada lectura, devuelve los valores correctos y ninguna prueba lo nota; la medición que encontró aquí los 16 408 bytes es la que hay que ejecutar allí.

## Ejercicios

1. Predice `Unsafe.SizeOf` de la tupla `(bool, int, bool)`, de un struct con los campos `bool Muted; int Fret; bool Barre;` en ese orden, y del mismo struct marcado con [`[StructLayout(LayoutKind.Auto)]`](https://learn.microsoft.com/dotnet/api/system.runtime.interopservices.layoutkind).
2. Haz que el compilador detecte el incremento perdido de `ByIn`: ¿qué cambias en `Counter`, y qué dice entonces el compilador sobre `Increment`?
3. Reescribe `PitchClassSetId.ItemsSpan` para que no asigne memoria, y comprueba que devuelve los mismos identificadores.

<details>
<summary>Soluciones</summary>

1. El struct en el orden de declaración ocupa **12** bytes: `bool` (1 byte, 3 de relleno), `int` (4), `bool` (1, 3 de relleno), porque el tamaño de un struct es un múltiplo de la alineación de su campo más grande. Con `LayoutKind.Auto`, el runtime puede reordenar los campos: `int`, `bool`, `bool`, 2 de relleno, **8** bytes. `ValueTuple` se declara con `LayoutKind.Auto`, así que la tupla también ocupa **8** bytes. La disposición secuencial es la predeterminada de C# para los structs porque coincide con el código nativo en la interoperabilidad; para un struct que nunca pasa al código nativo, `Auto` puede ahorrar espacio.

    ```text
    1. (bool, int, bool) 8 bytes, SequentialFlags 12, AutoFlags 8
    ```

2. Marca `Increment` como miembro `readonly`, o el struct entero como `readonly struct`. Entonces el compilador rechaza el incremento dentro del método, y la llamada sobre un parámetro `in` ya no necesita una copia defensiva. Para conservar un método que modifica el valor, recibe el parámetro por `ref`.

    ```csharp
    public readonly void Increment() => Value++;
    ```

    ```text
    l1_readonly_member.cs(6,41): error CS1604: Cannot assign to 'Value' because it is read-only
    ```

3. Guarda los identificadores en un array una sola vez y devuelve el array como span: la conversión de `T[]` a `ReadOnlySpan<T>` no copia ([`Lesson1.cs#L94-L100`](https://github.com/spareilleux/learn/blob/8ba378e7ea22a64a57b3e45b45afa4c85afa85a3/code/csharp-advanced/Advanced/Lesson1.cs#L94-L100)). En el propio GA, declarar `Items` con un array concreto, o pasar por `ValueObjectUtils<PitchClassSetId>.ItemsSpan` como los demás objetos de valor, conseguiría lo mismo.

    ```csharp
    private static readonly PitchClassSetId[] Items = [.. PitchClassSetId.Items];

    public static ReadOnlySpan<PitchClassSetId> ItemsSpan => Items;
    ```

    ```text
    3. cached ItemsSpan: 4096 items, 0 bytes, same ids True
    ```

</details>

## Puntos clave

- Un objeto de 64 bits cuesta al menos 24 bytes: el encabezado, el puntero a la tabla de métodos y luego los campos, redondeado a un múltiplo de 8. `Unsafe.SizeOf<T>()` da el tamaño en línea; `GC.GetAllocatedBytesForCurrentThread()` alrededor de una llamada ya calentada da el coste en el montón.
- El IL muestra el boxing como `box`. Las restricciones genéricas llaman a través de `constrained.` sin boxing, y las cadenas interpoladas dan formato sin boxing.
- El JIT puede eliminar un boxing que pide el IL: siempre en el caso de `box` seguido de `unbox.any` y, en el código optimizado, siempre que el objeto con boxing no escape del método. Mide el código optimizado, no el IL.
- Llamar a un método sobre un parámetro `in` o sobre un campo `readonly` de un struct mutable lo ejecuta sobre una copia silenciosa. Haz `readonly` el struct o el método.
- `Span<T>` y `stackalloc` analizan y trocean sin asignar memoria. Los errores de seguridad de referencias del compilador (CS8345, CS8352, CS9108, CS9244, CS8168) son los que les impiden apuntar a memoria que ya no existe; `Memory<T>` es para los datos que deben sobrevivir al marco de pila.
- Una expresión de colección asignada a una interfaz no es un array. Por eso, `PitchClassSetId.ItemsSpan` de GA copia 16 KB en cada llamada.

## Fuentes

- Microsoft Learn: [`Unsafe.SizeOf`](https://learn.microsoft.com/dotnet/api/system.runtime.compilerservices.unsafe.sizeof), [Boxing y unboxing](https://learn.microsoft.com/dotnet/csharp/programming-guide/types/boxing-and-unboxing), [Parámetros de método](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/method-parameters), [Tipos de estructura ref](https://learn.microsoft.com/dotnet/csharp/language-reference/builtin-types/ref-struct), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc), [Instrucciones de uso de Memory y Span](https://learn.microsoft.com/dotnet/standard/memory-and-spans/memory-t-usage-guidelines), [Expresiones de colección](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/collection-expressions).
- Novedades del runtime: [.NET 9, asignación en la pila de objetos con boxing](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-9/runtime#object-stack-allocation-for-boxes), [.NET 10, asignación en la pila](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-10/runtime#stack-allocation).
- [ECMA-335](https://www.ecma-international.org/publications-and-standards/standards/ecma-335/), partición III, para `box`, `unbox.any` y el prefijo `constrained.`.
- La propuesta del lenguaje C# para las [expresiones de colección](https://github.com/dotnet/csharplang/blob/main/proposals/csharp-12.0/collection-expressions.md).
