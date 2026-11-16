---
title: Fixer une erreur de corde pour un profil sculpté
description: Fixer une erreur de corde pour un profil sculpté — Informatique visuelle
sidebar:
  label: VC-015 · Fixer une erreur de corde pour un profil sculpté
  order: 15
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-015-budget-a-sculpture-profile-chord-error.fr.md
---

:::note[Streeling University]
**VC-015** · Fixer une erreur de corde pour un profil sculpté · intermédiaire · 45 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-015-budget-a-sculpture-profile-chord-error.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-005](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Une sculpture peu polygonée peut respecter un budget de triangles tout en perdant un bord courbe qui l’identifie. Nous ajoutons une tolérance géométrique explicite au budget de simplification. Un profil circulaire idéal est remplacé par un polygone régulier inscrit, puis nous calculons l’écart radial maximal de chaque corde. Cette coupe volontairement simple permet d’examiner la précision sans exécuter Blender.

## Lire la limite conservée

Le pipeline de nettoyage propose une cible maximale de triangles et un remaillage voxel facultatif. Aucun paramètre inspecté ne borne une silhouette circulaire précise. Notre coupe fournit un critère distinct pour un bord envisagé, sans supposer qu’une géométrie moins coûteuse le conserve.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Chaque segment couvre le même angle au centre. À son milieu, la corde est intérieure au cercle ; soustrayez sa distance au centre du rayon. Cette flèche est une longueur, tandis que le nombre de segments est sans dimension. Le périmètre répond à une autre question et ne remplace pas l’erreur locale. Doubler le nombre de segments ne divise pas nécessairement l’erreur radiale par le même facteur. La tolérance choisie appartient à cet élément construit et à ses unités. Courbures variables, arêtes et sections non circulaires empêchent d’en faire une garantie globale pour une sculpture réelle.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"radius_mm":100,"segments":12,"tolerance_mm":1}
sagitta_mm=radius_mm*(1-cos(pi/segments)); perimeter_mm=2*segments*radius_mm*sin(pi/segments); acceptable=sagitta_mm<=tolerance_mm
```

## Exercices corrigés

### Exercice 1

Trouvez l’erreur radiale de corde du cas principal.

<details><summary>Réponse 1</summary>

La flèche vaut environ `3.407417371093169 mm`. Elle dépasse la tolérance déclarée de `1 mm` ; l’exigence du profil construit échoue.

</details>

### Exercice 2

Calculez le périmètre. Sa proximité certifie-t-elle la tolérance locale ?

<details><summary>Réponse 2</summary>

Le périmètre vaut environ `621.1657082460498 mm`. Une comparaison de longueurs globales ne remplace pas la condition d’erreur radiale maximale.

</details>

### Exercice 3

Appliquez le témoin avec davantage de segments.

<details><summary>Réponse 3</summary>

La flèche devient environ `0.8555138626189618 mm`, conforme à la tolérance ; le périmètre vaut `626.5257226562476 mm`. Le changement améliore cette construction précise.

</details>

### Exercice 4

Pourquoi ne peut-on pas appeler la cible de triangles une tolérance de silhouette ?

<details><summary>Réponse 4</summary>

Elle contraint une quantité, pas la position des triangles ni le profil approché. Les paramètres conservés ne promettent pas cette borne de flèche propre à un élément.

</details>

### Exercice 5

Que faut-il pour transférer la méthode à un bord non circulaire ?

<details><summary>Réponse 5</summary>

Conservez le profil de référence, les unités, la définition analytique ou échantillonnée de l’erreur, l’identité de l’élément et la tolérance. Le calcul circulaire ne prouve rien pour toute courbure.

</details>

## Tâche avec consultation des sources

Dessinez le centre, le milieu de corde et le rayon, puis calculez l’écart manuellement. Rédigez une note sur l’élément à côté du paramètre de triangles, sans changer le script. Un écart supérieur à la tolérance malgré le respect de la cible réfute la conservation revendiquée.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: vc-005-craft-details-through-blender-to-godot](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
