---
title: "Leçon 27 : les notes qui sonnent en dehors"
description: "L'OutsideNotesSkill de Guitar Alchemist dit à un guitariste si une note jouée sur un accord est une note de l'accord, une tension disponible ou une note à éviter, sans modèle. Face aux gammes d'accord d'un manuel, il déclare tenables 4 notes qu'aucune gamme usuelle ne contient et fait de la b9 d'un accord de dominante une note à éviter ; il compte la onzième parmi les notes des accords de treizième, lit 27 des 40 écritures d'accords qu'il connaît et aucun ♯ ni ♭, et écrit C7 avec un A#."
sidebar:
  label: 27. Les notes qui sonnent en dehors
  order: 27
---

Le chatbot de GA répond à « why does F sound outside over Cmaj7? » avec `OutsideNotesSkill`, écrit pour clore l'élément du BACKLOG « Why does this sound outside? ». Il classe une note face à un accord comme note de l'accord, tension disponible ou note à éviter, sans modèle, et présente sa règle comme « the standard jazz-pedagogy definition and is derived **purely from the chord tones** » ([`OutsideNotesSkill.cs`, lignes 12-35](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L12-L35)). Cette leçon confronte cette règle aux gammes qu'un manuel associe à cinq accords de septième, puis examine les accords auxquels le skill l'applique et la façon dont il lit la note et l'accord dans la question.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), celui qu'épingle le cours. Sur le `main` de GA, à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `OutsideNotesSkill.cs` ne fait que marquer son refus `Declined`, et `ChordVocabulary.cs` est le même fichier : le programme ne tourne donc qu'au commit épinglé. La sortie vient de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l27
```

## Comment le skill répond

Le skill cherche un accord après « over », « against » ou « on », prend le dernier mot en forme de note qui le précède, et calcule l'intervalle depuis la fondamentale de l'accord. Une note de la formule de l'accord est une note de l'accord ; une note un demi-ton au-dessus d'une note de l'accord est une note à éviter ; toute autre note est une tension disponible :

```csharp
        var formula = ChordVocabulary.GetFormula(quality);
        var chordPcs = formula.Intervals.Select(i => ((i % 12) + 12) % 12).ToHashSet();
        var rel = ((notePc - rootPc) % 12 + 12) % 12;

        if (chordPcs.Contains(rel))
        {
            var function = ChordToneFunction(formula, rel);
            return new Verdict(
                RelationKind.ChordTone,
                function,
                $"a chord tone — the {function}",
                $"It's part of the chord itself (the {function}), so it sounds fully consonant — " +
                "as inside as a note can be over this chord.");
        }

        var degree = ExtensionLabel(rel);
        // Avoid note = a semitone above a chord tone (forms a b9 clash with it).
        var clashPc = chordPcs.FirstOrDefault(ct => (ct + 1) % 12 == rel, -1);
```

Sur un accord de dominante, une note à éviter reçoit un autre conseil : « exactly the kind of altered tension players reach for », « not a note to simply avoid » ([lignes 164-174](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L164-L174)).

## La règle face à un manuel

Un manuel ne classe pas une note face à l'accord seul, mais face aux gammes qu'on joue dessus : ionien ou lydien sur un accord de septième majeure, dorien, éolien ou phrygien sur une septième mineure, sept gammes sur une septième de dominante, locrien ou locrien #2 sur un accord demi-diminué, et la gamme diminuée ton/demi-ton sur une septième diminuée (`Usual` dans `Lesson27.cs`). Une note qu'aucune d'elles ne contient n'est pas une tension de l'accord. Une note un demi-ton au-dessus d'une note de l'accord est une note à éviter, sauf la b9 et la b13 d'un accord de dominante, qui sont ses tensions altérées. Le programme classe les douze notes sur chaque accord des deux façons :

```text
== The rule against a textbook: c chord tone, t available tension, a avoid note, o in none of the chord's usual scales
chord                        1    b9   9    #9   3    11   #11  5    b13  13   b7   7
Cmaj7              skill     c    a    t    t    c    a    t    c    a    t    t    c
                   textbook  c    o    t    o    c    a    t    c    o    t    o    c
Cm7                skill     c    a    t    c    a    t    t    c    a    t    c    a
                   textbook  c    a    t    c    o    t    o    c    a    t    c    o
C7                 skill     c    a    t    t    c    a    t    c    a    t    c    a
                   textbook  c    t    t    t    c    a    t    c    t    t    c    o
Cm7b5              skill     c    a    t    c    a    t    c    a    t    t    c    a
                   textbook  c    a    t    c    o    t    c    o    t    o    c    o
