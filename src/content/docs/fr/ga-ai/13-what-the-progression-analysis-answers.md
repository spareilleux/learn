---
title: "Leçon 13 : ce que répond l'analyse de progression"
description: "Le chatbot de Guitar Alchemist n'a aucun skill qui analyse une progression d'accords : le brouillon attend un outil, mais la closure du DSL dont il aurait besoin répond déjà par ga_dsl_eval. Le cours lui pose les quatre exemples du brouillon et huit progressions de manuel dans les 30 tonalités, au commit épinglé et sur main. Le commit épinglé ne lit que les fondamentales et donne une autre tonalité à chaque progression mineure ; main trouve chaque tonalité, mais n'écrit aucun chiffre romain pour le vii° d'une tonalité mineure, donne à six tonalités leur nom enharmonique et laisse des accords d'emprunt déplacer la tonalité."
sidebar:
  label: 13. Ce que répond l'analyse de progression
  order: 13
---

La [leçon 12](../12-what-the-progression-skills-answer/) s'arrêtait là où le chatbot n'a plus de skill : l'analyse d'une progression, avec sa tonalité et ses chiffres romains. Le brouillon de ce skill y voit « the single most-requested prompt class », le type de prompt le plus demandé au chatbot public ([`DRAFT.md` ligne 30](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L30)), et attend un outil `ga_analyze_progression` « not yet implemented in Common/GA.Business.ML/Agents/Mcp/ », pas encore implémenté ([ligne 20](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L20)) ; le dossier ne contient aucun fichier de ce genre, ni au commit épinglé ni sur `main`. Le calcul, lui, existe déjà. La closure `domain.analyzeProgression` du DSL déduit la tonalité d'une progression et attribue un chiffre romain à chaque accord. L'outil `GaAnalyzeProgression` de GaMcpServer l'appelle ([`GaDslTool.cs` lignes 195-197](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GaDslTool.cs#L195-L197)), tout comme deux autres outils du serveur qui ont d'abord besoin d'une tonalité, `GaProgressionCompletion` et `GaArpeggioSuggestions` ([`GuitaristProblemTools.cs` lignes 271-273](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L271-L273) et [434-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L434-L436)), et la ligne de commande de GA ([`Program.fs` ligne 320](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaCli/Program.fs#L320)). Cette leçon lui demande ce que le brouillon attend de l'outil.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. Sur `main`, la closure a été réécrite deux fois après le commit épinglé : [#625](https://github.com/GuitarAlchemist/ga/pull/625) prend la tonalité dans `KeyIdentificationService`, le service de la leçon 11, et [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40) tire de l'accord la casse de chaque chiffre romain. `DomainClosures.fs` n'a pas changé depuis, jusqu'à `main` au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30). Le cours le récupère à `6baf32e` et le compile sans modification dans un projet à part, `GaDslMain`, contre le DSL épinglé et contre le service de `main`, que la leçon 11 a compilé dans `GaKeysMain`. Le parseur d'accords de `main` diffère de celui du commit épinglé, mais seulement pour des chiffrages que cette leçon n'utilise pas : `M` et `Maj7`, `o`, `sus`, `omit` et `no`, et le texte qui reste après le chiffrage. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l13
```

## Ce qu'on montre au modèle

Les outils DSL du chatbot n'exposent que les closures de la catégorie Domain ([`DslEvalMcpTools.cs` ligne 70](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L70)). Le programme pose à `ga_dsl_list_closures` et à `ga_dsl_get_closure_schema` les questions qu'un modèle leur poserait :

```text
== What ga_dsl_list_closures and ga_dsl_get_closure_schema show the model
15 closures listed, among them domain.analyzeProgression (Domain): Infer the key of a progression and label each chord with a Roman numeral.
input  chords: string — space-separated chord symbols
output string (formatted key + Roman numeral analysis)
```

Un modèle peut appeler la closure par `ga_dsl_eval`, comme les trois skills de la [leçon 10](../10-what-the-model-is-told-to-trust/) appellent les leurs. Aucun SKILL.md ne le lui demande. La réponse tient en trois lignes : la tonalité avec un indice de confiance, les chiffrages, les chiffres romains. Les deux outils de GaMcpServer la découpent par ligne puis par espace pour en extraire la tonalité et les chiffres romains ([`GuitaristProblemTools.cs` lignes 276-293](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/GaMcpServer/Tools/GuitaristProblemTools.cs#L276-L293)).

## Comment le commit épinglé trouve la tonalité

Au commit épinglé, la closure attribue un score à chacune des 24 tonalités majeures et mineures ([`DomainClosures.fs` lignes 268-276](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L268-L276) et [308-316](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L308-L316)) :

```fsharp
let private scoreKey rootPc (offsets: int[]) (chordPcs: int list) =
    let diatonic = offsets |> Array.map (fun o -> (rootPc + o) % 12) |> Set.ofArray
    chordPcs |> List.filter diatonic.Contains |> List.length

let private romanFor rootPc (offsets: int[]) (romans: string[]) chordPc =
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i -> romans.[i])
    |> Option.defaultValue "?"
