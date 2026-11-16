---
title: Vérifier les contraintes de direction aux changements de corde
description: Vérifier les contraintes de direction aux changements de corde — Études de guitare
sidebar:
  label: GTR-018 · Vérifier les contraintes de direction aux changements de corde
  order: 18
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-studies/fr/gtr-018-check-direction-constraints-at-string-crossings.fr.md
---

:::note[Streeling University]
**GTR-018** · Vérifier les contraintes de direction aux changements de corde · avancé · 45 minutes

Généré par le département *Études de guitare* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-studies/fr/gtr-018-check-direction-constraints-at-string-crossings.fr.md) · [Mon journal](../../journal/)

Prérequis: [GTR-007](../../guitar-studies/gtr-007-carry-picking-phase-across-bar-lines/)
:::

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un assistant peut conserver correctement les étiquettes de coups tout en omettant la corde que le médiator doit rejoindre. Une suite valide comme horloge symbolique peut contredire une politique de balayage continu. Nous vérifions le sens du changement entre cordes successives. La géométrie complète ainsi le suivi de phase sur une corde du prérequis, sans décider du confort réel.

Déclarez d’abord le sens de numérotation. Selon notre politique, des coups descendants répétés entre cordes différentes continuent vers les numéros plus petits. Les coups montants exigent le sens inverse. Un changement de coup ou une répétition sur la même corde échappe seulement à cette exclusion ; il n’est pas déclaré facile. La règle interdit un repositionnement aérien non consigné. Un guitariste peut choisir une autre politique, mais le modèle et les preuves nécessaires doivent alors changer explicitement.

La phrase principale inverse le déplacement en gardant le même coup : une transition passe et l’autre échoue. Le témoin monotone supprime ce retournement sans modifier les coups symboliques. Il sépare donc géométrie et arithmétique de phase. Conservez la transition fautive plutôt qu’un simple total de coups descendants. Le support de pratique motive un relevé d’instructions, sans jeu réel ni sortie d’un solveur GA. Un schéma manuel de flèches suffit avant de proposer une abstraction de trajectoire.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-studies/gtr-007-carry-picking-phase-across-bar-lines/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "strings": [
      3,
      2,
      3
    ],
    "strokes": [
      "D",
      "D",
      "D"
    ]
  },
  "formula": "for equal consecutive strokes on different strings: legal iff (D and next_string<previous_string) or (U and next_string>previous_string); otherwise legal; plan_legal=all(transition_legal)",
  "expected": {
    "transition_legal": [
      true,
      false
    ],
    "plan_legal": false
  },
  "negative_control": {
    "values": {
      "strings": [
        3,
        2,
        1
      ],
      "strokes": [
        "D",
        "D",
        "D"
      ]
    },
    "expected": {
      "transition_legal": [
        true,
        true
      ],
      "plan_legal": true
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez la numérotation déclarée et un balayage continu pour des coups successifs identiques entre cordes, sans repositionnement aérien. C’est une politique restreinte, pas une loi biomécanique ni un avis de confort.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Repérez le sens du premier changement de corde.

<details><summary>Réponse 1</summary>

Il va vers un numéro plus petit et respecte le balayage descendant répété déclaré.

</details>

### Exercice 2

Pourquoi la seconde transition échoue-t-elle ?

<details><summary>Réponse 2</summary>

Elle inverse le déplacement tout en gardant le coup descendant, ce que le balayage continu exclut.

</details>

### Exercice 3

Une autre politique pourrait-elle autoriser un repositionnement aérien ?

<details><summary>Réponse 3</summary>

Oui, éventuellement, mais elle ajoute une action et un besoin temporel absents des étiquettes actuelles.

</details>

### Exercice 4

Pourquoi le témoin monotone passe-t-il ?

<details><summary>Réponse 4</summary>

Chaque changement avec le même coup suit le sens de numérotation permis par la règle.

</details>

### Exercice 5

Qu’est-ce qui réfute une conclusion universelle sur la technique ?

<details><summary>Réponse 5</summary>

La table suppose une politique restreinte et ne contient aucune observation de joueur ; elle ne prouve ni impossibilité générale ni confort.

</details>

## Travail avec consultation des sources

Dessinez chaque déplacement du médiator, puis annotez le plan avec sa politique de mouvement. Gardez la transition fautive comme témoin.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
