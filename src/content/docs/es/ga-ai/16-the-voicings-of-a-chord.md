---
title: "Lección 16: Los voicings de un acorde"
description: "El chatbot de Guitar Alchemist responde sin modelo, a partir del índice OPTIC-K, cuando se le piden los voicings de un acorde. El curso toca cada diagrama que devuelve, en el commit fijado y con la cadena de los voicings del main de GA, que cambió después del commit fijado. En main, cada voicing toca el acorde que leyó la skill. Lo demás lo deciden la lectura y los nombres: minor y todas las cualidades en palabras se leen como una tríada mayor, CanHandle rechaza un acorde mayor sin sufijo, C-7 se lee como C7, los acordes de sexta, ocho tríadas aumentadas y seis sus4 de una cuadrícula de 144 acordes no reciben ningún voicing propio porque el índice les da otro nombre, y de los 48 voicings devueltos para una técnica, cinco son de esa técnica."
sidebar:
  label: 16. Los voicings de un acorde
  order: 16
---

La [lección 15](../15-the-notes-of-a-chord/) le preguntó al chatbot qué notas forman un acorde. Esta lección le hace la pregunta que un guitarrista se plantea justo después: dónde poner los dedos. El enrutador envía "voicings for Cmaj7" a la intención `skill.chordvoicings`, que ejecuta `ChordVoicingsSkill` ([`GaPlugin.cs` línea 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L108)); un comentario de GA la presenta como la skill más usada del chatbot ([`ChordVoicingsSkill.cs` línea 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L14)). No llama a ningún modelo. `TypedMusicalQueryExtractor` lee en la pregunta un acorde, un modo y palabras de técnica, `MusicalQueryEncoder` los convierte en un vector de consulta, y el índice OPTIC-K de la [lección 3](../03-index-and-search/) devuelve los voicings más cercanos, filtrados por el nombre del acorde ([líneas 75-167](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L75-L167)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. Casi toda la cadena de los voicings cambió en el `main` de GA después del commit fijado: entre el commit fijado y [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `git diff --stat` lista 17 archivos modificados entre la skill, `VoicingAgent`, `Search/`, `Embeddings/`, `VoicingDocumentFactory`, los servicios de dominio de los voicings y la CLI que escribe el índice. El código que lee la pregunta no cambió: `TypedMusicalQueryExtractor.cs` es idéntico, y también lo son `ChordPitchClasses`, el `CanHandle` de la skill y sus dos expresiones. Así que el programa hace la lectura en el commit fijado y pide las respuestas dos veces: en el commit fijado y en un segundo programa, `GaMain`, compilado a partir de un segundo clon de GA en `f4f5b4a`. Los dos compilan las mismas preguntas, de `code/ga-ai/Shared/ChordVoicingsProbe.cs`. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l16
dotnet run --project code/ga-ai/GaMain -c Release -- l16
```

## Qué prompts llegan a la skill

En `main`, cuando el enrutador no puede calcular el embedding de una pregunta, recurre al `CanHandle` de cada skill ([`SemanticIntentRouter.cs` línea 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` línea 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). `ChordVoicingsSkill.CanHandle` pide una palabra de voicing y un acorde ([líneas 57-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L57-L73)):

```csharp
    public bool CanHandle(string message)
    {
        if (string.IsNullOrWhiteSpace(message)) return false;
        var q = message.ToLowerInvariant();
        // Whole-word match so a keyword embedded in an unrelated word doesn't
        // fire (e.g. "shell" inside "PowerShell" — see ga#261).
        var hasVoicingIntent = VoicingKeywords.Any(k => ChordIntentMatching.ContainsWord(q, k));
        if (!hasVoicingIntent) return false;
        // Require a real chord token. The two regexes are case-sensitive on the
        // root so bare lowercase "a"/"e" in normal English ("show me a shape")
        // won't trigger. Strict form requires an accidental/quality/digit
        // immediately after the root (Cmaj7, G7, F#m); spaced form allows
        // "[A-G] major/minor/dim/aug/sus" with whitespace between root and
        // quality (Bb major, C minor).
        return ChordSuffixRegex().IsMatch(message)
               || ChordWithSpacedQualityRegex().IsMatch(message);
    }
```

Un acorde es una fundamental en mayúscula seguida de un sufijo, o de una palabra de cualidad tras un espacio ([líneas 178-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L178-L185)):

```csharp
    [GeneratedRegex(@"\b[A-G][#b]?(?:maj|min|m|M|dim|aug|sus|add|alt|°|Δ|11|13|5|6|7|9)\w*\b")]
    private static partial Regex ChordSuffixRegex();

    // Spaced quality form: "C major", "Bb minor", "F# augmented". Quality word
    // accepts upper- and lower-case first letters but requires the root to be
    // an uppercase chord letter.
    [GeneratedRegex(@"\b[A-G][#b]?\s+(?:[Mm]ajor|[Mm]inor|[Mm]aj|[Mm]in|[Dd]im|[Aa]ug|[Ss]us)\b")]
    private static partial Regex ChordWithSpacedQualityRegex();
```

El programa arranca el host del chatbot como en la lección 15, toma la skill que hay detrás de la intención y le pasa a `CanHandle` cada uno de sus 12 prompts de ejemplo ([líneas 31-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L31-L45)); luego le pregunta al extractor del host qué lee en ellos:

```text
== The skill's example prompts: CanHandle, and the chord TypedMusicalQueryExtractor reads
prompt                           CanHandle  chord read             also read
voicings for Cmaj7               yes        Cmaj7: C E G B         tags for
show me Dm7 voicings             yes        Dm7: C D F A
shapes for F major               yes        F: C F A               mode major, tags for
fingerings for G7                yes        G7: D F G B            tags for
Cmaj9 voicings                   yes        Cmaj9: C D E G B
drop2 voicings of Cmaj7          yes        Cmaj7: C E G B         tags drop2
shell voicing for Dm7            yes        Dm7: C D F A           tags shell for
rootless A7 voicings             yes        A7: C# E G A           tags rootless
quartal voicings in C            no         C: C E G               tags quartal
all C major voicings on guitar   yes        C: C E G               mode major, tags all, instrument guitar
open chord shape for E minor     yes        E: E G# B              mode minor, tags open for
barre voicings for Bb major      yes        Bb: D F A#             mode major, tags for
```

```text
== Other phrasings
prompt                           CanHandle  chord read             also read
voicings for C                   no         C: C E G               tags for
G chord shapes                   no         G: D G B
how do I play a D chord          no         D: D F# A
voicings for A minor             yes        A: C# E A              mode minor, tags for
voicings for Am                  yes        Am: C E A              tags for
voicings for am                  no         no chord               tags for
Bb voicings please               no         Bb: D F A#
voicings for F#m7b5              yes        F#m7b5: C E F# A       tags for
voicings for C7(b9)              yes        C7(b9): C C# E G A#    tags for
voicings for C/G                 no         C/G: C E G             tags for
```

- **`CanHandle` rechaza uno de sus propios ejemplos, y todos los acordes mayores sin sufijo.** "quartal voicings in C" tiene una palabra de voicing, pero una fundamental sola no es un acorde para ninguna de las dos expresiones. "voicings for C", "G chord shapes" y "Bb voicings please" se rechazan de la misma manera, y también "voicings for C/G": `/` no es un sufijo. "how do I play a D chord" no tiene ninguna palabra de voicing.
- **"minor" se lee como un modo, y el acorde como una tríada mayor.** El extractor toma como acorde la primera palabra en mayúscula que `ChordPitchClasses` sabe analizar ([`TypedMusicalQueryExtractor.cs` líneas 90-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L90-L102)); "A" se analiza como A mayor, y "minor" está en la lista de modos ([líneas 104-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L104-L111)). "voicings for A minor" se lee como A mayor, y el ejemplo "open chord shape for E minor", como E mayor. El comentario de `CanHandle` da "C minor" como una forma que acepta.
- **Una lectura parcial deja fuera al modelo.** El extractor del host solo consulta a un modelo cuando la lectura tipada no encuentra nada ([líneas 217-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L217-L226)). En "voicings for am" no se lee ningún acorde, y en producción la pregunta le llegaría a un modelo, que el curso no ejecuta. "voicings for A minor" se lee como A mayor, así que ningún modelo llega a verla.

## Los cifrados y las cualidades en palabras

`ChordPitchClasses` construye el acorde a partir de su sufijo en lugar de buscarlo en una tabla. Unifica las variantes del sufijo, extrae sus alteraciones, notas añadidas y omisiones, luego su tríada y sus extensiones, y rechaza un sufijo que deje algo que no sabe explicar ([`MusicalQueryEncoder.cs` líneas 240-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L240-L336)):

```csharp
        // ── normalize symbol variants (case matters: 'M7' = major7, 'm' = minor) ──
        w = Regex.Replace(w, "△|Δ", "maj");
        w = Regex.Replace(w, "ø|Ø", "m7b5");
        w = Regex.Replace(w, @"M(?=7|9|11|13|6)", "maj");        // M7 / M9 / M13 → major-7th family
        w = w.Replace("Maj", "maj").Replace("MAJ", "maj").Replace("Major", "maj").Replace("major", "maj");
        w = w.Replace("Min", "min").Replace("MIN", "min").Replace("minor", "min");
        w = w.Replace("M", "maj");                                // any lone uppercase M ⇒ major
        // The major-7th marker is now canonical, so folding to lower case leaves a residual
        // 'm' meaning unambiguously minor.
        w = w.ToLowerInvariant();
        w = w.Replace("°", "dim").Replace("o7", "dim7");
```

```csharp
        // residue check: anything left (besides separators) means it was not a chord symbol.
        var residue = Regex.Replace(w, @"[\s/()+\-]", "");
        if (residue.Length > 0) return false;
```

El programa pregunta por los 51 cifrados de la lección 15 con "voicings for C…" y por las 31 cualidades en palabras con "voicings for C …", y compara el acorde que lee el extractor con el de un manual:

```text
== The 51 symbols of lesson 15, asked as "voicings for C…"
read as a textbook spells them: 47 of 51
  Cdom7: no chord, a textbook's C E G A#
  Cma7: no chord, a textbook's C E G B
  C-7: C-7: C E G A#, a textbook's C D# G A#
  C7+5: no chord, a textbook's C E G# A#
symbols ChordPitchClasses and ChordVocabulary read as different chords: 5: Cdom7 Cma7 CΔ7 C-7 C7+5
```

```text
== The 31 spelled-out qualities, asked as "voicings for C …"
CanHandle accepts 13 of 31; read as a textbook spells them: 1
  read as C: C E G: 31, major, minor, diminished, augmented, power, dominant, …
```

- **47 de los 51 cifrados se leen tal como los escribe un manual.** `dom7`, `ma7` y `7+5` dejan letras o un dígito que el parser no sabe explicar, y en la pregunta no se lee ningún acorde. `C-7` se lee como C7: la comprobación del residuo toma `-` por un separador, así que el signo de menor se pierde y la séptima pasa a ser de dominante.
- **El chatbot tiene dos lectores de cifrados, y discrepan en cinco de los 51.** `ChordVocabulary`, que usa `ChordInfoSkill` (lección 15), asigna a `dom7` una séptima de dominante, a `ma7` una séptima mayor, a `-7` una séptima menor y a `7+5` una séptima de dominante con la quinta aumentada ([`ChordVocabulary.cs` líneas 81-87](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L87)); `ChordPitchClasses` no lee ningún acorde en tres de ellos y lee una séptima de dominante en `-7`. El quinto, `CΔ7`, es el `δ7` del vocabulario de la lección 15.
- **Todas las cualidades en palabras se leen como C mayor.** El parser solo lee "C", y las palabras que siguen se convierten en un modo, en etiquetas o en nada. Solo "major" sale bien. `CanHandle` acepta 13 de las 31, las que empiezan por "major" o "minor": en su expresión con espacio, `dim` y `aug` tienen que cerrar la palabra, y en "diminished" y "augmented" la palabra sigue.

## Qué tocan las respuestas, en el commit fijado

La respuesta de la skill da cada voicing con un nombre y un diagrama. El programa toca el diagrama: cada cuerda que suena da su nota al aire más su traste, y las clases de altura del voicing son el conjunto de esas notas. Las compara con el acorde que pide el prompt, tal como lo escribe un manual: **exact** cuando el voicing toca esas notas y ninguna otra, **more** cuando las toca junto con otras, **part** cuando solo toca algunas, **other** en cualquier otro caso. En el commit fijado, el diagrama es la cadena de GA, con la cuerda 1, la E aguda, primero (diferencia 13 de la entrada del 2026-09-14 del [diario](../journal/), corregida en `main`):

```text
== The example prompts' answers, at the pin: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               2          2      0      0      0
show me Dm7 voicings             1          0      0      0      1
shapes for F major               8          8      0      0      0
fingerings for G7                8          1      0      7      0
Cmaj9 voicings                   8          0      0      8      0
drop2 voicings of Cmaj7          2          2      0      0      0
shell voicing for Dm7            1          0      0      0      1
rootless A7 voicings             5          0      0      5      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          2      0      3      3
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          6      0      2      0
```

```text
== "show me Dm7 voicings": the answer, and what each voicing plays (asked: C D F A)
Found 1 voicing:
name             diagram          score    plays
Bm7(shell)/D     x-0-2-0-x-x      0.342    D A B            other
```

- **En el commit fijado, Dm7 recibe un solo voicing, y no es Dm7.** `Bm7(shell)/D` toca D, A y B. En el commit fijado, el filtro de nombres buscaba la cualidad como subcadena del nombre almacenado y tomaba la nota más grave como fundamental ([`OptickSearchStrategy.cs` líneas 315-324](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L315-L324)): `m7` está en `Bm7(shell)/D`, y su nota más grave es D. Es la diferencia 11 del diario, corregida en `main`.

Luego el programa pide 144 acordes, 12 cualidades sobre 12 fundamentales, con "voicings for <chord>". El corpus de la lección 3, el generador de voicings de GA en los tres primeros trastes, contiene todos los acordes de la cuadrícula; el programa lo comprueba y se detiene si falta alguno:

```text
== A grid of 144 chords, at the pin: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    2      9      1      other 20, part 15
m        1      9      2      other 20, part 8
7        0      5      7      other 7, part 38
maj7     1      8      3      more 2, other 9, part 26
m7       0      6      6      other 12, part 26
dim      3      8      1      more 11, other 10, part 1
aug      8      4      0      more 1, other 2, part 1
sus4     2      5      5      more 2, other 12, part 34
m7b5     0      6      6      other 5, part 32
dim7     6      1      5      other 1, part 46
6        0      2      10     more 1, other 1, part 84
9        1      1      10     other 7, part 70
voicings returned: 841; exact 337, more 17, part 381, other 106
```

- **En el commit fijado, 337 de 841 voicings tocan el acorde pedido, y para 56 de los 144 acordes no lo toca ninguno.** La mayoría de los demás tocan una parte del acorde (381), como los voicings shell de G7 sin quinta.

## Las mismas preguntas en main

`GaMain` construye el corpus y el índice de la lección 3 con el generador, el análisis, el embedding y el escritor de `main`, y construye la skill como lo hace el host ([`ServiceCollectionExtensions.cs` líneas 78-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs#L78-L111), sin cambios en `main`). En `main`, la skill escribe sus diagramas en el orden de los diagramas de acordes, empezando por la E grave ([`ChordVoicingsSkill.cs` línea 136](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)):

```text
== Corpus on main: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
the names main's analysis gives the voicings of five chords, with their counts:
  C6, C E G A            Am7/G 24, Am7/E 17, Am7 6, Am7/C 2
  C6/9, C D E G A        C6/E 11, C6/G 11, C6 1, C6/A 1
  Dsus4, D G A           Gsus2 24, Gsus2/A 13, Gsus2/D 2
  Dbaug, Db F A          Faug 14, Faug/A 7
  Caug, C E G#           Caug/E 14, Caug 6, Caug/Ab 1
```

```text
== The example prompts' answers, on main: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               8          8      0      0      0
show me Dm7 voicings             8          8      0      0      0
shapes for F major               8          8      0      0      0
fingerings for G7                8          8      0      0      0
Cmaj9 voicings                   8          8      0      0      0
drop2 voicings of Cmaj7          8          8      0      0      0
shell voicing for Dm7            8          8      0      0      0
rootless A7 voicings             8          8      0      0      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          8      0      0      0
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          8      0      0      0
```

```text
== A grid of 144 chords, on main: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    10     2      0      more 4
m        10     2      0      more 3
7        12     0      0
maj7     10     2      0      more 2
m7       10     2      0      part 2
dim      10     2      0      more 6
aug      4      0      8      more 61
sus4     3      3      6      more 57, part 1
m7b5     11     1      0      more 1
dim7     12     0      0
6        0      0      12     more 74
9        8      4      0      more 7
voicings returned: 1097; exact 879, more 215, part 3, other 0
```

- **En `main`, cada voicing que devuelve la skill toca el acorde que ha leído.** 10 de los 12 ejemplos reciben 8 voicings de su acorde; los otros dos reciben el acorde mal leído, E mayor para "E minor" y C mayor para "quartal voicings in C". En la cuadrícula, 879 de 1.097 voicings tocan exactamente el acorde, ninguno toca otro acorde (other 0), y el resto toca el acorde y algo más (215) o una parte de él (3).
- **Los acordes de sexta, ocho tríadas aumentadas y seis sus4 no reciben ningún voicing propio, aunque el corpus los contiene todos.** El índice llama "Am7" a C E G A, nunca "C6", y llama "C6" al 6/9 C D E G A: "voicings for C6" recibe voicings de 6/9 con el nombre C6. Llama "Gsus2" a D G A y "Faug" a D♭ F A. El filtro de nombres compara la fundamental y la cualidad del nombre almacenado con las de la petición ([`OptickSearchStrategy.cs` líneas 307-319](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L307-L319)), y corta el nombre almacenado en su primer paréntesis ([líneas 348-349](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L348-L349)), así que `Dbaug(maj7)/C`, D♭ F A más C, pasa como D♭ aumentado. Cuando ningún nombre almacenado pasa el filtro, la skill vuelve a buscar sin él ([líneas 109-115](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L109-L115)), y los voicings más cercanos a Dsus4 son D7sus4.

```csharp
        var filterChord = filters.ChordName is { Length: > 0 } cn ? ParseChordName(cn) : null;

        foreach (var r in pool)
        {
            var d = r.Document;
            if (filterChord is { } fc)
            {
                if (ParseChordName(d.ChordName) is not { } docChord) continue;
                if (docChord.RootPitchClass != fc.RootPitchClass) continue;
                if (!string.Equals(docChord.Quality, fc.Quality, StringComparison.Ordinal)) continue;
                if (fc.BassPitchClass is int bass
                    && (d.MidiNotes.Length == 0 || ((d.MidiNotes.Min() % 12) + 12) % 12 != bass)) continue;
            }
```

## Las técnicas

Seis de los 12 prompts de ejemplo nombran una técnica, y la descripción de la skill las promete: "drop2, shell, rootless, quartal, barre" ([líneas 24-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L24-L29)). El programa comprueba cada voicing de las respuestas de `main` con las definiciones del curso, todas leídas en el diagrama:

- **drop2**: cuatro notas en cuatro cuerdas, las cuatro notas del acorde, y al subir una octava la más grave se obtiene una posición cerrada en la que es la segunda nota empezando por arriba;
- **shell**: la fundamental, la tercera y la séptima, nada más;
- **rootless**: al menos tres notas del acorde, sin la fundamental;
- **quartal**: al menos tres notas apiladas en cuartas justas desde la fundamental; "quartal voicings in C" se toma como C F B♭;
- **open**: el acorde con al menos una cuerda al aire;
- **barre**: el acorde sin ninguna cuerda al aire, y con el mismo traste en la más grave y la más aguda de las cuerdas que suenan.

La tabla cuenta los voicings que tocan el acorde, los que son de la técnica y los voicings del corpus que son de la técnica:

```text
== The techniques the example prompts name, on main
prompt                           voicings   chord    technique  in the corpus
drop2 voicings of Cmaj7          8          8        2          3
shell voicing for Dm7            8          8        0          19
rootless A7 voicings             8          8        0          45
quartal voicings in C            8          0        0          1
open chord shape for E minor     8          0        0          60
barre voicings for Bb major      8          8        3          11
```

```text
== "open chord shape for E minor": the answer, and what each voicing plays (asked: E G B)
Found 8 voicings:
name             diagram          score    plays
E/B              x-2-x-1-x-0      0.635    E G# B           other
E                0-x-x-1-0-x      0.635    E G# B           other
E                0-2-x-1-x-x      0.635    E G# B           other
E                0-2-x-1-x-0      0.635    E G# B           other
E                0-2-x-1-0-0      0.635    E G# B           other
E/Ab             x-x-x-1-0-0      0.632    E G# B           other
E                x-x-2-1-0-x      0.632    E G# B           other
E                x-x-2-1-0-0      0.632    E G# B           other
```

- **5 de los 48 voicings son de la técnica pedida,** 2 drop2 y 3 voicings con cejilla; ninguno es un shell, un A7 sin fundamental, un voicing por cuartas ni un E menor abierto, aunque el corpus contiene 19, 45, 1 y 60, respectivamente.
- **GA descarta las técnicas a propósito, y se lo dice a su telemetría, no al guitarrista.** Su registro de decisión ADR-0002 explica que el índice solo guarda el diagrama, el nombre inferido, el instrumento y las notas MIDI, así que la vía del índice respeta el nombre del acorde, el rango de alturas, el instrumento y los filtros de comodidad, y declara descartados los demás, entre ellos `Tags` y `ModeName` ([`OptickSearchStrategy.cs` líneas 101-130](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L101-L130), [`0002-voicing-filter-parity-cpu-gpu-only.md`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md)). `VoicingAgent` escribe los filtros descartados en su log de telemetría ([`VoicingAgent.cs` líneas 110-126](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/VoicingAgent.cs#L110-L126)); `ChordVoicingsSkill` no registra nada, y su respuesta empieza con "Found 8 voicings:".
- **Las seis técnicas se pueden leer en el diagrama y la afinación,** como hace aquí el curso. ADR-0002 aplica los filtros de comodidad en la vía del índice precisamente por eso: todas las estrategias llevan el diagrama.

## Hasta dónde llega el curso

- **El corpus es el de la lección 3,** 15.360 voicings en tres trastes, no el índice de producción. Entre más voicings, los más cercanos podrían ser otros (*por verificar*).
- **No se ejecutan ni el enrutador ni el modelo.** Saber qué intención elige el enrutador para estos prompts, y qué lee un modelo en "voicings for am", necesita los embeddings y el modelo (*por verificar*).
- **Las definiciones de las técnicas son las del curso,** y también la lectura de "quartal voicings in C".
- **`GaMain` construye la skill como lo hace el host, sin el host.** El cableado del host no ha cambiado en `main`; que construya los mismos objetos se deduce de su lectura.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: en la issue de GA [#785](https://github.com/GuitarAlchemist/ga/issues/785), "minor" y las cualidades en palabras leídas como una tríada mayor, los acordes sin sufijo que rechaza `CanHandle` y los cuatro cifrados que `ChordPitchClasses` lee mal; en la [#784](https://github.com/GuitarAlchemist/ga/issues/784), los nombres del índice que el filtro no encuentra y las técnicas descartadas sin que la respuesta diga nada. Todos están listados en el [diario](../journal/).

## Ejercicios

1. Pregúntale a la skill de `main` "voicings for Am" y luego "voicings for A minor". ¿Qué acorde tocan los voicings de cada respuesta?
2. ¿Cuántos de los 144 prompts de la cuadrícula acepta `CanHandle`, y cuáles rechaza?
3. ¿Qué responde `CanHandle` a "voicings for C-7"? ¿Qué respondería la skill de `main` si el enrutador le enviara la pregunta de todos modos?
4. En `main`, ¿para qué cuatro de las 12 fundamentales recibe "voicings for <root>aug" solo tríadas aumentadas? ¿Por qué cuatro?

<details>
<summary>Soluciones</summary>

1. "voicings for Am" recibe ocho voicings de A menor, A C E; "voicings for A minor" recibe ocho voicings de A mayor, A C♯ E. El primero se lee como el cifrado `Am`; el segundo, como el acorde `A` y el modo `minor`, que el índice descarta. Comprobado ejecutando la skill de `GaMain`, fuera de la salida esperada del curso.
2. 132: rechaza los 12 acordes mayores sin sufijo, de "voicings for C" a "voicings for B", cuya fundamental no lleva ni sufijo ni palabra de cualidad. Comprobado ejecutando `CanHandle` sobre los 144 prompts, fuera de la salida esperada del curso.
3. La rechaza: después de la fundamental, `-` no coincide con ninguna de las dos expresiones. Si se le pregunta directamente, la skill de `main` lee C7 y responde con ocho voicings de C E G B♭. Comprobado ejecutando la skill de `GaMain`, fuera de la salida esperada del curso.
4. C, D, F y G. Una tríada aumentada divide la octava en tres terceras mayores, así que las mismas tres notas tienen tres nombres, y el índice guarda uno de ellos: Caug para C E G♯, Daug para D F♯ A♯, Faug para D♭ F A y Gaug para E♭ G B. El filtro solo acepta el nombre almacenado. Las otras ocho fundamentales reciben tríadas aumentadas con séptima mayor, cuyo nombre el filtro corta en el paréntesis. Comprobado ejecutando la skill de `GaMain`, fuera de la salida esperada del curso.

</details>

## Puntos clave

- Un voicing se puede comprobar sin manual: el diagrama y la afinación dan sus notas.
- En `main`, cada voicing que devuelve la skill toca el acorde que ha leído; lo que sigue fallando está en la lectura y en los nombres.
- Una lectura parcial deja fuera el respaldo: el lector tipado toma "A" de "A minor", y el modelo nunca ve la pregunta.
- Un filtro por nombres necesita un solo nombre por acorde: C6 y Am7, Dsus4 y Gsus2, y cada tríada aumentada son un mismo conjunto de notas con varios nombres.
- Un filtro descartado debería llegar a la respuesta, no solo a la telemetría.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs` (`ChordPitchClasses`), `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): la misma skill y el mismo extractor, `Common/GA.Business.ML/Search/OptickSearchStrategy.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson16.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ChordVoicingsProbe.cs`, `code/ga-ai/fetch-ga.sh`.
