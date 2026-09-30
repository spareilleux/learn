---
title: "Leçon 12 : ce que répondent les skills de progression"
description: "Le chatbot de Guitar Alchemist a deux skills qui prennent une progression d'accords : l'un répond par un texte fixe, l'autre laisse le modèle proposer l'accord suivant dans une liste qu'il calcule. Le cours pose à chacun ses propres prompts d'exemple et demande l'accord suivant de deux progressions de manuel dans les 30 tonalités : six prompts qui demandent d'éclaircir reçoivent la réponse pour assombrir, G Em C reçoit les accords de C majeur au commit épinglé, et la liste d'aucune tonalité mineure ne contient sa dominante."
sidebar:
  label: 12. Ce que répondent les skills de progression
  order: 12
---

La [leçon 11](../11-the-chords-the-key-skill-reads/) suivait une question sur les tonalités. Le plus souvent, un guitariste a déjà une progression et veut en faire quelque chose. Le chatbot de GA a deux skills pour cela. [`ProgressionMoodSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs) explique comment rendre une progression plus sombre ou plus lumineuse, avec « zero LLM calls », sans le moindre appel au modèle de langage : il renvoie l'un de deux textes fixes ([ligne 7](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L7)). [`ProgressionCompletionSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs) propose l'accord suivant : `KeyIdentificationService`, le service de la leçon 11, « detects the key and diatonic set deterministically; the LLM selects and explains cadence candidates from that pre-computed set » (le service détecte de façon déterministe la tonalité et son ensemble diatonique, et le modèle choisit et explique des cadences dans cet ensemble calculé d'avance ; [lignes 11-12](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L11-L12)). Chaque skill a un SKILL.md, [progression-mood](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md) et [progression-completion](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md), l'autre point d'entrée : le SKILL.md d'ambiance donne au modèle le même catalogue, et celui de complétion lui fait appeler `ga_key_identify`, un outil qui exécute le même service. Le skill qui analyserait une progression, avec sa tonalité, ses chiffres romains et ses cadences, n'est qu'un brouillon, bloqué sur un outil `ga_analyze_progression` « not yet implemented in Common/GA.Business.ML/Agents/Mcp/ », pas encore implémenté ([`skills-dev/_pending-tools/progression-analysis/DRAFT.md` ligne 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur `main` au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), `ProgressionMoodSkill.cs`, les deux fichiers SKILL.md et le brouillon sont inchangés ; `ProgressionCompletionSkill.cs` ne diffère du commit épinglé que par une ligne `using` et par un indicateur qui marque un refus. Ce qui a changé, c'est le service qu'il appelle, que la leçon 11 a compilé au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) contre le domaine épinglé ; le programme réutilise ce projet, `GaKeysMain`. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l12
```

## Les deux skills

Le programme héberge GaChatbot.Api dans son propre processus, comme dans la leçon 9, et liste les intentions que le routeur peut choisir et dont le nom contient « progression » :

```text
== The intents that take a chord progression
skill.progressionmood          ProgressionMoodSkill         15 example prompts
skill.progressioncompletion    ProgressionCompletionSkill   5 example prompts
```

Le skill d'ambiance n'a pas besoin de modèle : le programme l'appelle donc comme le fait le chatbot, par son intention. Le skill de complétion appelle le modèle après le service ; le programme exécute les étapes qui précèdent cet appel et lit le prompt qu'elles construisent, sans exécuter le modèle.

## Plus lumineux ou plus sombre

Le skill d'ambiance choisit son texte avec un seul test ([lignes 58-66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L58-L66)) :

```csharp
    public Task<AgentResponse> ExecuteAsync(string message, CancellationToken cancellationToken = default)
    {
        var lower = message.ToLowerInvariant();
        var brighten = lower.Contains("brighter") || lower.Contains("uplift") || lower.Contains("happier");

        return Task.FromResult(brighten
            ? BrightenAnswer()
            : DarkenAnswer());
    }
