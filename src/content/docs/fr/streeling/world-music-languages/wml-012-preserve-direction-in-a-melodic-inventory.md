---
title: Conserver la direction dans un inventaire mélodique
description: Conserver la direction dans un inventaire mélodique — Musiques et langues du monde
sidebar:
  label: WML-012 · Conserver la direction dans un inventaire mélodique
  order: 12
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/world-music-languages/fr/wml-012-preserve-direction-in-a-melodic-inventory.fr.md
---

:::note[Streeling University]
**WML-012** · Conserver la direction dans un inventaire mélodique · intermédiaire · 55 minutes

Généré par le département *Musiques et langues du monde* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/world-music-languages/fr/wml-012-preserve-direction-in-a-melodic-inventory.fr.md) · [Mon journal](../../journal/)

Prérequis: [WML-007](../../world-music-languages/wml-007-resolve-scale-degrees-against-tonic-and-mode/)
:::

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un ensemble de classes peut dire quelles notes apparaissent quelque part sans dire lesquelles sont permises dans une direction. Remplacer deux inventaires par leur union peut faire accepter une phrase que le modèle original exclut. Nous construisons cette perte pour une future explication GA ou proposition de grammaire. Les nombres sont pédagogiques et inventés : ils ne décrivent aucune tradition nommée ni pratique d’interprétation réelle.

## Lire les preuves conservées

Lire les observations de catalogue et les fréquences construites séparées du dossier d’intonation. Le résumé de classes est une représentation sélectionnée, pas une grammaire complète. Le prérequis résout un degré dans une forme déclarée. Nous ajoutons la direction et étudions une règle finie précise, sans supposer que deux ensembles décrivent toutes les mélodies traditionnelles.

[Prérequis](../../world-music-languages/wml-007-resolve-scale-degrees-against-tonic-and-mode/)

[Artefact de projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier construit fixe](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-24/journal.md)

### Exercice 1

L’inventaire montant est `[0,2,4,7,9]`, le descendant `[0,2,3,7,9]`, dans un registre déclaré. Leur union vaut `[0,2,3,4,7,9]`, sans champ indiquant où `3` ou `4` étaient permis. Garder la provenance empêche de transformer cette opposition construite en affirmation ethnomusicologique mal attribuée.

Quelle information l’union efface-t-elle ?

<details><summary>Réponse 1</summary>

Elle efface que `4` appartient seulement au montant et `3` seulement au descendant. Elle garde une présence quelque part, pas l’autorisation selon la direction.

</details>

### Exercice 2

Employer `[0,4,7,4,0]`. Pour chaque paire, comparer arrivée et départ afin de choisir la direction, puis tester l’arrivée dans l’inventaire correspondant. Les deux premiers mouvements montent et sont permis. Cette règle ne limite pas les sauts et n’exige pas des degrés voisins ; elle est plus étroite qu’une grammaire complète.

Quelles sont les deux premières décisions ?

<details><summary>Réponse 2</summary>

Elles sont `[true,true]` : les arrivées `4` et `7` appartiennent au montant. Cela ne juge ni adéquation stylistique ni exécution physique.

</details>

### Exercice 3

De `7` à `4`, le mouvement descend, mais `4` n’appartient pas au descendant. L’arrivée finale `0` est permise. Le vecteur est donc `[true,true,false,true]` et la phrase est rejetée. La première position fautive constitue un témoin examinable sans moteur musical.

Pourquoi la règle originale rejette-t-elle la phrase ?

<details><summary>Réponse 3</summary>

La descente vers `4` échoue. Le vecteur `[true,true,false,true]` montre que toutes les étapes requises ne sont pas permises.

</details>

### Exercice 4

Le contrôle négatif remplace les deux inventaires par l’union `[0,2,3,4,7,9]`. La même phrase donne alors `[true,true,true,true]` et est acceptée. L’union reste identique dans les deux descriptions ; un test limité à cette projection ne distingue donc pas la règle originale de son remplacement avec perte.

Que démontre ce contrôle sur l’union prise comme règle complète ?

<details><summary>Réponse 4</summary>

Une phrase est acceptée après projection mais rejetée avant. Des unions égales n’établissent pas des règles directionnelles équivalentes.

</details>

### Exercice 5

Une description réelle pourrait aussi dépendre du registre, des phrases caractéristiques, du contexte, de l’intonation et de l’autorité des sources. Notre règle omet ces dimensions. Un futur DSL doit d’abord reproduire le témoin manuel et garder les inconnues, sans ériger les ensembles en modèle normatif. Accepter des données ne prouve pas leur validité musicale.

Qu’est-ce qui réfuterait la conservation de cette règle par un transfert ?

<details><summary>Réponse 5</summary>

Accepter la phrase principale sur la seule union en prétendant conserver les inventaires contredit le témoin. Toute interprétation culturelle plus large demande sources appropriées et revue musicale.

</details>

## Tâche avec consultation des sources

Construire à la main le tableau de direction et d’appartenance, puis le contrôle par union. Inspecter la limite du catalogue conservé et préciser ses questions résolubles. Proposer un enregistrement directionnel consultatif avec le mouvement rejeté comme réfutateur d’un transfert avec perte. Garder la provenance inventée explicite et ne pas attribuer cette table à une tradition réelle.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
