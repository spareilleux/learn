---
module_id: gtr-015-sample-a-vibrato-without-erasing-its-motion
department: guitar-studies
course: "Échantillonner un vibrato sans effacer son mouvement"
level: advanced
prerequisites: ["gtr-013-judge-a-bend-with-an-uncertainty-budget"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Échantillonner un vibrato sans effacer son mouvement

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une courbe de hauteur apparemment plate peut masquer un mouvement entre les échantillons. Pour expliquer un exercice [GA](https://github.com/GuitarAlchemist/ga), distinguez vitesse du vibrato, amplitude en cents et grille d’observation avant de juger une tenue de note. Nous construisons une trajectoire continue et examinons des instants choisis. Ses extrema et ses valeurs échantillonnées répondent à des questions différentes.

## Lire les éléments conservés

La référence de notation prévoit des paramètres de lecture des ornements pour les lignes ondulées. Ces champs ne définissent pas notre sinusoïde en cents. Le relevé d’intonation conservé apporte une convention fréquentielle, sans performance de vibrato.

[Prérequis](../../guitar-studies/en/gtr-013-judge-a-bend-with-an-uncertainty-budget.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/wavy-line/)

[Lecture principale](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "base_hz": 440,
    "extent_cents": 25,
    "rate_hz": 2,
    "times_s": [
      0,
      0.125,
      0.25,
      0.375,
      0.5
    ]
  },
  "formula": "c(t)=extent*sin(2*pi*rate*t); f(t)=base*2^(c(t)/1200)",
  "expected": {
    "cents": [
      0,
      25,
      0,
      -25,
      0
    ],
    "period_s": 0.5,
    "peak_to_peak_cents": 50
  },
  "negative_control": {
    "values": {
      "base_hz": 440,
      "extent_cents": 25,
      "rate_hz": 4,
      "times_s": [
        0,
        0.125,
        0.25,
        0.375,
        0.5
      ]
    },
    "expected": {
      "cents": [
        0,
        0,
        0,
        0,
        0
      ],
      "period_s": 0.25,
      "peak_to_peak_cents": 50
    }
  }
}
```

## Définir le geste avant d’évaluer sa trace échantillonnée

La vitesse décrit les répétitions dans le temps ; l’amplitude décrit l’écart autour de la référence. L’interprète peut modifier chaque grandeur indépendamment. La trajectoire choisie est symétrique en cents : les fréquences extrêmes ont donc des rapports réciproques à la porteuse. Une courbe symétrique en hertz décrirait un autre geste. Précisez le repère avant d’interpréter hauteur moyenne ou excursion maximale.

Les instants d’échantillonnage observent la trajectoire sans la définir complètement. Le témoin rapide ne peut notamment pas être reconstruit avec ses seuls échantillons : une hauteur continue fixe conviendrait aussi. Connaître l’intervalle d’échantillonnage n’identifie pas la courbe réellement produite sans hypothèse supplémentaire de bande passante ou de modèle. Une qualification assurée du mouvement dépasserait les preuves données.

Pour un outil futur, conservez séparément estimations horodatées brutes, incertitudes et geste voulu. Une ligne lisse dessinée entre points espacés est une proposition d’interpolation, pas une mesure intermédiaire. Le dessin direct doit rendre ce manque visible avant qu’un DSL ajoute une consigne ou qu’un agent l’évalue. Une trace plus dense pourrait tester le mouvement, mais le suivi réel devrait aussi distinguer variation de hauteur, changement de partiel dominant et erreur d’octave.

### Exercice 1

Distinguez l’amplitude et l’excursion crête à crête de la trajectoire principale.

<details><summary>Réponse 1</summary>

L’amplitude en cents mesure un seul côté de l’oscillation. L’excursion crête à crête en vaut le double, comme indiqué ; aucune n’est une mesure de jeu réel.

</details>

### Exercice 2

Évaluez la trajectoire aux instants déclarés et trouvez sa période.

<details><summary>Réponse 2</summary>

Le vecteur indiqué passe par les extrema positif et négatif. La période est l’inverse de la vitesse et ne dépend pas de la fréquence porteuse.

</details>

### Exercice 3

Comment convertir la courbe en cents en courbe de fréquence ?

<details><summary>Réponse 3</summary>

Appliquez la relation exponentielle affichée. Ajouter une valeur fixe en hertz ne conserverait pas une excursion symétrique en cents autour de la référence.

</details>

### Exercice 4

Appliquez le témoin plus rapide. Son vecteur nul prouve-t-il l’absence de vibrato ?

<details><summary>Réponse 4</summary>

Non. La grille tombe sur les passages par zéro, alors que l’amplitude continue reste inchangée. Le témoin réfute concrètement cette déduction à partir des seuls échantillons.

</details>

### Exercice 5

Qu’est-ce qui réfute l’idée que cette grille identifie l’amplitude du vibrato ?

<details><summary>Réponse 5</summary>

Des amplitudes ou vitesses continues différentes compatibles avec le même vecteur empêchent l’identification. Conservez les instants, la phase supposée et une observation indépendante plus dense avant toute évaluation du jeu.

</details>

## Travail avec consultation des sources

Dessinez les courbes continues et leurs instants d’échantillonnage avant d’utiliser une calculatrice. Expliquez le mouvement masqué du témoin et proposez un relevé pour un outil futur. Comparez votre tracé manuel aux propositions de notation ou d’agent, sans prétendre avoir analysé un enregistrement.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
