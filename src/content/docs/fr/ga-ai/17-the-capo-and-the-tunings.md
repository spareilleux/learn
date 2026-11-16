---
title: "Leçon 17 : le capodastre et les accordages"
description: "Le chatbot de Guitar Alchemist répond sans modèle aux questions de capodastre et d'accordage. Le cours confronte chaque réponse à un manuel. L'arithmétique du capodastre est juste, mais le skill tire le sens du calcul et la tonalité de formulations figées : il répond par une forme quand on lui demande ce qu'on entend avec un capodastre, lit l'article a comme la tonalité A et une tonalité diésée sans « major » comme sa seule lettre, écrit D dièse là où la tonalité est E bémol, et ne sait pas dire où placer le capodastre. Le skill des accordages laisse tomber les dièses des six notes qu'il lit, nomme D standard l'accordage E bémol standard écrit en dièses, et donne l'open D pour l'open D mineur. Le repli hors ligne de GA n'atteint aucun des deux skills."
sidebar:
  label: 17. Le capodastre et les accordages
  order: 17
---

La [leçon 16](../16-the-voicings-of-a-chord/) demandait où placer les doigts pour jouer un accord. Deux questions viennent avant celle-là : où mettre le capodastre, et comment sont accordées les cordes. Deux skills du chatbot y répondent sans modèle ; tous deux ont été écrits le 2026-05-14 pour lever deux « dealbreakers » du backlog de GA. Le routeur envoie « what shape do I play in E with capo 4 » à `skill.capo`, qui exécute `CapoSkill`, et « what is DADGAD tuning » à `skill.alternatetunings`, qui exécute `AlternateTuningsSkill` ([`GaPlugin.cs` lignes 83 et 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L80-L93)). Le premier fait de l'arithmétique en demi-tons, le second consulte une table de neuf accordages ([`CapoSkill.cs` lignes 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L6-L23), [`AlternateTuningsSkill.cs` lignes 6-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L6-L23)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Entre celui-ci et le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `CapoSkill` n'a fait que poser l'indicateur `Declined` sur son refus, ce qui laisse ses réponses inchangées. `AlternateTuningsSkill` a en outre changé les expressions qui lisent le nom d'un accordage. Le programme interroge donc le skill du capodastre au commit épinglé, et celui des accordages au commit épinglé et dans `GaMain`, le programme de la leçon 16 compilé à partir du `main` de GA. Les deux programmes compilent les questions d'accordage à partir de `code/ga-ai/Shared/TuningsProbe.cs`. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l17
dotnet run --project code/ga-ai/GaMain -c Release -- l17
```

## Quels prompts atteignent les deux skills

Le `CanHandle` des deux skills renvoie `false`, avec le commentaire « semantic-routing only » ([`CapoSkill.cs` ligne 47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L47), [`AlternateTuningsSkill.cs` ligne 50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L50)), au commit épinglé comme sur `main`. Sur `main`, quand le routeur ne peut pas calculer l'embedding d'une question, il la confie à la première intention, dans l'ordre d'enregistrement, dont le skill l'accepte par son `CanHandle` ([`SemanticIntentRouter.cs` ligne 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` ligne 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). Le programme démarre l'hôte du chatbot comme dans la leçon 15 et soumet au `CanHandle` de chaque skill les 22 prompts d'exemple des deux skills :

```text
== Without embeddings: the first skill, in registration order, whose CanHandle accepts each example prompt
prompt                                                           first skill that accepts it
What shape do I play in E with capo 4                            none
Song is in E, what chord shape with capo on 4                    none
Capo on 3, song in G, what shape                                 none
I play a C shape with capo 3 — what does it sound like           none
What does a G shape sound like with capo 2                       none
Capo on 5, song in A                                             none
If I capo on 2 and play an Em shape, what's the sounding chord   skill.chordinfo
What's the sounding key if I play in G with capo on 5            none
Capo 7, D shape — sounding chord                                 none
What chord shape for B major with capo 4                         skill.chordvoicings
what is DADGAD tuning                                            none
what's drop D tuning                                             none
how do I tune to drop C                                          none
drop C tuning notes                                              none
how do I tune to open G                                          none
open D tuning notes                                              none
what is double drop D tuning                                     none
what's half step down tuning                                     none
whole step down tuning notes                                     none
DGCGCD tuning explained                                          none
how is DADGAD different from standard                            none
what tuning is Eb Ab Db Gb Bb Eb                                 none
skill intents 32; CanHandle of skill.capo and skill.alternatetunings accepts 0 of their 22 example prompts
```

