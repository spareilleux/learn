---
title: Vérifier le couple lors du déplacement d’un pivot de scène
description: Vérifier le couple lors du déplacement d’un pivot de scène — Physique
sidebar:
  label: PHY-013 · Vérifier le couple lors du déplacement d’un pivot de scène
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-013-check-torque-when-moving-a-scene-pivot.fr.md
---

:::note[Streeling University]
**PHY-013** · Vérifier le couple lors du déplacement d’un pivot de scène · intermédiaire · 40 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-013-check-torque-when-moving-a-scene-pivot.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un futur visualiseur de créations IX déplace l’origine d’un objet sans déplacer le panneau visible. Le moment de la charge reste-t-il identique ? Une modification de coordonnées peut préserver la géométrie tout en changeant le point de calcul du couple. Le repère BRUTAL figé emploie des mètres ; il ne fournit ni masse, ni force appliquée, ni charnière physique. Ce sont ici des hypothèses explicites.

[Prérequis: phy-005-sheet-thickness-and-scene-units](../../physics/phy-005-sheet-thickness-and-scene-units/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

La définition d’OpenStax prend le produit vectoriel du déplacement entre l’origine choisie et le point d’application avec la force. Dans ce cas plan construit, calculez la composante signée perpendiculaire à la page. Déplacez l’origine de calcul sans déplacer la force. Cela diffère d’une translation de toute la configuration physique, où les deux points se déplacent ensemble et où leur différence reste identique. Un nom de pivot ne suffit donc pas pour un échange mécanique : indiquez sa position et précisez s’il s’agit d’une origine de modélisation ou d’un appui réel. Le dossier d’orientation motive ces repères explicites, mais ne contient aucun essai de force.

## Cas fixe et hypothèses

```text
P=(0.30,0,0) m; O=(0,0,0) m; O2=(0.10,0,0) m
F=(0,-20,0) N
r=P-O; tau=r cross F
tau_z=-6 N*m; tau2_z=-4 N*m
P3=(0.40,0,0) m; O3=(0.10,0,0) m; tau3_z=-6 N*m
```

## Exercices corrigés

### Exercice 1

Calculez le moment initial et son signe.

> **Réponse:** Le bras est `0.30 m` ; le moment vaut `-6 N*m`. Le signe dépend des axes déclarés et de l’ordre du produit vectoriel.

### Exercice 2

Gardez le panneau fixe et utilisez la seconde origine. Que change-t-il ?

> **Réponse:** Le bras devient `0.20 m` et le moment `-4 N*m`. La force reste identique ; le point de référence a changé.

### Exercice 3

Translatez les deux points selon le contrôle. Le couple change-t-il ?

> **Réponse:** Non : `0.40-0.10=0.30 m`, donc `-6 N*m`. Une translation commune conserve le bras relatif.

### Exercice 4

Placez l’origine au point d’application. La force disparaît-elle ?

> **Réponse:** Le bras et le moment valent `0`, mais la force reste dirigée vers le bas avec une intensité de `20 N`. Un moment nul autour de ce point ne signifie pas une charge nulle.

### Exercice 5

Ce calcul peut-il certifier une charnière ?

> **Réponse:** Non. Il donne un moment autour de points déclarés. Les réactions d’appui, la résistance du matériau et le mouvement manquent ; aucune capacité de charge n’a été mesurée.

## Tâche assistée par les sources

À partir du dossier et de la définition figée du repère BRUTAL, préparez un échange distinguant panneau fixe et assemblage translaté. Recalculez le modèle avec l’origine au point d’application. Les moments inégaux ci-dessus réfutent l’affirmation selon laquelle toutes les origines donnent le même moment.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/orientation-controls.json)
- [Source primaire](https://openstax.org/books/university-physics-volume-1/pages/10-6-torque)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
