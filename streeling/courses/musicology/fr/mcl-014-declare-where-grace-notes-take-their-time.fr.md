---
module_id: mcl-014-declare-where-grace-notes-take-their-time
department: musicology
course: "Déclarer où les petites notes prennent leur temps"
level: intermediate
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Déclarer où les petites notes prennent leur temps

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un ornement bref sur la page demande quand même une règle de lecture. Insérer sa durée sans dire d’où elle vient peut décaler toute la phrase ou raccourcir une note principale. Nous comparons deux allocations construites en secondes. L’objectif est de rendre la règle vérifiable avant l’ordonnancement, sans déduire une pratique d’exécution d’une barre oblique ou d’une petite tête de note.

## Lire les preuves conservées

Le dossier temporel conserve débuts et fins absolus d’une phrase construite, sans politique universelle d’ornement. L’élément grace MusicXML distingue l’ajout de temps et le prélèvement d’un pourcentage sur une note voisine. Ces attributs expriment des possibilités distinctes ; nos exemples en secondes sont explicatifs, pas une exécution ni une sérialisation directe. La carte de tempo du prérequis ne choisit pas entre elles.

[Prérequis](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/grace/)

### Exercice 1

Le groupe commence à `1 s`. La note principale écrite dure `0.5 s` et le budget d’ornement construit vaut `0.1 s` pour `2` petites notes. Une division égale donne `0.05 s` chacune. C’est un choix local, pas une affirmation sur l’articulation de tous les guitaristes.

Quelle durée revient à chaque petite note ?

<details><summary>Réponse 1</summary>

Chacune reçoit `0.05 s`, par partage explicitement égal de `0.1 s` entre `2` notes.

</details>

### Exercice 2

La politique principale est `steal_following`. Placer l’ornement au début et soustraire son budget de la note principale. Celle-ci commence à `1.1 s` et dure `0.4 s`. Début retardé et durée réduite sont deux conséquences voulues ; masquer l’un rendrait la chronologie difficile à examiner.

Donner début et durée de la note principale.

<details><summary>Réponse 2</summary>

Le début est `1.1 s` et la durée `0.4 s`. L’ornement consomme une partie du temps écrit de la note suivante.

</details>

### Exercice 3

La frontière suivante reste à `1.5 s`. Ornement et note principale totalisent `0.5 s`, l’emplacement écrit. La conservation concerne tout cet emplacement, pas la principale seule. Un contrôle doit préciser le support conservé : une principale raccourcie et une frontière inchangée peuvent être simultanément correctes.

Quelle durée est conservée dans le cas principal ?

<details><summary>Réponse 3</summary>

L’emplacement entier garde `0.5 s` et finit à `1.5 s`. La note principale est raccourcie ; affirmer la conservation de sa durée originale serait faux.

</details>

### Exercice 4

Le contrôle négatif passe à `add_time`. La principale commence toujours à `1.1 s`, mais garde `0.5 s`, déplaçant la frontière à `1.6 s`. Les hauteurs pourraient rester identiques. Vérifier seulement nombre d’ornements ou début de la principale manquerait donc le décalage ultérieur.

Quelle est la frontière suivante du contrôle, et pourquoi ?

<details><summary>Réponse 4</summary>

Elle vaut `1.6 s` : l’ornement de `0.1 s` s’ajoute à la principale de `0.5 s`. C’est une autre allocation, pas une erreur arithmétique de la politique principale.

</details>

### Exercice 5

Si la source ne fournit pas d’allocation exploitable, conserver l’ambiguïté plutôt qu’inventer une règle stylistique autoritaire. Un musicien peut choisir après examen du contexte. L’agent doit annoncer sa politique et conserver la notation pour permettre une autre interprétation. Une lecture apparemment fluide ne prouve pas la fidélité à une intention non formulée.

Qu’est-ce qui réfuterait la conservation de l’emplacement choisi ?

<details><summary>Réponse 5</summary>

Faire finir le cas principal à `1.6 s` plutôt qu’à `1.5 s` contredit sa règle. Une autre politique déclarée pourrait choisir légitimement la frontière tardive.

</details>

## Tâche avec consultation des sources

Dessiner les deux chronologies avec intervalles d’ornement, début principal et frontière suivante. Inspecter les bornes conservées et les attributs officiels. Rédiger un transfert nommant l’allocation et gardant le signe original. Définir un réfutateur de frontière avant toute règle d’ordonnancement ; laisser adéquation stylistique, lecture réelle et prestation de l’apprenant indécises.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
