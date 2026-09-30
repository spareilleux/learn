---
title: "Leçon 9 : tous les intervalles, toutes les tonalités"
description: "Les trois skills de Guitar Alchemist qui orthographient des notes sans modèle, IntervalSkill, ScaleInfoSkill et RelativeKeySkill, interrogés sur tous les intervalles que peuvent former deux noms de notes et sur toutes les tonalités, et notés avec le calcul par lettres d'un manuel. Un dièse sur la deuxième note est perdu, si bien que de E à G# le skill trouve une tierce mineure ; un unisson abaissé devient un unisson juste ; la relative mineure de B majeur dépend du skill qui répond ; et huit des treize prompts d'exemple d'IntervalSkill sont des questions qu'il ne sait pas lire."
sidebar:
  label: 9. Tous les intervalles, toutes les tonalités
  order: 9
---

Les leçons 5 et 7 ont trouvé des chiffrages d'accords que le chatbot lit mal. Un nom d'accord peut être ambigu ; une question d'orthographe, non. « What is the interval from E to G#? », l'intervalle de E à G#, n'a qu'une réponse, une tierce majeure, et un manuel la calcule à partir des lettres : E, F, G font trois lettres, donc une tierce ; quatre demi-tons, donc majeure. Le chatbot de GA a trois skills qui répondent à ce genre de question sans modèle : [`IntervalSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs), [`ScaleInfoSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ScaleInfoSkill.cs) et [`RelativeKeySkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs). Cette leçon leur pose tous les intervalles que peuvent former deux noms de notes et toutes les tonalités, et note chaque réponse.

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6), le commit épinglé du cours. Sur le `main` de GA au commit [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), `IntervalSkill.cs`, `IntervalNaming.cs`, `KeyNaming.cs` et le `NoteExtensions.cs` du domaine sont inchangés ; `ScaleInfoSkill` et `RelativeKeySkill` n'ont changé que dans `CanHandle` et par un indicateur `Declined` posé sur le refus que donne `RelativeKeySkill` quand aucune de ses expressions ne correspond ; aucune des réponses ci-dessous ne passe par là. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l9
```

## Le manuel

L'oracle du cours tient en une vingtaine de lignes de [`Lesson9.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson9.cs). Le numéro d'un intervalle compte les lettres, de la lettre de la première note jusqu'à celle de la deuxième ; sa qualité compare ses demi-tons à ceux de l'intervalle majeur ou juste de même numéro :

```csharp
static (string Short, string Long, int Semitones) Interval(string a, string b)
{
    var steps = (Letters.IndexOf(b[0]) - Letters.IndexOf(a[0]) + 7) % 7;
    var semitones = ((Pitch(b) - Pitch(a)) % 12 + 12) % 12;
    var offset = ((semitones - MajorSteps[steps] + 6) % 12 + 12) % 12 - 6;
    var perfect = steps is 0 or 3 or 4;
    var quality = (perfect, offset) switch
    {
        (true, 0) => "P",
        (false, 0) => "M",
        (false, -1) => "m",
        (_, > 0) => new string('A', offset),
        (true, < 0) => new string('d', -offset),
        _ => new string('d', -offset - 1),
    };
    // Counted from the major or perfect interval of that number: C to Cb is a semitone down
    return ($"{quality}{steps + 1}", $"{QualityName(quality)} {Sizes[steps]}", MajorSteps[steps] + offset);
}
```

La gamme d'une tonalité s'orthographie de la même façon : sept lettres à partir de la tonique, chacune avec l'altération qui la place à la bonne distance. La relative mineure d'une tonalité majeure commence sur son sixième degré, la relative majeure d'une tonalité mineure sur son troisième, et l'armure compte les altérations de la gamme. Les 21 noms de notes sont les sept lettres avec un bémol, sans altération ou avec un dièse ; les 30 tonalités sont les quinze de chaque mode qui ont au plus sept dièses ou sept bémols.

