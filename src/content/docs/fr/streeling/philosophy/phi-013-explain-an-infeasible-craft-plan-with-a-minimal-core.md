---
title: Expliquer un projet artisanal impossible par un noyau minimal
description: Expliquer un projet artisanal impossible par un noyau minimal — Philosophie
sidebar:
  label: PHI-013 · Expliquer un projet artisanal impossible par un noyau minimal
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core.fr.md
---

:::note[Streeling University]
**PHI-013** · Expliquer un projet artisanal impossible par un noyau minimal · avancé · 45 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-013-explain-an-infeasible-craft-plan-with-a-minimal-core.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-009](../../computer-science/cs-009-composing-origami-panel-constraints/), [PHI-008](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un projet artisanal échoue à plusieurs contrôles et un agent propose de supprimer une exigence commode. Une explication utile identifie un sous-ensemble déjà contradictoire et montre pourquoi chacun de ses membres compte. Le prérequis d’origami établit des échecs de composition ; ce cours ajoute une explication minimale avec témoins de suppression dans un domaine fini.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Gardez le domaine et les inégalités nommées fixes pendant l’examen des sous-ensembles. Un noyau insatisfiable explique une contradiction ; sa minimalité par inclusion exige en plus que chaque sous-ensemble strict soit satisfiable. Le guide [Z3](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/) décrit des noyaux nommés sans garantir leur minimalité. Notre cas fini la démontre manuellement, sans exécuter de solveur. Les dimensions Atlas motivent un transfert futur, sans fournir les valeurs construites. Une contradiction minimale ne décide pas quelle exigence modifier ni qui peut l’autoriser.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "domain": [
      0,
      10
    ],
    "lower_x": 8,
    "upper_x": 6,
    "lower_y": 1,
    "sum_limit": 10
  },
  "formula": "Integer x,y in inclusive domain; A:x>=lower_x; B:x<=upper_x; C:y>=lower_y; D:x+y<=sum_limit; enumerate full solutions; enumerate nonempty constraint subsets; a minimal core has no solution and every proper subset has one",
  "expected": {
    "full_solution_count": 0,
    "minimal_cores": [
      [
        "A",
        "B"
      ]
    ],
    "core_deletion_witnesses": {
      "remove_A": [
        0,
        0
      ],
      "remove_B": [
        8,
        0
      ]
    }
  },
  "negative_control": {
    "values": {
      "domain": [
        0,
        10
      ],
      "lower_x": 8,
      "upper_x": 9,
      "lower_y": 1,
      "sum_limit": 10
    },
    "expected": {
      "full_solution_count": 3,
      "minimal_cores": [],
      "core_deletion_witnesses": {}
    }
  }
}
```

### Exercice 1

Trouvez la contradiction du projet principal.

<details><summary>Réponse 1</summary>

Les contraintes `[A,B]` imposent des bornes incompatibles sur la même dimension ; le nombre de solutions complètes vaut `0`.

</details>

### Exercice 2

Démontrez la minimalité du noyau.

<details><summary>Réponse 2</summary>

Sans A, `[0,0]` convient ; sans B, `[8,0]` convient. Ces témoins satisfont le membre restant du noyau et le domaine, pas nécessairement toutes les autres exigences du projet.

</details>

### Exercice 3

Supprimer la contrainte de somme corrige-t-il le projet initial ?

<details><summary>Réponse 3</summary>

Non. Les bornes incompatibles restent présentes. Une réparation doit toucher un membre du noyau ou changer la sémantique du domaine déclaré.

</details>

### Exercice 4

Appliquez la borne supérieure relâchée.

<details><summary>Réponse 4</summary>

Il existe `3` solutions complètes et aucun noyau minimal : `[]`. Les points possibles sont `[8,1]`, `[8,2]` et `[9,1]`.

</details>

### Exercice 5

Un noyau minimal autorise-t-il une modification ?

<details><summary>Réponse 5</summary>

Non. Il explique l’impossibilité. Coût, sécurité, intention artisanale et autorité déterminent les réparations permises ; une petite explication n’est pas une préférence de modification.

</details>

## Travail avec consultation des sources

Énumérez les candidats entiers et rayez manuellement les violations. Trouvez le noyau, conservez ses témoins de suppression et inspectez la frontière des dimensions Atlas. Distinguez contradiction, minimalité et autorité de réparation dans votre explication.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Une affectation satisfaisant le noyau, ou un sous-ensemble strict encore contradictoire, réfute une prétendue minimalité ; conservez chacun de ces témoins.

## Sources et périmètre de validation

- [Prérequis déjà commité: cs-009-composing-origami-panel-constraints](../../computer-science/cs-009-composing-origami-panel-constraints/)

- [Prérequis déjà commité: phi-008-separate-a-test-oracle-from-a-specification](../../philosophy/phi-008-separate-a-test-oracle-from-a-specification/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
