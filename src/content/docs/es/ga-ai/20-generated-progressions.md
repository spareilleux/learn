---
title: "Lección 20: Las progresiones generadas"
description: "El servidor MCP de Guitar Alchemist escribe progresiones de acordes sin modelo, a partir de nueve plantillas, con la herramienta ga_generate_progression; el chatbot no la llama. Todos los acordes tienen las notas correctas, y 712 de 750 se escriben como los escribe un manual en las 15 tonalidades de cada modo: D, G y C menor reciben sostenidos, y con doce nombres por grafía no se pueden escribir Cb, Fb ni E#. La propia tabla de doce tonalidades de GA escribe el mismo B para el IV de Gb. Un cifrado se acepta como tonalidad, una b minúscula pasa B mayor a bemoles y la longitud no tiene límite: 100000 acordes ocupan 17.300.216 caracteres. Al enlazar los acordes con ga_voice_leading_pair, como sugiere la respuesta, los primeros pares empalman en 17 de 32 puntos en main."
sidebar:
  label: 20. Las progresiones generadas
  order: 20
---

La [lección 19](../19-voice-leading-pairs/) ejecutó `ga_voice_leading_pair`, una herramienta de `GaMcpServer`, el servidor MCP de GA. El mismo archivo contiene su compañera, `ga_generate_progression`: dados la fundamental de una tonalidad y el nombre de una plantilla, escribe una progresión de acordes, "Deterministic — no LLM" (determinista, sin LLM) ([`CompositionTools.cs` líneas 108-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L108-L177)). Su respuesta termina con una nota: "Compose by passing each chord to ga_search_voicings; stitch with ga_voice_leading_pair for smooth-voiced transitions" (compón pasando cada acorde a ga_search_voicings; enlázalos con ga_voice_leading_pair para obtener transiciones con una conducción de voces suave). El chatbot no la llama, y la skill redactada para llamarla está en espera, como la de la lección 19 ([`skills-dev/_pending-tools/README.md` línea 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L49)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. `CompositionTools.cs` y `ChordPitchClasses`, que lee la fundamental, son idénticos en el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), así que el programa solo pide las progresiones en el commit fijado. La última sección las enlaza con `ga_voice_leading_pair`, cuya búsqueda cambió en `main`, así que `GaMain` la vuelve a ejecutar. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l20
dotnet run --project code/ga-ai/GaMain -c Release -- l20
```

## Cómo responde la herramienta

Cada plantilla es una lista de pasos: un desplazamiento en semitonos desde la fundamental de la tonalidad, una cualidad de acorde y un número romano ([líneas 27-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L27-L37)):

```csharp
    private record ProgressionStep(int SemitoneOffset, string Quality, string RomanLabel);

    private static readonly Dictionary<string, ProgressionStep[]> Templates = new(StringComparer.OrdinalIgnoreCase)
    {
        // Jazz staples
        ["ii-V-I"] =
        [
            new(2, "m7",  "ii7"),
            new(7, "7",   "V7"),
            new(0, "maj7", "Imaj7"),
        ],
```

Las nueve plantillas son ii-V-I, circle-of-fifths, rhythm-changes-a, I-V-vi-IV, I-vi-IV-V, canon, 12-bar-blues y dos en menor, minor-vamp y andalusian ([líneas 29-106](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L29-L106)). La herramienta comprueba la fundamental con `ChordPitchClasses.TryParse` ([línea 139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L139)) y luego nombra la fundamental de cada acorde con uno de dos arrays de doce nombres, en sostenidos o en bemoles ([líneas 344-380](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L344-L380)):

```csharp
    private static string BuildSymbol(int rootPc, ProgressionStep step, bool preferFlats)
    {
        var chordRootPc = (rootPc + step.SemitoneOffset) % 12;
        var rootName = preferFlats
            ? PitchClassToFlatName(chordRootPc)
            : PitchClassToSharpName(chordRootPc);
        return rootName + step.Quality;
    }

    private static string PitchClassToSharpName(int pc) => pc switch
    {
        0  => "C",  1  => "C#", 2  => "D",  3  => "D#",
        4  => "E",  5  => "F",  6  => "F#", 7  => "G",
        8  => "G#", 9  => "A",  10 => "A#", 11 => "B",
        _  => "C",
    };

    private static string PitchClassToFlatName(int pc) => pc switch
    {
        0  => "C",  1  => "Db", 2  => "D",  3  => "Eb",
        4  => "E",  5  => "F",  6  => "Gb", 7  => "G",
        8  => "Ab", 9  => "A",  10 => "Bb", 11 => "B",
        _  => "C",
    };

    /// <summary>
    ///     True when the user's key root is on the flat side of the circle of fifths
    ///     (F, Bb, Eb, Ab, Db, Gb — i.e. the symbol contains a 'b' OR is plain F). Used
    ///     to pick flat vs sharp enharmonic spelling for generated chord symbols so
    ///     "ii-V-I in Bb" yields Bbmaj7 rather than the sharp-spelled A#maj7.
    ///     C is treated as sharp-side (the pop convention for chromatic chords in C).
    /// </summary>
    private static bool PrefersFlats(string root)
    {
        var r = root.Trim();
        return r.Contains('b') || r.Equals("F", StringComparison.OrdinalIgnoreCase);
    }
```

Cada acorde de la respuesta lleva su número romano, su cifrado, un `degree`, su cualidad y sus clases de altura ([líneas 158-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L158-L165)). `degree` guarda el desplazamiento en semitonos, 7 para V, no el grado de la escala.

## Las plantillas en todas las tonalidades

El programa pide las siete plantillas mayores en las 15 tonalidades mayores que se escriben con una armadura, de C♭ a C♯, y las dos menores en las 15 tonalidades menores, de A♭ menor a A♯ menor. Un manual escribe la fundamental de cada acorde con la letra del grado de su número romano en la tonalidad, y con la alteración que da la nota: en D menor, ♭VI es B♭, nunca A♯. El programa compara cada cifrado con esa grafía, y las clases de altura con las del acorde:

```text
== The nine templates in the keys a textbook writes, at the pin, against the textbook's spelling
template           mode    keys   chords   spelled right   pitch classes right
ii-V-I             major   15     45       44              45
circle-of-fifths   major   15     60       59              60
rhythm-changes-a   major   15     120      118             120
I-V-vi-IV          major   15     60       57              60
I-vi-IV-V          major   15     60       57              60
canon              major   15     120      113             120
12-bar-blues       major   15     180      167             180
minor-vamp         minor   15     45       44              45
andalusian         minor   15     60       53              60
chords 750: spelled right 712, pitch classes right 750
the chords spelled otherwise, as the tool writes them, with the textbook's spelling and their count:
  Cb major   Bmaj7 for Cbmaj7 3, B for Cb 4, E for Fb 4, B7 for Cb7 7, E7 for Fb7 3
  C# major   Fm7 for E#m7 1, Fm for E#m 1
  Gb major   B for Cb 4, B7 for Cb7 3
  A# minor   F7 for E#7 1, F for E# 1
  D minor    A# for Bb 1
  G minor    D# for Eb 1
  C minor    A# for Bb 1, G# for Ab 1
  Eb minor   B for Cb 1
  Ab minor   E for Fb 1
```

- **Todos los acordes tienen las clases de altura correctas, y 712 de 750 se escriben como los escribe un manual.** El fallo está solo en los nombres.
- **D, G y C menor reciben sostenidos.** `PrefersFlats` busca una `b` en la fundamental, o la fundamental F; su comentario enumera el lado de los bemoles como "F, Bb, Eb, Ab, Db, Gb". Las tres tonalidades menores llevan bemoles en su armadura, pero ninguno en su nombre: la plantilla andalusian en C menor se escribe con A♯ y G♯ en lugar de B♭ y A♭.
- **Doce nombres por array no bastan para escribir todas las tonalidades.** Cada array tiene un nombre por clase de altura. En C♭ mayor, la tónica se escribe B, y el IV, E; en G♭ mayor, el IV se escribe B; en C♯ mayor, el iii se escribe Fm en lugar de E♯m; en A♯ menor, el V se escribe F7 en lugar de E♯7. E♭ menor y A♭ menor reciben B y E para su ♭VI, C♭ y F♭. Las lecciones 10 y 18 encontraron los mismos doce nombres en otras partes de GA.

## Las propias tablas de GA

`ChordProgressions.yaml`, la configuración de progresiones de GA, termina con tablas de transposición: tres de ellas corresponden a una plantilla de la herramienta ([líneas 580-695](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L580-L695)). El programa las lee y le pide a la herramienta las mismas tonalidades:

```text
== The tool against the twelve-key tables of GA's ChordProgressions.yaml, at the pin
table                                template        keys   same chords   spelled otherwise by a textbook
ii–V–I (Major) — 12 keys             ii-V-I          12     12            none
Pop I–V–vi–IV — 12 keys (triads)     I-V-vi-IV       12     12            Gb: Gb Db Ebm B, textbook Gb Db Ebm Cb
12-Bar Blues — common guitar keys    12-bar-blues    5      5             none
```

- **La herramienta y las tablas de GA coinciden en todas las filas, incluido un acorde equivocado.** La tabla de I-V-vi-IV escribe B para el IV de G♭, como la herramienta ([línea 685](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L685)); un manual escribe C♭. Dos fuentes que coinciden no son una comprobación: la tabla no puede servir de prueba para la herramienta.

## Las fundamentales que lee

`ChordPitchClasses` lee un cifrado, no una tonalidad. Su tabla de fundamentales no distingue mayúsculas de minúsculas, y lista C♭ pero no E♯, ni ningún `♭` ([`MusicalQueryEncoder.cs` líneas 166-171](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L166-L171)). El programa prueba algunas fundamentales que podrían escribir un guitarrista o un agente:

```text
== The roots the tool reads, at the pin
root       template       chords, or the error
C          I-V-vi-IV      C G Am F
c          I-V-vi-IV      C G Am F
B          I-V-vi-IV      B F# G#m E
b          I-V-vi-IV      B Gb Abm E
Bb         I-V-vi-IV      Bb F Gm Eb
bb         I-V-vi-IV      Bb F Gm Eb
B♭         I-V-vi-IV      unknown root 'B♭' — try C, D, Eb, F#, etc.
Cb         I-V-vi-IV      B Gb Abm E
E#         I-V-vi-IV      unknown root 'E#' — try C, D, Eb, F#, etc.
F major    I-V-vi-IV      F C Dm A#
D minor    I-V-vi-IV      D A Bm G
D minor    andalusian     Dm C A# A
Dm         andalusian     Dm C A# A
C          andalusian     Cm A# G# G
C7b9       andalusian     Cm Bb Ab G
Cmaj7      ii-V-I         Dm7 G7 Cmaj7
```

- **Una b minúscula pasa B mayor a bemoles.** El parser lee "b" como B, y luego `PrefersFlats` encuentra en ella una `b`: `B Gb Abm E`. "c" y "bb" salen bien.
- **Un cifrado se acepta como fundamental, y su cualidad se descarta.** "D minor" y "Dm" se leen como D, así que I-V-vi-IV en "D minor" recibe los acordes de D mayor, sin ninguna advertencia. `PrefersFlats` compara la cadena entera con "F", así que "F major" recibe sostenidos: `F C Dm A#`.
- **Cualquier `b` de la cadena decide la grafía.** "C7b9" se lee como C, y la `b` de su novena bemol pasa la plantilla andalusian en C menor a bemoles: `Cm Bb Ab G`, la grafía que "C" no recibe.
- **`♭` y E♯ se rechazan,** con un error que sugiere "C, D, Eb, F#, etc.".

## La longitud

`length` repite o recorta la plantilla ([líneas 148-151](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L148-L151)). En el mismo archivo, `limit` y `candidatesPerChord` están acotados ([líneas 202-203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L202-L203)); `length`, no:

```text
== The length, at the pin
length   template       chords    last chord, characters of JSON
(none)   12-bar-blues   12        V7 G7, 2288
0        12-bar-blues   12        V7 G7, 2288
-1       12-bar-blues   12        V7 G7, 2288
4        12-bar-blues   4         I7 C7, 903
13       12-bar-blues   13        I7 C7, 2461
100000   12-bar-blues   100000    I7 C7, 17300216
```

- **0 y una longitud negativa dan la longitud propia de la plantilla,** sin ninguna advertencia.
- **Una longitud de 100000 devuelve 100000 acordes, 17.300.216 caracteres de JSON,** una sola respuesta mucho mayor que la ventana de contexto de un agente.

## Enlazar la progresión

El programa sigue la nota de la herramienta para cada plantilla, en C mayor o en A menor. Le pide a `ga_voice_leading_pair` cada movimiento entre dos acordes y se queda con el primer par. Dos primeros pares empalman cuando el segundo empieza en el voicing en el que termina el primero; si no, un guitarrista tiene que saltar de un voicing del acorde a otro. El programa busca también, entre los mismos 15 candidatos de cada acorde, el camino continuo que menos mueve: un voicing por acorde, con los movimientos sumados según la propia distancia de la herramienta.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, at the pin
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          0 of 1             9                   10
circle-of-fifths   4       3          0 of 2             13                  15
rhythm-changes-a   8       7          0 of 6             35                  40
I-V-vi-IV          4       3          0 of 2             13                  15
I-vi-IV-V          4       3          1 of 2             13                  15
canon              8       7          1 of 6             33                  42
12-bar-blues       12      11         4 of 10            31                  34
minor-vamp         3       2          0 of 1             6                   8
andalusian         4       3          0 of 2             12                  16
places where two first pairs should meet 32: they meet at 6; templates whose least joined path moves as little as the sum of first pairs 0 of 9
I-V-vi-IV, the first pairs: x-x-2-0-1-x C/E → x-x-0-0-0-3 G/D, 6; x-2-0-0-x-x G/B → x-3-0-2-x-x D5/C, 3; x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 4
I-V-vi-IV, the least joined path: x-3-2-0-1-x C → x-2-0-0-x-x G/B → x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 15
```

- **En el commit fijado, los primeros pares empalman en 6 de 32 puntos, y todo camino continuo mueve más que la suma de los primeros pares.** En I-V-vi-IV, el primer par de C → G termina en `x-x-0-0-0-3`, y el primero de G → Am empieza en `x-2-0-0-x-x` y termina en `x-3-0-2-x-x`, que el índice llama D5/C.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, on main
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          1 of 1             6                   6
circle-of-fifths   4       3          2 of 2             10                  10
rhythm-changes-a   8       7          3 of 6             21                  25
I-V-vi-IV          4       3          0 of 2             9                   9
I-vi-IV-V          4       3          1 of 2             9                   9
canon              8       7          3 of 6             27                  27
12-bar-blues       12      11         7 of 10            24                  28
minor-vamp         3       2          0 of 1             7                   7
andalusian         4       3          0 of 2             14                  14
places where two first pairs should meet 32: they meet at 17; templates whose least joined path moves as little as the sum of first pairs 7 of 9
I-V-vi-IV, the first pairs: x-x-2-x-1-3 C/E → x-x-0-x-0-3 G/D, 3; x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E, 5; x-x-x-2-1-0 Am → x-x-x-2-1-1 F/A, 1
I-V-vi-IV, the least joined path: x-x-2-0-1-x C/E → x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E → x-x-3-2-1-x F, 9
```

- **En `main`, empalman en 17 de 32 puntos.** En 7 de las 9 plantillas, un camino continuo mueve exactamente tan poco como la suma de los primeros pares, pero en cinco de ellas no todos los primeros pares empalman. En I-V-vi-IV, el primer par de C → G termina en `x-x-0-x-0-3` y el siguiente empieza en `x-x-0-0-0-x`, dos voicings de G; el camino continuo también mueve 9 semitonos, sin el salto.
- **En rhythm-changes-a y 12-bar-blues, cualquier camino continuo mueve más:** 25 semitonos en lugar de 21, y 28 en lugar de 24. La herramienta responde movimiento a movimiento. Elegir un voicing por acorde exige una búsqueda sobre toda la progresión, como la que ejecuta el programa.

## El borrador de skill que la llamaría

`skills-dev/_pending-tools/progression-generator/DRAFT.md` es una skill del chatbot escrita para llamar a `ga_generate_progression` ([líneas 1-24](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L1-L24)). Como el borrador de la lección 19, describe otra herramienta:

- los argumentos `mood`, `key`, `length` con un valor por defecto de 4, `style` y `complexity` ([líneas 32-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L32-L38)), cuando la herramienta recibe `root`, `template` y `length`;
- `Chords`, `RomanNumerals`, `Style` y `Rationale` en la respuesta ([líneas 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L40-L45)), cuando la herramienta devuelve `chords`, sin estilo ni justificación;
- tonalidades escritas "D minor" y "F major" ([líneas 49-52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L49-L52)): pasada como fundamental, "D minor" se lee como D, y "F major" recibe sostenidos;
- un ejemplo de respuesta, Dm – B♭maj7 – Gm – A7 ([líneas 56-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L56-L63)), que ninguna plantilla escribe;
- una referencia cruzada a `Common/GA.Business.ML/Agents/Mcp/ProgressionMcpTools.cs` ([línea 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L77)), un archivo que GA no tiene ni en el commit fijado ni en `main`.

## Hasta dónde llega el curso

- **El manual es el del curso:** la letra de la fundamental sigue el grado del número romano, en las 15 armaduras de cada modo. La descripción de la herramienta ofrece también D♯, G♯ y A♯ como fundamentales para las plantillas mayores, tonalidades que un manual escribe E♭, A♭ y B♭; el curso no las evalúa.
- **El enlace se hace sobre el corpus de la lección 3,** solo en C mayor y en A menor, con los 15 candidatos que la herramienta usa por defecto.
- **El camino continuo es una búsqueda del curso,** con la propia distancia de la herramienta; la lección 19 mostró que esa distancia empareja las notas más graves cuando el número de notas difiere.
- **El programa llama directamente a los métodos de las herramientas,** no a través de un cliente MCP y del servidor de GA.

## Ejercicios

1. En la tabla de fundamentales, "C" escribe la plantilla andalusian en C menor con sostenidos, y "C7b9", con bemoles. ¿Qué línea del código marca la diferencia, y por qué, fuera de ese caso, ninguna fundamental leída como C se escribe con bemoles?
2. En C♯ mayor, el iii de canon se escribe Fm. ¿Qué escribe un manual, y por qué no puede escribirlo ninguno de los dos arrays de nombres?
3. En `main`, los primeros pares de I-V-vi-IV mueven 3, 5 y 1 semitonos. ¿Por qué un guitarrista no puede tocarlos seguidos, y cuánto mueve el camino continuo que encuentra el programa?
4. El borrador asocia "Jazz ii-V-I in F" con la tonalidad "F major". Pasada como fundamental de ii-V-I, ¿se nota la grafía en sostenidos? ¿Y con I-V-vi-IV?

<details>
<summary>Soluciones</summary>

1. `PrefersFlats` solo devuelve true si la fundamental contiene una `b` o es igual a F ([línea 379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L379)). El parser lee C a partir de "C", de "c" o de un cifrado sobre C, y B♯ no está en su tabla. Solo una `b` en la cualidad, como la novena bemol de "C7b9", pasa la grafía a bemoles.
2. E♯m: el iii de C♯ mayor está sobre E, elevado. El array de sostenidos da a la clase de altura 5 el nombre F, y el de bemoles también; ninguno tiene E♯.
3. El primer par de C → G termina en `x-x-0-x-0-3`, y el siguiente empieza en `x-x-0-0-0-x`: dos voicings de G, así que la mano salta de uno a otro. El camino continuo `x-x-2-0-1-x` → `x-x-0-0-0-x` → `x-x-2-2-1-x` → `x-x-3-2-1-x` mueve 9 semitonos, tanto como la suma de los primeros pares.
4. Con ii-V-I, no: los acordes caen sobre G, C y F, que los dos arrays nombran sin alteración, y la herramienta responde `Gm7 C7 Fmaj7`. Con I-V-vi-IV, sí: el IV cae sobre B♭, y la tabla muestra `F C Dm A#`. Comprobado ejecutando la herramienta del commit fijado, fuera de la salida esperada del curso.

</details>

## Puntos clave

- La grafía de una tonalidad sigue su armadura, no las letras de su nombre: buscar una `b` en el nombre deja fuera D, G y C menor.
- Un nombre por clase de altura no permite escribir las tonalidades con E♯, B♯, C♭ o F♭.
- Dos fuentes que coinciden no son una comprobación: la tabla de GA comparte el B que la herramienta escribe en lugar de C♭.
- Un parámetro sin límite puede devolver una respuesta que ningún agente puede leer.
- Una respuesta par a par no puede planificar una secuencia: el mejor par de cada movimiento no forma un camino.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/CompositionTools.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.Config/ChordProgressions.yaml`, `skills-dev/_pending-tools/progression-generator/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): la misma herramienta, el mismo parser, la misma tabla y el mismo borrador, y la búsqueda de la lección 16.
- Los programas del curso: `code/ga-ai/GaAi/Lesson20.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ProgressionProbe.cs`.
