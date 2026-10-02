---
title: "Leçon 20 : les progressions générées"
description: "Le serveur MCP de Guitar Alchemist écrit des progressions d'accords à partir de neuf gabarits, avec ga_generate_progression et sans modèle ; le chatbot ne l'appelle pas. Chaque accord a les bonnes notes, et 712 sur 750 s'écrivent comme dans un manuel, dans les 15 tonalités de chaque mode : D, G et C mineur reçoivent des dièses, et douze noms par orthographe ne peuvent écrire ni Cb, ni Fb, ni E#. La table à douze tonalités de GA écrit, elle aussi, B pour le IV de Gb. Un chiffrage passe pour une tonalité, un b minuscule fait passer B majeur aux bémols, et la longueur n'a pas de limite : 100000 accords font 18 500 223 caractères. Raccordées avec ga_voice_leading_pair, comme le suggère la réponse, les premières paires se rejoignent sur main à 17 endroits sur 32."
sidebar:
  label: 20. Les progressions générées
  order: 20
---

La [leçon 19](../19-voice-leading-pairs/) exécutait `ga_voice_leading_pair`, un outil de `GaMcpServer`, le serveur MCP de GA. Le même fichier contient son compagnon, `ga_generate_progression` : à partir d'une tonique et du nom d'un gabarit, il écrit une progression d'accords, « Deterministic — no LLM » ([`CompositionTools.cs` lignes 108-177](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L108-L177)). Sa réponse se termine par une remarque : « Compose by passing each chord to ga_search_voicings; stitch with ga_voice_leading_pair for smooth-voiced transitions ». Le chatbot ne l'appelle pas, et le skill rédigé pour l'appeler reste en attente, comme celui de la leçon 19 ([`skills-dev/_pending-tools/README.md` ligne 49](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/README.md#L49)).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. `CompositionTools.cs` et `ChordPitchClasses`, qui lit la tonique, sont identiques sur le `main` de GA à [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/commit/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) (2026-10-01) : le programme ne demande donc les progressions qu'au commit épinglé. La dernière section les raccorde avec `ga_voice_leading_pair`, dont la recherche a changé sur `main` ; `GaMain` la refait donc tourner. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l20
dotnet run --project code/ga-ai/GaMain -c Release -- l20
```

## Comment l'outil répond

Chaque gabarit est une liste d'étapes : un décalage en demi-tons depuis la tonique, une qualité d'accord et un chiffre romain ([lignes 27-37](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L27-L37)) :

```csharp
    private record ProgressionStep(int SemitoneOffset, string Quality, string RomanLabel);

    private static readonly Dictionary<string, ProgressionStep[]> Templates = new(StringComparer.OrdinalIgnoreCase)
    {
        // Jazz staples
        ["ii-V-I"] =
        [
            new(2, "m7",  "ii7"),
            new(7, "7",   "V7"),
            new(0, "maj7", "Imaj7"),
        ],
```

Les neuf gabarits sont ii-V-I, circle-of-fifths, rhythm-changes-a, I-V-vi-IV, I-vi-IV-V, canon, 12-bar-blues, et deux en mineur, minor-vamp et andalusian ([lignes 29-106](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L29-L106)). L'outil vérifie la tonique avec `ChordPitchClasses.TryParse` ([ligne 139](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L139)), puis nomme la fondamentale de chaque accord d'après l'un de deux tableaux de douze noms, en dièses ou en bémols ([lignes 344-380](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L344-L380)) :

```csharp
    private static string BuildSymbol(int rootPc, ProgressionStep step, bool preferFlats)
    {
        var chordRootPc = (rootPc + step.SemitoneOffset) % 12;
        var rootName = preferFlats
            ? PitchClassToFlatName(chordRootPc)
            : PitchClassToSharpName(chordRootPc);
        return rootName + step.Quality;
    }

    private static string PitchClassToSharpName(int pc) => pc switch
    {
        0  => "C",  1  => "C#", 2  => "D",  3  => "D#",
        4  => "E",  5  => "F",  6  => "F#", 7  => "G",
        8  => "G#", 9  => "A",  10 => "A#", 11 => "B",
        _  => "C",
    };

    private static string PitchClassToFlatName(int pc) => pc switch
    {
        0  => "C",  1  => "Db", 2  => "D",  3  => "Eb",
        4  => "E",  5  => "F",  6  => "Gb", 7  => "G",
        8  => "Ab", 9  => "A",  10 => "Bb", 11 => "B",
        _  => "C",
    };

    /// <summary>
    ///     True when the user's key root is on the flat side of the circle of fifths
    ///     (F, Bb, Eb, Ab, Db, Gb — i.e. the symbol contains a 'b' OR is plain F). Used
    ///     to pick flat vs sharp enharmonic spelling for generated chord symbols so
    ///     "ii-V-I in Bb" yields Bbmaj7 rather than the sharp-spelled A#maj7.
    ///     C is treated as sharp-side (the pop convention for chromatic chords in C).
    /// </summary>
    private static bool PrefersFlats(string root)
    {
        var r = root.Trim();
        return r.Contains('b') || r.Equals("F", StringComparison.OrdinalIgnoreCase);
    }
```

Chaque accord de la réponse porte son chiffre romain, son chiffrage, un `degree`, sa qualité et ses classes de hauteurs ([lignes 158-165](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L158-L165)). `degree` contient le décalage en demi-tons, 7 pour V, et non le degré de la gamme.

## Les gabarits dans toutes les tonalités

Le programme demande les sept gabarits majeurs dans les 15 tonalités majeures qu'écrit une armure, de C♭ à C♯, et les deux gabarits mineurs dans les 15 tonalités mineures, de A♭ mineur à A♯ mineur. Un manuel écrit la fondamentale de chaque accord avec la lettre du degré que désigne son chiffre romain dans la tonalité, et l'altération qui mène à la note : en D mineur, ♭VI est B♭, jamais A♯. Le programme compare chaque chiffrage à cette orthographe, et les classes de hauteurs à celles de l'accord :

```text
== The nine templates in the keys a textbook writes, at the pin, against the textbook's spelling
template           mode    keys   chords   spelled right   pitch classes right
ii-V-I             major   15     45       44              45
circle-of-fifths   major   15     60       59              60
rhythm-changes-a   major   15     120      118             120
I-V-vi-IV          major   15     60       57              60
I-vi-IV-V          major   15     60       57              60
canon              major   15     120      113             120
12-bar-blues       major   15     180      167             180
minor-vamp         minor   15     45       44              45
andalusian         minor   15     60       53              60
chords 750: spelled right 712, pitch classes right 750
the chords spelled otherwise, as the tool writes them, with the textbook's spelling and their count:
  Cb major   Bmaj7 for Cbmaj7 3, B for Cb 4, E for Fb 4, B7 for Cb7 7, E7 for Fb7 3
  C# major   Fm7 for E#m7 1, Fm for E#m 1
  Gb major   B for Cb 4, B7 for Cb7 3
  A# minor   F7 for E#7 1, F for E# 1
  D minor    A# for Bb 1
  G minor    D# for Eb 1
  C minor    A# for Bb 1, G# for Ab 1
  Eb minor   B for Cb 1
  Ab minor   E for Fb 1
```

- **Chaque accord a les bonnes classes de hauteurs, et 712 des 750 sont écrits comme les écrit un manuel.** L'erreur ne porte que sur les noms.
- **D, G et C mineur reçoivent des dièses.** `PrefersFlats` cherche un `b` dans la tonique, ou la tonique F ; son commentaire donne pour côté bémol « F, Bb, Eb, Ab, Db, Gb ». Les trois tonalités mineures ont des bémols à l'armure, mais aucun dans leur nom : l'andalusian en C mineur s'écrit avec A♯ et G♯ pour B♭ et A♭.
- **Douze noms par tableau ne suffisent pas à écrire toutes les tonalités.** Chaque tableau a un nom par classe de hauteurs. En C♭ majeur, la tonique s'écrit B et le IV E ; en G♭ majeur, le IV s'écrit B ; en C♯ majeur, le iii s'écrit Fm pour E♯m ; en A♯ mineur, le V s'écrit F7 pour E♯7. E♭ mineur et A♭ mineur reçoivent B et E pour leur ♭VI, C♭ et F♭. Les leçons 10 et 18 ont trouvé les mêmes douze noms ailleurs dans GA.

## Les tables de GA elles-mêmes

`ChordProgressions.yaml`, la configuration des progressions de GA, se termine par des tables de transposition : trois d'entre elles correspondent à un gabarit de l'outil ([lignes 580-695](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L580-L695)). Le programme les lit et demande à l'outil les mêmes tonalités :

```text
== The tool against the twelve-key tables of GA's ChordProgressions.yaml, at the pin
table                                template        keys   same chords   spelled otherwise by a textbook
ii–V–I (Major) — 12 keys             ii-V-I          12     12            none
Pop I–V–vi–IV — 12 keys (triads)     I-V-vi-IV       12     12            Gb: Gb Db Ebm B, textbook Gb Db Ebm Cb
12-Bar Blues — common guitar keys    12-bar-blues    5      5             none
```

- **L'outil et les tables de GA concordent sur chaque ligne, accord faux compris.** La table de I-V-vi-IV écrit B pour le IV de G♭, comme l'outil ([ligne 685](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Config/ChordProgressions.yaml#L685)) ; un manuel écrit C♭. Deux sources qui s'accordent ne font pas une vérification : la table ne peut pas servir de test à l'outil.

## Les toniques qu'il lit

`ChordPitchClasses` lit un chiffrage, pas une tonalité. Sa table des fondamentales ignore la casse, contient C♭ mais pas E♯, et aucun `♭` ([`MusicalQueryEncoder.cs` lignes 166-171](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Search/MusicalQueryEncoder.cs#L166-L171)). Le programme essaie quelques toniques qu'un guitariste ou un agent pourrait écrire :

```text
== The roots the tool reads, at the pin
root       template       chords, or the error
C          I-V-vi-IV      C G Am F
c          I-V-vi-IV      C G Am F
B          I-V-vi-IV      B F# G#m E
b          I-V-vi-IV      B Gb Abm E
Bb         I-V-vi-IV      Bb F Gm Eb
bb         I-V-vi-IV      Bb F Gm Eb
B♭         I-V-vi-IV      unknown root 'B♭' — try C, D, Eb, F#, etc.
Cb         I-V-vi-IV      B Gb Abm E
E#         I-V-vi-IV      unknown root 'E#' — try C, D, Eb, F#, etc.
F major    I-V-vi-IV      F C Dm A#
D minor    I-V-vi-IV      D A Bm G
D minor    andalusian     Dm C A# A
Dm         andalusian     Dm C A# A
C          andalusian     Cm A# G# G
C7b9       andalusian     Cm Bb Ab G
Cmaj7      ii-V-I         Dm7 G7 Cmaj7
```

- **Un b minuscule fait passer B majeur aux bémols.** Le lecteur lit « b » comme B, puis `PrefersFlats` y trouve un `b` : `B Gb Abm E`. « c » et « bb » donnent la bonne réponse.
- **Un chiffrage passe pour une tonique, et sa qualité tombe.** « D minor » et « Dm » sont lus comme D : I-V-vi-IV en « D minor » reçoit donc les accords de D majeur, sans avertissement. `PrefersFlats` compare la chaîne entière à « F », si bien que « F major » reçoit des dièses : `F C Dm A#`.
- **N'importe quel `b` de la chaîne décide de l'orthographe.** « C7b9 » est lu comme C, et le `b` de sa neuvième bémol fait passer l'andalusian en C mineur aux bémols : `Cm Bb Ab G`, l'orthographe que « C » n'obtient pas.
- **`♭` et E♯ sont refusés,** avec une erreur qui suggère « C, D, Eb, F#, etc. ».

## La longueur

`length` répète ou tronque le gabarit ([lignes 148-151](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L148-L151)). Dans le même fichier, `limit` et `candidatesPerChord` sont bornés ([lignes 202-203](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L202-L203)) ; `length` ne l'est pas :

```text
== The length, at the pin
length   template       chords    last chord, characters of JSON
(none)   12-bar-blues   12        V7 G7, 2439
0        12-bar-blues   12        V7 G7, 2439
-1       12-bar-blues   12        V7 G7, 2439
4        12-bar-blues   4         I7 C7, 958
13       12-bar-blues   13        I7 C7, 2624
100000   12-bar-blues   100000    I7 C7, 18500223
```

- **0 et une longueur négative donnent la longueur du gabarit lui-même,** sans avertissement.
- **Une longueur de 100000 renvoie 100000 accords, soit 18 500 223 caractères de JSON,** une seule réponse, bien plus grande que la fenêtre de contexte d'un agent.

## Raccorder la progression

Le programme suit la remarque de l'outil pour chaque gabarit, en C majeur ou en A mineur. Il demande à `ga_voice_leading_pair` chaque passage d'un accord au suivant, et prend la première paire. Deux premières paires se rejoignent quand la seconde part du voicing où finit la première ; sinon, le guitariste doit sauter d'un voicing de l'accord à un autre. Le programme cherche aussi, parmi les mêmes 15 candidats de chaque accord, le chemin continu qui bouge le moins : un voicing par accord, les mouvements additionnés avec la distance de l'outil lui-même.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, at the pin
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          0 of 1             9                   10
circle-of-fifths   4       3          0 of 2             13                  15
rhythm-changes-a   8       7          0 of 6             35                  40
I-V-vi-IV          4       3          0 of 2             13                  15
I-vi-IV-V          4       3          1 of 2             13                  15
canon              8       7          1 of 6             33                  42
12-bar-blues       12      11         4 of 10            31                  34
minor-vamp         3       2          0 of 1             6                   8
andalusian         4       3          0 of 2             12                  16
places where two first pairs should meet 32: they meet at 6; templates whose least joined path moves as little as the sum of first pairs 0 of 9
I-V-vi-IV, the first pairs: x-x-2-0-1-x C/E → x-x-0-0-0-3 G/D, 6; x-2-0-0-x-x G/B → x-3-0-2-x-x D5/C, 3; x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 4
I-V-vi-IV, the least joined path: x-3-2-0-1-x C → x-2-0-0-x-x G/B → x-3-2-2-x-x Am/C → x-3-3-2-x-1 F/C, 15
```

- **Au commit épinglé, les premières paires se rejoignent à 6 endroits sur 32, et chaque chemin continu bouge plus que les premières paires additionnées.** Dans I-V-vi-IV, la première paire de C → G aboutit à `x-x-0-0-0-3`, et celle de G → Am part de `x-2-0-0-x-x` et aboutit à `x-3-0-2-x-x`, que l'index nomme D5/C.

```text
== Each template stitched with ga_voice_leading_pair, in C major or A minor, on main
template           chords  moves      first pairs meet   sum of first pairs  least joined path
ii-V-I             3       2          1 of 1             6                   6
circle-of-fifths   4       3          2 of 2             10                  10
rhythm-changes-a   8       7          3 of 6             21                  25
I-V-vi-IV          4       3          0 of 2             9                   9
I-vi-IV-V          4       3          1 of 2             9                   9
canon              8       7          3 of 6             27                  27
12-bar-blues       12      11         7 of 10            24                  28
minor-vamp         3       2          0 of 1             7                   7
andalusian         4       3          0 of 2             14                  14
places where two first pairs should meet 32: they meet at 17; templates whose least joined path moves as little as the sum of first pairs 7 of 9
I-V-vi-IV, the first pairs: x-x-2-x-1-3 C/E → x-x-0-x-0-3 G/D, 3; x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E, 5; x-x-x-2-1-0 Am → x-x-x-2-1-1 F/A, 1
I-V-vi-IV, the least joined path: x-x-2-0-1-x C/E → x-x-0-0-0-x G/D → x-x-2-2-1-x Am/E → x-x-3-2-1-x F, 9
```

- **Sur `main`, elles se rejoignent à 17 endroits sur 32.** Dans 7 des 9 gabarits, un chemin continu bouge exactement aussi peu que les premières paires additionnées, mais dans cinq d'entre eux, les premières paires ne se rejoignent pas toutes. Dans I-V-vi-IV, la première paire de C → G aboutit à `x-x-0-x-0-3` et la suivante part de `x-x-0-0-0-x`, deux voicings de G ; le chemin continu bouge lui aussi de 9 demi-tons, sans le saut.
- **Dans rhythm-changes-a et 12-bar-blues, tout chemin continu bouge davantage :** 25 demi-tons au lieu de 21, 28 au lieu de 24. L'outil répond un mouvement à la fois. Choisir un voicing par accord demande une recherche sur toute la progression, comme celle qu'exécute le programme.

## Le brouillon de skill qui l'appellerait

`skills-dev/_pending-tools/progression-generator/DRAFT.md` est un skill du chatbot écrit pour appeler `ga_generate_progression` ([lignes 1-24](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L1-L24)). Comme celui de la leçon 19, il décrit un autre outil :

- des arguments `mood`, `key`, `length` avec une valeur par défaut de 4, `style` et `complexity` ([lignes 32-38](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L32-L38)), là où l'outil prend `root`, `template` et `length` ;
- `Chords`, `RomanNumerals`, `Style` et `Rationale` dans la réponse ([lignes 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L40-L45)), là où l'outil renvoie `chords`, sans style ni justification ;
- des tonalités écrites « D minor » et « F major » ([lignes 49-52](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L49-L52)) : passé comme tonique, « D minor » est lu comme D, et « F major » reçoit des dièses ;
- un exemple de réponse, Dm – B♭maj7 – Gm – A7 ([lignes 56-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L56-L63)), qu'aucun gabarit n'écrit ;
- un renvoi à `Common/GA.Business.ML/Agents/Mcp/ProgressionMcpTools.cs` ([ligne 77](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-generator/DRAFT.md#L77)), un fichier que GA n'a ni au commit épinglé ni sur `main`.

## Où le cours s'arrête

- **Le manuel est celui du cours :** la lettre de la fondamentale suit le degré du chiffre romain, dans les 15 armures de chaque mode. La description de l'outil propose aussi D♯, G♯ et A♯ comme toniques pour les gabarits majeurs, des tonalités qu'un manuel écrit E♭, A♭ et B♭ ; le cours ne les évalue pas.
- **Le raccord tourne sur le corpus de la leçon 3,** en C majeur et en A mineur seulement, avec les 15 candidats que l'outil utilise par défaut.
- **Le chemin continu est la recherche du cours,** avec la distance de l'outil lui-même ; la leçon 19 a montré que cette distance apparie les notes les plus graves quand les tailles diffèrent.
- **Le programme appelle directement les méthodes des outils,** et non par un client MCP et le serveur de GA.

## Exercices

1. Dans le tableau des toniques, « C » écrit l'andalusian en C mineur avec des dièses, et « C7b9 » avec des bémols. Quelle ligne du code fait la différence, et pourquoi, sinon, aucune tonique lue comme C n'est-elle écrite en bémols ?
2. En C♯ majeur, le iii du canon s'écrit Fm. Qu'écrit un manuel, et pourquoi aucun des deux tableaux de noms ne peut-il l'écrire ?
3. Sur `main`, les premières paires de I-V-vi-IV bougent de 3, 5 et 1 demi-tons. Pourquoi un guitariste ne peut-il pas les jouer à la suite, et de combien bouge le chemin continu que trouve le programme ?
4. Le brouillon fait correspondre « Jazz ii-V-I in F » à la tonalité « F major ». Passée comme tonique de ii-V-I, l'orthographe en dièses se voit-elle ? Et avec I-V-vi-IV ?

<details>
<summary>Solutions</summary>

1. `PrefersFlats` ne renvoie vrai que si la tonique contient un `b` ou vaut F ([ligne 379](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/CompositionTools.cs#L379)). Le lecteur lit C dans « C », « c » ou un chiffrage sur C, et B♯ n'est pas dans sa table. Seul un `b` dans la qualité, comme la neuvième bémol de « C7b9 », fait passer l'orthographe aux bémols.
2. E♯m : le iii de C♯ majeur est sur E, diésé. Le tableau des dièses donne à la classe de hauteurs 5 le nom F, et celui des bémols aussi ; aucun des deux n'a E♯.
3. La première paire de C → G aboutit à `x-x-0-x-0-3`, et la suivante part de `x-x-0-0-0-x` : deux voicings de G, entre lesquels la main doit sauter. Le chemin continu `x-x-2-0-1-x` → `x-x-0-0-0-x` → `x-x-2-2-1-x` → `x-x-3-2-1-x` bouge de 9 demi-tons, autant que les premières paires additionnées.
4. Avec ii-V-I, non : les accords tombent sur G, C et F, que les deux tableaux nomment sans altération, et l'outil répond `Gm7 C7 Fmaj7`. Avec I-V-vi-IV, oui : le IV tombe sur B♭, et le tableau montre `F C Dm A#`. Vérifié en exécutant l'outil du commit épinglé, hors de la sortie attendue du cours.

</details>

## À retenir

- L'orthographe d'une tonalité suit son armure, pas les lettres de son nom : chercher un `b` dans le nom manque D, G et C mineur.
- Un nom par classe de hauteurs ne permet pas d'écrire les tonalités qui ont E♯, B♯, C♭ ou F♭.
- Deux sources qui s'accordent ne font pas une vérification : la table de GA partage le B de l'outil pour C♭.
- Un paramètre sans limite peut renvoyer une réponse qu'aucun agent ne peut lire.
- Une réponse paire par paire ne peut pas planifier une suite : la meilleure paire pour chaque mouvement ne fait pas un chemin.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `GaMcpServer/Tools/CompositionTools.cs`, `Common/GA.Business.ML/Search/MusicalQueryEncoder.cs`, `Common/GA.Business.Config/ChordProgressions.yaml`, `skills-dev/_pending-tools/progression-generator/DRAFT.md`, `skills-dev/_pending-tools/README.md`.
- GuitarAlchemist/ga au commit [`f4f5b4a`](https://github.com/GuitarAlchemist/ga/tree/f4f5b4af881f3970c6fdc25fa61a30ef9d23458a) : le même outil, le même lecteur, la même table et le même brouillon, et la recherche de la leçon 16.
- Les programmes du cours : `code/ga-ai/GaAi/Lesson20.cs`, `code/ga-ai/GaMain/Program.cs`, `code/ga-ai/Shared/ProgressionProbe.cs`.