```

Le programme lui pose ses 15 prompts d'exemple, ceux auxquels le routeur compare les questions, et note ce que chacun demande :

```text
== ProgressionMoodSkill's example prompts: what each asks for, and the answer it gets
prompt                                                     asks       gets
How do I make this progression sound darker?               darken     darken
Make this progression sound moodier                        darken     darken
How can I make my chords sound sadder?                     darken     darken
What can I do to make a song sound more melancholy?        darken     darken
How to add a darker feel to a chord progression            darken     darken
Techniques to make a major progression minor-sounding      darken     darken
Make my song sound brighter                                brighten   brighten
How to make a progression more uplifting                   brighten   brighten
Brighten up a minor key tune                               brighten   darken
Brighten this minor song                                   brighten   darken
How do I lift the mood of a minor progression?             brighten   darken
How does Mixolydian flavor brighten rock progressions?     brighten   darken
Use Lydian color to brighten a major progression           brighten   darken
Phrygian flavor to darken a progression                    darken     darken
What mode adds the most brightness to a major key tune?    brighten   darken
7 prompts ask to darken: 7 get the darken answer
8 prompts ask to brighten: 2 get the brighten answer
```

« Brighten » et « brightness » ne contiennent pas « brighter », et « lift the mood » n'est pas « uplift ». Six des huit prompts qui demandent d'éclaircir reçoivent les cinq façons d'assombrir. Ce sont les six prompts d'éclaircissement ajoutés le 2026-05-12 pour corriger des erreurs de routage, comme le consignent les commentaires des [lignes 36-53](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L36-L53) : le routage les amène désormais au skill, et le skill répond l'inverse de ce qu'ils demandent. Le SKILL.md donne au modèle la même règle, « pick the **brighten** branch when the query mentions brighter / uplifting / happier » (choisir la branche brighten quand la requête mentionne brighter, uplifting ou happier ; [ligne 36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L36)), alors que ses déclencheurs listent « brighten » ([ligne 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L17)). Ce qu'un modèle fait de cette règle n'est pas exécuté ici (*à vérifier*).

## Les accords qu'écrivent les deux textes

Le programme liste les progressions que chaque texte écrit entre accents graves, et signale tout élément qui n'est ni un chiffrage d'accord ni un chiffre romain :

```text
== The progressions each text writes out
ProgressionMoodSkill, darken answer:
  C F G
  C Fm G
  C bA G   <- bA: neither a chord symbol nor a Roman numeral
  C bB F   <- bB: neither a chord symbol nor a Roman numeral
  C G F
ProgressionMoodSkill, brighten answer:
  I bVII IV I
skills/progression-mood/SKILL.md, the progressions written with chord names:
  C F G
  C Fm G
  C F Gm
  C Am F G
  C Am Ab G
  C Bb F
  C G F
```

`bA` et `bB` ne sont ni l'un ni l'autre : un chiffrage d'accord écrit son bémol après la lettre, `Ab` et `Bb`, et un chiffre romain l'écrit avant le chiffre, `bVI` et `bVII` ([lignes 74 et 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L74-L77)). Le SKILL.md écrit `C Am Ab G` et `C Bb F` ([lignes 48](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L48) et [51](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L51)) et demande au modèle « Reproduce the technique list verbatim », de reproduire la liste des techniques mot pour mot ([ligne 38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L38)). Les deux listes diffèrent par plus que l'orthographe. Dans le texte C#, la deuxième technique pour assombrir est `IV → iv`, `vi → bVI` et `V → v` ; le SKILL.md a `IV → iv` et `V → v`, ajoute `bIII`, `bVI` et `bVII` empruntés au mineur homonyme, et donne trois exemples détaillés, dont l'un mentionne `vi → bVI`. Dans le texte C#, la deuxième technique pour éclaircir hausse le quatrième degré, « #iv° actually », ou tient un IV avec une #11 ([ligne 104](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L104)) ; le SKILL.md utilise un `IVmaj7#11` ou un `II` majeur ([ligne 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-mood/SKILL.md#L60)).

## Le test par mots-clés

