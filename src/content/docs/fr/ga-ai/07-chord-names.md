---
title: "Leçon 7 : les noms d'accords que le chatbot ne sait pas lire"
description: "Des demandes d'improvisation avec des noms d'accords invalides, valides, ou les deux, envoyées au skill d'improvisation de Guitar Alchemist au commit épinglé du cours et dans la version de la pull request #749, qui refuse les demandes qui ne nomment que des accords invalides — compilée à côté du commit épinglé grâce à un alias extern, et notée par un petit reconnaisseur de chiffrages d'accords. La garde fonctionne ; les noms en minuscules, les qualités inconnues, les bémols, une fondamentale diésée sans qualité, C+ et Bø7 passent encore ou sont mal lus."
sidebar:
  label: 7. Les noms d'accords qu'il ne lit pas
  order: 7
---

Le 2026-09-28, un tracer a demandé au chatbot public « which arpeggio fits Hm Q7 ». Ni Hm ni Q7 ne sont des accords en notation anglaise, et la réponse aurait dû le dire. Elle a répondu : « The note Hm Q7 (also known as H) is a perfect 4th above the note Q.To create an arpeggio based on this note, you'll need to find a chord that includes H and its neighboring notes. … », autrement dit une note Hm Q7, « aussi appelée H », une quarte juste au-dessus d'une note Q. C'est devenu le ticket de GA [#745](https://github.com/GuitarAlchemist/ga/issues/745), et le même jour, la pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749) a ajouté une garde qui refuse ce genre de demande. Cette leçon exécute cette garde, ainsi que le skill d'improvisation de la leçon 5 avant et après elle, sur seize demandes, et note ce qu'ils en font avec un petit reconnaisseur de chiffrages d'accords. La question est plus large que celle de #745 : quels noms d'accords le chatbot sait-il lire, au juste ?

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours, sauf ceux qui mènent aux fichiers de #749, qui pointent sur son commit de fusion [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5). Les trois fichiers que compile la leçon sont inchangés sur le `main` de GA au commit [`f4f4d30`](https://github.com/GuitarAlchemist/ga/commit/f4f4d30465b39be7ec36aba3742c218782cf9127), vérifié le 2026-09-28. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l7
```

## Comment Hm Q7 est arrivé jusqu'au modèle

La description de #749 retrace deux chemins entre ce message et le modèle de langage, tous deux par le repli de GA :

1. **Rien ne correspond.** Le routeur sémantique d'intentions de la leçon 4 donne au message un score inférieur à son seuil pour chaque intention, le routeur d'agents ne trouve rien de mieux, et la réponse vient de l'appel direct au modèle. C'est le chemin qu'a enregistré le tracer : routage `fallback-direct`, méthode `low-confidence-fallback`.
2. **Le skill correspond, et sa réponse est remplacée.** Si le routeur choisit bel et bien le skill d'improvisation, le skill ne trouve aucun chiffrage d'accord, passe le message à son extracteur, qui appelle un modèle, et termine sur sa réponse d'absence d'accord, "I couldn't find a chord name in your request…" (je n'ai trouvé aucun nom d'accord dans votre demande…), avec une confiance de 0.2. [`OrchestratedChatApplicationService`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs#L17) remplace toute réponse sous `Chatbot:FallbackMinConfidence`, 0.25, par celle du modèle.

Un modèle sans garde répond à tout. Hors ligne, le cours voit la première étape du second chemin : au commit épinglé, le skill passe « which arpeggio fits Hm Q7 » à son extracteur, et l'extracteur du cours arrête l'exécution à cet endroit, comme aux leçons 5 et 6.

#749 ajoute [`InvalidChordNames`](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.ML/Agents/Skills/InvalidChordNames.cs). Sa méthode `Find` renvoie les mots qui ont la forme d'un chiffrage d'accord mais dont la lettre de fondamentale est hors de A–G, et seulement quand le message pose une question d'improvisation et ne nomme aucun accord valide. L'orchestrateur l'appelle après l'aiguillage sémantique et avant le routeur d'agents, dans ses deux chemins de réponse ([`ProductionOrchestrator.cs` lignes 828-840](https://github.com/GuitarAlchemist/ga/blob/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5/Common/GA.Business.Core.Orchestration/Services/ProductionOrchestrator.cs#L828-L840), un code appelé aux lignes 259 et 550), et le skill l'appelle avant son extracteur. Dans les deux cas, le refus a une confiance de 0.9, au-dessus du seuil du repli : c'est donc lui qui fait la réponse.

## Compiler un correctif à côté du commit épinglé

Le cours se compile contre GA à `a826864`, et déplacer l'épinglage changerait la sortie de chaque leçon. Le programme ne compile donc que les trois fichiers de #749, `InvalidChordNames.cs`, `ImprovisationSkill.cs` et `ChordIntentMatching.cs`, pris dans le commit de fusion, dans un petit projet à part qui référence le `GA.Business.ML` épinglé. [`fetch-ga.sh`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/fetch-ga.sh) les extrait du clone sans blobs avec `git show`, si bien que le dépôt du cours ne contient aucune copie du code de GA :

```xml
<ItemGroup>
  <Compile Include="../.ga-fix/*.cs" />
  <!-- The global usings the three files were written against, from the pinned project -->
  <Compile Include="$(GaRoot)Common/GA.Business.ML/GlobalUsings.cs" Link="GlobalUsings.cs" />
