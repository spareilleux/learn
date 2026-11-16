---
title: Distinguer les tests de pixels des jugements d'apparence
description: Distinguer les tests de pixels des jugements d'apparence — Sciences cognitives
sidebar:
  label: COG-006 · Distinguer les tests de pixels des jugements d'apparence
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cognitive-science/fr/cog-006-separate-pixel-tests-from-appearance-judgments.fr.md
---

:::note[Streeling University]
**COG-006** · Distinguer les tests de pixels des jugements d'apparence · intermédiaire · 35 minutes

Généré par le département *Sciences cognitives* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cognitive-science/fr/cog-006-separate-pixel-tests-from-appearance-judgments.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-009](../../physics/phy-009-distinguish-linear-color-from-display-encoding/)
:::

> **Portée du brouillon.** Témoin numérique original, comparaisons exactes de pixels, inspection du code public de capture à une révision précise et lecture d'une étude primaire sur la perception. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun observateur n'a participé, aucune luminance d'écran n'a été mesurée et aucune expérience de perception citée n'a été reproduite.

## La question du projet

Un agent compare une capture d'une scène de surfaces travaillées avec sa texture source et affirme : « les couleurs correspondent ». Cela pourrait désigner des octets identiques, des coordonnées interprétées identiques, une luminosité apparente similaire ou une réflectance de matériau suggérée similaire. Ce sont des questions différentes. [PHY-009](../../physics/phy-009-distinguish-linear-color-from-display-encoding/) a établi la distinction entre coordonnées ; ce cours précise ce qu'un test de pixels permet ou non de déterminer.

L'[étude primaire de Lovell et ses collègues de 2026](https://pmc.ncbi.nlm.nih.gov/articles/PMC12876641/) examine les réponses de luminosité et de clarté en faisant varier des indices dans un stimulus de blocs en damier. Son résumé et son introduction motivent la distinction entre intensité lumineuse perçue et réflectance de surface inférée. Nous ne copions pas son stimulus et ne présentons pas notre témoin plus simple à deux entourages comme une reproduction, un effet mesuré ou une prédiction de la réponse de chaque observateur.

## 1. Poser précisément la question des pixels

Le panneau inférieur de l'image originale contient deux carrés cibles de 160 par 160. Chaque cible contient 25600 pixels dont les octets RGB sont 128, 128, 128. L'entourage gauche a la valeur d'octet 32 et l'entourage droit 224. L'[audit des pixels](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/color-contract-2026-10-22/figure-pixel-audit.json) associe les coordonnées de recadrage en intervalles semi-ouverts, les octets de l'image, les empreintes identiques des recadrages cibles et l'interprétation sRGB indiquée par la balise.

