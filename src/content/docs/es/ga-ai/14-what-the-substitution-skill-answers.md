---
title: "Lección 14: Lo que responde la skill de sustitución"
description: "El chatbot de Guitar Alchemist responde sin modelo a una petición de sustitución de acorde, a partir de la distancia entre vectores interválicos. El curso le hace a su skill los doce prompts de ejemplo, un acorde de cada cualidad en las 12 fundamentales y ocho parejas de acordes que nombra un manual. Para un acorde, la lista solo depende de la cualidad del acorde: cada acorde recibe los otros cinco miembros de su clase de conjuntos con las máscaras de bits más pequeñas, todos a un paso, y la lista de G7 no tiene Db7. Para dos acordes, las tríadas relativas y las tríadas a un tritono de distancia reciben las mismas etiquetas, y un acorde está a un paso de sí mismo. La closure del DSL que da respuestas de manual exige, a través de ga_dsl_eval, las entradas que su propio esquema llama opcionales."
sidebar:
  label: 14. Lo que responde la skill de sustitución
  order: 14
---

La [lección 12](../12-what-the-progression-skills-answer/) y la [lección 13](../13-what-the-progression-analysis-answers/) preguntaron por progresiones de acordes. Esta lección le pide al chatbot otro acorde: un sustituto para G7, la dominante secundaria de Am, una rearmonización de Dm7. El enrutador envía una pregunta así a la intención `skill.chordsubstitution`, que ejecuta `ChordSubstitutionSkill` ([`GaPlugin.cs` línea 41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L41)). La skill no llama a ningún modelo: para un acorde, enumera los acordes más cercanos según la distancia de Grothendieck, una distancia entre vectores interválicos, y para dos acordes nombra su relación. El chatbot tiene otras dos maneras de responder. La skill SKILL.md [`chord-substitution`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md), para la vía del modelo, le da al modelo dos herramientas MCP, `ga_chord_substitutions` y `ga_chord_compare`, cuyo código repite el de la skill de C#; sus funciones de lectura de acordes llevan el comentario "mirror ChordSubstitutionSkill" ([`ChordSubstitutionMcpTools.cs` línea 176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L176)). La closure `domain.chordSubstitutions` del DSL funciona de otra manera: ordena los acordes de una tonalidad por las notas que comparten con el acorde. La llama la herramienta `GaChordSubstitutions` de GaMcpServer ([`GaDslTool.cs` líneas 208-222](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L208-L222)), y también la herramienta que busca voicings más fáciles ([`GuitaristProblemTools.cs` líneas 602-605](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L602-L605)).

Todos los enlaces a GA apuntan al commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), el commit fijado del curso, salvo los que nombran otro. En `main`, en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordSubstitutionSkill.cs`, `ChordSubstitutionMcpTools.cs`, el SKILL.md, `GrothendieckDelta.cs`, `DslEvalMcpTools.cs` y `DefaultRoutingHintProvider.cs` no han cambiado. `GrothendieckService.FindNearby` solo ha cambiado en la comprobación que deja el conjunto de origen fuera de su propia lista, algo que la skill ya hace por su cuenta. La closure solo ha cambiado en cómo nombra los intervalos; el curso la compila en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), donde `DomainClosures.fs` es igual que en `main`, como en la lección 13. Las salidas proceden de:

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l14
```

## Los prompts de ejemplo de la propia skill

El programa arranca el host del chatbot como en la lección 12, toma la intención que elegiría el enrutador y le hace cada uno de sus prompts de ejemplo ([`ChordSubstitutionSkill.cs` líneas 35-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L35-L55)). La skill lee hasta dos cifrados de acorde en la pregunta; con dos, los compara; con uno, enumera sustitutos ([líneas 146-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L146-L160)):

```csharp
        // Try to extract up to two chord symbols (extended, includes 7th chords)
        var chords = ExtendedChordSymbol.Matches(message)
            .Select(TryParseChordMatch)
            .Where(c => c.HasValue)
            .Select(c => c!.Value)
            .Take(2)
            .ToList();

        if (chords.Count == 2)
            return Task.FromResult(ExecuteComparison(chords[0], chords[1]));

        // Single-chord path — original behaviour
        var parsed = ParseChord(message);
        if (parsed is null)
            return Task.FromResult(CannotHelp("Could not identify a chord symbol in your message."));
```