Cdim7              skill     c    a    t    c    a    t    c    a    t    c    a    t
                   textbook  c    o    t    c    o    t    c    o    t    c    o    t
cells 60: the same 42; avoid notes no usual scale holds 12; tensions no usual scale holds 4: #9 over Cmaj7, b7 over Cmaj7, #11 over Cm7, 13 over Cm7b5; avoid notes the textbook makes tensions 2: b9 over C7, b13 over C7
```

- **Les deux s'accordent sur 42 des 60 notes, et en pratique sur 12 de plus.** Ces 12 notes, qu'aucune gamme usuelle ne contient, le skill les appelle notes à éviter : dans les deux cas, on ne s'y attarde pas.
- **Quatre notes qu'aucune gamme usuelle ne contient deviennent « an available tension », « Safe to sustain as an extension ».** Ce sont la #9 et la b7 sur Cmaj7, la #11 sur Cm7 et la 13 sur Cm7b5. Chacune se trouve un demi-ton sous une note de l'accord, là où la règle ne regarde pas. Cela ne suffit pas à rendre une note inutilisable : la #11 sur Cmaj7 se trouve un demi-ton sous la quinte, et le lydien la contient. Ce que les quatre ont en commun, c'est qu'aucune gamme usuelle de l'accord ne les contient.
- **Le skill fait de la b9 et de la b13 de C7 des notes à éviter.** Pour la b9, la réponse ci-dessous le dit dans son titre, et le contraire dans son explication.

## Quelques réponses

```text
== A few of OutsideNotesSkill's answers
why does Db sound outside over C7
  | **Db** over **C dominant 7**: an avoid note — the b9 (flat ninth).
  | It's the b9 (flat ninth), sitting a semitone above the root of the chord. That half-step rub is why it sounds outside — but over a dominant chord it's exactly the kind of altered tension players reach for (b9 (flat ninth) on the V), so it's usable if you resolve it, not a note to simply avoid.
why does D# sound outside over Cmaj7
  | **D#** over **C major 7**: an available tension — the #9 (sharp ninth).
  | It's the #9 (sharp ninth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does Bb sound outside over Cmaj7
  | **Bb** over **C major 7**: an available tension — the b7 (minor seventh).
  | It's the b7 (minor seventh) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
why does A sound outside over Cm7b5
  | **A** over **C half-diminished**: an available tension — the 13 (thirteenth).
  | It's the 13 (thirteenth) — a non-chord tone, but it isn't a semitone above any chord tone, so it adds colour without clashing. Safe to sustain as an extension.
