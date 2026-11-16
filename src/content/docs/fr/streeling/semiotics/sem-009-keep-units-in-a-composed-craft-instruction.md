---
title: Conserver les unités dans une instruction artisanale composée
description: Conserver les unités dans une instruction artisanale composée — Sémiotique
sidebar:
  label: SEM-009 · Conserver les unités dans une instruction artisanale composée
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/semiotics/fr/sem-009-keep-units-in-a-composed-craft-instruction.fr.md
---

:::note[Streeling University]
**SEM-009** · Conserver les unités dans une instruction artisanale composée · intermédiaire · 40 minutes

Généré par le département *Sémiotique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/semiotics/fr/sem-009-keep-units-in-a-composed-craft-instruction.fr.md) · [Mon journal](../../journal/)

Prérequis: [SEM-007](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/), [PHY-005](../../physics/phy-005-sheet-thickness-and-scene-units/)
:::

> Brouillon à soumettre à une relecture humaine. Les cas fixes ci-dessous sont des modèles mathématiques rédigés après lecture des sources ; ce ne sont pas de nouvelles mesures du projet. Les avis techniques, artisanaux, linguistiques et pédagogiques restent en attente. Aucun moteur de scène, échantillon physique, GPU, exécuteur de politique ni essai avec un apprenant n’a été utilisé pour cette leçon.

## Question du projet

Une instruction artisanale ajoute un décalage de feuille en millimètres à un placement BRUTAL en mètres. La syntaxe accepte des nombres, mais les instructions composées désignent-elles la même longueur ? Le prérequis distinguait les significations des angles. Ici, nous dressons un bilan dimensionnel : chaque opérande garde grandeur, unité et repère avant l’addition. C’est une note consultative, pas un analyseur ni un nouveau DSL.

[Prérequis: sem-007-preserve-the-meaning-of-a-bend-angle](../../semiotics/sem-007-preserve-the-meaning-of-a-bend-angle/); [Prérequis: phy-005-sheet-thickness-and-scene-units](../../physics/phy-005-sheet-thickness-and-scene-units/)

## Lire le périmètre avant de calculer

Lisez le prérequis et le document du projet avant de calculer. Distinguez les affirmations tirées du code inspecté, les résultats consignés antérieurement et les conséquences des seules hypothèses ci-dessous. Un commentaire de code, un corrigé préparé et une observation exécutée n’ont pas la même valeur probante. Conservez la date d’origine ainsi que tout contrôle échoué ou non concluant dans votre résumé d’un ancien document. La référence manuelle est un petit calcul sur papier accompagné d’un tableau des emplacements dans les sources ; un agent peut aider à trouver une définition, mais son résumé doit être confronté à celle-ci. Ce cas fini ne nécessite aucun nouveau langage ni automatisme.

L’addition exige des grandeurs représentées dans des unités compatibles et un même repère. Convertissez le déplacement physique avant d’ajouter sa représentation numérique. Un facteur sans dimension multiplie une longueur ; le produit de deux longueurs porte une unité d’aire et ne peut rester tacitement un déplacement. Des repères différents exigent aussi une correspondance, même si tous deux utilisent des mètres. La source définit axes et ordre des matrices sans déduire la règle externe de la feuille. Gardez celle-ci comme hypothèse et vérifiez par un aller-retour indépendant. Un décalage nul est un contrôle faible : il masque une conversion omise.

## Cas fixe et hypothèses

```text
base=0.20 m; offset=30 mm; mm_to_m=0.001 m/mm
offset_m=30*0.001=0.03 m
composed=0.20+0.03=0.23 m
wrong=0.20+30=30.20
roundtrip=0.23*1000=230 mm
scale=2; scaled_offset=2*0.03=0.06 m
control_offset=0 mm; control_composed=0.20 m
```

## Exercices corrigés

### Exercice 1

Composez correctement les deux longueurs.

> **Réponse:** Convertissez `30 mm` en `0.03 m`, puis additionnez pour obtenir `0.23 m`. Une addition numérique brute ne réalise pas la conversion.

### Exercice 2

Pourquoi l’addition brute échoue-t-elle comme instruction physique ?

> **Réponse:** Le nombre `30.20` mélange les représentations. L’étiqueter en mètres implique un décalage `1000` fois trop grand ; le libellé ne répare pas l’opération.

### Exercice 3

Vérifiez le résultat par le chemin en millimètres.

> **Réponse:** La base vaut `200 mm`, donc `200+30=230 mm`, en accord avec `0.23 m`. Les deux chemins partagent unités et repère déclarés.

### Exercice 4

Redimensionnez le décalage et examinez le contrôle nul.

> **Réponse:** Le décalage redimensionné vaut `0.06 m`. Avec un décalage nul, les deux additions peuvent donner `0.20` ; ce seul contrôle manquerait l’erreur d’unité.

### Exercice 5

Des libellés d’unité identiques suffisent-ils entre repères différents ?

> **Réponse:** Non. Un déplacement doit aussi avoir un repère et un sens déclarés. La convention en mètres ne fournit ni correspondance feuille-scène ni adaptateur exécuté.

## Tâche assistée par les sources

Lisez le repère figé et l’ancien calcul de composition. Annotez une instruction proposée avec grandeur, unité et repère à chaque frontière. Comparez la composition d’une aide à l’aller-retour manuel en millimètres. Un aller-retour non nul divergent réfute la préservation du sens par la syntaxe numérique.

Réalisez la tâche en masquant les corrigés. Gardez vos réponses initiales, les étapes de calcul, les emplacements dans les sources, les incertitudes et toutes les aides reçues, y compris un indice, un terme traduit ou une suggestion d’agent. Comparez ensuite avec les réponses préparées et consignez les corrections sans effacer votre premier essai. Rédigez une courte note de décision présentant l’affirmation, ses hypothèses, le calcul, le contrôle négatif et l’observation susceptible de la réfuter. Un résultat juste dépourvu d’unité ou d’identité de source ne suffit pas à démontrer le transfert. Le dossier comporte cinq critères préparés pour l’apprenant ; leur décision reste null tant qu’il n’existe pas d’essai réel et de relecture autorisée. La réussite de ces calculs établirait seulement une compétence sur le cas déclaré. Elle ne prouverait ni adaptateur opérationnel, ni procédé matériel réussi, ni moteur de rendu plus rapide, ni progrès d’apprentissage dans le projet. Comparez votre note assistée à la référence manuelle : si l’aide masque une hypothèse ou supprime un refus, corrigez la note avant de proposer un changement de méthode.

## Sources et journal de validation

- [Document du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json)
- [Source primaire](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Space.fs)
- [Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-c.json)
- [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
