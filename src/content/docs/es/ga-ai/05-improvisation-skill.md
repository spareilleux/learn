---
title: "Lección 5: La skill de improvisación y la teoría acorde–escala"
description: La skill de improvisación de Guitar Alchemist llamada directamente, sin modelo, y contrastada con la teoría acorde–escala — cómo lee una serie de acordes, el arpegio y la escala que da a cada uno, dónde se salen del acorde o de la tonalidad, y un pequeño oráculo que encuentra la tonalidad y la escala de manual.
sidebar:
  label: 5. La skill de improvisación
  order: 5
---

La lección 4 terminó con preguntas que una skill determinista responde sin modelo. Esta lección toma una que los guitarristas hacen a todas horas, "which arpeggio fits Am F C G?" (¿qué arpegio encaja sobre Am F C G?), y la skill que la responde, [`ImprovisationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs). El programa llama a la skill directamente, como la lección 4 llamó a la skill de tonalidad relativa, y comprueba cada respuesta con un pequeño oráculo escrito a partir de las definiciones de manual: qué notas tiene cada acorde, qué notas tiene cada escala y qué tonalidad implica una progresión. La música que hay detrás está en dos lecciones del curso de teoría musical, [escalas y modos](../../music-theory-ga/02-scales-and-modes/) y [los acordes de una tonalidad](../../music-theory-ga/06-diatonic-chords/).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). El archivo de la skill sigue igual en el `main` de GA, en [`8cd5042`](https://github.com/GuitarAlchemist/ga/commit/8cd5042b91e38eb9949566dc3584fa0a42089788) (comprobado el 2026-09-28), así que las respuestas que siguen son todavía las del chatbot. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l5
```

## La respuesta de la skill

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G")
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  | - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  |
  | Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
assumption: Each chord classified independently from its written quality; no key inferred.
```

Una línea por acorde: un arpegio, que desgrana las notas del acorde, y una escala para tocar encima, la primera de una lista ordenada por preferencia. La última línea dice cómo: cada acorde se clasifica por separado, a partir de la cualidad escrita en su cifrado, y no se infiere ninguna tonalidad. El comentario de la skill explica esa elección ([líneas 22-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)). La alternativa obvia, inferir la tonalidad y dar a cada acorde el modo de su grado, "is wrong for any borrowed or secondary chord" (falla con cualquier acorde prestado o secundario): un acorde de A mayor en C mayor cae sobre el grado vi, cuyo modo es el eólico, con un C natural contra el C♯ del acorde. Leyendo la cualidad escrita, ese error es imposible.

Pero comete otro. F y G son tríadas mayores, así que las dos reciben el jónico, la primera escala que la skill propone para un acorde mayor ([líneas 360-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L360-L436)). F jónico tiene un B♭ y G jónico un F♯; la progresión no tiene ninguno de los dos. La nota de color que la propia skill asocia al jónico dice "careful on the IV chord" (cuidado con el acorde de IV), y aun así lo pone en cabeza sobre ese acorde.

El recorrido, en [`ExecuteAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L117-L128) y [`BuildProgressionResponse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261):

1. `ExtractChordRun` extrae los cifrados de acorde del mensaje con una [expresión regular generada por un generador de código fuente](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators) ([líneas 453-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L453-L462)). Con dos acordes o más se toma la vía de progresión, antes de probar ninguna otra cosa.
2. Para cada acorde, `ExtractRoot` e `InferQuality` ([líneas 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)) separan el cifrado en una fundamental y una cualidad, `ArpeggioFor` ([líneas 266-284](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L266-L284)) nombra el arpegio, y `ScalesFor` enumera las escalas, la mejor primero.
3. El texto de la respuesta, su `Evidence` y su `Data` llevan los mismos resultados, acorde por acorde.

Solo la vía de un único acorde llama a un modelo, a través del `IMusicalQueryExtractor` que recibe la skill. El curso le pasa uno que lanza una excepción, así que la ejecución fallaría si la vía de progresión llegara a usarlo; no lo usa. Como otra dependencia, la skill recibe un [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1), y el programa lee `Data` con [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement): cada fila de abajo es lo que devolvió la skill, no texto extraído de su respuesta.

## Un oráculo en cien líneas

Para calificar las respuestas, el programa necesita las notas de cada acorde y de cada escala, escritas con la ortografía correcta, para que imprima B♭ y no A♯. [`Lesson5.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson5.cs) contiene tres tablas escritas a partir de las fórmulas de manual: los acordes de la lección (`"m7#5"` es `1 b3 #5 b7`), todos los nombres de escala que la skill puede devolver (`"Mixolydian b6"` es `1 2 3 4 5 b6 b7`) y los nombres de los modos de siete notas. Una nota es una letra y una clase de altura, y cada grado se escribe sobre su propia letra:

