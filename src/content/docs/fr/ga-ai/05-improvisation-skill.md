---
title: "Leçon 5 : le skill d'improvisation et la théorie accord–gamme"
description: Le skill d'improvisation de Guitar Alchemist appelé directement, sans modèle, et confronté à la théorie accord–gamme — comment il lit une suite d'accords, l'arpège et la gamme qu'il donne à chacun, où ils sortent de l'accord ou de la tonalité, et un petit oracle qui trouve la tonalité et la gamme des manuels.
sidebar:
  label: 5. Le skill d'improvisation
  order: 5
---

La leçon 4 s'est terminée sur des questions auxquelles un skill déterministe répond sans modèle. Celle-ci en prend une que les guitaristes posent sans arrêt, « which arpeggio fits Am F C G? », quel arpège va sur Am F C G, et le skill qui y répond, [`ImprovisationSkill`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs). Le programme appelle le skill directement, comme la leçon 4 appelait le skill des tonalités relatives, et vérifie chaque réponse avec un petit oracle écrit à partir des définitions des manuels : les notes de chaque accord, les notes de chaque gamme, et la tonalité qu'implique une progression. La musique qui sous-tend tout cela se trouve dans deux leçons du cours de théorie musicale, [gammes et modes](../../music-theory-ga/02-scales-and-modes/) et [accords diatoniques](../../music-theory-ga/06-diatonic-chords/).

