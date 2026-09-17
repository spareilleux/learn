---
title: "Apéndice 2: perfilar GA, luego demostrar y medir"
description: El apéndice 1 eligió sus miembros leyendo el código; este parte de un perfilador sobre el pipeline de indexación real de Guitar Alchemist. El reconocimiento de acordes con máscaras de 12 bits y calculado una sola vez por conjunto de clases de altura, un vector de clases de intervalo en caché en lugar de reconstruido, y una consulta LINQ que asignaba 38 MB por búsqueda OPTIC-K — cada cambio demostrado byte a byte contra la propia salida de GA sobre todas las entradas y un corpus de 667.125 voicings, medido con BenchmarkDotNet y enviado aguas arriba como pull request, junto con lo que se midió y se descartó.
sidebar:
  label: "Apéndice 2: GA, perfilado"
  order: 91
---

El [apéndice 1](../appendix-benchmarks/) eligió cinco miembros de [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) leyéndolos, y demostró cada reescritura sobre los 4096 conjuntos de clases de altura antes de medir su tiempo. El método era correcto, pero la elección de los miembros fue una apuesta. Un miembro que asigna 175 KB solo es un problema si algo lo llama a menudo.

Este apéndice no apuesta sobre *dónde* mirar. Ejecuta el propio pipeline de GA —generar todos los voicings de guitarra, analizarlos, convertir cada uno en un documento y un embedding, y buscar en el índice OPTIC-K— y deja que un perfilador diga adónde va el tiempo. A lo que encuentra el perfilador se le aplican después las mismas reglas:

