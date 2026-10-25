---
title: Borner le balayage d’une charnière de pli
description: Borner le balayage d’une charnière de pli — Physique
sidebar:
  label: PHY-016 · Borner le balayage d’une charnière de pli
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-016-bound-a-fold-hinge-sweep.fr.md
---

:::note[Streeling University]
**PHY-016** · Borner le balayage d’une charnière de pli · intermédiaire · 45 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-016-bound-a-fold-hinge-sweep.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-013](../../physics/phy-013-check-torque-when-moving-a-scene-pivot/)
:::

> Brouillon soumis à une revue technique et linguistique. Chaque scène, nombre, température, durée et résultat introduit ci-dessous est un exemple construit. La lecture des sources et les calculs ne constituent ni un essai physique, ni un import [Godot](https://docs.godotengine.org/en/4.5/), ni un rendu [Blender](https://raw.githubusercontent.com/blender/blender/v4.5.0/README.md), ni une exécution [ComfyUI](https://docs.comfy.org/), ni une observation d’apprentissage. Les décisions humaines et celles liées à l’exécution restent en attente.

## Question du projet

Un panneau plié peut finir à distance de son voisin tout en le traversant pendant son mouvement. Pour une sculpture en origami envisagée dans Godot, l’image finale répond donc à une question plus étroite que la trajectoire. Cette leçon suit un point repéré autour d’une charnière idéale et distingue sa distance à la charnière de son déplacement depuis la position initiale. Aucune de ces quantités n’est une déformation du matériau.

## Lire la limite conservée

L’utilitaire Atlas conservé précise son repère de modélisation et le parentage des objets. Une hiérarchie de charnière constitue ainsi une question d’intégration concrète, mais les lignes inspectées ne contiennent ni charnière d’origami ni essai de collision.

Lisez le prérequis et l’artefact conservé avant d’interpréter le modèle. La source a sa propre révision et son propre objectif ; elle fournit la limite décrite ici, pas les nouvelles données pédagogiques. Dressez un tableau distinguant un champ inspecté, une hypothèse, une quantité calculée et un effet envisagé dans la scène. Le résumé d’un agent doit renvoyer au champ interprété. Un nom de fichier ne suffit pas à établir un résultat antérieur.

## Interpréter le modèle

Placez la charnière à l’origine et le point repéré sur X positif. La rotation conserve son rayon tout en modifiant ses coordonnées finales. La corde reliant la position initiale à la position finale est plus courte que l’arc, sauf à la limite d’un angle nul. Notre marge compare uniquement deux rayons ; elle ne situe pas un obstacle fini. Une marge radiale positive ne prouve donc pas que le trajet est libre. La documentation Godot distingue rotation locale et rotation par rapport au parent ; le plan pédagogique est ici défini indépendamment de tout import.

La référence directe est un croquis légendé et un calcul manuel, réalisés sans ouvrir les réponses. Conservez les valeurs intermédiaires et les unités, puis appliquez l’entrée modifiée du témoin négatif. Un désaccord est instructif : cherchez s’il provient de la définition, du calcul, de la représentation ou de la tâche avant de modifier le modèle. Un accord sur le seul cas principal n’établit pas une règle universelle. Ces exemples finis rendent explicite une hypothèse qu’un aperçu fluide pourrait masquer.

```text
{"radius_mm":100,"angle_deg":60,"obstacle_radius_mm":90}
x=r*cos(theta*pi/180); y=r*sin(theta*pi/180); swept_displacement=2*r*sin(abs(theta)*pi/360); radial_margin=r-obstacle_radius
```

## Exercices corrigés

### Exercice 1

Calculez la position finale. Quelle coordonnée est restée fixe ?

<details><summary>Réponse 1</summary>

La position finale est `(50,86.60254037844386) mm`. Aucune coordonnée n’est fixe ; la charnière et le rayon le restent. Déclarez tout arrondi sans modifier la construction.

</details>

### Exercice 2

Calculez le déplacement rectiligne depuis le départ et comparez-le au rayon.

<details><summary>Réponse 2</summary>

La corde mesure `100 mm`, soit le rayon de ce cas. Cette égalité dépend de l’angle choisi ; elle ne définit pas une rotation.

</details>

### Exercice 3

Que permet d’établir la marge radiale au sujet d’un obstacle voisin ?

<details><summary>Réponse 3</summary>

Elle vaut `10 mm` dans cette comparaison radiale. Sans étendue angulaire ni volume occupé, elle ne prouve pas que le panneau évite l’obstacle.

</details>

### Exercice 4

Appliquez le témoin à angle nul. Un rayon conservé implique-t-il toujours une position finale inchangée ?

<details><summary>Réponse 4</summary>

Le témoin donne `(100,0) mm` et un déplacement de `0 mm`. Le cas principal modifie pourtant la position finale en conservant le même rayon.

</details>

### Exercice 5

Quelles données supplémentaires faut-il pour vérifier le dégagement pendant le mouvement ?

<details><summary>Réponse 5</summary>

Fournissez le repère de charnière, les volumes du panneau et de l’obstacle, tout l’intervalle angulaire et la convention de contact. Un point et une capture finale ne suffisent pas.

</details>

## Tâche avec consultation des sources

Dessinez le départ, l’arrivée et l’arc avant de consulter les réponses. Annotez une proposition de charnière parent-enfant dans l’utilitaire Atlas, sans le modifier. Un obstacle traversant une position intermédiaire alors que les extrémités sont libres réfute le critère fondé sur les seules extrémités.

Conservez séparément votre réponse initiale, les passages consultés, l’historique de l’aide reçue et les corrections ultérieures. Énoncez le résultat observable qui réfuterait votre recommandation avant de proposer une automatisation. Comparez la réponse assistée par les sources à votre référence manuelle, en précisant l’incertitude supplémentaire. Le dossier contient cinq critères préparés ; chaque décision reste nulle jusqu’à une véritable tentative suivie d’une revue. Les corrigés servent de vérification ; ils ne prouvent pas qu’un apprenant a effectué la tâche.

## Sources et journal de validation

- [Prérequis: phy-013-check-torque-when-moving-a-scene-pivot](../../physics/phy-013-check-torque-when-moving-a-scene-pivot/)
- [Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/blender/scripts/atlas/kit.py)
- [Source primaire](https://docs.godotengine.org/en/4.5/tutorials/3d/using_transforms.html)
- [Dossier fixe des exemples](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)
