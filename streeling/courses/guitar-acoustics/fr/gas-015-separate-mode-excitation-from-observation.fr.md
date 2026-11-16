---
module_id: gas-015-separate-mode-excitation-from-observation
department: guitar-acoustics
course: "Distinguer l’excitation d’un mode de son observation"
level: advanced
prerequisites: ["gas-006-relate-pluck-position-to-string-modes"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer l’excitation d’un mode de son observation

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une composante absente du spectre ne signifie pas forcément que le mode n’a pas été excité. Un observateur ponctuel placé sur un nœud ne voit pas son déplacement. Les explications de [GA](https://github.com/GuitarAlchemist/ga) doivent distinguer excitation, propagation et observation avant de diagnostiquer un modèle de guitare. Ici, les amplitudes modales restent fixes pendant que l’observateur se déplace.

## Lire les éléments conservés

La source sur les ondes stationnaires décrit nœuds et ventres. Comparez le calcul des amplitudes du prérequis à l’état de voix conservé. Aucun ne fournit une mesure étalonnée de capteur ponctuel. L’opérateur d’observation est une hypothèse pédagogique explicite.

[Prérequis](../../guitar-acoustics/en/gas-006-relate-pluck-position-to-string-modes.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.phys.unsw.edu.au/jw/strings.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "amplitudes": [
      1,
      0.5,
      0.25,
      0.125
    ],
    "modes": [
      1,
      2,
      3,
      4
    ],
    "position_fraction": 0.5
  },
  "formula": "observed_n=A_n*sin(n*pi*u)",
  "expected": {
    "observed": [
      1,
      0,
      -0.25,
      0
    ],
    "zero_modes": [
      2,
      4
    ]
  },
  "negative_control": {
    "values": {
      "amplitudes": [
        1,
        0.5,
        0.25,
        0.125
      ],
      "modes": [
        1,
        2,
        3,
        4
      ],
      "position_fraction": 0.25
    },
    "expected": {
      "observed": [
        0.7071067811865476,
        0.5,
        0.1767766952966369,
        0
      ],
      "zero_modes": [
        4
      ]
    }
  }
}
```

## Chercher à quelle étape disparaît la composante

Le coefficient d’excitation décrit l’état modal préparé, tandis que le poids d’observation décrit sa contribution à la sortie. Leur produit peut s’annuler si l’un ou l’autre facteur s’annule. Le produit seul n’identifie pas la cause du zéro. Cette factorisation aide lorsqu’un agent veut modifier le pincement après avoir repéré un creux spectral à la sortie.

Un point placé sur un nœud idéal est révélateur : son zéro ne dépend pas de l’amplitude modale. Augmenter l’excitation n’y rend pas le déplacement visible. Déplacer l’observateur peut aider, à condition de conserver sa position et la même excitation. Le témoin montre cette possibilité sans promettre une reconstruction complète : un mode invisible aux positions choisies exige encore une autre observation.

Les sorties réelles de guitare ajoutent généralement des transferts. Un capteur magnétique peut demander un modèle de vitesse, de champ et de largeur finie, tandis qu’un microphone observe la pression rayonnée après la caisse et la pièce. Notre observateur ponctuel de déplacement ne fournit aucun de ces mécanismes. Une expérience utile caractériserait le chemin d’observation avant d’attribuer un pic absent à la synthèse. La table modale directe est plus simple à interpréter qu’une règle compensatrice d’agent ajoutée sans cause identifiée.

### Exercice 1

Appliquez l’opérateur à la position principale. Quels modes deviennent invisibles ?

<details><summary>Réponse 1</summary>

La liste des modes nuls contient les modes pairs de cet exemple fini. Leurs coefficients d’excitation sont non nuls : cette observation ne prouve donc pas leur absence à l’excitation.

</details>

### Exercice 2

Interprétez le coefficient observé négatif. S’agit-il d’un volume négatif ?

<details><summary>Réponse 2</summary>

C’est un coefficient de déplacement signé par rapport à la phase modale déclarée. Le volume perçu n’est pas un déplacement signé et n’a pas été mesuré.

</details>

### Exercice 3

L’observation principale permet-elle de retrouver toutes les amplitudes d’origine ?

<details><summary>Réponse 3</summary>

Non. Un poids d’observation nul efface l’amplitude du mode. Plusieurs tableaux d’excitation produisent la même observation à ces indices.

</details>

### Exercice 4

Passez à la position témoin. Quel mode invisible devient observable ?

<details><summary>Réponse 4</summary>

Le second mode devient non nul, tandis que le quatrième reste invisible. L’excitation est inchangée ; le changement d’observation explique le nouveau coefficient.

</details>

### Exercice 5

Quel résultat réfute l’idée qu’un mode absent à l’observation est non excité ?

<details><summary>Réponse 5</summary>

Le cas principal donne déjà un coefficient d’excitation non nul et un déplacement observé nul. Un diagnostic réel exige un transfert d’observation connu et d’autres positions ou mesures.

</details>

## Travail avec consultation des sources

Dessinez les nœuds des modes sinusoïdaux et refaites les tableaux signés à la main. Proposez une autre position d’observation pour une expérience future. Précisez quel zéro empêche encore la reconstruction complète ; le transfert du capteur réel reste à établir avant de modifier le moteur.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
