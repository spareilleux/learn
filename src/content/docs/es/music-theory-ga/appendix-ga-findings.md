---
title: "Apéndice C: cada divergencia, y de quién es el error"
description: Las cuarenta líneas DIFF de las lecciones 1 a 7, cada una con su veredicto —error de Guitar Alchemist o error del curso—, la línea de GA que lo provoca y los diecinueve defectos distintos en los que se resumen.
sidebar:
  label: "Apéndice C: cada divergencia"
  order: 92
---

Cada lección de este curso imprime una tabla con tres columnas: lo que el curso calcula a partir de la definición del libro de texto, lo que Guitar Alchemist responde a la misma pregunta, y `ok` o `DIFF`. Las lecciones 1 a 7 producen **40 líneas `DIFF`**. Quien lea tiene derecho a hacerse la pregunta evidente sobre cada una: *¿es un error de GA, o se equivoca el curso?*

Este apéndice la responde, línea por línea. La versión corta:

| | líneas |
|---|---|
| Error de GA, el curso coincide con la teoría | 39 |
| Ninguno de los dos: una convención defendible (con un fallo real debajo) | 1 |
| Error del curso | 0 |

Cuarenta líneas, pero no cuarenta problemas: se resumen en **19 defectos distintos**, porque una sola línea equivocada puede estropear ocho filas. La agrupación de abajo es la vista útil; las tablas por lección que vienen después son el detalle.

:::note[Cómo comprobar tú mismo cualquier fila]
Nada de lo que hay aquí es una opinión sobre el estilo del código. Cada fila es un valor calculado dos veces y comparado por un programa, en tres sistemas operativos, en un commit fijado de GA. Clona este repositorio y ejecuta `bash code/music-theory-ga/check.sh`, o ejecuta una sola lección con `dotnet run --project code/music-theory-ga/GaTheory -c Release -- l3`. GA se lee en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) y nunca se modifica.
:::

## Los 19 defectos

