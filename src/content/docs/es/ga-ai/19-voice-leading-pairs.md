---
title: "Lección 19: Los pares de voicings"
description: "El servidor MCP de Guitar Alchemist ofrece a los agentes ga_voice_leading_pair, una herramienta que empareja voicings tocables de dos acordes a partir del índice OPTIC-K; el chatbot no la llama. El curso le plantea los diez ejemplos de la lección 18, en el commit fijado y con la búsqueda del main de GA. En el commit fijado, 3 de los 10 primeros pares tocan los dos acordes; en main, los 10, y cada uno es el que menos mueve de todos los pares del índice que los tocan. La herramienta no comprueba nada de lo que empareja: con 50 candidatos, en el commit fijado responde de C a Am con los mismos tres E a ambos lados, a 0 semitonos. Su distancia es la mínima entre voicings con el mismo número de notas, empareja las notas más graves cuando ese número difiere, y sus diagramas empiezan por la E aguda."
sidebar:
  label: 19. Los pares de voicings
  order: 19
---

La [lección 18](../18-voice-leading/) le preguntó al chatbot cómo pasar de un acorde al siguiente. Su skill respondió con clases de altura, sin octava ni traste, y la lección se detuvo ante otra vía de GA, una que mueve voicings reales. Esta lección la ejecuta. `ga_voice_leading_pair` es una herramienta de `GaMcpServer`, el servidor MCP de GA, cuyas herramientas pueden llamar agentes como Claude Code. Dados dos cifrados, le pide al índice OPTIC-K de la [lección 3](../03-index-and-search/) 15 voicings de cada acorde, mide cada par con una distancia en semitonos y devuelve los cinco pares de menor distancia ([`CompositionTools.cs` líneas 179-268](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L268)). El chatbot no la llama: sus propias herramientas son otras, y la skill redactada para llamar a esta está en espera ([`skills-dev/_pending-tools/README.md` líneas 19-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L19-L29)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. `CompositionTools.cs` es idéntico en el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), pero la búsqueda a la que llama cambió después del commit fijado, como mostró la [lección 16](../16-the-voicings-of-a-chord/). El programa compila el archivo de la herramienta de cada clon de GA en los dos programas del curso y lo apunta al índice de la lección 3: en `GaAi`, al del commit fijado, y en `GaMain`, al índice que el código de `main` escribe a partir del mismo corpus. La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l19
dotnet run --project code/ga-ai/GaMain -c Release -- l19
```

## Cómo responde la herramienta

`SearchByChordAsync` lee el cifrado con `ChordPitchClasses`, el lector de la lección 16, lo convierte en un vector de consulta y le pide al índice los voicings más cercanos ([líneas 278-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L278-L298)):

```csharp
    private static async Task<SearchOutcome> SearchByChordAsync(
        string chordSymbol, int limit, string? instrument, CancellationToken ct)
    {
        if (!ChordPitchClasses.TryParse(chordSymbol.Trim(), out var rootPc, out var pcs) || rootPc is null)
            return new([], $"unrecognized chord symbol '{chordSymbol}'");

        var structured = new StructuredQuery(
            ChordSymbol: chordSymbol.Trim(),
            RootPitchClass: rootPc,
            PitchClasses: pcs,
            ModeName: null,
            Tags: null);

        var vec = EncoderShared.Value.Encode(structured);
        var strategy = GetStrategy();
        var hits = string.IsNullOrWhiteSpace(instrument)
            ? await strategy.SemanticSearchAsync(vec, limit, ct)
            : await strategy.HybridSearchAsync(vec, new VoicingSearchFilters(VoicingType: instrument), limit, ct);

        return new(hits, null);
    }
