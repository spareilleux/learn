---
title: Examiner les lectures et écritures avant de réordonner
description: Examiner les lectures et écritures avant de réordonner — Informatique
sidebar:
  label: CS-022 · Examiner les lectures et écritures avant de réordonner
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-022-check-read-write-footprints-before-reordering.fr.md
---

:::note[Streeling University]
**CS-022** · Examiner les lectures et écritures avant de réordonner · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-022-check-read-write-footprints-before-reordering.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-017](../../computer-science/cs-017-test-pipeline-rewrites-with-counterexamples/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Deux étapes d’agent écrivent dans des fichiers distincts ; un coordinateur propose donc de les exécuter dans n’importe quel ordre. Mais l’étape de rapport lit aussi le manifeste écrit par la première. Des destinations différentes ne suffisent pas à établir l’indépendance. L’empreinte doit inclure les entrées et les sorties.

Le guide d’isolation de SQLite distingue les connexions séparées et les écritures sérialisées. Ses garanties appartiennent à cette base. Nous déclarons ici un contrat statique plus restreint pour des étapes Learn fictives : chaque nom désigne un emplacement mutable, lire ne le modifie pas et les empreintes sont complètes. Comparez les écritures de chaque étape à toutes les ressources touchées par l’autre. Les lectures communes sont alors inoffensives ; un chevauchement impliquant une écriture exige de préserver ou de justifier l’ordre.

Ce test rejette volontairement certaines étapes dont une analyse plus poussée pourrait établir la commutation, par exemple deux affectations de la même constante. Un conflit signale la limite de ce test suffisant, pas une différence certaine de chaque exécution. Un état caché invalide un résultat favorable : le DSL proposé doit exposer les effets.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cs-017-test-pipeline-rewrites-with-counterexamples](../../computer-science/cs-017-test-pipeline-rewrites-with-counterexamples/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.sqlite.org/isolation.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "a": {
      "reads": [
        "source"
      ],
      "writes": [
        "manifest"
      ]
    },
    "b": {
      "reads": [
        "manifest"
      ],
      "writes": [
        "report"
      ]
    }
  },
  "formula": "conflicts=(Wa intersect (Rb union Wb)) union (Wb intersect (Ra union Wa)); sort unique names; independent iff conflicts empty.",
  "expected": {
    "conflicts": [
      "manifest"
    ],
    "independent": false
  },
  "negative_control": {
    "values": {
      "a": {
        "reads": [
          "source"
        ],
        "writes": [
          "manifest"
        ]
      },
      "b": {
        "reads": [
          "source"
        ],
        "writes": [
          "report"
        ]
      }
    },
    "expected": {
      "conflicts": [],
      "independent": true
    },
    "why": "Removing the read-after-write dependency leaves disjoint writes and shared read-only input."
  },
  "assumptions": [
    "Exact resource names cover every read and write; stages otherwise deterministic.",
    "No clocks, network effects, hidden mutable state or failures are represented."
  ],
  "limits": "Empty conflicts is a sufficient footprint check under these assumptions, not universal commutativity or a concurrent runtime.",
  "input_types": {
    "a": "{reads:set<string>,writes:set<string>}",
    "b": "{reads:set<string>,writes:set<string>}"
  }
}
```

### Exercice 1

Repérez le conflit du cas fixé.

<details><summary>Réponse 1</summary>

`manifest` figure parmi les écritures de la première étape et les lectures de la seconde. La liste vaut `[manifest]`, donc `independent=false`.

</details>

### Exercice 2

Pourquoi des sorties distinctes ne suffisent-elles pas ?

<details><summary>Réponse 2</summary>

La seconde étape consomme une valeur modifiée par la première. Inverser l’ordre peut lire un ancien manifeste malgré des ensembles d’écriture disjoints.

</details>

### Exercice 3

Appliquez le contrôle à lecture commune.

<details><summary>Réponse 3</summary>

Les étapes lisent `source` et écrivent dans des ressources distinctes. La liste vaut `[]` et `independent=true` si les empreintes sont complètes.

</details>

### Exercice 4

Un conflit prouve-t-il la non-commutation ?

<details><summary>Réponse 4</summary>

Non. Le test suffit à établir l’indépendance lorsqu’il réussit. Un autre argument pourrait établir une équivalence malgré le chevauchement ; l’empreinte seule ne le peut pas.

</details>

### Exercice 5

Quel effet caché réfuterait le résultat ?

<details><summary>Réponse 5</summary>

Une écriture omise dans un cache commun invalide la complétude. Conservez-la et recommencez ; une intersection vide issue d’une liste incomplète ne prouve rien.

</details>

## Travail avec consultation des sources

Annotez des étapes Learn fictives par leurs lectures et écritures, puis demandez à un assistant de justifier ou de rejeter leur permutation.

**Référence manuelle directe:** Calculez sur papier les intersections des écritures avec l’union des lectures et écritures de l’autre étape.

**Critère de réfutation:** Une dépendance lecture-après-écriture est omise ou un effet non déclaré est considéré comme couvert.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
