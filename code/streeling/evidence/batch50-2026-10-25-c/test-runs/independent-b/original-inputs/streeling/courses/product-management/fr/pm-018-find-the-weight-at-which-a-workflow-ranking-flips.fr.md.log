---
module_id: "pm-018-find-the-weight-at-which-a-workflow-ranking-flips"
department: "product-management"
course: "Trouver le poids qui inverse le classement des processus"
title: "Trouver le poids qui inverse le classement des processus"
level: "intermediate"
prerequisites: ["pm-011-include-review-and-correction-in-automation-break-even", "pm-004-craft-extension-release-decision"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Trouver le poids qui inverse le classement des processus

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Une équipe classe des processus de vérification en combinant des points de latence et de reprise. Un assistant peut donner une apparence objective à une préférence en cachant son poids dans une note composite. L’analyse de sensibilité demande quelles préférences soutiennent réellement la recommandation. Les coordonnées doivent déjà suivre des échelles comparables déclarées ; multiplier des unités hétérogènes ne justifie pas une utilité.

Écrivez chaque note comme une fonction affine du poids de latence, le poids restant étant attribué à la reprise. Égalisez les deux fonctions et résolvez le seuil de bascule. Vérifiez qu’il appartient à l’intervalle autorisé. Évaluez un point de chaque côté pour déterminer l’option préférable, puis gardez les deux à égalité exacte.

Le poids fixé favorise un processus et le contrôle favorise l’autre. Aucun résultat ne donne de gagnant universel. Le seuil rend visible une frontière de décision avant l’adoption d’une politique. Distributions réelles de latence, qualité des corrections et incertitude des échelles ne sont pas mesurées. La lecture sur la scalarisation fournit le concept d’objectif pondéré ; la comparaison affine finie est créée ici. Une recommandation devrait afficher son poids et signaler les préférences qui inversent le classement.

## Sources et périmètre du projet

[Prérequis: pm-011-include-review-and-correction-in-automation-break-even](../../product-management/en/pm-011-include-review-and-correction-in-automation-break-even.md)

[Prérequis: pm-004-craft-extension-release-decision](../../product-management/en/pm-004-craft-extension-release-decision.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "names": [
      "A",
      "B"
    ],
    "latency": [
      2,
      6
    ],
    "rework": [
      8,
      2
    ],
    "latency_weight": "1/4"
  },
  "formula": "score[i]=w*latency[i]+(1-w)*rework[i], minimize. Solve equal affine scores for crossover w; report scores there and all tied winners. Exact rationals.",
  "expected": {
    "scores": [
      "13/2",
      "3"
    ],
    "winners": [
      "B"
    ],
    "crossover_weight": "3/5",
    "crossover_scores": [
      "22/5",
      "22/5"
    ],
    "crossover_winners": [
      "A",
      "B"
    ]
  },
  "negative_control": {
    "values": {
      "names": [
        "A",
        "B"
      ],
      "latency": [
        2,
        6
      ],
      "rework": [
        8,
        2
      ],
      "latency_weight": "3/4"
    },
    "expected": {
      "scores": [
        "7/2",
        "5"
      ],
      "winners": [
        "A"
      ],
      "crossover_weight": "3/5",
      "crossover_scores": [
        "22/5",
        "22/5"
      ],
      "crossover_winners": [
        "A",
        "B"
      ]
    },
    "why": "Different declared preferences reverse the winner without changing either workflow coordinate."
  },
  "input_types": {
    "names": "two distinct option strings",
    "latency": "two finite rational points on declared comparable scale",
    "rework": "two finite rational points on declared comparable scale",
    "latency_weight": "rational string in closed unit interval"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No measured workflow cost, accepted utility scale, stakeholder preference or production recommendation is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Écrire les fonctions affines, résoudre leur intersection et tester de chaque côté.

**Critère de réfutation:** Une recommandation est présentée comme indépendante du poids malgré un seuil dans l’intervalle autorisé.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Calculez le classement fixé.

> **Réponse:** Au poids `1/4`, les notes sont `[13/2,3]` ; la minimisation choisit `B`.

### Exercice 2

Trouvez le seuil et le contrôle.

> **Réponse:** Le seuil vaut `3/5`, où les notes valent `22/5`. À `3/4`, les notes `[7/2,5]` choisissent `A`.

### Exercice 3

Que permet l’égalité ?

> **Réponse:** Elle permet d’annoncer les deux minima de cet objectif. Une recommandation unique exige un autre critère déclaré.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Au poids `1/4`, les notes sont `[13/2,3]` ; la minimisation choisit `B`.
- Exercice 2: Le seuil vaut `3/5`, où les notes valent `22/5`. À `3/4`, les notes `[7/2,5]` choisissent `A`.
- Exercice 3: Elle permet d’annoncer les deux minima de cet objectif. Une recommandation unique exige un autre critère déclaré.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