![Témoins de valeurs médianes et de contexte à cibles identiques conçus pour le cours](https://raw.githubusercontent.com/spareilleux/learn/50a9e9d5604dfe60c37f4a52d6bfa5e2ca376e63/code/streeling/evidence/color-contract-2026-10-22/color-context-controls.png)

La figure partagée possède des libellés anglais. Son panneau supérieur illustre les calculs sur les coordonnées ; son panneau inférieur fournit des octets cibles égaux dans des contextes différents. Les cibles sont des régions numériques vérifiées, et non des sorties lumineuses mesurées sur l'écran de l'utilisateur.

### Exercice 1 : définir la région de comparaison

Combien de pixels chaque cible contient-elle ? Que permet d'établir l'égalité des octets RGB de leurs recadrages ? Établit-elle l'égalité des panneaux environnants complets ou du jugement d'un participant ?

> **Réponse:** Chaque cible contient 25600 pixels. Les tableaux d'octets RGB de leurs recadrages sont égaux selon les coordonnées déclarées. Les entourages diffèrent, et l'égalité des octets n'établit aucun jugement de participant ni aucune luminance d'écran mesurée par un instrument.

## 2. Distinguer l'égalité numérique de l'expérience demandée

La luminosité est un jugement perceptif sur l'intensité apparente de la lumière ; la clarté concerne la réflectance perçue de la surface. Aucune n'est simplement un octet de fichier. L'audit des pixels répond à la question de savoir si deux recadrages cibles contiennent des valeurs RGB identiques. Pour savoir si une surface tissée semble faite du même matériau sous un éclairage différent, il faut une question opérationnelle distincte et un contexte adapté.

Le [protocole préparé pour la tâche](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/color-contract-2026-10-22/appearance-task-design.json) demande quelle cible semble la plus lumineuse, tout en autorisant les réponses gauche, droite, égales et incertain. Il ne contient aucun participant ni aucune donnée de réponse. La bonne réponse à l'exercice n'est pas un sens d'illusion imposé. Consignez ce qu'un observateur rapporte réellement, ainsi que les conditions d'observation et la question posée.

### Exercice 2 : éviter d'inventer un corrigé

Un apprenant vérifie que les octets des cibles sont identiques. Un observateur ultérieur doit-il répondre « égales » à la question d'apparence ? « Le même matériau peint » est-il la même question que « la même intensité lumineuse apparente » ?

> **Réponse:** Le test d'octets n'impose aucune réponse à l'observateur. Consignez la réponse réelle plutôt que de noter un sens supposé d'illusion comme s'il était vrai. La réflectance suggérée du matériau et l'intensité lumineuse apparente sont des jugements distincts qui exigent des questions précisées séparément.

## 3. Ne pas déduire tout le parcours d'affichage d'une capture d'écran

Le [code public d'écriture des captures BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L4308-L4337), à la révision `76efbffd5af82b46c3146957a6bd4504008eeb89`, convertit les octets BGRA de la chaîne de présentation en données PNG RGB. Le code examiné écrit des blocs d'image sans bloc d'espace colorimétrique. Cette observation du code n'est ni une nouvelle capture ni une preuve de la manière dont un navigateur réel a interprété un fichier.

Notre témoin original contient explicitement un bloc sRGB. Cette balise déclare une interprétation prévue ; elle n'étalonne pas le moniteur, n'établit pas l'éclairage ambiant et ne mesure pas la radiance qui atteint l'œil. La mise à l'échelle, les réglages de gestion des couleurs et le parcours d'affichage doivent être consignés lorsqu'ils comptent pour la comparaison. L'égalité des octets de fichiers ne peut pas remplacer ces observations manquantes.

### Exercice 3 : interpréter les métadonnées à leur juste portée

Le PNG conçu pour le cours contient un bloc sRGB. Le code examiné d'écriture des captures du projet n'en produit pas. L'un ou l'autre de ces faits permet-il d'établir une correspondance visuelle étalonnée entre les deux flux de travail ?

> **Réponse:** Non. L'un déclare une interprétation d'image et l'autre identifie une omission de métadonnées dans le code. Aucun ne fournit une comparaison réelle de captures, une configuration de navigateur ou d'écran, une luminance mesurée ou un résultat d'observateur. Aucune correspondance étalonnée n'a été testée.

## 4. Contrôler la disposition sans prétendre qu'une expérience a eu lieu

Le protocole préparé propose d'inverser les entourages sombre et clair entre la gauche et la droite en gardant les octets et les dimensions des cibles fixes. Cela aide à distinguer une éventuelle préférence de côté d'une réponse liée au contexte. Seule la première disposition est rendue dans ce dossier ; la version inversée est prévue et ne constitue ni un essai effectué ni un second stimulus publié.

Ne dites pas aux participants quelle cible devrait sembler la plus lumineuse. Conservez les choix égales et incertain, préservez les réponses réelles et les exclusions, et consignez la transformation d'image ou de visualisation, l'échelle et les conditions d'observation. Ce petit témoin n'établit ni un effet dans une population, ni une ampleur d'effet, ni le réalisme d'un matériau travaillé, ni le transfert d'un résultat de l'étude citée sur les blocs en damier.

### Exercice 4 : corriger une procédure orientée

Un essai proposé place toujours l'entourage sombre à gauche et demande : « Voyez-vous que la cible gauche est plus lumineuse ? » Proposez deux changements et indiquez ce que le dossier actuel contient réellement.

> **Réponse:** Contrebalancez le côté des entourages et utilisez une question neutre avec les choix égales et incertain. Le dossier contient une disposition conçue pour le cours et des vérifications exactes de pixels, mais aucun rendu de la disposition inversée, aucun participant ni aucune réponse. La procédure révisée reste une proposition tant qu'elle n'a pas été réalisée.

## 5. Renvoyer des preuves distinctes à l'agent

Une transmission entre agents peut indiquer dans des champs distincts l'égalité des octets des recadrages cibles, l'encodage de couleur déclaré, les réglages connus du parcours d'affichage et un résultat d'observateur. Les preuves d'observation absentes restent absentes. Il s'agit d'un enregistrement de tâche proposé, et non d'un nouveau schéma normatif de l'écosystème. Un test de pixels positif peut étayer la vérification d'un artefact tout en laissant une décision sur la qualité d'un matériau non résolue.

[VC-010](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/) montre pourquoi l'interprétation même des octets RGBA peut dépendre d'un contrat de canaux. Un tuple numérique identique utilisé comme données de normales, de rugosité ou de hauteur n'est pas le même type d'affirmation qu'un tuple identique utilisé comme couleur affichée.

### Exercice 5 : rédiger une conclusion limitée aux preuves

Un agent possède l'empreinte de l'image et des octets identiques pour les recadrages cibles, mais aucun relevé d'observateur. Rédigez la conclusion étayée et une prochaine action pour évaluer l'apparence de la surface travaillée.

> **Réponse:** Les recadrages cibles conçus pour le cours sont identiques octet par octet selon les coordonnées enregistrées et l'interprétation indiquée par la balise de l'image. Aucun résultat d'observateur ni aucune équivalence de qualité des matériaux ne sont établis. Définissez la question d'apparence visée et recueillez une observation dans l'environnement cible avec des conditions de visualisation contrôlées de manière adaptée avant de revendiquer ce résultat plus large.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/color-contract-2026-10-22/learner-task.md). Expliquez comment un test de pixels valide et une question d'apparence non résolue peuvent coexister, sans remplacer une réponse absente par une valeur numérique par défaut.
