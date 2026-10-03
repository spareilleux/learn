---
title: "Lección 22: Los acordes parecidos"
description: "IcvNeighborsSkill es la respuesta del chatbot de Guitar Alchemist a la pregunta de qué acordes se parecen a un acorde: lee un acorde y lista los conjuntos de clases de altura cuyos vectores interválicos están a 2 o menos del suyo. Ninguno de sus diez prompts de ejemplo, las preguntas que le envía el enrutador, coincide con las expresiones que lee, así que los rechaza todos, cuando su skill hermana responde a ocho de los suyos. Construye bien 10 de 27 acordes habituales, CM7 como una séptima menor, y sus ocho vecinos son los ocho primeros conjuntos por máscara de bits: los mismos para todas las tríadas mayores y menores, cinco de ellos intervalos de dos notas."
sidebar:
  label: 22. Los acordes parecidos
  order: 22
---

La [lección 21](../21-the-voicing-search/) midió la búsqueda por embeddings. Para los acordes que comparten una forma en cualquier tonalidad, GA remite a otra parte: "Transposition-agnostic "same-shape" similarity uses the ICV path (`IcvNeighborsSkill` / Grothendieck), not the embedding" (la similitud de «misma forma», independiente de la transposición, usa la vía ICV, no el embedding) ([`CLAUDE.md` línea 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md#L43)). `IcvNeighborsSkill` es esa vía en el chatbot ([`IcvNeighborsSkill.cs` líneas 9-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L9-L49)), registrada con las demás skills ([`GaPlugin.cs` línea 101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L101)). Lee un acorde, construye su conjunto de clases de altura y lista los conjuntos cuyos vectores interválicos están a una distancia L1 de 2 como máximo del vector del acorde, que obtiene de `GrothendieckService.FindNearby`. La [lección 14](../14-what-the-substitution-skill-answers/) se encontró con `FindNearby` a través de la skill de sustitución, y el [curso de teoría musical](../../music-theory-ga/04-set-classes/), a través de la herramienta MCP `ga_icv_neighbors`; esta lección interroga a la skill del chatbot.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `IcvNeighborsSkill` e `IntervalClassVectorSkill` solo marcan su rechazo con `Declined`, `DefaultRoutingHintProvider` y `GrothendieckDelta` no han cambiado, y `FindNearby` compara el conjunto de origen con cada conjunto por valor; los propios conjuntos de clases de altura sí cambiaron, así que `GaMain` vuelve a preguntar. Su salida imprime las mismas tablas que la del commit fijado, bajo títulos que dicen "on main". La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l22
dotnet run --project code/ga-ai/GaMain -c Release -- l22
```

## Cómo lee la skill una pregunta

La skill no tiene ninguna prueba por palabras clave: su `CanHandle` siempre dice que no, y el enrutador le envía una pregunta cuando el prompt más cercano al embedding de la pregunta es uno de sus prompts de ejemplo. Esos prompts se reformularon el 2026-06-16 para alejarlos de los de las skills vecinas, y el comentario que los precede dice qué palabras se quitaron. Las expresiones que leen la pregunta todavía las necesitan:

```csharp
    // Routing anchors emphasise the user GOAL — "find OTHER chords SIMILAR to
    // one chord" — using resemble/similar/most-like/interval-profile. Two
    // curation passes (routing-ambiguity diagnostic, 2026-06-16):
    //  1. dropped the bare "ICV" framing (owned by IntervalClassVectorSkill,
    //     the single-chord ICV intent): -0.05 -> +0.036 silhouette.
    //  2. dropped "close/nearby/adjacent" (collided with GrothendieckDeltaSkill's
    //     "how close are X and Y") and "chords to C major" (collided with
    //     ChordInfoSkill's "what is a C major chord"). "other … resemble/similar"
    //     keeps the find-similar goal while shedding both neighbours' vocabulary.
    public IReadOnlyList<string> ExamplePrompts =>
    [
        "which chords are most similar to Dm7",
        "what other chords resemble Cmaj7",
        "find chords with a similar sound to G7",
        "chords related to F major by interval content",
        "what chords share Gmaj7's interval profile",
        "list chords most like E minor",
        "chords with similar interval content to Bm7b5",
        "what voicings are most similar to Am",
        "which chords are closest in interval content to Fmaj7",
        "chords that resemble Cmaj7 harmonically",
    ];

    public bool CanHandle(string message) => false;  // semantic-routing only

    private const int DefaultMaxDistance = 2;
    private const int MaxNeighborsToShow = 8;

    // Single-chord pattern — anchored on "neighbors/near/close/adjacent" + a
    // chord token. Word boundary protects against routing on prose that
    // happens to mention a single chord-letter.
    private static readonly Regex NeighborsPattern =
        new(@"\b(?:icv\s+neighbors?|neighbors?|nearby|close\s+to|near|adjacent|harmonic(?:ally)?\s+(?:close|near|adjacent))\s+(?:to\s+|of\s+)?(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Reverse anchor: "<chord> ... (icv-)neighbors" / "<chord> ... close"
    private static readonly Regex NeighborsPatternReverse =
        new(@"\b(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b[^.?!]*?\b(?:icv\s+neighbors?|neighbors?|harmonic(?:ally)?\s+(?:close|near|adjacent))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`ExecuteAsync` prueba la primera expresión y después la segunda, toma el acorde que capturan y construye su conjunto ([líneas 102-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L102-L118)). Cuando no coincide ninguna de las dos, responde "Ask about ICV-neighbor pitch-class sets near a chord", con una confianza de 0.1 ([líneas 254-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L254-L260)). En la vía de los embeddings, `DefaultRoutingHintProvider` suma además 0.06 a una intención cuya regla coincide con la pregunta; la regla de esta skill pide "icv neighbors", "harmonically close" o algunas variantes ([`DefaultRoutingHintProvider.cs` líneas 136-139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L136-L139)).

## Las formulaciones de GA

El programa le hace a la skill sus diez prompts de ejemplo, las cuatro formulaciones de su comentario de documentación ([líneas 17-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L17-L23)), las dos que sugiere su rechazo y las tres del borrador en espera, y le pregunta a `DefaultRoutingHintProvider` qué intenciones reforzaría cada una:

```text
== IcvNeighborsSkill's example prompts and GA's other phrasings for it, at the pin
prompt                                             from           the skill's answer       routing hints, +0.06 each
which chords are most similar to Dm7               anchor         declined                 none
what other chords resemble Cmaj7                   anchor         declined                 none
find chords with a similar sound to G7             anchor         declined                 none
chords related to F major by interval content      anchor         declined                 none
what chords share Gmaj7's interval profile         anchor         declined                 none
list chords most like E minor                      anchor         declined                 none
chords with similar interval content to Bm7b5      anchor         declined                 none
what voicings are most similar to Am               anchor         declined                 none
which chords are closest in interval content to Fmaj7 anchor         declined                 none
chords that resemble Cmaj7 harmonically            anchor         declined                 none
What chords are harmonically close to Cmaj7        doc comment    neighbors of Cmaj7       skill.icvneighbors
Nearby pitch-class sets to C major                 doc comment    declined                 none
Find ICV neighbors of Dm7                          doc comment    neighbors of Dm7         skill.icvneighbors, skill.intervalclassvector
Closest chord to G7 in ICV space                   doc comment    declined                 skill.intervalclassvector
ICV neighbors of Cmaj7                             refusal        neighbors of Cmaj7       skill.icvneighbors, skill.intervalclassvector
what chords are harmonically close to Dm7          refusal        neighbors of Dm7         skill.icvneighbors
Harmonically similar chords to Cmaj7               parked draft   declined                 none
ICV neighbours of [0,3,6,9]                        parked draft   declined                 skill.intervalclassvector
What's close to a half-diminished chord?           parked draft   neighbors of a           skill.interval
anchors 10: answered 0, declined 10, hinted toward skill.icvneighbors 0
CanHandle accepts 0 of them
```

- **La skill rechaza sus diez prompts de ejemplo.** "most similar", "resemble", "closest in interval content": ninguna es una palabra que lean las expresiones. Una pregunta formulada como estos prompts es la que más probabilidades tiene de llegar a la skill, ya que el enrutador compara las preguntas con ellos, y la skill le da su rechazo. En `main`, el rechazo lleva el indicador `Declined`, "so a caller may route it to another handler" (para que quien llama pueda enviarlo a otro manejador) ([`GuitarAlchemistAgentBase.cs` líneas 347-352 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)).
- **Ninguna regla de las pistas refuerza la skill para ellos,** y dos de las formulaciones del comentario de documentación, "Nearby pitch-class sets to C major" y "Closest chord to G7 in ICV space", también se rechazan.
- **La propia sugerencia del rechazo, "ICV neighbors of Cmaj7", refuerza a dos skills,** esta y `skill.intervalclassvector`, cuya regla coincide con "icv" en cualquier parte ([líneas 124-126](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L124-L126)).

## La skill hermana

`IntervalClassVectorSkill` calcula el vector de un acorde, y sus prompts de ejemplo se depuraron en la misma pasada: conservó el vocabulario ICV como "the discriminator vs the neighbors / delta / path skills, which were de-ICV'd" (lo que la distingue de las skills de vecinos, delta y camino, a las que se les quitó el ICV) ([`IntervalClassVectorSkill.cs` líneas 43-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L43-L60)). El programa le hace los suyos:

```text
== IntervalClassVectorSkill's example prompts, at the pin
prompt                                             the skill's answer
what is the interval-class vector of Cmaj7         ICV of Cmaj7
interval class vector of Dm7                       ICV of Dm7
compute the ICV of the major scale                 ICV of the major scale
interval-class vector of {0,2,4,5,7,9,11}          ICV of {0,2,4,5,7,9,11}
what's the interval vector for G7                  ICV of G7
how many tritones does Cmaj7 contain               declined
compute the interval-class vector of Fmaj7         ICV of Fmaj7
ICV of the dorian mode                             ICV of the dorian
interval class vector for {0,1,4,8}                ICV of {0,1,4,8}
what's the interval content of Am                  declined
anchors 10: answered 8
```

Responde a ocho. Sus dos rechazos, "how many tritones does Cmaj7 contain" y "what's the interval content of Am", son los dos prompts que no tienen ni un conjunto de números ni "interval vector", "interval-class vector" o "ICV", que necesitan sus expresiones de acorde y de escala ([líneas 64-77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L64-L77)).

## Los acordes que lee

El acorde es una letra, una alteración, una de ocho palabras, cifras, notas alteradas y un ° opcional, y después un límite de palabra. `TryBuildPcSet` construye su conjunto a partir de una tabla de 16 cualidades ([líneas 196-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L196-L232)):

```csharp
    private static int[] QualityIntervals(string quality)
    {
        var q = quality.ToLowerInvariant().Trim();
        if (q == string.Empty || q == "maj" || q == "major") return [0, 4, 7];
        if (q is "m" or "min" or "minor" or "-") return [0, 3, 7];
        if (q is "dim" or "°" or "o") return [0, 3, 6];
        if (q is "aug" or "+") return [0, 4, 8];
        if (q is "7") return [0, 4, 7, 10];
        if (q is "m7" or "min7" or "-7") return [0, 3, 7, 10];
        if (q is "maj7" or "major7" or "M7") return [0, 4, 7, 11];
        if (q is "m7b5" or "min7b5" or "ø" or "ø7") return [0, 3, 6, 10];
        if (q is "dim7" or "°7" or "o7") return [0, 3, 6, 9];
        if (q is "sus2") return [0, 2, 7];
        if (q is "sus4" or "sus") return [0, 5, 7];
        if (q is "6") return [0, 4, 7, 9];
        if (q is "m6") return [0, 3, 7, 9];
        if (q is "9") return [0, 4, 7, 10, 2];
        if (q is "maj9") return [0, 4, 7, 11, 2];
        if (q is "m9") return [0, 3, 7, 10, 2];
        return [0, 4, 7];
    }
```

El programa pregunta "ICV neighbors of" por 27 acordes y compara el conjunto que construye la skill con las notas del acorde:

```text
== The chords the skill reads, after "ICV neighbors of", at the pin
chord      its notes          read as          notes built        right
C          C E G              C                C E G              yes
Cm         C D# G             Cm               C D# G             yes
Cmaj7      C E G B            Cmaj7            C E G B            yes
CM7        C E G B            CM7              C D# G A#          no
Cmin7      C D# G A#          Cmin7            C D# G A#          yes
Cdom7      C E G A#           Cdom7            C E G              no
Cm7b5      C D# F# A#         Cm7b5            C D# F# A#         yes
Cø7        C D# F# A#         declined         -                  no
Cdim       C D# F#            Cdim             C D# F#            yes
C°         C D# F#            C                C E G              no
Cdim7      C D# F# A          Cdim7            C D# F# A          yes
C°7        C D# F# A          C°               C D# F#            no
Caug       C E G#             Caug             C E G#             yes
C+         C E G#             C                C E G              no
Cadd9      C D E G            Cadd9            C E G              no
C7sus4     C F G A#           declined         -                  no
C7b9       C C# E G A#        C7b9             C E G              no
C7#9       C D# E G A#        C7#9             C E G              no
Cm11       C D D# F G A#      Cm11             C E G              no
C13        C D E G A A#       C13              C E G              no
CmMaj7     C D# G B           declined         -                  no
C5         C G                C5               C E G              no
F#m7b5     C E F# A           F#m7b5           C E F# A           yes
B♭7        D F G# A#          B♭7              D F G# A#          yes
C minor    C D# G             C                C E G              no
A minor    C E A              A                C# E A             no
a Cmaj7    C E G B            a                C# E A             no
chords 27: built right 10
```

- **"CM7", una séptima mayor, se construye como C menor séptima.** El sufijo se pasa a minúsculas antes de leer la tabla, así que el `"M7"` de la línea 221 no puede coincidir nunca, y "m7" sí.
- **Un sufijo desconocido da una tríada mayor, sin ningún aviso.** Cdom7, Cadd9, C7b9, C7#9, Cm11, C13 y C5 reciben todos la respuesta de C E G; "C minor" y "A minor" se leen como C y A, porque un espacio termina el acorde.
- **° y + terminan el acorde.** No son letras, así que el límite de palabra cae delante de ellos: C° y C+ se convierten en C, y C°7 en la tríada C°, porque también cae un límite entre ° y 7. ø es una letra, así que Cø7 no tiene límite detrás de su C y se rechaza, como C7sus4 y CmMaj7, cuyos sufijos no figuran en la expresión.
- **"a" es un acorde.** La expresión no distingue mayúsculas de minúsculas, así que el artículo de "close to a half-diminished chord", la formulación del borrador en espera, se lee como A mayor, y lo mismo ocurre con el de "ICV neighbors of a Cmaj7".

## Los vecinos

La skill le pide a `FindNearby` todos los conjuntos a una distancia de 3 como máximo, vuelve a calcular ella misma cada distancia y se queda con los ocho primeros a distancia 1 o 2 ([líneas 120-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L120-L140)):

```csharp
        var sourceIcv = source.IntervalClassVector;
        var rawNeighbors = grothendieck.FindNearby(source, DefaultMaxDistance + 1).ToList();

        var neighbors = rawNeighbors
            .Select(n => (n.Set, Delta: ComputeTrueDelta(sourceIcv, n.Set.IntervalClassVector)))
            .Where(t => !ReferenceEquals(t.Set, source))           // skip the source itself
            .Where(t => t.Delta.l1 > 0)                            // skip exact ICV-identical (same set class)
            .Where(t => t.Delta.l1 <= DefaultMaxDistance)
            .OrderBy(t => t.Delta.l1)
            .Take(MaxNeighborsToShow)
            .ToList();
```

`FindNearby` recorre `PitchClassSet.Items` en el orden de sus ids, que son sus máscaras de bits, y ordena lo que conserva por un coste, la distancia multiplicada por 0.6, manteniendo ese orden entre costes iguales ([`GrothendieckService.cs` líneas 38-90](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L90)). El programa cuenta, para cada una de las 16 cualidades de la skill sobre C, los conjuntos a distancia 1 o 2, y compara las ocho filas con los ocho primeros de ellos por id:

```text
== The neighbors the skill lists for a chord, at the pin
chord   its vector      sets 1-2 off  set classes  of notes  rows   of notes  L1, cost   set classes   with a C   the first by id
C       <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cm      <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cdim    <0 0 2 0 0 1>   18            2            2         8      2         2, 1.20    2             2          yes
Caug    <0 0 0 3 0 0>   12            1            2         8      2         2, 1.20    1             2          yes
C7      <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cm7     <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cmaj7   <1 0 1 2 2 0>   72            4            4         8      4         2, 1.20    4             6          yes
Cm7b5   <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cdim7   <0 0 4 0 0 2>   0             0                      0      -         -          0             0          -
Csus2   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
Csus4   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
C6      <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cm6     <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
C9      <0 3 2 2 2 1>   24            1            5         8      5         2, 1.20    1             4          yes
Cmaj9   <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
Cm9     <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
the rows for C:
  {0,3}     C D#       2-3    <0 0 1 0 0 0>
  {0,4}     C E        2-4    <0 0 0 1 0 0>
  {1,4}     C# E       2-3    <0 0 1 0 0 0>
  {0,1,4}   C C# E     3-3    <1 0 1 1 0 0>
  {0,3,4}   C D# E     3-3    <1 0 1 1 0 0>
  {0,5}     C F        2-5    <0 0 0 0 1 0>
  {1,5}     C# F       2-4    <0 0 0 1 0 0>
  {0,1,5}   C C# F     3-4    <1 0 0 1 1 0>
Cdim7: No pitch-class sets within L1 = 2. Try a wider radius.
chords 192: qualities whose 12 roots get the same rows 16 of 16; different answers 10, different vectors 10
```

- **Todas las filas están a distancia 2, con un coste de 1.20.** Entre dos conjuntos del mismo tamaño la distancia es par, y un conjunto de otro tamaño está a 3 como mínimo de un acorde de tres notas o más, salvo un conjunto de dos notas respecto de una tríada. "Sorted by harmonic cost" no ordena nada, y las ocho filas son las ocho primeras por máscara de bits, lo que favorece a las clases de altura más bajas: seis de las ocho filas de C contienen un C, y ninguna pasa de F.
- **Las filas solo dependen del vector del acorde.** Los 192 acordes de 12 fundamentales y 16 cualidades reciben 10 respuestas distintas, una por vector: C y F#m reciben las mismas ocho filas.
- **Los vecinos de una tríada son sobre todo intervalos.** Cinco de las ocho filas de C son conjuntos de dos notas, y las otras tres contienen cada una un semitono, que C mayor no tiene. Las filas de Cdim y de Caug son todas conjuntos de dos notas.
- **Cdim7 no recibe ningún vecino, y sí el consejo "Try a wider radius",** aunque el radio es una constante, `DefaultMaxDistance` ([línea 76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L76)), que el usuario no puede cambiar.

El curso de teoría musical comprobó que `ga_icv_neighbors`, la herramienta MCP construida sobre el mismo servicio, imprimía para C, en el commit fijado, doce líneas de la propia clase de conjuntos de C; en `main` lista cada clase de conjuntos una sola vez, a su distancia real ([`ChordAtonalTool.cs` líneas 337-348 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/GaMcpServer/Tools/ChordAtonalTool.cs#L337-L348)). La skill calculaba distancias reales desde el principio ([líneas 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)), y sigue listando varias transposiciones de una misma clase de conjuntos: las ocho filas de C contienen cinco clases de conjuntos.

## El borrador de skill en espera

`skills-dev/_pending-tools/icv-neighbors/DRAFT.md` es una skill del chatbot escrita para llamar a `ga_icv_neighbors`, en espera como las de las lecciones 19 a 21 ([`skills-dev/_pending-tools/README.md` línea 52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L52)):

- dice que la herramienta aún no está implementada, "not yet implemented in Common/GA.Business.ML/Agents/Mcp/", y remite a `Common/GA.Business.ML/Agents/Mcp/AtonalMcpTools.cs` (líneas [18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L18) y [72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L72)), un archivo que GA no tiene; la herramienta está en `GaMcpServer/Tools/ChordAtonalTool.cs` ([líneas 220-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L220-L254));
- espera `chord`, `topK` y `metric`, con una distancia euclídea, de Manhattan o del coseno, y una respuesta de `Neighbours` ([líneas 31-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L31-L41)); la herramienta recibe `symbol` y `maxDistance` y devuelve líneas de texto;
- su ejemplo da el vector de Cmaj7 y tres vecinos, cada uno con una distancia ([líneas 53-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L53-L58)):

```text
== The parked draft's example for Cmaj7, at the pin
chord                  notes          vector           Forte  L1     the draft
Cmaj7                  C E G B        <1 0 1 2 2 0>    4-20   0      [1, 0, 1, 2, 2, 0], 4-20
Am7                    A C E G        <0 1 2 1 2 0>    4-26   4      [1,0,1,2,2,0], distance 0.0, same set class
Cm9 without its root   D# G A# D      <1 0 1 2 2 0>    4-20   0      distance 0.6
Fmaj7                  F A C E        <1 0 1 2 2 0>    4-20   0      distance 0.0, same set class
```

Am7 no pertenece a la clase de conjuntos de Cmaj7: es A C E G, las notas de C6, 4-26, a distancia 4. Cm9 sin su fundamental es E♭ séptima mayor, de la clase de Cmaj7, a distancia 0, no 0.6. De las tres formulaciones del borrador, la skill rechaza dos y lee A mayor en la tercera.

## Hasta dónde llega el curso

- **No se ejecuta el enrutador:** necesita los embeddings. La lección le pregunta a la skill lo que le enviaría el enrutador, sus propios prompts de ejemplo.
- **Las notas de los acordes son las del curso,** las de un manual para cada cifrado.
- **`ga_icv_neighbors` no se ejecuta aquí;** lo ejecuta el curso de teoría musical.
- **El programa llama directamente a los métodos de las skills,** no a través del chatbot.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#798](https://github.com/GuitarAlchemist/ga/issues/798): los prompts de ejemplo que las expresiones no leen, los acordes que la tabla construye mal, los vecinos listados por máscara de bits, y el borrador de skill en espera.

## Ejercicios

1. "which chords are most similar to Dm7" es uno de los prompts de ejemplo de la skill. ¿Por qué lo rechaza la skill?
2. Las filas de C incluyen `{0,4}`, C y E. ¿Qué distancia hay entre el vector de C, `<0 0 1 1 1 0>`, y el de este conjunto, `<0 0 0 1 0 0>`? ¿Por qué no puede tener tres notas un vecino de Cmaj7?
3. ¿Por qué reciben C y F#m las mismas ocho filas?
4. "ICV neighbors of CM7" responde para C menor séptima. ¿Qué línea convierte M7 en m7?

<details>
<summary>Soluciones</summary>

1. Sus expresiones necesitan "neighbors", "nearby", "close to", "near" o "adjacent" justo delante del acorde, "neighbors" detrás de él, o "harmonically close", "near" o "adjacent" a cualquiera de los dos lados ([líneas 82-89](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L82-L89)); el prompt no tiene ninguna de ellas, así que `ExecuteAsync` da el rechazo.
2. 1 + 1 = 2: el vector de C cuenta una tercera menor, E–G, y una quinta, C–G, que le faltan a C–E. Un vector cuenta los intervalos entre cada par de notas: 6 para cuatro notas, 3 para tres, así que un conjunto de tres notas está a 3 como mínimo de Cmaj7, más que los 2 de la skill.
3. Las dos son tríadas de la misma clase de conjuntos, con el vector `<0 0 1 1 1 0>`. `FindNearby` compara vectores, no notas, y devuelve los conjuntos por máscara de bits, así que los ocho primeros a distancia 2 son los mismos.
4. La línea 214, `quality.ToLowerInvariant()`: "M7" se convierte en "m7", que la línea 220 lee como una séptima menor.

</details>

## Puntos clave

- Las anclas de enrutamiento y el parser que las sigue forman un único contrato: reformular uno sin el otro envía preguntas a un rechazo.
- Los prompts de ejemplo de una skill son la primera prueba de la skill.
- Una tabla que recurre por defecto a una tríada mayor responde a preguntas que no sabe leer.
- "Sorted by cost" significa poco cuando todos los costes empatan: el orden es entonces el orden de enumeración.
- Los vecinos en el espacio de los vectores dependen del vector, no del acorde: todos los acordes de una clase de conjuntos reciben la misma lista.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/ChordAtonalTool.cs`, `skills-dev/_pending-tools/icv-neighbors/DRAFT.md`, `CLAUDE.md`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): las mismas skills, con sus rechazos marcados con `Declined`, y `ChordAtonalTool.cs`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson22.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvNeighborsProbe.cs`.