## 441 questions

Chaque question est « What is the interval from X to Y? », envoyée à l'intention `skill.interval`, comme la leçon 8 envoyait ses prompts. La réponse de GA nomme les deux notes qu'il a lues, ce qui permet de distinguer une note mal lue d'un intervalle mal calculé :

```text
== IntervalSkill, "What is the interval from X to Y?" for the 21 x 21 note names
. right   # a note read as another   a right interval, quality abbreviated   x wrong interval

from\to Cb C  C# Db D  D# Eb E  E# Fb F  F# Gb G  G# Ab A  A# Bb B  B#
Cb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  x  # 
C       x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
C#      x  x  #  .  .  #  .  .  #  a  .  #  a  .  #  .  .  #  .  .  # 
Db      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D       .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
D#      a  .  #  x  x  #  .  .  #  a  .  #  a  .  #  a  .  #  .  .  # 
Eb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E       .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
E#      a  .  #  a  .  #  x  x  #  x  .  #  a  .  #  a  .  #  a  .  # 
Fb      .  .  #  .  .  #  .  x  #  .  .  #  .  .  #  .  .  #  .  a  # 
F       .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  #  .  .  # 
F#      a  .  #  .  .  #  .  .  #  x  x  #  .  .  #  .  .  #  .  .  # 
Gb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
G       .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  #  .  .  # 
G#      a  .  #  a  .  #  .  .  #  a  .  #  x  x  #  .  .  #  .  .  # 
Ab      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
A       .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  x  .  #  .  .  # 
A#      a  .  #  a  .  #  a  .  #  a  .  #  a  .  #  x  x  #  .  .  # 
Bb      .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  #  .  .  # 
B       .  .  #  .  .  #  .  .  #  a  .  #  .  .  #  .  .  #  x  .  # 
B#      x  .  #  a  .  #  a  .  #  x  a  #  a  .  #  a  .  #  x  x  # 

441 questions: 241 right, 147 with a note read as another, 27 right with the quality abbreviated, 26 wrong
```

Les colonnes `#` rassemblent toutes les questions dont la deuxième note porte un dièse : 7 dièses fois 21 premières notes, 147 questions, qui reçoivent toutes la réponse pour la note naturelle. L'expression régulière ([lignes 62-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L62-L64)) se termine par `\b` :

```csharp
    private static readonly Regex IntervalPattern = new(
        @"\b([A-Ga-g][#b]?)\s*(?:to|and)\s+([A-Ga-g][#b]?)\b",
        RegexOptions.IgnoreCase | RegexOptions.Compiled);
```

