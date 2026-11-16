---
module_id: mcl-013-keep-tuplet-duration-as-a-rational
department: musicology
course: "Conserver la durée du tuplet sous forme rationnelle"
level: intermediate
prerequisites: ["mcl-006-preserve-meter-grouping-and-tempo-units"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver la durée du tuplet sous forme rationnelle

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un exercice peut avoir le bon nombre de notes écrites et finir au mauvais moment si le rapport du tuplet est inversé. Le groupement métrique ne résout pas ce rapport, et un crochet ne contient pas forcément tous les champs de durée. Nous construisons une chronologie rationnelle avant conversion en secondes. La leçon ajoute la durée locale des notes aux unités du prérequis et fournit une référence manuelle pour un futur transfert.

## Lire les preuves conservées

Lire les temps absolus du dossier conservé : ils sont explicites, pas déduits d’un signe décoratif. L’élément time-modification MusicXML distingue nombres actual et normal et leur effet sonore cumulé. Les notations imbriquées demandent davantage d’informations. Notre exemple se limite à un groupe non pointé, non imbriqué, sans prétendre implémenter un importeur ou exporteur complet.

[Prérequis](../../musicology/en/mcl-006-preserve-meter-grouping-and-tempo-units.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/time-modification/)

### Exercice 1

Fixer `480` ticks par noire et une durée de base de `1/2` noire. La note non modifiée dure donc `240` ticks. Séparer type de base et modificateur évite de considérer une croche comme durée sonore finale dans tout contexte. L’unité est la noire, pas un mot temps non défini.

Quelle est la durée de base en ticks ?

<details><summary>Réponse 1</summary>

Elle vaut `240` ticks selon `480*(1/2)`. C’est la durée avant application du rapport déclaré.

</details>

### Exercice 2

Employer actual `3` et normal `2` : les notes écrites occupent le temps du nombre normal. La durée par note est `Q*(base_num/base_den)*(normal/actual)`, soit `160` ticks. Le rapport multiplie le temps ; inverser les champs allongerait les notes au lieu de faire tenir le groupe dans l’étendue voulue.

Quelle durée reçoit chaque note modifiée ?

<details><summary>Réponse 2</summary>

Chaque note reçoit `160` ticks. Le multiplicateur temporel est `2/3`, appliqué aux `240` ticks non modifiés.

</details>

### Exercice 3

Les `3` notes totalisent `480` ticks, soit `1` noire. Les débuts relatifs sont `[0,160,320]` ticks et la fin `480`. Le calcul exact montre la fermeture. À une autre résolution, un rationnel peut ne pas être entier ; arrondir chaque note séparément déplacerait parfois la fin et demande une politique distincte.

Donner les débuts et la fin du groupe.

<details><summary>Réponse 3</summary>

Les débuts sont `[0,160,320]` ticks et la fin `480`. Ce groupe remplit exactement `1` noire à la résolution déclarée.

</details>

### Exercice 4

Le contrôle négatif échange actual et normal, en gardant `3` notes et la durée de base. Chaque note dure alors `360` ticks ; le groupe totalise `1080` ticks, soit `2.25` noires. Un contrôle du seul nombre écrit accepterait cette autre interprétation malgré sa fin très différente.

Que produit le contrôle aux champs inversés ?

<details><summary>Réponse 4</summary>

Il donne `360` ticks par note et `1080` au total, soit `2.25` noires. Les champs du rapport sont des entrées sémantiques, pas des annotations interchangeables.

</details>

### Exercice 5

Une carte de tempo convertira ensuite ces coordonnées en secondes, sans réparer un mauvais tuplet. Conserver unité de base, comptes actual/normal, points éventuels et support exact avant projection en ticks entiers. Un agent pourra comparer le résultat à cette référence rationnelle sans prendre le crochet imprimé pour preuve de fidélité.

Qu’est-ce qui réfuterait la conservation de cette durée ?

<details><summary>Réponse 5</summary>

Une fin différente de `480` ticks dans le cas principal contredit le modèle. Les `1080` ticks du contrôle constituent un témoin d’échec s’ils sont présentés comme résultat principal.

</details>

## Tâche avec consultation des sources

Construire à la main les chronologies principale et inversée avec des fractions, puis inspecter les temps conservés et la définition officielle. Proposer un transfert gardant base de durée et deux comptes plutôt qu’une simple légende. Définir un réfutateur de fin et le besoin éventuel d’arrondi. Laisser import réel, exécution musicale et acceptation de l’apprenant en attente.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
