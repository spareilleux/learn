---
title: "Lección 2: Embeddings OPTIC-K"
description: Los 240 números que Guitar Alchemist calcula para cada forma de acorde — las particiones y sus pesos, la historia de versiones, vectores reales de seis acordes abiertos, la similitud ponderada calculada a mano, a qué es invariante el vector, y dos errores de records posicionales que lo aplanan.
sidebar:
  label: 2. Embeddings OPTIC-K
  order: 2
---

Un **embedding** (vector de incrustación) es un array de números que describe un objeto, construido para que objetos parecidos reciban arrays parecidos. Los embeddings de texto salen de una red neuronal y nadie sabe decir qué significa la dimensión 417. OPTIC-K es lo contrario: cada uno de sus 240 números lo calcula código C# a partir de la teoría musical, y tiene nombre. Eso lo convierte en un buen primer embedding para estudiar, porque cada número se puede comprobar. Esta lección calcula los vectores de seis acordes con las propias clases de GA y los comprueba.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l2
```

## De dónde viene el nombre

En 2008, Clifton Callender, Ian Quinn y Dmitri Tymoczko describieron los objetos musicales por las equivalencias que uno decide ignorar: **O**ctava, **P**ermutación (el orden de las notas), **T**ransposición, **I**nversión y **C**ardinalidad (notas duplicadas) ([*Generalized Voice-Leading Spaces*](https://doi.org/10.1126/science.1153021)). Si se ignoran la octava y el orden, un acorde se convierte en un conjunto de clases de altura; si se ignoran también la transposición y la inversión, se convierte en una clase de conjuntos, el tema de la lección 4 del [curso de teoría musical](../../music-theory-ga/04-set-classes/). Una **K**, de complementariedad, viene de [Harmonious](https://harmoniousapp.net/), la referencia de acordes y escalas de Jared Updike: su página [Equivalence Groups](https://harmoniousapp.net/p/ec/Equivalence-Groups) añade esa letra y aclara que no es terminología estándar. GA bautiza su embedding con la lista completa, y su clase [`OpticKClass`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/OpticKClass.cs#L3-L15) cita esa página. Los comentarios de [`TheoryVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L41-L77) asocian cada bloque de números con las letras que debe cubrir.

## El esquema

[`EmbeddingSchema.Partitions`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L117-L137) es el registro que todo consumidor debería leer: un nombre, un rango de las 240 posiciones, un peso y un rol para cada partición.

```text
== EmbeddingSchema.Partitions (OPTIC-K-v1.8)
partition     raw      dims  role        weight
IDENTITY      0-5      6     Identity    0.00
STRUCTURE     6-29     24    Similarity  0.45
MORPHOLOGY    30-53    24    Similarity  0.25
CONTEXT       54-65    12    Similarity  0.20
SYMBOLIC      66-77    12    Similarity  0.10
EXTENSIONS    78-95    18    Info        0.00
SPECTRAL      96-108   13    Info        0.00
MODAL         109-148  40    Similarity  0.10
HIERARCHY     149-163  15    Info        0.00
ATONAL_MODAL  164-227  64    Info        0.00
ROOT          228-239  12    Similarity  0.05
TotalDimension          240
sum of dims             240
sum of weights          1.15
CompactDimension        124
CompactLayoutV4         optk-v4-pp-r:STRUCTURE:0-23,MORPHOLOGY:24-47,CONTEXT:48-59,SYMBOLIC:60-71,MODAL:72-111,ROOT:112-123
SchemaHashV4            0x37CD8ECF
```

Lo que describe cada partición, según el generador y sus servicios:

