---
title: "Leçon 19 : les paires de voicings"
description: "Le serveur MCP de Guitar Alchemist propose aux agents ga_voice_leading_pair, un outil qui apparie des voicings jouables de deux accords, tirés de l'index OPTIC-K ; le chatbot ne l'appelle pas. Le cours lui pose les dix exemples de la leçon 18, au commit épinglé et avec la recherche du main de GA. Au commit épinglé, 3 des 10 premières paires jouent les deux accords ; sur main, les 10 y parviennent, et chacune est la paire de voicings exacts de l'index qui bouge le moins. L'outil ne vérifie rien de ce qu'il apparie : avec 50 candidats, au commit épinglé, il répond à C vers Am par les trois mêmes E des deux côtés, pour un mouvement de 0 demi-ton. Sa distance est minimale entre voicings de même taille et apparie les notes les plus graves quand les tailles diffèrent ; ses diagrammes, eux, commencent par le mi aigu."
sidebar:
  label: 19. Les paires de voicings
  order: 19
---

La [leçon 18](../18-voice-leading/) demandait au chatbot comment passer d'un accord au suivant. Son skill répondait en classes de hauteurs, sans octave ni case, et la leçon s'arrêtait devant un autre chemin de GA, qui conduit de vrais voicings. Cette leçon l'exécute. `ga_voice_leading_pair` est un outil de `GaMcpServer`, le serveur MCP de GA, dont les outils peuvent être appelés par des agents comme Claude Code. À partir de deux chiffrages, il demande à l'index OPTIC-K de la [leçon 3](../03-index-and-search/) 15 voicings de chaque accord, évalue chaque paire par une distance en demi-tons, et renvoie les cinq paires dont la distance est la plus petite ([`CompositionTools.cs` lignes 179-268](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L268)). Le chatbot ne l'appelle pas : ses propres outils forment un autre ensemble, et le skill rédigé pour appeler celui-ci reste en attente ([`skills-dev/_pending-tools/README.md` lignes 19-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L19-L29)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. `CompositionTools.cs` est identique sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), mais la recherche qu'il appelle a changé après le commit épinglé, comme l'a montré la [leçon 16](../16-the-voicings-of-a-chord/). Le fichier de l'outil, tiré de chaque clone de GA, est compilé dans les deux programmes du cours et branché sur l'index de la leçon 3 : celui du commit épinglé dans `GaAi`, et dans `GaMain` celui qu'écrit le code de `main` à partir du même corpus. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l19
dotnet run --project code/ga-ai/GaMain -c Release -- l19
```

## Comment l'outil répond

`SearchByChordAsync` lit le chiffrage avec `ChordPitchClasses`, le lecteur de la leçon 16, en fait un vecteur de requête, et demande à l'index les voicings les plus proches ([lignes 278-298](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L278-L298)) :

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

La requête ne nomme aucun accord : sans instrument, les candidats sont les voicings dont les vecteurs sont les plus proches de la requête, quoi qu'ils jouent. `GetStrategy` emprunte la recherche à `VoicingSearchTool`, l'outil de recherche du serveur, en lisant son champ privé `Strategy` ([lignes 300-310](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L300-L310)). Cette classe trouve l'index par `GA_OPTICK_INDEX_PATH` ou sous `state/voicings/` ([`VoicingSearchTool.cs` lignes 64-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L83)). Le cours compile à sa place une classe de remplacement, avec le même nom et le même champ, qui lit l'index de la leçon 3 (`code/ga-ai/Shared/VoicingSearchTool.cs`).

L'outil évalue chaque paire de candidats avec `VoiceLeadingDistance` ([lignes 312-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L336)) :

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

La distance trie les notes MIDI des deux voicings, les apparie en partant de la plus grave, additionne les écarts, et compte 3 demi-tons pour chaque note en trop. L'outil trie ensuite les paires par distance, puis, à égalité, par la somme de leurs deux scores de recherche ([lignes 224-235](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L224-L235)).

## Les candidats

Le programme demande les candidats des 14 accords que contiennent les dix prompts d'exemple de `VoiceLeadingSkill` (leçon 18), et compare chaque voicing à l'accord tel qu'un manuel l'orthographie, comme l'a fait la leçon 16 : **exact** quand le voicing joue les notes de l'accord et aucune autre, **more** quand il les joue avec d'autres, **part** quand il n'en joue qu'une partie, **other** dans les autres cas. Un accord de septième auquel ne manque que sa quinte juste reçoit son propre verdict, **no fifth** : les shells omettent la quinte, et un guitariste les joue pour l'accord. Le cours compte exact et no fifth comme justes. Le programme compte aussi les voicings exacts de chaque accord dans tout l'index :

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

- **Au commit épinglé, 80 des 210 candidats sont exacts, et 52 autres ne manquent que de la quinte.** G7, Dm7, A7 et Fmaj7 n'obtiennent aucun voicing exact parmi leurs 15, alors que l'index en contient respectivement 49, 25, 35 et 60. G7 et Fmaj7 obtiennent tout de même 15 voicings sans quinte. A obtient son premier voicing exact au rang 11, et C7 au rang 15.
- **Les autres jouent une partie de l'accord, ou d'autres notes.** Pour C, 5 des 15 n'en jouent qu'une partie, comme le C5 du tableau suivant, qui n'a pas de E.

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

- **Sur `main`, les 210 candidats sont tous exacts.** L'outil est le même ; la recherche qu'il appelle ne renvoie que des voicings de l'accord demandé, pour chacun des 14 accords.

## La première paire

Pour chaque prompt, le programme vérifie les deux voicings de la première des cinq paires, et compte, parmi les cinq, les paires dont les deux voicings sont justes. Il cherche aussi, dans tout l'index, la paire de voicings exacts qui bouge le moins selon la distance de l'outil lui-même, et donne le mouvement minimal en classes de hauteurs de la leçon 18. Le programme écrit chaque diagramme mi grave en premier, comme le fait une grille d'accords :

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

- **Au commit épinglé, 3 des 10 premières paires jouent les deux accords.** C → F part de `x-3-x-0-1-x`, un C5 qui joue C et G, mais pas E. Em → A7 aboutit à `3-x-2-2-x-x`, A et E au-dessus de G, sans C♯.
- **8 premières paires bougent plus qu'une paire de voicings justes de l'index.** C → G reçoit deux voicings exacts qui bougent de 6 demi-tons, alors que `x-x-2-x-1-3` → `x-x-0-x-0-3` bouge de 3 : les 15 candidats de C et ceux de G ne contiennent pas cette paire.
- **Pour les dix prompts, la paire exacte qui bouge le moins atteint le mouvement minimal de la leçon 18.** Dans le corpus de la leçon 3, de vrais voicings bougent aussi peu que le permettent les classes de hauteurs.

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

- **Sur `main`, chaque première paire joue les deux accords, et c'est la paire de voicings exacts de l'index qui bouge le moins.** Les cinq paires de chaque prompt sont toutes justes.
- **L'outil renvoie ses diagrammes mi aigu en premier, sur `main` aussi.** La dernière ligne donne la première paire de C → F telle que l'outil la renvoie : `0-1-0-x-x-x`, c'est `x-x-x-0-1-0` lu à partir du mi aigu. L'index écrit la corde 1 en premier (différence 13 de l'entrée du 2026-09-14 du [journal](../journal/)). Sur `main`, le skill des voicings remet la chaîne dans l'ordre des grilles d'accords avant de répondre ([`ChordVoicingsSkill.cs` ligne 136 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)), mais l'outil renvoie la chaîne de l'index telle quelle ([`CompositionTools.cs` lignes 239-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L239-L254)). Un client qui lit `0-1-0-x-x-x` comme une grille place les doigts sur les mauvaises cordes.

## Cinquante candidats

La description de `candidatesPerChord` promet « Higher = more exhaustive pair search, slower » ([ligne 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L195)). Le programme pose de nouveau les questions avec 50 candidats par accord, le maximum que l'outil accepte ([ligne 203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L203)) :

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

- **Au commit épinglé, aucune première paire ne joue les deux accords.** C → Am reçoit `0-x-2-x-x-0` des deux côtés : la corde de mi grave, la corde de ré à la deuxième case et la corde de mi aigu, soit trois E. E est une note des deux accords, et aucune voix ne bouge. C → G et Em → A7 reçoivent eux aussi le même voicing des deux côtés.
- **La distance juge le mouvement, pas l'accord.** Une recherche plus large ramène des unissons et des quintes à vide, qui bougent moins, et l'outil ne vérifie rien de ce qu'il apparie.

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

- **Sur `main`, 8 premières paires jouent les deux accords, et les deux autres les jouent avec d'autres notes.** G7 → Cmaj7 conduit `x-2-2-0-3-1` vers `x-2-2-0-1-1` en 2 demi-tons, là où 15 candidats en donnaient 3 : le premier ajoute E à G7, le second F à Cmaj7. D → A conduit un Dmaj7 vers un A avec un D, en 2 demi-tons au lieu de 3.
- **Au commit épinglé comme sur `main`, davantage de candidats sacrifient l'accord à un mouvement moindre.**

## La distance

La description de l'outil qualifie son appariement de « good enough for retrieval ranking, not a formal Hungarian-optimal assignment » ([lignes 180-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L180-L185)), et le commentaire de documentation dit qu'un voicing plus petit « pairs against its nearest neighbors » ([lignes 312-319](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L312-L319)). Sur chaque paire que l'outil évalue pour les dix prompts, le programme compare la distance au mouvement minimal, pris sur toutes les façons d'apparier les notes. Quand les tailles diffèrent, le minimum choisit quelles notes du plus grand voicing apparier, et ajoute les mêmes 3 demi-tons pour chaque note en trop :

```text
== The tool's distance on every pair it weighs for the ten prompts, at the pin, against the least motion
pairs of equal size 867: the distance is the least over every pairing 867
pairs of unequal size 1383: the distance is the least over every choice of notes 593
the largest gap, 39 semitones: 0-2-2-0-0-0 Em [40 47 52 55 59 64] → x-x-x-2-2-3 A7(shell) [57 61 67], distance 55, least 16
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **Entre voicings de même taille, la distance est toujours minimale.** Apparier les notes triées est imbattable quand le coût est la somme des écarts : deux voix qui se croisent ne bougent jamais moins que les deux mêmes sans croisement. Sur ce point, la description sous-estime l'appariement.
- **Quand les tailles diffèrent, l'outil apparie les notes les plus graves, pas les plus proches, et 593 paires sur 1383 obtiennent le minimum.** De Em `0-2-2-0-0-0` au shell de A7 `x-x-x-2-2-3`, l'outil apparie les trois notes les plus graves de Em avec A, C♯ et G, une octave et plus au-dessus : 55 demi-tons avec la pénalité. Apparier les trois plus aiguës donne 16.
- **Pour ces dix prompts, la plus petite distance ne change pas.** Si le minimum remplaçait la distance, aucune première paire ne bougerait moins, au commit épinglé comme sur `main`.

