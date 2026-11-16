---
title: Préserver les fréquences par l’aire de classes de points inégales
description: Préserver les fréquences par l’aire de classes de points inégales — Visualisation de données
sidebar:
  label: DV-020 · Préserver les fréquences par l’aire de classes de points inégales
  order: 20
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-020-make-unequal-stitch-bins-preserve-frequency-area.fr.md
---

:::note[Streeling University]
**DV-020** · Préserver les fréquences par l’aire de classes de points inégales · avancé · 45 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-020-make-unequal-stitch-bins-preserve-frequency-area.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-011](../../data-visualization/dv-011-retain-raw-counts-behind-normalized-heatmaps/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Une révision de broderie groupe les longueurs de points dans des classes courtes étroites et des classes longues plus larges. Si les comptes servent de hauteurs malgré ces largeurs inégales, un rectangle large paraît plus fréquent même à effectif égal. L’opération attribue ici la fréquence à l’aire et la densité à la hauteur. Elle change le codage du graphique, sans modifier les points sous-jacents ni prétendre que ces effectifs proviennent d’IX.

Écrivez les limites avant de dessiner. Divisez chaque effectif par le total, puis par la largeur de sa classe. Multiplier la hauteur obtenue par la largeur restitue la fréquence relative. L’unité verticale est une longueur inverse, pas un pourcentage propre à la barre. Une densité peut dépasser l’unité lorsqu’une classe étroite contient beaucoup de masse ; il ne faut donc pas rejeter une hauteur au seul motif qu’elle dépasse une borne de probabilité.

Le témoin change les effectifs pour égaliser les hauteurs de densité tout en différenciant les aires. Il met à l’épreuve un assistant qui confond barre la plus haute et intervalle le plus fréquent sans vérifier la largeur. Pour un tableau de bord artisanal Learn proposé, conservez effectifs bruts, limites, unités, appartenance des frontières et densité. Les points absents ou exclus exigent un compte séparé. Un histogramme bien légendé ne prouve ni taille de point acceptable, ni fibre intacte, ni reconnaissance d’un motif par l’apprenant.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "edges_mm": [
      0,
      1,
      3
    ],
    "counts": [
      4,
      4
    ]
  },
  "formula": "width_i=edge[i+1]-edge[i]; N=sum(counts); density_i=count_i/(N*width_i); area_i=density_i*width_i",
  "expected": {
    "widths_mm": [
      1,
      2
    ],
    "sample_count": 8,
    "density_per_mm": [
      0.5,
      0.25
    ],
    "areas": [
      0.5,
      0.5
    ]
  },
  "negative_control": {
    "values": {
      "edges_mm": [
        0,
        1,
        3
      ],
      "counts": [
        4,
        8
      ]
    },
    "expected": {
      "widths_mm": [
        1,
        2
      ],
      "sample_count": 12,
      "density_per_mm": [
        0.3333333333333333,
        0.3333333333333333
      ],
      "areas": [
        0.3333333333333333,
        0.6666666666666666
      ]
    }
  }
}
```

### Exercice 1

Trouvez les largeurs et le dénominateur.

<details><summary>Réponse 1</summary>

Les largeurs valent `[1,2] mm` et le total `8`. Le second intervalle est plus large malgré son effectif égal.

</details>

### Exercice 2

Calculez les hauteurs de densité.

<details><summary>Réponse 2</summary>

Elles valent `[0.5,0.25] per mm`. Chaque hauteur divise la fréquence relative par la largeur correspondante, pas seulement par le total.

</details>

### Exercice 3

Retrouvez les masses codées.

<details><summary>Réponse 3</summary>

Les aires valent `[0.5,0.5]` et leur somme `1`. Des fréquences égales n’exigent pas des densités égales à largeurs différentes.

</details>

### Exercice 4

Interprétez le témoin à effectifs modifiés.

<details><summary>Réponse 4</summary>

Les hauteurs deviennent `0.3333333333333333 per mm`, mais les masses valent `[0.3333333333333333,0.6666666666666666]`. Même hauteur ne signifie pas même effectif.

</details>

### Exercice 5

La densité donne-t-elle une probabilité de défaut à longueur exacte ?

<details><summary>Réponse 5</summary>

Non. C’est une masse par unité de longueur sur un intervalle. Étiquettes de défaut, modèle continu et preuves populationnelles sont absents.

</details>

## Travail avec sources et référence manuelle directe

Dessinez deux rectangles inégaux à la main avec effectif, largeur, hauteur et aire. Préparez une légende de tableau de bord de broderie et faites contester le mot fréquence avant d’adopter un DSL graphique.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une légende assimilant les hauteurs égales du témoin à des effectifs égaux est réfutée par ses masses différentes.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: dv-011-retain-raw-counts-behind-normalized-heatmaps](../../data-visualization/dv-011-retain-raw-counts-behind-normalized-heatmaps/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://www.itl.nist.gov/div898/handbook/eda/section3/histogra.htm)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
