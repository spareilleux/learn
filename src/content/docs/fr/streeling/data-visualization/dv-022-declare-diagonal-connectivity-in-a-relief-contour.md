---
title: Déclarer la connexité diagonale d’un contour de relief
description: Déclarer la connexité diagonale d’un contour de relief — Visualisation de données
sidebar:
  label: DV-022 · Déclarer la connexité diagonale d’un contour de relief
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-022-declare-diagonal-connectivity-in-a-relief-contour.fr.md
---

:::note[Streeling University]
**DV-022** · Déclarer la connexité diagonale d’un contour de relief · avancé · 45 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-022-declare-diagonal-connectivity-in-a-relief-contour.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-015](../../data-visualization/dv-015-map-missing-stitches-without-inventing-holes/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un aperçu de hauteur de relief contient une cellule dont les sommets hauts sont diagonalement opposés. Tous les sommets sont présents ; le traitement des données manquantes ne décide donc pas du passage du contour. L’interpolation linéaire des arêtes donne les positions, mais laisse un choix de connexité. Ce cours rend ce choix visible avant d’attribuer une étiquette de composante à un masque de broderie ou une zone ciselée.

Nommez sommets et arêtes dans une orientation d’image fixe. Le motif alterne haut et bas, avec une intersection sur chaque arête. Relier la classe haute au centre sépare les sommets bas ; relier la classe basse sépare au contraire les sommets hauts. Conservez coordonnées d’intersection et politique d’appariement dans des champs distincts. Le témoin change seulement la politique : mêmes positions, mais nombres locaux de composantes différents. Une image montrant les mêmes points peut cacher le changement topologique.

La documentation officielle décrit ce cas ambigu et propose une option de connexité ; notre construction papier n’exécute pas cette implémentation. Elle ne déduit pas l’intérieur inconnu de la surface depuis les sommets et ne prétend pas reconstruire physiquement une selle. Un transfert d’asset devra préciser si la connexité est une convention construite ou repose sur un échantillonnage supplémentaire. Un assistant peut proposer l’une ou l’autre politique selon la tâche, mais doit conserver l’alternative rejetée et sa conséquence sur l’identité des régions.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "corners_TL_TR_BR_BL": [
      1,
      0,
      1,
      0
    ],
    "threshold": 0.5,
    "connect_high": false
  },
  "formula": "classify corners strictly above threshold; alternating high/low is ambiguous; interpolate each crossing at (threshold-a)/(b-a); connect_high false pairs top-left and right-bottom; connect_high true pairs top-right and bottom-left",
  "expected": {
    "ambiguous": true,
    "edge_fractions": [
      0.5,
      0.5,
      0.5,
      0.5
    ],
    "pairs": [
      [
        "top",
        "left"
      ],
      [
        "right",
        "bottom"
      ]
    ],
    "high_components": 2,
    "low_components": 1
  },
  "negative_control": {
    "values": {
      "corners_TL_TR_BR_BL": [
        1,
        0,
        1,
        0
      ],
      "threshold": 0.5,
      "connect_high": true
    },
    "expected": {
      "ambiguous": true,
      "edge_fractions": [
        0.5,
        0.5,
        0.5,
        0.5
      ],
      "pairs": [
        [
          "top",
          "right"
        ],
        [
          "bottom",
          "left"
        ]
      ],
      "high_components": 1,
      "low_components": 2
    }
  }
}
```

### Exercice 1

Classez le motif des sommets.

<details><summary>Réponse 1</summary>

Il alterne haut et bas ; le cas local est ambigu. Des sommets complets ne choisissent pas seuls la connexité diagonale.

</details>

### Exercice 2

Placez les intersections sur arêtes.

<details><summary>Réponse 2</summary>

Toutes les fractions valent `0.5`. L’interpolation fixe les positions sans leur appariement dans la cellule.

</details>

### Exercice 3

Appliquez la politique principale.

<details><summary>Réponse 3</summary>

Reliez haut et gauche, puis droite et bas. La classe haute locale a `2` composantes et la classe basse `1`.

</details>

### Exercice 4

Appliquez le témoin de politique.

<details><summary>Réponse 4</summary>

Reliez haut et droite, puis bas et gauche. La classe haute a `1` composante et la basse `2`, sans changement de positions.

</details>

### Exercice 5

Une politique mesure-t-elle l’intérieur de la surface ?

<details><summary>Réponse 5</summary>

Non. Il faudrait des échantillons supplémentaires ou un modèle d’interpolation justifié. Une convention déclare un sens, sans observation physique.

</details>

## Travail avec sources et référence manuelle directe

Dessinez les deux appariements sur la même cellule et étiquetez les régions hautes. Préparez une annotation conservant politique et alternative, puis demandez quel échantillon futur pourrait contester le choix.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une identité de composantes prétendument inchangée sous le témoin de politique est réfutée par les nouveaux comptes locaux.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: dv-015-map-missing-stitches-without-inventing-holes](../../data-visualization/dv-015-map-missing-stitches-without-inventing-holes/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://scikit-image.org/docs/stable/api/skimage.measure.html#skimage.measure.find_contours)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