</ItemGroup>
```

Le projet définit maintenant lui-même `GA.Business.ML.Agents.Skills.ImprovisationSkill`, et l'assembly qu'il référence aussi. À l'intérieur du projet, le compilateur utilise sa propre définition et le signale par l'avertissement [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), que le projet fait taire exprès. Le programme du cours référence les deux assemblys : il a donc deux types qui portent le même nom complet. Il donne au nouveau un [alias extern](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), par la métadonnée `Aliases` de sa [référence de projet](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference) :

```xml
<ProjectReference Include="../GaFix749/GaFix749.csproj" Aliases="fix749" />
```

`Lesson7.cs` commence par `extern alias fix749;` et nomme l'espace de noms corrigé `Fixed` avec un [alias using](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), `using Fixed = fix749::GA.Business.ML.Agents.Skills;`. Sans alias, les noms se résolvent dans l'assembly épinglé, comme partout ailleurs dans le cours :

```csharp
var pinned = new ImprovisationSkill(NullLogger<ImprovisationSkill>.Instance, new NoExtractor());
var fixedSkill = new Fixed.ImprovisationSkill(NullLogger<Fixed.ImprovisationSkill>.Instance, new NoExtractor());
```

Les trois fichiers appellent le reste de `GA.Business.ML` tel qu'il est au commit épinglé, pas tel qu'il est au commit de fusion de #749. Cela suffit ici, parce que #749 n'a rien changé d'autre dans ce projet ; ses autres modifications touchent l'orchestrateur et les tests. Si le correctif avait eu besoin d'un nouveau type ailleurs, la compilation échouerait, et le dirait.

## Un reconnaisseur de chiffrages d'accords

Pour noter les réponses, le programme doit savoir quels mots d'un message sont des chiffrages d'accords. `Read`, dans [`Lesson7.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson7.cs), suit l'usage des grilles d'accords (*lead sheets*) : une fondamentale en majuscule de A à G, une altération facultative, une qualité prise dans une liste, une basse facultative après une barre oblique. Un mot qui en a la forme mais qui est défectueux, avec une fondamentale hors de A–G, une fondamentale en minuscule ou une qualité absente de la liste, n'est « pas un chiffrage d'accord ». Un mot qui n'en a pas du tout la forme, « fits », « mode », « I », est du texte :