```csharp
// Un grado como "b3", "#11" o "bb7" sobre una fundamental, escrito en la letra correcta
static Note Degree(Note root, string degree)
{
    var flats = degree.TakeWhile(ch => ch == 'b').Count();
    var sharps = degree.TakeWhile(ch => ch == '#').Count();
    var step = (int.Parse(degree[(flats + sharps)..]) - 1) % 7;
    return new Note((root.Letter + step) % 7, (root.Pc + MajorSteps[step] + sharps - flats + 12) % 12);
}
```

Si GA añade o renombra una escala, el nombre no está en la tabla y la búsqueda en el diccionario lanza una excepción: la CI del curso falla en lugar de calificar una respuesta que no entiende.

De estas tablas salen tres comprobaciones. Para un acorde: ¿añade el arpegio una nota que el acorde no tiene, omite alguna, y le falta a la escala principal alguna nota del acorde? Para una progresión: ¿en qué tonalidad está, y qué escala da el manual a cada acorde en esa tonalidad?

## Un acorde cada vez

La skill clasifica cada acorde de una serie por separado, así que una serie de diecisiete acordes, todos sobre C, equivale a diecisiete preguntas, y una sola llamada las responde todas:

```text
== ImprovisationSkill.ExecuteAsync("arpeggios over Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5")
written: Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5
read:    Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7 Csus4 Csus2 C5

written  read as    quality                 arpeggio  lead scale                       check
Cmaj7               major 7                 Cmaj7     C Ionian (major)                 ok
C7                  dominant 7              C7        C Mixolydian                     ok
Cm7                 minor 7                 Cm7       C Dorian                         ok
Cm7b5               half-diminished (m7b5)  Cm7b5     C Locrian                        ok
Cdim                diminished triad        Cdim      C Locrian                        ok
Cdim7               diminished 7            Cdim7     C Whole-Half Diminished          ok
Caug                augmented               Caug      C Whole Tone                     ok
C6                  major triad             C         C Ionian (major)                 arpeggio drops A
Cm6                 minor major 7           CmMaj7    C Melodic Minor                  arpeggio adds B; arpeggio drops A
C7#11               dominant 7              C7        C Mixolydian                     arpeggio drops F#; scale lacks F# (choice 2 of 3 has it)
Cm7#5               augmented               Caug      C Whole Tone                     arpeggio adds E; arpeggio drops Eb Bb; scale lacks Eb (none of 2 choices has it)
Cmaj7#5  Cmaj7      major 7                 Cmaj7     C Ionian (major)                 arpeggio adds G; arpeggio drops G#; scale lacks G# (none of 2 choices has it)
C7sus4   (dropped)
CmMaj7   (dropped)
Csus4               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops F
Csus2               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops D
C5                  unknown                 C         C Major scale of the chord root  arpeggio adds E
```

Siete acordes salen bien. Los otros diez fallan en tres sitios.

