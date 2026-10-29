---
title: Choisir une clé de diversité des voicings selon la tâche
description: Choisir une clé de diversité des voicings selon la tâche — Guitar Alchemist Academy
sidebar:
  label: GAA-013 · Choisir une clé de diversité des voicings selon la tâche
  order: 13
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-alchemist-academy/fr/gaa-013-choose-a-voicing-diversity-key-for-the-task.fr.md
---

:::note[Streeling University]
**GAA-013** · Choisir une clé de diversité des voicings selon la tâche · intermédiaire · 55 minutes

Généré par le département *Guitar Alchemist Academy* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-alchemist-academy/fr/gaa-013-choose-a-voicing-diversity-key-for-the-task.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAA-004](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Une réponse GA peut proposer plusieurs formes qu’un résumé appelle toutes des doublons. Les deux descriptions peuvent être justes selon la règle d’équivalence. Chercher d’autres registres ne demande pas le même aperçu que compter les familles de classes de hauteur. Nous explicitons la clé avant qu’un agent ne compresse les résultats. La leçon ajoute une décision de représentation au choix du prérequis, sans modifier embeddings, recherche ni schéma musical.

## Lire les preuves conservées

Lire les candidats du dossier de pratique : plusieurs formes ont la même famille mais des notes exactes et critères d’acceptation différents. Cette source fournit le problème du projet, pas les listes suivantes, qui sont construites. Aucune recherche en direct ne les a fournies ; le regroupement par classes de hauteur n’est pas présenté comme politique d’un service existant.

[Prérequis](../../guitar-alchemist-academy/gaa-004-choose-a-useful-voicing/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

### Exercice 1

Employer `[[48,52,55,60],[48,55,60,64],[52,55,60,64],[48,52,55,60]]`, des listes croissantes. Une clé de famille prend chaque valeur modulo `12`, supprime les doublons et trie. Elle efface volontairement registre, multiplicité et ordre de basse. Elle convient seulement à une tâche portant sur cette famille projetée.

Combien d’ensembles distincts de classes de hauteur ?

<details><summary>Réponse 1</summary>

Il y en a `1`, de clé `[0,4,7]`. Cela n’implique pas l’identité des notes, basses ou doigtés.

</details>

### Exercice 2

Une clé de voicing absolu garde toute la liste ordonnée. Le dernier candidat répète exactement le premier ; les candidats intermédiaires diffèrent. Il reste donc `3` voicings. Un agent doit nommer sa clé avec le nombre, puisque les mêmes données autorisent plusieurs comptes selon l’objectif.

Combien de voicings absolus distincts restent-ils ?

<details><summary>Réponse 2</summary>

Il en reste `3`. Seule la répétition exacte début/fin disparaît ; registre et multiplicité appartiennent toujours à cette clé.

</details>

### Exercice 3

La clé de basse prend la note la plus grave modulo `12`. Les premier, deuxième et dernier candidats ont la classe `0`, le troisième la classe `4`. Il y a donc `2` classes de basse malgré une seule famille. Une tâche sur les renversements peut conserver cela sans prétendre évaluer doigté ou continuité des voix.

Que conserve la clé de basse que perd la famille ?

<details><summary>Réponse 3</summary>

Elle distingue les basses `0` et `4`, soit `2` classes. L’ensemble `[0,4,7]` ne dit pas quel membre est le plus grave.

</details>

### Exercice 4

Le contrôle négatif remplace le troisième candidat par `[52,55,60,65]`, de famille `[0,4,5,7]`. Il y a maintenant `2` familles, mais toujours `3` voicings et `2` classes de basse. Vérifier uniquement les comptes inchangés manquerait le changement musical ; conserver les clés elles-mêmes.

Quel résultat de diversité change ?

<details><summary>Réponse 4</summary>

Les familles passent à `2`, soit `[[0,4,7],[0,4,5,7]]`. Les voicings restent `3` et les basses `2`. Une coordonnée modifiée affecte différemment les clés.

</details>

### Exercice 5

Pour pratiquer, on peut chercher un renversement, une position proche ou un autre timbre. Un compte abstrait de familles ne fournit rien de tout cela seul. Garder les candidats consultables après résumé et expliquer la perte liée à la clé. Une méthode future peut alors être évaluée contre ce calcul manuel avant adoption d’une abstraction.

Qu’est-ce qui réfuterait un résumé censé conserver la diversité de registre ?

<details><summary>Réponse 5</summary>

Réduire tous les candidats principaux à un seul enregistrement sans distinctions de voicing perd le registre demandé. Un compte de familles correct ne sauve pas cette affirmation plus forte.

</details>

## Tâche avec consultation des sources

Calculer les trois clés pour chaque candidat, puis pour le contrôle. Inspecter les formes conservées et comparer acceptation exacte et par famille. Rédiger une réponse GA pour un guitariste cherchant d’autres basses, avec clé et limites. Définir un réfutateur de projection avant toute politique de dédoublonnage ; laisser jouabilité, classement réel et préférence non observés.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
