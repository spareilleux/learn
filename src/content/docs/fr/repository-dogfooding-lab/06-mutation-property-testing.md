---
title: "6. Tests de mutation et de propriétés sur un vrai parseur"
description: Un labo borné et pré-inscrit sur le parseur de hauteurs de GA. Stryker.NET mesure les fautes que les tests détectent ; des propriétés FsCheck vérifient le contrat public ; un témoin négatif prouve que le banc peut échouer.
sidebar:
  order: 6
---

:::caution[Portée de la preuve]
Un seul fichier d'un seul dépôt, à un seul commit épinglé : [`PitchParser.cs`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/PitchParser.cs) dans GuitarAlchemist/ga à `aa22f91`. Mesuré sous Windows 11 seulement ; Linux et macOS sont *à vérifier*. Rien ici ne dit quoi que ce soit de la qualité des tests de GA dans son ensemble.
:::

Une suite de tests verte dit que les tests écrits passent. Elle ne dit pas s'ils remarqueraient un bogue. Deux techniques posent cette seconde question par deux côtés opposés :

- Le **test de mutation** modifie le code de production par petites touches (un `<` en `<=`, un `true` en `false`) et relance les tests. Une modification que les tests remarquent est *tuée* ; une modification qui leur échappe *survit*. [Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/) fait cela pour .NET.
- Le **test de propriétés** énonce une règle qui doit tenir pour toute entrée et laisse un générateur chercher un contre-exemple. [FsCheck](https://fscheck.github.io/FsCheck/) génère les entrées et, quand l'une échoue, la *réduit* (*shrinking*) à un cas minimal.

Cette leçon applique les deux à une vraie fonction, avec des hypothèses écrites avant toute mesure.

## La jointure

`PitchParser` est une classe `internal` de `GA.Domain.Core`. Elle transforme un texte comme `C#4` ou `Bb3` en hauteur. Ses seuls appelants sont les méthodes publiques [`Pitch.Sharp.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L114) et [`Pitch.Flat.TryParse`](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/Pitch.cs#L285). Le labo ne teste que ces deux points d'entrée publics : pas d'`InternalsVisibleTo`, pas de réflexion, et aucune modification de GA.

Le cœur du parseur est une expression régulière ancrée par type d'altération :

```csharp
// PitchParser.cs:7-8 à aa22f91
new(@"\A([A-G])(#?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // dièse
new(@"\A([A-G])(b?)(-1|[0-9])\z", PcreOptions.Compiled | PcreOptions.IgnoreCase);  // bémol
```

Après une correspondance, le code vérifie de nouveau que chaque groupe est défini et analyse chaque morceau, en renvoyant `false` au moindre échec (lignes 36 à 68).

## Pré-inscrire avant de mesurer

La [pré-inscription](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/results/preregistration.md) a été écrite et hachée avant la première compilation. Son SHA-256 a été consigné dans un fichier séparé. Elle fixe :

- **B (référence) :** Stryker avec le projet de tests propre à GA, en ne mutant que `PitchParser.cs`.
- **T (traitement) :** la même commande, avec le projet de propriétés du labo en plus.
- **Détection :** seul *Killed* compte. Les dépassements de délai seraient rapportés à part, jamais comme des mutants tués.
- **H1 :** B laisse au moins un mutant Survived ou NoCoverage ; les candidats probables sont les vérifications défensives que la regex garantit déjà.
- **H2 :** T tue au moins un mutant que B a laissé en vie, en n'affirmant que ce que les tests de GA affirment déjà.
- **H3 :** aucune entrée (null, vide, blancs, Unicode arbitraire) ne fait lever d'exception à l'un ou l'autre `TryParse`, sur 10 000 cas par propriété.
- **Témoin négatif :** une propriété volontairement fausse, qui doit échouer, se réduire et se rejouer depuis sa graine.
- **Budget :** un fichier, concurrence 2, 10 minutes par exécution, aucune compilation de la solution complète.

Une correction faite après le hachage n'est pas cachée : elle va dans une section *Post-measurement edits*, avec sa date et sa raison. Ce labo en compte trois, dont un bogue de générateur attrapé avant toute exécution : préfixer `b3` par `b` donne `bb3`, un bémol valide, donc une entrée « malformée » ne l'était pas.

## Les propriétés

Les hauteurs valides sont construites à partir de petits entiers et de booléens, que FsCheck sait réduire. Le texte est dérivé à l'intérieur de la propriété :

```csharp
private static Spelling FromParts(Kind kind, byte letter, bool accidental, bool lowerCase, byte octave)
{
    var upper = "ABCDEFG"[letter % 7];
    var octaveValue = octave % 11 - 1;
    var acc = accidental ? Accidental(kind) : "";
    var text = $"{(lowerCase ? char.ToLowerInvariant(upper) : upper)}{acc}{octaveValue}";
    return new Spelling(kind, text, $"{upper}{acc}{octaveValue}");
}
```

Le [fichier de tests](https://github.com/spareilleux/learn/blob/main/code/repository-dogfooding-lab/test-quality/PitchParserProperties/PitchParserPropertyTests.cs) contient cinq propriétés et un test par l'exemple :

| Test | Oracle |
|---|---|
| Dièse valide / bémol valide | `TryParse` renvoie vrai et `ToString()` affiche la forme canonique (`c#4` → `C#4`) |
| Dièse malformé / bémol malformé | Une modification tirée d'une liste fermée (lettre en trop, espace, chiffre, octave hors plage, l'autre altération, une altération doublée, pas d'octave) fait renvoyer faux à `TryParse` |
| Chaîne quelconque | Aucune exception ; un texte accepté se ré-analyse en le même texte |
| Null, vide, blancs | Refusés sans exception |

## L'exécuter

Depuis `code/repository-dogfooding-lab/test-quality/`, dans un shell POSIX (Git Bash sous Windows) :

```bash
bash fetch-ga.sh                                    # extraction partielle de GA à aa22f91 dans .ga/ (12 Mo)
dotnet tool restore                                 # dotnet-stryker 5.0.0 depuis dotnet-tools.json
dotnet test PitchParserProperties -c Release --filter "TestCategory!=NegativeControl"
dotnet test PitchParserProperties -c Release --filter "TestCategory=NegativeControl"   # doit échouer
dotnet tool run dotnet-stryker -f stryker-config.baseline.json -O out/stryker-B        # B
dotnet tool run dotnet-stryker -f stryker-config.json -O out/stryker-T                 # T
```

## Ce qui a été mesuré (2026-09-26, Windows 11, SDK .NET 10.0.112)

| Exécution | Tests | Killed | Survived | NoCoverage | Ignored | Timeout | Score | Durée |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| B — tests de GA | 706 | 25 | 0 | 5 | 9 | 0 | 83,33 % | 109 s |
| T — GA + propriétés | 710 dans le rapport | 25 | 0 | 5 | 9 | 0 | 83,33 % | 142 s |
| P — propriétés seules (exploratoire) | 6 | 25 | 0 | 5 | 9 | 0 | 83,33 % | 93 s |

Stryker génère 39 mutants dans le fichier. Le score vaut Killed divisé par Killed + Survived + NoCoverage, soit 25/30. Les 9 mutants *Ignored* se trouvent dans des blocs que Stryker avait déjà mutés en entier.

- **H1 confirmée.** B laisse 5 mutants sans couverture : `return false` changé en `return true` aux lignes 38, 43, 49, 58 et 67. Les cinq sont dans les branches défensives qui suivent une correspondance réussie de la regex.
- **H2 réfutée.** T tue exactement les mêmes 25 mutants. Les 5 mêmes restent non couverts, car aucune entrée décrite par le contrat public ne les atteint.
- **H3 tient pour cette graine.** 10 000 cas par propriété, et aucune exception.
- **Témoin négatif :** `Falsifiable, after 2 tests (2 shrinks)`, réduit à `a#-1` (le parseur dièse l'accepte, le parseur bémol non), et une sortie identique à une seconde exécution depuis la graine `(20260926,7)`.

L'exécution **P** ne figurait pas dans la pré-inscription. Elle a été déclarée dans la section post-mesure après T et avant son lancement, et elle est rapportée comme exploratoire. Elle répond à une question que T ne pouvait pas trancher : les six tests de propriétés détectent-ils *à eux seuls* ce que détectent les 706 tests de GA dans ce fichier ? Oui : les mêmes 25 mutants tués. La plupart des premiers « tueurs » sont les deux propriétés « valides », 20 chacune.

## Lire le résultat honnêtement

Trois conclusions sont défendables :

1. Les tests existants de GA tuent déjà tout mutant de ce fichier atteignable depuis l'extérieur.
2. Les cinq mutants non couverts sont probablement **inatteignables** depuis l'API publique : la regex refuse les entrées qui feraient s'exécuter ces branches. Pour la ligne 58, `FlatAccidental.TryParse` met son entrée en minuscules ([FlatAccidental.cs:96](https://github.com/GuitarAlchemist/ga/blob/aa22f9101d5bb86800ff2819381f97986fc81fb1/Common/GA.Domain.Core/Primitives/Notes/FlatAccidental.cs#L96)), donc même `CB4` ne devrait pas l'atteindre. C'est une lecture du code, pas une exécution : *à vérifier*. Du code inatteignable est une observation de conception, pas un trou de tests. Aucun test ne peut tuer un mutant équivalent.
3. Une poignée de propriétés a égalé une grande suite d'exemples sur ce seul fichier. Cela ne dit rien des autres fichiers. Ici, le contrat est petit et la regex fait l'essentiel du travail.

Une affirmation n'est pas défendable : que les tests de propriétés « ont amélioré les tests de GA ». Ils ne l'ont pas fait ici, et le tableau le montre.

## Ce que cela **n'établit pas**

- Rien sur aucun autre fichier de GA, ni sur le score de mutation global de GA. Stryker a créé 4 781 mutants dans le projet, dont 4 439 ignorés par le filtre de mutation.
- Aucun code de production n'a été modifié, et aucune issue n'a été ouverte chez GA. Garder ou non les branches défensives relève du mainteneur.
- Stryker a aussi signalé 303 mutants en erreur de compilation ailleurs dans le projet, hors du filtre. Ils n'affectent pas les chiffres de ce fichier.
- Les 710 tests du rapport de T ne sont pas réconciliés avec 706 + 6 : *à vérifier*.
- Il n'y a eu ni exécution en CI, ni exécution sous Linux ou macOS.

## Exercices

1. Faites passer le témoin négatif en corrigeant son affirmation, pas le parseur. Quelle est la plus petite affirmation vraie sur l'analyse des dièses et des bémols que vous pouvez écrire comme une propriété ?
2. Ajoutez une modification malformée à la liste fermée : une lettre hors de `A–G` à la place de la note, comme `H4`. Exécutez les propriétés « malformées ». Le score change-t-il ? Expliquez pourquoi.
3. Retirez la restriction sur les préfixes (autorisez un `b` ou n'importe quelle lettre de note) et exécutez la propriété bémol malformé. Que rapporte FsCheck, et qu'est-ce que cela vous apprend sur les générateurs ?
4. Trouvez une entrée écrite à la main qui atteint la ligne 58 par `Pitch.Flat.TryParse`, ou montrez à partir du code qu'il n'en existe aucune.

<details>
<summary>Solutions</summary>

1. Par exemple : « un texte accepté par les deux parseurs ne contient aucune altération ». Les deux regex acceptent une hauteur naturelle, et une seule accepte chaque altération. Écrivez-la avec `Prop.ForAll(Parts, …)`, et sortez-la de la catégorie `NegativeControl` une fois qu'elle est vraie.
2. Le score ne change pas. La regex refuse déjà `H`, donc la nouvelle modification exerce un chemin que les propriétés valides tuent déjà : la branche `!match.Success` de la ligne 28. Une nouvelle modification n'aide que si elle atteint une branche qu'aucun test n'atteint encore.
3. FsCheck rapporte un cas falsifié comme `bb3` ou `Ab3` pour le parseur bémol, qui sont des bémols valides. C'est le générateur qui avait tort, pas le parseur. C'est exactement le défaut attrapé ici avant la première exécution. Les générateurs sont du code eux aussi, et une propriété ne vaut que ce que vaut le domaine qu'elle échantillonne.
4. La regex laisse passer `b` ou `B` comme groupe bémol. `FlatAccidental.TryParse` met son entrée en minuscules et accepte `b`, donc elle ne renvoie jamais faux pour ce que la regex laisse passer. Aucune entrée n'atteint la ligne 58, et le mutant qui s'y trouve est équivalent. Vérifiez-le en exécutant `Pitch.Flat.TryParse("CB4", null, out var p)` : le résultat devrait être vrai et afficher `Cb4`. Ce labo n'a pas exécuté cette vérification.

</details>

## Sources

- [Documentation de Stryker.NET](https://stryker-mutator.io/docs/stryker-net/introduction/), et sa [référence de configuration](https://stryker-mutator.io/docs/stryker-net/configuration/).
- [Documentation de FsCheck](https://fscheck.github.io/FsCheck/), le [guide des propriétés](https://fscheck.github.io/FsCheck/Properties.html), et [NUnit](https://docs.nunit.org/) pour l'exécuteur de tests.
- Code du labo et résultats bruts : [`code/repository-dogfooding-lab/test-quality`](https://github.com/spareilleux/learn/tree/main/code/repository-dogfooding-lab/test-quality). Le [journal](../journal/) contient l'entrée datée.
