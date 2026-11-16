---
title: Composer la résistance thermique de couches artisanales
description: Composer la résistance thermique de couches artisanales — Physique
sidebar:
  label: PHY-024 · Composer la résistance thermique de couches artisanales
  order: 24
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-024-compose-thermal-resistance-through-craft-layers.fr.md
---

:::note[Streeling University]
**PHY-024** · Composer la résistance thermique de couches artisanales · avancé · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-024-compose-thermal-resistance-through-craft-layers.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-017](../../physics/phy-017-budget-thermal-growth-at-a-metal-joint/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un relief métallique doublé de textile est proposé comme objet interactif. Les noms des matériaux suggèrent une histoire thermique, mais un shader de surface ne détermine pas le flux traversant l’assemblage. Ce cours compose un empilement plan de couches inventées et calcule la puissance commune en régime stationnaire. Il prolonge le prérequis sur la dilatation en déterminant la répartition d’un écart de température total, au lieu de prescrire cet écart intégral à chaque pièce.

En régime stationnaire sans source interne, toutes les couches transmettent la même puissance. La chute de température d’une couche est donc cette puissance multipliée par sa résistance thermique. Additionnez les résistances avant de diviser l’écart total ; une moyenne des conductivités masquerait les épaisseurs et pourrait changer le résultat. La plus grande part de résistance reçoit la plus grande part de chute thermique. L’égalité des aires est essentielle à la formule utilisée.

Le témoin change l’épaisseur et produit des résistances égales malgré des conductivités différentes. Il vérifie que l’explication assistée suit géométrie et unités au lieu de prendre un nom de matériau séduisant pour réponse. Une annotation artisanale future devra conserver provenance des conductivités, contacts et températures aux limites avec les dimensions du maillage. Les paramètres de matériau Atlas décrivent l’apparence, sans mesure de conductivité thermique. Un motif repoussé, un interstice adhésif ou un tissage poreux peut invalider le modèle de dalle et nécessiter une autre expérience.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "thickness_m": [
      0.02,
      0.01
    ],
    "conductivity_W_mK": [
      0.2,
      0.5
    ],
    "area_m2": 0.5,
    "delta_K": 30
  },
  "formula": "R_i=d_i/(k_i*A); R_total=sum(R_i); power=delta/R_total; drop_i=power*R_i",
  "expected": {
    "resistances_K_W": [
      0.2,
      0.04
    ],
    "total_K_W": 0.24,
    "power_W": 125,
    "drops_K": [
      25,
      5
    ]
  },
  "negative_control": {
    "values": {
      "thickness_m": [
        0.02,
        0.05
      ],
      "conductivity_W_mK": [
        0.2,
        0.5
      ],
      "area_m2": 0.5,
      "delta_K": 30
    },
    "expected": {
      "resistances_K_W": [
        0.2,
        0.2
      ],
      "total_K_W": 0.4,
      "power_W": 75,
      "drops_K": [
        15,
        15
      ]
    }
  }
}
```

### Exercice 1

Calculez les résistances.

<details><summary>Réponse 1</summary>

Elles valent `[0.2,0.04] K/W`. Divisez l’épaisseur par conductivité et aire commune ; l’épaisseur seule n’est pas une résistance.

</details>

### Exercice 2

Trouvez résistance totale et puissance commune.

<details><summary>Réponse 2</summary>

Elles valent `0.24 K/W` et `125 W`. La même puissance stationnaire traverse chaque couche.

</details>

### Exercice 3

Répartissez les chutes de température.

<details><summary>Réponse 3</summary>

Elles valent `[25,5] K` et leur somme donne l’écart imposé. Appliquer cet écart entier à chaque couche violerait le modèle en série.

</details>

### Exercice 4

Appliquez le témoin avec couche épaissie.

<details><summary>Réponse 4</summary>

Les résistances deviennent `[0.2,0.2] K/W`, la puissance `75 W` et les chutes `[15,15] K`. Les conductivités seules n’expliquent pas la répartition.

</details>

### Exercice 5

Un shader métallique établit-il la conductivité ?

<details><summary>Réponse 5</summary>

Non. Aucun étalonnage ne relie ce paramètre d’apparence au coefficient de transport. Séparez mesure matérielle et représentation visuelle.

</details>

## Travail avec sources et référence manuelle directe

Dessinez la coupe d’un relief doublé de textile proposé et répartissez les chutes à la main. Examinez les champs d’apparence Atlas, puis rédigez séparément la demande de données matérielles nécessaire au calcul physique.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

L’affirmation selon laquelle la couche plus conductrice doit toujours recevoir la plus faible chute est réfutée par le témoin à résistances égales.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: phy-017-budget-thermal-growth-at-a-metal-joint](../../physics/phy-017-budget-thermal-growth-at-a-metal-joint/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://openstax.org/books/university-physics-volume-2/pages/1-6-mechanisms-of-heat-transfer)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
