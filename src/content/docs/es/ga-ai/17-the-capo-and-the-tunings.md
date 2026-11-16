---
title: "Lección 17: La cejilla y las afinaciones"
description: "El chatbot de Guitar Alchemist responde sin modelo a las preguntas sobre la cejilla y las afinaciones. El curso comprueba cada respuesta contra un manual. La aritmética de la cejilla es correcta, pero la skill saca el sentido de la pregunta y la tonalidad de formulaciones fijas: responde con una forma cuando se le pregunta qué suena con cejilla, lee el artículo inglés a como la tonalidad A y una tonalidad con sostenido sin major detrás como su sola letra, escribe D sostenido donde la tonalidad es E bemol y no sabe decir dónde poner la cejilla. La skill de afinaciones pierde los sostenidos de las seis notas que lee, toma la afinación estándar en E bemol escrita con sostenidos por la estándar en D y da open D cuando se le pide open D minor. El respaldo sin conexión de GA no llega a ninguna de las dos skills."
sidebar:
  label: 17. La cejilla y las afinaciones
  order: 17
---

La [lección 16](../16-the-voicings-of-a-chord/) preguntó dónde poner los dedos para tocar un acorde. Antes vienen dos preguntas: dónde va la cejilla y cómo están afinadas las cuerdas. Dos skills del chatbot las responden sin modelo; las dos se crearon el 2026-05-14 para resolver dos "dealbreakers" (obstáculos insalvables) del backlog de GA. El enrutador envía "what shape do I play in E with capo 4" (¿qué forma toco en E con la cejilla en el traste 4?) a `skill.capo`, que ejecuta `CapoSkill`, y "what is DADGAD tuning" (¿qué es la afinación DADGAD?) a `skill.alternatetunings`, que ejecuta `AlternateTuningsSkill` ([`GaPlugin.cs` líneas 83 y 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L80-L93)). La primera hace aritmética de semitonos; la segunda consulta una tabla de nueve afinaciones ([`CapoSkill.cs` líneas 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L6-L23), [`AlternateTuningsSkill.cs` líneas 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L6-L23)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. Entre el commit fijado y el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `CapoSkill` solo añade el indicador `Declined` a su rechazo, lo que no cambia sus respuestas. `AlternateTuningsSkill` cambió además las expresiones que leen el nombre de una afinación. Así que el programa pregunta a la skill de cejilla en el commit fijado, y a la de afinaciones en el commit fijado y en `GaMain`, el programa de la lección 16 compilado a partir del `main` de GA. Los dos compilan las preguntas sobre afinaciones a partir de `code/ga-ai/Shared/TuningsProbe.cs`. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l17
dotnet run --project code/ga-ai/GaMain -c Release -- l17
```

## Qué prompts llegan a las dos skills

El `CanHandle` de las dos skills devuelve `false`, con el comentario "semantic-routing only" (solo enrutamiento semántico) ([`CapoSkill.cs` línea 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L47), [`AlternateTuningsSkill.cs` línea 50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L50)), y lo sigue haciendo en `main`. En `main`, cuando el enrutador no puede calcular el embedding de una pregunta, se la da a la primera intención, en orden de registro, cuya skill la acepta en `CanHandle` ([`SemanticIntentRouter.cs` línea 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` línea 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). El programa arranca el host del chatbot como en la lección 15 y le pasa al `CanHandle` de cada skill los 22 prompts de ejemplo de las dos skills:

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                                           first skill that accepts it
What shape do I play in E with capo 4                            none
Song is in E, what chord shape with capo on 4                    none
Capo on 3, song in G, what shape                                 none
I play a C shape with capo 3 — what does it sound like           none
What does a G shape sound like with capo 2                       none
Capo on 5, song in A                                             none
If I capo on 2 and play an Em shape, what's the sounding chord   skill.chordinfo
What's the sounding key if I play in G with capo on 5            none
Capo 7, D shape — sounding chord                                 none
What chord shape for B major with capo 4                         skill.chordvoicings
what is DADGAD tuning                                            none
what's drop D tuning                                             none
how do I tune to drop C                                          none
drop C tuning notes                                              none
how do I tune to open G                                          none
open D tuning notes                                              none
what is double drop D tuning                                     none
what's half step down tuning                                     none
whole step down tuning notes                                     none
DGCGCD tuning explained                                          none
how is DADGAD different from standard                            none
what tuning is Eb Ab Db Gb Bb Eb                                 none
skill intents 32; CanHandle of skill.capo and skill.alternatetunings accepts 0 of their 22 example prompts
```

- **Sin embeddings no responde ninguna de las dos skills, aunque ninguna necesita un modelo.** El respaldo se añadió en `main` para que las skills deterministas respondan cuando el servicio de embeddings está caído. Las skills de cejilla y de afinaciones son deterministas y nunca reciben una pregunta por esa vía. Dos de los ejemplos de la skill de cejilla van a otras skills: la de información de acordes se queda con el que nombra Em, y la de voicings, con el que pide una "chord shape for B major" (forma de acorde para B mayor).

## La cejilla

Una cejilla sube cada cuerda tantos semitonos como el número de su traste. El guitarrista toca la forma, y lo que se oye es la forma más el traste. `CapoSkill` lee la pregunta con dos expresiones, una para una forma y otra para una tonalidad que suena, y prueba primero la de la forma ([líneas 52-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L52-L64), [líneas 89-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L89-L104)):

```csharp
    private static readonly Regex SoundingToShape =
        new(@"(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual>major|minor|maj|min))?\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key2>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual2>major|minor|maj|min))?\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Pattern B: "<shape> shape with capo <N>" → SOUNDING
    // Shape-side anchor: "<note> shape" or "play a <note> shape" or "<note>m shape"
    private static readonly Regex ShapeToSounding =
        new(@"\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape>[A-Ga-g][b#♭♯]?m?)\s+shape\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape2>[A-Ga-g][b#♭♯]?m?)\s+shape\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

El programa le hace a la skill sus 10 prompts de ejemplo y compara cada respuesta con lo que pide el prompt: la forma que hay que tocar o el acorde que suena.

```text
== CapoSkill's example prompts: what each asks, and the answer
prompt                                                           asks         answer         verdict
What shape do I play in E with capo 4                            shape C      shape C        right
Song is in E, what chord shape with capo on 4                    shape C      shape C        right
Capo on 3, song in G, what shape                                 shape E      shape E        right
I play a C shape with capo 3 — what does it sound like           sounds Eb    sounds D#      right, theoretical spelling
What does a G shape sound like with capo 2                       sounds A     sounds A       right
Capo on 5, song in A                                             shape E      shape E        right
If I capo on 2 and play an Em shape, what's the sounding chord   sounds F#m   sounds F#m     right
What's the sounding key if I play in G with capo on 5            sounds C     shape D        wrong direction
Capo 7, D shape — sounding chord                                 sounds A     sounds A       right
What chord shape for B major with capo 4                         shape G      declined       declined
```

```text
== Other phrasings
prompt                                                   asks           answer         verdict
song in Em, capo 2, what shape                           shape Dm       declined       declined
song in E minor, capo 2, what shape                      shape Dm       shape Dm       right
What shape do I play in e with capo 4                    shape C        shape C        right
what shape for F with capo 3                             shape D        declined       declined
capo on 3 in G, what shape                               shape E        shape E        right
Capo on 2, song in F#, what shape                        shape E        shape D#       wrong chord
song in C#, capo 4, what shape                           shape A        shape G#       wrong chord
song in B♭, capo 1, what shape                           shape A        shape A#       wrong chord
I'm in a band, capo 2, song is in G                      shape F        shape G        wrong chord
Playing in D with capo 2, what key does it sound in?     sounds E       shape C        wrong direction
I play a C7 shape with capo 3, what does it sound like   sounds Eb7     declined       declined
what does a Cmaj7 shape sound like with capo 2           sounds Dmaj7   declined       declined
capo 2, Dsus4 shape, what chord do I hear                sounds Esus4   declined       declined
```

- **El sentido de la pregunta lo decide la formulación, no lo que se pregunta.** Salvo que la pregunta nombre una forma, una tonalidad detrás de "in" se toma por la tonalidad que suena, y la skill responde con la forma que hay que tocar. Su propio ejemplo "What's the sounding key if I play in G with capo on 5" (¿en qué tonalidad suena si toco en G con la cejilla en el traste 5?) recibe la forma D en lugar de lo que suena, C, y lo mismo le pasa a "Playing in D with capo 2, what key does it sound in?" (si toco en D con la cejilla en el traste 2, ¿en qué tonalidad suena?).
- **El artículo "a" se lee como la tonalidad A.** Las dos expresiones no distinguen mayúsculas de minúsculas, así que en "I'm in a band, capo 2, song is in G" (toco en un grupo, cejilla en el 2, la canción está en G) al primer "in" le sigue "a", y la skill responde con la forma para A.
- **Una tonalidad con sostenido o bemol sin "major" ni "minor" detrás se lee como su sola letra.** La tonalidad termina en `\b`, un límite de palabra. `#`, `♯` y `♭` no son caracteres de palabra, así que detrás de ellos el límite falla, y la expresión retrocede hasta quedarse con la letra sola. "Capo on 2, song in F#" recibe la forma D♯ en lugar de E, "song in C#, capo 4", G♯ en lugar de A, y "song in B♭, capo 1", A♯ en lugar de A. `b` es una letra, así que "Bb" se lee entero. La [lección 7](../07-chord-names/) decía que esta skill y la de afinaciones aceptan `♭` y `♯`: sus expresiones prevén los dos signos, pero aquí los pierden. Con "major" o "minor" detrás de la tonalidad, el límite cae después de la palabra, y por eso la cuadrícula del curso, más abajo, se lee bien.
- **La skill rechaza lo que sus expresiones no prevén.** Una tonalidad tiene que ir detrás de "in" o de "key", así que se rechaza "What chord shape for B major with capo 4" (¿qué forma de acorde para B mayor con la cejilla en el traste 4?), uno de sus propios ejemplos. Una tonalidad menor tiene que escribirse con la palabra, así que se rechaza "song in Em". Una forma es una letra, una alteración y una `m` opcional, así que se rechazan las formas C7, Cmaj7 y Dsus4.

## La grafía de las respuestas

La skill escribe su respuesta con sostenidos, salvo que la tonalidad o la forma que ha leído lleve un bemol o, si se trata de una forma, que la pregunta diga "flat" ([líneas 178-191](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L178-L191)):

```csharp
    /// <summary>
    /// Pick the enharmonic spelling that matches the user's preferred side.
    /// If the user said "Eb major" → flats. If "F# major" → sharps.
    /// Default: sharps (guitarist convention).
    /// </summary>
    private static string SpellPc(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];

    private static bool KeyIsFlat(string keyRaw) =>
        keyRaw.IndexOf('b') >= 0 || keyRaw.IndexOf('♭') >= 0;

    private static bool ShapeIsFlat(string shapeRaw, string fullMessage) =>
        shapeRaw.IndexOf('b') >= 0 || shapeRaw.IndexOf('♭') >= 0
        || fullMessage.Contains("flat", StringComparison.OrdinalIgnoreCase);
```

El programa pregunta por las 30 tonalidades, mayores y menores, que se escriben con una armadura, con la cejilla en los trastes 1 a 11, y luego por las ocho formas abiertas con la cejilla en los mismos trastes. Marca una respuesta como **right, theoretical spelling** (correcta, grafía teórica) cuando la nota es correcta pero la tonalidad o el acorde que nombra no se escribe con ninguna armadura, como D♯ mayor:

```text
== "Song is in <key>, what shape with capo <fret>": 30 keys, frets 1 to 11
key      prompts   right   right, theoretical spelling    wrong   declined
major    165       127     27 (A# D# G#)                  0       11 (Cb)
minor    165       159     6 (Dbm Gbm)                    0       0
the answers' "an Am shape at capo N would sound as …m": 319, a wrong chord 0, a theoretical minor key 16
```

```text
== "What does a <shape> shape sound like with capo <fret>": the eight open shapes, frets 1 to 11
shape    prompts   right   wrong   declined   right, theoretical spelling
C        11        8       0       0          3, capo 3: D#, 8: G#, 10: A#
A        11        8       0       0          3, capo 1: A#, 6: D#, 11: G#
G        11        8       0       0          3, capo 1: G#, 3: A#, 8: D#
E        11        8       0       0          3, capo 4: G#, 6: A#, 11: D#
D        11        8       0       0          3, capo 1: D#, 6: G#, 8: A#
Am       11        11      0       0          0
Em       11        11      0       0          0
Dm       11        11      0       0          0
```

- **La aritmética nunca falla.** En las dos cuadrículas, ninguna respuesta da un acorde equivocado.
- **La grafía, a menudo sí.** 27 formas de la cuadrícula mayor, y 3 de las 11 respuestas para cada forma abierta mayor, son A♯, D♯ o G♯ mayor, que un manual escribe B♭, E♭ y A♭. El propio comentario de la clase dice que una forma de C con la cejilla en el traste 3 suena como E♭ ([línea 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L13)); la skill responde D♯. Una tonalidad menor escrita con bemoles da su forma en bemoles: D♭m y G♭m, que un manual escribe C♯m y F♯m.
- **Se rechaza C♭ mayor.** La tabla de fundamentales no tiene C♭ ([líneas 67-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L67-L76)), aunque su armadura tiene siete bemoles.

## Dónde poner la cejilla

La pregunta que un guitarrista se hace primero es la inversa: dónde poner la cejilla para tocar en una tonalidad con las formas abiertas C, A, G, E y D. La aritmética es la misma, hecha al revés. El programa la hace para las 12 tonalidades y lista los trastes del 0 al 7 que dan una forma abierta:

```text
== "Where should I put the capo to play in <key> with open chords?"
key   frets 0 to 7 that give an open shape: C A G E D  the skill's answer
C     0 C, 3 A, 5 G                                    declined
Db    1 C, 4 A, 6 G                                    declined
D     0 D, 2 C, 5 A, 7 G                               declined
Eb    1 D, 3 C, 6 A                                    declined
E     0 E, 2 D, 4 C, 7 A                               declined
F     1 E, 3 D, 5 C                                    declined
F#    2 E, 4 D, 6 C                                    declined
G     0 G, 3 E, 5 D, 7 C                               declined
Ab    1 G, 4 E, 6 D                                    declined
A     0 A, 2 G, 5 E, 7 D                               declined
Bb    1 A, 3 G, 6 E                                    declined
B     2 A, 4 G, 7 E                                    declined
```

- **La skill rechaza las 12.** Las dos expresiones necesitan un número de traste en la pregunta.

## Las afinaciones

`AlternateTuningsSkill` lee el nombre de una afinación con nueve expresiones, una por cada afinación de su tabla ([líneas 53-74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L53-L74)), y responde con las seis notas, empezando por la cuerda grave, y con lo que se mueve cada cuerda respecto a la afinación estándar:

```csharp
    private static readonly (Regex Pattern, string Key)[] TuningPatterns =
    [
        // DADGAD — contiguous or hyphenated
        (new Regex(@"\b(?:dadgad|d-a-d-g-a-d)\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dadgad"),
        // Drop D — but NOT "double drop D"
        (new Regex(@"(?<!\bdouble\s)(?<!\bdouble-)\bdrop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-d"),
        // Double drop D
        (new Regex(@"\bdouble[\s-]?drop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "double-drop-d"),
        // Drop C — the (?![#b]) rejects "drop C#" / "drop Cb", which are
        // different tunings not in this table (better no match than a wrong one).
        (new Regex(@"\bdrop[\s-]?c\b(?![#b])", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-c"),
        // Open G
        (new Regex(@"\bopen[\s-]?g\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-g"),
        // Open D
        (new Regex(@"\bopen[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-d"),
        // DGCGCD (Sonic Youth / Pink Floyd style)
        (new Regex(@"\bdgcgcd\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dgcgcd"),
        // Half step down
        (new Regex(@"\bhalf[\s-]?step[\s-]?down\b|\beb\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "half-step-down"),
        // Whole step down
        (new Regex(@"\bwhole[\s-]?step[\s-]?down\b|\bd\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "whole-step-down"),
    ];
```

```text
== AlternateTuningsSkill's example prompts: the tuning each one gets
prompt                                   answer                         verdict
what is DADGAD tuning                    DADGAD                         right
what's drop D tuning                     Drop D                         right
how do I tune to drop C                  Drop C                         right
drop C tuning notes                      Drop C                         right
how do I tune to open G                  Open G                         right
open D tuning notes                      Open D                         right
what is double drop D tuning             Double Drop D                  right
what's half step down tuning             Half-step down (Eb standard)   right
whole step down tuning notes             Whole-step down (D standard)   right
DGCGCD tuning explained                  DGCGCD                         right
how is DADGAD different from standard    DADGAD                         right
what tuning is Eb Ab Db Gb Bb Eb         Half-step down (Eb standard)   right
```

```text
== The nine tunings of the skill's table: notes and moves from standard, against a textbook
tuning                         notes                  moves from standard        as a textbook
DADGAD                         D A D G A D            -2st same same same -2st -2st right
Drop D                         D A D G B E            -2st same same same same same right
Double Drop D                  D A D G B D            -2st same same same same -2st right
Drop C                         C G C F A D            -4st -2st -2st -2st -2st -2st right
Open G                         D G D G B D            -2st -2st same same same -2st right
Open D                         D A D F# A D           -2st same same -1st -2st -2st right
DGCGCD                         D G C G C D            -2st -2st -2st same +1st -2st right
Half-step down (Eb standard)   Eb Ab Db Gb Bb Eb      -1st -1st -1st -1st -1st -1st right
Whole-step down (D standard)   D G C F A D            -2st -2st -2st -2st -2st -2st right
```

- **La tabla es correcta.** Los 12 ejemplos reciben su afinación, y las notas y los cambios de las nueve afinaciones son los de un manual.

## Una afinación dada por sus notas

Cuando no coincide ningún nombre, la skill lee las seis primeras notas de la pregunta y busca en su tabla una afinación con la misma grafía ([líneas 203-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L203-L211), [líneas 228-238](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L228-L238)):

```csharp
    private static string[]? TryParseSixNoteTuning(string msg)
    {
        var matches = Regex.Matches(msg, @"\b[A-Ga-g][b#♭♯]?\b");
        if (matches.Count < 6) return null;
        // Take the first 6 — accept that if the user mentions extra pitches
        // elsewhere in the prompt we might pick up garbage. Common phrasings
        // tend to put the 6 notes right next to each other.
        var arr = new string[6];
        for (var i = 0; i < 6; i++) arr[i] = NormalizeNote(matches[i].Value);
        return arr;
    }
```

El programa pregunta "what tuning is …" (¿qué afinación es…?) con las notas de las nueve afinaciones, de la afinación estándar y de la estándar en E♭ escrita con sostenidos, en cuatro notaciones: ASCII, `♯` y `♭`, guiones entre las notas, y minúsculas. Espera la afinación de la tabla con las mismas alturas o, si ninguna las tiene, las notas de la pregunta:

```text
== "what tuning is …" with the six notes, at the pin: the tuning each notation gets
tuning                         ASCII            ♯ and ♭          hyphens          lower case
DADGAD                         right            right            right            right
Drop D                         right            right            right            right
Double Drop D                  right            right            right            right
Drop C                         right            right            right            right
Open G                         right            right            right            right
Open D                         other notes      other notes      other notes      other notes
DGCGCD                         right            right            right            right
Half-step down (Eb standard)   right            other notes      right            right
Whole-step down (D standard)   right            right            right            right
standard                       right            right            right            right
Eb standard, in sharps         another tuning   another tuning   another tuning   another tuning
questions 44: answered with the tuning asked or its notes 35, with another named tuning 4, other answers 5
  Open D, every notation: no name, reads D A D F A D
  Half-step down (Eb standard), ♯ and ♭: no name, reads E A D G B E
  Eb standard, in sharps, every notation: Whole-step down (D standard)
```

- **La expresión pierde los sostenidos, y los bemoles escritos `♭`.** Termina en `\b`, igual que la tonalidad en la skill de cejilla. F♯ se lee como F, así que las notas de open D, D A D F♯ A D, se leen como D A D F A D, que no coinciden con ninguna afinación, en ninguna de las notaciones. E♭ A♭ D♭ G♭ B♭ E♭ se lee como E A D G B E, la afinación estándar, que la skill no nombra.
- **La estándar en E♭ escrita con sostenidos recibe el nombre de Whole-step down.** D♯ G♯ C♯ F♯ A♯ D♯ se lee como D G C F A D, una afinación un semitono más grave en cada cuerda, y la respuesta da su nombre y su tabla.
- **En `main`, la lectura de las seis notas es la del commit fijado,** y `GaMain` imprime la misma tabla.

## Afinaciones fuera de la tabla

El programa pregunta por diez afinaciones por su nombre, fuera de la tabla o escritas con una alteración, y compara las notas de la respuesta con las de la afinación pedida:

```text
== Tunings outside the table, at the pin
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   Drop C: C G C F A D              another tuning
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   Drop D: D A D G B E              another tuning
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

```text
== Tunings outside the table, on main
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   declined                         declined
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   declined                         declined
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

- **Open D minor recibe open D, y open G minor, open G.** La expresión de open D se detiene en la `d`, y el "minor" que sigue no se lee. La respuesta da F♯ donde el guitarrista pidió F, y B donde pidió B♭.
- **En el commit fijado, "drop C♯" recibe drop C, y "drop D♭", drop D.** La expresión de drop C del commit fijado excluye un `#` o una `b` en ASCII detrás de su letra, pero no `♯` ni `♭`, y la de drop D no hace esa comprobación. En `main`, las expresiones de drop D, double drop D, drop C, open G y open D excluyen los cuatro signos, y la skill rechaza las dos preguntas ([líneas 57-67 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L57-L67)).
- **Las afinaciones fuera de la tabla se rechazan,** como quiere el comentario de drop C: "better no match than a wrong one" (mejor ninguna coincidencia que una equivocada). La afinación estándar es una de ellas.
- **El comentario de la clase promete una respuesta que el código no da.** Cita "What does an Em shape look like in drop-D" (¿cómo queda una forma de Em en drop D?) con "caveat about altered low E string" (advertencia sobre la cuerda E grave alterada) ([línea 15](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L15)). La skill responde con la tabla de drop D, que no nombra Em.

## Hasta dónde llega el curso

- **No se ejecutan ni el enrutador ni el modelo.** Saber qué intención elige el enrutador para estas preguntas en producción necesita los embeddings (*por verificar*).
- **La grafía teórica es la prueba del curso:** una tonalidad o un acorde, mayor o menor, que con esa fundamental y esa cualidad no tiene armadura. Un guitarrista que lee una hoja de acordes puede aceptar A♯ por B♭; una armadura, no.
- **La skill de cejilla solo se ejecuta en el commit fijado.** En `main`, `CapoSkill` difiere en el indicador `Declined` de su rechazo, según se lee en el diff.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: en la issue de GA [#787](https://github.com/GuitarAlchemist/ga/issues/787), el sentido de la pregunta, las alteraciones, los rechazos y la grafía de la skill de cejilla, y su `CanHandle`; en la [#788](https://github.com/GuitarAlchemist/ga/issues/788), la lectura de las seis notas por la skill de afinaciones, las afinaciones abiertas menores y la advertencia prometida para drop D.

## Ejercicios

1. ¿Por qué se rechaza "song in Em, capo 2, what shape"? ¿Qué responde la skill del commit fijado a "song in E min, capo 2, what shape"?
2. ¿Cómo puede un guitarrista obtener B♭ en lugar de A♯ al preguntar "What does an A shape sound like with capo 1"?
3. En el commit fijado, ¿qué responde la skill de afinaciones a "what tuning is D A D Gb A D"? ¿Cuál de sus dos pasos le impide nombrar open D?
4. En el commit fijado, ¿por qué se rechaza "what is drop Db tuning", mientras que "what is drop D♭ tuning" recibe drop D?

<details>
<summary>Soluciones</summary>

1. Detrás de la tonalidad, la expresión pide un límite de palabra, o un espacio y uno de `major`, `minor`, `maj` o `min`. "Em" es una sola palabra, así que el límite falla entre E y m, y la pregunta se rechaza. "song in E min, capo 2, what shape" recibe la forma Dm. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
2. Con la palabra "flat" en cualquier parte de la pregunta, por ejemplo "What does an A shape sound like with capo 1, in flats": para una forma, la skill escribe bemoles cuando la pregunta contiene "flat", y responde B♭. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
3. Ningún nombre, con las notas D A D Gb A D. Aquí la lectura es completa, porque `b` es una letra, pero `NotesMatch` compara grafías: G♭ no es F♯. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.
4. En ASCII, `b` es una letra, así que no hay límite de palabra entre `D` y `b`, y la expresión de drop D no coincide. Tampoco hay seis notas, así que la skill rechaza la pregunta. `♭` no es un carácter de palabra, así que entre `D` y `♭` sí hay límite, y la expresión coincide. Comprobado ejecutando la skill del commit fijado, fuera de la salida esperada del curso.

</details>

## Puntos clave

- Una respuesta aritmética se puede comprobar contra un manual prompt a prompt: aquí, cada tonalidad que tiene armadura, en cada traste, y 44 afinaciones dadas por sus notas.
- Una expresión que lee una tonalidad tiene que tomar la alteración junto con la letra: `\b` detrás de `#`, `♯` o `♭` falla, y la expresión se queda con la letra.
- Una skill que deduce el sentido de la pregunta de su formulación responde a la pregunta contraria cuando cambia la formulación.
- La grafía forma parte de la respuesta: D♯ y E♭ son el mismo traste, no la misma tonalidad.
- Una skill que no necesita modelo debería poder alcanzarse sin él.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/CapoSkill.cs`, `Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): las mismas dos skills, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson17.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/TuningsProbe.cs`.
