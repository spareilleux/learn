---
title: "Lección 13: Lo que responde el análisis de progresiones"
description: "El chatbot de Guitar Alchemist no tiene ninguna skill que analice una progresión de acordes: el borrador espera una herramienta, pero la closure del DSL que necesitaría ya responde a través de ga_dsl_eval. El curso le hace los cuatro ejemplos del borrador y ocho progresiones de manual en las 30 tonalidades, en el commit fijado y en main. El commit fijado solo lee las fundamentales y da otra tonalidad a todas las progresiones en menor; main encuentra todas las tonalidades, pero no escribe ningún número romano para el vii° de una tonalidad menor, nombra seis tonalidades por su grafía enarmónica y deja que los acordes prestados desplacen la tonalidad."
sidebar:
  label: 13. Lo que responde el análisis de progresiones
  order: 13
---

La [lección 12](../12-what-the-progression-skills-answer/) se detuvo donde el chatbot no tiene skill: el análisis de una progresión, con su tonalidad y sus números romanos. El borrador de esa skill lo llama "the single most-requested prompt class" (la clase de prompt más pedida) del chatbot público ([`DRAFT.md` línea 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L30)) y espera una herramienta `ga_analyze_progression` "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" (todavía sin implementar en esa carpeta) ([línea 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)); la carpeta no contiene ese archivo, ni en el commit fijado ni en `main`. El cálculo ya existe. La closure `domain.analyzeProgression` del DSL infiere la tonalidad de una progresión y etiqueta cada acorde con un número romano. La llama la herramienta `GaAnalyzeProgression` de GaMcpServer ([`GaDslTool.cs` líneas 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), y también dos herramientas del mismo servidor que necesitan antes una tonalidad, `GaProgressionCompletion` y `GaArpeggioSuggestions` ([`GuitaristProblemTools.cs` líneas 271-273](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L271-L273) y [434-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L434-L436)), además de la línea de comandos de GA ([`Program.fs` línea 320](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaCli/Program.fs#L320)). Esta lección le pregunta lo que el borrador espera de la herramienta.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En `main`, la closure se reescribió dos veces después del commit fijado: la [#625](https://github.com/GuitarAlchemist/ga/pull/625) toma la tonalidad de `KeyIdentificationService`, el servicio de la lección 11, y [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) toma del acorde si cada número romano va en mayúsculas o en minúsculas. `DomainClosures.fs` no ha cambiado desde entonces, hasta `main` en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30). El curso lo descarga en `6baf32e` y lo compila sin cambios en un proyecto propio, `GaDslMain`, contra el DSL fijado y contra el servicio de `main`, que la lección 11 compiló en `GaKeysMain`. El parser de acordes de `main` difiere del fijado, pero solo en símbolos que esta lección no usa: `M` y `Maj7`, `o`, `sus`, `omit` y `no`, y el texto que queda detrás del símbolo. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l13
```

## Lo que se le muestra al modelo

Las herramientas del DSL del chatbot solo exponen las closures de la categoría Domain ([`DslEvalMcpTools.cs` línea 70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L70)). El programa les pregunta a `ga_dsl_list_closures` y a `ga_dsl_get_closure_schema` lo que les preguntaría un modelo:

```text
== What ga_dsl_list_closures and ga_dsl_get_closure_schema show the model
15 closures listed, among them domain.analyzeProgression (Domain): Infer the key of a progression and label each chord with a Roman numeral.
input  chords: string — space-separated chord symbols
output string (formatted key + Roman numeral analysis)
```

Un modelo puede llamar a la closure a través de `ga_dsl_eval`, igual que las tres skills de la [lección 10](../10-what-the-model-is-told-to-trust/) llaman a las suyas. Ningún SKILL.md le dice que lo haga. La respuesta ocupa tres líneas: la tonalidad con una confianza, los cifrados y los números romanos. Las dos herramientas de GaMcpServer la cortan por líneas y por espacios para sacar la tonalidad y los números romanos ([`GuitaristProblemTools.cs` líneas 276-293](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L276-L293)).

## Cómo encuentra la tonalidad el commit fijado

En el commit fijado, la closure puntúa cada una de las 24 tonalidades mayores y menores ([`DomainClosures.fs` líneas 268-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L268-L276) y [308-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L308-L316)):

```fsharp
let private scoreKey rootPc (offsets: int[]) (chordPcs: int list) =
    let diatonic = offsets |> Array.map (fun o -> (rootPc + o) % 12) |> Set.ofArray
    chordPcs |> List.filter diatonic.Contains |> List.length

let private romanFor rootPc (offsets: int[]) (romans: string[]) chordPc =
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i -> romans.[i])
    |> Option.defaultValue "?"
```

```fsharp
                      // Score every major and minor key.
                      // Tiebreaker: prefer the key whose root matches the first chord.
                      let firstPc = validPcs |> List.tryHead |> Option.defaultValue 0
                      let keyRootPc, scaleName =
                          [ for rpc in 0..11 do
                              yield rpc, "major", scoreKey rpc majorOffsets validPcs
                              yield rpc, "minor", scoreKey rpc minorOffsets validPcs ]
                          |> List.maxBy (fun (rpc, _, s) -> s * 2 + (if rpc = firstPc then 1 else 0))
                          |> fun (rpc, scale, _) -> rpc, scale
```

`scoreKey` cuenta los acordes cuya fundamental está en la escala de la tonalidad: la cualidad del acorde no se lee nunca. La tonalidad cuya tónica es la fundamental del primer acorde recibe un punto más; entre puntuaciones iguales, `List.maxBy` se queda con la primera, y la lista da la tonalidad mayor de cada fundamental antes que la menor. Después, `romanFor` da el número romano del grado según la tabla de la tonalidad, sea cual sea el acorde ([líneas 257-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L257-L260)): en C mayor, D y Dm son los dos `ii`. El nombre de la tonalidad sale de la clase de altura de su tónica, con el nombre con bemol para las clases de altura 1, 3, 8 y 10, y en los demás casos una nota natural o F♯ ([líneas 262-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L262-L266)), la escriba como la escriba la pregunta.

## Los cuatro ejemplos del borrador

El borrador da cuatro preguntas con la respuesta que debería devolver la herramienta ([`DRAFT.md` líneas 51-54](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L51-L54)):

```text
== The four examples of skills-dev/_pending-tools/progression-analysis/DRAFT.md
"C Am F G": the draft expects C major, I vi IV V
  a826864  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
  6baf32e  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
"Dm7 G7 Cmaj7": the draft expects C major, ii V I
  a826864  Key: D minor  (confidence 3/3)
           Dm7    G7     Cmaj7
           i      iv     VII
  6baf32e  Key: C major  (confidence 3/3)
           Dm7    G7     Cmaj7
           ii     V      I
"D A Bm G": the draft expects D major, I V vi IV
  a826864  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
  6baf32e  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
"Fm Bbm C7 Fm": the draft expects F minor, i iv V i
  a826864  Key: F major  (confidence 4/4)
           Fm     Bbm    C7     Fm
           I      IV     V      I
  6baf32e  Key: F minor  (confidence 4/4)
           Fm     Bbm    C7     Fm
           i      iv     V      i
```

En el commit fijado, dos de las cuatro son correctas. Dm7 G7 Cmaj7, el ii–V–I del jazz, sale en D menor, `i iv VII`: D, G y C están los tres en D menor, y D es el primer acorde. Fm Bbm C7 Fm sale en F mayor, `I IV V I`: F, B♭ y C están en F mayor y en F menor, y el empate lo gana la tonalidad mayor. En `main`, las cuatro coinciden con el borrador. El cuarto ejemplo pasa `assumeKey="F minor"`, una entrada que la closure no tiene; `main` encuentra F menor sin ella.

## Ocho progresiones de manual en treinta tonalidades

El programa escribe cada progresión en las 15 tonalidades mayores o en las 15 menores, con la grafía del manual; la sensible de vii°7 es el séptimo grado elevado, C♯ en D menor y F𝄪, escrito `F##`, en G♯ menor. Compara la tonalidad y los números romanos con los del manual, sin las cifras que los acompañan: ii7 V7 Imaj7 se lee ii V I, y iiø7 V7 i se lee iiø V i.

```text
== Eight textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I IV V I      6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
IV V I        a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
IV V I        6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
I vi IV V     a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I vi IV V     6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
ii7 V7 Imaj7  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
ii7 V7 Imaj7  6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv V i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv v i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv v i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
iiø7 V7 i     a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
iiø7 V7 i     6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv vii°7 i  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv vii°7 i  6baf32e  n  n  n  n  n  n  n  n  n  n  n  n  n  n  n

= the textbook key, spelled as the question, and the textbook numerals; e the same key under its
enharmonic name, the textbook numerals; n the key, other numerals; x another key
a826864: 120 questions, = 24, e 6, n 0, x 90; confidence below the chord count: none
6baf32e: 120 questions, = 84, e 21, n 15, x 0; confidence below the chord count: iiø7 V7 i in 15 keys, i iv vii°7 i in 12 keys
```

- **`x`, el commit fijado, 90 de 120.** IV V I recibe la tonalidad de IV, donde los tres acordes son I ii V, y ii7 V7 Imaj7, la tonalidad menor de ii. Ninguna progresión en menor recibe su tonalidad: i iv V i, i iv v i y i iv vii°7 i reciben la tonalidad mayor homónima, cuya escala contiene las mismas fundamentales, y iiø7 V7 i, la tonalidad menor de ii, que la abre. En `main`, donde la tonalidad viene de `KeyIdentificationService`, la cuadrícula no tiene ninguna `x`.
- **`e`, la tonalidad con su nombre enarmónico.** En el commit fijado, C♭, G♭ y C♯ mayor vuelven como B, F♯ y D♭ mayor, por la tabla de clases de altura; las demás filas tienen ahí una `x`. En `main`, el nombre es el de la tonalidad que `Identify` pone primero, y las tonalidades con las mismas clases de altura se ordenan por nombre ([`KeyIdentificationService.cs` líneas 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)): C♭, G♭ y D♭ mayor se convierten en B, F♯ y C♯ mayor, y E♭, B♭ y G♯ menor en D♯, A♯ y A♭ menor. Son seis de las 30 tonalidades, en todas las filas salvo la última, donde ya difieren los números romanos. La causa es la de la [#772](https://github.com/GuitarAlchemist/ga/issues/772), que ya apareció en la lección 11.
- **`n`, `main`, i iv vii°7 i en las 15 tonalidades menores.** La tonalidad es correcta; los números romanos son `i iv ? i`.
- **La confianza.** En el commit fijado, cuenta fundamentales y es completa en las 120 preguntas. En `main`, queda por debajo del número de acordes en iiø7 V7 i en las 15 tonalidades menores y en i iv vii°7 i en 12. La sección siguiente explica por qué.

```text
Bb major, IV V I: "Eb F Bb"
  a826864  Key: Eb major (3/3), I ii V
  6baf32e  Key: Bb major (3/3), IV V I
Gb major, ii7 V7 Imaj7: "Abm7 Db7 Gbmaj7"
  a826864  Key: Ab minor (3/3), i iv VII
  6baf32e  Key: F# major (3/3), ii V I
G# minor, i iv v i: "G#m C#m D#m G#m"
  a826864  Key: Ab major (4/4), I IV V I
  6baf32e  Key: Ab minor (4/4), i iv v i
D minor, i iv vii°7 i: "Dm Gm C#dim7 Dm"
  a826864  Key: D major (4/4), I IV vii° I
  6baf32e  Key: D minor (3/4), i iv ? i
```

## Acordes fuera de la escala natural

En `main`, `romanFor` busca la fundamental del acorde entre las siete notas de la escala natural de la tonalidad, y después toma del acorde la mayúscula o la minúscula y el signo ([`DomainClosures.fs` líneas 353-374 en `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L353-L374)):

```fsharp
/// Roman numeral of a chord in a key: the degree comes from the scale, the case and sign from the
/// chord itself, so E7 in A minor is V (harmonic minor), not the natural-minor v.
let private romanFor rootPc (offsets: int[]) (ast: ChordAst) =
    let chordPc = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
    // Bm7b5 parses as a minor quality with a flat fifth; the -7b5 spelling as one extension.
    let halfDiminished =
        ast.Components
        |> List.exists (function
            | Extension "m7b5" -> true
            | Alteration (Flat, "5") -> ast.Quality = Some Minor
            | _ -> false)
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i ->
        let digits = romanDigits.[i]
        match ast.Quality with
        | _ when halfDiminished -> digits.ToLowerInvariant() + "ø"
        | Some Minor -> digits.ToLowerInvariant()
        | Some Diminished -> digits.ToLowerInvariant() + "°"
        | Some Augmented -> digits + "+"
        | _ -> digits)
    |> Option.defaultValue "?"
```

E7 es `V` en A menor porque E es el quinto grado de A menor natural. La sensible, G♯, no está en ningún grado de esa escala, así que G♯dim7 recibe `?`. En una tonalidad mayor, tres de los acordes prestados de la menor homónima, bIII, bVI y bVII, están un semitono por debajo de un grado: E♭ por debajo de E, A♭ por debajo de A, B♭ por debajo de B. El programa hace seis preguntas que un manual lee en C mayor o en A menor:

```text
== Chords borrowed from the parallel minor, and the harmonic minor's V and vii°
"C Ab G C": the textbook reads C major, I bVI V I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     G      C
           i      VI     v      i
  6baf32e  Key: C major  (confidence 3/4)
           C      Ab     G      C
           I      ?      V      I
"C Eb F C": the textbook reads C major, I bIII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Eb     F      C
           i      III    iv     i
  6baf32e  Key: C major  (confidence 3/4)
           C      Eb     F      C
           I      ?      IV     I
"C Bb F C": the textbook reads C major, I bVII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Bb     F      C
           i      VII    iv     i
  6baf32e  Key: F major  (confidence 4/4)
           C      Bb     F      C
           V      IV     I      V
"C Ab Bb C": the textbook reads C major, I bVI bVII I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     Bb     C
           i      VI     VII    i
  6baf32e  Key: Eb major  (confidence 2/4)
           C      Ab     Bb     C
           VI     IV     V      VI
"Am G#dim7 Am": the textbook reads A minor, i vii° i
  a826864  Key: A major  (confidence 3/3)
           Am     G#dim7 Am
           I      vii°   I
  6baf32e  Key: A minor  (confidence 2/3)
           Am     G#dim7 Am
           i      ?      i
"Bm7b5 E7 Am": the textbook reads A minor, iiø V i
  a826864  Key: B minor  (confidence 3/3)
           Bm7b5  E7     Am
           i      iv     VII
  6baf32e  Key: A minor  (confidence 2/3)
           Bm7b5  E7     Am
           iiø    V      i
KeyIdentificationService.Identify on main, "C Bb F C": F major 3/3, D minor 3/3, C major 2/3
KeyIdentificationService.Identify on main, "C Ab Bb C": Eb major 2/3, F major 2/3, C minor 2/3
KeyIdentificationService.IsChordDiatonic("A minor", ...) on main: Am yes, Bdim yes, Bm7b5 no, E yes, E7 yes, G#dim7 no
KeyIdentificationService.IsChordDiatonic("G# minor", ...) on main: G#m yes, D#7 yes, F# yes, F##dim7 yes
```

- **C Ab G C y C Eb F C.** `main` encuentra C mayor y escribe `?` donde un manual escribe bVI y bIII. El commit fijado encuentra C menor, donde A♭ y E♭ son VI y III, y llama `i` al acorde de C mayor.
- **C Bb F C y C Ab Bb C.** `main` desplaza la tonalidad. `Identify` ordena por el número de acordes distintos que son diatónicos en la tonalidad, más el peso de cadencia; después pone primero la tonalidad cuya tríada de tónica abre la progresión, luego la tonalidad mayor y luego el nombre ([líneas 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). C, B♭ y F son los tres diatónicos en F mayor y en D menor, frente a dos en C mayor; ninguna de las dos tonalidades abre con su tríada de tónica, y F mayor es la mayor: el análisis es F mayor, `V IV I V`. En C Ab Bb C, E♭ mayor, F mayor y C menor cuentan dos acordes, C mayor solo C; E♭ mayor es mayor y va antes que F por el nombre: el análisis es E♭ mayor, `VI IV V VI`, aunque sobre el sexto grado de E♭ mayor está C menor, no C mayor. La confianza, 2/4, es el único indicio.
- **La confianza cuenta lo que acepta `IsChordDiatonic`** ([`DomainClosures.fs` líneas 421-424 en `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L421-L424)). Acepta el V mayor y el V7 de una tonalidad menor ([`KeyIdentificationService.cs` líneas 261-267](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L261-L267)), pero `NormalizeChord` corta un símbolo en su primera cifra ([línea 319](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L319)): Bm7b5 se convierte en Bm, una tríada menor, mientras que el ii de A menor es B disminuido. El servicio lee una fundamental con una sola alteración ([línea 132](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L132)) y llama mayor a cualquier cualidad que no conoce ([líneas 145-150](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L145-L150)). `F##dim7` es, por tanto, F♯ mayor, el VII de la menor natural en G♯ menor, y cuenta: i iv vii°7 i es completa en G♯, D♯ y A♯ menor, cuya sensible lleva doble sostenido.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Si un modelo llama a `domain.analyzeProgression` a través de `ga_dsl_eval`, y qué escribe a partir de las tres líneas, son cosas que necesitan el modelo (*por verificar*).
- **La closure de `main` se ejecuta fuera de `main`.** Se compila contra el DSL fijado y contra el servicio de `main`, compilado a su vez contra el dominio fijado, como en la lección 11. Que los símbolos de la lección se lean igual con el parser de `main` se deduce de la lectura de su diff, no de una ejecución.
- **El borrador pide más.** Las funciones, las cadencias, las modulaciones y los acordes ajenos a la tonalidad ([`DRAFT.md` líneas 44-47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L44-L47)) no están en la respuesta de la closure.
- **Ocho progresiones de manual y seis preguntas con acordes prestados**, sin inversiones, acordes con barra, dominantes secundarias ni modulaciones.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#775](https://github.com/GuitarAlchemist/ga/issues/775): los números romanos que faltan para el vii° de una tonalidad menor y para los acordes prestados de la menor homónima, la tonalidad desplazada por los acordes prestados y la confianza que cuenta un ii semidisminuido como ajeno a la tonalidad. Las tonalidades nombradas por su grafía enarmónica en `main` tienen la misma causa que la [#772](https://github.com/GuitarAlchemist/ga/issues/772). La tonalidad y los números romanos que el commit fijado leía solo a partir de las fundamentales están corregidos en `main` por la [#625](https://github.com/GuitarAlchemist/ga/pull/625) y `6baf32e`. Todos están listados en el [diario](../journal/).

## Ejercicios

1. En el commit fijado, Am Dm E Am sale en A mayor. Calcula el valor que compara `List.maxBy` para A mayor y para A menor, y explica por qué gana A mayor.
2. Amplía el `romanFor` de `main` para que, en una tonalidad mayor, una fundamental situada un semitono por debajo del tercer, sexto o séptimo grado reciba un bemol y el número romano de ese grado, y para que, en una tonalidad menor, el séptimo grado elevado reciba `vii`. ¿Qué escribe para las seis preguntas de la última sección?
3. Supón que `Identify` pusiera primero, antes del recuento, la tonalidad cuya tríada de tónica abre y cierra la progresión. ¿Qué filas de la cuadrícula cambiarían en `main`, y qué recibirían C Bb F C y C Ab Bb C?
4. El commit fijado nombra las tonalidades por clase de altura. ¿Cuáles de las 15 tonalidades menores del manual escribe de otra forma?

<details>
<summary>Soluciones</summary>

1. Las fundamentales son A, D, E y A: las cuatro están en la escala de A mayor y en la de A menor, así que las dos puntúan 4. A es la fundamental del primer acorde, así que las dos obtienen 4 × 2 + 1 = 9. `List.maxBy` se queda con el primero de los valores iguales, y la lista da A mayor antes que A menor. Resuelto a mano a partir de las líneas 308-316.
2. C Ab G C: `I bVI V I`. C Eb F C: `I bIII IV I`. Am G#dim7 Am: `i vii° i`. Bm7b5 E7 Am sigue siendo `iiø V i`. C Bb F C y C Ab Bb C no cambian, `V IV I V` en F mayor y `VI IV V VI` en E♭ mayor: la regla etiqueta los acordes, pero no elige la tonalidad. Resuelto a mano.
3. Ninguna: las filas cuya progresión abre y cierra con la misma tríada de tónica, I IV V I, i iv V i, i iv v i y i iv vii°7 i, ya reciben su tonalidad, y las demás no abren y cierran con el mismo acorde. C Bb F C y C Ab Bb C recibirían C mayor: `I ? IV I` y `I ? ? I` con el `romanFor` de `main`, `I bVII IV I` y `I bVI bVII I` con el del ejercicio 2. Resuelto a mano.
4. Cuatro: C♯ menor se escribe D♭ menor, una tonalidad de ocho bemoles; D♯ menor, E♭ menor; G♯ menor, A♭ menor, y A♯ menor, B♭ menor. La tabla da bemol a las clases de altura 1, 3, 8 y 10 sea cual sea el modo. Resuelto a mano a partir de las líneas 262-266.

</details>

## Puntos clave

- Una closure que ya existe responde antes que la skill: el borrador espera una herramienta mientras `ga_dsl_eval` ya enumera y ejecuta la closure.
- Una tonalidad leída solo a partir de las fundamentales no distingue una tonalidad de su homónima: el commit fijado daba A mayor para Am Dm E Am.
- Los ejemplos de un borrador son una prueba ya hecha: dos de cuatro fallan en el commit fijado, y los cuatro pasan en `main`.
- Una tabla de números romanos indexada por la escala natural no tiene sitio para la sensible de la menor armónica ni para los acordes prestados.
- Clasificar las tonalidades primero por recuento deja que los acordes prestados alejen la tonalidad del acorde con el que la progresión abre y cierra.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Apps/GaCli/Program.fs`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`.
- GA en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), con commit del 2026-09-25 en UTC: `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs` y `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilados por el curso. La [#625](https://github.com/GuitarAlchemist/ga/pull/625) de GA. El `main` de GA en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), con commit del 2026-09-30 en UTC, para la comparación.
- *Open Music Theory*, los capítulos sobre los números romanos, la séptima elevada de la escala menor y la mezcla modal.
