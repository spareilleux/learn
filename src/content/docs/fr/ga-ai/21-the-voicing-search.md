---
title: "Leçon 21 : la recherche de voicings"
description: "Le serveur MCP de Guitar Alchemist cherche dans son index OPTIC-K de voicings avec ga_search_voicings, et liste avec ga_voicing_vocabulary ce que lit la recherche : 18 fondamentales, 45 qualités d'accords, 23 modes et 188 tags. Le mode n'atteint jamais le vecteur de la requête : « C Lydian » répond comme « C », et « Lydian » seul renvoie les dix premiers voicings de l'index, tous avec un score de 0. Les 188 tags se partagent 12 bits : jazz répond donc comme rock-guitar, rootless comme shell-voicing, et aucun des 100 voicings renvoyés à dix accords de septième suivis du mot rootless n'est rootless. Des mots comme « for », « the » et « what » passent pour des tags, et aucune requête ne peut dépasser 0.70, là où l'exemple du skill affiche 0.9831."
sidebar:
  label: 21. La recherche de voicings
  order: 21
---

La [leçon 20](../20-generated-progressions/) s'achevait sur une remarque de `ga_generate_progression` : « Compose by passing each chord to ga_search_voicings ». `ga_search_voicings` est l'outil avec lequel `GaMcpServer` cherche dans l'index OPTIC-K : il relève dans une requête un accord, un mode et des tags de style ou de technique, en fait un vecteur de requête, et renvoie les voicings les plus proches ([`VoicingSearchTool.cs` lignes 92-236](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L92-L236)). Un second outil, `ga_voicing_vocabulary`, liste ce que lit la recherche, pour qu'un agent puisse reformuler les mots de son utilisateur avant de chercher ([`VoicingVocabularyTool.cs` lignes 24-78](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L24-L78)). Le skill `voicing-search` de GA demande à Claude Code d'appeler une fois le vocabulaire, puis la recherche ([`.claude/skills/voicing-search/SKILL.md` ligne 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L30)). Les leçons 3 et 16 ont ouvert le lecteur et la recherche du côté du chatbot ; cette leçon interroge l'outil.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), les deux outils ne diffèrent que par un commentaire et une description, et le lecteur comme le registre des tags sont inchangés ; l'encodeur de requêtes et la recherche, eux, ont changé : `GaMain` repose donc les questions dont les réponses en dépendent. Le programme compile le `VoicingSearchTool.cs` de GA lui-même, qui sert désormais aussi aux leçons 19 et 20, à la place de la classe de substitution du cours. Il trouve l'index du cours par `GA_OPTICK_INDEX_PATH` ([lignes 64-80](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L64-L80)), et son journal de télémétrie est coupé par `GA_VOICING_NO_TELEMETRY` ([`VoicingTelemetryLog.cs` lignes 33-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/VoicingTelemetryLog.cs#L33-L36)). Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l21
dotnet run --project code/ga-ai/GaMain -c Release -- l21
```

## Comment l'outil lit une requête

`TypedMusicalQueryExtractor` lit la requête mot par mot ([lignes 86-148](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L86-L148)). Le premier mot qui commence par une majuscule et s'analyse comme un accord est l'accord. Ensuite, un mot, ou deux, tirés d'une liste de 23 modes donnent le mode, un instrument devient un filtre, quelques mots de remplissage comme « chord » et « voicing » sont sautés, et tout autre mot d'au moins trois lettres que connaît `SymbolicTagRegistry` devient un tag :

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

Le registre connaît un mot quand c'est l'un de ses tags, ou quand l'un des deux contient l'autre ([`SymbolicTagRegistry.cs` lignes 196-220](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L196-L220)) :

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

`MusicalQueryEncoder` fait ensuite de cette lecture un vecteur ([`MusicalQueryEncoder.cs` lignes 43-108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L43-L108)). STRUCTURE, MODAL et ROOT viennent des classes de hauteurs de l'accord, SYMBOLIC des tags, et MORPHOLOGY et CONTEXT restent à zéro. L'encodeur ne lit jamais le mode :

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

`SymbolicVectorService` donne aux tags 12 dimensions, une par bit du registre, et met à 1 le bit de chaque tag ([`SymbolicVectorService.cs` lignes 13-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs#L13-L32)). La réponse reprend la lecture sous `interpreted`, mode compris, « to confirm the parser understood what the user wanted », comme le dit le skill ([`SKILL.md` ligne 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L92)).

## Le vocabulaire

`ga_voicing_vocabulary` renvoie les fondamentales et les qualités d'accords de `ChordPitchClasses`, les modes du lecteur, et chaque nom que le registre connaît comme tag. Le registre attribue un bit à chaque tag, selon le fichier ou la catégorie d'où il vient ([`SymbolicTagRegistry.cs` lignes 46-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L46-L111)). Le programme lit le vocabulaire, regroupe les tags par bit, et soumet chaque entrée seule à la recherche :

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

- **188 tags, 12 bits.** Un tag met son bit à 1, rien de plus : `jazz`, `rock-guitar`, `flamenco` et `neo-soul` mettent à 1 le même, et les 60 accords célèbres un autre.
- **Huit entrées reprennent une autre entrée sans ses traits d'union.** Le registre ajoute une copie sans traits d'union à chaque tag qui contient un chiffre, pour que « drop2 » trouve le bit de `drop-2-voicings` ([lignes 176-193](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs#L176-L193)) ; le vocabulaire liste les deux.
- **53 tags donnent aussi un accord à la requête.** Quand une requête ne nomme aucun accord, le tag d'un accord célèbre lui donne les notes de cet accord : « Hendrix chord » cherche un E7#9 ([`TypedMusicalQueryExtractor.cs` lignes 157-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L157-L174)).
- **Trois tags sont lus autrement, et cinq modes lisent un tag.** `g5` n'atteint pas les trois lettres qu'exige un tag, et le `.` de `schoenberg-op.16-chord` le coupe en deux. « lydian dominant » et « phrygian dominant » sont lus comme Lydian et Phrygian, parce qu'un mot est essayé avant deux, et « dominant » devient un tag. « harmonic minor », « melodic minor » et « whole tone » gardent leur mode et ajoutent « minor » ou « tone » comme tag.

## Les exemples du vocabulaire lui-même

Le vocabulaire se termine par cinq exemples : ce qu'a dit un utilisateur, et la requête qu'un agent devrait envoyer à la place ([`VoicingVocabularyTool.cs` lignes 63-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L63-L70)). Le programme soumet les deux :

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

- **« something jazzy in F minor » reçoit des voicings de F majeur, au commit épinglé comme sur `main`.** Le lecteur prend « F » pour un accord, une triade majeure, et « minor » pour un mode, que le vecteur ignore. « Fm » reçoit F mineur.
- **« shell voicing for G7 » lit « for » comme un tag.** La requête reçoit les mêmes dix voicings que « G7 shell », avec un score plus bas en tête.
- Les trois autres exemples reçoivent les mêmes voicings que leur reformulation.

## Les modes

La description de l'outil promet « mode names (Lydian, Dorian) » ([ligne 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L95)), et le skill décrit la partition MODAL comme « mode flavor » ([`SKILL.md` ligne 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L14)). Le programme soumet quatre accords suivis de chacun des 23 modes, puis chaque mode seul :

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

- **Un mode ne change rien.** « C Lydian » renvoie les mêmes dix voicings que « C ». Les seuls modes qui changent une réponse sont ceux qui lisent un tag. MODAL est calculé à partir des notes de l'accord, et le nom du mode reste dans `interpreted`.
- **Un mode seul renvoie les dix premiers voicings de l'index.** Sans accord ni tag, chaque partition de la requête est nulle : 18 des 23 modes obtiennent un score de 0 pour chaque voicing, et la recherche renvoie les dix premiers qu'elle lit. `HasIntent` compte un mode comme quelque chose à chercher ([lignes 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)) : l'outil ne donne donc jamais sa réponse pour une requête qu'il ne sait pas lire, « No chord, mode, or known tag recognized » ([lignes 155-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L155-L177)). Le vocabulaire lui-même compte sur les « STRUCTURE and/or MODAL partitions » pour classer les voicings ([`VoicingVocabularyTool.cs` lignes 72-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L72-L76)), et seul un accord les remplit.

## Les tags

Le skill présente les tags comme des techniques et des styles, « drop2, shell, jazz, rootless » ([`SKILL.md` ligne 3](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L3)). Le programme ajoute chacun des 188 tags à trois accords :

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

- **Au commit épinglé, les 188 tags donnent sept réponses à Cmaj7 et à Dm7, et cinq à G7,** dont la réponse de l'accord seul. Dans chaque bit, les tags lus tels qu'on les tape donnent tous la même réponse : `jazz` répond comme `rock-guitar`, et `shell-voicing` comme `rootless`. Sur `main`, les réponses sont moins nombreuses encore, et `jazz` et `shell-voicing` donnent eux aussi la même réponse à Cmaj7.
- **Certains bits ne changent rien.** Pour Cmaj7, les tags des bits 3, 4, 5 et 10, parmi lesquels `caged-system`, `legato` et les formes CAGED, laissent la réponse telle quelle ; sur `main`, le bit 8 les rejoint.

`rootless` et `shell-voicing` viennent de la même catégorie de `SemanticNomenclature.yaml`, Structure, et mettent à 1 le bit 0 ([lignes 129-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/SemanticNomenclature.yaml#L129-L140)). Un voicing rootless omet la fondamentale de l'accord. Le programme soumet dix accords de septième suivis de « rootless », et compte les voicings de l'index qui jouent au moins trois notes, toutes de l'accord, sans sa fondamentale :

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

- **Aucun des 100 voicings renvoyés n'est rootless, ni au commit épinglé ni sur `main`,** alors que l'index en contient entre 5 et 63 pour chaque accord. Au commit épinglé, les premières réponses sont des voicings que l'analyse de GA appelle des shells, fondamentale comprise. Le tag ne peut faire bouger que SYMBOLIC, qui pèse 0.10 du score ; la STRUCTURE de la requête, qui pèse 0.45, contient l'accord entier, fondamentale comprise.

## Des mots lus comme des tags

Un mot devient un tag quand il contient un tag, ou qu'un tag le contient ; le vocabulaire appelle cela un « substring fallback » ([`VoicingVocabularyTool.cs` lignes 58-61](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingVocabularyTool.cs#L58-L61)). Le programme soumet les requêtes d'exemple de GA lui-même, tirées de la description de l'outil, du skill et du brouillon en attente, puis trois requêtes du cours :

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

- **Des mots courants deviennent des tags.** « for » correspond à `normal-form`, « the » à `pitch-axis-theory`, « what » à `so-what-chord` et « end » à `beginner-friendly`. C'est pour cette raison que le lecteur saute « chord » et « voicing », ainsi que les mots de moins de trois lettres, « a », « me », « to » ([lignes 132-147](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L132-L147)) ; « for », « the », « what » et « end » franchissent les deux gardes. Chacun met un bit à 1, et une fois la partition normalisée, un second bit diminue le poids du premier : « G7 shell for » obtient un score inférieur à celui de « G7 shell ». L'exemple du skill lui-même, « something jazzy in F minor for a ballad », lit « for » ([`SKILL.md` ligne 33](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L33)).
- **Sans accord, seul SYMBOLIC peut correspondre.** « Lydian on guitar », « jazz voicings » et « shell voicings » figurent parmi les usages du skill ([ligne 19](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L19)), et obtiennent 0, 0.0577 et 0.0707. Le skill donne « something warm and dreamy » comme une requête dont le lecteur ne tire rien, avec des « arbitrary results » ([ligne 26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L26)) ; l'outil y lit `dreamy`, un tag, et obtient 0.0577.
- **Dans « something warm and mellow », l'exemple de formulation floue de l'outil lui-même, le lecteur ne lit rien,** et l'outil ne renvoie aucun voicing ([ligne 99](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L99)). Son option `allowSampling` demanderait au modèle du client de lire la requête ([lignes 109-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L109-L111)) ; le cours la laisse désactivée.

## Les scores

Le skill explique les scores sous « Why Scores Cluster 0.4–0.98 » : « STRUCTURE (0.45) + MORPHOLOGY (0.25) + CONTEXT (0.20) + SYMBOLIC (0.10) + MODAL (0.10) », et « Near-perfect matches across all partitions approach 1.0 » ([lignes 94-96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L94-L96)) ; son exemple de réponse obtient 0.9831 ([ligne 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L81)). Le programme lit les poids dans `EmbeddingSchema` ([lignes 120-136](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Embeddings/EmbeddingSchema.cs#L120-L136)), et soumet chaque fondamentale, seule et avec chaque qualité :

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

- **Aucune requête ne peut dépasser 0.70.** L'encodeur laisse MORPHOLOGY et CONTEXT à zéro : leurs 0.45 ne comptent donc jamais. Les 828 requêtes d'accords plafonnent à 0.5250 au commit épinglé ; sur `main`, Cmaj7, G7 et A atteignent 0.6000, la somme des poids de STRUCTURE, MODAL et ROOT, et seuls des tags peuvent ajouter les 0.10 restants. Le 0.9831 de l'exemple est hors d'atteinte.
- **Ici, ajouter `jazz` fait monter le score.** Le skill prévient qu'un tag de style « currently *lowers* the score », parce que les voicings de l'index n'ont pas de bits de style ([ligne 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L47)). Sur l'index qu'écrit le code du commit épinglé, « Cmaj7 jazz » obtient un score supérieur à celui de « Cmaj7 », au commit épinglé comme sur `main`. L'index du cours n'est pas l'index de production de GA, où l'avertissement vaut peut-être encore.
- **L'avertissement du skill sur « drop2 » est périmé.** « `drop2` does NOT match — use `drop-2-voicings` » ([ligne 39](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/.claude/skills/voicing-search/SKILL.md#L39)) ; avec les copies sans traits d'union du registre, « drop2 » se lit comme un tag.

## Le brouillon de skill qui l'appellerait

`skills-dev/_pending-tools/voicing-search/DRAFT.md` est un skill du chatbot écrit pour la recherche de voicings, en attente comme ceux des leçons 19 et 20 ([`skills-dev/_pending-tools/README.md` ligne 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L47)). Il appelle un autre outil, `ga_search_voicings_by_query` ([lignes 22-26](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22-L26)) :

- cet outil se trouve dans `GaMcpServer`, dans `VoicingEmbeddingTool.cs`, et envoie la requête à GaApi, qui en calcule l'embedding avec Ollama ([lignes 93-132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingEmbeddingTool.cs#L93-L132)) ; le cours ne peut pas l'exécuter hors ligne ;
- le brouillon le dit « not yet implemented in Common/GA.Business.ML/Agents/Mcp/ » ([ligne 22](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L22)), et renvoie à `Common/GA.Business.ML/Agents/Mcp/VoicingMcpTools.cs` ([ligne 83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L83)), un fichier que GA n'a à aucun des deux commits ;
- il attend `topK`, `instrument` et une réponse faite de `Results` avec `contextTags` et `sourceCorpus` ([lignes 35-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L35-L44)), là où l'outil prend `query` et `limit` et renvoie la réponse de GaApi ;
- son exemple de réponse pour « mellow Cm9 » obtient 0.91 et montre un voicing avec trois tags ([lignes 57-68](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/voicing-search/DRAFT.md#L57-L68)) :

```text
== The parked draft's example answer for "mellow Cm9", at the pin
x-3-5-3-3-3 plays C G A# D G; Cm9 is C D D# G A#, and the voicing leaves out D#
its tag low-density: in the vocabulary no, read as chord Cm9
its tag rootless-on-bass: in the vocabulary no, read as chord Cm9, tags rootless-on-bass
its tag quartal-flavour: in the vocabulary no, read as chord Cm9
```

Le voicing n'a pas de tierce mineure : son diagramme appelle E♭ la troisième case de la corde de sol, et D celle du mi aigu, là où elles jouent B♭ et G. Aucun de ses trois tags ne figure dans le vocabulaire.

## Où le cours s'arrête

- **L'index est celui de la leçon 3,** 15 360 voicings de guitare sur les trois premières cases, et non l'index de production de GA : les réponses et les scores peuvent y différer ; les lectures, elles, ne dépendent pas de l'index.
- **Le filtre d'instrument n'est pas essayé :** l'index du cours ne contient que des voicings de guitare.
- **`allowSampling` reste désactivé,** et `ga_search_voicings_by_query` n'est pas exécuté : les deux demandent un modèle.
- **Le test rootless est celui du cours,** sur les notes que joue chaque voicing.
- **Le programme appelle directement les méthodes des outils,** et non par un client MCP et le serveur de GA.

## Exercices

1. « Lydian on guitar » renvoie dix voicings, tous avec un score de 0. Pourquoi l'outil ne répond-il pas qu'il ne sait pas lire la requête, et pourquoi ces dix-là ?
2. Au commit épinglé, « G7 shell » obtient 0.5078 et « G7 shell for » 0.4932, contre 0.4578 pour « G7 ». D'où viennent les deux écarts ?
3. `jazz` et `rock-guitar` donnent la même réponse à Cmaj7. Pourquoi, et quels autres tags la donnent aussi ?
4. La réponse du brouillon en attente pour « mellow Cm9 » est `x-3-5-3-3-3`. Quelle note de Cm9 ce voicing omet-il, et que devient alors l'accord ?

<details>
<summary>Solutions</summary>

1. `HasIntent` compte le mode « Lydian » comme quelque chose à chercher ([lignes 238-242](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/VoicingSearchTool.cs#L238-L242)) : l'outil cherche donc. L'encodeur ignore le mode, si bien que le vecteur de requête est nul, que chaque voicing obtient 0, et que la recherche garde les dix premiers qu'elle lit, les dix premiers de l'index.
2. « shell » se lit `shell-voicing`, du bit 0 : SYMBOLIC ajoute 0.5078 − 0.4578 = 0.0500. « for » se lit `normal-form`, du bit 10. Une fois normalisés, les deux bits de la requête pèsent chacun 1/√2 ; le bit 0 n'ajoute donc plus que 0.0500/√2, et le bit 10 rien du tout, d'où 0.4578 + 0.0354 = 0.4932.
3. Ils mettent à 1 le même bit, le 7, la catégorie Genre du registre, et la partition SYMBOLIC de la requête est le même vecteur. `flamenco` et `neo-soul`, les deux autres tags de ce bit, donnent aussi cette réponse : le programme a constaté que, dans chaque bit, les tags lus tels qu'on les tape répondent de la même façon.
4. Il joue C G A# D G : il omet D#, soit E♭, la tierce mineure. Sans tierce, l'accord n'est ni mineur ni majeur : c'est un C9 sans tierce.

</details>

## À retenir

- Un lecteur qui reconnaît un mot n'est pas une recherche qui s'en sert : le mode est lu, affiché dans `interpreted`, puis abandonné.
- 188 tags sur 12 bits font 12 mots pour la recherche, pas 188.
- Un tag qui nomme une propriété n'est pas un filtre : les réponses se vérifient contre la propriété.
- Une correspondance par sous-chaîne transforme des mots courants en signaux.
- Une plage de scores documentée se vérifie contre les poids qu'une requête peut remplir.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `GaMcpServer/Tools/VoicingSearchTool.cs`, `GaMcpServer/Tools/VoicingVocabularyTool.cs`, `GaMcpServer/Tools/VoicingEmbeddingTool.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.ML/Embeddings/Services/SymbolicVectorService.cs`, `Common/GA.Business.Config/Configuration/SymbolicTagRegistry.cs`, `Common/GA.Business.Config/SemanticNomenclature.yaml`, `.claude/skills/voicing-search/SKILL.md`, `skills-dev/_pending-tools/voicing-search/DRAFT.md`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : les mêmes outils, le même lecteur et le même registre, et la recherche de la leçon 16.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson21.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/SearchVoicingsProbe.cs`, `code/ga-ai/Shared/SearchIndex.cs`.