```csharp
static readonly Regex Symbol = new(@"^(?<letter>[A-Za-z])(?<accidental>[#b♯♭]?)(?<quality>[^/]*)(?:/(?<bass>[A-G][#b♯♭]?))?$");

// Chiffres romains de l'harmonie : "V7", "ii", "IV". Un "I" seul est laissé de côté : c'est le pronom anglais
static readonly Regex Roman = new(@"^(?=.{2})(?:VII|VI|V|IV|III|II|I|vii|vi|v|iv|iii|ii|i)(?:7|°|ø)?$");
```

```text
== What each message holds, read as chord symbols are written
#   message                            chords       not chord symbols
1   which arpeggio fits Hm Q7          -            Hm (root H), Q7 (root Q)
2   which arpeggio fits X7alt          -            X7alt (root X)
3   Q7, which arpeggio should I use?   -            Q7 (root Q)
4   which arpeggio fits H7             -            H7 (root H)
5   which arpeggio fits hm q7          -            hm (lowercase root), q7 (lowercase root)
6   which arpeggio fits Cq7            -            Cq7 (quality q7)
7   which arpeggio fits Am F C G       Am F C G     -
8   which arpeggio fits Bb Eb F        Bb Eb F      -
9   which arpeggio fits B♭ E♭ F        Bb Eb F      -
10  which arpeggio fits B F# G#m E     B F# G#m E   -
11  which arpeggio fits C C+ F         C C+ F       -
12  which arpeggio fits Bø7 E7 Am      Bø7 E7 Am    -
13  which arpeggio fits Am F Q7 G      Am F G       Q7 (root Q)
14  which arpeggio fits C and Q7       C            Q7 (root Q)
15  Hm, which mode is brightest?       -            Hm (root H)
16  which arpeggio fits V7             -            V7 (Roman numeral)
```

B♭ et Bb sont le même accord : le reconnaisseur écrit donc les deux avec des altérations ASCII. La règle de notation suit les critères d'acceptation de #745 : un message qui contient un mot qui n'est pas un chiffrage d'accord devrait être refusé, ou du moins la réponse devrait nommer ce mot ; un message qui contient deux accords ou plus devrait recevoir une réponse accord par accord, pour exactement ces accords-là. Le reste, un seul accord ou aucun, prend le chemin du modèle dans le skill et n'est pas noté ici.

## Ce que GA en fait

```text
== What GA does with them
#   skill at a826864       #749 guard   #749 skill             verdict (#749)
1   needs the model        Hm Q7        declines               same
2   needs the model        X7alt        declines               same
3   needs the model        Q7           declines               same
4   needs the model        H7           declines               same
5   needs the model        -            needs the model        DIFF reaches the model
6   needs the model        -            needs the model        DIFF reaches the model
7   answers Am F C G       -            answers Am F C G       same
8   answers Bb Eb F        -            answers Bb Eb F        same
9   answers B E F          -            answers B E F          DIFF reads Bb as B, Eb as E
10  answers B F G#m E      -            answers B F G#m E      DIFF reads F# as F
11  answers C C F          -            answers C C F          DIFF reads C+ as C
12  answers E7 Am          -            answers E7 Am          DIFF drops Bø7 without a word
13  answers Am F G         -            answers Am F G         DIFF drops Q7 without a word
14  needs the model        -            needs the model        DIFF reaches the model
15  needs the model        -            needs the model        DIFF reaches the model
16  needs the model        -            needs the model        n/a
```

« needs the model » veut dire que le skill a passé le message à son extracteur ; dans le chatbot déployé, c'est un modèle qui répond à partir de là, ou le repli. La colonne « #749 guard » est `InvalidChordNames.Find`, l'appel que fait l'orchestrateur.

**Lignes 1 à 4 : la garde fait son travail.** Chaque message qui ne nomme que des accords dont la fondamentale est hors de A–G est refusé, y compris celui qui commence par l'accord (`Q7, which arpeggio…`). Au commit épinglé, les quatre partaient vers le modèle.