El programa imprime el tipo de respuesta y los acordes que nombra:

```text
== The skill's own example prompts
skill.chordsubstitution: ChordSubstitutionSkill, 12 example prompts
"Tritone substitution for G7"  CanHandle yes
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
  the textbook answer: Db7
"What can I substitute for Cmaj7 in a ii-V-I?"  CanHandle no
  list for Cmaj7: Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7
"Reharmonize Dm7 in a jazz context"  CanHandle no
  list for Dm7: Fm7 F#m7 Am7 Ebm7 Cm7
"Alternative chord for F major in C"  CanHandle yes
  compares F with C: Set-Class Equivalent, ICV Neighbor (L1 = 1)
"What's the secondary dominant of Am?"  CanHandle no
  list for Am: Cm C Ab Dbm Fm
  the textbook answer: E7
"Show me a backdoor dominant for C major"  CanHandle no
  list for C: Cm Ab Dbm Fm Db
  the textbook answer: Bb7
"Alternative chord for Cmaj7"  CanHandle yes
  list for Cmaj7: Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7
"What can replace Dm7?"  CanHandle no
  list for Dm7: Fm7 F#m7 Am7 Ebm7 Cm7
"Swap chord for G7"  CanHandle yes
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
"Modal interchange substitutes for C major"  CanHandle no
  list for C: Cm Ab Dbm Fm Db
"Borrow a chord from parallel minor"  CanHandle no
  Could not identify a chord symbol in your message.
"Modal interchange options in F major"  CanHandle no
  list for F: Cm C Ab Dbm Fm
CanHandle accepts 4 of 12
```

- **Se ignora la relación que nombra el prompt.** "Tritone substitution for G7" (sustitución por tritono de G7), "What's the secondary dominant of Am?" (¿cuál es la dominante secundaria de Am?) y "Show me a backdoor dominant for C major" (muéstrame una dominante backdoor para C mayor) leen un solo acorde y reciben la misma lista que cualquier pregunta sobre ese acorde. Ninguna de las tres listas nombra el acorde que da un manual: D♭7, E7, B♭7. La comparación de dos acordes conoce las tres relaciones; la lista, no.
- **Un nombre de tonalidad se lee como un acorde.** En "Alternative chord for F major in C" (acorde alternativo para F mayor en C), la skill lee F y C, así que compara F con C en lugar de ofrecer un acorde para F en la tonalidad de C.
- **"Borrow a chord from parallel minor"** (toma prestado un acorde de la menor homónima) no nombra ningún acorde y recibe el rechazo de la skill. La skill no tiene ninguna noción de tonalidad: el intercambio modal en C mayor recibe la lista del acorde de C mayor.