- **Sans embeddings, aucun des deux skills ne répond, alors qu'aucun n'a besoin de modèle.** Le repli a été ajouté sur `main` pour que les skills déterministes répondent quand le service d'embeddings est en panne. Les skills du capodastre et des accordages sont déterministes, et ne reçoivent pourtant jamais de question par ce chemin. Deux des exemples du capodastre vont à d'autres skills : le skill d'information sur les accords prend celui qui nomme Em, le skill des voicings celui qui demande une « chord shape for B major ».

## Le capodastre

Un capodastre monte chaque corde d'autant de demi-tons que le numéro de sa case. Le guitariste joue la forme, l'auditeur entend la forme plus la case. `CapoSkill` lit la question avec deux expressions, l'une pour une forme, l'autre pour la tonalité entendue, et essaie d'abord la forme ([lignes 52-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L52-L64), [lignes 89-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L89-L104)) :

```csharp
    private static readonly Regex SoundingToShape =
        new(@"(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual>major|minor|maj|min))?\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?(?:song\s+(?:is\s+)?in\s+|key\s+(?:is\s+|of\s+)?|in\s+)(?<key2>[A-Ga-g][b#♭♯]?)(?:\s+(?<qual2>major|minor|maj|min))?\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Pattern B: "<shape> shape with capo <N>" → SOUNDING
    // Shape-side anchor: "<note> shape" or "play a <note> shape" or "<note>m shape"
    private static readonly Regex ShapeToSounding =
        new(@"\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape>[A-Ga-g][b#♭♯]?m?)\s+shape\b[^.?!]*?\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n>\d{1,2})\b" +
            @"|" +
            @"\bcapo\s+(?:on\s+|fret\s+|at\s+)?(?<n2>\d{1,2})\b[^.?!]*?\b(?:play(?:ing)?\s+(?:a\s+|an\s+)?)?(?<shape2>[A-Ga-g][b#♭♯]?m?)\s+shape\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Le programme pose au skill ses 10 prompts d'exemple, et compare chaque réponse à ce que demande le prompt : la forme à jouer, ou l'accord qu'on entend.

```text
== CapoSkill's example prompts: what each asks, and the answer
prompt                                                           asks         answer         verdict
What shape do I play in E with capo 4                            shape C      shape C        right
Song is in E, what chord shape with capo on 4                    shape C      shape C        right
Capo on 3, song in G, what shape                                 shape E      shape E        right
I play a C shape with capo 3 — what does it sound like           sounds Eb    sounds D#      right, theoretical spelling
What does a G shape sound like with capo 2                       sounds A     sounds A       right
Capo on 5, song in A                                             shape E      shape E        right
If I capo on 2 and play an Em shape, what's the sounding chord   sounds F#m   sounds F#m     right
What's the sounding key if I play in G with capo on 5            sounds C     shape D        wrong direction
Capo 7, D shape — sounding chord                                 sounds A     sounds A       right
What chord shape for B major with capo 4                         shape G      declined       declined
```

```text
== Other phrasings
prompt                                                   asks           answer         verdict
song in Em, capo 2, what shape                           shape Dm       declined       declined
song in E minor, capo 2, what shape                      shape Dm       shape Dm       right
What shape do I play in e with capo 4                    shape C        shape C        right
what shape for F with capo 3                             shape D        declined       declined
capo on 3 in G, what shape                               shape E        shape E        right
Capo on 2, song in F#, what shape                        shape E        shape D#       wrong chord
song in C#, capo 4, what shape                           shape A        shape G#       wrong chord
song in B♭, capo 1, what shape                           shape A        shape A#       wrong chord
I'm in a band, capo 2, song is in G                      shape F        shape G        wrong chord
Playing in D with capo 2, what key does it sound in?     sounds E       shape C        wrong direction
I play a C7 shape with capo 3, what does it sound like   sounds Eb7     declined       declined
what does a Cmaj7 shape sound like with capo 2           sounds Dmaj7   declined       declined
capo 2, Dsus4 shape, what chord do I hear                sounds Esus4   declined       declined
```

- **Le sens du calcul dépend de la formulation, pas de la question posée.** Sauf si la question nomme une forme, une tonalité après « in » est prise pour la tonalité entendue, et le skill répond par la forme à jouer. Son propre exemple « What's the sounding key if I play in G with capo on 5 » reçoit la forme D au lieu de la tonalité entendue, C, et il en va de même pour « Playing in D with capo 2, what key does it sound in? ».
- **L'article « a » est lu comme la tonalité A.** Les deux expressions ignorent la casse : dans « I'm in a band, capo 2, song is in G », le premier « in » est suivi de « a », et le skill donne la forme à jouer pour A.
- **Une tonalité diésée ou bémolisée sans « major » ni « minor » derrière elle est lue comme sa seule lettre.** L'expression de la tonalité se termine par `\b`, une limite de mot. `#`, `♯` et `♭` ne sont pas des caractères de mot : après eux, la limite échoue, et l'expression se rabat sur la lettre seule. « Capo on 2, song in F# » reçoit la forme D♯ au lieu de E, « song in C#, capo 4 » G♯ au lieu de A, et « song in B♭, capo 1 » A♯ au lieu de A. `b` est une lettre, si bien que « Bb » est lu en entier. La [leçon 7](../07-chord-names/) disait que ce skill et celui des accordages acceptent `♭` et `♯` : leurs expressions prévoient bien les deux signes, mais les laissent tomber ici. Avec « major » ou « minor » après la tonalité, la limite tombe après le mot, et c'est pourquoi la grille du cours, plus bas, est bien lue.
- **Le skill refuse ce que ses expressions ne prévoient pas.** Une tonalité doit suivre « in » ou « key » : « What chord shape for B major with capo 4 », l'un de ses propres exemples, est donc refusé. Une tonalité mineure doit être écrite en toutes lettres, si bien que « song in Em » est refusé. Une forme, c'est une lettre, une altération et un `m` facultatif : les formes C7, Cmaj7 et Dsus4 sont refusées.