```

La consulta no nombra ningún acorde: cuando no se indica instrumento, los candidatos son los voicings cuyos vectores están más cerca de la consulta, toquen lo que toquen. `GetStrategy` toma la búsqueda de `VoicingSearchTool`, la herramienta de búsqueda del servidor, leyendo su campo privado `Strategy` ([líneas 300-310](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L300-L310)). Esa clase encuentra el índice mediante `GA_OPTICK_INDEX_PATH` o en `state/voicings/` ([`VoicingSearchTool.cs` líneas 64-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L83)). El curso compila esa clase a partir del código fuente de GA y la dirige al índice de la lección 3 mediante `GA_OPTICK_INDEX_PATH` (`code/ga-ai/Shared/SearchIndex.cs`).

La herramienta mide cada par de candidatos con `VoiceLeadingDistance` ([líneas 312-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L336)):

```csharp
    /// <summary>
    ///     Sum of absolute semitone differences under greedy ascending-pitch matching.
    ///     For voicings of unequal note count, the shorter one pairs against its nearest
    ///     neighbors and the remainder contributes a small per-note penalty (simulating
    ///     "voice appears from silence" / "voice disappears"). This is not a formal
    ///     Hungarian-optimal assignment — it's O(n log n) and produces a ranking good
    ///     enough to surface smooth voice-leadings among candidates.
    /// </summary>
    private static double VoiceLeadingDistance(IReadOnlyList<int> midi1, IReadOnlyList<int> midi2)
    {
        if (midi1.Count == 0 || midi2.Count == 0) return double.MaxValue;

        var a = midi1.OrderBy(n => n).ToArray();
        var b = midi2.OrderBy(n => n).ToArray();
        var common = Math.Min(a.Length, b.Length);

        double sum = 0;
        for (var i = 0; i < common; i++)
            sum += Math.Abs(a[i] - b[i]);

        // Penalty for unmatched voices (extra notes on either side).
        var extras = Math.Abs(a.Length - b.Length);
        sum += extras * 3.0;  // soft penalty — 3 semitones per orphan note.
        return sum;
    }
