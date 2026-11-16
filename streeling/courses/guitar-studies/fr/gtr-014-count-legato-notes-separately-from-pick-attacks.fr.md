---
module_id: gtr-014-count-legato-notes-separately-from-pick-attacks
department: guitar-studies
course: "Compter les notes en legato séparément des coups de médiator"
level: intermediate
prerequisites: ["gtr-010-separate-muting-from-releasing-a-fretted-note"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Compter les notes en legato séparément des coups de médiator

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Une phrase peut changer de hauteur sans nouveau coup de médiator. Compter chaque nouvelle hauteur comme une attaque au médiator prescrit parfois le mauvais geste, même avec une liste de notes correcte. Nous séparons événements musicaux et action d’excitation ou de prolongement. Ce registre aide GA à expliquer la phrase avant de prétendre qu’un moteur en reproduit l’articulation. Il prolonge la distinction relâchement/étouffement du prérequis vers les changements de hauteur.

## Lire les preuves conservées

Le dossier d’occupation des cordes suit les notes tenues et exclut explicitement bends et réarticulation. Cette limite empêche de déduire une articulation d’un tableau d’occupation valide. MusicXML réserve un élément technique aux paires de hammer-on, distinct d’une liaison large. Notre plan construit conserve les gestes explicitement, sans affirmer import MusicXML ni prise en charge par un moteur de production.

[Prérequis](../../guitar-studies/en/gtr-010-separate-muting-from-releasing-a-fretted-note.md)

[Artefact de projet conservé](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/hammer-on/)

### Exercice 1

Employer les événements ordonnés `pick:64`, `hammer:67`, `pull:64`, `pick:69`. Les numéros désignent les cibles sonores selon la convention discrète déclarée. Chaque ligne est un nouvel événement, y compris le retour à une hauteur antérieure. Compter les hauteurs uniques répondrait donc à une autre question en supprimant les récurrences.

Combien d’événements et quelle suite de hauteurs décrit le plan ?

<details><summary>Réponse 1</summary>

Il comporte `4` événements, de hauteurs `[64,67,64,69]`. Le second `64` reste un événement distinct.

</details>

### Exercice 2

Seules les lignes d’action `pick` comptent comme coups de médiator. Hammer et pull désignent ici des gestes distincts de main gauche. Ils peuvent apporter ou redistribuer de l’énergie ; l’absence de médiator ne signifie pas absence de transitoire. Le modèle compte des consignes, pas les pics d’un détecteur acoustique.

Combien de coups de médiator et de changements legato ?

<details><summary>Réponse 2</summary>

Il y a `2` coups de médiator et `2` changements legato. Cela ne prédit ni force des transitoires, ni volume égal, ni réussite d’exécution.

</details>

### Exercice 3

Un export réduit aux hauteurs garde `[64,67,64,69]` mais efface les gestes intermédiaires. Le destinataire ne peut pas retrouver l’articulation de façon unique. Ajouter un agent après cette projection ne récupère pas l’information sans autre source ; une suggestion plausible doit être marquée comme nouvelle proposition.

La suite de hauteurs reconstruit-elle le registre de gestes original ?

<details><summary>Réponse 3</summary>

Non. Plusieurs registres correspondent à `[64,67,64,69]`. Conserver le champ d’action et sa provenance si la tâche exige le motif d’attaque construit.

</details>

### Exercice 4

Le contrôle négatif remplace `hammer:67` par `pick:67`, sans changer les cibles. Il donne `3` coups de médiator et `1` changement legato, avec toujours `4` événements. Une comparaison limitée aux hauteurs traiterait les plans comme égaux et manquerait précisément la technique à conserver.

Quels comptes changent dans le contrôle ?

<details><summary>Réponse 4</summary>

Les coups passent à `3` et les changements legato à `1` ; les événements restent `4`, avec `[64,67,64,69]`. Des hauteurs identiques n’impliquent pas une articulation identique.

</details>

### Exercice 5

Une tâche réelle demande aussi cordes, instants des gestes, géométrie et tenue sonore. Le dossier d’occupation traite les conflits de cordes sous ses hypothèses ; notre registre traite le mécanisme d’attaque. Les combiner exige de vérifier identités et frontières d’événements, sans considérer l’un ou l’autre comme une interprétation complète et jouable.

Qu’est-ce qui réfuterait la conservation de la technique par un export ?

<details><summary>Réponse 5</summary>

Un export donnant le même registre d’actions ou le même nombre de coups aux cas principal et de contrôle perd la distinction requise. Aucune écoute n’est nécessaire pour détecter cette perte de représentation.

</details>

## Tâche avec consultation des sources

Écrire les deux registres à la main avant de lire les réponses. Les comparer aux exclusions du dossier d’occupation et à la définition technique MusicXML. Proposer un transfert conservant identité, hauteur et action sans inventer de prise en charge moteur. Indiquer comment rejeter un export qui garde les notes mais perd l’articulation. Laisser aisance, transitoires et prestation réelle non évalués.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
