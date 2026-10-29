---
title: Distinguer l’équivalence d’un intervalle contenant zéro
description: Distinguer l’équivalence d’un intervalle contenant zéro — Philosophie
sidebar:
  label: PHI-012 · Distinguer l’équivalence d’un intervalle contenant zéro
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/philosophy/fr/phi-012-distinguish-equivalence-from-an-interval-containing-zero.fr.md
---

:::note[Streeling University]
**PHI-012** · Distinguer l’équivalence d’un intervalle contenant zéro · avancé · 45 minutes

Généré par le département *Philosophie* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/philosophy/fr/phi-012-distinguish-equivalence-from-an-interval-containing-zero.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHI-006](../../philosophy/phi-006-preserve-the-quantifier-in-a-fold-verdict/), [PHI-011](../../philosophy/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

L’intervalle de différence résiduelle d’un nettoyage proposé contient zéro ; un rapport déclare donc les versions équivalentes. Contenir zéro rend seulement l’égalité compatible avec l’intervalle. L’équivalence selon une marge pratique exige que tout l’intervalle admissible y tienne. Ce cours transforme la distinction des quantificateurs en opération de révision précise.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Les intervalles sont des ensembles admissibles construits, pas des intervalles de confiance étalonnés ni des résultats de tests. Borner toutes les valeurs est plus exigeant que trouver une valeur acceptable. Choisissez la marge avant d’inspecter le candidat et préservez son sens : une tolérance à l’écran n’établit pas l’interchangeabilité perceptive. Le script expose des paramètres de capture sans données d’intervalle ni critère d’équivalence. La référence logique distingue satisfiabilité et validité, ce qui invite à vérifier le quantificateur réellement utilisé.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "difference_interval": [
      -0.1,
      0.15
    ],
    "equivalence_margin": 0.2
  },
  "formula": "contains_zero=(lo<=0<=hi); equivalent=(lo>=-margin and hi<=margin); compatible_with_equivalence=(hi>=-margin and lo<=margin); width=hi-lo",
  "expected": {
    "contains_zero": true,
    "equivalent": true,
    "compatible_with_equivalence": true,
    "width": 0.25
  },
  "negative_control": {
    "values": {
      "difference_interval": [
        -0.5,
        0.5
      ],
      "equivalence_margin": 0.2
    },
    "expected": {
      "contains_zero": true,
      "equivalent": false,
      "compatible_with_equivalence": true,
      "width": 1
    }
  }
}
```

### Exercice 1

L’intervalle principal contient-il zéro ?

<details><summary>Réponse 1</summary>

Oui : `contains_zero=true`. L’égalité est compatible avec l’intervalle, sans être prouvée exactement.

</details>

### Exercice 2

Respecte-t-il la borne d’équivalence déclarée ?

<details><summary>Réponse 2</summary>

Oui : `equivalent=true` ; sa largeur vaut `0.25`. Ses bornes restent dans la marge prescrite.

</details>

### Exercice 3

Appliquez le témoin plus large.

<details><summary>Réponse 3</summary>

Il conserve `contains_zero=true`, mais `equivalent=false`, avec une largeur de `1`. La compatibilité avec l’équivalence reste `true`.

</details>

### Exercice 4

Un intervalle non concluant prouve-t-il une différence nuisible ?

<details><summary>Réponse 4</summary>

Non. L’ensemble large autorise des valeurs acceptables et inacceptables. Conservez l’ambiguïté sans affirmer équivalence ou nuisance.

</details>

### Exercice 5

Que faudrait-il pour affirmer une équivalence réelle ?

<details><summary>Réponse 5</summary>

Définissez à l’avance la tâche et la marge, justifiez l’obtention de l’intervalle et conservez les observations pertinentes. Ce calcul ensembliste n’est pas un test statistique d’équivalence.

</details>

## Travail avec consultation des sources

Dessinez à la main les intervalles sur la même bande de tolérance. Inspectez les paramètres de capture et listez le contrat de mesure manquant. Reformulez une affirmation fondée sur la présence de zéro avec le bon quantificateur.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Le témoin large, qui permet des valeurs hors marge, réfute l’affirmation selon laquelle tout intervalle contenant zéro prouve une équivalence pratique.

## Sources et périmètre de validation

- [Prérequis déjà commité: phi-006-preserve-the-quantifier-in-a-fold-verdict](../../philosophy/phi-006-preserve-the-quantifier-in-a-fold-verdict/)

- [Prérequis déjà commité: phi-011-cross-mesh-and-lighting-before-attributing-a-render-change](../../philosophy/phi-011-cross-mesh-and-lighting-before-attributing-a-render-change/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)

- [Lecture primaire](https://microsoft.github.io/z3guide/docs/logic/propositional-logic/)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
