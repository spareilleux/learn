---
title: "Leçon 15 : les notes d'un accord"
description: "Le chatbot de Guitar Alchemist orthographie sans modèle les notes d'un accord, et nomme l'accord que forme une liste de notes. Le cours pose à son skill les 32 prompts d'exemple, les 82 suffixes de son vocabulaire, 588 accords sur 21 fondamentales, puis chacun de ces accords sous forme de liste de notes. L'orthographe est celle d'un manuel pour tous les accords sauf la dominante altérée. C'est la lecture qui décide du reste : l'article a est lu comme la fondamentale A, trois prompts d'exemple et 22 suffixes ne sont pas lus, un chiffrage lu en partie reçoit les notes d'un accord plus petit, et aucune des 106 orthographes à altération double ou triple ne permet de retrouver l'accord. L'outil MCP du chemin du SKILL.md lit 14 des 51 symboles."
sidebar:
  label: 15. Les notes d'un accord
  order: 15
---

La [leçon 14](../14-what-the-substitution-skill-answers/) demandait au chatbot un accord à mettre à la place d'un autre. Cette leçon lui pose la question la plus élémentaire qu'un guitariste puisse lui adresser : quelles notes forment un accord, et quel accord forme un groupe de notes. Le routeur envoie les deux à l'intention `skill.chordinfo`, qui exécute `ChordInfoSkill` ([`GaPlugin.cs` ligne 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L36)). Le skill n'appelle aucun modèle : il lit un chiffrage d'accord et en orthographie les notes à partir d'une formule, ou bien il lit une liste de notes et cherche une formule qui leur corresponde. Pour le chemin qui passe par le modèle, le SKILL.md [`chord-info`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md) donne au modèle un seul outil MCP, `ga_chord_info`, et lui interdit d'orthographier un accord de mémoire ([`SKILL.md` ligne 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L43)) ; le plugin de GA enregistre l'outil ([`GaPlugin.cs` ligne 195](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L195)). Le skill et l'outil partagent deux fichiers : `ChordVocabulary`, qui associe un suffixe à une qualité et une qualité à sa formule, et `ChordSpelling`, qui place chaque note sur sa lettre.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur `main` au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ChordInfoSkill.cs`, `ChordVocabulary.cs`, `ChordSpelling.cs`, `ChordMcpTools.cs` et le SKILL.md sont inchangés. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l15
```

## Les prompts d'exemple du skill lui-même

Le programme démarre l'hôte du chatbot comme dans la leçon 12, prend l'intention que choisirait le routeur et lui pose chacun de ses 32 prompts d'exemple ([`ChordInfoSkill.cs` lignes 29-98](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L29-L98)). Le skill essaie de lire un nom d'accord de deux façons, puis une liste de notes, et renonce quand les trois lectures échouent ([lignes 114-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L114-L118), [lignes 154-169](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L154-L169)) :

```csharp
    private static (string Root, string Quality)? TryParse(string message)
    {
        var chordQuestion = ChordQuestionRegex().Match(message);
        if (chordQuestion.Success)
        {
            return (ChordVocabulary.NormalizeRoot(chordQuestion.Groups["root"].Value), ChordVocabulary.NormalizeQuality(chordQuestion.Groups["quality"].Value));
        }

        var compact = CompactChordRegex().Match(message);
        if (compact.Success)
        {
            return (ChordVocabulary.NormalizeRoot(compact.Groups["root"].Value), ChordVocabulary.NormalizeQuality(compact.Groups["quality"].Value));
        }

        return null;
    }
```

Le programme lit ce qu'a compris le skill dans les lignes de ses preuves, `Root:`, `Quality:` et `Notes:`, et compare les notes à celles qu'un manuel donne pour chaque prompt :

```text
== The skill's own example prompts
skill.chordinfo: ChordInfoSkill, 32 example prompts
"What is a C major chord?"  CanHandle yes
  C major: C E G
