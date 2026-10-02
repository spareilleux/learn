---
title: "Leçon 18 : la conduite des voix"
description: "Le chatbot de Guitar Alchemist répond sans modèle aux questions de conduite des voix, en essayant tous les appariements possibles des notes de deux accords. Le cours confronte chaque total au mouvement minimal que trouve un manuel. Entre deux accords de même taille, le total est toujours minimal. Quand les tailles diffèrent, le skill double la fondamentale et demande plus de mouvement que nécessaire dans 1186 réponses sur 3072, dont l'un de ses propres exemples, alors que chaque réponse affirme que tout autre voicing en demande davantage. Il ne lit correctement que 24 des 46 chiffrages, laisse tomber un dièse, un bémol ou un signe de diminué à la fin de la question, lit CM7 comme C mineur septième, écrit A dièse pour B bémol, et le repli hors ligne de GA ne l'atteint jamais."
sidebar:
  label: 18. La conduite des voix
  order: 18
---

La [leçon 17](../17-the-capo-and-the-tunings/) demandait où placer le capodastre et comment sont accordées les cordes. Une fois les accords choisis, reste à savoir comment passer de l'un au suivant. C'est l'objet de la conduite des voix : chaque note d'un accord est une voix, et chaque voix rejoint une note de l'accord suivant en bougeant aussi peu que possible. Le routeur envoie « voice leading from C to F » à `skill.voiceleading`, qui exécute `VoiceLeadingSkill`, enregistré entre les skills du capodastre et des accordages ([`GaPlugin.cs` lignes 85-88](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L85-L88)). Comme eux, il a été écrit le 2026-05-14 pour lever un « dealbreaker » du backlog de GA, et il n'a pas besoin de modèle : il essaie tous les appariements des notes des deux accords et garde celui qui bouge le moins ([`VoiceLeadingSkill.cs` lignes 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L6-L23)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. `VoiceLeadingSkill.cs` est identique sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01) : le programme ne l'interroge donc qu'au commit épinglé. La sortie vient de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l18
```

## Quels prompts atteignent le skill

`CanHandle` renvoie `false`, avec le commentaire « semantic-routing only » ([ligne 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L49)). Sur `main`, quand le routeur ne peut pas calculer l'embedding d'une question, il la confie à la première intention, dans l'ordre d'enregistrement, dont le skill l'accepte par son `CanHandle` ([`SemanticIntentRouter.cs` ligne 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` ligne 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). Le programme démarre l'hôte du chatbot comme dans la leçon 15 et soumet au `CanHandle` de chaque skill les 10 prompts d'exemple du skill :

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                       first skill that accepts it
voice leading from C to F                    none
smooth voice leading C to Am                 none
best voicing from G7 to Cmaj7                skill.chordvoicings
how do I voice lead Dm7 to G7                none
voice leading C major to G major             none
smoothest voicing from Em to A7              skill.chordvoicings
voice leading Fmaj7 to Bm7b5                 none
what's the smoothest voicing from D to A     none
voice lead C7 to F                           none
best way to move from G7 to C                none
skill intents 32; CanHandle of skill.voiceleading accepts 0 of its 10 example prompts
```

- **Sans embeddings, le skill ne répond jamais, alors qu'il n'a pas besoin de modèle.** Deux de ses exemples vont au skill des voicings de la [leçon 16](../16-the-voicings-of-a-chord/), parce qu'ils disent « voicing » : ce skill répond par des doigtés pour un seul accord, pas par le passage d'un accord à l'autre.
- **Sur `main`, un refus peut porter l'indicateur `Declined`,** « so a caller may route it to another handler » ([`GuitarAlchemistAgentBase.cs` lignes 347-352 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)). Les deux refus du skill ne le portent pas ([lignes 280-294](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L280-L294)).

## Comment le skill répond

Le skill lit deux chiffrages de part et d'autre de « to », « → », « -> » ou « > » ([lignes 51-57](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L51-L57)) :

```csharp
    // Two-chord pattern: <chord A> to/→/-> <chord B>. The chord token allows
    // root + optional accidental + optional quality keyword + optional digit
    // + optional flat/sharp-with-digit modifiers (b5, #9, b9...) + optional
    // ° symbol for diminished.
    private static readonly Regex TwoChordPattern =
        new(@"\b(?<a>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\s+(?:to|→|->|>)\s+(?<b>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Il convertit chaque chiffrage en classes de hauteurs, puis apparie les notes des deux accords. Quand un accord a moins de notes que l'autre, il répète sa fondamentale jusqu'à ce que les deux en aient autant ([lignes 101-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L101-L110), [`Pad`, lignes 185-194](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L185-L194)) :

```csharp
        // For an exhaustive minimum-cost matching, we permute the SHORTER chord
        // against subsets of the larger. To keep the explanation crisp, we pad
        // the smaller chord by repeating its root so |A| = |B| for assignment
        // — this is the standard voice-leading framing when voice counts
        // differ (e.g. triad → 7th chord adds a voice that gets the new tone).
        var n = Math.Max(chordA.Length, chordB.Length);
        var paddedA = Pad(chordA, n);
        var paddedB = Pad(chordB, n);

        var (bestPerm, bestCost) = FindBestAssignment(paddedA, paddedB);
```

`FindBestAssignment` essaie toutes les permutations et garde la première dont le total est le plus petit, chaque voix prenant le plus court chemin, soit 6 demi-tons au plus ([lignes 139-183](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L139-L183)). La réponse donne le total, un tableau des voix et une phrase de conclusion : « This is the optimal pitch-class assignment — every other voicing of … requires more total semitone movement » ([ligne 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L131)).

Le programme lit le total et le tableau de chaque réponse. Il nomme les accords de départ et d'arrivée du tableau, et compare le total au **mouvement minimal** : autant de voix que le plus grand des deux accords, toutes les notes des deux accords jouées, et n'importe quelle note du plus petit doublée. Il compte aussi les appariements qui atteignent le total du skill dans le cadre propre au skill, fondamentale doublée.

```text
== VoiceLeadingSkill's example prompts: the chords read, the total motion, and the least motion
prompt                                     asks           reads          total   least  best pairings
voice leading from C to F                  C → F          C → F          3       3      1
smooth voice leading C to Am               C → Am         C → Am         2       2      1
best voicing from G7 to Cmaj7              G7 → Cmaj7     G7 → Cmaj7     3       3      1
how do I voice lead Dm7 to G7              Dm7 → G7       Dm7 → G7       3       3      1
voice leading C major to G major           C → G          declined       -       -      -
smoothest voicing from Em to A7            Em → A7        Em → A7        5       4      1
voice leading Fmaj7 to Bm7b5               Fmaj7 → Bm7b5  Fmaj7 → Bm7b5  3       3      1
what's the smoothest voicing from D to A   D → A          D → A          3       3      1
voice lead C7 to F                         C7 → F         C7 → F         4       4      1
best way to move from G7 to C              G7 → C         G7 → C         4       4      1
```

- **Huit exemples obtiennent le mouvement minimal.** Entre C et F, la voix sur C reste en place, E monte à F et G monte à A : 3 demi-tons.
- **« smoothest voicing from Em to A7 » reçoit 5 demi-tons, là où 4 suffisent.** Em a trois notes et A7 quatre : le skill double donc E. Doubler G ou B à la place donne 4 demi-tons, et la réponse affirme pourtant que tout autre voicing demande plus de mouvement.
- **« voice leading C major to G major » est refusé.** Un accord doit être suivi d'espaces et de « to » : le mot « major » après C fait donc échouer l'expression.

## Le mouvement minimal, accord par accord

Le programme demande « voice leading C… to … » pour les 16 qualités que construit le skill, sur C et sur chacune des 12 fondamentales, et regroupe les réponses selon le nombre de notes des deux accords :

```text
== "voice leading C<quality> to <root><quality>": the 16 qualities the skill builds, on C and on each of the 12 roots
voices   prompts   read right   least motion   more than the least   most extra   several best pairings
3 → 3    432       432          432            0                     0            54
3 → 4    504       504          266            238                   5            69
3 → 5    216       216          34             182                   7            67
4 → 3    504       504          266            238                   5            69
4 → 4    588       588          588            0                     0            56
4 → 5    252       252          79             173                   5            88
5 → 3    216       216          34             182                   7            67
5 → 4    252       252          79             173                   5            88
5 → 5    108       108          108            0                     0            49
prompts 3072: closing on "every other voicing … requires more total semitone movement" 3072, more motion than the least 1186, several best pairings 607
by how much more: 1 semitone 512, 2 semitones 294, 3 semitones 240, 4 semitones 94, 5 semitones 24, 6 semitones 20, 7 semitones 2
the first answers with the most extra motion:
  Csus2 to Em9: 11 semitones, least 4
  Cm9 to Absus2: 11 semitones, least 4
  Cm to Emaj9: 10 semitones, least 4
  Cm to Em9: 10 semitones, least 4
  Cm to Fm9: 9 semitones, least 3
the first answers with the most best pairings:
  Cmaj9 to Em9: 7 pairings
  Cm9 to Abmaj9: 7 pairings
  Csus2 to Em9: 5 pairings
```

- **Entre deux accords de même taille, le total est toujours minimal.** Toutes les permutations sont essayées, et aucune doublure n'est nécessaire.
- **Quand les tailles diffèrent, la fondamentale n'est pas la bonne note à doubler dans 1186 réponses.** La nouvelle voix doit rejoindre la note qui manque au plus petit accord, et la faire partir de la fondamentale peut coûter jusqu'à 7 demi-tons de plus que de la faire partir d'une autre note. De Csus2 à Em9, les deux voix supplémentaires partent de C : 11 demi-tons, là où 4 suffisent. Le commentaire du skill appelle la doublure de la fondamentale « the standard voice-leading framing », et l'harmonie à quatre voix double bien en priorité la fondamentale d'une triade. Mais la réponse est alors le meilleur mouvement avec la fondamentale doublée, pas le mouvement minimal.
- **La phrase de conclusion figure dans les 3072 réponses.** Elle est fausse dans les 1186 réponses où une autre doublure demande moins de mouvement, et dans les 607 où un autre appariement, dans le cadre propre au skill, en demande tout aussi peu.

## Les chiffrages

`BuildChord` met la qualité en minuscules, puis la cherche dans une table de 16 qualités ([lignes 224-252](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L224-L252)) :

```csharp
    private static int[]? BuildChord(int root, string quality)
    {
        var q = quality.ToLowerInvariant().Trim();

        // Tone choices: 1, b3, 3, 4, b5, 5, #5, 6, b7, 7, b9, 9, #9, 11, #11, 13
        int[]? intervals = q switch
        {
            "" or "maj" or "major"           => [0, 4, 7],                     // major triad
            "m" or "min" or "minor" or "-"   => [0, 3, 7],                     // minor triad
            "dim" or "°" or "o"              => [0, 3, 6],                     // dim triad
            "aug" or "+"                     => [0, 4, 8],                     // aug triad
            "7"                              => [0, 4, 7, 10],                 // dom 7
            "m7" or "min7" or "-7"           => [0, 3, 7, 10],                 // min 7
            "maj7" or "major7" or "M7" or "Δ7" or "Δ"
                                             => [0, 4, 7, 11],                 // maj 7
            "m7b5" or "ø" or "ø7" or "half-dim" or "min7b5"
                                             => [0, 3, 6, 10],                 // half-dim
            "dim7" or "°7" or "o7"           => [0, 3, 6, 9],                  // dim 7
            "sus2"                           => [0, 2, 7],
            "sus4" or "sus"                  => [0, 5, 7],
            "6"                              => [0, 4, 7, 9],                  // maj 6
            "m6" or "min6"                   => [0, 3, 7, 9],                  // min 6
            "9"                              => [0, 4, 7, 10, 2],              // dom 9
            "maj9"                           => [0, 4, 7, 11, 2],
            "m9" or "min9"                   => [0, 3, 7, 10, 2],
            // Unknown quality — return null so the caller emits CannotParse
            // instead of pretending the chord is a major triad.
            _                                => null,
        };
```

Le programme écrit chaque chiffrage sur C, d'abord comme premier accord, puis comme dernier :

```text
== Each chord symbol on C, as the first chord ("voice leading C<symbol> to F") and as the last ("voice leading F to C<symbol>")
written    means      first                  last
C          C          right                  right
Cmaj       C          right                  right
C major    C          declined               right
Cm         Cm         right                  right
Cmin       Cm         right                  right
C minor    Cm         declined               reads C
C-         Cm         declined               reads C
Cdim       Cdim       right                  right
C°         Cdim       right                  reads C
Co         Cdim       declined               declined
Caug       Caug       right                  right
C+         Caug       declined               reads C
Csus2      Csus2      right                  right
Csus4      Csus4      right                  right
Csus       Csus4      right                  right
C7         C7         right                  right
Cdom7      C7         declined               declined
Cm7        Cm7        right                  right
Cmin7      Cm7        right                  right
C-7        Cm7        declined               reads C
Cmaj7      Cmaj7      right                  right
CM7        Cmaj7      reads Cm7              reads Cm7
CΔ7        Cmaj7      declined               declined
CΔ         Cmaj7      declined               declined
Cmajor7    Cmaj7      declined               declined
Cm7b5      Cm7b5      right                  right
Cmin7b5    Cm7b5      right                  right
Cø         Cm7b5      declined               declined
Cø7        Cm7b5      declined               declined
Cdim7      Cdim7      right                  right
C°7        Cdim7      declined               reads Cdim
Co7        Cdim7      declined               declined
C6         C6         right                  right
Cm6        Cm6        right                  right
Cmin6      Cm6        right                  right
C9         C9         right                  right
Cmaj9      Cmaj9      right                  right
Cm9        Cm9        right                  right
Cmin9      Cm9        right                  right
Cadd9      Cadd9      declined               declined
C7sus4     C7sus4     declined               declined
C7b9       C7b9       declined               declined
C7#9       C7#9       declined               declined
CmMaj7     CmMaj7     declined               declined
C11        C11        declined               declined
C13        C13        declined               declined
symbols 46: read right as the first chord 24, as the last 24
```

- **La table liste plus de chiffrages que l'expression n'en laisse passer.** Après la fondamentale, l'expression prend un mot parmi `maj`, `min`, `m`, `dim`, `aug`, `sus`, `add` et `dom`, des chiffres, des altérations suivies de chiffres et un `°` final. `Δ`, `ø`, `+`, `-`, `o`, « major7 » et « dom7 » n'atteignent jamais la table, ou l'atteignent sous une forme qu'elle ne liste pas. Comme premier accord, ils sont tous refusés. Comme dernier, `+` et `-` arrêtent l'expression, qui garde la lettre : « voice leading F to C+ » reçoit C majeur. Les autres sont refusés.
- **Les mots qui suivent le dernier accord sont ignorés.** « voice leading F to C minor » reçoit C majeur, et « voice leading F to C major » n'est juste que par hasard.
- **CM7 est lu comme C mineur septième.** La table liste `M7`, mais la qualité est d'abord mise en minuscules, si bien que `m7` correspond le premier. « voice leading CM7 to FM7 » conduit les voix de Cm7 à Fm7. C mineur septième a E♭ et B♭ là où C septième majeure a E et B.
- **Un `°` final tombe.** L'expression se termine par `\b`, une limite de mot, et `°` n'est pas un caractère de mot : « voice leading F to C° » reçoit C majeur. Comme premier accord, `°` est lu, mais « C°7 » est refusé, puisque `°` ne peut que terminer le chiffrage.
- **Sept accords courants sont refusés :** add9, 7sus4, 7♭9, 7♯9, mMaj7, 11 et 13. Le commentaire dit que c'est voulu : une revue du 2026-05-14 avait constaté que les qualités inconnues étaient traitées comme des triades majeures ([lignes 216-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L216-L223)).

## Une fondamentale altérée

Le programme écrit les dix fondamentales altérées, en ASCII et avec `♯` et `♭`, comme premier accord et comme dernier :

```text
== A root with an accidental, first ("voice leading <root> to C") and last ("voice leading C to <root>", "… to <root>m")
notation   first    last     last, m   the root first, spelled   the last, misread as
ASCII #    5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
♯          5 of 5   0 of 5   5 of 5    C#, D#, F#, G#, A#        C, D, F, G, A
ASCII b    5 of 5   5 of 5   5 of 5    Db, Eb, Gb, Ab, A#        -
♭          5 of 5   0 of 5   5 of 5    Db, Eb, Gb, Ab, Bb        D, E, G, A, B
```

- **Un dièse, ou un bémol écrit `♭`, tombe à la fin de la question.** Le même `\b` échoue après `#`, `♯` et `♭`, et l'expression garde la lettre : « voice leading from C to F# » reçoit C → F. La première ligne de la réponse nomme l'accord lu : un lecteur attentif peut donc s'en apercevoir. `b` est une lettre, si bien que « Db » est lu en entier, et avec un `m` après l'altération, la limite tombe après le `m`. Les skills du capodastre et des accordages de la leçon 17 ont le même défaut.
- **Le refus du skill suggère lui-même B°,** « Try a chord-symbol like C, Am, G7, Cmaj7, Dm7, F#m7b5, or B° », qui n'est lu que comme premier accord.

## L'orthographe des réponses

Le skill écrit les notes en dièses, sauf si l'un des deux chiffrages porte un bémol ou si la question contient « flat » ([lignes 85-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L85-L86), [lignes 261-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs#L261-L266)) :

```csharp
    private static bool TokenHasFlats(string token) =>
        token.IndexOf('b', StringComparison.OrdinalIgnoreCase) > 0  // 'b' at position 0 is the note B, not a flat
        || token.IndexOf('♭') >= 0;

    private static string Spell(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];
```

Le programme demande ii7 vers V7 et V7 vers Imaj7 dans les 12 tonalités majeures, et V7 vers i dans les 12 tonalités mineures, puis liste les notes que le skill écrit autrement que leur accord :

```text
== Spelling: ii7 to V7 and V7 to Imaj7 in the 12 major keys, the notes spelled otherwise than in their chord
key   ii7 to V7                          V7 to Imaj7
C     as spelled                         as spelled
G     as spelled                         as spelled
D     as spelled                         as spelled
A     as spelled                         as spelled
E     as spelled                         as spelled
B     as spelled                         as spelled
F#    F for E#                           F for E#
F     A# for Bb                          A# for Bb
Bb    D# for Eb, A# for Bb               A# for Bb, D# for Eb
Eb    G# for Ab, A# for Bb, D# for Eb    as spelled
Ab    as spelled                         as spelled
Db    as spelled                         as spelled
```

```text
== Spelling: V7 to i in the 12 minor keys
key   V7 to i
Cm    D# for Eb
Gm    A# for Bb
Dm    as spelled
Am    as spelled
Em    as spelled
Bm    as spelled
F#m   F for E#
C#m   C for B#
G#m   G for F##
Fm    A# for Bb, G# for Ab
Bbm   A# for Bb, D# for Eb, C# for Db
Ebm   as spelled
prompts 36: every note spelled as in its chord 22
```

- **Une fondamentale B♭ écrite en ASCII ne compte pas comme un bémol.** `TokenHasFlats` cherche un `b` sans tenir compte de la casse, ce qui trouve la fondamentale `B` de « Bb » en position 0, alors que le test exige une position supérieure à 0. « F7 to Bbmaj7 » donne donc A♯ et D♯, et « Bb » comme premier accord s'écrit A♯. Écrite `B♭`, elle compte.
- **Sans bémol dans la question, une tonalité à bémols reçoit des dièses.** D7 vers Gm donne A♯ pour B♭ : le skill ne connaît pas la tonalité, seulement les deux chiffrages.
- **Douze noms ne suffisent pas à écrire tous les accords.** Le skill a un nom par classe de hauteurs. En F♯ majeur, E♯ s'écrit F. Le B♯ de G♯7 s'écrit C, et le F double dièse de D♯7 s'écrit G.

## Autres formulations

```text
== Other phrasings
prompt                                         asks                   reads            verdict
how do I get from G7 to a C chord              G7 → C                 G7 → A           wrong chord
voice leading Dm7 to G7 to Cmaj7               Dm7 → G7 → Cmaj7       Dm7 → G7         reads 2 of 3 chords
voice leading CM7 to FM7                       Cmaj7 → Fmaj7          Cm7 → Fm7        wrong chord
voice leading G7 → C                           G7 → C                 G7 → C           right
voice leading G7 - C                           G7 → C                 declined         declined
voice leading from G7 into C                   G7 → C                 declined         declined
voice leading from C to F#                     C → F#                 C → F            wrong chord
voice leading from G to B°                     G → Bdim               G → B            wrong chord
smooth voice leading from C major to A minor   C → Am                 declined         declined
how do I voice lead Bb to Eb                   Bb → Eb                Bb → Eb          right
```

- **L'article « a » est lu comme l'accord A.** L'expression ignore la casse : dans « how do I get from G7 to a C chord », l'accord qui suit « to » est donc « a », et le skill conduit G7 vers A majeur.
- **Une progression de trois accords ne reçoit que son premier mouvement.** L'expression lit une seule paire, et la réponse ne dit pas qu'elle s'est arrêtée.
- **« - » et « into » ne sont pas lus comme « to »,** et les accords écrits en toutes lettres sont refusés.

## Où le cours s'arrête

- **Le routeur et le modèle ne sont pas exécutés.** Savoir quelle intention le routeur choisit pour ces questions en production demande les embeddings (*à vérifier*).
- **Le mouvement minimal est le critère du cours :** toutes les notes des deux accords jouées, autant de voix que le plus grand des deux. Un manuel peut aussi omettre la quinte d'un accord de septième, ce qui demanderait encore moins de mouvement, et il place les voix dans des registres. Le skill et le cours travaillent tous deux sur des classes de hauteurs : un « voicing » n'a donc ici ni octave ni case.
- **Un autre chemin de GA conduit de vrais voicings.** L'outil MCP `ga_voice_leading_pair` apparie des voicings jouables de l'index OPTIC-K avec « a greedy sorted-pitch matching », « not a formal Hungarian-optimal assignment » ([`CompositionTools.cs` lignes 179-186](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L179-L186)). Le cours ne l'exécute pas.

## Signalé en amont

- Signalés après l'écriture de cette leçon, dans le ticket de GA [#789](https://github.com/GuitarAlchemist/ga/issues/789) : la doublure de la fondamentale et la réponse qui se dit optimale, les chiffrages, les altérations, l'orthographe des notes, les formulations et `CanHandle`.

## Exercices

1. « voice leading from C to F# » reçoit C → F. Donnez deux façons d'écrire la question pour que le skill conduise C vers F♯ majeur.
2. Le skill conduit Em vers A7 en 5 demi-tons. Quelle note de Em faut-il doubler pour n'en bouger que 4, et comment ?
3. Pourquoi « voice leading F7 to Bbmaj7 » écrit-il A♯ et D♯, alors que « voice leading F7 to B♭maj7 » écrit B♭ et E♭ ? Donnez une troisième façon d'obtenir des bémols.
4. « voice leading CM7 to FM7 » et « voice leading Cmaj7 to Fmaj7 » reçoivent tous deux 4 demi-tons. Comment la réponse montre-t-elle que la première conduit d'autres accords ?

<details>
<summary>Solutions</summary>

1. L'écrire en bémol, `Gb` : `b` est une lettre, la limite tient donc après lui, et « voice leading from C to Gb » conduit C vers G♭ en 6 demi-tons, avec des notes écrites en bémols. Ou ajouter une qualité : « voice leading from C to F#maj » se termine sur le `j`, et reçoit les mêmes 6 demi-tons, avec des notes écrites en dièses. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
2. G ou B. En doublant B : E reste, G reste, B descend à A et l'autre B monte à C♯, 0 + 0 + 2 + 2. En doublant G : E reste, G reste, l'autre G monte à A, et B monte à C♯, 0 + 0 + 2 + 2. Le skill double E, qui doit descendre de 3 demi-tons jusqu'à C♯ pendant que B descend de 2 jusqu'à A. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
3. `TokenHasFlats` cherche `b` sans tenir compte de la casse et trouve le `B` de « Bbmaj7 » en position 0, qu'il prend pour la note B ; `♭` est trouvé directement. Avec « flat » n'importe où dans la question, par exemple « voice leading F7 to Bbmaj7 in flats », la réponse est écrite en bémols. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
4. Par ses notes : le tableau de la première donne D♯ et A♯, les E♭ et B♭ de Cm7, là où Cmaj7 a E et B. La première ligne reprend en outre « CM7 → FM7 », ce qui masque l'erreur de lecture. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.

</details>

## À retenir

- Une recherche optimale ne l'est que sur ce qu'elle explore : essayer toutes les permutations trouve le meilleur appariement, pas la meilleure doublure.
- Une réponse qui se dit optimale avance une affirmation que le programme peut vérifier, réponse par réponse, contre une recherche exhaustive plus lente.
- Une table de chiffrages ne promet que ce que l'expression placée devant elle laisse passer.
- `\b` échoue après `#`, `♯`, `♭` ou `°`, et l'expression garde la lettre : c'est le même défaut que dans les leçons 7, 9 et 17.
- Une recherche du bémol `b` insensible à la casse trouve la note B.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/VoiceLeadingSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/CompositionTools.cs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : le même skill, `Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- Le programme du cours : `code/ga-ai/GaAi/Lesson18.cs`.
