---
title: Distinguer une enveloppe indépendante d’un état indépendant
description: Distinguer une enveloppe indépendante d’un état indépendant — Sémiotique
sidebar:
  label: SEM-022 · Distinguer une enveloppe indépendante d’un état indépendant
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-022-distinguish-an-independent-wrapper-from-independent-state.fr.md
---

:::note[Streeling University]
**SEM-022** · Distinguer une enveloppe indépendante d’un état indépendant · avancé · 50 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-022-distinguish-an-independent-wrapper-from-independent-state.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-014](../../semiotics/sem-014-declare-material-patch-precedence/), [CS-019](../../computer-science/cs-019-preserve-lexical-bindings-when-composing-fragments/)
:::

> Brouillon soumis à une revue technique et linguistique. Les entrées numériques et les résultats attendus sont des cas construits. Aucun nouvel essai de matériau, passage dans un moteur de scène, résultat apprenant ou résultat de production n’est fourni. Les décisions humaines et pédagogiques restent ouvertes.

## Opération du projet et interprétation

Un nœud de correction de matériau proposé copie un conteneur et suppose les modifications isolées. Une enveloppe externe nouvelle peut encore référencer le même état mutable imbriqué. Dessinez le graphe avant mutation, distinguez identité de l’enveloppe et identité de l’enfant, puis comparez copie superficielle et copie récursive de cette structure limitée aux listes. Cela concerne les alias dans le tas, pas la capture lexicale, la priorité des champs ni la duplication de ressources [Godot](https://docs.godotengine.org/en/stable/classes/class_transform3d.html). Aucun objet de scène n’a été copié. Les partages voulus, cycles et mécanismes propres au moteur demandent d’autres contrats.

Lisez le prérequis versionné et le passage précisément délimité de la source avant de calculer. Identifiez l’opération dont le projet a besoin, le sens de ses entrées et l’affirmation que le résultat pourrait étayer. Le dossier conserve la révision et le périmètre réellement consulté. Placez dans des colonnes distinctes une définition documentaire, une hypothèse construite et un résultat observé. Un assistant ne doit pas remplacer une observation absente par un récit plausible de ce que le logiciel ferait probablement.

Explicitez la représentation. Le JSON ci-dessous décrit une spécification mathématique finie ; ce n’est ni une syntaxe exécutable du projet ni une nouvelle fonction du moteur. Les noms de champs et l’ordre des identités font partie du cas pédagogique. Lisez la formule avec les valeurs : un nombre apparemment juste obtenu selon une autre interprétation ne répond pas à la tâche. Conservez les intermédiaires et le contrôle pour permettre à un relecteur de retrouver le premier désaccord. Les hypothèses sont volontairement étroites ; élargir leur domaine exige une justification supplémentaire.

## Modèle fixé et contrôle par changement d’entrée

```json
{
  "values": {
    "original": [
      [
        1,
        2
      ],
      [
        3
      ]
    ],
    "copy_mode": "shallow",
    "mutation": {
      "row": 0,
      "column": 0,
      "value": 9
    }
  },
  "formula": "copy outer list; shallow retains child references, deep recursively copies list children; mutate copied child at supplied row/column; compare original and copy after mutation",
  "expected": {
    "original_after": [
      [
        9,
        2
      ],
      [
        3
      ]
    ],
    "copy_after": [
      [
        9,
        2
      ],
      [
        3
      ]
    ],
    "same_outer": false,
    "same_first_child": true
  },
  "negative_control": {
    "values": {
      "original": [
        [
          1,
          2
        ],
        [
          3
        ]
      ],
      "copy_mode": "deep",
      "mutation": {
        "row": 0,
        "column": 0,
        "value": 9
      }
    },
    "expected": {
      "original_after": [
        [
          1,
          2
        ],
        [
          3
        ]
      ],
      "copy_after": [
        [
          9,
          2
        ],
        [
          3
        ]
      ],
      "same_outer": false,
      "same_first_child": false
    }
  }
}
```

### Exercice 1

Identifiez les entrées et l’opération à préserver.

<details><summary>Réponse 1</summary>

> **Réponse:** L’identité de l’enveloppe et celle de l’enfant imbriqué sont différentes.

</details>

### Exercice 2

Déterminez les valeurs originale et copiée après la modification superficielle.

<details><summary>Réponse 2</summary>

> **Réponse:** Le cas superficiel change les deux valeurs en `[[9,2],[3]]` car le premier enfant est partagé.

</details>

### Exercice 3

Expliquez le piège d’interprétation qu’un résumé pourrait cacher.

<details><summary>Réponse 3</summary>

> **Réponse:** `same_outer` vaut `false` mais `same_first_child` vaut `true` ; une nouvelle enveloppe ne prouve pas l’isolation.

</details>

### Exercice 4

Appliquez le contrôle modifié et comparez les résultats.

<details><summary>Réponse 4</summary>

> **Réponse:** Le contrôle profond conserve l’original `[[1,2],[3]]` et change seulement la copie en `[[9,2],[3]]`.

</details>

### Exercice 5

Précisez la limite et les preuves requises avant toute adoption.

<details><summary>Réponse 5</summary>

> **Réponse:** Les autres types d’objet et les partages voulus exigent un contrat de copie distinct.

</details>

## Tâche avec sources et référence manuelle directe

Dessinez les identités d’objets d’une correction de matériau Atlas avant et après modification d’un enfant copié.

En masquant les réponses, dessinez un tableau ou un schéma propre à l’opération, puis calculez le résultat principal à la main. Cette première tentative conservée constitue la référence manuelle directe. Indiquez les entrées, les intermédiaires, la règle de chaque étape et la raison de tout refus ou résultat indéterminé. Énoncez le critère de réfutation avant de demander à un assistant de simplifier le travail. Un tableau ordinaire peut suffire au projet ; un DSL composable ou un nœud agentique doit apporter un bénéfice supplémentaire démontré.

Consultez ensuite l’artefact local et le passage primaire liés. Notez l’emplacement, la révision, la définition utilisée et ce qu’elle ne permet pas d’établir. Demandez à un assistant de contester une hypothèse et conservez la question et sa réponse. Déclarez comme aide tout usage de calculatrice, de traduction ou de recherche documentaire. Comparez le résultat aidé à la référence initiale avec les mêmes entrées. Rejetez une explication plus courte si elle supprime une identité, une condition ou la distinction entre exemple construit et observation du projet.

Traitez le contrôle négatif comme un enregistrement séparé. Prédisez son résultat avant de lire la correction, puis comparez les champs modifiés et les invariants. En cas de désaccord, distinguez erreur de calcul, erreur de sens et limite des hypothèses. Conservez l’échec, son diagnostic, sa correction et sa reprise ; n’effacez pas la première tentative. Remettez ces traces avec l’explication documentée et les incertitudes restantes. Cette petite boucle d’amélioration pourra servir au dogfooding, mais aucune amélioration réelle d’apprentissage ou d’exécution n’a été mesurée ici.

Le dossier prépare un critère par exercice sans remplir les décisions pédagogiques. La réponse réelle, l’historique d’aide, la correction personnelle et la décision restent vides tant qu’aucune tentative n’existe. Revue technique, revue linguistique, exécution dans le moteur, validation matérielle, adoption et publication nécessitent des preuves distinctes. Le calcul fini n’établit que la relation annoncée sous ses hypothèses. Avant de l’utiliser dans une scène ou un outil de pratique, précisez l’observation supplémentaire et son seuil de rejet ; un corrigé préparé ne vaut pas acceptation.

## Critère prospectif de réfutation

Une réponse proposée est rejetée si l’application de l’opération affichée à une entrée conservée contredit le résultat attendu, ou si son explication présente ce cas construit comme une observation déjà réalisée dans le projet.

## Critères préparés pour l’apprenant

- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 1, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 2, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 3, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 4, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.
- Conserver la réponse correcte et le raisonnement intermédiaire de l’exercice 5, ainsi que la portée de l’affirmation. La décision pédagogique reste ouverte.

## Sources et portée des affirmations

- [Prérequis versionné: sem-014-declare-material-patch-precedence](../../semiotics/sem-014-declare-material-patch-precedence/)
- [Prérequis versionné: cs-019-preserve-lexical-bindings-when-composing-fragments](../../computer-science/cs-019-preserve-lexical-bindings-when-composing-fragments/)
- [Artefact local conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/copy.html)
- [Dossier du cas construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
