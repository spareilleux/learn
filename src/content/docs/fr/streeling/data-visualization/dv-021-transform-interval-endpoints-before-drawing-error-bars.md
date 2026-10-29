---
title: Transformer les bornes avant de dessiner les barres d’intervalle
description: Transformer les bornes avant de dessiner les barres d’intervalle — Visualisation de données
sidebar:
  label: DV-021 · Transformer les bornes avant de dessiner les barres d’intervalle
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-021-transform-interval-endpoints-before-drawing-error-bars.fr.md
---

:::note[Streeling University]
**DV-021** · Transformer les bornes avant de dessiner les barres d’intervalle · avancé · 45 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-021-transform-interval-endpoints-before-drawing-error-bars.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-016](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)
:::

> Brouillon pour révision technique et linguistique. Entrées numériques, étiquettes et résultats attendus sont des cas pédagogiques construits. Ils ne constituent ni nouveaux essais matériels physiques, ni exécutions natives de scène, ni observations d’apprentissage, ni résultats de production. Les décisions humaines et d’apprentissage restent indécises.

## Opération du projet et interprétation

Un panneau de comparaison de sculptures comprime son axe de résidus positifs ou nuls par une racine carrée. Un assistant transforme la valeur centrale, puis reporte l’ancienne longueur d’erreur symétrique de chaque côté. Cette opération peut placer les bornes à des valeurs absentes des données construites. Il s’agit de préserver un intervalle admissible lors du changement de coordonnées, sans présenter cette plage mathématique comme un intervalle de confiance étalonné.

Transformez centre et bornes par la même application croissante. Soustrayez seulement ensuite le centre affiché pour obtenir les étendues basse et haute. Une estimation centrale fournie n’est pas nécessairement le milieu de l’intervalle dans l’un ou l’autre repère. Le cas principal a des distances brutes inégales mais des distances affichées égales ; le témoin inverse cette relation. Ces motifs opposés empêchent de remplacer le calcul par une règle de symétrie visuelle.

Un futur diagnostic Learn ou [Godot](https://docs.godotengine.org/en/4.5/) doit conserver intervalle brut, identifiant de transformation, unité et bornes affichées. Les valeurs originales restent disponibles pour les calculs et tolérances pratiques. Transformer l’axe change les positions dessinées ; cela ne modifie ni définition du résidu, ni précision, ni marge d’équivalence justifiée. Le réviseur assisté doit reconstruire chaque borne depuis les données conservées avant de discuter l’utilité du panneau pour comparer broderies ou objets métalliques.

Lisez le prérequis commité et le passage primaire délimité avant de calculer. Préparez un relevé séparant définition de source, prémisse construite, résultat dérivé et observation future. Une documentation ne soutient que l’affirmation située dans son périmètre lu. Paramètre de source, réponse mathématique et observation d’exécution ont des rôles de preuve différents ; un résumé assuré d’assistant ne peut les échanger. Le paquet conserve révision et périmètre de lecture pour permettre de contester une affirmation précise.

Travaillez d’abord réponses fermées. Dessinez la table ou le schéma requis et conservez les quantités intermédiaires, avec unités ou conventions d’identité. Cette dérivation manuscrite est la référence manuelle directe. Consultez seulement ensuite un assistant ou une aide à la traduction. Gardez la question, l’emplacement cité, la suggestion reçue et la modification acceptée ou rejetée. Comparez le résultat assisté à la première tentative conservée sur les mêmes entrées. Une réponse plus courte ne constitue pas un progrès si elle omet une condition ou invente un essai terminé.

## Modèle fixe et témoin à entrée modifiée

```json
{
  "values": {
    "centre": 4,
    "lower": 1,
    "upper": 9,
    "transform": "sqrt"
  },
  "formula": "display_centre=sqrt(centre); display_lower=sqrt(lower); display_upper=sqrt(upper); lower_extent=display_centre-display_lower; upper_extent=display_upper-display_centre",
  "expected": {
    "display_centre": 2,
    "display_lower": 1,
    "display_upper": 3,
    "lower_extent": 1,
    "upper_extent": 1
  },
  "negative_control": {
    "values": {
      "centre": 4,
      "lower": 0,
      "upper": 8,
      "transform": "sqrt"
    },
    "expected": {
      "display_centre": 2,
      "display_lower": 0,
      "display_upper": 2.8284271247461903,
      "lower_extent": 2,
      "upper_extent": 0.8284271247461903
    }
  }
}
```

### Exercice 1

Transformez le centre fourni.

<details><summary>Réponse 1</summary>

Le centre affiché vaut `2`. Cela transforme la référence seule, sans déterminer les bornes.

</details>

### Exercice 2

Transformez les bornes principales.

<details><summary>Réponse 2</summary>

Elles deviennent `[1,3]`. L’application croissante sur ce domaine conserve leur ordre.

</details>

### Exercice 3

Dérivez les étendues affichées.

<details><summary>Réponse 3</summary>

Elles valent toutes deux `1`, malgré des distances brutes inégales. Soustrayez après transformation, sans transformer une longueur d’erreur brute.

</details>

### Exercice 4

Appliquez le témoin brut symétrique.

<details><summary>Réponse 4</summary>

L’étendue basse vaut `2` et la haute `0.8284271247461903`. La symétrie brute ne survit pas à cette application non linéaire.

</details>

### Exercice 5

L’intervalle transformé établit-il une confiance statistique ?

<details><summary>Réponse 5</summary>

Non. Les bornes admissibles sont posées. Une interprétation de confiance exige un protocole d’échantillonnage justifié que l’axe ne fournit pas.

</details>

## Travail avec sources et référence manuelle directe

Esquissez une comparaison avec axe brut et axe en racine carrée. Placez les mêmes bornes à la main, puis faites expliquer chaque étendue affichée sans remplacer l’intervalle initial.

Traitez le témoin comme un enregistrement distinct. Préservez le cas principal, écrivez une prédiction pour l’entrée modifiée et expliquez quelle prémisse change. En cas d’écart avec la première réponse, distinguez erreur de calcul, erreur d’interprétation et limite du modèle. Gardez tentative échouée et correction côte à côte. Le travail demande une note vérifiable avant de proposer un nœud DSL ou un flux d’agents ; une table manuelle peut déjà répondre au besoin.

Soumettez ensemble référence initiale, emplacements de sources, explication corrigée, résultat du témoin et critère de réfutation. Les critères préparés ci-dessous s’adressent à une révision future ; ils ne sont pas des apprentissages acceptés. Réponse réelle, historique d’aide, correction et décision restent vides jusqu’à conservation d’une tentative. Révision technique, révision linguistique, exécution, adoption en production et publication exigent chacune leurs preuves applicables. Un calcul fini réussi établirait seulement l’opération déclarée dans ses hypothèses.

## Critère de réfutation annoncé

Une règle imposant des étendues égales au témoin est réfutée par ses bornes transformées indépendamment.

## Critères d’apprentissage préparés

- Pour l’exercice 1: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 2: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 3: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 4: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.
- Pour l’exercice 5: conserver une réponse correcte, le raisonnement intermédiaire et le périmètre déclaré ; la décision d’apprentissage reste indécise.

## Sources et périmètre des affirmations

- [Prérequis commité: dv-016-compare-paired-silhouette-residuals](../../data-visualization/dv-016-compare-paired-silhouette-residuals/)
- [Source de projet conservée](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Lecture primaire](https://docs.python.org/3/library/math.html)
- [Paquet construit](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-b/journal.md)
