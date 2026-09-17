---
title: "Lección 3: El índice y la búsqueda"
description: Construir un índice OPTIC-K pequeño con el propio escritor de Guitar Alchemist, leer su cabecera binaria byte a byte, proyectarlo en memoria, buscar en él por cifrado de acorde y medir cuáles de sus 124 dimensiones no varían nunca.
sidebar:
  label: 3. El índice y la búsqueda
  order: 3
---

El índice de voicings en producción de GA contiene 313.047 voicings de guitarra, bajo y ukelele. Construirlo lleva minutos y un clon del repositorio entero, así que esta lección construye uno pequeño con el mismo código: todos los voicings de tres notas o más en los tres primeros trastes de una guitarra. El archivo tiene el mismo formato, la misma cabecera y la misma búsqueda, y cada número de esta lección sale de él.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l3
```

## El corpus

[`VoicingGenerator.GenerateAllVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs#L156) desliza una ventana de unos pocos trastes a lo largo del mástil y produce cada combinación de cuerdas tocadas y silenciadas. Cada voicing pasa luego por los tres pasos de la lección 2, las mismas llamadas que el bucle de exportación de GA en [`FretboardVoicingsCLI`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/Program.cs#L813-L839), sin su eliminación de duplicados:

```text
== Corpus: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
  with 3 notes           1280
  with 4 notes           3840
  with 5 notes           6144
  with 6 notes           4096
first three, as generated:
diagram        MIDI (in order)    GA name      doc root
0-0-0-x-x-x    64 59 55           Em/G         E
1-0-0-x-x-x    65 59 55           G7(shell)    F
2-0-0-x-x-x    66 59 55           Gmaj7(shell) F#
```

Los recuentos sirven de comprobación: un mástil de 3 trastes tiene los trastes 0 a 3, cuatro opciones por cada cuerda tocada, así que los voicings de seis notas son `4⁶ = 4096`, y los de cinco notas `6 × 4⁵ = 6144`, seis formas de elegir la cuerda silenciada. Los diagramas empiezan por la cuerda 1, la E aguda, y la "doc root" vuelve a ser la nota más aguda de cada forma. La [skill `optic-k-rebuild`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/optic-k-rebuild/SKILL.md) de GA da la escala del índice real: unos 667.000 voicings de guitarra en bruto, 298.000 tras eliminar duplicados, unos 140 segundos.

## El formato del archivo

