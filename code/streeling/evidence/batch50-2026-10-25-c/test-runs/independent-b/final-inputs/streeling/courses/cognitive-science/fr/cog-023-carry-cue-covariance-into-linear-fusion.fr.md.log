---
module_id: "cog-023-carry-cue-covariance-into-linear-fusion"
department: "cognitive-science"
course: "Intégrer la covariance des indices à leur fusion linéaire"
title: "Intégrer la covariance des indices à leur fusion linéaire"
level: "intermediate"
prerequisites: ["cog-005-separate-pitch-estimates-from-listener-reports", "cyb-015-carry-covariance-through-smoothed-telemetry"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Intégrer la covariance des indices à leur fusion linéaire

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Une interface de guitare peut afficher une estimation de hauteur et un indice visuel tirés en partie du même enregistrement. Les traiter comme indépendants peut exagérer le gain de précision de leur combinaison. On suppose ici qu’ils estiment la même grandeur scalaire sans biais. Variances et covariance sont imposées afin d’examiner la décision avant toute collecte perceptive.

Écrivez l’estimation fusionnée comme une somme pondérée dont les poids totalisent l’unité. Le développement de sa variance fait apparaître un terme de covariance. Dérivez ce polynôme par rapport au premier poids pour trouver le minimum sans contrainte de positivité. Une covariance positive peut produire un poids négatif : l’indice le plus bruité aide alors à soustraire une erreur commune. Cela ne justifie pas un déploiement sans vérifier les biais et les estimations de covariance.

La matrice fixée est définie positive. Le contrôle annule les termes hors diagonale et retrouve les poids fondés sur les variances inverses. Réutiliser ces poids dans le cas corrélé donne une variance réelle moins favorable. Comparez aussi à l’indice individuel le plus précis. Le résumé perceptif cité motive le choix du comparateur ; l’optimisation avec covariance est dérivée ici, sans prétendre avoir lu cette équation dans l’article.

## Sources et périmètre du projet

[Prérequis: cog-005-separate-pitch-estimates-from-listener-reports](../../cognitive-science/en/cog-005-separate-pitch-estimates-from-listener-reports.md)

[Prérequis: cyb-015-carry-covariance-through-smoothed-telemetry](../../cybernetics/en/cyb-015-carry-covariance-through-smoothed-telemetry.md)

[Artefact du projet conservé](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://pubmed.ncbi.nlm.nih.gov/37730934/)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "estimates": [
      10,
      14
    ],
    "variances": [
      1,
      4
    ],
    "covariance": 1.5
  },
  "formula": "For unbiased estimates, w1=(v2-c)/(v1+v2-2*c), w2=1-w1; fused=w1*x1+w2*x2; variance=w1*w1*v1+w2*w2*v2+2*w1*w2*c. Weights are unconstrained real numbers summing to one.",
  "expected": {
    "weights": [
      1.25,
      -0.25
    ],
    "fused": 9,
    "variance": 0.875,
    "independence_weight_variance": 1.28
  },
  "negative_control": {
    "values": {
      "estimates": [
        10,
        14
      ],
      "variances": [
        1,
        4
      ],
      "covariance": 0
    },
    "expected": {
      "weights": [
        0.8,
        0.2
      ],
      "fused": 10.8,
      "variance": 0.8,
      "independence_weight_variance": 0.8
    },
    "why": "Covariance changes the optimum; inverse-variance weights assume independence."
  },
  "input_types": {
    "estimates": "two finite unbiased scalar estimates",
    "variances": "two positive marginal variances",
    "covariance": "finite covariance giving a positive-definite covariance matrix"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No perceptual fusion, actual detector variance, unbiasedness test or deployed interface gain is measured."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Développer la variance de l’erreur fusionnée et dériver le polynôme.

**Critère de réfutation:** Le gain de précision annoncé omet le terme de covariance.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez les poids du cas corrélé.

> **Réponse:** Les poids `[1.25,-0.25]` totalisent `1` ; l’estimation vaut `9` et la variance `0.875`. Le modèle autorise un poids négatif.

### Exercice 2

Appliquez le contrôle d’indépendance.

> **Réponse:** Avec une covariance de `0`, les poids sont `[0.8,0.2]`, l’estimation `10.8` et la variance `0.8`. Ces poids donnent `1.28` avec la covariance initiale.

### Exercice 3

Un poids négatif prouve-t-il que l’entrée est invalide ?

> **Réponse:** Non. La matrice est définie positive et les poids ne sont pas contraints. Exiger leur positivité définirait un autre problème.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les poids `[1.25,-0.25]` totalisent `1` ; l’estimation vaut `9` et la variance `0.875`. Le modèle autorise un poids négatif.
- Exercice 2: Avec une covariance de `0`, les poids sont `[0.8,0.2]`, l’estimation `10.8` et la variance `0.8`. Ces poids donnent `1.28` avec la covariance initiale.
- Exercice 3: Non. La matrice est définie positive et les poids ne sont pas contraints. Exiger leur positivité définirait un autre problème.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-c/journal.md)
