---
title: "Leçon 16 : arpèges, théorie accord–gamme et improvisation"
description: L'arpège sur chaque degré, la gamme qui va avec chaque accord et les notes qui le heurtent, comparés avec l'outil ga_arpeggio_suggestions de Guitar Alchemist, les deux compétences de son chatbot qui associent accords et gammes et jugent une note sur un accord, et ses entrées sur l'improvisation.
sidebar:
  label: 16. Arpèges et improvisation
  order: 16
---

La leçon 6 empilait des tierces dans une gamme pour en tirer ses accords, et la leçon 11 jouait une gamme depuis chacun de ses degrés pour en tirer ses modes. L'improvisateur se sert des deux à la fois : sur chaque accord, les notes de l'accord jouées une à une, et une gamme qui comble les trous entre elles. [Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) répond à la question du guitariste, « que jouer sur cet accord ? », à trois endroits : un outil de son serveur MCP, `ga_arpeggio_suggestions`, et deux compétences de son chatbot, `ImprovisationSkill`, qui associe à chaque accord un arpège et des gammes, et `OutsideNotesSkill`, qui dit si une note est une note de l'accord, une tension ou une note à éviter. Le programme du cours compile les deux compétences telles quelles, lit l'outil comme du texte et l'applique, et compare les trois avec les définitions publiées.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Les compétences prennent un logger et un extracteur de requêtes par LLM dans du code que le cours ne compile pas ; [`StandIns.cs`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/StandIns.cs) les remplace, et aucune requête ci-dessous n'atteint l'extracteur. Aucun outil MCP ni aucun chatbot n'a été appelé. Les sorties viennent de la commande ci-dessous ; le point d'entrée est `l18`.

```bash
dotnet run --project code/music-theory-ga/GaTheory -c Release -- l18
```

## Les arpèges

### L'idée

