---
title: "Lección 10: En qué se le dice al modelo que confíe"
description: "Las skills Transpose, DiatonicChords y CommonTones de Guitar Alchemist le dicen a un modelo que llame a una closure determinista a través de la herramienta ga_dsl_eval y que use su respuesta. El curso llama a esa herramienta con los argumentos que prescribe cada SKILL.md y califica las closures con la aritmética de letras de un manual: D menor vuelve con un A♯, G7 transpuesto a E♭ es D♯7, y el C♯ que comparten los acordes A y C♯m vuelve como D♭."
sidebar:
  label: 10. En qué se le dice al modelo que confíe
  order: 10
---

La [lección 9](../09-every-interval-every-key/) probó las skills que deletrean notas sin modelo. Otras tres skills, [`TransposeSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs), [`DiatonicChordsSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs) y [`CommonTonesSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CommonTonesSkill.cs), pasan la pregunta a un modelo, y sus SKILL.md le dicen que no calcule la respuesta: tiene que llamar a una closure a través de la herramienta `ga_dsl_eval` y usar lo que esta devuelva. El SKILL.md de diatonic-chords da la ortografía como razón, en [su descripción](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L3): "since LLMs commonly mis-spell the iv/vii° in less-common keys" (porque los LLM suelen deletrear mal el iv/vii° en las tonalidades menos habituales). El curso no puede ejecutar el modelo, pero sí puede llamar a la herramienta que el modelo tiene que llamar, con los argumentos que prescribe el SKILL.md. Lo que responda la closure es lo que dirá un modelo que siga sus instrucciones.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA, en [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), los tres SKILL.md, las tres skills y `ga_dsl_eval` siguen sin cambios. `DomainClosures.fs` sí ha cambiado allí, pero no en el código al que llama esta lección: `transposeChord`, `diatonicChords`, los dos arrays de nombres de nota, `preferFlat`, `conventionalKeyName` y la línea en la que `commonTones` nombra una nota son idénticos, comparados función por función. El parser de acordes también ha cambiado allí: ahora rechaza cualquier resto detrás del símbolo y lee las formas `sus`, `Maj7` con mayúscula y `omit`, y los símbolos que siguen no usan ninguna de ellas. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l10
```

## Lo que se le dice al modelo

A las tres skills solo se llega a través de los embeddings del enrutador de intenciones: [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L85) devuelve `false` desde `CanHandle`. Una vez elegida, una skill pasa la pregunta a un modelo con su SKILL.md como instrucciones; cada uno de los tres SKILL.md enumera una sola herramienta en `allowed-tools`, `ga_dsl_eval`. Después, el envoltorio comprueba si el modelo ha llamado a la herramienta ([líneas 111-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L111-L144)). Si lo ha hecho, la evidencia de la respuesta recibe `grounding.source: ga.dsl@domain.diatonicChords` (o la closure que corresponda a la skill) y se conserva la confianza del modelo. Si no, la evidencia dice "answer is LLM-only, not deterministic" (la respuesta solo viene del LLM, no es determinista) y la confianza se limita a 0,5. El diseño confía más en la closure que en el modelo.

Los SKILL.md dicen lo mismo en prosa. [diatonic-chords](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L26): "Do NOT enumerate the chords mentally — the closure handles enharmonic spelling correctly" (NO enumeres los acordes de cabeza: la closure resuelve bien la ortografía enarmónica). [transpose](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L28): "Do NOT compute the transposition mentally — for less-common keys (Gb major, C# minor) the LLM will confidently flip enharmonics and produce wrong spellings" (NO calcules la transposición de cabeza: en las tonalidades menos habituales, el LLM cambiará con aplomo una nota por su enarmónica y producirá grafías erróneas). [common-tones](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/common-tones/SKILL.md#L63): "The closure returns a formatted string already. Surface it verbatim" (la closure ya devuelve una cadena con formato; muéstrala tal cual).

`ga_dsl_eval` es un método estático, [`DslEvalMcpTools.EvalClosure`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L134-L139). Recibe un nombre de closure y un mapa plano de argumentos de tipo cadena, que es lo que envía el modelo. Al arrancar, el chatbot registra las closures con `GaClosureBootstrap.init()` ([`ChatbotOrchestrationExtensions.cs` línea 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs#L42)); [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson10.cs) hace lo mismo y después llama a la herramienta:

```csharp
static DslEvalResult Eval(string closure, params (string Key, string Value)[] args) =>
    DslEvalMcpTools.EvalClosure(closure, args.ToDictionary(a => a.Key, a => a.Value));
```

El manual es la aritmética de letras de la lección 9. Las siete tríadas de una tonalidad se construyen sobre su escala, una letra por grado, con las cualidades de la escala mayor o de la menor natural. Una nota desplazada un intervalo toma la letra que indica el número del intervalo, contando letras, y la alteración que da el número correcto de semitonos.

## Siete acordes, treinta tonalidades

El SKILL.md de diatonic-chords da dos argumentos: `root`, la tónica, y `scale`, `major` o `minor`. El programa pide las 30 tonalidades que tienen como mucho siete sostenidos o bemoles e imprime las que difieren del manual:

```text
== ga_dsl_eval "domain.diatonicChords" on the 30 keys with at most seven sharps or flats
Cb major   GA       B Dbm Ebm E Gb Abm Bbdim
           textbook Cb Dbm Ebm Fb Gb Abm Bbdim
Gb major   GA       Gb Abm Bbm B Db Ebm Fdim
           textbook Gb Abm Bbm Cb Db Ebm Fdim
F# major   GA       F# G#m A#m B C# D#m Fdim
           textbook F# G#m A#m B C# D#m E#dim
C# major   GA       C# D#m Fm F# G# A#m Cdim
           textbook C# D#m E#m F# G# A#m B#dim
Ab minor   GA       Abm Bbdim B Dbm Ebm E Gb
           textbook Abm Bbdim Cb Dbm Ebm Fb Gb
Eb minor   GA       Ebm Fdim Gb Abm Bbm B Db
           textbook Ebm Fdim Gb Abm Bbm Cb Db
C minor    GA       Cm Ddim D# Fm Gm G# A#
           textbook Cm Ddim Eb Fm Gm Ab Bb
G minor    GA       Gm Adim A# Cm Dm D# F
           textbook Gm Adim Bb Cm Dm Eb F
D minor    GA       Dm Edim F Gm Am A# C
           textbook Dm Edim F Gm Am Bb C
D# minor   GA       D#m Fdim F# G#m A#m B C#
           textbook D#m E#dim F# G#m A#m B C#
A# minor   GA       A#m Cdim C# D#m Fm F# G#
           textbook A#m B#dim C# D#m E#m F# G#

30 keys: 19 right, 11 with a chord on another letter
```

Todos los acordes tienen la altura de la fundamental y la cualidad correctas; 11 tonalidades tienen al menos un acorde sobre la letra equivocada. La closure calcula la fundamental de cada acorde como una clase de altura por encima de la tónica y la nombra con uno de dos arrays de doce nombres ([líneas 22-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L22-L36)):

```fsharp
/// Chromatic note names using sharp spelling.
let private sharpNames = [| "C";"C#";"D";"D#";"E";"F";"F#";"G";"G#";"A";"A#";"B" |]

/// Chromatic note names using flat spelling.
let private flatNames  = [| "C";"Db";"D";"Eb";"E";"F";"Gb";"G";"Ab";"A";"Bb";"B" |]

/// True when the key conventionally uses flat accidentals.
/// F natural is the one exception among white-key roots (it contains Bb).
let private preferFlat (note: string) (acc: AccidentalType) =
    match acc with
    | Flat | DoubleFlat  -> true
    | Sharp | DoubleSharp -> false
    | Natural             -> note = "F"
```

`preferFlat` mira la tónica, no la tonalidad ([línea 187](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L187)). F es la única tónica de tecla blanca de una tonalidad mayor con bemoles, pero D, G y C menor también son tonalidades con bemoles sobre tónicas de tecla blanca, así que sus B♭, E♭ y A♭ salen como A♯, D♯ y G♯. Además, un array indexado por clase de altura tiene un solo nombre por clase de altura: no puede escribir C♭, F♭, E♯ ni B♯, que necesitan ocho tonalidades. El acorde del cuarto grado de G♭ mayor, C♭, sale como B; el del séptimo grado de F♯ mayor, E♯dim, sale como Fdim.

## Los ejemplos del SKILL.md

El SKILL.md le muestra al modelo lo que devuelve la closure:

```text
== The results diatonic-chords' SKILL.md gives for the closure
C major   GA       ["C","Dm","Em","F","G","Am","Bdim"]
          SKILL.md ["C", "Dm", "Em", "F", "G", "Am", "B°"]
A minor   GA       ["Am","Bdim","C","Dm","Em","F","G"]
          SKILL.md ["Am", "B°", "C", "Dm", "Em", "F", "G"]
Bb major  GA       ["Bb","Cm","Dm","Eb","F","Gm","Adim"]
          SKILL.md ["Bb","Cm","Dm","Eb","F","Gm","A°"]
Gb major  GA       ["Gb","Abm","Bbm","B","Db","Ebm","Fdim"]
          SKILL.md Gb major returns Cm, not B#m
F# minor  GA       ["F#m","G#dim","A","Bm","C#m","D","E"]
          SKILL.md F# minor returns G#°, not Ab°
```

El SKILL.md escribe la tríada disminuida `B°`, y la closure, `Bdim`. El SKILL.md le dice al modelo que use cada acorde "exactly as the closure returned it" (exactamente como lo devolvió la closure), así que esta diferencia solo cambia lo que lee el usuario. Las afirmaciones sobre tonalidades poco habituales solo aciertan a medias. G♭ mayor no tiene ningún acorde de C menor: su acorde del cuarto grado es C♭ mayor, y la closure devuelve B. El acorde del segundo grado de F♯ menor es G♯dim, que la closure sí devuelve. La descripción de la propia skill hace la misma promesa ([`DiatonicChordsSkill.cs` líneas 27-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs#L27-L32)): se llama a la closure "so enharmonic spelling is correct in less-common keys (Gb major, F# minor)" (para que la ortografía enarmónica sea correcta en las tonalidades menos habituales).

## Transponer por semitonos

El SKILL.md de transpose da dos argumentos, `symbol` y `semitones`, con una tabla que convierte nombres de intervalo en semitonos ([línea 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L42) y siguientes): "up a minor third" (una tercera menor hacia arriba) es 3. La closure suma los semitonos a la clase de altura de la fundamental y nombra el resultado con los mismos dos arrays, elegidos según la fundamental del propio acorde ([líneas 159-162](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L159-L162)):

```fsharp
                      let rootPc  = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
                      let newPc   = (rootPc + semitones % 12 + 12) % 12
                      let naming  = spellingOf (preferFlat ast.Root ast.RootAccidental)
                      let newRoot, newAcc = splitNoteAcc naming.[newPc]
```

El programa sube cada uno de los 21 nombres de nota por cada intervalo de la tabla, del unísono a la octava, salvo el tritono, al que la tabla asigna 6 semitonos se escriba como se escriba:

```text
== ga_dsl_eval "domain.transposeChord": the 21 note names up each interval of transpose's SKILL.md but the tritone
. right   ~ right pitch, another letter   d the textbook needs a double sharp or flat   x wrong pitch

note    P1 m2 M2 m3 M3 P4 P5 m6 M6 m7 M7 P8
Cb      ~  d  .  d  .  ~  .  d  .  d  .  ~ 
C       .  ~  .  ~  .  .  .  ~  .  ~  .  . 
C#      .  .  .  .  ~  .  .  .  .  .  ~  . 
Db      .  d  .  ~  .  .  .  d  .  ~  .  . 
D       .  ~  .  .  .  .  .  ~  .  .  .  . 
D#      .  .  ~  .  d  .  .  .  ~  .  d  . 
Eb      .  ~  .  .  .  .  .  ~  .  .  .  . 
E       .  .  .  .  .  .  .  .  .  .  .  . 
E#      ~  .  d  .  d  .  ~  .  d  .  d  ~ 
Fb      ~  d  .  d  .  d  ~  d  .  d  .  ~ 
F       .  .  .  .  .  .  .  .  .  .  .  . 
F#      .  .  .  .  .  .  .  .  .  .  ~  . 
Gb      .  d  .  d  .  ~  .  d  .  ~  .  . 
G       .  ~  .  ~  .  .  .  ~  .  .  .  . 
G#      .  .  .  .  ~  .  .  .  ~  .  d  . 
Ab      .  d  .  ~  .  .  .  ~  .  .  .  . 
A       .  ~  .  .  .  .  .  .  .  .  .  . 
A#      .  .  ~  .  d  .  ~  .  d  .  d  . 
Bb      .  ~  .  .  .  .  .  .  .  .  .  . 
B       .  .  .  .  .  .  .  .  .  .  .  . 
B#      ~  .  d  .  d  ~  d  .  d  .  d  ~ 

252 questions: 182 right, 40 on another letter, 30 where the textbook needs a double accidental, 0 wrong pitch
```

Ninguna altura es errónea; todos los errores son de letra. Incluso un unísono puede cambiar de letra: C♭ desplazado 0 semitonos vuelve como B, y E♯ como F, porque la closure nombra con su array la clase de altura, que no ha cambiado. El número de un intervalo cuenta letras, y un número de semitonos no. Una tercera abarca tres letras, así que una tercera menor por encima de C es E♭ (C, D, E); una segunda abarca dos, así que una segunda aumentada por encima de C es D♯ (C, D). Las dos miden 3 semitonos, y la closure responde D♯ porque C toma el array de sostenidos. La tabla del SKILL.md ha perdido el número que necesita el manual antes de que se llame a la closure. Solo E, F y B salen bien en todos los intervalos: cada intervalo por encima de E y de B cae en una nota natural o con sostenido, y cada uno por encima de F, en una natural o con bemol. Las casillas `d` son intervalos cuya respuesta de manual lleva un doble sostenido o un doble bemol (una segunda menor por encima de C♭ es D doble bemol); los arrays tampoco pueden escribirlos, y se cuentan aparte.

## Los ejemplos de la propia skill

Los prompts de ejemplo de `TransposeSkill`, convertidos como dice el SKILL.md:

```text
== Transpose's example prompts, with the arguments its SKILL.md maps them to, one call per chord
prompt                                symbol    semitones  GA           textbook
Transpose Cmaj7 up a perfect fourth   Cmaj7             5  Fmaj7        Fmaj7
Move this F chord down a minor third  F                -3  D            D
What's Dm7 up a whole step?           Dm7               2  Em7          Em7
Transpose G7 to Eb                    G7                8  D#7          Eb7
                                      G7               -4  D#7          Eb7
Shift Am7 up a fifth                  Am7               7  Em7          Em7
transpose C-Am-F-G to G major         C Am F G          7  G Em C D     G Em C D
transpose C-Am-F-G to Eb major        C Am F G          3  D# Cm Ab A#  Eb Cm Ab Bb

Bb up a whole step, then back down: C, then A#
```

"Transpose G7 to Eb" (transpón G7 a E♭) es uno de los prompts de ejemplo de la skill, y da D♯7 cuente como cuente el modelo, una sexta menor hacia arriba o una tercera mayor hacia abajo: la closure nunca ve E♭, solo un número. La progresión llevada a E♭ mayor vuelve como D♯ Cm A♭ A♯, con la tonalidad escrita de dos maneras en cuatro acordes. Para una progresión, el SKILL.md dice que se llame a la skill una vez por acorde o que se pidan los acordes ([línea 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L95)), y, si se la llama una vez por acorde, cada llamada elige su array según su propio acorde. Un B♭ subido un tono y bajado de nuevo vuelve como A♯.

## Los símbolos que vuelven a entrar

Una conversación puede pasarle a una closure la respuesta de otra closure, así que el programa comprueba que los dos símbolos de acorde disminuido se leen:

```text
== The chord symbols the closures return, passed back in
B° up a semitone             Cdim
Bdim up a semitone           Cdim
```

Los dos se leen; la diferencia entre el `B°` del SKILL.md y el `Bdim` de la closure no va más allá.

## Notas comunes

El SKILL.md de common-tones da dos argumentos, `chord1` y `chord2`. El programa pide todas las parejas de tríadas de cada una de las 30 tonalidades, 21 parejas por tonalidad, con los acordes escritos como los escribe el manual, y compara las notas compartidas con las que comparten las dos tríadas en la escala de la tonalidad:

```text
== ga_dsl_eval "domain.commonTones" on every pair of triads in each of the 30 keys
key        misspelled pairs  the key's note as GA writes it
Cb major   9 of 21           Cb as B, Fb as E, Gb as F#
Gb major   6 of 21           Cb as B, Gb as F#
Db major   3 of 21           Gb as F#
D major    3 of 21           C# as Db
A major    6 of 21           C# as Db, G# as Ab
E major    9 of 21           C# as Db, D# as Eb, G# as Ab
B major    11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
F# major   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
C# major   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab
Ab minor   9 of 21           Cb as B, Fb as E, Gb as F#
Eb minor   6 of 21           Cb as B, Gb as F#
Bb minor   3 of 21           Gb as F#
B minor    3 of 21           C# as Db
F# minor   6 of 21           C# as Db, G# as Ab
C# minor   9 of 21           C# as Db, D# as Eb, G# as Ab
G# minor   11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
D# minor   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
A# minor   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab

630 pairs: shared notes right 630, spelled as the key spells them 486
```

Las notas compartidas son correctas en las 630 parejas: la closure hace la intersección de las clases de altura. Después nombra cada una con `conventionalKeyName` ([líneas 263-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L263-L266), llamada en la [línea 523](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L523)), que no conoce ninguno de los dos acordes:

```fsharp
let private conventionalKeyName pc =
    match pc with
    | 1 | 3 | 8 | 10 -> flatNames.[pc]   // Db, Eb, Ab, Bb — prefer flat
    | _               -> sharpNames.[pc]  // everything else — prefer sharp / natural
```

C♯ es siempre D♭, y G♯ siempre A♭, mientras que G♭ es siempre F♯. Doce tonalidades no tienen ninguna pareja mal escrita, seis de cada modo: aquellas cuyas notas esta regla acierta a nombrar por casualidad. D menor es una de ellas, aunque `diatonicChords` escribe su B♭ como A♯; D mayor no lo es, aunque `diatonicChords` la escribe bien. Tres closures de un mismo archivo escriben las mismas notas con tres reglas: según la tónica, según la fundamental del acorde, según la clase de altura sola.

```text
== Common-tones' SKILL.md example, and a pair from A major
Cmaj7 and Am7
  | Common tones (3):
  |   C (P1 in Cmaj7, m3 in Am7)
  |   E (M3 in Cmaj7, P5 in Am7)
  |   G (P5 in Cmaj7, m7 in Am7)
A and C#m
  | Common tones (2):
  |   Db (M3 in A, P1 in C#m)
  |   E (P5 in A, m3 in C#m)
```

El ejemplo del SKILL.md es correcto. En A mayor, la fundamental de C♯m vuelve como "Db", y el SKILL.md le dice al modelo que la muestre tal cual.

## Donde GA ya deletrea bien

El dominio de GA deletrea bien las tonalidades. En la lección 9, `ScaleInfoSkill` dio correctamente las notas de las 30 escalas; las toma del `Key.Notes` del dominio ([`ScaleInfoSkill.cs` línea 132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs#L132)). Las closures no lo llaman; reconstruyen la ortografía a partir de clases de altura, y una clase de altura no lleva letra.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Si llama a `ga_dsl_eval`, qué argumentos envía y si vuelve a escribir la respuesta en contra de sus instrucciones son cosas que necesitan el modelo (*por verificar*). Un modelo que ignorara el SKILL.md podría deletrear mejor que la closure.
- **No se prueba el enrutamiento.** A las tres skills solo se llega a través de los embeddings del enrutador.
- **Solo tríadas.** Los acordes diatónicos son tríadas; las notas comunes se prueban con tríadas, aunque los acordes de séptima pasan por la misma forma de nombrar las notas.
- **La transposición se califica frente a intervalos con nombre**, los de la tabla, sin el tritono. Un usuario que dice "three semitones" (tres semitonos) no nombra ninguna letra, y cualquier grafía del resultado es defendible.
- **Las closures de `main` se compararon, no se ejecutaron.** Las funciones a las que llama esta lección son textualmente idénticas en el commit fijado y en `main`.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: la ortografía de `diatonicChords`, `transposeChord` y `commonTones`, y las afirmaciones del SKILL.md de diatonic-chords, en la issue de GA [#770](https://github.com/GuitarAlchemist/ga/issues/770). Están listadas en el [diario](../journal/).

## Ejercicios

1. Reescribe la forma en que `diatonicChords` nombra los acordes para que cada grado reciba su propia letra. ¿Cuáles de las 11 tonalidades salen bien, y qué devuelve para una tonalidad como G♯ mayor, cuyo séptimo grado es F doble sostenido?
2. `transposeChord` recibe un número de semitonos. ¿Qué necesitaría para escribir una tercera menor por encima de C como E♭ y una segunda aumentada por encima de C como D♯, y cómo cambiaría la tabla del SKILL.md de transpose?
3. `commonTones` nombra las notas compartidas sin conocer ninguna tonalidad. ¿Qué grafía podría usar que fuera correcta en las 630 parejas de esta lección, también sin tonalidad?
4. Un usuario pregunta "Transpose G7 to Eb". Siguiendo el SKILL.md, ¿qué envía el modelo, qué recibe, y qué dice la evidencia del chatbot sobre la respuesta?

<details>
<summary>Soluciones</summary>

1. Toma la letra del grado y la alteración de la altura: para el grado `i`, la letra es la que está `i` pasos por encima de la letra de la tónica, y la alteración es la diferencia, llevada al rango de -6 a 5, entre la clase de altura del patrón y la altura natural de esa letra, como hace `Spell` en `Lesson10.cs`. Así, las 11 tonalidades coinciden con el manual, porque el manual hace el mismo cálculo. El acorde del séptimo grado de G♯ mayor es F doble sostenido disminuido; el `accStr` de la closure ya escribe `DoubleSharp` como `##`, así que sale `F##dim`. No se ha compilado contra GA (*por verificar*).
2. El número del intervalo: con un recuento de pasos de letra junto a los semitonos, la letra del resultado está ese número de pasos por encima de la de la fundamental, y los semitonos dan la alteración. La tabla haría corresponder "minor third" a 2 pasos y 3 semitonos, y "augmented second" a 1 paso y 3 semitonos. Para "Transpose G7 to Eb", una fundamental de destino es todavía más sencilla: la closure tomaría del usuario la letra de E♭. No se ha compilado contra GA (*por verificar*).
3. La grafía de chord1: cada nota compartida se nombra como la escribe chord1, a partir de la letra de la fundamental de chord1 y del grado de la nota en el acorde (la tercera, dos pasos de letra más arriba; la quinta, cuatro). Las tríadas de una tonalidad escriben sus notas como la tonalidad, así que la grafía de chord1 es la de la tonalidad en todas las parejas de la lección, y la regla no necesita ninguna tonalidad para los acordes que no pertenecen a ninguna. Resuelto a mano a partir de las parejas de la lección.
4. `ga_dsl_eval(closureName: "domain.transposeChord", args: { "symbol": "G7", "semitones": "8" })`, o `-4`; el resultado es `D#7` en los dos casos. Siguiendo la plantilla del SKILL.md, "**Cmaj7 up a perfect fourth = Fmaj7** (interval = +5 semitones)", el modelo empezaría por **G7 up a minor sixth = D#7**. Como el modelo ha llamado a `ga_dsl_eval`, `SkillMdDrivenWrapperBase` añade `grounding.source: ga.dsl@domain.transposeChord` a la evidencia y conserva la confianza del modelo: la evidencia nombra la closure como fuente de la respuesta, igual que lo haría con una respuesta correcta. Resuelto a partir del código; la llamada real del modelo necesita el modelo (*por verificar*).

</details>

## Puntos clave

- Una skill que le dice a un modelo "llama a esta herramienta, no lo calcules tú" traslada la corrección a la herramienta. Llamar a la herramienta con los argumentos del propio SKILL.md prueba lo que dirá un modelo obediente, sin el modelo.
- Un nombre por clase de altura no puede dar una letra por grado. Un array indexado por clase de altura tiene un nombre por clase de altura, y una tonalidad necesita una letra por grado: 11 de 30 tonalidades, 70 de 252 transposiciones y 144 de 630 parejas de notas comunes salen sobre otra letra.
- Un número de semitonos pierde el número del intervalo. Una vez que "minor third" se ha convertido en 3, ya no se puede distinguir E♭ de D♯.
- Tres closures de un mismo archivo escriben las mismas notas con tres reglas, así que el B♭ de D menor es A♯ en una y B♭ en otra.
- Una etiqueta de anclaje dice de dónde viene una respuesta, no si es correcta.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.DSL/Library.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `TransposeSkill.cs`, `DiatonicChordsSkill.cs`, `CommonTonesSkill.cs`, `ScaleInfoSkill.cs`, `skills/transpose/SKILL.md`, `skills/diatonic-chords/SKILL.md`, `skills/common-tones/SKILL.md`, `Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs`.
- El `main` de GA en [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), con commit del 2026-09-30 en UTC: `DomainClosures.fs` y `ChordParser.fs`, para la comparación función por función.
- *Open Music Theory*, los capítulos de fundamentos sobre intervalos, escalas y tríadas, para las definiciones del manual: el número del intervalo por las letras, la cualidad por los semitonos, una letra por grado de la escala.