**Lectura.** `read:` tiene quince acordes, no diecisiete, y la respuesta no lo dice. La expresión regular del tokenizador es una lista de cualidades seguida de un límite de palabra, `\b`. `Cmaj7#5` coincide con `maj7`, y entre `7` y `#` hay un límite de palabra: el acorde se lee como `Cmaj7`, sin su quinta aumentada. `C7sus4` y `CmMaj7` no coinciden con nada. La lista tiene `7` pero no `7sus4`, y `mmaj7` solo en minúsculas; y las coincidencias más cortas, `C7` y `Cm`, no van seguidas de un límite de palabra. La etiqueta de arpegio que la propia skill usa para un acorde menor con séptima mayor es `mMaj7` ([línea 278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L278)), una grafía que su tokenizador no sabe volver a leer.

**Clasificación.** `InferQuality` prueba subcadenas en un orden fijo, y gana la primera coincidencia.

- `Cm7#5` contiene `7#5`, que se prueba con la familia aumentada antes que cualquier cualidad menor ([línea 343](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)). El arpegio es `Caug`, C E G♯, cuyo E natural choca con el E♭ del acorde, y ninguna de las dos escalas propuestas contiene el E♭.
- `Cm6` va a parar a "minor major 7" a propósito: "mel min territory" (terreno de la menor melódica), dice el comentario ([línea 346](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)). La menor melódica contiene el acorde, pero el arpegio `CmMaj7` toca B donde el acorde tiene A.
- Para el clasificador, `C7#11` es una simple séptima de dominante, así que la escala principal es el mixolidio, con el F natural que el acorde eleva. La segunda opción, el lidio dominante, es la correcta.
- `Csus4`, `Csus2` y `C5` son "unknown" (desconocidos), y una cualidad desconocida recibe como etiqueta de arpegio la fundamental sola ([línea 283](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L283)), que se lee como una tríada mayor: un E frente al F del sus4 o al D del sus2, y una tercera que el acorde de quinta omite a propósito.

**Incompleto.** `C6` recibe una tríada como arpegio, sin el A. Ese no está mal, solo se queda corto: un arpegio que omite una nota no toca nada fuera del acorde. Un arpegio que añade una toca una nota falsa cada vez que llega a ella.

## Una progresión y su tonalidad

Para una progresión, el oráculo encuentra primero la tonalidad. Para cada una de las doce escalas mayores, cuenta las notas de los acordes que quedan fuera de ella, y se queda con la escala que deja fuera menos; C mayor y A menor comparten sus notas, así que cuentan como una sola. Después da a cada acorde las notas de la tonalidad, leídas desde la fundamental del acorde. Es la tabla de la que parte todo curso de acorde–escala: jónico sobre I, dórico sobre ii, frigio sobre iii, lidio sobre IV, mixolidio sobre V, eólico sobre vi y locrio sobre vii ([Open Music Theory, sección 6.7](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory)).

