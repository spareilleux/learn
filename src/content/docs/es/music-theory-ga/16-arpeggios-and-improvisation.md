---
title: "Lección 16: Arpegios, teoría acorde–escala e improvisación"
description: El arpegio de cada grado, la escala que va con cada acorde y las notas que chocan con él, comparados con la herramienta ga_arpeggio_suggestions de Guitar Alchemist, las dos habilidades de su chatbot que emparejan acordes con escalas y juzgan una nota sobre un acorde, y sus entradas sobre improvisación.
sidebar:
  label: 16. Arpegios e improvisación
  order: 16
---

La lección 6 apilaba terceras dentro de una escala para sacar sus acordes, y la lección 11 tocaba una escala desde cada uno de sus grados para sacar sus modos. El improvisador usa las dos cosas a la vez: sobre cada acorde, las notas del acorde tocadas una a una, y una escala que llena los huecos entre ellas. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) responde a la pregunta del guitarrista, «¿qué toco sobre este acorde?», en tres sitios: una herramienta de su servidor MCP, `ga_arpeggio_suggestions`, y dos habilidades de su chatbot, `ImprovisationSkill`, que da a cada acorde un arpegio y escalas, y `OutsideNotesSkill`, que dice si una nota es nota del acorde, tensión o nota a evitar. El programa del curso compila las dos habilidades tal cual, lee la herramienta como texto y la aplica, y compara las tres con las definiciones publicadas.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Las habilidades toman un logger y un extractor de consultas por LLM de código que el curso no compila; [`StandIns.cs`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/StandIns.cs) los sustituye, y ninguna petición de abajo llega al extractor. No se llamó a ninguna herramienta MCP ni a ningún chatbot. Las salidas vienen del comando de abajo; el punto de entrada es `l18`.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l18
```

## Los arpegios

### La idea

Wikipedia: "An arpeggio … is a type of chord in which the notes that compose a chord are individually sounded in a progressive rising or descending order", y "An arpeggio for the chord of C major going up two octaves would be the notes (C, E, G, C, E, G, C)" ([Arpeggio](https://en.wikipedia.org/wiki/Arpeggio)). En el jazz, "Saxophone player Charlie Parker began soloing using the scales and arpeggios associated with the chords in the chord progression" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). El arpegio de un acorde de séptima son sus cuatro notas. Apilar terceras dentro de la escala, como en la lección 6, da el acorde de séptima de cada grado: en C mayor, Cmaj7, Dm7, Em7, Fmaj7, G7, Am7 y Bm7♭5; en A menor, los mismos siete acordes a partir de Am7.

### En GA: dos tablas y una habilidad

`ga_arpeggio_suggestions` guarda dos tablas, una fila por grado de una tonalidad mayor o menor: el sufijo del arpegio, el modo y los intervalos del modo ([`GuitaristProblemTools.cs#L385-L406`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L385-L406)). `ImprovisationSkill.ArpeggioFor` nombra el arpegio a partir de una fundamental y una calidad ([`ImprovisationSkill.cs#L263-L284`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L263-L284)). El programa comprueba las dos contra los acordes del curso ([`Lesson18.cs#L270-L282`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L270-L282)):

```text
== The seventh chord on each degree, thirds stacked within C major and within A minor, against the arpeggio suffix of ga_arpeggio_suggestions's two tables (GuitaristProblemTools.cs, read as text) and ImprovisationSkill.ArpeggioFor (GA.Business.ML, compiled) for the course's symbol
degree  notes          course   tool   check  ImprovisationSkill  check
I       C E G B        Cmaj7    maj7   ok     Cmaj7               ok
ii      D F A C        Dm7      m7     ok     Dm7                 ok
iii     E G B D        Em7      m7     ok     Em7                 ok
IV      F A C E        Fmaj7    maj7   ok     Fmaj7               ok
V       G B D F        G7       7      ok     G7                  ok
vi      A C E G        Am7      m7     ok     Am7                 ok
vii°    B D F A        Bm7b5    m7b5   ok     Bm7b5               ok
degree  notes          course   tool   check  ImprovisationSkill  check
i       A C E G        Am7      m7     ok     Am7                 ok
ii°     B D F A        Bm7b5    m7b5   ok     Bm7b5               ok
III     C E G B        Cmaj7    maj7   ok     Cmaj7               ok
iv      D F A C        Dm7      m7     ok     Dm7                 ok
v       E G B D        Em7      m7     ok     Em7                 ok
VI      F A C E        Fmaj7    maj7   ok     Fmaj7               ok
VII     G B D F        G7       7      ok     G7                  ok
```

Los catorce sufijos coinciden, y `ArpeggioFor` devuelve a cada acorde su propio símbolo.

## La escala de cada acorde

### La idea

"The chord-scale system is a method of matching, from a list of possible chords, a list of possible scales." Wikipedia lo contrapone a tocar una sola escala sobre toda una progresión, "the blues scale on A for all chords of the blues progression: A7 E7 D7": "in the chord-scale system, a different scale is used for each chord in the progression (for example mixolydian scales on A, E, and D for chords A7, E7, and D7, respectively)". Los profesores no coinciden sobre el acorde mayor: "Russell associated the C major chord with the lydian scale, while teachers including John Mehegan, David Baker, and Mark Levine teach the major scale as the best match for a C major chord" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)). Otro artículo da parejas: "C7 → C mixolydian", "C-7 → C dorian", "Cmaj7♯11 → C Lydian mode", "C- → C Aeolian mode (natural minor)" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). Y da el criterio que el curso aplica en todo momento: "the scale contains the chord tones G–B–D♭–F and is said to be compatible with it" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). Una escala sirve para un acorde cuando contiene todas sus notas.

