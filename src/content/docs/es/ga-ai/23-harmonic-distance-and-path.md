---
title: "Lección 23: La distancia y el camino armónicos"
description: "GrothendieckDeltaSkill e IcvShortestPathSkill son las dos skills del chatbot de Guitar Alchemist para una pareja de acordes: la primera da la diferencia de sus vectores interválicos, la segunda una cadena de conjuntos de clases de altura de uno a otro. La primera da a dos acordes con el mismo vector una distancia de 1 y más color cromático, incluso de C a C; la segunda nunca une acordes de tamaños distintos, así que dos de sus propios prompts de ejemplo no obtienen ningún camino tras una búsqueda de cientos de conjuntos, y cuenta los conjuntos de un camino como sus pasos."
sidebar:
  label: 23. La distancia y el camino armónicos
  order: 23
---

La [lección 22](../22-similar-chords/) le pidió a `IcvNeighborsSkill` los conjuntos cercanos a un acorde. Dos skills registradas junto a ella reciben una pareja de acordes ([`GaPlugin.cs` líneas 100-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L100-L102)): `GrothendieckDeltaSkill` da la diferencia de sus vectores interválicos, sus normas L1 y L2 y un coste ([`GrothendieckDeltaSkill.cs` líneas 97-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L97-L131)), e `IcvShortestPathSkill`, una cadena de conjuntos de clases de altura de uno a otro ([`IcvShortestPathSkill.cs` líneas 9-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L9-L53)). Las dos llaman a `GrothendieckService`, y las dos tienen un `CanHandle` que siempre dice que no: el enrutador compara una pregunta con la descripción y los prompts de ejemplo de cada skill, le suma los refuerzos de las pistas y la envía a la de mayor puntuación si esa puntuación alcanza un umbral de confianza ([`SemanticIntentRouter.cs` líneas 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En el `main` de GA en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), las dos skills solo marcan su rechazo con `Declined`, `GrothendieckDelta` y `DefaultRoutingHintProvider` no han cambiado, y `FindNearby` compara el conjunto de origen con cada conjunto por valor; los propios conjuntos de clases de altura sí cambiaron, así que `GaMain` vuelve a preguntar. Su salida imprime las mismas tablas que la del commit fijado, bajo títulos que dicen "on main". La salida procede de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l23
dotnet run --project code/ga-ai/GaMain -c Release -- l23
```

## Cómo leen las skills una pregunta

La skill delta busca dos acordes unidos por "to", "and" o una flecha:

```csharp
    // Two-chord pattern shared with VoiceLeadingSkill — anchored on
    // "<chord A> to/and <chord B>" with a permissive chord token. Pre-anchored
    // by routing hint, so substring overlap with unrelated phrases is unlikely.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|and|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

La skill de camino pide "shortest path", "shortest route", "harmonic path", "step by step" o algunas palabras más, y después dos acordes unidos por "to", o bien "how do I get from" seguido de dos acordes y luego "harmonic":

```csharp
    // "shortest path / harmonic path / route from A to B"
    private static readonly Regex PathPattern =
        new(@"\b(?:shortest(?:[\s-]*harmonic)?[\s-]*(?:path|route)|harmonic[\s-]*(?:path|route)|BFS\s+path|step[\s-]*by[\s-]*step|PC[\s-]*set\s+path|ICV\s+path|harmonic\s+route)\b[^.?!]*?\b(?:from\s+)?(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Fallback — "how do I get from X to Y harmonically"
    private static readonly Regex HowDoIGetPattern =
        new(@"\bhow\s+do\s+i\s+get\s+from\s+(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+to\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b[^.?!]*?\bharmonic",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Los prompts de ejemplo de las dos skills se reformularon el 2026-06-16 para mantenerlas separadas. La skill de camino conserva dos comentarios al respecto, el segundo escrito encima del primero sin quitarlo ([líneas 55-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L55-L66)).

## Las formulaciones de GA

El programa le hace a cada skill sus diez prompts de ejemplo, las formulaciones de su comentario de documentación y las dos que sugiere su rechazo, le hace las mismas preguntas a la otra skill, y le pregunta a `DefaultRoutingHintProvider` qué intenciones reforzaría cada una:

```text
== GrothendieckDeltaSkill's and IcvShortestPathSkill's example prompts and GA's other phrasings for them, at the pin
prompt                                           skill   from          its answer       the other's      routing hints, +0.06 each
how harmonically far is Am from D7               delta   anchor        declined         declined         skill.grothendieckdelta
harmonic distance from Cmaj7 to G7               delta   anchor        Cmaj7 → G7       declined         skill.grothendieckdelta
how far apart are Cmaj7 and Dm7 harmonically     delta   anchor        Cmaj7 → Dm7      declined         none
harmonic cost to move from C to G                delta   anchor        C → G            declined         skill.transpose
how different are C major and F major harmonically delta   anchor        declined         declined         none
harmonic distance between Am and Em              delta   anchor        Am → Em          declined         skill.grothendieckdelta
how close are Cmaj7 and Fmaj7 harmonically       delta   anchor        Cmaj7 → Fmaj7    declined         none
L1 distance from Gmaj7 to Bm7b5                  delta   anchor        Gmaj7 → Bm7b5    declined         none
Grothendieck delta from C to F                   delta   anchor        C → F            declined         skill.grothendieckdelta
measure the harmonic gap between Dm7 and G7      delta   anchor        Dm7 → G7         declined         none
shortest harmonic path from Cmaj7 to G7          path    anchor        Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
shortest path from C major to F major            path    anchor        declined         declined         skill.icvshortestpath
shortest harmonic route from Am to D7            path    anchor        Am → D7          Am → D7          skill.icvshortestpath
shortest path from Cmaj7 to Bm7b5                path    anchor        Cmaj7 → Bm7b5    Cmaj7 → Bm7b5    skill.icvshortestpath
step-by-step harmonic route from C to G          path    anchor        C → G            C → G            skill.icvshortestpath
shortest chord path from Dm7 to Gmaj7            path    anchor        declined         Dm7 → Gmaj7      none
shortest route from C to A minor                 path    anchor        C → A            C → A            skill.icvshortestpath
harmonic stepping stones from Cmaj7 to Fmaj7     path    anchor        declined         Cmaj7 → Fmaj7    none
shortest path from Gmaj7 to Em                   path    anchor        Gmaj7 → Em       Gmaj7 → Em       skill.icvshortestpath
shortest harmonic path of chords from C to F     path    anchor        C → F            C → F            skill.icvshortestpath
Harmonic distance from Cmaj7 to G7               delta   doc comment   Cmaj7 → G7       declined         skill.grothendieckdelta
Grothendieck delta C to F                        delta   doc comment   C → F            declined         skill.grothendieckdelta
How harmonically far is Am from D7               delta   doc comment   declined         declined         skill.grothendieckdelta
Compare the ICVs of Cmaj7 and Dm7                delta   doc comment   Cmaj7 → Dm7      declined         none
harmonic distance from Cmaj7 to G7               delta   refusal       Cmaj7 → G7       declined         skill.grothendieckdelta
delta C to F                                     delta   refusal       C → F            declined         none
Shortest harmonic path from Cmaj7 to G7          path    doc comment   Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
Path from C major to F major                     path    doc comment   declined         declined         none
How do I get from Am to D7 harmonically          path    doc comment   Am → D7          Am → D7          none
shortest path from Cmaj7 to G7                   path    refusal       Cmaj7 → G7       Cmaj7 → G7       skill.icvshortestpath
how do I get from C to F harmonically            path    refusal       C → F            C → F            none
GrothendieckDeltaSkill: anchors 10, answered 8, hinted toward skill.grothendieckdelta 4; the other skill answers 0 of them; CanHandle accepts 0
IcvShortestPathSkill: anchors 10, answered 7, hinted toward skill.icvshortestpath 8; the other skill answers 9 of them; CanHandle accepts 0
```

- **La skill delta responde a 8 de sus 10 prompts de ejemplo.** "how harmonically far is Am from D7", que también es la primera formulación de su comentario de documentación, pone "from" entre los acordes, y "how different are C major and F major harmonically" pone "major" entre el primer acorde y "and".
- **La skill de camino responde a 7 de sus 10.** "shortest path from C major to F major", que también figura en su comentario de documentación como "Path from C major to F major", tiene "major" detrás de cada acorde; "shortest chord path from Dm7 to Gmaj7" pone "chord" entre "shortest" y "path"; "harmonic stepping stones from Cmaj7 to Fmaj7" no tiene ni "path" ni "route". De los siete a los que responde, dos no obtienen ningún camino y uno se lee como A mayor, como muestran las secciones siguientes.
- **La skill delta responde a 9 de los 10 prompts de la skill de camino,** ya que le basta con dos acordes cualesquiera unidos por "to"; la skill de camino no responde a ninguno de los de la delta. Una pregunta de camino formulada como estos prompts que el enrutador envíe a la skill delta recibe una distancia, no un rechazo.
- **Las reglas de las pistas refuerzan 4 de los prompts de la skill delta y 8 de los de la skill de camino** ([`DefaultRoutingHintProvider.cs` líneas 128-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L128-L144)). "harmonic cost to move from C to G" refuerza en cambio a `skill.transpose`, cuya regla lee "move … to" y una letra mayúscula ([líneas 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)).

## Los acordes que leen

Las dos skills construyen sus conjuntos con una copia de la tabla que leyó la lección 22 ([`GrothendieckDeltaSkill.cs` líneas 133-173](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L133-L173), [`IcvShortestPathSkill.cs` líneas 165-201](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L165-L201)). El programa construye los acordes de la lección 22 y las 16 cualidades con las tablas de las tres skills, y después les pregunta por parejas de acordes:

```text
== The chords the two skills read, at the pin
chord tokens 36: built alike by IcvNeighborsSkill, GrothendieckDeltaSkill and IcvShortestPathSkill 36
prompt                                     skill   read as      first built    second built   right
harmonic distance from C major to F major  delta   declined     -              -              no
harmonic distance from C to A minor        delta   C → A        C E G          C# E A         no
harmonic distance from Cmaj7 to a G7       delta   Cmaj7 → a    C E G B        C# E A         no
harmonic distance between CM7 and G7       delta   CM7 → G7     C D# G A#      D F G B        no
harmonic distance from C° to C+            delta   C° → C       C D# F#        C E G          no
shortest path from C major to F major      path    declined     -              -              no
shortest route from C to A minor           path    C → A        C E G          C# E A         no
shortest path from C to a G                path    C → a        C E G          C# E A         no
shortest path from CM7 to G7               path    CM7 → G7     C D# G A#      D F G B        no
```

- **Las tres tablas construyen los mismos conjuntos,** así que los errores de lectura de la lección 22 se repiten: CM7 se construye como C menor séptima, y una palabra detrás de la fundamental termina el acorde, así que "C to A minor", uno de los prompts de ejemplo de la skill de camino, pide A mayor.
- **"a" también es un acorde aquí:** "from Cmaj7 to a G7" pide la distancia hasta A mayor, y "from C to a G", un camino hasta A mayor.
- **° se conserva en el primer acorde, no en el segundo.** Al primer acorde solo le hace falta un espacio detrás, y al segundo un límite de palabra, así que "C° to C+" se lee como de C disminuido a C mayor.

## Los deltas

La skill delta da lo que devuelve `ComputeDelta`, a través de `GrothendieckDelta.FromIcVs`:

```csharp
    public static GrothendieckDelta FromIcVs(IntervalClassVector source, IntervalClassVector target)
    {
        var delta = new GrothendieckDelta
        {
            Ic1 = target[IntervalClass.Hemitone] - source[IntervalClass.Hemitone],
            Ic2 = target[IntervalClass.Tone] - source[IntervalClass.Tone],
            Ic3 = target[IntervalClass.FromValue(3)] - source[IntervalClass.FromValue(3)],
            Ic4 = target[IntervalClass.FromValue(4)] - source[IntervalClass.FromValue(4)],
            Ic5 = target[IntervalClass.FromValue(5)] - source[IntervalClass.FromValue(5)],
            Ic6 = target[IntervalClass.Tritone] - source[IntervalClass.Tritone]
        };

        // Heuristic: When two distinct sets share the same ICV (e.g., diatonic modes/keys),
        // L1 difference is zero. To preserve musical differentiation expected by callers/tests,
        // emit a minimal non-zero delta focused on ic1. This keeps related keys close but not identical.
        if (delta.L1Norm == 0)
        {
            delta = delta with { Ic1 = 1 };
        }

        return delta;
    }
```

El programa le pregunta a la skill delta por cada pareja de sus prompts de ejemplo en los dos sentidos y por dos acordes frente a sí mismos, y después por cada pareja ordenada de los 192 acordes de 12 fundamentales y 16 cualidades:

```text
== The deltas GrothendieckDeltaSkill gives, at the pin
pair             first vector    second vector   L1     the skill's delta      L1   L2      cost   its interpretation
Cmaj7 → G7       <1 0 1 2 2 0>   <0 1 2 1 1 1>   6      [-1, +1, +1, -1, -1, +1] 6    2.449   3.60   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd), -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ more chromatic color
G7 → Cmaj7       <0 1 2 1 1 1>   <1 0 1 2 2 0>   6      [+1, -1, -1, +1, +1, -1] 6    2.449   3.60   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd), +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more chromatic color
Cmaj7 → Dm7      <1 0 1 2 2 0>   <0 1 2 1 2 0>   4      [-1, +1, +1, -1, 0, 0] 4    2.000   2.40   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd) â†’ more chromatic color
Dm7 → Cmaj7      <0 1 2 1 2 0>   <1 0 1 2 2 0>   4      [+1, -1, -1, +1, 0, 0] 4    2.000   2.40   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd) â†’ more chromatic color
C → G            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
G → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Am → Em          <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Em → Am          <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Cmaj7 → Fmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Fmaj7 → Cmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Gmaj7 → Bm7b5    <1 0 1 2 2 0>   <0 1 2 1 1 1>   6      [-1, +1, +1, -1, -1, +1] 6    2.449   3.60   -1 ic1 (semitone), +1 ic2 (whole tone), +1 ic3 (minor 3rd), -1 ic4 (major 3rd), -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ more chromatic color
Bm7b5 → Gmaj7    <0 1 2 1 1 1>   <1 0 1 2 2 0>   6      [+1, -1, -1, +1, +1, -1] 6    2.449   3.60   +1 ic1 (semitone), -1 ic2 (whole tone), -1 ic3 (minor 3rd), +1 ic4 (major 3rd), +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more chromatic color
C → F            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
F → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Dm7 → G7         <0 1 2 1 2 0>   <0 1 2 1 1 1>   2      [0, 0, 0, 0, -1, +1]   2    1.414   1.20   -1 ic5 (perfect 4th), +1 ic6 (tritone) â†’ increased tension
G7 → Dm7         <0 1 2 1 1 1>   <0 1 2 1 2 0>   2      [0, 0, 0, 0, +1, -1]   2    1.414   1.20   +1 ic5 (perfect 4th), -1 ic6 (tritone) â†’ more consonant
C → C            <0 0 1 1 1 0>   <0 0 1 1 1 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
Cmaj7 → Cmaj7    <1 0 1 2 2 0>   <1 0 1 2 2 0>   0      [+1, 0, 0, 0, 0, 0]    1    1.000   0.60   +1 ic1 (semitone) â†’ more chromatic color
ordered pairs 36864: with the same vector 4320, answered L1 1 4320, delta [+1, 0, 0, 0, 0, 0] 4320; with different vectors 32544, L1 right 32544
pairs with different vectors 16272: "more chromatic color" both ways 1440
```

- **Dos acordes con el mismo vector están a 1 de distancia, con un semitono más.** Las parejas de C a G, de Am a Em, de Cmaj7 a Fmaj7 y de C al propio C reciben el delta `[+1, 0, 0, 0, 0, 0]`, un L1 de 1, un coste de 0.60 y "more chromatic color". Lo mismo ocurre con las 4320 parejas ordenadas de los 192 acordes que comparten un vector; las otras 32544 reciben su L1 correcto. La propia glosa de la respuesta dice que cada componente es "how many more occurrences of that interval-class the target has than the source" (cuántas apariciones más de esa clase de intervalo tiene el destino que el origen) ([líneas 122-128](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L122-L128)): G mayor no tiene más semitonos que C mayor. La skill de la lección 22 vuelve a calcular el delta para evitarlo ([`IcvNeighborsSkill.cs` líneas 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)); esta no. La heurística está comunicada en la issue de GA [#776](https://github.com/GuitarAlchemist/ga/issues/776).
- **La interpretación es la primera regla que coincide,** y la primera es "more semitones or whole tones" (más semitonos o tonos enteros) ([`GrothendieckDelta.cs` líneas 226-258](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L226-L258)). De Cmaj7 a G7 se gana un tono entero y de G7 a Cmaj7 un semitono, así que los dos sentidos reciben "more chromatic color", como les ocurre a 1440 de las 16272 parejas con vectores distintos.
- **La flecha que precede a la interpretación se imprime como `â†’`.** La línea 217 contiene los bytes de `→` leídos como Windows-1252 y guardados de nuevo como UTF-8 ([`GrothendieckDelta.cs` línea 217](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L217)); `main` tiene la misma línea.

## Los caminos

`FindShortestPath` es una búsqueda en anchura: desde cada conjunto, pasa a los conjuntos del mismo tamaño a un L1 de 2 como máximo que aún no ha visto, y se detiene tras cinco movimientos ([`GrothendieckService.cs` líneas 117-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L117-L163)):

```csharp
            // Check if we've exceeded max steps
            if (path.Count >= maxSteps + 1)
            {
                continue;
            }

            // Find nearby sets (within small distance) to keep the graph sparse and paths musically local.
            // Using radius=2 connects closely related diatonic collections (e.g., C major → G major)
            // that typically differ by one accidental yet may exceed radius=1 under the ICV L1 metric.
            var nearby = FindNearby(current, 2)
                .Select(r => r.Set)
                // Restrict traversal to sets with the same cardinality to avoid unrealistic one-step jumps
                .Where(s => s.Cardinality == current.Cardinality)
                .Where(s => !visited.Contains(s));

            foreach (var next in nearby)
            {
                visited.Add(next);
                var newPath = new List<PitchClassSet>(path) { next };
                queue.Enqueue((next, newPath));
            }