[`OptickIndexWriter`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs) recibe una lista de `VoicingEntry(float[] Embedding, string Diagram, string Instrument, int[] MidiNotes, string? QualityInferred)` y escribe un archivo. El curso vuelve a leer su cabecera con un `BinaryReader`, campo a campo, en el orden en que los escribe [`WriteHeader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L233-L258):

```text
== The header OptickIndexWriter wrote (little-endian)
magic                    OPTK
format version           4
header size              616
schema hash              0x37CD8ECF
endian marker            0xFEFF
dimension                124
voicings                 15360
instruments              3
  guitar   offset 123496, count 15360
  bass     offset 7742056, count 0
  ukulele  offset 7742056, count 0
metadata offsets at      616
vectors at               123496 (15360 x 124 x 4 bytes = 7618560)
metadata at              7742056 (1233243 bytes of msgpack)
sqrt weights, first dims 0.67 0.67 0.67 ... ROOT 0.22
file size                8975299 bytes
```

La disposición, sección por sección:

| Bytes | Contenido |
|---|---|
| 0 a 615 | la cabecera: número mágico, versión, hash del esquema, dimensión, recuento, un desplazamiento y un recuento por instrumento, cuatro desplazamientos de sección y luego 124 pesos `float` |
| 616 a 123.495 | un desplazamiento de 8 bytes por voicing hacia los metadatos: `15,360 × 8 = 122,880` bytes |
| 123.496 a 7.742.055 | los vectores: 124 `float`s por voicing, un instrumento tras otro |
| 7.742.056 hasta el final | los metadatos, un registro [MessagePack](https://msgpack.org/) por voicing: diagrama, instrumento, notas MIDI, nombre |

Los pesos de la cabecera son las raíces cuadradas de los pesos de las particiones: `√0.45 = 0.67`, `√0.05 = 0.22`. El **marcador de orden de bytes** `0xFEFF` permite que un lector en una máquina big-endian note que los bytes están invertidos. El **hash del esquema** es el CRC-32 de la cadena de disposición de la lección 2; [`OptickIndexReader`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L64-L76) lanza `InvalidDataException` cuando no coincide con el suyo, así que un programa compilado con otra disposición no puede leer en silencio números equivocados. El resumen del escritor todavía dice que conserva "the 112 search-relevant dims" ([línea 11](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Demos/Music%20Theory/FretboardVoicingsCLI/OptickIndexWriter.cs#L11)); el archivo dice 124.

Un formato así es lo que diseñarías en C# para un array grande de solo lectura: registros de tamaño fijo a los que se llega con aritmética, y datos de tamaño variable detrás de una tabla de desplazamientos. Las particiones de información de la lección 2 no están en el archivo.

## Volver a leerlo

`OptickIndexReader` no carga el archivo en memoria: lo [proyecta en memoria](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile) ([líneas 50-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickIndexReader.cs#L50-L55)) y entrega cada vector como un `ReadOnlySpan<float>` que apunta a las páginas proyectadas. El sistema operativo carga las páginas que se tocan, y varios procesos pueden compartirlas.

```text
== OptickIndexReader
Count                    15360
guitar range             (0, 15360)
bass range               (15360, 0)
voicing 0                0-0-0-x-x-x Em/G [64 59 55]
its squared norm         1.150
max |disk - ExtractCompact| 1.5e-8
```

La norma al cuadrado de cada vector almacenado es 1,15: cada partición tiene norma 1 multiplicada por `√w`, así que su contribución al cuadrado es `w`, y los pesos suman 1,15. La última línea compara los `float` almacenados con `EmbeddingSchema.ExtractCompact` calculado en `double`: coinciden hasta 1,5 × 10⁻⁸, la precisión de un `float`.

La proyección en memoria tiene un coste sobre el que avisa la skill de GA: en Windows, un proceso en ejecución que tiene el índice abierto bloquea el archivo, y una reconstrucción "WILL fail with IOException" mientras GaApi y el servidor MCP de GA no se detengan.

## Buscar

[`OptickSearchStrategy.SearchInternal`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L164-L262) es una búsqueda exacta de vecinos más cercanos, los `k` vecinos más cercanos por fuerza bruta del [curso de IX](../../machine-learning-ix/03-classification/), con un producto escalar en lugar de una distancia:

- un [`TensorPrimitives.Dot`](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot) por voicing, acelerado con SIMD, sobre los vectores proyectados;
- un [`Parallel.For`](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for) sobre los voicings, en el que cada hilo mantiene su propia [`PriorityQueue`](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2) de los `k` mejores, fusionadas al final;
- los empates se deshacen por índice, el menor primero, para que el resultado no dependa de la planificación de los hilos. El comentario explica por qué: muchos voicings comparten un conjunto de clases de altura y, por tanto, una puntuación.

Ni índice aproximado ni árbol: para el índice en producción, son 313.047 × 124, unos 39 millones de multiplicaciones por consulta.

### El vector de consulta

Un mensaje de chat no tiene mástil, así que [`MusicalQueryEncoder`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L109) rellena solo lo que puede dar un cifrado de acorde: STRUCTURE a partir de las clases de altura, MODAL, SYMBOLIC cuando hay etiquetas y ROOT cuando el cifrado tiene fundamental. MORPHOLOGY y CONTEXT se quedan a cero, igual que el vector interválico dentro de STRUCTURE, "not yet wired into the query path" ([líneas 52-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L52-L58)). La mejor puntuación posible queda, por tanto, por debajo de `0.45 + 0.10 + 0.05 = 0.60`.

### Cmaj7

```text
== HybridSearchAsync for "Cmaj7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-x-2-2-x    60 52 47           Cmaj7(shell)/B 0.458
2     x-1-x-x-2-0    60 47 40           Cmaj7(shell)/E 0.458
3     x-1-x-2-2-0    60 52 47 40        Cmaj7(shell)/E 0.458
4     x-1-0-2-2-x    60 55 52 47        Cmaj7/B      0.419
5     x-1-0-x-2-0    60 55 47 40        Cmaj7/E      0.419
with the filter ChordName = "Cmaj7":
rank  diagram        MIDI               name         score
1     3-0-x-2-3-x    67 59 52 48        Cmaj7        0.369
2     3-0-0-2-3-x    67 59 55 52 48     Cmaj7        0.369
```

Todos los resultados sin filtrar tienen C, MIDI 60, como nota más aguda, y ninguno tiene C en el bajo: son inversiones y voicings reducidos (shells). Las dos formas de Cmaj7 en estado fundamental salen más abajo, con 0.369, porque su nota más aguda es G. La consulta dice "fundamental C"; el índice guardó la nota más aguda como fundamental (lección 2). Una búsqueda por cifrado de acorde premia las formas que tienen la fundamental arriba.

[`HybridSearchAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L49-L73) añade filtros después de la búsqueda: toma `max(10 × limit, 100)` candidatos, y luego [`ApplyFilters`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L296-L329) separa `"Cmaj7"` en una fundamental, C, y una calidad, `maj7`, y conserva los candidatos cuyo nombre contiene `maj7` y cuya nota **más grave** es un C. El filtro usa el bajo real; los vectores usaron la nota más aguda. Solo pasan dos formas, y son las dos que muestra el chatbot de la lección 4.

