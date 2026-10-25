---
module_id: gtr-019-declare-the-coordinate-of-a-continuous-slide
department: guitar-studies
course: "Déclarer la coordonnée d’un glissé continu"
level: advanced
prerequisites: ["gtr-014-count-legato-notes-separately-from-pick-attacks"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Déclarer la coordonnée d’un glissé continu

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un transfert de phrase GA conserve les extrémités d’un glissé et suppose que le trajet est déterminé. La coordonnée interpolée compte pourtant. Nous comparons une variation uniforme de longueur vibrante et une variation uniforme de fréquence logarithmique. Les extrémités et la durée coïncident, mais la hauteur intermédiaire diffère. L’opération prolonge le relevé d’articulations vers une trajectoire continue, sans créer de moteur de glissé.

Pour une corde idéale souple à vitesse d’onde constante, la fréquence est inversement proportionnelle à la longueur vibrante. Une droite en longueur produit donc une courbe en fréquence. Une hauteur logarithmique uniforme donne une interpolation géométrique de fréquence. Aucun chemin n’est le comportement universel d’un glissé ; une guitare frettée ordinaire peut introduire des transitions de contact exclues ici.

La source de notation décrit le glissé comme continu et prévoit des attributs de discrétisation. Elle ne choisit pas notre coordonnée physique et ne certifie pas sa conservation par un analyseur. Le point intérieur distingue les politiques, contrairement aux seules extrémités. Un agent qui ne conserve que celles-ci a besoin d’une convention de trajet supplémentaire. Gardez unités, coordonnée et contact dans le relevé proposé. Une table directe vérifie la fidélité d’une abstraction. Mouvement réel, contact, suivi de hauteur et avis du musicien exigent d’autres observations.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-studies/en/gtr-014-count-legato-notes-separately-from-pick-attacks.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/phrase-performance-2026-10-22/string-occupancy.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

[Lecture primaire](https://www.w3.org/2021/06/musicxml40/musicxml-reference/elements/slide/)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "start_length": 1,
    "end_length": 0.5,
    "start_frequency_hz": 100,
    "duration_s": 1,
    "times_s": [
      0,
      0.5,
      1
    ],
    "policy": "linear_length"
  },
  "formula": "u=t/duration; linear_length: L=(1-u)*L0+u*L1; f=f0*L0/L; linear_log_frequency: f=f0*(L0/L1)^u; L=f0*L0/f",
  "expected": {
    "length": [
      1,
      0.75,
      0.5
    ],
    "frequency_hz": [
      100,
      133.33333333333334,
      200
    ]
  },
  "negative_control": {
    "values": {
      "start_length": 1,
      "end_length": 0.5,
      "start_frequency_hz": 100,
      "duration_s": 1,
      "times_s": [
        0,
        0.5,
        1
      ],
      "policy": "linear_log_frequency"
    },
    "expected": {
      "length": [
        1,
        0.7071067811865475,
        0.5
      ],
      "frequency_hz": [
        100,
        141.4213562373095,
        200
      ]
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez une vitesse d’onde constante et une longueur idéale continûment variable. Les interruptions par frettes sont absentes. Les chemins sont construits ; aucun ne prédit un glissé fretté ordinaire ni un mouvement mesuré.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Dérivez la longueur au temps intérieur pour le mouvement linéaire.

<details><summary>Réponse 1</summary>

C’est l’interpolation arithmétique des longueurs extrêmes, indiquée dans le cas fixe.

</details>

### Exercice 2

Convertissez cette longueur en fréquence à vitesse d’onde constante.

<details><summary>Réponse 2</summary>

Utilisez la relation inverse ; le milieu arithmétique des longueurs n’est pas celui des fréquences.

</details>

### Exercice 3

Comment le témoin interpole-t-il la hauteur ?

<details><summary>Réponse 3</summary>

Il interpole la fréquence logarithmique, donnant un milieu géométrique et une autre longueur vibrante.

</details>

### Exercice 4

Des extrémités communes prouvent-elles un même glissé ?

<details><summary>Réponse 4</summary>

Non. Les valeurs intérieures diffèrent malgré les extrémités et la durée identiques.

</details>

### Exercice 5

Qu’est-ce qui réfute la fidélité des seules extrémités ?

<details><summary>Réponse 5</summary>

Un destinataire incapable de distinguer ces trajectoires ne peut retrouver le chemin demandé.

</details>

## Travail avec consultation des sources

Dessinez les chemins avant les réponses. Rédigez une note GA nommant la coordonnée interpolée et excluant la prédiction ordinaire du contact sur les frettes.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