```

El programa le hace a la skill de camino los prompts de ejemplo a los que responde y cuatro parejas más, y cuenta, para cada camino, los movimientos, el L1 y las notas que se conservan en cada movimiento, y los movimientos entre dos conjuntos de un mismo vector:

```text
== The paths IcvShortestPathSkill finds, at the pin
pair             notes   the answer says                        moves  L1 per move  common notes   same vector
Cmaj7 → G7       4, 4    4 steps total (3 intermediate moves)   3      2,2,2        2,1,0          0
Am → D7          3, 4    No path found within 5 steps           0      -            -              0
Cmaj7 → Bm7b5    4, 4    4 steps total (3 intermediate moves)   3      2,2,2        2,1,0          0
C → G            3, 3    2 steps total (1 intermediate move)    1      0            1              1
C → A            3, 3    2 steps total (1 intermediate move)    1      0            1              1
Gmaj7 → Em       4, 3    No path found within 5 steps           0      -            -              0
C → F            3, 3    2 steps total (1 intermediate move)    1      0            1              1
C → C            3, 3    1 step total (0 intermediate moves)    0      -            -              0
C → Cm           3, 3    2 steps total (1 intermediate move)    1      0            2              1
Cdim7 → Cmaj7    4, 4    No path found within 5 steps           0      -            -              0
Caug → C         3, 3    No path found within 5 steps           0      -            -              0
before "No path" for Am → D7: sets expanded 168 of the 220 of 3 notes, each a scan of the 4096 sets
before "No path" for Gmaj7 → Em: sets expanded 462 of the 495 of 4 notes, each a scan of the 4096 sets
before "No path" for Cdim7 → Cmaj7: sets expanded 3 of the 495 of 4 notes, each a scan of the 4096 sets
before "No path" for Caug → C: sets expanded 4 of the 220 of 3 notes, each a scan of the 4096 sets
the path for "shortest harmonic path from Cmaj7 to G7":
  {0,4,7,11}   C E G B        4-20   <1 0 1 2 2 0>
  {0,2,3,7}    C D D# G       4-14   <1 1 1 1 2 0>  L1 2, common notes 2
  {0,1,4,6}    C C# E F#      4-Z15  <1 1 1 1 1 1>  L1 2, common notes 1
  {2,5,7,11}   D F G B        4-27   <0 1 2 1 1 1>  L1 2, common notes 0