## L'orthographe des réponses

Le skill écrit sa réponse en dièses, sauf si la tonalité ou la forme qu'il a lue porte un bémol, ou, pour une forme, si la question contient « flat » ([lignes 178-191](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L178-L191)) :

```csharp
    /// <summary>
    /// Pick the enharmonic spelling that matches the user's preferred side.
    /// If the user said "Eb major" → flats. If "F# major" → sharps.
    /// Default: sharps (guitarist convention).
    /// </summary>
    private static string SpellPc(int pc, bool preferFlats) =>
        preferFlats ? FlatNames[((pc % 12) + 12) % 12] : SharpNames[((pc % 12) + 12) % 12];

    private static bool KeyIsFlat(string keyRaw) =>
        keyRaw.IndexOf('b') >= 0 || keyRaw.IndexOf('♭') >= 0;

    private static bool ShapeIsFlat(string shapeRaw, string fullMessage) =>
        shapeRaw.IndexOf('b') >= 0 || shapeRaw.IndexOf('♭') >= 0
        || fullMessage.Contains("flat", StringComparison.OrdinalIgnoreCase);
```

Le programme demande les 30 tonalités qu'écrit une armure, majeures et mineures, avec le capodastre de la case 1 à la case 11, puis les huit formes ouvertes avec le capodastre sur les mêmes cases. Il qualifie une réponse de **right, theoretical spelling** quand la note est juste, mais que la tonalité ou l'accord qu'elle nomme est de ceux qu'aucune armure n'écrit, comme D♯ majeur :

