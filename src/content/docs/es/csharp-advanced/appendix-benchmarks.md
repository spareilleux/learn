---
title: "Apéndice 1: cinco optimizaciones, demostradas y luego medidas"
description: Cinco miembros de Guitar Alchemist reescritos con rotaciones, popcounts y tablas de consulta — primero una comprobación exhaustiva de la equivalencia sobre los 4096 conjuntos de clases de altura, después BenchmarkDotNet, un defecto documentado que la versión rápida no tiene permitido corregir, y un benchmark que hubo que tirar porque medía el JIT y no el código.
sidebar:
  label: "Apéndice 1: optimizaciones demostradas"
  order: 90
---

Un benchmark por sí solo no demuestra nada. «Mil veces más rápido» es una afirmación sobre dos programas, y solo resulta interesante si son el *mismo* programa: la forma más fácil de ganar un benchmark es dejar de hacer discretamente una parte del trabajo.

Este apéndice toma cinco miembros de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), reescribe cada uno de ellos y hace la demostración antes que la medición. Los cinco reciben un **conjunto de clases de altura**: un subconjunto de las doce clases de altura, es decir, un número de 12 bits, es decir, un dominio de entrada de 4096 valores en total. No hay nada que muestrear ni nada que discutir. El programa comprueba que la reescritura devuelve lo que devuelve GA para **cada** entrada, y la CI lo ejecuta en Linux, Windows y macOS en cada push. Solo entonces merece la pena leer los tiempos.