Wikipédia : "An arpeggio … is a type of chord in which the notes that compose a chord are individually sounded in a progressive rising or descending order", et "An arpeggio for the chord of C major going up two octaves would be the notes (C, E, G, C, E, G, C)" ([Arpeggio](https://en.wikipedia.org/wiki/Arpeggio)). En jazz, "Saxophone player Charlie Parker began soloing using the scales and arpeggios associated with the chords in the chord progression" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). L'arpège d'un accord de septième, ce sont ses quatre notes. Empiler des tierces dans la gamme, comme à la leçon 6, donne l'accord de septième de chaque degré : en C majeur, Cmaj7, Dm7, Em7, Fmaj7, G7, Am7 et Bm7♭5 ; en A mineur, les mêmes sept accords à partir de Am7.

### Dans GA : deux tables et une compétence

`ga_arpeggio_suggestions` garde deux tables, une ligne par degré d'une tonalité majeure ou mineure : le suffixe de l'arpège, le mode, et les intervalles du mode ([`GuitaristProblemTools.cs#L385-L406`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L385-L406)). `ImprovisationSkill.ArpeggioFor` nomme l'arpège à partir d'une fondamentale et d'une qualité ([`ImprovisationSkill.cs#L263-L284`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L263-L284)). Le programme vérifie les deux contre les accords du cours ([`Lesson18.cs#L270-L282`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L270-L282)) :

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

Les quatorze suffixes concordent, et `ArpeggioFor` rend à chaque accord son propre symbole.

## La gamme sur chaque accord

### L'idée

"The chord-scale system is a method of matching, from a list of possible chords, a list of possible scales." Wikipédia l'oppose au jeu d'une seule gamme sur toute une grille, "the blues scale on A for all chords of the blues progression: A7 E7 D7" : "in the chord-scale system, a different scale is used for each chord in the progression (for example mixolydian scales on A, E, and D for chords A7, E7, and D7, respectively)". Les enseignants divergent sur l'accord majeur : "Russell associated the C major chord with the lydian scale, while teachers including John Mehegan, David Baker, and Mark Levine teach the major scale as the best match for a C major chord" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)). Un autre article donne des paires : "C7 → C mixolydian", "C-7 → C dorian", "Cmaj7♯11 → C Lydian mode", "C- → C Aeolian mode (natural minor)" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)). Et il donne le critère que le cours applique partout : "the scale contains the chord tones G–B–D♭–F and is said to be compatible with it" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). Une gamme convient à un accord quand elle contient toutes ses notes.

Dans une même tonalité, la gamme de chaque degré est le mode de ce degré, comme l'a montré la leçon 11 : ionien sur I, dorien sur ii, et ainsi de suite jusqu'au locrien sur vii°.

### Dans GA : les tables de l'outil, et les modes de GA

Le programme compare les colonnes Mode et Notes des deux tables avec le mode de chaque degré, et les gammes que nomment l'outil et les compétences avec les modes de GA ([`Lesson18.cs#L284-L315`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L284-L315)) :

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

Les deux tables de l'outil sont justes, et `MajorScaleMode` de GA aussi. Sur les douze autres gammes, dix concordent avec le mode de GA au même rang de sa classe. Les deux lignes `DIFF` sont les modes diminués de GA, comme à la [leçon 12](../12-symmetry-and-limited-transposition/) : le premier, que GA nomme "Half-whole diminished", commence par un ton, et le second à l'inverse. Le correctif que le cours a proposé à GA est dans le [journal](../journal/#2026-10-04--correctifs-proposés-à-guitar-alchemist).

## Ce que renvoie `ga_arpeggio_suggestions`

La description de l'outil dit : "For each chord in a progression, suggest the matching arpeggio and mode to improvise over it. … Example: ["Am","F","C","G"] in C major → Am: Aeolian/Am7, F: Lydian/Fmaj7, C: Ionian/Cmaj7, G: Mixolydian/G7." ([`#L409-L412`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L409-L412)). Quand la requête nomme sa tonalité, le premier mot est la tonique et le second le mode, et tout mot autre que « minor » veut dire majeur ([`#L426-L431`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L426-L431), [`#L450`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L450)). L'outil cherche le degré dont la note est la fondamentale de l'accord ([`#L462-L463`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L462-L463)) et renvoie `chord + arpeggioSuffix`, le symbole entier suivi du suffixe de la table, avec le mode de ce degré ([`#L477-L485`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L477-L485)). Une fondamentale hors de la tonalité reçoit une réponse fixe ([`#L464-L475`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L464-L475)). L'outil demande les paquets MCP et F# du serveur de GA, donc le programme ne le compile pas : il lit dans le fichier les tables et les listes de degrés, applique ces lignes ([`Lesson18.cs#L142-L236`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L142-L236)), et liste les notes de chaque accord hors du mode qu'il reçoit ([`#L317-L341`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L317-L341)) :

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

- Sur son propre exemple, l'outil renvoie « Amm7 », là où sa description dit Am7. Un ii–V–I écrit avec des septièmes reçoit « Dm7m7 », « G77 » et « Cmaj7maj7 ».
- Le mode vient du degré de la fondamentale, pas de l'accord. L'exemple de Wikipédia, A7 E7 D7 en A majeur, reçoit ionien, mixolydien et lydien : le G de A7 est hors de A ionien et le C de D7 hors de D lydien, là où Wikipédia joue mixolydien sur les trois. Un accord de A majeur en C majeur tombe sur le degré vi : l'outil répond « Am7 » et éolien, dont le C heurte le C♯ de l'accord. E7, la dominante de A mineur, reçoit « E7m7 » et phrygien, sans le G♯ de l'accord.
- Une tonalité écrite « Am » se lit « Am major », c'est-à-dire A majeur : Am reçoit « Ammaj7 » et ionien, avec son C en dehors, et Dm reçoit « Dmmaj7 » et lydien.

Le code de GA connaissait les deux premiers. Les remarques d'`ImprovisationSkill` décrivent l'accord de A majeur en C majeur ([`ImprovisationSkill.cs#L22-L32`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)), et un commentaire sur `ArpeggioFor` appelle "root + full-suffix concatenation ("Amm7")" "the single most-broken behavior of the MCP arpeggio tool" ([`#L264-L265`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L264-L265)). [GA #626](https://github.com/GuitarAlchemist/ga/pull/626), fusionnée le 2026-09-24, après le commit du cours du 2026-09-14, fait nommer l'arpège par `InferQuality` et `ArpeggioFor` de la compétence, et comparer la qualité de l'accord avec celle du degré. Sur `main`, la tonalité se lit toujours de la même façon. Lu, pas exécuté.

## Ce que propose `ImprovisationSkill`

La compétence "Suggests scales, modes and arpeggios to improvise / solo over a chord or a whole chord progression" ([`ImprovisationSkill.cs#L46-L51`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L46-L51)). `InferQuality` lit la qualité après la fondamentale, "Most-specific first" ([`#L309-L353`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)) ; `ScalesFor` donne à chaque qualité une liste de gammes, "best/most-common first" ([`#L355-L437`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L355-L437)). Le programme demande 31 symboles sur C, chacun avec ses notes usuelles ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation), [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord)), et cherche les notes de l'accord hors de la première gamme ([`Lesson18.cs#L343-L358`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L343-L358)) :

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

Pour 24 des 31 symboles, la première gamme contient toutes les notes de l'accord. Les sept autres :

- **CM7.** `InferQuality` passe le suffixe en minuscules ([`#L323`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L323)), et « m7 » est le test de la septième mineure ([`#L347`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L347)). Donc CM7, que Wikipédia écrit pour "a C major seventh chord (CM7)" ([Chord notation](https://en.wikipedia.org/wiki/Chord_notation)), reçoit l'arpège Cm7 et dorien, et son E et son B sont hors des trois gammes proposées. `ChordVocabulary`, dans GA, décrit cette régression même : "the skill lowercased the whole quality token before matching, so "CM" resolved to C *minor* instead of C major (a regression of the PR #80 fix that the MCP tool already carried)", regroupée en "one home for the case-sensitive M/M7 handling" ([`ChordVocabulary.cs#L8-L16`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L8-L16)). Son `NormalizeQuality` lit « M7 » comme « major 7 » ([`#L59-L65`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L65)), mais `InferQuality` ne l'appelle pas.
- **Cmaj7♯5** se lit « major 7 », parce que le test de « maj7 » ([`#L340`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L340)) passe avant celui de « 7#5 » ([`#L343`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)) : G♯ est hors de l'ionien comme du lydien.
- **C7♯11, C7♭13 et C7+5** se lisent « dominant 7 », et le mixolydien n'a pas leur F♯, leur A♭ ou leur G♯ ; Lydian Dominant et Mixolydian ♭6, plus loin dans la liste, les ont. Wikipédia associe "C7♯11 and C lydian dominant", où "every note of the scale may be considered a chord tone" ([Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system)).
- **C7♭9 et C7♯9** se lisent « altered dominant », arpège C7alt, et reçoivent d'abord la gamme altérée. Cette gamme garde "The tonic, major third (as a diminished fourth), and dominant seventh" et altère les deux quintes ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)), donc le G de l'accord est en dehors ; Half-Whole Diminished, deuxième, contient les cinq notes.

Deux autres lectures donnent la bonne gamme sous un mauvais nom. Cm6 se lit « minor major 7 » ("mel min territory", [`#L346`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)), donc son arpège est CmMaj7, C E♭ G B, et non C E♭ G A, les notes de l'accord ; le mineur mélodique contient les deux. C6 et C69 se lisent « major triad », arpège C. Cadd9, Csus2, Csus4 et C5 sont « unknown » et reçoivent « Major scale of the chord root ».

`CanHandle` est le filtre par mots-clés de la compétence, la voie de secours derrière le routeur sémantique du chatbot ([`#L92-L94`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L92-L94)). Il refuse l'un des 17 exemples de requête de la compétence, "what scales fit over the progression Cmaj7 A7 Dm7 G7" ([`#L74`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L74)). Ses mots-clés ne comptent que comme mots entiers ([`ChordIntentMatching.cs#L22-L35`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordIntentMatching.cs#L22-L35)) : « what scale » est suivi d'un s, et aucun autre mot-clé n'est dans la phrase ([`ImprovisationSkill.cs#L86-L101`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L86-L101)).

Sur une requête qui nomme deux symboles d'accord ou plus, la compétence classe chaque accord à part ([`#L119-L125`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L119-L125), [`#L212-L261`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261)) ; ses remarques le disent voulu : "The per-chord classification is deliberately key-agnostic" ([`#L23`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L23)). Le programme appelle `ExecuteAsync` directement ([`Lesson18.cs#L359-L368`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L359-L368)) :

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

A7 E7 D7 reçoit trois fois mixolydien, la réponse de Wikipédia, et le vamp dorien du module Streeling GAA-003, Am7 D7, reçoit A dorien et D mixolydien. Sans tonalité, une triade majeure reçoit toujours l'ionien, avec "careful on the IV chord" ([`#L371-L376`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L371-L376)) : sur Am F C G, l'exemple de l'outil, la compétence propose F ionien et G ionien, dont le B♭ et le F♯ ne sont dans aucun des quatre accords, là où la description de l'outil a lydien et mixolydien. Le vamp mixolydien de GAA-003, A7 vers G/A, une triade de G sur une basse de A, se lit comme trois accords : le découpage s'arrête à la barre oblique ([`#L461`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L461)), et la basse devient un accord de A, qui reçoit A ionien et son G♯, contre le G du vamp.

## Les notes hors de l'accord

### L'idée

Wikipédia : "An F against a C major chord could be considered an avoid note because it lies a semitone above the third, an interval which was historically heard as dissonance. Treating the F as a passing tone is a simpler way to use it in a melody over a C major chord" ([Avoid note](https://en.wikipedia.org/wiki/Avoid_note)). Un autre article la place dans la gamme : "An avoid note is a note in a jazz scale that is considered, in jazz theory and practice, too dissonant to be emphasised against the underlying chord", et "Avoid notes are often a minor second (or a minor ninth) above a chord tone or a perfect fourth above the root of the chord" ; "Non-classical harmony just tells you which note in the scale to avoid … meaning that all the others are okay" ([Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale)). La définition accord–gamme trie les notes d'une gamme : une note hors de la gamme n'est ni une tension ni une note à éviter de cette gamme. Sur un accord de dominante, les tensions altérées sont le but : "The altered extensions played by a jazz guitarist or jazz pianist on an altered dominant chord on G might include (at the discretion of the performer) a flatted ninth A♭ …; a sharp eleventh C♯ … and a flattened thirteenth E♭" ([Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation)).

### Dans GA : une règle pour douze notes

Les remarques d'`OutsideNotesSkill` donnent sa règle : "a non-chord-tone that sits a semitone above a chord tone is an avoid note (it forms a b9 clash with that chord tone); any other non-chord-tone is an available tension" ([`OutsideNotesSkill.cs#L20-L28`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L20-L28)). `Classify` l'applique à n'importe quelle note, sans gamme ([`#L141-L189`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L141-L189)). Le programme lui demande les douze notes sur quatre accords de C, et compare ses tensions avec les gammes qu'`ImprovisationSkill` propose pour les mêmes accords ([`Lesson18.cs#L370-L388`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L370-L388)) :

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

Sur Cmaj7, les notes à éviter sont D♭, F et A♭ ; F est la note à éviter de Wikipédia. Toute autre note est une « tension », dans une gamme qui convient à l'accord ou non. Sur Cmaj7, B♭ est « tension: b7 », une septième mineure contre la septième majeure de l'accord, et E♭ « tension: #9 », contre sa tierce majeure ; sur Cm7, F♯ ; sur Cm7♭5, A. Aucune n'est dans les gammes qu'`ImprovisationSkill` propose pour le même accord. B♭ est un demi-ton sous le B de l'accord : la règle ne regarde qu'au-dessus des notes de l'accord. Sur C7, la règle fait de la ♭9 et de la ♭13 des notes à éviter, là où Wikipédia les compte parmi les extensions d'une dominante altérée. Le commentaire sur les accords de dominante nomme "the b9/#9/#11/b13 half-step clashes" ([`#L164-L166`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L166)), mais la ♯9 et la ♯11 ne sont un demi-ton au-dessus d'aucune note de l'accord : elles sortent comme tensions.

Les exemples de requête de la compétence, puis trois questions ajoutées après la première exécution ([`Lesson18.cs#L389-L403`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L389-L403)) :

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

Sept des dix exemples de requête obtiennent une réponse. "what is F over G7" en obtient une quand on l'appelle directement, mais `CanHandle` le refuse : aucun des mots-clés de la compétence n'est dans la phrase ([`#L67-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L67-L72)). "why does that note clash over the chord" passe `CanHandle`, parce que le motif d'accord ignore la casse ([`#L291-L293`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L291-L293)) et lit « the chord » comme un accord de C, puis ne trouve aucune note avant « over ». "why does the b9 sound so tense over C7" passe et reçoit le même texte d'aide : la compétence lit des noms de notes, pas des degrés, comme le disent ses remarques ([`#L31-L33`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L33)). « Bb over C major » se mesure contre une triade de C majeur.

Des trois questions ajoutées après la première exécution, la première montre ce qu'un utilisateur lit sur la septième majeure au-dessus d'un accord de dominante : une note à éviter, puis "over a dominant chord it's exactly the kind of altered tension players reach for (major 7th on the V)" ([`#L164-L172`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L172)). La septième majeure n'est aucune des tensions altérées, et elle heurte la septième de l'accord. Les deux autres montrent qu'`OutsideNotesSkill`, qui lit l'accord par `ChordVocabulary`, prend CM7 pour une septième majeure : deux compétences du même chatbot ne s'accordent pas sur ce symbole.

## GAA-003 et les entrées de GA sur l'improvisation

Le module Streeling [GAA-003 · Fondements de l'improvisation](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/) part de la boîte 1 de la pentatonique mineure de A, "The five notes are: A, C, D, E, G" ([`gaa-003-improvisation-foundations.md#L40-L51`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L40-L51)). Sa première réponse d'auto-évaluation explique pourquoi cette gamme est sûre sur Am7 et moins sur A7 : "Over Am or Am7 none of its notes lies a half step from a chord tone, so no order or combination makes a half-step clash with the chord. Over a dominant chord such as A7 that no longer holds: C lies a half step below the chord's C#, and D a half step above it" ([`#L467`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L467)). Sur un blues en A, il vise la tierce de chaque accord : "For A7, target the 3rd (C#). For D7, target the 3rd (F#). For E7, target the 3rd (G#)" ([`#L175`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L175)). Il épelle trois modes sur A ([`#L267`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L267), [`#L273`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L273), [`#L279`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L279)) et nomme la note qui tire chacun ailleurs, en ajoutant : "They are not "avoid notes" in the chord-scale sense of mus-005, which are notes inside the scale that clash with the chord" ([`#L283-L289`](https://github.com/GuitarAlchemist/Demerzel/blob/0f7a5fd110acfc4835776d38ab1a115533467d34/state/streeling/courses/guitar-alchemist-academy/en/gaa-003-improvisation-foundations.md#L283-L289)). Le programme vérifie ces affirmations par `Classify` ([`Lesson18.cs#L404-L419`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L404-L419)) :

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

Sur Am7, `Classify` est d'accord avec le module : A, C, E et G sont des notes de l'accord, et D une tension. Sur A7, il ne voit que la moitié du frottement : D, un demi-ton au-dessus de C♯, est une note à éviter, mais C, un demi-ton en dessous, est une tension, la ♯9. Les trois notes qui tirent un mode ailleurs sortent toutes comme notes à éviter, l'étiquette que GAA-003 leur refuse. Les trois cibles sont les tierces de la formule de dominante de GA ([`ChordVocabulary.cs#L121`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L121)).

La configuration de GA a un fichier pour l'improvisation, `ImprovisationConcepts.yaml`, avec quatre concepts, chacun un nom et une ligne `Concept` ([`ImprovisationConcepts.yaml#L6-L14`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ImprovisationConcepts.yaml#L6-L14)). `YamlKnowledgeLoader` fait de chacun une entrée pour la recherche : le nom, puis chaque autre champ sous la forme « Key: Value », étiqueté du nom du fichier et de la `Category`, s'il y en a une ([`YamlKnowledgeLoader.fs#L65-L91`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/YamlKnowledgeLoader.fs#L65-L91)). Le programme les charge, puis joue la boîte 1 de GAA-003 et épelle ses trois modes ([`Lesson18.cs#L421-L448`](https://github.com/spareilleux/learn/blob/5d5720e/code/music-theory-ga/GaTheory/Lesson18.cs#L421-L448)) :

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

Les quatre entrées tiennent chacune en un nom et une ligne, et aucune n'associe un accord à une gamme ou à un arpège. La boîte 1 joue A, C, D, E et G, le cinquième mode de la pentatonique majeure de GA, et le module épelle juste ses trois modes. Le chargeur saute `SpecializedTunings.yaml`, comme l'a relevé le [journal](../journal/#2026-10-04--correctifs-proposés-à-guitar-alchemist) ; il le dit sur le flux d'erreur, que la sortie ci-dessus laisse de côté.

## Exercices

1. À `a826864`, que renvoie `ga_arpeggio_suggestions` pour G7 en C majeur, et pourquoi ?
2. Sur un accord de A majeur en C majeur, l'outil propose l'éolien. Quelle note heurte, et quelle note de l'accord ?
3. Pourquoi `ImprovisationSkill` lit-il CM7 comme une septième mineure, alors qu'`OutsideNotesSkill` le lit comme une septième majeure ?
4. `Classify` appelle B♭ sur Cmaj7 une tension. Pourquoi sa règle manque-t-elle le frottement, et que dirait la définition accord–gamme ?
5. Quelles notes de la pentatonique mineure de A sont à un demi-ton d'une note de A7, et comment `Classify` les appelle-t-il ?

<details>
<summary>Solutions</summary>

1. « G77 » et mixolydien. G est le degré V de C majeur, et l'outil ajoute le suffixe de cette ligne, « 7 », au symbole entier.
2. L'éolien sur A a C, un demi-ton sous le C♯ de l'accord. L'outil trouve le degré à partir de la seule fondamentale, A, qui est le degré vi de C majeur.
3. `InferQuality` passe le suffixe en minuscules, donc « M7 » devient « m7 », le test de la septième mineure. `OutsideNotesSkill` passe par `ChordVocabulary.NormalizeQuality`, qui lit « M7 » comme une septième majeure avant toute mise en minuscules.
4. La règle ne regarde qu'un demi-ton au-dessus des notes de l'accord, et B♭ est un demi-ton sous B, la septième de l'accord. B♭ n'est dans aucune des gammes proposées pour Cmaj7, ionien et lydien : au sens accord–gamme, ce n'est ni une tension ni une note à éviter de l'une ou de l'autre, c'est une note hors de la gamme.
5. C, un demi-ton sous C♯, et D, un demi-ton au-dessus. `Classify` appelle D une note à éviter (la 11) et C une tension (la ♯9).

</details>

## À retenir

- Empiler des tierces dans une gamme donne l'arpège de chaque degré. Les deux tables de GA et `ArpeggioFor` nomment juste les quatorze, et les modes de l'outil sont ceux des degrés.
- À `a826864`, `ga_arpeggio_suggestions` ajoute son suffixe au symbole entier (« Amm7 », « G77 ») et prend le mode au degré de la fondamentale, si bien que A7 en A majeur reçoit l'ionien. GA #626 a corrigé les deux le 2026-09-24 ; une tonalité écrite « Am » veut toujours dire A majeur.
- `ImprovisationSkill` lit chaque accord à part, et pour 24 symboles sur 31 sa première gamme contient l'accord. Il lit CM7 comme une septième mineure, la régression que `ChordVocabulary` dit avoir supprimée, Cmaj7♯5 comme une septième majeure, et nomme CmMaj7 l'arpège de Cm6.
- `OutsideNotesSkill` trie les douze notes par une seule règle, un demi-ton au-dessus d'une note de l'accord ; le manuel trie les notes d'une gamme. Il appelle B♭ sur Cmaj7 une tension et la ♭9 et la ♭13 sur C7 des notes à éviter, et il dit à l'utilisateur que la septième majeure sur une dominante est une tension altérée.
- Les entrées de GA sur l'improvisation sont quatre concepts d'une ligne. La boîte 1, les modes et les cibles de GAA-003 sont justes.

## Sources

- Wikipédia : [Arpeggio](https://en.wikipedia.org/wiki/Arpeggio), [Chord-scale system](https://en.wikipedia.org/wiki/Chord-scale_system) (une gamme par accord, A7 E7 D7, C7♯11 et le lydien dominante), [Jazz improvisation](https://en.wikipedia.org/wiki/Jazz_improvisation) (les arpèges, les paires d'accords et de modes, les extensions altérées), [Jazz scale](https://en.wikipedia.org/wiki/Jazz_scale) (la compatibilité, les notes à éviter, la gamme altérée), [Avoid note](https://en.wikipedia.org/wiki/Avoid_note), [Chord notation](https://en.wikipedia.org/wiki/Chord_notation) et [Jazz chord](https://en.wikipedia.org/wiki/Jazz_chord) (les symboles d'accord).
- Streeling : [GAA-003 · Fondements de l'improvisation](../../streeling/guitar-alchemist-academy/gaa-003-improvisation-foundations/).
- GuitarAlchemist/ga à [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `OutsideNotesSkill.cs`, `ChordIntentMatching.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.Config/ImprovisationConcepts.yaml`, `YamlKnowledgeLoader.fs` ; et [GA #626](https://github.com/GuitarAlchemist/ga/pull/626).