```

```fsharp
                      // Score every major and minor key.
                      // Tiebreaker: prefer the key whose root matches the first chord.
                      let firstPc = validPcs |> List.tryHead |> Option.defaultValue 0
                      let keyRootPc, scaleName =
                          [ for rpc in 0..11 do
                              yield rpc, "major", scoreKey rpc majorOffsets validPcs
                              yield rpc, "minor", scoreKey rpc minorOffsets validPcs ]
                          |> List.maxBy (fun (rpc, _, s) -> s * 2 + (if rpc = firstPc then 1 else 0))
                          |> fun (rpc, scale, _) -> rpc, scale
```

`scoreKey` compte les accords dont la fondamentale appartient à la gamme de la tonalité : la qualité de l'accord n'est jamais lue. Une tonalité dont la tonique est la fondamentale du premier accord reçoit un point de plus ; entre scores égaux, `List.maxBy` garde le premier, et la liste place, pour chaque tonique, la tonalité majeure avant la mineure. `romanFor` donne ensuite le chiffre romain du degré d'après la table de la tonalité, quel que soit l'accord ([lignes 257-260](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L257-L260)) : en C majeur, D et Dm sont tous deux `ii`. Le nom de la tonalité vient de la classe de hauteurs de sa tonique, avec le nom à bémol pour les classes de hauteurs 1, 3, 8 et 10, et sinon une note naturelle ou F♯ ([lignes 262-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L262-L266)), quelle que soit l'écriture de la question.

## Les quatre exemples du brouillon

Le brouillon donne quatre questions, avec la réponse que l'outil devrait renvoyer ([`DRAFT.md` lignes 51-54](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L51-L54)) :

```text
== The four examples of skills-dev/_pending-tools/progression-analysis/DRAFT.md
"C Am F G": the draft expects C major, I vi IV V
  a826864  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
  6baf32e  Key: C major  (confidence 4/4)
           C      Am     F      G
           I      vi     IV     V
"Dm7 G7 Cmaj7": the draft expects C major, ii V I
  a826864  Key: D minor  (confidence 3/3)
           Dm7    G7     Cmaj7
           i      iv     VII
  6baf32e  Key: C major  (confidence 3/3)
           Dm7    G7     Cmaj7
           ii     V      I
"D A Bm G": the draft expects D major, I V vi IV
  a826864  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
  6baf32e  Key: D major  (confidence 4/4)
           D      A      Bm     G
           I      V      vi     IV
"Fm Bbm C7 Fm": the draft expects F minor, i iv V i
  a826864  Key: F major  (confidence 4/4)
           Fm     Bbm    C7     Fm
           I      IV     V      I
  6baf32e  Key: F minor  (confidence 4/4)
           Fm     Bbm    C7     Fm
           i      iv     V      i
