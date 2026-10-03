---
title: "Lección 21: La búsqueda de voicings"
description: "El servidor MCP de Guitar Alchemist busca en su índice de voicings OPTIC-K con ga_search_voicings, y lista lo que lee esa búsqueda con ga_voicing_vocabulary: 18 fundamentales, 45 cualidades de acorde, 23 modos y 188 tags. El modo nunca llega al vector de la consulta: C Lydian responde lo mismo que C, y Lydian a secas devuelve los diez primeros voicings del índice, todos con puntuación 0. Los 188 tags activan 12 bits, así que jazz responde como rock-guitar y rootless como shell-voicing, y ninguno de los 100 voicings devueltos para diez acordes de séptima seguidos de rootless prescinde de la fundamental. Palabras como for, the y what pasan por tags, y ninguna consulta puede puntuar por encima de 0.70, cuando el ejemplo de la skill muestra 0.9831."
sidebar:
  label: 21. La búsqueda de voicings
  order: 21
---

La [lección 20](../20-generated-progressions/) terminó con una nota de `ga_generate_progression`: "Compose by passing each chord to ga_search_voicings" (compón pasando cada acorde a ga_search_voicings). `ga_search_voicings` es la búsqueda de `GaMcpServer` en el índice OPTIC-K: lee en una consulta un acorde, un modo y tags de estilo o de técnica, los convierte en un vector de consulta y devuelve los voicings más cercanos ([`VoicingSearchTool.cs` líneas 92-236](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L92-L236)). Una segunda herramienta, `ga_voicing_vocabulary`, lista lo que lee la búsqueda, para que un agente pueda reformular las palabras de su usuario antes de buscar ([`VoicingVocabularyTool.cs` líneas 24-78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L24-L78)). La skill `voicing-search` de GA le indica a Claude Code que llame una vez al vocabulario y después a la búsqueda ([`.claude/skills/voicing-search/SKILL.md` línea 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L30)). Las lecciones 3 y 16 examinaron el lector y la búsqueda desde el lado del chatbot; esta lección interroga a la herramienta.

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), las dos herramientas solo difieren en un comentario y en una descripción, y el lector y el registro de tags no han cambiado; el codificador de consultas y la búsqueda sí cambiaron, así que `GaMain` vuelve a hacer las preguntas cuyas respuestas dependen de ellos. El programa compila el propio `VoicingSearchTool.cs` de GA, que ahora sirve también a las lecciones 19 y 20 en lugar del sustituto del curso. La herramienta encuentra el índice del curso mediante `GA_OPTICK_INDEX_PATH` ([líneas 64-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L80)), y su log de telemetría se desactiva mediante `GA_VOICING_NO_TELEMETRY` ([`VoicingTelemetryLog.cs` líneas 33-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/VoicingTelemetryLog.cs#L33-L36)). La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l21
dotnet run --project code/ga-ai/GaMain -c Release -- l21
```

## Cómo lee la herramienta una consulta

`TypedMusicalQueryExtractor` lee la consulta palabra a palabra ([líneas 86-148](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L86-L148)). La primera palabra que empieza por mayúscula y se analiza como un acorde es el acorde. Después, una palabra, o dos, de una lista de 23 modos es el modo, un instrumento es un filtro, unas pocas palabras de relleno como "chord" y "voicing" se omiten, y cualquier otra palabra de tres letras o más que conozca `SymbolicTagRegistry` es un tag:

```csharp
            // 2. Mode: single-word modes or two-word ("harmonic minor").
            if (modeName is null)
            {
                if (KnownModesSet.Contains(tok))
                {
                    modeName = tok;
                    continue;
                }
                if (i + 1 < tokens.Length)
                {
                    var twoWord = tok + " " + tokens[i + 1];
                    if (KnownModesSet.Contains(twoWord))
                    {
                        modeName = twoWord;
                        continue;
                    }
                }
            }

            // 3. Instrument filter — first hit wins. Consumes the token so it never
            //    leaks into the tag stream (where "bass" would otherwise miss the
            //    registry and silently return no voicings from the wrong population).
            if (instrument is null && InstrumentAliases.TryGetValue(tok, out var inst))
            {
                instrument = inst;
                continue;
            }

            // 4. Linguistic filler ("chord", "voicing", "shape", …) never becomes a tag.
            //    Without this, the registry's substring fallback maps "chord" onto the
            //    first tag whose name contains it and poisons the SYMBOLIC vector.
            if (TagStopWords.Contains(tok))
            {
                continue;
            }

            // 5. Symbolic tag — matches the corpus's vocabulary (case-insensitive,
            //    hyphen-normalized, with prefix/substring fallback). Require tokens
            //    ≥ 3 chars so the registry's substring-contains fallback doesn't fire
            //    on stop-words ("a", "me", "to") that happen to be substrings of a tag.
            if (tok.Length >= 3 && registry.GetBitIndex(tok).HasValue)
            {
                tags.Add(tok.ToLowerInvariant());
            }
```

El registro conoce una palabra cuando es uno de sus tags, o cuando la palabra contiene uno de sus tags, o uno de sus tags la contiene ([`SymbolicTagRegistry.cs` líneas 196-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L196-L220)):

```csharp
    public int? GetBitIndex(string tag)
    {
        if (string.IsNullOrWhiteSpace(tag))
        {
            return null;
        }

        var normalized = tag.ToLowerInvariant().Trim().Replace(" ", "-").Replace("_", "-");

        if (_tagToBitMap.TryGetValue(normalized, out var bit))
        {
            return bit;
        }

        // Partial match fallback (e.g. "sweep" matches "sweep-picking")
        foreach (var kvp in _tagToBitMap)
        {
            if (normalized.Contains(kvp.Key) || kvp.Key.Contains(normalized))
            {
                return kvp.Value;
            }
        }

        return null;
    }
```

Luego `MusicalQueryEncoder` convierte la lectura en un vector ([`MusicalQueryEncoder.cs` líneas 43-108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L108)). STRUCTURE, MODAL y ROOT salen de las clases de altura del acorde, SYMBOLIC de los tags, y MORPHOLOGY y CONTEXT se quedan a cero. El codificador nunca lee el modo:

```csharp
        // SYMBOLIC — technique/style tags
        if (q.Tags is { Count: > 0 })
        {
            var symbolicVec = SymbolicVectorService.ComputeEmbedding(q.Tags);
            EmbeddingSchema.WriteInto(raw, "SYMBOLIC", symbolicVec);
        }

        // ROOT — 12-dim one-hot (v1.8). Query carries root signal IF the chord symbol
        // specified one; otherwise zero. Low weight (0.05) in the weighted cosine, so
        // root match adds a small discriminating boost on top of set-class-level STRUCTURE.
        if (root2.HasValue)
        {
            var rootVec = RootVectorService.ComputeEmbedding(root2);
            EmbeddingSchema.WriteInto(raw, "ROOT", rootVec);
        }

        // MORPHOLOGY (24 dim) and CONTEXT (12 dim) remain zero — a text query carries no
        // fretboard realization or temporal-motion information. Their cosine contribution
        // is therefore zero, which is the correct behavior.

        return ExtractCompactAndNormalize(raw);
```

`SymbolicVectorService` dedica 12 dimensiones a los tags, una por bit del registro, y pone a 1 el bit de cada tag ([`SymbolicVectorService.cs` líneas 13-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs#L13-L32)). La respuesta repite la lectura bajo `interpreted`, modo incluido, "to confirm the parser understood what the user wanted" (para confirmar que el parser entendió lo que quería el usuario), como dice la skill ([`SKILL.md` línea 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L92)).

## El vocabulario

`ga_voicing_vocabulary` devuelve las fundamentales y las cualidades de acorde de `ChordPitchClasses`, los modos del lector y todos los nombres que el registro conoce como tags. El registro asigna a cada tag un bit, según el archivo o la categoría de la que procede ([`SymbolicTagRegistry.cs` líneas 46-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L46-L111)). El programa lee el vocabulario, agrupa los tags por bit y le pasa a la búsqueda cada entrada por separado:

```text
== What ga_voicing_vocabulary lists, and how ga_search_voicings reads it, at the pin
roots 18, chord-quality suffixes 45, modes 23, symbolic tags 188
the query's SYMBOLIC partition: 12 dimensions; a tag sets the one its bit names
bit  where the registry takes it from                     tags  the first four
0    SemanticNomenclature, Structure                      6     closed-voicing, dense, open-voicing, resonant
1    SemanticNomenclature, Register                       5     register:high, register:low, register:mid, register:mid-high
2    SemanticNomenclature, Playability                    2     beginner-friendly, campfire-chord
3    GuitarTechniques.yaml                                16    bending, caged-system, chicken-picking, economy-picking
4    ArticulationTechniques.yaml                          4     accents, legato, slides, staccato
5    SemanticNomenclature, CAGED                          5     a-shape, c-shape, d-shape, e-shape
6    SemanticNomenclature, Mood                           8     aggressive, bright, dreamy, melancholy
7    SemanticNomenclature, Genre                          4     flamenco, jazz, neo-soul, rock-guitar
8    AdvancedHarmony.yaml                                 23    added-note-chords, augmented-scale, cluster-chords, eleventh-chords
9    VoiceLeading.yaml                                    28    augmented-fourth, chord-melody-technique, chromatic-voice-leading, contrary-motion
10   AtonalTechniques.yaml, KeyModulationTechniques.yaml  27    chromatic-mediant, chromatic-trichord, circle-of-fifths-modulation, direct-modulation
11   IconicChords                                         60    a-hard-day's-night-chord, add9(no3), beatles-chord, beatles-intro-chord
entries listed twice, with and without hyphens: 8, cmaj9floating, drop2voicings, drop3voicings, messiaen’smode2(octatonic)
tags that also give the query a chord, a famous chord's: 53
entries read otherwise when typed alone:
  g5: nothing
  schoenberg-op.16-chord: tags schoenberg-op 16-chord
  schoenbergop.16chord: tags schoenbergop 16chord
  harmonic minor: mode harmonic minor, tags minor
  lydian dominant: mode lydian, tags dominant
  melodic minor: mode melodic minor, tags minor
  phrygian dominant: mode phrygian, tags dominant
  whole tone: mode whole tone, tags tone
```

- **188 tags, 12 bits.** Un tag activa su bit, y nada más: `jazz`, `rock-guitar`, `flamenco` y `neo-soul` activan el mismo, y los 60 acordes famosos, otro.
- **Ocho entradas son otra entrada sin sus guiones.** El registro añade una copia sin guiones de cada tag que lleva un dígito, para que "drop2" encuentre el bit de `drop-2-voicings` ([líneas 176-193](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L176-L193)); el vocabulario lista las dos.
- **53 tags dan además un acorde a la consulta.** Cuando una consulta no nombra ningún acorde, el tag de un acorde famoso le da las notas de ese acorde: "Hendrix chord" busca un E7#9 ([`TypedMusicalQueryExtractor.cs` líneas 157-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L157-L174)).
- **Tres tags se leen de otra manera, y cinco modos leen un tag.** `g5` tiene menos de las tres letras que necesita un tag, y el `.` de `schoenberg-op.16-chord` lo parte en dos. "lydian dominant" y "phrygian dominant" se leen como lidio y frigio, porque se prueba una palabra antes que dos, y "dominant" se convierte en un tag. "harmonic minor", "melodic minor" y "whole tone" conservan su modo y añaden "minor" o "tone" como tag.

## Los propios ejemplos del vocabulario

El vocabulario termina con cinco ejemplos: lo que dijo un usuario y la consulta que un agente debería enviar en su lugar ([`VoicingVocabularyTool.cs` líneas 63-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L63-L70)). El programa envía las dos:

```text
== The vocabulary's five examples, as the user said them and as it rewrites them, at the pin
the user said                read as                            rewritten         read as                    same voicings   top scores
Cmaj7 jazz voicing           chord Cmaj7, tags jazz             Cmaj7 jazz        chord Cmaj7, tags jazz     yes             0.5085, 0.5085
F# Lydian drop 2             chord F#, mode Lydian, tags drop   F# Lydian drop2   chord F#, mode Lydian, tags drop2 yes             0.5310, 0.5310
rootless Dm7                 chord Dm7, tags rootless           Dm7 rootless      chord Dm7, tags rootless   yes             0.5085, 0.5085
something jazzy in F minor   chord F, mode minor, tags jazzy    Fm jazz           chord Fm, tags jazz        no              0.4810, 0.4810
shell voicing for G7         chord G7, tags shell for           G7 shell          chord G7, tags shell       yes             0.4932, 0.5078
F minor, read as chord F, mode minor: x-x-x-2-1-1 F/A, x-x-3-2-1-1 F, x-0-x-x-1-1 F/A
Fm, read as chord Fm: x-x-x-1-1-1 Fm/Ab, x-x-3-1-1-1 Fm, x-3-x-1-x-1 Fm/C
```

```text
== The vocabulary's five examples, as the user said them and as it rewrites them, on main
the user said                read as                            rewritten         read as                    same voicings   top scores
Cmaj7 jazz voicing           chord Cmaj7, tags jazz             Cmaj7 jazz        chord Cmaj7, tags jazz     yes             0.6447, 0.6447
F# Lydian drop 2             chord F#, mode Lydian, tags drop   F# Lydian drop2   chord F#, mode Lydian, tags drop2 yes             0.6500, 0.6500
rootless Dm7                 chord Dm7, tags rootless           Dm7 rootless      chord Dm7, tags rootless   yes             0.6408, 0.6408
something jazzy in F minor   chord F, mode minor, tags jazzy    Fm jazz           chord Fm, tags jazz        no              0.6000, 0.6000
shell voicing for G7         chord G7, tags shell for           G7 shell          chord G7, tags shell       yes             0.6316, 0.6447
F minor, read as chord F, mode minor: x-x-x-2-1-1 F/A, x-x-3-2-1-x F, x-x-3-2-1-1 F
Fm, read as chord Fm: x-x-x-1-1-1 Fm/Ab, x-x-3-1-1-x Fm, x-x-3-1-1-1 Fm
```

- **"something jazzy in F minor" recibe voicings de F mayor, en el commit fijado y en `main`.** El lector toma "F" por un acorde, una tríada mayor, y "minor" por un modo, que el vector ignora. "Fm" recibe F menor.
- **"shell voicing for G7" lee "for" como un tag.** Recibe los mismos diez voicings que "G7 shell", con una puntuación máxima más baja.
- Los otros tres ejemplos reciben los mismos voicings que su reformulación.

## Los modos

La descripción de la herramienta promete nombres de modo, "mode names (Lydian, Dorian)" ([línea 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L95)), y la skill describe la partición MODAL como el color del modo, "mode flavor" ([`SKILL.md` línea 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L14)). El programa pregunta por cuatro acordes seguidos de cada uno de los 23 modos, y luego por cada modo a secas:

```text
== The 23 modes after a chord, and alone, at the pin
chord   modes  the same ten voicings as alone the others, as read
C       23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Am      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
G7      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Dm7     23     18                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant; whole tone: mode whole tone, tags tone
modes alone: 18 of 23 answer with every score 0.0000, all the same ten voicings: yes, the index's first ten: yes
  x-x-x-0-0-0 Em/G, x-x-x-0-0-1 G7(shell), x-x-x-0-0-2 Gmaj7(shell), x-x-x-0-0-3 G + B (Major 3rd), x-x-x-0-1-0 C/G, x-x-x-0-1-1 Csus4/G, x-x-x-0-1-2 C5/G, x-x-x-0-1-3 C5, x-x-x-0-2-0 Dbdim/G, x-x-x-0-2-1 Gm7b5
  harmonic minor: mode harmonic minor, tags minor, top score 0.0577
  lydian dominant: mode lydian, tags dominant, top score 0.0577
  melodic minor: mode melodic minor, tags minor, top score 0.0577
  phrygian dominant: mode phrygian, tags dominant, top score 0.0577
  whole tone: mode whole tone, tags tone, top score 0.0577
```

```text
== The 23 modes after a chord, and alone, on main
chord   modes  the same ten voicings as alone the others, as read
C       23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
Am      23     19                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant
G7      23     21                             lydian dominant: mode lydian, tags dominant; phrygian dominant: mode phrygian, tags dominant
Dm7     23     18                             harmonic minor: mode harmonic minor, tags minor; lydian dominant: mode lydian, tags dominant; melodic minor: mode melodic minor, tags minor; phrygian dominant: mode phrygian, tags dominant; whole tone: mode whole tone, tags tone
modes alone: 18 of 23 answer with every score 0.0000, all the same ten voicings: yes, the index's first ten: yes
  x-x-x-0-0-0 Em/G, x-x-x-0-0-1 G7(shell), x-x-x-0-0-2 Gmaj7(shell), x-x-x-0-0-3 G + B (Major 3rd), x-x-x-0-1-0 C/G, x-x-x-0-1-1 Csus4/G, x-x-x-0-1-2 C5/G, x-x-x-0-1-3 C5, x-x-x-0-2-0 Dbdim/G, x-x-x-0-2-1 Gm7b5
  harmonic minor: mode harmonic minor, tags minor, top score 0.0577
  lydian dominant: mode lydian, tags dominant, top score 0.0577
  melodic minor: mode melodic minor, tags minor, top score 0.0577
  phrygian dominant: mode phrygian, tags dominant, top score 0.0577
  whole tone: mode whole tone, tags tone, top score 0.0577
```

- **Un modo no cambia nada.** "C Lydian" devuelve los mismos diez voicings que "C". Los únicos modos que cambian una respuesta son los que leen un tag. MODAL se calcula a partir de las notas del acorde, y el nombre del modo se queda en `interpreted`.
- **Un modo a secas devuelve los diez primeros voicings del índice.** Sin acorde ni tag, todas las particiones de la consulta son cero: 18 de los 23 modos reciben una puntuación de 0 para todos los voicings, y la búsqueda devuelve los diez primeros que lee. `HasIntent` cuenta un modo como algo que buscar ([líneas 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)), así que la herramienta nunca da la respuesta que tiene prevista para una consulta que no sabe leer, "No chord, mode, or known tag recognized" (no se ha reconocido ningún acorde, modo ni tag conocido) ([líneas 155-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L155-L177)). El propio vocabulario cuenta con las "STRUCTURE and/or MODAL partitions" para ordenar los voicings ([`VoicingVocabularyTool.cs` líneas 72-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L72-L76)), y solo un acorde las rellena.

## Los tags

La skill presenta los tags como técnica y estilo, "drop2, shell, jazz, rootless" ([`SKILL.md` línea 3](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L3)). El programa añade cada uno de los 188 tags a tres acordes:

```text
== The 188 symbolic tags after a chord, at the pin
chord   tags   different answers  the same ten as the chord alone  bits whose tags all answer alike
Cmaj7   188    7                  53                               12 of 12
Dm7     188    7                  53                               12 of 12
G7      188    5                  76                               12 of 12
for Cmaj7, the bits whose tags change nothing: 3, 4, 5, 10
for Cmaj7, jazz and rock-guitar: the same answer yes
for Cmaj7, shell-voicing and rootless: the same answer yes
for Cmaj7, jazz and shell-voicing: the same answer no
```

```text
== The 188 symbolic tags after a chord, on main
chord   tags   different answers  the same ten as the chord alone  bits whose tags all answer alike
Cmaj7   188    5                  76                               12 of 12
Dm7     188    4                  53                               12 of 12
G7      188    3                  135                              12 of 12
for Cmaj7, the bits whose tags change nothing: 3, 4, 5, 8, 10
for Cmaj7, jazz and rock-guitar: the same answer yes
for Cmaj7, shell-voicing and rootless: the same answer yes
for Cmaj7, jazz and shell-voicing: the same answer yes
```

- **En el commit fijado, los 188 tags dan siete respuestas para Cmaj7 y para Dm7, y cinco para G7,** entre ellas la propia respuesta del acorde. Dentro de cada bit, los tags que se leen tal como están escritos dan todos la misma respuesta: `jazz` responde como `rock-guitar`, y `shell-voicing` como `rootless`. En `main` hay todavía menos respuestas, y `jazz` y `shell-voicing` también dan la misma respuesta para Cmaj7.
- **Algunos bits no cambian nada.** Para Cmaj7, los tags de los bits 3, 4, 5 y 10, entre ellos `caged-system`, `legato` y las formas CAGED, dejan la respuesta como estaba; en `main`, se les suma el bit 8.

`rootless` y `shell-voicing` proceden de la misma categoría de `SemanticNomenclature.yaml`, Structure, y activan el bit 0 ([líneas 129-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/SemanticNomenclature.yaml#L129-L140)). Un voicing rootless deja fuera la fundamental del acorde. El programa pregunta por diez acordes de séptima seguidos de "rootless", y cuenta los voicings del índice que tocan tres notas o más, todas del acorde y ninguna su fundamental:

```text
== "rootless" after a seventh chord, at the pin
chord   ten voicings, rootless rootless in the index  the first three
Cmaj7   0 of 10                63                     x-2-2-x-1-x Cmaj7(shell)/B, 0-2-x-x-1-x Cmaj7(shell)/E, 0-2-2-x-1-x Cmaj7(shell)/E
Dm7     0 of 10                35                     x-3-3-x-3-x Dm7(shell)/C, 1-3-x-x-3-x Dm7(shell)/F, 1-3-0-x-x-x Dm7(shell)/F
Em7     0 of 10                35                     x-x-x-0-3-0 Em7(shell)/G, x-x-0-0-x-0 Em7(shell)/D, x-x-0-0-3-0 Em7(shell)/D
Fmaj7   0 of 10                35                     x-x-2-2-x-1 Fmaj7(shell)/E, 0-x-3-2-x-1 Fmaj7(shell)/E, 0-0-3-x-x-1 Fmaj7(shell)/E
G7      0 of 10                19                     x-2-3-x-x-3 G7(shell)/B, 1-x-x-x-0-3 G7(shell)/F, 1-x-x-0-0-3 G7(shell)/F
Am7     0 of 10                63                     3-3-x-2-x-x Am7(shell)/G, x-3-2-2-x-x Am/C, 0-3-x-2-x-x Am/E
C7      0 of 10                35                     x-x-2-3-1-x C7(shell)/E, x-1-2-x-1-x C7(shell)/Bb, 0-x-x-3-1-x C7(shell)/E
D7      0 of 10                15                     2-3-x-x-3-x D7(shell)/Gb, 2-3-0-x-x-x D7(shell)/Gb, 2-3-0-x-3-x D7(shell)/Gb
E7      0 of 10                5                      x-x-x-1-3-0 E7(shell)/Ab, 0-x-0-1-3-0 E7(shell), x-x-0-1-x-0 E7(shell)/D
A7      0 of 10                21                     3-0-x-2-x-x G + A (Major 2nd), 3-x-2-2-x-x A5/G, 3-0-2-2-x-x A5/G
voicings answered 100: rootless 0
```

```text
== "rootless" after a seventh chord, on main
chord   ten voicings, rootless rootless in the index  the first three
Cmaj7   0 of 10                63                     x-2-2-x-1-3 Cmaj7/B, x-3-2-x-0-3 Cmaj7, x-3-2-0-0-3 Cmaj7
Dm7     0 of 10                35                     x-3-0-2-3-1 Dm7/C, 1-3-x-2-3-x Dm7/F, 1-3-x-2-3-1 Dm7/F
Em7     0 of 10                35                     x-2-0-0-x-0 Em7/B, x-2-0-0-0-0 Em7/B, x-2-0-0-3-0 Em7/B
Fmaj7   0 of 10                35                     1-0-3-2-1-0 Fmaj7, x-3-2-2-x-1 Fmaj7/C, x-3-2-2-1-1 Fmaj7/C
G7      0 of 10                19                     x-2-3-0-3-1 G7/B, 1-2-x-x-3-3 G7/F, 1-2-x-0-3-1 G7/F
Am7     0 of 10                63                     x-3-2-2-1-3 Am7/C, 0-3-x-2-1-3 Am7/E, 0-3-2-2-1-3 Am7/E
C7      0 of 10                35                     x-x-2-3-1-3 C7/E, x-1-2-x-1-3 C7/Bb, x-1-2-0-1-3 C7/Bb
D7      0 of 10                15                     x-3-0-2-1-2 D7/C, 2-3-x-2-3-2 D7/Gb, 2-3-0-2-1-x D7/Gb
E7      0 of 10                5                      x-2-2-1-3-x E7/B, x-x-0-1-0-0 E7/D, x-2-x-1-3-0 E7/B
A7      0 of 10                21                     x-x-2-2-2-3 A7/E, x-0-x-0-2-0 A7, x-0-2-x-2-3 A7
voicings answered 100: rootless 0
```

- **Ninguno de los 100 voicings devueltos es rootless, ni en el commit fijado ni en `main`,** cuando el índice contiene entre 5 y 63 para cada acorde. En el commit fijado, las primeras respuestas son voicings que el análisis de GA llama shells, con la fundamental incluida. El tag solo puede mover SYMBOLIC, que vale 0.10 de la puntuación; la STRUCTURE de la consulta, que vale 0.45, contiene el acorde entero, fundamental incluida.

## Palabras leídas como tags

Una palabra se convierte en tag cuando contiene un tag o un tag la contiene; el vocabulario lo llama "substring fallback", un recurso a la subcadena ([`VoicingVocabularyTool.cs` líneas 58-61](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L58-L61)). El programa envía las propias consultas de ejemplo de GA, tomadas de la descripción de la herramienta, de la skill y del borrador en espera, y luego tres del curso:

```text
== GA's example queries, and words read as tags, at the pin
query                                     read as                            top score    words no tag spells, and the tag they match
Cmaj7 drop2 jazz                          chord Cmaj7, tags drop2 jazz       0.4938       drop2 → drop2voicings
F# Lydian                                 chord F#, mode Lydian              0.4810
Dm7                                       chord Dm7                          0.4585
something warm and mellow                 nothing                            none
show me Cmaj7 voicings                    chord Cmaj7                        0.4585
drop-2 Dm7                                chord Dm7, tags drop-2             0.4942       drop-2 → drop-2-voicings
rootless G7 shapes                        chord G7, tags rootless            0.5078
Lydian on guitar                          mode Lydian                        0.0000
jazz voicings                             tags jazz                          0.0577
shell voicings                            tags shell                         0.0707       shell → shell-voicing
voicings with a similar quality to F#m7b5 chord F#m7b5                       0.4368
something warm and dreamy                 tags dreamy                        0.0577
something jazzy in F minor for a ballad   chord F, mode minor, tags jazzy for 0.4810       jazzy → jazz, for → normal-form
Find me a mellow Cm9                      chord Cm9                          0.3887
Rootless Dm7 voicing                      chord Dm7, tags rootless           0.5085
Drop-2 voicing for Gmaj7                  chord Gmaj7, tags drop-2 for       0.4585       drop-2 → drop-2-voicings, for → normal-form
Bright open-position Em                   chord Em, tags bright              0.5310
the course's:
the best G7 voicing                       chord G7, tags the                 0.4578       the → pitch-axis-theory
what is a good Am7 voicing                chord Am7, tags what               0.4995       what → so-what-chord
a sad chord for the end of a song         tags sad for the end               0.0500       for → normal-form, the → pitch-axis-theory, end → beginner-friendly
```

- **Palabras corrientes se convierten en tags.** "for" coincide con `normal-form`, "the" con `pitch-axis-theory`, "what" con `so-what-chord` y "end" con `beginner-friendly`. Por eso el lector omite "chord" y "voicing", y también las palabras de menos de tres letras, "a", "me", "to" ([líneas 132-147](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L132-L147)); "for", "the", "what" y "end" pasan las dos guardas. Cada una activa un bit, y una vez normalizada la partición, un segundo bit rebaja el peso del primero: "G7 shell for" puntúa por debajo de "G7 shell". El propio ejemplo de la skill, "something jazzy in F minor for a ballad", lee "for" ([`SKILL.md` línea 33](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L33)).
- **Sin acorde, solo SYMBOLIC puede coincidir.** "Lydian on guitar", "jazz voicings" y "shell voicings" figuran entre los usos de la skill ([línea 19](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L19)), y puntúan 0, 0.0577 y 0.0707. La skill da "something warm and dreamy" como una consulta de la que el lector no saca nada, con resultados arbitrarios, "arbitrary results" ([línea 26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L26)); la herramienta lee `dreamy`, un tag, y puntúa 0.0577.
- **"something warm and mellow", el propio ejemplo de formulación vaga de la herramienta, no lee nada** y no devuelve ningún voicing ([línea 99](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L99)). Su `allowSampling` le pediría al modelo del cliente que la leyera ([líneas 109-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L109-L111)); el curso lo deja desactivado.

## Las puntuaciones

La skill explica las puntuaciones bajo "Why Scores Cluster 0.4–0.98": "STRUCTURE (0.45) + MORPHOLOGY (0.25) + CONTEXT (0.20) + SYMBOLIC (0.10) + MODAL (0.10)", y "Near-perfect matches across all partitions approach 1.0" (las coincidencias casi perfectas en todas las particiones se acercan a 1.0) ([líneas 94-96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L94-L96)); su ejemplo de respuesta puntúa 0.9831 ([línea 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L81)). El programa lee los pesos en `EmbeddingSchema` ([líneas 120-136](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L120-L136)) y pregunta por todas las fundamentales, a secas y con todas las cualidades:

```text
== The scores, at the pin
partitions a query fills: STRUCTURE 0.45, SYMBOLIC 0.10, MODAL 0.10, ROOT 0.05; always empty: MORPHOLOGY 0.25, CONTEXT 0.20
the highest score a query can reach: 0.70
chord queries 828: the highest top score 0.5250, for E5
  Cmaj7: 0.4585
  Cmaj7 jazz: 0.5085
  Cmaj7 drop2 jazz: 0.4938
  Cmaj7 shell dreamy jazz: 0.5451
  G7: 0.4578
  G7 shell: 0.5078
  G7 shell for: 0.4932
```

```text
== The scores, on main
partitions a query fills: STRUCTURE 0.45, SYMBOLIC 0.10, MODAL 0.10, ROOT 0.05; always empty: MORPHOLOGY 0.25, CONTEXT 0.20
the highest score a query can reach: 0.70
chord queries 828: the highest top score 0.6000, for A
  Cmaj7: 0.6000
  Cmaj7 jazz: 0.6447
  Cmaj7 drop2 jazz: 0.6577
  Cmaj7 shell dreamy jazz: 0.6775
  G7: 0.6000
  G7 shell: 0.6447
  G7 shell for: 0.6316
```

- **Ninguna consulta puede puntuar por encima de 0.70.** El codificador deja MORPHOLOGY y CONTEXT a cero, así que sus 0.45 nunca cuentan. Las 828 consultas de acordes llegan como máximo a 0.5250 en el commit fijado; en `main`, Cmaj7, G7 y A alcanzan 0.6000, la suma de los pesos de STRUCTURE, MODAL y ROOT, y solo los tags pueden añadir los últimos 0.10. El 0.9831 del ejemplo es inalcanzable.
- **Aquí, añadir `jazz` sube la puntuación.** La skill advierte de que un tag de estilo "currently *lowers* the score" (actualmente *baja* la puntuación) porque los voicings del índice no tienen bits de estilo ([línea 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L47)). Sobre el índice que escribe el código del commit fijado, "Cmaj7 jazz" puntúa por encima de "Cmaj7", en el commit fijado y en `main`. El índice del curso no es el índice de producción de GA, donde la advertencia puede seguir siendo válida.
- **La advertencia de la skill sobre "drop2" está desfasada.** "`drop2` does NOT match — use `drop-2-voicings`" ([línea 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L39)); con las copias sin guiones del registro, "drop2" se lee como un tag.

## El borrador de skill que la llamaría

`skills-dev/_pending-tools/voicing-search/DRAFT.md` es una skill del chatbot escrita para la búsqueda de voicings, en espera como las de las lecciones 19 y 20 ([`skills-dev/_pending-tools/README.md` línea 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L47)). Llama a otra herramienta, `ga_search_voicings_by_query` ([líneas 22-26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22-L26)):

- esa herramienta está en `GaMcpServer`, en `VoicingEmbeddingTool.cs`, y envía la consulta a GaApi, que calcula su embedding con Ollama ([líneas 93-132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L93-L132)); el curso no puede ejecutarla sin conexión;
- el borrador dice que aún no está implementada, "not yet implemented in Common/GA.Business.ML/Agents/Mcp/" ([línea 22](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22)), y remite a `Common/GA.Business.ML/Agents/Mcp/VoicingMcpTools.cs` ([línea 83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L83)), un archivo que GA no tiene en ninguno de los dos commits;
- espera `topK`, `instrument` y una respuesta de `Results` con `contextTags` y `sourceCorpus` ([líneas 35-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L35-L44)), cuando la herramienta recibe `query` y `limit` y devuelve la respuesta de GaApi;
- su ejemplo de respuesta para "mellow Cm9" puntúa 0.91 y muestra un voicing con tres tags ([líneas 57-68](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L57-L68)):

```text
== The parked draft's example answer for "mellow Cm9", at the pin
x-3-5-3-3-3 plays C G A# D G; Cm9 is C D D# G A#, and the voicing leaves out D#
its tag low-density: in the vocabulary no, read as chord Cm9
its tag rootless-on-bass: in the vocabulary no, read as chord Cm9, tags rootless-on-bass
its tag quartal-flavour: in the vocabulary no, read as chord Cm9
```

El voicing no tiene tercera menor: su diagrama llama E♭ al tercer traste de la cuerda G y D al de la E aguda, cuando tocan B♭ y G. Ninguno de sus tres tags está en el vocabulario.

## Hasta dónde llega el curso

- **El índice es el de la lección 3,** 15.360 voicings de guitarra en los tres primeros trastes, no el índice de producción de GA: allí las respuestas y las puntuaciones pueden ser otras; las lecturas no dependen del índice.
- **No se prueba el filtro de instrumento:** el índice del curso solo contiene voicings de guitarra.
- **`allowSampling` sigue desactivado,** y no se ejecuta `ga_search_voicings_by_query`: los dos necesitan un modelo.
- **La prueba de rootless es la del curso,** sobre las notas que toca cada voicing.
- **El programa llama directamente a los métodos de las herramientas,** no a través de un cliente MCP y del servidor de GA.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#795](https://github.com/GuitarAlchemist/ga/issues/795): el modo que se lee y se descarta, los 188 tags en 12 bits que no filtran, las palabras reconocidas por subcadena, los scores y las advertencias de la skill voicing-search, y el borrador de skill en espera.

## Ejercicios

1. "Lydian on guitar" devuelve diez voicings, todos con una puntuación de 0. ¿Por qué no responde la herramienta que no sabe leer la consulta, y por qué estos diez?
2. En el commit fijado, "G7 shell" puntúa 0.5078 y "G7 shell for", 0.4932, con "G7" en 0.4578. ¿De dónde vienen las dos diferencias?
3. `jazz` y `rock-guitar` dan la misma respuesta para Cmaj7. ¿Por qué, y qué otros tags la dan también?
4. La respuesta del borrador en espera para "mellow Cm9" es `x-3-5-3-3-3`. ¿Qué nota de Cm9 deja fuera, y en qué convierte eso al acorde?

<details>
<summary>Soluciones</summary>

1. `HasIntent` cuenta el modo "Lydian" como algo que buscar ([líneas 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)), así que la herramienta busca. El codificador ignora el modo, así que el vector de consulta es cero, todos los voicings puntúan 0, y la búsqueda se queda con los diez primeros que lee, los diez primeros del índice.
2. "shell" lee `shell-voicing`, del bit 0: SYMBOLIC suma 0.5078 − 0.4578 = 0.0500. "for" lee `normal-form`, del bit 10. Tras la normalización, los dos bits de la consulta pesan 1/√2 cada uno, así que el bit 0 ya solo suma 0.0500/√2, y el bit 10, nada: 0.4578 + 0.0354 = 0.4932.
3. Activan el mismo bit, el 7, la categoría Genre del registro, y la partición SYMBOLIC de la consulta es el mismo vector. `flamenco` y `neo-soul`, los otros dos tags del bit, dan también esa respuesta: el programa comprobó que los tags de cada bit, leídos tal como están escritos, responden igual.
4. Toca C G A# D G: deja fuera D#, es decir E♭, la tercera menor. Sin tercera, no es ni menor ni mayor: es un C9 sin tercera.

</details>

## Puntos clave

- Un lector que reconoce una palabra no es una búsqueda que la use: el modo se lee, se imprime en `interpreted` y se descarta.
- 188 tags repartidos en 12 bits son 12 palabras para la búsqueda, no 188.
- Un tag que nombra una propiedad no es un filtro: hay que comprobar las respuestas contra esa propiedad.
- Comparar por subcadena convierte palabras corrientes en señales.
- Un rango de puntuaciones documentado se puede contrastar con los pesos que una consulta puede rellenar.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/VoicingSearchTool.cs`, `GaMcpServer/Tools/VoicingVocabularyTool.cs`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs`, `Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs`, `Common/GA.Business.Config/SemanticNomenclature.yaml`, `.claude/skills/voicing-search/SKILL.md`, `skills-dev/_pending-tools/voicing-search/DRAFT.md`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): las mismas herramientas, el mismo lector y el mismo registro, y la búsqueda de la lección 16.
- Los programas del curso: `code/ga-ai/GaAi/Lesson21.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SearchVoicingsProbe.cs`, `code/ga-ai/Shared/SearchIndex.cs`.