```text
== "Song is in <key>, what shape with capo <fret>": 30 keys, frets 1 to 11
key      prompts   right   right, theoretical spelling    wrong   declined
major    165       127     27 (A# D# G#)                  0       11 (Cb)
minor    165       159     6 (Dbm Gbm)                    0       0
the answers' "an Am shape at capo N would sound as …m": 319, a wrong chord 0, a theoretical minor key 16
```

```text
== "What does a <shape> shape sound like with capo <fret>": the eight open shapes, frets 1 to 11
shape    prompts   right   wrong   declined   right, theoretical spelling
C        11        8       0       0          3, capo 3: D#, 8: G#, 10: A#
A        11        8       0       0          3, capo 1: A#, 6: D#, 11: G#
G        11        8       0       0          3, capo 1: G#, 3: A#, 8: D#
E        11        8       0       0          3, capo 4: G#, 6: A#, 11: D#
D        11        8       0       0          3, capo 1: D#, 6: G#, 8: A#
Am       11        11      0       0          0
Em       11        11      0       0          0
Dm       11        11      0       0          0
```

- **L'arithmétique n'est jamais fausse.** Dans les deux grilles, aucune réponse ne donne un mauvais accord.
- **L'orthographe l'est souvent.** 27 formes de la grille majeure, et 3 des 11 réponses pour chaque forme ouverte majeure, sont A♯, D♯ ou G♯ majeur, qu'un manuel écrit B♭, E♭ et A♭. Le commentaire de la classe elle-même dit qu'une forme de C avec le capodastre en case 3 sonne en E♭ ([ligne 13](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L13)) ; le skill répond D♯. Une tonalité mineure écrite avec des bémols donne sa forme en bémols : D♭m et G♭m, qu'un manuel écrit C♯m et F♯m.
- **C♭ majeur est refusé.** La table des fondamentales n'a pas de C♭ ([lignes 67-76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs#L67-L76)), alors que son armure compte sept bémols.

## Où placer le capodastre

La première question que se pose un guitariste va dans l'autre sens : où placer le capodastre pour jouer dans une tonalité avec les formes ouvertes C, A, G, E et D. L'arithmétique est la même, faite à rebours. Le programme pose la question pour les 12 tonalités, et liste les cases 0 à 7 qui donnent une forme ouverte :

```text
== "Where should I put the capo to play in <key> with open chords?"
key   frets 0 to 7 that give an open shape: C A G E D  the skill's answer
C     0 C, 3 A, 5 G                                    declined
Db    1 C, 4 A, 6 G                                    declined
D     0 D, 2 C, 5 A, 7 G                               declined
Eb    1 D, 3 C, 6 A                                    declined
E     0 E, 2 D, 4 C, 7 A                               declined
F     1 E, 3 D, 5 C                                    declined
F#    2 E, 4 D, 6 C                                    declined
G     0 G, 3 E, 5 D, 7 C                               declined
Ab    1 G, 4 E, 6 D                                    declined
A     0 A, 2 G, 5 E, 7 D                               declined
Bb    1 A, 3 G, 6 E                                    declined
B     2 A, 4 G, 7 E                                    declined
```

- **Le skill refuse les 12.** Ses deux expressions exigent un numéro de case dans la question.

## Les accordages

`AlternateTuningsSkill` lit le nom d'un accordage avec neuf expressions, une par accordage de sa table ([lignes 53-74](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L53-L74)), et répond par les six notes, corde grave en premier, avec l'écart de chaque corde par rapport à l'accordage standard :