Tous les liens vers GA pointent sur le commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6). Le fichier du skill est inchangé sur le `main` de GA au commit [`8cd5042`](https://github.com/GuitarAlchemist/ga/commit/8cd5042b91e38eb9949566dc3584fa0a42089788), vérifié le 2026-09-28 : les réponses ci-dessous sont donc toujours celles du chatbot. Les sorties viennent de :

```bash
dotnet run --project code/ga-ai/GaAi -c Release -- l5
```

## La réponse du skill

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G")
  | Over **Am – F – C – G**, for each chord:
  |
  | - **Am** → arpeggio **Am**, play **A Aeolian (natural minor)** (diatonic minor — fits most i chords).
  | - **F** → arpeggio **F**, play **F Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **C** → arpeggio **C**, play **C Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  | - **G** → arpeggio **G**, play **G Ionian (major)** (diatonic, includes the 7 — careful on the IV chord).
  |
  | Each arpeggio spells the chord tones; the scale adds the passing notes for lines between them.
assumption: Each chord classified independently from its written quality; no key inferred.
```

Une ligne par accord : un arpège, qui égrène les notes de l'accord, et une gamme à jouer dessus, la première d'une liste classée. La dernière ligne dit comment : chaque accord est classé seul, d'après la qualité écrite dans son chiffrage, et aucune tonalité n'est déduite. Le commentaire du skill justifie ce choix ([lignes 22-32](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L22-L32)). L'alternative évidente, déduire la tonalité et donner à chaque accord le mode de son degré, « is wrong for any borrowed or secondary chord », se trompe sur tout accord d'emprunt ou secondaire : un accord de A majeur en C majeur tombe sur le degré vi, dont le mode est l'éolien, avec un C bécarre contre le C♯ de l'accord. Lire la qualité écrite ne peut pas commettre cette erreur.

Elle en commet une autre. F et G sont des triades majeures : toutes deux reçoivent donc l'ionien, la première gamme que le skill liste pour un accord majeur ([lignes 360-436](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L360-L436)). F ionien a un B♭ et G ionien un F♯ ; la progression n'a ni l'un ni l'autre. La remarque du skill lui-même dit « careful on the IV chord », prudence sur l'accord de IV, et il met quand même l'ionien en tête sur cet accord.

Le chemin, dans [`ExecuteAsync`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L117-L128) et [`BuildProgressionResponse`](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L212-L261) :

1. `ExtractChordRun` extrait les chiffrages d'accords du message avec une [expression régulière produite par un générateur de source](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators) ([lignes 453-462](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L453-L462)). À partir de deux accords, c'est le chemin des progressions, avant toute autre tentative.
2. Pour chaque accord, `ExtractRoot` et `InferQuality` ([lignes 309-353](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L309-L353)) séparent le chiffrage en une fondamentale et une qualité, `ArpeggioFor` ([lignes 266-284](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L266-L284)) nomme l'arpège, et `ScalesFor` liste les gammes, la meilleure d'abord.
3. Le texte de la réponse, son `Evidence` et son `Data` portent les mêmes résultats, accord par accord.

Seul le chemin à un accord appelle un modèle, par l'`IMusicalQueryExtractor` que reçoit le skill. Le cours lui en passe un qui lève une exception : l'exécution échouerait si le chemin des progressions s'en servait un jour ; ce n'est pas le cas. Pour son autre dépendance, le skill reçoit un [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1), et le programme lit `Data` avec [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement) : chaque ligne ci-dessous est ce que le skill a renvoyé, pas du texte extrait de sa réponse.

## Un oracle en cent lignes

Pour noter les réponses, le programme a besoin des notes de chaque accord et de chaque gamme, avec leur orthographe, pour afficher B♭ et non A♯. [`Lesson5.cs`](https://github.com/spareilleux/learn/blob/main/code/ga-ai/GaAi/Lesson5.cs) contient trois tables écrites à partir des formules des manuels : les accords de la leçon (`"m7#5"` vaut `1 b3 #5 b7`), chaque nom de gamme que le skill peut renvoyer (`"Mixolydian b6"` vaut `1 2 3 4 5 b6 b7`), et les noms des modes à sept notes. Une note est une lettre et une classe de hauteurs, et un degré s'écrit sur sa lettre :

```csharp
// Un degré comme "b3", "#11" ou "bb7" au-dessus d'une fondamentale, écrit sur la bonne lettre
static Note Degree(Note root, string degree)
{
    var flats = degree.TakeWhile(ch => ch == 'b').Count();
    var sharps = degree.TakeWhile(ch => ch == '#').Count();
    var step = (int.Parse(degree[(flats + sharps)..]) - 1) % 7;
    return new Note((root.Letter + step) % 7, (root.Pc + MajorSteps[step] + sharps - flats + 12) % 12);
}
```

Si GA ajoute ou renomme une gamme, le nom manque dans la table et la recherche dans le dictionnaire lève une exception : la CI du cours échoue au lieu de noter une réponse qu'elle ne comprend pas.

Ces tables donnent trois vérifications. Pour un accord : l'arpège ajoute-t-il une note que l'accord n'a pas, en omet-il une, et manque-t-il une note de l'accord à la gamme principale, la première que propose le skill ? Pour une progression : dans quelle tonalité est-elle, et quelle gamme les manuels donnent-ils à chaque accord dans cette tonalité ?

## Un accord à la fois

Le skill classe chaque accord d'une suite indépendamment des autres : une suite de dix-sept accords, tous sur C, revient donc à dix-sept questions, et un seul appel y répond :

```text
== ImprovisationSkill.ExecuteAsync("arpeggios over Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5")
written: Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7#5 C7sus4 CmMaj7 Csus4 Csus2 C5
read:    Cmaj7 C7 Cm7 Cm7b5 Cdim Cdim7 Caug C6 Cm6 C7#11 Cm7#5 Cmaj7 Csus4 Csus2 C5

written  read as    quality                 arpeggio  lead scale                       check
Cmaj7               major 7                 Cmaj7     C Ionian (major)                 ok
C7                  dominant 7              C7        C Mixolydian                     ok
Cm7                 minor 7                 Cm7       C Dorian                         ok
Cm7b5               half-diminished (m7b5)  Cm7b5     C Locrian                        ok
Cdim                diminished triad        Cdim      C Locrian                        ok
Cdim7               diminished 7            Cdim7     C Whole-Half Diminished          ok
Caug                augmented               Caug      C Whole Tone                     ok
C6                  major triad             C         C Ionian (major)                 arpeggio drops A
Cm6                 minor major 7           CmMaj7    C Melodic Minor                  arpeggio adds B; arpeggio drops A
C7#11               dominant 7              C7        C Mixolydian                     arpeggio drops F#; scale lacks F# (choice 2 of 3 has it)
Cm7#5               augmented               Caug      C Whole Tone                     arpeggio adds E; arpeggio drops Eb Bb; scale lacks Eb (none of 2 choices has it)
Cmaj7#5  Cmaj7      major 7                 Cmaj7     C Ionian (major)                 arpeggio adds G; arpeggio drops G#; scale lacks G# (none of 2 choices has it)
C7sus4   (dropped)
CmMaj7   (dropped)
Csus4               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops F
Csus2               unknown                 C         C Major scale of the chord root  arpeggio adds E; arpeggio drops D
C5                  unknown                 C         C Major scale of the chord root  arpeggio adds E
```

Sept accords reviennent justes. Les dix autres pèchent à trois endroits.

**Lecture.** `read:` compte quinze accords, pas dix-sept, et la réponse n'en dit rien. L'expression régulière du tokenizer est une liste de qualités suivie d'une limite de mot, `\b`. `Cmaj7#5` correspond à `maj7`, et il y a une limite de mot entre `7` et `#` : l'accord est lu comme `Cmaj7`, sans sa quinte augmentée. `C7sus4` et `CmMaj7` ne correspondent à rien. La liste a `7` mais pas `7sus4`, et `mmaj7` en minuscules seulement ; quant aux correspondances plus courtes, `C7` et `Cm`, elles ne sont pas suivies d'une limite de mot. L'étiquette d'arpège que le skill lui-même donne à un accord mineur à septième majeure est `mMaj7` ([ligne 278](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L278)), une graphie que son tokenizer ne sait pas relire.

**Classification.** `InferQuality` teste des sous-chaînes dans un ordre fixe, et la première qui correspond l'emporte.

- `Cm7#5` contient `7#5`, testé avec la famille augmentée avant toute qualité mineure ([ligne 343](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L343)). L'arpège est `Caug`, C E G♯, dont le E bécarre se heurte au E♭ de l'accord, et aucune des deux gammes proposées ne contient ce E♭.
- `Cm6` est envoyé exprès vers « minor major 7 » : « mel min territory », le territoire de la mineure mélodique, dit le commentaire ([ligne 346](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L346)). La mineure mélodique contient bien l'accord, mais l'arpège `CmMaj7` joue B là où l'accord a A.
- Pour le classifieur, `C7#11` est une simple septième de dominante : la gamme principale est donc le mixolydien, avec le F bécarre que l'accord hausse. Le deuxième choix, le lydien dominant, est le bon.
- `Csus4`, `Csus2` et `C5` sont « unknown », inconnus, et une qualité inconnue reçoit pour étiquette d'arpège la fondamentale seule ([ligne 283](https://github.com/GuitarAlchemist/ga/blob/a826864f3a012cad88e415954bf57eca0ce12aa6/Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs#L283)), qui se lit comme une triade majeure : un E contre le F du sus4 ou le D du sus2, et une tierce que le power chord laisse de côté exprès.

**Incomplet.** `C6` reçoit une triade pour arpège, sans le A. Celui-là n'est pas faux, seulement incomplet : un arpège qui omet une note ne joue rien hors de l'accord. Un arpège qui en ajoute une joue une fausse note chaque fois qu'il y arrive.

## Une progression et sa tonalité

Pour une progression, l'oracle cherche d'abord la tonalité. Pour chacune des douze gammes majeures, il compte les notes des accords qui tombent en dehors, et garde la gamme qui en a le moins ; C majeur et A mineur ont les mêmes notes, et comptent donc pour une seule. Puis il donne à chaque accord les notes de la tonalité, lues à partir de la fondamentale de l'accord. C'est le tableau par lequel commence tout cours de théorie accord–gamme : ionien sur I, dorien sur ii, phrygien sur iii, lydien sur IV, mixolydien sur V, éolien sur vi et locrien sur vii ([Open Music Theory, section 6.7](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory)).

Les colonnes : la gamme principale du skill ; ses notes *étrangères*, celles qui ne sont ni dans la tonalité ni dans l'accord ; la gamme des manuels ; le rang de la gamme des manuels dans la propre liste du skill, `-` quand elle n'y est pas ; et le verdict.

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits Dm7 G7 Cmaj7") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Dm7    Dm7       D Dorian                   -         D Dorian                  1      same
G7     G7        G Mixolydian               -         G Mixolydian              1      same
Cmaj7  Cmaj7     C Ionian (major)           -         C Ionian                  1      same

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am F C G") against the key
key: C major / A minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
F      F         F Ionian (major)           Bb        F Lydian                  2      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Em C G D") against the key
key: G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Em     Em        E Aeolian (natural minor)  -         E Aeolian                 1      same
C      C         C Ionian (major)           F         C Lydian                  2      DIFF
G      G         G Ionian (major)           -         G Ionian                  1      same
D      D         D Ionian (major)           C#        D Mixolydian              -      DIFF
```

Le ii–V–I concorde sur chaque accord : les qualités écrites, m7, 7 et maj7, se trouvent nommer les bons modes. Pas les triades. Une triade de F majeur est le même accord, qu'elle soit le I de F ou le IV de C, et seule la tonalité permet de trancher. Sur Am F C G, le skill joue B♭ sur F et F♯ sur G ; sur Em C G D, F bécarre sur C et C♯ sur D. F lydien et C lydien sont les deuxièmes choix du skill ; G mixolydien et D mixolydien ne figurent même pas dans sa liste pour une triade majeure.

## Des accords hors de la tonalité

C'est sur un accord étranger à la tonalité que le commentaire de GA marque un point, et l'oracle y répond par une seule règle : garder les notes de la tonalité, mais remplacer chaque note de la tonalité par la note de l'accord qui porte la même lettre.

```csharp
// Les notes de la tonalité, chaque note de l'accord à la place de la note de même lettre, lues
// depuis la fondamentale : le mode de la tonalité pour un accord diatonique et, pour une dominante
// secondaire, les notes de la tonalité autour de celles de l'accord (A en C majeur : A B C# D E F G)
static List<Note> Textbook(List<Note> chord, int k)
{
    var byLetter = Key(k).ToDictionary(n => n.Letter, n => n.Pc);
    foreach (var tone in chord) byLetter[tone.Letter] = tone.Pc;
    return Enumerable.Range(0, 7).Select(i => (chord[0].Letter + i) % 7).Select(l => new Note(l, byLetter[l])).ToList();
}
```

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C A Dm G") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
A      A         A Ionian (major)           F# G#     A Mixolydian b6           -      DIFF
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF

== ImprovisationSkill.ExecuteAsync("which arpeggio fits Am Dm E") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
Am     Am        A Aeolian (natural minor)  -         A Aeolian                 1      same
Dm     Dm        D Aeolian (natural minor)  Bb        D Dorian                  2      DIFF
E      E         E Ionian (major)           F# C# D#  E Phrygian dominant       -      DIFF
```

Dans C A Dm G, l'accord de A majeur est la dominante de D mineur. Son C♯ remplace C, et la gamme est A B C♯ D E F G, A mixolydien ♭6 : elle garde la tierce de l'accord, celle que rate la méthode par degrés que rejette le commentaire de GA. L'enseignement accord–gamme de Berklee construit de la même façon les gammes des dominantes secondaires, à partir des notes de l'accord et des autres notes de la tonalité, et appelle celle-ci mixolydien ♭13 pour V7/II (Nettles et Graf, voir les sources ; *à vérifier* dans le livre). Le A ionien de GA garde lui aussi le C♯, mais ajoute F♯ et G♯, que n'ont ni la tonalité ni l'accord.

Dans Am Dm E, l'accord de E majeur est la dominante de A mineur, avec la sensible G♯. La règle donne E F G♯ A B C D, E phrygien dominant, « the fifth mode of the harmonic minor scale, the fifth being the dominant », le cinquième mode de la mineure harmonique, que la méthode de Berklee appelle mixolydien ♭9 ♭13 ([Wikipédia](https://en.wikipedia.org/wiki/Phrygian_dominant_scale)). Le E ionien de GA ajoute trois notes étrangères, F♯, C♯ et D♯, sur l'accord qui ramène la phrase à la tonique.

Les accords mineurs subissent la même erreur que les triades majeures. Dm reçoit l'éolien, la première gamme que le skill liste pour une triade mineure, avec son B♭. Dans les deux progressions, D mineur est le ii ou le iv de la tonalité et prend le dorien, le deuxième choix du skill.

Le choix n'est donc pas entre la tonalité et la qualité écrite. Les manuels se servent des deux : les notes de l'accord viennent de son chiffrage, toutes les autres de la tonalité.

## Quand la tonalité est ambiguë

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C G") against the key
key: C major / A minor or G major / E minor; chord tones outside it: 0

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           - | F     C Ionian | C Lydian       1 | 2  same in C major / A minor
G      G         G Ionian (major)           F# | -    G Mixolydian | G Ionian   - | 1  same in G major / E minor
```

C et G vont aussi bien en C majeur qu'en G majeur, sans aucune note d'accord hors de l'une ou de l'autre. L'oracle le dit, et note chaque accord dans les deux tonalités, séparées par `|`. Les deux réponses du skill sont chacune juste dans une tonalité et fausse dans l'autre : C ionien est la lecture en C majeur, G ionien celle en G majeur. Jouées tour à tour sur une boucle C–G, elles passent de F à F♯ à chaque changement d'accord. Le ticket de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744) demande que ce cas soit traité : dire que la tonalité est ambiguë plutôt que d'en choisir une en silence.

Am F C G, en revanche, n'est pas ambigu en ce sens. C majeur et A mineur ont les mêmes notes : chaque accord reçoit donc la même gamme, quel que soit le nom qu'on donne à la tonalité ; seules les notes décident.

## Où l'oracle s'arrête

```text
== ImprovisationSkill.ExecuteAsync("which arpeggio fits C Fm G C") against the key
key: C major / A minor; chord tones outside it: 1

chord  arpeggio  GA lead scale              foreign   textbook                  rank   verdict
C      C         C Ionian (major)           -         C Ionian                  1      same
Fm     Fm        F Aeolian (natural minor)  Bb Db Eb  F (0 2 3 6 7 9 11)        -      DIFF
G      G         G Ionian (major)           F#        G Mixolydian              -      DIFF
C      C         C Ionian (major)           -         C Ionian                  1      same
```

F mineur en C majeur est un accord d'emprunt, le iv pris à C mineur. La règle met A♭ dans les notes de C majeur et obtient F G A♭ B C D E, soit les écarts `0 2 3 6 7 9 11` en demi-tons : aucune gamme qu'on enseigne sur F mineur, et c'est pourquoi le programme affiche ses écarts au lieu d'un nom. La réponse habituelle prend les notes de la tonalité d'où l'accord est emprunté, ce qui donne F dorien si la source est C mineur naturel (*à vérifier* dans Nettles et Graf). L'oracle connaît une tonalité et ne sait pas en trouver une seconde. Sur cette ligne, DIFF dit seulement que les deux réponses diffèrent, pas laquelle est juste : ici, aucune ne l'est. Les notes étrangères sont mesurées par rapport à la gamme de l'oracle : elles ne veulent donc rien dire non plus sur cette ligne.

L'oracle ne vérifie pas non plus le reste de la théorie accord–gamme : les tensions et les notes à éviter, le chemin à un accord, qui a besoin d'un modèle pour extraire l'accord, ni rien de mélodique. La critique qu'Open Music Theory fait elle-même de la méthode décrit de près la conception de GA : la théorie accord–gamme « can lead a student to see each chord as a new key center, instead of viewing an entire chord progression as derived from a parent scale », peut amener un élève à voir chaque accord comme un nouveau centre tonal au lieu de voir toute la progression comme dérivée d'une gamme mère. Un skill qui classe chaque accord seul, sans tonalité, c'est cette critique écrite en C#.

## Signalé en amont

- Les gammes aveugles à la tonalité du chemin des progressions : ticket de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744), ouvert le 2026-09-28 à la suite d'un tracer lancé contre le chatbot public, avec les cas Am F C G et C A Dm G de cette leçon.
- Les défauts vus dans « Un accord à la fois », à savoir le tokenizer, l'ordre de `InferQuality`, les accords suspendus et le power chord inconnus, et l'arpège de `m6` : non signalés en amont au moment où cette leçon a été écrite. Ils sont listés dans le [journal](../journal/).

## Exercices

1. Sans rien exécuter, prédis les verdicts pour « which arpeggio fits Bb Gm Cm F ». Quelle gamme le skill donne-t-il à chaque accord, et lesquelles de ses notes sont étrangères ?
2. Modifie le tokenizer pour que `C7sus4` et `CmMaj7` soient lus et que `Cmaj7#5` ne soit pas tronqué. Fais ensuite en sorte qu'un accord qu'il ne sait toujours pas lire ne disparaisse pas en silence. Qu'ajouterais-tu ?
3. Modifie `InferQuality` pour que `Cm7#5` soit un accord mineur. Quelle étiquette d'arpège et quelles gammes devrait-il recevoir ?
4. Le ticket #744 demande un test d'adéquation à la tonalité dans GA. Quelles vérifications de l'oracle de cette leçon porterais-tu en tests unitaires, et lesquelles laisserais-tu de côté ?

<details>
<summary>Solutions</summary>

1. La tonalité est B♭ majeur, sans aucune note d'accord en dehors. B♭ reçoit B♭ ionien et Gm G éolien, tous deux justes (I et vi). Cm reçoit C éolien, dont le A♭ est étranger : les manuels donnent C dorien (ii), le deuxième choix du skill. F reçoit F ionien, dont le E bécarre est étranger : les manuels donnent F mixolydien (V), qui n'est pas dans la liste du skill. Vérifié avec le programme du cours le 2026-09-28, en ajoutant la progression à `Progressions` le temps d'une exécution.
2. Ajoute les qualités manquantes à la liste, chacune avant son préfixe plus court : `7sus4` et `7sus2` avant `7`, `maj7#5` avant `maj7`, et `mMaj7`. Pour la disparition silencieuse, compare les mots du message qui commencent par une lettre d'accord avec les accords lus, et nomme dans la réponse ceux qui n'ont pas été lus, par exemple « I couldn't read Cmaj7#5 ». Non compilé contre GA (*à vérifier*).
3. Teste `m7#5` avant la famille augmentée, comme `m7b5` est déjà testé avant la famille diminuée. L'accord est C E♭ G♯ B♭, et G♯ est l'enharmonique de A♭ : C éolien et C phrygien contiennent donc ses quatre notes. L'étiquette d'arpège devrait être `Cm7#5`, ce qui demande une qualité à part entière : `Minor7` afficherait `Cm7`. Non compilé contre GA (*à vérifier*).
4. Porte les vérifications qui ne dépendent d'aucune tradition d'enseignement : chaque note de l'accord est dans la gamme principale ; l'arpège n'ajoute aucune note ; quand une tonalité contient toutes les notes des accords, la gamme principale n'a aucune note hors de cette tonalité. Fige C A Dm G, pour que la gamme de l'accord de A garde son C♯ et n'ait ni F♯ ni G♯. Laisse de côté les noms de gammes et la règle des accords d'emprunt : la ligne C Fm G C montre que cette règle n'est pas tranchée, et #744 lui-même laisse ouverte la règle de déduction de la tonalité, comme une décision de conception.

</details>

## À retenir

- Le skill d'improvisation de GA répond sans modèle aux questions sur une progression : il lit les chiffrages d'accords avec une expression régulière, classe chaque accord d'après sa qualité écrite, et donne un arpège et une liste classée de gammes.
- Classer chaque accord seul évite l'erreur de la méthode par degrés que décrit le commentaire de GA, mais perd la tonalité : sur Am F C G, le skill joue B♭ sur F et F♯ sur G.
- La gamme des manuels pour un accord puise aux deux sources : les notes de l'accord viennent de son chiffrage, toutes les autres de la tonalité. Cette règle couvre les accords diatoniques et les dominantes secondaires, pas les accords d'emprunt.
- Le tokenizer abandonne ou tronque en silence les accords qu'il ne connaît pas, et l'ordre fixe de `InferQuality` lit mal `Cm7#5`, `C7#11`, les accords suspendus et le power chord. Dans les pires cas, l'arpège contient une note que l'accord n'a pas.
- Un oracle n'est utile que s'il dit où il s'arrête : sur la ligne de l'accord d'emprunt, DIFF signifie que les deux réponses sont fausses.

## Sources

- GuitarAlchemist/ga au commit [`a826864`](https://github.com/GuitarAlchemist/ga/tree/a826864f3a012cad88e415954bf57eca0ce12aa6) : `Common/GA.Business.ML/Agents/Skills/ImprovisationSkill.cs`, inchangé sur `main` au commit `8cd5042` le 2026-09-28.
- Ticket de GA [#744](https://github.com/GuitarAlchemist/ga/issues/744), ouvert le 2026-09-28.
- Mark Gotham, Kyle Gullings, Chelsey Hamm, Bryn Hughes, Brian Jarvis, Megan Lavengood et John Peterson, *Open Music Theory*, 2e édition, [section 6.7, "Chord-Scale Theory"](https://human.libretexts.org/Bookshelves/Music/Music_Theory/Open_Music_Theory_2e_%28Gotham_et_al.%29/06%3A_Jazz/6.07%3A_Chord-Scale_Theory), CC BY-SA 4.0, lu le 2026-09-28.
- Wikipédia, ["Phrygian dominant scale"](https://en.wikipedia.org/wiki/Phrygian_dominant_scale) et ["Chord-scale system"](https://en.wikipedia.org/wiki/Chord-scale_system), pour l'origine de la méthode dans le *Lydian Chromatic Concept of Tonal Organization* de George Russell (1953) ; lus le 2026-09-28.
- Barrie Nettles et Richard Graf, *The Chord Scale Theory & Jazz Harmony*, Advance Music, 1997 : la référence de Berklee pour les gammes des dominantes secondaires et des accords d'emprunt. Pas lu par ce cours ; les deux affirmations qui s'appuient dessus sont marquées *à vérifier*.
- Microsoft Learn : [Générateurs de source d'expressions régulières .NET](https://learn.microsoft.com/dotnet/standard/base-types/regular-expression-source-generators), [`NullLogger<T>`](https://learn.microsoft.com/dotnet/api/microsoft.extensions.logging.abstractions.nulllogger-1), [`JsonSerializer.SerializeToElement`](https://learn.microsoft.com/dotnet/api/system.text.json.jsonserializer.serializetoelement).
