---
title: Prévoir la largeur en pixels d’un point de broderie
description: Prévoir la largeur en pixels d’un point de broderie — Informatique visuelle
sidebar:
  label: VC-014 · Prévoir la largeur en pixels d’un point de broderie
  order: 14
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-014-predict-an-embroidered-stitch-pixel-footprint.fr.md
---

:::note[Streeling University]
**VC-014** · Prévoir la largeur en pixels d’un point de broderie · intermédiaire · 45 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-014-predict-an-embroidered-stitch-pixel-footprint.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-005](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un fil survit au nettoyage Blender mais disparaît dans une vue générale Godot envisagée. La conservation géométrique et la visibilité à l’écran répondent à des questions différentes. Nous prévoyons la largeur projetée d’un point avant de choisir entre géométrie et texture. Le calcul donne une empreinte dépendant de la caméra, sans affirmer qu’une personne reconnaît le point, ni mesurer un moteur de rendu ou un système de mise à l’échelle.

## Lire la limite conservée

Le script de nettoyage propose un argument de résolution pour ses captures. Il ne définit ni viewport Godot ni champ de vision. Le modèle de caméra ci-dessous est construit séparément ; la référence Godot explique les projections et le choix d’axe du champ de vision.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Associez la hauteur du viewport au champ de vision vertical pour exprimer la focale en pixels. Divisez la largeur physique par la distance à la caméra, puis multipliez par cette focale. Les longueurs doivent partager la même unité. La projection suppose un élément parallèle au plan image ; un point incliné aurait une autre largeur. Le seuil est un choix de conception qui attend une observation. Il ne décrit ni acuité, ni contraste, ni ombrage, ni stabilité temporelle. Une caméra orthographique exige un autre modèle : sa taille projetée ne diminue pas ainsi avec la distance.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"width_m":0.002,"distance_m":1,"viewport_height_px":1000,"vertical_fov_deg":90,"required_px":2}
focal_px=viewport_height_px/(2*tan(vertical_fov_deg*pi/360)); width_px=focal_px*width_m/distance_m; meets_declared_threshold=width_px>=required_px
```

## Exercices corrigés

### Exercice 1

Calculez la focale en pixels pour le cas principal.

<details><summary>Réponse 1</summary>

La focale vaut `500 px`. Associer un champ vertical à la largeur du viewport répondrait à une autre question de projection, généralement incorrecte.

</details>

### Exercice 2

Trouvez la largeur projetée et comparez-la au seuil déclaré.

<details><summary>Réponse 2</summary>

Elle vaut `1 px`, sous le seuil de `2 px`. Cela rejette uniquement l’exigence géométrique construite ; aucune invisibilité réelle n’est démontrée.

</details>

### Exercice 3

Appliquez le témoin avec caméra rapprochée sans changer le maillage.

<details><summary>Réponse 3</summary>

La largeur devient `2 px` et atteint le seuil déclaré. Une même géométrie produit des empreintes différentes selon la distance de vue.

</details>

### Exercice 4

La formule se transpose-t-elle telle quelle à une vue orthographique ?

<details><summary>Réponse 4</summary>

Non. La division par la distance appartient à la perspective. Le modèle orthographique exige la taille de vue et sa correspondance au viewport.

</details>

### Exercice 5

Atteindre le seuil établit-il un résultat DLSS ou de reconnaissance ?

<details><summary>Réponse 5</summary>

Non. Aucun système de mise à l’échelle ni observateur n’a été testé. Contraste, échantillonnage, mouvement et reconnaissance restent des questions distinctes à observer.

</details>

## Tâche avec consultation des sources

Préparez une fiche indiquant largeur physique, convention des axes de caméra, distance, viewport et largeur prévue. Calculez manuellement avant de consulter le dossier. Réfutez une visibilité inconditionnelle en changeant seulement la distance ; proposez une capture à caméra identique comme preuve future, sans la déclarer exécutée.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: vc-005-craft-details-through-blender-to-godot](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/glb_pipeline.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
