---
module_id: gaa-016-separate-order-drift-from-a-practice-condition
department: guitar-alchemist-academy
course: "Distinguer la dérive temporelle de l’effet d’une condition de pratique"
level: advanced
prerequisites: ["gaa-012-cross-timbre-with-interval-in-an-ear-trial"]
estimated_duration: "60 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Distinguer la dérive temporelle de l’effet d’une condition de pratique

> Modèle construit et lecture de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, essai d’écoute, analyse exécutée, rendu du moteur ou usage en production n’est revendiqué.

Un guitariste peut progresser pendant une courte séance même si deux formats de consigne ont le même effet. Placer un format plus tard peut améliorer artificiellement sa moyenne. Pour une comparaison [GA](https://github.com/GuitarAlchemist/ga), examinez l’ordre des essais en plus de l’équilibre des facteurs. Nous construisons une dérive linéaire et comparons des séquences d’effectifs égaux.

## Lire les éléments conservés

La source traite de l’ordre aléatoire et des répétitions équilibrées. Notre séquence symétrique est déterministe : ce n’est pas une expérience randomisée. Les règles conservées définissent les réponses, sans supprimer leur dépendance temporelle.

[Prérequis](../../guitar-alchemist-academy/en/gaa-012-cross-timbre-with-interval-in-an-ear-trial.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25/unit-a.json)

[Lecture principale](https://www.itl.nist.gov/div898/handbook/pri/section3/pri331.htm)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "order": [
      "A",
      "B",
      "B",
      "A"
    ],
    "base": 4,
    "drift_per_trial": 1,
    "condition_effect": {
      "A": 0,
      "B": 0
    }
  },
  "formula": "score_i=base+drift*i+effect[condition_i], i starts at 0; contrast=mean(B)-mean(A)",
  "expected": {
    "scores": [
      4,
      5,
      6,
      7
    ],
    "mean_a": 5.5,
    "mean_b": 5.5,
    "contrast": 0
  },
  "negative_control": {
    "values": {
      "order": [
        "A",
        "B",
        "A",
        "B"
      ],
      "base": 4,
      "drift_per_trial": 1,
      "condition_effect": {
        "A": 0,
        "B": 0
      }
    },
    "expected": {
      "scores": [
        4,
        5,
        6,
        7
      ],
      "mean_a": 5,
      "mean_b": 6,
      "contrast": 1
    }
  }
}
```

## Conserver l’hypothèse de nuisance temporelle

Des effectifs égaux facilitent la comparaison des moyennes, sans déterminer les instants qui y contribuent. Sous une tendance linéaire, la position moyenne devient la grandeur supplémentaire pertinente. L’ordre symétrique égalise cette position entre conditions. C’est une annulation algébrique pour la tendance choisie, sans garantie générale que l’ordre ne compte plus.

L’autre séquence montre pourquoi une table de comptes marginaux ne suffit pas. Elle contient les mêmes labels, effectifs et réponses, mais associe des positions tardives à une condition. Un résumé qui supprime l’ordre ne peut pas reconstruire cette association. Le relevé brut des essais doit donc survivre aux agrégations du tableau de bord, avec la grille et le format réellement présenté.

Certaines tendances échappent à cette annulation. Un apprentissage soudain après correction, une pause en cours de séance ou un effet du format précédent modifient les réponses hors du modèle linéaire. Une expérience future devrait choisir randomisation, blocs ou modélisation avant les résultats. Le calcul direct des positions moyennes aide à choisir cette étape. Ajouter un agent qui mélange des labels ne documente pas à lui seul la randomisation, la présentation réelle ou une comparaison d’apprentissage sans biais ; ces affirmations demandent une procédure et des observations conservées.

### Exercice 1

Construisez la séquence principale à partir de la dérive. Quel effet a été posé absent ?

<details><summary>Réponse 1</summary>

Les scores indiqués augmentent avec la position. Les effets des conditions sont supposés nuls ; une différence provient donc ici de l’ordre ou du calcul.

</details>

### Exercice 2

Calculez les moyennes principales. Pourquoi cet ordre annule-t-il la tendance choisie ?

<details><summary>Réponse 2</summary>

La position moyenne des essais est la même pour chaque condition. Cette dérive linéaire contribue donc de façon identique aux moyennes.

</details>

### Exercice 3

Un contraste nul prouve-t-il l’équivalence des conditions pour les musiciens ?

<details><summary>Réponse 3</summary>

Non. Il découle exactement d’un modèle de nuisance construit. Les résultats réels, leur incertitude, les effets de report et la pertinence musicale n’ont pas été observés.

</details>

### Exercice 4

Appliquez le témoin alterné. Des effectifs égaux suppriment-ils son contraste artificiel ?

<details><summary>Réponse 4</summary>

Non. La position moyenne plus tardive de la seconde condition produit le contraste non nul affiché, malgré les effectifs égaux et l’effet de traitement supposé nul.

</details>

### Exercice 5

Qu’est-ce qui réfute l’idée que l’équilibre marginal contrôle tout effet d’ordre ?

<details><summary>Réponse 5</summary>

Le témoin donne déjà un contre-exemple linéaire. Une dérive non linéaire pourrait aussi déjouer la séquence symétrique ; conservez l’ordre et vérifiez cette hypothèse avant une interprétation réelle.

</details>

## Travail avec consultation des sources

Dressez les tables de positions à la main et calculez les moyennes, puis examinez la grille conservée. Proposez un rapport futur gardant l’ordre et une hypothèse de nuisance formulée à l’avance. Comparez cette table directe aux séquences générées avant de juger les consignes.

Conservez d’abord votre raisonnement sans aide, avant de révéler les réponses. Examinez ensuite un passage précis avec sa révision, consignez chaque aide reçue et gardez séparément la réponse initiale et sa correction. Votre résultat manuel sert de référence pour toute calculatrice, proposition de DSL ou intervention d’agent. Une donnée manquante reste non résolue. Le dossier contient un critère préparé par exercice, sans décision d’apprenant. Une réponse correcte ne justifie que le cas déclaré ; l’acceptation exige une tentative réelle et sa revue. Formulez un critère de réfutation avant toute abstraction, puis indiquez les preuves humaines ou d’exécution nécessaires à la prochaine étape.
