---
title: Préserver l’orientation du repère tangent après une symétrie
description: Préserver l’orientation du repère tangent après une symétrie — Informatique visuelle
sidebar:
  label: VC-011 · Préserver l’orientation du repère tangent après une symétrie
  order: 11
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-011-preserve-tangent-handedness-after-a-mirror.fr.md
---

:::note[Streeling University]
**VC-011** · Préserver l’orientation du repère tangent après une symétrie · intermédiaire · 40 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-011-preserve-tangent-handedness-after-a-mirror.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-008](../../physics/phy-008-keep-surface-normals-perpendicular/), [VC-010](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Un agent applique une symétrie à un panneau et conserve correctement sa normale. Une texture dans le repère tangent décrit-elle nécessairement le même relief ? La normale seule ne fixe pas le sens du second axe tangent. La question concerne un futur transfert de Blender vers Godot, qui n’a pas été exécuté. Le prérequis définit l’interprétation des canaux ; cette leçon reconstruit la base locale qui donne un sens à leurs valeurs.

[Prérequis: phy-008-keep-surface-normals-perpendicular](../../physics/phy-008-keep-surface-normals-perpendicular/); [Prérequis: vc-010-preserve-packed-texture-channel-contracts](../../visual-computing/vc-010-preserve-packed-texture-channel-contracts/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

La spécification glTF reconstruit la bitangente à partir de la normale, de la tangente et de la composante signée. Notre symétrie conserve les coordonnées de texture liées aux mêmes points matériels et réfléchit la base physique. Comparez la bitangente réfléchie souhaitée à celle reconstruite avec l’ancien signe. Leur désaccord révèle une erreur de base même si la normale reste perpendiculaire. Ce cas aligné sur les axes isole l’orientation ; une échelle non uniforme et l’orthogonalisation demanderaient d’autres contrôles. Le signe tangent ne prescrit ni inversion de toute la texture compacte ni modification des indices des triangles : ces opérations relèvent d’autres contrats.

## Cas fixe et hypothèses

```text
N=(0,0,1); T=(1,0,0); w=+1
B=w*(N cross T)=(0,1,0)
M=diag(-1,1,1); det(M)=-1
N2=(0,0,1); T2=(-1,0,0); desired_B2=(0,1,0)
old_w_B2=(0,-1,0); corrected_w=-1
sample=(0,0.6,0.8); desired_world=(0,0.6,0.8)
wrong_world=(0,-0.6,0.8); dot=0.28
```

## Exercices corrigés

### Exercice 1

Reconstruisez la bitangente initiale.

> **Réponse:** Le produit vectoriel donne `(0,1,0)` et la multiplication par `+1` ne le change pas. La normale seule n’encode pas ce signe.

### Exercice 2

Conservez l’ancien signe après la symétrie. Quel contrôle échoue ?

> **Réponse:** La bitangente reconstruite est `(0,-1,0)`, opposée à la bitangente matérielle réfléchie `(0,1,0)`. Le contrôle de perpendicularité ne détecte pas cette erreur.

### Exercice 3

Quel signe répare cette base construite ?

> **Réponse:** Le signe `-1` reconstruit `(0,1,0)`. Cela suppose la correspondance matérielle des UV conservée et la convention déclarée de transformation.

### Exercice 4

Utilisez l’échantillon asymétrique. La mauvaise direction mondiale est-elle identique ?

> **Réponse:** Non. La composante Y change de signe et les directions unitaires ont un produit scalaire de `0.28`. Un échantillon `(0,0,1)` masquerait l’erreur : c’est un contrôle peu discriminant.

### Exercice 5

Cela établit-il un défaut visuel de matériau dans le projet ?

> **Réponse:** Non. C’est un contre-exemple portant sur la base. La génération des UV, le dépaquetage des canaux, la convention du moteur et un import contrôlé restent à tester.

## Tâche assistée par les sources

Lisez la comparaison de normales et la définition tangente glTF, puis annotez la base réfléchie d’un transfert proposé. Gardez le tableau manuel des produits vectoriels et les hypothèses UV. Une bitangente reconstruite opposée à celle souhaitée réfute la préservation annoncée.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/scene-frames-2026-10-22/normal-comparison.json)
- [Source primaire](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#meshes)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