```

La distancia ordena las notas MIDI de los dos voicings, las empareja de la más grave hacia arriba, suma las diferencias y cuenta 3 semitonos por cada nota que queda sin pareja. Luego la herramienta ordena los pares por distancia y, en caso de empate, por la suma de sus dos puntuaciones de búsqueda ([líneas 224-235](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L224-L235)).

## Los candidatos

El programa pide los candidatos de los 14 acordes de los diez prompts de ejemplo de `VoiceLeadingSkill` (lección 18) y compara cada voicing con el acorde tal como lo escribe un manual, como hizo la lección 16: **exact** cuando el voicing toca las notas del acorde y ninguna otra, **more** cuando las toca junto con otras, **part** cuando solo toca algunas, **other** en cualquier otro caso. Un acorde de séptima al que solo le falta la quinta justa recibe su propio veredicto, **no fifth**: los voicings shell omiten la quinta, y un guitarrista los usa para tocar el acorde. El curso da por correctos los veredictos exact y no fifth. El programa cuenta también los voicings exactos de cada acorde en todo el índice:

```text
== The 15 candidates the tool pairs for each chord, at the pin, against the chord a textbook spells
chord    exact   no fifth   more   part   other   exact in the index  first exact candidate
C        10      0          0      5      0       63                  rank 1
F        15      0          0      0      0       35                  rank 1
Am       3       0          0      10     2       35                  rank 1
G7       0       15         0      0      0       49                  none
Cmaj7    5       3          0      7      0       42                  rank 4
Dm7      0       5          0      10     0       25                  none
G        15      0          0      0      0       35                  rank 1
Em       15      0          0      0      0       63                  rank 1
A7       0       2          0      7      6       35                  none
Fmaj7    0       15         0      0      0       60                  none
Bm7b5    4       0          0      11     0       25                  rank 1
D        7       0          0      5      3       27                  rank 1
A        5       0          0      5      5       21                  rank 11
C7       1       12         0      2      0       49                  rank 15
candidates 210: exact 80, no fifth 52, more 0, part 62, other 16
```

- **En el commit fijado, 80 de los 210 candidatos son exactos, y a otros 52 solo les falta la quinta.** G7, Dm7, A7 y Fmaj7 no reciben ningún voicing exacto entre sus 15, aunque el índice contiene 49, 25, 35 y 60, respectivamente. G7 y Fmaj7 reciben, eso sí, 15 voicings sin la quinta. A recibe su primer voicing exacto en el puesto 11, y C7, en el 15.
- **Los demás tocan una parte del acorde, u otras notas.** Para C, 5 de los 15 tocan una parte, como el C5 de la tabla siguiente, que no tiene E.

```text
== The 15 candidates the tool pairs for each chord, on main, against the chord a textbook spells
chord    exact   no fifth   more   part   other   exact in the index  first exact candidate
C        15      0          0      0      0       63                  rank 1
F        15      0          0      0      0       35                  rank 1
Am       15      0          0      0      0       35                  rank 1
G7       15      0          0      0      0       49                  rank 1
Cmaj7    15      0          0      0      0       42                  rank 1
Dm7      15      0          0      0      0       25                  rank 1
G        15      0          0      0      0       35                  rank 1
Em       15      0          0      0      0       63                  rank 1
A7       15      0          0      0      0       35                  rank 1
Fmaj7    15      0          0      0      0       60                  rank 1
Bm7b5    15      0          0      0      0       25                  rank 1
D        15      0          0      0      0       27                  rank 1
A        15      0          0      0      0       21                  rank 1
C7       15      0          0      0      0       49                  rank 1
candidates 210: exact 210, no fifth 0, more 0, part 0, other 0
```

- **En `main`, los 210 candidatos son exactos.** La herramienta es la misma; la búsqueda a la que llama solo devuelve voicings del acorde pedido, para cada uno de los 14 acordes.

## El primer par

Para cada prompt, el programa comprueba los dos voicings del primero de los cinco pares, y cuenta los pares, entre los cinco, cuyos dos voicings son correctos. También busca en todo el índice el par de voicings exactos que menos mueve según la propia distancia de la herramienta, y da el movimiento mínimo de la lección 18, en clases de altura. El programa escribe cada diagrama en el orden de los diagramas de acordes, empezando por la E grave:

```text
== The tool's first pair for each prompt, at the pin, and the smoothest pair of exact voicings in the index
prompt         first pair: from                           to                                   both right   smoothest exact pair in the index    least in pitch classes
C → F          5: x-3-x-0-1-x C5, part                    x-3-x-2-1-1 F/C, exact               4 of 5       3: x-x-x-0-1-0 → x-x-x-2-1-1         3
C → Am         3: x-3-2-x-1-x C + E (Major 3rd), part     x-3-2-2-x-x Am/C, exact              0 of 5       2: x-x-x-0-1-0 → x-x-x-2-1-0         2
G7 → Cmaj7     3: x-2-3-x-0-3 G7(shell)/B, no fifth       x-2-x-0-1-3 C5/B, part               1 of 5       3: x-x-0-0-0-1 → x-3-x-0-0-0         3
Dm7 → G7       6: x-3-3-x-3-x Dm7(shell)/C, no fifth      x-2-3-x-x-3 G7(shell)/B, no fifth    5 of 5       3: x-x-0-2-1-1 → x-x-0-0-0-1         3
C → G          6: x-x-2-0-1-x C/E, exact                  x-x-0-0-0-3 G/D, exact               4 of 5       3: x-x-2-x-1-3 → x-x-0-x-0-3         3
Em → A7        5: 3-x-2-x-0-0 Em/G, exact                 3-x-2-2-x-x A5/G, part               0 of 5       4: x-x-2-0-0-3 → x-x-2-2-2-3         4
Fmaj7 → Bm7b5  4: 0-0-3-x-x-x Fmaj7(shell)/E, no fifth    1-0-3-x-0-x Bm7b5/F, part            1 of 5       3: x-x-2-2-1-1 → x-x-0-2-0-1         3
D → A          4: x-0-x-2-3-x D5, part                    x-0-x-2-2-0 A, exact                 0 of 5       3: x-x-x-2-3-2 → x-x-x-2-2-0         3
C7 → F         4: x-3-x-3-1-x Bb + C (Major 2nd), part    x-3-x-2-1-1 F/C, exact               4 of 5       4: x-x-2-3-1-3 → x-x-3-2-1-1         4
G7 → C         5: x-x-3-0-0-3 G7(shell)/F, no fifth       x-x-2-0-1-x C/E, exact               5 of 5       4: x-x-0-0-0-1 → x-x-2-0-1-0         4
prompts 10: first pair right on both sides 3, moves more than the smoothest exact pair 8; that pair moves the least in pitch classes 10
the first pair for C → F, as the tool returns it: diagram x-1-0-x-3-x → 1-1-2-x-3-x
```

- **En el commit fijado, 3 de los 10 primeros pares tocan los dos acordes.** C → F parte de `x-3-x-0-1-x`, un C5 que toca C y G pero no E. Em → A7 termina en `3-x-2-2-x-x`, A y E sobre G, sin C♯.
- **En 8 casos, el primer par mueve más que un par de voicings correctos del índice.** C → G recibe dos voicings exactos que mueven 6 semitonos, mientras que `x-x-2-x-1-3` → `x-x-0-x-0-3` mueve 3: ese par no está entre los 15 candidatos de C y de G.
- **El par exacto que menos mueve alcanza el movimiento mínimo de la lección 18 en los diez prompts.** En el corpus de la lección 3, los voicings reales se mueven tan poco como lo permiten las clases de altura.

```text
== The tool's first pair for each prompt, on main, and the smoothest pair of exact voicings in the index
prompt         first pair: from                           to                                   both right   smoothest exact pair in the index    least in pitch classes
C → F          3: x-x-x-0-1-0 C/G, exact                  x-x-x-2-1-1 F/A, exact               5 of 5       3: x-x-x-0-1-0 → x-x-x-2-1-1         3
C → Am         2: x-x-x-0-1-0 C/G, exact                  x-x-x-2-1-0 Am, exact                5 of 5       2: x-x-x-0-1-0 → x-x-x-2-1-0         2
G7 → Cmaj7     3: x-x-0-0-0-1 G7/D, exact                 x-3-x-0-0-0 Cmaj7, exact             5 of 5       3: x-x-0-0-0-1 → x-3-x-0-0-0         3
Dm7 → G7       3: x-x-0-2-1-1 Dm7, exact                  x-x-0-0-0-1 G7/D, exact              5 of 5       3: x-x-0-2-1-1 → x-x-0-0-0-1         3
C → G          3: x-x-2-x-1-3 C/E, exact                  x-x-0-x-0-3 G/D, exact               5 of 5       3: x-x-2-x-1-3 → x-x-0-x-0-3         3
Em → A7        4: x-x-2-0-0-3 Em, exact                   x-x-2-2-2-3 A7/E, exact              5 of 5       4: x-x-2-0-0-3 → x-x-2-2-2-3         4
Fmaj7 → Bm7b5  3: x-x-2-2-1-1 Fmaj7/E, exact              x-x-0-2-0-1 Bm7b5/D, exact           5 of 5       3: x-x-2-2-1-1 → x-x-0-2-0-1         3
D → A          3: x-x-x-2-3-2 D/A, exact                  x-x-x-2-2-0 A, exact                 5 of 5       3: x-x-x-2-3-2 → x-x-x-2-2-0         3
C7 → F         4: x-x-2-3-1-3 C7/E, exact                 x-x-3-2-1-1 F, exact                 5 of 5       4: x-x-2-3-1-3 → x-x-3-2-1-1         4
G7 → C         4: x-x-0-0-0-1 G7/D, exact                 x-x-2-0-1-0 C/E, exact               5 of 5       4: x-x-0-0-0-1 → x-x-2-0-1-0         4
prompts 10: first pair right on both sides 10, moves more than the smoothest exact pair 0; that pair moves the least in pitch classes 10
the first pair for C → F, as the tool returns it: diagram 0-1-0-x-x-x → 1-1-2-x-x-x
```

- **En `main`, cada primer par toca los dos acordes, y es el par de voicings exactos que menos mueve en todo el índice.** Los cinco pares de cada prompt son correctos.
- **La herramienta devuelve sus diagramas empezando por la E aguda, también en `main`.** La última línea da el primer par de C → F tal como lo devuelve la herramienta: `0-1-0-x-x-x` es `x-x-x-0-1-0` leído desde la E aguda. El índice escribe primero la cuerda 1 (diferencia 13 de la entrada del 2026-09-14 del [diario](../journal/)). En `main`, la skill de voicings pasa esa cadena al orden de los diagramas de acordes antes de responder ([`ChordVoicingsSkill.cs` línea 136 en `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)), pero la herramienta devuelve la cadena del índice tal cual ([`CompositionTools.cs` líneas 239-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L239-L254)). Un cliente que lea `0-1-0-x-x-x` como un diagrama de acordes pone los dedos en las cuerdas equivocadas.

