---
title: Calculer la longueur de pliage sur une couche neutre déclarée
description: Calculer la longueur de pliage sur une couche neutre déclarée — Physique
sidebar:
  label: PHY-011 · Calculer la longueur de pliage sur une couche neutre déclarée
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-011-compute-bend-length-on-a-declared-neutral-layer.fr.md
---

:::note[Streeling University]
**PHY-011** · Calculer la longueur de pliage sur une couche neutre déclarée · intermédiaire · 40 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-011-compute-bend-length-on-a-declared-neutral-layer.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> **Portée du brouillon.** Géométrie de pli circulaire conçue pour le cours, calculs exacts et lecture de code et de documents primaires à une révision précise. Les revues humaines technique, artisanale, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune éprouvette de matériau, machine de pliage, commande de CAO, vérification IX ou scène n'ont fait l'objet d'un essai. Le facteur de couche neutre est posé, et non étalonné.

## La question du projet

Un futur adaptateur de création peut-il déduire la longueur développée d'un flan métallique à partir d'un rapport d'épaisseur d'origami ? L'[ADR d'IX sur l'épaisseur à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/docs/adr/0007-origami-thickness-as-parallel-rigid-panels.md#L7-L34) décrit des vérifications à épaisseur nulle avec une lecture facultative en panneaux parallèles. Il exclut explicitement les refus liés au rayon de pliage et le mouvement de pliage. [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/) convertit les unités de cette lecture ; ce cours ajoute un modèle de pli distinct conçu pour l'exercice, sans prétendre qu'IX l'implémente.

