---
title: "Apéndice 1: tres optimizaciones, demostradas y luego medidas"
description: Tres miembros de Guitar Alchemist reescritos con rotaciones, popcounts y una tabla de consulta — primero una comprobación exhaustiva de la equivalencia sobre los 4096 conjuntos de clases de altura, después BenchmarkDotNet, y un defecto documentado que la versión rápida no tiene permitido corregir.
sidebar:
  label: "Apéndice 1: optimizaciones demostradas"
  order: 90
---

Un benchmark por sí solo no demuestra nada. «Dos mil veces más rápido» es una afirmación sobre dos programas, y solo resulta interesante si son el *mismo* programa: la forma más fácil de ganar un benchmark es dejar de hacer discretamente una parte del trabajo.

Este apéndice toma tres miembros de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga), reescribe cada uno de ellos y hace la demostración antes que la medición. Los tres reciben un **conjunto de clases de altura**: un subconjunto de las doce clases de altura, es decir, un número de 12 bits, es decir, un dominio de entrada de 4096 valores en total. No hay nada que muestrear ni nada que discutir. El programa comprueba que la reescritura devuelve lo que devuelve GA para **cada** entrada, y la CI lo ejecuta en Linux, Windows y macOS en cada push. Solo entonces merece la pena leer los tiempos.

Los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).

## Ejecutar el apéndice

```bash
bash code/csharp-advanced/check.sh                                   # todas las lecciones, comparadas con expected/
dotnet run --project code/csharp-advanced/Advanced -c Release -- a1  # solo la demostración, después de check.sh
cd code/csharp-advanced
dotnet run -c Release --project Benchmarks -- --filter "*IntervalClassVectorBenchmarks*"
```