`\b` est une limite entre un caractère de mot et un caractère qui n'en est pas un, ou entre un caractère de mot et le début ou la fin du texte. Après `G#` viennent un point d'interrogation, une espace ou la fin du texte, et `#` n'est pas non plus un caractère de mot : il n'y a donc pas de limite à cet endroit ; le moteur revient en arrière, abandonne le `#` facultatif et reconnaît `G`, suivi de la limite entre `G` et `#`. Un bémol survit, parce que `b` est une lettre, et la première note survit, parce qu'aucun `\b` ne la suit. C'est le même `\b` final qui faisait lire `F#` comme `F` à `ImprovisationSkill` dans la [leçon 7](../07-chord-names/), ticket de GA [#757](https://github.com/GuitarAlchemist/ga/issues/757), ici dans l'expression d'un autre skill.

Écrites autrement, les mêmes questions ne s'en tirent pas mieux :

```text
== The same question, written another way
What is the interval between E and G#?
  | From **E** to **G** is a **minor third** (m3, 3 semitones).
What is the interval from C to F♯?
  | From **C** to **F** is a **perfect fourth** (P4, 5 semitones).
What is the interval from B♭ to D?
  | Could not parse two note names from your question.
```

De E à G#, c'est la tierce d'un accord de E majeur. Le `♯` de `F♯` n'est pas dans la classe de caractères de l'expression : celle-ci s'arrête donc avant lui et lit F ; `B♭` n'est pas lu du tout.

## Là où le domaine se trompe

27 réponses sont justes, mais avec une qualité abrégée : `IntervalNaming.QualityLongName` ([lignes 56-64](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/IntervalNaming.cs#L56-L64)) nomme cinq qualités, si bien qu'une quarte doublement augmentée s'affiche « AA fourth ». Les 26 autres sont fausses, alors que les deux notes ont été bien lues :

```text
== The note names read right, the interval wrong
Cb to B   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
C  to Cb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
C# to Cb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
C# to C   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D  to Db  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
D# to Db  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
D# to D   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E  to Eb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Eb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
E# to E   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
E# to Fb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
Fb to E   GA major seventh (M7, 11)           textbook augmented seventh (A7, 12)
F  to Fb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
F# to Fb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
F# to F   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G  to Gb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
G# to Gb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
G# to G   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A  to Ab  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
A# to Ab  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
A# to A   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B  to Bb  GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
B# to Cb  GA major second (M2, 2)             textbook doubly diminished second (dd2, -1)
B# to Fb  GA perfect fifth (P5, 7)            textbook triply diminished fifth (ddd5, 4)
B# to Bb  GA perfect unison (P1, 0)           textbook doubly diminished unison (dd1, -2)
B# to B   GA perfect unison (P1, 0)           textbook diminished unison (d1, -1)
```

21 d'entre elles sont un unisson abaissé, la deuxième note étant sur la même lettre avec moins de dièses ou plus de bémols : « C# to C » est un unisson juste de 0 demi-ton. Le domaine calcule les demi-tons modulo 12 ([`NoteExtensions.cs` ligne 110](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L110)) : de C# à C, cela fait 11, et `DetermineQuality` soustrait le 0 de l'unisson ([lignes 13-56](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs#L13-L56)). Aucune branche ne couvre une différence de 11, et la branche par défaut renvoie la qualité juste ; le switch des secondes, tierces, sixtes et septièmes a des branches de -3 à 2 et renvoie majeure par défaut :

```csharp
            return difference switch
            {
                -2 => IntervalQuality.DoublyDiminished,
                -1 => IntervalQuality.Diminished,
                0 => IntervalQuality.Perfect,
                1 => IntervalQuality.Augmented,
                2 => IntervalQuality.DoublyAugmented,
                _ => IntervalQuality.Perfect
            };
```

Les cinq autres passent par la même branche par défaut : de Cb à B, il y a douze demi-tons, 0 modulo 12, et l'intervalle devient une septième majeure. Il leur faut un Cb, un Fb, un E# ou un B#, qu'un guitariste écrit rarement ; les unissons, non. Le `main` de GA a un `Note.cs` différent ; ces réponses y ont donc été vérifiées une fois, hors du programme du cours : `GA.Domain.Core`, avec les `GA.Core` et `GA.Business.Config` qu'il référence, et `IntervalNaming.cs`, pris sur `main` avec `git archive` et exécutés sur les 441 paires, avec des notes correctement lues. Les 21 unissons et les cinq autres donnent le même résultat, de même que l'intervalle de C à B#, une septième augmentée qu'il donne comme majeure ; sur le skill épinglé, son dièse est perdu avant même le calcul.

## Les tonalités

Pour chacune des 30 tonalités, le programme demande ses notes à `ScaleInfoSkill`, qui les donne avec la tonalité relative, et demande à `RelativeKeySkill` la tonalité relative et l'armure. Seules les tonalités où quelque chose diffère sont affichées :

```text
== ScaleInfoSkill and RelativeKeySkill on the 30 keys with at most seven sharps or flats
key         notes  relative key: ScaleInfoSkill  RelativeKeySkill  textbook      signature
Cb major    right  Ab minor                        Ab minor          Ab minor      not read as a key
B major     right  Ab minor                        G# minor          G# minor      5 sharps
F# major    right  Eb minor                        D# minor          D# minor      6 sharps
C# major    right  Bb minor                        A# minor          A# minor      7 sharps
G# minor    right  Cb major                        B major           B major       5 sharps
D# minor    right  Gb major                        F# major          F# major      6 sharps
A# minor    right  Db major                        C# major          C# major      7 sharps

30 keys: notes right 30, relative key right: ScaleInfoSkill 24, RelativeKeySkill 30; signature right 29
How many flats in Cb major?
  | I couldn't identify 'Cb' as a key. Try a single pitch letter optionally followed by # or b (e.g. C, G, F#, Bb).
```

Les notes des 30 gammes sont toutes justes. La tonalité relative ne l'est pas, pour six tonalités et pour l'un des deux skills : `ScaleInfoSkill` dit que la relative mineure de B majeur est A♭ mineur, et `RelativeKeySkill` dit G♯ mineur. `ScaleInfoSkill` tire ce nom de `KeyNaming.RelativeKeyName` ([lignes 55-65](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/KeyNaming.cs#L55-L65)), qui prend la première tonalité de l'autre mode ayant les mêmes classes de hauteurs ; G♯ mineur et A♭ mineur ont les mêmes classes de hauteurs, et A♭ mineur vient en premier. Les six tonalités sont les tonalités à dièses qui ont une jumelle enharmonique en bémols. `RelativeKeySkill` a été corrigé pour exactement ce problème en mai : son commentaire ([lignes 119-125](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L119-L125)) dit que l'ancienne recherche « always returned flat-side spellings », renvoyait toujours des graphies en bémols, et que « F# major incorrectly returned "Ebm" », F# majeur renvoyait à tort "Ebm". Le correctif est allé dans un seul skill ; la fonction utilitaire qu'appelle l'autre a gardé l'ancienne méthode. « What notes are in B major? » et « What is the relative minor of B major? » reçoivent deux réponses différentes du même chatbot.

`RelativeKeySkill` lit C♭ majeur quand on lui demande sa relative mineure, qu'il cherche dans son cercle des quintes ([lignes 84-91](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L84-L91)), mais pas quand on lui demande son armure, dont le calcul part d'une table des toniques sans C♭ ([lignes 72-81](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L72-L81)). Le refus demande alors précisément ce que l'utilisateur a écrit : « a single pitch letter optionally followed by # or b », une lettre de note suivie éventuellement de # ou de b.

Au-delà de sept dièses ou de sept bémols, les tonalités sont théoriques. `ScaleInfoSkill` dit qu'il ne les reconnaît pas, et `RelativeKeySkill` répond :

```text
== Keys past seven sharps or flats that RelativeKeySkill reads
What notes are in G# major?
  | I don't recognise "G# major" as a standard key. Try a key like C major, F# minor, or Bb major.
How many sharps in D# major?  textbook 9 sharps, usually written Eb major
  | **D# major** has no sharps or flats.
How many sharps in G# major?  textbook 8 sharps, usually written Ab major
  | **G# major** has no sharps or flats.
How many sharps in A# major?  textbook 10 sharps, usually written Bb major
  | **A# major** has no sharps or flats.
How many sharps in Db minor?  textbook 8 flats, usually written C# minor
  | **Db minor** has no sharps or flats.
How many sharps in Gb minor?  textbook 9 flats, usually written F# minor
  | **Gb minor** has no sharps or flats.
What is the parallel minor of G# major?  textbook: G# minor has 5 sharps
  | Same root note (**G#**) but different scales — the parallel minor lowers the 3rd, 6th, and 7th degrees. G# major has no sharps or flats; G# minor has 3 flats (three positions counter-clockwise on the circle of fifths).
```

La table des toniques contient les dix-sept noms de notes usuels ; le cercle des quintes contient quinze tonalités de chaque mode, sans D♯, G♯ ni A♯ majeur, ni D♭ ni G♭ mineur. Pour une tonalité présente dans la première et absente du second, `MajorSharpsFlats` et `MinorSharpsFlats` renvoient 0 ([lignes 208-212](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L208-L212)), ce qui s'affiche « no sharps or flats », ni dièse ni bémol. L'homonyme mineure retranche trois de ce 0, et G♯ mineur, une tonalité à cinq dièses, se voit attribuer trois bémols.

## Les exemples des skills eux-mêmes

Une intention liste des prompts d'exemple, et le routeur d'intentions envoie une question à l'intention dont les exemples lui ressemblent le plus ([`IIntent.cs` lignes 29-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Intents/IIntent.cs#L29-L32)). L'intention qui enveloppe un skill passe la question telle quelle à l'`ExecuteAsync` du skill ([`OrchestratorSkillIntent.cs` ligne 29](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs#L29)). Chaque skill devrait donc au moins répondre à ses propres exemples :

```text
== Each skill's example prompts, which the intent router matches questions against, sent to that skill
skill.interval: 5 of 13 answered
  What's a perfect fifth?                  | Could not parse two note names from your question.
  What is a major sixth?                   | Could not parse two note names from your question.
  Define a minor third                     | Could not parse two note names from your question.
  Minor third up from D                    | Could not parse two note names from your question.
  Perfect fourth above C                   | Could not parse two note names from your question.
  Major sixth above G                      | Could not parse two note names from your question.
  augmented fourth definition              | Could not parse two note names from your question.
  semitones in a major sixth               | Could not parse two note names from your question.
skill.scaleinfo: 21 of 24 answered
  What's the formula for harmonic minor    | Could not parse a key name from your question.
  Formula for melodic minor scale          | Could not parse a key name from your question.
  what notes are in the B flat major scale | Could not parse a key name from your question.
skill.relativekey: 12 of 12 answered
```

Huit des exemples de `IntervalSkill`, cinq définitions et trois questions comme « Minor third up from D », nomment au plus une note, alors que son expression en veut deux, reliées par « to » ou « and ». Le commentaire placé au-dessus d'eux ([lignes 34-44](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs#L34-L44)) dit qu'ils ont été ajoutés pour enlever ces questions à `CircleOfFifthsSkill` et à `ScaleInfoSkill` : le routage a été corrigé, et la réponse vers laquelle il mène est « Could not parse two note names from your question. » Ce que le chatbot complet sert pour ces questions demande le modèle d'embeddings, que le cours n'exécute pas (*à vérifier*). Le repli sur le chat direct est désactivé par défaut, et conditionné à la confiance du routeur, pas à celle du skill ([`IFallbackChatHandler.cs` ligne 66](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Abstractions/IFallbackChatHandler.cs#L66), [`FallbackChatApplicationService.cs` lignes 142-158](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs#L142-L158)). Sur `main`, `IntentResult` a gagné un indicateur `Declined` pour une requête « that does not have the input shape this intent handles », qui n'a pas la forme d'entrée que traite cette intention, ce qui permet à l'orchestrateur d'essayer le chemin suivant ; `IntervalSkill` ne le positionne pas.

`ScaleInfoSkill` rate deux questions de formule, qui ne nomment aucune tonalité, et « B flat » écrit en toutes lettres, parce que son expression veut l'altération sous forme de symbole, collée à la lettre.

## Où le cours s'arrête

- **Une seule formulation par type de question**, plus les trois variantes de la question d'intervalle. D'autres formulations peuvent être lues autrement.
- **Aucun double dièse ni double bémol dans les questions.** Les 21 noms ont au plus une altération ; le manuel en gère deux, pour les tonalités théoriques.
- **Le routage n'est pas testé.** Les questions vont directement aux intentions ; savoir quelle intention le routeur choisit pour elles, et ce que sert le chatbot quand le skill ne sait pas les lire, demande le modèle.
- **Les tonalités théoriques peuvent être refusées.** Un chatbot qui dit ne pas connaître G♯ majeur est honnête ; le constat porte sur le décompte faux, pas sur le refus.
- **Le domaine de `main` n'a été vérifié qu'une fois**, à la main, pas par le programme du cours.

## Signalé en amont

- Signalés après l'écriture de cette leçon : le dièse perdu, les `♯` et `♭` non reconnus, les qualités abrégées et les prompts d'exemple de `IntervalSkill` dans le ticket de GA [#767](https://github.com/GuitarAlchemist/ga/issues/767) ; les unissons abaissés et la branche par défaut dans [#768](https://github.com/GuitarAlchemist/ga/issues/768) ; les tonalités relatives de `ScaleInfoSkill`, les armures de `RelativeKeySkill` au-delà de sept altérations et son refus de C♭ dans [#769](https://github.com/GuitarAlchemist/ga/issues/769). Les trois prompts d'exemple auxquels `ScaleInfoSkill` ne sait pas répondre ne sont pas signalés. Ils sont listés dans le [journal](../journal/).

## Exercices

1. Réécris `IntervalPattern` pour qu'elle lise `G#` dans « E and G# » et `B♭` dans « B♭ to D », sans changer ce qu'elle lit dans « distance from F# to D » ou « interval from Bb to Eb ». Que faut-il changer d'autre pour que `B♭` reçoive une réponse ?
2. `DetermineQuality` reçoit une différence égale à un nombre de 0 à 11 moins les demi-tons attendus. Comment la ramènerais-tu dans la plage que couvrent ses branches, et que devient l'intervalle de C# à C ? Lesquelles des 26 réponses fausses atteindraient encore la branche par défaut ?
3. Réécris `KeyNaming.RelativeKeyName` pour qu'elle donne G♯ mineur pour B majeur et B majeur pour G♯ mineur, et toujours A♭ mineur pour C♭ majeur.
4. Prédis la réponse de `IntervalSkill` à « What is the interval between C and F sharp? » et celle de `ScaleInfoSkill` à « what notes are in the B flat major scale ». Laquelle des deux est la pire pour un utilisateur, et pourquoi ?

<details>
<summary>Solutions</summary>

1. `\b([A-Ga-g][#b♯♭]?)\s*(?:to|and)\s+([A-Ga-g][#b♯♭]?)(?![\w#♯♭])` : la classe des altérations gagne `♯` et `♭`, et le `\b` final devient une assertion avant qui interdit seulement une autre lettre, un chiffre ou une altération après la note : elle n'a donc plus besoin d'un caractère de mot avant elle. Vérifié avec le moteur d'expressions régulières de .NET sur les questions de l'exercice et de cette leçon : `E|G#`, `C|F♯`, `B♭|D`, `F#|D`, `Bb|Eb`. Les notes passent ensuite par `IntervalNaming.TryParseNote`, qui les transmet aux parseurs du domaine ; remplacer d'abord `♯` et `♭` par `#` et `b`, comme le fait `RelativeKeySkill.NormalizeKey` ([ligne 226](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/RelativeKeySkill.cs#L226)), rend le skill indépendant de ce que ces parseurs acceptent. Non compilé contre GA (*à vérifier*).
2. Replie-la : `((difference + 6) % 12 + 12) % 12 - 6` donne une valeur de -6 à 5. De C# à C, on obtient 11 - 0 = 11, replié en -1 : un unisson diminué, un demi-ton vers le bas. Les 21 unissons, les deux septièmes (-11 devient 1, augmentée) et les deux secondes (9 devient -3, doublement diminuée) ont alors une branche ; de B# à Fb, 4 - 7 = -3 pour une quinte donne une quinte triplement diminuée, et le switch des intervalles justes s'arrête à « doublement » : cet intervalle atteint donc encore la branche par défaut. Les demi-tons qu'affiche le skill viennent de l'intervalle que le domaine construit à partir de la qualité et du numéro : ce qu'il affiche pour un unisson diminué doit donc être vérifié aussi (*à vérifier*). Résolu à la main à partir du code.
3. Compare les armures au lieu des classes de hauteurs : la tonalité relative est la tonalité de l'autre mode qui a le même nombre d'altérations, et de la même sorte, `Key.Items.First(k => k.KeyMode != key.KeyMode && k.KeySignature.AccidentalCount == key.KeySignature.AccidentalCount && k.KeySignature.AccidentalKind == key.KeySignature.AccidentalKind)`. B majeur a cinq dièses, comme G♯ mineur et contrairement aux sept bémols de A♭ mineur ; C♭ majeur a sept bémols, comme A♭ mineur. C majeur et A mineur n'ont aucune altération, et la comparaison de leurs sortes d'altérations doit conclure à l'égalité pour que les deux tonalités se correspondent. Non compilé contre GA (*à vérifier*).
4. `IntervalSkill` lit « C and F » et répond « From **C** to **F** is a **perfect fourth** (P4, 5 semitones) » : le mot « sharp » est hors de l'expression, et la réponse nomme F, ce qu'un lecteur attentif pourrait remarquer. `ScaleInfoSkill` répond « Could not parse a key name from your question. » La première réponse est la pire : un refus pousse l'utilisateur à reformuler, alors qu'une réponse fausse sur une autre note est crue. Vérifié avec le programme du cours le 2026-09-29, en posant les deux questions le temps d'une exécution.

</details>

## À retenir

- Une question d'orthographe a une seule bonne réponse, et le calcul par lettres d'un manuel la donne : le numéro d'un intervalle compte les lettres, sa qualité compte les demi-tons. Chaque skill de ce genre peut donc être testé sur toutes ses entrées, ici 441 intervalles et 30 tonalités.
- Une expression régulière qui se termine par `\b` après un `#` facultatif perd le `#` chaque fois qu'une espace, une ponctuation ou la fin du texte le suit. GA a ce défaut dans les expressions d'au moins deux skills ; de E à G#, on obtient une tierce mineure.
- Un switch avec une branche par défaut cache les valeurs que personne n'attendait : des demi-tons pris modulo 12 donnent des différences que les branches ne couvrent pas, et la branche par défaut répond « juste ».
- Un correctif appliqué à un seul de deux chemins de code laisse le chatbot se contredire : la relative mineure de B majeur est G♯ mineur ou A♭ mineur selon le skill que choisit le routeur.
- Les prompts d'exemple d'un skill sont un test qu'il peut s'appliquer à lui-même. `IntervalSkill` échoue sur huit de ses treize.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/IntervalSkill.cs`, `ScaleInfoSkill.cs`, `RelativeKeySkill.cs`, `Common/GA.Business.ML/Agents/IntervalNaming.cs`, `KeyNaming.cs`, `Common/GA.Business.ML/Agents/Intents/IIntent.cs`, `Common/GA.Business.Core.Orchestration/Intents/OrchestratorSkillIntent.cs`, `Common/GA.Business.Core.Orchestration/Services/FallbackChatApplicationService.cs`, `Common/GA.Domain.Core/Primitives/Extensions/NoteExtensions.cs`.
- Le `main` de GA au commit [`53b7253`](https://github.com/GuitarAlchemist/ga/commit/53b7253596e71e40c02208a3a85edd25419aeb53), daté du 2026-09-30 en UTC : `OrchestratorSkillIntent.cs` et `IIntent.cs` pour l'indicateur `Declined` ; `GA.Domain.Core` pour la vérification ponctuelle des intervalles.
- *Open Music Theory*, les chapitres de base sur les intervalles et les armures, pour les définitions du manuel : le numéro d'un intervalle par les lettres, la qualité par les demi-tons, les tonalités relatives qui partagent une armure.