### Am7 y C

```text
== HybridSearchAsync for "Am7" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-x-2-x-3-3    57 48 43           Am7(shell)/G 0.458
2     x-x-2-2-3-x    57 52 48           Am/C         0.450
3     x-x-2-x-3-0    57 48 40           Am/E         0.450
4     x-x-2-2-3-0    57 52 48 40        Am/E         0.450
5     x-x-2-2-3-3    57 52 48 43        Am7/G        0.419
with the filter ChordName = "Am7":
rank  diagram        MIDI               name         score
1     2-x-x-2-0-x    66 52 45           Gbm7(shell)/A 0.342
2     2-x-2-2-0-x    66 57 52 45        Gbm7(shell)/A 0.342

== HybridSearchAsync for "C" (query vector from MusicalQueryEncoder)
query partitions set: STRUCTURE, MODAL, ROOT
rank  diagram        MIDI               name         score
1     x-1-0-2-x-x    60 55 52           C/E          0.481
2     x-1-0-2-3-x    60 55 52 48        C            0.481
3     x-1-0-x-x-0    60 55 40           C/E          0.481
4     x-1-0-2-x-0    60 55 52 40        C/E          0.481
5     x-1-0-x-3-0    60 55 48 40        C/E          0.481
with the filter ChordName = "C":
rank  diagram        MIDI               name         score
1     x-1-0-2-3-x    60 55 52 48        C            0.481
2     x-1-x-2-3-x    60 52 48           C + E (Major 3rd) 0.453
3     x-1-0-x-3-x    60 55 48           C5           0.415
4     x-1-2-2-3-x    60 57 52 48        Am/C         0.393
5     x-1-x-0-3-x    60 50 48           C + D (Major 2nd) 0.367
```

La prueba de calidad es una prueba de subcadena, así que el filtro `Am7` acepta una forma llamada `Gbm7(shell)/A`: su nombre contiene `m7` y su nota más grave es un A. Para `"C"`, la calidad es la cadena vacía, que contienen todos los nombres: el filtro conserva cualquier cosa con C en el bajo, incluida una forma con solo C y E, y Am/C.

### Los voicings más cercanos a un voicing

