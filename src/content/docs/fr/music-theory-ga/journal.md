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

## À vérifier

- Si le reconnaisseur d'accords complet de GA (pas seulement `TryFindExact`) nomme les renversements comme `032010` ; la recherche de voicings du MCP laisse penser que oui (`C/E`), mais le cours ne l'a pas appelé.
- Le commit du serveur MCP : les réponses ci-dessus n'ont pas été reproduites avec un serveur compilé à partir de `a826864`.
- `HarmonicFunctionAnalyzer.Parse` sur "Supertonic" et "Submediant", par un test dans GA.
- Les rayons et les axes de symétrie du `BraceletNotation` de GA, rendus dans un navigateur.