```

Au commit épinglé, deux réponses sur quatre sont justes. Dm7 G7 Cmaj7, le ii–V–I du jazz, ressort en D mineur, `i iv VII` : D, G et C appartiennent tous à D mineur, et D est le premier accord. Fm Bbm C7 Fm ressort en F majeur, `I IV V I` : F, B♭ et C appartiennent à F majeur comme à F mineur, et l'égalité revient à la tonalité majeure. Sur `main`, les quatre concordent avec le brouillon. Le quatrième exemple passe `assumeKey="F minor"`, un paramètre que la closure n'a pas ; `main` trouve F mineur sans lui.

## Huit progressions de manuel dans trente tonalités

Le programme écrit chaque progression dans les 15 tonalités majeures ou les 15 tonalités mineures, comme l'écrit un manuel ; vii°7 se construit sur la sensible, le septième degré haussé : C♯ en D mineur, F𝄪, écrit `F##`, en G♯ mineur. Il compare la tonalité et les chiffres romains à ceux du manuel, les chiffres sans l'indication de septième : ii7 V7 Imaj7 se lit ii V I, et iiø7 V7 i se lit iiø V i.

```text
== Eight textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I IV V I      6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
IV V I        a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
IV V I        6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
I vi IV V     a826864  e  e  =  =  =  =  =  =  =  =  =  =  =  =  e
I vi IV V     6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =
ii7 V7 Imaj7  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
ii7 V7 Imaj7  6baf32e  e  e  e  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv V i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv v i      a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv v i      6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
iiø7 V7 i     a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
iiø7 V7 i     6baf32e  =  e  e  =  =  =  =  =  =  =  =  =  e  =  =
i iv vii°7 i  a826864  x  x  x  x  x  x  x  x  x  x  x  x  x  x  x
i iv vii°7 i  6baf32e  n  n  n  n  n  n  n  n  n  n  n  n  n  n  n

= the textbook key, spelled as the question, and the textbook numerals; e the same key under its
enharmonic name, the textbook numerals; n the key, other numerals; x another key
a826864: 120 questions, = 24, e 6, n 0, x 90; confidence below the chord count: none
6baf32e: 120 questions, = 84, e 21, n 15, x 0; confidence below the chord count: iiø7 V7 i in 15 keys, i iv vii°7 i in 12 keys
```