```csharp
    private static readonly (Regex Pattern, string Key)[] TuningPatterns =
    [
        // DADGAD — contiguous or hyphenated
        (new Regex(@"\b(?:dadgad|d-a-d-g-a-d)\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dadgad"),
        // Drop D — but NOT "double drop D"
        (new Regex(@"(?<!\bdouble\s)(?<!\bdouble-)\bdrop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-d"),
        // Double drop D
        (new Regex(@"\bdouble[\s-]?drop[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "double-drop-d"),
        // Drop C — the (?![#b]) rejects "drop C#" / "drop Cb", which are
        // different tunings not in this table (better no match than a wrong one).
        (new Regex(@"\bdrop[\s-]?c\b(?![#b])", RegexOptions.IgnoreCase | RegexOptions.Compiled), "drop-c"),
        // Open G
        (new Regex(@"\bopen[\s-]?g\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-g"),
        // Open D
        (new Regex(@"\bopen[\s-]?d\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "open-d"),
        // DGCGCD (Sonic Youth / Pink Floyd style)
        (new Regex(@"\bdgcgcd\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "dgcgcd"),
        // Half step down
        (new Regex(@"\bhalf[\s-]?step[\s-]?down\b|\beb\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "half-step-down"),
        // Whole step down
        (new Regex(@"\bwhole[\s-]?step[\s-]?down\b|\bd\s+standard\b", RegexOptions.IgnoreCase | RegexOptions.Compiled), "whole-step-down"),
    ];
```

```text
== AlternateTuningsSkill's example prompts: the tuning each one gets
prompt                                   answer                         verdict
what is DADGAD tuning                    DADGAD                         right
what's drop D tuning                     Drop D                         right
how do I tune to drop C                  Drop C                         right
drop C tuning notes                      Drop C                         right
how do I tune to open G                  Open G                         right
open D tuning notes                      Open D                         right
what is double drop D tuning             Double Drop D                  right
what's half step down tuning             Half-step down (Eb standard)   right
whole step down tuning notes             Whole-step down (D standard)   right
DGCGCD tuning explained                  DGCGCD                         right
how is DADGAD different from standard    DADGAD                         right
what tuning is Eb Ab Db Gb Bb Eb         Half-step down (Eb standard)   right
```

```text
== The nine tunings of the skill's table: notes and moves from standard, against a textbook
tuning                         notes                  moves from standard        as a textbook
DADGAD                         D A D G A D            -2st same same same -2st -2st right
Drop D                         D A D G B E            -2st same same same same same right
Double Drop D                  D A D G B D            -2st same same same same -2st right
Drop C                         C G C F A D            -4st -2st -2st -2st -2st -2st right
Open G                         D G D G B D            -2st -2st same same same -2st right
Open D                         D A D F# A D           -2st same same -1st -2st -2st right
DGCGCD                         D G C G C D            -2st -2st -2st same +1st -2st right
Half-step down (Eb standard)   Eb Ab Db Gb Bb Eb      -1st -1st -1st -1st -1st -1st right
Whole-step down (D standard)   D G C F A D            -2st -2st -2st -2st -2st -2st right
```

- **La table est juste.** Les 12 exemples reçoivent leur accordage, et les notes et les écarts des neuf accordages sont ceux d'un manuel.

## Un accordage donné par ses notes

Quand aucun nom ne correspond, le skill lit les six premières notes de la question et cherche dans sa table un accordage de même orthographe ([lignes 203-211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L203-L211), [lignes 228-238](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L228-L238)) :

```csharp
    private static string[]? TryParseSixNoteTuning(string msg)
    {
        var matches = Regex.Matches(msg, @"\b[A-Ga-g][b#♭♯]?\b");
        if (matches.Count < 6) return null;
        // Take the first 6 — accept that if the user mentions extra pitches
        // elsewhere in the prompt we might pick up garbage. Common phrasings
        // tend to put the 6 notes right next to each other.
        var arr = new string[6];
        for (var i = 0; i < 6; i++) arr[i] = NormalizeNote(matches[i].Value);
        return arr;
    }
```

Le programme demande « what tuning is … » avec les notes des neuf accordages, de l'accordage standard et de l'accordage E♭ standard écrit en dièses, dans quatre notations : en ASCII, avec `♯` et `♭`, avec des traits d'union entre les notes, et en minuscules. Il attend l'accordage de la table qui a les mêmes hauteurs, ou, si aucun ne les a, les notes demandées :

