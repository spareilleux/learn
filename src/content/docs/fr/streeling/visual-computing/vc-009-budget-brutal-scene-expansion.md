---
title: Budgéter l'expansion des scènes BRUTAL avant le rendu
description: Budgéter l'expansion des scènes BRUTAL avant le rendu — Informatique visuelle
sidebar:
  label: VC-009 · Budgéter l'expansion des scènes BRUTAL avant le rendu
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-009-budget-brutal-scene-expansion.fr.md
---

:::note[Streeling University]
**VC-009** · Budgéter l'expansion des scènes BRUTAL avant le rendu · intermédiaire · 35 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-009-budget-brutal-scene-expansion.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-008](../../visual-computing/vc-008-save-and-query-a-weave-scene/), [CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/)
:::

> **Périmètre du brouillon.** Nouveaux résultats de génération de scènes et de refus sur CPU à partir du code source public. La revue technique humaine, la relecture linguistique par une personne maîtrisant la langue, les essais par des apprenants et la vérification du HTML public du cours restent à faire. Aucune fenêtre graphique, aucun GPU, moteur de rendu ou flux n'a été lancé.

## La question du projet

Un agent compose une scène récursive pour l'[évaluation BRUTAL](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/README.md). Comment le système peut-il refuser une expansion excessive avant de créer les ressources de rendu ? Une petite description peut générer beaucoup de boîtes. Borner la croissance de la description constitue une tâche concrète de préparation graphique, même si cela ne prédit pas le temps de calcul d'une image.

