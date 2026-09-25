---
title: Journal
description: Notes de progression datées — épinglage et compilation de GA, exécutions de CI, différences entre la théorie, le code de GA et les outils MCP de GA, et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Programme du cours : .NET 10, compilé contre le `GA.Domain.Core` de GA à un commit épinglé
- [x] CI : la sortie de chaque leçon comparée avec son fichier attendu sur trois OS
- [x] Leçon 1 : notes, classes de hauteurs et manche
- [x] Leçon 2 : gammes, modes et identifiants de gamme sur 12 bits
- [x] Leçon 3 : accords, chiffrages, renversements et voicings
- [x] Leçon 4 : classes d'ensembles, vecteurs d'intervalles et relation Z
- [x] Diagrammes : bracelets, grilles d'accords, manche et cercles des quintes dessinés par le programme du cours, vérifiés par la CI
- [x] Leçon 5 : tonalités, armures et cercle des quintes
- [x] Leçon 6 : les accords d'une tonalité
- [x] Leçon 7 : cadences, ii–V–I et tonalité d'une progression
- [x] Leçon 8 : le ukulélé et la basse
- [x] Annexe A : tous les instruments du catalogue de GA
- [x] Annexe B : la hiérarchie OPTIC
- [x] Annexe C : un verdict sur chaque ligne `DIFF` des leçons 1 à 7
- [ ] Leçons 9 à 17 (voir le plan sur la page de mission)

## QA