Dentro de una tonalidad, la escala de cada grado es el modo de ese grado, como mostró la lección 11: jónico sobre I, dórico sobre ii, y así hasta el locrio sobre vii°.

### En GA: las tablas de la herramienta, y los modos de GA

El programa compara las columnas Mode y Notes de las dos tablas con el modo de cada grado, y las escalas que nombran la herramienta y las habilidades con los modos de GA ([`Lesson18.cs#L284-L315`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L284-L315)):

```text
== The mode on each degree of C major: its intervals from the course's steps, against the Mode and Notes columns of the tool's major table, and against GA's MajorScaleMode
degree  course      tool             intervals (course)          tool's Notes MajorScaleMode name
I       Ionian      Ionian (major)   R, M2, M3, P4, P5, M6, M7   ok           ok             ok
ii      Dorian      Dorian           R, M2, m3, P4, P5, M6, m7   ok           ok             ok
iii     Phrygian    Phrygian         R, m2, m3, P4, P5, m6, m7   ok           ok             ok
IV      Lydian      Lydian           R, M2, M3, A4, P5, M6, M7   ok           ok             ok
V       Mixolydian  Mixolydian       R, M2, M3, P4, P5, M6, m7   ok           ok             ok
vi      Aeolian     Aeolian (minor)  R, M2, m3, P4, P5, m6, m7   ok           ok             ok
vii°    Locrian     Locrian          R, m2, m3, P4, d5, m6, m7   ok           ok             ok

== The tool's minor table, row by row: the mode on that degree of A minor (the course rotates the steps of natural minor), against the row's Mode and Notes
i       Aeolian     Aeolian (minor)  ok    ok
ii°     Locrian     Locrian          ok    ok
III     Ionian      Ionian (major)   ok    ok
iv      Dorian      Dorian           ok    ok
v       Phrygian    Phrygian         ok    ok
VI      Lydian      Lydian           ok    ok
VII     Mixolydian  Mixolydian       ok    ok

== The textbook scales the tool and the skills name, against GA's mode with that place in its class
name                     course                       GA's mode                check
Melodic Minor            0 2 3 5 7 9 11               Melodic Minor            ok
Lydian Augmented         0 2 4 6 8 9 11               Lydian Augmented         ok
Lydian Dominant          0 2 4 6 7 9 10               Lydian Dominant          ok
Mixolydian b6            0 2 4 5 7 8 10               Mixolydian b6            ok
Locrian #2               0 2 3 5 6 8 10               Locrian Natural 2        ok
Altered (Super Locrian)  0 1 3 4 6 8 10               Altered                  ok
Phrygian Dominant        0 1 4 5 7 8 10               Phrygian Dominant        ok
Half-Whole Diminished    0 1 3 4 6 7 9 10             Half-whole diminished    DIFF
Whole-Half Diminished    0 2 3 5 6 8 9 11             Whole-half diminished    DIFF
Whole Tone               0 2 4 6 8 10                 Whole-tone               ok
Major Pentatonic         0 2 4 7 9                    Major pentatonic         ok
Minor Pentatonic         0 3 5 7 10                   Minor pentatonic         ok
```

