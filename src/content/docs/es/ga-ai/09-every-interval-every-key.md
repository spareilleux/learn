---
title: "Lección 9: Cada intervalo, cada tonalidad"
description: "Las tres skills de Guitar Alchemist que deletrean notas sin modelo, IntervalSkill, ScaleInfoSkill y RelativeKeySkill, interrogadas sobre todos los intervalos que pueden formar dos nombres de nota y sobre todas las tonalidades, y calificadas con la aritmética de letras de un manual. El sostenido de la segunda nota se pierde, así que de E a G# sale una tercera menor; un unísono rebajado es un unísono justo; la relativa menor de B mayor depende de qué skill responda; y ocho de los trece prompts de ejemplo de IntervalSkill son preguntas que no sabe leer."
sidebar:
  label: 9. Cada intervalo, cada tonalidad
  order: 9
---

Las lecciones 5 y 7 encontraron cifrados de acorde que el chatbot lee mal. Un nombre de acorde puede ser ambiguo; una pregunta de ortografía musical, no. "What is the interval from E to G#?" (¿qué intervalo hay de E a G#?) tiene una sola respuesta, una tercera mayor, y un manual la calcula a partir de las letras: E, F, G son tres letras, así que es una tercera; cuatro semitonos, así que es mayor. El chatbot de GA tiene tres skills que responden a esas preguntas sin modelo: [`IntervalSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs), [`ScaleInfoSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs) y [`RelativeKeySkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs). Esta lección les pregunta todos los intervalos que pueden formar dos nombres de nota y todas las tonalidades, y califica cada respuesta.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso. En el `main` de GA, en [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), `IntervalSkill.cs`, `IntervalNaming.cs`, `KeyNaming.cs` y el `NoteExtensions.cs` del dominio siguen sin cambios; `ScaleInfoSkill` y `RelativeKeySkill` solo han cambiado en `CanHandle` y en un indicador `Declined` en el rechazo que da `RelativeKeySkill` cuando no coincide ninguna de sus expresiones, por el que no pasa ninguna de las respuestas que siguen. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l9
```

## El manual

El oráculo del curso ocupa unas veinte líneas de [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson9.cs). El número de un intervalo cuenta letras, desde la letra de la primera nota hasta la de la segunda; su cualidad compara sus semitonos con los del intervalo mayor o justo de ese número:

```csharp
static (string Short, string Long, int Semitones) Interval(string a, string b)
{
    var steps = (Letters.IndexOf(b[0]) - Letters.IndexOf(a[0]) + 7) % 7;
    var semitones = ((Pitch(b) - Pitch(a)) % 12 + 12) % 12;
    var offset = ((semitones - MajorSteps[steps] + 6) % 12 + 12) % 12 - 6;
    var perfect = steps is 0 or 3 or 4;
    var quality = (perfect, offset) switch
    {
        (true, 0) => "P",
        (false, 0) => "M",
        (false, -1) => "m",
        (_, > 0) => new string('A', offset),
        (true, < 0) => new string('d', -offset),
        _ => new string('d', -offset - 1),
    };
    // Counted from the major or perfect interval of that number: C to Cb is a semitone down
    return ($"{quality}{steps + 1}", $"{QualityName(quality)} {Sizes[steps]}", MajorSteps[steps] + offset);
}
```

La escala de una tonalidad se deletrea de la misma manera: siete letras desde la tónica, cada una con la alteración que la pone a la distancia correcta. La relativa menor de una tonalidad mayor empieza en su sexta nota, y la relativa mayor de una tonalidad menor, en su tercera; la armadura cuenta las alteraciones de la escala. Los 21 nombres de nota son las siete letras con un bemol, sin alteración o con un sostenido; las 30 tonalidades son las quince de cada modo que tienen como mucho siete sostenidos o bemoles.

## 441 preguntas

Cada pregunta es "What is the interval from X to Y?", enviada a la intención `skill.interval`, como la lección 8 enviaba sus prompts. La respuesta de GA nombra las dos notas que ha leído, lo que permite distinguir una nota mal leída de un intervalo mal calculado:

```text
== IntervalSkill, "What is the interval from X to Y?" for the 21 x 21 note names
. right   # a note read as another   a right interval, quality abbreviated   x wrong interval

from\to Cb C  C# Db D  D# Eb E  E# Fb F  F# Gb G  G# Ab A  A# Bb B  B#
Cb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  x  # 
C       x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
C#      x  x  #  .  .  #  .  .  #  a  .  #  a  .  #  .  .  #  .  .  # 
Db      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D       .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D#      a  .  #  x  x  #  .  .  #  a  .  #  a  .  #  a  .  #  .  .  # 
Eb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E       .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E#      a  .  #  a  .  #  x  x  #  x  .  #  a  .  #  a  .  #  a  .  # 
Fb      .  .  #  .  .  #  .  x  #  .  .  #  .  .  #  .  .  #  .  a  # 
F       .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  # 
F#      a  .  #  .  .  #  .  .  #  x  x  #  .  .  #  .  .  #  .  .  # 
Gb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
G       .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  # 
G#      a  .  #  a  .  #  .  .  #  a  .  #  x  x  #  .  .  #  .  .  # 
Ab      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
A       .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  # 
A#      a  .  #  a  .  #  a  .  #  a  .  #  a  .  #  x  x  #  .  .  # 
Bb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
B       .  .  #  .  .  #  .  .  #  a  .  #  .  .  #  .  .  #  x  .  # 
B#      x  .  #  a  .  #  a  .  #  x  a  #  a  .  #  a  .  #  x  x  # 

441 questions: 241 right, 147 with a note read as another, 27 right with the quality abbreviated, 26 wrong
```

Las columnas `#` son todas las preguntas cuya segunda nota lleva un sostenido: 7 sostenidos por 21 primeras notas, 147 preguntas, todas respondidas para la nota natural. La expresión ([líneas 62-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L62-L64)) termina en `\b`:

```csharp
    private static readonly Regex IntervalPattern = new(
        @"\b([A-Ga-g][#b]?)\s*(?:to|and)\s+([A-Ga-g][#b]?)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`\b` es un límite entre un carácter de palabra y un carácter que no lo es, o entre un carácter de palabra y el principio o el final del texto. Tras `G#` viene un signo de interrogación, un espacio o el final del texto, y `#` tampoco es un carácter de palabra, así que ahí no hay límite; el motor devuelve el `#` opcional y encuentra `G`, seguido del límite entre `G` y `#`. Un bemol sobrevive, porque `b` es una letra, y la primera nota también, porque no la sigue ningún `\b`. Es el mismo `\b` final que hacía que `ImprovisationSkill` leyera `F#` como `F` en la [lección 7](../07-chord-names/), la issue de GA [#757](https://github.com/GuitarAlchemist/ga/issues/757), en la expresión de otra skill.

Escritas de otras maneras, a las mismas preguntas no les va mejor:

```text
== The same question, written another way
What is the interval between E and G#?
  | From **E** to **G** is a **minor third** (m3, 3 semitones).
What is the interval from C to F♯?
  | From **C** to **F** is a **perfect fourth** (P4, 5 semitones).
What is the interval from B♭ to D?
  | Could not parse two note names from your question.
```

E y G# forman la tercera de un acorde de E mayor. El `♯` de `F♯` no está en la clase de caracteres de la expresión, así que esta se detiene antes de él y lee F; `B♭` ni siquiera se lee.

## Dónde se equivoca el dominio

Hay 27 respuestas correctas con la cualidad abreviada: `IntervalNaming.QualityLongName` ([líneas 56-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/IntervalNaming.cs#L56-L64)) nombra cinco cualidades, así que una cuarta doblemente aumentada se imprime "AA fourth". Las otras 26 son erróneas con las dos notas bien leídas:

```text
== The note names read right, the interval wrong
Cb to B   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
C  to Cb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
C# to Cb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
C# to C   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D  to Db  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D# to Db  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
D# to D   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E  to Eb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Eb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
E# to E   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Fb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
Fb to E   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
F  to Fb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
F# to Fb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
F# to F   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G  to Gb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G# to Gb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
G# to G   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A  to Ab  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A# to Ab  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
A# to A   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B  to Bb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B# to Cb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
B# to Fb  GA perfect fifth (P5, 7)            textbook triply diminished fifth (ddd5, 4)
B# to Bb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
B# to B   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
```

De ellas, 21 son un unísono rebajado, con la segunda nota sobre la misma letra y menos sostenidos o más bemoles: "C# to C" da un unísono justo de 0 semitonos. El dominio calcula los semitonos módulo 12 ([`NoteExtensions.cs` línea 110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L110)), así que de C# a C hay 11, y `DetermineQuality` resta el 0 del unísono ([líneas 13-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L13-L56)). Una diferencia de 11 no tiene rama, y la rama por defecto devuelve justo; el switch de las segundas, terceras, sextas y séptimas tiene ramas de -3 a 2 y devuelve mayor por defecto:

```csharp
            return difference switch
            {
                -2 => IntervalQuality.DoublyDiminished,
                -1 => IntervalQuality.Diminished,
                0 => IntervalQuality.Perfect,
                1 => IntervalQuality.Augmented,
                2 => IntervalQuality.DoublyAugmented,
                _ => IntervalQuality.Perfect
            };
```

Las otras cinco pasan por la misma rama por defecto: de Cb a B hay doce semitonos, 0 módulo 12, y sale una séptima mayor. Necesitan un Cb, Fb, E# o B#, que un guitarrista rara vez escribe; los unísonos, no. El `main` de GA tiene otro `Note.cs`, así que estas respuestas se comprobaron allí una vez, fuera del programa del curso: `GA.Domain.Core`, con los `GA.Core` y `GA.Business.Config` a los que hace referencia, e `IntervalNaming.cs`, tomados de `main` con `git archive` y ejecutados sobre los 441 pares con las notas bien leídas. Los 21 unísonos y las otras cinco salen igual, y lo mismo pasa con C a B#, una séptima aumentada que llama mayor; en la skill fijada, su sostenido se pierde antes.

## Tonalidades

Para cada una de las 30 tonalidades, el programa pide a `ScaleInfoSkill` sus notas, que da junto con la tonalidad relativa, y pide a `RelativeKeySkill` la tonalidad relativa y la armadura. Solo se imprimen las tonalidades en las que algo difiere:

```text
== ScaleInfoSkill and RelativeKeySkill on the 30 keys with at most seven sharps or flats
key         notes  relative key: ScaleInfoSkill  RelativeKeySkill  textbook      signature
Cb major    right  Ab minor                        Ab minor          Ab minor      not read as a key
B major     right  Ab minor                        G# minor          G# minor      5 sharps
F# major    right  Eb minor                        D# minor          D# minor      6 sharps
C# major    right  Bb minor                        A# minor          A# minor      7 sharps
G# minor    right  Cb major                        B major           B major       5 sharps
D# minor    right  Gb major                        F# major          F# major      6 sharps
A# minor    right  Db major                        C# major          C# major      7 sharps

30 keys: notes right 30, relative key right: ScaleInfoSkill 24, RelativeKeySkill 30; signature right 29
How many flats in Cb major?
  | I couldn't identify 'Cb' as a key. Try a single pitch letter optionally followed by # or b (e.g. C, G, F#, Bb).
```

Las notas de las 30 escalas son correctas. La tonalidad relativa no lo es, en seis tonalidades y para una de las dos skills: `ScaleInfoSkill` dice que la relativa menor de B mayor es A♭ menor, y `RelativeKeySkill`, que es G♯ menor. `ScaleInfoSkill` toma el nombre de `KeyNaming.RelativeKeyName` ([líneas 55-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyNaming.cs#L55-L65)), que elige la primera tonalidad del otro modo con las mismas clases de altura; G♯ menor y A♭ menor tienen las mismas clases de altura, y A♭ menor va primero. Las seis tonalidades son las tonalidades con sostenidos que tienen una gemela con bemoles. `RelativeKeySkill` se corrigió exactamente por esto en mayo: su comentario ([líneas 119-125](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L119-L125)) dice que la búsqueda antigua "always returned flat-side spellings" (siempre devolvía grafías del lado de los bemoles) y que "F# major incorrectly returned "Ebm"" (F# mayor devolvía por error "Ebm"). La corrección entró en una skill; la función auxiliar a la que llama la otra se quedó con el método antiguo. "What notes are in B major?" y "What is the relative minor of B major?" reciben dos respuestas distintas del mismo chatbot.

`RelativeKeySkill` lee C♭ mayor cuando se le pide su relativa menor, que busca en su círculo de quintas ([líneas 84-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L84-L91)), y no cuando se le pide su armadura, que parte de una tabla de fundamentales sin C♭ ([líneas 72-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L72-L81)). El rechazo pide entonces justo lo que el usuario ha escrito: "a single pitch letter optionally followed by # or b" (una sola letra de nota, seguida opcionalmente de # o b).

Por encima de siete sostenidos o bemoles, las tonalidades son teóricas. `ScaleInfoSkill` dice que no las reconoce, y `RelativeKeySkill` responde:

```text
== Keys past seven sharps or flats that RelativeKeySkill reads
What notes are in G# major?
  | I don't recognise "G# major" as a standard key. Try a key like C major, F# minor, or Bb major.
How many sharps in D# major?  textbook 9 sharps, usually written Eb major
  | **D# major** has no sharps or flats.
How many sharps in G# major?  textbook 8 sharps, usually written Ab major
  | **G# major** has no sharps or flats.
How many sharps in A# major?  textbook 10 sharps, usually written Bb major
  | **A# major** has no sharps or flats.
How many sharps in Db minor?  textbook 8 flats, usually written C# minor
  | **Db minor** has no sharps or flats.
How many sharps in Gb minor?  textbook 9 flats, usually written F# minor
  | **Gb minor** has no sharps or flats.
What is the parallel minor of G# major?  textbook: G# minor has 5 sharps
  | Same root note (**G#**) but different scales — the parallel minor lowers the 3rd, 6th, and 7th degrees. G# major has no sharps or flats; G# minor has 3 flats (three positions counter-clockwise on the circle of fifths).
```

La tabla de fundamentales contiene los diecisiete nombres de nota habituales; el círculo de quintas, quince tonalidades de cada modo, sin D♯, G♯ ni A♯ mayor ni D♭ ni G♭ menor. Para una tonalidad que está en la primera y no en el segundo, `MajorSharpsFlats` y `MinorSharpsFlats` devuelven 0 ([líneas 208-212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L208-L212)), que se imprime como "no sharps or flats". Para la homónima menor, la skill resta tres a ese 0, y G♯ menor, una tonalidad con cinco sostenidos, pasa a tener tres bemoles.

## Los ejemplos de las propias skills

Una intención enumera prompts de ejemplo, y el enrutador de intenciones envía una pregunta a la intención a cuyos ejemplos más se parece ([`IIntent.cs` líneas 29-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/IIntent.cs#L29-L32)). La intención que envuelve una skill pasa la pregunta tal cual al `ExecuteAsync` de la skill ([`OrchestratorSkillIntent.cs` línea 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). Así que cada skill debería responder al menos a sus propios ejemplos:

```text
== Each skill's example prompts, which the intent router matches questions against, sent to that skill
skill.interval: 5 of 13 answered
  What's a perfect fifth?                  | Could not parse two note names from your question.
  What is a major sixth?                   | Could not parse two note names from your question.
  Define a minor third                     | Could not parse two note names from your question.
  Minor third up from D                    | Could not parse two note names from your question.
  Perfect fourth above C                   | Could not parse two note names from your question.
  Major sixth above G                      | Could not parse two note names from your question.
  augmented fourth definition              | Could not parse two note names from your question.
  semitones in a major sixth               | Could not parse two note names from your question.
skill.scaleinfo: 21 of 24 answered
  What's the formula for harmonic minor    | Could not parse a key name from your question.
  Formula for melodic minor scale          | Could not parse a key name from your question.
  what notes are in the B flat major scale | Could not parse a key name from your question.
skill.relativekey: 12 of 12 answered
```

Ocho de los ejemplos de `IntervalSkill`, cinco definiciones y tres preguntas como "Minor third up from D" (una tercera menor por encima de D), nombran como mucho una nota, y su expresión necesita dos, unidas por "to" o "and". El comentario que los precede ([líneas 34-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L34-L44)) dice que se añadieron para arrebatar estas preguntas a `CircleOfFifthsSkill` y a `ScaleInfoSkill`: el enrutamiento se corrigió, y la respuesta a la que lleva es "Could not parse two note names from your question." (no he podido leer dos nombres de nota en tu pregunta). Lo que sirve el chatbot completo para ellas necesita el modelo de embeddings, que el curso no ejecuta (*por verificar*). El respaldo de chat directo está desactivado por defecto y depende de la confianza del enrutador, no de la de la skill ([`IFallbackChatHandler.cs` línea 66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Abstractions/IFallbackChatHandler.cs#L66), [`FallbackChatApplicationService.cs` líneas 142-158](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs#L142-L158)). En `main`, `IntentResult` ha ganado un indicador `Declined` para una consulta "that does not have the input shape this intent handles" (que no tiene la forma de entrada que maneja esta intención), que permite al orquestador probar la vía siguiente; `IntervalSkill` no lo activa.

`ScaleInfoSkill` falla con dos preguntas sobre fórmulas, que no nombran ninguna tonalidad, y con "B flat" escrito con palabras, porque su expresión quiere la alteración como símbolo, junto a la letra.

## Hasta dónde llega el curso

- **Una formulación por tipo de pregunta**, más las tres variantes de la pregunta de intervalo. Otras formulaciones pueden leerse de otra manera.
- **Sin dobles sostenidos ni dobles bemoles en las preguntas.** Los 21 nombres tienen como mucho una alteración; el manual maneja dos, para las tonalidades teóricas.
- **No se prueba el enrutamiento.** Las preguntas van directamente a las intenciones; qué intención elige el enrutador para ellas, y qué sirve el chatbot cuando la skill no sabe leerlas, necesita el modelo.
- **Las tonalidades teóricas pueden rechazarse.** Un chatbot que dice que no conoce G♯ mayor es honesto; el hallazgo es el recuento erróneo, no el rechazo.
- **El dominio de `main` se comprobó una vez**, a mano, no con el programa del curso.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: el sostenido que se pierde, los `♯` y `♭` que no se reconocen, las cualidades abreviadas y los prompts de ejemplo de `IntervalSkill`, en la issue de GA [#767](https://github.com/GuitarAlchemist/ga/issues/767); los unísonos rebajados y la rama por defecto, en la [#768](https://github.com/GuitarAlchemist/ga/issues/768); las tonalidades relativas de `ScaleInfoSkill`, las armaduras de `RelativeKeySkill` por encima de siete alteraciones y su rechazo de C♭, en la [#769](https://github.com/GuitarAlchemist/ga/issues/769). Los tres prompts de ejemplo que `ScaleInfoSkill` no sabe responder no se han comunicado. Están listados en el [diario](../journal/).

## Ejercicios

1. Reescribe `IntervalPattern` para que "E and G#" lea `G#` y "B♭ to D" lea `B♭`, sin cambiar lo que lee en "distance from F# to D" o en "interval from Bb to Eb". ¿Qué más tiene que cambiar para que `B♭` reciba respuesta?
2. `DetermineQuality` recibe una diferencia entre 0 y 11 menos los semitonos esperados. ¿Cómo la llevarías al rango que cubren sus ramas, y en qué se convierte C# a C? ¿Cuáles de las 26 respuestas erróneas seguirían llegando a la rama por defecto?
3. Reescribe `KeyNaming.RelativeKeyName` para que dé G♯ menor para B mayor y B mayor para G♯ menor, y siga dando A♭ menor para C♭ mayor.
4. Predice la respuesta de `IntervalSkill` a "What is the interval between C and F sharp?" y la de `ScaleInfoSkill` a "what notes are in the B flat major scale". ¿Cuál de las dos es peor para un usuario, y por qué?

<details>
<summary>Soluciones</summary>

1. `\b([A-Ga-g][#b♯♭]?)\s*(?:to|and)\s+([A-Ga-g][#b♯♭]?)(?![\w#♯♭])`: la clase de las alteraciones gana `♯` y `♭`, y el `\b` final se convierte en una búsqueda hacia delante que solo prohíbe otra letra, cifra o alteración detrás de la nota, así que ya no necesita un carácter de palabra antes. Comprobado con el motor de expresiones regulares de .NET sobre las preguntas del ejercicio y de esta lección: `E|G#`, `C|F♯`, `B♭|D`, `F#|D`, `Bb|Eb`. Después, las notas van a `IntervalNaming.TryParseNote`, que las pasa a los parsers del dominio; sustituir antes `♯` y `♭` por `#` y `b`, como hace `RelativeKeySkill.NormalizeKey` ([línea 226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L226)), hace que la skill no dependa de si esos parsers los aceptan. No se ha compilado contra GA (*por verificar*).
2. Llévala a un rango centrado: `((difference + 6) % 12 + 12) % 12 - 6` da un valor de -6 a 5. C# a C da 11 - 0 = 11, que se reduce a -1: un unísono disminuido, un semitono hacia abajo. Los 21 unísonos, las dos séptimas (-11 pasa a ser 1, aumentada) y las dos segundas (9 pasa a ser -3, doblemente disminuida) tienen entonces una rama; B# a Fb, 4 - 7 = -3 para una quinta, es triplemente disminuida, y el switch de los intervalos justos se detiene en doblemente, así que sigue llegando a la rama por defecto. Los semitonos que imprime la skill salen del intervalo que el dominio construye a partir de la cualidad y el número, así que también hay que comprobar qué imprime para un unísono disminuido (*por verificar*). Resuelto a mano a partir del código.
3. Empareja por la armadura en lugar de por las clases de altura: la tonalidad relativa es la tonalidad del otro modo con el mismo número de alteraciones del mismo tipo, `Key.Items.First(k => k.KeyMode != key.KeyMode && k.KeySignature.AccidentalCount == key.KeySignature.AccidentalCount && k.KeySignature.AccidentalKind == key.KeySignature.AccidentalKind)`. B mayor tiene cinco sostenidos, como G♯ menor y a diferencia de los siete bemoles de A♭ menor; C♭ mayor tiene siete bemoles, como A♭ menor. C mayor y A menor no tienen alteraciones, y su tipo tiene que compararse como igual para que coincidan. No se ha compilado contra GA (*por verificar*).
4. `IntervalSkill` lee "C and F" y responde "From **C** to **F** is a **perfect fourth** (P4, 5 semitones)": la palabra "sharp" queda fuera de la expresión, y la respuesta nombra F, algo que un lector atento podría notar. `ScaleInfoSkill` responde "Could not parse a key name from your question." La primera es peor: un rechazo lleva al usuario a reformular, mientras que una respuesta errónea sobre otra nota se da por buena. Comprobado con el programa del curso el 2026-09-29, haciendo las dos preguntas en una sola ejecución.

</details>

## Puntos clave

- Una pregunta de ortografía tiene una sola respuesta correcta, y la aritmética de letras de un manual la calcula: el número de un intervalo cuenta letras; su cualidad, semitonos. Eso permite probar cualquier skill de este tipo con todas sus entradas, aquí 441 intervalos y 30 tonalidades.
- Una expresión regular que termina en `\b` detrás de un `#` opcional pierde el `#` siempre que lo sigue un espacio, un signo de puntuación o el final del texto. GA tiene este defecto en las expresiones de al menos dos skills; de E a G# sale una tercera menor.
- Un switch con una rama por defecto esconde los valores que nadie esperaba: los semitonos tomados módulo 12 dan diferencias que las ramas no cubren, y la rama por defecto dice "perfect".
- Una corrección aplicada a una sola de dos rutas de código deja al chatbot contradiciéndose: la relativa menor de B mayor es G♯ menor o A♭ menor según qué skill elija el enrutador.
- Los prompts de ejemplo de una skill son una prueba que puede ejecutar sobre sí misma. `IntervalSkill` falla ocho de sus trece.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs`, `ScaleInfoSkill.cs`, `RelativeKeySkill.cs`, `Common/GA.Business.ML/Agents/IntervalNaming.cs`, `KeyNaming.cs`, `Common/GA.Business.ML/Agents/Intents/IIntent.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs`, `Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs`.
- El `main` de GA en [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), con commit del 2026-09-30 en UTC: `OrchestratorSkillIntent.cs` e `IIntent.cs`, por el indicador `Declined`; `GA.Domain.Core`, para la comprobación puntual de los intervalos.
- *Open Music Theory*, los capítulos de fundamentos sobre intervalos y armaduras, para las definiciones del manual: el número del intervalo por las letras, la cualidad por los semitonos, las tonalidades relativas que comparten armadura.
