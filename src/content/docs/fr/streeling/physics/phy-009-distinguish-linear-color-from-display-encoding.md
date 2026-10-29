---
title: Distinguer la couleur linéaire de l'encodage d'affichage
description: Distinguer la couleur linéaire de l'encodage d'affichage — Physique
sidebar:
  label: PHY-009 · Distinguer la couleur linéaire de l'encodage d'affichage
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-009-distinguish-linear-color-from-display-encoding.fr.md
---

:::note[Streeling University]
**PHY-009** · Distinguer la couleur linéaire de l'encodage d'affichage · intermédiaire · 35 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-009-distinguish-linear-color-from-display-encoding.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-005](../../visual-computing/vc-005-craft-details-through-blender-to-godot/)
:::

> **Portée du brouillon.** Code public de rendu de GA à une révision précise, calculs de référence de fonctions de transfert et image numérique témoin originale. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun shader, import [Blender](https://docs.blender.org/manual/en/4.5/render/color_management.html)/[Godot](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/shading_language.html#using-source-color), image GPU, écran étalonné ni essai humain sur l'apparence n'ont été mis à l'épreuve.

## La question du projet

Une surface tissée ou un mur sculpté change d'apparence lorsqu'un actif passe d'un environnement à un autre. Avant de modifier sa géométrie ou son générateur de textures, déterminez quelles valeurs représentent une couleur encodée, des coordonnées en lumière linéaire et des données. Le [script public de précalcul des textures BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/textures/bake_blender.py) déclare séparément un albédo sRGB et des textures de données regroupées non colorimétriques. Son [modèle Lego](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L87-L94) déclare les couleurs des boîtes en RGB linéaire. Ce sont des contrats d'entrée différents à la révision publique de GA `76efbffd5af82b46c3146957a6bd4504008eeb89`.

Le [brouillon daté de Color 4 du W3C](https://www.w3.org/TR/2026/CRD-css-color-4-20261020/#color-conversion-code) fournit la référence sRGB définie par morceaux utilisée ci-dessous. Ce document en cours d'élaboration sert de référence à nos calculs, et non de certification du pipeline de rendu du projet. Les exemples restent dans les coordonnées positives ou nulles de 0 à 1.

## 1. Déclarer la coordonnée avant d'interpréter sa valeur

Pour un canal encodé C, la référence donne `L=C/12.92` lorsque `C<=0.04045` ; sinon, `L=((C+0.055)/1.055)^2.4`. Ainsi, la valeur encodée 0.5 correspond à la valeur linéaire 0.21404114048223255. Une valeur linéaire de 0.5 s'encode en 0.7353569830524495. Le nombre 0.5 seul ne permet pas d'identifier laquelle de ces valeurs était visée.

Les coordonnées RGB en lumière linéaire permettent les calculs d'addition de lumière du modèle de couleur choisi. Ce ne sont ni une luminance mesurée en cd/m², ni le spectre de réflectance physique d'un matériau, ni un jugement de luminosité d'un participant. Une véritable affirmation photométrique exige la mesure pertinente de l'écran ou de la scène.

### Exercice 1 : interpréter deux fois le même nombre

Comparez 0.5 encodé et 0.5 linéaire. Donnez la coordonnée linéaire de référence du premier et la coordonnée encodée du second. L'un ou l'autre de ces nombres permet-il à lui seul d'établir une luminance mesurée à l'écran ?

> **Réponse:** La valeur encodée 0.5 se décode en environ 0.21404114048223255 ; la valeur linéaire 0.5 s'encode en environ 0.7353569830524495. Aucune ne suffit à établir une luminance mesurée à l'écran. Il faudrait connaître le système de coordonnées et disposer d'une mesure physique réelle.

## 2. Choisir le domaine dans lequel combiner la lumière

Les [calculs fixés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/color-contract-2026-10-22/transfer-calculations.json) font la moyenne du noir et du blanc dans deux domaines. Faire la moyenne de leurs valeurs extrêmes encodées donne 0.5 encodé. Faire la moyenne des valeurs extrêmes linéaires correspondantes donne 0.5 linéaire, qui s'encode en environ 0.7353569830524495. Avec la quantification déclarée sur 8 bits par arrondi au plus proche, ces valeurs deviennent les octets 128 et 188.

La quantification compte : l'octet 128 se décode en environ 0.21586050011389926, tandis que l'octet 188 se décode en environ 0.5028864580325687. Ces valeurs ne sont pas exactement égales aux valeurs de référence non quantifiées. Le panneau supérieur de l'image illustre ces choix numériques conçus pour le cours ; il ne s'agit pas d'une comparaison de luminance étalonnée.

![Échantillons de valeurs médianes et témoin contextuel à cibles identiques conçus pour le cours](https://raw.githubusercontent.com/spareilleux/learn/50a9e9d5604dfe60c37f4a52d6bfa5e2ca376e63/code/streeling/evidence/color-contract-2026-10-22/color-context-controls.png)

La figure partagée utilise des libellés anglais ; le panneau supérieur oppose les deux domaines de calcul, tandis que le panneau inférieur sert à une tâche contextuelle distincte.

### Exercice 2 : vérifier une valeur médiane

Un worker calcule la moyenne du noir et du blanc directement dans les coordonnées encodées et indique l'octet 128. Un autre les combine dans les coordonnées linéaires puis réencode le résultat, indiquant 188. Lequel suit le mélange déclaré en lumière linéaire ? Pourquoi ne faut-il pas affirmer que son résultat quantifié puis décodé est exactement égal à 0.5 ?

> **Réponse:** L'octet 188 suit le mélange déclaré en lumière linéaire. Il provient de l'encodage de 0.5 linéaire suivi d'un arrondi. Le décodage de l'octet quantifié donne environ 0.5028864580325687 plutôt qu'exactement 0.5 ; la quantification finie modifie la valeur représentée.

## 3. Examiner l'approximation réellement utilisée par le projet

Le [shader de matériau](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L587-L655) à la révision fixée applique une puissance de 2.2 à l'albédo échantillonné dans les parcours béton, façade et machine. Pour 0.5 encodé, cette puissance donne 0.217637640824031, soit un écart d'environ 0.003596500341798453 par rapport à la référence. C'est une approximation, et non la fonction exacte définie par morceaux.

Le parcours de bardage examiné utilise plutôt le RGB échantillonné dans une expression tonale pondérée, sans la même expression de puissance. Ne généralisez pas une politique de conversion à tous les matériaux. Il s'agit d'observations du code ; aucune nouvelle comparaison de rendus n'établit la conséquence perceptive ou un résultat artistique préférable.

### Exercice 3 : borner une affirmation fondée sur le code

Calculez la puissance 2.2 de 0.5 et comparez-la à la référence. Une personne chargée de la revue peut-elle conclure que tous les matériaux BRUTAL utilisent la même conversion ou que l'écart numérique est visuellement gênant ?

> **Réponse:** La puissance donne environ 0.217637640824031, soit environ 0.003596500341798453 au-dessus de la référence. L'expression du bardage diffère ; l'affirmation d'une politique uniforme n'est donc pas étayée. L'écart numérique seul n'établit aucun jugement d'observateur sur la visibilité ou la qualité.

## 4. Ne pas déplacer l'exposition de part et d'autre d'une courbe non linéaire

Le [shader de composition](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L1186-L1228) nomme aces sa courbe rationnelle bornée. Le calcul pédagogique évalue cette courbe scalaire isolée, sans prétendre réaliser une transformation complète de gestion des couleurs ACES. Pour une entrée de 0.25 et une exposition de 2, appliquer l'exposition avant la courbe donne environ 0.6163069544364508. Doubler la valeur de 0.25 déjà transformée par la courbe donne plutôt environ 0.7482219061166429.

Le code réel combine également le bloom, l'étalonnage RGB, une vignette, une puissance de sortie de 1/2.2 et du grain. La courbe isolée ne prédit pas un pixel capturé complet. Gardez ces étapes omises explicites lorsque vous comparez un calcul simplifié à un résultat de l'application.

### Exercice 4 : préserver l'ordre des opérations

Pour l'entrée pédagogique de 0.25 et l'exposition de 2, comparez l'exposition avant la courbe à la courbe suivie du doublement. Ces opérations sont-elles interchangeables ? L'un de ces résultats scalaires reproduit-il le shader de composition entier ?

> **Réponse:** Les résultats sont d'environ 0.6163069544364508 et 0.7482219061166429 ; les opérations ne sont donc pas interchangeables. Aucun ne reproduit la composition entière : le bloom, l'étalonnage RGB, la vignette, l'encodage de sortie et le grain sont omis de ce témoin scalaire.

## 5. Vérifier les conversions sans inventer un résultat d'importation

Les preuves vérifient les 256 valeurs d'octet par décodage, encodage et quantification déclarée ; chacune retrouve son octet d'origine. Cet aller-retour fini vérifie ces calculs, et non la fidélité d'un moteur de rendu ou la préférence d'un utilisateur. Un essai d'importation exige encore un espace source déclaré, les rôles de données ou de couleur des canaux, une politique de conversion, une transformation de sortie ou de visualisation et un résultat observé dans l'environnement cible.

[VC-010](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/) suit la texture regroupée, où appliquer un décodage de couleur modifie des valeurs censées être des données. [COG-006](../../cognitive-science/cog-006-separate-pixel-tests-from-appearance-judgments/) distingue les vérifications de pixels des questions d'apparence.

### Exercice 5 : rejeter une affirmation de vérification trop large

Les 256 allers-retours de référence réussissent. Un worker déclare que le transfert du matériau de Blender vers Godot est validé visuellement. Qu'est-ce qui a réellement été vérifié, et quelles preuves manquent ensuite ?

> **Réponse:** La vérification finie de référence du décodage, de l'encodage et de la quantification a réussi. Aucune importation de Blender vers Godot, aucun rendu cible, aucune comparaison sur écran étalonné ni aucun jugement d'observateur n'ont été réalisés. Une configuration déclarée de l'environnement et un résultat de transfert observé restent nécessaires pour cette affirmation plus large.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/color-contract-2026-10-22/learner-task.md) avec la référence et le code fixés. Distinguez la conversion mathématique, l'inspection du shader, la sortie réelle de l'environnement et la revue humaine.
