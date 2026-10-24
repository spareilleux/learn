---
module_id: gas-014-predict-a-two-path-comb-with-distance
department: guitar-acoustics
course: "Prévoir un peigne à deux trajets à partir des distances"
level: intermediate
prerequisites: ["aud-009-declare-alignment-before-a-null-test"]
estimated_duration: "55 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Prévoir un peigne à deux trajets à partir des distances

> Exemple construit et lecture de sources. Aucune nouvelle prestation, exécution audio ou de parseur, réponse de participant ni adoption en production n’est revendiquée. Les décisions techniques humaines, linguistiques et pédagogiques restent en attente.

Un creux dans le spectre d’une guitare peut venir du mélange de copies retardées d’une même source. Il ne signifie pas nécessairement que la corde n’a pas produit cette fréquence. Dans une salle ou un modèle de réflexion, la différence de trajet fait varier la phase avec la fréquence. Nous prédisons un peigne construit avant d’attribuer un creux à l’instrument, puis montrons qu’une opposition bien située ne garantit pas une annulation totale mesurée.

## Lire les preuves conservées

Lire les réflexions précoces Rust conservées et leur conversion des secondes en indices d’échantillons. Ce sont des paramètres synthétiques, pas des distances de microphones mesurées. OpenStax explique l’addition d’ondes retardées et l’opposition de phase. Nous introduisons nos propres distances et vitesse. La décision d’alignement du prérequis reste utile, mais aligner automatiquement les trajets supprimerait ici l’effet de propagation étudié.

[Prérequis](../../audio-engineering/en/aud-009-declare-alignment-before-a-null-test.md)

[Artefact de projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier construit fixe](../../../../code/streeling/evidence/batch50-2026-10-24/unit-a.json)

[Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)

[Lecture primaire](https://openstax.org/books/university-physics-volume-1/pages/16-5-interference-of-waves)

### Exercice 1

Le premier trajet mesure `1 m`, le second `1.343 m`, et la vitesse supposée vaut `343 m/s`. La différence est `0.343 m`. La diviser par la vitesse donne `tau=(d_b-d_a)/c`, soit `0.001 s`. L’origine absolue de l’attaque est inutile pour cette différence si les signaux partagent excitation et horloge.

Quel retard relatif découle des distances ?

<details><summary>Réponse 1</summary>

Le retard relatif est `0.001 s`. Il décrit le temps de propagation supplémentaire, pas une latence absolue mesurée du microphone ou du moteur.

</details>

### Exercice 2

Quand la période vaut deux fois le retard, la copie retardée arrive avec un demi-cycle de décalage. La première opposition positive vaut `1/(2*tau)=500 Hz`. À gains égaux et signaux autrement identiques, la paire s’annule. Ce résultat dépend des deux trajets ; un enregistrement riche en réflexions ne présente pas nécessairement un zéro exact isolé.

Où se situe la première annulation prévue à gains égaux ?

<details><summary>Réponse 2</summary>

À `500 Hz`, avec une amplitude de `0` dans le modèle idéal. C’est une prédiction, pas une caractéristique observée d’un enregistrement.

</details>

### Exercice 3

La phase se répète lorsque la fréquence augmente de `1/tau=1000 Hz`. L’opposition suivante se situe donc à `1500 Hz`, après celle de `500 Hz`. Espacement et première opposition répondent à des questions distinctes. Ne pas confondre les deux ; les raies d’un spectre discret peuvent aussi manquer les fréquences prévues.

Donner l’espacement et l’opposition suivante.

<details><summary>Réponse 3</summary>

L’espacement est `1000 Hz` et l’opposition suivante `1500 Hz`. Pour comparer un minimum mesuré, il faut déclarer échantillonnage et fenêtrage de la grille spectrale.

</details>

### Exercice 4

Le contrôle négatif garde les trajets et fixe le gain du second à `0.5`. À l’opposition, l’amplitude vaut `abs(1-g)=0.5` plutôt que `0`. La géométrie prédit toujours `500 Hz`, mais le déséquilibre d’amplitude change la profondeur. La position du creux seule ne certifie ni appariement des microphones ni annulation parfaite.

Quelle prédiction subsiste et laquelle échoue ?

<details><summary>Réponse 4</summary>

L’opposition reste à `500 Hz`, avec espacement `1000 Hz`. L’annulation totale échoue : le résidu prévu vaut `0.5`. Opposition de phase et amplitude nulle sont des affirmations différentes.

</details>

### Exercice 5

Une revue doit conserver les voies avant sommation, distances supposées, gain et alignement éventuel. Si l’on étudie l’effet de salle, retirer le retard relatif change l’expérience. Si l’on compare des moteurs après compensation, il faut déclarer cette compensation. Un spectre lissé après traitement ne détermine pas à lui seul l’objectif correct.

Qu’est-ce qui réfuterait cette explication idéale à deux trajets ?

<details><summary>Réponse 5</summary>

Un transfert mesuré incompatible avec retard, périodicité ou résidu dépendant du gain au-delà de l’incertitude déclarée la réfuterait pour cette capture. Des trajets inconnus empêchent d’attribuer l’écart à la seule guitare.

</details>

## Tâche avec consultation des sources

Dessiner les trajets construits et calculer retard, première opposition, espacement et résidu à gains inégaux. Inspecter les taps synthétiques et expliquer pourquoi leurs secondes ne constituent pas un relevé de salle. Proposer une capture conservant les deux trajets et une mesure de transfert réfutante. Décider si l’alignement appartient à la question avant de suggérer un workflow audio ou une commande.

Conserver d’abord votre réponse avant de révéler les corrections préparées. Prendre le tableau ou calcul manuel comme référence pour toute calculatrice, consultation ou aide d’agent, et consigner cette aide. Garder réponse initiale et réponse corrigée séparément. Relier chaque exercice à un critère préparé du dossier ; aucune décision d’apprenant n’est encore prise. Noter un passage réellement lu et sa révision, puis distinguer ce qu’il établit de la prochaine étape proposée. Signaler toute entrée manquante comme non résolue. Une réponse mathématique juste soutient cet exemple ; revue humaine, exécution réelle et acceptation de l’apprenant demandent leurs propres observations conservées.
