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
- [x] Diagramas: brazaletes, diagramas de acordes, mástil y círculos de quintas dibujados por el programa del curso, comprobados por la CI
- [x] Lección 5: tonalidades, armaduras y el círculo de quintas
- [x] Lección 6: los acordes de una tonalidad
- [x] Lección 7: cadencias, ii–V–I y la tonalidad de una progresión
- [x] Lección 8: el ukelele y el bajo
- [x] Apéndice A: todos los instrumentos del catálogo de GA
- [x] Apéndice B: la jerarquía OPTIC
- [x] Apéndice C: un veredicto para cada línea `DIFF` de las lecciones 1 a 7
- [ ] Lecciones 9 a 17 (ver el plan en la página de la misión)

## QA

Las cuarenta divergencias entre la aritmética de este curso y la de Guitar Alchemist, los diecinueve defectos a los que se reducen y el veredicto de cada una están en el [apéndice C](/learn/es/music-theory-ga/appendix-ga-findings/); dieciséis se fusionaron aguas arriba en [GA #711](https://github.com/GuitarAlchemist/ga/pull/711), y tres quedan como límites de diseño documentados. Esta tabla cubre lo que el apéndice no cubre: los hallazgos fuera de la comparación ejecutable. La última fila se leyó en lugar de ejecutarse, y lo dice.

| Esperado | Lo que pasa | Dónde | Medición | Estado |
|---|---|---|---|---|
| `getAllInstruments()` devuelve los instrumentos que contiene el YAML | Devuelve uno, y dos afinaciones, cayendo sin error ni línea de registro en valores de guitarra escritos a mano | `InstrumentsYaml`/`InstrumentsConfig`, `GA.Business.Config` en `a826864` | El archivo contiene 122 instrumentos y 280 afinaciones; el cargador devolvió 1 y 2. Siete de las 280 ni siquiera son alturas: dos entradas de pedal steel empiezan por el nombre de su afinación, una por la palabra `Tuning`, una por el nombre del instrumento, una conserva parte de su nombre | Corregido upstream por [#734](https://github.com/GuitarAlchemist/ga/pull/734), fusionada el 2026-09-24: el archivo se lee como un diccionario, 122 instrumentos y 280 afinaciones, y un fallo ahora lo dice en stderr en lugar de responder en silencio con la guitarra integrada. Nueve afinaciones se restauraron a partir de `Tunings.txt`; las dos entradas de arpa-guitarra conservan su `|` [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| `Tuning.BuildPitchArray` numera bien las cuerdas de cualquier afinación | Decide qué extremo es la cuerda 1 comparando solo la primera altura con la última, así que una afinación reentrante sale al revés | `Tuning.BuildPitchArray` en `a826864` | Las dos afinaciones de banjo de 5 cuerdas del propio GA, cuya prima va escrita primero y suena más aguda que la última, quedan numeradas al revés — en contra del comentario de `Str`, que dice que la cuerda 1 es la más aguda | Corregido upstream por [#734](https://github.com/GuitarAlchemist/ga/pull/734): el sentido se decide contando los pasos ascendentes y descendentes entre cuerdas vecinas, así que las dos afinaciones de banjo numeran la cuerda 1 como la más aguda [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| El parámetro documentado de `Fretboard.GetNote` coincide con su indexación | El comentario dice «Zero-based string index (0 = lowest string)» y el código indexa `Tuning[stringIndex + 1]`, donde la cuerda 1 es la más aguda | `Fretboard.GetNote` en `a826864` | El que se equivoca es el comentario, no el código | Reproducido, solo documentación [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices) |
| El `ga_chord_to_set` del servidor MCP deletrea el acorde que recibe | Toma sus clases de altura de una closure de F# que guarda un intervalo por extensión y descarta las alteraciones, así que la escritura y el número de Forte salen mal | `DomainClosures.fs#L85-L98`, servidor MCP de GA | `Cm7b5` da `{C, Eb, G, Bb}` y 4-26, donde lo correcto es 4-27 con sol♭; `Cdim7` da 4-27 y «Scale: Major Seventh», donde lo correcto es 4-28 | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionada el 2026-09-23. Relanzado sobre `27a1257`: `Cm7b5` da `{C, Eb, F#, Bb}` y 4-27, `Cdim7` da 4-28 [2026-09-14](#2026-09-14--el-servidor-mcp-de-ga), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| `ga_set_class_subs` agrupa bajo la cualidad correcta los acordes que lista | Todos caen bajo `[maj]`, porque la prueba es `c.EndsWith("")`, cierta para cualquier cadena | `ChordAtonalTool.cs#L187-L190` | Las listas en sí son correctas; solo la agrupación no lo es | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681). Relanzado sobre `27a1257`: las tríadas mayores bajo `[maj]`, las menores bajo `[m]` [2026-09-14](#2026-09-14--el-servidor-mcp-de-ga), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| `ga_scale_by_id` y `ga_scale_by_name` responden para una escala que GA conoce | `ga_scale_by_id(2741)` devuelve Major con `Forte Number: Some(n/a)` donde se espera 7-35, y `ga_scale_by_name("Dorian")` no aparece | servidor MCP de GA | Un campo equivocado, una búsqueda que no encuentra | Corregido upstream por [#681](https://github.com/GuitarAlchemist/ga/pull/681). Relanzado sobre `27a1257`: `Forte Number: 7-35`, y Dorian encontrado con el id 1709 [2026-09-14](#2026-09-14--el-servidor-mcp-de-ga), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| Toda herramienta MCP que recibe un acorde o una tonalidad responde | Varias devuelven la cadena «An error occurred» en lugar de un error MCP | servidor MCP de GA | `get_chord_voicings("C", maxFret 3)`, `get_neighboring_keys` y `get_diatonic_chords("A minor")` responden todas así; `ga_search_voicings("C major open chord")` ignoró la restricción «open» y devolvió `8-8-x-x-7-x` | Reproducido; el commit de build del servidor nunca se confirmó, así que estas filas no están fijadas a `a826864` [2026-09-14](#2026-09-14--el-servidor-mcp-de-ga). Sobre `27a1257`, `get_neighboring_keys("Key of C")` responde F, C, G; las otras tres necesitan GaApi y no se relanzaron [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| `ga_key_from_progression` y `ga_analyze_progression` encuentran la tonalidad que establece una cadencia | Contaban las fundamentales de los acordes en la escaA menor natural y preferían la del primer acorde: `Dm7 G7 Cmaj7` daba D menor, `Am Dm E7 Am` A mayor | [`GuitaristProblemTools.cs#L157-L223`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L157-L223), [`DomainClosures.fs#L255-L336`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L255-L336) | Sobre `27a1257`: `Dm7 G7 Cmaj7` da C mayor, ii V I; `Am Dm E7 Am` da A menor, con E7 cifrado `v` y contado fuera de la tonalidad; `Am F C G` sigue poniendo A menor primero, empatada 4/4 con C mayor, en contra de la propia descripción de la herramienta | Corregido upstream por [#625](https://github.com/GuitarAlchemist/ga/pull/625), fusionada el 2026-09-24, para las dos cadencias; el cifrado y la descripción siguen, no reportados [2026-09-15](#2026-09-15--el-servidor-mcp-de-ga-tonalidades-y-progresiones), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |
| `BraceletNotation.tsx` coloca sus puntos sobre sus propios radios | Los puntos se colocan en `ángulo − 90°` mientras los radios usan `cos(ángulo)` sin desfase, un cuarto de vuelta de diferencia; `findSymmetryAxes` además se salta los ejes que caen entre dos notas y cuenta cada eje dos veces | `ReactComponents/ga-react-components` de GA | Leído en el código, nunca ejecutado | Reproducido por la prueba de [#733](https://github.com/GuitarAlchemist/ga/pull/733), y corregido por ella, fusionada el 2026-09-24 [2026-09-15](#2026-09-15--diagramas), [2026-09-24](#2026-09-24--correcciones-upstream-comprobadas-de-nuevo) |

## Experimentos

Tres preguntas cuya medición podía salir al revés. La primera es la red de seguridad del propio curso: su teoría se escribió a partir de definiciones publicadas, no de GA, de modo que coincidir con GA en los 4096 conjuntos dice algo sobre ambos.

| Pregunta | Hipótesis | Resultado | Veredicto | Dónde |
|---|---|---|---|---|
| ¿Coincide la forma prima de Rahn reescrita desde cero por el curso con la forma prima de identificador mínimo de GA, en todo el espacio? | Construida a partir de Open Music Theory, Wikipedia y la OEIS, con independencia de GA: la coincidencia no estaba garantizada | Coinciden para cada uno de los 4096 conjuntos. Las 224 clases de conjuntos y 352 clases de transposición de GA coinciden con OEIS A000029 y A000031. El empaquetado de Forte difiere del de Rahn en 6 clases de conjuntos y 17 de las 352 clases de transposición | Confirmada, con la diferencia Forte/Rahn cuantificada aparte | [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices) |
| ¿Subir la escalera OPTIC de GA una equivalencia cada vez sobre una digitación real llega a los recuentos del manual? | Escrita de antemano: debería aterrizar en 4096, 352 y 224 | 4096, 352 y 224 | Confirmada | [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices) |
| ¿Cambia dar un parámetro de afinación a `Diagrams.Fretboard` los diagramas de guitarra ya producidos? | Escrita de antemano: no — la guitarra es solo una afinación más entre las nuevas | Los catorce archivos SVG existentes son idénticos byte a byte tras el cambio | Confirmada | [2026-09-15](#2026-09-15--un-veredicto-para-cada-divergencia-el-ukelele-y-el-bajo-tres-apéndices) |

## 2026-09-21 — Conciliación upstream del apéndice C

- [GA #711](https://github.com/GuitarAlchemist/ga/pull/711) concilió los hallazgos ejecutables del apéndice C y se fusionó como [`b363c3f`](https://github.com/GuitarAlchemist/ga/commit/b363c3f086608f850be026546f85ef13c6e6bfb8).
- Los defectos 1–5, 7–11 y 13–18 están corregidos con cobertura de regresión. Las entradas 6, 12 y 19 siguen siendo límites documentados de diseño o representación.
- El curso sigue fijado en `a826864` para que las 40 filas `DIFF` originales continúen siendo reproducibles; el apéndice ahora enlaza el resultado upstream más reciente sin reescribir esa evidencia histórica.

## 2026-09-18 — Correcciones upstream en GA: resolución de las anomalías

- **16 de los 19 defectos resueltos upstream en GA**:
  - Notas y análisis de alturas: fábricas `Pitch.Flat` (`DFlat`, `FFlat`, `GFlat`, `EFlat`, `BFlat`) corregidas; regexes ancladas y precompiladas en `PitchParser`; `Note.Flat.TryParse` corregido para que B natural se analice en B (y no B♭) con soporte Unicode `♭`; separación de `PitchClass.TryParseSetNotation`; `SimpleIntervalSize.TryParse` y `CompoundIntervalSize.TryParse` devuelven `false` ante entradas erróneas sin lanzar excepciones.
  - Acordes y voicings: clasificación de cualidades y sufijos de `ChordFormula` mejorada (separación de dim7 de extensiones de 6ª/13ª, `m7b5` y `dim7` preservados); transposición con ortografía correcta en el constructor de `Chord`; conservación de `Root` y `Formula` originales en inversiones; exclusión de cuerdas al aire (traste 0) en `Voicing.HasBarre()`.
  - Tonalidades: `KeyTools.GetParallelKey` conserva la tónica con el modo opuesto; `KeyTools.GetNeighboringKeys` busca por recuento de armadura; `Key.GetInterval` restablece el orden tónica-a-nota; `Key.Major.TryParse` devuelve `false` con entrada no válida; adición de `HarmonicFunction.Subtonic`; corrección del número romano `iii` en `Cadences.yaml` en mi menor.
  - El defecto 12 (empaquetado en base 12) permanece como limitación fijada para preservar el orden existente del catálogo; los defectos 6 (`ModalFamily`) y 19 (`ClosestDiatonicKey`) se mantienen documentados como compromisos de diseño / heurísticas.

## 2026-09-15 — Un veredicto para cada divergencia, el ukelele y el bajo, tres apéndices

- **Las 40 líneas `DIFF` de las lecciones 1 a 7 ya tienen un veredicto**, en el [apéndice C](../appendix-ga-findings/): 39 son un error de GA, una (`PitchClass.Parse("A")`) es una convención defendible con un fallo de precedencia debajo, y ninguna es un error del curso. Proceden de **19 defectos distintos** —una sola línea equivocada en `Note.Chromatic.ToAccidented` explica ocho líneas ella sola— y se reparten en tres familias: copiar y pegar dentro de un bloque de miembros casi idénticos, un tipo reducido al que se le pide la información que se construyó para descartar, y un `TryParse` que lanza una excepción.
- Nueve frases de las lecciones 1, 2, 3, 4, 6 y 7 presentaban una divergencia como una cuestión de gusto y ahora dan el veredicto. La peor era el «Ninguna respuesta es incorrecta» de la lección 2 a propósito de `ModalFamily`: un modo es una rotación, una escala tiene tantos modos como notas, y las páginas de Ian Ring responden 7 y 6 donde GA responde 14 y 24.
- **Lección 8, el ukelele y el bajo.** Dos hechos que un código con forma de guitarra se equivoca: un ukelele es reentrante (su cuarta cuerda suena más aguda que la tercera), y un bajo está afinado enteramente por cuartas (no tiene el único par irregular de la guitarra). Los saltos de un ukelele son 5 4 5, los mismos que los de las cuatro cuerdas agudas de la guitarra; un ukelele barítono *es* esas cuatro cuerdas; un bajo son las cuatro graves, una octava más abajo.
- `Tuning.BuildPitchArray` decide cuál de los dos extremos de una afinación es la cuerda 1 comparando **solo la primera altura con la última**. Eso funciona con cualquier afinación que suba o baje de principio a fin. Con las dos afinaciones de banjo de 5 cuerdas del propio GA, cuya corta cuerda de bordón se escribe primero y suena más aguda que la última, conserva el orden del archivo y numera las cuerdas al revés. El comentario de `Str`, "String 1 is the string with the highest pitch", no puede ser cierto para ese instrumento: la cuerda 1 es D4 y la cuerda 5 es G4.
- `Fretboard.GetNote` documenta su primer parámetro como "Zero-based string index (0 = lowest string)" y luego indexa `Tuning[stringIndex + 1]`, donde la cuerda 1 es la más aguda. Lo que está mal es el comentario, no el código.
- **Apéndice A: `InstrumentsConfig` devuelve un solo instrumento.** El programa del curso ya referencia `GA.Business.Config` y llama a `getAllInstruments()` en la misma ejecución en que lee el archivo él mismo: el archivo contiene **122 instrumentos y 280 afinaciones**, el cargador devuelve **1 y 2**. `InstrumentsYaml` espera un documento con una lista `Instruments:` de `{ Name, Tunings }`; el archivo es un mapa de instrumentos, cada uno un mapa de afinaciones, sin ninguna clave `Instruments` en ninguna parte. Tanto la comprobación de nulo como el manejador `with _ ->` recurren a `defaultData ()`, dos afinaciones de guitarra escritas a mano. Nada falla y nada se registra.
- Siete de las 280 afinaciones no son alturas: dos entradas de pedal steel empiezan por el *nombre* de su afinación (`C6`, `E9`), una empieza por la palabra literal `Tuning`, otra es el nombre del propio instrumento, a otra le falta la octava, y las dos guitarras arpa usan `|` para separar las cuerdas de subgraves. El mismo desliz de tomar un nombre por una altura produjo las afinaciones de cinco alturas del ukelele, que se analizan sin protestar.
- **Apéndice B: la jerarquía OPTIC.** Una digitación que sube hasta una clase de conjuntos, una equivalencia cada vez, con el tipo de GA en cada peldaño —`PitchClassSet` tras O, P y C, `TranspositionClass` tras T, `SetClass` tras I— y los recuentos 4096, 352 y 224 coincidiendo con los del curso. El esquema de embeddings OPTIC-K de GA parte esa misma escalera en dos: STRUCTURE (dimensiones 6-29, peso 0.45) son los "pitch-class set invariants (O+P+T+I)", MORPHOLOGY (30-53, peso 0.25) es la "physical fretboard realization", es decir todo lo que la escalera descarta. Los pesos y los rangos están leídos en el documento de la skill, no ejecutados: *por verificar*.
- El apéndice explica además el [buscador de escalas](https://ianring.com/musictheory/scales/finder/) de Ian Ring como esa escalera vuelta clicable —Rotate es T, Reflect es I— y [Harmonious](https://harmoniousapp.net/) como el mismo material visto desde el otro extremo, por tonalidad y por acorde en lugar de por número de conjunto.
- El programa del curso crece hasta diez puntos de entrada (`l1` a `l10`), todos en `check.sh`. `Diagrams.Fretboard` ahora recibe una afinación, así que el ukelele y el bajo tienen sus propios diagramas de mástil; los catorce archivos SVG existentes son idénticos byte a byte tras el cambio.
- **Las lecciones se pueden escuchar.** Un bloque de código ```play se convierte en un reproductor: las alturas de una misma línea suenan juntas, una línea tras otra. Las muestras son una nota grabada por semitono de la guitarra de nailon de FluidR3_GM, fijada en un commit de [`gleitz/midi-js-soundfonts`](https://github.com/gleitz/midi-js-soundfonts) y descargada en el primer clic: nada se sintetiza, aquí no se guarda ningún archivo de audio y cada nota es una muestra reproducida a su propia altura. La afinación estándar está en la lección 1, do jonio frente a do dorio en la lección 2, los cuatro voicings en la lección 3, el ii–V–I en la lección 7 y la forma de guitarra frente a los mismos dedos en un ukelele en la lección 8. El bloque es código: es idéntico en los tres idiomas, solo la etiqueta del botón sigue a la página.

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

## 2026-09-15 — Diagramas

- Los diagramas son archivos SVG que escribe el programa del curso ([`Diagrams.cs`](https://github.com/spareilleux/learn/blob/a2439ba/code/music-theory-ga/GaTheory/Diagrams.cs)) en `src/assets/music-theory-ga/` y que las lecciones `.mdx` importan como componentes, así que quedan incrustados en la página. Sus colores son `currentColor` y las variables CSS de Starlight (`--sl-color-accent-high`, `--sl-color-orange-high`, `--sl-color-green-high`, `--sl-color-bg`), con un valor de reserva claro, y siguen el tema claro u oscuro del sitio. Solo contienen nombres de notas y números, así que los tres idiomas comparten los mismos archivos; la descripción está en el `aria-label` de cada página y en el párrafo que precede a la figura.
- `check.sh` los regenera en memoria y los compara con los archivos del repositorio; la CI falla cuando un diagrama no está al día. Para regenerarlos: `dotnet run --project GaTheory -c Release -- svg ../../src/assets/music-theory-ga`.
- GA tiene componentes React para las mismas figuras, que el curso lee pero no reutiliza: `BraceletNotation.tsx`, `FretDiagram.tsx` y `VexChordDiagram.tsx`, en `ReactComponents/ga-react-components/src/components`. Leyendo `BraceletNotation` y su `NoteGroup` (sin ejecutarlos, *por verificar* en un navegador): los puntos y las etiquetas se colocan en `angle − 90°`, pero los radios de `NoteGroup` usan `cos(angle)` sin ese desfase, así que estarían girados un cuarto de vuelta; y `findSymmetryAxes` solo prueba ejes que pasan por una nota, se salta los ejes que pasan entre dos notas y añade cada eje dos veces.

## 2026-09-15 — Lecciones 5 a 7: diferencias en el código de GA (commit a826864)

Conservadas como líneas `DIFF` en las salidas esperadas. Ninguna se ha comunicado al proyecto original.

Lección 5, tonalidades:

- `Key.GetInterval(note)` devuelve `note.GetInterval(Root)`, el intervalo que sube desde la nota hasta la tónica: `Key.Major.C.GetInterval(E)` es m6, no M3 ([`Key.cs#L70-L76`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L70-L76)).
- `Key.Major.TryParse("H")` lanza `InvalidOperationException` en lugar de devolver `false`, y `Key.Minor.TryParse` tiene el mismo código ([`Key.cs#L153-L186`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L153-L186)).
- Las herramientas MCP `get_parallel_key` y `get_relative_key` tienen el mismo cuerpo: el otro modo sobre la misma armadura, así que la tonalidad homónima de C es A menor ([`KeyTools.cs#L135-L169`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L135-L169)).
- `get_neighboring_keys` pasa `key.KeySignature.ToString()`, la lista de alteraciones, a una búsqueda por nombre de tonalidad, y falla ([`KeyTools.cs#L197-L215`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L197-L215)).

Lección 6, acordes de una tonalidad:

- `HarmonicFunctionExtensions.FromDegree(7)` es siempre `LeadingTone`, también para la subtónica de la menor natural; `ScaleDegreeFunction.Subtonic` existe pero no se usa ahí.
- `ga_diatonic_chords` nombra las fundamentales con una tabla de 12 nombres: F♯ mayor recibe `Fdim` (E♯dim) y G♭ mayor recibe `B` (C♭) ([`DomainClosures.fs#L23-L36`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L23-L36)). El `Key.Notes` del núcleo escribe bien las dos tonalidades.
- Solo lectura del código (el curso no compila `GA.Domain.Services`, *por verificar*): `HarmonicFunctionAnalyzer.Parse` prueba `Contains("tonic")` antes que `"supertonic"` y `"mediant"` antes que `"submediant"`, así que "Supertonic" se analizaría como `Tonic` y "Submediant" como `Mediant` ([`HarmonicFunctionAnalyzer.cs#L29-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Tonal/HarmonicFunctionAnalyzer.cs#L29-L72)). `ToPrimaryCategory` agrupa la mediante y la submediante con la tónica, donde Open Music Theory llama a iii y vi predominantes débiles: una elección de manual, no un error.

Lección 7, cadencias y progresiones:

- `Cadences.yaml` numera "Chromatic Mediant (Metal)", Em–Gm en E menor, como `i biii`, desde E mayor; la cadencia andaluza del mismo archivo se numera a partir de las notas de E frigio. Su "Phrygian Half Cadence" es ♭II–i, cuando el término clásico designa iv⁶–V en menor.
- `PitchClassSet.ClosestDiatonicKey` resuelve los empates con «la forma normal contiene la clase de altura 3, luego menor». La forma normal de las notas de una escala mayor es `0 1 3 5 6 8 T`, así que C F G C, G D Em C, Dm7 G7 Cmaj7 y C Am F G7 salen en la relativa menor ([`PitchClassSet.cs#L597-L660`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L660)).
- `ga_key_from_progression` y `ga_analyze_progression` puntúan las tonalidades solo por las fundamentales de los acordes, contra la escala menor natural, y prefieren la fundamental del primer acorde ([`GuitaristProblemTools.cs#L157-L223`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L157-L223), [`DomainClosures.fs#L255-L336`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L255-L336)).

## 2026-09-15 — El servidor MCP de GA, tonalidades y progresiones

La misma salvedad que el 2026-09-14: el servidor no indica su versión.

- `get_parallel_key("Key of C")` → `Key of Am`. `get_relative_key("Key of Ab")` → `Key of Fm`, correcto. `get_key_signature_info("Key of Gm")` → tónica G, `Bb Eb`, notas G A Bb C D Eb F, correcto.
- `get_neighboring_keys("Key of C")` y `get_diatonic_chords("A minor")`: "An error occurred invoking …".
- `ga_diatonic_chords`: F♯ mayor → `F#, G#m, A#m, B, C#, D#m, Fdim`; G♭ mayor → `Gb, Abm, Bbm, B, Db, Ebm, Fdim`.
- `ga_key_from_progression(["Am","F","C","G"])` → mejor opción A menor (luego C mayor y D menor, todas 4/4), mientras que la descripción de la herramienta promete C mayor; `(["Dm7","G7","Cmaj7"])` → D menor (luego C mayor y C menor).
- `ga_analyze_progression("Am Dm E7 Am")` → "Key: A major, I IV V I"; `("Dm7 G7 Cmaj7")` → "Key: D minor, i iv VII".

## 2026-09-15 — Notas sobre los módulos de Streeling (continuación)

- MUS-003, "Guitar Example — D7 to G Voice Movements": la tablatura pone C en el traste 1 de la cuerda E aguda y F♯ en el traste 1 de la cuerda B. El traste 1 es F en la cuerda E aguda y C en la cuerda B; el D7 abierto (`xx0212`) tiene F♯ en el traste 2 de la cuerda 1 y C en el traste 1 de la cuerda 2. Las lecciones enlazan MUS-003 por sus funciones, sus cadencias y sus tonalidades estrechamente relacionadas, no por este ejemplo.
- MUS-003 pone iii y vi en la familia de la tónica; la lección 6 da las dos lecturas.

## 2026-09-24 — Correcciones upstream comprobadas de nuevo

- GA fusionó correcciones para las filas de la tabla QA: [#681](https://github.com/GuitarAlchemist/ga/pull/681) para las herramientas MCP y [#682](https://github.com/GuitarAlchemist/ga/pull/682) para los analizadores el 2026-09-23, [#625](https://github.com/GuitarAlchemist/ga/pull/625) para la detección de tonalidad el 2026-09-24. El curso sigue fijado a `a826864`, así que las lecciones y los apéndices siguen mostrando el comportamiento contra el que se escribieron.
- [`recheck/probe.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/recheck/probe.cs) llama directamente a los mismos métodos de herramientas, sin el transporte MCP, sobre GA [`52f7fd5`](https://github.com/GuitarAlchemist/ga/commit/52f7fd5ce0ba508b2ffd47595e918243c98df5b1); su salida es [`recheck/results.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/recheck/results.txt). Solo imprime los hechos de los que trata cada hallazgo, y [`ga-recheck.yml`](https://github.com/spareilleux/learn/blob/main/.github/workflows/ga-recheck.yml) lo ejecuta cada lunes contra la rama `main` de GA y falla ante cualquier diferencia con `results.txt`: un hallazgo que vuelve, o una corrección que cambia una respuesta, se ve ahí. No forma parte de `check.sh`, porque necesita un clon completo de GA.
- Corregido, y relanzado: `ga_chord_to_set('Cm7b5')` → `{C, Eb, F#, Bb}`, 4-27, y `('Cdim7')` → 0 3 6 9, 4-28 (escrito `{C, Eb, F#, A}`). `ga_set_class_subs('Am')` → las tríadas mayores bajo `[maj]`, las menores bajo `[m]`. `ga_icv_neighbors('C', 1)` → «No other set class within distance 1 of C» en lugar de doce líneas idénticas. `ga_scale_by_id(2741)` → `Forte Number: 7-35`, y `ga_scale_by_name('Dorian')` → id 1709. `get_neighboring_keys('Key of C')` → F, C, G.
- La detección de tonalidad pasa ahora por `KeyIdentificationService`, que suma un peso de cadencia al número de acordes diatónicos ([líneas 171-237](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L171-L237)). `ga_analyze_progression("Dm7 G7 Cmaj7")` → «Key: C major», ii V I, y `ga_key_from_progression` coincide; `ga_analyze_progression("Am Dm E7 Am")` → «Key: A minor», i iv v i.
- [#729](https://github.com/GuitarAlchemist/ga/pull/729), fusionada el 2026-09-24, corrige lo que esa nueva ejecución aún daba mal. En menor, la dominante mayor pertenece ahora a la tonalidad: `"Am Dm E7 Am"` → i iv V i, confianza 4/4 en lugar de 3/4. El numeral sigue la calidad del acorde (`Bm7b5` → viiø, `Bdim` → vii°). Un empate entre tonalidades relativas, que comparten sus acordes, se lo lleva la tonalidad cuya tríada de tónica abre la progresión, y ya no la primera en orden alfabético: `[Am, F, C, G]` → A menor, `[C, G, Am, F]` → C mayor, y `ga_analyze_progression` y `ga_key_from_progression` dan ahora la misma tonalidad. Relanzado sobre [`52f7fd5`](https://github.com/GuitarAlchemist/ga/commit/52f7fd5ce0ba508b2ffd47595e918243c98df5b1): líneas 12-19 de `results.txt`.
- Todavía mal, no reportado: E7 se cifra `v`, porque el número sale del grado de la escala menor natural y no del acorde ([`romanFor`](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L351-L355)); además cuenta fuera de A menor (3/4), por diseño en #625, que acredita el V7 de la escala menor armónica a través de la cadencia. `ga_key_from_progression(["Am","F","C","G"])` sigue poniendo A menor primero, empatada 4/4 con C mayor, y la descripción de la herramienta sigue prometiendo C mayor ([línea 168](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/GaMcpServer/Tools/GuitaristProblemTools.cs#L168)).
- No relanzados: `get_chord_voicings`, `get_diatonic_chords("A minor")` y `ga_search_voicings`, que necesitan GaApi.
- La fila `BraceletNotation` era una lectura de código; [#733](https://github.com/GuitarAlchemist/ga/pull/733), fusionada el 2026-09-24, la reprodujo y la corrigió. Su prueba compara las coordenadas SVG. Con el código antiguo fallan 3 de sus 4 casos: el radio de C termina en x=160 mientras su punto está en x=100; una séptima disminuida da las direcciones de ejes [0, 0, 90] en lugar de [0, 45, 90, 135]; la escala mayor traza dos veces su único eje. Los radios usan ahora el mismo `angleToCoordinates` que los puntos, y los ejes se buscan por medios pasos, así que se encuentran los que caen entre dos notas. El renderizado en un navegador sigue *por verificar*.
- [#734](https://github.com/GuitarAlchemist/ga/pull/734), fusionada el 2026-09-24, corrige las dos filas fuera de los diecinueve defectos, cada una con una prueba que falla con el código antiguo. `getAllInstruments()` devuelve 122 instrumentos y 280 afinaciones donde devolvía 1 y 2. Nueve afinaciones mal formadas se restauraron a partir de `Tunings.txt`, el archivo del que viene el YAML: las dos entradas de pedal steel, el saz, la huapanguera, el dulcimer y las cuatro afinaciones de ukelele que empezaban por `C6` o `D6`. Las afinaciones de banjo de 5 cuerdas numeran ahora la cuerda 1 desde el lado agudo; las que suben o bajan de un extremo a otro se numeran como antes. Los nombres de instrumentos y afinaciones son ahora las claves del YAML, `DropD` en lugar de `Drop D`.
- Una lectura del [apéndice B](../appendix-instruments/) era errónea. `Dulcimer.LydianMode` es `Bb C4 C4 F3 Bb2`, y tomé el primer `Bb` por una altura sin octava. [`Tunings.txt`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Tunings.txt#L112) dice `Ducimer - Lydian Mode Bb C4 C4 F3 Bb2`: el `Bb` es el final del nombre de la afinación, *Lydian Mode Bb*, que la conversión a YAML dejó en la lista de alturas. El apéndice y la fila QA ahora lo dicen.

## Por verificar

- Si el reconocedor completo de acordes de GA (no solo `TryFindExact`) nombra inversiones como `032010`; la búsqueda de voicings por MCP sugiere que sí (`C/E`), pero el curso no lo llamó.
- El commit del servidor MCP: las respuestas anteriores no se reprodujeron contra un servidor compilado desde `a826864`.
- `HarmonicFunctionAnalyzer.Parse` con "Supertonic" y "Submediant", mediante un test en GA.
- Los radios y los ejes de simetría del `BraceletNotation` de GA, renderizados en un navegador.