Las dos tablas de la herramienta están bien, y `MajorScaleMode` de GA también. De las otras doce escalas, diez coinciden con el modo de GA en el mismo lugar de su clase. Las dos filas `DIFF` son los modos disminuidos de GA, como en la [lección 12](../12-symmetry-and-limited-transposition/): el primero, que GA llama "Half-whole diminished", empieza por un tono, y el segundo al revés. La corrección que el curso propuso a GA está en el [diario](../journal/#2026-10-04--correcciones-propuestas-a-guitar-alchemist).

## Lo que devuelve `ga_arpeggio_suggestions`

La descripción de la herramienta dice: "For each chord in a progression, suggest the matching arpeggio and mode to improvise over it. … Example: ["Am","F","C","G"] in C major → Am: Aeolian/Am7, F: Lydian/Fmaj7, C: Ionian/Cmaj7, G: Mixolydian/G7." ([`#L409-L412`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L409-L412)). Cuando la petición nombra su tonalidad, la primera palabra es la tónica y la segunda el modo, y cualquier palabra que no sea «minor» significa mayor ([`#L426-L431`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L426-L431), [`#L450`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L450)). La herramienta busca el grado cuya nota es la fundamental del acorde ([`#L462-L463`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L462-L463)) y devuelve `chord + arpeggioSuffix`, el símbolo entero seguido del sufijo de la tabla, con el modo de ese grado ([`#L477-L485`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L477-L485)). Una fundamental fuera de la tonalidad recibe una respuesta fija ([`#L464-L475`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L464-L475)). La herramienta necesita los paquetes MCP y F# del servidor de GA, así que el programa no la compila: lee del archivo las tablas y las listas de grados, aplica esas líneas ([`Lesson18.cs#L142-L236`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L142-L236)), y lista las notas de cada acorde fuera del modo que recibe ([`#L317-L341`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L317-L341)):

```text
== What ga_arpeggio_suggestions returns when the request names its key (the course's reading of lines 413 to 495), and the notes of each chord outside the mode it pairs with the chord
the tool's own example: [Am, F, C, G], key "C major" read as "C major"
  Am     vi         Amm7                               Aeolian (minor)      outside the mode: -
  F      IV         Fmaj7                              Lydian               outside the mode: -
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  G      V          G7                                 Mixolydian           outside the mode: -
a ii-V-I written with sevenths: [Dm7, G7, Cmaj7], key "C major" read as "C major"
  Dm7    ii         Dm7m7                              Dorian               outside the mode: -
  G7     V          G77                                Mixolydian           outside the mode: -
  Cmaj7  I          Cmaj7maj7                          Ionian (major)       outside the mode: -
Wikipedia's chord-scale example: [A7, E7, D7], key "A major" read as "A major"
  A7     I          A7maj7                             Ionian (major)       outside the mode: G
  E7     V          E77                                Mixolydian           outside the mode: -
  D7     IV         D7maj7                             Lydian               outside the mode: C
an A major chord in C major: [C, A, Dm, G], key "C major" read as "C major"
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  A      vi         Am7                                Aeolian (minor)      outside the mode: C♯
  Dm     ii         Dmm7                               Dorian               outside the mode: -
  G      V          G7                                 Mixolydian           outside the mode: -
a minor key with its dominant: [Am, Dm, E7, Am], key "A minor" read as "A minor"
  Am     i          Amm7                               Aeolian (minor)      outside the mode: -
  Dm     iv         Dmm7                               Dorian               outside the mode: -
  E7     v          E7m7                               Phrygian             outside the mode: G♯
  Am     i          Amm7                               Aeolian (minor)      outside the mode: -
the key written "Am": [Am, Dm, E7], key "Am" read as "Am major"
  Am     I          Ammaj7                             Ionian (major)       outside the mode: C
  Dm     IV         Dmmaj7                             Lydian               outside the mode: F
  E7     V          E77                                Mixolydian           outside the mode: -
a chord outside the key: [C, Bb, F], key "C major" read as "C major"
  C      I          Cmaj7                              Ionian (major)       outside the mode: -
  Bb     chromatic  Bb (chromatic — outside key)       depends on context   outside the mode: (no scale)
  F      IV         Fmaj7                              Lydian               outside the mode: -
for a chord outside the key the tool returns the arpeggio "<chord> (chromatic — outside key)", the mode "depends on context" and the notes "R, M2, M3, P5"
```

- En su propio ejemplo, la herramienta devuelve «Amm7», donde su descripción dice Am7. Un ii–V–I escrito con séptimas recibe «Dm7m7», «G77» y «Cmaj7maj7».
- El modo sale del grado de la fundamental, no del acorde. El ejemplo de Wikipedia, A7 E7 D7 en A mayor, recibe jónico, mixolidio y lidio: el G de A7 queda fuera de A jónico y el C de D7 fuera de D lidio, donde Wikipedia toca mixolidio sobre los tres. Un acorde de A mayor en C mayor cae en el grado vi: la herramienta responde «Am7» y eólico, cuyo C choca con el C♯ del acorde. E7, la dominante de A menor, recibe «E7m7» y frigio, sin el G♯ del acorde.
- Una tonalidad escrita «Am» se lee «Am major», es decir A mayor: Am recibe «Ammaj7» y jónico, con su C fuera, y Dm recibe «Dmmaj7» y lidio.

El código de GA conocía los dos primeros. Los comentarios de `ImprovisationSkill` describen el acorde de A mayor en C mayor ([`ImprovisationSkill.cs#L22-L32`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)), y un comentario sobre `ArpeggioFor` llama a "root + full-suffix concatenation ("Amm7")" "the single most-broken behavior of the MCP arpeggio tool" ([`#L264-L265`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L264-L265)). [GA #626](https://github.com/GuitarAlchemist/ga/pull/626), fusionada el 2026-09-24, después del commit del curso del 2026-09-14, hace que la herramienta nombre el arpegio con `InferQuality` y `ArpeggioFor` de la habilidad, y compare la calidad del acorde con la del grado. En `main`, la tonalidad se sigue leyendo igual. Leído, no ejecutado.

## Lo que ofrece `ImprovisationSkill`

La habilidad "Suggests scales, modes and arpeggios to improvise / solo over a chord or a whole chord progression" ([`ImprovisationSkill.cs#L46-L51`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L46-L51)). `InferQuality` lee la calidad tras la fundamental, "Most-specific first" ([`#L309-L353`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)); `ScalesFor` da a cada calidad una lista de escalas, "best/most-common first" ([`#L355-L437`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L355-L437)). El programa pide 31 símbolos sobre C, cada uno con sus notas habituales ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation), [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord)), y busca las notas del acorde fuera de la primera escala ([`Lesson18.cs#L343-L358`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L343-L358)):