```text
== The tool's distance on every pair it weighs for the ten prompts, on main, against the least motion
pairs of equal size 890: the distance is the least over every pairing 890
pairs of unequal size 1360: the distance is the least over every choice of notes 340
the largest gap, 39 semitones: x-x-2-x-0-3 Em [52 59 67] → 0-0-2-x-2-3 A7/E [40 45 52 61 67], distance 47, least 8
prompts whose first pair would move less with the least over every choice of notes: 0 of 10
```

- **Sur `main`, 340 paires de tailles différentes sur 1360 obtiennent le minimum,** et le plus grand écart est là aussi de 39 demi-tons, d'un Em de trois notes à un A7 de cinq notes.

## Le brouillon de skill qui l'appellerait

`skills-dev/_pending-tools/voice-leading/DRAFT.md` est un skill du chatbot écrit pour appeler `ga_voice_leading_pair` ([lignes 1-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L1-L25)). Son nom de fichier le tient à l'écart du chatbot : le chargeur de skills ne lit que les fichiers nommés `SKILL.md`, et le README laisse le brouillon en attente tant que l'outil ne figure pas parmi ceux du chatbot ([README lignes 1-17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L1-L17)). Le brouillon décrit un autre outil que celui de `CompositionTools.cs` :

- un argument `optimize`, `"minimum_movement"` ou `"common_tones"`, que l'outil ne prend pas, et `VoiceMovements`, `TotalSemitones` et `CommonTones` dans la réponse, là où l'outil renvoie des paires de voicings avec une distance ([lignes 31-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L31-L44)) ;
- « a Plücker-line / minimum-displacement solution » ([ligne 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L29)), là où l'outil trie des notes MIDI ;
- un renvoi à `Common/GA.Business.ML/Agents/Mcp/HarmonyMcpTools.cs` ([ligne 74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L74)), un fichier que GA n'a ni au commit épinglé ni sur `main` ;
- un exemple de réponse, de Dm7 à G7, qui annonce un mouvement total de 2 demi-tons, puis liste quatre mouvements de 0, 0, 2 et 1 ([lignes 54-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voice-leading/DRAFT.md#L54-L60)). Leur somme fait 3, la distance de la première paire de l'outil sur `main` et le mouvement minimal de la leçon 18.

## Où le cours s'arrête

- **Le corpus est celui de la leçon 3,** 15 360 voicings sur trois cases, et non l'index de production. Parmi davantage de voicings, les candidats et les paires pourraient être différents (*à vérifier*).
- **Le programme appelle directement la méthode de l'outil,** avec une classe de remplacement pour `VoicingSearchTool`, et non par un client MCP et le serveur de GA.
- **Les verdicts lisent des classes de hauteurs.** Le cours compte comme juste un accord de septième sans quinte, quelle que soit la note qu'il double, et ne juge ni le doigté ni le registre.
- **Seule la première paire est vérifiée en détail.** Le programme compte les paires justes parmi les cinq, mais ne mesure pas comment le défaut de la distance les réordonne.

## Exercices

1. Avec 50 candidats, au commit épinglé, l'outil répond à C → Am par `0-x-2-x-x-0` des deux côtés, pour 0 demi-ton. Que joue ce voicing, et pourquoi une distance de 0 n'est-elle pas une réponse ici ?
2. Calculez la distance de l'outil entre Em `0-2-2-0-0-0`, notes MIDI 40 47 52 55 59 64, et le shell de A7 `x-x-x-2-2-3`, notes MIDI 57 61 67. Quel appariement bouge de 16 ?
3. Au commit épinglé, il ne manque aux 15 candidats de G7 que la quinte. Quelles notes jouent-ils, et comment la leçon 16 appelle-t-elle un tel voicing ?
4. L'outil prend un instrument, « guitar | bass | ukulele ». Que répond-il sur l'index du cours pour « bass » ?

<details>
<summary>Solutions</summary>

1. Trois E : la corde de mi grave à vide, la corde de ré à la deuxième case et la corde de mi aigu à vide. E est une note de C comme de A mineur : le voicing joue donc une partie de chacun, et aucun des deux accords. La requête ne nomme aucun accord, et au commit épinglé ce voicing figure parmi les 50 plus proches des deux requêtes. Apparié avec lui-même, il bouge de 0, et rien dans l'outil ne vérifie ce qu'il joue. Sur `main`, avec 50 candidats, la première paire de C → Am bouge de 2 et joue les deux accords.
2. Triées, les trois notes du shell de A7 s'apparient aux trois plus graves de Em : 40 → 57 donne 17, 47 → 61 donne 14 et 52 → 67 donne 15, soit 46, plus 3 pour chacune des trois notes en trop : 55. Appariées aux trois plus aiguës, 55 → 57, 59 → 61 et 64 → 67 bougent de 2 + 2 + 3 = 7, plus 9 : 16.
3. G, B et F, la fondamentale, la tierce et la septième, rien d'autre : le shell de la leçon 16. Dans le tableau des premières paires, les noms que leur donne l'index commencent par « G7(shell) ».
4. L'erreur « no voicings retrieved for one or both chords » ([lignes 214-221](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L214-L221)) : l'index du cours ne contient que des voicings de guitare, et le filtre n'en garde donc aucun. Avec « guitar », les premières paires sont celles obtenues sans instrument. Vérifié en exécutant l'outil du commit épinglé, hors de la sortie attendue du cours.

</details>

## À retenir

- Un classement par mouvement ne classe que le mouvement : un outil qui apparie ce que renvoie une recherche doit vérifier ce que jouent les voicings, ou se fier à la recherche.
- Davantage de candidats peut dégrader la réponse quand les plus proches voisins s'éloignent de l'accord.
- Apparier les notes triées donne le mouvement minimal entre voicings de même taille ; quand les tailles diffèrent, c'est le choix des notes à apparier qui demande une recherche.
- L'ordre de la chaîne d'un diagramme est un contrat : un consommateur de l'index l'a corrigé, un autre le transmet tel quel.
- Un outil qu'un agent peut appeler n'est pas un outil que le chatbot peut appeler, et un brouillon écrit pour l'un des registres peut décrire un outil qui n'existe dans aucun des deux.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `GaMcpServer/Tools/CompositionTools.cs`, `GaMcpServer/Tools/VoicingSearchTool.cs`, `skills-dev/_pending-tools/voice-leading/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : le même outil et les mêmes brouillons, la recherche de la leçon 16, `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson19.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/VoiceLeadingPairProbe.cs`, `code/ga-ai/Shared/VoicingSearchTool.cs`.