**Lignes 5, 6 et 14 : la garde ne se déclenche pas, et le message continue vers le modèle.** L'expression régulière de la garde est sensible à la casse et cherche des fondamentales de H à Z : `hm q7` ne correspond donc pas. `Cq7` a une fondamentale valide et une qualité inconnue, un cas que #749 déclare hors de son périmètre. `C and Q7` nomme un accord valide, `C` : la garde se tait donc, et c'est voulu, puisqu'une demande qui mêle accords valides et invalides « keeps its route », garde son chemin. Dans les trois cas, ce que lit l'utilisateur dépend d'un modèle qui a déjà inventé de la théorie sur des mots invalides.

**Lignes 9 à 12 : des accords valides, mal lus.** Aucun modèle n'intervient et rien n'est refusé : le skill répond, mais pour d'autres accords.

- `B♭ E♭ F` reçoit une réponse pour B, E et F : un arpège de B majeur et B ionien pour B♭. Dans les expressions du skill, chaque chiffrage admet `[#b]` après la fondamentale, mais ni `♭` ni `♯` ([lignes 447-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L447-L462)). Les skills de GA pour le capodastre et les accordages alternatifs prévoient les deux signes, mais les laissent souvent tomber, comme le montre la [leçon 17](../17-the-capo-and-the-tunings/).
- `F#` est lu F, en simple ASCII. La suite d'accords vient de `ChordTokenRegex`, qui se termine par `\b`, une [limite de mot](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b) : une position entre un [caractère de mot](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) et un caractère qui n'en est pas un, ou le début ou la fin du texte. Après `F#` vient un espace, et ni `#` ni l'espace ne sont des caractères de mot : il n'y a donc pas de limite à cet endroit. Le moteur revient en arrière, abandonne le `#` facultatif, et trouve une limite entre `F` et `#`. `G#m` s'en sort parce qu'il se termine par `m` ; `Bb`, parce que `b` est une lettre.
- `C+` est lu C pour la même raison : `+` fait partie des qualités que liste l'expression, mais un `+` suivi d'une espace ne laisse aucune limite.
- `Bø7` disparaît de la suite : `ø` est une lettre, donc aucune limite ne le sépare du `7`, et la liste a `°7` mais pas `ø7`. Le skill répond pour E7 et Am, et ne dit rien du premier accord.

Le refus des lignes 1 à 4 explique à l'utilisateur qu'un nom d'accord est une fondamentale « optionally followed by # or b », suivie éventuellement de # ou de b. La ligne 10 montre que le skill ne sait pas lire le plus simple de ces noms, un accord majeur sur une fondamentale diésée.

**Ligne 13 : un accord invalide abandonné en silence.** `Am F Q7 G` reçoit une réponse pour Am, F et G. La leçon 5 a constaté le même silence pour des accords que le skill ne sait pas analyser, `C7sus4` et `CmMaj7`.

## Le refus

```text
== #749's skill on "which arpeggio fits Hm Q7"
confidence 0.9
  | I don't recognize "Hm" and "Q7" as chord names, so I can't suggest arpeggios or scales for them. A chord name starts with a root letter from A to G, optionally followed by # or b, then the chord quality: for example 'Bm', 'G7' or 'Cmaj7'. In German notation H is B: "Hm" is written "Bm" here. Name the chords again and I'll give the arpeggio and scales for each.
assumption: Not chord names (root outside A-G): Hm, Q7.
```

La réponse nomme les mots, dit à quoi ressemble un nom d'accord, et redemande, sans aucune théorie sur ces mots. Sa touche finale est musicale : en notation allemande, et dans les pays nordiques, H désigne B bécarre et B désigne B♭, si bien que « Hm » est un vrai accord, B mineur. L'indication est juste, et elle apparaît pour tout mot qui commence par H. Pour `H7`, la réponse dit : « In German notation H is B: "H7" is written "B7" here. »