Les quarante divergences entre l'arithmétique de ce cours et celle de Guitar Alchemist, les dix-neuf défauts auxquels elles se ramènent et le verdict de chacune sont dans l'[annexe C](/learn/fr/music-theory-ga/appendix-ga-findings/) ; seize ont été fusionnés en amont dans [GA #711](https://github.com/GuitarAlchemist/ga/pull/711), et trois restent des limites de conception documentées. Ce tableau porte sur ce que l'annexe ne couvre pas : les constats hors de la comparaison exécutable. La dernière ligne a été lue et non exécutée, et le dit.

| Attendu | Ce qui se passe | Où | Mesure | État |
|---|---|---|---|---|
| `getAllInstruments()` rend les instruments que contient le YAML | Il en rend un, et deux accordages, en retombant sans erreur ni ligne de journal sur des valeurs de guitare écrites en dur | `InstrumentsYaml`/`InstrumentsConfig`, `GA.Business.Config` à `a826864` | Le fichier contient 122 instruments et 280 accordages ; le chargeur en a rendu 1 et 2. Sept des 280 ne sont même pas des hauteurs : deux entrées de pedal steel commencent par le nom de leur accordage, une par le mot `Tuning`, une par le nom de l'instrument, une oublie l'octave | Reproduit, hors des dix-neuf défauts, non signalé [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |
| `Tuning.BuildPitchArray` numérote correctement les cordes de n'importe quel accordage | Il décide quel bout est la corde 1 en comparant seulement la première hauteur à la dernière : un accordage rentrant sort donc à l'envers | `Tuning.BuildPitchArray` à `a826864` | Les deux accordages de banjo 5 cordes de GA lui-même, dont la chanterelle est écrite en premier et sonne plus haut que la dernière, sont numérotés à l'envers — ce que contredit le commentaire de `Str`, qui dit que la corde 1 est la plus aiguë | Reproduit, hors des dix-neuf défauts, non signalé [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |
| Le paramètre documenté de `Fretboard.GetNote` correspond à son indexation | Le commentaire dit « Zero-based string index (0 = lowest string) » et le code indexe `Tuning[stringIndex + 1]`, où la corde 1 est la plus aiguë | `Fretboard.GetNote` à `a826864` | C'est le commentaire qui a tort, pas le code | Reproduit, documentation seulement [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |
| Le `ga_chord_to_set` du serveur MCP orthographie l'accord qu'on lui donne | Il tire ses classes de hauteurs d'une closure F# qui garde un intervalle par extension et laisse tomber les altérations : l'orthographe et le numéro de Forte sont donc faux | `DomainClosures.fs#L85-L98`, serveur MCP de GA | `Cm7b5` donne `{C, Eb, G, Bb}` et 4-26, là où 4-27 avec un sol♭ est juste ; `Cdim7` donne 4-27 et « Scale: Major Seventh », là où 4-28 est juste | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681), fusionnée le 2026-09-23. Relancé sur `27a1257` : `Cm7b5` donne `{C, Eb, F#, Bb}` et 4-27, `Cdim7` donne 4-28 [2026-09-14](#2026-09-14--le-serveur-mcp-de-ga), [2026-09-24](#2026-09-24--correctifs-amont-vérifiés-à-nouveau) |
| `ga_set_class_subs` range sous la bonne qualité les accords qu'il liste | Tous tombent sous `[maj]`, parce que le test est `c.EndsWith("")`, vrai de toute chaîne | `ChordAtonalTool.cs#L187-L190` | Les listes elles-mêmes sont justes ; seul le regroupement ne l'est pas | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681). Relancé sur `27a1257` : les accords parfaits majeurs sous `[maj]`, les mineurs sous `[m]` [2026-09-14](#2026-09-14--le-serveur-mcp-de-ga), [2026-09-24](#2026-09-24--correctifs-amont-vérifiés-à-nouveau) |
| `ga_scale_by_id` et `ga_scale_by_name` répondent pour une gamme que GA connaît | `ga_scale_by_id(2741)` rend Major avec `Forte Number: Some(n/a)` là où on attend 7-35, et `ga_scale_by_name("Dorian")` reste introuvable | serveur MCP de GA | Un champ faux, une recherche qui n'aboutit pas | Corrigé en amont par [#681](https://github.com/GuitarAlchemist/ga/pull/681). Relancé sur `27a1257` : `Forte Number: 7-35`, et Dorian trouvé sous l'identifiant 1709 [2026-09-14](#2026-09-14--le-serveur-mcp-de-ga), [2026-09-24](#2026-09-24--correctifs-amont-vérifiés-à-nouveau) |
| Tout outil MCP qui prend un accord ou une tonalité répond | Plusieurs renvoient la chaîne « An error occurred » plutôt qu'une erreur MCP | serveur MCP de GA | `get_chord_voicings("C", maxFret 3)`, `get_neighboring_keys` et `get_diatonic_chords("A minor")` répondent tous ainsi ; `ga_search_voicings("C major open chord")` a ignoré la contrainte « open » et rendu `8-8-x-x-7-x` | Reproduit ; le commit de build du serveur n'a jamais été confirmé, ces lignes ne sont donc pas épinglées à `a826864` [2026-09-14](#2026-09-14--le-serveur-mcp-de-ga). Sur `27a1257`, `get_neighboring_keys("Key of C")` répond F, C, G ; les trois autres ont besoin de GaApi et n'ont pas été relancés [2026-09-24](#2026-09-24--correctifs-amont-vérifiés-à-nouveau) |
| `ga_key_from_progression` et `ga_analyze_progression` trouvent la tonalité qu'établit une cadence | Ils comptaient les fondamentales des accords dans la gamme mineure naturelle et préféraient celle du premier accord : `Dm7 G7 Cmaj7` donnait D mineur, `Am Dm E7 Am` A majeur | [`GuitaristProblemTools.cs#L157-L223`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L157-L223), [`DomainClosures.fs#L255-L336`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L255-L336) | Sur `27a1257` : `Dm7 G7 Cmaj7` donne C majeur, ii V I ; `Am Dm E7 Am` donne A mineur, avec E7 noté `v` et compté hors de la tonalité ; `Am F C G` met toujours A mineur en tête, à égalité 4/4 avec C majeur, contre la description de l'outil lui-même | Corrigé en amont par [#625](https://github.com/GuitarAlchemist/ga/pull/625), fusionnée le 2026-09-24, pour les deux cadences ; le chiffrage et la description restent, non signalés [2026-09-15](#2026-09-15--le-serveur-mcp-de-ga-tonalités-et-progressions), [2026-09-24](#2026-09-24--correctifs-amont-vérifiés-à-nouveau) |
| `BraceletNotation.tsx` pose ses points sur ses propres rayons | Les points sont posés à `angle − 90°` tandis que les rayons utilisent `cos(angle)` sans décalage, soit un quart de tour d'écart ; `findSymmetryAxes` rate en outre les axes qui tombent entre deux notes et compte chaque axe deux fois | `ReactComponents/ga-react-components` de GA | Lu dans la source, jamais exécuté | **Non reproduit** : cette ligne est une lecture de code, et le journal la garde à vérifier dans un navigateur [2026-09-15](#2026-09-15--diagrammes) |

## Expériences

Trois questions dont la mesure pouvait tourner autrement. La première est le filet de sécurité du cours lui-même : sa théorie a été écrite depuis des définitions publiées, pas depuis GA, si bien que coïncider avec GA sur les 4096 ensembles renseigne sur les deux.

| Question | Hypothèse | Résultat | Verdict | Où |
|---|---|---|---|---|
| La forme première de Rahn réécrite de zéro par le cours coïncide-t-elle avec la forme première à identifiant minimal de GA, sur tout l'espace ? | Bâtie sur Open Music Theory, Wikipédia et l'OEIS, indépendamment de GA : l'accord n'avait rien de garanti | Elles coïncident pour chacun des 4096 ensembles. Les 224 classes d'ensembles et 352 classes de transposition de GA correspondent à OEIS A000029 et A000031. L'empaquetage de Forte diffère de celui de Rahn sur 6 classes d'ensembles et 17 des 352 classes de transposition | Confirmée, l'écart Forte/Rahn étant chiffré à part | [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |
| Gravir l'échelle OPTIC de GA une équivalence à la fois sur un vrai doigté retombe-t-il sur les comptes du manuel ? | Écrite à l'avance : on devrait atterrir sur 4096, 352 et 224 | 4096, 352 et 224 | Confirmée | [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |
| Donner un paramètre d'accordage à `Diagrams.Fretboard` change-t-il les diagrammes de guitare déjà produits ? | Écrite à l'avance : non — la guitare n'est qu'un accordage parmi les nouveaux | Les quatorze fichiers SVG existants sont identiques octet pour octet après le changement | Confirmée | [2026-09-15](#2026-09-15--un-verdict-sur-chaque-divergence-le-ukulélé-et-la-basse-trois-annexes) |

## 2026-09-21 — Rapprochement amont de l’annexe C

- [GA #711](https://github.com/GuitarAlchemist/ga/pull/711) a rapproché les constats exécutables de l’annexe C et a été fusionnée sous [`b363c3f`](https://github.com/GuitarAlchemist/ga/commit/b363c3f086608f850be026546f85ef13c6e6bfb8).
- Les défauts 1 à 5, 7 à 11 et 13 à 18 sont corrigés avec une couverture de régression. Les entrées 6, 12 et 19 restent des limites documentées de conception ou de représentation.
- Le cours reste épinglé sur `a826864` afin que les 40 lignes `DIFF` d’origine restent reproductibles ; l’annexe renvoie désormais au résultat amont plus récent sans réécrire cette preuve historique.

## 2026-09-18 — Corrections amont dans GA : résolution des anomalies

- **16 des 19 défauts résolus en amont dans GA** :
  - Notes et analyse de hauteurs : fabriques `Pitch.Flat` (`DFlat`, `FFlat`, `GFlat`, `EFlat`, `BFlat`) corrigées ; regexes ancrées et précompilées dans `PitchParser` ; `Note.Flat.TryParse` corrigé pour que le B naturel s'analyse en B (et non B♭) avec support Unicode `♭` ; séparation de `PitchClass.TryParseSetNotation` ; `SimpleIntervalSize.TryParse` et `CompoundIntervalSize.TryParse` renvoient `false` en cas d'erreur sans lever d'exception.
  - Accords et voicings : classification des qualités et suffixes de `ChordFormula` fiabilisée (séparation de dim7 des extensions 6e/13e, `m7b5` et `dim7` préservés) ; transposition respectueuse de l'orthographe dans le constructeur de `Chord` ; conservation de `Root` et `Formula` d'origine lors des renversements ; exclusion des cordes à vide (case 0) dans `Voicing.HasBarre()`.
  - Tonalités : `KeyTools.GetParallelKey` conserve la tonique avec le mode opposé ; `KeyTools.GetNeighboringKeys` recherche par compte d'armure ; `Key.GetInterval` rétablit l'ordre tonique-vers-note ; `Key.Major.TryParse` renvoie `false` sur entrée invalide ; ajout du membre `HarmonicFunction.Subtonic` ; correction du chiffre romain `iii` dans `Cadences.yaml` en mi mineur.
  - Le défaut 12 (compactage en base 12) reste une limitation figée pour conserver l'ordonnancement existant du catalogue ; les défauts 6 (`ModalFamily`) et 19 (`ClosestDiatonicKey`) demeurent documentés comme des compromis de conception / heuristiques.

## 2026-09-15 — Un verdict sur chaque divergence, le ukulélé et la basse, trois annexes

- **Les 40 lignes `DIFF` des leçons 1 à 7 ont maintenant toutes un verdict**, dans l'[annexe C](../appendix-ga-findings/) : 39 sont un bug de GA, une (`PitchClass.Parse("A")`) est une convention défendable avec un défaut de priorité en dessous, et aucune n'est une erreur du cours. Elles viennent de **19 défauts distincts** — une seule ligne fausse dans `Note.Chromatic.ToAccidented` explique à elle seule huit lignes — et se répartissent en trois familles : le copier-coller à l'intérieur d'un bloc de membres presque identiques, un type réduit à qui l'on demande l'information qu'il a été construit pour jeter, et un `TryParse` qui lève une exception.
- Neuf phrases, dans les leçons 1, 2, 3, 4, 6 et 7, présentaient une divergence comme une affaire de goût et donnent maintenant le verdict. La pire était le « Aucune des deux réponses n'est fausse » de la leçon 2 à propos de `ModalFamily` : un mode est une rotation, une gamme a autant de modes qu'elle a de notes, et les pages d'Ian Ring répondent 7 et 6 là où GA répond 14 et 24.
- **Leçon 8, le ukulélé et la basse.** Deux faits qu'un code taillé pour la guitare se trompe : un ukulélé est rentrant (sa quatrième corde est plus aiguë que sa troisième), et une basse est accordée entièrement en quartes (elle n'a pas l'unique paire irrégulière de la guitare). Les écarts d'un ukulélé sont 5 4 5, les mêmes que ceux des quatre cordes aiguës de la guitare ; un ukulélé baryton *est* ces quatre cordes ; une basse, ce sont les quatre graves, une octave plus bas.
- `Tuning.BuildPitchArray` décide quelle extrémité d'un accordage est la corde 1 en comparant **la première hauteur avec la dernière seulement**. Cela marche sur tout accordage qui monte ou descend de bout en bout. Sur les deux accordages de banjo 5 cordes de GA lui-même, dont la courte corde de bourdon est écrite en premier et sonne plus aigu que la dernière corde, il conserve l'ordre du fichier et numérote les cordes à l'envers. Le commentaire de `Str`, "String 1 is the string with the highest pitch", ne peut pas tenir pour cet instrument : la corde 1 est D4 et la corde 5 est G4.
- `Fretboard.GetNote` documente son premier paramètre comme "Zero-based string index (0 = lowest string)" puis indexe `Tuning[stringIndex + 1]`, où la corde 1 est la plus aiguë. C'est le commentaire qui est faux, pas le code.
- **Annexe A : `InstrumentsConfig` renvoie un seul instrument.** Le programme du cours référence maintenant `GA.Business.Config` et appelle `getAllInstruments()` dans la même exécution que celle qui lit le fichier lui-même : le fichier contient **122 instruments et 280 accordages**, le chargeur en renvoie **1 et 2**. `InstrumentsYaml` attend un document avec une liste `Instruments:` de `{ Name, Tunings }` ; le fichier est une correspondance d'instruments, chacun une correspondance d'accordages, sans aucune clé `Instruments` nulle part. Le test de nullité comme le gestionnaire `with _ ->` retombent sur `defaultData ()`, deux accordages de guitare écrits en dur. Rien n'échoue et rien n'est journalisé.
- Sept des 280 accordages ne sont pas des hauteurs : deux entrées de pedal steel commencent par le *nom* de leur accordage (`C6`, `E9`), une commence par le mot `Tuning` lui-même, une est le nom de l'instrument, une oublie une octave, et les deux guitares-harpes utilisent `|` pour séparer les cordes sous-basses. Le même glissement du nom pris pour une hauteur a produit les accordages à cinq hauteurs du ukulélé, qui s'analysent sans rien signaler.
- **Annexe B : la hiérarchie OPTIC.** Un doigté que l'on fait monter jusqu'à une classe d'ensembles, une équivalence à la fois, avec le type de GA à chaque barreau — `PitchClassSet` après O, P et C, `TranspositionClass` après T, `SetClass` après I — et les comptes 4096, 352 et 224 qui concordent avec le cours. Le schéma d'embedding OPTIC-K de GA coupe la même échelle en deux : STRUCTURE (dimensions 6-29, poids 0.45), ce sont les "pitch-class set invariants (O+P+T+I)", MORPHOLOGY (30-53, poids 0.25) la "physical fretboard realization", c'est-à-dire tout ce que l'échelle jette. Les poids et les plages sont lus dans le document de compétence, pas exécutés : *à vérifier*.
- L'annexe explique aussi le [chercheur de gammes](https://ianring.com/musictheory/scales/finder/) d'Ian Ring comme l'échelle rendue cliquable — Rotate, c'est T, Reflect, c'est I — et [Harmonious](https://harmoniousapp.net/) comme le même matériau vu par l'autre bout, par tonalité et par accord plutôt que par numéro d'ensemble.
- Le programme du cours passe à dix points d'entrée (`l1` à `l10`), tous dans `check.sh`. `Diagrams.Fretboard` prend maintenant un accordage, si bien que le ukulélé et la basse ont leurs propres diagrammes de manche ; les quatorze fichiers SVG existants sont identiques octet pour octet après le changement.
- **Les leçons s'écoutent.** Un bloc de code ```play devient un lecteur : les hauteurs d'une même ligne sonnent ensemble, une ligne après l'autre. Les échantillons sont une note enregistrée par demi-ton de la guitare nylon de FluidR3_GM, épinglée sur un commit de [`gleitz/midi-js-soundfonts`](https://github.com/gleitz/midi-js-soundfonts) et chargée au premier clic — rien n'est synthétisé, aucun fichier audio n'est stocké ici, et chaque note est un échantillon joué à sa propre hauteur. L'accordage standard est dans la leçon 1, do ionien contre do dorien dans la leçon 2, les quatre voicings dans la leçon 3, le ii–V–I dans la leçon 7, et la forme de guitare contre les mêmes doigts sur un ukulélé dans la leçon 8. Le bloc est du code : il est identique dans les trois langues, seul le libellé du bouton suit la page.

## 2026-09-14 — Épingler GA et compiler contre lui

- GA est épinglé sur [`a826864`](https://github.com/GuitarAlchemist/ga/commit/a826864f3a012cad88e415954bf57eca0ce12aa6) (`chore(quality): snapshot 2026-09-14`), la tête de `main` ce jour-là. Le clone local de GA de l'auteur n'est jamais utilisé ni modifié : [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/fetch-ga.sh) fait son propre clone dans `code/music-theory-ga/.ga`, ignoré par Git.
- Le clone est sans blobs (`--filter=blob:none`) avec un sparse checkout hors mode cone de `/Directory.Build.props`, `GA.Core`, `GA.Business.Config` et `GA.Domain.Core` : Git ne télécharge que le contenu de ces fichiers à l'extraction. `GA.Domain.Core` référence les deux autres ; `GA.Business.Config` est un projet F#, que le SDK .NET compile sans configuration supplémentaire.
- Dans Git Bash sous Windows, les motifs sparse commençant par `/` étaient réécrits en chemins Windows (`C:/Program Files/Git/Common/...`) et ne correspondaient à rien. `MSYS_NO_PATHCONV=1` corrige le problème.
- Un `git grep` sur le clone sans blobs s'est bloqué : il récupérait un par un tous les blobs du dépôt. Lire des fichiers isolés avec `git show HEAD:<path>` ne récupère que ceux-là.
- Le projet du cours référence GA avec un simple `ProjectReference` ([`GaTheory.csproj`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/GaTheory.csproj#L9-L14)). Compilation locale des trois projets de GA plus le cours : 5 à 13 secondes après la première restauration.
- Exécution de CI [34903462624](https://github.com/spareilleux/learn/actions/runs/34903462624), pour le push qui contenait le commit `79d2198` : verte sur les trois OS, 34 s sous Linux, 47 s sous macOS, 67 s sous Windows, clone compris.

## 2026-09-14 — Vérifier la théorie

- Le [`Theory.cs`](https://github.com/spareilleux/learn/blob/79d2198/code/music-theory-ga/GaTheory/Theory.cs) du cours est écrit uniquement à partir des définitions des manuels, puis comparé à GA. Sources : *Open Music Theory* (chapitres listés dans chaque leçon), Wikipédia (MIDI tuning standard, Guitar tunings, Guitar chord, Blues scale, Interval vector, List of set classes), la gamme 2741 d'Ian Ring, OEIS A000029 et A000031.
- Le site d'Open Music Theory et l'OEIS répondent 403 aux clients HTTP simples ; les chapitres ont été lus dans un navigateur.
- Vérifié en masse sur les 4096 ensembles : la forme primaire de Rahn du cours est égale à la forme primaire d'identifiant minimal de GA pour chaque ensemble ; 224 classes d'ensembles et 352 classes de transposition, comme le dit l'OEIS. Les tassements de Forte et de Rahn diffèrent sur 6 classes d'ensembles, et sur 17 des 352 classes de transposition, le chiffre que donne *List of set classes* (les 17 ont été calculées avec le même algorithme en dehors du programme).
- Bugs trouvés dans le programme du cours lui-même pendant l'écriture : l'ensemble vide faisait planter la clé de tri de la forme primaire ; la règle du barré comptait d'abord les cordes à vide, en copiant GA ; le voicing `x02010` a d'abord été nommé C6/A, jusqu'à ce que la fonction de nommage essaie d'abord la basse comme fondamentale.

## 2026-09-14 — Différences dans le code de GA (commit a826864)

Gardées comme lignes `DIFF` dans les sorties attendues, pour que la CI remarque quand GA change. Aucune n'a été signalée en amont.

Leçon 1, notes :

- `Pitch.Flat.DFlat(octave)`, `FFlat` et `GFlat` construisent D, G et A ([`Pitch.cs#L285-L295`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285-L295)).
- La regex de `PitchParser` n'a pas d'ancres et ignore la casse : `Pitch.Sharp.TryParse("Eb2")` réussit avec B2.
- `Note.Flat.Parse("B")` donne B♭ : le parseur met en majuscules, puis lit un `B` final comme un bémol.
- `PitchClass.Parse("A")` donne 10 (chiffre à la manière de l'hexadécimal, exprès), alors que la note A vaut 9.
- `SimpleIntervalSize.TryParse` lève une exception au lieu de renvoyer `false`.
- `Fretboard.GetPositionsForNote(Note.Sharp.C)` ne trouve rien : les positions contiennent des `Note.Chromatic`, et des records de types différents ne sont jamais égaux.
- Mineur, sans effet visible : `ValueObjectUtils.IsValueInRange(..., normalize: true)` calcule `count = max - min` et ajoute 1 après le modulo, contrairement à `EnsureValueRange` ; avec la normalisation, les deux finissent toujours dans la plage ([`ValueObjectUtils.cs#L69-L92`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Core/ValueObjects/ValueObjectUtils.cs#L69-L92)).

Leçon 2, gammes :

- `ModalFamily` regroupe les ensembles contenant 0 par vecteur d'intervalles, pas par rotation : 14 « modes » pour la mineure harmonique (ses 7 et ceux de la majeure harmonique), 24 pour la blues (avec son inversion et une classe en relation Z). Pas un bug, mais le nom évoque des rotations.
- Les gammes mineures sont écrites à partir de A, donc `Scale.NaturalMinor` a l'identifiant de C majeur (2741). Normal pour un ensemble de classes de hauteurs, surprenant à côté des autres gammes, écrites à partir de C.

Leçon 3, accords :

- `ChordFormula.DetermineQuality` ne renvoie jamais `Major7`, `Minor7`, `HalfDiminished` ni `Diminished7`, donc `GetSymbolSuffix` donne `7` pour maj7, `dim7` pour m7♭5 et `dim6` pour dim7.
- Le constructeur de `Chord` écrit toutes les notes autres que la fondamentale avec des dièses : `Eb` → `Eb G A#`, `Gb7` → `Gb A# C# E`.
- `Chord.AnalyzeChordFormula` saute `Notes[0]` comme si c'était la fondamentale ; après `ToInversion(1)`, c'est la basse, la tierce est perdue et la qualité est `Other`.
- `Voicing.HasBarre` compte les cordes à vide : C ouvert avec un E grave, E ouvert et G ouvert sont des accords « barrés ».
- Les diagrammes de voicings de GA commencent à la corde 1 (E aigu), à l'inverse des diagrammes d'accords.
- `CanonicalChordPatternCatalog` liste quatre ensembles d'intervalles deux fois (`9-sus4`/`dominant-11`, `major-6-add-9`/`6-9`, `minor-6-add-9`/`minor-6-9`, `augmented-7`/`dominant-7-sharp-5`) ; `TryFindExact` ne peut jamais renvoyer le second nom de chaque paire.
- Dans l'usage qu'en fait le cours, le catalogue compare les intervalles depuis la note la plus grave, donc un renversement comme `032010` (C/E) n'a pas de nom.

Leçon 4, classes d'ensembles :

- `IntervalClassVectorId` range les comptes en base 12 ; les comptes de 12 de la gamme chromatique débordent et se décodent en `<1 1 1 1 0 6>`.
- `CanonicalForteCatalog` décrit ses données comme "the standard Forte-column values", mais stocke les écritures de Rahn pour les classes disputées (`5-20 01568`, `6-Z29 023679`), comme le tableau d'Open Music Theory. Les étiquettes sont justes ; seul le commentaire est imprécis.
- `GrothendieckDelta.FromIcVs` transforme exprès une différence nulle en `Ic1 = 1`, donc des ensembles de même vecteur sont signalés à distance 1, et les « voisins à distance 1 » d'une triade sont les autres triades majeures et mineures, elle-même comprise.

## 2026-09-14 — Le serveur MCP de GA

Appelé depuis cette session via le serveur MCP de GA (le serveur n'indique pas de version ; il n'exécute peut-être pas le commit `a826864`). Les références au code portent sur `a826864`.

- `ga_set_class_subs("Am")` et `("G7")` : les bonnes listes (toutes les triades majeures et mineures ; toutes les septièmes de dominante et demi-diminuées), mais chaque accord sous `[maj]` (`c.EndsWith("")` dans [`ChordAtonalTool.cs#L187-L190`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/ChordAtonalTool.cs#L187-L190)), et une description qui dit "Am and C are NOT equivalent".
- `ga_chord_intervals` : `Cm7b5` → P1 m3 P5 m7, `G7b9` → P1 M3 P5 m7, `C9` → P1 M3 P5 M9, `Cmaj9` → P1 M3 P5 M9. La closure F# garde un intervalle par extension et ignore les altérations ([`DomainClosures.fs#L85-L98`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L85-L98)). `ga_parse_chord("Cm7b5")` a bien analysé `alt:b5`.
- `ga_chord_to_set`, qui tire ses classes de hauteurs de la même closure : `Cm7b5` → `{C, Eb, G, Bb}`, 4-26 (devrait être 4-27, avec G♭) ; `Cdim7` → `{C, Eb, F#, Bb}`, 4-27, "Scale: Major Seventh" (devrait être 4-28, avec A) ; `C` → 3-11, forme primaire `0 3 7`, une famille modale de 6.
- `ga_icv_neighbors("C", 1)` : douze lignes identiques `<0 0 1 1 1 0> Δ=1 Forte:3-11 [Major Triad]`, expliquées par la règle de la différence nulle ci-dessus.
- `ga_scale_by_id(2741)` : Major, avec `Forte Number: Some(n/a)` (7-35 attendu). `ga_scale_by_name("Dorian")` : introuvable.
- `get_tuning(Guitar, Standard)` : E2 A2 D3 G3 B3 E4, juste. `get_chord_voicings("C", maxFret 3)` : "An error occurred". `ga_search_voicings("C major open chord")` : la contrainte « ouvert » a été ignorée (diagramme `8-8-x-x-7-x`, étiqueté C/E).

## 2026-09-14 — Notes sur les modules Streeling

Les modules sont générés à partir de GuitarAlchemist/Demerzel et n'ont pas été modifiés ; les leçons y renvoient là où ils aident.

- MUS-006, "Modes as Rotations" : un décalage circulaire à gauche de l'identifiant transpose (C majeur décalé de 2 donne D majeur, 2774) ; obtenir D dorien sur C demande le décalage opposé (1709). La réponse d'entraînement "rotate left by 2 semitones → 2nd mode" a le même problème de sens.
- MUS-006 dit que Forte « a identifié 224 classes d'ensembles distinctes pour les cardinalités de 3 à 9 » ; 224 compte toutes les cardinalités de 0 à 12.
- MUS-002 déduit la forme primaire des cordes à vide (E A D G B) comme `[0,2,5,7,9]`, en comparant des classes de hauteurs au lieu d'intervalles pour départager ; la forme primaire est `(02479)`. Le même module répond « les triades majeures et mineures sont-elles des classes d'ensembles différentes ? Oui », puis range les deux dans 3-11, et écrit les formes primaires entre crochets là où Open Music Theory utilise des parenthèses.
- GTR-002 étiquette la forme de C `x 3 2 0 1 0` avec "Strings: 5-4-3-2-1" : six symboles pour cinq cordes, le `x` étant la corde 6.

## 2026-09-15 — Diagrammes

- Les diagrammes sont des fichiers SVG écrits par le programme du cours ([`Diagrams.cs`](https://github.com/spareilleux/learn/blob/a2439ba/code/music-theory-ga/GaTheory/Diagrams.cs)) dans `src/assets/music-theory-ga/`, puis importés comme composants par les leçons `.mdx`, donc intégrés à la page. Leurs couleurs sont `currentColor` et les variables CSS de Starlight (`--sl-color-accent-high`, `--sl-color-orange-high`, `--sl-color-green-high`, `--sl-color-bg`), avec une valeur de repli claire, et ils suivent le thème clair ou sombre du site. Ils ne contiennent que des noms de notes et des nombres, donc les trois langues partagent les mêmes fichiers ; la description se trouve dans l'`aria-label` de chaque page et dans le paragraphe qui précède la figure.
- `check.sh` les régénère en mémoire et les compare aux fichiers du dépôt ; la CI échoue quand un diagramme n'est pas à jour. Pour les régénérer : `dotnet run --project GaTheory -c Release -- svg ../../src/assets/music-theory-ga`.
- GA a des composants React pour les mêmes images, que le cours lit mais ne réutilise pas : `BraceletNotation.tsx`, `FretDiagram.tsx` et `VexChordDiagram.tsx`, sous `ReactComponents/ga-react-components/src/components`. À la lecture de `BraceletNotation` et de son `NoteGroup` (non exécuté, *à vérifier* dans un navigateur) : les points et les étiquettes sont placés à `angle − 90°`, mais les rayons de `NoteGroup` utilisent `cos(angle)` sans ce décalage, et seraient donc tournés d'un quart de tour ; et `findSymmetryAxes` ne teste que les axes qui passent par une note, manque les axes entre deux notes, et ajoute chaque axe deux fois.

## 2026-09-15 — Leçons 5 à 7 : différences dans le code de GA (commit a826864)

Gardées comme lignes `DIFF` dans les sorties attendues. Aucune n'a été signalée en amont.

Leçon 5, tonalités :

- `Key.GetInterval(note)` renvoie `note.GetInterval(Root)`, l'intervalle qui monte de la note jusqu'à la tonique : `Key.Major.C.GetInterval(E)` vaut m6, pas M3 ([`Key.cs#L70-L76`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L70-L76)).
- `Key.Major.TryParse("H")` lève une `InvalidOperationException` au lieu de renvoyer `false`, et `Key.Minor.TryParse` a le même code ([`Key.cs#L153-L186`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L153-L186)).
- Les outils MCP `get_parallel_key` et `get_relative_key` ont le même corps : l'autre mode sur la même armure, donc la tonalité homonyme de C est A mineur ([`KeyTools.cs#L135-L169`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L135-L169)).
- `get_neighboring_keys` passe `key.KeySignature.ToString()`, la liste des altérations, à une recherche par nom de tonalité, et échoue ([`KeyTools.cs#L197-L215`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/KeyTools.cs#L197-L215)).

Leçon 6, accords d'une tonalité :

- `HarmonicFunctionExtensions.FromDegree(7)` vaut toujours `LeadingTone`, y compris pour la sous-tonique de la mineure naturelle ; `ScaleDegreeFunction.Subtonic` existe mais n'y est pas utilisé.
- `ga_diatonic_chords` nomme les fondamentales à partir d'une table de 12 noms : F♯ majeur obtient `Fdim` (E♯dim) et G♭ majeur `B` (C♭) ([`DomainClosures.fs#L23-L36`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L23-L36)). Le `Key.Notes` du cœur de GA écrit correctement les deux tonalités.
- Lecture du code seulement (`GA.Domain.Services` n'est pas compilé par le cours, *à vérifier*) : `HarmonicFunctionAnalyzer.Parse` teste `Contains("tonic")` avant `"supertonic"` et `"mediant"` avant `"submediant"`, donc "Supertonic" serait analysé comme `Tonic` et "Submediant" comme `Mediant` ([`HarmonicFunctionAnalyzer.cs#L29-L72`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Services/Tonal/HarmonicFunctionAnalyzer.cs#L29-L72)). `ToPrimaryCategory` range la médiante et la sus-dominante avec la tonique, là où Open Music Theory appelle iii et vi des prédominantes faibles : un choix de manuel, pas un bug.

Leçon 7, cadences et progressions :

- `Cadences.yaml` numérote "Chromatic Mediant (Metal)", Em–Gm en E mineur, `i biii`, à partir de E majeur ; la cadence andalouse du même fichier est numérotée à partir des notes de E phrygien. Sa "Phrygian Half Cadence" est ♭II–i, là où le terme classique désigne iv⁶–V en mineur.
- `PitchClassSet.ClosestDiatonicKey` départage avec « la forme normale contient la classe de hauteurs 3, donc mineur ». La forme normale des notes d'une gamme majeure est `0 1 3 5 6 8 T`, donc C F G C, G D Em C, Dm7 G7 Cmaj7 et C Am F G7 sortent dans la relative mineure ([`PitchClassSet.cs#L597-L660`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Atonal/PitchClassSet.cs#L597-L660)).
- `ga_key_from_progression` et `ga_analyze_progression` notent les tonalités sur les seules fondamentales des accords, avec la gamme mineure naturelle, et préfèrent la fondamentale du premier accord ([`GuitaristProblemTools.cs#L157-L223`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L157-L223), [`DomainClosures.fs#L255-L336`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L255-L336)).

## 2026-09-15 — Le serveur MCP de GA, tonalités et progressions

Même réserve que le 2026-09-14 : le serveur n'indique pas sa version.

- `get_parallel_key("Key of C")` → `Key of Am`. `get_relative_key("Key of Ab")` → `Key of Fm`, juste. `get_key_signature_info("Key of Gm")` → fondamentale G, `Bb Eb`, notes G A Bb C D Eb F, juste.
- `get_neighboring_keys("Key of C")` et `get_diatonic_chords("A minor")` : "An error occurred invoking …".
- `ga_diatonic_chords` : F♯ majeur → `F#, G#m, A#m, B, C#, D#m, Fdim` ; G♭ majeur → `Gb, Abm, Bbm, B, Db, Ebm, Fdim`.
- `ga_key_from_progression(["Am","F","C","G"])` → meilleure hypothèse A mineur (puis C majeur et D mineur, tous à 4/4), alors que la description de l'outil promet C majeur ; `(["Dm7","G7","Cmaj7"])` → D mineur (puis C majeur et C mineur).
- `ga_analyze_progression("Am Dm E7 Am")` → "Key: A major, I IV V I" ; `("Dm7 G7 Cmaj7")` → "Key: D minor, i iv VII".

## 2026-09-15 — Notes sur les modules Streeling, suite

- MUS-003, "Guitar Example — D7 to G Voice Movements" : la tablature met C à la case 1 de la corde de E aigu et F♯ à la case 1 de la corde de B. La case 1 donne F sur la corde de E aigu et C sur la corde de B ; le D7 ouvert (`xx0212`) a F♯ à la case 2 de la corde 1 et C à la case 1 de la corde 2. Les leçons renvoient à MUS-003 pour ses fonctions, ses cadences et ses tonalités voisines, pas pour cet exemple.
- MUS-003 range iii et vi dans la famille de la tonique ; la leçon 6 donne les deux lectures.

## 2026-09-24 — Correctifs amont vérifiés à nouveau

- GA a fusionné des correctifs pour les lignes du tableau QA : [#681](https://github.com/GuitarAlchemist/ga/pull/681) pour les outils MCP et [#682](https://github.com/GuitarAlchemist/ga/pull/682) pour les analyseurs le 2026-09-23, [#625](https://github.com/GuitarAlchemist/ga/pull/625) pour la détection de tonalité le 2026-09-24. Le cours reste épinglé à `a826864` : les leçons et les annexes montrent toujours le comportement contre lequel elles ont été écrites.
- [`recheck/probe.cs`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/recheck/probe.cs) appelle directement les mêmes méthodes d'outils, sans le transport MCP, sur GA [`27a1257`](https://github.com/GuitarAlchemist/ga/commit/27a1257f7fe5478c4b1bcb6b86ebe101707ac935) ; sa sortie est [`recheck/results.txt`](https://github.com/spareilleux/learn/blob/main/code/music-theory-ga/recheck/results.txt). Il ne fait pas partie de `check.sh`, parce qu'il lui faut un clone complet de GA.
- Corrigé, et relancé : `ga_chord_to_set('Cm7b5')` → `{C, Eb, F#, Bb}`, 4-27, et `('Cdim7')` → 0 3 6 9, 4-28 (orthographié `{C, Eb, F#, A}`). `ga_set_class_subs('Am')` → les accords parfaits majeurs sous `[maj]`, les mineurs sous `[m]`. `ga_icv_neighbors('C', 1)` → « No other set class within distance 1 of C » au lieu de douze lignes identiques. `ga_scale_by_id(2741)` → `Forte Number: 7-35`, et `ga_scale_by_name('Dorian')` → identifiant 1709. `get_neighboring_keys('Key of C')` → F, C, G.
- La détection de tonalité passe désormais par `KeyIdentificationService`, qui ajoute un poids de cadence au nombre d'accords diatoniques ([lignes 171-237](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L171-L237)). `ga_analyze_progression("Dm7 G7 Cmaj7")` → « Key: C major », ii V I, et `ga_key_from_progression` est d'accord ; `ga_analyze_progression("Am Dm E7 Am")` → « Key: A minor », i iv v i.
- Encore faux, non signalé : E7 est noté `v`, parce que le chiffre vient du degré de la gamme mineure naturelle et non de l'accord ([`romanFor`](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L351-L355)) ; il compte aussi hors de A mineur (3/4), par choix dans #625, qui crédite plutôt le V7 du mineur harmonique par la cadence. `ga_key_from_progression(["Am","F","C","G"])` met toujours A mineur en tête, à égalité 4/4 avec C majeur, et la description de l'outil promet toujours C majeur ([ligne 168](https://github.com/GuitarAlchemist/ga/blob/27a1257f7fe5478c4b1bcb6b86ebe101707ac935/GaMcpServer/Tools/GuitaristProblemTools.cs#L168)).
- Non relancés : `get_chord_voicings`, `get_diatonic_chords("A minor")` et `ga_search_voicings`, qui ont besoin de GaApi.

## À vérifier

- Si le reconnaisseur d'accords complet de GA (pas seulement `TryFindExact`) nomme les renversements comme `032010` ; la recherche de voicings du MCP laisse penser que oui (`C/E`), mais le cours ne l'a pas appelé.
- Le commit du serveur MCP : les réponses ci-dessus n'ont pas été reproduites avec un serveur compilé à partir de `a826864`.
- `HarmonicFunctionAnalyzer.Parse` sur "Supertonic" et "Submediant", par un test dans GA.
- Les rayons et les axes de symétrie du `BraceletNotation` de GA, rendus dans un navigateur.
