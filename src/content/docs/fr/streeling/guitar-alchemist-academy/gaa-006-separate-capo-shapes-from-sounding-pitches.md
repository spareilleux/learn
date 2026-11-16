---
title: Distinguer les formes d'accord avec capo des hauteurs réelles
description: Distinguer les formes d'accord avec capo des hauteurs réelles — Guitar Alchemist Academy
sidebar:
  label: GAA-006 · Distinguer les formes d'accord avec capo des hauteurs réelles
  order: 6
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/fr/gaa-006-separate-capo-shapes-from-sounding-pitches.fr.md
---

:::note[Streeling University]
**GAA-006** · Distinguer les formes d'accord avec capo des hauteurs réelles · early-intermediate · 35 minutes

Généré par le département *Guitar Alchemist Academy* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/fr/gaa-006-separate-capo-shapes-from-sounding-pitches.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/), [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/)
:::

> **Portée du brouillon.** Code source public de GA à une révision précise, réponses réelles de l'outil de transposition d'accords et 312 cas de calcul de classes de hauteur conçus pour le cours. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Ce cours n'a exécuté ni CapoSkill ni un parcours de routage dans l'application, et n'a pas fait l'objet d'un essai sur une guitare physique.

## La question du projet

Un guitariste connaît l'accord demandé par le chanteur, mais souhaite utiliser une forme familière avec un capo. Un autre connaît la forme et demande ce que le groupe entendra. Ces questions parcourent la même relation dans des sens opposés. Le [CapoSkill](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Agents/Skills/CapoSkill.cs) public de GA, fixé à la révision `dc2e74cbd992a298f67efb928b5b3754615e1924`, distingue explicitement les deux.

Utilisez ici les noms de notes anglais, le calcul en demi-tons du tempérament égal et un capo ordinaire couvrant toutes les cordes. Un capo partiel, un autre accordage, les limites du manche et un doigté réel exigent des informations supplémentaires. [WML-005](../../world-music-languages/wml-005-declare-note-name-conventions/) explique pourquoi un B sans convention précisée doit être interprété avant tout calcul.

## 1. Additionner pour prévoir le son ; soustraire pour choisir une forme

En prenant C comme classe de hauteur 0, la classe réelle est la classe de la forme plus la case du capo, le tout réduit modulo 12. Pour choisir une forme donnant le son demandé, soustrayez la case du capo et ramenez le résultat à une classe positive ou nulle. La compétence à la révision fixée valide les cases de 0 à 12 ; cette contrainte du code source est distincte de l'étendue physique de chaque guitare ou de tous les placements de capo possibles.

Les [essais réels de transposition de GA](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/theory-tool-probes.json) ont renvoyé C# pour B monté de 2 et Gm pour Bm descendu de 4. Il s'agit d'appels à l'outil de transposition d'accords, avec une révision de service inconnue. Ce ne sont pas des exécutions du CapoSkill à la révision fixée ni une preuve qu'une demande en anglais ou en français lui parvient.

### Exercice 1 : identifier le sens du calcul

Quel accord entend-on lorsqu'on joue une forme de B majeur avec un capo 2 ? Quelle forme mineure produit un B mineur réel avec un capo 4 ? Donnez les calculs de classes de hauteur.

> **Réponse:** La forme de B majeur donne C# majeur : `(11+2)%12 = 1`. Un B mineur réel avec un capo 4 exige une forme de G mineur : `(11-4)%12 = 7`. L'addition prévoit le son à partir d'une forme ; la soustraction choisit la forme à partir du son souhaité.

## 2. Préserver la qualité en déplaçant la fondamentale

Dans ce cours, une triade majeure possède les intervalles relatifs en demi-tons 0, 4 et 7 ; une triade mineure possède 0, 3 et 7. Ajouter le même décalage à chaque note préserve ces intervalles relatifs. Le [dossier de calculs fixés](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/capo-arithmetic.json) énumère 12 classes de départ, 13 positions de capo et 2 qualités, soit 312 cas. Chacun retrouve sa classe de départ par l'opération inverse et préserve les intervalles de triade déclarés.

Il s'agit d'une vérification arithmétique finie. Elle ne mesure pas le confort du doigté, ne prouve pas la prise en charge de toutes les extensions de symboles d'accord et n'établit pas qu'un musicien a produit le son prévu. En particulier, remplacer la forme de G mineur de l'exercice précédent par G majeur modifie la qualité demandée, même si la classe de la fondamentale est correcte.

### Exercice 2 : détecter une erreur de qualité

Pour obtenir un B mineur réel avec un capo 4, comparez une forme de G mineur et une forme de G majeur. Donnez la liste d'intervalles relatifs obtenue pour chacune. Pourquoi vérifier seulement la fondamentale ne suffit-il pas ?

> **Réponse:** G mineur préserve les intervalles 0, 3, 7 et produit B mineur. G majeur préserve 0, 4, 7 et produit B majeur. Les deux atteignent la classe de fondamentale 11 ; une vérification limitée à la fondamentale manque le changement de tierce et donc de qualité.

## 3. Une classe de hauteur ne conserve pas l'octave

