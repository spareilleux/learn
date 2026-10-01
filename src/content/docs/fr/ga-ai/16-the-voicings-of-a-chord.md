---
title: "Leçon 16 : les voicings d'un accord"
description: "Le chatbot de Guitar Alchemist répond sans modèle, à partir de l'index OPTIC-K, quand on lui demande les voicings d'un accord. Le cours joue chaque diagramme qu'il renvoie, au commit épinglé et avec le pipeline de voicings du main de GA, qui a changé depuis. Sur main, chaque voicing joue l'accord que le skill a lu. La lecture et les noms décident du reste : « minor » et toutes les qualités en toutes lettres sont lus comme une triade majeure, CanHandle rejette un accord majeur écrit sans suffixe, C-7 est lu comme C7, et dans une grille de 144 accords, les accords de sixte, huit triades augmentées et six triades sus4 n'ont aucun voicing à eux, parce que l'index les nomme autrement ; enfin, des 48 voicings renvoyés pour une technique, cinq relèvent de cette technique."
sidebar:
  label: 16. Les voicings d'un accord
  order: 16
---

La [leçon 15](../15-the-notes-of-a-chord/) demandait au chatbot quelles notes forment un accord. Cette leçon lui pose la question que se pose ensuite un guitariste : où placer les doigts. Le routeur envoie « voicings for Cmaj7 » à l'intention `skill.chordvoicings`, qui exécute `ChordVoicingsSkill` ([`GaPlugin.cs` ligne 108](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L108)) ; un commentaire de GA le présente comme le skill le plus utilisé du chatbot ([`ChordVoicingsSkill.cs` ligne 14](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L14)). Il n'appelle aucun modèle. `TypedMusicalQueryExtractor` relève dans la question un accord, un mode et des mots de technique, `MusicalQueryEncoder` en fait un vecteur de requête, et l'index OPTIC-K de la [leçon 3](../03-index-and-search/) renvoie les voicings les plus proches, filtrés par le nom de l'accord ([lignes 75-167](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L75-L167)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA, l'essentiel du pipeline de voicings a changé après le commit épinglé : entre celui-ci et [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `git diff --stat` compte 17 fichiers modifiés, répartis entre le skill, `VoicingAgent`, `Search/`, `Embeddings/`, `VoicingDocumentFactory`, les services de domaine des voicings et la CLI qui écrit l'index. Le code qui lit la question n'a pas changé : `TypedMusicalQueryExtractor.cs` est identique, tout comme `ChordPitchClasses`, le `CanHandle` du skill et ses deux expressions. Le programme fait donc lire les questions au commit épinglé, et demande les réponses deux fois : au commit épinglé, et dans un second programme, `GaMain`, compilé à partir d'un second clone de GA à `f4f5b4a`. Les deux compilent les mêmes questions, tirées de `code/ga-ai/Shared/ChordVoicingsProbe.cs`. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l16
dotnet run --project code/ga-ai/GaMain -c Release -- l16
```

## Quels prompts atteignent le skill

Sur `main`, quand le routeur ne peut pas calculer l'embedding d'une question, il se replie sur le `CanHandle` de chaque skill ([`SemanticIntentRouter.cs` ligne 321](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321), [`OrchestratorSkillIntent.cs` ligne 29](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). `ChordVoicingsSkill.CanHandle` exige un mot qui renvoie aux voicings et un accord ([lignes 57-73](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L57-L73)) :

```csharp
    public bool CanHandle(string message)
    {
        if (string.IsNullOrWhiteSpace(message)) return false;
        var q = message.ToLowerInvariant();
        // Whole-word match so a keyword embedded in an unrelated word doesn't
        // fire (e.g. "shell" inside "PowerShell" — see ga#261).
        var hasVoicingIntent = VoicingKeywords.Any(k => ChordIntentMatching.ContainsWord(q, k));
        if (!hasVoicingIntent) return false;
        // Require a real chord token. The two regexes are case-sensitive on the
        // root so bare lowercase "a"/"e" in normal English ("show me a shape")
        // won't trigger. Strict form requires an accidental/quality/digit
        // immediately after the root (Cmaj7, G7, F#m); spaced form allows
        // "[A-G] major/minor/dim/aug/sus" with whitespace between root and
        // quality (Bb major, C minor).
        return ChordSuffixRegex().IsMatch(message)
               || ChordWithSpacedQualityRegex().IsMatch(message);
    }
```

Un accord, c'est une fondamentale en majuscule suivie d'un suffixe, ou d'un mot de qualité après une espace ([lignes 178-185](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L178-L185)) :

```csharp
    [GeneratedRegex(@"\b[A-G][#b]?(?:maj|min|m|M|dim|aug|sus|add|alt|°|Δ|11|13|5|6|7|9)\w*\b")]
    private static partial Regex ChordSuffixRegex();

    // Spaced quality form: "C major", "Bb minor", "F# augmented". Quality word
    // accepts upper- and lower-case first letters but requires the root to be
    // an uppercase chord letter.
    [GeneratedRegex(@"\b[A-G][#b]?\s+(?:[Mm]ajor|[Mm]inor|[Mm]aj|[Mm]in|[Dd]im|[Aa]ug|[Ss]us)\b")]
    private static partial Regex ChordWithSpacedQualityRegex();
```

Le programme démarre l'hôte du chatbot comme dans la leçon 15, prend le skill qui se trouve derrière l'intention et soumet à `CanHandle` chacun de ses 12 prompts d'exemple ([lignes 31-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L31-L45)), puis demande à l'extracteur de l'hôte ce qu'il y lit :

```text
== The skill's example prompts: CanHandle, and the chord TypedMusicalQueryExtractor reads
prompt                           CanHandle  chord read             also read
voicings for Cmaj7               yes        Cmaj7: C E G B         tags for
show me Dm7 voicings             yes        Dm7: C D F A
shapes for F major               yes        F: C F A               mode major, tags for
fingerings for G7                yes        G7: D F G B            tags for
Cmaj9 voicings                   yes        Cmaj9: C D E G B
drop2 voicings of Cmaj7          yes        Cmaj7: C E G B         tags drop2
shell voicing for Dm7            yes        Dm7: C D F A           tags shell for
rootless A7 voicings             yes        A7: C# E G A           tags rootless
quartal voicings in C            no         C: C E G               tags quartal
all C major voicings on guitar   yes        C: C E G               mode major, tags all, instrument guitar
open chord shape for E minor     yes        E: E G# B              mode minor, tags open for
barre voicings for Bb major      yes        Bb: D F A#             mode major, tags for
```

```text
== Other phrasings
prompt                           CanHandle  chord read             also read
voicings for C                   no         C: C E G               tags for
G chord shapes                   no         G: D G B
how do I play a D chord          no         D: D F# A
voicings for A minor             yes        A: C# E A              mode minor, tags for
voicings for Am                  yes        Am: C E A              tags for
voicings for am                  no         no chord               tags for
Bb voicings please               no         Bb: D F A#
voicings for F#m7b5              yes        F#m7b5: C E F# A       tags for
voicings for C7(b9)              yes        C7(b9): C C# E G A#    tags for
voicings for C/G                 no         C/G: C E G             tags for
```

- **`CanHandle` rejette l'un de ses propres exemples, et tout accord majeur écrit sans suffixe.** « quartal voicings in C » contient bien un mot qui renvoie aux voicings, mais une fondamentale seule n'est un accord pour aucune des deux expressions. « voicings for C », « G chord shapes » et « Bb voicings please » sont rejetés de la même façon, et « voicings for C/G » aussi : `/` n'est pas un suffixe. « how do I play a D chord » ne contient aucun mot de ce genre.
- **« minor » est lu comme un mode, et l'accord comme une triade majeure.** L'extracteur prend pour accord le premier mot en majuscule que `ChordPitchClasses` sait analyser ([`TypedMusicalQueryExtractor.cs` lignes 90-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L90-L102)) ; « A » s'analyse comme A majeur, et « minor » figure dans la liste des modes ([lignes 104-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L104-L111)). « voicings for A minor » donne A majeur, et l'exemple « open chord shape for E minor » donne de même E majeur. Le commentaire de `CanHandle` cite « C minor » parmi les formes qu'il accepte.
- **Une lecture partielle tient le modèle à l'écart.** L'extracteur de l'hôte ne consulte un modèle que lorsque la lecture typée ne trouve rien ([lignes 217-226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs#L217-L226)). Dans « voicings for am », il ne lit aucun accord : en production, la question irait à un modèle, que le cours n'exécute pas. « voicings for A minor » donne A majeur, si bien qu'aucun modèle ne la voit jamais.

## Les symboles et les qualités en toutes lettres

`ChordPitchClasses` construit l'accord à partir de son suffixe au lieu de le chercher dans une table. Il ramène les variantes du suffixe à une seule forme, en retire les altérations, les ajouts et les omissions, puis la triade et les extensions, et refuse un suffixe qui laisse un reste qu'il ne sait pas expliquer ([`MusicalQueryEncoder.cs` lignes 240-336](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L240-L336)) :

```csharp
        // ── normalize symbol variants (case matters: 'M7' = major7, 'm' = minor) ──
        w = Regex.Replace(w, "△|Δ", "maj");
        w = Regex.Replace(w, "ø|Ø", "m7b5");
        w = Regex.Replace(w, @"M(?=7|9|11|13|6)", "maj");        // M7 / M9 / M13 → major-7th family
        w = w.Replace("Maj", "maj").Replace("MAJ", "maj").Replace("Major", "maj").Replace("major", "maj");
        w = w.Replace("Min", "min").Replace("MIN", "min").Replace("minor", "min");
        w = w.Replace("M", "maj");                                // any lone uppercase M ⇒ major
        // The major-7th marker is now canonical, so folding to lower case leaves a residual
        // 'm' meaning unambiguously minor.
        w = w.ToLowerInvariant();
        w = w.Replace("°", "dim").Replace("o7", "dim7");
```

```csharp
        // residue check: anything left (besides separators) means it was not a chord symbol.
        var residue = Regex.Replace(w, @"[\s/()+\-]", "");
        if (residue.Length > 0) return false;
```

Le programme demande les 51 symboles de la leçon 15 sous la forme « voicings for C… » et les 31 qualités en toutes lettres sous la forme « voicings for C … », et compare l'accord que lit l'extracteur à celui d'un manuel :

```text
== The 51 symbols of lesson 15, asked as "voicings for C…"
read as a textbook spells them: 47 of 51
  Cdom7: no chord, a textbook's C E G A#
  Cma7: no chord, a textbook's C E G B
  C-7: C-7: C E G A#, a textbook's C D# G A#
  C7+5: no chord, a textbook's C E G# A#
symbols ChordPitchClasses and ChordVocabulary read as different chords: 5: Cdom7 Cma7 CΔ7 C-7 C7+5
```

```text
== The 31 spelled-out qualities, asked as "voicings for C …"
CanHandle accepts 13 of 31; read as a textbook spells them: 1
  read as C: C E G: 31, major, minor, diminished, augmented, power, dominant, …
```

- **47 des 51 symboles sont lus comme un manuel les orthographie.** `dom7`, `ma7` et `7+5` laissent des lettres ou un chiffre que l'analyseur ne sait pas expliquer, et la question ne donne aucun accord. `C-7` est lu comme C7 : le contrôle du reste prend `-` pour un séparateur, si bien que le signe mineur disparaît et que la septième devient une septième de dominante.
- **Le chatbot a deux lecteurs de chiffrages, et ils divergent sur cinq des 51.** `ChordVocabulary`, qu'utilise `ChordInfoSkill` (leçon 15), associe `dom7` à une septième de dominante, `ma7` à une septième majeure, `-7` à une septième mineure et `7+5` à une septième de dominante à quinte augmentée ([`ChordVocabulary.cs` lignes 81-87](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L81-L87)) ; `ChordPitchClasses` ne lit aucun accord pour trois d'entre eux, et une septième de dominante pour `-7`. Le cinquième, `CΔ7`, c'est le `δ7` du vocabulaire, vu à la leçon 15.
- **Chaque qualité en toutes lettres est lue comme C majeur.** L'analyseur ne lit que « C », et les mots qui suivent deviennent un mode, des étiquettes ou rien du tout. Seul « major » donne le bon accord. `CanHandle` en accepte 13 sur 31, celles qui commencent par « major » ou « minor » : dans son expression avec espace, `dim` et `aug` doivent terminer un mot, alors que « diminished » et « augmented » continuent au-delà.

## Ce que jouent les réponses, au commit épinglé

La réponse du skill liste chaque voicing avec un nom et un diagramme. Le programme joue le diagramme : chaque corde qui sonne donne sa note à vide plus sa case, et les classes de hauteurs du voicing sont l'ensemble de ces notes. Il les compare à l'accord que demande le prompt, tel qu'un manuel l'orthographie : **exact** quand le voicing joue ces notes et aucune autre, **more** quand il les joue avec d'autres, **part** quand il n'en joue qu'une partie, **other** dans les autres cas. Au commit épinglé, le diagramme est la chaîne de GA, qui commence par la corde 1, le mi aigu (différence 13 de l'entrée du 2026-09-14 du [journal](../journal/), corrigée sur `main`) :

```text
== The example prompts' answers, at the pin: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               2          2      0      0      0
show me Dm7 voicings             1          0      0      0      1
shapes for F major               8          8      0      0      0
fingerings for G7                8          1      0      7      0
Cmaj9 voicings                   8          0      0      8      0
drop2 voicings of Cmaj7          2          2      0      0      0
shell voicing for Dm7            1          0      0      0      1
rootless A7 voicings             5          0      0      5      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          2      0      3      3
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          6      0      2      0
```

```text
== "show me Dm7 voicings": the answer, and what each voicing plays (asked: C D F A)
Found 1 voicing:
name             diagram          score    plays
Bm7(shell)/D     x-0-2-0-x-x      0.342    D A B            other
```

- **Au commit épinglé, Dm7 reçoit un seul voicing, et ce n'est pas Dm7.** `Bm7(shell)/D` joue D, A et B. Au commit épinglé, le filtre sur le nom cherchait la qualité comme sous-chaîne du nom stocké et prenait la note la plus grave pour la fondamentale ([`OptickSearchStrategy.cs` lignes 315-324](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L315-L324)) : `m7` figure dans `Bm7(shell)/D`, dont la note la plus grave est D. C'est la différence 11 du journal, corrigée sur `main`.

Le programme demande ensuite 144 accords, 12 qualités sur 12 fondamentales, sous la forme « voicings for <chord> ». Le corpus de la leçon 3, produit par le générateur de voicings de GA sur les trois premières cases, contient chaque accord de la grille ; le programme le vérifie, et s'arrête s'il en manque un :

```text
== A grid of 144 chords, at the pin: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    2      9      1      other 20, part 15
m        1      9      2      other 20, part 8
7        0      5      7      other 7, part 38
maj7     1      8      3      more 2, other 9, part 26
m7       0      6      6      other 12, part 26
dim      3      8      1      more 11, other 10, part 1
aug      8      4      0      more 1, other 2, part 1
sus4     2      5      5      more 2, other 12, part 34
m7b5     0      6      6      other 5, part 32
dim7     6      1      5      other 1, part 46
6        0      2      10     more 1, other 1, part 84
9        1      1      10     other 7, part 70
voicings returned: 841; exact 337, more 17, part 381, other 106
```

- **Au commit épinglé, 337 des 841 voicings jouent l'accord demandé, et pour 56 des 144 accords, aucun ne le joue.** La plupart des autres en jouent une partie (381), comme les shells de G7 sans quinte.

## Les mêmes questions sur main

`GaMain` construit le corpus et l'index de la leçon 3 avec le générateur, l'analyse, l'embedding et l'écrivain d'index de `main`, et construit le skill comme le fait l'hôte ([`ServiceCollectionExtensions.cs` lignes 78-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs#L78-L111), inchangé sur `main`). Sur `main`, le skill écrit ses diagrammes dans l'ordre des grilles d'accords, mi grave en premier ([`ChordVoicingsSkill.cs` ligne 136](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L136)) :

```text
== Corpus on main: GA's VoicingGenerator, standard tuning, 3 frets, window 3, at least 3 notes
voicings                 15360
the names main's analysis gives the voicings of five chords, with their counts:
  C6, C E G A            Am7/G 24, Am7/E 17, Am7 6, Am7/C 2
  C6/9, C D E G A        C6/E 11, C6/G 11, C6 1, C6/A 1
  Dsus4, D G A           Gsus2 24, Gsus2/A 13, Gsus2/D 2
  Dbaug, Db F A          Faug 14, Faug/A 7
  Caug, C E G#           Caug/E 14, Caug 6, Caug/Ab 1
```

```text
== The example prompts' answers, on main: what each voicing plays
prompt                           voicings   exact  more   part   other
voicings for Cmaj7               8          8      0      0      0
show me Dm7 voicings             8          8      0      0      0
shapes for F major               8          8      0      0      0
fingerings for G7                8          8      0      0      0
Cmaj9 voicings                   8          8      0      0      0
drop2 voicings of Cmaj7          8          8      0      0      0
shell voicing for Dm7            8          8      0      0      0
rootless A7 voicings             8          8      0      0      0
quartal voicings in C            8          0      0      0      8
all C major voicings on guitar   8          8      0      0      0
open chord shape for E minor     8          0      0      0      8
barre voicings for Bb major      8          8      0      0      0
```

```text
== A grid of 144 chords, on main: "voicings for <chord>" on 12 roots
For each quality, the roots whose answer has only voicings that play the chord, some, or none;
the corpus holds every chord of the grid. Then what the voicings that aren't the chord play.
quality  all    some   none   the other voicings play
major    10     2      0      more 4
m        10     2      0      more 3
7        12     0      0
maj7     10     2      0      more 2
m7       10     2      0      part 2
dim      10     2      0      more 6
aug      4      0      8      more 61
sus4     3      3      6      more 57, part 1
m7b5     11     1      0      more 1
dim7     12     0      0
6        0      0      12     more 74
9        8      4      0      more 7
voicings returned: 1097; exact 879, more 215, part 3, other 0
```

- **Sur `main`, chaque voicing que renvoie le skill joue l'accord qu'il a lu.** 10 des 12 exemples reçoivent 8 voicings de leur accord ; les deux autres reçoivent l'accord mal lu, E majeur pour « E minor » et C majeur pour « quartal voicings in C ». Sur la grille, 879 des 1 097 voicings jouent exactement l'accord, aucun ne joue un autre accord (other 0), et le reste joue l'accord avec d'autres notes (215) ou une partie de l'accord (3).
- **Les accords de sixte, huit triades augmentées et six triades sus4 n'ont aucun voicing à eux, alors que le corpus les contient tous.** L'index nomme C E G A « Am7 », jamais « C6 », et nomme « C6 » le 6/9 C D E G A : « voicings for C6 » reçoit des voicings de 6/9 nommés C6. Il nomme D G A « Gsus2 » et D♭ F A « Faug ». Le filtre sur le nom compare la fondamentale et la qualité du nom stocké à celles de la demande ([`OptickSearchStrategy.cs` lignes 307-319](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L307-L319)), et coupe le nom stocké à sa première parenthèse ([lignes 348-349](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L348-L349)) : `Dbaug(maj7)/C`, D♭ F A plus C, passe donc pour D♭ augmenté. Quand aucun nom stocké ne passe, le skill relance la recherche sans le filtre ([lignes 109-115](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L109-L115)), et les voicings les plus proches de Dsus4 sont des D7sus4.

```csharp
        var filterChord = filters.ChordName is { Length: > 0 } cn ? ParseChordName(cn) : null;

        foreach (var r in pool)
        {
            var d = r.Document;
            if (filterChord is { } fc)
            {
                if (ParseChordName(d.ChordName) is not { } docChord) continue;
                if (docChord.RootPitchClass != fc.RootPitchClass) continue;
                if (!string.Equals(docChord.Quality, fc.Quality, StringComparison.Ordinal)) continue;
                if (fc.BassPitchClass is int bass
                    && (d.MidiNotes.Length == 0 || ((d.MidiNotes.Min() % 12) + 12) % 12 != bass)) continue;
            }
```

## Les techniques

Six des 12 prompts d'exemple nomment une technique, et la description du skill les promet : « drop2, shell, rootless, quartal, barre » ([lignes 24-29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs#L24-L29)). Le programme vérifie chaque voicing des réponses de `main` avec les définitions du cours, toutes lues sur le diagramme :

- **drop2** : quatre notes sur quatre cordes, les quatre notes de l'accord, et monter la plus grave d'une octave donne une position serrée où elle est la deuxième note en partant du haut ;
- **shell** : la fondamentale, la tierce et la septième, rien d'autre ;
- **rootless** : au moins trois notes de l'accord, sans la fondamentale ;
- **quartal** : au moins trois notes empilées en quartes justes à partir de la fondamentale ; « quartal voicings in C » est compris comme C F B♭ ;
- **open** : l'accord avec au moins une corde à vide ;
- **barre** : l'accord sans corde à vide, avec la même case sur la plus grave et sur la plus aiguë des cordes qui sonnent.

Le tableau compte les voicings qui jouent l'accord, ceux qui relèvent de la technique, et les voicings du corpus qui en relèvent :

```text
== The techniques the example prompts name, on main
prompt                           voicings   chord    technique  in the corpus
drop2 voicings of Cmaj7          8          8        2          3
shell voicing for Dm7            8          8        0          19
rootless A7 voicings             8          8        0          45
quartal voicings in C            8          0        0          1
open chord shape for E minor     8          0        0          60
barre voicings for Bb major      8          8        3          11
```

```text
== "open chord shape for E minor": the answer, and what each voicing plays (asked: E G B)
Found 8 voicings:
name             diagram          score    plays
E/B              x-2-x-1-x-0      0.635    E G# B           other
E                0-x-x-1-0-x      0.635    E G# B           other
E                0-2-x-1-x-x      0.635    E G# B           other
E                0-2-x-1-x-0      0.635    E G# B           other
E                0-2-x-1-0-0      0.635    E G# B           other
E/Ab             x-x-x-1-0-0      0.632    E G# B           other
E                x-x-2-1-0-x      0.632    E G# B           other
E                x-x-2-1-0-0      0.632    E G# B           other
```

- **5 des 48 voicings relèvent de la technique demandée,** 2 drop2 et 3 voicings barrés ; aucun n'est un shell, un A7 rootless, un voicing quartal ou un E mineur ouvert, alors que le corpus en contient respectivement 19, 45, 1 et 60.
- **GA laisse tomber les techniques à dessein, et le dit à sa télémétrie, pas au guitariste.** Sa décision d'architecture ADR-0002 explique que l'index ne porte que le diagramme, le nom inféré, l'instrument et les notes MIDI : le chemin de l'index respecte donc le nom de l'accord, la plage de hauteurs, l'instrument et les filtres de confort, et déclare abandonnés les autres filtres, dont `Tags` et `ModeName` ([`OptickSearchStrategy.cs` lignes 101-130](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Search/OptickSearchStrategy.cs#L101-L130), [`0002-voicing-filter-parity-cpu-gpu-only.md`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md)). `VoicingAgent` inscrit les filtres abandonnés dans son journal de télémétrie ([`VoicingAgent.cs` lignes 110-126](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/VoicingAgent.cs#L110-L126)) ; `ChordVoicingsSkill` n'enregistre rien, et sa réponse commence par « Found 8 voicings: ».
- **Les six techniques se lisent sur le diagramme et l'accordage,** comme le fait ici le cours. ADR-0002 applique les filtres de confort sur le chemin de l'index pour cette raison même : toutes les stratégies disposent du diagramme.

## Où le cours s'arrête

- **Le corpus est celui de la leçon 3,** 15 360 voicings sur trois cases, et non l'index de production. Parmi davantage de voicings, les plus proches pourraient être différents (*à vérifier*).
- **Le routeur et le modèle ne sont pas exécutés.** Savoir quelle intention le routeur choisit pour ces prompts demande les embeddings, et savoir ce qu'un modèle lit dans « voicings for am » demande le modèle (*à vérifier*).
- **Les définitions des techniques sont celles du cours,** tout comme la lecture de « quartal voicings in C ».
- **`GaMain` construit le skill comme le fait l'hôte, mais sans l'hôte.** Le câblage de l'hôte est inchangé sur `main` ; qu'il construise les mêmes objets, on le sait en le lisant, pas en l'exécutant.

## Signalé en amont

- Signalés après l'écriture de cette leçon : dans le ticket de GA [#785](https://github.com/GuitarAlchemist/ga/issues/785), « minor » et les qualités en toutes lettres lus comme une triade majeure, les accords sans suffixe que rejette `CanHandle` et les quatre symboles de `ChordPitchClasses` ; dans [#784](https://github.com/GuitarAlchemist/ga/issues/784), les noms de l'index que le filtre ne trouve pas et les techniques abandonnées sans un mot dans la réponse. Tous sont listés dans le [journal](../journal/).

## Exercices

1. Demande au skill de `main` « voicings for Am », puis « voicings for A minor ». Quel accord jouent les voicings de chaque réponse ?
2. Combien des 144 prompts de la grille `CanHandle` accepte-t-il, et lesquels rejette-t-il ?
3. Que répond `CanHandle` à « voicings for C-7 » ? Que répondrait le skill de `main` si le routeur lui envoyait quand même la question ?
4. Sur `main`, quelles sont les quatre fondamentales, sur 12, pour lesquelles « voicings for <root>aug » ne reçoit que des triades augmentées ? Pourquoi quatre ?

<details>
<summary>Solutions</summary>

1. « voicings for Am » reçoit huit voicings de A mineur, A C E ; « voicings for A minor » en reçoit huit de A majeur, A C♯ E. La première question est lue comme le symbole `Am`, la seconde comme l'accord `A` et le mode `minor`, que l'index laisse tomber. Vérifié en exécutant le skill de `GaMain`, hors de la sortie attendue du cours.
2. 132 : il rejette les 12 accords majeurs sans suffixe, de « voicings for C » à « voicings for B », dont la fondamentale n'est suivie ni d'un suffixe ni d'un mot de qualité. Vérifié en exécutant `CanHandle` sur les 144 prompts, hors de la sortie attendue du cours.
3. Il la rejette : après la fondamentale, `-` ne correspond à aucune des deux expressions. Interrogé directement, le skill de `main` lit C7 et répond par huit voicings de C E G B♭. Vérifié en exécutant le skill de `GaMain`, hors de la sortie attendue du cours.
4. C, D, F et G. Une triade augmentée partage l'octave en trois tierces majeures, si bien que les trois mêmes notes ont trois noms, dont l'index ne stocke qu'un seul : Caug pour C E G♯, Daug pour D F♯ A♯, Faug pour D♭ F A et Gaug pour E♭ G B. Le filtre n'accepte que le nom stocké. Les huit autres fondamentales reçoivent des triades augmentées avec septième majeure, dont le filtre coupe le nom à la parenthèse. Vérifié en exécutant le skill de `GaMain`, hors de la sortie attendue du cours.

</details>

## À retenir

- Un voicing se vérifie sans manuel : le diagramme et l'accordage donnent ses notes.
- Sur `main`, chaque voicing que renvoie le skill joue l'accord qu'il a lu ; ce qui reste faux tient à la lecture et aux noms.
- Une lecture partielle tient le repli à l'écart : le lecteur typé tire « A » de « A minor », et le modèle ne voit jamais la question.
- Un filtre sur les noms demande un seul nom par accord : C6 et Am7, Dsus4 et Gsus2, et chaque triade augmentée sont chacun un même ensemble de notes sous plusieurs noms.
- Un filtre abandonné devrait apparaître dans la réponse, pas seulement dans la télémétrie.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ChordVoicingsSkill.cs`, `Common/GA.Business.ML/Search/TypedMusicalQueryExtractor.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs` (`ChordPitchClasses`), `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Apps/GaChatbot.Api/Extensions/ServiceCollectionExtensions.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : le même skill et le même extracteur, `Common/GA.Business.ML/Search/OptickSearchStrategy.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `docs/adr/0002-voicing-filter-parity-cpu-gpu-only.md`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson16.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ChordVoicingsProbe.cs`, `code/ga-ai/fetch-ga.sh`.