## Où le reconnaisseur s'arrête

- **La ligne 15 est une erreur du reconnaisseur, pas de GA.** « Hm, which mode is brightest? » commence par une interjection. Le reconnaisseur lit `Hm` comme un chiffrage mal formé ; la garde de GA ignore une interjection qui ouvre un message et que suit une virgule, ce qui est la bonne lecture. La question elle-même, savoir quel mode sonne le plus brillant, relève d'un modèle, et l'y envoyer est correct.
- **Les chiffres romains ne sont pas notés.** `V7` ne nomme un accord que dans une tonalité, et le message n'en donne aucune. La garde de GA laisse les chiffres romains de côté exprès ; ce que devrait être la réponse, une question en retour sur la tonalité, n'est pas vérifié ici.
- **La liste des qualités est finie.** Un chiffrage valide qui n'y figure pas, `C13#11` par exemple, serait jugé mal formé. La liste couvre les accords des leçons 5 et 7, pas plus.
- **Une seule notation.** Le reconnaisseur connaît les lettres anglaises, en majuscules. Le H et le B allemands, le solfège (`Do`, `Ré`) et les noms d'accords en minuscules, fréquents quand on tape vite, ne sont pour lui « pas des chiffrages d'accords » : c'est un choix du cours, pas un fait musical.

## Signalé en amont