[CS-014](../../computer-science/cs-014-compose-brutal-scene-descriptions/) présente les blocs Lego typés. Cette leçon examine leurs [limites et problèmes](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Model.fs#L133-L195), les [garde-fous de génération](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Generate.fs) et la [frontière de validation](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Lego/Validate.fs). Toutes les observations du code utilisent le commit GA public `76efbffd5af82b46c3146957a6bd4504008eeb89`.

## 1. Compter la représentation qui se développe réellement

Les limites standard du code source sont une profondeur maximale de 8, un maximum de 4096 instances de blocs et un maximum de 20000 boîtes. Elles contraignent des éléments différents. Un bloc peut émettre plusieurs boîtes sans ajouter une autre instance de bloc ; l'imbrication peut dépasser la limite de profondeur tout en conservant peu de géométrie au total.

Les [descriptions réellement produites sur CPU](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-descriptions.json) montrent une colonnade à quatre colonnes contenant cinq instances et 53 boîtes. Sélectionner explicitement la seconde version de ses colonnes conserve cinq instances mais porte le nombre de boîtes à 85. Un budget fondé uniquement sur les instances manquerait cette augmentation de géométrie.

### Exercice 1 : choisir le compteur pertinent

Comparez les deux colonnades. Qu'est-ce qui change, qu'est-ce qui reste fixe et pourquoi le nombre d'instances seul ne suffit-il pas à budgéter les boîtes ?

> **Réponse:** Le nombre d'instances reste de cinq : la racine et quatre colonnes. Les boîtes passent de 53 à 85, soit une différence de 32, car la version de colonne sélectionnée émet davantage de géométrie. Un compteur d'instances suit les nœuds d'expansion ; sans règle supplémentaire, il ne borne pas la géométrie par nœud. Conservez les deux compteurs.

## 2. Convertir en un coût géométrique déclaré

Le code source décrit chaque boîte comme 12 triangles. Dans cette représentation, 53 boîtes correspondent à 636 triangles et 85 à 1020 ; la différence est de 384. La limite standard de 20000 boîtes correspond à un budget de 240000 triangles de boîtes.

Ces nombres portent sur la représentation. Ils n'établissent ni le nombre d'appels de dessin, ni le nombre de sommets uniques, ni la mémoire GPU, ni le surdessin, ni le coût du lancer de rayons, ni le temps de calcul d'une image. Une application hôte peut instancier la géométrie, ajouter d'autres objets ou utiliser d'autres passes. Précisez la quantité contrôlée par un budget avant d'en faire une affirmation sur les performances du produit.

### Exercice 2 : calculer le budget

Avec 12 triangles par boîte, calculez les coûts des deux colonnades, leur différence et le budget standard de triangles de boîtes. Ces nombres permettent-ils d'établir le nombre d'images par seconde de la scène ?

> **Réponse:** Les coûts sont `53*12 = 636` et `85*12 = 1020` ; l'augmentation est de `32*12 = 384`. Le budget standard est de `20000*12 = 240000` triangles dans la représentation de boîtes déclarée. Le nombre d'images par seconde nécessite une charge de rendu mesurée, une application hôte et une méthode de chronométrage ; ces nombres seuls ne les fournissent pas.

## 3. Comprendre où intervient le refus

Le [compte rendu d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/cpu-execution.json) consigne 20 tests Release existants réussis. Des requêtes CLI sélectionnées ont aussi été exécutées séparément. Le sanctuaire de niveau 2 a été accepté avec 756 instances et 8505 boîtes, correspondant à 102060 triangles de boîtes. Le niveau 3 a renvoyé le code de sortie 2 et `lego-errors/1` avec un problème `too-many-boxes`. La sortie refusée ne contient pas le décompte d'une scène complète acceptée.

La génération incrémente son compteur de boîtes avant de vérifier si la limite a été franchie. Le garde-fou permet donc au compteur d'atteindre 20001 avec la limite standard, tout en conservant au plus 20000 boîtes placées. Ce sont des bornes supérieures déduites du code source, sans affirmer que la scène complète de niveau 3 visée contient 20001 boîtes. Le test existant vérifie que l'arrêt reste borné ; la validation refuse le brouillon partiel lorsqu'il comporte des problèmes.

### Exercice 3 : distinguer le nombre de tentatives d'une scène

Pourquoi un compteur peut-il dépasser d'une unité la limite de boîtes sans approuver une scène trop volumineuse ? Qu'établissent le résultat accepté de niveau 2 et le résultat refusé de niveau 3 ?

> **Réponse:** L'implémentation compte une tentative de boîte, détecte que le compteur dépasse 20000, consigne le problème et cesse de conserver de la géométrie supplémentaire. Le compteur peut donc atteindre 20001 tandis que les boîtes conservées restent au plus 20000. Le niveau 2 a produit une description acceptée de 8505 boîtes et 756 instances. Le niveau 3 a été refusé ; son erreur ne constitue ni la taille d'une scène complète ni un résultat de rendu.

## 4. Rendre visible la convention de profondeur

La racine a une profondeur de 0. Une profondeur maximale de 1 autorise la racine et ses enfants immédiats, puis refuse toute expansion plus profonde. La requête de temple enregistrée avec cette limite a renvoyé `too-deep` ; une requête distincte limitée à 10 instances a renvoyé `too-many-instances`. La suite de tests vérifie également qu'une profondeur de 2 suffit pour le temple testé.

Une limite de profondeur de 8 signifie donc huit étapes d'imbrication sous la racine, plutôt que huit nœuds racine comprise sur chaque chemin. Conservez cette convention dans une transmission à un autre agent ou une interface. Renommer un champ « niveaux » sans définir son origine peut créer un décalage d'une unité entre producteur et consommateur.

### Exercice 4 : lire un refus de profondeur

Une profondeur maximale de 1 autorise-t-elle un petit-enfant à la profondeur 2 ? Pourquoi un agent doit-il conserver la distinction entre `too-deep` et `too-many-instances`, même si les deux interrompent le même temple demandé ?

> **Réponse:** Non. Avec la racine à la profondeur 0, un enfant immédiat à la profondeur 1 est autorisé, mais un petit-enfant à la profondeur 2 dépasse la limite. Les deux problèmes désignent des contraintes différentes. Augmenter le nombre d'instances autorisées ne peut pas à lui seul corriger un refus de profondeur, et augmenter la profondeur ne garantit pas que le budget d'instances sera respecté. Modifiez une exigence explicite et relancez sa vérification.

## 5. Associer la validation à une étape distincte de vérification du rendu

Les [commentaires publics du point d'entrée de Colossus](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Experiments/Brutal/Colossus/Program.cs#L37-L41) décrivent la génération et la validation avant la création de la fenêtre. Le code source témoigne ainsi de l'intégration prévue. Ce cours a exécuté la CLI pure, sans exécuter cette application graphique. Une description acceptée est prête pour l'étape suivante ; elle n'a pas réussi un test GPU ou de coexistence.

[PM-005](../../product-management/pm-005-interpret-brutal-coexistence-experiments/) explique pourquoi une fréquence d'images historique élevée dans un processus ne suffit pas à approuver son exécution à côté de l'Observatory. Transmettez le code source, la graine, les versions, les arguments, les limites, le format, le code de sortie et l'empreinte de la description à l'expérience suivante au lieu de substituer un seul compteur à tous ces faits.

### Exercice 5 : rédiger la transmission

Un agent annonce « 8505 boîtes, donc affichage rapide et sûr à côté de [Godot](https://docs.godotengine.org/en/stable/) ». Remplacez cette affirmation par un résultat étayé et la prochaine étape de vérification.

> **Réponse:** La CLI publique fixée à la révision indiquée, exécutée uniquement sur CPU, a accepté le sanctuaire de niveau 2 avec 8505 boîtes et 756 instances sous les limites consignées. Conservez sa requête, le format de sortie, le code de sortie 0 et l'empreinte. La vitesse de rendu, la libération des ressources et la coexistence avec la tâche Godot voisine nécessitent une expérience mesurée distincte dans l'application hôte. La description acceptée ne fournit aucun résultat GPU observé.

## Limites des preuves

Le [relevé des calculs](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/brutal-composition-2026-10-22/composition-calculations.json) distingue les descriptions réelles, l'arithmétique et les bornes déduites des garde-fous. Ces vérifications finies ne prouvent ni que tous les blocs possibles se terminent, ni que tous les paramètres sont sûrs, ni que toutes les applications hôtes respectent les limites, ni qu'un apprenant peut transférer la méthode. Seuls le code source public et les résultats sur CPU dans le périmètre défini étayent ce brouillon.