Chaque skill a aussi une méthode `CanHandle`, un test sur les mots de la question. Au commit épinglé, rien ne l'appelle en dehors des tests : le routeur compare des embeddings. Sur `main`, [`OrchestratorSkillIntent`](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29) la transmet au routeur, qui s'y replie quand il ne peut pas calculer l'embedding de la question, et qui donne alors la question à la première intention dont le test l'accepte ([`SemanticIntentRouter.cs` ligne 321](https://github.com/GuitarAlchemist/ga/blob/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L321)). Les tests des deux skills sont inchangés sur `main`. Le programme soumet à chaque test les prompts d'exemple de son propre skill :

```text
== CanHandle, the keyword test main's router falls back on when it has no embeddings
ProgressionMoodSkill: 0 of 15 example prompts accepted
ProgressionCompletionSkill: 3 of 5 example prompts accepted
  rejected: What chord comes next after C G Am?
  rejected: Help me end Am F G
```

Le test du skill d'ambiance renvoie `false` ([ligne 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs#L56)) : sans embeddings, `main` ne l'atteint donc jamais. Le déclencheur du skill de complétion ([lignes 35-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L35-L37)) contient `what\s+comes\s+next`, que « What chord comes next » ne satisfait pas, et aucun « help me end », que le SKILL.md liste pourtant parmi ses déclencheurs ([ligne 17](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L17)) :

```csharp
    private static readonly Regex CompletionTrigger = new(
        @"\b(finish|complete|end\s+it|end\s+this|what\s+comes\s+next|next\s+chord|help\s+me\s+finish|how\s+(do\s+i|to)\s+end|what\s+should\s+follow|continue|extend)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

## Ce que le skill de complétion dit au modèle

`ExecuteAsync` lit les accords avec `ExtractChords`, attribue un score aux tonalités avec `Identify`, et passe à `BuildPrompt` la première tonalité et la liste entière ([lignes 49-67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L49-L67)). `BuildPrompt` nomme toutes les tonalités à égalité avec la première, mais prend les accords que le modèle peut proposer dans la première seule ([lignes 93-107](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L93-L107)) :

```csharp
        var topTied = all.Where(c => c.MatchCount == top.MatchCount).ToList();
        var keyDesc = topTied.Count == 1
            ? top.Key
            : string.Join(" / ", topTied.Select(c => c.Key));
```

`BuildPrompt` est privée ; le programme l'appelle par réflexion et affiche ce que lit le modèle pour le premier prompt d'exemple du skill, de la progression jusqu'aux règles, puis les deux suggestions de l'exemple JSON qui clôt le prompt :

```text
== What the model reads for "What chord comes next after C G Am?", pinned
  | The input progression is: [C, G, Am]
  | Detected key: A minor / C major / E minor / G major  (3/3 chords diatonic)
  |
  | AVAILABLE DIATONIC CHORDS — you may ONLY suggest chords from this list:
  | Am, Bdim, C, Dm, Em, F, G
  |
  | Task: Suggest 2-3 chord completions (each 1-2 chords) that cadence naturally
  | to end or continue the progression in A minor / C major / E minor / G major.
  |
  | For each suggestion:
  |   - Name the cadence type (authentic, half, deceptive, or plagal)
  |   - Give the Roman numeral(s)
  |   - Write a one-sentence guitarist-friendly explanation
  |
  | IMPORTANT: Every chord you suggest MUST appear in the AVAILABLE DIATONIC CHORDS list.
  | You may substitute the plain V chord with V7 even if only V appears in the diatonic list
  | (this is the standard harmonic minor adjustment).
  |
  | { "chords": ["E7"], "cadence": "authentic", "roman": "V7-i", "explanation": "Strongest resolution back to Am." },
  | { "chords": ["G"],  "cadence": "half",      "roman": "bVII-i", "explanation": "Open loop, floats back to the top." }
```

C'est la première tonalité qui décide de la liste. Au commit épinglé, `Identify` trie les tonalités par décompte, puis par nom ([`KeyIdentificationService.cs` lignes 177-178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L177-L178)). Sur `main`, il les trie par décompte plus un poids pour la cadence finale, puis place d'abord la tonalité dont la triade de tonique ouvre la progression, puis la tonalité majeure, et enfin le nom ([lignes 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). Pour `main`, le programme applique les lignes du skill au service de `main` ; pour le commit épinglé, il confronte ces lignes au prompt qu'écrit `BuildPrompt` lui-même, sur chaque question de la leçon.

## Les exemples du skill lui-même

Le programme pose les cinq prompts d'exemple du skill, puis la progression seule de l'exemple du SKILL.md :

```text
== ProgressionCompletionSkill's example prompts: the key and the chords the model may suggest
"What chord comes next after C G Am?"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"How do I finish this progression: Em D C"
  a826864  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
  6baf32e  reads Em D C; key: E minor / G major (3/3)
           may suggest: Em, F#dim, G, Am, Bm, C, D
"Help me end Am F G"
  a826864  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Am F G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
"What should follow Dm G C?"
  a826864  reads Dm G C; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads Dm G C; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"Continue this progression: F C G"
  a826864  reads F C G; key: A minor / C major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads F C G; key: C major / A minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
"C G Am"
  a826864  reads C G Am; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C G Am; key: C major / G major / A minor / E minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
```

C G Am, le premier exemple du skill et le seul du SKILL.md, convient à quatre tonalités : C majeur et A mineur, mais aussi G majeur et E mineur, dont la gamme contient F♯ au lieu de F. Au commit épinglé, A mineur vient en premier par le nom ; sur `main`, c'est C majeur, qui ouvre la progression. Le SKILL.md décrit un autre résultat : « `TopCandidates: [{ Key: "C major", DiatonicSet: [C, Dm, Em, F, G, Am, B°] }, ...]` (also tied with A minor) » ([ligne 86](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L86)). Au commit épinglé, A mineur est en premier, G majeur et E mineur sont eux aussi à égalité, et la liste écrit `Bdim`, pas `B°`. Sa réponse d'exemple propose ensuite `Dm → G7` ([ligne 92](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L92)) : G7 n'est pas dans la liste, et la première contrainte stricte du SKILL.md est « Every suggested chord must appear in `DiatonicSet` », que chaque accord proposé figure dans la liste ([ligne 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). Sur les égalités, le SKILL.md dit que des tonalités relatives partagent le même ensemble diatonique, et qu'une égalité avec une autre tonalité est rare, réservée aux « very short progressions », les progressions très courtes ([ligne 56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L56)).

## L'accord suivant dans trente tonalités

Le programme demande « What chord comes next after …? » pour I vi IV dans les 15 tonalités majeures et pour i VI VII dans les 15 tonalités mineures, écrits comme les écrit un manuel, et compare la liste dans laquelle le modèle peut choisir aux sept triades de la tonalité :

```text
== "What chord comes next after ...?" for two textbook progressions in the 30 keys

I vi IV             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
           a826864  =  x  e  x  x  =  x  =  x  =  =  x  e  r  r
           6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  r  r

i VI VII            Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
           a826864  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r
           6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  r  r  r

= the chords read as written, and the model may suggest the key's chords as the textbook spells them;
e the same chords, spelled from the enharmonic key; x other chords; r a chord dropped or read as another chord
a826864: 30 questions, = 15, e 4, x 6, r 5; a key of another scale tied at the top in 13 of the 25 read as written
6baf32e: 30 questions, = 20, e 5, x 0, r 5; a key of another scale tied at the top in 13 of the 25 read as written
```

- **`x`, le commit épinglé, six tonalités majeures.** G Em C est I vi IV en G majeur et V iii I en C majeur, et les quatre tonalités de C G Am sont de nouveau à égalité ; A mineur vient en premier par le nom, et le modèle ne peut proposer que les accords de C majeur, sans D, la dominante de G majeur. En G♭, A♭, E♭, F et E majeur aussi, une tonalité de l'autre gamme passe en premier par le nom. Sur `main`, c'est la tonalité dont la triade de tonique ouvre la progression qui passe en premier : la ligne n'a plus de `x`, même si G♭ majeur y devient F♯ majeur (`e`).
- **`e`, écrit depuis la tonalité enharmonique.** D♭ B♭m G♭ met huit tonalités à égalité, les quatre noms de D♭ majeur et les quatre de G♭ majeur. Au commit épinglé, A♯ mineur vient en premier, et le modèle peut proposer `A#m, B#dim, C#, D#m, E#m, F#, G#` pour une question écrite avec des bémols ; sur `main`, c'est C♯ majeur. Quatre questions au commit épinglé, D♭ et B majeur, E♭ et B♭ mineur ; cinq sur `main`, où C♭, G♭ et D♭ majeur deviennent B, F♯ et C♯ majeur, et où E♭ et B♭ mineur deviennent D♯ et A♯ mineur.
- **`r`, un dièse perdu.** `ExtractChords` perd un dièse devant une espace ou un point d'interrogation ([#771](https://github.com/GuitarAlchemist/ga/issues/771)) : F♯ D♯m B est lu F D♯m B, et au commit épinglé, le modèle peut proposer les accords de A♭ mineur, `Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb`.
- **Égalités avec une autre gamme.** Chaque I vi IV lu tel qu'il est écrit est à égalité avec la tonalité située une quarte plus haut, où les trois accords sont V iii I : 13 des 25 questions lues telles qu'elles sont écrites, et non un cas rare de progressions très courtes.

```text
C major, I vi IV: "What chord comes next after C Am F?"
  a826864  reads C Am F; key: A minor / C major / D minor / F major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads C Am F; key: C major / F major / A minor / D minor (3/3)
           may suggest: C, Dm, Em, F, G, Am, Bdim
G major, I vi IV: "What chord comes next after G Em C?"
  a826864  reads G Em C; key: A minor / C major / E minor / G major (3/3)
           may suggest: Am, Bdim, C, Dm, Em, F, G
  6baf32e  reads G Em C; key: G major / C major / A minor / E minor (3/3)
           may suggest: G, Am, Bm, C, D, Em, F#dim
Db major, I vi IV: "What chord comes next after Db Bbm Gb?"
  a826864  reads Db Bbm Gb; key: A# minor / Bb minor / C# major / D# minor / Db major / Eb minor / F# major / Gb major (3/3)
           may suggest: A#m, B#dim, C#, D#m, E#m, F#, G#
  6baf32e  reads Db Bbm Gb; key: C# major / Db major / F# major / Gb major / A# minor / Bb minor / D# minor / Eb minor (3/3)
           may suggest: C#, D#m, E#m, F#, G#, A#m, B#dim
F# major, I vi IV: "What chord comes next after F# D#m B?"
  a826864  reads F D#m B; key: Ab minor / B major / Cb major / D# minor / Eb minor / F# major / G# minor / Gb major (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads F D#m B; key: B major / Cb major / F# major / Gb major / Ab minor / D# minor / Eb minor / G# minor (2/3)
           may suggest: B, C#m, D#m, E, F#, G#m, A#dim
G# minor, i VI VII: "What chord comes next after G#m E F#?"
  a826864  reads G#m E F; key: Ab minor / B major / C# minor / Cb major / E major / G# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
  6baf32e  reads G#m E F; key: Ab minor / G# minor / B major / Cb major / E major / C# minor (2/3)
           may suggest: Abm, Bbdim, Cb, Dbm, Ebm, Fb, Gb
```

## La dominante d'une tonalité mineure

La liste est faite des sept triades de la tonalité, celles du mineur naturel pour une tonalité mineure ([lignes 39-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L39-L45)). Le programme cherche les triades du cinquième degré dans la propre liste de chaque tonalité :

```text
== The dominant the list holds, in each key's own list
15 major keys: the major triad on the fifth degree in 15, the minor one in 0
15 minor keys: the major triad on the fifth degree in 0, the minor one in 15
A minor: Am, Bdim, C, Dm, Em, F, G
  the prompt's example suggests E7 ("V7-i"): E7 in the list: no; E: no
  and G as a half cadence ("bVII-i"): G is degree 7 of the list; a half cadence ends on degree 5, Em
```

En mineur, une cadence prend d'ordinaire sa dominante dans le mineur harmonique : E ou E7 en A mineur, avec la sensible G♯. Aucune liste de tonalité mineure ne la contient. Le prompt ne l'autorise que si elle s'y trouve déjà : « You may substitute the plain V chord with V7 even if only V appears in the diatonic list (this is the standard harmonic minor adjustment) » (le modèle peut remplacer le simple V par V7 même si seul V figure dans la liste ; [lignes 117-119](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L117-L119)) ; dans une tonalité mineure, seul v y figure. Son propre exemple propose ensuite E7 comme V7–i de A mineur ([ligne 130](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L130)), un accord que sa liste ne contient pas, et G comme demi-cadence, « bVII-i » ([ligne 131](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs#L131)) : une demi-cadence se termine sur V, « anything → V » dans le catalogue du SKILL.md ([ligne 67](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L67)), et G est le septième degré. Le SKILL.md autorise V7 en mineur « even when only `v` appears » ([ligne 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)) et interdit tout accord hors de la liste ([ligne 96](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L96)). Dans une tonalité mineure, le modèle ne peut pas proposer de cadence parfaite sans enfreindre l'une des deux règles.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Ce qu'il propose à partir de ces listes, et s'il suit la règle du V7 ou la liste, demande le modèle (*à vérifier*).
- **Le routage n'est pas testé.** C'est le modèle d'embeddings qui décide quelles questions atteignent les deux skills ; le test par mots-clés n'est soumis qu'aux exemples des skills eux-mêmes.
- **Le skill de complétion de `main` n'est pas exécuté.** Ses lignes sont appliquées au service de `main` à `6baf32e`, compilé contre le domaine épinglé ; pour le commit épinglé, les mêmes lignes sont confrontées à `BuildPrompt` sur les 36 questions.
- **Le skill d'analyse n'existe pas.** Le chatbot n'en a aucun, ni au commit épinglé ni sur `main`. La closure `domain.analyzeProgression` du DSL existe, et l'outil `GaAnalyzeProgression` de GaMcpServer l'appelle ([`GaDslTool.cs` lignes 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), mais aucun skill du chatbot ne le fait ; cette leçon ne l'exécute pas.
- **Deux progressions de manuel**, en triades à l'état fondamental.

## Signalé en amont

- Non signalés en amont au moment où cette leçon a été écrite : le test d'éclaircissement, les accords des deux textes, les listes prises dans la première tonalité par ordre de nom, les listes écrites depuis la tonalité enharmonique, la dominante absente de la liste d'une tonalité mineure, l'exemple du prompt, l'exemple du SKILL.md et les tests par mots-clés. Les dièses perdus relèvent de [#771](https://github.com/GuitarAlchemist/ga/issues/771), et l'ordre des tonalités qui ont les mêmes classes de hauteurs a la même cause que [#772](https://github.com/GuitarAlchemist/ga/issues/772). Tous sont listés dans le [journal](../journal/).

## Exercices

1. Réécris le test du skill d'ambiance pour que ses 15 prompts d'exemple reçoivent la réponse qu'ils demandent. Le SKILL.md dit de choisir la branche pour assombrir quand les deux ambiances apparaissent : que répond ton test à « How do I make a happier song sound darker? » ?
2. Pour « What chord comes next after G Em C? », le skill épinglé propose les accords de C majeur. Quelle règle, appliquée avant le nom, donne la liste de G majeur, et que donne-t-elle pour C G Am et pour Am F G ?
3. Modifie la liste d'une tonalité mineure pour que le modèle puisse proposer une cadence parfaite sans enfreindre les règles du prompt. Quel accord ajoutes-tu à la liste de A mineur, qu'autorise alors la règle du V7 du prompt, et que doit changer le SKILL.md ?
4. Avec la liste de A mineur telle qu'elle est, lesquelles des quatre cadences du SKILL.md ([lignes 64-69](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L64-L69)) le modèle peut-il construire ?

<details>
<summary>Solutions</summary>

1. Teste d'abord les mots qui assombrissent, `dark`, `sad`, `moodier`, `melancholy` et `minor-sounding`, puis les radicaux `bright`, `lift` et `happ`. « Brighten », « brightness », « lift the mood », « uplifting » et « happier » contiennent chacun l'un de ces radicaux, et aucun des huit prompts d'éclaircissement ne contient un mot qui assombrit (« lift the mood » contient « mood », pas « moodier »). « How do I make a happier song sound darker? » reçoit alors la réponse pour assombrir, comme le demande le SKILL.md ; le test épinglé choisit d'éclaircir, parce que la question contient « happier ». Résolu à la main sur les 15 prompts.
2. Préfère la tonalité dont la triade de tonique est le premier accord, comme le fait `main`. G Em C reçoit la liste de G majeur, C G Am celle de C majeur et Am F G celle de A mineur : la sortie ci-dessus montre `main` plaçant G majeur, C majeur et A mineur en premier. Résolu à partir de la sortie.
3. Ajoute la triade de dominante du mineur harmonique, E pour A mineur : le cinquième degré de `Key.Notes` en triade majeure. La règle du prompt fonctionne alors en mineur comme en majeur : V figure dans la liste, le modèle peut donc écrire V7, et l'exemple E7 du prompt devient juste. La contrainte stricte du SKILL.md interdit toujours E7, comme elle interdit G7 en C majeur, que son propre exemple propose pourtant : il lui faut la même exception pour V7 que celle du prompt. Résolu à la main.
4. Seule la cadence plagale, sous la forme iv–i, Dm–Am : le SKILL.md dit « In a minor key, substitute as needed » ([ligne 71](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/progression-completion/SKILL.md#L71)). La cadence parfaite (V → I) et la cadence rompue (V → vi) demandent le V majeur, qui n'est pas dans la liste. Une demi-cadence se termine sur V, et la liste n'a que v, Em, une dominante sans la sensible G♯. Résolu à la main.

</details>

## À retenir

- Une réponse fixe est tout de même choisie par un test : quand ce test manque « brighten », une question bien routée reçoit la réponse inverse, et corriger le routage a conduit la question tout droit au bogue.
- Un skill qui restreint le modèle à une liste décide de la réponse par cette liste : au commit épinglé, les égalités tranchées par le nom donnent à G Em C les accords de C majeur.
- Une liste et les règles qui la concernent doivent s'accorder : le prompt autorise V7 quand V figure dans la liste, et dans une tonalité mineure, il n'y figure jamais.
- L'exemple d'un prompt ou d'un SKILL.md instruit le modèle : E7 hors de la liste, une demi-cadence qui ne se termine pas sur V, G7 contre la contrainte stricte.
- Deux textes censés dire la même chose finissent par diverger : la réponse C# écrit `bA` et `bB`, le SKILL.md `Ab` et `Bb`, avec des techniques différentes.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ProgressionMoodSkill.cs`, `Common/GA.Business.ML/Agents/Skills/ProgressionCompletionSkill.cs`, `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `skills/progression-mood/SKILL.md`, `skills/progression-completion/SKILL.md`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`, `GaMcpServer/Tools/GaDslTool.cs`.
- GA au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), daté du 2026-09-25 en UTC : `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilé par le cours. Le `main` de GA au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), daté du 2026-09-30 en UTC : `OrchestratorSkillIntent.cs` et `SemanticIntentRouter.cs`, et la comparaison des deux skills, de leurs fichiers SKILL.md et du brouillon.
- *Open Music Theory*, les chapitres sur les cadences, le septième degré haussé de la gamme mineure et l'emprunt au mode homonyme.
