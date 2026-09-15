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

## À vérifier

- Si le reconnaisseur d'accords complet de GA (pas seulement `TryFindExact`) nomme les renversements comme `032010` ; la recherche de voicings du MCP laisse penser que oui (`C/E`), mais le cours ne l'a pas appelé.
- Le commit du serveur MCP : les réponses ci-dessus n'ont pas été reproduites avec un serveur compilé à partir de `a826864`.
