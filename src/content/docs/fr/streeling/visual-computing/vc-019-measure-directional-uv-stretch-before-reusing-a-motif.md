---
title: Mesurer l’étirement UV directionnel avant de réutiliser un motif
description: Mesurer l’étirement UV directionnel avant de réutiliser un motif — Informatique visuelle
sidebar:
  label: VC-019 · Mesurer l’étirement UV directionnel avant de réutiliser un motif
  order: 19
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-019-measure-directional-uv-stretch-before-reusing-a-motif.fr.md
---

:::note[Streeling University]
**VC-019** · Mesurer l’étirement UV directionnel avant de réutiliser un motif · avancé · 45 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-019-measure-directional-uv-stretch-before-reusing-a-motif.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-016](../../visual-computing/vc-016-track-uv-gutters-through-mip-levels/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Un motif brodé circulaire peut s’allonger alors que des patches UV partagent le même facteur d’aire. La marge d’atlas mesure la séparation entre îlots ; elle ne décrit pas la déformation directionnelle à l’intérieur. Ce cours compare les étirements indépendants d’un patch affine déclaré avant une réutilisation proposée de Blender vers Godot.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

L’application diagonale envoie les axes de coordonnées vers des directions de surface orthogonales. Chaque valeur absolue diagonale est un étirement ; leur produit donne le facteur d’aire. Un cercle suit ces étirements et devient une ellipse s’ils diffèrent. [PBRT](https://pbr-book.org/4ed/Shapes/Triangle_Meshes) explique les dérivées UV affines sur un triangle. Atlas crée des objets maillés, sans fournir de résultat sur la qualité des UV exportés. Notre table simplifiée est construite et ne constitue pas une mesure d’un asset généré.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "dx_du": 4,
    "dy_dv": 1,
    "uv_radius": 0.1
  },
  "formula": "J=diag(dx_du,dy_dv); stretches=[abs(dx_du),abs(dy_dv)]; area_scale=abs(dx_du*dy_dv); anisotropy=max(stretches)/min(stretches); ellipse_axes=uv_radius*stretches",
  "expected": {
    "stretches": [
      4,
      1
    ],
    "area_scale": 4,
    "anisotropy": 4,
    "ellipse_axes": [
      0.4,
      0.1
    ]
  },
  "negative_control": {
    "values": {
      "dx_du": 2,
      "dy_dv": 2,
      "uv_radius": 0.1
    },
    "expected": {
      "stretches": [
        2,
        2
      ],
      "area_scale": 4,
      "anisotropy": 1,
      "ellipse_axes": [
        0.2,
        0.2
      ]
    }
  }
}
```

### Exercice 1

Trouvez les étirements et le facteur d’aire principaux.

<details><summary>Réponse 1</summary>

Les étirements valent `[4,1]` et le facteur d’aire `4`. Leur produit seul perd la différence entre directions.

</details>

### Exercice 2

Transformez le cercle UV.

<details><summary>Réponse 2</summary>

Ses demi-axes deviennent `[0.4,0.1]` unités de scène, avec une anisotropie de `4`. Ce sont des rayons, pas des diamètres.

</details>

### Exercice 3

Appliquez le témoin de même aire.

<details><summary>Réponse 3</summary>

Les étirements deviennent `[2,2]`, le facteur d’aire reste `4`, les demi-axes valent `[0.2,0.2]` et l’anisotropie vaut `1`.

</details>

### Exercice 4

Une marge d’atlas suffisante corrige-t-elle cette déformation ?

<details><summary>Réponse 4</summary>

Non. La marge prévient une contamination entre îlots. Elle ne modifie pas la dérivée affine à l’intérieur du patch.

</details>

### Exercice 5

Quand le raccourci diagonal cesse-t-il de convenir ?

<details><summary>Réponse 5</summary>

Un cisaillement ou des dérivées non orthogonales exigent les valeurs singulières de l’application locale complète. Sur un patch courbe, les dérivées dépendent de la position ; ce cas ne les évalue pas.

</details>

## Travail avec consultation des sources

Dessinez les cercles transformés avec la même règle, inspectez la création du maillage Atlas et identifiez les preuves de dérivées UV manquantes. Formulez d’abord une recommandation fondée sur l’aire, puis confrontez-la au témoin avant d’automatiser.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

Les applications ont le même facteur d’aire mais une anisotropie différente : cela réfute la conservation de forme déduite de la seule aire.

## Sources et périmètre de validation

- [Prérequis déjà commité: vc-016-track-uv-gutters-through-mip-levels](../../visual-computing/vc-016-track-uv-gutters-through-mip-levels/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://pbr-book.org/4ed/Shapes/Triangle_Meshes)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