## Cincuenta candidatos

La descripción de `candidatesPerChord` promete "Higher = more exhaustive pair search, slower" (más alto = búsqueda de pares más exhaustiva, más lenta) ([línea 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L195)). El programa vuelve a preguntar con 50 candidatos por acorde, el máximo que admite la herramienta ([línea 203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L203)):

```text
== The first pair with 50 candidates per chord, the most the tool allows, at the pin
prompt         distance   from         to           first pair
C → F          3          part         part         0-x-2-x-x-0 E (unison) → 1-x-3-x-x-1 F (unison)
C → Am         0          part         part         0-x-2-x-x-0 E (unison) → 0-x-2-x-x-0 E (unison)
G7 → Cmaj7     3          no fifth     part         x-2-3-x-0-3 G7(shell)/B → x-2-x-0-1-3 C5/B
Dm7 → G7       3          other        part         1-x-3-0-3-x G5/F → 1-x-3-0-x-x F + G (Major 2nd)
C → G          0          part         part         3-x-x-0-x-3 G (unison) → 3-x-x-0-x-3 G (unison)
Em → A7        0          other        part         x-0-x-0-x-0 A5 → x-0-x-0-x-0 A5
Fmaj7 → Bm7b5  1          part         other        0-x-3-x-1-x F5/E → 0-x-3-x-0-x E5
D → A          2          part         part         x-0-x-2-3-x D5 → x-0-x-2-x-0 A5
C7 → F         4          part         exact        x-3-x-3-1-x Bb + C (Major 2nd) → x-3-x-2-1-1 F/C
G7 → C         2          part         part         1-x-x-0-x-3 F + G (Major 2nd) → 3-x-x-0-x-3 G (unison)
prompts 10: first pair right on both sides 0
```

