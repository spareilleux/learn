---
module_id: mcl-012-merge-ties-without-merging-slurs
department: musicology
course: "Fusionner les tenues sans fusionner les liaisons de phrasé"
level: intermediate
prerequisites: ["mcl-007-integrate-a-midi-tempo-map-before-scheduling"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Fusionner les tenues sans fusionner les liaisons de phrasé

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Une partition peut montrer deux têtes pour un son tenu, ou une courbe sur plusieurs sons distincts. Un import GA qui transforme chaque courbe en fusion peut garder les hauteurs écrites tout en changeant la phrase. Nous calculons cette distinction sur quelques événements. La reconstruction temporelle s’enrichit de l’identité sonore avant de choisir ordonnancement audio ou technique. Notre attaque signifie début sonore symbolique, pas coup de médiator.

## Lire les preuves conservées

Lire les identités stables et les instantanés de notes tenues du dossier temporel. Ils distinguent déjà tenue et redéclenchement à chaque instantané. MusicXML associe l’élément tie au son et tied à la notation. Ce passage établit une distinction, pas la validité d’un importeur. Le cas suivant est construit pour une seule voix ; aucun import ni jeu GA n’est revendiqué.

[Prérequis](../../musicology/en/mcl-007-integrate-a-midi-tempo-map-before-scheduling.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/music-phrase-2026-10-22/timed-events.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/tie/)

### Exercice 1

Les lignes écrites sont hauteur `60` au temps `0` pendant `1` temps, hauteur `60` au temps `1` pendant `1` temps, puis `62` au temps `2` pendant `1` temps. La première paire porte explicitement une tenue. Intervalles contigus et hauteurs égales autorisent sa fusion selon la règle construite, en conservant son début.

Quel événement sonore remplace la paire ?

<details><summary>Réponse 1</summary>

Hauteur `60`, début `0`, durée `2` temps. La seconde tête n’ajoute pas d’attaque symbolique selon la règle déclarée.

</details>

### Exercice 2

La dernière hauteur devient `62` : elle reste donc un événement du temps `2` au temps `3`. La liste contient `2` événements sur `3` temps. Une somme de durées ne dit pas si une note répétée est attaquée ou tenue ; relation et identités doivent donc survivre à la projection.

Donner les totaux d’événements sonores et de durée couverte.

<details><summary>Réponse 2</summary>

Il y a `2` événements, de durées `[2,1]` temps, couvrant `3` temps. Cette étendue seule ne détermine pas le nombre d’attaques.

</details>

### Exercice 3

L’égalité des hauteurs ne suffit pas. Un silence, une autre voix ou l’absence de tenue changeraient les prémisses. Les formats réels demandent aussi des règles de paires début/fin, passages répétés et notation malformée. La leçon ne les implémente pas. Une revue doit annoncer ce cas simple plutôt qu’une conformité générale.

Peut-on fusionner automatiquement des hauteurs égales adjacentes ?

<details><summary>Réponse 3</summary>

Non. La tenue et les conditions d’identité et de temps doivent être conservées. L’égalité seule n’établit pas une continuité sonore ; le modèle reste limité à sa voix contiguë déclarée.

</details>

### Exercice 4

Le contrôle négatif remplace la relation par `slur`, sans changer hauteurs ni durées. Notre règle n’autorise aucune fusion sonore. Il y a alors `3` événements symboliques, sur toujours `3` temps. Une liaison de phrasé ou d’articulation ne transforme pas leurs frontières en tenue.

Que change le contrôle malgré des totaux temporels égaux ?

<details><summary>Réponse 4</summary>

Le compte passe à `3`, avec durées `[1,1,1]` temps. L’étendue inchangée de `3` temps ne certifie pas l’identité des tenues.

</details>

### Exercice 5

Une guitare peut réaliser des notes legato séparées sans coups de médiator séparés ; une tenue demande normalement une continuité. Le compte symbolique ne permet pas d’inférer ce geste physique. Distinguer relation notée, identité sonore et action souhaitée, puis exiger une trace de rendu avant d’affirmer leur conservation audio.

Qu’est-ce qui réfuterait un import distinguant tenue et phrasé ?

<details><summary>Réponse 5</summary>

Une même liste fusionnée pour les cas principal et de contrôle perdrait la distinction. Une durée totale correcte ne rétablit pas la frontière manquante.

</details>

## Tâche avec consultation des sources

Dessiner lignes écrites et intervalles sonores pour chaque relation. Les comparer aux instantanés conservés et à la distinction son/notation MusicXML. Proposer une table minimale avec relation, voix, hauteur et bornes. Définir le témoin de sortie rejetant la fusion indue, en laissant import réel, réalisation audio et prestation d’apprenant en attente.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