```text
== Nearest voicings to 0-1-0-2-3-x (open C), by its own compact vector
rank  diagram        MIDI               name         score
1     0-1-0-2-3-x    64 60 55 52 48     C            1.150
2     0-1-0-2-x-3    64 60 55 52 43     C/G          1.150
3     0-1-0-x-3-x    64 60 55 48        C            1.149
4     0-1-0-x-x-3    64 60 55 43        C/G          1.149
5     0-1-x-2-x-3    64 60 52 43        C/G          1.149
6     0-1-0-2-x-0    64 60 55 52 40     C/E          1.139
FindSimilarVoicingsAsync("0-1-0-2-3-x") returned 0 results
```

Buscar con un vector almacenado encuentra primero C abierto, y luego C/G con la misma puntuación hasta tres decimales: pasar el bajo de C a G, un cambio que cualquier guitarrista oye, casi no cuesta nada, porque el "bajo" del vector es la nota más aguda, E en los dos. El método pensado para esto, [`FindSimilarVoicingsAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L75-L92), devuelve una lista vacía para cualquier entrada: los metadatos OPTK "is keyed by index, not voicing id", y registra un aviso una sola vez.

## Dimensiones que no varían nunca

Una dimensión que tiene el mismo valor para todos los voicings suma la misma cantidad a todas las puntuaciones: no puede cambiar un orden. El curso las cuenta sobre el corpus:

```text
== Dimensions that never vary over the 15360 voicings
partition     dims  always 0  constant  weight
IDENTITY      6     3         3         0.00
STRUCTURE     24    2         1         0.45
MORPHOLOGY    24    5         0         0.25
CONTEXT       12    11        1         0.20
SYMBOLIC      12    3         2         0.10
EXTENSIONS    18    6         1         0.00
SPECTRAL      13    0         0         0.00
MODAL         40    16        0         0.10
HIERARCHY     15    14        0         0.00
ATONAL_MODAL  64    47        0         0.00
ROOT          12    0         0         0.05
in the 124 compact dims: 37 always 0, 4 constant
named MODAL slots never set (9 of 33): LocrianNatural6, DorianSharp4, LydianSharp2, AlteredDoubleFlat7, DorianFlat2, LydianAugmented, MixolydianFlat6, LocrianNatural2, Diminished
MODAL slots without a name constant: 7
```

- **CONTEXT**, peso 0,20: 11 dimensiones siempre a cero y una constante, la tensión de la lección 2. La issue [#616](https://github.com/GuitarAlchemist/ga/issues/616) midió lo mismo en el índice en producción, y 40 dimensiones muertas de 124; este corpus es pequeño, pero encuentra 41 que no varían nunca.
- **ATONAL_MODAL**: las 47 posiciones que el array de 17 elementos de la lección 2 no puede alcanzar.
- **MODAL**: 9 de las 33 posiciones con nombre no se activan nunca. [`ModalVectorService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs#L165-L178) busca cada modo por un nombre visible como `"Locrian ♮6"` o `"Dorian ♯4"`, y vuelve sin escribir cuando la búsqueda no encuentra intervalos; un nombre que la búsqueda no conoce explicaría estas nueve (*por verificar*). Algunos ceros también pueden ser reales: un corpus de tres trastes tiene pocos voicings de los modos más raros.

## Ejercicios

1. La cabecera dice que los vectores empiezan en el byte 123.496 y los metadatos en el 7.742.056. Comprueba los dos números a partir del tamaño de la cabecera, el recuento y la dimensión.
2. ¿Por qué la norma al cuadrado de cada vector almacenado es exactamente la suma de los pesos, y cuánto valdría para un voicing cuya partición SYMBOLIC es toda ceros?
3. Un usuario pide al chatbot "C voicings". Con los resultados filtrados para `"C"`, enumera lo que objetaría un guitarrista.
4. Escribe el bucle de productos escalares de `SearchInternal` para un solo hilo, sin el montículo: un `for` sobre los voicings que conserva la mejor puntuación y su índice.

<details>
<summary>Soluciones</summary>

1. La tabla de desplazamientos empieza justo después de la cabecera, en 616, con 8 bytes por voicing: `616 + 15,360 × 8 = 123,496`. Los vectores ocupan `15,360 × 124 × 4 = 7,618,560` bytes: `123,496 + 7,618,560 = 7,742,056`. El archivo termina `1,233,243` bytes de metadatos más adelante, en 8.975.299, el tamaño impreso.
2. `ExtractCompact` divide cada partición por su norma y la multiplica por `√w`, así que la norma al cuadrado de cada partición es `w`, y las normas al cuadrado de partes disjuntas se suman. Una partición toda a ceros se queda a cero, así que la norma al cuadrado de ese voicing sería `1.15 − 0.10 = 1.05`.
3. La forma `x-1-x-2-3-x` solo tiene dos clases de altura, C y E, y se llama "C + E (Major 3rd)"; `x-1-0-x-3-x` es un power chord C5, sin tercera; `x-1-2-2-3-x` es Am/C, otro acorde; `x-1-x-0-3-x` es C y D. Solo el primer resultado es un acorde de C mayor. El filtro comprueba el bajo y una subcadena del nombre, y la calidad vacía de `"C"` coincide con todos los nombres.
4. Por ejemplo:

   ```csharp
   var best = (Score: float.NegativeInfinity, Index: -1L);
   for (long i = start; i < start + count; i++)
   {
       var score = TensorPrimitives.Dot(q.AsSpan(), reader.GetVector(i));
       if (score > best.Score) best = (score, i); // estricto: el índice menor gana los empates
   }
   ```

   El `>` estricto conserva el primer índice, el menor, entre puntuaciones iguales, el mismo desempate que los montículos de GA.

</details>

## Puntos clave

- Un índice OPTK es un archivo binario plano: una cabecera con un hash del esquema, una tabla de desplazamientos, vectores `float` de tamaño fijo con las 124 dimensiones de similitud, y metadatos MessagePack. Se proyecta en memoria, no se carga.
- La búsqueda es exacta: un producto escalar SIMD por voicing, montículos top-k por hilo y empates deshechos por índice para obtener resultados deterministas.
- El codificador de consultas solo puede rellenar STRUCTURE (sin su vector interválico), MODAL, SYMBOLIC y ROOT, así que las puntuaciones de un cifrado de acorde se quedan por debajo de 0,60.
- Como la fundamental almacenada es la nota más aguda mientras que el filtro usa el bajo, una búsqueda de "Cmaj7" pone primero las formas con C arriba, y el filtrado solo conserva dos formas del corpus pequeño; el filtro por nombre es una prueba de subcadena.
- Sobre 15.360 voicings, 41 de las 124 dimensiones buscadas no varían nunca, CONTEXT entre ellas: una parte de cada puntuación es una constante.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Demos/Music Theory/FretboardVoicingsCLI` (`OptickIndexWriter.cs`, `Program.cs`), `Common/GA.Business.ML/Search` (`OptickIndexReader.cs`, `OptickSearchStrategy.cs`, `MusicalQueryEncoder.cs`), `Common/GA.Business.ML/Embeddings/Services/ModalVectorService.cs`, `Common/GA.Domain.Services/Fretboard/Voicings/Generation/VoicingGenerator.cs`, `.claude/skills/optic-k-rebuild/SKILL.md`.
- Issue de GA [#616](https://github.com/GuitarAlchemist/ga/issues/616), leída el 2026-09-14.
- Microsoft Learn: [MemoryMappedFile](https://learn.microsoft.com/dotnet/api/system.io.memorymappedfiles.memorymappedfile), [TensorPrimitives.Dot](https://learn.microsoft.com/dotnet/api/system.numerics.tensors.tensorprimitives.dot), [PriorityQueue](https://learn.microsoft.com/dotnet/api/system.collections.generic.priorityqueue-2), [Parallel.For](https://learn.microsoft.com/dotnet/api/system.threading.tasks.parallel.for), [BinaryReader](https://learn.microsoft.com/dotnet/api/system.io.binaryreader).
- [Especificación de MessagePack](https://github.com/msgpack/msgpack/blob/8aa09e2a6a9180a49fc62ecfefe149f063cc5e4b/spec.md).
