---
title: Distinguer la disponibilité des nœuds d'un DAG de leur admission à l'exécution
description: Distinguer la disponibilité des nœuds d'un DAG de leur admission à l'exécution — Science des réseaux
sidebar:
  label: NET-007 · Distinguer la disponibilité des nœuds d'un DAG de leur admission à l'exécution
  order: 7
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-007-separate-dag-readiness-from-admission.fr.md
---

:::note[Streeling University]
**NET-007** · Distinguer la disponibilité des nœuds d'un DAG de leur admission à l'exécution · intermédiaire · 35 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-007-separate-dag-readiness-from-admission.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-005](../../network-science/net-005-fanout-results-and-dependency-joins/)
:::

> **Portée du brouillon.** Cinq fichiers publics d'IX à une révision précise, trois réponses réelles de l'outil de topologie, trois réponses de l'outil d'exécution dans un cadre limité et des ordonnancements conçus pour le cours. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun ordonnanceur de production, aucune limite de workers, aucun mécanisme de nouvelle tentative ni aucune modification de l'éditeur n'ont été implémentés ; la concurrence réelle des workers n'a pas été mesurée.

## La question du projet

Un éditeur de pipelines IX affiche huit nœuds indépendants. Un agent peut-il lancer huit workers parce que tous les nœuds sont prêts ? Un graphe de dépendances indique quelles entrées précèdent un calcul. L'admission à l'exécution exige aussi de connaître la capacité et la politique applicable. [NET-005](../../network-science/net-005-fanout-results-and-dependency-joins/) examinait les jointures et la conservation des résultats des branches ; nous examinons ici l'écart entre la structure du graphe et les ressources d'exécution.

L'[implémentation publique du DAG d'IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs) rejette les cycles et calcule des ordres et des niveaux topologiques. Toutes les observations du code source de ce cours utilisent la révision `456df065ee837e33b5bbe22a4df0616a4fcb76e5`. La révision du service ayant produit les réponses réelles des outils est inconnue ; ces réponses constituent des preuves distinctes.

## 1. Un niveau décrit la disponibilité au regard des dépendances

Les [essais réels de topologie](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/topology-tool-probes.json) comprennent un losange avec les arcs de a vers b, de a vers c, de b vers d et de c vers d. Ses ensembles de niveau sont a, puis b et c, puis d. L'outil indique quatre nœuds, quatre arcs et un parallélisme maximal de 2. Ce champ décrit ici le plus grand niveau renvoyé, et non une mesure des workers en cours d'exécution.

Une seconde entrée comporte huit nœuds sans aucun arc. Elle indique un seul niveau contenant les huit nœuds et un parallélisme maximal de 8. Une entrée cyclique à deux nœuds renvoie une erreur. Le rejet des cycles protège la structure acyclique du graphe ; il ne choisit pas combien de nœuds prêts doivent s'exécuter simultanément.

### Exercice 1 : interpréter la largeur indiquée

Donnez les ensembles de niveau du losange et la largeur indiquée. Si la machine ne dispose que d'un emplacement de worker, les dépendances deviennent-elles cycliques ou invalides ?

> **Réponse:** Les niveaux sont a, puis b et c, puis d ; la largeur indiquée est 2. Un seul emplacement de worker ne rend pas le graphe cyclique. Il modifie l'ordonnancement possible : b et c peuvent s'exécuter successivement tout en respectant chaque dépendance.

## 2. Ajouter explicitement une contrainte de ressources

