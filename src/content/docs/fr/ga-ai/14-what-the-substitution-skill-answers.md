---
title: "Leçon 14 : ce que répond le skill de substitution"
description: "Le chatbot de Guitar Alchemist répond sans modèle à une demande de substitution d'accord, à partir de la distance entre vecteurs d'intervalles. Le cours pose à son skill ses douze prompts d'exemple, un accord de chaque qualité sur les 12 fondamentales et huit paires d'accords que nomme un manuel. Pour un accord, la liste ne dépend que de sa qualité : chaque accord reçoit les cinq autres membres de sa classe d'ensembles aux plus petits masques de bits, tous à un pas, et la liste de G7 ne contient pas Db7. Pour deux accords, des triades relatives et des triades à un triton d'écart reçoivent les mêmes étiquettes, et un accord est à un pas de lui-même. La closure du DSL qui donne les réponses d'un manuel exige, par ga_dsl_eval, les entrées que son propre schéma dit facultatives."
sidebar:
  label: 14. Ce que répond le skill de substitution
  order: 14
---

La [leçon 12](../12-what-the-progression-skills-answer/) et la [leçon 13](../13-what-the-progression-analysis-answers/) portaient sur des progressions d'accords. Cette leçon demande au chatbot un autre accord : un substitut de G7, la dominante secondaire de Am, une réharmonisation de Dm7. Le routeur envoie ce genre de question à l'intention `skill.chordsubstitution`, qui exécute `ChordSubstitutionSkill` ([`GaPlugin.cs` ligne 41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L41)). Le skill n'appelle aucun modèle : pour un accord, il liste les accords les plus proches selon la distance de Grothendieck, une distance entre vecteurs d'intervalles, et pour deux accords, il nomme leur relation. Le chatbot a deux autres façons de répondre. Le skill SKILL.md [`chord-substitution`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md), destiné au chemin qui passe par le modèle, donne au modèle deux outils MCP, `ga_chord_substitutions` et `ga_chord_compare`, dont le code reprend celui du skill C# ; leurs fonctions de lecture des accords portent le commentaire « mirror ChordSubstitutionSkill » ([`ChordSubstitutionMcpTools.cs` ligne 176](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L176)). La closure `domain.chordSubstitutions` du DSL procède autrement : elle classe les accords d'une tonalité selon les notes qu'ils ont en commun avec l'accord. L'outil `GaChordSubstitutions` de GaMcpServer l'appelle ([`GaDslTool.cs` lignes 208-222](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L208-L222)), tout comme l'outil qui cherche des voicings plus faciles ([`GuitaristProblemTools.cs` lignes 602-605](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L602-L605)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur `main` au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordSubstitutionSkill.cs`, `ChordSubstitutionMcpTools.cs`, le SKILL.md, `GrothendieckDelta.cs`, `DslEvalMcpTools.cs` et `DefaultRoutingHintProvider.cs` sont inchangés. `GrothendieckService.FindNearby` n'a changé que par le test qui écarte l'ensemble de départ de sa propre liste, ce que le skill fait déjà lui-même. La closure n'a changé que par sa façon de nommer les intervalles ; le cours la compile au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), où `DomainClosures.fs` est identique à celui de `main`, comme dans la leçon 13. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l14
```

## Les prompts d'exemple du skill lui-même

Le programme démarre l'hôte du chatbot comme dans la leçon 12, prend l'intention que choisirait le routeur et lui pose chacun de ses prompts d'exemple ([`ChordSubstitutionSkill.cs` lignes 35-55](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L35-L55)). Le skill lit jusqu'à deux chiffrages d'accords dans la question ; s'il en trouve deux, il les compare, s'il n'en trouve qu'un, il liste des substituts ([lignes 146-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L146-L160)) :

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

Le programme affiche le type de réponse et les accords qu'elle nomme :

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

- **La relation que nomme le prompt est ignorée.** Dans « Tritone substitution for G7 », « What's the secondary dominant of Am? » et « Show me a backdoor dominant for C major », le skill lit un seul accord, et chacun de ces prompts reçoit la même liste que n'importe quelle question sur cet accord. Aucune de ces listes ne nomme l'accord que donne un manuel : D♭7, E7, B♭7. La comparaison de deux accords connaît ces trois relations ; la liste, non.
- **Un nom de tonalité est lu comme un accord.** Dans « Alternative chord for F major in C », le skill lit F et C : il compare donc F à C au lieu de proposer un accord pour F dans la tonalité de C.
- **« Borrow a chord from parallel minor »** ne nomme aucun accord et reçoit le refus du skill. Le skill n'a aucune notion de tonalité : une demande d'emprunt modal en C majeur reçoit la liste de l'accord de C majeur.

Chaque skill a aussi `CanHandle`, un test sur les mots de la question. Au commit épinglé, le routeur ne l'appelle pas ; sur `main`, il s'y replie quand il ne peut pas calculer l'embedding de la question, comme l'a montré la leçon 12 ([`SemanticIntentRouter.cs` ligne 321 sur `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). Le test accepte 4 des 12 prompts ([lignes 59-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L59-L75)) :

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

