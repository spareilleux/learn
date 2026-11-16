---
title: Projeter une action proposée sur un ensemble admissible
description: Projeter une action proposée sur un ensemble admissible — Cybernétique
sidebar:
  label: CYB-022 · Projeter une action proposée sur un ensemble admissible
  order: 22
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/cybernetics/fr/cyb-022-project-proposed-actions-onto-a-declared-feasible-set.fr.md
---

:::note[Streeling University]
**CYB-022** · Projeter une action proposée sur un ensemble admissible · intermédiaire · 45 minutes

Généré par le département *Cybernétique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/cybernetics/fr/cyb-022-project-proposed-actions-onto-a-declared-feasible-set.fr.md) · [Mon journal](../../journal/)

Prérequis: [CYB-017](../../cybernetics/cyb-017-limit-command-change-separately-from-amplitude/), [CYB-020](../../cybernetics/cyb-020-check-disturbance-robust-set-closure/)
:::

> Ce cas mathématique ou logique fini est créé pour le cours et appuyé par une lecture délimitée des sources. Revue technique humaine, revue linguistique, tentatives apprenantes, exécution native, adoption et publication restent indécidées.

Un assistant peut proposer une action qui dépasse la borne du prochain état tout en respectant celle de l’actionneur. Limiter seulement l’actionneur oublie cette autre obligation. Un filtre de faisabilité intersecte d’abord toutes les restrictions déclarées, puis choisit l’action admissible la plus proche de la proposition. Les restrictions devraient venir du contrat réel avant toute utilisation.

Le prochain état est ici l’état scalaire courant augmenté de l’action choisie. Transformez la borne d’état en borne d’action, puis intersectez-la avec l’intervalle de l’actionneur. Minimisez ensuite la distance quadratique à la proposition. Sur un intervalle fermé non vide, on garde la proposition si elle appartient à l’intervalle ; sinon on prend l’extrémité la plus proche. Ce petit problème explicite ne certifie aucun filtre général.

Le contrôle impose une borne d’état que l’actionneur ne peut atteindre. L’ensemble admissible devient vide : il faut annoncer l’impossibilité plutôt qu’inventer une commande prétendument sûre. Une action proche n’est pas sûre dans un monde non modélisé ; perturbations, observations anciennes et erreurs de modèle sont absentes. Un futur artefact agentique devrait conserver la proposition, les restrictions actives et le motif du refus, pour ne pas masquer une demande impossible.

## Sources et périmètre du projet

[Prérequis: cyb-017-limit-command-change-separately-from-amplitude](../../cybernetics/cyb-017-limit-command-change-separately-from-amplitude/)

[Prérequis: cyb-020-check-disturbance-robust-set-closure](../../cybernetics/cyb-020-check-disturbance-robust-set-closure/)

[Artefact du projet conservé](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Lecture primaire](https://web.stanford.edu/~boyd/cvxbook/bv_cvxslides.pdf)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "state": 0,
    "desired_action": 3,
    "action_interval": [
      -2,
      2
    ],
    "next_state_upper": 1
  },
  "formula": "next_state=state+u. Feasible interval=[action_interval[0], min(action_interval[1], next_state_upper-state)]. If lower>upper return infeasible; otherwise project desired_action onto interval and compute squared change.",
  "expected": {
    "feasible": true,
    "feasible_interval": [
      -2,
      1
    ],
    "action": 1,
    "next_state": 1,
    "squared_change": 4
  },
  "negative_control": {
    "values": {
      "state": 0,
      "desired_action": 3,
      "action_interval": [
        -2,
        2
      ],
      "next_state_upper": -3
    },
    "expected": {
      "feasible": false,
      "feasible_interval": null,
      "action": null,
      "next_state": null,
      "squared_change": null
    },
    "why": "The tightened next-state obligation and actuator interval have no common action."
  },
  "input_types": {
    "state": "finite scalar",
    "desired_action": "finite scalar",
    "action_interval": "ordered closed real interval",
    "next_state_upper": "finite scalar upper bound"
  },
  "assumptions": [
    "All inputs are stipulated teaching values, not measured project events.",
    "Only the declared finite objective and constraints are represented."
  ],
  "limits": "No disturbance robustness, physical safety, actual agent action or generic quadratic-program solver is established."
}
```

## Tâche avec sources et journal

**Référence manuelle directe:** Intersecter les contraintes et trouver le point le plus proche, ou prouver l’intersection vide.

**Critère de réfutation:** Une commande est émise malgré une intersection vide ou une borne d’état ignorée.

Lisez le prérequis et la représentation du projet conservée avant de traiter cet exemple comme une fonctionnalité proposée. Le script Learn lié extrait les métadonnées, le titre et le corps, puis indexe les identités des modules anglais. Cette frontière de représentation est observable ; elle ne fournit ni les entrées inventées ni une implémentation du calcul. Attachez la révision source à la note de lecture pour qu’un changement ultérieur n’hérite pas silencieusement de cette inspection.

Pour la tâche avec sources, reproduisez directement le cas fixé avant de demander une explication à un assistant. Incluez les types et hypothèses du dossier, conservez les calculs intermédiaires et comparez le contrôle négatif déclaré. Demandez quelle prémisse distingue les résultats. Une explication plausible sans calcul de l’entrée modifiée ne démontre pas l’opération.

Consignez question exacte, sources fournies, réponse, assistance et correction dans le journal. Les corrigés ci-dessous forment une grille, pas une tentative d’apprenant. Un contrôle mathématique indépendant peut vérifier le calcul fini sans déceler une mauvaise question ou une traduction trompeuse. Revue technique humaine, revue linguistique, acceptation apprenante, comportement du moteur natif, adoption et publication restent donc indécidés. Gardez l’échec original et son diagnostic avant d’inscrire une reprise réussie ; ne remplacez jamais l’échec par le résultat corrigé.

## Exercices corrigés

### Exercice 1

Trouvez l’intervalle admissible.

> **Réponse:** L’intersection donne `[-2,1]`, pas seulement `[-2,2]`.

### Exercice 2

Projetez la proposition fixée.

> **Réponse:** La proposition `3` se projette sur `1` ; l’état suivant vaut `1` et la modification quadratique `4`.

### Exercice 3

Traitez le contrôle impossible.

> **Réponse:** La borne supérieure devient `-3`, sous la borne inférieure `-2`. L’intersection est vide ; action et état suivant restent `null`.

### Exercice 4

Que montre réellement le script du projet conservé ?

> **Réponse:** Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.

### Exercice 5

Quelles acceptations le corrigé peut-il clore ?

> **Réponse:** Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

## Critères apprenants préparés

Ces critères sont préparés ; chaque décision apprenante reste indécidée.

- Exercice 1: L’intersection donne `[-2,1]`, pas seulement `[-2,2]`.
- Exercice 2: La proposition `3` se projette sur `1` ; l’état suivant vaut `1` et la modification quadratique `4`.
- Exercice 3: La borne supérieure devient `-3`, sous la borne inférieure `-2`. L’intersection est vide ; action et état suivant restent `null`.
- Exercice 4: Il extrait métadonnées, titre et corps, puis indexe les identités des modules anglais. Sa lecture étaye cette représentation ; elle n’exécute pas le modèle et ne valide pas une fonctionnalité réelle.
- Exercice 5: Aucune acceptation humaine ou apprenante. Une tentative réelle exige sa réponse, l’assistance reçue et la correction ; le cas fini ne démontre ni le moteur natif, ni l’adoption, ni l’approbation d’une livraison.

[Dossier fixé de l’unité](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25-c/journal.md)
