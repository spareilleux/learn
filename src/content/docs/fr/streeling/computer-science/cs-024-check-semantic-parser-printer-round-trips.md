---
title: Vérifier le sens après un aller-retour entre analyseur et imprimeur
description: Vérifier le sens après un aller-retour entre analyseur et imprimeur — Informatique
sidebar:
  label: CS-024 · Vérifier le sens après un aller-retour entre analyseur et imprimeur
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-024-check-semantic-parser-printer-round-trips.fr.md
---

:::note[Streeling University]
**CS-024** · Vérifier le sens après un aller-retour entre analyseur et imprimeur · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-024-check-semantic-parser-printer-round-trips.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-019](../../computer-science/cs-019-preserve-lexical-bindings-when-composing-fragments/), [SEM-002](../../semiotics/sem-002-chord-symbols-and-canonicalization/)
:::

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un agent qui explique GA peut reformuler une petite expression pour la rendre lisible avant de la transmettre à un auteur de pipeline IX. Une présentation soignée peut modifier le groupement. À l’inverse, un imprimeur peut préserver toutes les opérations en changeant les espaces. Il faut donc préciser quelle représentation doit survivre au transfert avant de comparer les chaînes ou de vanter une simplification DSL.

Le langage du cas contient des entiers, des additions, des multiplications et des parenthèses. Analysez la source en arbre ordonné, imprimez une proposition, puis analysez-la avec la même grammaire. Comparez récursivement les arbres. La documentation AST de Python illustre une garantie d’arbre équivalent sans garantie de texte identique. Nous reprenons cette distinction ; cette petite grammaire n’est ni Python ni un nouvel analyseur GA.

Le cas fixé garde la multiplication dans le fils droit de l’addition. Le résultat est préservé, mais les chaînes diffèrent. Une simple égalité numérique serait moins probante : des arbres différents pourraient donner par hasard le même nombre. Le contrôle place délibérément l’addition sous la multiplication et change structure et résultat. Gardez le premier nœud différent comme diagnostic.

Avant de proposer un formateur ou une réécriture par agent, décidez si commentaires, graphie et mise en page font partie du besoin. Un arbre qui les omet ne peut les restituer. Le prérequis sur les liaisons lexicales traite un autre échec, lié aux noms ; notre grammaire sans noms isole la priorité. Une grammaire enrichie devrait vérifier les deux. La tâche est une comparaison d’arbres sur papier avec un critère de réfutation, sans autorisation de remplacer l’analyseur de production.

Le prérequis de sémiotique suit déjà l’analyse et le rendu canonique de GA, avec des alias convergents. La canonicalisation est donc acquise. La vérification supplémentaire réanalyse l’expression imprimée et compare l’arbre ordonné complet ; le groupement modifié réfute une fausse loi d’aller-retour.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cs-019-preserve-lexical-bindings-when-composing-fragments](../../computer-science/cs-019-preserve-lexical-bindings-when-composing-fragments/)

[Prérequis: sem-002-chord-symbols-and-canonicalization](../../semiotics/sem-002-chord-symbols-and-canonicalization/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://docs.python.org/3/library/ast.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "source": "1 + 2 * 3",
    "printed": "1+(2*3)"
  },
  "formula": "Parse nonnegative decimal integers, +, *, and parentheses; multiplication binds tighter than addition, both left-associative. AST uses [lit,n], [add,left,right], [mul,left,right]. Compare parsed ASTs and evaluate recursively.",
  "expected": {
    "source_ast": [
      "add",
      [
        "lit",
        1
      ],
      [
        "mul",
        [
          "lit",
          2
        ],
        [
          "lit",
          3
        ]
      ]
    ],
    "printed_ast": [
      "add",
      [
        "lit",
        1
      ],
      [
        "mul",
        [
          "lit",
          2
        ],
        [
          "lit",
          3
        ]
      ]
    ],
    "same_ast": true,
    "same_text": false,
    "values": [
      7,
      7
    ]
  },
  "negative_control": {
    "values": {
      "source": "1 + 2 * 3",
      "printed": "(1+2)*3"
    },
    "expected": {
      "source_ast": [
        "add",
        [
          "lit",
          1
        ],
        [
          "mul",
          [
            "lit",
            2
          ],
          [
            "lit",
            3
          ]
        ]
      ],
      "printed_ast": [
        "mul",
        [
          "add",
          [
            "lit",
            1
          ],
          [
            "lit",
            2
          ]
        ],
        [
          "lit",
          3
        ]
      ],
      "same_ast": false,
      "same_text": false,
      "values": [
        7,
        9
      ]
    },
    "why": "Moving parentheses changes the grouping, not merely whitespace."
  },
  "input_types": {
    "source": "expression string in the declared grammar",
    "printed": "expression string in the declared grammar"
  },
  "assumptions": [
    "No names, floating-point rounding, effects or compiler optimizations.",
    "Tree equality compares tags and ordered children, ignoring no semantic node."
  ],
  "limits": "A few exact trees do not certify an entire GA or IX grammar or establish source-comment preservation."
}
```

### Exercice 1

Quel est l’arbre source ?

<details><summary>Réponse 1</summary>

Sa racine est `add`, son fils gauche `lit(1)` et son fils droit `mul(lit(2),lit(3))`. La multiplication est prioritaire ; la source vaut `7`.

</details>

### Exercice 2

L’imprimeur fixé respecte-t-il le contrat ?

<details><summary>Réponse 2</summary>

Oui : les arbres analysés concordent et valent tous deux `7`, tandis que l’égalité textuelle vaut `false`. Ce contrat sémantique permet une différence d’espacement.

</details>

### Exercice 3

Évaluez le groupement modifié.

<details><summary>Réponse 3</summary>

Le contrôle a pour racine `mul` et vaut `9`. Son arbre différent réfute la garantie d’aller-retour, même si la présentation paraît agréable.

</details>

### Exercice 4

Une valeur égale prouverait-elle l’égalité des arbres ?

<details><summary>Réponse 4</summary>

Non. Des opérations distinctes peuvent coïncider sur certaines entrées. Gardez les étiquettes et l’ordre des fils ; précisez séparément si commentaires et disposition exigent une représentation sans perte.

</details>

### Exercice 5

Quelles preuves justifieraient une réécriture par agent ?

<details><summary>Réponse 5</summary>

Une grammaire versionnée, les arbres manuels, le groupement rejeté et une couverture des constructions pertinentes. Ce cas ne couvre que les expressions déclarées, sans exécution de l’analyseur de production.

</details>

## Travail avec consultation des sources

Annotez une réécriture proposée par un agent dans une explication transmise de GA à IX.

**Référence manuelle directe:** Dessinez les arbres ordonnés à la main et repérez leur premier nœud différent.

**Critère de réfutation:** Une proposition censée préserver l’arbre change une étiquette ou le groupement des fils.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Quel est l’arbre source ? — Décision indéterminée.
- Exercice 2: L’imprimeur fixé respecte-t-il le contrat ? — Décision indéterminée.
- Exercice 3: Évaluez le groupement modifié. — Décision indéterminée.
- Exercice 4: Une valeur égale prouverait-elle l’égalité des arbres ? — Décision indéterminée.
- Exercice 5: Quelles preuves justifieraient une réécriture par agent ? — Décision indéterminée.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
