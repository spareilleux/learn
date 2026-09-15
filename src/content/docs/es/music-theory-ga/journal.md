---
title: Diario
description: Notas de progreso fechadas — fijación y compilación de GA, ejecuciones de CI, diferencias entre la teoría, el código de GA y las herramientas MCP de GA, y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Programa del curso: .NET 10, compilado contra el `GA.Domain.Core` de GA en un commit fijado
- [x] CI: la salida de cada lección comparada con su archivo esperado en tres sistemas operativos
- [x] Lección 1: notas, clases de altura y el mástil
- [x] Lección 2: escalas, modos e ids de escala de 12 bits
- [x] Lección 3: acordes, cifrados, inversiones y voicings
- [x] Lección 4: clases de conjuntos, vectores interválicos y la relación Z

## 2026-09-14 — Fijar GA y compilar contra él

- GA está fijado en [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6) (`chore(quality): snapshot 2026-09-14`), la cabeza de `main` ese día. El clon local de GA del autor nunca se usa ni se modifica: [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/fetch-ga.sh) hace su propio clon en `code/music-theory-ga/.ga`, ignorado por Git.
- El clon no tiene blobs (`--filter=blob:none`) y usa un sparse checkout en modo no cono de `/Directory.Build.props`, `GA.Core`, `GA.Business.Config` y `GA.Domain.Core`: Git descarga solo el contenido de esos archivos al hacer checkout. `GA.Domain.Core` referencia los otros dos; `GA.Business.Config` es un proyecto F#, que el SDK de .NET compila sin configuración adicional.
- En Git Bash sobre Windows, los patrones sparse que empiezan por `/` se reescribían como rutas de Windows (`C:/Program Files/Git/Common/...`) y no coincidían con nada. `MSYS_NO_PATHCONV=1` lo arregla.
- Un `git grep` sobre el clon sin blobs se quedó colgado: descargaba uno a uno todos los blobs del repositorio. Leer archivos sueltos con `git show HEAD:<path>` descarga solo esos.
- El proyecto del curso referencia GA con un simple `ProjectReference` ([`GaTheory.csproj`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/GaTheory.csproj#L9-L14)). Compilación local de los tres proyectos de GA más el curso: de 5 a 13 segundos tras la primera restauración.
- Ejecución de CI [34903462624](https://github.com/spareilleux/learn/actions/runs/34903462624), para el push que contenía el commit `79d2198`: en verde en los tres sistemas operativos, 34 s en Linux, 47 s en macOS, 67 s en Windows, clon incluido.

## 2026-09-14 — Verificar la teoría

- El [`Theory.cs`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/Theory.cs) del curso está escrito solo a partir de las definiciones de los libros de texto y luego se compara con GA. Fuentes: *Open Music Theory* (capítulos citados en cada lección), Wikipedia (MIDI tuning standard, Guitar tunings, Guitar chord, Blues scale, Interval vector, List of set classes), la escala 2741 de Ian Ring, OEIS A000029 y A000031.
- El sitio de Open Music Theory y la OEIS responden 403 a los clientes HTTP simples; los capítulos se leyeron en un navegador.
- Comprobado en bloque sobre los 4096 conjuntos: la forma prima de Rahn del curso es igual a la forma prima de id mínimo de GA para todos los conjuntos; 224 clases de conjuntos y 352 clases de transposición, como dice la OEIS. Los empaquetados de Forte y de Rahn difieren en 6 clases de conjuntos, y en 17 de las 352 clases de transposición, la cifra que da *List of set classes* (las 17 se calcularon con el mismo algoritmo fuera del programa).
- Errores encontrados en el propio programa del curso al escribirlo: el conjunto vacío hacía fallar la clave de ordenación de la forma prima; la regla de la cejilla contaba al principio las cuerdas al aire, copiando a GA; el voicing `x02010` se nombraba al principio C6/A, hasta que el nombrador probó primero el bajo como fundamental.

## 2026-09-14 — Diferencias en el código de GA (commit a826864)

Conservadas como líneas `DIFF` en las salidas esperadas, para que la CI se entere cuando GA cambie. Ninguna se ha comunicado al proyecto original.

Lección 1, notas:

- `Pitch.Flat.DFlat(octave)`, `FFlat` y `GFlat` construyen D, G y A ([`Pitch.cs#L285-L295`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295)).
- La regex de `PitchParser` no tiene anclas e ignora las mayúsculas: `Pitch.Sharp.TryParse("Eb2")` tiene éxito con B2.
- `Note.Flat.Parse("B")` es B♭: el parser pasa a mayúsculas y luego lee una `B` final como bemol.
- `PitchClass.Parse("A")` es 10 (dígito de estilo hexadecimal, a propósito), mientras que la nota A es 9.
- `SimpleIntervalSize.TryParse` lanza una excepción en lugar de devolver `false`.
- `Fretboard.GetPositionsForNote(Note.Sharp.C)` no encuentra nada: las posiciones contienen `Note.Chromatic`, y los records de tipos distintos nunca son iguales.
- Menor, sin efecto visible: `ValueObjectUtils.IsValueInRange(..., normalize: true)` calcula `count = max - min` y suma 1 después del módulo, a diferencia de `EnsureValueRange`; con la normalización, ambos acaban siempre dentro del rango ([`ValueObjectUtils.cs#L69-L92`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L69-L92)).

Lección 2, escalas:

- `ModalFamily` agrupa los conjuntos que contienen 0 por vector interválico, no por rotación: 14 «modos» para la menor armónica (sus propios 7 y los de la mayor armónica), 24 para el blues (con su inversión y una clase relacionada por Z). No es un error, pero el nombre sugiere rotaciones.
- Las escalas menores están escritas desde A, así que `Scale.NaturalMinor` tiene el id de C mayor (2741). Es lo esperable para un conjunto de clases de altura, pero sorprende junto a las demás escalas, escritas desde C.

Lección 3, acordes:

- `ChordFormula.DetermineQuality` nunca devuelve `Major7`, `Minor7`, `HalfDiminished` ni `Diminished7`, así que `GetSymbolSuffix` da `7` para maj7, `dim7` para m7♭5 y `dim6` para dim7.
- El constructor de `Chord` escribe todas las notas que no son la fundamental con sostenidos: `Eb` → `Eb G A#`, `Gb7` → `Gb A# C# E`.
- `Chord.AnalyzeChordFormula` omite `Notes[0]` como si fuera la fundamental; tras `ToInversion(1)` es el bajo, la tercera se pierde y la cualidad es `Other`.
- `Voicing.HasBarre` cuenta las cuerdas al aire: el C abierto con un E grave, el E abierto y el G abierto son acordes «con cejilla».
- Los diagramas de voicings de GA empiezan por la cuerda 1 (E aguda), al revés que los diagramas de acordes.
- `CanonicalChordPatternCatalog` lista cuatro conjuntos de intervalos dos veces (`9-sus4`/`dominant-11`, `major-6-add-9`/`6-9`, `minor-6-add-9`/`minor-6-9`, `augmented-7`/`dominant-7-sharp-5`); `TryFindExact` nunca puede devolver el segundo nombre de cada par.
- En el uso que hace el curso, el catálogo empareja intervalos desde la nota más grave, así que una inversión como `032010` (C/E) no tiene nombre.

Lección 4, clases de conjuntos:

- `IntervalClassVectorId` empaqueta los recuentos en base 12; los recuentos de 12 de la escala cromática desbordan y se decodifican como `<1 1 1 1 0 6>`.
- `CanonicalForteCatalog` describe sus datos como "the standard Forte-column values", pero almacena las grafías de Rahn para las clases en disputa (`5-20 01568`, `6-Z29 023679`), como la tabla de Open Music Theory. Las etiquetas son correctas; solo el comentario es impreciso.
- `GrothendieckDelta.FromIcVs` convierte una diferencia nula en `Ic1 = 1` a propósito, así que los conjuntos con el mismo vector aparecen a distancia 1, y los «vecinos a distancia 1» de una tríada son las demás tríadas mayores y menores, ella incluida.

## 2026-09-14 — El servidor MCP de GA

Llamado desde esta sesión a través del servidor MCP de GA (el servidor no indica versión; puede que no ejecute el commit `a826864`). Las referencias al código son de `a826864`.

- `ga_set_class_subs("Am")` y `("G7")`: las listas correctas (todas las tríadas mayores y menores; todas las séptimas de dominante y semidisminuidas), pero todos los acordes bajo `[maj]` (`c.EndsWith("")` en [`ChordAtonalTool.cs#L187-L190`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L187-L190)), y una descripción que dice "Am and C are NOT equivalent".
- `ga_chord_intervals`: `Cm7b5` → P1 m3 P5 m7, `G7b9` → P1 M3 P5 m7, `C9` → P1 M3 P5 M9, `Cmaj9` → P1 M3 P5 M9. El closure F# conserva un intervalo por extensión e ignora las alteraciones ([`DomainClosures.fs#L85-L98`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L85-L98)). `ga_parse_chord("Cm7b5")` sí analizó `alt:b5`.
- `ga_chord_to_set`, que toma sus clases de altura del mismo closure: `Cm7b5` → `{C, Eb, G, Bb}`, 4-26 (debería ser 4-27, con G♭); `Cdim7` → `{C, Eb, F#, Bb}`, 4-27, "Scale: Major Seventh" (debería ser 4-28, con A); `C` → 3-11, prima `0 3 7`, una familia modal de 6.
- `ga_icv_neighbors("C", 1)`: doce líneas idénticas `<0 0 1 1 1 0> Δ=1 Forte:3-11 [Major Triad]`, explicadas por la regla de la diferencia nula de arriba.
- `ga_scale_by_id(2741)`: Major, con `Forte Number: Some(n/a)` (se esperaba 7-35). `ga_scale_by_name("Dorian")`: no encontrada.
- `get_tuning(Guitar, Standard)`: E2 A2 D3 G3 B3 E4, correcto. `get_chord_voicings("C", maxFret 3)`: "An error occurred". `ga_search_voicings("C major open chord")`: la restricción "open" se ignoró (diagrama `8-8-x-x-7-x`, etiquetado C/E).

## 2026-09-14 — Notas sobre los módulos de Streeling

Los módulos se generan a partir de GuitarAlchemist/Demerzel y no se modificaron; las lecciones los enlazan donde ayudan.

- MUS-006, "Modes as Rotations": un desplazamiento circular a la izquierda del id transpone (C mayor desplazada 2 es D mayor, 2774); para obtener D dórico sobre C hace falta el desplazamiento opuesto (1709). La respuesta del ejercicio "rotate left by 2 semitones → 2nd mode" tiene el mismo problema de dirección.
- MUS-006 dice que Forte "identified 224 distinct set classes for cardinalities 3 through 9"; 224 cuenta todas las cardinalidades de 0 a 12.
- MUS-002 obtiene la forma prima de las cuerdas al aire (E A D G B) como `[0,2,5,7,9]`, comparando clases de altura en lugar de intervalos en el desempate; la forma prima es `(02479)`. El mismo módulo responde "are major and minor triads different set classes? Yes", luego pone ambas en 3-11, y escribe las formas primas entre corchetes donde Open Music Theory usa paréntesis.
- GTR-002 etiqueta la forma de C `x 3 2 0 1 0` con "Strings: 5-4-3-2-1": seis símbolos para cinco cuerdas, siendo la `x` la cuerda 6.

## Por verificar

- Si el reconocedor completo de acordes de GA (no solo `TryFindExact`) nombra inversiones como `032010`; la búsqueda de voicings por MCP sugiere que sí (`C/E`), pero el curso no lo llamó.
- El commit del servidor MCP: las respuestas anteriores no se reprodujeron contra un servidor compilado desde `a826864`.
