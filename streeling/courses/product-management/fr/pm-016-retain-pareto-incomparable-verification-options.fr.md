---
module_id: "pm-016-retain-pareto-incomparable-verification-options"
department: "product-management"
course: "Conserver les options de vérification incomparables au sens de Pareto"
title: "Conserver les options de vérification incomparables au sens de Pareto"
level: "intermediate"
prerequisites: ["pm-014-select-a-budgeted-portfolio-with-prerequisite-closure", "pm-004-craft-extension-release-decision"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conserver les options de vérification incomparables au sens de Pareto

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un coordinateur Learn compare des processus de vérification optionnels selon l’effort initial et un nombre de défauts imposé. Une option peut coûter moins et une autre présenter moins de défauts. Une note unique exigerait une règle explicite d’échange entre ces dimensions. La comparaison de Pareto commence par écarter les options sans avantage sur les objectifs représentés.

Tous les objectifs sont ici à minimiser. Une option en domine une autre si elle n’est pire sur aucune coordonnée et s’améliore strictement sur au moins une. L’égalité complète n’est pas une dominance stricte. Comparez toutes les paires et conservez les options non dominées. Cet ordre partiel peut laisser plusieurs candidats ; c’est un résultat honnête, pas un échec d’optimisation.

Le cas fixé contient une option dominée et plusieurs compromis réels. Le contrôle dégrade une autre option jusqu’à la rendre dominée. Supprimer ces options ne choisit pas entre les compromis restants et ne prouve pas le respect des critères de publication. Dimensions absentes, incertitudes et priorités pourraient modifier la décision réelle. Les coordonnées sont fictives, pas des défauts de cours mesurés. Un DSL devrait afficher l’ensemble non dominé et la préférence manquante avant une recommandation unique.

## Sources et périmètre du projet

[Prérequis: pm-014-select-a-budgeted-portfolio-with-prerequisite-closure](../../product-management/en/pm-014-select-a-budgeted-portfolio-with-prerequisite-closure.md)

[Prérequis: pm-004-craft-extension-release-decision](../../product-management/en/pm-004-craft-extension-release-decision.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "names": [
      "A",
      "B",
      "C",
      "D"
    ],
    "objectives": [
      [
        2,
        5
      ],
      [
        4,
        2
      ],
      [
        5,
        6
      ],
      [
        3,
        4
      ]
    ]
  },
  "formula": "Minimize every coordinate. i dominates j iff all objectives[i]<=objectives[j] coordinatewise and at least one strict inequality. Return nondominated names and all ordered [dominator,dominated] pairs in name order.",
  "expected": {
    "nondominated": [
      "A",
      "B",
      "D"
    ],
    "dominance_pairs": [
      [
        "A",
        "C"
      ],
      [
        "B",
        "C"
      ],
      [
        "D",
        "C"
      ]
    ]
  },
  "negative_control": {
    "values": {
      "names": [
        "A",
        "B",
        "C",
        "D"
      ],
      "objectives": [
        [
          2,
          5
        ],
        [
          4,
          2
        ],
        [
          5,
          6
        ],
        [
          4,
          5
        ]
      ]
    },
    "expected": {
      "nondominated": [
        "A",
        "B"
      ],
      "dominance_pairs": [
        [
          "A",
          "C"
        ],
        [
          "A",
          "D"
        ],
        [
          "B",
          "C"
        ],
        [
          "B",
          "D"
        ],
        [
          "D",
          "C"
        ]
      ]
    },
    "why": "Worsening an option removes its distinct tradeoff without supplying a preference among survivors."
  },
  "input_types": {
    "names": "ordered distinct option strings",
    "objectives": "equal-length finite minimization vectors, one per option"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No observed defects, chosen product policy, approved release or subjective utility scale is supplied."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Comparer les paires dans une table d’objectifs avant toute pondération.

**Critère de réfutation:** Une option dite dominée améliore un objectif, ou des options incomparables produisent un gagnant arbitraire.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez l’ensemble non dominé fixé.

> **Réponse:** Les survivants sont `[A,B,D]`. Chacun domine `C`, mais aucun ne domine un autre survivant.

### Exercice 2

Appliquez le contrôle d’option dégradée.

> **Réponse:** Avec `D=[4,5]`, `A` et `B` dominent `D`. L’ensemble non dominé devient `[A,B]`.

### Exercice 3

L’ensemble restant justifie-t-il un choix unique ?

> **Réponse:** Non. Le filtre de Pareto conserve les compromis. Choisir demande des priorités déclarées et toutes les contraintes obligatoires.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les survivants sont `[A,B,D]`. Chacun domine `C`, mais aucun ne domine un autre survivant.
- Exercice 2: Avec `D=[4,5]`, `A` et `B` dominent `D`. L’ensemble non dominé devient `[A,B]`.
- Exercice 3: Non. Le filtre de Pareto conserve les compromis. Choisir demande des priorités déclarées et toutes les contraintes obligatoires.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