| Partición | Describe | Se calcula a partir de |
|---|---|---|
| STRUCTURE | qué clases de altura, cuántas, el vector interválico | el conjunto de notas, sin octava ni orden |
| MORPHOLOGY | la forma sobre el mástil: bajo y nota más aguda, extensión, posición en el mástil, cejilla | el voicing físico |
| CONTEXT | función armónica, tensión, movimiento | el análisis del acorde |
| SYMBOLIC | etiquetas como técnica y estilo | etiquetas del análisis |
| MODAL | cuánto sugiere el acorde cada modo: 40 posiciones, 33 de ellas con nombre de modo | las notas, respecto a una fundamental |
| ROOT | la clase de altura de la fundamental, en one-hot | la fundamental |
| IDENTITY, EXTENSIONS, SPECTRAL, HIERARCHY, ATONAL_MODAL | tipo de objeto, rasgos psicoacústicos y espectrales, complejidad, familias de la teoría de conjuntos | se guardan, nunca puntúan |

Tres cosas que observar:

- **Solo se buscan las seis particiones "Similarity".** Juntas contienen 124 números, la `CompactDimension`. Las otras cinco son información para otras herramientas; el archivo del índice ni siquiera las guarda (lección 3).
- **Los pesos suman 1,15, no 1.** Por eso un vector comparado consigo mismo puntúa 1,15, como muestra la salida de abajo. Nada se rompe, ya que solo importa el orden, pero una puntuación no es un coseno en el sentido habitual de 0 a 1.
- **La cadena de disposición se resume con un hash.** `SchemaHashV4` es el [CRC-32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32) de `CompactLayoutV4` ([líneas 154-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L154-L186)). La issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) indica `0x37CD8ECF` para el índice en producción de GA, de 313.047 voicings: el curso y ese índice usan la misma disposición.

Junto al registro, `EmbeddingSchema` conserva constantes más antiguas para cada partición. Tres de ellas ya no coinciden:

```text
== Loose constants next to the registry
constant                 value      registry
HierarchyDim             8          15
AtonalModalDim           17         64
ExtensionsEnd            96         240
```

`ExtensionsEnd` es correcta, 96 es donde termina EXTENSIONS, pero su [comentario](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L406-L407) dice que es igual a `TotalDimension`, lo que era cierto cuando el vector tenía 96 números. Las otras dos importan más: [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L116) reserva su array ATONAL_MODAL con `AtonalModalDim`, 17, y [`WriteInto`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L219-L220) copia la longitud que se le dé sin protestar, así que 47 de las 64 posiciones de esa partición nunca pueden ser otra cosa que cero. La lección 3 encuentra exactamente 47 en un corpus entero.

## Versiones

El esquema creció añadiendo particiones al final. La historia de abajo procede de los [documentos del esquema](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Documentation/Schema) de GA, de los comentarios de versión de `EmbeddingSchema.cs` y de dos commits:

| Versión | Dimensiones | Qué cambió | Fuente |
|---|---|---|---|
| v1.2.1 | 96 | EXTENSIONS añadida; "indices 0–77 are unchanged" | `OPTIC-K_Embedding_Schema_v1.2.1.md`, fechado el 2026-01-11 |
| v1.3, v1.3.1 | 108, 109 | SPECTRAL, y luego la entropía espectral en el índice 108 | `OPTIC-K_Embedding_Schema_v1.3.md`, `_v1.3.1.md` |
| v1.4 | 216 | índices 0-135 definidos, el resto reservado | `OPTIC-K_Embedding_Schema_v1.4.1.md`, fechado el 2026-01-21 |
| v1.6 | | MODAL y HIERARCHY | comentarios de `EmbeddingSchema.cs` |
| v1.7 | 228 | ATONAL_MODAL | comentarios de `EmbeddingSchema.cs` |
| v1.8 | 240 | ROOT añadida; se quita la bonificación de la fundamental en STRUCTURE | commit [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9), 2026-04-19 |

El formato del índice tiene su propia historia: v4 normalizaba todo el vector compacto de una vez, v4-pp normaliza cada partición por separado (commit [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365), 2026-04-19), y v4-pp-r añade ROOT, lo que llevó el tamaño compacto de 112 a 124.

