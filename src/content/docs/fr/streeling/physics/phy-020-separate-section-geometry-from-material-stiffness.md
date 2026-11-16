---
title: Distinguer la géométrie de section de la rigidité du matériau
description: Distinguer la géométrie de section de la rigidité du matériau — Physique
sidebar:
  label: PHY-020 · Distinguer la géométrie de section de la rigidité du matériau
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-020-separate-section-geometry-from-material-stiffness.fr.md
---

:::note[Streeling University]
**PHY-020** · Distinguer la géométrie de section de la rigidité du matériau · avancé · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-020-separate-section-geometry-from-material-stiffness.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-012](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)
:::

> Brouillon pour révision technique et linguistique. Le cas est construit, y compris ses entrées numériques, étiquettes et résultats attendus. Il ne constitue ni essai artisanal physique, ni observation [Godot](https://docs.godotengine.org/en/4.5/tutorials/shaders/advanced_postprocessing.html), ni rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni exécution [ComfyUI](https://github.com/Comfy-Org/ComfyUI), ni résultat d’apprentissage. Toutes les décisions humaines et d’apprentissage restent indécises.

## Question du projet

Une bande métallique plate et une barre carrée peuvent avoir la même aire de section tout en réagissant différemment à la flexion. En ne conservant que l’aire ou le nom du matériau, un agent perd la répartition de matière autour de l’axe de flexion. Le prérequis traite les directions constitutives ; ici, le matériau reste isotrope et la section change.

Lisez le prérequis déjà commité et le passage de source conservé avant de calculer. Préparez une table distinguant définition de source, hypothèse construite, résultat dérivé et observation future proposée. La révision et le périmètre de lecture figurent dans le paquet. Un paramètre inspecté prouve que la représentation expose ce paramètre ; il ne fournit pas un coefficient matériel, un jugement de visibilité ou un temps de traitement non mesuré. Préservez cette distinction quand un assistant résume la source. La référence primaire ne soutient que le concept et le passage indiqués dans la fiche de lecture.

## Dériver l’opération avant de proposer une automatisation

Pour l’axe horizontal passant par le centre, intégrez le carré de la distance sur le rectangle : le moment quadratique est le produit de la largeur par le cube de la hauteur, divisé par la constante du rectangle indiquée dans le paquet. Permuter largeur et hauteur modifie ce facteur géométrique à aire constante. Avec la relation linéaire de courbure explicitement adoptée, un moment quadratique plus grand donne une courbure plus faible. Atlas crée des prismes rectangulaires ; le helper inspecté ne résout pas l’élasticité et ne certifie aucune bande fabriquée. La section idéale ne désigne pas un nombre de triangles.

## Modèle construit fixe et témoin à entrée modifiée

```json
{
  "values": {
    "width_mm": 12,
    "height_mm": 3,
    "moment_Nmm": 9,
    "young_N_mm2": 1000
  },
  "formula": "I_x=width*height**3/12; I_y=height*width**3/12; curvature_x=moment/(young*I_x); curvature_y=moment/(young*I_y); ratio=I_y/I_x",
  "expected": {
    "I_x_mm4": 27,
    "I_y_mm4": 432,
    "curvature_x_per_mm": 0.0003333333333333333,
    "curvature_y_per_mm": 2.0833333333333333e-05,
    "ratio": 16
  },
  "negative_control": {
    "values": {
      "width_mm": 6,
      "height_mm": 6,
      "moment_Nmm": 9,
      "young_N_mm2": 1000
    },
    "expected": {
      "I_x_mm4": 108,
      "I_y_mm4": 108,
      "curvature_x_per_mm": 8.333333333333333e-05,
      "curvature_y_per_mm": 8.333333333333333e-05,
      "ratio": 1
    }
  }
}
```

### Exercice 1

Calculez les moments quadratiques suivant les axes centraux.

<details><summary>Réponse 1</summary>

Ils valent `27 mm^4` et `432 mm^4`. L’unité à la puissance quatrième vient de l’intégration d’une distance au carré sur une aire.

</details>

### Exercice 2

Comparez les courbures sous le même moment.

<details><summary>Réponse 2</summary>

Elles valent `0.0003333333333333333 mm^-1` et `0.000020833333333333333 mm^-1`. La première vaut `16` fois la seconde.

</details>

### Exercice 3

Que change le témoin carré ?

<details><summary>Réponse 3</summary>

Les moments quadratiques valent tous deux `108 mm^4` ; les courbures valent `0.00008333333333333333 mm^-1` et le rapport vaut `1`.

</details>

### Exercice 4

Une aire égale conserve-t-elle la réponse en flexion ?

<details><summary>Réponse 4</summary>

Non. Les sections ont toutes deux une aire de `36 mm^2`, mais la matière est répartie différemment autour des axes. L’aire ne suffit pas à retrouver un moment quadratique.

</details>

### Exercice 5

Un agent peut-il présenter ce calcul comme un résultat de sécurité en métallerie ?

<details><summary>Réponse 5</summary>

Non. Il faudrait valider le comportement du matériau, mesurer la section réelle et préciser les conditions aux limites ainsi que les critères de rupture. Ce calcul linéaire construit ne fournit aucune de ces observations.

</details>

## Travail avec consultation des sources

Dessinez les sections et leurs axes centraux. Repérez les dimensions des prismes Atlas, puis préparez une liste indicative distinguant géométrie, module du matériau et charge. Calculez les rapports à la main avant d’envisager une notation réutilisable.

Commencez par une référence manuelle directe : fermez les réponses, dessinez le schéma ou la table demandé et calculez les quantités intermédiaires avec leurs unités. Conservez cette première réponse avant de demander de l’aide. Utilisez ensuite la source pour contester une hypothèse précise, en gardant la question, l’emplacement consulté, l’aide reçue et les suggestions rejetées. Comparez le résultat assisté au calcul initial pour la même tâche et les mêmes entrées. Une explication plus courte ne démontre aucun progrès si elle perd une condition aux limites ou invente une observation.

Traitez le témoin structuré comme un cas distinct, sans modifier les entrées principales en place. Consignez changements et invariants, puis précisez si un écart relève du calcul, de l’interprétation ou des hypothèses. Conservez séparément chaque tentative échouée et sa correction. Le paquet prépare un critère pour chaque exercice corrigé ; chaque décision d’apprentissage reste null jusqu’à la conservation et la révision d’une tentative réelle. Consulter une source ou une réponse préparée ne prouve pas que l’apprenant a réalisé la tâche. Aucun nouveau DSL, flux d’agents, adaptateur de scène ni intégration en production n’est nécessaire pour cet exercice sur papier.

## Critère de réfutation annoncé

À matériau et aire identiques, l’affirmation d’une même courbure directionnelle est réfutée par le rectangle et le carré dans le modèle déclaré.

## Sources et périmètre de validation

- [Prérequis déjà commité: phy-012-rotate-directional-stiffness-with-the-material](../../physics/phy-012-rotate-directional-stiffness-with-the-material/)

- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)

- [Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/12-3-stress-strain-and-elastic-modulus)

- [Paquet construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-c.json)

- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