- **En el commit fijado, ningún primer par toca los dos acordes.** C → Am recibe `0-x-2-x-x-0` a ambos lados: la cuerda E grave, la cuerda D en el segundo traste y la cuerda E aguda, tres E. E es una nota de los dos acordes, y ninguna voz se mueve. C → G y Em → A7 también reciben el mismo voicing a ambos lados.
- **La distancia premia el movimiento, no el acorde.** Una búsqueda más amplia trae unísonos y quintas vacías, que mueven menos, y la herramienta no comprueba nada de lo que empareja.

```text
== The first pair with 50 candidates per chord, the most the tool allows, on main
prompt         distance   from         to           first pair
C → F          3          exact        exact        x-x-x-0-1-0 C/G → x-x-x-2-1-1 F/A
C → Am         2          exact        exact        x-x-x-0-1-0 C/G → x-x-x-2-1-0 Am
G7 → Cmaj7     2          more         more         x-2-2-0-3-1 G7/B → x-2-2-0-1-1 Cmaj7/B
Dm7 → G7       3          exact        exact        x-x-0-2-1-1 Dm7 → x-x-0-0-0-1 G7/D
C → G          3          exact        exact        x-x-2-x-1-3 C/E → x-x-0-x-0-3 G/D
Em → A7        4          exact        exact        x-x-2-0-0-3 Em → x-x-2-2-2-3 A7/E
Fmaj7 → Bm7b5  3          exact        exact        x-x-2-2-1-1 Fmaj7/E → x-x-0-2-0-1 Bm7b5/D
D → A          2          more         more         x-x-0-2-2-2 Dmaj7 → x-x-0-2-2-0 Aadd11/D
C7 → F         4          exact        exact        x-x-2-3-1-3 C7/E → x-x-3-2-1-1 F
G7 → C         4          exact        exact        x-x-0-0-0-1 G7/D → x-x-2-0-1-0 C/E
prompts 10: first pair right on both sides 8
```

- **En `main`, el primer par toca los dos acordes en 8 prompts, y en los otros dos toca además otras notas.** G7 → Cmaj7 mueve `x-2-2-0-3-1` a `x-2-2-0-1-1` con 2 semitonos, donde 15 candidatos daban 3: el primero añade E a G7, y el segundo, F a Cmaj7. D → A mueve un Dmaj7 a un A con un D, con 2 en lugar de 3.
- **Tanto en el commit fijado como en `main`, más candidatos sacrifican el acorde a cambio de menos movimiento.**

## La distancia