"What notes are in Dm7?"  CanHandle yes
  D minor 7: D F A C
"Notes in an F minor chord"  CanHandle yes
  F minor: F Ab C
"What chord contains C E G?"  CanHandle yes
  C major: C E G
"Spell a B7 chord"  CanHandle yes
  B dominant 7: B D# F# A
"What notes are in a Cmaj7?"  CanHandle yes
  C major 7: C E G B
"Tell me the tones in F#m7b5"  CanHandle no
  F# half-diminished: F# A C E
"tell me about Dm7"  CanHandle yes
  D minor 7: D F A C
"tell me about a Cmaj7 chord"  CanHandle yes
  C major 7: C E G B
"what makes a chord a major seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord diminished"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"what makes a chord a dominant seventh"  CanHandle yes
  A major: A C# E
  the question names a quality, no root
"What chord is C E G"  CanHandle yes
  C major: C E G
"What chord is F A C E"  CanHandle yes
  F major 7: F A C E
"Which chord contains the notes G B D F"  CanHandle yes
  G dominant 7: G B D F
"What chord is C E G Bb D"  CanHandle yes
  C dominant 9: C E G Bb D
"anatomy of a D7sus4 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: D G A C
"break down Gmaj13 for me"  CanHandle no
  G major 13: G B D F# A C E
"what is a C add 9 chord"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G D
"give me the notes of an F#m7b5"  CanHandle yes
  F# half-diminished: F# A C E
"tones in a Bb diminished seventh"  CanHandle no
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb Db Fb Abb
"What is C7b9"  CanHandle yes
  C dominant 7 flat 9: C E G Bb Db
"What is Cmaj9"  CanHandle yes
  C major 9: C E G B D
"What is Dm7b5"  CanHandle yes
  D half-diminished: D F Ab C
"What is F#m7"  CanHandle yes
  F# minor 7: F# A C# E
"What is Bbdim7"  CanHandle yes
  Bb diminished 7: Bb Db Fb Abb
"what notes are in a C major triad"  CanHandle yes
  C major: C E G
"what are the notes of an A minor triad"  CanHandle yes
  A minor: A C E
"what notes make up a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"which notes form a B diminished triad"  CanHandle yes
  B diminished: B D F
"spell a G7 chord"  CanHandle yes
  G dominant 7: G B D F
"what notes are in an E major chord"  CanHandle yes
  E major: E G# B
The intent's answer is the skill's Result for 32 of 32
The textbook's notes for 26 of the 29 prompts that name a chord or its notes
CanHandle accepts 27 of 32
```

- **Trois questions sur une qualité reçoivent A majeur.** « what makes a chord diminished » reçoit la réponse « A major chord contains A, C#, and E », tout comme les deux autres prompts « what makes a chord ». La première expression régulière cherche une fondamentale, une qualité facultative et le mot « chord » ([lignes 302-303](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L302-L303)) ; sa classe de fondamentales `[A-Ga-g]` accepte l'article « a », et « a chord » est la première correspondance de la phrase :

```csharp
    [GeneratedRegex(@"\b(?<root>[A-Ga-g][#b]?)\s*(?<quality>major 13|minor 13|dominant 13|major 11|minor 11|dominant 11|major 9|minor 9|dominant 9|major 7|minor 7|dominant 7|major 6|minor 6|half[- ]diminished|altered dominant|major|minor|maj|min|diminished|dim|augmented|aug|sus[24]?|add9|7alt|alt|13|11|9|7|6)?\s*(?:chord|triad)\b", RegexOptions.CultureInvariant)]
    private static partial Regex ChordQuestionRegex();