| # | Defecto en GA | Líneas | Lecciones |
|---|---|---|---|
| 1 | [`Pitch.Flat.DFlat/FFlat/GFlat(Octave)`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295) construyen la nota equivocada: cada uno devuelve la nota de la línea siguiente | 3 | 1 |
| 2 | La regex de [`PitchParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs#L20-L25) no tiene anclas e ignora las mayúsculas, así que `Eb2` coincide como `b2` = B2 | 1 | 1 |
| 3 | [`Note.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L219-L237) pasa a mayúsculas antes de sustituir `♭`, así que `B` se convierte en B♭ y `D♭` se rechaza | 1 | 1 |
| 4 | [`PitchClass.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L252-L268) prueba los alias hexadecimales `A`=10, `B`=11 antes que los nombres de notas | 1 | 1 |
| 5 | [`SimpleIntervalSize.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Intervals/SimpleIntervalSize.cs#L155-L164) y `CompoundIntervalSize.TryParse` lanzan una excepción en lugar de devolver `false` | 1 | 1 |
| 6 | [`ModalFamily`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/ModalFamily.cs#L114-L128) agrupa los conjuntos por vector interválico pero llama `Modes` a sus miembros | 2 | 2 |
| 7 | [`ChordFormula.DetermineQuality`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L172-L214) nunca devuelve `Major7`, `Minor7`, `HalfDiminished` ni `Diminished7` | 2 | 3 |
| 8 | [`DetermineExtension`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L216-L294) lee nueve semitonos como una sexta mayor, nunca como una séptima disminuida | 1 | 3 |
| 9 | [`Note.Chromatic.ToAccidented`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L75-L77) es `ToSharp().ToAccidented()`: cada tecla negra recibe un nombre con sostenido | 8 | 3 |
| 10 | [`Chord`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/Chord.cs#L241-L250) rota su lista de notas para una inversión y luego la reanaliza desde el bajo como si fuera la fundamental | 1 | 3 |
| 11 | [`Voicing.HasBarre`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Fretboard/Voicings/Core/Voicing.cs#L73-L80) cuenta el traste 0, así que las cuerdas al aire forman una cejilla | 3 | 3 |
| 12 | [`IntervalClassVectorId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVectorId.cs#L39-L85) empaqueta seis recuentos como dígitos en base 12, y un recuento de 12 desborda su dígito | 1 | 4 |
| 13 | [`KeyTools.GetParallelKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L161-L166) tiene el mismo cuerpo que `GetRelativeKey`: conserva la armadura en lugar de la tónica | 5 | 5 |
| 14 | [`KeyTools.GetNeighboringKeys`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L204) busca una tonalidad por sus alteraciones en lugar de por su nombre, y lanza una excepción | 1 | 5 |
| 15 | [`Key.GetInterval`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L76) pasa sus argumentos al revés y devuelve la inversión | 2 | 5 |
| 16 | [`Key.Major.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L155-L158) lanza una excepción ante una fundamental no analizable aunque tiene un camino `return false` | 1 | 5 |
| 17 | [`HarmonicFunction.FromDegree`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/HarmonicFunction.cs#L32) solo ve un número de grado, y su enum no tiene `Subtonic` | 1 | 6 |
| 18 | [`Cadences.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Cadences.yaml#L124-L129) numera una fila en tonalidad menor desde el mayor homónimo (`♭iii` para G en E menor) | 1 | 7 |
| 19 | [`PitchClassSet.ClosestDiatonicKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L609-L615) resuelve el empate mayor/menor con una forma normal, que no puede codificar un modo | 4 | 7 |

Tres patrones explican la mayoría de ellos.

- **Copiar y pegar dentro de un bloque de miembros casi idénticos**: los defectos 1 y 13. Tres métodos de fábrica que devuelven cada uno la nota de la línea siguiente, y un `GetParallelKey` cuyo cuerpo nunca se cambió después de copiarlo de `GetRelativeKey`.
- **Una clase de altura a la que se le pide recordar una letra**: los defectos 8, 9 y 12, y el núcleo del 19. Una clase de altura, un id de conjunto y un recuento de intervalos son todos *reducciones*: tiran a propósito la grafía, la octava o la tónica. Cada fila de este grupo es esa información descartada que se vuelve a pedir más abajo.
- **`TryParse` que lanza excepciones**: los defectos 5 y 16, en tres tipos. El contrato de [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse) dice que un análisis fallido devuelve `false`.

## Lección 1: notas, clases de altura y el mástil

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| `Pitch.Flat.DFlat(4)` → `Db4` | `D4` | GA, defecto 1 | El método construye `Note.Flat.D`, la natural, aunque `Note.Flat.DFlat` existe. |
| `Pitch.Flat.FFlat(4)` → `Fb4` | `G4` | GA, defecto 1 | Construye `Note.Flat.G`. F♭ es enarmónicamente E y nunca puede ser G. |
| `Pitch.Flat.GFlat(4)` → `Gb4` | `A4` | GA, defecto 1 | Construye `Note.Flat.A`, otra vez la nota de la línea siguiente. |
| `Pitch.Sharp.TryParse("Eb2")` → rechazado | `B2` | GA, defecto 2 | `([A-G])(#?)(10\|11\|[0-9])` no tiene anclas y no distingue mayúsculas, así que la coincidencia se salta la `E` y lee `b2`. |
| `Note.Flat.Parse("B")` → `B` | `Bb` | GA, defecto 3 | `ToUpperInvariant()` se ejecuta antes que `Replace("♭", "b")`, así que la prueba de la `B` final se dispara de más y de menos. |
| `PitchClass.Parse("A")` → `9` | `10` | **Ninguno** | Leer `A` como el dígito 10 es una convención documentada de la teoría de conjuntos, así que 10 no está mal. Pero los alias se prueban antes que los nombres de notas, así que la nota A no se puede analizar nunca como 9: esa parte sí es un defecto. |
| `IntervalSize.TryParse("x")` → `False` | lanza `ArgumentException` | GA, defecto 5 | `SimpleIntervalSize` y `CompoundIntervalSize` lanzan los dos una excepción donde el contrato exige `false`. |

Un hallazgo más que no aparece en ninguna fila: el bloque de fábricas `Flat(Octave)` **no tiene ningún `EFlat(Octave)` ni ningún `BFlat(Octave)`**, aunque las propiedades por octava `EFlat0`, `BFlat0` y sus hermanas sí existen. Solo esa familia de sobrecargas no es de fiar.

## Lección 2: escalas y modos

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| la menor armónica tiene 7 modos | 14 | GA, defecto 6 | Un modo es una rotación, así que una escala de siete notas tiene siete. Los 14 de GA son las 7 rotaciones de la menor armónica más las 7 de su imagen especular, la mayor armónica, que tiene el mismo vector interválico. |
| la escala de blues tiene 6 modos | 24 | GA, defecto 6 | 6 rotaciones, 6 de la imagen especular y 12 conjuntos de una clase relacionada por Z que comparte el vector. |

El comentario de clase de GA describe lo que construye de verdad —conjuntos "that share the same interval vector"—, así que el cálculo es correcto y lo que está mal es el *nombre*. [Ian Ring](https://ianring.com/musictheory/scales/2477) responde 7 y 6.

## Lección 3: acordes, cifrados, inversiones y voicings

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| `Cmaj7` → `maj7` | `7` | GA, defecto 7 | Mayor más séptima, y `Major` no aporta ningún prefijo, así que imprime el cifrado del acorde de séptima de dominante. |
| `Cm7b5` → `m7b5` | `dim7` | GA, defecto 7 | El acorde semidisminuido se imprime con el cifrado del totalmente disminuido. |
| `Cdim7` → `dim7` | `dim6` | GA, defecto 8 | Los nueve semitonos se leen como una sexta mayor; solo la grafía B𝄫 dice lo contrario, y una fórmula en semitonos no tiene ninguna. |
| `Cm` → `C Eb G` | `C D# G` | GA, defecto 9 | |
| `Eb` → `Eb G Bb` | `Eb G A#` | GA, defecto 9 | Por sus letras, E♭–A♯ es una cuarta, no la quinta del acorde. |
| `Ab` → `Ab C Eb` | `Ab C D#` | GA, defecto 9 | |
| `Bbm7` → `Bb Db F Ab` | `Bb C# F G#` | GA, defecto 9 | Dos de los cuatro grados caen en la letra equivocada. |
| `Cdim` → `C Eb Gb` | `C D# F#` | GA, defecto 9 | F♯ nombra una cuarta aumentada, no una quinta disminuida. |
| `Cdim7` → `C Eb Gb Bbb` | `C D# F# A` | GA, defecto 9 | El doble bemol es la grafía del libro de texto; A es una sexta. |
| `Gb7` → `Gb Bb Db Fb` | `Gb A# C# E` | GA, defecto 9 | |
| ejercicio: `F#dim7` → `F# A C Eb` | `F# A C D#` | GA, defecto 9 | Las letras de un acorde de séptima disminuida son F A C E. |
| `C/E` → inversión 1, Major | inversión 1, Other | GA, defecto 10 | Tras la rotación el bajo queda en `Notes[0]`, así que el nuevo análisis se salta la tercera y no encuentra ninguna. |
| `032010` no es una cejilla | cejilla | GA, defecto 11 | |
| `022100` no es una cejilla | cejilla | GA, defecto 11 | |
| `320003` no es una cejilla | cejilla | GA, defecto 11 | Tres cuerdas al aire comparten el «traste 0»; ningún dedo pisa una cuerda al aire. |

Dos de estos tienen una implementación correcta en otro lugar del mismo commit: [`CadenceChordParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Chords/Parsing/CadenceChordParser.cs#L11-L14) y el [`DslCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Types/DslCommand.fs#L227-L230) en F# conocen los cifrados correctos, y [`DetectBarreRequirement`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L219-L233) sí comprueba `fret > 0` y sí exige que las cuerdas sean contiguas.

## Lección 4: clases de conjuntos

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| ICV del agregado cromático → `<12 12 12 12 12 6>` | `<1 1 1 1 0 6>` | GA, defecto 12 | Los recuentos se calculan bien y luego se empaquetan como dígitos en base 12, donde el 12 no cabe. |

GA lo documenta él mismo, como una "KNOWN LIMITATION" en el comentario del propio tipo, y anota como solución la base 13 o un record de seis campos. Es el único conjunto afectado: un conjunto de 11 notas llega como máximo a 10 por clase de intervalo.

## Lección 5: tonalidades y el círculo de quintas

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| homónima de C → C menor | A menor | GA, defecto 13 | La tonalidad homónima comparte la *tónica*; GA conserva la *armadura*, que es la tonalidad relativa. |
| homónima de A♭ → A♭ menor | F menor | GA, defecto 13 | |
| homónima de A menor → A mayor | C mayor | GA, defecto 13 | |
| homónima de E menor → E mayor | G mayor | GA, defecto 13 | |
| ejercicio: homónima de A♭ → A♭ menor, 7 bemoles | F menor | GA, defecto 13 | El ejercicio repite la misma expresión. |
| vecinas de C → F, G | lanza `InvalidOperationException` | GA, defecto 14 | La herramienta vuelve a buscar la tonalidad por `""` (las alteraciones de C mayor) en lugar de por `"Key of C"`. |
| `Key.Major.C.GetInterval(E)` → M3 | m6 | GA, defecto 15 | |
| `Key.Major.G.GetInterval(F#)` → M7 | m2 | GA, defecto 15 | Los dos devuelven la inversión del intervalo documentado. |
| `Key.Major.TryParse("H")` → `False` | lanza una excepción | GA, defecto 16 | El método tiene un camino `return false` unas líneas más abajo. |

El núcleo de GA no tiene ningún miembro para la tonalidad relativa ni para la homónima, así que la herramienta MCP es el único código que responde a estas dos preguntas. El comentario dentro del método *correcto* ya intercambia las dos palabras, así que la confusión está en el vocabulario y no solo en un cuerpo de método.

## Lección 6: los acordes de una tonalidad

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| VII de A menor natural → G mayor, **Subtonic** | **LeadingTone** | GA, defecto 17 | El séptimo grado de la menor natural está un tono entero por debajo de la tónica, así que es la subtónica; una sensible está un semitono por debajo. |

## Lección 7: cadencias y progresiones

| Fila | GA responde | Veredicto | Por qué |
|---|---|---|---|
| Chromatic Mediant (Metal), Em–Gm en E menor → `i iii` | `i biii` | GA, defecto 18 | G es el tercer grado sin alterar de E menor. Leído en E menor, ♭iii señala un G♭, que el acorde no contiene. El propio analizador en F# de GA usa los números romanos de la escala menor. |
| tonalidad de `C F G C` → C mayor | A menor | GA, defecto 19 | |
| tonalidad de `G D Em C` → G mayor | E menor | GA, defecto 19 | |
| tonalidad de `Dm7 G7 Cmaj7` → C mayor | A menor | GA, defecto 19 | |
| tonalidad de `C Am F G7` → C mayor | A menor | GA, defecto 19 | Toda colección diatónica de siete notas tiene la forma normal `0 1 3 5 6 8 T`, que contiene 3, así que la marca de modo se activa siempre y la respuesta es siempre la relativa menor. |

Las cuatro últimas merecen separarse del resto de este apéndice, porque el arreglo no es una línea: un conjunto de clases de altura **no tiene tónica**. `C F G C` y `Am F C G` son el mismo conjunto. Ninguna función del conjunto por sí solo puede nombrar una de las dos tonalidades relativas; nombrar una exige el orden de los acordes, que `ClosestDiatonicKey` nunca recibe. Devolver una armadura, o el par —cosa que `GetCompatibleKeys` ya hace—, es la respuesta honesta para esa entrada.

## Lo que este apéndice no es

No es un informe de errores presentado contra GA, y nada de lo que hay aquí se ha publicado fuera de este repositorio. Es el registro de lo que quien lee debería concluir cuando una lección imprime `DIFF`: en este curso, hasta ahora, ha significado GA todas las veces menos una.

Tampoco es una afirmación de que el curso sea la autoridad. Los cálculos del propio curso son implementaciones llanas de definiciones de libro de texto, y su regla de la cejilla, su heurística para encontrar la tonalidad y su tabla de cifrados son todas aproximaciones que declara como tales allí donde aparecen. Donde el curso y GA coinciden, los dos podrían estar equivocados; esas filas imprimen `ok` y este apéndice no dice nada de ellas.

## Fuentes

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/) v2: ["Triads"](https://viva.pressbooks.pub/openmusictheory/chapter/triads/), ["Seventh Chords"](https://viva.pressbooks.pub/openmusictheory/chapter/seventh-chords/), ["Mediants"](https://viva.pressbooks.pub/openmusictheory/chapter/mediants/), ["Roman Numerals"](https://viva.pressbooks.pub/openmusictheory/chapter/roman-numerals/), "Minor Scales, Scale Degrees, and Key Signatures".
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): [la menor armónica](https://ianring.com/musictheory/scales/2477), [la escala de blues](https://ianring.com/musictheory/scales/1257), [la escala cromática](https://ianring.com/musictheory/scales/4095).
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [Barre chord](https://en.wikipedia.org/wiki/Barre_chord), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).