```text
== "what tuning is …" with the six notes, at the pin: the tuning each notation gets
tuning                         ASCII            ♯ and ♭          hyphens          lower case
DADGAD                         right            right            right            right
Drop D                         right            right            right            right
Double Drop D                  right            right            right            right
Drop C                         right            right            right            right
Open G                         right            right            right            right
Open D                         other notes      other notes      other notes      other notes
DGCGCD                         right            right            right            right
Half-step down (Eb standard)   right            other notes      right            right
Whole-step down (D standard)   right            right            right            right
standard                       right            right            right            right
Eb standard, in sharps         another tuning   another tuning   another tuning   another tuning
questions 44: answered with the tuning asked or its notes 35, with another named tuning 4, other answers 5
  Open D, every notation: no name, reads D A D F A D
  Half-step down (Eb standard), ♯ and ♭: no name, reads E A D G B E
  Eb standard, in sharps, every notation: Whole-step down (D standard)
```

- **L'expression laisse tomber les dièses, et les bémols écrits `♭`.** Elle se termine par `\b`, comme la tonalité du capodastre. F♯ est lu comme F : les notes de l'open D, D A D F♯ A D, sont donc lues D A D F A D, ce qui ne correspond à aucun accordage, dans toutes les notations. E♭ A♭ D♭ G♭ B♭ E♭ est lu E A D G B E, l'accordage standard, que le skill ne nomme pas.
- **L'accordage E♭ standard écrit en dièses est nommé Whole-step down.** D♯ G♯ C♯ F♯ A♯ D♯ est lu D G C F A D, un accordage plus bas d'un demi-ton sur chaque corde, et la réponse donne son nom et sa table.
- **Sur `main`, la lecture des six notes est celle du commit épinglé,** et `GaMain` affiche le même tableau.

## Les accordages hors de la table

Le programme demande dix accordages par leur nom, hors de la table ou écrits avec une altération, et compare les notes de la réponse à l'accordage demandé :