Cada skill tiene además `CanHandle`, una prueba sobre las palabras de la pregunta. En el commit fijado, el enrutador no la llama; en `main`, recurre a ella cuando no puede calcular el embedding de la pregunta, como mostró la lección 12 ([`SemanticIntentRouter.cs` línea 321 en `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). La prueba acepta 4 de los 12 prompts ([líneas 59-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L59-L75)):

```csharp
    private static readonly Regex SubstituteTrigger =
        new(@"\b(substitut|reharmoni|instead\s+of|alternative\s+chord|swap\s+chord|replace\s+chord)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Additional comparison keywords for the two-chord path
    private static readonly Regex TwoChordTrigger =
        new(@"\b(?:same|related|equivalent|tritone)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Extended chord symbol pattern — matches triads AND 7th chords (longer alternations first)
    private static readonly Regex ExtendedChordSymbol =
        new(@"\b(?<root>[A-G])(?<acc>[b#]?)(?<qual>m7b5|dim7|maj7|m7|7|min|m|dim|aug|\+)?(?!\w)",
            RegexOptions.Compiled);

    public bool CanHandle(string message) =>
        ExtendedChordSymbol.IsMatch(message) &&
        (SubstituteTrigger.IsMatch(message) || TwoChordTrigger.IsMatch(message));
```

`\b(substitut|reharmoni...)\b` exige un límite de palabra justo después de la raíz, y "substitute", "substitution" y "reharmonize" continúan todas con una letra: las dos raíces no coinciden nunca con una palabra. "Tritone substitution for G7" pasa gracias a "tritone", la palabra clave de la comparación; los dos prompts con "alternative chord" y "Swap chord for G7" pasan gracias a sus propias expresiones. Las pistas de enrutamiento que usa el enrutador escriben las raíces con `\w*` ([`DefaultRoutingHintProvider.cs` líneas 53-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L53-L56)), y el SKILL.md incluye "substitute", "secondary dominant", "backdoor" y "modal interchange" entre sus triggers ([`SKILL.md` líneas 8-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L8-L21)).

## Un acorde en las doce fundamentales

Para un acorde, la skill le pide a `FindNearby` todos los conjuntos de clases de altura a una distancia de 3 como máximo, se queda con los que tienen el tamaño del acorde, los ordena por coste y toma cinco ([líneas 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L164-L174)):

```csharp
        // Exclude the source from its own substitution list. The previous
        // ReferenceEquals check only worked if the catalog interned the EXACT
        // instance built locally — it doesn't, so the source could leak into
        // its own results. Compare by pitch-class mask instead (PR #85 fix).
        var sourceMask = sourceSet.PitchClassMask;
        var nearby = grothendieck.FindNearby(sourceSet, maxDistance: 3)
            .Where(r => r.Set.PitchClassMask != sourceMask
                        && r.Set.Cardinality == sourceSet.Cardinality)
            .OrderBy(r => r.Cost)
            .Take(5)
            .ToList();
```

`FindNearby` compara el vector interválico del acorde con los de los 4096 conjuntos de clases de altura de `PitchClassSet.Items`, en el orden de sus ids, de 0 a 4095, que son sus máscaras de bits ([`GrothendieckService.cs` líneas 55-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L55-L81), [`PitchClassSetId.cs` líneas 70-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)). El coste es la distancia L1 entre los vectores multiplicada por 0,6 ([líneas 38-42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L42)). El programa pregunta "Substitute for" (sustituto para) por cada una de las nueve cualidades que lee la skill, en las 12 fundamentales, escritas como las escribe la skill. Para seis cualidades, comprueba si la lista contiene uno de los dos sustitutos que da un manual: dos acordes a una tercera de distancia, que comparten dos notas con una tríada o tres con un acorde de séptima, o bien, para una séptima de dominante, su sustituto por tritono y la séptima semidisminuida una tercera por encima. También cuenta las notas que cada acorde de la lista comparte con el acorde por el que se pregunta:

```text
== One chord: "Substitute for <chord>" on the 12 roots
major (C ... B): the 12 lists name 6 chords, Cm Ab Dbm Fm Db C
  a textbook substitute listed for 5 of 12 roots, e.g. for C: Am, Em
  notes each listed chord shares with its source: 0 for 29, 1 for 22, 2 for 9
minor (Cm ... Bm): the 12 lists name 6 chords, C Ab Dbm Fm Db Cm
  a textbook substitute listed for 4 of 12 roots, e.g. for Cm: Eb, Ab
  notes each listed chord shares with its source: 0 for 28, 1 for 24, 2 for 8
dominant 7th (C7 ... B7): the 12 lists name 6 chords, Dm7b5 Ab7 F7 D7 Ebm7b5 F#m7b5
  a textbook substitute listed for 4 of 12 roots, e.g. for C7: F#7, Em7b5
  notes each listed chord shares with its source: 0 for 14, 1 for 20, 2 for 23, 3 for 3
major 7th (Cmaj7 ... Bmaj7): the 12 lists name 6 chords, Dbmaj7 Abmaj7 Fmaj7 Dmaj7 Amaj7 F#maj7
  a textbook substitute listed for 0 of 12 roots, e.g. for Cmaj7: Em7, Am7
  notes each listed chord shares with its source: 0 for 16, 1 for 22, 2 for 22
minor 7th (Cm7 ... Bm7): the 12 lists name 6 chords, Fm7 Dm7 F#m7 Am7 Ebm7 Cm7
  a textbook substitute listed for 0 of 12 roots, e.g. for Cm7: Ebmaj7, Abmaj7
  notes each listed chord shares with its source: 0 for 16, 1 for 21, 2 for 23
half-diminished (Cm7b5 ... Bm7b5): the 12 lists name 6 chords, Dm7b5 Ab7 F7 D7 Ebm7b5 F#m7b5
  a textbook substitute listed for 3 of 12 roots, e.g. for Cm7b5: Ab7, Ebm7
  notes each listed chord shares with its source: 0 for 16, 1 for 16, 2 for 25, 3 for 3
diminished (Cdim ... Bdim): the 12 lists name 6 chords, Dbdim Ddim Adim F#dim Ebdim Cdim
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 42, 2 for 18
augmented (Caug ... Baug): the 12 lists name 4 chords, Dbaug Daug Ebaug Caug
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 36
diminished 7th (Cdim7 ... Bdim7): the 12 lists name 3 chords, Dbdim7 Ddim7 Cdim7
  no textbook substitute of the same size
  notes each listed chord shares with its source: 0 for 24
Cost and L1 of every listed chord: cost 0.60, L1 1
ga_chord_substitutions returns the same chords, costs and L1 for 108 of 108 chords
ICV C <001110>, Am <001110>: ComputeDelta(...).L1Norm = 1
ICV C <001110>, F# <001110>: ComputeDelta(...).L1Norm = 1
ICV G7 <012111>, Db7 <012111>: ComputeDelta(...).L1Norm = 1
ICV C <001110>, C <001110>: ComputeDelta(...).L1Norm = 1
```

- **La lista solo depende de la cualidad.** Un acorde y todas sus transposiciones e inversiones tienen el mismo vector interválico: las 12 tríadas mayores y las 12 menores comparten uno, y las 12 séptimas de dominante comparten el suyo con las 12 séptimas semidisminuidas. Todos tienen el mismo coste, el más bajo, así que la lista toma los cinco con las máscaras de bits más pequeñas, en el orden de `PitchClassSet.Items`: `OrderBy` conserva el orden de los elementos iguales. Para cada cualidad, las doce listas nombran seis acordes, menos para la tríada aumentada y la séptima disminuida, que tienen cuatro y tres transposiciones.
- **La lista de G7 no tiene D♭7.** D♭7 está en la clase de conjuntos de G7, pero su máscara de bits es mayor que las de los cinco primeros. Las séptimas mayores y las séptimas menores no reciben nunca un sustituto de manual; las tríadas mayores y menores, las séptimas de dominante y las séptimas semidisminuidas solo lo reciben en las fundamentales cuyos sustitutos resultan estar entre los seis. De los 60 acordes enumerados para las tríadas mayores, 29 no comparten ninguna nota con su acorde de origen.
- **Todos los acordes tienen coste 0,60 y L1 1.** Las cuatro últimas líneas muestran por qué: C y Am tienen el mismo vector, igual que C y F♯, G7 y D♭7, y C y él mismo, pero `ComputeDelta` da 1. Cuando la diferencia es cero, `GrothendieckDelta.FromIcVs` escribe 1 en su primera componente ([`GrothendieckDelta.cs` líneas 125-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L125-L131)):

```csharp
        // Heuristic: When two distinct sets share the same ICV (e.g., diatonic modes/keys),
        // L1 difference is zero. To preserve musical differentiation expected by callers/tests,
        // emit a minimal non-zero delta focused on ic1. This keeps related keys close but not identical.
        if (delta.L1Norm == 0)
        {
            delta = delta with { Ic1 = 1 };
        }
```

- **La vía del SKILL.md recibe las mismas listas.** `ga_chord_substitutions` devuelve los mismos acordes, costes y L1 para los 108 acordes. El ejemplo del SKILL.md para Cmaj7 enumera Am7 con coste 0,50 y Em7 con 0,83 ([`SKILL.md` líneas 100-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L100-L104)); la herramienta enumera otras cinco séptimas mayores, y un coste de 0,6 × L1 no puede valer 0,50 ni 0,83.

## Dos acordes

Con dos acordes, la skill comprueba cinco relaciones, una tras otra, y añade una última etiqueta cuando no se cumple ninguna ([líneas 246-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L246-L298)). Las dos primeras:

```csharp
        var results = new List<SubstitutionRelationship>();
        var ab = (rootB - rootA + 12) % 12;   // semitones from A up to B
        var ba = (rootA - rootB + 12) % 12;   // semitones from B up to A

        // Tritone substitution: roots 6 semitones apart + both dominant 7ths
        if (ab == 6 && intervalsA.SequenceEqual(Dom7) && intervalsB.SequenceEqual(Dom7))
            results.Add(new("Tritone Substitution",
                $"Roots are 6 semitones (tritone) apart; both are dominant 7ths. " +
                $"The M3 of {nameA} equals the m7 of {nameB} and vice versa — guide tones are shared by inversion. " +
                $"Classic bebop move: both chords resolve to the same target by half-step."));

        // Secondary dominant: A is a P5 above B → A functions as V of B
        if (ba == 7)
            results.Add(new("Secondary Dominant",
                $"{nameA} is a perfect 5th above {nameB} — {nameA} functions as V (dominant) of {nameB}."));
```

El programa pregunta "How are A and B related?" (¿qué relación hay entre A y B?) por ocho parejas que nombra un manual, en las 12 fundamentales, y le pregunta a `ga_chord_compare` por las mismas parejas:

```text
== Two chords: "How are <A> and <B> related?" on the 12 roots
the same chord twice, e.g. C and C: common notes 3; textbook: the same chord
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
V7 and I, e.g. G7 and C: common notes 1; textbook: V7 of I
  12 of 12 roots: Secondary Dominant
  ga_chord_compare gives the same labels for 12 of 12
v and i, e.g. Gm and Cm: common notes 1; textbook: a minor v is not a dominant
  12 of 12 roots: Secondary Dominant, Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
bVII7 and I, e.g. Bb7 and C: common notes 0; textbook: backdoor dominant
  12 of 12 roots: Backdoor Dominant
  ga_chord_compare gives the same labels for 12 of 12
dominant 7ths a tritone apart, e.g. F#7 and C7: common notes 2; textbook: tritone substitution
  12 of 12 roots: Tritone Substitution, Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
relative minor and major, e.g. Am and C: common notes 2; textbook: relative chords
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
triads a tritone apart, e.g. F#m and C: common notes 0; textbook: no common note
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
viiø7 and V7, e.g. Em7b5 and C7: common notes 3; textbook: viiø7 is V9 without its root
  12 of 12 roots: Set-Class Equivalent, ICV Neighbor (L1 = 1)
  ga_chord_compare gives the same labels for 12 of 12
```

- **Tres relaciones son correctas en las 12 fundamentales:** V7 y I, bVII7 y I, y la sustitución por tritono.
- **Un v menor recibe la etiqueta de dominante secundaria.** La prueba solo lee el intervalo entre las fundamentales; Gm no es la dominante de Cm, lo son G o G7.
- **Las etiquetas no separan lo que separa un manual.** Am y C comparten dos notas; F♯m y C, ninguna; las dos parejas reciben "Set-Class Equivalent" y "ICV Neighbor (L1 = 1)", porque todas las tríadas mayores y menores están en una misma clase de conjuntos. Un acorde comparado consigo mismo también está "1 step(s) apart in ICV space" (a 1 paso en el espacio de ICV). Em7b5 y C7, que comparten tres notas, reciben las mismas dos etiquetas. El ejemplo de comparación del SKILL.md termina con "Also flagged as ICV Neighbor with L1 = 0" (marcado también como ICV Neighbor con L1 = 0) ([`SKILL.md` línea 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L108)), un valor que `FromIcVs` no devuelve nunca.

## Lo que la skill lee como acorde

El cifrado de acorde de la skill es una letra mayúscula de A a G, un `b` o un `#` opcionales, una cualidad opcional y ningún carácter de palabra detrás ([líneas 69-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L69-L71)). El programa hace cuatro preguntas más; la última es una entrada del corpus de prompts de GA ([`prompts.yaml` líneas 206-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L206-L209)):

```text
== What the skill reads as a chord
"A substitute for G7?"  CanHandle no, 200 characters
  compares A with G7: Harmonic Distance
"Substitute for B♭7"  CanHandle no, 254 characters
  list for B: Cm C Ab Dbm Fm
"Substitute for Cmin7"  CanHandle no, 50 characters
  Could not identify a chord symbol in your message.
"Suggest substitutions for G7 in a ii-V-I"  CanHandle no, 263 characters
  list for G7: Dm7b5 Ab7 F7 D7 Ebm7b5
SKILL.md: | `m7` / `min7` | minor 7 |
ga_chord_substitutions("Cmin7"): Could not parse 'Cmin7' as a chord symbol. Try Cmaj7, F#m, Bb7, etc.
```

- **"A substitute for G7?"** (¿un sustituto para G7?) El artículo "A" es un cifrado de acorde: la skill compara A mayor con G7.
- **B♭7** se lee como B mayor: `♭` no es `b`, ni es un carácter de palabra, así que el cifrado termina después de B. La skill de improvisación de la lección 7 leía el mismo signo de la misma manera ([#757](https://github.com/GuitarAlchemist/ga/issues/757)).
- **Cmin7** no se lee en absoluto, ni en la skill ni en la herramienta MCP ([`ChordSubstitutionMcpTools.cs` líneas 230-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L230-L232)), aunque la tabla de cifrados del SKILL.md incluye `min7`.
- **La entrada del corpus** solo pide una respuesta de al menos 100 caracteres, en menos de 60 segundos. La respuesta de la skill tiene 263 y ningún D♭7: la entrada pasa. La lección 8 envió este prompt a través del chat, donde falló con un HTTP 500 por falta de modelo.

## La closure que responde a partir de la tonalidad

`domain.chordSubstitutions` recibe un acorde, una tonalidad y una escala, se queda con los acordes diatónicos de la tonalidad que comparten una nota con el acorde, los ordena según ese recuento y añade el sustituto por tritono cuando el acorde tiene una tercera mayor y una séptima menor ([`DomainClosures.fs` líneas 535-621](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L535-L621)). El programa le pregunta a través de `ga_dsl_eval`, como lo haría una skill del chatbot, y ejecuta directamente la closure de `main`, como hace GaMcpServer:

```text
== domain.chordSubstitutions, through ga_dsl_eval at a826864 and as it is on main
input  key: string? — key root (e.g. 'C', 'G'). Defaults to chord root.
input  scale: string? — 'major' or 'minor'. Defaults to 'major'.
input  symbol: string — chord to substitute (e.g. 'Am', 'G7')
5 inputs of 15 closures are marked optional: domain.chordSubstitutions.key, domain.chordSubstitutions.scale, domain.queryChords.degree, domain.queryChords.hasInterval, domain.queryChords.quality
symbol=Am
  a826864  missing-required-arg: closure 'domain.chordSubs…' requires argument 'key' (declared type: string? — key root (e.g. 'C', 'G'). Defaults to chord root.)
  6baf32e  Substitutions for Am in key of A major:
             ★★  A      — 2 shared: A(P1/P1) E(P5/P5)
             ★   C#m    — 1 shared: E(P5/m3)
             ★   D      — 1 shared: A(P1/P5)
             ★   E      — 1 shared: E(P5/P1)
             ★   F#m    — 1 shared: A(P1/m3)
symbol=Am, key=C
  a826864  missing-required-arg: closure 'domain.chordSubs…' requires argument 'scale' (declared type: string? — 'major' or 'minor'. Defaults to 'major'.)
  6baf32e  Substitutions for Am in key of C major:
             ★★  C      — 2 shared: C(m3/P1) E(P5/M3)
             ★★  F      — 2 shared: A(P1/M3) C(m3/P5)
             ★   Dm     — 1 shared: A(P1/P5)
             ★   Em     — 1 shared: E(P5/P1)
symbol=Am, key=C, scale=major
  a826864  Substitutions for Am in key of C major:
             ★★  C      — 2 shared: C(m3/P1) E(P5/M3)
             ★★  F      — 2 shared: A(P1/M3) C(m3/P5)
             ★   Dm     — 1 shared: A(P1/P5)
             ★   Em     — 1 shared: E(P5/P1)
  6baf32e  the same
symbol=G7, key=C, scale=major
  a826864  Substitutions for G7 in key of C major:
             ★★★ Bdim   — 3 shared: B(M3/P1) D(P5/m3) F(m7/TT)
             ★★  Dm     — 2 shared: D(P5/P1) F(m7/m3)
             ★★  Em     — 2 shared: G(P1/m3) B(M3/P5)
             ★   C      — 1 shared: G(P1/P5)
             ★   F      — 1 shared: F(m7/P1)
             ◈  Db7    — tritone sub (shares guide tones enharmonically)
  6baf32e  Substitutions for G7 in key of C major:
             ★★★ Bdim   — 3 shared: B(M3/P1) D(P5/m3) F(m7/d5)
             ★★  Dm     — 2 shared: D(P5/P1) F(m7/m3)
             ★★  Em     — 2 shared: G(P1/m3) B(M3/P5)
             ★   C      — 1 shared: G(P1/P5)
             ★   F      — 1 shared: F(m7/P1)
             ◈  Db7    — tritone sub (shares guide tones enharmonically)
symbol=F#7, key=B, scale=major
  a826864  Substitutions for F#7 in key of B major:
             ★★★ A#dim  — 3 shared: Bb(M3/P1) Db(P5/m3) E(m7/TT)
             ★★  C#m    — 2 shared: Db(P5/P1) E(m7/m3)
             ★★  D#m    — 2 shared: F#(P1/m3) Bb(M3/P5)
             ★   B      — 1 shared: F#(P1/P5)
             ★   E      — 1 shared: E(m7/P1)
             ◈  C7     — tritone sub (shares guide tones enharmonically)
  6baf32e  Substitutions for F#7 in key of B major:
             ★★★ A#dim  — 3 shared: Bb(M3/P1) Db(P5/m3) E(m7/d5)
             ★★  C#m    — 2 shared: Db(P5/P1) E(m7/m3)
             ★★  D#m    — 2 shared: F#(P1/m3) Bb(M3/P5)
             ★   B      — 1 shared: F#(P1/P5)
             ★   E      — 1 shared: E(m7/P1)
             ◈  C7     — tritone sub (shares guide tones enharmonically)
```

- **Las entradas opcionales son obligatorias.** El esquema dice que `key` y `scale` son opcionales y da sus valores por defecto, pero `ga_dsl_eval` exige todas las entradas que declara el esquema ([`DslEvalMcpTools.cs` líneas 257-270](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L257-L270)): "everything in InputSchema is required for v0.1" (todo lo que figura en InputSchema es obligatorio en la v0.1). Un modelo que se fía del esquema y las omite recibe un error. Están en ese caso cinco entradas de dos de las 15 closures.
- **La tonalidad por defecto de un acorde menor es mayor.** Sin tonalidad, la closure toma la fundamental del acorde y la escala mayor ([líneas 557-559](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L557-L559)): Am recibe los acordes de A mayor, una tonalidad sin Am. La herramienta de GaMcpServer solo pasa la tonalidad cuando la tiene ([`GaDslTool.cs` líneas 218-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L218-L220)), y la herramienta de voicings más fáciles no la pasa nunca.
- **Con una tonalidad, las respuestas son las de un manual.** Para G7 en C mayor, B disminuido comparte tres notas y D♭7 es el sustituto por tritono; para Am, C y F comparten dos notas. La descripción de la herramienta en GaMcpServer promete otra cosa para Am en C mayor: "C (★★★, relative major), Em (★★, shared E/B), F (★, shared A)" (relativo mayor; E/B compartidas; A compartida) ([`GaDslTool.cs` línea 212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L212)). Em solo comparte E con Am, F comparte A y C, y tres estrellas exigen tres notas compartidas ([línea 614](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L614)).
- **F♯7 en B mayor** recibe A♯dim, C♯m y D♯m, escritos a partir de la tonalidad, pero las notas compartidas se escriben B♭ y D♭: las nombra `conventionalKeyName`, la causa de la [#770](https://github.com/GuitarAlchemist/ga/issues/770), que ya apareció en la lección 10. `main` nombra la quinta del acorde disminuido, F sobre B y E sobre A♯, `d5` en lugar de `TT`: es la única diferencia en estas ejecuciones.

## Hasta dónde llega el curso

- **No se ejecuta el modelo.** Saber si el enrutador semántico envía cada prompt de ejemplo a esta intención necesita los embeddings, y lo que escribe un modelo a partir de `ga_chord_substitutions` y `ga_chord_compare` necesita el modelo (*por verificar*).
- **Los sustitutos de manual son una elección.** Dos por cualidad, más el sustituto por tritono; la armonía de jazz conoce otros, y los recuentos solo valen para estos.
- **La skill y las herramientas no se ejecutan en `main`.** No han cambiado allí, como tampoco `GrothendieckDelta.cs`, y `FindNearby` solo difiere en la comprobación que deja fuera el conjunto de origen; que las listas sean las mismas en `main` se deduce de la lectura del diff.

## Comunicado upstream

- Se comunicaron después de escribir esta lección: en la issue de GA [#777](https://github.com/GuitarAlchemist/ga/issues/777), la lista que solo depende de la cualidad del acorde, las etiquetas que no distinguen las tríadas relativas de las tríadas a un tritono de distancia, el v menor llamado dominante secundaria, la relación ignorada, los cifrados leídos en nombres de tonalidad y en artículos, y las raíces de `CanHandle`; en la [#776](https://github.com/GuitarAlchemist/ga/issues/776), la distancia de 1 entre vectores iguales; en la [#778](https://github.com/GuitarAlchemist/ga/issues/778), las entradas opcionales que exige `ga_dsl_eval`, la tonalidad por defecto de la closure y la descripción de la herramienta de GaMcpServer. Las notas compartidas escritas con bemoles en una tonalidad con sostenidos tienen la misma causa que la [#770](https://github.com/GuitarAlchemist/ga/issues/770), y el B♭ leído como B, la misma que la [#757](https://github.com/GuitarAlchemist/ga/issues/757). Todos están listados en el [diario](../journal/).

## Ejercicios

1. Calcula las máscaras de bits de G7, Dm7b5 y D♭7, con C como bit 0, y explica por qué Dm7b5 abre la lista de G7 y D♭7 no está en ella.
2. Cambia la prueba de dominante secundaria para que exija una tríada mayor o una séptima de dominante. ¿Qué filas de la sección de dos acordes cambian?
3. Escribe las dos raíces de `CanHandle` con `\w*`, como hacen las pistas de enrutamiento. ¿Cuántos de los 12 prompts de ejemplo acepta entonces la prueba, y cuáles sigue rechazando?
4. Para Am en C mayor, la closure enumera C, F, Dm y Em. ¿Qué acordes diatónicos de C mayor faltan, y por qué?

<details>
<summary>Soluciones</summary>

1. G7 es G B D F, clases de altura 7, 11, 2 y 5: 128 + 2048 + 4 + 32 = 2212. Dm7b5 es D F A♭ C, 2, 5, 8 y 0: 4 + 32 + 256 + 1 = 293. D♭7 es D♭ F A♭ C♭, 1, 5, 8 y 11: 2 + 32 + 256 + 2048 = 2338. Los tres tienen el vector <012111>, así que los tres tienen coste 0,60. La ordenación estable los deja en el orden de las máscaras de bits, y la lista se detiene tras las cinco más pequeñas; el 293 de Dm7b5 es la más pequeña de la clase de conjuntos, y el 2338 de D♭7 va después de la del propio G7. Resuelto a mano.
2. Solo "v and i": su etiqueta "Secondary Dominant" desaparece, y la fila queda en "Set-Class Equivalent, ICV Neighbor (L1 = 1)". V7 y I la conservan. Resuelto a mano.
3. Siete. Sigue rechazando "What's the secondary dominant of Am?", "Show me a backdoor dominant for C major", "What can replace Dm7?", "Borrow a chord from parallel minor" y "Modal interchange options in F major": ninguno contiene una de las expresiones de la prueba, y el cuarto no nombra ningún acorde. Comprobado con las expresiones regulares de .NET; no se ha compilado en el curso.
4. G y B disminuido: G B D y B D F no comparten ninguna nota con A C E, y la closure descarta los acordes que no comparten ninguna nota. El propio Am, con la misma fundamental y la misma cualidad, se omite. Resuelto a mano a partir de las líneas 580-602.

</details>

## Puntos clave

- Una distancia que ignora la transposición no puede ordenar sustitutos: todos los acordes de una clase de conjuntos empatan, y el empate decide la respuesta.
- Un empate que se resuelve por el orden de almacenamiento es una respuesta que nadie eligió: aquí, las máscaras de bits más pequeñas.
- Una distancia que da 1 para entradas iguales engaña a todo el que la llama y la lee como una distancia.
- Un límite de palabra justo después de una raíz no coincide con ninguna palabra; las propias pistas del enrutador escribían `\w*`.
- La respuesta de manual puede existir ya en el código, aquí en una closure, mientras la skill a la que enruta el chatbot no la llama.

## Fuentes

- GuitarAlchemist/ga en [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6): `Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs`, `skills/chord-substitution/SKILL.md`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GA en [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40): `DomainClosures.fs`, compilado por el curso. El `main` de GA en [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), con commit del 2026-09-30 en UTC, para la comparación.
- *Open Music Theory*, los capítulos sobre los acordes aplicados, la mezcla modal y la sustitución de acordes en el jazz.