La [référence des règles de tôlerie de Fusion](https://help.autodesk.com/cloudhelp/ENU/Fusion-Sheet-Metal/files/SM-RULES-REF.htm) distingue l'épaisseur, le rayon intérieur de pliage et le rapport de décalage de l'axe neutre. Son texte réel a été lu. Ces définitions motivent les grandeurs ci-dessous, mais ne fournissent aucun facteur mesuré pour notre matériau ou notre machine.

## 1. Déclarer la couche de référence

Utilisez un rayon intérieur pédagogique de 4 mm, une épaisseur totale de 2 mm et un facteur sans dimension de décalage neutre `k=0.4`. Définissez le rayon neutre par `R_n=R_i+k*t`, donnant 4.8 mm. Le rayon extérieur est de 6 mm. Supposez des couches circulaires concentriques et traitez l'arc neutre comme la longueur développée du pli ; c'est une règle géométrique simplifiée, et non une prédiction de déformation, de retour élastique ou de comportement de l'outillage.

Pour une amplitude de pliage de 90 degrés, soit `pi/2` radians, la longueur d'arc est le rayon multiplié par l'amplitude angulaire. Les arcs intérieur, neutre et extérieur valent respectivement `2*pi`, `2.4*pi` et `3*pi` mm. L'arc neutre mesure environ 7.539822369 mm. Des couches de référence différentes donnent des longueurs différentes même lorsqu'une scène représente la même région pliée.

### Exercice 1 : identifier l'arc développé

Calculez le rayon neutre et les trois longueurs d'arc pour le pli déclaré. Lequel utilise ce modèle, et le facteur choisi décrit-il une éprouvette physique mesurée ?

> **Réponse:** Le rayon neutre est `4+0.4*2=4.8` mm. Les arcs intérieur, neutre et extérieur sont `2*pi`, `2.4*pi` et `3*pi` mm. Le modèle utilise l'arc neutre `2.4*pi`, soit environ 7.539822369 mm. Le facteur 0.4 est une hypothèse pédagogique, et non une règle de matériau mesurée.

## 2. Ne pas remplacer une couche déclarée par le milieu

Choisir le rayon à mi-épaisseur donnerait 5 mm et une longueur développée de pli de `2.5*pi` mm. Cela dépasse la longueur de référence de `0.1*pi`, soit environ 0.314159265 mm. Utiliser plutôt l'arc intérieur ou extérieur la modifie de `-0.4*pi` ou de `0.6*pi` mm.

Ni une ligne médiane affichée ni le mot « épaisseur » ne choisissent automatiquement la couche neutre. Un milieu géométrique et un décalage neutre étalonné sont des grandeurs différentes. Une application peut afficher un milieu par commodité tout en conservant une règle de pliage distincte ; ce cours n'observe aucune implémentation de ce type.

### Exercice 2 : quantifier une substitution commode

Un agent remplace silencieusement le facteur posé par 0.5. Quels rayon, longueur développée de pli et erreur en résultent ? Une erreur d'affichage plus faible ou un pli visuellement plausible constituent-ils un étalonnage du matériau ?

> **Réponse:** Il utilise un rayon de 5 mm et une longueur développée de pli de `2.5*pi` mm, dépassant les `2.4*pi` posés de `0.1*pi`, soit environ 0.314159265 mm. Un résultat visuel n'étalonne pas le décalage neutre et ne montre pas que le modèle substitué décrit un procédé réel.

## 3. Préciser où se terminent les longueurs droites

Ajoutez deux longueurs droites pédagogiques de 30 et 20 mm, chacune mesurée jusqu'à la tangente où commence le pli circulaire. Le total à plat du modèle est donc `30+20+2.4*pi`, soit environ 57.539822369 mm. La convention de tangence rend ces régions droites disjointes de l'arc du pli.

Les cotes extérieures des ailes mesurées jusqu'à un coin vif virtuel suivent une autre convention. Ajouter ces nombres à l'arc entier sans les retraits ou déductions appropriés peut compter deux fois du matériau. Nous ne déduisons ici aucune formule de cotation extérieure. Une transmission doit conserver les extrémités de mesure plutôt qu'étiqueter toute longueur « longueur d'aile ».

### Exercice 3 : vérifier la convention de cotation

Calculez le total des longueurs mesurées aux tangentes. Peut-on utiliser la même expression sans modification si 30 et 20 désignent plutôt des cotes extérieures non précisées jusqu'à un coin virtuel ?

> **Réponse:** Le total mesuré aux tangentes est `50+2.4*pi`, soit environ 57.539822369 mm. Des cotes extérieures non précisées ne justifient pas cette somme : leur convention de recouvrement ou de retrait doit d'abord être résolue. Rebaptiser leurs nombres en longueurs aux tangentes changerait le problème.

## 4. Porter l'incertitude sous forme d'intervalle conditionnel

Posez séparément que `k` pourrait aller de 0.3 à 0.5, avec rayon, épaisseur et angle fixes. Les rayons neutres vont alors de 4.6 à 5 mm, et les longueurs développées des plis à 90 degrés de `2.3*pi` à `2.5*pi` mm. Leur largeur est `0.2*pi`, soit environ 0.628318531 mm. Le total correspondant est de 50 mm plus cet intervalle de longueur de pli.

La longueur développée du pli change de `pi` mm pour une variation unitaire de `k` sous ces prémisses fixes. C'est une sensibilité du modèle, et non une distribution de probabilité ou un intervalle de confiance. La plage choisie est une hypothèse pédagogique, et non une plage recommandée pour tous les métaux, outils ou procédés de formage.

### Exercice 4 : propager la plage de facteur posée

Déduisez l'intervalle de longueur développée du pli, sa largeur et l'intervalle de longueur totale. Qu'est-ce qui justifierait de le traiter comme une plage de procédé réel plutôt qu'un exemple pédagogique de sensibilité ?

> **Réponse:** La longueur développée du pli va de `2.3*pi` à `2.5*pi` mm, de largeur `0.2*pi` ; la longueur totale va de `50+2.3*pi` à `50+2.5*pi` mm. Il faudrait des comportements de matériau et de procédé mesurés pertinents et un modèle justifié. Le calcul seul ne fournit ni étalonnage, ni probabilité, ni tolérance de production.

## 5. Garder la lecture d'IX à sa portée réelle

Le [module d'épaisseur à la révision fixée](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/src/thickness.rs#L1-L22) accepte l'épaisseur totale dans les unités du motif de plis et rapporte des lectures d'empilement. Son texte distingue explicitement le refus de panneaux parallèles d'une affirmation de fabricabilité. Les [tests d'épaisseur existants](https://github.com/GuitarAlchemist/ix/blob/d7c22fdd6a62becb66b9d7246ea85850e7c55854/crates/ix-origami/tests/thickness.rs) sont des assertions du code sur ce modèle ; aucun nouveau test n'a été exécuté dans ce dossier.

### Exercice 5 : corriger l'affirmation de fabrication

Un agent qualifie un rapport d'épaisseur IX de flan métallique développé certifié. Quelles grandeurs et observations supplémentaires manquent à cette conclusion ?

> **Réponse:** Le rapport sélectionné ne fournit ni les unités physiques du modèle de pli circulaire, ni le rayon intérieur, la règle de décalage neutre, la convention d'angle de pliage ou les extrémités des cotes aux tangentes. Un procédé réel exige aussi un étalonnage pertinent et des contrôles de retour élastique, de dégagement, d'outillage et de mouvement ou de jeu. Le calcul pédagogique d'arc et une lecture d'empilement ne certifient ni un flan physique ni sa fabrication. Aucun essai de ce type n'a eu lieu ici.

Le [relevé de pliage fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/bend-development-2026-10-22/bend-lengths.json) conserve les multiples exacts de pi avec les décimales affichées. [SEM-007](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/) suit le même calcul à travers différents sens de l'angle.