```text
== Tunings outside the table, at the pin
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   Drop C: C G C F A D              another tuning
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   Drop D: D A D G B E              another tuning
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

```text
== Tunings outside the table, on main
prompt                                       asks for            answer                           verdict
what is open D minor tuning                  D A D F A D         Open D: D A D F# A D             another tuning
what is open G minor tuning                  D G D G Bb D        Open G: D G D G B D              another tuning
what is open E tuning                        E B E G# B E        declined                         declined
what is open C tuning                        C G C G C E         declined                         declined
what is drop B tuning                        B F# B E G# C#      declined                         declined
what is C standard tuning                    C F Bb Eb G C       declined                         declined
what is drop C# tuning                       C# G# C# F# A# D#   declined                         declined
what is drop C♯ tuning                       C# G# C# F# A# D#   declined                         declined
what is drop D♭ tuning                       Db Ab Db Gb Bb Eb   declined                         declined
what is standard tuning                      E A D G B E         declined                         declined
"What does an Em shape look like in drop-D": Drop D, the answer names Em: no
```

- **L'open D mineur reçoit l'open D, et l'open G mineur l'open G.** L'expression de l'open D s'arrête au `d`, et le « minor » qui suit n'est pas lu. La réponse donne F♯ là où le guitariste demandait F, et B là où il demandait B♭.
- **Au commit épinglé, « drop C♯ » reçoit le drop C, et « drop D♭ » le drop D.** Au commit épinglé, l'expression du drop C rejette un `#` ou un `b` ASCII après sa lettre, mais ni `♯` ni `♭`, et celle du drop D n'a aucun contrôle de ce genre. Sur `main`, les expressions du drop D, du double drop D, du drop C, de l'open G et de l'open D rejettent les quatre signes, et les deux questions sont refusées ([lignes 57-67 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L57-L67)).
- **Les accordages hors de la table sont refusés,** comme le veut le commentaire du drop C : « better no match than a wrong one ». L'accordage standard en fait partie.
- **Le commentaire de la classe promet une réponse que le code ne donne pas.** Il cite « What does an Em shape look like in drop-D » avec « caveat about altered low E string » ([ligne 15](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs#L15)). Le skill répond par la table du drop D, qui ne nomme pas Em.

## Où le cours s'arrête

- **Le routeur et le modèle ne sont pas exécutés.** Savoir quelle intention le routeur choisit pour ces questions en production demande les embeddings (*à vérifier*).
- **L'orthographe théorique est le critère du cours :** une tonalité ou un accord, majeur ou mineur, dont aucune armure n'écrit la fondamentale avec cette qualité. Un guitariste qui lit une grille d'accords peut accepter A♯ pour B♭ ; une armure, non.
- **Le skill du capodastre n'est exécuté qu'au commit épinglé.** Sur `main`, `CapoSkill` n'en diffère que par l'indicateur `Declined` de son refus, ce qu'on sait en lisant le diff.

## Signalé en amont

- Signalés après l'écriture de cette leçon : dans le ticket de GA [#787](https://github.com/GuitarAlchemist/ga/issues/787), le sens du calcul, les altérations, les refus et l'orthographe du skill du capodastre, ainsi que son `CanHandle` ; dans [#788](https://github.com/GuitarAlchemist/ga/issues/788), la lecture des six notes par le skill des accordages, les accordages ouverts mineurs et la mise en garde promise pour le drop D.

## Exercices

1. Pourquoi « song in Em, capo 2, what shape » est-il refusé ? Que répond le skill du commit épinglé à « song in E min, capo 2, what shape » ?
2. Comment un guitariste peut-il obtenir B♭ plutôt que A♯ à partir de la question « What does an A shape sound like with capo 1 » ?
3. Au commit épinglé, que répond le skill des accordages à « what tuning is D A D Gb A D » ? Laquelle de ses deux étapes l'empêche de nommer l'open D ?
4. Au commit épinglé, pourquoi « what is drop Db tuning » est-il refusé, alors que « what is drop D♭ tuning » reçoit le drop D ?

<details>
<summary>Solutions</summary>

1. Après la tonalité, l'expression attend une limite de mot, ou une espace suivie de `major`, `minor`, `maj` ou `min`. « Em » ne forme qu'un mot : la limite échoue entre E et m, et la question est refusée. « song in E min, capo 2, what shape » reçoit la forme Dm. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
2. En mettant le mot « flat » n'importe où dans la question, par exemple « What does an A shape sound like with capo 1, in flats » : pour une forme, le skill écrit des bémols quand la question contient « flat », et répond B♭. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
3. Aucun nom, avec les notes D A D Gb A D. Ici, la lecture est complète, puisque `b` est une lettre, mais `NotesMatch` compare des orthographes : G♭ n'est pas F♯. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.
4. En ASCII, `b` est une lettre : il n'y a donc pas de limite de mot entre `D` et `b`, et l'expression du drop D ne correspond pas. La question ne contient pas non plus six notes, si bien que le skill refuse. `♭` n'est pas un caractère de mot : la limite tient entre `D` et `♭`, et l'expression correspond. Vérifié en exécutant le skill du commit épinglé, hors de la sortie attendue du cours.

</details>

## À retenir

- Une réponse qui relève de l'arithmétique se vérifie contre un manuel, prompt par prompt : ici, chaque tonalité qu'écrit une armure sur chaque case, et 44 accordages donnés par leurs notes.
- Une expression qui lit une tonalité doit prendre l'altération avec la lettre : `\b` échoue après `#`, `♯` ou `♭`, et l'expression ne garde que la lettre.
- Un skill qui tire le sens du calcul de la formulation répond à l'autre question dès que la formulation change.
- L'orthographe fait partie de la réponse : D♯ et E♭ sont la même case, pas la même tonalité.
- Un skill qui se passe de modèle devrait être accessible sans modèle.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/CapoSkill.cs`, `Common/GA.Business.ML/Agents/Skills/AlternateTuningsSkill.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : les deux mêmes skills, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson17.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/TuningsProbe.cs`.
