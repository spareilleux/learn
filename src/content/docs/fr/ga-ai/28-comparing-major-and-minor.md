---
title: "Leçon 28 : comparer majeur et mineur"
description: "Le TheoryComparisonSkill de Guitar Alchemist répond à une seule question, la différence entre majeur et mineur, avec un texte fixe dont les gammes sont celles d'un manuel. Ses expressions régulières lisent ses 7 prompts d'exemple, mais 5 des 20 formulations du cours ; sa réponse à une paire identique suggère une comparaison qu'il refuse, les tonalités parallèles qu'il laisse à RelativeKeySkill reçoivent le refus de ce skill, et sans embeddings le main de GA ne lui envoie aucun de ses exemples."
sidebar:
  label: 28. Comparer majeur et mineur
  order: 28
---

Le chatbot de GA répond à « What is the difference between major and minor » avec `TheoryComparisonSkill`. Ce skill a été écrit le 2026-05-16 parce que ce prompt du corpus partait vers `RelativeKeySkill`, recevait son texte à 0,1 de confiance, puis attendait Ollama jusqu'à l'expiration ([`TheoryComparisonSkill.cs`, lignes 12-18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L12-L18)). Il répond sans modèle, et pour une seule paire : ses remarques donnent pour périmètre « major vs minor (the broken prompt) » ([lignes 20-25](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L20-L25)). Cette leçon cherche quelles formulations il lit, confronte sa réponse à un manuel, et demande au `main` de GA ce que fait son chatbot des exemples mêmes du skill quand rien ne peut les plonger dans l'espace des embeddings.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), celui qu'épingle le cours. Sur le `main` de GA, à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `TheoryComparisonSkill.cs` ne fait que marquer son refus `Declined`, et `RelativeKeySkill.cs` de même, avec un nouveau `CanHandle` décrit plus bas : `GaAi` interroge donc les skills au commit épinglé, et `GaMain` l'hôte du chatbot de `main`, démarré comme dans la [leçon 25](../25-what-reaches-the-transpose-skill/). La sortie vient de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l28
dotnet run --project code/ga-ai/GaMain -c Release -- l28
```

## Comment le skill lit une question

`CanHandle` répond toujours non : seuls les embeddings du routeur peuvent choisir le skill. `ExecuteAsync` essaie quatre expressions régulières l'une après l'autre, chacune à la recherche de deux des mots `major` et `minor` :

```csharp
    public bool CanHandle(string message) => false;  // semantic-routing only

    // Match "difference between X and Y", "compare X and Y", "X vs Y",
    // "X versus Y", "how do X and Y differ", "X and Y difference".
    // Quality tokens are kept narrow so unrelated comparisons
    // ("C major vs F major", "Hendrix vs Clapton") do not route here.
    private const string QualityTokens = "major|minor";

    private static readonly Regex DifferencePattern =
        new(@"\b(?:what(?:'s|\s+is)?\s+the\s+)?(?:difference|distinction)\s+between\s+(?<a>" + QualityTokens + @")\s+and\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex ComparePattern =
        new(@"\bcompare\s+(?<a>" + QualityTokens + @")\s+(?:and|with|vs|versus)\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex VsPattern =
        // Negative lookbehind keeps "C major vs C minor" out — that's a
        // parallel-key question handled by RelativeKeySkill. Bare
        // "major vs minor" with no preceding key letter falls through.
        new(@"(?<![A-Ga-g][b#♭♯]?\s)\b(?<a>" + QualityTokens + @")\s+(?:vs\.?|versus)\s+(?<b>" + QualityTokens + @")\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static readonly Regex HowDifferPattern =
        new(@"\bhow\s+do\s+(?<a>" + QualityTokens + @")\s+and\s+(?<b>" + QualityTokens + @")\s+differ\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

Deux mots différents reçoivent la comparaison, `major` placé en premier ; le même mot deux fois reçoit une courte réponse à part ; sans correspondance, c'est un refus vide ([lignes 77-111](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L77-L111), [lignes 151-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L151-L165)).

## Les formulations auxquelles il répond

Le programme pose au skill ses 7 prompts d'exemple et 20 formulations du cours, et nomme la première expression régulière qui correspond :

```text
== TheoryComparisonSkill: the regex that finds the pair in each phrasing, and the answer
source   phrasing                                                   regex              answer
example  What is the difference between major and minor             DifferencePattern  answer
example  Compare major and minor                                    ComparePattern     answer
example  Major vs minor                                             VsPattern          answer
example  Major versus minor                                         VsPattern          answer
example  Difference between major and minor scales                  DifferencePattern  answer
example  Explain the difference between major and minor             DifferencePattern  answer
example  How do major and minor differ                              HowDifferPattern   answer
course   Minor vs major                                             VsPattern          answer
course   Major vs. minor                                            VsPattern          answer
course   Compare minor with major                                   ComparePattern     answer
course   What is the difference between minor and major             DifferencePattern  answer
course   What's the difference between major and minor keys         DifferencePattern  answer
course   Major and minor difference                                 none               refused
course   How are major and minor different                          none               refused
course   Major or minor: what's the difference?                     none               refused
course   Majors vs minors                                           none               refused
course   What is the difference between the major and minor scales  none               refused
course   Difference between a major and a minor chord               none               refused
course   Explain the major vs minor difference                      none               refused
course   Which sounds sadder, a major vs minor chord?               none               refused
course   C major vs C minor                                         none               refused
course   What's the difference between C major and C minor          none               refused
course   Major vs major                                             VsPattern          same pair
course   Major vs dorian                                            none               refused
course   Dorian vs Aeolian                                          none               refused
course   Harmonic minor vs melodic minor                            none               refused
course   Major pentatonic vs minor pentatonic                       none               refused
example prompts 7: answer 7; the course's 20: answer 5, same pair 1, refused 14; CanHandle accepts 0
```

- **Les 7 prompts d'exemple reçoivent la réponse, et 5 des 20 formulations du cours.** La paire peut venir dans les deux ordres, et « vs. » comme « Compare … with » sont lus.
- **Un mot de plus, et la question est perdue.** Rien ne peut s'intercaler entre « between » et le premier mot, ni entre les mots et « and » : « the major and minor scales » et « a major and a minor chord » sont refusés. De même pour « Majors vs minors », où un « s » précède l'espace qu'attendent les expressions régulières, et pour « How are major and minor different ». Le commentaire au-dessus des expressions régulières compte « X and Y difference » parmi les formes qu'elles reconnaissent, mais aucune ne l'a : « Major and minor difference » est refusé.
- **L'assertion arrière de `VsPattern` écarte plus que des tonalités.** Elle refuse un mot précédé d'une lettre de A à G, d'une altération facultative et d'une espace, pour laisser « C major vs C minor » à un autre skill. La casse étant ignorée, le « e » de « the » et l'article « a » sont de telles lettres : « Explain the major vs minor difference » et « Which sounds sadder, a major vs minor chord? » sont refusés.
- **Rien d'autre n'est comparé.** « Dorian vs Aeolian », « Harmonic minor vs melodic minor » et « Major pentatonic vs minor pentatonic » sont refusés, comme l'annonce le périmètre des remarques.

## La réponse face à un manuel

```text
== TheoryComparisonSkill's answer to "What is the difference between major and minor"
  | Major and minor differ primarily in the **third scale degree**, with secondary differences at the 6th and 7th depending on the minor form.
  | 
  | **Scale formulas (semitones from root):**
  | - Major:   2 2 1 2 2 2 1 — degrees `1 2 3 4 5 6 7` (major third = 4 semitones)
  | - Minor:   2 1 2 2 1 2 2 — degrees `1 2 b3 4 5 b6 b7` (minor third = 3 semitones, natural minor)
  | 
  | The single interval that flips is the **third**: a major third (4 semitones) versus a minor third (3 semitones). That one-semitone shift changes the entire harmonic and emotional character of the key — chords built on the same root come out major or minor accordingly.
  | 
  | **Common associations:** major sounds bright and stable (often "happy"); minor sounds darker and more ambiguous (often "sad" but really just emotionally richer). These are cultural shorthand, not absolutes.
  | 
  | **Minor variants:**
  | - Natural minor: `1 2 b3 4 5 b6 b7`
  | - Harmonic minor: `1 2 b3 4 5 b6 7` — raised 7th for stronger dominant resolution
  | - Melodic minor: `1 2 b3 4 5 6 7` ascending (raised 6th and 7th), natural minor descending
  | 
  | **In context:**
  | - Relative pairs share a key signature (C major ↔ A minor, G major ↔ E minor)
  | - Parallel pairs share a root but flip quality (C major ↔ C minor)
  | - Diatonic chords differ: I IV V (major-quality) vs i iv V (minor with raised 7th in V)
```

Le programme relit les gammes de la réponse et les compare à celles d'un manuel, puis vérifie les paires relatives et les accords qu'elle nomme :

```text
== The scales in the answer, against a textbook: the degrees it writes, the degrees its steps give, and a textbook's
scale            the answer writes  its steps give     a textbook         the same  degrees not major's
Major            1 2 3 4 5 6 7      1 2 3 4 5 6 7      1 2 3 4 5 6 7      yes       none
Minor            1 2 b3 4 5 b6 b7   1 2 b3 4 5 b6 b7   1 2 b3 4 5 b6 b7   yes       3 6 7
Natural minor    1 2 b3 4 5 b6 b7   -                  1 2 b3 4 5 b6 b7   yes       3 6 7
Harmonic minor   1 2 b3 4 5 b6 7    -                  1 2 b3 4 5 b6 7    yes       3 6
Melodic minor    1 2 b3 4 5 6 7     -                  1 2 b3 4 5 6 7     yes       3
relative pairs: C major ↔ A minor: the same notes yes; G major ↔ E minor: the same notes yes
triads on degrees 1, 4 and 5: major: major, major, major; natural minor: minor, minor, minor; harmonic minor: minor, minor, major
```

- **Chaque gamme de la réponse est celle d'un manuel,** d'après ses intervalles comme d'après ses degrés, de même que ses paires relatives et les qualités de I, IV et V.
- **« The single interval that flips is the third » ne vaut que pour le mineur mélodique.** Le mineur naturel, celui que la réponse écrit en premier, diffère du majeur aux 3e, 6e et 7e degrés, et le mineur harmonique aux 3e et 6e. La première phrase de la réponse le dit, « secondary differences at the 6th and 7th », et la phrase qui suit les formules dit le contraire.

## La même paire deux fois

```text
== The same pair twice: the answer, the comparison it suggests, and the skill's answer to that
question         suggests             answer to the suggestion
Major vs major   major vs dorian      refused
Minor vs minor   minor vs dorian      refused
  | You asked to compare major to itself — there's no difference. Try comparing major to its opposite (major↔minor) or to a specific mode (e.g. "major vs dorian").
```

- **« Major vs major » reçoit une suggestion que le skill refuse :** « major vs dorian », et « minor vs dorian » pour mineur. Ses expressions régulières ne connaissent que `major` et `minor` ([ligne 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L56)).

## Les tonalités parallèles

Le commentaire de `VsPattern` dit que « C major vs C minor » est « a parallel-key question handled by RelativeKeySkill » ([lignes 67-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs#L67-L69)). `RelativeKeySkill` lit « relative » ou « parallel » suivis de « minor of » ou « major of », et les armures ([`RelativeKeySkill.cs`, lignes 52-70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L52-L70)) :

```text
== RelativeKeySkill, which VsPattern's comment says handles "C major vs C minor": confidence and the first line of the answer
question                                             confidence   answer
C major vs C minor                                   0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
What's the difference between C major and C minor    0.100        Ask about the relative or parallel key of a given major/minor key, or how many sharps/flats a key has.
Parallel minor of C major                            1.000        The parallel minor of **C major** is **C minor**.
```

- **Aucun des deux skills ne répond à « C major vs C minor ».** `RelativeKeySkill` donne son refus, avec une confiance de 0,1, et ne répond à la question que sous la forme « Parallel minor of C major ».

## Sans embeddings, sur main

Le routeur n'atteint le skill que par les embeddings. Le diagnostic de routage de GA lui-même, du 2026-06-16, en fait l'intention la mieux séparée des 30 qu'il mesure, ses sept exemples étant sept formulations d'une même question, et place « Major versus minor » au plus près de « Relative major of A minor », un exemple de `RelativeKeySkill` ([`routing-ambiguity-2026-06-16.md`, lignes 53 et 93](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md?plain=1#L53-L93)). Le cours n'a pas de modèle pour les calculer. Sans modèle, le chatbot épinglé a répondu HTTP 500 à toutes les questions de la [leçon 25](../25-what-reaches-the-transpose-skill/) ; le routeur de `main` demande à chaque intention si elle correspond sans embeddings, puis son routeur d'agents se rabat sur des mots-clés. Le programme pose à l'hôte de `main` les 7 prompts d'exemple et trois des formulations du cours :

```text
== Without embeddings: the intent SemanticIntentRouter picks for the example prompts and three of the course's phrasings, and what POST /api/chatbot/chat answers (on main)
phrasing                                                   router picks             chat: agent (routing method)                  first line of the answer
What is the difference between major and minor             none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [wha…
Compare major and minor                                    none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [min…
Major vs minor                                             none                     voicing (keyword)                             Found 10 voicings matching mode Major + tags [min…
Major versus minor                                         none                     voicing (keyword)                             Found 10 voicings matching mode Major + tags [min…
Difference between major and minor scales                  none                     fallback-direct (error-fallback-unavailable)  Our reasoning service is currently unavailable, s…
Explain the difference between major and minor             none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [the…
How do major and minor differ                              none                     voicing (keyword)                             Found 10 voicings matching mode major + tags [min…
Minor vs major                                             none                     voicing (keyword)                             Found 10 voicings matching mode Minor + tags [maj…
Difference between a major and a minor chord               skill.chordinfo          skill.chordinfo (orchestrator-skill-semantic) A minor chord contains A, C, and E.
C major vs C minor                                         none                     voicing (keyword)                             Found 10 voicings matching chord C + mode major +…
10 phrasings; the router picks none 9, skill.chordinfo 1; the chat endpoint answers with voicing (keyword) 8, fallback-direct (error-fallback-unavailable) 1, skill.chordinfo (orchestrator-skill-semantic) 1
```

- **Aucun des 7 prompts d'exemple n'atteint le skill.** 6 reçoivent une recherche de voicings, avec « major » ou « minor » comme mode et d'autres mots de la question comme étiquettes ; un reçoit le repli, « Our reasoning service is currently unavailable ».
- **« Difference between a major and a minor chord » reçoit « A minor chord contains A, C, and E. »** `ChordInfoSkill` l'accepte et lit l'article « a » comme une fondamentale, comme l'avait trouvé la [leçon 15](../15-the-notes-of-a-chord/), signalé dans [#782](https://github.com/GuitarAlchemist/ga/issues/782).
- **`main` a donné le correctif à un autre skill.** Le `CanHandle` de `RelativeKeySkill` accepte désormais exactement les formulations que lisent ses expressions régulières : « this predicate only serves the offline keyword fallback » ([lignes 50-63 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L50-L63)). Celui de `TheoryComparisonSkill` vaut toujours `false`.

## Où le cours s'arrête

- **Aucun routeur avec embeddings ne tourne.** Les formulations que le chatbot déployé envoie au skill dépendent de ses embeddings.
- **Le paragraphe « Common associations » de la réponse n'est pas vérifié.** Il dit lui-même qu'il s'agit de « cultural shorthand, not absolutes ».
- **Sur `main`, le programme pose 10 questions, pas 27,** pour que son exécution reste courte.

## Exercices

1. Pourquoi « Explain the major vs minor difference » est-il refusé, alors que « Major vs minor » reçoit la réponse ?
2. Quel changement de `DifferencePattern` laisserait passer « What is the difference between the major and minor scales » ? Quelle autre formulation refusée laisserait-il passer ?
3. Pour quel mineur « the single interval that flips is the third » est-il vrai ?
4. Pourquoi `RelativeKeySkill` refuse-t-il « C major vs C minor », alors qu'il répond à « Parallel minor of C major » ?

<details>
<summary>Solutions</summary>

1. `VsPattern` refuse « major » quand une lettre de A à G et une espace le précèdent, et la casse étant ignorée, le « e » de « the » est une telle lettre. « Major vs minor » commence la question : rien ne précède « Major ». `DifferencePattern` ne correspond pas non plus : la question n'a pas de « between ».
2. Un article facultatif devant chaque mot, `(?:the\s+|a\s+)?`, après « between » et après « and ». Il laisserait aussi passer « Difference between a major and a minor chord », vers une réponse sur les gammes. Raisonnement fait sur le code : le programme n'exécute pas l'expression régulière modifiée.
3. Le mineur mélodique, en montant : il ne diffère du majeur qu'au 3e degré. Les mineurs naturel et harmonique diffèrent aussi au 6e, et le mineur naturel au 7e.
4. Ses motifs exigent « relative » ou « parallel » suivis de « minor of » ou « major of », ou une question d'armure. « C major vs C minor » n'a rien de tout cela : il reçoit le refus.

</details>

## À retenir

- Sept exemples écrits de la même façon ne prouvent qu'une formulation : une réponse fixe n'est atteignable qu'autant que les expressions régulières placées devant elle.
- Un commentaire qui confie une question à un autre composant est une affirmation à tester : le skill qu'il nomme la refuse.
- Une réponse qui suggère une question de suivi devrait pouvoir y répondre.
- Une phrase doit s'accorder avec le tableau qu'elle surmonte.
- Un skill que seuls les embeddings peuvent atteindre se tait dès que les embeddings sont indisponibles.

## Sources

- GuitarAlchemist/ga à [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/TheoryComparisonSkill.cs`, `Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs`, `state/quality/routing-diagnostic/routing-ambiguity-2026-06-16.md`.
- GuitarAlchemist/ga à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : l'hôte du chatbot que démarre `GaMain`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson28.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ComparisonProbe.cs`.