La medición acabó necesitando el mismo escepticismo que el código. La primera versión de los benchmarks llamaba a cada miembro una vez y anunciaba que el `IsClusterFree` rápido se ejecutaba en 0,0107 ns — una veinticincoava parte de un ciclo, que no es una velocidad sino un síntoma. Esa historia está en [las mediciones](#las-mediciones), al final, y es la razón por la que cada cifra de más abajo es un barrido del dominio entero.

Los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Ejecutar el apéndice

```bash
bash code/csharp-advanced/check.sh                                   # todas las lecciones, comparadas con expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # solo la demostración, después de check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*NormalFormBenchmarks*"
```

Las reescrituras están en [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), la demostración en [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), las mediciones en [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Miembro | El movimiento | Lo que la demostración debe garantizar |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | sacar un invariante del bucle y luego eliminar el bucle | nada: es una ganancia limpia |
| 2 | `PitchClassSet.IntervalClassVector` | contar pares con `PopCount` y luego precalcular los 4096 | un defecto aritmético documentado que hay que **conservar** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | eliminar un diccionario que nadie lee | un empate resuelto por la estabilidad del orden, a reproducir exactamente |
| 4 | `PitchClassSet.ToNormalForm` | rotar bits en lugar de construir conjuntos ordenados | una regla de compacidad que no es la de los manuales |
| 5 | `PitchClassSetId.PrimeForm` | la misma aritmética, y después una tabla | nada: ya era aritmética de bits |

Todo se apoya en una representación, que conviene enunciar una vez. El bit *p* del número vale 1 cuando la clase de altura *p* está en el conjunto. Transponer *n* semitonos es rotar esos doce bits *n* posiciones: no se añade ni se quita nada, el anillo gira. «Cuántas clases de altura cumplen X» es un recuento de bits, o sea una instrucción. Y el dominio es lo bastante pequeño como para tabular al arrancar cualquier función de un conjunto.

## 1. Un bucle que hace doce veces lo mismo

Un conjunto está *libre de clústeres* cuando no contiene tres clases de altura cromáticamente adyacentes, contadas alrededor del círculo. La versión de GA:

```csharp
public bool IsClusterFree
{
    get
    {
        for (var i = 0; i < 12; i++)
        {
            var extended = Value | (Value << 12);
            if (((extended >> i) & 7) == 7)
            {
                return false;
            }
        }

        return true;
    }
}
```

Hay dos cosas mal en ella, y solo una es la evidente.

`extended` no depende de `i`. Se reconstruye en cada iteración —un desplazamiento y un OR, doce veces, para un valor que nunca cambia—. Puede que el JIT lo saque del bucle; lo que importa es que el código fuente lo pide.

El problema más interesante es el bucle mismo. `((extended >> i) & 7) == 7` pregunta «¿están los bits *i*, *i+1* e *i+2* todos a 1?», y la respuesta para los doce *i* a la vez cabe en una expresión:

```csharp
const int Mask12 = 0xFFF;

// Rotación a la derecha de una palabra de 12 bits: el bit i del resultado es el bit i + n de la entrada, módulo 12
static int Rotr12(int value, int n) => ((value >> n) | (value << (12 - n))) & Mask12;

public static bool IsClusterFree(int set) => (set & Rotr12(set, 1) & Rotr12(set, 2)) == 0;
```

`Rotr12(v, 1)` lleva el bit *i + 1* a donde estaba el bit *i*, y `Rotr12(v, 2)` lleva allí el bit *i + 2*. El bit *i* del AND es, por tanto, exactamente la prueba de GA para ese *i*, y el conjunto está libre de clústeres cuando no sobrevive ningún bit. Dos rotaciones, dos AND, una comparación con cero, ninguna bifurcación.

| Método | Los 4096 conjuntos | Por conjunto | Ratio |
|---|---|---|---|
| `Ga` | 9,582 µs | 2,34 ns | 1,00 |
| `Fast` | 2,378 µs | 0,58 ns | 0,25 |

**Cuatro veces, no treinta.** Este es el miembro cuya medición honesta resulta menos halagüeña, y merece detenerse en él: el mismo par de métodos, medido llamada a llamada, anunciaba 3,25 ns frente a 0,0107 ns y un ratio de 0,003. Ninguna de las dos versiones asigna memoria. El bucle de GA sale pronto en cuanto encuentra un clúster —2.597 de los 4096 conjuntos tienen uno—, así que de media hace bastantes menos de doce iteraciones, y el predictor de saltos lo aprende.

## 2. Contar pares, y un defecto que debe sobrevivir

Un **vector de clases de intervalo** cuenta, para cada clase de intervalo de 1 a 6, cuántos pares no ordenados del conjunto están a esa distancia. Es la huella digital de la [lección 4 del curso de teoría musical](../../music-theory-ga/04-set-classes/), y en GA es una propiedad sin caché:

```csharp
public IntervalClassVector IntervalClassVector => _pitchClassesSet.ToIntervalClassVector();
```

`ToIntervalClassVector` construye un *producto cartesiano normado* genérico, y construir eso, antes de haber mirado un solo par, hace esto:

```csharp
Elements = [.. elements];
Base = new(Elements.Count);
Count = BigInteger.Pow(Base, length);
IndexFormat = Count > 0 ? $"D{(int)Math.Floor(BigInteger.Log10(Count) + 1)}" : "D1";

_indexByElement = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.o, t => t.i);
_elementByIndex = Elements.Select((o, i) => (o, i)).ToImmutableDictionary(t => t.i, t => t.o);
```

Un `BigInteger.Pow`, un `BigInteger.Log10`, un `string.Format` y dos `ImmutableDictionary` — para contar seis números pequeños. Después se enumeran n² pares, se filtran a través de delegados, se agrupan en un `ILookup` y se pliegan en un `ImmutableSortedDictionary`; y leer la propiedad `Vector` del vector resultante reconstruye *otro*, porque también se calcula en cada acceso.

Las seis cuentas son tres operaciones cada una. Para la clase de intervalo `ic`, los pares son las clases de altura *p* tales que *p* y *p + ic* están ambas presentes —`v & Rotr12(v, ic)`— y [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount) las cuenta:

```csharp
public static int IntervalClassVectorId(int set)
{
    var value = 0;
    for (var ic = 1; ic <= 6; ic++)
    {
        // El bit p del AND vale 1 cuando p y p + ic están ambas en el conjunto: un bit por par
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));

        // El tritono es su propio complemento: el AND contó cada par por los dos extremos
        if (ic == 6) count /= 2;

        // El empaquetado de GA: desplazar los dígitos un lugar en base 12 y sumar esta cuenta
        value = value * 12 + count;
    }
    return value;
}
```

Y como el dominio tiene 4096 valores, todo esto puede hacerse una sola vez, al arrancar:

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Método | Los 4096 conjuntos | Por conjunto | Asignado, por conjunto | Ratio |
|---|---|---|---|---|
| `Ga` | 18,747 ms | 4.577 ns | 13.513 B | 1,000 |
| `Computed` | 15,480 µs | 3,78 ns | — | 0,001 |
| `Table` | 828,4 ns | 0,20 ns | — | 0,00004 |

**Leer esta propiedad para los 4096 conjuntos asigna 55 MB.** Mil veces más rápido calculando en cada llamada, veintidós mil desde la tabla, y la asignación baja a cero. Esa última cifra es la que importa en un servicio: el propio constructor estático de `PitchClassSet` construye un índice de los 4096 conjuntos por esta propiedad, y `SetClass.ToString()` la llama, de modo que cada línea de registro que nombraba una clase de conjuntos lo pagaba.

### La parte que convierte esto en una demostración

`IntervalClassVectorId` empaqueta las seis cuentas como dígitos en base 12, con la cuenta 1 como más significativa. Un dígito en base 12 va de 0 a 11. El agregado cromático —las doce clases de altura— tiene cinco cuentas que valen exactamente **12**, que no caben, y que acarrean:

```text
== The defect the fast version has to keep, not fix
chromatic aggregate          id                 decoded
GA                           3257430            <1 1 1 1 0 6>
the fast version             3257430            <1 1 1 1 0 6>
```

El vector verdadero es `<12 12 12 12 12 6>`. GA documenta el empaquetado en los comentarios del propio tipo, junto con un error anterior en el que un literal en base 10 escrito a mano se decodificaba como un vector equivocado en cuanto la codificación pasó a base 12.

Así que la reescritura tiene que elegir, y solo una de las dos opciones es una optimización. Empaquetar las cuentas *correctamente* cambiaría el identificador del conjunto 4095 —y `ProgrammaticForteCatalog` ordena cada cardinalidad por ese identificador para asignar los números de Forte, de modo que los números de Forte del catálogo se desplazarían—. Eso es un cambio de comportamiento disfrazado de cambio de rendimiento. La reescritura reproduce el acarreo, la comprobación exhaustiva lo confirma, y el catálogo se comprueba aparte:

```text
== Forte numbering is unchanged
set classes                  224                224 vector ids identical
distinct Forte numbers       224
```

Corregir el empaquetado es buena idea. Es un cambio *distinto*, con su propia migración, y no pertenece a un commit cuyo mensaje dice «más rápido».

## 3. Un diccionario que nadie lee

`ClosestDiatonicKey` responde a «cuál de las 30 tonalidades comparte más notas con este conjunto». Su implementación empieza así:

```csharp
var dict = new Dictionary<Key, IReadOnlyCollection<PitchClass>>();
foreach (var key in Key.Items)
{
    var accidentedKeyNotes = key.Notes.Where(note => note.Accidental != null);
    var accidentedPitchClasses = accidentedKeyNotes.Select(note => note.PitchClass).ToImmutableArray();

    dict.Add(key, accidentedPitchClasses);
}
```

El diccionario se pasa a `IdentifyClosestKey`, que lo desestructura como `foreach (var (key, _) in items)`. **Los valores nunca se leen.** Se construyen treinta `ImmutableArray`, cada uno a partir de un filtro y una proyección sobre una colección de notas reconstruida para la ocasión, y se tiran.

Por debajo, `Key.Items` es una propiedad, no un campo: cada acceso concatena las 15 tonalidades mayores y las 15 menores y materializa una nueva `ImmutableList`, y el método la toca dos veces. `key.Notes` también reconstruye su colección en cada acceso. `IdentifyClosestKey` asigna después, por tonalidad, una `List`, una `ImmutableList`, dos envoltorios imprimibles y una `ImmutableList` ordenada — y de todo ello usa un solo número, `Matches.Count`.

El cálculo entero se reduce, por tonalidad, a un AND y un `PopCount` contra una máscara de 12 bits precalculada:

```csharp
static readonly (Key Key, int Mask, bool IsMinor)[] Keys =
    [.. Key.Items.Select(key => (key, Mask(key), key.KeyMode == KeyMode.Minor))];

static int Mask(Key key) => key.Notes.Aggregate(0, (mask, note) => mask | 1 << note.PitchClass.Value);

public static Key ClosestDiatonicKey(PitchClassSet set)
{
    // `Id` es una propiedad almacenada, no calculada: los doce bits del conjunto salen gratis
    var mask = set.Id.Value;

    // El desempate de GA: se espera que un conjunto cuya forma normal contiene la clase 3 sea menor.
    // Aquí es una lectura de array, porque la sección 4 tabuló la forma normal de todos los conjuntos.
    var expectMinor = (NormalFormMasks[mask] & (1 << 3)) != 0;

    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
        // El AND deja las notas de la tonalidad que el conjunto contiene: es el `Matches.Count` de GA
        var score = BitOperations.PopCount((uint)(mask & candidate.Mask));
        var expected = candidate.IsMinor == expectMinor;
        if (score > bestScore || (score == bestScore && expected && !bestExpected))
        {
            (best, bestScore, bestExpected) = (candidate, score, expected);
        }
    }
    return best.Key;
}
```

| Método | Los 4096 conjuntos | Por conjunto | Asignado, por conjunto | Ratio |
|---|---|---|---|---|
| `Ga` | 279,681 ms | 68,28 µs | 175.650 B | 1,000 |
| `Fast` | 173,2 µs | 42,3 ns | — | 0,001 |

**175 kilobytes para leer una propiedad**, y 719 MB para leerla en cada conjunto del dominio. Mil seiscientas veces más rápido, y nada asignado.

### El empate es toda la dificultad

GA elige su respuesta así:

```csharp
list.OrderByDescending(tuple => tuple.Matches.Count)
    .ThenByDescending(tuple => tuple.Key.KeyMode == expectedKeyMode)
    .First()
```

[LINQ to Objects ordena de forma estable](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), así que cuando varias tonalidades empatan en ambos criterios gana la que venía primero en `Key.Items` — las 15 mayores y después las 15 menores. Un bucle que sustituyera al que va ganando con `>=` en lugar de `>` devolvería una *tonalidad distinta* para muchos conjuntos: la misma cuenta, otro nombre. La reescritura recorre las tonalidades en ese mismo orden y solo sustituye ante una puntuación estrictamente mejor, y es la comprobación sobre los 4096 casos la que dice que eso es correcto.

Merece la pena ver cómo son las respuestas:

```text
== A few sets, so the tables above are readable
set                          interval-class vector closest key, cluster-free
major scale                  2741: <2 5 4 3 6 1> Key of Am, True
C major triad                145: <0 0 1 1 1 0> Key of Dm, True
whole tone                   1365: <0 6 0 6 0 3> Key of Cb, True
chromatic aggregate          4095: <1 1 1 1 0 6> Key of Abm, False
```

La tonalidad diatónica más cercana a la escala de do mayor es la menor, y la del acorde perfecto de do mayor es re menor. Ambas son erróneas, por una razón que la [lección 7 del curso de teoría musical](../../music-theory-ga/07-cadences-and-progressions/#encontrar-la-tonalidad-de-una-progresión) desmonta: un conjunto de clases de altura no tiene tónica. `C F G C` y `Am F C G` son el mismo conjunto, así que ninguna función del conjunto por sí solo puede elegir entre dos tonalidades relativas, y el desempate de GA lo intenta igualmente, leyendo un modo en una forma normal, que no puede codificar ninguno. El [apéndice C de ese curso](../../music-theory-ga/appendix-ga-findings/) lo registra como defecto 19.

La optimización reproduce todo eso, porque en eso consiste una optimización.

## 4. La forma normal, que se escondía dentro de la anterior

El párrafo anterior usaba `NormalFormMasks`, y es esa tabla la que hace que el `ClosestDiatonicKey` rápido no asigne nada. Antes de que existiera, la reescritura todavía llamaba a `set.ToNormalForm()`, y esa única llamada era la totalidad de los 16 KB que le quedaban.

El `ToNormalForm` de GA transpone el conjunto una vez por miembro, de modo que ese miembro quede en 0, y se queda con la transposición cuya secuencia de huecos circulares tiene el menor *hueco mayor menos hueco menor*, resolviendo los empates lexicográficamente sobre los huecos. Conviene releerlo, porque **no** es la forma normal de los manuales, que minimiza la amplitud de la primera clase de altura a la última; los propios comentarios de GA lo dicen. La reescritura debe reproducir la regla de GA, no la de los libros.

El coste no es la regla, es de qué está hecha la regla — un `ImmutableSortedSet` por rotación, dos `ImmutableArray` de huecos por comparación, una `List<PitchClass>` para el que va ganando y un `PitchClassSet` para la respuesta. Una transposición es una rotación y los huecos se leen en los bits, así que todo cabe en dos búferes de pila:

```csharp
public static int NormalFormMask(int set)
{
    if (set == 0) return 0;

    Span<int> gaps = stackalloc int[12];
    Span<int> bestGaps = stackalloc int[12];
    var count = BitOperations.PopCount((uint)set);
    var best = 0;
    var bestSpan = int.MaxValue;

    // Ascendente, porque GA enumera un ImmutableSortedSet y conserva la rotación que vio primero
    for (var member = 0; member < 12; member++)
    {
        if ((set & (1 << member)) == 0) continue;

        // Transponer para que este miembro caiga en 0 es rotar el conjunto `member` posiciones hacia abajo
        var rotation = Rotr12(set, member);
        Gaps(rotation, count, gaps);
        var span = Span(gaps, count);

        // Una amplitud menor siempre gana; a igual amplitud, la secuencia de huecos menor
        if (span > bestSpan) continue;
        if (span == bestSpan && !MoreCompact(gaps, bestGaps, count)) continue;

        best = rotation;
        bestSpan = span;
        gaps[..count].CopyTo(bestGaps);
    }

    return best;
}
```

Hay un detalle que merece conservarse aunque no cambie nada. GA mide cada hueco como `(pitchClasses[(i + 1) % n] - pitchClasses[i])`, así que para un conjunto de una sola nota el único hueco es la distancia del miembro a sí mismo: **0**, y no los doce semitonos que sugeriría un «hueco circular». La reescritura hace lo mismo, y la comprobación exhaustiva es lo que demuestra que la elección es gratuita: un conjunto de una nota tiene exactamente una rotación, así que nunca se hace ninguna comparación y ambas lecturas devuelven la misma respuesta para los doce. Es el tipo de cosa que conviene saber en lugar de suponer, y la única forma de saberlo es ejecutar todas las entradas.

| Método | Los 4096 conjuntos | Por conjunto | Asignado, por conjunto | Ratio |
|---|---|---|---|---|
| `Ga` | 11,085 ms | 2.706 ns | 6.657 B | 1,000 |
| `Computed` | 1,172 ms | 286 ns | — | 0,106 |
| `Table` | 834,5 ns | 0,20 ns | — | 0,00008 |

Fíjate en la distancia entre `Computed` y `Table` aquí. La reescritura solo es 9,5 veces más rápida que la de GA, porque a diferencia del vector de clases de intervalo sigue haciendo trabajo real en cada llamada — hasta doce rotaciones y una comparación lexicográfica. Eso es lo que hace que la tabla valga sus 16 KB: el coste no está solo en las asignaciones.

```text
== Normal form and prime form, on the same sets
set                          GA's normal form         prime form
major scale                  0 1 3 5 6 8 T            0 1 3 5 6 8 T
C major triad                0 3 8                    0 3 7
whole tone                   0 2 4 6 8 T              0 2 4 6 8 T
chromatic aggregate          0 1 2 3 4 5 6 7 8 9 T E  0 1 2 3 4 5 6 7 8 9 T E
```

La segunda fila es la regla de GA mostrándose a las claras: la forma normal del acorde perfecto de do mayor es `0 3 8`, mientras que su forma prima es `0 3 7`. Los huecos de `0 3 8` son 3, 5, 4 —una amplitud de 2— frente a 4, 3, 5 para `0 4 7`, también amplitud 2, y `3 5 4` gana el empate lexicográfico frente a `4 3 5`. Una forma normal de manual habría respondido `0 4 7`.

## 5. PrimeForm, que ya estaba bien

El `PitchClassSetId.PrimeForm` de GA es el único miembro de aquí que no necesitaba replantearse. Ya es aritmética pura sobre el identificador —el menor de las doce transposiciones y de las doce transposiciones de la inversión— y no asigna nada:

```csharp
var min = Value;
var inverse = Inverse;
for (var i = 0; i < 12; i++)
{
    var t = Transpose(i).Value;
    if (t < min) min = t;

    var ti = inverse.Transpose(i).Value;
    if (ti < min) min = ti;
}
```

Lo que paga es el envoltorio. `Inverse` es una propiedad que ejecuta un bucle de doce iteraciones para reflejar los bits; `Transpose` se llama 24 veces, y cada llamada construye un `PitchClassSetId` mediante un constructor que comprueba el rango de su argumento. Escribir la misma aritmética sobre `int` pelados es 1,8 veces más rápido, y la tabla 415 veces:

| Método | Los 4096 conjuntos | Por conjunto | Ratio |
|---|---|---|---|
| `Ga` | 347,4 µs | 84,8 ns | 1,000 |
| `Computed` | 193,9 µs | 47,3 ns | 0,562 |
| `Table` | 836,9 ns | 0,20 ns | 0,002 |

Un factor de 1,8 por reescribir un método que ya era correcto es el techo honesto de «microoptimizar la aritmética», y conviene ponerlo al lado del 1.600× de la sección 3. Las grandes ganancias de este apéndice no vinieron de trucos con bits. Vinieron de eliminar trabajo que nunca hizo falta: un diccionario que nadie lee, un producto cartesiano construido para contar seis números, un conjunto ordenado por rotación.

## Lo que imprime la comprobación exhaustiva

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
ToNormalForm                 4096/4096          identical
PrimeForm                    4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Cinco líneas, y son la razón por la que se pueden citar los tiempos anteriores. `ClosestDiatonicKey` se compara por la forma de *texto* de la tonalidad y no por igualdad de record, para que un cambio en cómo `Key` se compara consigo misma no pueda ocultar una diferencia.

## Las mediciones

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, una clase de benchmarks cada vez en una máquina por lo demás inactiva:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

### El benchmark que hubo que tirar

La primera versión de estos benchmarks hacía lo evidente: una llamada por método `[Benchmark]`, sobre la escala mayor. Anunciaba esto para `IsClusterFree`:

```text
| Method | Mean      | Ratio |
| Ga     | 3.2472 ns |  1.000 |
| Fast   | 0.0107 ns |  0.003 |
```

0,0107 ns en un procesador a 3,7 GHz es una veinticincoava parte de un ciclo. Ningún método se ejecuta en una veinticincoava parte de un ciclo. El argumento era una `const`, así que el JIT plegó la llamada entera en un literal, y lo que se estaba midiendo era el plegado.

Un campo `static readonly` tampoco habría ayudado: el JIT los promueve a constantes en cuanto la compilación por niveles se estabiliza. Convertirlo en un `static int` mutable eliminó el plegado y aun así produjo 0,0474 ns con una **mediana de 0,0000 ns**: por debajo de la resolución de la técnica, porque BenchmarkDotNet resta el coste de un método vacío y no quedaba nada.

Por eso cada benchmark barre el dominio entero, acumulando un valor que el JIT no puede dar por muerto:

```csharp
[Benchmark]
public int Fast()
{
    var count = 0;
    for (var id = 0; id < 4096; id++)
    {
        if (GaFast.IsClusterFree(id)) count++;
    }
    return count;
}
```

El contador del bucle es la entrada, así que nada puede plegarse; cada método tiene milisegundos o microsegundos de trabajo real; y las columnas «por conjunto» de más arriba son la media dividida entre 4096. Que las tres filas `Table` caigan en 828,4 ns, 834,5 ns y 836,9 ns —el mismo número tres veces, para tres tablas distintas— es el suelo de la técnica: una lectura de array con comprobación de límites y una iteración de bucle, unos 0,20 ns, incluidos en cada cifra de este apéndice.

Esto no es una nota al pie. El benchmark descartado habría publicado «treinta y una veces más rápido» para un miembro que lo es cuatro veces, y habría parecido más impresionante que todo lo que el apéndice encontró de verdad.

### Las asignaciones

Estas no tienen nada de estadístico:

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey                   0 bytes
# GA   ToNormalForm                     8,000 bytes
# fast NormalFormMask                       0 bytes
# GA   PrimeForm                        1,704 bytes
# fast PrimeFormIds[id]                     0 bytes
```

Vienen de [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) alrededor de una única llamada, después de una llamada de calentamiento que ha ejecutado los constructores estáticos — la técnica de la [lección 1](../01-memory-values-and-spans/). Dependen lo bastante de la máquina como para imprimirse con el prefijo `# ` y quedar fuera de la comparación, y son lo bastante estables como para merecer imprimirse. Son mayores que las cifras «por conjunto» de las tablas, que son las medias de `[MemoryDiagnoser]` sobre todo el barrido con su propio sobrecoste restado; una llamada aislada, algo fría, cuesta un poco más que la media de 4096.

La CI ejecuta cada clase de benchmarks con `--job Dry`, que comprueba que siguen funcionando y no mide nada, porque los tiempos de un runner compartido son ruido.

## Puntos clave

- El dominio de entrada de un conjunto de 12 bits tiene 4096 valores. Cuando el dominio es así de pequeño, «lo he probado» debería significar *entero*, y esa prueba pertenece a la CI, junto al benchmark.
- Una reescritura que devuelve otra respuesta no es la versión rápida de nada. El acarreo en base 12 de GA es un defecto real y la versión rápida lo reproduce; el hueco nulo de un conjunto de una sola nota, también.
- **Mide tu medición.** Una cifra por debajo del ciclo no es un resultado, es un error en la medición: un argumento `const` o `static readonly` se pliega, y la resta del sobrecoste de BenchmarkDotNet se lleva el resto. Barre un dominio, acumula un resultado y divide.
- Las grandes ganancias vinieron de eliminar trabajo, no de trucos con bits: un diccionario cuyos valores nunca se leen, un producto cartesiano construido para contar seis números, un conjunto ordenado por rotación. Reescribir aritmética que ya era correcta dio 1,8×.
- Una propiedad sin caché es un método con un nombre engañoso. `IntervalClassVector` y `Key.Items` reconstruyen todo en cada acceso, y ambas se leen dentro de bucles en otras partes de GA.

## Fuentes

- BenchmarkDotNet: [cómo funciona](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [buenas prácticas](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger), [`stackalloc`](https://learn.microsoft.com/dotnet/csharp/language-reference/operators/stackalloc).
- Guitar Alchemist en el commit `a826864`: [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57) y su [`PrimeForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L133-L156), [`PitchClassSet.ToNormalForm`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L412-L475) y [`FindClosestDiatonicKey2`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- El código del curso: [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- El mismo código leído como música y no como rendimiento: [Teoría musical para Guitar Alchemist](../../music-theory-ga/), en particular la [lección 4](../../music-theory-ga/04-set-classes/), la [lección 7](../../music-theory-ga/07-cadences-and-progressions/) y [su apéndice C](../../music-theory-ga/appendix-ga-findings/).