```text
== ImprovisationSkill (GA.Business.ML, compiled): the quality InferQuality reads in each symbol, the arpeggio ArpeggioFor names, the first scale ScalesFor offers and the chord's notes outside it, and the first of its scales that holds them all
symbol    notes           quality                 arpeggio   first scale                    outside   holds every note
C         C E G           major triad             C          Ionian (major)                 -         the first
Cm        C E♭ G          minor triad             Cm         Aeolian (natural minor)        -         the first
C6        C E G A         major triad             C          Ionian (major)                 -         the first
C69       C E G A D       major triad             C          Ionian (major)                 -         the first
Cadd9     C E G D         unknown                 C          Major scale of the chord root  -         the first
Csus2     C D G           unknown                 C          Major scale of the chord root  -         the first
Csus4     C F G           unknown                 C          Major scale of the chord root  -         the first
C5        C G             unknown                 C          Major scale of the chord root  -         the first
Cmaj7     C E G B         major 7                 Cmaj7      Ionian (major)                 -         the first
CM7       C E G B         minor 7                 Cm7        Dorian                         E B       none
Cmaj9     C E G B D       major 7                 Cmaj7      Ionian (major)                 -         the first
Cmaj7#11  C E G B F♯      major 7#11              Cmaj7#11   Lydian                         -         the first
Cmaj7#5   C E G♯ B        major 7                 Cmaj7      Ionian (major)                 G♯        none
C7        C E G B♭        dominant 7              C7         Mixolydian                     -         the first
C9        C E G B♭ D      dominant 7              C7         Mixolydian                     -         the first
C13       C E G B♭ D A    dominant 7              C7         Mixolydian                     -         the first
C7sus4    C F G B♭        suspended dominant      C7sus4     Mixolydian                     -         the first
C7#11     C E G B♭ F♯     dominant 7              C7         Mixolydian                     F♯        Lydian Dominant
C7b9      C E G B♭ D♭     altered dominant        C7alt      Altered (Super Locrian)        G         Half-Whole Diminished
C7#9      C E G B♭ D♯     altered dominant        C7alt      Altered (Super Locrian)        G         Half-Whole Diminished
C7b13     C E G B♭ A♭     dominant 7              C7         Mixolydian                     A♭        Mixolydian b6
C7#5      C E G♯ B♭       augmented               Caug       Whole Tone                     -         the first
C7+5      C E G♯ B♭       dominant 7              C7         Mixolydian                     G♯        Mixolydian b6
Caug      C E G♯          augmented               Caug       Whole Tone                     -         the first
Cm7       C E♭ G B♭       minor 7                 Cm7        Dorian                         -         the first
Cm9       C E♭ G B♭ D     minor 7                 Cm7        Dorian                         -         the first
Cm6       C E♭ G A        minor major 7           CmMaj7     Melodic Minor                  -         the first
CmMaj7    C E♭ G B        minor major 7           CmMaj7     Melodic Minor                  -         the first
Cm7b5     C E♭ G♭ B♭      half-diminished (m7b5)  Cm7b5      Locrian                        -         the first
Cdim      C E♭ G♭         diminished triad        Cdim       Locrian                        -         the first
Cdim7     C E♭ G♭ B♭♭     diminished 7            Cdim7      Whole-Half Diminished          -         the first
CanHandle on its 17 example prompts: 16 accepted; turned down: "what scales fit over the progression Cmaj7 A7 Dm7 G7"
```

Para 24 de los 31 símbolos, la primera escala contiene todas las notas del acorde. Los siete restantes:

- **CM7.** `InferQuality` pasa el sufijo a minúsculas ([`#L323`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L323)), y «m7» es la prueba de la séptima menor ([`#L347`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L347)). Así, CM7, que Wikipedia escribe para "a C major seventh chord (CM7)" ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation)), recibe el arpegio Cm7 y dórico, y su E y su B quedan fuera de las tres escalas ofrecidas. `ChordVocabulary`, en GA, describe esta misma regresión: "the skill lowercased the whole quality token before matching, so "CM" resolved to C *minor* instead of C major (a regression of the PR #80 fix that the MCP tool already carried)", reunida en "one home for the case-sensitive M/M7 handling" ([`ChordVocabulary.cs#L8-L16`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L8-L16)). Su `NormalizeQuality` lee «M7» como «major 7» ([`#L59-L65`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L65)), pero `InferQuality` no lo llama.
- **Cmaj7♯5** se lee «major 7», porque la prueba de «maj7» ([`#L340`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L340)) va antes que la de «7#5» ([`#L343`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)): G♯ queda fuera del jónico y del lidio.
- **C7♯11, C7♭13 y C7+5** se leen «dominant 7», y al mixolidio le faltan su F♯, su A♭ o su G♯; Lydian Dominant y Mixolydian ♭6, más abajo en la lista, los tienen. Wikipedia empareja "C7♯11 and C lydian dominant", donde "every note of the scale may be considered a chord tone" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)).
- **C7♭9 y C7♯9** se leen «altered dominant», arpegio C7alt, y reciben primero la escala alterada. Esa escala conserva "The tonic, major third (as a diminished fourth), and dominant seventh" y altera las dos quintas ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)), así que el G del acorde queda fuera; Half-Whole Diminished, la segunda, contiene las cinco notas.

Otras dos lecturas dan la escala correcta con un nombre equivocado. Cm6 se lee «minor major 7» ("mel min territory", [`#L346`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)), así que su arpegio es CmMaj7, C E♭ G B, y no C E♭ G A, las notas del acorde; el menor melódico contiene las dos. C6 y C69 se leen «major triad», arpegio C. Cadd9, Csus2, Csus4 y C5 son «unknown» y reciben «Major scale of the chord root».