Le capo 12 redonne la même classe de hauteur. Il ne redonne pas la même hauteur absolue. Le témoin de registre conçu pour le cours part du E grave à vide au numéro MIDI 40 et ajoute 12 pour obtenir 52, soit E une octave plus haut. Les deux se réduisent à la classe 4. Une réponse sur le capo exprimée comme fondamentale d'accord est donc insuffisante lorsqu'un autre agent a besoin d'un numéro précis de note réelle.

Le [TabToPitchConverter](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.ML/Tabs/TabToPitchConverter.cs) de GA à la révision fixée combine séparément les décalages de l'accordage standard avec les positions de cases ; la conversion examinée n'a pas de paramètre de capo. Cette observation du code source n'est pas une nouvelle exécution du convertisseur. Ne supposez pas que la présence de calculs de capo ailleurs signifie que tous les parcours de tablature les appliquent.

### Exercice 3 : conserver le registre

Le témoin part de 40 avec un capo 12. Donnez le numéro absolu obtenu et les deux classes de hauteur. Une réponse limitée à « E » permet-elle de montrer que l'octave est correcte ?

> **Réponse:** Le résultat absolu est 52 ; les deux classes de hauteur sont 4. « E » seul ne distingue pas 40 de 52. Conservez la note absolue ou le registre lorsque la tâche destinataire exige la hauteur réelle plutôt qu'une simple fondamentale d'accord.

## 4. Distinguer normalisation, transposition et graphie

Pour un B allemand déclaré, normalisez d'abord en Bb anglais, classe 10. Le capo 2 donne ensuite la classe 0, soit C. Pour un B anglais, le même capo donne la classe 1, soit C#. Le [tableau de décision linguistique](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/language-decisions.json) conserve ces entrées séparément. Un calcul de capo correct ne peut pas retrouver une convention de nommage éliminée avant son exécution.

La graphie enharmonique de sortie constitue un autre choix. Une forme de C avec un capo 3 donne la classe 3, que l'on peut nommer Eb ou D# dans ce calcul en tempérament égal. La compétence à la révision fixée choisit une préférence de graphie à partir de l'entrée ; la graphie d'un outil de transposition ne suffit pas nécessairement à établir comment cette compétence répondrait à chaque formulation en langue naturelle. Préservez le contexte musical lorsque la notation compte, au lieu de traiter l'égalité des classes comme une règle universelle de graphie.

### Exercice 4 : expliquer deux désaccords différents

Comparez C et C# après avoir interprété B selon les deux conventions déclarées avec un capo 2. Comparez ensuite Eb et D# pour une forme de C avec un capo 3. Ces désaccords sont-ils de même nature ?

> **Réponse:** Non. C et C# ont des classes différentes, 0 et 1, parce que le B de la source a été interprété différemment. Eb et D# partagent la classe 3 dans le calcul déclaré en tempérament égal, mais leurs graphies diffèrent. Les erreurs d'interprétation et les choix de graphie enharmonique exigent des explications différentes.

## 5. Composer les opérations après avoir déclaré leurs domaines

Supposons qu'une note écrite conçue pour le cours possède la coordonnée 64, une transposition explicite de l'instrument de -1 octave et un décalage de capo déclaré séparément de 2 demi-tons qui n'a pas encore été encodé. Le calcul est `64-12+2 = 54`. Il s'agit d'un jeu d'essai arithmétique délibérément composé ; il ne prétend pas qu'une partition réelle devrait toujours ajouter un décalage de capo séparé. Une partition ou une tablature peut déjà encoder ses hauteurs réelles. Examinez cette politique avant d'appliquer un autre ajustement.

[MCL-005](../../musicology/mcl-005-preserve-written-and-sounding-pitch/) montre comment un parseur peut éliminer les métadonnées de transposition. Une transmission utile entre agents précise la convention de nommage, si la cible est une forme ou une hauteur réelle, la qualité, la position du capo, le registre si nécessaire, les ajustements déjà appliqués et la portée des preuves. Il s'agit d'une liste de vérification proposée pour la tâche, et non d'un nouveau schéma imposé au dépôt.

### Exercice 5 : éviter de compter un décalage deux fois

Calculez le témoin composé déclaré à partir de 64, de -1 octave et d'un capo 2 pas encore appliqué. Si une valeur reçue est déjà la hauteur réelle finale 54, un agent doit-il ajouter encore 2 ? Indiquez la question qu'il doit d'abord résoudre.

> **Réponse:** Le témoin donne 54. Ajouter 2 à une hauteur réelle 54 déjà finale donnerait 56 et compterait le capo deux fois. Établissez si la hauteur reçue inclut déjà le capo et la transposition de l'instrument, et si la sortie demandée décrit une forme, une hauteur écrite ou le son réel.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/pitch-context-2026-10-22/learner-task.md) avec les preuves fixées et une calculatrice. Expliquez le sens du calcul, la qualité, le registre et la politique d'encodage avant de proposer une réponse destinée au musicien. Les essais instrumentaux réels, les réponses des apprenants et les décisions de revue humaine restent à recueillir.