`\b(substitut|reharmoni...)\b` exige une limite de mot juste après le radical, or « substitute », « substitution » et « reharmonize » continuent tous par une lettre : les deux radicaux ne reconnaissent jamais un mot. « Tritone substitution for G7 » passe grâce à « tritone », le mot-clé de la comparaison ; les deux prompts « alternative chord » et « Swap chord for G7 » passent chacun grâce à sa propre locution. Les indices de routage du routeur écrivent les radicaux avec `\w*` ([`DefaultRoutingHintProvider.cs` lignes 53-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L53-L56)), et le SKILL.md liste « substitute », « secondary dominant », « backdoor » et « modal interchange » parmi ses déclencheurs ([`SKILL.md` lignes 8-21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L8-L21)).

## Un accord sur les douze fondamentales

Pour un seul accord, le skill demande à `FindNearby` tous les ensembles de classes de hauteurs situés à une distance de 3 au plus, garde ceux qui ont la taille de l'accord, les trie par coût et en prend cinq ([lignes 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L164-L174)) :

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

`FindNearby` compare le vecteur d'intervalles de l'accord à ceux des 4096 ensembles de classes de hauteurs de `PitchClassSet.Items`, dans l'ordre de leurs identifiants, de 0 à 4095, qui sont leurs masques de bits ([`GrothendieckService.cs` lignes 55-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L55-L81), [`PitchClassSetId.cs` lignes 70-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs#L70-L71)). Le coût est la distance L1 entre les vecteurs, multipliée par 0.6 ([lignes 38-42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L42)). Le programme pose « Substitute for » suivi de chacune des neuf qualités que lit le skill, sur les 12 fondamentales, en écrivant les accords comme le skill les écrit. Pour six qualités, il vérifie si la liste contient l'un des deux substituts que donne un manuel : deux accords situés à une tierce, qui partagent deux notes avec une triade ou trois avec un accord de septième, ou, pour une septième de dominante, son substitut tritonique et la septième demi-diminuée située une tierce au-dessus. Il compte aussi les notes que chaque accord de la liste partage avec l'accord demandé :

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

- **La liste ne dépend que de la qualité.** Un accord, ses transpositions et ses inversions ont tous le même vecteur d'intervalles : les 12 triades majeures et les 12 triades mineures en partagent un, et les 12 septièmes de dominante partagent le leur avec les 12 septièmes demi-diminuées. Tous sont au même coût, le plus petit, et la liste prend donc les cinq aux plus petits masques de bits, dans l'ordre de `PitchClassSet.Items` : `OrderBy` garde les éléments égaux dans leur ordre. Pour chaque qualité, les douze listes nomment six accords, moins pour la triade augmentée et la septième diminuée, qui ont quatre et trois transpositions.
- **La liste de G7 ne contient pas D♭7.** D♭7 appartient à la classe d'ensembles de G7, mais son masque de bits est plus grand que les cinq premiers. Les accords de septième majeure et de septième mineure ne reçoivent jamais de substitut de manuel ; les triades majeures et mineures, les septièmes de dominante et les septièmes demi-diminuées n'en reçoivent un que sur les fondamentales dont les substituts se trouvent, par hasard, parmi les six. Sur les 60 accords listés pour les triades majeures, 29 n'ont aucune note commune avec leur accord de départ.
- **Chaque accord coûte 0.60, à une distance L1 de 1.** Les quatre dernières lignes montrent pourquoi : C et Am ont le même vecteur, tout comme C et F♯, G7 et D♭7, et C et lui-même, mais `ComputeDelta` donne 1. Quand la différence est nulle, `GrothendieckDelta.FromIcVs` écrit 1 dans sa première composante ([`GrothendieckDelta.cs` lignes 125-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L125-L131)) :

