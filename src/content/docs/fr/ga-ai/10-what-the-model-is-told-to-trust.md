---
title: "Leçon 10 : ce à quoi le modèle doit se fier"
description: "Les skills Transpose, DiatonicChords et CommonTones de Guitar Alchemist demandent à un modèle d'appeler une closure déterministe par l'outil ga_dsl_eval et de reprendre sa réponse. Le cours appelle cet outil avec les arguments que prescrit chaque SKILL.md et note les closures avec le calcul par lettres d'un manuel : D mineur revient avec un A♯, G7 transposé en E♭ donne D♯7, et le C♯ commun aux accords A et C♯m revient en D♭."
sidebar:
  label: 10. Ce à quoi le modèle doit se fier
  order: 10
---

La [leçon 9](../09-every-interval-every-key/) a testé les skills qui orthographient des notes sans modèle. Trois autres skills, [`TransposeSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/TransposeSkill.cs), [`DiatonicChordsSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs) et [`CommonTonesSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/CommonTonesSkill.cs), confient la question à un modèle, et leurs fichiers SKILL.md lui interdisent de calculer la réponse : il doit appeler une closure par l'outil `ga_dsl_eval` et reprendre ce qu'elle renvoie. Le SKILL.md de diatonic-chords invoque l'orthographe, dans [sa description](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L3) : « since LLMs commonly mis-spell the iv/vii° in less-common keys », parce que les LLM orthographient souvent mal le iv et le vii° dans les tonalités moins courantes. Le cours ne peut pas exécuter le modèle, mais il peut appeler l'outil que le modèle a pour consigne d'appeler, avec les arguments que prescrit le SKILL.md. Ce que répond la closure, c'est ce que dira un modèle qui suit ses instructions.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours. Sur le `main` de GA au commit [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), les trois fichiers SKILL.md, les trois skills et `ga_dsl_eval` sont inchangés. `DomainClosures.fs` y a changé, mais pas dans le code qu'appelle cette leçon : `transposeChord`, `diatonicChords`, les deux tableaux de noms de notes, `preferFlat`, `conventionalKeyName` et la ligne où `commonTones` nomme une note sont identiques, comparés fonction par fonction. Le parseur d'accords y a changé aussi : il refuse maintenant tout ce qui reste après le chiffrage et lit les formes `sus`, `Maj7` avec majuscule et `omit`, dont aucune ne figure dans les chiffrages ci-dessous. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l10
```

## Ce qu'on dit au modèle

On n'atteint les trois skills que par les embeddings du routeur d'intentions : le `CanHandle` de [`SkillMdDrivenWrapperBase`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L85) renvoie `false`. Une fois choisi, un skill passe la question à un modèle, avec son SKILL.md pour instructions ; chacun des trois SKILL.md liste un seul outil sous `allowed-tools`, `ga_dsl_eval`. L'enveloppe vérifie ensuite si le modèle a appelé l'outil ([lignes 111-144](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs#L111-L144)). Si oui, les preuves de la réponse reçoivent `grounding.source: ga.dsl@domain.diatonicChords` (ou la closure du skill), et la confiance du modèle est conservée. Sinon, les preuves indiquent « answer is LLM-only, not deterministic », une réponse du seul LLM, non déterministe, et la confiance est plafonnée à 0.5. Le dispositif fait davantage confiance à la closure qu'au modèle.

Les fichiers SKILL.md disent la même chose en prose. [diatonic-chords](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/diatonic-chords/SKILL.md#L26) : « Do NOT enumerate the chords mentally — the closure handles enharmonic spelling correctly », n'énumère pas les accords de tête, la closure gère correctement l'orthographe enharmonique. [transpose](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L28) : « Do NOT compute the transposition mentally — for less-common keys (Gb major, C# minor) the LLM will confidently flip enharmonics and produce wrong spellings », ne calcule pas la transposition de tête, car dans les tonalités moins courantes le LLM inversera les enharmoniques avec aplomb et produira de fausses graphies. [common-tones](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/common-tones/SKILL.md#L63) : « The closure returns a formatted string already. Surface it verbatim », la closure renvoie déjà une chaîne mise en forme, à restituer telle quelle.

`ga_dsl_eval` est une méthode statique, [`DslEvalMcpTools.EvalClosure`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs#L134-L139). Elle prend un nom de closure et un dictionnaire plat d'arguments sous forme de chaînes, ce qu'envoie le modèle. Au démarrage, le chatbot enregistre les closures avec `GaClosureBootstrap.init()` ([`ChatbotOrchestrationExtensions.cs` ligne 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs#L42)) ; [`Lesson10.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson10.cs) fait de même, puis appelle l'outil :

```csharp
static DslEvalResult Eval(string closure, params (string Key, string Value)[] args) =>
    DslEvalMcpTools.EvalClosure(closure, args.ToDictionary(a => a.Key, a => a.Value));
```

Le manuel est le calcul par lettres de la leçon 9. Les sept triades d'une tonalité se construisent sur sa gamme, une lettre par degré, avec les qualités de la gamme majeure ou mineure naturelle. Une note déplacée d'un intervalle prend la lettre que compte le numéro de l'intervalle, et l'altération qui donne le bon nombre de demi-tons.

## Sept accords, trente tonalités

Le SKILL.md de diatonic-chords donne deux arguments : `root`, la tonique, et `scale`, `major` ou `minor`. Le programme demande les 30 tonalités qui ont au plus sept dièses ou sept bémols, et affiche celles qui diffèrent du manuel :

```text
== ga_dsl_eval "domain.diatonicChords" on the 30 keys with at most seven sharps or flats
Cb major   GA       B Dbm Ebm E Gb Abm Bbdim
           textbook Cb Dbm Ebm Fb Gb Abm Bbdim
Gb major   GA       Gb Abm Bbm B Db Ebm Fdim
           textbook Gb Abm Bbm Cb Db Ebm Fdim
F# major   GA       F# G#m A#m B C# D#m Fdim
           textbook F# G#m A#m B C# D#m E#dim
C# major   GA       C# D#m Fm F# G# A#m Cdim
           textbook C# D#m E#m F# G# A#m B#dim
Ab minor   GA       Abm Bbdim B Dbm Ebm E Gb
           textbook Abm Bbdim Cb Dbm Ebm Fb Gb
Eb minor   GA       Ebm Fdim Gb Abm Bbm B Db
           textbook Ebm Fdim Gb Abm Bbm Cb Db
C minor    GA       Cm Ddim D# Fm Gm G# A#
           textbook Cm Ddim Eb Fm Gm Ab Bb
G minor    GA       Gm Adim A# Cm Dm D# F
           textbook Gm Adim Bb Cm Dm Eb F
D minor    GA       Dm Edim F Gm Am A# C
           textbook Dm Edim F Gm Am Bb C
D# minor   GA       D#m Fdim F# G#m A#m B C#
           textbook D#m E#dim F# G#m A#m B C#
A# minor   GA       A#m Cdim C# D#m Fm F# G#
           textbook A#m B#dim C# D#m E#m F# G#

30 keys: 19 right, 11 with a chord on another letter
```

Chaque accord a la bonne hauteur de fondamentale et la bonne qualité ; 11 tonalités ont au moins un accord sur la mauvaise lettre. La closure calcule la fondamentale de chaque accord comme une classe de hauteurs au-dessus de la tonique, et la nomme d'après l'un de deux tableaux de douze noms ([lignes 22-36](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L22-L36)) :

```fsharp
/// Chromatic note names using sharp spelling.
let private sharpNames = [| "C";"C#";"D";"D#";"E";"F";"F#";"G";"G#";"A";"A#";"B" |]

/// Chromatic note names using flat spelling.
let private flatNames  = [| "C";"Db";"D";"Eb";"E";"F";"Gb";"G";"Ab";"A";"Bb";"B" |]

/// True when the key conventionally uses flat accidentals.
/// F natural is the one exception among white-key roots (it contains Bb).
let private preferFlat (note: string) (acc: AccidentalType) =
    match acc with
    | Flat | DoubleFlat  -> true
    | Sharp | DoubleSharp -> false
    | Natural             -> note = "F"
```

`preferFlat` regarde la tonique, pas la tonalité ([ligne 187](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L187)). F est la seule tonique sans altération d'une tonalité majeure à bémols, mais D, G et C mineur sont aussi des tonalités à bémols sur une tonique sans altération : leurs B♭, E♭ et A♭ deviennent donc A♯, D♯ et G♯. Et un tableau indexé par classe de hauteurs a un nom par classe de hauteurs : il ne peut écrire ni C♭, ni F♭, ni E♯, ni B♯, dont huit tonalités ont besoin. Le quatrième accord de G♭ majeur, C♭, devient B ; le septième de F♯ majeur, E♯dim, devient Fdim.

## Les exemples du SKILL.md

Le SKILL.md montre au modèle ce que renvoie la closure :

```text
== The results diatonic-chords' SKILL.md gives for the closure
C major   GA       ["C","Dm","Em","F","G","Am","Bdim"]
          SKILL.md ["C", "Dm", "Em", "F", "G", "Am", "B°"]
A minor   GA       ["Am","Bdim","C","Dm","Em","F","G"]
          SKILL.md ["Am", "B°", "C", "Dm", "Em", "F", "G"]
Bb major  GA       ["Bb","Cm","Dm","Eb","F","Gm","Adim"]
          SKILL.md ["Bb","Cm","Dm","Eb","F","Gm","A°"]
Gb major  GA       ["Gb","Abm","Bbm","B","Db","Ebm","Fdim"]
          SKILL.md Gb major returns Cm, not B#m
F# minor  GA       ["F#m","G#dim","A","Bm","C#m","D","E"]
          SKILL.md F# minor returns G#°, not Ab°
```

Le SKILL.md écrit la triade diminuée `B°`, et la closure `Bdim`. Le SKILL.md demande au modèle d'utiliser chaque accord « exactly as the closure returned it », exactement tel que la closure l'a renvoyé : cela ne change donc que ce que lit l'utilisateur. Les affirmations sur les tonalités peu courantes ne sont qu'à moitié justes. G♭ majeur n'a pas d'accord de C mineur : son quatrième accord est C♭ majeur, et la closure renvoie B. Le deuxième accord de F♯ mineur est G♯dim, que la closure renvoie bel et bien. La description du skill lui-même fait la même promesse ([`DiatonicChordsSkill.cs` lignes 27-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/DiatonicChordsSkill.cs#L27-L32)) : la closure est appelée « so enharmonic spelling is correct in less-common keys (Gb major, F# minor) », pour que l'orthographe enharmonique soit juste dans les tonalités moins courantes.

## Transposer par demi-tons

Le SKILL.md de transpose donne deux arguments, `symbol` et `semitones`, avec une table de conversion des noms d'intervalles en demi-tons ([ligne 42](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L42) et suivantes) : « up a minor third », une tierce mineure plus haut, vaut 3. La closure ajoute les demi-tons à la classe de hauteurs de la fondamentale et nomme le résultat d'après les deux mêmes tableaux, choisis selon la fondamentale de l'accord lui-même ([lignes 159-162](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L159-L162)) :

```fsharp
                      let rootPc  = (noteToSemitone ast.Root + accToSemitone ast.RootAccidental + 120) % 12
                      let newPc   = (rootPc + semitones % 12 + 12) % 12
                      let naming  = spellingOf (preferFlat ast.Root ast.RootAccidental)
                      let newRoot, newAcc = splitNoteAcc naming.[newPc]
```

Le programme monte chacun des 21 noms de notes de chaque intervalle de la table, de l'unisson à l'octave, sauf le triton, que la table convertit en 6 demi-tons quelle que soit son écriture :

```text
== ga_dsl_eval "domain.transposeChord": the 21 note names up each interval of transpose's SKILL.md but the tritone
. right   ~ right pitch, another letter   d the textbook needs a double sharp or flat   x wrong pitch

note    P1 m2 M2 m3 M3 P4 P5 m6 M6 m7 M7 P8
Cb      ~  d  .  d  .  ~  .  d  .  d  .  ~ 
C       .  ~  .  ~  .  .  .  ~  .  ~  .  . 
C#      .  .  .  .  ~  .  .  .  .  .  ~  . 
Db      .  d  .  ~  .  .  .  d  .  ~  .  . 
D       .  ~  .  .  .  .  .  ~  .  .  .  . 
D#      .  .  ~  .  d  .  .  .  ~  .  d  . 
Eb      .  ~  .  .  .  .  .  ~  .  .  .  . 
E       .  .  .  .  .  .  .  .  .  .  .  . 
E#      ~  .  d  .  d  .  ~  .  d  .  d  ~ 
Fb      ~  d  .  d  .  d  ~  d  .  d  .  ~ 
F       .  .  .  .  .  .  .  .  .  .  .  . 
F#      .  .  .  .  .  .  .  .  .  .  ~  . 
Gb      .  d  .  d  .  ~  .  d  .  ~  .  . 
G       .  ~  .  ~  .  .  .  ~  .  .  .  . 
G#      .  .  .  .  ~  .  .  .  ~  .  d  . 
Ab      .  d  .  ~  .  .  .  ~  .  .  .  . 
A       .  ~  .  .  .  .  .  .  .  .  .  . 
A#      .  .  ~  .  d  .  ~  .  d  .  d  . 
Bb      .  ~  .  .  .  .  .  .  .  .  .  . 
B       .  .  .  .  .  .  .  .  .  .  .  . 
B#      ~  .  d  .  d  ~  d  .  d  .  d  ~ 

252 questions: 182 right, 40 on another letter, 30 where the textbook needs a double accidental, 0 wrong pitch
```

Aucune hauteur n'est fausse ; chaque erreur est une lettre. Même un unisson peut changer de lettre : C♭ déplacé de 0 demi-ton revient en B, et E♯ en F, parce que la closure nomme d'après son tableau la classe de hauteurs, qui n'a pas changé. Le numéro d'un intervalle compte des lettres, un nombre de demi-tons non. Une tierce couvre trois lettres : C une tierce mineure plus haut, c'est donc E♭ (C, D, E) ; une seconde en couvre deux : C une seconde augmentée plus haut, c'est donc D♯ (C, D). Les deux font 3 demi-tons, et la closure répond D♯ parce que C prend le tableau des dièses. La table du SKILL.md a perdu le numéro dont le manuel a besoin avant même que la closure soit appelée. Seuls E, F et B sont justes sur tous les intervalles : tout intervalle au-dessus de E ou de B tombe sur une note naturelle ou diésée, et tout intervalle au-dessus de F sur une note naturelle ou bémolisée. Les cases `d` sont les intervalles dont la réponse du manuel porte un double dièse ou un double bémol (C♭ une seconde mineure plus haut donne D double bémol) ; les tableaux ne savent pas non plus les écrire, et elles sont comptées à part.

## Les exemples du skill lui-même

Les prompts d'exemple de `TransposeSkill`, convertis comme le dit le SKILL.md :

```text
== Transpose's example prompts, with the arguments its SKILL.md maps them to, one call per chord
prompt                                symbol    semitones  GA           textbook
Transpose Cmaj7 up a perfect fourth   Cmaj7             5  Fmaj7        Fmaj7
Move this F chord down a minor third  F                -3  D            D
What's Dm7 up a whole step?           Dm7               2  Em7          Em7
Transpose G7 to Eb                    G7                8  D#7          Eb7
                                      G7               -4  D#7          Eb7
Shift Am7 up a fifth                  Am7               7  Em7          Em7
transpose C-Am-F-G to G major         C Am F G          7  G Em C D     G Em C D
transpose C-Am-F-G to Eb major        C Am F G          3  D# Cm Ab A#  Eb Cm Ab Bb

Bb up a whole step, then back down: C, then A#
```

« Transpose G7 to Eb » est l'un des prompts d'exemple du skill, et il donne D♯7 quelle que soit la façon dont le modèle compte, une sixte mineure vers le haut ou une tierce majeure vers le bas : la closure ne voit jamais E♭, seulement un nombre. La progression transposée en E♭ majeur revient sous la forme D♯ Cm A♭ A♯, la tonalité écrite de deux façons en quatre accords. Pour une progression, le SKILL.md dit d'appeler le skill une fois par accord ou de demander la liste des accords ([ligne 95](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/skills/transpose/SKILL.md#L95)), et quand le skill est appelé une fois par accord, chaque appel choisit son tableau d'après son propre accord. Un B♭ monté d'un ton puis redescendu revient en A♯.

## Les chiffrages renvoyés en entrée

Une conversation peut renvoyer la réponse d'une closure à une closure : le programme vérifie donc que les deux chiffrages de l'accord diminué sont bien lus :

```text
== The chord symbols the closures return, passed back in
B° up a semitone             Cdim
Bdim up a semitone           Cdim
```

Ils le sont tous les deux ; la différence entre le `B°` du SKILL.md et le `Bdim` de la closure s'arrête là.

## Les notes communes

Le SKILL.md de common-tones donne deux arguments, `chord1` et `chord2`. Le programme demande chaque paire de triades de chacune des 30 tonalités, 21 paires par tonalité, avec les accords écrits comme le manuel les écrit, et compare les notes communes renvoyées avec celles que les deux triades partagent dans la gamme de la tonalité :

```text
== ga_dsl_eval "domain.commonTones" on every pair of triads in each of the 30 keys
key        misspelled pairs  the key's note as GA writes it
Cb major   9 of 21           Cb as B, Fb as E, Gb as F#
Gb major   6 of 21           Cb as B, Gb as F#
Db major   3 of 21           Gb as F#
D major    3 of 21           C# as Db
A major    6 of 21           C# as Db, G# as Ab
E major    9 of 21           C# as Db, D# as Eb, G# as Ab
B major    11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
F# major   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
C# major   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab
Ab minor   9 of 21           Cb as B, Fb as E, Gb as F#
Eb minor   6 of 21           Cb as B, Gb as F#
Bb minor   3 of 21           Gb as F#
B minor    3 of 21           C# as Db
F# minor   6 of 21           C# as Db, G# as Ab
C# minor   9 of 21           C# as Db, D# as Eb, G# as Ab
G# minor   11 of 21          A# as Bb, C# as Db, D# as Eb, G# as Ab
D# minor   12 of 21          A# as Bb, C# as Db, D# as Eb, E# as F, G# as Ab
A# minor   13 of 21          A# as Bb, B# as C, C# as Db, D# as Eb, E# as F, G# as Ab

630 pairs: shared notes right 630, spelled as the key spells them 486
```

Les notes communes sont justes dans les 630 paires : la closure fait l'intersection des classes de hauteurs. Elle nomme ensuite chacune d'elles avec `conventionalKeyName` ([lignes 263-266](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L263-L266), appelée à la [ligne 523](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs#L523)), qui ne connaît aucun des deux accords :

```fsharp
let private conventionalKeyName pc =
    match pc with
    | 1 | 3 | 8 | 10 -> flatNames.[pc]   // Db, Eb, Ab, Bb — prefer flat
    | _               -> sharpNames.[pc]  // everything else — prefer sharp / natural
```

C♯ est toujours D♭ et G♯ toujours A♭, tandis que G♭ est toujours F♯. Douze tonalités n'ont aucune paire mal orthographiée, six de chaque mode : celles dont cette règle se trouve nommer les notes comme il faut. D mineur en fait partie, bien que `diatonicChords` écrive son B♭ A♯ ; D majeur non, bien que `diatonicChords` l'orthographie correctement. Trois closures d'un même fichier orthographient les mêmes notes selon trois règles : d'après la tonique, d'après la fondamentale de l'accord, d'après la seule classe de hauteurs.

```text
== Common-tones' SKILL.md example, and a pair from A major
Cmaj7 and Am7
  | Common tones (3):
  |   C (P1 in Cmaj7, m3 in Am7)
  |   E (M3 in Cmaj7, P5 in Am7)
  |   G (P5 in Cmaj7, m7 in Am7)
A and C#m
  | Common tones (2):
  |   Db (M3 in A, P1 in C#m)
  |   E (P5 in A, m3 in C#m)
```

L'exemple du SKILL.md est juste. En A majeur, la fondamentale de C♯m revient sous la forme "Db", et le SKILL.md demande au modèle de la restituer telle quelle.

## Là où GA orthographie déjà juste

Le domaine de GA orthographie correctement les tonalités. Dans la leçon 9, `ScaleInfoSkill` a donné justes les notes des 30 gammes ; il les prend dans le `Key.Notes` du domaine ([`ScaleInfoSkill.cs` ligne 132](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs#L132)). Les closures ne l'appellent pas : elles reconstruisent l'orthographe à partir des classes de hauteurs, et une classe de hauteurs ne porte aucune lettre.

## Où le cours s'arrête

- **Le modèle n'est pas exécuté.** Savoir s'il appelle `ga_dsl_eval`, quels arguments il envoie et s'il change l'orthographe de la réponse contre ses instructions demande le modèle (*à vérifier*). Un modèle qui ignore le SKILL.md pourrait orthographier mieux que la closure.
- **Le routage n'est pas testé.** On n'atteint les trois skills que par les embeddings du routeur.
- **Des triades seulement.** Les accords diatoniques sont des triades ; les notes communes sont testées sur des triades, alors que les accords de septième passent par le même nommage.
- **La transposition est notée par rapport à des intervalles nommés**, ceux de la table, sans le triton. Un utilisateur qui dit « three semitones », trois demi-tons, ne nomme aucune lettre, et n'importe quelle orthographe du résultat se défend.
- **Les closures de `main` ont été comparées, pas exécutées.** Les fonctions qu'appelle cette leçon sont textuellement identiques au commit épinglé et sur `main`.

## Signalé en amont

- Pas encore signalées en amont au moment de l'écriture de cette leçon : l'orthographe de `diatonicChords`, de `transposeChord` et de `commonTones`, et les affirmations du SKILL.md de diatonic-chords. Elles sont listées dans le [journal](../journal/).

## Exercices

1. Réécris le nommage de `diatonicChords` pour que chaque degré reçoive sa propre lettre. Lesquelles des 11 tonalités deviennent justes, et que renvoie la closure pour une tonalité comme G♯ majeur, dont le septième degré est F double dièse ?
2. `transposeChord` prend un nombre de demi-tons. De quoi aurait-elle besoin pour écrire E♭ quand on monte C d'une tierce mineure, et D♯ quand on le monte d'une seconde augmentée, et comment changerait la table du SKILL.md de transpose ?
3. `commonTones` nomme les notes communes sans connaître de tonalité. Quelle orthographe pourrait-elle utiliser qui soit juste dans les 630 paires de cette leçon, toujours sans tonalité ?
4. Un utilisateur demande « Transpose G7 to Eb ». En suivant le SKILL.md, qu'envoie le modèle, que reçoit-il en retour, et que disent les preuves du chatbot sur la réponse ?

<details>
<summary>Solutions</summary>

1. Prends la lettre dans le degré et l'altération dans la hauteur : pour le degré `i`, la lettre se trouve `i` pas au-dessus de celle de la tonique, et l'altération est l'écart, ramené entre -6 et 5, entre la classe de hauteurs que donne le motif de la gamme et la hauteur naturelle de cette lettre, comme le fait `Spell` dans `Lesson10.cs`. Les 11 tonalités concordent alors toutes avec le manuel, puisque le manuel fait le même calcul. Le septième accord de G♯ majeur est F double dièse diminué ; l'`accStr` de la closure écrit déjà `DoubleSharp` sous la forme `##`, d'où `F##dim`. Non compilé contre GA (*à vérifier*).
2. Le numéro de l'intervalle : avec un nombre de pas de lettre à côté des demi-tons, la lettre du résultat se trouve autant de pas au-dessus de celle de la fondamentale, et les demi-tons donnent l'altération. La table convertirait « minor third » en 2 pas et 3 demi-tons, et « augmented second » en 1 pas et 3 demi-tons. Pour « Transpose G7 to Eb », une fondamentale cible est plus simple encore : la closure prendrait la lettre de E♭ dans la demande de l'utilisateur. Non compilé contre GA (*à vérifier*).
3. L'orthographe de chord1 : chaque note commune est nommée comme chord1 l'écrit, à partir de la lettre de la fondamentale de chord1 et du degré de la note dans l'accord (la tierce deux pas de lettre plus haut, la quinte quatre). Les triades d'une tonalité écrivent leurs notes comme la tonalité : l'orthographe de chord1 est donc celle de la tonalité dans chaque paire de la leçon, et la règle se passe de tonalité pour des accords qui n'appartiennent à aucune. Résolu à la main à partir des paires de la leçon.
4. `ga_dsl_eval(closureName: "domain.transposeChord", args: { "symbol": "G7", "semitones": "8" })`, ou `-4` ; le résultat est `D#7` dans les deux cas. En suivant le gabarit du SKILL.md, « **Cmaj7 up a perfect fourth = Fmaj7** (interval = +5 semitones) », le modèle ouvrirait sa réponse par **G7 up a minor sixth = D#7**. Comme le modèle a appelé `ga_dsl_eval`, `SkillMdDrivenWrapperBase` ajoute `grounding.source: ga.dsl@domain.transposeChord` aux preuves et conserve la confiance du modèle : les preuves désignent la closure comme la source de la réponse, comme elles le feraient pour une réponse juste. Résolu à partir du code ; l'appel réel du modèle demande le modèle (*à vérifier*).

</details>

## À retenir

- Un skill qui dit à un modèle « appelle cet outil, ne calcule pas toi-même » déplace la justesse dans l'outil. Appeler l'outil avec les arguments du SKILL.md lui-même teste ce que dira un modèle obéissant, sans le modèle.
- Un nom par classe de hauteurs ne peut pas donner une lettre par degré. Un tableau indexé par classe de hauteurs a un nom par classe de hauteurs, et une tonalité demande une lettre par degré : 11 tonalités sur 30, 70 transpositions sur 252 et 144 paires de notes communes sur 630 tombent sur une autre lettre.
- Un nombre de demi-tons perd le numéro de l'intervalle. Une fois que « minor third » est devenu 3, on ne peut plus distinguer E♭ de D♯.
- Trois closures d'un même fichier orthographient les mêmes notes selon trois règles : le B♭ de D mineur est A♯ dans l'une et B♭ dans une autre.
- Une étiquette d'ancrage dit d'où vient une réponse, pas si elle est juste.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.DSL/Closures/BuiltinClosures/DomainClosures.fs`, `Common/GA.Business.DSL/Library.fs`, `Common/GA.Business.ML/Agents/Mcp/DslEvalMcpTools.cs`, `Common/GA.Business.ML/Agents/Skills/SkillMdDrivenWrapperBase.cs`, `TransposeSkill.cs`, `DiatonicChordsSkill.cs`, `CommonTonesSkill.cs`, `ScaleInfoSkill.cs`, `skills/transpose/SKILL.md`, `skills/diatonic-chords/SKILL.md`, `skills/common-tones/SKILL.md`, `Common/GA.Business.Core.Orchestration/Extensions/ChatbotOrchestrationExtensions.cs`.
- Le `main` de GA au commit [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), daté du 2026-09-30 en UTC : `DomainClosures.fs` et `ChordParser.fs`, pour la comparaison fonction par fonction.
- *Open Music Theory*, les chapitres de base sur les intervalles, les gammes et les triades, pour les définitions du manuel : le numéro d'un intervalle par les lettres, la qualité par les demi-tons, une lettre par degré de la gamme.
