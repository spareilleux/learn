---
title: "Leçon 22 : les accords semblables"
description: "IcvNeighborsSkill est la réponse du chatbot de Guitar Alchemist à la question des accords semblables à un accord donné : il lit un accord et liste les ensembles de classes de hauteurs dont le vecteur d'intervalles est à 2 au plus du sien. Aucun de ses dix prompts d'exemple, les questions que le routeur a le plus de chances de lui envoyer, ne correspond aux expressions qu'il lit : il les décline donc tous les dix, là où son skill jumeau répond à huit des siens. Sur 27 accords courants, il en construit 10 correctement, et CM7 comme une septième mineure ; ses huit voisins sont les huit premiers ensembles par masque de bits : les mêmes pour toutes les triades majeures et mineures, et cinq d'entre eux sont des intervalles de deux notes."
sidebar:
  label: 22. Les accords semblables
  order: 22
---

La [leçon 21](../21-the-voicing-search/) a mesuré la recherche par embeddings. Pour les accords qui partagent une forme dans n'importe quelle tonalité, GA renvoie ailleurs : « Transposition-agnostic "same-shape" similarity uses the ICV path (`IcvNeighborsSkill` / Grothendieck), not the embedding » ([`CLAUDE.md` ligne 43](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/CLAUDE.md#L43)). `IcvNeighborsSkill` est ce chemin dans le chatbot ([`IcvNeighborsSkill.cs` lignes 9-49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L9-L49)), enregistré avec les autres skills ([`GaPlugin.cs` ligne 101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs#L101)). Il lit un accord, construit son ensemble de classes de hauteurs, et liste les ensembles dont le vecteur d'intervalles est à une distance L1 de 2 au plus de celui de l'accord, d'après `GrothendieckService.FindNearby`. La [leçon 14](../14-what-the-substitution-skill-answers/) a rencontré `FindNearby` par le skill de substitution, et le [cours de théorie musicale](../../music-theory-ga/04-set-classes/) par l'outil MCP `ga_icv_neighbors` ; cette leçon interroge le skill du chatbot.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01), `IcvNeighborsSkill` et `IntervalClassVectorSkill` ne font que marquer leur refus `Declined`, `DefaultRoutingHintProvider` et `GrothendieckDelta` sont inchangés, et `FindNearby` compare l'ensemble de départ à chaque ensemble par valeur ; les ensembles de classes de hauteurs eux-mêmes ont changé : `GaMain` repose donc les questions. Sa sortie affiche les mêmes tableaux que celle du commit épinglé, sous des titres qui portent « on main ». Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l22
dotnet run --project code/ga-ai/GaMain -c Release -- l22
```

## Comment le skill lit une question

Le skill n'a pas de test par mots-clés : son `CanHandle` répond toujours non, et le routeur compare une question à la description et aux prompts d'exemple de chaque skill, ajoute les bonus des indices de routage, et l'envoie au skill qui obtient le meilleur score, si ce score atteint un seuil de confiance ([`SemanticIntentRouter.cs` lignes 129-257](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs#L129-L257)). Ces prompts ont été reformulés le 2026-06-16, pour les tenir à l'écart de ceux des skills voisins, et le commentaire placé au-dessus d'eux dit quels mots ont été retirés. Les expressions régulières qui lisent la question en ont toujours besoin :

```csharp
    // Routing anchors emphasise the user GOAL — "find OTHER chords SIMILAR to
    // one chord" — using resemble/similar/most-like/interval-profile. Two
    // curation passes (routing-ambiguity diagnostic, 2026-06-16):
    //  1. dropped the bare "ICV" framing (owned by IntervalClassVectorSkill,
    //     the single-chord ICV intent): -0.05 -> +0.036 silhouette.
    //  2. dropped "close/nearby/adjacent" (collided with GrothendieckDeltaSkill's
    //     "how close are X and Y") and "chords to C major" (collided with
    //     ChordInfoSkill's "what is a C major chord"). "other … resemble/similar"
    //     keeps the find-similar goal while shedding both neighbours' vocabulary.
    public IReadOnlyList<string> ExamplePrompts =>
    [
        "which chords are most similar to Dm7",
        "what other chords resemble Cmaj7",
        "find chords with a similar sound to G7",
        "chords related to F major by interval content",
        "what chords share Gmaj7's interval profile",
        "list chords most like E minor",
        "chords with similar interval content to Bm7b5",
        "what voicings are most similar to Am",
        "which chords are closest in interval content to Fmaj7",
        "chords that resemble Cmaj7 harmonically",
    ];

    public bool CanHandle(string message) => false;  // semantic-routing only

    private const int DefaultMaxDistance = 2;
    private const int MaxNeighborsToShow = 8;

    // Single-chord pattern — anchored on "neighbors/near/close/adjacent" + a
    // chord token. Word boundary protects against routing on prose that
    // happens to mention a single chord-letter.
    private static readonly Regex NeighborsPattern =
        new(@"\b(?:icv\s+neighbors?|neighbors?|nearby|close\s+to|near|adjacent|harmonic(?:ally)?\s+(?:close|near|adjacent))\s+(?:to\s+|of\s+)?(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);

    // Reverse anchor: "<chord> ... (icv-)neighbors" / "<chord> ... close"
    private static readonly Regex NeighborsPatternReverse =
        new(@"\b(?<chord>[A-Ga-g][b#♭♯]?(?:maj|min|m|dim|aug|sus|add|dom)?\d*(?:[b#♭♯]\d+)*°?)\b[^.?!]*?\b(?:icv\s+neighbors?|neighbors?|harmonic(?:ally)?\s+(?:close|near|adjacent))\b",
            RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`ExecuteAsync` essaie la première expression, puis la seconde, prend l'accord qu'elles capturent et construit son ensemble ([lignes 102-118](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L102-L118)). Quand aucune des deux ne correspond, il répond « Ask about ICV-neighbor pitch-class sets near a chord », avec une confiance de 0.1 ([lignes 254-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L254-L260)). Sur le chemin des embeddings, `DefaultRoutingHintProvider` ajoute en outre 0.06 à une intention dont la règle correspond à la question ; la règle de ce skill veut « icv neighbors », « harmonically close » ou quelques variantes ([`DefaultRoutingHintProvider.cs` lignes 136-139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L136-L139)).

## Les formulations de GA

Le programme pose au skill ses dix prompts d'exemple, les quatre formulations de son commentaire de documentation ([lignes 17-23](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L17-L23)), les deux que suggère son refus et les trois du brouillon en attente, et demande à `DefaultRoutingHintProvider` quelles intentions chacune favoriserait :

```text
== IcvNeighborsSkill's example prompts and GA's other phrasings for it, at the pin
prompt                                             from           the skill's answer       routing hints, +0.06 each
which chords are most similar to Dm7               anchor         declined                 none
what other chords resemble Cmaj7                   anchor         declined                 none
find chords with a similar sound to G7             anchor         declined                 none
chords related to F major by interval content      anchor         declined                 none
what chords share Gmaj7's interval profile         anchor         declined                 none
list chords most like E minor                      anchor         declined                 none
chords with similar interval content to Bm7b5      anchor         declined                 none
what voicings are most similar to Am               anchor         declined                 none
which chords are closest in interval content to Fmaj7 anchor         declined                 none
chords that resemble Cmaj7 harmonically            anchor         declined                 none
What chords are harmonically close to Cmaj7        doc comment    neighbors of Cmaj7       skill.icvneighbors
Nearby pitch-class sets to C major                 doc comment    declined                 none
Find ICV neighbors of Dm7                          doc comment    neighbors of Dm7         skill.icvneighbors, skill.intervalclassvector
Closest chord to G7 in ICV space                   doc comment    declined                 skill.intervalclassvector
ICV neighbors of Cmaj7                             refusal        neighbors of Cmaj7       skill.icvneighbors, skill.intervalclassvector
what chords are harmonically close to Dm7          refusal        neighbors of Dm7         skill.icvneighbors
Harmonically similar chords to Cmaj7               parked draft   declined                 none
ICV neighbours of [0,3,6,9]                        parked draft   declined                 skill.intervalclassvector
What's close to a half-diminished chord?           parked draft   neighbors of a           skill.interval
anchors 10: answered 0, declined 10, hinted toward skill.icvneighbors 0
CanHandle accepts 0 of them
```

- **Le skill décline ses dix prompts d'exemple, sans exception.** « most similar », « resemble », « closest in interval content » : aucun n'est un mot que lisent les expressions. Une question formulée comme eux est celle qui a le plus de chances d'atteindre le skill, puisque le routeur compare les questions à ces prompts, et le skill lui oppose son refus. Sur `main`, le refus est marqué `Declined`, « so a caller may route it to another handler » ([`GuitarAlchemistAgentBase.cs` lignes 347-352 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/Common/GA.Business.ML/Agents/GuitarAlchemistAgentBase.cs#L347-L352)).
- **Aucune règle des indices de routage ne favorise le skill pour ces prompts,** et deux des formulations du commentaire de documentation, « Nearby pitch-class sets to C major » et « Closest chord to G7 in ICV space », sont déclinées elles aussi.
- **La suggestion du refus lui-même, « ICV neighbors of Cmaj7 », favorise deux skills,** celui-ci et `skill.intervalclassvector`, dont la règle reconnaît « icv » n'importe où ([lignes 124-126](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs#L124-L126)).

## Le skill jumeau

`IntervalClassVectorSkill` calcule le vecteur d'un accord, et ses prompts d'exemple ont été revus en même temps : il a gardé le vocabulaire ICV comme « the discriminator vs the neighbors / delta / path skills, which were de-ICV'd » ([`IntervalClassVectorSkill.cs` lignes 43-60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L43-L60)). Le programme lui pose les siens :

```text
== IntervalClassVectorSkill's example prompts, at the pin
prompt                                             the skill's answer
what is the interval-class vector of Cmaj7         ICV of Cmaj7
interval class vector of Dm7                       ICV of Dm7
compute the ICV of the major scale                 ICV of the major scale
interval-class vector of {0,2,4,5,7,9,11}          ICV of {0,2,4,5,7,9,11}
what's the interval vector for G7                  ICV of G7
how many tritones does Cmaj7 contain               declined
compute the interval-class vector of Fmaj7         ICV of Fmaj7
ICV of the dorian mode                             ICV of the dorian
interval class vector for {0,1,4,8}                ICV of {0,1,4,8}
what's the interval content of Am                  declined
anchors 10: answered 8
```

Il répond à huit d'entre eux. Les deux qu'il refuse, « how many tritones does Cmaj7 contain » et « what's the interval content of Am », sont les deux prompts qui n'ont ni ensemble de nombres, ni « interval vector », « interval-class vector » ou « ICV », dont ont besoin ses expressions pour les accords et les gammes ([lignes 64-77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs#L64-L77)).

## Les accords qu'il lit

L'accord est une lettre, une altération, l'un de huit mots, des chiffres, des degrés altérés et un ° facultatif, puis une limite de mot. `TryBuildPcSet` construit son ensemble à partir d'une table de 16 qualités ([lignes 196-232](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L196-L232)) :

```csharp
    private static int[] QualityIntervals(string quality)
    {
        var q = quality.ToLowerInvariant().Trim();
        if (q == string.Empty || q == "maj" || q == "major") return [0, 4, 7];
        if (q is "m" or "min" or "minor" or "-") return [0, 3, 7];
        if (q is "dim" or "°" or "o") return [0, 3, 6];
        if (q is "aug" or "+") return [0, 4, 8];
        if (q is "7") return [0, 4, 7, 10];
        if (q is "m7" or "min7" or "-7") return [0, 3, 7, 10];
        if (q is "maj7" or "major7" or "M7") return [0, 4, 7, 11];
        if (q is "m7b5" or "min7b5" or "ø" or "ø7") return [0, 3, 6, 10];
        if (q is "dim7" or "°7" or "o7") return [0, 3, 6, 9];
        if (q is "sus2") return [0, 2, 7];
        if (q is "sus4" or "sus") return [0, 5, 7];
        if (q is "6") return [0, 4, 7, 9];
        if (q is "m6") return [0, 3, 7, 9];
        if (q is "9") return [0, 4, 7, 10, 2];
        if (q is "maj9") return [0, 4, 7, 11, 2];
        if (q is "m9") return [0, 3, 7, 10, 2];
        return [0, 4, 7];
    }
```

Le programme demande « ICV neighbors of » suivi de 27 accords, et compare l'ensemble que construit le skill aux notes de l'accord :

```text
== The chords the skill reads, after "ICV neighbors of", at the pin
chord      its notes          read as          notes built        right
C          C E G              C                C E G              yes
Cm         C D# G             Cm               C D# G             yes
Cmaj7      C E G B            Cmaj7            C E G B            yes
CM7        C E G B            CM7              C D# G A#          no
Cmin7      C D# G A#          Cmin7            C D# G A#          yes
Cdom7      C E G A#           Cdom7            C E G              no
Cm7b5      C D# F# A#         Cm7b5            C D# F# A#         yes
Cø7        C D# F# A#         declined         -                  no
Cdim       C D# F#            Cdim             C D# F#            yes
C°         C D# F#            C                C E G              no
Cdim7      C D# F# A          Cdim7            C D# F# A          yes
C°7        C D# F# A          C°               C D# F#            no
Caug       C E G#             Caug             C E G#             yes
C+         C E G#             C                C E G              no
Cadd9      C D E G            Cadd9            C E G              no
C7sus4     C F G A#           declined         -                  no
C7b9       C C# E G A#        C7b9             C E G              no
C7#9       C D# E G A#        C7#9             C E G              no
Cm11       C D D# F G A#      Cm11             C E G              no
C13        C D E G A A#       C13              C E G              no
CmMaj7     C D# G B           declined         -                  no
C5         C G                C5               C E G              no
F#m7b5     C E F# A           F#m7b5           C E F# A           yes
B♭7        D F G# A#          B♭7              D F G# A#          yes
C minor    C D# G             C                C E G              no
A minor    C E A              A                C# E A             no
a Cmaj7    C E G B            a                C# E A             no
chords 27: built right 10
```

- **« CM7 », une septième majeure, est construit comme une septième mineure sur C.** Le suffixe est mis en minuscules avant la lecture de la table : le `"M7"` de la ligne 221 ne peut donc jamais correspondre, et « m7 », si.
- **Un suffixe inconnu donne une triade majeure, sans avertissement.** Cdom7, Cadd9, C7b9, C7#9, Cm11, C13 et C5 reçoivent tous la réponse de C E G ; « C minor » et « A minor » sont lus comme C et A, puisque l'accord s'arrête à l'espace.
- **° et + terminent l'accord.** Ce ne sont pas des lettres : la limite de mot tombe donc avant eux. C° et C+ deviennent C, et C°7 la triade C°, puisqu'une limite tombe aussi entre ° et 7. ø est une lettre : Cø7 n'a donc pas de limite après son C et est décliné, comme C7sus4 et CmMaj7, dont les suffixes manquent à l'expression.
- **« a » est un accord.** L'expression ignore la casse : l'article de « close to a half-diminished chord », la formulation du brouillon en attente, est donc lu comme A majeur, tout comme celui de « ICV neighbors of a Cmaj7 ».

## Les voisins

Le skill demande à `FindNearby` tous les ensembles situés à 3 au plus, recalcule lui-même chaque distance, et garde les huit premiers à une distance de 1 ou 2 ([lignes 120-140](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L120-L140)) :

```csharp
        var sourceIcv = source.IntervalClassVector;
        var rawNeighbors = grothendieck.FindNearby(source, DefaultMaxDistance + 1).ToList();

        var neighbors = rawNeighbors
            .Select(n => (n.Set, Delta: ComputeTrueDelta(sourceIcv, n.Set.IntervalClassVector)))
            .Where(t => !ReferenceEquals(t.Set, source))           // skip the source itself
            .Where(t => t.Delta.l1 > 0)                            // skip exact ICV-identical (same set class)
            .Where(t => t.Delta.l1 <= DefaultMaxDistance)
            .OrderBy(t => t.Delta.l1)
            .Take(MaxNeighborsToShow)
            .ToList();
```

`FindNearby` parcourt `PitchClassSet.Items` dans l'ordre de leurs identifiants, qui sont leurs masques de bits, et trie ce qu'il garde selon un coût, la distance multipliée par 0.6, en conservant cet ordre entre coûts égaux ([`GrothendieckService.cs` lignes 38-90](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs#L38-L90)). Pour chacune des 16 qualités du skill sur C, le programme compte les ensembles à une distance de 1 ou 2, et compare les huit lignes aux huit premiers d'entre eux par identifiant :

```text
== The neighbors the skill lists for a chord, at the pin
chord   its vector      sets 1-2 off  set classes  of notes  rows   of notes  L1, cost   set classes   with a C   the first by id
C       <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cm      <0 0 1 1 1 0>   108           6            2, 3      8      2, 3      2, 1.20    5             6          yes
Cdim    <0 0 2 0 0 1>   18            2            2         8      2         2, 1.20    2             2          yes
Caug    <0 0 0 3 0 0>   12            1            2         8      2         2, 1.20    1             2          yes
C7      <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cm7     <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cmaj7   <1 0 1 2 2 0>   72            4            4         8      4         2, 1.20    4             6          yes
Cm7b5   <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
Cdim7   <0 0 4 0 0 2>   0             0                      0      -         -          0             0          -
Csus2   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
Csus4   <0 1 0 0 2 0>   48            3            2, 3      8      2, 3      2, 1.20    3             4          yes
C6      <0 1 2 1 2 0>   72            3            4         8      4         2, 1.20    3             6          yes
Cm6     <0 1 2 1 1 1>   132           6            4         8      4         2, 1.20    5             8          yes
C9      <0 3 2 2 2 1>   24            1            5         8      5         2, 1.20    1             4          yes
Cmaj9   <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
Cm9     <1 2 2 2 3 0>   72            3            5         8      5         2, 1.20    3             5          yes
the rows for C:
  {0,3}     C D#       2-3    <0 0 1 0 0 0>
  {0,4}     C E        2-4    <0 0 0 1 0 0>
  {1,4}     C# E       2-3    <0 0 1 0 0 0>
  {0,1,4}   C C# E     3-3    <1 0 1 1 0 0>
  {0,3,4}   C D# E     3-3    <1 0 1 1 0 0>
  {0,5}     C F        2-5    <0 0 0 0 1 0>
  {1,5}     C# F       2-4    <0 0 0 1 0 0>
  {0,1,5}   C C# F     3-4    <1 0 0 1 1 0>
Cdim7: No pitch-class sets within L1 = 2. Try a wider radius.
chords 192: qualities whose 12 roots get the same rows 16 of 16; different answers 10, different vectors 10
```

- **Chaque ligne est à une distance de 2, au coût de 1.20.** Entre deux ensembles de même taille, la distance est paire, et un ensemble d'une autre taille est à 3 au moins d'un accord de trois notes ou plus, sauf un ensemble de deux notes par rapport à une triade. « Sorted by harmonic cost » ne trie rien, et les huit lignes sont les huit premiers ensembles par masque de bits, ce qui avantage les classes de hauteurs les plus basses : six des huit lignes de C contiennent un C, et aucune ne dépasse F.
- **Les lignes ne dépendent que du vecteur de l'accord.** Les 192 accords formés de 12 fondamentales et de 16 qualités reçoivent 10 réponses différentes, une par vecteur : C et F#m reçoivent les mêmes huit lignes.
- **Les voisins d'une triade sont surtout des intervalles.** Cinq des huit lignes de C sont des ensembles de deux notes, et les trois autres contiennent chacune un demi-ton, ce que C majeur n'a pas. Les lignes de Cdim et de Caug ne sont que des ensembles de deux notes.
- **Cdim7 ne reçoit aucun voisin, et le conseil « Try a wider radius »,** alors que le rayon est une constante, `DefaultMaxDistance` ([ligne 76](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L76)), que l'utilisateur ne peut pas changer.

Le cours de théorie musicale a constaté qu'au commit épinglé, `ga_icv_neighbors`, l'outil MCP qui repose sur le même service, affichait pour C douze lignes de la classe d'ensembles de C elle-même ; sur `main`, il liste chaque classe d'ensembles une seule fois, à sa vraie distance ([`ChordAtonalTool.cs` lignes 337-348 sur `main`](https://github.com/GuitarAlchemist/ga/blob/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a/GaMcpServer/Tools/ChordAtonalTool.cs#L337-L348)). Le skill a calculé les vraies distances dès le départ ([lignes 122-129](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L122-L129)), et liste encore plusieurs transpositions d'une même classe d'ensembles : les huit lignes de C contiennent cinq classes d'ensembles.

## Le brouillon de skill en attente

`skills-dev/_pending-tools/icv-neighbors/DRAFT.md` est un skill du chatbot écrit pour appeler `ga_icv_neighbors`, en attente comme ceux des leçons 19 à 21 ([`skills-dev/_pending-tools/README.md` ligne 52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L52)) :

- il dit l'outil « not yet implemented in Common/GA.Business.ML/Agents/Mcp/ » et renvoie à `Common/GA.Business.ML/Agents/Mcp/AtonalMcpTools.cs` (lignes [18](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L18) et [72](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L72)), un fichier que GA n'a pas ; l'outil se trouve dans `GaMcpServer/Tools/ChordAtonalTool.cs` ([lignes 220-254](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L220-L254)) ;
- il attend `chord`, `topK` et `metric`, avec des distances euclidienne, de Manhattan ou cosinus, et une réponse faite de `Neighbours` ([lignes 31-41](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L31-L41)) ; l'outil prend `symbol` et `maxDistance` et renvoie des lignes de texte ;
- son exemple donne le vecteur de Cmaj7 et trois voisins, chacun avec une distance ([lignes 53-58](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/icv-neighbors/DRAFT.md#L53-L58)) :

```text
== The parked draft's example for Cmaj7, at the pin
chord                  notes          vector           Forte  L1     the draft
Cmaj7                  C E G B        <1 0 1 2 2 0>    4-20   0      [1, 0, 1, 2, 2, 0], 4-20
Am7                    A C E G        <0 1 2 1 2 0>    4-26   4      [1,0,1,2,2,0], distance 0.0, same set class
Cm9 without its root   D# G A# D      <1 0 1 2 2 0>    4-20   0      distance 0.6
Fmaj7                  F A C E        <1 0 1 2 2 0>    4-20   0      distance 0.0, same set class
```

Am7 n'appartient pas à la classe d'ensembles de Cmaj7 : c'est A C E G, les notes de C6, 4-26, à une distance de 4. Cm9 sans sa fondamentale est une septième majeure sur E♭, de la classe de Cmaj7, à une distance de 0 et non de 0.6. Des trois formulations du brouillon, le skill en décline deux et lit A majeur dans la troisième.

## Où le cours s'arrête

- **Le routeur n'est pas exécuté :** il a besoin des embeddings. La leçon pose au skill les questions que le routeur a le plus de chances de lui envoyer, ses propres prompts d'exemple.
- **Les notes des accords sont celles du cours,** celles d'un manuel pour chaque chiffrage.
- **`ga_icv_neighbors` n'est pas exécuté ici ;** le cours de théorie musicale l'exécute.
- **Le programme appelle directement les méthodes des skills,** et non par le chatbot.

## Signalé en amont

- Signalés après l'écriture de cette leçon, dans le ticket de GA [#798](https://github.com/GuitarAlchemist/ga/issues/798) : les prompts d'exemple que les expressions ne lisent pas, les accords que la table construit mal, les voisins listés par masque de bits, et le brouillon de skill en attente.

## Exercices

1. « which chords are most similar to Dm7 » est l'un des prompts d'exemple du skill. Pourquoi le skill le décline-t-il ?
2. Les lignes de C comprennent `{0,4}`, C et E. Quelle est la distance entre le vecteur de C, `<0 0 1 1 1 0>`, et celui de cet ensemble, `<0 0 0 1 0 0>` ? Pourquoi un voisin de Cmaj7 ne peut-il pas avoir trois notes ?
3. Pourquoi C et F#m reçoivent-ils les mêmes huit lignes ?
4. « ICV neighbors of CM7 » répond pour une septième mineure sur C. Quelle ligne change M7 en m7 ?

<details>
<summary>Solutions</summary>

1. Ses expressions exigent « neighbors », « nearby », « close to », « near » ou « adjacent » juste avant l'accord, « neighbors » après lui, ou « harmonically close », « near » ou « adjacent » d'un côté ou de l'autre ([lignes 82-89](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs#L82-L89)) ; le prompt n'en contient aucun : `ExecuteAsync` donne donc le refus.
2. 1 + 1 = 2 : le vecteur de C compte une tierce mineure, E–G, et une quinte, C–G, qui manquent à C–E. Un vecteur compte les intervalles entre chaque paire de notes : 6 pour quatre notes, 3 pour trois ; un ensemble de trois notes est donc à 3 au moins de Cmaj7, plus que les 2 du skill.
3. Ce sont deux triades de la même classe d'ensembles, avec le vecteur `<0 0 1 1 1 0>`. `FindNearby` compare des vecteurs, pas des notes, et renvoie les ensembles par masque de bits : les huit premiers à une distance de 2 sont donc les mêmes.
4. La ligne 214, `quality.ToLowerInvariant()` : « M7 » devient « m7 », que la ligne 220 lit comme une septième mineure.

</details>

## À retenir

- Les ancres de routage et l'analyseur qui vient après elles forment un seul contrat : retoucher l'un sans l'autre envoie des questions vers un refus.
- Les prompts d'exemple d'un skill en sont le premier test.
- Une table qui se rabat sur une triade majeure répond à des questions qu'elle ne sait pas lire.
- « Sorted by cost » ne veut pas dire grand-chose quand tous les coûts sont à égalité : l'ordre est alors celui de l'énumération.
- Des voisins dans l'espace des vecteurs dépendent du vecteur, pas de l'accord : tous les accords d'une classe d'ensembles reçoivent la même liste.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/IcvNeighborsSkill.cs`, `Common/GA.Business.ML/Agents/Skills/IntervalClassVectorSkill.cs`, `Common/GA.Business.ML/Agents/Intents/DefaultRoutingHintProvider.cs`, `Common/GA.Business.ML/Agents/Intents/SemanticIntentRouter.cs`, `Common/GA.Domain.Services/Atonal/Grothendieck/GrothendieckService.cs`, `Common/GA.Business.Core.Orchestration/Plugins/GaPlugin.cs`, `GaMcpServer/Tools/ChordAtonalTool.cs`, `skills-dev/_pending-tools/icv-neighbors/DRAFT.md`, `CLAUDE.md`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : les mêmes skills, avec leurs refus marqués `Declined`, et `ChordAtonalTool.cs`.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson22.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/IcvNeighborsProbe.cs`.