```csharp
        // Heuristic: When two distinct sets share the same ICV (e.g., diatonic modes/keys),
        // L1 difference is zero. To preserve musical differentiation expected by callers/tests,
        // emit a minimal non-zero delta focused on ic1. This keeps related keys close but not identical.
        if (delta.L1Norm == 0)
        {
            delta = delta with { Ic1 = 1 };
        }
```

- **Le chemin du SKILL.md reçoit les mêmes listes.** `ga_chord_substitutions` renvoie les mêmes accords, les mêmes coûts et les mêmes distances L1 pour les 108 accords. L'exemple du SKILL.md pour Cmaj7 liste Am7 au coût 0.50 et Em7 à 0.83 ([`SKILL.md` lignes 100-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L100-L104)) ; l'outil liste cinq autres accords de septième majeure, et un coût de 0.6 × L1 ne peut valoir ni 0.50 ni 0.83.

## Deux accords

Avec deux accords, le skill teste cinq relations l'une après l'autre, et ajoute une dernière étiquette quand aucune ne s'applique ([lignes 246-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L246-L298)). Les deux premières :

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

Le programme demande « How are A and B related? » pour huit paires que nomme un manuel, sur les 12 fondamentales, et soumet les mêmes paires à `ga_chord_compare` :

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

- **Trois relations sont justes sur les 12 fondamentales :** V7 et I, bVII7 et I, et la substitution tritonique.
- **Un v mineur est étiqueté dominante secondaire.** Le test ne lit que l'intervalle entre les fondamentales ; Gm n'est pas la dominante de Cm : c'est G, ou G7.
- **Les étiquettes ne séparent pas ce que sépare un manuel.** Am et C partagent deux notes, F♯m et C aucune ; les deux paires reçoivent « Set-Class Equivalent » et « ICV Neighbor (L1 = 1) », parce que toutes les triades majeures et mineures appartiennent à une même classe d'ensembles. Un accord comparé à lui-même est lui aussi « 1 step(s) apart in ICV space ». Em7b5 et C7, qui partagent trois notes, reçoivent les deux mêmes étiquettes. L'exemple de comparaison du SKILL.md se termine par « Also flagged as ICV Neighbor with L1 = 0 » ([`SKILL.md` ligne 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-substitution/SKILL.md#L108)), une valeur que `FromIcVs` ne renvoie jamais.

## Ce que le skill lit comme un accord

Pour le skill, un chiffrage d'accord est une majuscule de A à G, un `b` ou un `#` facultatif, une qualité facultative, et aucun caractère de mot à la suite ([lignes 69-71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs#L69-L71)). Le programme pose quatre questions de plus ; la dernière est une entrée du corpus de prompts de GA ([`prompts.yaml` lignes 206-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L206-L209)) :

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

- **« A substitute for G7? »** L'article « A » est un chiffrage d'accord : le skill compare A majeur à G7.
- **B♭7** est lu comme B majeur : `♭` n'est pas `b`, et ce n'est pas un caractère de mot, si bien que le chiffrage s'arrête après B. Le skill d'improvisation de la leçon 7 lisait ce signe de la même façon ([#757](https://github.com/GuitarAlchemist/ga/issues/757)).
- **Cmin7** n'est pas lu du tout, ni par le skill ni par l'outil MCP ([`ChordSubstitutionMcpTools.cs` lignes 230-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs#L230-L232)), alors que le tableau des chiffrages du SKILL.md liste `min7`.
- **L'entrée du corpus** demande seulement une réponse d'au moins 100 caractères, en moins de 60 secondes. La réponse du skill en a 263 et ne contient pas D♭7 : l'entrée passe. La leçon 8 a envoyé ce prompt par le chat, où il a échoué avec une erreur HTTP 500, faute de modèle.

## La closure qui répond à partir de la tonalité

`domain.chordSubstitutions` prend un accord, une tonalité et une gamme, garde les accords diatoniques de la tonalité qui ont une note en commun avec l'accord, les classe selon le nombre de notes communes et ajoute le substitut tritonique quand l'accord a une tierce majeure et une septième mineure ([`DomainClosures.fs` lignes 535-621](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L535-L621)). Le programme l'interroge par `ga_dsl_eval`, comme le ferait un skill du chatbot, et exécute directement la closure de `main`, comme le fait GaMcpServer :

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

- **Les entrées facultatives sont obligatoires.** Le schéma déclare `key` et `scale` facultatives et donne leurs valeurs par défaut, mais `ga_dsl_eval` exige toutes les entrées que déclare le schéma ([`DslEvalMcpTools.cs` lignes 257-270](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L257-L270)) : « everything in InputSchema is required for v0.1 », tout ce que contient InputSchema est obligatoire en v0.1. Un modèle qui se fie au schéma et les omet reçoit une erreur. Cinq entrées de deux des 15 closures sont dans ce cas.
- **La tonalité par défaut d'un accord mineur est majeure.** Sans tonalité, la closure prend la fondamentale de l'accord et la gamme majeure ([lignes 557-559](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L557-L559)) : Am reçoit les accords de A majeur, une tonalité qui ne contient pas Am. L'outil de GaMcpServer ne passe la tonalité que lorsqu'il en a une ([`GaDslTool.cs` lignes 218-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L218-L220)), et l'outil des voicings plus faciles ne la passe jamais.
- **Avec une tonalité, les réponses sont celles d'un manuel.** Pour G7 en C majeur, B diminué partage trois notes et D♭7 est le substitut tritonique ; pour Am, C et F partagent deux notes. La description de l'outil dans GaMcpServer promet autre chose pour Am en C majeur : « C (★★★, relative major), Em (★★, shared E/B), F (★, shared A) » ([`GaDslTool.cs` ligne 212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L212)). Em ne partage que E avec Am, F partage A et C, et trois étoiles demandent trois notes communes ([ligne 614](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L614)).
- **F♯7 en B majeur** reçoit A♯dim, C♯m et D♯m, écrits d'après la tonalité, mais les notes communes s'écrivent B♭ et D♭ : elles sont nommées par `conventionalKeyName`, la cause de [#770](https://github.com/GuitarAlchemist/ga/issues/770), rencontrée dans la leçon 10. `main` nomme la quinte de l'accord diminué, F au-dessus de B et E au-dessus de A♯, `d5` au lieu de `TT` : c'est la seule différence dans ces exécutions.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Savoir si le routeur sémantique envoie chaque prompt d'exemple à cette intention demande les embeddings, et ce qu'un modèle écrit à partir de `ga_chord_substitutions` et de `ga_chord_compare` demande le modèle (*à vérifier*).
- **Les substituts de manuel sont un choix.** Deux par qualité, plus le substitut tritonique ; l'harmonie jazz en connaît d'autres, et les décomptes ne valent que pour ceux-là.
- **Le skill et les outils ne sont pas exécutés sur `main`.** Ils y sont inchangés, comme `GrothendieckDelta.cs`, et `FindNearby` ne diffère que par le test qui écarte l'ensemble de départ ; que les listes soient les mêmes sur `main`, c'est la lecture du diff qui le dit.

## Signalé en amont

- Non signalés en amont au moment de l'écriture de cette leçon : la liste qui ne dépend que de la qualité de l'accord, la distance de 1 entre vecteurs égaux, les étiquettes qui ne séparent pas les triades relatives des triades à un triton d'écart, le v mineur appelé dominante secondaire, la relation ignorée et les chiffrages lus dans des noms de tonalités et des articles, les radicaux de `CanHandle`, et les entrées facultatives qu'exige `ga_dsl_eval`. Les notes communes écrites avec des bémols dans une tonalité à dièses ont la même cause que [#770](https://github.com/GuitarAlchemist/ga/issues/770), et B♭ lu comme B la même que [#757](https://github.com/GuitarAlchemist/ga/issues/757). Tous sont listés dans le [journal](../journal/).

## Exercices

1. Calcule les masques de bits de G7, Dm7b5 et D♭7, avec C comme bit 0, et explique pourquoi Dm7b5 ouvre la liste de G7 et pourquoi D♭7 n'y figure pas.
2. Modifie le test de dominante secondaire pour qu'il exige une triade majeure ou une septième de dominante. Quelles lignes de la section à deux accords changent ?
3. Écris les deux radicaux de `CanHandle` avec `\w*`, comme le font les indices de routage. Combien des 12 prompts d'exemple le test accepte-t-il alors, et lesquels rejette-t-il encore ?
4. Pour Am en C majeur, la closure liste C, F, Dm et Em. Quels accords diatoniques de C majeur manquent, et pourquoi ?

<details>
<summary>Solutions</summary>

1. G7 est G B D F, les classes de hauteurs 7, 11, 2 et 5 : 128 + 2048 + 4 + 32 = 2212. Dm7b5 est D F A♭ C, 2, 5, 8 et 0 : 4 + 32 + 256 + 1 = 293. D♭7 est D♭ F A♭ C♭, 1, 5, 8 et 11 : 2 + 32 + 256 + 2048 = 2338. Les trois ont le vecteur <012111> : tous trois sont donc au coût 0.60. Le tri stable les laisse dans l'ordre des masques de bits, et la liste s'arrête après les cinq plus petits ; le 293 de Dm7b5 est le plus petit de la classe d'ensembles, et le 2338 de D♭7 vient après celui de G7 lui-même. Résolu à la main.
2. Seule la paire « v and i » change : son étiquette « Secondary Dominant » disparaît, et sa ligne devient « Set-Class Equivalent, ICV Neighbor (L1 = 1) ». V7 et I la gardent. Résolu à la main.
3. Sept. Il rejette encore « What's the secondary dominant of Am? », « Show me a backdoor dominant for C major », « What can replace Dm7? », « Borrow a chord from parallel minor » et « Modal interchange options in F major » : aucun ne contient l'une des locutions du test, et le quatrième ne nomme aucun accord. Vérifié avec les expressions régulières de .NET, non compilé dans le cours.
4. G et B diminué : G B D et B D F n'ont aucune note commune avec A C E, et la closure écarte un accord sans note commune. Am lui-même, de même fondamentale et de même qualité, est sauté. Résolu à la main à partir des lignes 580-602.

</details>

## À retenir

- Une distance qui ignore la transposition ne peut pas classer des substituts : tous les accords d'une classe d'ensembles sont à égalité, et c'est l'égalité qui décide de la réponse.
- Une égalité tranchée par l'ordre de stockage donne une réponse que personne n'a choisie : ici, les plus petits masques de bits.
- Une distance qui vaut 1 pour des entrées égales trompe tout appelant qui la lit comme une distance.
- Une limite de mot juste après un radical ne reconnaît aucun mot ; les indices du routeur lui-même écrivaient `\w*`.
- La réponse du manuel peut déjà exister dans le code, ici dans une closure, alors que le skill vers lequel le chatbot route la question ne l'appelle pas.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ChordSubstitutionSkill.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSubstitutionMcpTools.cs`, `skills/chord-substitution/SKILL.md`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSetId.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- GA au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) : `DomainClosures.fs`, compilé par le cours. Le `main` de GA au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), daté du 2026-09-30 en UTC, pour la comparaison.
- *Open Music Theory*, les chapitres sur les accords appliqués, l'emprunt au mode homonyme et la substitution d'accords en jazz.
