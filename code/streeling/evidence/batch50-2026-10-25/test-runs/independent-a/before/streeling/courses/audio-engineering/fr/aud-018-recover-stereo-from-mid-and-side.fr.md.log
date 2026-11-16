---
module_id: aud-018-recover-stereo-from-mid-and-side
department: audio-engineering
course: "Reconstruire la stéréo à partir des composantes centrale et latérale"
level: advanced
prerequisites: ["aud-010-preserve-channels-before-downmixing"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Reconstruire la stéréo à partir des composantes centrale et latérale

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Une référence de guitare stéréo peut changer de représentation sans perdre d’information si les composantes transformées sont conservées. Leur somme seule efface leur différence, même si l’export recrée ensuite un fichier stéréo. Nous construisons une transformation inversible, puis supprimons sa composante latérale. Le besoin de stockage et le coût énergétique deviennent ainsi explicites avant de proposer un réglage de largeur.

## Lire les éléments conservés

Le prérequis montre la perte due au mélange mono. Le script conservé déclare une sortie WAV mono : il ne démontre donc pas cette opération stéréo. La matrice ci-dessous est une extension construite pour une proposition de revue, sans nouveau support d’exécution.

[Prérequis](../../audio-engineering/en/aud-010-preserve-channels-before-downmixing.md)

[Artefact du projet conservé](../../../../code/streeling/guitar-runtime/run.mjs)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "left": [
      1,
      0
    ],
    "right": [
      0,
      1
    ],
    "side_gain": 1
  },
  "formula": "M=(L+R)/sqrt(2); S=(L-R)/sqrt(2); L_out=(M+g*S)/sqrt(2); R_out=(M-g*S)/sqrt(2); E=sum(L_out^2+R_out^2)",
  "expected": {
    "mid": [
      0.7071067811865476,
      0.7071067811865476
    ],
    "side": [
      0.7071067811865476,
      -0.7071067811865476
    ],
    "left_out": [
      1,
      0
    ],
    "right_out": [
      0,
      1
    ],
    "input_energy": 2,
    "output_energy": 2
  },
  "negative_control": {
    "values": {
      "left": [
        1,
        0
      ],
      "right": [
        0,
        1
      ],
      "side_gain": 0
    },
    "expected": {
      "mid": [
        0.7071067811865476,
        0.7071067811865476
      ],
      "side": [
        0.7071067811865476,
        -0.7071067811865476
      ],
      "left_out": [
        0.5,
        0.5
      ],
      "right_out": [
        0.5,
        0.5
      ],
      "input_energy": 2,
      "output_energy": 1
    }
  }
}
```

## Conserver les coordonnées tant que la question exige la réversibilité

La transformation change de coordonnées dans le plan des canaux. Elle n’identifie pas à elle seule une source physique au centre ou sur les côtés d’une pièce. Ces noms désignent les directions somme et différence, avec un ordre de canaux déclaré. Échanger gauche et droite conserve la coordonnée centrale et inverse la coordonnée latérale ; même un relevé numériquement réversible exige donc cette orientation.

Une transformation orthonormale conserve la somme des carrés des coordonnées à chaque instant, puis sur tout l’enregistrement fini. Cette propriété algébrique dépasse le seul contrôle de crête, sans justifier une conclusion perceptive. La crête d’un canal transformé peut différer de celles des canaux d’origine. Limitation, quantification ou changement de gain demanderaient un bilan supplémentaire avant de promettre la reconstruction exacte.

Le témoin sans composante latérale illustre une projection et non un changement de coordonnées réversible. Copier la moyenne dans des canaux ne restitue pas la coordonnée manquante. Plusieurs paires initiales partagent cette moyenne. Conservez les tableaux si des comparaisons ultérieures portent sur la pièce ou les échantillons stéréo d’origine. Une table matricielle directe suffit à décider du stockage ; un traitement proposé doit justifier sa complexité en explicitant ordre des canaux, normalisation et traitement latéral dans le relevé sauvegardé.

### Exercice 1

Formez les tableaux central et latéral. Pourquoi préciser la normalisation ?

<details><summary>Réponse 1</summary>

Les tableaux figurent ci-dessous. La normalisation par la racine carrée rend cette matrice orthonormale ; une autre convention demanderait d’autres formules d’inversion et d’énergie.

</details>

### Exercice 2

Inversez le cas principal et comparez chaque échantillon aux canaux d’origine.

<details><summary>Réponse 2</summary>

L’inversion retrouve les tableaux d’origine. Conserver les composantes centrale et latérale préserve la différence qu’une moyenne mono ne permet pas de reconstruire.

</details>

### Exercice 3

Vérifiez la somme des carrés avant et après la transformation principale. Cela prouve-t-il un même volume perçu ?

<details><summary>Réponse 3</summary>

Les énergies affichées sont égales, par propriété de la matrice orthonormale. Le volume perçu dépend aussi de la restitution et des conditions d’écoute.

</details>

### Exercice 4

Appliquez le témoin sans composante latérale. Des canaux de sortie égaux permettent-ils la reconstruction ?

<details><summary>Réponse 4</summary>

Non. Les sorties deviennent la même moyenne et l’énergie diminue comme indiqué. L’information latérale a été supprimée, et non stockée en double.

</details>

### Exercice 5

Quel résultat ferait rejeter un transfert stéréo annoncé sans perte ?

<details><summary>Réponse 5</summary>

Ne pas retrouver un échantillon conservé avec l’inverse déclaré réfute l’absence de perte numérique. Un résultat du script mono ne démontre pas ce transfert stéréo.

</details>

## Travail avec consultation des sources

Dessinez les transformations à la main. Comparez la conservation des composantes à celle de leur somme seule, puis repérez la déclaration mono de l’en-tête. Proposez le plus petit enregistrement réversible avant un réglage de largeur, en conservant l’ordre des canaux et leur échelle.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