La documentación no ha seguido el ritmo. El documento de esquema más reciente se queda en v1.4.1, y el que no lleva versión en el nombre, `OPTIC-K_Embedding_Schema.md`, describe v1.3.1 y 109 dimensiones. En el código, el resumen del generador todavía dice "228-dimensional canonical musical embedding (v1.7)" ([línea 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L13)) y su propiedad `Dimension` "216 for v1.4/v1.5" ([línea 55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L55)), mientras que los dos devuelven 240. Cuando un comentario y el registro no coinciden, fíate del registro, y mejor aún, imprímelo.

## De una forma de acorde a un documento

Los guitarristas escriben las formas de acorde de la cuerda E grave a la E aguda: `x32010` es C abierto, con la E grave silenciada. GA numera las cuerdas al revés, desde la E aguda, la cuerda 1, y su generador de voicings construye las posiciones en ese orden. [`Voicings.FromShape`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L39-L64), del curso, convierte un diagrama de acordes al orden de GA, y luego [`Voicings.Embed`](https://github.com/spareilleux/learn/blob/8e335d7/code/ga-ai/GaAi/Voicings.cs#L97-L103) ejecuta los tres pasos que ejecutan las propias herramientas de GA:

```csharp
var analysis = VoicingAnalyzer.Analyze(voicing);
var doc = VoicingDocumentFactory.FromAnalysis(voicing, analysis, tuningId: "guitar");
var raw = Generator.GenerateEmbeddingAsync(doc).GetAwaiter().GetResult();
```

El paso del medio construye un `ChordVoicingRagDocument`, un record de unas cincuenta propiedades que lee el generador. Seis acordes:

```text
== From a chord shape to GA's voicing document
shape   GA diagram   GA name       pcs      MIDI            doc root inv   rootless function
x32010  0-1-0-2-3-x  C             0 4 7    64 60 55 52 48  4 E      1     yes  Functional Harmony
x35553  3-5-5-5-3-x  C             0 4 7    67 64 60 55 48  7 G      2     yes  Functional Harmony
032010  0-1-0-2-3-0  C/E           0 4 7    64 60 55 52 48 40 4 E      1     yes  Functional Harmony
x32000  0-0-0-2-3-x  Cmaj7         0 4 7 11 64 59 55 52 48  4 E      1     yes  Functional Harmony
x02210  0-1-2-2-0-x  Am            0 4 9    64 60 57 52 45  4 E      2     yes  Functional Harmony
320003  3-0-0-0-2-3  G             2 7 11   67 59 55 50 47 43 7 G      0     yes  Functional Harmony
```

Los nombres son correctos. La fundamental del documento no: es E para C abierto y G para C con cejilla. [`VoicingDocumentFactory`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L37-L38) toma la primera nota MIDI a la vez como fundamental y como bajo:

```csharp
RootPitchClass = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] % 12 : 0,
MidiBassNote = analysis.MidiNotes.Length > 0 ? analysis.MidiNotes[0] : 0,
```

Como las notas vienen empezando por la cuerda 1, `MidiNotes[0]` es la nota **más aguda**, la nota de la melodía, ni el bajo ni la fundamental. La columna de inversión también se calcula a partir de esa nota: C abierto en estado fundamental aparece como primera inversión. La fundamental con la que se compara la lee `PitchClass.Parse`, que toma los nombres de nota A y E por los números 10 y 11 ([líneas 43-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs#L43-L44)): fuera del programa del curso, un Em en estado fundamental, `022000`, sale con la inversión -1. Toda partición que lee `RootPitchClass` o `MidiBassNote` hereda el error: ROOT, MODAL y parte de MORPHOLOGY.

## Dos records posicionales

La columna "rootless" dice que sí para los seis acordes, y todos contienen su fundamental. La causa es un patrón que todo desarrollador C# debería reconocer. [`VoicingCharacteristics`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core/Analysis/Voicings/VoicingCharacteristics.cs#L3-L15) es un record posicional de once parámetros, y [`VoicingHarmonicAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingHarmonicAnalyzer.cs#L31-L43) lo construye con argumentos posicionales:

```csharp
// El record: (ChordId, DissonanceScore, Consonance, IntervalSpread, NoteCount,
//              IntervalClassVector, IsRootless, DropVoicing, IsOpenVoicing, Features, SemanticTags)
return new(
    chordId,
    dissonanceScore,
    consonance,
    intervalSpread,
    pitchClasses.Count,
    pcSet.IntervalClassVector.ToString(),
    intervalSpread > 12,
    dropVoicing,
    false,
    [],
    semanticTags
);
```

`intervalSpread > 12`, "las notas abarcan más de una octava", es lo que significa un **voicing abierto**, y acaba en `IsRootless`; la constante `false` acaba en `IsOpenVoicing`. El compilador no puede objetar nada: los dos son `bool`. Lo mismo ocurre un nivel más arriba, en [`VoicingAnalyzer`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingAnalyzer.cs#L164), con un record declarado como `PerceptualQualities(double Brightness, double ConsonanceScore, double Roughness, string TexturalDescription, string Register)`:

```csharp
var perceptualQualities = new PerceptualQualities(curVoiceChars.Consonance, 0, 0, "Neutral", "Medium");
```

La consonancia va a `Brightness`, y `ConsonanceScore` vale siempre 0. El programa imprime los dos records para los seis acordes:

```text
== VoicingCharacteristics and PerceptualQualities, as VoicingAnalyzer fills them
shape   span    IsRootless  IsOpen    Consonance  Brightness   ConsonanceScore
x32010  16      True        False     1.000       1.000        0.000
x35553  19      True        False     1.000       1.000        0.000
032010  24      True        False     1.000       1.000        0.000
x32000  16      True        False     1.000       1.000        0.000
x02210  19      True        False     1.000       1.000        0.000
320003  24      True        False     1.000       1.000        0.000
```

El documento copia `ConsonanceScore` en su propiedad `Consonance`, y el generador calcula la tensión de CONTEXT como `1.0 - doc.Consonance` ([línea 102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/MusicalEmbeddingGenerator.cs#L99-L104)). Así que la tensión es 1 para todos los acordes indexados. La issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) midió la partición CONTEXT como "vacía", con una dimensión constante, y culpó a los literales que se pasan al lado; la dimensión constante es esta, y su causa es el record de arriba. Con argumentos con nombre, `new PerceptualQualities(Brightness: ..., ConsonanceScore: ...)`, los dos descuidos habrían sido visibles en la llamada.

## Los 240 números de C abierto

```text
== The 240 values of x32010 (C), partition by partition
IDENTITY       3/6   1 0 1 0 0 1
STRUCTURE     10/24  1 0 0 0 1 0 0 1 0 0 0 0 0.5 0 0 1 1 1 0 0 1 0.83 1 0
MORPHOLOGY     7/24  0 0 0 0 1 0 0 0 0 0 0 0 0.17 0.83 1 0.87 -0.5 0.33 0 0 0 0 0 0
CONTEXT        1/12  0 0 0 0 1 0 0 0 0 0 0 0
SYMBOLIC       4/12  1 1 0 0 0 0 0 0 0 1 0 1
EXTENSIONS     9/18  0 1 0.4 0 0 0.57 0.33 0.47 0.2 0 0 0 0.33 0 0 1 0.6 0
SPECTRAL      13/13  0.2 0.26 0.61 0.37 0.4 0.47 0.29 0.6 0.53 0.29 0.64 0.5 0.16
MODAL          2/40  0 0 0 0 0 0.43 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.67 (+13 zeros)
HIERARCHY      1/15  0.33 0 0 0 0 0 0 0 0 0 0 0 0 0 0
ATONAL_MODAL  11/64  0.2 0.5 0 1 0 0 0.33 0.33 0.33 0 0.03 0.44 0.67 1 0 0.88 (+48 zeros)
ROOT           1/12  0 0 0 0 1 0 0 0 0 0 0 0
MODAL slots set: Aeolian=0.43, LydianAugmentedSharp2=0.67
```

STRUCTURE se puede leer a mano con [`TheoryVectorService.ComputeEmbedding`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L27-L94) abierto al lado:

| Posiciones | Valores | Significado |
|---|---|---|
| 0-11 | `1 0 0 0 1 0 0 1 0 0 0 0` | el croma: clases de altura 0, 4 y 7, C E G |
| 12 | `0.5` | cardinalidad, 3 ÷ 12 × 2 |
| 13-18 | `0 0 1 1 1 0` | el vector interválico `<001110>` de una tríada mayor |
| 19 | `0` | complementariedad, siempre pasada como 0.0 |
| 20, 21 | `1`, `0.83` | consonancia y brillo derivados del vector |
| 22 | `1` | "se conoce una fundamental" |
| 23 | `0` | reservada |

La línea CONTEXT es la tensión constante de la sección anterior, en la posición 4 de [`ContextVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ContextVectorService.cs#L43-L52); las posiciones 6 a 11 están "reservadas" y nunca se escriben. La línea ROOT tiene su 1 en la clase de altura 4, E, la nota más aguda. Las posiciones MODAL también se calculan respecto a una fundamental, lo que explicaría por qué una tríada de C mayor enciende Aeolian, un modo menor: leídas desde E, C E G son E, G, C (una interpretación, *por verificar* línea a línea en `ModalVectorService`).

Nueve de las posiciones MODAL con nombre no las activa ninguno de los 15.360 voicings del corpus de la lección 3.

## La similitud a mano

GA compara dos vectores partición por partición: el coseno de cada partición de similitud, multiplicado por su peso, y todo sumado. [`WeightedPartitionCosine`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L277-L304) lo hace con [`TensorPrimitives.CosineSimilarity`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), y se salta una partición que sea toda ceros. El curso imprime cada coseno frente a C abierto:

```text
== Cosine per partition, and GA's weighted score, against open C
pair             structure  morphology  context  symbolic  modal  root   weighted  compact dot
x32010 x35553    1.000      0.348       1.000    1.000     0.000  0.000  0.837     0.837
x32010 032010    1.000      0.997       1.000    0.750     1.000  1.000  1.124     1.124
x32010 x32000    0.883      0.998       1.000    0.816     0.541  1.000  1.033     1.033
x32010 x02210    0.888      0.998       1.000    0.816     0.153  1.000  0.996     0.996
x32010 320003    0.776      0.496       1.000    0.671     0.000  0.000  0.740     0.740
open C with itself: 1.150
```

La primera fila, C abierto frente a C con cejilla en el tercer traste, a mano:

`0.45 × 1.000 + 0.25 × 0.348 + 0.20 × 1.000 + 0.10 × 1.000 + 0.10 × 0.000 + 0.05 × 0.000 = 0.837`

Leída musicalmente, la tabla sorprende. El C con cejilla tiene exactamente las notas de C abierto, y aun así puntúa menos que Am (0.996) y que Cmaj7 (1.033). Su STRUCTURE es idéntica; lo que lo hunde son ROOT y MODAL, ambas calculadas a partir de la nota más aguda, G en vez de E, y su forma de mano distinta. C abierto y C/E, que comparten sus cinco cuerdas superiores, puntúan 1.124. Y CONTEXT vale 1.000 en todas las filas: 0,20 de cada puntuación es una constante.

La última columna es el producto escalar de los dos vectores compactos. [`ExtractCompact`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L241-L267) conserva las seis particiones de similitud, divide cada una por su norma euclídea y la multiplica por la raíz cuadrada de su peso. Entonces, para una partición `p`, `(√w · a/|a|) · (√w · b/|b|) = w · cos(a, b)`, y el producto escalar de dos vectores compactos es la puntuación ponderada. Por eso el índice guarda vectores compactos: un único producto escalar por voicing sustituye seis cosenos.

## A qué es invariante el vector

El croma de STRUCTURE ignora octavas y orden de las notas: cualquier voicing de C E G recibe las mismas doce posiciones, y por eso el C con cejilla puntúa 1.000 ahí. La transposición es otra historia. El curso compara la STRUCTURE de C mayor con sus once transposiciones, y por separado las posiciones 12 a 18, la cardinalidad y el vector interválico:

```text
== STRUCTURE of C major (0 4 7) against its 11 transpositions (TheoryVectorService)
T    pcs        structure  icv dims
1    1 5 8      0.665      1.000
2    2 6 9      0.665      1.000
3    3 7 10     0.776      1.000
4    4 8 11     0.776      1.000
5    0 5 9      0.776      1.000
6    1 6 10     0.665      1.000
7    2 7 11     0.776      1.000
8    0 3 8      0.776      1.000
9    1 4 9      0.776      1.000
10   2 5 10     0.665      1.000
11   3 6 11     0.665      1.000
set classes swept                 222
invariant (min cosine > 0.9999)   1
mean of the minimum cosines       0.881
worst minimum cosine              0.514
```

Las dimensiones interválicas no se mueven; la partición completa sí, porque el croma nombra las notas literales. De todas las clases de conjuntos de dos notas o más, solo una es invariante, el conjunto cromático de doce notas, el único conjunto igual a todas sus transposiciones. Son las cifras del propio barrido de GA, [`state/quality/domain-invariants/README.md`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/domain-invariants/README.md#L37-L47): "1 of 222 set classes is T-invariant", media 0,88, peor 0,51. `TheoryVectorService` recoge el hallazgo en un [comentario](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/TheoryVectorService.cs#L57-L64); [`RootVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/RootVectorService.cs#L3-L7) sigue diciendo que sacar la fundamental hizo que STRUCTURE fuera "genuinely O+P+T+I-invariant".

Así que OPTIC-K es invariante a la octava y al orden, como promete el nombre, y no a la transposición ni a la inversión: una búsqueda de "esta forma en otra tonalidad" no puede apoyarse en STRUCTURE.

## Una herramienta MCP, dos órdenes de diagrama

GA expone el generador a los asistentes de IA mediante una herramienta [MCP](https://modelcontextprotocol.io/), `ga_generate_voicing_embedding`. Su [descripción](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L42-L44) promete "a 228-dim OPTIC-K embedding vector" y da el ejemplo `'x-3-2-0-1-0' for Cmaj7`. Su [parser](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L134-L173) lee el primer elemento como la cuerda 1, la E aguda, igual que el generador de GA. El curso copia ese parser y le pasa el ejemplo:

```text
== ga_generate_voicing_embedding's example diagram, x-3-2-0-1-0
parsed by              GA diagram   MIDI             GA name          pcs
the MCP tool's parser  x-3-2-0-1-0  62 57 50 46 40   Dsus2/E          2 4 9 10
chord chart x32010     0-1-0-2-3-x  64 60 55 52 48   C                0 4 7
```

El ejemplo está escrito como un diagrama de acordes, empezando por la E grave, y se analiza empezando por la E aguda: un asistente que siga la descripción obtiene el vector de otro acorde. Leído empezando por la E grave sería C abierto, y seguiría sin ser Cmaj7. El [curso de programación agéntica](../../agentic-coding/04-mcp/) lo plantea en general: la descripción de una herramienta MCP forma parte de su interfaz, y el modelo se la cree.

## Ejercicios

1. Con la tabla de cosenos, calcula a mano la puntuación ponderada de C abierto frente a G (`320003`), y compárala con la salida.
2. ¿Por qué C abierto frente a Am puntúa 1.000 en ROOT, si sus fundamentales son C y A?
3. Los pesos suman 1,15. Sin cambiar nada del código, ¿cómo convertirías una puntuación de GA en un número entre 0 y 1, y cambiaría eso algún resultado de búsqueda?
4. Reescribe la llamada a `PerceptualQualities` de `VoicingAnalyzer` con argumentos con nombre, respetando la intención evidente del autor.

<details>
<summary>Soluciones</summary>

1. `0.45 × 0.776 + 0.25 × 0.496 + 0.20 × 1.000 + 0.10 × 0.671 + 0.10 × 0.000 + 0.05 × 0.000 = 0.3492 + 0.124 + 0.20 + 0.0671 = 0.740`, el valor impreso.
2. Porque la fundamental del documento es la nota más aguda, y las dos formas tienen E arriba, `64` en sus listas MIDI. El one-hot ROOT de ambas tiene su 1 en la clase de altura 4.
3. Dividir por 1,15, la suma de los pesos, o por la puntuación de un vector consigo mismo. No cambia ningún orden, porque todas las puntuaciones se dividen por la misma constante. Solo importa donde una puntuación se compara con un umbral fijo.
4. `new PerceptualQualities(Brightness: 0, ConsonanceScore: curVoiceChars.Consonance, Roughness: 0, TexturalDescription: "Neutral", Register: "Medium")`. "Respetar la intención" es una suposición: quizá el brillo también debía calcularse. Con argumentos con nombre, al menos la pregunta se ve en la revisión.

</details>

## Puntos clave

- OPTIC-K es un embedding hecho a mano: 240 números con nombre en 11 particiones, de las que 6 particiones y 124 números sirven para la similitud, con pesos que suman 1,15.
- La similitud es una suma ponderada de cosenos por partición; guardar cada partición normalizada y escalada por la raíz cuadrada de su peso la convierte en un único producto escalar.
- El vector es invariante a la octava y al orden de las notas, no a la transposición: el croma de STRUCTURE nombra las notas.
- En el commit `a826864`, la fundamental del documento es la nota más aguda, dos records posicionales ponen valores en el lugar equivocado, y CONTEXT es una constante: los vectores son deterministas, pero varias particiones no significan lo que dicen sus nombres.
- Los comentarios y los documentos describen versiones antiguas (96, 109, 216, 228 dimensiones); el registro, y un programa que lo imprima, son la fuente fiable.

## Fuentes

- Clifton Callender, Ian Quinn y Dmitri Tymoczko, ["Generalized Voice-Leading Spaces"](https://doi.org/10.1126/science.1153021), *Science* 320 (5874), 2008, pp. 346-348.
- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Embeddings` (`EmbeddingSchema.cs`, `MusicalEmbeddingGenerator.cs`, `Services/TheoryVectorService.cs`, `Services/ContextVectorService.cs`, `Services/ModalVectorService.cs`, `Services/RootVectorService.cs`), `Common/GA.Business.ML/Rag/VoicingDocumentFactory.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Analysis` (`VoicingAnalyzer.cs`, `VoicingHarmonicAnalyzer.cs`), `Common/GA.Business.Core/Analysis/Voicings`, `Common/GA.Business.ML/Documentation/Schema`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `state/quality/domain-invariants/README.md`; commits [`95b5a9d9`](https://github.com/GuitarAlchemist/ga/commit/95b5a9d9) y [`3ba35365`](https://github.com/GuitarAlchemist/ga/commit/3ba35365).
- Issue de GA [#616](https://github.com/GuitarAlchemist/ga/issues/616), leída el 2026-09-14.
- Microsoft Learn: [TensorPrimitives.CosineSimilarity](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.cosinesimilarity), [Records](https://learn.microsoft.com/dotnet/csharp/fundamentals/types/records), [Argumentos con nombre y opcionales](https://learn.microsoft.com/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments), [Crc32](https://learn.microsoft.com/dotnet/api/system.io.hashing.crc32).
- Wikipedia, [Similitud del coseno](https://en.wikipedia.org/wiki/Cosine_similarity).