Las reescrituras están en [`Advanced/GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), la demostración en [`Advanced/Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), las mediciones en [`Benchmarks/GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs).

| | Miembro | El movimiento | Lo que la demostración debe garantizar |
|---|---|---|---|
| 1 | `PitchClassSetId.IsClusterFree` | sacar un invariante del bucle y luego eliminar el bucle | nada: es una ganancia limpia |
| 2 | `PitchClassSet.IntervalClassVector` | contar pares con `PopCount` y luego precalcular los 4096 | un defecto aritmético documentado que hay que **conservar** |
| 3 | `PitchClassSet.ClosestDiatonicKey` | eliminar un diccionario que nadie lee | un empate resuelto por la estabilidad del orden, a reproducir exactamente |

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

| Método | Media | Ratio |
|---|---|---|
| `Ga` | 3,5344 ns | 1,00 |
| `Fast` | 0,1131 ns | 0,03 |

Treinta y una veces más rápido, y 0,11 ns está por debajo del coste de una sola predicción errónea de salto: el método se ha disuelto prácticamente dentro de quien lo llama. Ninguna de las dos versiones asigna memoria.

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
        var count = BitOperations.PopCount((uint)(set & Rotr12(set, ic)));
        if (ic == 6) count /= 2;
        value = value * 12 + count;
    }
    return value;
}
```

La clase de intervalo 6 se divide entre dos porque *p* y *p + 6* nombran el mismo par visto desde ambos extremos. Y como el dominio tiene 4096 valores, todo esto puede hacerse una sola vez, al arrancar:

```csharp
public static readonly int[] IntervalClassVectorIds =
    [.. Enumerable.Range(0, 4096).Select(IntervalClassVectorId)];
```

| Método | Media | Asignado | Ratio |
|---|---|---|---|
| `Ga` | 5.518,86 ns | 16.304 B | 1,00 |
| `Computed` | 2,62 ns | — | 0,0005 |
| `Table` | 0,0799 ns | — | 0,00001 |

Dos mil veces más rápido calculando en cada llamada, sesenta y nueve mil veces desde la tabla, y dieciséis kilobytes de asignación por lectura de propiedad pasan a ser cero. Esa última cifra es la que importa en un servicio: el propio constructor estático de `PitchClassSet` construye un índice de los 4096 conjuntos por esta propiedad, y `SetClass.ToString()` la llama, de modo que cada línea de registro que nombraba una clase de conjuntos costaba 16 KB.

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
    // El desempate de GA: se espera que un conjunto cuya forma normal contiene la clase 3 sea menor
    var normalForm = set.IsNormalForm ? set : set.ToNormalForm();
    var expectMinor = normalForm.Contains(Note.Chromatic.DSharpOrEFlat.PitchClass);

    var mask = set.Aggregate(0, (bits, pitchClass) => bits | 1 << pitchClass.Value);
    var best = Keys[0];
    var bestScore = -1;
    var bestExpected = false;
    foreach (var candidate in Keys)
    {
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

| Método | Media | Asignado | Ratio |
|---|---|---|---|
| `Ga` | 68,211 µs | 175,66 KB | 1,00 |
| `Fast` | 6,195 µs | 15,69 KB | 0,09 |

**175 kilobytes para leer una propiedad.** Once veces más rápido y once veces más ligero — y los 15,69 KB restantes no vienen de la búsqueda de tonalidad: son de `ToNormalForm()`, llamado para decidir si esperar una respuesta mayor o menor, e intacto aquí. Es el siguiente candidato.

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

## Lo que imprime la comprobación exhaustiva

```text
== Exhaustive check: all 4096 twelve-bit pitch-class sets
member                       agree              verdict
IsClusterFree                4096/4096          identical
IntervalClassVector.Id       4096/4096          identical
ClosestDiatonicKey           4096/4096          identical
sets with no chromatic cluster: 1499 of 4096
```

Tres líneas, y son la razón por la que se pueden citar los tiempos anteriores. `ClosestDiatonicKey` se compara por la forma de *texto* de la tonalidad y no por igualdad de record, para que un cambio en cómo `Key` se compara consigo misma no pueda ocultar una diferencia.

## Las mediciones

[BenchmarkDotNet](https://benchmarkdotnet.org/) v0.15.8, una clase de benchmarks cada vez en una máquina por lo demás inactiva:

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9445/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
  DefaultJob : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

Cada método `[Benchmark]` hace exactamente una llamada, sobre la escala mayor (2741) — siete notas, el caso habitual en GA. La CI ejecuta las mismas clases con `--job Dry`, que comprueba que siguen funcionando y no mide nada, porque los tiempos de un runner compartido son ruido. Los tiempos absolutos serán distintos en tu máquina; los ratios son la afirmación.

Las cifras de asignación, en cambio, no tienen nada de estadístico:

```text
# GA   IntervalClassVector.Id.Value    16,432 bytes
# fast IntervalClassVectorIds[id]           0 bytes
# GA   IsClusterFree                        0 bytes
# fast IsClusterFree                        0 bytes
# GA   ClosestDiatonicKey             179,848 bytes
# fast ClosestDiatonicKey              16,064 bytes
```

Vienen de [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread) alrededor de una única llamada, después de una llamada de calentamiento que ha ejecutado los constructores estáticos — la técnica de la [lección 1](../01-memory-values-and-spans/). Dependen lo bastante de la máquina como para imprimirse con el prefijo `# ` y quedar fuera de la comparación, y son lo bastante estables como para merecer imprimirse. También son algo mayores que las de `[MemoryDiagnoser]`, que resta su propio sobrecoste.

## Puntos clave

- El dominio de entrada de un conjunto de 12 bits tiene 4096 valores. Cuando el dominio es así de pequeño, «lo he probado» debería significar *entero*, y esa prueba pertenece a la CI, junto al benchmark.
- Una reescritura que devuelve otra respuesta no es la versión rápida de nada. El acarreo en base 12 de GA es un defecto real, y la versión rápida lo reproduce exactamente; corregirlo es un cambio aparte, con su propio radio de impacto.
- Los ordenamientos estables sostienen la estructura. `OrderByDescending(…).ThenByDescending(…).First()` esconde un desempate en el *orden de entrada*, y a un bucle escrito a mano hay que contárselo.
- Una propiedad sin caché es un método con un nombre engañoso. `IntervalClassVector` y `Key.Items` reconstruyen todo en cada acceso, y ambas se leen dentro de bucles en otras partes de GA.
- La cifra que destaca aquí no es un tiempo, son 175 KB de asignación para leer una propiedad — y no hizo falta ningún perfilador para encontrarla, solo leer un método que llena un diccionario y luego ignora sus valores.

## Fuentes

- BenchmarkDotNet: [cómo funciona](https://benchmarkdotnet.org/articles/guides/how-it-works.html), [buenas prácticas](https://benchmarkdotnet.org/articles/guides/good-practices.html).
- Microsoft Learn: [`BitOperations.PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount), [`GC.GetAllocatedBytesForCurrentThread`](https://learn.microsoft.com/dotnet/api/system.gc.getallocatedbytesforcurrentthread), [`Enumerable.OrderByDescending`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.orderbydescending), [`BigInteger`](https://learn.microsoft.com/dotnet/api/system.numerics.biginteger).
- Guitar Alchemist en el commit `a826864`: [`PitchClassSetId.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L42-L57), [`PitchClassSet.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L658), [`AtonalExtensions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/AtonalExtensions.cs#L28-L35), [`VariationsWithRepetitions.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/Combinatorics/VariationsWithRepetitions.cs#L55-L73), [`IntervalClassVector.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVector.cs), [`Key.cs`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50).
- El código del curso: [`GaFast.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/GaFast.cs), [`Appendix1.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Advanced/Appendix1.cs), [`GaBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/Benchmarks/GaBenchmarks.cs), [`expected/a1.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/a1.txt).
- El mismo código leído como música y no como rendimiento: [Teoría musical para Guitar Alchemist](../../music-theory-ga/), en particular la [lección 4](../../music-theory-ga/04-set-classes/), la [lección 7](../../music-theory-ga/07-cadences-and-progressions/) y [su apéndice C](../../music-theory-ga/appendix-ga-findings/).