- **`x`, le commit épinglé, 90 sur 120.** IV V I reçoit la tonalité de IV, où les trois accords sont I ii V, et ii7 V7 Imaj7 la tonalité mineure de ii. Aucune progression mineure ne reçoit sa tonalité : i iv V i, i iv v i et i iv vii°7 i reçoivent le majeur homonyme, dont la gamme contient les mêmes fondamentales, et iiø7 V7 i la tonalité mineure de ii, son premier accord. Sur `main`, où la tonalité vient de `KeyIdentificationService`, la grille n'a aucun `x`.
- **`e`, la tonalité sous son nom enharmonique.** Au commit épinglé, C♭, G♭ et C♯ majeur reviennent en B, F♯ et D♭ majeur, par la table des classes de hauteurs ; les autres lignes y ont un `x`. Sur `main`, le nom est celui que `Identify` place en premier, et les tonalités qui ont les mêmes classes de hauteurs sont triées par nom ([`KeyIdentificationService.cs` lignes 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)) : C♭, G♭ et D♭ majeur deviennent B, F♯ et C♯ majeur, et E♭, B♭ et G♯ mineur deviennent D♯, A♯ et A♭ mineur. Cela fait six des 30 tonalités, dans chaque ligne sauf la dernière, où les chiffres romains diffèrent déjà. La cause est celle de [#772](https://github.com/GuitarAlchemist/ga/issues/772), rencontrée dans la leçon 11.
- **`n`, `main`, i iv vii°7 i dans les 15 tonalités mineures.** La tonalité est juste, les chiffres romains sont `i iv ? i`.
- **La confiance.** Au commit épinglé, elle compte des fondamentales et elle est maximale dans les 120 questions. Sur `main`, elle est inférieure au nombre d'accords pour iiø7 V7 i dans les 15 tonalités mineures et pour i iv vii°7 i dans 12. La section suivante explique pourquoi.

```text
Bb major, IV V I: "Eb F Bb"
  a826864  Key: Eb major (3/3), I ii V
  6baf32e  Key: Bb major (3/3), IV V I
Gb major, ii7 V7 Imaj7: "Abm7 Db7 Gbmaj7"
  a826864  Key: Ab minor (3/3), i iv VII
  6baf32e  Key: F# major (3/3), ii V I
G# minor, i iv v i: "G#m C#m D#m G#m"
  a826864  Key: Ab major (4/4), I IV V I
  6baf32e  Key: Ab minor (4/4), i iv v i
D minor, i iv vii°7 i: "Dm Gm C#dim7 Dm"
  a826864  Key: D major (4/4), I IV vii° I
  6baf32e  Key: D minor (3/4), i iv ? i
```

## Les accords hors de la gamme naturelle

Sur `main`, `romanFor` cherche la fondamentale de l'accord parmi les sept notes de la gamme naturelle de la tonalité, puis tire de l'accord la casse et le signe ([`DomainClosures.fs` lignes 353-374 au commit `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L353-L374)) :

```fsharp
/// Roman numeral of a chord in a key: the degree comes from the scale, the case and sign from the
/// chord itself, so E7 in A minor is V (harmonic minor), not the natural-minor v.
let private romanFor rootPc (offsets: int[]) (ast: ChordAst) =
    let chordPc = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
    // Bm7b5 parses as a minor quality with a flat fifth; the -7b5 spelling as one extension.
    let halfDiminished =
        ast.Components
        |> List.exists (function
            | Extension "m7b5" -> true
            | Alteration (Flat, "5") -> ast.Quality = Some Minor
            | _ -> false)
    offsets
    |> Array.tryFindIndex (fun o -> (rootPc + o) % 12 = chordPc)
    |> Option.map (fun i ->
        let digits = romanDigits.[i]
        match ast.Quality with
        | _ when halfDiminished -> digits.ToLowerInvariant() + "ø"
        | Some Minor -> digits.ToLowerInvariant()
        | Some Diminished -> digits.ToLowerInvariant() + "°"
        | Some Augmented -> digits + "+"
        | _ -> digits)
    |> Option.defaultValue "?"
```

E7 est `V` en A mineur parce que E est le cinquième degré de A mineur naturel. La sensible, G♯, n'y occupe aucun degré : G♯dim7 reçoit donc `?`. Dans une tonalité majeure, trois des accords empruntés au mineur homonyme, bIII, bVI et bVII, se trouvent un demi-ton sous un degré : E♭ sous E, A♭ sous A, B♭ sous B. Le programme pose six questions qu'un manuel lit en C majeur ou en A mineur :

```text
== Chords borrowed from the parallel minor, and the harmonic minor's V and vii°
"C Ab G C": the textbook reads C major, I bVI V I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     G      C
           i      VI     v      i
  6baf32e  Key: C major  (confidence 3/4)
           C      Ab     G      C
           I      ?      V      I
"C Eb F C": the textbook reads C major, I bIII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Eb     F      C
           i      III    iv     i
  6baf32e  Key: C major  (confidence 3/4)
           C      Eb     F      C
           I      ?      IV     I
"C Bb F C": the textbook reads C major, I bVII IV I
  a826864  Key: C minor  (confidence 4/4)
           C      Bb     F      C
           i      VII    iv     i
  6baf32e  Key: F major  (confidence 4/4)
           C      Bb     F      C
           V      IV     I      V
"C Ab Bb C": the textbook reads C major, I bVI bVII I
  a826864  Key: C minor  (confidence 4/4)
           C      Ab     Bb     C
           i      VI     VII    i
  6baf32e  Key: Eb major  (confidence 2/4)
           C      Ab     Bb     C
           VI     IV     V      VI
"Am G#dim7 Am": the textbook reads A minor, i vii° i
  a826864  Key: A major  (confidence 3/3)
           Am     G#dim7 Am
           I      vii°   I
  6baf32e  Key: A minor  (confidence 2/3)
           Am     G#dim7 Am
           i      ?      i
"Bm7b5 E7 Am": the textbook reads A minor, iiø V i
  a826864  Key: B minor  (confidence 3/3)
           Bm7b5  E7     Am
           i      iv     VII
  6baf32e  Key: A minor  (confidence 2/3)
           Bm7b5  E7     Am
           iiø    V      i
KeyIdentificationService.Identify on main, "C Bb F C": F major 3/3, D minor 3/3, C major 2/3
KeyIdentificationService.Identify on main, "C Ab Bb C": Eb major 2/3, F major 2/3, C minor 2/3
KeyIdentificationService.IsChordDiatonic("A minor", ...) on main: Am yes, Bdim yes, Bm7b5 no, E yes, E7 yes, G#dim7 no
KeyIdentificationService.IsChordDiatonic("G# minor", ...) on main: G#m yes, D#7 yes, F# yes, F##dim7 yes
```

- **C Ab G C et C Eb F C.** `main` trouve C majeur et écrit `?` là où un manuel écrit bVI et bIII. Le commit épinglé trouve C mineur, où A♭ et E♭ sont VI et III, et appelle `i` l'accord de C majeur.
- **C Bb F C et C Ab Bb C.** `main` déplace la tonalité. `Identify` trie par le décompte des accords distincts diatoniques dans la tonalité, plus le poids de cadence ; il place ensuite en premier la tonalité dont la triade de tonique ouvre la progression, puis la tonalité majeure, puis le nom ([lignes 224-227](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L224-L227)). C, B♭ et F sont tous diatoniques en F majeur et en D mineur, contre deux en C majeur ; aucune des deux tonalités ne s'ouvre sur sa triade de tonique, et F majeur est la tonalité majeure : l'analyse donne F majeur, `V IV I V`. Dans C Ab Bb C, E♭ majeur, F majeur et C mineur comptent deux accords, C majeur un seul, C ; E♭ majeur est une tonalité majeure et passe avant F par le nom : l'analyse donne E♭ majeur, `VI IV V VI`, alors que le sixième degré de E♭ majeur porte C mineur, et non C majeur. La confiance, 2/4, en est le seul indice.
- **La confiance compte ce qu'accepte `IsChordDiatonic`** ([`DomainClosures.fs` lignes 421-424 au commit `6baf32e`](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L421-L424)). Cette méthode accepte le V et le V7 majeurs d'une tonalité mineure ([`KeyIdentificationService.cs` lignes 261-267](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L261-L267)), mais `NormalizeChord` coupe un chiffrage à son premier chiffre ([ligne 319](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L319)) : Bm7b5 devient Bm, une triade mineure, alors que le ii de A mineur est B diminué. Le service lit une fondamentale à une seule altération ([ligne 132](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L132)) et tient pour majeure toute qualité qu'il ne connaît pas ([lignes 145-150](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L145-L150)). `F##dim7` devient donc F♯ majeur, le VII du mineur naturel en G♯ mineur, et compte : pour i iv vii°7 i, la confiance est maximale en G♯, D♯ et A♯ mineur, dont la sensible prend un double dièse.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Savoir si un modèle appelle `domain.analyzeProgression` par `ga_dsl_eval`, et ce qu'il écrit à partir des trois lignes, demande le modèle (*à vérifier*).
- **La closure de `main` tourne hors de `main`.** Elle est compilée contre le DSL épinglé et contre le service de `main`, lui-même compilé contre le domaine épinglé, comme dans la leçon 11. Si le parseur de `main` lit les chiffrages de la leçon de la même façon, c'est la lecture de son diff qui le dit, pas une exécution.
- **Le brouillon demande davantage.** Les fonctions, les cadences, les modulations et les accords étrangers à la tonalité ([`DRAFT.md` lignes 44-47](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills-dev/_pending-tools/progression-analysis/DRAFT.md#L44-L47)) ne figurent pas dans la réponse de la closure.
- **Huit progressions de manuel et six questions sur des accords d'emprunt**, sans renversements, ni accords à basse imposée, ni dominantes secondaires, ni modulations.

## Signalé en amont

- Non signalés en amont au moment de l'écriture de cette leçon : les chiffres romains absents pour le vii° d'une tonalité mineure et pour les accords empruntés au mineur homonyme, la tonalité déplacée par des accords d'emprunt, et la confiance qui compte un ii demi-diminué comme étranger à la tonalité. Les tonalités nommées par leur orthographe enharmonique sur `main` ont la même cause que [#772](https://github.com/GuitarAlchemist/ga/issues/772). La tonalité et les chiffres romains que le commit épinglé tire des seules fondamentales sont corrigés sur `main` par [#625](https://github.com/GuitarAlchemist/ga/pull/625) et `6baf32e`. Tous sont listés dans le [journal](../journal/).

## Exercices

1. Au commit épinglé, Am Dm E Am ressort en A majeur. Calcule la valeur que compare `List.maxBy` pour A majeur et pour A mineur, et explique pourquoi A majeur l'emporte.
2. Étends le `romanFor` de `main` pour que, dans une tonalité majeure, une fondamentale située un demi-ton sous le troisième, le sixième ou le septième degré reçoive un bémol et le chiffre romain de ce degré, et que, dans une tonalité mineure, le septième degré haussé reçoive `vii`. Qu'écrit-il pour les six questions de la dernière section ?
3. Suppose que `Identify` place en premier, avant le décompte, la tonalité dont la triade de tonique à la fois ouvre et ferme la progression. Quelles lignes de la grille changeraient sur `main`, et que recevraient C Bb F C et C Ab Bb C ?
4. Le commit épinglé nomme les tonalités par classe de hauteurs. Lesquelles des 15 tonalités mineures du manuel écrit-il autrement ?

<details>
<summary>Solutions</summary>

1. Les fondamentales sont A, D, E et A : toutes les quatre appartiennent à la gamme de A majeur comme à celle de A mineur, et les deux tonalités ont donc un score de 4. A est la fondamentale du premier accord : les deux reçoivent donc 4 × 2 + 1 = 9. `List.maxBy` garde le premier des éléments à égalité, et la liste donne A majeur avant A mineur. Résolu à la main à partir des lignes 308-316.
2. C Ab G C : `I bVI V I`. C Eb F C : `I bIII IV I`. Am G#dim7 Am : `i vii° i`. Bm7b5 E7 Am reste `iiø V i`. C Bb F C et C Ab Bb C ne changent pas, `V IV I V` en F majeur et `VI IV V VI` en E♭ majeur : la règle étiquette les accords, mais ne choisit pas la tonalité. Résolu à la main.
3. Aucune : les lignes dont la progression s'ouvre et se ferme sur la même triade de tonique, I IV V I, i iv V i, i iv v i et i iv vii°7 i, reçoivent déjà leur tonalité, et les autres ne finissent pas sur l'accord qui les ouvre. C Bb F C et C Ab Bb C recevraient C majeur, `I ? IV I` et `I ? ? I` avec le `romanFor` de `main`, `I bVII IV I` et `I bVI bVII I` avec celui de l'exercice 2. Résolu à la main.
4. Quatre : C♯ mineur s'écrit D♭ mineur, une tonalité à huit bémols, D♯ mineur E♭ mineur, G♯ mineur A♭ mineur et A♯ mineur B♭ mineur. La table donne un bémol aux classes de hauteurs 1, 3, 8 et 10, quel que soit le mode. Résolu à la main à partir des lignes 262-266.

</details>

## À retenir

- Une closure qui existe répond avant le skill : le brouillon attend un outil, alors que `ga_dsl_eval` liste et exécute déjà la closure.
- Une tonalité lue sur les seules fondamentales ne distingue pas une tonalité de son homonyme : le commit épinglé donnait A majeur à Am Dm E Am.
- Les exemples d'un brouillon sont un test tout prêt : deux sur quatre échouent au commit épinglé, les quatre passent sur `main`.
- Une table de chiffres romains indexée sur la gamme naturelle n'a de place ni pour la sensible du mineur harmonique ni pour les accords d'emprunt.
- Classer les tonalités d'abord par décompte laisse des accords d'emprunt éloigner la tonalité de l'accord sur lequel la progression s'ouvre et se ferme.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `GaMcpServer/Tools/GaDslTool.cs`, `GaMcpServer/Tools/GuitaristProblemTools.cs`, `Apps/GaCli/Program.fs`, `skills-dev/_pending-tools/progression-analysis/DRAFT.md`.
- GA au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), daté du 2026-09-25 en UTC : `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs` et `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilés par le cours. La PR de GA [#625](https://github.com/GuitarAlchemist/ga/pull/625). Le `main` de GA au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), daté du 2026-09-30 en UTC, pour la comparaison.
- *Open Music Theory*, les chapitres sur les chiffres romains, le septième degré haussé de la gamme mineure et l'emprunt au mode homonyme.
