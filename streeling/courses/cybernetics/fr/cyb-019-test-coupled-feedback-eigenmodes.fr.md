---
module_id: "cyb-019-test-coupled-feedback-eigenmodes"
department: "cybernetics"
course: "Tester les modes propres de boucles couplées"
title: "Tester les modes propres de boucles couplées"
level: "intermediate"
prerequisites: ["cyb-008-check-convergence-before-repeating-a-correction"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Tester les modes propres de boucles couplées

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Des agents GA et IX peuvent réduire chacun leur écart local tout en déclenchant du travail correctif chez l’autre. Examiner chaque multiplicateur isolément peut masquer cette interaction. La question est de savoir si la mise à jour commune réduit tous les modes, y compris celui où les écarts augmentent ensemble. Explicitez le couplage avant d’appliquer une règle scalaire à un travail multi-agent.

Prenez une transition symétrique, avec les mêmes termes diagonaux et un terme croisé dans chaque position hors diagonale. Additionner les équations donne le multiplicateur du mode commun ; les soustraire donne celui du mode opposé. Les vecteurs propres apparaissent directement, sans solveur numérique général. Une diagonale inférieure à l’unité ne décrit que le système dont le voisin serait maintenu fixe.

Dans le cas fixé, le mode commun croît tandis que le mode opposé décroît en alternant. Des coordonnées initiales égales et positives excitent le mode croissant : une courte trajectoire exacte en fournit un témoin. Le contrôle réduit le terme croisé et fait décroître les deux modes. Vérifier uniquement la trajectoire affichée resterait moins fort que vérifier les deux multiplicateurs, car un autre état initial pourrait exciter l’autre mode.

Le cours de convergence fournit une dynamique d’erreur pour un calcul diagonal de matériau. Ici, nous changeons la structure des dépendances au lieu d’ajuster son gain. Le critère discret de Harvard s’applique à cette matrice diagonalisable. Des transferts réels entre agents peuvent être retardés, non linéaires et discontinus ; des progrès locaux n’identifient pas ces coefficients. Une étude en dogfood demanderait des changements alignés et liés aux révisions, puis une transition mesurée.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cyb-008-check-convergence-before-repeating-a-correction](../../cybernetics/en/cyb-008-check-convergence-before-repeating-a-correction.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://hankyang.seas.harvard.edu/OptimalControlEstimation/app-lti-system-theory.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "diagonal": 0.5,
    "coupling": 0.75,
    "initial": [
      1,
      1
    ],
    "steps": 3
  },
  "formula": "A=[[a,b],[b,a]]; eigenvalues are a+b and a-b. Iterate x_next=A*x exactly steps times. Asymptotically stable iff both eigenvalue absolute values are strictly below 1.",
  "expected": {
    "eigenvalues": [
      1.25,
      -0.25
    ],
    "spectral_radius": 1.25,
    "stable": false,
    "trajectory": [
      [
        1,
        1
      ],
      [
        1.25,
        1.25
      ],
      [
        1.5625,
        1.5625
      ],
      [
        1.953125,
        1.953125
      ]
    ]
  },
  "negative_control": {
    "values": {
      "diagonal": 0.5,
      "coupling": 0.25,
      "initial": [
        1,
        1
      ],
      "steps": 3
    },
    "expected": {
      "eigenvalues": [
        0.75,
        0.25
      ],
      "spectral_radius": 0.75,
      "stable": true,
      "trajectory": [
        [
          1,
          1
        ],
        [
          0.75,
          0.75
        ],
        [
          0.5625,
          0.5625
        ],
        [
          0.421875,
          0.421875
        ]
      ]
    },
    "why": "Reducing cross-coupling puts both modes strictly inside the unit circle."
  },
  "input_types": {
    "diagonal": "rational scalar",
    "coupling": "rational scalar",
    "initial": "length-2 rational vector",
    "steps": "nonnegative integer"
  },
  "assumptions": [
    "Synchronous autonomous linear updates with fixed coefficients.",
    "The two coordinates are deviations, not literal nonnegative queue counts."
  ],
  "limits": "No production controller or gain recommendation. Delays, saturation and disturbance change the transition."
}
```

### Exercice 1

Trouvez les multiplicateurs des modes.

<details><summary>Réponse 1</summary>

Ils valent `1.25` et `-0.25` ; le rayon spectral vaut `1.25`. La matrice est instable malgré ses diagonales de `0.5`.

</details>

### Exercice 2

Suivez le témoin du mode commun.

<details><summary>Réponse 2</summary>

Depuis `[1,1]`, le vecteur après `3` étapes vaut `[1.953125,1.953125]`. Chaque étape amplifie l’écart commun.

</details>

### Exercice 3

Appliquez le contrôle au couplage réduit.

<details><summary>Réponse 3</summary>

Les valeurs propres deviennent `[0.75,0.25]`, strictement dans le cercle unité. Le vecteur final commun vaut `[0.421875,0.421875]` ; la stabilité vaut `true`.

</details>

### Exercice 4

Une trajectoire opposée décroissante certifie-t-elle la stabilité ?

<details><summary>Réponse 4</summary>

Non. Elle n’excite que son mode. Le mode commun peut encore croître ; vérifiez chaque mode propre du modèle linéaire déclaré.

</details>

### Exercice 5

Qu’est-ce qui rejetterait la règle réelle proposée ?

<details><summary>Réponse 5</summary>

Une transition mesurée hors modèle, un mode amplificateur ou un comportement inacceptable aux limites. Le seul progrès scalaire local ne valide pas une règle couplée.

</details>

## Travail avec consultation des sources

Évaluez une esquisse de correction couplée pour des transferts GA et IX.

**Référence manuelle directe:** Additionnez puis soustrayez les équations et suivez manuellement les directions des modes.

**Critère de réfutation:** Un mode propre croît malgré la promesse de réduire tout écart initial.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Trouvez les multiplicateurs des modes. — Décision indéterminée.
- Exercice 2: Suivez le témoin du mode commun. — Décision indéterminée.
- Exercice 3: Appliquez le contrôle au couplage réduit. — Décision indéterminée.
- Exercice 4: Une trajectoire opposée décroissante certifie-t-elle la stabilité ? — Décision indéterminée.
- Exercice 5: Qu’est-ce qui rejetterait la règle réelle proposée ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