- Les noms d'accords invalides qui atteignent le modèle : ticket de GA [#745](https://github.com/GuitarAlchemist/ga/issues/745), corrigé par la pull request [#749](https://github.com/GuitarAlchemist/ga/pull/749), fusionnée le 2026-09-28. Les lignes 1 à 4 sont ce correctif.
- Les lignes 5, 6, 9 à 12 et 13, à savoir les noms en minuscules, la qualité inconnue, les bémols, la fondamentale diésée sans qualité, `C+`, `Bø7` et l'abandon silencieux : signalées après l'écriture de cette leçon, les symboles mal lus ou abandonnés dans le ticket de GA [#757](https://github.com/GuitarAlchemist/ga/issues/757) et les demandes que la garde laisse passer dans [#759](https://github.com/GuitarAlchemist/ga/issues/759). Elles sont listées dans le [journal](../journal/).

## Exercices

1. Sans rien exécuter, prédis ce que le skill répond à « which arpeggio fits F♯ C♯m ». Lequel des deux accords garde sa qualité ?
2. Modifie le skill pour que les lignes 9 à 12 lisent leurs accords. Quelle est la plus petite modification de `ChordTokenRegex`, et que faut-il d'autre ?
3. Pourquoi serait-il difficile d'étendre la garde aux mots en minuscules ? Cite trois mots qu'une règle sur les minuscules devrait laisser tranquilles.
4. Que devrait dire la réponse à la ligne 13, « which arpeggio fits Am F Q7 G » ? Où la placerais-tu dans le skill ?

<details>
<summary>Solutions</summary>

1. Le skill répond pour F et C : les deux fondamentales perdent leur dièse, parce que `♯` n'est pas dans les expressions, et `C♯m` perd aussi sa qualité mineure, puisque la correspondance s'arrête à `C`. Aucun des deux accords ne garde sa qualité telle qu'elle est écrite. Vérifié avec le programme du cours le 2026-09-28, en ajoutant le message à `Messages` le temps d'une exécution.
2. Trois modifications. Remplace `♭` par `b` et `♯` par `#` dans le message avant que le skill le lise. Termine `ChordTokenRegex` par l'assertion avant négative `(?![\w#+°ø-])` au lieu de `\b`, pour qu'un chiffrage puisse se terminer par `#`, `+` ou `°`, mais pas au milieu d'un mot. Ajoute `ø7` avant `ø` dans la liste des qualités. Avec ces trois modifications apportées au `ImprovisationSkill.cs` de #749 le temps d'une exécution, les lignes 9 à 12 affichent `same`, et les lignes 1 à 8 et 13 à 16 ne changent pas ; vérifié avec le programme du cours le 2026-09-28. `InferQuality` classe déjà un chiffrage qui contient `ø` comme demi-diminué, et un chiffrage qui commence par `+` après sa fondamentale comme augmenté ([lignes 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)).
3. Des lettres minuscules sont aussi des mots. Une règle qui traiterait une lettre minuscule suivie d'un suffixe comme un nom d'accord attraperait `am` (comme dans « I am »), `hm` et `mm` (des interjections), et `a` devant un nombre. La garde aurait besoin du contexte que la règle des majuscules obtient gratuitement : une suite de plusieurs mots, ou une position après « fits » ou « over ».
4. Elle devrait répondre pour Am, F et G, et nommer Q7, par exemple « I don't recognize "Q7" as a chord name; here are the other three. » Le skill a déjà ce qu'il lui faut : `InvalidChordNames` trouve le mot, mais ne le renvoie que si aucun accord valide n'est nommé. Une variante qui renverrait les mots invalides dans tous les cas, appelée depuis le chemin des progressions, pourrait ajouter une phrase à la réponse. Non compilé contre GA (*à vérifier*).

</details>

## À retenir

- Un chatbot adossé à un modèle répond à n'importe quel message : ce à quoi on ne peut pas répondre doit donc être refusé avant que le modèle ne le voie. #749 le fait pour les demandes d'improvisation qui ne nomment que des accords dont la fondamentale est hors de A–G, avec une confiance au-dessus du seuil du repli.
- Un correctif absent du commit épinglé peut quand même s'exécuter : on compile ses fichiers à côté de l'assembly épinglé, et on atteint le type en double par un alias extern.
- La garde rate les noms en minuscules, les qualités inconnues sur une fondamentale valide, et les demandes qui mêlent accords valides et invalides ; ces demandes atteignent encore le modèle, ou perdent un accord en silence.
- Des accords valides sont mal lus sans aucun modèle : les signes bémol et dièse, une fondamentale diésée sans qualité en ASCII, `C+` et `Bø7`. La cause est le jeu de caractères des expressions du skill et le `\b` final, qui ne peut pas suivre `#`, `+` ou `°`.
- Le reconnaisseur se trompe sur la ligne de l'interjection, là où GA a raison : un oracle doit dire où il s'arrête.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, `Apps/GaChatbot.Api/Services/OrchestratedChatApplicationService.cs`.
- Pull request de GA [#749](https://github.com/GuitarAlchemist/ga/pull/749), fusionnée le 2026-09-28 sous le commit [`d7efd41`](https://github.com/GuitarAlchemist/ga/commit/d7efd4142908542d469e0b1a9e6dd3dceba8ecc5) : `InvalidChordNames.cs`, `ImprovisationSkill.cs`, `ChordIntentMatching.cs`, `ProductionOrchestrator.cs`, et sa description ; ticket de GA [#745](https://github.com/GuitarAlchemist/ga/issues/745), avec la réponse obtenue par le tracer.
- Microsoft Learn : [extern alias](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/extern-alias), [CS0436](https://learn.microsoft.com/dotnet/csharp/language-reference/compiler-messages/using-directive-errors#cs0436), [la directive `using`](https://learn.microsoft.com/dotnet/csharp/language-reference/keywords/using-directive), [éléments de projet MSBuild courants](https://learn.microsoft.com/visualstudio/msbuild/common-msbuild-project-items#projectreference), [ancres](https://learn.microsoft.com/dotnet/standard/base-types/anchors-in-regular-expressions#word-boundary-b) et [classes de caractères](https://learn.microsoft.com/dotnet/standard/base-types/character-classes-in-regular-expressions#word-character-w) dans les expressions régulières .NET.
