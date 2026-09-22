---
title: "Annexe C : toutes les divergences, et à qui revient le bug"
description: Les quarante lignes DIFF des leçons 1 à 7, chacune avec un verdict — bug de Guitar Alchemist ou erreur du cours — la ligne de GA qui la cause, et les dix-neuf défauts distincts auxquels elles se ramènent.
sidebar:
  label: "Annexe C : toutes les divergences"
  order: 92
---

Chaque leçon de ce cours imprime un tableau à trois colonnes : ce que le cours calcule à partir de la définition du manuel, ce que Guitar Alchemist répond à la même question, et `ok` ou `DIFF`. Les leçons 1 à 7 produisent **40 lignes `DIFF`**. Un lecteur a le droit de poser la question évidente sur chacune : *est-ce un bug de GA, ou est-ce le cours qui a tort ?*

Cette annexe y répond, ligne par ligne. La version courte :

| | lignes |
|---|---|
| Bug de GA, le cours suit la théorie | 39 |
| Ni l'un ni l'autre : une convention défendable (avec un vrai défaut en dessous) | 1 |
| Erreur du cours | 0 |

Quarante lignes, mais pas quarante problèmes : elles se ramènent à **19 défauts distincts**, parce qu'une seule ligne fausse peut gâcher huit lignes. Le regroupement ci-dessous est la vue utile ; les tableaux par leçon qui suivent en sont le détail.

