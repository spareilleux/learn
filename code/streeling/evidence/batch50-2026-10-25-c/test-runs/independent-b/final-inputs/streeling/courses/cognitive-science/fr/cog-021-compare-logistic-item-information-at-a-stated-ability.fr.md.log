---
module_id: "cog-021-compare-logistic-item-information-at-a-stated-ability"
department: "cognitive-science"
course: "Comparer l’information des items logistiques à un niveau donné"
title: "Comparer l’information des items logistiques à un niveau donné"
level: "intermediate"
prerequisites: ["cog-020-screen-an-item-using-the-rest-score"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Comparer l’information des items logistiques à un niveau donné

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un concepteur d’exercices GA souhaite comparer des questions de hauteur avant de recueillir des réponses. Le taux de réussite seul ne montre pas où un item distingue des niveaux voisins. Le modèle logistique rend cette dépendance explicite. La difficulté déplace la courbe sur l’axe d’habileté, tandis que la discrimination en modifie la pente. Ces paramètres sont ici des hypothèses, pas des propriétés estimées d’un exercice réel.

Pour une réponse de Bernoulli, on dérive la log-vraisemblance par rapport à l’habileté. L’espérance du carré de cette dérivée donne le carré de la discrimination multiplié par la probabilité de réussite et celle d’échec. Cette information est locale et dépend du modèle choisi. Ce n’est ni l’entropie d’un message, ni une note de précision, ni une preuve de maîtrise.

Calculez les probabilités et les informations de chaque candidat au niveau annoncé. Une discrimination plus forte ne suffit pas si la difficulté est trop éloignée de l’habileté. Le contrôle déplace cette dernière et inverse le classement. L’exemple prépare une comparaison avant sélection adaptative ; il ne constitue pas un tuteur adaptatif. L’incertitude des paramètres, les compétences multiples et les réponses au hasard demanderaient une autre analyse.

## Sources et périmètre du projet

[Prérequis: cog-020-screen-an-item-using-the-rest-score](../../cognitive-science/en/cog-020-screen-an-item-using-the-rest-score.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://quantdev.ssri.psu.edu/sites/qdev/files/IRT_tutorial_FA17_2.html)

[Lecture primaire](https://www.publichealth.columbia.edu/research/population-health-methods/item-response-theory)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "theta": 0,
    "items": [
      [
        1,
        0
      ],
      [
        2,
        1
      ]
    ],
    "round_digits": 12
  },
  "formula": "For each [a,b], P=1/(1+exp(-a*(theta-b))); I=a*a*P*(1-P). Round only displayed probabilities/information to round_digits; choose largest unrounded I, retaining ties.",
  "expected": {
    "probabilities": [
      0.5,
      0.119202922022
    ],
    "information": [
      0.25,
      0.419974341614
    ],
    "best_indices": [
      1
    ]
  },
  "negative_control": {
    "values": {
      "theta": -1,
      "items": [
        [
          1,
          0
        ],
        [
          2,
          1
        ]
      ],
      "round_digits": 12
    },
    "expected": {
      "probabilities": [
        0.26894142137,
        0.017986209962
      ],
      "information": [
        0.196611933241,
        0.070650824853
      ],
      "best_indices": [
        0
      ]
    },
    "why": "Moving ability changes which item is locally informative."
  },
  "input_types": {
    "theta": "finite real ability",
    "items": "ordered [positive discrimination a, finite difficulty b] pairs",
    "round_digits": "nonnegative integer"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real learner ability, fitted item parameters, guessing model or adaptive tutoring result is observed."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Calculer à la main les probabilités et informations, puis comparer les items.

**Critère de réfutation:** Le classement est réutilisé après un changement d’habileté sans recalcul.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Quel item apporte le plus d’information dans le cas fixé ?

> **Réponse:** L’indice `1` gagne : son information vaut `0.419974341614`, contre `0.25`. Sa probabilité de réussite est inférieure ; information et facilité diffèrent.

### Exercice 2

Appliquez le contrôle sur l’habileté.

> **Réponse:** À `theta=-1`, l’indice `0` gagne avec `0.196611933241`, contre `0.070650824853`. Le classement est conditionnel.

### Exercice 3

Le calcul estime-t-il l’habileté ?

> **Réponse:** Non. Habileté et paramètres sont imposés. Une estimation réelle exige des réponses et un modèle de mesure justifié.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: L’indice `1` gagne : son information vaut `0.419974341614`, contre `0.25`. Sa probabilité de réussite est inférieure ; information et facilité diffèrent.
- Exercice 2: À `theta=-1`, l’indice `0` gagne avec `0.196611933241`, contre `0.070650824853`. Le classement est conditionnel.
- Exercice 3: Non. Habileté et paramètres sont imposés. Une estimation réelle exige des réponses et un modèle de mesure justifié.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