1. **Primero la demostración.** Cada cambio se contrasta con las propias respuestas de GA: sobre todas las entradas cuando el dominio es lo bastante pequeño, y siempre sobre un corpus real. La comprobación compara dos *compilaciones de GA*, antes y después, byte a byte.
2. **Después la medición.** [BenchmarkDotNet](https://benchmarkdotnet.org/) con `[MemoryDiagnoser]`, antes y después, en la misma máquina.
3. **Después, aguas arriba.** Una rama de GA y una pull request por tema, con las cifras y la demostración en la descripción.

Los enlaces a GA apuntan al commit [`66bdd04`](https://github.com/GuitarAlchemist/ga/tree/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e), la cabeza de `main` cuando se hicieron las mediciones. Las pull requests son [#695](https://github.com/GuitarAlchemist/ga/pull/695) (reconocimiento de acordes), [#694](https://github.com/GuitarAlchemist/ga/pull/694) (vector de clases de intervalo) y [#693](https://github.com/GuitarAlchemist/ga/pull/693) (búsqueda OPTIC-K).

## Ejecutar el apéndice

```bash
bash code/csharp-advanced/check.sh                                     # todas las lecciones y los dos apéndices, comparados con expected/
dotnet run --project code/csharp-advanced/GaPerf -c Release -- a2      # solo la demostración de este apéndice, después de check.sh
cd code/csharp-advanced
dotnet run -c Release --project GaPerfBenchmarks -- --filter "*RecognitionBenchmarks*"
```

El apéndice 2 se compila contra su propio commit de GA, que `fetch-ga.sh` descarga en `.ga-perf/`, junto a la carpeta `.ga/` del apéndice 1: los dos apéndices leen commits distintos y ninguno mueve al otro. Las reescrituras están en [`GaPerf/GaFast2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/GaFast2.cs) y [`GaPerf/OptickDimension.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/OptickDimension.cs), la demostración en [`GaPerf/Appendix2.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerf/Appendix2.cs), las mediciones en [`GaPerfBenchmarks/GaPerfBenchmarks.cs`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/GaPerfBenchmarks/GaPerfBenchmarks.cs).

## Adónde va el tiempo

Un pequeño programa de sondeo llamó a cada etapa del pipeline sobre 20.000 voicings de guitarra, e imprimió el tiempo real y [`GC.GetTotalAllocatedBytes`](https://learn.microsoft.com/dotnet/api/system.gc.gettotalallocatedbytes) alrededor de cada una:

| Etapa | Por voicing | Asignado por voicing |
|---|---|---|
| Generar los 667.125 voicings de guitarra, en paralelo | 1.419 ms en total | 364 MB en total |
| Generar los 667.125 voicings de guitarra, en secuencia | 711 ms en total | 305 MB en total |
| `VoicingAnalyzer.Analyze` | 173 µs | 347 KB |
| `VoicingHarmonicAnalyzer.Analyze` | 95 µs | 321 KB |
| `VoicingDocumentFactory.FromAnalysis` | 68 µs | 113 KB |
| `MusicalEmbeddingGenerator.GenerateEmbeddingAsync` | 93 µs | 125 KB |
| `KeyIdentificationService.Identify`, por progresión | 25 µs | 16 KB |
| `OptickSearchStrategy.SemanticSearchAsync`, por consulta | 6,95 ms | **38 MB** |

Dos líneas destacan antes de abrir ningún perfilador: un análisis que asigna un tercio de megabyte por voicing, y una búsqueda que asigna 38 MB por consulta.

Después, [`dotnet-trace`](https://learn.microsoft.com/dotnet/core/diagnostics/dotnet-trace) con el perfil `dotnet-sampled-thread-time`, y su informe mediante `dotnet-trace report … topN --inclusive`, desglosaron el análisis. De las muestras del subproceso principal:

- **alrededor del 52 %** estaban en `CanonicalChordRecognizer.IdentifyChordSet`, y la mayor parte de ellas en la construcción de `HashSet<int>` dentro de `ChordIntervalPattern.TryMatch`;
- alrededor del 13,5 % en `PitchClassSet.GetCompatibleKeys`;
- alrededor del 11 % en `NormedPairExtensions.ByNormCounts`, que es, otra vez, el vector de clases de intervalo de la sección 2 del apéndice 1.

La búsqueda no tenía ningún marco caliente: `TensorPrimitives.Dot` sobre un archivo proyectado en memoria no asigna nada. Eso es lo que explican las secciones siguientes.

## 1. Tres conjuntos hash para contar tres números

`CanonicalChordRecognizer` pone nombre a un acorde probando cada clase de altura del conjunto como fundamental, y cada patrón del catálogo contra los intervalos medidos desde esa fundamental. En este commit el catálogo tiene 62 patrones, así que un voicing de cuatro notas hace 248 llamadas a [`TryMatch`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Domain.Core/Theory/Harmony/ChordIntervalPattern.cs#L37-L54):

```csharp
var patternSet = new HashSet<int>(Intervals);
var voicingSet = intervalsFromRoot is HashSet<int> hs ? hs : [.. intervalsFromRoot];

var missing = patternSet.Except(voicingSet).Count();
var extra = voicingSet.Except(patternSet).Count();

if (missing > maxMissing || extra > maxExtra)
    return null;

return new MatchResult(this, Overlap: patternSet.Intersect(voicingSet).Count(), Missing: missing, Extra: extra);
```

Un `HashSet` para el patrón, y otro más dentro de cada [`Except`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.except), `Except` e [`Intersect`](https://learn.microsoft.com/dotnet/api/system.linq.enumerable.intersect), que construyen un conjunto con su segundo argumento para comprobar la pertenencia. Cuatro conjuntos por llamada, para contar tres números.

Los intervalos desde una fundamental son clases de altura, de 0 a 11. Así que los dos lados son conjuntos de 12 bits, y las tres cuentas son lo que el apéndice 1 usaba en todas partes: un AND, un AND-NOT y un [`PopCount`](https://learn.microsoft.com/dotnet/api/system.numerics.bitoperations.popcount).

```csharp
var missing = BitOperations.PopCount((uint)(patternMask & ~voicingMask));
var extra = BitOperations.PopCount((uint)(voicingMask & ~patternMask));
if (missing > maxMissing || extra > maxExtra) return null;

return new MatchResult(pattern, BitOperations.PopCount((uint)(patternMask & voicingMask)), missing, extra);
```

El método recibe un `IReadOnlyCollection<int>`, que puede contener cualquier cosa: un 12, un −1, un duplicado. Un valor fuera del rango de 0 a 11 no tiene bit, así que la reescritura no intenta buscarle uno. Para esa llamada recurre al código de conjuntos de GA, y eso la hace correcta por construcción también con entradas que hoy ningún llamador envía.

### La primera versión seguía asignando

La primera versión con máscaras construía cada máscara con un `foreach` sobre `IEnumerable<int>`. Era diez veces más rápida, y aun así asignaba 8,6 MB para 2.000 voicings:

| Método (2.000 voicings × 62 patrones) | Media | Por voicing | Asignado | Ratio |
|---|---|---|---|---|
| `Ga` | 40,110 ms | 20,1 µs | 147,2 MB | 1,00 |
| `MasksThroughInterface` | 3,869 ms | 1,93 µs | 8,6 MB | 0,10 |
| `Masks` | 1,427 ms | 0,71 µs | 62,5 KB | 0,04 |

Un `foreach` sobre una interfaz llama a `GetEnumerator()` a través de la interfaz. El enumerador de `HashSet<int>` es un struct, que vuelve encapsulado en una caja, y un array entrega un pequeño objeto enumerador: 72 bytes por llamada para las dos máscaras. La [lección 4](../04-measured-performance/) mostraba cómo la PGO dinámica eliminaba una asignación así en un bucle ajustado. Aquí no lo hizo. Este punto de llamada ve dos tipos, un array y un `HashSet`, y si esa es la razón queda *por verificar*. `Masks` distingue primero el tipo concreto con un `switch`, de modo que el compilador usa el bucle del array y el enumerador struct:

```csharp
switch (intervals)
{
    case int[] array:
        foreach (var interval in array) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    case HashSet<int> set:
        foreach (var interval in set) { if ((uint)interval > 11) return false; mask |= 1 << interval; }
        return true;
    default:
        return TryMaskThroughInterface(intervals, out mask);
}
```

Otras 2,7 veces, y la asignación desaparece. Los 62,5 KB que quedan son 32 bytes por voicing, muy probablemente el propio `foreach` del benchmark sobre el catálogo, que está tipado como `IReadOnlyList`. `(uint)interval > 11` es una sola comparación para los dos extremos del rango, porque un `int` negativo se convierte en un `uint` muy grande.

## 2. La misma búsqueda, 266 veces

Hacer `TryMatch` 28 veces más rápido sigue dejando 248 llamadas por voicing de cuatro notas. La pregunta interesante es si hacen falta.

La propia documentación del reconocedor responde. El reconocimiento «depende solo del contenido en clases de altura y de la indicación opcional del bajo para la notación con barra», y el comentario de la clasificación lo llama *invariante n.º 33*: el bajo no debe influir en qué patrón gana. Así que el resultado para un conjunto, sin el bajo, es una función de 12 bits. El programa de demostración contó cuántas veces se llama a esa función con el mismo argumento mientras analiza el corpus:

```text
== How often the same set comes back
recognitions per distinct set  16.8                 in the sample
in the whole corpus            265.9
```

Los 667.125 voicings de guitarra usan unos 2.500 conjuntos de clases de altura distintos. **La búsqueda de patrones de cada conjunto se repetía, de media, 266 veces.** La solución es recordar la respuesta:

```csharp
static readonly (CanonicalChordResult Result, int? Root)?[] Recognized = new (CanonicalChordResult, int?)?[4096];

public static CanonicalChordResult Identify(PitchClassSet set, PitchClass? bass = null)
{
    var (result, root) = Recognized[set.Id.Value] ??= Recognize(set);
    if (root is not { } chordRoot || bass is not { } b || b.Value == chordRoot) return result;
    return result with { SlashSuffix = $"/{NoteNames[b.Value]}" };
}
```

Un array de 4096 elementos es toda la caché: ni diccionario, ni hash, ni desalojo, porque el espacio de claves es el espacio de índices. Dos subprocesos que compiten por la misma casilla calculan resultados inmutables iguales, y la última escritura gana sin causar daño.

### El bajo es donde podía salir mal

La caché solo es correcta si el bajo se aplica *exactamente* como lo aplica GA, y GA no lo aplica en todas partes:

- los conjuntos de 0, 1 y 2 clases de altura tienen sus propios caminos de código, que ignoran el bajo;
- un conjunto que no coincide con ningún patrón recurre a su número de Forte, que también ignora el bajo;
- una coincidencia de patrón solo añade `/X` cuando el bajo difiere de la fundamental del acorde.

Así que la entrada almacenada guarda la fundamental *solo* en el camino de coincidencia de patrón, y `null` en todos los demás. La versión del curso no puede ver la fundamental privada de GA. La reconstruye a partir del resultado público, y es la demostración la que dice que esa reconstrucción es correcta: 4096 conjuntos × sin bajo y 12 bajos × dos pasadas (la segunda lee la caché), comparando cada campo:

```text
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
```

| Método (2.000 voicings) | Media | Por voicing | Asignado | Ratio |
|---|---|---|---|---|
| `Ga` | 198.958 µs | 99,5 µs | 677,1 MB | 1,000 |
| `OncePerSet` | 26,22 µs | 13 ns | 158,8 KB | 0,0001 |

**7.600 veces más rápido, y 347 KB por voicing que ya no se asignan.** Los 79 bytes por voicing que quedan son la copia `with` de los voicings cuyo bajo no es la fundamental. Como en el apéndice 1, la medición es un estado estacionario: las iteraciones de calentamiento ya han visto los conjuntos del corpus. La primera llamada para cada conjunto cuesta lo que siempre costó, y en un proceso hay como mucho 4096 primeras llamadas.

Este es el cambio que importa, y no tiene nada de ingenioso. La reescritura con máscaras de la sección 1 es el tipo de cosa que se espera encontrar en un apéndice de rendimiento. La caché es lo que pedía el perfil.

## 3. El vector de clases de intervalo, que el apéndice 1 ya había reescrito

La sección 2 del apéndice 1 sustituyó el cálculo de `IntervalClassVector` por seis popcounts, y conservó a propósito un defecto aritmético: el empaquetado en base 12 acarrea para el agregado cromático. El perfil muestra que la propiedad sigue en el camino caliente de GA: `VoicingHarmonicAnalyzer` la lee una vez por voicing, y `VoicingAnalyzer` hasta cuatro veces.

Para la pull request, la reescritura más segura era otra: **conservar el cálculo de GA y hacerlo una sola vez por conjunto.** Una tabla de popcounts tendría que reproducir el empaquetado, acarreo incluido, y divergiría en silencio si GA lo cambiara algún día. Una caché de la propia respuesta de GA no puede divergir, porque cuando falla llama al código sin cambios:

```csharp
static readonly int[] IntervalClassVectorIdPlusOne = new int[4096];

public static IntervalClassVectorId IntervalClassVectorId(PitchClassSet set)
{
    var stored = IntervalClassVectorIdPlusOne[set.Id.Value];
    if (stored == 0)
    {
        stored = set.IntervalClassVector.Id.Value + 1;
        IntervalClassVectorIdPlusOne[set.Id.Value] = stored;
    }
    return new(stored - 1);
}
```

El `+ 1` es la forma en que un array de `int` dice «todavía no calculado» sin un segundo array: todo conjunto con menos de dos clases de altura tiene el identificador 0, que de otro modo no se distinguiría de una casilla vacía.

| Método (2.000 voicings) | Media | Por voicing | Asignado | Ratio |
|---|---|---|---|---|
| `Ga` | 6.323,165 µs | 3,16 µs | 16,2 MB | 1,000 |
| `OncePerSet` | 1,147 µs | 0,57 ns | — | 0,0002 |

En GA, la caché está dentro de `ToIntervalClassVector<T>`. Solo se aplica cuando la colección es el `ImmutableSortedSet<PitchClass>` con el comparador por defecto que pasa `PitchClassSet`, y cualquier otra forma de colección toma el camino general. Por sí sola, esa pull request apenas mueve el análisis de voicings: el benchmark dio un 9 %, que está dentro del ruido de esta máquina, porque el reconocimiento de acordes sigue dominando. Después de la sección 2, el vector de clases de intervalo es el mayor coste que queda en el análisis armónico, y lo que muestran las cifras de extremo a extremo de más abajo es el efecto de los dos cambios juntos.

## 4. Una consulta LINQ, 626.000 veces por búsqueda

La búsqueda asignaba 38 MB por consulta, y el recorrido no asigna nada. El primer sospechoso fue [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for): [`OptickSearchStrategy`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L185-L220) ejecuta una iteración por voicing indexado, con un montículo por worker. Así que un experimento ejecutó el mismo recorrido en secuencia:

```text
identical top-10 lists: 64/64
current x200                                      1,337.3 ms      7,646.8 MB
chunked x200                                      1,236.8 ms      7,651.3 MB
sequential x50                                    1,670.5 ms      1,910.7 MB
```

38 MB por consulta en los tres casos. El paralelismo era inocente: los bytes venían del interior del bucle. El cuerpo del bucle lee un vector, y [`GetVector`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Search/OptickIndexReader.cs#L179-L183) tiene dos líneas:

```csharp
public static int Dimension => EmbeddingSchema.CompactDimension;

public ReadOnlySpan<float> GetVector(long i)
{
    if ((ulong)i >= (ulong)_count) throw new ArgumentOutOfRangeException(nameof(i));
    return new ReadOnlySpan<float>(_vectors + i * Dimension, Dimension);
}
```

Y [`CompactDimension`](https://github.com/GuitarAlchemist/ga/blob/66bdd049ad3f4b10f996e4cc6a9c6e58797cf30e/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L147-L148) no es una constante:

```csharp
public static int CompactDimension =>
    SimilarityPartitions.Sum(p => p.Dim);

public static IEnumerable<EmbeddingPartition> SimilarityPartitions =>
    Partitions.Where(p => p.Role == PartitionRole.Similarity);
```

Cada lectura filtra el registro de 11 particiones y lo suma, asignando iteradores de LINQ por el camino. `GetVector` lee `Dimension` dos veces, y el recorrido llama a `GetVector` una vez por cada uno de los 313.047 voicings indexados: **626.094 consultas LINQ por búsqueda, para calcular 124 cada vez.**

Nada en el nombre de la propiedad lo indica. `Dimension` parece un campo y `=>` parece un getter. El diseño es razonable, ya que el registro es la única fuente de verdad sobre la disposición. El coste solo existe porque un bucle caliente lo lee. La solución conserva la propiedad y lee el registro una sola vez:

```csharp
public static int Dimension { get; } = EmbeddingSchema.CompactDimension;
```

El curso no puede compilar el proyecto de búsqueda de GA, que arrastra Semantic Kernel, ONNX Runtime e ILGPU. Así que `OptickDimension.cs` copia el registro y las dos propiedades del commit de GA, y mide la aritmética de desplazamientos de un recorrido:

| Método (313.047 vectores) | Media | Por vector | Asignado | Ratio |
|---|---|---|---|---|
| `Computed` | 25.849,42 µs | 82,6 ns | 40.070.016 B | 1,000 |
| `Stored` | 67,50 µs | 0,22 ns | — | 0,003 |

Exactamente 128 bytes por vector, 64 por cada lectura de la propiedad. Una vez que el JIT ha leído un valor `static readonly` puede usarlo como constante, así que `Stored` es la multiplicación y nada más.

En el propio GA, con el índice real de 313.047 entradas, BenchmarkDotNet midió antes y después:

| Benchmark | Antes | Después |
|---|---|---|
| `SemanticSearchAsync`, 10 primeros | 4,986 ms, 38,25 MB | 2,162 ms, 41.306 B |
| `GetVector` para cada entrada | 31,955 ms, 38,21 MB | 1,689 ms, 0 B |

### Lo que se descartó

Una vez corregido `GetVector`, el experimento de particionado volvió a ejecutarse:

```text
identical top-10 lists: 64/64
current x200                                        827.2 ms          3.1 MB
chunked x200                                      1,009.9 ms          7.2 MB
sequential x50                                      857.6 ms          0.0 MB
```

El particionado por rangos con [`Partitioner.Create`](https://learn.microsoft.com/dotnet/api/system.collections.concurrent.partitioner.create) fue *más lento* que el bucle por elemento de GA, así que `SearchInternal` no cambia. Habría sido fácil publicar el cambio de particionado basándose en el primer experimento, donde parecía un 8 % más rápido. Era ruido sobre 38 MB de basura.

## Lo que imprimen las demostraciones

```text
== Exhaustive check
member                         agree                inputs
ChordIntervalPattern.TryMatch  6,856,704/6,856,704  62 patterns x 4096 sets x 9 tolerances x 3 shapes
CanonicalChordRecognizer       106,496/106,496      4096 sets x 13 basses x 2 passes
IntervalClassVector.Id         4,096/4,096          4096 sets

== Real corpus: guitar voicings from GA's generator
voicings generated             667,125
voicings checked               41,696               every 16th
distinct pitch-class sets      2,482                of 4096
chord name, canonical, slash   41,696/41,696

== A few voicings, as GA names them
x-3-2-0-1-0                    C
3-2-0-0-0-3                    G
x-x-0-2-3-2                    D
0-2-2-1-0-0                    E
x-5-4-5-3-x                    D7(shell)

== OPTIC-K reader: the dimension, read once
compact dimension              124                  sum of the similarity partitions
GetVector offset and length    313,047/313,047      one per indexed voicing
```

Esa es la demostración del curso, que compara dos métodos dentro de un mismo proceso, y la CI la ejecuta en tres sistemas operativos. Las pull requests usan una más fuerte. El *mismo* programa de volcado se compila dos veces, una contra el `main` de GA y otra contra la rama, y escribe en un archivo cada respuesta del camino. Después, `cmp` compara los archivos:

| Volcado | Contenido | Líneas | Resultado |
|---|---|---|---|
| `trymatch` | cada patrón × 4096 conjuntos de intervalos × 9 tolerancias, como array y como `HashSet`, más entradas fuera de rango y duplicadas | 258.048 | idéntico |
| `identify` | 4096 conjuntos × 13 bajos × 2 pasadas | 106.496 | idéntico |
| `icv` | 4096 conjuntos × 2 pasadas: identificador, texto, cuentas y tres propiedades derivadas | 8.192 | idéntico |
| `voicings` | los 667.125 voicings de guitarra a través de `VoicingAnalyzer.Analyze`: campos del acorde, consonancia, drop voicing, etiquetas, modo | 667.125 | idéntico |
| búsqueda | 2.048 búsquedas de los 10 primeros sobre el índice real | 2.048 | idéntico |

Una comparación entre dos compilaciones detecta lo que una comparación entre dos métodos no puede: un cambio en un llamador, en un tipo que la reescritura olvidó, o en el orden en que el analizador lee las cosas.

## De extremo a extremo

`FretboardVoicingsCLI --export-embeddings` de GA construye el índice OPTIC-K: 688.351 voicings para guitarra, bajo y ukelele, 313.047 tras eliminar duplicados, cada uno analizado y convertido en embedding. Se ejecutó cuatro veces, alternando el `main` de GA y una compilación con los cambios del acorde y del vector de clases de intervalo:

| Ronda | `main` de GA | Los dos cambios |
|---|---|---|
| 1 | 142,8 s | 62,9 s |
| 2 | 95,0 s | 38,3 s |

Los cuatro archivos de índice son idénticos entrada a entrada. Los benchmarks de análisis en GA, sobre los mismos 2.000 voicings:

| Benchmark | `main` de GA | Cambio del acorde | Los dos cambios |
|---|---|---|---|
| `VoicingHarmonicAnalyzer.Analyze` | 213,19 ms, 700,8 MB | 8,48 ms, 23,6 MB | 2,47 ms, 7,3 MB |
| `VoicingAnalyzer.Analyze` | 234,34 ms, 759,3 MB | 30,23 ms, 82,1 MB | 8,94 ms, 22,1 MB |

`VoicingAnalyzer.Analyze` pasa de 117 µs y 380 KB por voicing a 4,5 µs y 11 KB. La exportación, que además genera los embeddings y escribe, es entre 2,3 y 2,5 veces más rápida.

## Las mediciones, y cuánto fiarse de ellas

```text
BenchmarkDotNet v0.15.8, Windows 11 (10.0.26200.9457/25H2/2025Update/HudsonValley2)
Intel Core Ultra 9 285K 3.70GHz, 1 CPU, 24 logical and 24 physical cores
.NET SDK 10.0.112
  [Host]     : .NET 10.0.12 (10.0.12, 10.0.1226.42308), X64 RyuJIT x86-64-v3
```

El apéndice 1 se midió en una máquina inactiva. Este no, y la diferencia merece explicarse:

- **La máquina estaba compartida.** Los benchmarks del curso se ejecutaron en un equipo de sobremesa que otras sesiones estaban usando, con Microsoft Defender, Docker y WSL ocupados. Cada serie se ejecutó bajo un bloqueo global de la máquina que mantenía fuera otras compilaciones y trabajos de GPU, y al principio de cada serie se registraron la RAM libre y los procesos más activos: entre 13,6 y 18,5 GB libres, y entre el 32 % y el 100 % de CPU total.
- **Las asignaciones son exactas; los tiempos, orientativos.** Las tablas del curso de más arriba usan el job por defecto. Las tablas de antes y después de GA usan `ShortRun` (tres iteraciones), cuyas barras de error llegaron al 10 a 50 % de la media en las ejecuciones más cargadas.
- **La exportación varió en un factor de 1,5 entre rondas** con el mismo binario: 142,8 s y luego 95,0 s. La proporción dentro de cada ronda se mantuvo, y por eso las rondas se alternan.
- **Toda aceleración que se afirma está muy por encima del ruido.** Ninguna baja de 2,3 veces, y las mayores se cuentan por miles. En esta máquina, una mejora del 10 % no habría sido publicable, y por eso la sección 3 no afirma ninguna.

## Medido, y sin cambiar

- **El camino paralelo de `VoicingGenerator`** generó los 667.125 voicings en 1.419 ms y 364 MB, y el camino secuencial en 711 ms y 305 MB: el paralelo es el doble de lento. Ese archivo pertenece a otra serie de correcciones de GA en curso, así que el hallazgo fue a ese trabajo en lugar de a una pull request de aquí.
- **`PitchClassSet.GetCompatibleKeys`**, el 13,5 % del perfil del análisis, y los miembros de `Key` a los que llama. Estos archivos también tienen correcciones en curso en otro lugar; la misma caché por conjunto se aplica, y quedó redactada como propuesta.
- **`KeyIdentificationService.Identify`**: 25 µs por progresión, llamado una vez por petición, no por voicing.
- **Las asignaciones de los objetos de valor de la [lección 5](../05-generics-in-depth/)** (`Items`, `Values`, `ValueObjectCache<T>`): reales, medidas, y ausentes de este perfil. Ninguna está en el camino de indexación.
- **El particionado por rangos de la búsqueda**: más lento, véase la sección 4.
- **La exportación del índice no siempre es reproducible.** Las cuatro exportaciones alternadas de más arriba son idénticas, y también lo son dos exportaciones anteriores hechas una tras otra con los dos binarios. Pero la primera exportación de la noche, desde el `main` de GA, difiere de todas ellas en 266 de las 313.047 entradas cuando las entradas se identifican por instrumento y diagrama, y los tres grupos de archivos difieren en tamaño en unas pocas decenas de bytes. Cada comparación de este apéndice se hace entre exportaciones del mismo grupo, así que las conclusiones se mantienen. La causa queda *por verificar*.