```

La deuxième expression a buté sur le même article, et son commentaire dit comment elle a été corrigée : sa qualité est devenue obligatoire ([lignes 310-314](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L310-L314)). La première a gardé sa qualité facultative.

- **Trois prompts ne sont pas lus.** « anatomy of a D7sus4 chord » : l'expression des chiffrages n'a pas `7sus4`, et après `7` elle exige une limite de mot, que le `s` de `sus4` ne fournit pas. « what is a C add 9 chord » : l'alternative prévue s'écrit `add9`, sans espace. « tones in a Bb diminished seventh » : ni « chord » ni « triad » pour la première expression, aucun chiffrage pour la deuxième. La réponse est « Could not parse a chord name from your question. »
- **Les 26 autres sont justes,** y compris le D♯ de B7, et le F♭ et le A♭♭ de B♭dim7.
- **`CanHandle` accepte 27 des 32.** Il n'accepte un chiffrage qu'à côté des mots « chord », « triad » ou « note », ou après une entrée en matière comme « what is » ou « tell me about » ([lignes 100-110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L100-L110), [lignes 267-282](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L267-L282)). Outre les trois prompts illisibles, il rejette « Tell me the tones in F#m7b5 » et « break down Gmaj13 for me », auxquels le skill répond pourtant juste. Au commit épinglé, le routeur n'appelle pas `CanHandle` ; sur `main`, il s'y replie quand il ne peut pas calculer l'embedding de la question ([`SemanticIntentRouter.cs` ligne 321 sur `main`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)).

## Tous les suffixes que connaît le vocabulaire

`ChordVocabulary.NormalizeQuality` ramène 83 graphies de suffixe, dont le suffixe vide, aux qualités de `GetFormula` ([`ChordVocabulary.cs` lignes 59-104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L59-L104)). Son commentaire de documentation explique les deux branches en majuscules : `M` signifie majeur et ne doit pas être mis en minuscules, ce qui donnerait `m`, mineur :

```csharp
    /// <summary>
    ///     Normalises a quality suffix to its canonical form (the key <see cref="GetFormula"/> switches on).
    /// </summary>
    /// <remarks>
    ///     The uppercase <c>"M"</c> / <c>"M7"</c> arms are matched <b>case-sensitively before</b> the
    ///     lowercase fallback: <c>"M"</c> means major and must not fold through <c>ToLowerInvariant()</c>
    ///     to <c>"m"</c> (minor). This is the PR #80 fix; consolidating it here keeps the skill from
    ///     re-introducing the <c>"CM"</c> → C-minor regression.
    /// </remarks>
    public static string NormalizeQuality(string raw)
    {
        var trimmed = raw.Trim();
        return trimmed switch
        {
            "M"  => "major",
            "M7" => "major 7",
            _    => trimmed.ToLowerInvariant() switch
            {
                "" => "major",
```

Le programme interroge le skill sur chacun des 82 autres suffixes, les 51 symboles sous la forme « What notes are in C…? », les 31 mots sous la forme « What notes are in a C … chord? », et affiche ceux qu'il ne lit pas comme le vocabulaire :

```text
== Every suffix the vocabulary knows
"What notes are in C+?"  the vocabulary: augmented, the skill: no chord
"What notes are in C5?"  the vocabulary: power, the skill: no chord
"What notes are in Cno3?"  the vocabulary: power, the skill: no chord
"What notes are in Cdom7?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in Cma7?"  the vocabulary: major 7, the skill: no chord
"What notes are in CΔ7?"  the vocabulary: major, the skill: no chord
"What notes are in C-7?"  the vocabulary: minor 7, the skill: no chord
"What notes are in C°7?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in Cmin7b5?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in Cø7?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in C7+5?"  the vocabulary: dominant 7 sharp 5, the skill: dominant 7
"What notes are in a C power chord?"  the vocabulary: power, the skill: no chord
"What notes are in a C dominant chord?"  the vocabulary: dominant 7, the skill: no chord
"What notes are in a C diminished 7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C diminished7 chord?"  the vocabulary: diminished 7, the skill: no chord
"What notes are in a C minor 7 flat 5 chord?"  the vocabulary: half-diminished, the skill: no chord
"What notes are in a C dominant 7 flat 5 chord?"  the vocabulary: dominant 7 flat 5, the skill: no chord
"What notes are in a C dominant 7 sharp 5 chord?"  the vocabulary: dominant 7 sharp 5, the skill: no chord
"What notes are in a C dominant 7 flat 9 chord?"  the vocabulary: dominant 7 flat 9, the skill: no chord
"What notes are in a C dominant 7 sharp 9 chord?"  the vocabulary: dominant 7 sharp 9, the skill: no chord
"What notes are in a C altered chord?"  the vocabulary: altered dominant, the skill: no chord
The skill reads 60 of 82 suffixes as the vocabulary does (51 symbols, 31 words)
NormalizeQuality("Δ7") returns "δ7", which GetFormula doesn't know
ga_chord_info reads 14 of the 51 symbols: M M7 maj m min dim aug 7 maj7 m7 min7 dim7 m7b5 min7b5
```

- **22 des 82 ne sont pas lus, ou sont lus comme une autre qualité.** L'expression des chiffrages, insensible à la casse, n'a ni `5`, ni `no3`, ni `dom7`, ni `ma7`, ni `-7`, ni `°7`, ni `ø`, ni `ø7`, ni `min7b5` ([lignes 305-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L305-L316)) ; le vocabulaire les connaît, mais le skill ne les lui transmet jamais. Son commentaire range pourtant `+` et « power 5/no3 » parmi les formes qu'elle prend en charge. `+` figure bien dans l'alternance, mais le `\b` qui le suit exige un caractère de mot d'un côté ou de l'autre, et dans la question `+` est suivi d'un point d'interrogation. La formule du power chord est tout à fait inaccessible, que ce soit par « C5 » ou par « a C power chord ». Les formes en toutes lettres s'arrêtent à la liste de la première expression, à laquelle manquent entre autres « power », « diminished 7 », « dominant 7 flat 5 », et « dominant » ou « altered » employés seuls. `7+5` est lu comme une septième de dominante, pour la raison que donne la section suivante.
- **Le `Δ7` du vocabulaire ne peut jamais correspondre.** `NormalizeQuality` met le suffixe en minuscules avant son second switch, et `ToLowerInvariant` met aussi en minuscules les lettres grecques : le delta majuscule de `Δ7` devient `δ`, et aucune branche ne s'écrit `δ7`. Le suffixe passe inchangé, et `GetFormula` donne une triade majeure à toute qualité inconnue ([ligne 140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L140)). Aucune des deux expressions ne lit `Δ` : le chatbot n'arrive donc pas jusque-là.

```csharp
                // 7th family
                "7" or "dominant" or "dom7" or "dominant 7" => "dominant 7",
                "maj7" or "major 7" or "ma7" or "Δ7" => "major 7",
                "m7" or "min7" or "minor 7" or "-7" => "minor 7",
```

- **`ga_chord_info` lit 14 des 51 symboles,** comme le montre la dernière ligne ; la section consacrée à l'outil y revient.

## Au-delà du vocabulaire

Le programme demande des chiffrages que le vocabulaire ne connaît pas, un accord à basse imposée, le signe bémol `♭`, et deux phrases qu'un guitariste pourrait taper :

```text
== Beyond the vocabulary
"What notes are in Cmaj7#11?"
  C major 7: C E G B
  the textbook: C E G B F#
"What notes are in C7#11?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb F#
"What notes are in C7(b9)?"
  C dominant 7: C E G Bb
  the textbook: C E G Bb Db
"What notes are in Cm(maj7)?"
  C minor: C Eb G
  the textbook: C Eb G B
"What notes are in C6/9?"
  C major 6: C E G A
  the textbook: C E G A D
"What notes are in C7#5#9?"
  C dominant 7 sharp 5: C E G# Bb
  the textbook: C E G# Bb D#
"What notes are in C7sus4?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C F G Bb
"What notes are in C/E?"
  no chord: "Could not parse a chord name from your question."
  the textbook: C E G
"What notes are in B♭7?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Bb D F Ab
"What notes are in an E♭ major chord?"
  no chord: "Could not parse a chord name from your question."
  the textbook: Eb G Bb
"I am learning Cmaj7, what notes are in it?"
  A minor: A C E
  the textbook: C E G B
"Am I right that G7 has an F?"
  A minor: A C E
  the textbook: G B D F
```

- **Six chiffrages reçoivent les notes d'un accord plus petit.** Après le suffixe, l'expression des chiffrages exige une limite de mot et l'absence de lettre ([ligne 315](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L315)) : `#`, `(`, `/` et `+` remplissent les deux conditions. Cmaj7♯11 reçoit la réponse de Cmaj7, C7(♭9) celle de C7, Cm(maj7) celle de Cm, C6/9 celle de C6, et rien dans la réponse ne signale qu'une partie a été laissée de côté. Le skill d'improvisation de la leçon 5 lisait de la même façon Cmaj7♯5 comme Cmaj7 (entrée 23 du [journal](../journal/)).
- **C7sus4, C/E et le signe bémol ne sont pas lus**, et la réponse le dit. `♭` n'est pas la lettre `b`.
- **« I am » et « Am I » donnent A mineur.** L'expression des chiffrages ignore la casse : « am » est donc la fondamentale A suivie du suffixe `m`, et il vient avant Cmaj7 ou G7 dans la phrase.

## Orthographe : 21 fondamentales, 28 qualités

Le skill place chaque note sur une lettre : la formule donne à chaque note son nombre de lettres au-dessus de la fondamentale, et `ChordSpelling.Spell` ajoute les altérations qui amènent cette lettre à la hauteur de la note ([`ChordSpelling.cs` lignes 52-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs#L52-L69)) :

```csharp
    public static string Spell(string root, int pitchClass, int letterSteps)
    {
        var rootLetter   = char.ToUpperInvariant(root[0]);
        var rootIndex    = Array.IndexOf(NaturalLetters, rootLetter);
        var targetLetter = NaturalLetters[(rootIndex + letterSteps) % NaturalLetters.Length];
        var targetNatural = NaturalPitchClasses[targetLetter];
        var normalized   = ((pitchClass % 12) + 12) % 12;
        var accidental   = ((normalized - targetNatural) % 12 + 12) % 12;

        return accidental switch
        {
            0  => targetLetter.ToString(),
            1  => $"{targetLetter}#",
            2  => $"{targetLetter}##",
            10 => $"{targetLetter}bb",
            11 => $"{targetLetter}b",
            _  => $"{targetLetter}{(accidental < 6 ? new string('#', accidental) : new string('b', 12 - accidental))}",
        };
```

Le programme orthographie les mêmes accords à sa manière, à partir de degrés écrits dans `Lesson15.cs` : un 3 se trouve deux lettres et quatre demi-tons au-dessus de la fondamentale, un ♭3 sur la même lettre un demi-ton plus bas. Il demande au skill les 28 qualités que celui-ci sait lire, sur les 21 fondamentales du vocabulaire, de C à B, plus B♯, C♭, E♯ et F♭ :

```text
== Spelling: 21 roots, 28 qualities
The skill spells 567 of 588 chords as the textbook does
  C7alt: skill C E F# G# Bb Db D#, textbook C E Gb G# Bb Db D#
  C#7alt: skill C# E# F## G## B D D##, textbook C# E# G G## B D D##
  Db7alt: skill Db F G A Cb Ebb E, textbook Db F Abb A Cb Ebb E
  … and 18 more
The chords that differ: 21 7alt
C7alt: Intervals: root, major third, flat fifth, sharp fifth, minor seventh, flat ninth, sharp ninth
Chords with a double or triple accidental: 175 of 588
```

- **567 des 588 concordent.** Les 21 autres sont la dominante altérée, sur chaque fondamentale. Sa formule place la quinte bémol sur la lettre de la quarte, trois lettres au-dessus de la fondamentale au lieu de quatre ([`ChordVocabulary.cs` ligne 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L130)) : F♯ pour C, dont la quinte bémol est G♭. F♯ est une orthographe courante de la ♯11 d'un accord altéré, mais les preuves du skill appellent cette note « flat fifth ».
- **175 accords s'écrivent avec une double ou une triple altération,** comme le A♭♭ de B♭dim7 ou le F♯♯♯ de B♯ augmenté. Ces orthographes sont justes, et la section suivante les renvoie au skill.

## Les orthographes du skill, reposées en listes de notes

Une question où « what chord » ou « which chord » est suivi de « is », « contains », « has » ou « uses » passe à la troisième lecture ([ligne 322](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L322)). Le skill relève tous les noms de notes de la question, ne poursuit qu'avec 3 à 5 notes distinctes, et essaie chacune comme fondamentale face à 19 formules ([lignes 171-223](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L171-L223), [lignes 236-265](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L236-L265)). Un nom de note est une lettre, une altération facultative, et aucune lettre à la suite :

```csharp
    [GeneratedRegex(@"(?<![A-Za-z])(?<note>[A-Ga-g][#b]?)(?![A-Za-z])", RegexOptions.CultureInvariant)]
    private static partial Regex NoteTokenRegex();
```

Le programme lit par réflexion la liste des 19 formules dans le skill, puis demande « What chord is … » avec les notes que le skill a orthographiées pour chacun des 588 accords. Un aller-retour n'a pas besoin d'oracle : un skill qui orthographie un accord devrait savoir le nommer à partir de sa propre orthographe. Les dernières lignes soumettent six listes de notes de son cru :

```text
== The skill's own spellings, asked back as notes
It names 19 qualities from notes; not dominant 7 flat 9, dominant 7 sharp 9, altered dominant, dominant 11, major 11, minor 11, dominant 13, major 13, minor 13
a quality it names, single accidentals: 293 chords, named back 293, as another chord 0, not named 0
a quality it names, a double or triple accidental: 106 chords, named back 0, as another chord 58, not named 48
  "What chord is D# F## A#" → D# minor: D# F# A#
a quality it doesn't name, 3 to 5 notes: 42 chords, named back 0, as another chord 12, not named 30
  "What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
6 or 7 notes: 147 chords, named back 0, as another chord 3, not named 144
  "What chord is C E F# G# Bb Db D#" → no chord: "Could not parse a chord name from your question."
```

```text
== Lists of notes
"What chord is C E G# B" → no chord: "Could not parse a chord name from your question."
"What chord is C E G Bb Db" → no chord: "Could not parse a chord name from your question."
"What chord is C Eb Gb Bbb" → C diminished: C Eb Gb
"What chord is F# A# C##" → F# major: F# A# C#
"Which chord has a C, an E and a G?" → A minor 7: A C E G
"What chord is C E G B♭" → C major 7: C E G B
```

- **Altérations simples : les 293 accords sont retrouvés.** Chaque accord des 19 formules orthographié sans double altération revient tel quel.
- **Doubles altérations : aucun des 106.** L'expression des notes ne prend qu'une altération et refuse une lettre à la suite : `Bbb` est écarté, puisqu'un `b` suit `Bb`, et `C##` est lu C♯, puisque `#` n'est pas une lettre. « C Eb Gb Bbb », l'orthographe de Cdim7 que donnent aussi bien le skill que la description de l'outil, est nommé C diminué ; F♯ augmenté est nommé F♯ majeur. Le signe bémol se perd de la même façon : C E G B♭ devient C septième majeure, la mauvaise lecture de [#757](https://github.com/GuitarAlchemist/ga/issues/757).
- **7b9 et 7#9 ne font pas partie des 19.** Ces accords ont cinq notes, dans la limite, mais « What chord is C E G Bb Db » reçoit le refus alors que « What is C7b9 » orthographie exactement ces notes, et le corpus de prompts de GA pose les deux genres de question ([`prompts.yaml` lignes 462-468](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L462-L468), [lignes 542-548](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml#L542-L548)). « What chord is C E G# B » est l'exemple que donne le commentaire de la liste elle-même pour « 7-with-altered-fifth » ([lignes 261-262](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L261-L262)) ; c'est Cmaj7♯5, et la liste n'a que la septième de dominante à quinte augmentée ou diminuée.
- **Six et sept notes sont refusées à dessein :** le commentaire en donne la raison, un accord de onzième ou de treizième a plusieurs noms ([lignes 184-189](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs#L184-L189)).
- **« Which chord has a C, an E and a G? » donne A mineur 7 :** l'expression des notes lit l'article « a ».

## ga_chord_info, l'outil du SKILL.md

L'outil lit un chiffrage avec sa propre expression, ancrée et plus courte que celle du skill ([`ChordMcpTools.cs` lignes 77-82](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs#L77-L82)) :

```csharp
    // Order matters in the alternation: longer prefixes first so `dim7` is
    // tried before `dim` and `m7b5` before `m7`. Without this ordering, input
    // "Cdim7" matches `dim` and leaves "7" unconsumed, failing the ^...$ anchor
    // and the whole regex. Same for "Cm7b5" → matches `m` and fails on "7b5".
    [GeneratedRegex(@"^(?<root>[A-Ga-g][#b]?)(?<quality>maj7|min7b5|min7|m7b5|m7|maj|min|m|dim7|dim|aug|7|M7|M)?$",
        RegexOptions.CultureInvariant)]
```

Le programme lui soumet les chiffrages du tableau des suffixes du SKILL.md ([`SKILL.md` lignes 60-72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L60-L72)) et les cinq exemples de sa propre description :

```text
== ga_chord_info, the tool of the SKILL.md
The SKILL.md's table lists 16 symbols, the tool reads 15
  Cdom7: "Could not parse 'Cdom7' as a chord symbol. Try C, Cm, Cmaj7, F#dim, Bbm7, etc."
The tool returns the notes its description gives for 5 of its 5 examples
```

- **Le tableau liste `Cdom7`,** et l'outil le refuse : son expression n'a pas `dom7`.
- **14 des 51 symboles du vocabulaire,** comme l'a montré la section sur le vocabulaire : les triades, les accords de septième, `dim7` et `m7b5`. Le SKILL.md le dit : les accords suspendus et à note ajoutée, les neuvièmes, les onzièmes, les treizièmes, les accords à basse imposée et les dominantes altérées renvoient une erreur, et le modèle doit alors refuser de répondre ([lignes 95-102](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/chord-info/SKILL.md#L95-L102)) ; il doit en faire autant pour une liste de notes, qu'aucun outil ne lit. Le même chatbot orthographie Cmaj9 sur le chemin du skill, et son SKILL.md demande au modèle de le refuser.
- **Là où l'outil lit, il répond juste :** ses cinq exemples reviennent tels que sa description les donne.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Savoir si le routeur sémantique envoie chacune de ces questions à `skill.chordinfo`, « I am learning Cmaj7 » comprise, demande les embeddings, et ce qu'un modèle écrit à partir de `ga_chord_info` demande le modèle (*à vérifier*).
- **Les orthographes de manuel sont celles du cours,** calculées à partir de degrés ; pour la dominante altérée, une orthographe avec ♯11 est aussi en usage.
- **Le skill et l'outil ne sont pas exécutés sur `main`.** Leurs fichiers y sont inchangés ; qu'ils répondent de la même façon sur `main`, c'est la lecture du diff qui le dit.

## Signalé en amont

- Non signalés en amont au moment où cette leçon a été écrite : l'article et « am » lus comme des fondamentales, les prompts d'exemple et les suffixes que le skill ne lit pas, les chiffrages lus en partie, les doubles altérations et les formules absentes de la lecture des notes, la quinte bémol de la dominante altérée, le `Δ7` du vocabulaire, et l'outil qui ne lit que 14 symboles. B♭ lu comme B, c'est la même lecture que [#757](https://github.com/GuitarAlchemist/ga/issues/757). Tous sont listés dans le [journal](../journal/).

## Exercices

1. Réduis la classe de fondamentales de la première expression à `[A-G]`. Lesquels des 32 prompts d'exemple changent, et quelle réponse reçoivent-ils alors ?
2. Orthographie B♯ augmenté comme le fait le skill, puis dis ce qu'il répond à « What chord is » suivi de cette orthographe.
3. Ajoute `7sus4` à l'alternance de l'expression des chiffrages, sans rien changer d'autre. Que répond alors le skill à « anatomy of a D7sus4 chord » ?
4. Autorise l'expression des notes à prendre deux altérations, `bb` ou `##`. Pourquoi « C Eb Gb Bbb » n'est-il toujours pas nommé C septième diminuée ?

<details>
<summary>Solutions</summary>

1. Les trois prompts « what makes a chord », et eux seuls : la première expression ne trouve plus de correspondance, l'expression des chiffrages ne trouve aucun chiffrage, et la question n'a ni « what chord » ni « which chord » suivi de « is », « contains », « has » ou « uses ». Ils reçoivent « Could not parse a chord name from your question. » au lieu de A majeur. Vérifié avec les expressions régulières de .NET, à partir des expressions compilées de GA, hors du programme du cours.
2. B♯ D♯♯ F♯♯♯ : la tierce et la quinte sont deux et quatre lettres au-dessus de B. L'expression des notes lit B♯, D♯ et F♯, les classes de hauteurs 0, 3 et 6, et le skill répond « B# diminished chord contains B#, D#, and F#. » Vérifié en appelant le skill compilé de GA, hors du programme du cours.
3. « D major chord contains D, F#, and A. » : `NormalizeQuality` n'a pas de branche pour `7sus4` et le renvoie inchangé, et `GetFormula` donne une triade majeure à toute qualité inconnue. Un suffixe que l'expression lit doit avoir une entrée dans le vocabulaire, sinon la réponse est une triade. Vérifié en appelant le vocabulaire compilé de GA, hors du programme du cours.
4. `ChordVocabulary.PitchClasses` contient 21 noms, dont aucun ne porte deux altérations ([`ChordVocabulary.cs` lignes 23-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/ChordVocabulary.cs#L23-L32)), et le skill ne garde que les noms qu'il y trouve. `Bbb` est écarté après l'expression au lieu de l'être par elle, et les trois autres notes forment toujours une triade diminuée. Vérifié en appelant le vocabulaire compilé de GA, hors du programme du cours.

</details>

## À retenir

- Une orthographe juste pour 567 accords sur 588 ne rend pas les réponses justes : c'est ce que lit le skill qui décide de l'accord qu'il orthographie.
- Une classe de caractères qui contient des minuscules lit des mots anglais : l'article « a » et « am ».
- Une correspondance qui s'arrête à une limite de mot répond pour un accord plus petit que celui qui était demandé ; un skill devrait dire ce qu'il a laissé de côté, ou refuser de répondre.
- Un aller-retour est un test sans oracle : on rend à une fonction sa propre sortie.
- `ToLowerInvariant` ne se limite pas à l'ASCII : Δ devient δ.
- Un repli sur la triade majeure transforme chaque qualité que personne n'a prévue en réponse assurée.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ChordInfoSkill.cs`, `Common/GA.Business.ML/Agents/ChordVocabulary.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordSpelling.cs`, `Common/GA.Business.ML/Agents/Mcp/ChordMcpTools.cs`, `skills/chord-info/SKILL.md`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `Tests/Apps/GaChatbot.Api.Tests/Corpus/prompts.yaml`.
- Le `main` de GA au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), daté du 2026-09-30 en UTC, pour la comparaison et `SemanticIntentRouter.cs`.
- *Open Music Theory*, les chapitres sur les chiffrages d'accords et les accords de septième.
