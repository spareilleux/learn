---
module_id: wml-015-carry-the-concert-reference-through-a-frequency-handoff
department: world-music-languages
course: "Conserver le diapason de référence lors d’un transfert de fréquences"
level: advanced
prerequisites: ["wml-004-preserve-intonation-beyond-pitch-classes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Conserver le diapason de référence lors d’un transfert de fréquences

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Des outils peuvent s’accorder sur tous les intervalles d’une phrase et diverger sur ses fréquences absolues. L’omission du diapason de référence peut l’expliquer. Pour un transfert [GA](https://github.com/GuitarAlchemist/ga), nous modifions l’étalonnage sans changer les numéros de notes ni les intervalles. Cette opération diffère d’une transposition : les identités écrites restent fixes et la référence change.

## Lire les éléments conservés

La source principale décrit la référence conventionnelle et la relation des cents. Notre autre référence est construite, sans affirmation sur un ensemble musical réel. Le relevé conserve les références et rappelle qu’accepter une fréquence ne prouve pas sa réalisation acoustique.

[Prérequis](../../world-music-languages/en/wml-004-preserve-intonation-beyond-pitch-classes.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/intonation-listening-2026-10-22/intonation.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.nist.gov/pml/time-and-frequency-division/popular-links/time-frequency-z)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "reference_a_hz": 442,
    "comparison_a_hz": 440,
    "midi_notes": [
      69,
      81
    ]
  },
  "formula": "f(n)=reference*2^((n-69)/12); calibration_ratio=reference/comparison; calibration_cents=1200*log2(calibration_ratio); octave_ratio=f(81)/f(69)",
  "expected": {
    "frequencies_hz": [
      442,
      884
    ],
    "calibration_ratio": 1.0045454545454546,
    "calibration_cents": 7.851415040126504,
    "octave_ratio": 2
  },
  "negative_control": {
    "values": {
      "reference_a_hz": 440,
      "comparison_a_hz": 440,
      "midi_notes": [
        69,
        81
      ]
    },
    "expected": {
      "frequencies_hz": [
        440,
        880
      ],
      "calibration_ratio": 1,
      "calibration_cents": 0,
      "octave_ratio": 2
    }
  }
}
```

## Séparer étalonnage et identité de note

La référence associe une coordonnée de note à une fréquence physique. Modifier cette correspondance conserve la coordonnée écrite. La transposition change au contraire cette coordonnée selon une transformation musicale déclarée. Ces opérations peuvent produire des déplacements fréquentiels proches sur une note, tout en préservant des sens différents dans un transfert. Un son plus aigu ne suffit pas à identifier l’opération.

Dans ce modèle, le rapport entre notes élimine la référence commune. Une phrase peut donc garder tous ses intervalles et échouer à un contrôle absolu. Cela explique aussi la faiblesse de l’octave comme test d’étalonnage. Une comparaison utile doit inclure une cible fréquentielle absolue avec référence et unités, puis distinguer valeur demandée et valeur réellement estimée.

L’autre étalonnage est une donnée pédagogique, sans recommandation pour un ensemble musical. Instruments, contextes et pratiques peuvent choisir d’autres références ou ajustements non uniformes. Un transfert futur pourrait combiner diapason et rapports par degré ; aucun ne doit remplacer l’autre sans déclaration. La table directe rend cette séparation visible avant une nouvelle abstraction d’accordage. Si un relevé perd sa référence, signalez l’entrée manquante au lieu de la deviner d’après un nom familier ou d’annoncer une correction par transposition automatique.

### Exercice 1

Convertissez la liste principale en fréquences avec sa référence déclarée.

<details><summary>Réponse 1</summary>

Les fréquences attendues figurent ci-dessus. Les numéros de notes ne les déterminent pas seuls si le récepteur ignore la référence de conversion.

</details>

### Exercice 2

Calculez le rapport d’étalonnage et l’écart en cents par rapport à la référence de comparaison.

<details><summary>Réponse 2</summary>

Ils s’appliquent identiquement à chaque note dans ce modèle. Un décalage additif en hertz ne conserverait pas le même écart en cents entre registres.

</details>

### Exercice 3

Vérifiez le rapport d’octave. Détecte-t-il une référence oubliée ?

<details><summary>Réponse 3</summary>

L’octave reste exacte dans les cas principal et témoin. Un contrôle des seuls intervalles ne détecte donc pas cet écart de fréquence absolue.

</details>

### Exercice 4

Appliquez le témoin utilisant la référence de comparaison. Quel écart disparaît ?

<details><summary>Réponse 4</summary>

L’écart d’étalonnage devient nul et les fréquences absolues changent. Les identités écrites et le rapport d’octave restent inchangés.

</details>

### Exercice 5

Qu’est-ce qui réfute un récepteur annonçant conserver l’étalonnage original ?

<details><summary>Réponse 5</summary>

Reconstruire les fréquences témoins à partir de l’entrée principale avec référence réfute sa conservation. Même une demande fidèle exige une mesure de sortie avant de valider le moteur.

</details>

## Travail avec consultation des sources

Calculez les tables à la main, puis suivez le champ de référence conservé. Proposez un relevé distinguant identité écrite, étalonnage et fréquence voulue. Formulez le critère absolu de réfutation avant qu’un agent recommande accordage ou transposition.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