:::note[Comment vérifier soi-même n'importe quelle ligne]
Rien ici n'est un avis sur le style du code. Chaque ligne est une valeur calculée deux fois et comparée par un programme, sur trois systèmes d'exploitation, à un commit épinglé de GA. Clone ce dépôt et lance `bash code/music-theory-ga/check.sh`, ou exécute une leçon avec `dotnet run --project code/music-theory-ga/GaTheory -c Release -- l3`. GA est lu au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) et jamais modifié. La colonne **Statut amont** est une seconde lecture, distincte : elle dit ce que contenait le `main` de GA le 22 septembre 2026, au commit [`05528dc`](https://github.com/GuitarAlchemist/ga/tree/05528dc12af4fd014cc1b135ad4ef5c9e108290a), les seize corrections ayant été vérifiées une à une dans cette source. Les liens du tableau pointent toujours vers `a826864`, où le défaut est visible.
:::

:::tip[Rapprochement avec l’amont]
Le snapshot d’origine `a826864` reste la référence reproductible des 40 lignes `DIFF`. Les constats exécutables ont été rapprochés dans [GA #711](https://github.com/GuitarAlchemist/ga/pull/711), fusionnée sous [`b363c3f`](https://github.com/GuitarAlchemist/ga/commit/b363c3f086608f850be026546f85ef13c6e6bfb8) le 21 septembre 2026. Les défauts 1 à 5, 7 à 11 et 13 à 18 sont corrigés et couverts par des tests de régression. Les entrées 6, 12 et 19 restent des limites explicites de conception ou de représentation, plutôt que des corrections silencieuses.
:::

## Les 19 défauts

| # | Défaut dans GA | Lignes | Leçons | Statut amont |
|---|---|---|---|---|
| 1 | [`Pitch.Flat.DFlat/FFlat/GFlat(Octave)`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295) construisent la mauvaise note : chacune renvoie la note de la ligne du dessous | 3 | 1 | **Corrigé** (fabriques corrigées ; `EFlat`/`BFlat` ajoutés) |
| 2 | [`PitchParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs#L20-L25) a une regex sans ancres et insensible à la casse, si bien que `Eb2` correspond à `b2` = B2 | 1 | 1 | **Corrigé** (regexes ancrées précompilées statiques) |
| 3 | [`Note.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L219-L237) met en majuscules avant de remplacer `♭`, si bien que `B` devient B♭ et que `D♭` est rejeté | 1 | 1 | **Corrigé** (`B` naturel analysé en B ; Unicode `♭` géré) |
| 4 | [`PitchClass.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClass.cs#L252-L268) essaie les alias pseudo-hexadécimaux `A`=10, `B`=11 avant les noms de notes | 1 | 1 | **Corrigé** (`TryParseSetNotation` séparé de `TryParse`) |
| 5 | [`SimpleIntervalSize.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Intervals/SimpleIntervalSize.cs#L155-L164) et `CompoundIntervalSize.TryParse` lèvent une exception au lieu de renvoyer `false` | 1 | 1 | **Corrigé** (renvoie `false` sur entrée invalide) |
| 6 | [`ModalFamily`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/ModalFamily.cs#L114-L128) regroupe les ensembles par vecteur de classes d'intervalles mais appelle les membres `Modes` | 2 | 2 | Conception connue (regroupement par ICV) |
| 7 | [`ChordFormula.DetermineQuality`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L172-L214) ne renvoie jamais `Major7`, `Minor7`, `HalfDiminished` ni `Diminished7` | 2 | 3 | **Corrigé** (qualités et suffixes de `ChordFormula`) |
| 8 | [`DetermineExtension`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/ChordFormula.cs#L216-L294) lit neuf demi-tons comme une sixte majeure, jamais comme une septième diminuée | 1 | 3 | **Corrigé** (septième diminuée distinguée de sixte/13e) |
| 9 | [`Note.Chromatic.ToAccidented`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Note.cs#L75-L77) est `ToSharp().ToAccidented()` : chaque touche noire reçoit un nom avec dièse | 8 | 3 | **Corrigé** (transposition d'intervalles respectueuse de l'orthographe dans `Chord`) |
| 10 | [`Chord`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Harmony/Chord.cs#L241-L250) fait tourner sa liste de notes pour un renversement, puis réanalyse depuis la basse comme si elle était la fondamentale | 1 | 3 | **Corrigé** (`Root` et `Formula` d'origine préservés) |
| 11 | [`Voicing.HasBarre`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Instruments/Fretboard/Voicings/Core/Voicing.cs#L73-L80) compte la case 0, si bien que des cordes à vide font un barré | 3 | 3 | **Corrigé** (filtre `fret > 0` dans `Voicing.HasBarre()`) |
| 12 | [`IntervalClassVectorId`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/IntervalClassVectorId.cs#L39-L85) range six comptes en chiffres base 12, et un compte de 12 déborde de son chiffre | 1 | 4 | Limite figée (préserve l'ordre du catalogue) |
| 13 | [`KeyTools.GetParallelKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L161-L166) a le même corps que `GetRelativeKey` : elle garde l'armure au lieu de la tonique | 5 | 5 | **Corrigé** (conserve la tonique avec mode inverse) |
| 14 | [`KeyTools.GetNeighboringKeys`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L204) cherche une tonalité par ses altérations au lieu de son nom, et lève une exception | 1 | 5 | **Corrigé** (position dans le cercle des quintes par compte d'armure) |
| 15 | [`Key.GetInterval`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L76) passe ses arguments dans le mauvais sens et renvoie l'intervalle renversé | 2 | 5 | **Corrigé** (ordre tonique-vers-note rétabli) |
| 16 | [`Key.Major.TryParse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L155-L158) lève une exception sur une fondamentale illisible alors qu'elle a un chemin `return false` | 1 | 5 | **Corrigé** (renvoie `false` sur fondamentale illisible) |
| 17 | [`HarmonicFunction.FromDegree`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/HarmonicFunction.cs#L32) ne voit qu'un numéro de degré, et son énumération n'a pas de `Subtonic` | 1 | 6 | **Corrigé** (`Subtonic` ajouté avec test des demi-tons sous la tonique) |
| 18 | [`Cadences.yaml`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/Cadences.yaml#L124-L129) numérote une ligne en mineur depuis la majeure homonyme (`♭iii` pour G en E mineur) | 1 | 7 | **Corrigé** (corrigé en `iii` dans Cadences.yaml) |
| 19 | [`PitchClassSet.ClosestDiatonicKey`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L609-L615) départage majeur/mineur sur une forme normale, qui ne peut pas coder un mode | 4 | 7 | Heuristique connue (ambiguïté intrinsèque de tonique du PC-set) |

Trois schémas en expliquent la plupart.

- **Le copier-coller à l'intérieur d'un bloc de membres presque identiques** : défauts 1 et 13. Trois méthodes de fabrique qui renvoient chacune la note de la ligne suivante, et un `GetParallelKey` dont le corps n'a jamais été modifié après avoir été copié depuis `GetRelativeKey`.
- **Une classe de hauteurs à qui l'on demande de se souvenir d'une lettre** : défauts 8, 9 et 12, et le cœur du 19. Une classe de hauteurs, un identifiant d'ensemble et un compte d'intervalles sont tous des *réductions* : ils jettent délibérément l'orthographe, l'octave ou la tonique. Chaque ligne de ce groupe est cette information jetée qu'on redemande plus loin.
- **Un `TryParse` qui lève une exception** : défauts 5 et 16, dans trois types. Le contrat [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse) dit qu'une analyse ratée renvoie `false`.

## Leçon 1 : notes, classes de hauteurs et manche

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| `Pitch.Flat.DFlat(4)` → `Db4` | `D4` | GA, défaut 1 | La méthode construit `Note.Flat.D`, la naturelle, alors que `Note.Flat.DFlat` existe. |
| `Pitch.Flat.FFlat(4)` → `Fb4` | `G4` | GA, défaut 1 | Elle construit `Note.Flat.G`. F♭ est l'enharmonique de E et ne peut jamais être G. |
| `Pitch.Flat.GFlat(4)` → `Gb4` | `A4` | GA, défaut 1 | Elle construit `Note.Flat.A`, encore la note de la ligne suivante. |
| `Pitch.Sharp.TryParse("Eb2")` → rejeté | `B2` | GA, défaut 2 | `([A-G])(#?)(10\|11\|[0-9])` est sans ancres et insensible à la casse, donc la correspondance glisse au-delà du `E` et lit `b2`. |
| `Note.Flat.Parse("B")` → `B` | `Bb` | GA, défaut 3 | `ToUpperInvariant()` s'exécute avant `Replace("♭", "b")`, donc le test du `B` final se déclenche à la fois trop et pas assez. |
| `PitchClass.Parse("A")` → `9` | `10` | **Ni l'un ni l'autre** | Lire `A` comme le chiffre 10 est une convention documentée de la théorie des ensembles, donc 10 n'est pas faux. Mais les alias sont essayés avant les noms de notes, si bien que la note A ne peut jamais être analysée comme 9 — cette partie-là est un défaut. |
| `IntervalSize.TryParse("x")` → `False` | lève `ArgumentException` | GA, défaut 5 | `SimpleIntervalSize` et `CompoundIntervalSize` lèvent tous deux une exception là où le contrat exige `false`. |

Un constat supplémentaire qui n'apparaît dans aucune ligne : le bloc de fabriques `Flat(Octave)` n'a **ni `EFlat(Octave)` ni `BFlat(Octave)` du tout**, alors que les propriétés par octave `EFlat0`, `BFlat0` et leurs voisines existent. Seule cette famille de surcharges n'est pas fiable.

## Leçon 2 : gammes et modes

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| la mineure harmonique a 7 modes | 14 | GA, défaut 6 | Un mode est une rotation, donc une gamme de sept notes en a sept. Les 14 de GA sont les 7 rotations de la mineure harmonique plus les 7 de son image miroir, la majeure harmonique, qui a le même vecteur de classes d'intervalles. |
| la gamme blues a 6 modes | 24 | GA, défaut 6 | 6 rotations, 6 du miroir, et 12 ensembles d'une classe d'ensembles en relation Z qui partage le vecteur. |

Le commentaire de classe de GA décrit ce qu'il construit réellement — des ensembles "that share the same interval vector" — donc le calcul est juste et c'est le *nom* qui est faux. [Ian Ring](https://ianring.com/musictheory/scales/2477) répond 7 et 6.

## Leçon 3 : accords, chiffrages, renversements et voicings

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| `Cmaj7` → `maj7` | `7` | GA, défaut 7 | Major plus septième, et `Major` n'apporte aucun préfixe, donc il imprime le chiffrage de la septième de dominante. |
| `Cm7b5` → `m7b5` | `dim7` | GA, défaut 7 | L'accord demi-diminué s'imprime avec le chiffrage de l'accord entièrement diminué. |
| `Cdim7` → `dim7` | `dim6` | GA, défaut 8 | Neuf demi-tons sont lus comme une sixte majeure ; seule l'orthographe B𝄫 dit le contraire, et une formule en demi-tons n'en a pas. |
| `Cm` → `C Eb G` | `C D# G` | GA, défaut 9 | |
| `Eb` → `Eb G Bb` | `Eb G A#` | GA, défaut 9 | D'après ses lettres, E♭–A♯ est une quarte, pas la quinte de l'accord. |
| `Ab` → `Ab C Eb` | `Ab C D#` | GA, défaut 9 | |
| `Bbm7` → `Bb Db F Ab` | `Bb C# F G#` | GA, défaut 9 | Deux degrés sur quatre tombent sur la mauvaise lettre. |
| `Cdim` → `C Eb Gb` | `C D# F#` | GA, défaut 9 | F♯ nomme une quarte augmentée, pas une quinte diminuée. |
| `Cdim7` → `C Eb Gb Bbb` | `C D# F# A` | GA, défaut 9 | Le double bémol est l'orthographe du manuel ; A est une sixte. |
| `Gb7` → `Gb Bb Db Fb` | `Gb A# C# E` | GA, défaut 9 | |
| exercice : `F#dim7` → `F# A C Eb` | `F# A C D#` | GA, défaut 9 | Les lettres d'un accord de septième diminuée sont F A C E. |
| `C/E` → renversement 1, Major | renversement 1, Other | GA, défaut 10 | Après la rotation, la basse se retrouve dans `Notes[0]`, donc la réanalyse saute la tierce et n'en trouve aucune. |
| `032010` n'est pas un barré | barré | GA, défaut 11 | |
| `022100` n'est pas un barré | barré | GA, défaut 11 | |
| `320003` n'est pas un barré | barré | GA, défaut 11 | Trois cordes à vide partagent la « case 0 » ; aucun doigt n'appuie une corde à vide. |

Deux d'entre eux ont une implémentation correcte ailleurs dans le même commit : [`CadenceChordParser`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Chords/Parsing/CadenceChordParser.cs#L11-L14) and the F# [`DslCommand`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Types/DslCommand.fs#L227-L230) F# connaissent les bons chiffrages, et [`DetectBarreRequirement`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Fretboard/Voicings/Analysis/VoicingPhysicalAnalyzer.cs#L219-L233) teste bien `fret > 0` et exige bien des cordes voisines.

## Leçon 4 : classes d'ensembles

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| vecteur ICV de l'agrégat chromatique → `<12 12 12 12 12 6>` | `<1 1 1 1 0 6>` | GA, défaut 12 | Les comptes sont calculés correctement, puis rangés en chiffres base 12 où 12 ne tient pas. |

GA documente celui-ci lui-même, comme une "KNOWN LIMITATION" dans le commentaire du type, avec la base 13 ou un record à six champs indiqués comme correctif. C'est le seul ensemble touché : un ensemble de 11 notes plafonne à 10 par classe d'intervalles.

## Leçon 5 : tonalités et cercle des quintes

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| homonyme de C → C mineur | A mineur | GA, défaut 13 | La tonalité homonyme partage la *tonique* ; GA garde l'*armure*, ce qui donne la relative. |
| homonyme de A♭ → A♭ mineur | F mineur | GA, défaut 13 | |
| homonyme de A mineur → A majeur | C majeur | GA, défaut 13 | |
| homonyme de E mineur → E majeur | G majeur | GA, défaut 13 | |
| exercice : homonyme de A♭ → A♭ mineur, 7 bémols | F mineur | GA, défaut 13 | L'exercice réexécute la même expression. |
| voisines de C → F, G | lève `InvalidOperationException` | GA, défaut 14 | L'outil recherche la tonalité par `""` (les altérations de C majeur) au lieu de `"Key of C"`. |
| `Key.Major.C.GetInterval(E)` → M3 | m6 | GA, défaut 15 | |
| `Key.Major.G.GetInterval(F#)` → M7 | m2 | GA, défaut 15 | Les deux renvoient le renversement de l'intervalle documenté. |
| `Key.Major.TryParse("H")` → `False` | lève une exception | GA, défaut 16 | La méthode a un chemin `return false` quelques lignes plus bas. |

Le cœur de GA n'a aucun membre pour la tonalité relative ni pour l'homonyme, donc l'outil MCP est le seul code qui répond à ces deux questions. Son commentaire, à l'intérieur de la méthode *correcte*, intervertit déjà les deux mots : la confusion est dans le vocabulaire, pas seulement dans un corps de méthode.

## Leçon 6 : les accords d'une tonalité

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| VII de A mineur naturel → G majeur, **Subtonic** | **LeadingTone** | GA, défaut 17 | Le septième degré de la mineure naturelle est un ton entier sous la tonique, c'est donc la sous-tonique ; une sensible est un demi-ton en dessous. |

## Leçon 7 : cadences et progressions

| Ligne | Réponse de GA | Verdict | Pourquoi |
|---|---|---|---|
| Chromatic Mediant (Metal), Em–Gm en E mineur → `i iii` | `i biii` | GA, défaut 18 | G est le troisième degré non altéré de E mineur. Lu en E mineur, ♭iii désigne G♭, que l'accord ne contient pas. L'analyseur F# de GA lui-même utilise les chiffres de la gamme mineure. |
| tonalité de `C F G C` → C majeur | A mineur | GA, défaut 19 | |
| tonalité de `G D Em C` → G majeur | E mineur | GA, défaut 19 | |
| tonalité de `Dm7 G7 Cmaj7` → C majeur | A mineur | GA, défaut 19 | |
| tonalité de `C Am F G7` → C majeur | A mineur | GA, défaut 19 | Toute collection diatonique de sept notes a la forme normale `0 1 3 5 6 8 T`, qui contient 3, donc le drapeau de mode est toujours levé et la réponse est toujours la relative mineure. |

Les quatre dernières méritent d'être séparées du reste de cette annexe, parce que le correctif n'est pas une ligne : un ensemble de classes de hauteurs **n'a pas de tonique**. `C F G C` et `Am F C G` sont le même ensemble. Aucune fonction de l'ensemble seul ne peut nommer l'une des deux tonalités relatives ; la nommer demande l'ordre des accords, que `ClosestDiatonicKey` ne reçoit jamais. Renvoyer une armure, ou la paire — ce que `GetCompatibleKeys` fait déjà — est la réponse honnête pour cette entrée.

## Ce que cette annexe n'est pas

Ce n'est pas un rapport de bug déposé contre GA, et rien ici n'a été publié hors de ce dépôt. C'est le compte rendu de ce qu'un lecteur doit conclure quand une leçon imprime `DIFF` : dans ce cours, jusqu'ici, cela a voulu dire GA, à une exception près.

Ce n'est pas non plus prétendre que le cours fait autorité. Les calculs du cours sont de simples implémentations des définitions du manuel, et sa règle du barré, son heuristique de tonalité et sa table de chiffrages d'accords sont toutes des approximations qu'il déclare comme telles là où elles apparaissent. Là où le cours et GA concordent, les deux pourraient encore se tromper ; ces lignes impriment `ok` et cette annexe n'en dit rien.

## Sources

- Mark Gotham et al., [*Open Music Theory*](https://viva.pressbooks.pub/openmusictheory/) v2 : ["Triads"](https://viva.pressbooks.pub/openmusictheory/chapter/triads/), ["Seventh Chords"](https://viva.pressbooks.pub/openmusictheory/chapter/seventh-chords/), ["Mediants"](https://viva.pressbooks.pub/openmusictheory/chapter/mediants/), ["Roman Numerals"](https://viva.pressbooks.pub/openmusictheory/chapter/roman-numerals/), "Minor Scales, Scale Degrees, and Key Signatures".
- Ian Ring, [*A Study of Musical Scales*](https://ianring.com/musictheory/scales/) : [la mineure harmonique](https://ianring.com/musictheory/scales/2477), [la gamme blues](https://ianring.com/musictheory/scales/1257), [la gamme chromatique](https://ianring.com/musictheory/scales/4095).
- Wikipédia : [Interval vector](https://en.wikipedia.org/wiki/Interval_vector), [Barre chord](https://en.wikipedia.org/wiki/Barre_chord), [Cadence](https://en.wikipedia.org/wiki/Cadence).
- [`IParsable<TSelf>.TryParse`](https://learn.microsoft.com/dotnet/api/system.iparsable-1.tryparse).
- [GuitarAlchemist/ga](https://github.com/GuitarAlchemist/ga) au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6).
