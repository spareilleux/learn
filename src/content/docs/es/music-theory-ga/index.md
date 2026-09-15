---
title: Teoría musical para Guitar Alchemist — Misión
description: La teoría musical detrás de Guitar Alchemist, para desarrolladores que tocan un poco la guitarra y no leen partituras — cada concepto explicado, escrito en notación y luego localizado en el código C# de GA y contrastado con él.
sidebar:
  label: Misión
  order: 0
---

:::note[Cómo se prueba este curso]
Cada tabla de salida de las lecciones procede de [`code/music-theory-ga`](https://github.com/spareilleux/learn/tree/main/code/music-theory-ga), un programa .NET 10 que calcula cada concepto a partir de las definiciones de los libros de texto y le pide la misma respuesta a [Guitar Alchemist](https://github.com/GuitarAlchemist/ga). Se compila contra el proyecto `GA.Domain.Core` de GA, clonado en el commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). [`.github/workflows/music-ga-examples.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/music-ga-examples.yml) lo ejecuta en Linux, Windows y macOS y compara la salida, líneas `DIFF` incluidas, con los archivos esperados. Las salidas se capturaron en septiembre de 2026.
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
- construir escalas y modos a partir de patrones de pasos y leerlos como números de 12 bits;
- leer cifrados de acordes, deletrear acordes, reconocer inversiones y nombrar *voicings* de guitarra;
- calcular vectores interválicos, formas primas y números de Forte, y explicar la relación Z;
- encontrar cada uno de estos conceptos en el código de GA, y decir dónde GA coincide con la teoría y dónde no.

## Plan

| # | Lección | Teoría | En GA | Si escribes C# |
|---|---|---|---|---|
| 1 | [Notas, clases de altura y el mástil](01-notes-and-the-fretboard/) | altura, clase de altura, alteraciones, intervalos, afinación | `PitchClass`, `Note`, `Interval`, `Tuning`, `Fretboard` | value objects, jerarquías cerradas de records |
| 2 | [Escalas, modos e ids de escala de 12 bits](02-scales-and-modes/) | escalas mayores y menores, modos, transposición | `PitchClassSetId`, `Scale`, `MajorScaleMode`, `ModalFamily` | `[Flags]`, rotación de bits, `PopCount` |
| 3 | [Acordes, cifrados, inversiones y voicings](03-chords-and-voicings/) | tríadas, acordes de séptima, cifrados, inversiones | `Chord`, `ChordFormula`, `CanonicalChordPatternCatalog`, `Voicing` | parsers, expresiones `switch` |
| 4 | [Clases de conjuntos, vectores interválicos y la relación Z](04-set-classes/) | equivalencia T/I, vectores interválicos, formas primas, números de Forte | `SetClass`, `IntervalClassVector`, `ForteCatalog`, herramientas MCP | formas canónicas, clases de equivalencia |
| — | [Diario](journal/) | | | |

## Requisitos previos

- El [SDK de .NET 10](https://dotnet.microsoft.com/download/dotnet/10.0) y [Git](https://git-scm.com/downloads). En Windows, ejecuta los scripts del curso desde Git Bash.
- Menos de 20 MB de disco para el clon parcial de GA, salida de compilación incluida: el script descarga solo los archivos de los tres proyectos contra los que se compila el programa.
- Una guitarra ayuda: todos los ejemplos se pueden tocar.

## Módulos relacionados en este sitio

Los módulos de [Streeling](../streeling/), generados a partir de [GuitarAlchemist/Demerzel](https://github.com/GuitarAlchemist/Demerzel), cubren parte del mismo terreno desde el lado del músico. Cada lección enlaza los que vienen al caso:

- [MUS-001 · ¿Qué es un acorde?](../streeling/music/mus-001-what-is-a-chord/) y [MUS-002 · Más allá de la tonalidad](../streeling/music/mus-002-beyond-tonality/) (lecciones 3 y 4);
- [MUS-006 · El universo de las escalas](../streeling/music/mus-006-the-scale-universe/) (lecciones 2 y 4);
- [GTR-001 · El mapa del mástil](../streeling/guitar-studies/gtr-001-the-fretboard-map/), [GTR-002 · Geometría CAGED](../streeling/guitar-studies/gtr-002-caged-geometry/) y [GAA-001 · Tu primer acorde](../streeling/guitar-alchemist-academy/gaa-001-your-first-chord/) (lecciones 1 y 3).

## Recursos

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/), versión 2 (2023), un libro de texto gratuito y revisado por pares bajo CC BY-SA 4.0: la principal fuente teórica del curso.
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/): todas las escalas por su número de 12 bits, la numeración que usa GA.
- Wikipedia: [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [List of set classes](https://en.wikipedia.org/wiki/List_of_set_classes), [Guitar chord](https://en.wikipedia.org/wiki/Guitar_chord).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga): el código que lee este curso.
