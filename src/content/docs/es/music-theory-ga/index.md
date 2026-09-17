---
title: Teoría musical para Guitar Alchemist — Misión
description: La teoría musical detrás de Guitar Alchemist, para desarrolladores que tocan un poco la guitarra y no leen partituras — cada concepto explicado, escrito en notación y luego localizado en el código C# de GA y contrastado con él.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada tabla de salida de las lecciones procede de [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), un programa .NET 10 que calcula cada concepto a partir de las definiciones de los libros de texto y le pide la misma respuesta a [Guitar Alchemist](https://github.com/GuitarAlchemist/ga). Se compila contra el proyecto `GA.Domain.Core` de GA, clonado en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) lo ejecuta en Linux, Windows y macOS y compara la salida, líneas `DIFF` incluidas, con los archivos esperados. El mismo programa dibuja las figuras, brazaletes, diagramas de acordes, mástiles y círculos de quintas, como archivos SVG, y la CI comprueba que las imágenes del repositorio están al día. Las salidas se capturaron en septiembre de 2026.
:::

:::tip[En 3D]
El [Atlas des Douze](https://claude.ai/artifact/Qh4oMxFH5aPx9dYC4xGjyn) (en francés e inglés) presenta las ideas de este curso en once láminas 3D interactivas: las doce clases de altura en un mástil, una hélice y brazaletes, los siete modos, el vector interválico, el círculo de quintas, los acordes de una tonalidad, una máquina de cadencias, OPTIC-K y las afinaciones. Es una instantánea, no forma parte del curso probado; véase [Artefactos](../artifacts/).
:::

## Por qué aprendo esto

[Guitar Alchemist](https://github.com/GuitarAlchemist/ga) (GA) es una gran base de código C# y F# sobre música: notas, intervalos, escalas, modos, acordes, *voicings*, clases de conjuntos y herramientas que permiten a un asistente de IA razonar sobre ellos. Sé leer el código. Lo que no sé es decir si `ModalFamily`, `PrimeForm` o `GetSymbolSuffix` calculan lo que un músico entiende con esas palabras. Este curso aprende la teoría en fuentes serias, luego lee los tipos de GA con esa teoría en la mano y anota cada punto en que las dos no coinciden.

## Para quién es este curso

Escribes C# o Java. Tocas un poco la guitarra: algunos acordes abiertos, quizá una escala pentatónica. No lees partituras, y no te hace falta: cada concepto llega en tres pasos.

1. **La idea**, en palabras y sobre el mástil.
2. **La notación** con la que la escriben músicos y teóricos.
3. **En GA**: los tipos y métodos que la representan, con enlaces a las líneas exactas.

El lado de la programación te resultará familiar: value objects, records, campos de bits, expresiones `switch`, LINQ.

## Al terminar este curso, sabré

- convertir entre nombres de notas, clases de altura, números MIDI y posiciones en el mástil;
- nombrar y deletrear intervalos, y reducirlos a clases de intervalo;
- construir escalas y modos a partir de patrones de pasos, leerlos como números de 12 bits y dibujarlos como brazaletes;
- leer cifrados de acordes, deletrear acordes, reconocer inversiones y nombrar *voicings* de guitarra;
- calcular vectores interválicos, formas primas y números de Forte, y explicar la relación Z;
- leer armaduras, recorrer el círculo de quintas y encontrar las tonalidades relativas, homónimas y estrechamente relacionadas;
- construir los acordes de una tonalidad, etiquetarlos con números romanos y funciones, y analizar cadencias y progresiones;
- explicar la conducción de voces, las sustituciones, la mezcla modal, las escalas simétricas, los acordes extendidos y las técnicas de voicing de guitarra;
- encontrar cada uno de estos conceptos en el código de GA, y decir dónde GA coincide con la teoría y dónde no.

## Plan

El curso sigue los conceptos que usan el código, los archivos de configuración y las herramientas MCP de GA, desde la nota aislada hasta las transformaciones neorriemannianas. Las lecciones 1 a 7 están escritas; las demás son el plan, y su columna «En GA» nombra los tipos, archivos y herramientas que leerá cada una.

| # | Lección | Teoría | En GA | Si escribes C# |
|---|---|---|---|---|
| 1 | [Notas, clases de altura y el mástil](01-notes-and-the-fretboard/) | altura, clase de altura, alteraciones, intervalos, afinación | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | value objects, jerarquías cerradas de records |
| 2 | [Escalas, modos e ids de escala de 12 bits](02-scales-and-modes/) | escalas mayores y menores, modos, transposición, brazaletes | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, rotación de bits, `PopCount` |
| 3 | [Acordes, cifrados, inversiones y voicings](03-chords-and-voicings/) | tríadas, acordes de séptima, cifrados, inversiones | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parsers, expresiones `switch` |
| 4 | [Clases de conjuntos, vectores interválicos y la relación Z](04-set-classes/) | equivalencia T/I, vectores interválicos, formas primas, números de Forte | `SetClass`, `IntervalClassVector`, `ForteCatalog`, herramientas MCP | formas canónicas, clases de equivalencia |
| 5 | [Tonalidades, armaduras y el círculo de quintas](05-keys-and-the-circle-of-fifths/) | armaduras, tonalidades relativas y homónimas, tonalidades estrechamente relacionadas | `Key`, `KeySignature`, herramientas MCP de tonalidades | value objects de rango, tablas de búsqueda |
| 6 | [Los acordes de una tonalidad](06-diatonic-chords/) | tríadas y acordes de séptima diatónicos, números romanos, nombres de los grados, funciones | `HarmonicFunction`, `Key.Notes`, `PitchClassSet.GetCompatibleKeys`, `ga_diatonic_chords` | enums, pruebas de subconjunto sobre máscaras de bits |
| 7 | [Cadencias, ii–V–I y la tonalidad de una progresión](07-cadences-and-progressions/) | cadencias, movimientos plagal y de engaño, ii–V–I, resolución de V⁷, encontrar la tonalidad | `Cadences.yaml`, `PitchClassSet.ClosestDiatonicKey`, `ga_analyze_progression`, `ga_key_from_progression` | puntuación y desempate |
| 8 | [El ukelele y el bajo](08-ukulele-and-bass/) | afinaciones reentrantes, afinaciones por cuartas, numeración de las cuerdas | `Tuning.Ukulele`, `Tuning.Bass`, `Str`, `Fretboard`, `Instruments.yaml` | deducir a partir de los datos, y cuándo no hacerlo |
| 9 | Conducción de voces y notas comunes | notas comunes, conducción de voces fluida, distancia de conducción de voces | `VoiceLeadingSpace`, `ProgressionVoiceLeadingAnalyzer`, `ga_common_tones`, `ga_voice_leading_pair` | métricas de distancia |
| 10 | Sustituciones y mezcla modal | sustitución por la relativa y por tritono, acordes prestados | `ChordSubstitutionSkill`, `ModalInterchange.yaml`, `get_borrowed_chords`, `ga_chord_substitutions`, `GrothendieckDelta` | clasificación de candidatos |
| 11 | Los modos en profundidad | modos de la menor melódica y de la menor armónica, brillo, familias modales | `MelodicMinorMode`, `HarmonicMinorMode`, `Modes.yaml`, `PitchClassSet.StepBrightness` | genéricos sobre grados de la escala |
| 12 | Simetría: modos de transposición limitada | escalas de tonos enteros, octatónica y aumentada, brazaletes simétricos | `SymmetricScaleMode`, `WholeToneScaleMode`, `DiminishedScaleMode`, `AugmentedScaleMode` | invariantes por rotación |
| 13 | Acordes extendidos y alterados | novenas, oncenas, trecenas, alteraciones, estructuras superiores, poliacordes | `ChordAlterationService`, `ExtendedChords.yaml`, `ga_polychord` | parsers con partes opcionales |
| 14 | Voicings de guitarra: shells, drop 2 y drop 3 | voicings shell, voicings cerrados y drop, notas guía | `VoicingAnalyzer`, `VoicingDecomposer`, `VoicingGenerator`, `ga_search_voicings` | generación combinatoria |
| 15 | El mástil: CAGED, digitación y tocabilidad | formas CAGED, geometría del mástil, digitación, afinaciones alternativas | `FretboardGeometry`, `PhysicalCostService`, `Biomechanics`, `Tunings.toml`, `ga_easier_voicings` | funciones de coste |
| 16 | Arpegios, teoría acorde–escala e improvisación | arpegios, pares acorde–escala, notas fuera de la escala | `ImprovisationConcepts.yaml`, `OutsideNotesSkill`, `ga_arpeggio_suggestions` | tablas de correspondencia |
| 17 | El Tonnetz y las transformaciones neorriemannianas | P, L y R, el Tonnetz, mediantes cromáticas | `NeoRiemannian.yaml`, `NeoRiemannianConfig.fs` | grafos de transformaciones |
| A | [Todos los instrumentos de Guitar Alchemist](appendix-instruments/) | afinaciones, órdenes, cuerdas reentrantes | `Instruments.yaml`, `InstrumentsConfig`, `Tuning` | configuración que nadie lee |
| B | [La jerarquía OPTIC](appendix-optic/) | octava, permutación, transposición, inversión, cardinalidad | `PitchClassSet`, `TranspositionClass`, `SetClass`, el esquema OPTIC-K de GA | equivalencia, cociente tras cociente |
| C | [Cada divergencia, y de quién es el error](appendix-ga-findings/) | las 40 líneas `DIFF` de las lecciones 1 a 7 | los 19 defectos de los que proceden | leer una comparación con honestidad |
| — | [Diario](journal/) | | | |

## Requisitos previos

- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y [Git](https://git-scm.com/downloads). En Windows, ejecuta los scripts del curso desde Git Bash.
- Menos de 20 MB de disco para el clon parcial de GA, salida de compilación incluida: el script descarga solo los archivos de los tres proyectos contra los que se compila el programa.
- Una guitarra ayuda: todos los ejemplos se pueden tocar.

## Módulos relacionados en este sitio

Los módulos de [Streeling](../streeling/), generados a partir de [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), cubren parte del mismo terreno desde el lado del músico. Cada lección enlaza los que vienen al caso:

- [MUS-001 · ¿Qué es un acorde?](../streeling/music/mus-001-what-is-a-chord/) y [MUS-002 · Más allá de la tonalidad](../streeling/music/mus-002-beyond-tonality/) (lecciones 3 y 4);
- [MUS-006 · El universo de las escalas](../streeling/music/mus-006-the-scale-universe/) (lecciones 2 y 4);
- [MUS-003 · Cómo funciona la armonía](../streeling/music/mus-003-functional-harmony/) (lecciones 5, 6 y 7) y [MUS-005 · Armonía de jazz para guitarra](../streeling/music/mus-005-jazz-harmony/) (lección 7);
- [GTR-001 · El mapa del mástil](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · Geometría CAGED](../streeling/guitar-studies/gtr-002-caged-geometry/) y [GAA-001 · Tu primer acorde](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (lecciones 1 y 3).

## Recursos

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), versión 2 (2023), un libro de texto gratuito y revisado por pares bajo CC BY-SA 4.0: la principal fuente teórica del curso.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): todas las escalas por su número de 12 bits, la numeración que usa GA, con un diagrama de brazalete para cada una.
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord), [Circle of fifths](https://en.wikipedia.org/wiki/Circle_of_fifths), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga): el código que lee este curso.