La descripción de la herramienta dice que su emparejamiento es "good enough for retrieval ranking, not a formal Hungarian-optimal assignment" (suficiente para ordenar resultados de búsqueda, no una asignación formal óptima según el algoritmo húngaro) ([líneas 180-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L180-L185)), y el comentario de documentación dice que un voicing con menos notas "pairs against its nearest neighbors" (se empareja con sus vecinos más cercanos) ([líneas 312-319](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L319)). El programa compara la distancia, en cada par que la herramienta mide para los diez prompts, con el movimiento mínimo entre todas las maneras de emparejar las notas. Cuando el número de notas difiere, el mínimo elige qué notas del voicing con más notas emparejar, y suma los mismos 3 semitonos por cada nota sin pareja:

```text
== The tool's distance on every pair it weighs for the ten prompts, at the pin, against the least motion
pairs of equal size 867: the distance is the least over every pairing 867
pairs of unequal size 1383: the distance is the least over every choice of notes 593
the largest gap, 39 semitones: 0-2-2-0-0-0 Em [40 47 52 55 59 64] → x-x-x-2-2-3 A7(shell) [57 61 67], distance 55, least 16
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **Entre voicings con el mismo número de notas, la distancia siempre es la mínima.** Emparejar las notas ordenadas es imbatible cuando el coste es la suma de las diferencias: dos voces que se cruzan nunca mueven menos que las mismas dos sin cruzarse. Aquí la descripción subestima el emparejamiento.
- **Cuando el número de notas difiere, la herramienta empareja las notas más graves, no las más cercanas, y 593 de 1383 pares reciben el mínimo.** De Em `0-2-2-0-0-0` al voicing shell de A7 `x-x-x-2-2-3`, la herramienta empareja las tres notas más graves de Em con A, C♯ y G, a una octava o más por encima: 55 semitonos con la penalización. Emparejar las tres más agudas mueve 16.
- **En estos diez prompts, la distancia más pequeña no cambia.** Con el mínimo en su lugar, ningún primer par movería menos, ni en el commit fijado ni en `main`.

```text
== The tool's distance on every pair it weighs for the ten prompts, on main, against the least motion
pairs of equal size 890: the distance is the least over every pairing 890
pairs of unequal size 1360: the distance is the least over every choice of notes 340
the largest gap, 39 semitones: x-x-2-x-0-3 Em [52 59 67] → 0-0-2-x-2-3 A7/E [40 45 52 61 67], distance 47, least 8
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **En `main`, 340 de 1360 pares con distinto número de notas reciben el mínimo,** y la mayor diferencia vuelve a ser de 39 semitonos, de un Em de tres notas a un A7 de cinco.

## El borrador de skill que la llamaría

`skills-dev/_pending-tools/voice-leading/DRAFT.md` es una skill del chatbot escrita para llamar a `ga_voice_leading_pair` ([líneas 1-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L1-L25)). Su nombre de archivo la mantiene fuera del chatbot: el cargador de skills solo lee archivos llamados `SKILL.md`, y el README deja el borrador en espera hasta que la herramienta exista entre las del propio chatbot ([README líneas 1-17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L1-L17)). El borrador describe una herramienta distinta de la de `CompositionTools.cs`:

- un argumento `optimize`, `"minimum_movement"` o `"common_tones"`, que la herramienta no recibe, y `VoiceMovements`, `TotalSemitones` y `CommonTones` en la respuesta, cuando la herramienta devuelve pares de voicings con una distancia ([líneas 31-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L31-L44));
- "a Plücker-line / minimum-displacement solution" (una solución por líneas de Plücker / de desplazamiento mínimo) ([línea 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L29)), cuando la herramienta ordena notas MIDI;
- una referencia cruzada a `Common/GA.Business.ML/Agents/Mcp/HarmonyMcpTools.cs` ([línea 74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L74)), un archivo que GA no tiene ni en el commit fijado ni en `main`;
- un ejemplo de respuesta de Dm7 a G7 que anuncia un movimiento total de 2 semitonos y luego enumera cuatro movimientos de 0, 0, 2 y 1 ([líneas 54-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L54-L60)). Suman 3, la distancia del primer par de la herramienta en `main` y el movimiento mínimo de la lección 18.

## Hasta dónde llega el curso