`CanHandle` es el filtro por palabras clave de la habilidad, la vía de respaldo detrás del enrutador semántico del chatbot ([`#L92-L94`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L92-L94)). Rechaza uno de los 17 ejemplos de petición de la habilidad, "what scales fit over the progression Cmaj7 A7 Dm7 G7" ([`#L74`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L74)). Sus palabras clave solo cuentan como palabras enteras ([`ChordIntentMatching.cs#L22-L35`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordIntentMatching.cs#L22-L35)): «what scale» va seguido de una s, y ninguna otra palabra clave está en la frase ([`ImprovisationSkill.cs#L86-L101`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L86-L101)).

En una petición que nombra dos símbolos de acorde o más, la habilidad clasifica cada acorde por separado ([`#L119-L125`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L119-L125), [`#L212-L261`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261)); sus comentarios dicen que es a propósito: "The per-chord classification is deliberately key-agnostic" ([`#L23`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L23)). El programa llama a `ExecuteAsync` directamente ([`Lesson18.cs#L359-L368`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L359-L368)):

```text
== ImprovisationSkill.ExecuteAsync on requests that name two chords or more: two of its own example prompts, Wikipedia's chord-scale example and GAA-003's Dorian and Mixolydian vamps
"which arpeggio fits Am F C G": CanHandle True, chords read Am F C G
  - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
"what scales fit over the progression Cmaj7 A7 Dm7 G7": CanHandle False, chords read Cmaj7 A7 Dm7 G7
  - **Cmaj7** → arpeggio **Cmaj7**, play **C Ionian (major)** (diatonic — the safe choice).
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **Dm7** → arpeggio **Dm7**, play **D Dorian** (natural 6 — modern jazz default).
  - **G7** → arpeggio **G7**, play **G Mixolydian** (diatonic dominant — natural choice for V chords).
"how do I improvise over A7 E7 D7": CanHandle True, chords read A7 E7 D7
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **E7** → arpeggio **E7**, play **E Mixolydian** (diatonic dominant — natural choice for V chords).
  - **D7** → arpeggio **D7**, play **D Mixolydian** (diatonic dominant — natural choice for V chords).
"improvise over Am7 D7": CanHandle True, chords read Am7 D7
  - **Am7** → arpeggio **Am7**, play **A Dorian** (natural 6 — modern jazz default).
  - **D7** → arpeggio **D7**, play **D Mixolydian** (diatonic dominant — natural choice for V chords).
"improvise over A7 G/A": CanHandle True, chords read A7 G A
  - **A7** → arpeggio **A7**, play **A Mixolydian** (diatonic dominant — natural choice for V chords).
  - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  - **A** → arpeggio **A**, play **A Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
```

A7 E7 D7 recibe tres veces mixolidio, la respuesta de Wikipedia, y el vamp dórico del módulo Streeling GAA-003, Am7 D7, recibe A dórico y D mixolidio. Sin tonalidad, una tríada mayor recibe siempre el jónico, con "careful on the IV chord" ([`#L371-L376`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L371-L376)): sobre Am F C G, el ejemplo de la herramienta, la habilidad ofrece F jónico y G jónico, cuyo B♭ y F♯ no están en ninguno de los cuatro acordes, donde la descripción de la herramienta tiene lidio y mixolidio. El vamp mixolidio de GAA-003, A7 a G/A, una tríada de G sobre un bajo de A, se lee como tres acordes: el tokenizador se detiene en la barra ([`#L461`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L461)), y el bajo se vuelve un acorde de A, que recibe A jónico y su G♯, contra el G del vamp.

## Las notas fuera del acorde

### La idea

Wikipedia: "An F against a C major chord could be considered an avoid note because it lies a semitone above the third, an interval which was historically heard as dissonance. Treating the F as a passing tone is a simpler way to use it in a melody over a C major chord" ([Avoid note](https://en.wikipedia.org/wiki/Avoid_note)). Otro artículo la sitúa dentro de la escala: "An avoid note is a note in a jazz scale that is considered, in jazz theory and practice, too dissonant to be emphasised against the underlying chord", y "Avoid notes are often a minor second (or a minor ninth) above a chord tone or a perfect fourth above the root of the chord"; "Non-classical harmony just tells you which note in the scale to avoid … meaning that all the others are okay" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). La definición acorde–escala clasifica las notas de una escala: una nota fuera de ella no es ni tensión ni nota a evitar de esa escala. Sobre un acorde de dominante, las tensiones alteradas son el objetivo: "The altered extensions played by a jazz guitarist or jazz pianist on an altered dominant chord on G might include (at the discretion of the performer) a flatted ninth A♭ …; a sharp eleventh C♯ … and a flattened thirteenth E♭" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)).

### En GA: una regla para doce notas

Los comentarios de `OutsideNotesSkill` dan su regla: "a non-chord-tone that sits a semitone above a chord tone is an avoid note (it forms a b9 clash with that chord tone); any other non-chord-tone is an available tension" ([`OutsideNotesSkill.cs#L20-L28`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L20-L28)). `Classify` la aplica a cualquier nota, sin escala ([`#L141-L189`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L141-L189)). El programa le pide las doce notas sobre cuatro acordes de C, y compara sus tensiones con las escalas que `ImprovisationSkill` ofrece para los mismos acordes ([`Lesson18.cs#L370-L388`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L370-L388)):

```text
== OutsideNotesSkill.Classify (GA.Business.ML, compiled): each of the twelve notes over Cmaj7, C7, Cm7 and Cm7b5
note  Cmaj7                         C7                            Cm7                           Cm7b5
C     chord tone: root              chord tone: root              chord tone: root              chord tone: root
D♭    avoid: b9                     avoid: b9                     avoid: b9                     avoid: b9
D     tension: 9                    tension: 9                    tension: 9                    tension: 9
E♭    tension: #9                   tension: #9                   chord tone: minor third       chord tone: minor third
E     chord tone: major third       chord tone: major third       avoid: major 3rd              avoid: major 3rd
F     avoid: 11                     avoid: 11                     tension: 11                   tension: 11
F♯    tension: #11                  tension: #11                  tension: #11                  chord tone: diminished fifth
G     chord tone: perfect fifth     chord tone: perfect fifth     chord tone: perfect fifth     avoid: 5th
A♭    avoid: b13                    avoid: b13                    avoid: b13                    tension: b13
A     tension: 13                   tension: 13                   tension: 13                   tension: 13
B♭    tension: b7                   chord tone: minor seventh     chord tone: minor seventh     chord tone: minor seventh
B     chord tone: major seventh     avoid: major 7th              avoid: major 7th              avoid: major 7th

== The notes Classify calls a tension that none of the scales ImprovisationSkill offers for the same chord contains
Cmaj7  scales: Ionian (major), Lydian; tensions: D E♭ F♯ A B♭; in none of them: E♭ (#9), B♭ (b7)
C7     scales: Mixolydian, Lydian Dominant, Mixolydian b6; tensions: D E♭ F♯ A; in none of them: E♭ (#9)
Cm7    scales: Dorian, Aeolian (minor), Phrygian; tensions: D F F♯ A; in none of them: F♯ (#11)
Cm7b5  scales: Locrian, Locrian #2; tensions: D F A♭ A; in none of them: A (13)
```

Sobre Cmaj7, las notas a evitar son D♭, F y A♭; F es la nota a evitar de Wikipedia. Cualquier otra nota es una «tension», esté o no en una escala que sirva para el acorde. Sobre Cmaj7, B♭ es «tension: b7», una séptima menor contra la séptima mayor del acorde, y E♭ «tension: #9», contra su tercera mayor; sobre Cm7, F♯; sobre Cm7♭5, A. Ninguna está en las escalas que `ImprovisationSkill` ofrece para el mismo acorde. B♭ está un semitono por debajo del B del acorde: la regla solo mira por encima de las notas del acorde. Sobre C7, la regla convierte la ♭9 y la ♭13 en notas a evitar, donde Wikipedia las cuenta entre las extensiones de una dominante alterada. El comentario sobre los acordes de dominante nombra "the b9/#9/#11/b13 half-step clashes" ([`#L164-L166`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L166)), pero la ♯9 y la ♯11 no están un semitono por encima de ninguna nota del acorde: salen como tensiones.

Los ejemplos de petición de la habilidad, y luego tres preguntas añadidas después de la primera ejecución ([`Lesson18.cs#L389-L403`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L389-L403)):

```text
== OutsideNotesSkill on its own example prompts: CanHandle, then the first line of ExecuteAsync's answer
"why does F sound outside over Cmaj7": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"why does that note clash over the chord": True; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
"is F an avoid note over Cmaj7": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"what is F over G7": False; **F** over **G dominant 7**: a chord tone — the minor seventh.
"why does the b9 sound so tense over C7": True; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
"is A a chord tone or a tension over Cmaj7": True; **A** over **C major 7**: an available tension — the 13 (thirteenth).
"why does Bb sound outside over C major": True; **Bb** over **C**: an available tension — the b7 (minor seventh).
"is F# an avoid note or a tension over Cmaj7": True; **F#** over **C major 7**: an available tension — the #11 (sharp eleventh).
"why does F clash over a Cmaj7 chord": True; **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
"why does the note clash over this chord": False; Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".

== Added after the first run: OutsideNotesSkill.ExecuteAsync's whole answer for B over C7, and for E and B over CM7, the symbol ImprovisationSkill reads as minor 7
"is B an avoid note over C7": **B** over **C dominant 7**: an avoid note — the major 7th. It's the major 7th, sitting a semitone above the minor seventh of the chord. That half-step rub is why it sounds outside — but over a dominant chord it's exactly the kind of altered tension players reach for (major 7th on the V), so it's usable if you resolve it, not a note to simply avoid.
"is E a chord tone over CM7": **E** over **C major 7**: a chord tone — the major third. It's part of the chord itself (the major third), so it sounds fully consonant — as inside as a note can be over this chord.
"is B a chord tone over CM7": **B** over **C major 7**: a chord tone — the major seventh. It's part of the chord itself (the major seventh), so it sounds fully consonant — as inside as a note can be over this chord.
```

Siete de los diez ejemplos de petición obtienen respuesta. "what is F over G7" obtiene una cuando se la llama directamente, pero `CanHandle` la rechaza: ninguna de las palabras clave de la habilidad está en la frase ([`#L67-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L67-L72)). "why does that note clash over the chord" pasa `CanHandle`, porque el patrón de acorde ignora mayúsculas y minúsculas ([`#L291-L293`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L291-L293)) y lee «the chord» como un acorde de C, y luego no encuentra ninguna nota antes de «over». "why does the b9 sound so tense over C7" pasa y recibe el mismo texto de ayuda: la habilidad lee nombres de notas, no grados, como dicen sus comentarios ([`#L31-L33`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L33)). «Bb over C major» se mide contra una tríada de C mayor.

De las tres preguntas añadidas después de la primera ejecución, la primera muestra lo que un usuario lee sobre la séptima mayor encima de un acorde de dominante: una nota a evitar, y luego "over a dominant chord it's exactly the kind of altered tension players reach for (major 7th on the V)" ([`#L164-L172`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L172)). La séptima mayor no es ninguna de las tensiones alteradas, y choca con la propia séptima del acorde. Las otras dos muestran que `OutsideNotesSkill`, que lee el acorde a través de `ChordVocabulary`, toma CM7 por una séptima mayor: dos habilidades del mismo chatbot no coinciden sobre ese símbolo.

## GAA-003 y las entradas de GA sobre improvisación

El módulo Streeling [GAA-003 · Fundamentos de la improvisación](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/) parte de la caja 1 de la pentatónica menor de A, "The five notes are: A, C, D, E, G" ([`gaa-003-improvisation-foundations.md#L40-L51`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L40-L51)). Su primera respuesta de autoevaluación explica por qué esa escala es segura sobre Am7 y menos sobre A7: "Over Am or Am7 none of its notes lies a half step from a chord tone, so no order or combination makes a half-step clash with the chord. Over a dominant chord such as A7 that no longer holds: C lies a half step below the chord's C#, and D a half step above it" ([`#L467`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L467)). Sobre un blues en A, apunta a la tercera de cada acorde: "For A7, target the 3rd (C#). For D7, target the 3rd (F#). For E7, target the 3rd (G#)" ([`#L175`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L175)). Deletrea tres modos sobre A ([`#L267`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L267), [`#L273`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L273), [`#L279`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L279)) y nombra la nota que aleja a cada uno, añadiendo: "They are not "avoid notes" in the chord-scale sense of mus-005, which are notes inside the scale that clash with the chord" ([`#L283-L289`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L283-L289)). El programa comprueba esas afirmaciones con `Classify` ([`Lesson18.cs#L404-L419`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L404-L419)):

```text
== GAA-003's claims, through Classify: the notes of A minor pentatonic over Am7 and over A7, and the notes the module says pull each mode away
A   over Am7: chord tone, root            over A7: chord tone, root
C   over Am7: chord tone, minor third     over A7: tension, #9
D   over Am7: tension, 11                 over A7: avoid, 11
E   over Am7: chord tone, perfect fifth   over A7: chord tone, perfect fifth
G   over Am7: chord tone, minor seventh   over A7: chord tone, minor seventh
Dorian      F   over Am7    avoid, b13
Mixolydian  G♯  over A7     avoid, major 7th
Lydian      D   over Amaj7  avoid, 11
GAA-003's targets, the third of each dominant chord of a blues in A, from ChordVocabulary.GetFormula("dominant 7"): A7 C♯, D7 F♯, E7 G♯
```

Sobre Am7, `Classify` está de acuerdo con el módulo: A, C, E y G son notas del acorde, y D una tensión. Sobre A7 solo ve la mitad del roce: D, un semitono por encima de C♯, es una nota a evitar, pero C, un semitono por debajo, es una tensión, la ♯9. Las tres notas que alejan un modo salen todas como notas a evitar, la etiqueta que GAA-003 dice que no tienen. Los tres objetivos son las terceras de la fórmula de dominante de GA ([`ChordVocabulary.cs#L121`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L121)).

La configuración de GA tiene un archivo para la improvisación, `ImprovisationConcepts.yaml`, con cuatro conceptos, cada uno un nombre y una línea `Concept` ([`ImprovisationConcepts.yaml#L6-L14`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ImprovisationConcepts.yaml#L6-L14)). `YamlKnowledgeLoader` convierte cada uno en una entrada para la búsqueda: el nombre, y luego cada otro campo en la forma «Key: Value», etiquetado con el nombre del archivo y la `Category`, si la hay ([`YamlKnowledgeLoader.fs#L65-L91`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/YamlKnowledgeLoader.fs#L65-L91)). El programa las carga, luego toca la caja 1 de GAA-003 y deletrea sus tres modos ([`Lesson18.cs#L421-L448`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L421-L448)):

```text
== YamlKnowledgeLoader.LoadAllKnowledgeEntries (GA.Business.Config): 192 entries from 15 files; the 4 of ImprovisationConcepts.yaml
Motivic Development    category "", tags ImprovisationConcepts; content: Motivic Development | Concept: Repeat and vary small melodic ideas
Tension and Release    category "", tags ImprovisationConcepts; content: Tension and Release | Concept: Alternate dissonance and resolution
Rhythmic Displacement  category "", tags ImprovisationConcepts; content: Rhythmic Displacement | Concept: Shift motifs across beats
Space Usage            category "", tags ImprovisationConcepts; content: Space Usage | Concept: Use silence as phrasing element

== GAA-003's box 1 of A minor pentatonic, read on the strings in standard tuning, against GA's fifth mode of the major pentatonic
E: frets 5, 8 -> A2 C3
A: frets 5, 7 -> D3 E3
D: frets 5, 7 -> G3 A3
G: frets 5, 7 -> C4 D4
B: frets 5, 8 -> E4 G4
e: frets 5, 8 -> A4 C5
notes of the box: C D E G A; GA's Minor pentatonic: A C D E G; the same notes True

== GAA-003's three modes on A, as the module spells them, against the course's spelling from the steps
mode        course               GAA-003              check
Dorian      A B C D E F♯ G       A B C D E F♯ G       ok
Mixolydian  A B C♯ D E F♯ G      A B C♯ D E F♯ G      ok
Lydian      A B C♯ D♯ E F♯ G♯    A B C♯ D♯ E F♯ G♯    ok
```

Las cuatro entradas son cada una un nombre y una línea, y ninguna empareja un acorde con una escala o un arpegio. La caja 1 toca A, C, D, E y G, el quinto modo de la pentatónica mayor de GA, y el módulo deletrea bien sus tres modos. El cargador se salta `SpecializedTunings.yaml`, como encontró el [diario](../journal/#2026-10-04--correcciones-propuestas-a-guitar-alchemist); lo dice en el flujo de errores, que la salida de arriba deja fuera.

## Ejercicios

1. En `a826864`, ¿qué devuelve `ga_arpeggio_suggestions` para G7 en C mayor, y por qué?
2. Sobre un acorde de A mayor en C mayor, la herramienta ofrece el eólico. ¿Qué nota choca, y con qué nota del acorde?
3. ¿Por qué `ImprovisationSkill` lee CM7 como una séptima menor, mientras que `OutsideNotesSkill` la lee como una séptima mayor?
4. `Classify` llama tensión a B♭ sobre Cmaj7. ¿Por qué su regla no ve el choque, y qué diría la definición acorde–escala?
5. ¿Qué notas de la pentatónica menor de A están a un semitono de una nota de A7, y cómo las llama `Classify`?

<details>
<summary>Soluciones</summary>

1. «G77» y mixolidio. G es el grado V de C mayor, y la herramienta añade el sufijo de esa fila, «7», al símbolo entero.
2. El eólico sobre A tiene C, un semitono por debajo del C♯ del acorde. La herramienta busca el grado a partir de la fundamental sola, A, que es el grado vi de C mayor.
3. `InferQuality` pasa el sufijo a minúsculas, así que «M7» se vuelve «m7», la prueba de la séptima menor. `OutsideNotesSkill` pasa por `ChordVocabulary.NormalizeQuality`, que lee «M7» como séptima mayor antes de pasar nada a minúsculas.
4. La regla solo mira un semitono por encima de las notas del acorde, y B♭ está un semitono por debajo de B, la séptima del acorde. B♭ no está en ninguna de las escalas ofrecidas para Cmaj7, jónico y lidio: en el sentido acorde–escala no es ni tensión ni nota a evitar de ninguna de las dos, es una nota fuera de la escala.
5. C, un semitono por debajo de C♯, y D, un semitono por encima. `Classify` llama a D nota a evitar (la 11) y a C tensión (la ♯9).

</details>

## Puntos clave

- Apilar terceras dentro de una escala da el arpegio de cada grado. Las dos tablas de GA y `ArpeggioFor` nombran bien los catorce, y los modos de la herramienta son los de los grados.
- En `a826864`, `ga_arpeggio_suggestions` añade su sufijo al símbolo entero («Amm7», «G77») y toma el modo del grado de la fundamental, de modo que A7 en A mayor recibe el jónico. GA #626 corrigió las dos cosas el 2026-09-24; una tonalidad escrita «Am» sigue significando A mayor.
- `ImprovisationSkill` lee cada acorde por separado, y para 24 de 31 símbolos su primera escala contiene el acorde. Lee CM7 como una séptima menor, la regresión que `ChordVocabulary` dice haber eliminado, Cmaj7♯5 como una séptima mayor, y llama CmMaj7 al arpegio de Cm6.
- `OutsideNotesSkill` clasifica las doce notas con una sola regla, un semitono por encima de una nota del acorde; el manual clasifica las notas de una escala. Llama tensión a B♭ sobre Cmaj7 y notas a evitar a la ♭9 y la ♭13 sobre C7, y le dice al usuario que la séptima mayor sobre una dominante es una tensión alterada.
- Las entradas de GA sobre improvisación son cuatro conceptos de una línea. La caja 1, los modos y los objetivos de GAA-003 están bien.

## Fuentes

- Wikipedia: [Arpeggio](https://en.wikipedia.org/wiki/Arpeggio), [Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system) (una escala por acorde, A7 E7 D7, C7♯11 y el lidio dominante), [Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation) (los arpegios, las parejas de acordes y modos, las extensiones alteradas), [Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale) (la compatibilidad, las notas a evitar, la escala alterada), [Avoid note](https://en.wikipedia.org/wiki/Avoid_note), [Chord notation](https://en.wikipedia.org/wiki/Chord_notation) y [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord) (los símbolos de acorde).
- Streeling: [GAA-003 · Fundamentos de la improvisación](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/).
- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `OutsideNotesSkill.cs`, `ChordIntentMatching.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.Config/ImprovisationConcepts.yaml`, `YamlKnowledgeLoader.fs`; y [GA #626](https://github.com/GuitarAlchemist/ga/pull/626).