```

- **Los acordes de tamaños distintos nunca se unen.** De Am a D7 y de Gmaj7 a Em, dos de los prompts de ejemplo de la skill, y "How do I get from Am to D7 harmonically", de su comentario de documentación, reciben "No path found within 5 steps", y la respuesta culpa a la distancia o a "the cardinality constraint" ([línea 137](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L137)). Antes de decirlo, la búsqueda expande 168 de los 220 conjuntos de tres notas, o 462 de los 495 conjuntos de cuatro, y cada expansión recorre los 4096 conjuntos, cuyos vectores se recalculan en cada lectura ([`PitchClassSet.cs` línea 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L104)); `FindNearby` guarda sus respuestas para 256 conjuntos ([`GrothendieckService.cs` línea 21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L21)).
- **La respuesta cuenta los conjuntos como pasos** ([línea 141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L141)). De Cmaj7 a G7 son "4 steps total (3 intermediate moves)": tres movimientos, a través de dos conjuntos. De C a G son "2 steps total (1 intermediate move)": un movimiento, a través de ninguno. De C a C es "1 step total".
- **Un movimiento entre dos conjuntos de un mismo vector cuenta como un paso.** Los caminos de C a G, de C a F, de C a Cm y de C a A requieren un movimiento cada uno: su L1 real es 0, que `FromIcVs` convierte en 1.
- **La respuesta no nombra ninguno de los conjuntos intermedios, y las notas se pierden.** El camino de Cmaj7 a G7 pasa por C D D# G y C C# E F#, 4-14 y 4-Z15, y conserva 2 notas, después 1 y después ninguna, cuando la respuesta promete "common-tone bridges" ([líneas 156-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L156-L160)). El de Cmaj7 a Bm7b5 da los mismos recuentos.
- **Cdim7 y Caug solo alcanzan sus propias transposiciones,** 3 y 4 conjuntos: la lección 22 no encontró ningún conjunto a un L1 de 1 o 2 de Cdim7 y solo conjuntos de dos notas de Caug, y la búsqueda conserva el tamaño, así que solo quedan los conjuntos con su vector.

## Hasta dónde llega el curso

- **No se ejecuta el enrutador:** necesita los embeddings. La lección les hace a las skills sus propios prompts de ejemplo: una pregunta formulada exactamente como uno de ellos es la que más probabilidades tiene de que se les envíe.
- **El recuento de conjuntos expandidos es el del curso,** procede de una búsqueda que sigue la regla de `FindShortestPath`; la skill no lo imprime. El programa no cronometra las skills.
- **El programa llama directamente a los métodos de las skills,** no a través del chatbot.

## Ejercicios

1. ¿Por qué rechaza la skill delta "how harmonically far is Am from D7"?
2. C mayor y G mayor tienen los dos el vector `<0 0 1 1 1 0>`. ¿Qué L1 los separa, y qué imprime la skill delta? ¿Qué línea marca la diferencia?
3. ¿Por qué no encuentra la skill de camino ningún camino de Am a D7?
4. El camino de Cmaj7 a G7 contiene cuatro conjuntos. ¿Cuántos movimientos hace, y a través de cuántos conjuntos intermedios? ¿Qué dice la respuesta?

<details>
<summary>Soluciones</summary>

1. Su expresión necesita "to", "and" o una flecha entre los dos acordes ([líneas 65-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L65-L67)); el prompt tiene "from".
2. 0. La skill imprime un L1 de 1 y el delta `[+1, 0, 0, 0, 0, 0]`, porque `FromIcVs` convierte un delta nulo en `Ic1 = 1` (líneas 128-131 del extracto anterior).
3. Am tiene tres notas y D7 cuatro, y la búsqueda solo pasa a conjuntos del mismo tamaño (línea 150 de `GrothendieckService.cs`), así que nunca llega a D7.
4. Tres movimientos, a través de dos conjuntos: C D D# G y C C# E F#. La respuesta dice "4 steps total (3 intermediate moves)".

</details>

## Puntos clave

- Una heurística colocada en un tipo compartido llega a todos los que lo usan: una skill la corrige, su hermana la imprime.
- Una distancia que nunca devuelve 0 no puede decir que dos acordes son semejantes.
- Una búsqueda que conserva el tamaño no puede unir acordes de tamaños distintos, y debería decirlo antes de buscar.
- Un recuento de pasos es un recuento de movimientos, no de las cosas que los movimientos unen.
- El mojibake de un archivo de código fuente acaba en las respuestas del chatbot.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga en [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a): las mismas skills, con sus rechazos marcados con `Declined`, y `GrothendieckDelta.cs`.
- Los programas del curso: `code/ga-ai/GaAi/Lesson23.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvDeltaPathProbe.cs`.