- **El corpus es el de la lección 3,** 15.360 voicings en tres trastes, no el índice de producción. Entre más voicings, los candidatos y los pares podrían ser otros (*por verificar*).
- **El programa llama directamente al método de la herramienta,** no a través de un cliente MCP y del servidor de GA.
- **Los veredictos leen clases de altura.** El curso da por correcto un acorde de séptima sin quinta, duplique la nota que duplique, y no juzga ni la digitación ni el registro.
- **Solo se comprueba en detalle el primer par.** El programa cuenta los pares correctos entre los cinco, pero no mide cómo los reordena el fallo de la distancia.

## Comunicado upstream

- Se comunicaron después de escribir esta lección, en la issue de GA [#791](https://github.com/GuitarAlchemist/ga/issues/791): los voicings que la herramienta nunca comprueba, la distancia entre voicings con distinto número de notas, el orden de los diagramas y el borrador de skill en espera.

## Ejercicios

1. Con 50 candidatos, en el commit fijado, la herramienta responde a C → Am con `0-x-2-x-x-0` a ambos lados, a 0 semitonos. ¿Qué toca ese voicing, y por qué una distancia de 0 no es aquí ninguna respuesta?
2. Calcula la distancia de la herramienta de Em `0-2-2-0-0-0`, notas MIDI 40 47 52 55 59 64, al voicing shell de A7 `x-x-x-2-2-3`, notas MIDI 57 61 67. ¿Qué emparejamiento mueve 16?
3. En el commit fijado, a los 15 candidatos de G7 solo les falta la quinta. ¿Qué notas tocan, y cómo llama la lección 16 a un voicing así?
4. La herramienta recibe un instrumento, "guitar | bass | ukulele". ¿Qué responde sobre el índice del curso para "bass"?

<details>
<summary>Soluciones</summary>

1. Tres E: la cuerda E grave al aire, la cuerda D en el segundo traste y la cuerda E aguda al aire. E es una nota tanto de C como de A menor, así que el voicing toca una parte de cada uno y ninguno de los dos acordes. La consulta no nombra ningún acorde, y en el commit fijado este voicing está entre los 50 más cercanos a las dos consultas. Emparejado consigo mismo mueve 0, y nada en la herramienta comprueba lo que toca. En `main`, el primer par de C → Am con 50 candidatos mueve 2 y toca los dos acordes.
2. Ordenadas, las tres notas del A7 se emparejan con las tres más graves de Em: 40 → 57 son 17, 47 → 61 son 14 y 52 → 67 son 15, es decir, 46, más 3 por cada una de las tres notas sin pareja: 55. Emparejadas con las tres más agudas, 55 → 57, 59 → 61 y 64 → 67 mueven 2 + 2 + 3 = 7, más 9: 16.
3. G, B y F, la fundamental, la tercera y la séptima, nada más: el shell de la lección 16. En la tabla del primer par, los nombres que les da el índice empiezan por "G7(shell)".
4. El error "no voicings retrieved for one or both chords" (no se ha recuperado ningún voicing para uno de los acordes o para los dos) ([líneas 214-221](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L214-L221)): el índice del curso solo contiene voicings de guitarra, así que el filtro no conserva ninguno. Con "guitar", los primeros pares son los mismos que sin instrumento. Comprobado ejecutando la herramienta del commit fijado, fuera de la salida esperada del curso.

</details>

## Puntos clave

- Ordenar por movimiento solo ordena el movimiento: una herramienta que empareja lo que devuelve una búsqueda tiene que comprobar lo que tocan los voicings, o fiarse de la búsqueda.
- Más candidatos pueden empeorar la respuesta cuando los vecinos más cercanos se alejan del acorde.
- Emparejar las notas ordenadas da el movimiento mínimo entre voicings con el mismo número de notas; cuando ese número difiere, elegir qué notas emparejar es la parte que necesita una búsqueda.
- El orden de la cadena de un diagrama es un contrato: un consumidor del índice lo corrigió, otro lo transmite tal cual.
- Una herramienta que puede llamar un agente no es una herramienta que pueda llamar el chatbot, y un borrador escrito para un registro puede describir una herramienta que no existe en ninguno de los dos.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `GaMcpServer/Tools/CompositionTools.cs`, `GaMcpServer/Tools/VoicingSearchTool.cs`, `skills-dev/_pending-tools/voice-leading/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): la misma herramienta y los mismos borradores, la búsqueda de la lección 16, `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson19.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/VoiceLeadingPairProbe.cs`, `code/ga-ai/Shared/SearchIndex.cs`.
