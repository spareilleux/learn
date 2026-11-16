---
title: Comparer des résidus de silhouette appariés
description: Comparer des résidus de silhouette appariés — Visualisation de données
sidebar:
  label: DV-016 · Comparer des résidus de silhouette appariés
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/data-visualization/fr/dv-016-compare-paired-silhouette-residuals.fr.md
---

:::note[Streeling University]
**DV-016** · Comparer des résidus de silhouette appariés · intermédiaire · 45 minutes

Généré par le département *Visualisation de données* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/data-visualization/fr/dv-016-compare-paired-silhouette-residuals.fr.md) · [Mon journal](../../journal/)

Prérequis: [DV-006](../../data-visualization/dv-006-position-length-area-comparisons/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un nettoyage réduit le pire résidu de silhouette d’une sculpture tout en dégradant d’autres vues. La seule amélioration moyenne masque ces vues ; trier les colonnes séparément détruit leur appariement. Nous préparons une comparaison avant-après indexée par identité de caméra. La question est de savoir quelles vues changent, pas seulement si deux collections ont des moyennes différentes.

## Lire la limite conservée

Le pipeline demande plusieurs images de rotation et une résolution. Ces arguments motivent une revue par point de vue, mais ne contiennent aucun résidu de notre sculpture. Les valeurs suivantes sont des pixels inventés selon une convention de comparaison proposée.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Un résidu exige une frontière de référence, une définition dans l’image et une caméra appariée. Chaque scalaire est ici l’erreur déclarée d’une caméra. Reliez les valeurs avant et après sur une échelle commune en conservant son étiquette. Un changement négatif améliore ce critère, car les faibles résidus sont préférés. Une moyenne négative ne prouve pas que toutes les vues progressent. Le témoin réattribue des valeurs sans modifier leur collection. Les résumés subsistent mais les écarts appariés changent : l’identité de vue est une donnée, pas une décoration.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"view_ids":["front","side","back"],"before_px":[2,8,2],"after_px":[4,3,4]}
delta_i=after_i-before_i; mean_delta=sum(delta)/len(delta); worst_before=max(before); worst_after=max(after)
```

## Exercices corrigés

### Exercice 1

Calculez les changements dans l’ordre des caméras.

<details><summary>Réponse 1</summary>

Ils valent `[2,-5,2] px`. Face et dos se dégradent ; le côté s’améliore. Gardez l’ordre des caméras avec le vecteur.

</details>

### Exercice 2

Trouvez le changement moyen et les pires résidus.

<details><summary>Réponse 2</summary>

Le changement moyen vaut `-1/3 px` ; le pire résidu passe de `8 px` à `4 px`. Ces résumés coexistent avec des vues dégradées.

</details>

### Exercice 3

Appliquez le témoin aux valeurs finales réattribuées.

<details><summary>Réponse 3</summary>

Les changements deviennent `[1,-4,2] px`, tandis que la moyenne reste `-1/3 px` et les pires résidus `8 px` et `4 px`. L’appariement change sans changer les agrégats.

</details>

### Exercice 4

Pourquoi trier indépendamment les colonnes est-il trompeur ?

<details><summary>Réponse 4</summary>

Cela apparie des rangs statistiques au lieu des caméras. Un segment pourrait relier des points de vue différents et ne décrirait plus l’effet du nettoyage pour une vue.

</details>

### Exercice 5

Un maximum réduit prouve-t-il une meilleure fidélité artistique ?

<details><summary>Réponse 5</summary>

Non. Le résidu choisi mesure une tâche géométrique. Éléments signifiants, matériaux, éclairage et jugement artistique exigent d’autres critères et des observations réelles.

</details>

## Tâche avec consultation des sources

Dessinez les segments appariés légendés et annotez toute dégradation avant les réponses. Repérez les arguments de capture et le contrat d’image de référence absent. Une prétendue amélioration de toutes les vues est réfutée par un changement positif correctement apparié.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: dv-006-position-length-area-comparisons](../../data-visualization/dv-006-position-length-area-comparisons/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