Las columnas: la escala principal de la skill; sus notas *ajenas*, las que no están ni en la tonalidad ni en el acorde; la escala de manual; el puesto de la escala de manual en la propia lista de la skill, `-` cuando no aparece; y el veredicto.

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Dm7 G7 Cmaj7") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Dm7    Dm7       D Dorian                   -         D Dorian                  1      same
G7     G7        G Mixolydian               -         G Mixolydian              1      same
Cmaj7  Cmaj7     C Ionian (major)           -         C Ionian                  1      same

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
F      F         F Ionian (major)           Bb        F Lydian                  2      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Em C G D") against the key
key: G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Em     Em        E Aeolian (natural minor)  -         E Aeolian                 1      same
C      C         C Ionian (major)           F         C Lydian                  2      DIFF
G      G         G Ionian (major)           -         G Ionian                  1      same
D      D         D Ionian (major)           C#        D Mixolydian              -      DIFF
```

El ii–V–I coincide en todos los acordes: las cualidades escritas, m7, 7 y maj7, resultan nombrar los modos correctos. Las tríadas no. Una tríada de F mayor es el mismo acorde tanto si es I en F como IV en C, y solo la tonalidad lo decide. Sobre Am F C G, la skill toca B♭ sobre F y F♯ sobre G; sobre Em C G D, F natural sobre C y C♯ sobre D. F lidio y C lidio son las segundas opciones de la skill; G mixolidio y D mixolidio ni siquiera están en su lista para una tríada mayor.

## Acordes fuera de la tonalidad

Un acorde de fuera de la tonalidad es justo el caso en que el comentario de GA tiene razón, y el oráculo lo resuelve con una sola regla: conservar las notas de la tonalidad, pero poner cada nota del acorde en lugar de la nota de la tonalidad que lleva la misma letra.

```csharp
// Las notas de la tonalidad, con cada nota del acorde en lugar de la nota de la misma letra,
// leídas desde la fundamental: el modo de la tonalidad para un acorde diatónico y, para una
// dominante secundaria, las notas de la tonalidad alrededor de las del acorde (A en C mayor: A B C# D E F G)
static List<Note> Textbook(List<Note> chord, int k)
{
    var byLetter = Key(k).ToDictionary(n => n.Letter, n => n.Pc);
    foreach (var tone in chord) byLetter[tone.Letter] = tone.Pc;
    return Enumerable.Range(0, 7).Select(i => (chord[0].Letter + i) % 7).Select(l => new Note(l, byLetter[l])).ToList();
}
```

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C A Dm G") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
A      A         A Ionian (major)           F# G#     A Mixolydian b6           -      DIFF
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am Dm E") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
E      E         E Ionian (major)           F# C# D#  E Phrygian dominant       -      DIFF
```

En C A Dm G, el acorde de A mayor hace de dominante de D menor. Su C♯ sustituye a C, y la escala es A B C♯ D E F G, A mixolidio ♭6: conserva la propia tercera del acorde, justo la nota en la que se equivoca el método por grados que descarta el comentario de GA. La enseñanza acorde–escala de Berklee construye igual las escalas de las dominantes secundarias, con las notas del acorde más las demás notas de la tonalidad, y llama a esta mixolidio ♭13 para V7/II (Nettles y Graf, véanse las fuentes; *por verificar* en el libro). El A jónico de GA también conserva el C♯, pero añade F♯ y G♯, que no tienen ni la tonalidad ni el acorde.

