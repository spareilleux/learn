---
title: Mesurer le déplacement a posteriori par variation totale
description: Mesurer le déplacement a posteriori par variation totale — Théorie de l'information
sidebar:
  label: INF-022 · Mesurer le déplacement a posteriori par variation totale
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-022-measure-posterior-movement-with-total-variation.fr.md
---

:::note[Streeling University]
**INF-022** · Mesurer le déplacement a posteriori par variation totale · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-022-measure-posterior-movement-with-total-variation.fr.md) · [Mon journal](../../journal/)

Prérequis: [INF-013](../../information-theory/inf-013-value-an-evidence-probe-by-expected-information/), [INF-003](../../information-theory/inf-003-verdict-distribution-drift/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un compte rendu agentique annonce qu’une observation a changé une croyance. De combien la distribution déclarée a-t-elle réellement bougé ? Une explication plus longue peut ne rien modifier si les hypothèses prédisent aussi bien l’observation. Ce cours associe une mise à jour bayésienne finie à une distance bornée entre distributions.

Multipliez chaque masse a priori par la vraisemblance de l’observation sous cette hypothèse. Additionnez les produits pour obtenir sa probabilité marginale, puis normalisez. Les vraisemblances n’ont pas à totaliser l’unité entre hypothèses : elles relèvent d’expériences conditionnelles différentes. Un normalisateur nul rendrait l’observation impossible dans le modèle fourni ; il ne faudrait pas inventer une distribution pour masquer ce problème.

La variation totale est la moitié de la somme des différences absolues entre coordonnées. Elle mesure le plus grand changement de probabilité d’un événement dans cet espace fini. Le cas informatif déplace de la masse vers une hypothèse ; le contrôle à vraisemblances égales conserve l’a priori. Aucun résultat ne prouve l’hypothèse favorisée. Identité de la mesure, adéquation du modèle et absence de double comptage restent à vérifier séparément. Aucun service de croyances réel n’est exécuté.

## Sources et périmètre du projet

[Prérequis: inf-013-value-an-evidence-probe-by-expected-information](../../information-theory/inf-013-value-an-evidence-probe-by-expected-information/)

[Prérequis: inf-003-verdict-distribution-drift](../../information-theory/inf-003-verdict-distribution-drift/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://www.cs.cornell.edu/courses/cs2800/2016fa/lectures/lec17-prob.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "prior": [
      "1/2",
      "1/2"
    ],
    "likelihood": [
      "4/5",
      "1/5"
    ]
  },
  "formula": "Products prior[i]*likelihood[i] give unnormalized mass; normalizer=sum(products)>0; posterior=products/normalizer; total_variation=sum(abs(posterior[i]-prior[i]))/2. All arithmetic is exact rational.",
  "expected": {
    "unnormalized": [
      "2/5",
      "1/10"
    ],
    "normalizer": "1/2",
    "posterior": [
      "4/5",
      "1/5"
    ],
    "total_variation": "3/10"
  },
  "negative_control": {
    "values": {
      "prior": [
        "1/2",
        "1/2"
      ],
      "likelihood": [
        "2/5",
        "2/5"
      ]
    },
    "expected": {
      "unnormalized": [
        "1/5",
        "1/5"
      ],
      "normalizer": "2/5",
      "posterior": [
        "1/2",
        "1/2"
      ],
      "total_variation": "0"
    },
    "why": "An equally predicted observation is not discriminating evidence."
  },
  "input_types": {
    "prior": "nonnegative rational strings summing to one",
    "likelihood": "same-length rational strings in closed unit interval with positive marginal"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No real likelihood calibration, causal claim, posterior truth guarantee or production belief update is observed."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Écrire la table pondérée par vraisemblance, normaliser et calculer les écarts absolus.

**Critère de réfutation:** Une mise à jour modifie des masses égales sous des vraisemblances égales sans nouvelle hypothèse.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Normalisez les produits fixés.

> **Réponse:** Les produits sont `[2/5,1/10]`, le normalisateur `1/2` et l’a posteriori `[4/5,1/5]`.

### Exercice 2

Calculez le déplacement et le contrôle.

> **Réponse:** La variation totale fixée vaut `3/10`. Les vraisemblances égales donnent `[1/2,1/2]` et un déplacement de `0`.

### Exercice 3

Faut-il normaliser d’abord les vraisemblances entre hypothèses ?

> **Réponse:** Non. Elles conditionnent la même observation sur différentes hypothèses. Normalisez les produits pondérés par l’a priori et conservez le modèle de vraisemblance.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: Les produits sont `[2/5,1/10]`, le normalisateur `1/2` et l’a posteriori `[4/5,1/5]`.
- Exercice 2: La variation totale fixée vaut `3/10`. Les vraisemblances égales donnent `[1/2,1/2]` et un déplacement de `0`.
- Exercice 3: Non. Elles conditionnent la même observation sur différentes hypothèses. Normalisez les produits pondérés par l’a priori et conservez le modèle de vraisemblance.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