Le [modèle d'ordonnancement conçu pour le cours](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/admission-model.json) suppose huit tâches indépendantes durant chacune un pas de temps, deux workers, aucun surcoût et aucune préemption. Quatre vagues de deux tâches se terminent en 4 pas de temps, avec au plus 2 tâches actives. Le nombre de tâches prêtes reste initialement de 8, même si seules 2 peuvent être admises.

Pour le losange, supposons des durées de a=1, b=4, c=2 et d=1 pas de temps. Deux workers peuvent exécuter a de 0 à 1, b de 1 à 5, c de 1 à 3 et d de 5 à 6. Le chemin a-b-d prend 6 pas de temps ; un seul worker exige 8 pas de temps pour les quatre tâches. Il s'agit d'ordonnancements construits avec des coûts déclarés, et non de durées mesurées dans IX. La topologie seule ne fournissait pas ces coûts.

### Exercice 2 : calculer un ordonnancement tenant compte de la capacité

Combien de vagues les huit tâches unitaires exigent-elles avec deux emplacements ? Pour le losange pondéré, donnez le temps d'achèvement avec deux workers et le total avec un seul. Une largeur topologique de 2 implique-t-elle une accélération de 2 ?

> **Réponse:** Les huit tâches exigent quatre vagues et 4 pas de temps. Le losange se termine en 6 pas de temps avec l'ordonnancement donné à deux workers, contre 8 avec un seul. L'accélération est `8/6`, et non 2 : le chemin de dépendances et les durées inégales limitent le gain.

## 3. Lire le flux de contrôle plutôt que se fier à une étiquette de parallélisme

Le [moteur d'exécution ix-agent](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450) à la révision fixée parcourt l'ordre topologique et appelle un outil par itération. Un autre [exécuteur ix-pipeline](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/executor.rs#L115-L243) annonce des threads parallèles dans ses commentaires, mais sa branche multinœud examinée appelle directement compute dans un map d'itérateur suivi d'une collecte. Elle ne crée pas de threads à cet endroit. La [référence des itérateurs Rust](https://doc.rust-lang.org/std/iter/trait.Iterator.html#method.map) décrit map comme une transformation d'itérateur ; cette expression synchrone de map suivie d'une collecte n'assure pas à elle seule un ordonnancement parallèle.

La description initiale du code suivait trop facilement les commentaires. Le [journal de production du cours](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/production-plan.md) conserve cette correction. La description du code de ces deux parcours ne prouve pas une concurrence mesurée dans le service déployé. De même, l'absence d'un champ de limite de workers ne prouve pas que ce code lance un nombre illimité de threads.

### Exercice 3 : contester la déduction

Un tableau de bord indique « niveau parallèle » et un commentaire du code mentionne « threads std ». Une personne chargée de la revue conclut que huit threads ont été lancés. Quelle observation supplémentaire du code contredit cette déduction, et quelles preuves d'exécution permettraient de mesurer la concurrence réelle ?

> **Réponse:** La branche examinée appelle compute de façon synchrone dans un map suivi d'une collecte et ne contient aucune création de thread à cet endroit. Les étiquettes ne prouvent pas que huit threads s'exécutent. Une exécution instrumentée, avec des observations de début et de fin des tentatives ainsi que les identités des contextes d'exécution, permettrait de mesurer les chevauchements ; aucune mesure de concurrence de ce type n'a été réalisée pour ce cours.

## 4. Distinguer les ordres partiels d'un ordre total choisi

Les [essais réels d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) soumettent deux fois le même petit pipeline statistique à trois étapes. Tous deux placent first avant second et third. Le premier indique first, second, third ; la répétition indique first, third, second. Les résultats numériques sont égaux. Les deux ordres respectent les dépendances déclarées.

Le code du DAG à la révision fixée stabilise explicitement son ordre par la position d'insertion. Les différents ordres réels des étapes sœurs ne peuvent donc pas servir d'attestation d'exécution de ce code exact. Conservez les deux observations et le fait que la révision du service est inconnue. Ne triez pas silencieusement les comptes rendus bruts et ne présentez pas cette paire comme une preuve d'ordre déterministe.

### Exercice 4 : identifier l'invariant préservé

Les deux ordres observés ne diffèrent que par second et third. Quel invariant de dépendance est conservé ? L'égalité des résultats numériques ou les deux ordres peuvent-ils prouver que le serveur exécute la révision fixée à ordre déterministe ?

> **Réponse:** First précède les deux étapes qui en dépendent dans chaque ordre. L'égalité des résultats numériques n'établit pas l'identité de l'implémentation, et le changement d'ordre n'atteste pas le code à ordre déterministe de la révision fixée. La révision réelle du serveur reste inconnue.

## 5. Donner à un éditeur des états qu'il peut justifier

Un vocabulaire proposé pour l'éditeur distingue prêt au regard des dépendances, admis, en cours d'exécution et terminé. Ce sont des propositions de conception propres à la tâche, et non des états installés dans IX. Un nœud prêt attend une décision de capacité ; un nœud admis dispose d'un emplacement ; l'état en cours exige un début de tentative observé ; l'achèvement exige une observation terminale. L'échec, les dépendances bloquées et les observations manquantes doivent avoir des significations propres, au lieu d'être affichés comme un même état inactif générique.

Dans l'essai volontairement défaillant, un outil absent produit une erreur sans agrégat final par étape. La réponse n'énumère pas le travail effectué en amont et ne donne pas les états des étapes ignorées en aval. Préservez cette limite au lieu de fabriquer une chronologie complète dans l'éditeur. [CYB-006](../../cybernetics/cyb-006-bound-retry-feedback-and-workload/) examine la charge supplémentaire créée lorsque des observations manquantes déclenchent de nouvelles tentatives.

### Exercice 5 : délimiter une vérification d'admission proposée

Huit nœuds ont satisfait leurs dépendances, mais seuls deux emplacements sont disponibles. Selon le vocabulaire proposé, peut-on marquer les huit comme en cours d'exécution ? Indiquez les observations nécessaires pour marquer un nœud donné comme en cours puis terminé.

> **Réponse:** Non. Au plus deux sont admis sous la contrainte de capacité déclarée, et l'admission ne prouve toujours pas un démarrage. L'état en cours exige un début de tentative observé ; l'état terminé exige son résultat terminal. Les autres nœuds prêts conservent leur statut au regard des dépendances en attendant la capacité. Il s'agit d'un contrat proposé, et non d'un compte rendu du comportement installé dans l'éditeur.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) avant de lire sa grille d'évaluation. Reconstituez les niveaux, les ordonnancements et les limites des preuves, puis proposez le plus petit affichage utile de l'admission. Aucun résultat indépendant d'apprenant ni de revue humaine n'a encore été consigné.
