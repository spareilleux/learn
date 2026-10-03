---
title: "Leçon 23 : la distance et le chemin harmoniques"
description: "GrothendieckDeltaSkill et IcvShortestPathSkill sont les deux skills du chatbot de Guitar Alchemist consacrés à une paire d'accords : le premier donne la différence de leurs vecteurs d'intervalles, le second une chaîne d'ensembles de classes de hauteurs de l'un à l'autre. Le premier attribue à deux accords de même vecteur une distance de 1 et « more chromatic color », y compris de C à C ; le second ne relie jamais des accords de tailles différentes, si bien que deux de ses propres prompts d'exemple n'obtiennent aucun chemin au terme d'une recherche parmi des centaines d'ensembles, et il compte les ensembles d'un chemin comme ses étapes."
sidebar:
  label: 23. La distance et le chemin harmoniques
  order: 23
---

La [leçon 22](../22-similar-chords/) a demandé à `IcvNeighborsSkill` les ensembles proches d'un accord. Deux skills enregistrés à côté de lui prennent une paire d'accords ([`GaPlugin.cs` lignes 100-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L100-L102)) : `GrothendieckDeltaSkill` donne la différence de leurs vecteurs d'intervalles, ses normes L1 et L2 et un coût ([`GrothendieckDeltaSkill.cs` lignes 97-131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L97-L131)), et `IcvShortestPathSkill` une chaîne d'ensembles de classes de hauteurs de l'un à l'autre ([`IcvShortestPathSkill.cs` lignes 9-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L9-L53)). Tous deux appellent `GrothendieckService`, et tous deux ont un `CanHandle` qui répond toujours non : le routeur compare une question à la description et aux prompts d'exemple de chaque skill, ajoute les bonus des indices de routage, et l'envoie au skill qui obtient le meilleur score, si ce score atteint un seuil de confiance ([`SemanticIntentRouter.cs` lignes 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), les deux skills ne font que marquer leur refus `Declined`, `GrothendieckDelta` et `DefaultRoutingHintProvider` sont inchangés, et `FindNearby` compare l'ensemble de départ à chaque ensemble par valeur ; les ensembles de classes de hauteurs eux-mêmes ont changé : `GaMain` repose donc les questions. Sa sortie affiche les mêmes tableaux que celle du commit épinglé, sous des titres qui portent « on main ». Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l23
dotnet run --project code/ga-ai/GaMain -c Release -- l23
```

## Comment les skills lisent une question

Le skill du delta cherche deux accords reliés par « to », « and » ou une flèche :

```csharp
    // Two-chord pattern shared with VoiceLeadingSkill — anchored on
    // "<chord A> to/and <chord B>" with a permissive chord token. Pre-anchored
    // by routing hint, so substring overlap with unrelated phrases is unlikely.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|and|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Le skill du chemin veut « shortest path », « shortest route », « harmonic path », « step by step » ou quelques autres mots, suivis de deux accords reliés par « to », ou bien « how do I get from » suivi de deux accords, puis « harmonic » :

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

Les prompts d'exemple des deux skills ont été reformulés le 2026-06-16, pour tenir les deux skills à l'écart l'un de l'autre. Le skill du chemin garde deux commentaires à ce sujet, le second écrit par-dessus le premier sans que celui-ci soit supprimé ([lignes 55-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L55-L66)).

## Les formulations de GA

Le programme pose à chaque skill ses dix prompts d'exemple, les formulations de son commentaire de documentation et les deux que suggère son refus, pose les mêmes à l'autre skill, et demande à `DefaultRoutingHintProvider` quelles intentions chacune favoriserait :

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

- **Le skill du delta répond à 8 de ses 10 prompts d'exemple.** « how harmonically far is Am from D7 », qui est aussi la première formulation de son commentaire de documentation, place « from » entre les accords, et « how different are C major and F major harmonically » place « major » entre le premier accord et « and ».
- **Le skill du chemin répond à 7 de ses 10.** « shortest path from C major to F major », qui figure aussi dans son commentaire de documentation sous la forme « Path from C major to F major », a « major » après chaque accord ; « shortest chord path from Dm7 to Gmaj7 » place « chord » entre « shortest » et « path » ; « harmonic stepping stones from Cmaj7 to Fmaj7 » n'a ni « path » ni « route ». Des sept prompts auxquels il répond, deux n'obtiennent aucun chemin et un est lu comme A majeur, comme le montrent les sections suivantes.
- **Le skill du delta répond à 9 des 10 prompts du skill du chemin,** puisque deux accords quelconques reliés par « to » lui suffisent ; le skill du chemin ne répond à aucun de ceux du delta. Une question de chemin formulée comme eux que le routeur envoie au skill du delta reçoit une distance, et non un refus.
- **Les règles des indices de routage favorisent 4 des prompts du skill du delta et 8 de ceux du skill du chemin** ([`DefaultRoutingHintProvider.cs` lignes 128-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L128-L144)). « harmonic cost to move from C to G » favorise plutôt `skill.transpose`, dont la règle lit « move … to » et une majuscule ([lignes 257-259](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L257-L259)).

## Les accords qu'ils lisent

Les deux skills construisent leurs ensembles avec une copie de la table qu'a lue la leçon 22 ([`GrothendieckDeltaSkill.cs` lignes 133-173](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L133-L173), [`IcvShortestPathSkill.cs` lignes 165-201](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L165-L201)). Le programme construit les accords de la leçon 22 et les 16 qualités avec les tables des trois skills, puis leur pose des paires :

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

- **Les trois tables construisent les mêmes ensembles,** et les erreurs de lecture de la leçon 22 se retrouvent donc ici : CM7 est construit comme une septième mineure sur C, et un mot placé après la fondamentale termine l'accord, si bien que « C to A minor », l'un des prompts d'exemple du skill du chemin, demande A majeur.
- **« a » est ici aussi un accord :** « from Cmaj7 to a G7 » demande la distance jusqu'à A majeur, et « from C to a G » un chemin jusqu'à A majeur.
- **° survit sur le premier accord, pas sur le second.** Le premier accord n'a besoin que d'être suivi d'un espace, le second d'une limite de mot : « C° to C+ » est donc lu comme C diminué vers C majeur.

## Les deltas

Le skill du delta donne ce que renvoie `ComputeDelta`, par l'intermédiaire de `GrothendieckDelta.FromIcVs` :

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

Le programme pose au skill du delta chaque paire de ses prompts d'exemple dans les deux sens, et deux accords face à eux-mêmes, puis chaque paire ordonnée des 192 accords formés de 12 fondamentales et de 16 qualités :

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

- **Deux accords de même vecteur sont à 1 l'un de l'autre, avec un demi-ton de plus.** C vers G, Am vers Em, Cmaj7 vers Fmaj7, et C vers C lui-même reçoivent le delta `[+1, 0, 0, 0, 0, 0]`, un L1 de 1, un coût de 0.60 et « more chromatic color ». Il en va de même pour chacune des 4320 paires ordonnées des 192 accords qui partagent un vecteur ; les 32544 autres reçoivent un L1 juste. La glose de la réponse elle-même dit que chaque composante est « how many more occurrences of that interval-class the target has than the source » ([lignes 122-128](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L122-L128)) : G majeur n'a pas plus de demi-tons que C majeur. Le skill de la leçon 22 recalcule le delta pour éviter cela ([`IcvNeighborsSkill.cs` lignes 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)) ; celui-ci, non. Le ticket de GA [#776](https://github.com/GuitarAlchemist/ga/issues/776) signale cette heuristique.
- **L'interprétation est la première règle qui correspond,** et la première est « more semitones or whole tones » ([`GrothendieckDelta.cs` lignes 226-258](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L226-L258)). Cmaj7 vers G7 gagne un ton entier et G7 vers Cmaj7 un demi-ton : les deux sens reçoivent donc « more chromatic color », comme 1440 des 16272 paires de vecteurs différents.
- **La flèche qui précède l'interprétation s'affiche comme `â†’`.** La ligne 217 contient les octets de `→` lus comme du Windows-1252 et réenregistrés en UTF-8 ([`GrothendieckDelta.cs` ligne 217](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs#L217)) ; `main` a la même ligne.

## Les chemins

`FindShortestPath` est un parcours en largeur : depuis chaque ensemble, il passe aux ensembles de même taille, situés à un L1 de 2 au plus, qu'il n'a pas encore vus, et s'arrête après cinq déplacements ([`GrothendieckService.cs` lignes 117-163](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L117-L163)) :

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

Le programme pose au skill du chemin les prompts d'exemple auxquels il répond et quatre autres paires, et compte, pour chaque chemin, les déplacements, le L1 et les notes conservées à chaque déplacement, ainsi que les déplacements entre deux ensembles d'un même vecteur :

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

- **Des accords de tailles différentes ne sont jamais reliés.** Am vers D7 et Gmaj7 vers Em, deux des prompts d'exemple du skill, et « How do I get from Am to D7 harmonically », tiré de son commentaire de documentation, reçoivent « No path found within 5 steps », et la réponse en accuse la distance ou « the cardinality constraint » ([ligne 137](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L137)). Avant de le dire, la recherche développe 168 des 220 ensembles de trois notes, ou 462 des 495 ensembles de quatre, chacun au prix d'un parcours des 4096 ensembles, dont les vecteurs sont recalculés à chaque lecture ([`PitchClassSet.cs` ligne 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L104)) ; `FindNearby` conserve ses réponses pour 256 ensembles ([`GrothendieckService.cs` ligne 21](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L21)).
- **La réponse compte les ensembles comme des étapes** ([ligne 141](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L141)). Cmaj7 vers G7 donne « 4 steps total (3 intermediate moves) » : trois déplacements, en passant par deux ensembles. C vers G donne « 2 steps total (1 intermediate move) » : un déplacement, sans passer par aucun. C vers C donne « 1 step total ».
- **Un déplacement entre deux ensembles d'un même vecteur compte comme une étape.** C vers G, C vers F, C vers Cm et C vers A demandent chacun un déplacement : leur vrai L1 est 0, dont `FromIcVs` fait 1.
- **La réponse ne nomme aucun des ensembles intermédiaires, et les notes se perdent en chemin.** Cmaj7 vers G7 passe par C D D# G et C C# E F#, 4-14 et 4-Z15, en gardant 2 notes, puis 1, puis aucune, là où la réponse promet des « common-tone bridges » ([lignes 156-160](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs#L156-L160)). Cmaj7 vers Bm7b5 obtient les mêmes décomptes.
- **Cdim7 et Caug n'atteignent que leurs propres transpositions,** 3 et 4 ensembles : la leçon 22 n'a trouvé aucun ensemble à un L1 de 1 ou 2 de Cdim7, et seulement des ensembles de deux notes près de Caug ; or la recherche garde la taille : il ne reste donc que les ensembles qui ont leur vecteur.

## Où le cours s'arrête

- **Le routeur n'est pas exécuté :** il a besoin des embeddings. La leçon pose aux skills leurs propres prompts d'exemple : une question formulée exactement comme l'un d'eux est celle qui a le plus de chances de leur être envoyée.
- **Le nombre d'ensembles développés est celui du cours,** obtenu par une recherche qui suit la règle de `FindShortestPath` ; le skill ne l'affiche pas. Le programme ne chronomètre pas les skills.
- **Le programme appelle directement les méthodes des skills,** et non par le chatbot.

## Exercices

1. Pourquoi le skill du delta décline-t-il « how harmonically far is Am from D7 » ?
2. C majeur et G majeur ont tous deux le vecteur `<0 0 1 1 1 0>`. Quel L1 les sépare, et qu'affiche le skill du delta ? Quelle ligne fait la différence ?
3. Pourquoi le skill du chemin ne trouve-t-il aucun chemin de Am à D7 ?
4. Le chemin de Cmaj7 à G7 contient quatre ensembles. Combien de déplacements fait-il, et par combien d'ensembles intermédiaires passe-t-il ? Que dit la réponse ?

<details>
<summary>Solutions</summary>

1. Son expression exige « to », « and » ou une flèche entre les deux accords ([lignes 65-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs#L65-L67)) ; le prompt contient « from ».
2. 0. Le skill affiche un L1 de 1 et le delta `[+1, 0, 0, 0, 0, 0]`, parce que `FromIcVs` change un delta nul en `Ic1 = 1` (lignes 128-131 de l'extrait ci-dessus).
3. Am a trois notes et D7 quatre, et la recherche ne passe qu'à des ensembles de même taille (ligne 150 de `GrothendieckService.cs`) : elle n'atteint donc jamais D7.
4. Trois déplacements, par deux ensembles : C D D# G et C C# E F#. La réponse dit « 4 steps total (3 intermediate moves) ».

</details>

## À retenir

- Une heuristique placée dans un type partagé atteint chaque appelant : un skill la corrige, son frère l'affiche.
- Une distance qui ne renvoie jamais 0 ne peut pas dire que deux accords sont semblables.
- Une recherche qui garde la taille ne peut pas relier des accords de tailles différentes, et devrait le dire avant de chercher.
- Compter des étapes, c'est compter des déplacements, et non ce que relient ces déplacements.
- Le mojibake d'un fichier source finit dans les réponses du chatbot.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/GrothendieckDeltaSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvShortestPathSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckDelta.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : les mêmes skills, avec leurs refus marqués `Declined`, et `GrothendieckDelta.cs`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson23.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvDeltaPathProbe.cs`.
