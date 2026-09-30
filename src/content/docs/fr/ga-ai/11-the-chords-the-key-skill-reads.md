---
title: "Leçon 11 : les accords que lit le skill des tonalités"
description: "Le skill des tonalités de Guitar Alchemist extrait les chiffrages d'accords de la question avec une seule expression régulière, attribue un score aux 30 tonalités et donne au modèle celles qui sont à égalité en tête. Le cours demande la tonalité de six progressions de manuel dans les 30 tonalités, avec le service épinglé et avec celui du main de GA : le commit épinglé ne lit aucun accord de septième, les deux versions lisent F♯ comme F, main répond C♯ majeur pour D♭ G♭ A♭ D♭, et C D G C ressort en G majeur."
sidebar:
  label: 11. Les accords que lit le skill des tonalités
  order: 11
---

La [leçon 10](../10-what-the-model-is-told-to-trust/) appelait l'outil auquel un modèle a pour consigne de se fier. Le skill des tonalités va plus loin : la réponse est calculée avant même que le modèle voie la question. [`KeyIdentificationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs) attribue un score aux tonalités, puis demande au modèle d'expliquer le résultat, avec la consigne « Use ONLY the data below — do not guess or add your own analysis » (n'utiliser que les données fournies, sans rien deviner ni ajouter d'analyse personnelle ; [ligne 97](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L97)). L'autre point d'entrée pour « what key is … », le [SKILL.md de key-identification](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md), demande au modèle d'appeler l'outil `ga_key_identify` et de ne pas analyser la progression lui-même. Les deux suivent les mêmes étapes. Le `ExtractChords` de [`KeyIdentificationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs) extrait les chiffrages d'accords de la question, et son `Identify` attribue un score aux 30 tonalités majeures et mineures ; puis l'outil, comme le skill, garde comme groupe de tête les tonalités dont le décompte égale celui de la première, suivies d'au plus trois correspondances partielles. Ce que produisent ces étapes, c'est ce que le modèle a pour consigne de dire, et le programme les exécute sans modèle.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui en nomment un autre. La détection de la tonalité a changé depuis sur le `main` de GA. [#625](https://github.com/GuitarAlchemist/ga/pull/625), fusionnée le 2026-09-24, a déplacé le service dans `GA.Domain.Services`, étendu son expression régulière aux accords de septième, compté les septièmes de dominante et ajouté un poids pour la cadence finale. [#729](https://github.com/GuitarAlchemist/ga/pull/729), commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), a changé la façon de départager les égalités, à la suite de la [leçon 7 du cours de théorie musicale](../../music-theory-ga/07-cadences-and-progressions/), qui avait testé les outils du serveur MCP de GA. Ces outils ne prennent que les accords ; cette leçon pose la question du chatbot, une phrase dont il faut extraire les accords. Sur `main` au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26) (2026-09-30), le service est toujours tel que `6baf32e` l'a laissé, le SKILL.md est inchangé, et l'outil et le skill ne diffèrent du commit épinglé que par une ligne `using` et, dans le skill, par un indicateur qui marque un refus. `fetch-ga.sh` récupère le service à `6baf32e`, et le projet [`GaKeysMain`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaKeysMain/GaKeysMain.csproj) le compile contre le domaine épinglé, dont `Key.Items` et `Key.Notes` sont inchangés sur `main`. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l11
```

## Ce qu'on donne au modèle

L'outil garde les tonalités dont le décompte égale celui de la première, puis les trois suivantes ([`KeyIdentificationMcpTools.cs` lignes 66-75](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs#L66-L75)) :

```csharp
        var topScore = candidates[0].MatchCount;
        var topTied  = candidates
            .Where(c => c.MatchCount == topScore)
            .Select(ToCandidate)
            .ToArray();
        var partial  = candidates
            .Skip(topTied.Length)
            .Take(MaxPartialCandidates)
            .Select(ToCandidate)
            .ToArray();
```

`KeyIdentificationSkill` construit le même groupe de tête ([lignes 62-63](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L62-L63)) et l'écrit dans le prompt du modèle sous « TOP MATCHES (all tied at the highest score) », les meilleures correspondances, toutes à égalité au score le plus haut, puis les trois tonalités qui viennent ensuite sous « PARTIAL MATCHES », les correspondances partielles ([lignes 100-114](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs#L100-L114)). [`Lesson11.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson11.cs) appelle `ExtractChords` et `Identify` des deux versions et applique ces lignes à leurs résultats. Pour la version épinglée, il appelle aussi `ga_key_identify` lui-même, `KeyIdentificationMcpTools.IdentifyKey`, et s'arrête si l'outil lit d'autres accords ou renvoie d'autres tonalités :

```text
== The pinned answers, checked against ga_key_identify
99 questions: KeyIdentificationMcpTools.IdentifyKey read the same chords and returned the same keys
```

Le manuel, lui, tient en quelques phrases. Une progression construite sur la gamme d'une tonalité est dans cette tonalité. Une tonalité et sa relative partagent leurs sept triades : les triades seules ne distinguent donc pas C majeur de A mineur ; le premier accord et la fin, si. Le cours regarde la première tonalité du groupe de tête, et si la tonalité du manuel en fait partie.

## Les exemples du skill lui-même

Les sept prompts d'exemple de `KeyIdentificationSkill`, et les progressions des deux exemples du SKILL.md :

```text
== The key skill's example prompts: the chords read, and the keys tied at the top
"What key is C Am F G in?"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
"Identify the key of Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"What key does Am F G E sound like?"
  a826864  reads Am F G E       3/4: A minor, C major
  6baf32e  reads Am F G E       3/4: A minor, C major
"Tell me the key of these chords: G D Em C"
  a826864  reads G D Em C       4/4: E minor, G major
  6baf32e  reads G D Em C       4/4: G major, E minor
"Find the tonic of A E F#m D"
  a826864  reads A E F#m D      4/4: A major, F# minor
  6baf32e  reads A E F#m D      4/4: A major, F# minor
"What's the tonic of these chords: C F G C"
  a826864  reads C F G          3/3: A minor, C major
  6baf32e  reads C F G          3/3: C major, A minor
"Identify the tonic of this progression: D A Bm G"
  a826864  reads D A Bm G       4/4: B minor, D major
  6baf32e  reads D A Bm G       4/4: D major, B minor
"Dm G C"
  a826864  reads Dm G C         3/3: A minor, C major
  6baf32e  reads Dm G C         3/3: C major, A minor
"C Am F G"
  a826864  reads C Am F G       4/4: A minor, C major
  6baf32e  reads C Am F G       4/4: C major, A minor
```

Au commit épinglé, chaque exemple met à égalité une tonalité et sa relative, et l'égalité est triée par nom ([ligne 178](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L178)) : A mineur passe avant C majeur, E mineur avant G majeur, B mineur avant D majeur. Le premier exemple du SKILL.md dit « The progression `Dm G C` is in **C major** (3/3 chords diatonic) » ([ligne 60](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L60)) ; l'outil renvoie C majeur et A mineur, et quand le groupe de tête compte plus d'un candidat, le SKILL.md demande au modèle de nommer les deux ([ligne 64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L64)). Sur `main`, C majeur passe en premier parce que Dm G C se termine par G C, un V–I de C majeur, et que le poids de cadence ajoute 2 ; A mineur reste dans le groupe de tête, parce que l'outil regroupe les tonalités par décompte et que celui de A mineur vaut aussi 3. Dans les autres exemples, `main` tranche une égalité en faveur de la tonalité dont la triade de tonique ouvre la progression, puis de la tonalité majeure. Dans « Am F G E », aucune des deux versions ne compte le E dans A mineur : le service compare avec les triades du mineur naturel ([lignes 40-45](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L40-L45)), dont la triade sur le cinquième degré est E mineur.

## La lecture des accords

Le programme place chaque chiffrage dans « What key is X in? » et affiche ce que renvoie `ExtractChords`. Après la lecture de chaque version, une colonne donne la qualité que le parseur privé du service attribue à chaque accord lu ; le programme appelle ce parseur par réflexion.

```text
== What each version reads in "What key is X in?", and what each chord counts as
X        a826864 reads  counts as      6baf32e reads  counts as
C        C              major          C              major
Cm       Cm             minor          Cm             minor
Cdim     Cdim           diminished     Cdim           diminished
Caug     Caug           major          Caug           major
C+       C              major          C              major
C°       C              major          C              major
Cmin     nothing        -              Cmin           minor
C#       C              major          C              major
C#m      C#m            minor          C#m            minor
Db       Db             major          Db             major
F#       F              major          F              major
F#7      F#             major          F#7            dominant
B♭       B              major          B              major
F♯       F              major          F              major
C7       nothing        -              C7             dominant
Cm7      nothing        -              Cm7            minor
Cmaj7    nothing        -              Cmaj7          major
CM7      nothing        -              nothing        -
CΔ7      nothing        -              nothing        -
Cm7b5    nothing        -              Cm7b5          minor
Cø7      nothing        -              nothing        -
Cdim7    nothing        -              Cdim7          diminished
C6       nothing        -              C6             major
C9       nothing        -              C9             major
Csus4    nothing        -              Csus4          major
Cadd9    nothing        -              Cadd9          major
C7#9     nothing        -              C7#9           dominant
C/E      C E            major major    C E            major major
```

Au commit épinglé, l'expression régulière est ([ligne 211](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L211)) :

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(m|dim|aug|maj)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

`\b` correspond à la limite entre un caractère de mot (une lettre, un chiffre ou `_`) et tout autre caractère. Dans `Am7`, `m` et `7` sont tous deux des caractères de mot : le `\b` final échoue donc après `m` ; sans le `m`, il échoue après `A`, et l'accord est ignoré. Tout chiffrage où un chiffre suit directement une lettre est ignoré de la même façon : `C7`, `Cm7`, `Cmaj7`, `Cm7b5`, `C6`. De même pour une qualité que le groupe ne liste pas, `sus` dans `Csus4` ou `add` dans `Cadd9`, avec ou sans chiffre. Le SKILL.md dit que l'outil « doesn't distinguish a `Cmaj7` from a `C` for the purposes of key fitting » : pour trouver la tonalité, il ne ferait pas la différence entre les deux ([ligne 81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/key-identification/SKILL.md#L81)). Au commit épinglé, il ne lit pas `Cmaj7` du tout. Dans `F#` suivi d'une espace, le `#` et l'espace ne sont ni l'un ni l'autre des caractères de mot : le `\b` final échoue donc après `#` ; l'expression rend le `#` et reconnaît `F`. `F#m` garde son dièse parce que `m` est une lettre ; `F#7` le garde parce que `7` est un chiffre, et perd le `7`, puisque l'expression s'arrête au dièse. C'est la cause de [#757](https://github.com/GuitarAlchemist/ga/issues/757) dans le skill d'improvisation et de [#767](https://github.com/GuitarAlchemist/ga/issues/767) dans le skill des intervalles, ici dans une troisième expression. `B♭` et `F♯` utilisent les signes musicaux, que `[b#]` n'inclut pas. `C°` est lu `C`, et compte comme une triade majeure. `C/E` devient deux accords.

Sur `main`, `Cm7b5` est lu et compte comme mineur : le parseur supprime tout à partir du premier chiffre ([lignes 316-321](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L316-L321)), et il reste `Cm`. La triade d'une septième demi-diminuée est diminuée. Le parseur du commit épinglé fait de même ([lignes 205-209](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L205-L209)), mais son expression ne lui transmet jamais ce chiffrage.

Sur `main`, l'expression accepte des chiffres et des altérations après la qualité ([ligne 325](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L325)) :

```csharp
    [GeneratedRegex(@"\b[A-G][b#]?(?:maj|Maj|min|m|dim|aug|sus|add)?\d*(?:b5|#5|b9|#9|#11|b13)?\b", RegexOptions.None)]
    private static partial Regex ChordPattern();
```

Les accords de septième sont lus. `C7` et `C7#9` comptent comme des dominantes, que `Identify` accepte sur le cinquième degré d'une tonalité majeure ou sur le septième d'une tonalité mineure. Le `\b` final est toujours là : `C#` et `F#` reviennent toujours en `C` et `F`, et `CM7`, `CΔ7` et `Cø7` sont toujours ignorés.

## Six progressions dans trente tonalités

Le programme construit six progressions sur la gamme de chaque tonalité qui a au plus sept dièses ou sept bémols, les écrit comme le manuel et demande « What key is … in? ». Trois sont dans les 15 tonalités majeures : I IV V I ; I II V I, où II est une triade majeure, la dominante de la dominante (C D G C) ; et ii7 V7 Imaj7 (Dm7 G7 Cmaj7). Trois sont dans les 15 tonalités mineures : i iv V i, avec le V majeur du mineur harmonique (Am Dm E Am) ; iiø7 V7 i (Bm7b5 E7 Am) ; et i VI III VII (Am F C G).

```text
== "What key is ... in?" for six textbook progressions in the 30 keys

major keys             Cb Gb Db Ab Eb Bb F  C  G  D  A  E  B  F# C#
I IV V I      a826864  ~  ~  ~  =  ~  =  ~  ~  ~  ~  =  ~  r  r  r
I IV V I      6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r
I II V I      a826864  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
I II V I      6baf32e  x  x  x  x  x  x  x  x  x  x  x  r  r  r  r
ii7 V7 Imaj7  a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
ii7 V7 Imaj7  6baf32e  ~  ~  ~  =  =  =  =  =  =  =  =  =  =  =  =

minor keys             Ab Eb Bb F  C  G  D  A  E  B  F# C# G# D# A#
i iv V i      a826864  =  ~  ~  ~  ~  ~  ~  =  ~  r  r  r  r  r  r
i iv V i      6baf32e  =  ~  ~  =  =  =  =  =  =  r  r  r  r  r  r
iiø7 V7 i     a826864  r  r  r  r  r  r  r  r  r  r  r  r  r  r  r
iiø7 V7 i     6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  ~  =  =
i VI III VII  a826864  =  ~  ~  ~  =  ~  =  =  =  =  ~  =  r  r  r
i VI III VII  6baf32e  =  ~  ~  =  =  =  =  =  =  =  =  =  r  r  r

= every chord read as written, the textbook key first; ~ read, the key tied at the top but not first;
x read, the key not among the top; r a chord dropped or read as another chord
a826864: 90 questions, = 12, ~ 21, x 11, r 46; a key after the top with a higher count: 0
6baf32e: 90 questions, = 50, ~ 13, x 11, r 16; a key after the top with a higher count: 2
```

Au commit épinglé, les 30 questions qui ont des accords de septième les perdent tous : il reste le i de iiø7 V7 i et, quand une fondamentale porte un dièse, la fondamentale seule, `F#` pour `F#m7`. 16 autres perdent un dièse : chaque question qui a une triade majeure sur F♯, C♯, G♯, D♯, A♯ ou E♯. Sur les 44 questions lues telles qu'elles sont écrites, 12 reçoivent la tonalité du manuel en premier, 21 la reçoivent parmi les tonalités à égalité en tête, triée par nom après une autre tonalité, et 11 ne la reçoivent pas du tout.

Sur `main`, 50 questions reçoivent la tonalité du manuel en premier. Les 16 qui ont une triade majeure diésée perdent toujours le dièse. Les 13 `~` portent tous sur des tonalités qui partagent leurs sept classes de hauteurs avec une autre tonalité. D♭ majeur a les notes de C♯ majeur, et sa relative B♭ mineur celles de A♯ mineur : les quatre tonalités sont donc à égalité sur le décompte. Pour C♯ majeur comme pour D♭ majeur, la progression s'ouvre sur la tonique, et les deux sont majeures ; la dernière règle, le nom, choisit C♯ majeur : une progression écrite avec cinq bémols reçoit une tonalité à sept dièses. G♭ majeur devient F♯ majeur, C♭ majeur B majeur, E♭ mineur D♯ mineur, B♭ mineur A♯ mineur, et G♯ mineur A♭ mineur. Les 11 `x` sont les mêmes dans les deux versions : I II V I, dans chaque tonalité dont les accords sont lus.

Cinq questions en entier ; pour une question qui répète un accord, le programme donne aussi les accords à l'`Identify` de `main` sous forme de liste, tels qu'ils sont écrits :

```text
Db major, I IV V I: "What key is Db Gb Ab Db in?"
  a826864  reads Db Gb Ab; top 3/3: A# minor, Bb minor, C# major, Db major; then Ab major 2/3, D# minor 2/3, Eb minor 2/3
  6baf32e  reads Db Gb Ab; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
           given Db Gb Ab Db as a list, Identify puts C# major first; top 3/3: C# major, Db major, A# minor, Bb minor; then Ab major 2/3, F# major 2/3, Gb major 2/3
C major, I II V I: "What key is C D G C in?"
  a826864  reads C D G; top 3/3: E minor, G major; then A minor 2/3, B minor 2/3, C major 2/3
  6baf32e  reads C D G; top 3/3: G major, E minor; then C major 2/3, D major 2/3, A minor 2/3
           given C D G C as a list, Identify puts C major first; top 2/3: C major, D major, A minor, B minor; then A minor 2/3, B minor 2/3, A major 1/3
E major, ii7 V7 Imaj7: "What key is F#m7 B7 Emaj7 in?"
  a826864  reads F#; top 1/1: A# minor, Ab minor, B major, Bb minor, C# major, Cb major, D# minor, Db major, Eb minor, F# major, G# minor, Gb major
  6baf32e  reads F#m7 B7 Emaj7; top 3/3: E major, C# minor; then F# minor 2/3, A major 2/3, B major 1/3
F# minor, i iv V i: "What key is F#m Bm C# F#m in?"
  a826864  reads F#m Bm C; top 2/3: A major, B minor, D major, E minor, F# minor, G major; then A minor 1/3, C major 1/3, C# minor 1/3
  6baf32e  reads F#m Bm C; top 2/3: F# minor, A major, D major, G major, B minor, E minor; then C major 1/3, E major 1/3, F major 1/3
           given F#m Bm C# F#m as a list, Identify puts F# minor first; top 2/3: F# minor, A major, D major, B minor; then Ab major 1/3, C# major 1/3, Db major 1/3
B minor, iiø7 V7 i: "What key is C#m7b5 F#7 Bm in?"
  a826864  reads C# F# Bm; top 2/3: A# minor, Bb minor, C# major, D# minor, Db major, Eb minor, F# major, Gb major; then A major 1/3, Ab major 1/3, Ab minor 1/3
  6baf32e  reads C#m7b5 F#7 Bm; top 1/3: B minor, C# minor, D major, E major, G major, E minor; then G# minor 2/3, C# minor 1/3, D major 1/3
```

`ExtractChords` supprime les accords répétés ([ligne 299](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L299)) : le C final de C D G C n'atteint donc jamais `Identify`. Le poids de cadence de #625 regarde les deux derniers accords ([lignes 231-246](https://github.com/GuitarAlchemist/ga/blob/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40/Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs#L231-L246)) :

```csharp
        var tonic = kd.DiatonicTriads[0];
        var last = ordered[^1];
        if (ordered.Count < 2 || last.RootPc != tonic.RootPc || last.Quality != tonic.Quality) return 0;
```

Avec C D G, les deux derniers accords sont D G, un V–I de G majeur : G majeur contient les trois accords et reçoit en plus le poids de cadence. Quand on lui donne les quatre accords, `Identify` place bien C majeur en premier : son décompte vaut 2, puisque D majeur n'est pas une des triades de C majeur, et la cadence ajoute 2. L'outil regroupe alors les tonalités dont le décompte vaut 2 comme « tied at the highest score », à égalité au score le plus haut : C majeur, D majeur, A mineur, B mineur. Les trois suivantes sautent autant de tonalités que le groupe de tête en contient, et non les tonalités qu'il contient : A mineur et B mineur reviennent donc comme correspondances partielles, et G majeur, dont le décompte vaut 3, n'est dans aucune des deux listes. Le même regroupement, sur la question telle que le chatbot la lit, donne à C♯m7b5 F♯7 Bm un groupe de tête de six tonalités à 1/3, avec B mineur en premier, et G♯ mineur à 2/3 parmi les correspondances partielles : on dit au modèle que le groupe de tête a le score le plus haut, et une correspondance partielle a un score plus élevé. Cela arrive deux fois sur les 90 questions.

Les 16 dièses perdus seraient lus avec une seule modification de l'expression de `main` : remplacer le `\b` final par `(?!\w)`, « non suivi d'un caractère de mot ». Vérifié avec le moteur d'expressions régulières de .NET sur les 90 questions : 74 sont lues telles qu'elles sont écrites avec l'expression actuelle, 90 avec l'assertion avant.

## La tonalité relative

Chaque candidat porte sa tonalité relative, et le prompt du skill la montre au modèle :

```text
== The relative key each candidate carries, against the textbook
a826864: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
6baf32e: 30 keys, 6 with another relative key: A# minor → Db major; B major → Ab minor; C# major → Bb minor; D# minor → Gb major; F# major → Eb minor; G# minor → Cb major
```

Le service trouve la tonalité relative par l'ensemble des classes de hauteurs : la première tonalité de l'autre mode qui a les mêmes sept classes de hauteurs ([lignes 93-101](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyIdentificationService.cs#L93-L101)) :

```csharp
        return [.. items.Select(item =>
        {
            var (key, name, pcs, triads, symbols) = item;
            var mask     = pcs.Aggregate(0, (acc, pc) => acc | (1 << pc));
            var sibling  = byMask.GetValueOrDefault(mask)
                               ?.FirstOrDefault(x => x.Mode != key.KeyMode);
            return new DomainKeyData(name, sibling?.Name ?? string.Empty, symbols, pcs, triads);
        })];
```

`Key.Items` liste les tonalités majeures de C♭ à C♯, puis les tonalités mineures de A♭ à A♯ ([`Key.cs` lignes 49-50](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Theory/Tonal/Key.cs#L49-L50)). B majeur a les classes de hauteurs de C♭ majeur, de A♭ mineur et de G♯ mineur, et la première tonalité mineure des quatre est A♭ mineur. Six tonalités reçoivent la relative de leur jumelle enharmonique. Dans la [leçon 9](../09-every-interval-every-key/), `ScaleInfoSkill` se trompait sur les six mêmes, de la même façon ([#769](https://github.com/GuitarAlchemist/ga/issues/769)).

## Ce que lit le modèle

`BuildPrompt` est privée elle aussi ; le programme l'appelle par réflexion avec ce que lui passe `ExecuteAsync`, et affiche la partie données du prompt :

```text
== The data KeyIdentificationSkill puts in the model's prompt for "What key is Db Gb Ab Db in?", at a826864
── TOP MATCHES (all tied at the highest score) ──
• A# minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : A#m, B#dim, C#, D#m, E#m, F#, G#
• Bb minor  (3/3 chords diatonic)
  Relative key : Db major
  Diatonic set : Bbm, Cdim, Db, Ebm, Fm, Gb, Ab
• C# major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : C#, D#m, E#m, F#, G#, A#m, B#dim
• Db major  (3/3 chords diatonic)
  Relative key : Bb minor
  Diatonic set : Db, Ebm, Fm, Gb, Ab, Bbm, Cdim

── PARTIAL MATCHES ──
• Ab major  (2/3 chords diatonic)
• D# minor  (2/3 chords diatonic)
• Eb minor  (2/3 chords diatonic)
```

Les instructions qui suivent demandent au modèle d'expliquer dans quelle tonalité « (or keys) » (ou quelles tonalités) se trouve la progression et, « If two keys tie (e.g. C major and A minor) » (si deux tonalités sont à égalité), comment les distinguer en écoutant la tonique. Ici, quatre tonalités sont à égalité, et ce sont deux tonalités, chacune écrite de deux façons. A♯ mineur vient en premier, avec D♭ majeur pour tonalité relative ; l'ensemble diatonique de C♯ majeur écrit E♯m et B♯dim pour une question écrite en D♭. Sur `main`, la même liste commence par C♯ majeur.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Ce qu'il dit quand quatre tonalités sont « all tied », toutes à égalité, ou quand un dièse a été perdu, demande le modèle (*à vérifier*).
- **Le routage n'est pas testé.** C'est le routage qui décide lequel des deux points d'entrée répond, et il demande le modèle d'embeddings ; les deux calculent la même réponse.
- **Le service de `main` tourne contre le domaine épinglé.** `Key.Items` et `Key.Notes` sont inchangés sur `main` ; le reste du chatbot de `main` n'est pas exécuté.
- **Une seule formulation.** Chaque question est « What key is … in? », avec les accords séparés par des espaces.
- **Des progressions de manuel seulement** : triades et accords de septième à l'état fondamental, sans renversements, ni accords d'emprunt, ni modulations.

## Signalé en amont

- Pas encore signalés en amont au moment de l'écriture de cette leçon : les accords de septième ignorés au commit épinglé et les chiffrages que `main` ignore encore, les dièses perdus, les égalités entre tonalités qui ont les mêmes classes de hauteurs, les accords répétés que supprime `ExtractChords`, le groupe de tête formé par décompte, les tonalités relatives, et l'exemple à un seul candidat du SKILL.md. Ils sont listés dans le [journal](../journal/).

## Exercices

1. Le `\b` final du `ChordPattern` de `main` fait perdre un dièse devant une espace. Remplace-le pour que `F#`, `C#` et `G#` gardent leur dièse, et que `C#m7b5` et `Cmaj7#11` soient toujours lus en entier. Lesquelles des 90 questions changent ?
2. `ExtractChords` retire les accords répétés. Que répondrait `main` pour C D G C s'il les gardait, et que faut-il changer d'autre pour que le modèle reçoive C majeur seul en tête ?
3. Réécris la recherche de la tonalité relative pour que B majeur reçoive G♯ mineur et G♯ mineur B majeur, sans comparer d'ensembles de classes de hauteurs.
4. Pour « What key is Db Gb Ab Db in? », `main` place C♯ majeur en premier. Quelle règle, ajoutée avant le nom, donnerait D♭ majeur, et que donnerait-elle pour « What key is C# F# G# C# in? » ?

<details>
<summary>Solutions</summary>

1. Remplace le `\b` final par `(?!\w)` : après `F#`, le caractère suivant est une espace, qui n'est pas un caractère de mot, et la correspondance garde donc le `#` ; après `Cmaj7#11`, c'est aussi une espace, et l'expression a déjà consommé le `#11`. Les 16 questions `r` de `main` sont alors lues telles qu'elles sont écrites, et les 74 autres lisent les mêmes accords qu'avant. Vérifié avec le moteur d'expressions régulières de .NET sur les 90 questions ; ce que `Identify` répond pour les 16 demande une exécution (*à vérifier*).
2. Avec C D G C, `Identify` place C majeur en premier, avec un décompte de 2 et une cadence de 2. L'outil regrouperait alors les quatre tonalités dont le décompte vaut 2, et laisserait G majeur, dont le décompte vaut 3, hors des deux listes (la deuxième question détaillée plus haut le montre). La sélection doit suivre l'ordre de `Identify` : le service exposerait le score de chaque tonalité, le décompte plus la cadence, et l'outil garderait les tonalités dont le score égale celui de la première, puis les trois tonalités qui les suivent dans l'ordre de `Identify`. C majeur serait seul à 4, suivi de G majeur et de E mineur à 3. Résolu à la main à partir du code.
3. Prends la tonalité relative dans la gamme : la relative mineure d'une tonalité majeure commence sur son sixième degré, et la relative majeure d'une tonalité mineure sur son troisième. Le `Key.Notes` du domaine orthographie correctement ces degrés (leçon 9) : le sixième degré de B majeur est G♯, le troisième de G♯ mineur est B. La recherche devient un nom construit à partir de `key.Notes[5]` ou de `key.Notes[2]` et de l'autre mode, sans aucun ensemble de classes de hauteurs. Résolu à la main ; les six tonalités sont confrontées au manuel dans la sortie ci-dessus.
4. Préfère la tonalité dont la tonique s'écrit comme la fondamentale du premier accord. `OpensOnTonic` compare des classes de hauteurs : D♭ et C♯ passent donc toutes les deux ; en comparant les noms, D♭ majeur passe et C♯ majeur non. Pour C♯ F♯ G♯ C♯, la même règle donne C♯ majeur, mais la question doit d'abord garder ses dièses (exercice 1) : aujourd'hui, elle est lue C F G et reçoit la réponse C majeur. Résolu à la main à partir du code.

</details>

## À retenir

- Quand le modèle a pour consigne de n'utiliser que les données qu'on lui donne, la réponse est décidée avant qu'il tourne, par ce que le skill lit dans la question.
- Une expression régulière qui extrait des accords d'un texte décide de ce qu'entend le skill des tonalités : au commit épinglé, elle ignorait chaque accord de septième, et sur `main`, elle lit toujours F♯ comme F.
- Un `\b` final après `#` échoue devant une espace. Le même bogue se trouve maintenant dans trois expressions du chatbot de GA.
- Retirer les accords répétés ampute la progression de sa fin, et le poids de cadence de `main` entend alors cette fin tronquée comme la cadence : D G dans C D G C.
- Un classement et la sélection qu'on bâtit dessus doivent utiliser le même score : `main` ordonne les tonalités par décompte plus cadence, et l'outil les regroupe toujours par décompte.
- Des tonalités qui ont les mêmes classes de hauteurs ne se distinguent que par l'orthographe de la question. Un ordre par nom choisit C♯ majeur pour D♭.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/KeyIdentificationService.cs`, `Common/GA.Business.ML/Agents/Mcp/KeyIdentificationMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/KeyIdentificationSkill.cs`, `skills/key-identification/SKILL.md`, `Common/GA.Domain.Core/Theory/Tonal/Key.cs`.
- GA au commit [`6baf32e`](https://github.com/GuitarAlchemist/ga/commit/6baf32ed9b35c9b8a1645cb8d6836aafd0713a40), daté du 2026-09-25 en UTC : `Common/GA.Domain.Services/Tonal/KeyIdentificationService.cs`, compilé par le cours. Le `main` de GA au commit [`5c3a52a`](https://github.com/GuitarAlchemist/ga/commit/5c3a52ab40d0d433f8f68dbbd0590f70c8d8cf26), daté du 2026-09-30 en UTC, pour la comparaison du service, de l'outil, du skill et du SKILL.md.
- *Open Music Theory*, les chapitres sur les triades diatoniques, le septième degré haussé de la gamme mineure et les cadences, pour les progressions du manuel.