En Am Dm E, el acorde de E mayor hace de dominante de A menor, con la sensible G♯. La regla da E F G♯ A B C D, E frigio dominante, "the fifth mode of the harmonic minor scale, the fifth being the dominant" (el quinto modo de la escala menor armónica, cuyo quinto grado es la dominante), que el método de Berklee llama mixolidio ♭9 ♭13 ([Wikipedia](https://en.wikipedia.org/wiki/Phrygian_dominant_scale)). El E jónico de GA añade tres notas ajenas, F♯, C♯ y D♯, justo en el acorde que devuelve la frase a casa.

Los acordes menores fallan igual que las tríadas mayores. Dm recibe el eólico, la primera escala que la skill propone para una tríada menor, con su B♭. En las dos progresiones, D menor es el ii o el iv de la tonalidad y lleva el dórico, la segunda opción de la skill.

Así que la elección no es entre la tonalidad y la cualidad escrita. El manual usa las dos: las notas del acorde salen de su cifrado, y todas las demás, de la tonalidad.

## Cuando la tonalidad es ambigua

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C G") against the key
key: C major / A minor or G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           - | F     C Ionian | C Lydian       1 | 2  same in C major / A minor
G      G         G Ionian (major)           F# | -    G Mixolydian | G Ionian   - | 1  same in G major / E minor
```

C y G encajan igual de bien en C mayor y en G mayor, sin que ninguna nota de los acordes quede fuera de ninguna de las dos. El oráculo lo dice y califica cada acorde en las dos tonalidades, separadas por `|`. Cada una de las dos respuestas de la skill es correcta en una tonalidad e incorrecta en la otra: C jónico es la lectura en C mayor, G jónico la lectura en G mayor. Tocadas una tras otra sobre un vamp C–G, alternan entre F y F♯ en cada cambio de acorde. La issue [#744](https://github.com/GuitarAlchemist/ga/issues/744) de GA pide que se trate este caso: decir que la tonalidad es ambigua en lugar de elegir una en silencio.

Am F C G, en cambio, no es ambigua en este sentido. C mayor y A menor tienen las mismas notas, así que cada acorde recibe la misma escala se le dé a la tonalidad el nombre que se le dé; solo deciden las notas.

## Hasta dónde llega el oráculo

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C Fm G C") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
Fm     Fm        F Aeolian (natural minor)  Bb Db Eb  F (0 2 3 6 7 9 11)        -      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
```

F menor en C mayor es un acorde prestado, el iv tomado de C menor. La regla pone A♭ entre las notas de C mayor y obtiene F G A♭ B C D E, los semitonos `0 2 3 6 7 9 11`: una escala que nadie enseña sobre F menor, y por eso el programa imprime esos semitonos en lugar de un nombre. La respuesta habitual toma las notas de la tonalidad de la que se toma prestado el acorde, lo que da F dórico si la fuente es C menor natural (*por verificar* en Nettles y Graf). El oráculo conoce una tonalidad y no sabe encontrar una segunda. En esta fila, DIFF solo dice que las dos respuestas difieren, no cuál es la correcta: aquí no lo es ninguna. Las notas ajenas se miden frente a la escala del oráculo, así que en esta fila tampoco significan nada.

El oráculo tampoco comprueba el resto de la teoría acorde–escala: las tensiones y las notas a evitar, la vía de un único acorde, que necesita un modelo para extraer el acorde, ni nada melódico. La propia crítica que Open Music Theory hace del método describe de cerca el diseño de GA: la teoría acorde–escala "can lead a student to see each chord as a new key center, instead of viewing an entire chord progression as derived from a parent scale" (puede llevar al estudiante a ver cada acorde como un nuevo centro tonal, en lugar de ver toda la progresión como derivada de una escala madre). Una skill que clasifica cada acorde por separado, sin tonalidad, es esa crítica escrita en C#.

## Comunicado upstream

- Las escalas ciegas a la tonalidad de la vía de progresión: issue de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744), abierta el 2026-09-28 a partir de un tracer ejecutado contra el chatbot público, con los casos Am F C G y C A Dm G de esta lección.
- Los defectos de "Un acorde cada vez", el tokenizador, el orden de `InferQuality`, los acordes suspendidos y de quinta desconocidos y el arpegio de `m6`: se comunicaron después de escribir esta lección, el tokenizador en la issue de GA [#757](https://github.com/GuitarAlchemist/ga/issues/757) y los demás en la [#758](https://github.com/GuitarAlchemist/ga/issues/758). Están listados en el [diario](../journal/).

## Ejercicios

1. Sin ejecutar nada, predice los veredictos para "which arpeggio fits Bb Gm Cm F". ¿Qué escala da la skill a cada acorde, y cuáles de sus notas son ajenas?
2. Cambia el tokenizador para que lea `C7sus4` y `CmMaj7` y no recorte `Cmaj7#5`. Después asegúrate de que un acorde que siga sin saber leer no desaparezca en silencio. ¿Qué añadirías?
3. Cambia `InferQuality` para que `Cm7#5` sea un acorde menor. ¿Qué etiqueta de arpegio y qué escalas debería recibir?
4. La issue #744 pide en GA una prueba de ajuste a la tonalidad. ¿Qué comprobaciones del oráculo de esta lección portarías como pruebas unitarias, y cuáles dejarías fuera?

<details>
<summary>Soluciones</summary>

1. La tonalidad es B♭ mayor, sin ninguna nota de los acordes fuera de ella. B♭ recibe B♭ jónico y Gm recibe G eólico, los dos correctos (I y vi). Cm recibe C eólico, cuyo A♭ es ajeno: el manual da C dórico (ii), la segunda opción de la skill. F recibe F jónico, cuyo E natural es ajeno: el manual da F mixolidio (V), que no está en la lista de la skill. Comprobado con el programa del curso el 2026-09-28, añadiendo la progresión a `Progressions` para una sola ejecución.
2. Añade a la lista las cualidades que faltan, cada una antes de su prefijo más corto: `7sus4` y `7sus2` antes de `7`, `maj7#5` antes de `maj7`, y `mMaj7`. Para la omisión silenciosa, compara las palabras del mensaje que empiezan por una letra de acorde con los acordes leídos, y nombra en la respuesta los que no se leyeron, por ejemplo "I couldn't read Cmaj7#5". No se ha compilado contra GA (*por verificar*).
3. Prueba `m7#5` antes de la familia aumentada, igual que `m7b5` ya se prueba antes de la familia disminuida. El acorde es C E♭ G♯ B♭, y G♯ equivale a A♭, así que C eólico y C frigio contienen las cuatro notas. La etiqueta de arpegio debería ser `Cm7#5`, lo que exige una cualidad propia: `Minor7` imprimiría `Cm7`. No se ha compilado contra GA (*por verificar*).
4. Porta las comprobaciones que no dependen de una tradición pedagógica: toda nota del acorde está en la escala principal; el arpegio no añade ninguna nota; cuando una tonalidad contiene todas las notas de los acordes, la escala principal no tiene ninguna nota fuera de esa tonalidad. Fija el caso C A Dm G para que la escala del acorde de A conserve su C♯ y no tenga ni F♯ ni G♯. Deja fuera los nombres de las escalas y la regla de los acordes prestados: la fila de C Fm G C muestra que esa regla no está resuelta, y la propia #744 deja abierta la regla de inferencia de la tonalidad como decisión de diseño.

</details>

## Puntos clave

- La skill de improvisación de GA responde a preguntas sobre una progresión sin modelo: lee los cifrados con una expresión regular, clasifica cada acorde a partir de su cualidad escrita, y da un arpegio y una lista ordenada de escalas.
- Clasificar cada acorde por separado evita el error del método por grados que describe el comentario de GA, pero pierde la tonalidad: sobre Am F C G, la skill toca B♭ sobre F y F♯ sobre G.
- La escala de manual de un acorde bebe de las dos fuentes: las notas del acorde, de su cifrado; todas las demás, de la tonalidad. Esa regla cubre los acordes diatónicos y las dominantes secundarias, no los acordes prestados.
- El tokenizador descarta o recorta en silencio los acordes que no conoce, y el orden fijo de `InferQuality` lee mal `Cm7#5`, `C7#11` y los acordes suspendidos y de quinta. En los peores casos, el arpegio lleva una nota que el acorde no tiene.
- Un oráculo solo es útil si dice hasta dónde llega: en la fila del acorde prestado, DIFF significa que las dos respuestas están mal.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, sin cambios en `main` en `8cd5042` el 2026-09-28.
- Issue de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744), abierta el 2026-09-28.
- Mark Gotham, Kyle Gullings, Chelsey Hamm, Bryn Hughes, Brian Jarvis, Megan Lavengood y John Peterson, *Open Music Theory*, 2.ª edición, [sección 6.7, "Chord-Scale Theory"](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory), CC BY-SA 4.0, leída el 2026-09-28.
- Wikipedia, ["Phrygian dominant scale"](https://en.wikipedia.org/wiki/Phrygian_dominant_scale) y ["Chord-scale system"](https://en.wikipedia.org/wiki/Chord-scale_system), para el origen del método en el *Lydian Chromatic Concept of Tonal Organization* de George Russell (1953); leídas el 2026-09-28.
- Barrie Nettles y Richard Graf, *The Chord Scale Theory & Jazz Harmony*, Advance Music, 1997: la referencia de Berklee para las escalas de las dominantes secundarias y de los acordes prestados. Este curso no lo ha leído; las dos afirmaciones que dependen de él están marcadas *por verificar*.
- Microsoft Learn: [Generadores de código fuente de expresiones regulares de .NET](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators), [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1), [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement).