```

- **Db sur C7 est « an avoid note — the b9 », puis « not a note to simply avoid ».**
- **D# et Bb sur Cmaj7, et A sur Cm7b5, sont « Safe to sustain as an extension ».**

## La onzième dans les accords étendus

```text
== F over C and its extended chords: the first line of the answer, and the chord's notes
chord    answer                                                                        notes
C        **F** over **C**: an avoid note — the 11 (natural eleventh).                  C, E, G
Cmaj7    **F** over **C major 7**: an avoid note — the 11 (natural eleventh).          C, E, G, B
Cmaj9    **F** over **C major 9**: an avoid note — the 11 (natural eleventh).          C, E, G, B, D
Cmaj11   **F** over **C major 11**: a chord tone — the perfect eleventh.               C, E, G, B, D, F
Cmaj13   **F** over **C major 13**: a chord tone — the perfect eleventh.               C, E, G, B, D, F, A
C7       **F** over **C dominant 7**: an avoid note — the 11 (natural eleventh).       C, E, G, A#
C9       **F** over **C dominant 9**: an avoid note — the 11 (natural eleventh).       C, E, G, A#, D
C11      **F** over **C dominant 11**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F
C13      **F** over **C dominant 13**: a chord tone — the perfect eleventh.            C, E, G, A#, D, F, A
Cm7      **F** over **C minor 7**: an available tension — the 11 (natural eleventh).   C, Eb, G, Bb
Cm11     **F** over **C minor 11**: a chord tone — the perfect eleventh.               C, Eb, G, Bb, D, F
```

- **F est une note à éviter sur C, Cmaj7, Cmaj9, C7 et C9, un demi-ton au-dessus de E.** Sur Cmaj11, Cmaj13, C11 et C13, il devient « a chord tone — the perfect eleventh », alors que E est toujours dans l'accord. `ChordVocabulary` construit les accords de onzième et de treizième en empilant les tierces jusqu'à la onzième :

```csharp
        "dominant 11" => new("dominant 11", [0, 4, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "major 11" => new("major 11", [0, 4, 7, 11, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh"]),
        "minor 11" => new("minor 11", [0, 3, 7, 10, 14, 17], [0, 2, 4, 6, 8, 10], ["root", "minor third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh"]),
        "dominant 13" => new("dominant 13", [0, 4, 7, 10, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "minor seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
        "major 13" => new("major 13", [0, 4, 7, 11, 14, 17, 21], [0, 2, 4, 6, 8, 10, 12], ["root", "major third", "perfect fifth", "major seventh", "major ninth", "perfect eleventh", "major thirteenth"]),
```

  En harmonie jazz, un accord de treizième de dominante ou majeur omet la 11 à cause de ce frottement même, et un accord de onzième omet la tierce.
- **Sur Cm7 et Cm11, F est une tension puis une note de l'accord,** comme dans un manuel : un accord mineur n'a pas de tierce majeure contre laquelle la 11 frotterait.

## La lecture de la note

```text
== "why does <note> sound outside over Cmaj7": the note the skill reads, for each way to write it
written      notes     read      misread   not read
natural      7         7         0         0
sharp, #     7         7         0         0
flat, b      7         7         0         0
sharp, ♯     7         0         7         0
flat, ♭      7         0         7         0
lowercase    7         0         0         7
not read right: C♯: C; D♯: D; E♯: E; F♯: F; G♯: G; A♯: A; B♯: B; C♭: C; D♭: D; E♭: E; F♭: F; G♭: G; A♭: A; B♭: B; c: no answer; d: no answer; e: no answer; f: no answer; g: no answer; a: no answer; b: no answer
```

- **Toute note écrite avec `#` ou `b` est bien lue, E#, Fb, B# et Cb compris.**
- **Toute note écrite avec `♯` ou `♭` est lue comme la note naturelle.** La note est une lettre, puis `#` ou `b`, non suivie d'une lettre, d'un chiffre ou d'un `#` ([lignes 295-299](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L295-L299)) : derrière la lettre vient `♭`, et la lettre seule devient la note. La leçon 7 avait trouvé la même chose pour les chiffrages, signalée dans [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **Une note en minuscule n'est pas lue du tout.** L'expression régulière de la note distingue la casse, ce qui empêche aussi de lire l'article « a » comme A ; « why does f sound outside over Cmaj7 » reçoit le refus du skill.

## La lecture de l'accord

L'accord, c'est la fondamentale qui suit la préposition et une suite de `maj`, `min`, `m`, `M`, `dim`, `aug`, `sus`, `add`, `alt`, `ø`, `°`, `Δ`, `+`, de chiffres, de `#` et de `b`, sans distinction de casse :

```csharp
    // "<prep> <root><quality>" — prep is over/against/on; root is A–G + optional
    // accidental; quality is the trailing chord-symbol run (letters/digits/#/b/°/ø/+).
    [GeneratedRegex(@"(?<prep>\bover\b|\bagainst\b|\bon\b)\s+(?:a\s+|an\s+|the\s+)?(?<root>[A-G][#b]?)(?<qual>(?:maj|min|m|M|dim|aug|sus|add|alt|ø|°|Δ|\+|\d|#|b)*)",
        RegexOptions.IgnoreCase)]
    private static partial Regex ChordAfterPrepRegex();
```

Le programme interroge le skill sur F au-dessus de C écrit de 45 façons, et liste les accords qu'il lit autrement :

```text
== "why does F sound outside over C<chord>": the chord the skill reads, for each way to write it
written    read as                its notes          the chord's notes
C-         C                      C E G              C Eb G
C°         C °                    C E G              C Eb Gb
Co         C                      C E G              C Eb Gb
Cdom7      C                      C E G              C E G Bb
Cma7       Cm                     C Eb G             C E G B
CΔ7        C δ7                   C E G              C E G B
CΔ         C δ                    C E G              C E G B
C-7        C                      C E G              C Eb G Bb
Cmi7       Cm                     C Eb G             C Eb G Bb
Cm7♭5      C minor 7              C Eb G Bb          C Eb Gb Bb
C-7b5      C                      C E G              C Eb Gb Bb
Co7        C                      C E G              C Eb Gb A
C7♯9       C dominant 7           C E G A#           C Eb E G Bb
C7sus4     C 7sus4                C E G              C F G Bb
CmMaj7     C mmaj7                C E G              C Eb G B
Cm(maj7)   Cm                     C Eb G             C Eb G B
C7#11      C 7#11                 C E G              C E Gb G Bb
Cmaj7#11   C maj7#11              C E G              C E Gb G B
chords written 45: chords ChordVocabulary has 40, read right 27; chords it doesn't have 5, read right 0
```

- **27 des 40 accords que connaît `ChordVocabulary` sont bien lus, et aucun des 5 qu'il ne connaît pas.**
- **La suite s'arrête à tout autre caractère.** « - » fait lire C-7 comme C, « o » fait lire Co7 comme C, le « a » de ma7 et le « i » de mi7 font lire Cma7 et Cmi7 comme Cm, et « ( » fait lire Cm(maj7) comme Cm. `♭` et `♯` l'arrêtent aussi : Cm7♭5 devient Cm7 et C7♯9 devient C7. `NormalizeQuality` connaît `dom7`, `ma7` et `-7` ([`ChordVocabulary.cs`, lignes 81-83](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L83)), mais la suite ne les lui transmet jamais.
- **Ce que `NormalizeQuality` ne connaît pas devient C E G.** `°` seul n'a pas de cas, `Δ` passe en minuscule et devient `δ`, comme le signale [#783](https://github.com/GuitarAlchemist/ga/issues/783), et 7sus4, mMaj7, 7#11 et maj7#11 ne sont pas dans le vocabulaire. `GetFormula` donne un accord majeur à toute qualité inconnue ([ligne 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). La réponse nomme quand même l'accord par son suffixe, « C 7sus4 », tout en classant F face à C E G.
- **Comme la casse est ignorée, « a » et « the » peuvent devenir la fondamentale.** Dans les prompts d'exemple ci-dessous, « over a minor chord » devient A majeur, et « over a dominant chord » D majeur : l'expression prend « a » pour l'article, puis le « d » de « dominant » pour la fondamentale.

## L'orthographe des notes de l'accord

Les preuves du skill listent les notes de l'accord. Il les nomme à partir de deux tableaux de douze noms, en dièses sauf si l'accord est mineur ou diminué, ou si sa fondamentale est l'une de six tonalités en bémols ([lignes 226-241](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L226-L241)), et n'utilise pas les pas de lettre que `ChordFormula` contient pour cela ([`ChordVocabulary.cs`, lignes 144-156](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L144-L156)) :

```text
== The chord's notes in the skill's evidence, against one letter per chord step, on 12 roots
chord            symbol  right     the first that differs: the skill's, a textbook's
major                    11 of 12  F#: Gb Bb Db; F# A# C#
minor            m       8 of 12   Dbm: Db E Ab; Db Fb Ab
dominant 7       7       9 of 12   C7: C E G A#; C E G Bb
major 7          maj7    11 of 12  F#maj7: Gb Bb Db F; F# A# C# E#
minor 7          m7      8 of 12   Dbm7: Db E Ab B; Db Fb Ab Cb
half-diminished  m7b5    6 of 12   Dbm7b5: Db E G B; Db Fb Abb Cb
diminished 7     dim7    3 of 12   Cdim7: C Eb Gb A; C Eb Gb Bbb
augmented        aug     6 of 12   Eaug: E G# C; E G# B#
```

- **C7 s'écrit C E G A#, F# majeur Gb Bb Db, et Cdim7 C Eb Gb A.** La plupart des septièmes diminuées demandent un double bémol, un Cb ou un Fb, que les tableaux n'ont pas ; 3 sur 12 sortent justes.

## Les prompts d'exemple

```text
== OutsideNotesSkill's example prompts, and a few other ways to ask: CanHandle, and the first line of the answer
prompt                                             CanHandle  answer
why does F sound outside over Cmaj7                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does that note clash over the chord            yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is F an avoid note over Cmaj7                      yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
what is F over G7                                  no         **F** over **G dominant 7**: a chord tone — the minor seventh.
why does the b9 sound so tense over C7             yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
is A a chord tone or a tension over Cmaj7          yes        **A** over **C major 7**: an available tension — the 13 (thirteenth).
why does Bb sound outside over C major             yes        **Bb** over **C**: an available tension — the b7 (minor seventh).
is F# an avoid note or a tension over Cmaj7        yes        **F#** over **C major 7**: an available tension — the #11 (sharp eleventh).
why does F clash over a Cmaj7 chord                yes        **F** over **C major 7**: an avoid note — the 11 (natural eleventh).
why does the note clash over this chord            no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does F sound outside over a minor chord        yes        **F** over **A**: an avoid note — the b13 (flat thirteenth).
why does F sound outside over a dominant chord     yes        **F** over **D**: an available tension — the #9 (sharp ninth).
why does F sound outside on top of Cmaj7           no         Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
why does the 11 clash over Cmaj7                   yes        Tell me a single note and a single chord and I'll say whether it's a chord tone, a tension, or an avoid note — e.g. "why does F sound outside over Cmaj7" or "is A a tension over Cmaj7".
example prompts 10: CanHandle accepts 8
```

- **Deux prompts d'exemple reçoivent le refus.** « why does that note clash over the chord » ne nomme aucune note, et « why does the b9 sound so tense over C7 » nomme un degré : les degrés sont hors du champ du skill ([lignes 31-34](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L31-L34)), mais ce prompt fait partie de ses exemples. « why does the 11 clash over Cmaj7 » reçoit aussi le refus.
- **`CanHandle` en accepte 8 sur 10.** Il lui faut l'un de ses mots-clés, une préposition et un accord ([lignes 65-86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L65-L86)) : « what is F over G7 » n'a pas de mot-clé, alors que le skill y répond, et « why does the note clash over this chord » n'a pas d'accord. Au commit épinglé, l'orchestrateur n'appelle pas `CanHandle` ; sur `main`, le routeur d'intentions le consulte quand il ne peut pas calculer l'embedding d'une question ([leçon 25](../25-what-reaches-the-transpose-skill/)).
- **« on top of » figure dans la liste de prépositions de `CanHandle`, mais pas dans l'expression régulière,** qui veut l'accord juste après « on » : « why does F sound outside on top of Cmaj7 » reçoit le refus.

## Où le cours s'arrête

- **Les gammes d'accord sont celles du cours.** `Usual` dans `Lesson27.cs` liste les gammes que les manuels de jazz donnent d'habitude aux cinq accords. Les triades, les accords de sixte et les accords sus ne sont pas comparés à un manuel : ce qu'on joue dessus dépend davantage de la tonalité.
- **La règle est vérifiée sur C.** Le verdict du skill ne dépend que de l'intervalle depuis la fondamentale ([ligne 145](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs#L145)) ; l'orthographe est vérifiée sur 12 fondamentales.
- **Aucun routeur ne tourne.** La leçon appelle le skill directement.

## Exercices

1. Sur Cm7, pourquoi le skill appelle-t-il F# une tension disponible ? Laquelle des gammes usuelles de Cm7 le contient ?
2. Que répondrait le skill à « why does E sound outside over C7sus4 » ? Que dirait un manuel ?
3. Pourquoi « why does F sound outside over Cma7 » recevrait-il « an available tension — the 11 » ?
4. Comment changer la règle pour que la #9 sur Cmaj7 ne soit plus tenable, tandis que la #11 reste une tension ?

<details>
<summary>Solutions</summary>

1. F# n'est pas dans Cm7, et il n'est pas un demi-ton au-dessus d'une note de l'accord : F, un demi-ton plus bas, n'est pas dans l'accord. Il tombe donc dans « an available tension ». Aucune des gammes dorienne, éolienne et phrygienne ne contient F# : toutes ont F.
2. 7sus4 n'est pas dans `ChordVocabulary` : `GetFormula` donne C E G, et E est une note de l'accord, la tierce majeure. Le C7sus4 d'un manuel est C F G Bb : la quarte remplace la tierce, et E, un demi-ton sous F, est justement la note qu'évite l'accord sus. Raisonnement fait sur le code : le programme interroge le skill sur F au-dessus de C7sus4, pas sur E.
3. La suite s'arrête au « a » de « ma7 » : l'accord est Cm. Sur C Eb G, F est une quarte au-dessus de la fondamentale, et non un demi-ton au-dessus d'une note de l'accord : c'est une tension. Raisonnement fait sur le code et le tableau des accords, où Cma7 se lit Cm.
4. Classer la note face aux gammes de l'accord autant que face à ses notes : une note étrangère à l'accord n'est une tension que si une gamme usuelle de l'accord la contient. La #11 reste une tension sur Cmaj7, puisque le lydien la contient, alors qu'aucune gamme usuelle ne contient la #9.

</details>

## À retenir

- Une note à éviter dépend de la gamme de l'accord, pas de l'accord seul : une règle qui ne regarde que les notes de l'accord ne distingue pas une note inutilisable d'une tension.
- Quand un titre et son explication se contredisent, l'utilisateur lit le titre.
- Une formule d'accord est une affirmation sur la pratique : empiler les tierces jusqu'à la treizième met dans l'accord le frottement que cause la onzième.
- Une expression régulière qui capture une partie d'un symbole doit avoir le même alphabet que le vocabulaire qui l'interprète.
- Écrivez les notes d'un accord d'après ses lettres, pas à partir de douze noms.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/OutsideNotesSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`.
- Le programme du cours : `code/ga-ai/GaAi/Lesson27.cs`.
