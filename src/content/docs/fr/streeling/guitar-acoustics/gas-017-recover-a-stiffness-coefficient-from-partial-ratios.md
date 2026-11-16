---
title: Retrouver un coefficient de raideur à partir des rapports de partiels
description: Retrouver un coefficient de raideur à partir des rapports de partiels — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-017 · Retrouver un coefficient de raideur à partir des rapports de partiels
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-017-recover-a-stiffness-coefficient-from-partial-ratios.fr.md
---

:::note[Streeling University]
**GAS-017** · Retrouver un coefficient de raideur à partir des rapports de partiels · avancé · 60 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-017-recover-a-stiffness-coefficient-from-partial-ratios.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-010](../../guitar-acoustics/gas-010-distinguish-stiff-string-partials-from-harmonics/)
:::

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un spectre inharmonique plausible ne suffit pas à identifier un paramètre de production. Avant de recommander un réglage de dispersion [GA](https://github.com/GuitarAlchemist/ga), résolvez le modèle inverse déclaré et vérifiez un partiel qui n’a pas servi à l’ajustement. Ce cours distingue estimation et prévision, puis rejette une observation incompatible avec la famille choisie.

## Lire les éléments conservés

La source principale explique la propagation dispersive et sa modélisation par filtres passe-tout. Notre coefficient normalisé vient du modèle du prérequis, sans étalonnage documenté du moteur. L’état de dispersion conservé décrit une frontière logicielle, et non une mesure de matériau.

[Prérequis](../../guitar-acoustics/gas-010-distinguish-stiff-string-partials-from-harmonics/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/vendor/lib.rs)

[Dossier des cas construits](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.dsprelated.com/freebooks/pasp/Stiff_String.html)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "squared_normalized_second_ratio": 1.0297029702970297,
    "squared_normalized_third_ratio": 1.0792079207920793
  },
  "formula": "r=(f2/(2*f1))^2; B=(r-1)/(4-r); predicted_third_squared_ratio=(1+9*B)/(1+B); valid=1<=r<4 and B>=0",
  "expected": {
    "B": 0.01,
    "predicted_third_squared_ratio": 1.0792079207920793,
    "held_out_residual": 0,
    "valid": true
  },
  "negative_control": {
    "values": {
      "squared_normalized_second_ratio": 0.99,
      "squared_normalized_third_ratio": 1
    },
    "expected": {
      "B": -0.0033222591362126247,
      "valid": false
    }
  }
}
```

## Distinguer ajustement, prévision et étalonnage

Un calcul inverse peut retrouver exactement l’observation choisie par construction. Cet accord ne constitue pas une validation indépendante. L’entrée du troisième partiel reste donc hors de l’équation d’ajustement et n’est comparée qu’après estimation du coefficient. Dans un spectre réel, l’incertitude et l’identité des pics compteraient aussi : intervertir un indice peut donner un bel ajustement numérique à une mauvaise relation physique.

L’inverse possède un domaine admissible. Lorsque son dénominateur approche de zéro, de petits écarts de rapport peuvent produire de grandes variations du coefficient. Une réponse finie peut donc être algébriquement définie et pratiquement instable. Le contrôle de non-négativité traite une autre question : il rejette un signe incompatible avec la famille déclarée, sans estimer la confiance dans un ajustement valide. Distinguez singularité, admissibilité et incertitude de mesure.

Enfin, un coefficient pédagogique estimé n’est pas une valeur de réglage logiciel. Une implémentation passe-tout peut utiliser des coefficients liés aux rapports de partiels par la boucle complète. L’état conservé montre des grandeurs de dispersion, sans fournir leur inverse étalonné. Avant de recommander un réglage, une expérience doit conserver une intervention identifiée et des partiels mesurés réservés à la vérification. L’inverse manuel et son cas rejeté fournissent une référence simple pour juger si cet étalonnage plus vaste est justifié.

### Exercice 1

Réarrangez le rapport quadratique du second partiel pour isoler le coefficient. Quel terme doit rester non nul ?

<details><summary>Réponse 1</summary>

Le regroupement des termes donne l’inverse affiché. Son dénominateur doit être non nul ; écrêter silencieusement un ajustement ne répare pas un rapport singulier ou exclu.

</details>

### Exercice 2

Utilisez le rapport principal et indiquez le coefficient retrouvé. Quelle relation a été ajustée ?

<details><summary>Réponse 2</summary>

Le coefficient attendu figure ci-dessus. Seule la relation normalisée du second partiel a servi à l’ajustement ; le premier partiel fixe toujours l’échelle fréquentielle.

</details>

### Exercice 3

Prévoyez le rapport du troisième partiel réservé à la vérification. Pourquoi le garder séparément ?

<details><summary>Réponse 3</summary>

La prévision et le rapport fourni concordent dans ce cas construit. Réutiliser l’équation du second partiel ne testerait pas la conséquence pour un partiel supérieur.

</details>

### Exercice 4

Appliquez le témoin. Pourquoi rejeter le coefficient alors que l’algèbre fournit un nombre ?

<details><summary>Réponse 4</summary>

Le coefficient est négatif et sort de la famille non négative choisie. Un résultat algébrique fini ne garantit pas son admissibilité physique sous ces hypothèses.

</details>

### Exercice 5

Qu’est-ce qui réfuterait l’ajustement avant un étalonnage du moteur ?

<details><summary>Réponse 5</summary>

Un rapport réservé incompatible avec la prévision au-delà de l’incertitude déclarée réfute l’ajustement. Une mauvaise identification du partiel invalide aussi l’entrée, sans démontrer un défaut du moteur.

</details>

## Travail avec consultation des sources

Déduisez l’inverse à la main et conservez séparément la vérification réservée. Comparez le résultat à l’état logiciel conservé. Proposez un relevé avec identité et incertitude des partiels avant toute recommandation ; la correspondance avec le moteur et l’audibilité restent à établir.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
