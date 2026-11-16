---
module_id: "cyb-020-check-disturbance-robust-set-closure"
department: "cybernetics"
course: "Vérifier la fermeture d’un ensemble face aux perturbations"
title: "Vérifier la fermeture d’un ensemble face aux perturbations"
level: "intermediate"
prerequisites: ["cyb-013-bound-observation-age-before-a-control-decision"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Vérifier la fermeture d’un ensemble face aux perturbations

> Il s’agit d’un cas mathématique ou logique construit, appuyé par des passages de sources consultés. Revue technique humaine, relecture linguistique, tentatives apprenantes, exécution, adoption en production et publication restent indéterminées.

Un coordinateur Demerzel propose de maintenir le travail en attente dans un petit ensemble d’états admissibles. Une trajectoire calme ne prouve pas que la politique résiste à toutes les arrivées autorisées. Il faut demander si chaque état sûr revient dans cet ensemble pour toute perturbation permise. On transforme ainsi un exemple rassurant en argument de sûreté quantifié.

Déclarez d’abord l’ordre des opérations. Le contrôleur sert le travail existant, ramène le reste à zéro si nécessaire, puis ajoute les arrivées. Inverser cet ordre change le calcul aux limites. Énumérez les successeurs de chaque paire état-perturbation. Si aucun ne sort, l’ensemble est fermé pour cette transition. En partant à l’intérieur, les applications successives y restent par récurrence.

L’ensemble fixé autorise au plus autant d’arrivées que de service par étape. Le contrôle élargit les perturbations sans changer le contrôleur ni les états sûrs proposés. Un état limite possède alors un successeur extérieur. Gardez cette paire comme témoin au lieu de la noyer dans une moyenne d’arrivées favorables. Puisque le contrat couvre tous les cas permis, un témoin rare mais autorisé suffit.

Les notes distinguent les hypothèses d’ensemble au pire cas des contraintes probabilistes. Notre énumération n’a pas de distribution d’arrivées et ne donne donc aucune probabilité d’échec. Le prérequis sur l’âge d’observation borne une valeur actuelle ; ce cours vérifie si un ensemble reste sûr indéfiniment sous une transition connue. Aucun ne garantit le service réel d’une file. Avant de proposer une garde DSL, examinez le tableau manuel et les observations nécessaires pour justifier les bornes.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps, puis indexe les identités des modules anglais. Examinez cette représentation pour nommer l’artefact et sa révision. Elle n’implémente pas le modèle du cours et ne fournit aucune de ses entrées inventées.

[Prérequis: cyb-013-bound-observation-age-before-a-control-decision](../../cybernetics/en/cyb-013-bound-observation-age-before-a-control-decision.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire](https://underactuated.mit.edu/robust.html)

## Modèle fixé et contrôle négatif

```json
{
  "values": {
    "safe_states": [
      0,
      1,
      2
    ],
    "disturbances": [
      0,
      1
    ],
    "service": 1
  },
  "formula": "For every safe integer state q and disturbance d compute q_next=max(0,q-service)+d. Closed iff every successor belongs to safe_states. Sort escaping [q,d,q_next] triples lexicographically.",
  "expected": {
    "successor_set": [
      0,
      1,
      2
    ],
    "escaping": [],
    "closed": true
  },
  "negative_control": {
    "values": {
      "safe_states": [
        0,
        1,
        2
      ],
      "disturbances": [
        0,
        1,
        2
      ],
      "service": 1
    },
    "expected": {
      "successor_set": [
        0,
        1,
        2,
        3
      ],
      "escaping": [
        [
          2,
          2,
          3
        ]
      ],
      "closed": false
    },
    "why": "A larger allowed arrival breaks closure at the upper state."
  },
  "input_types": {
    "safe_states": "finite set of nonnegative integers",
    "disturbances": "finite set of nonnegative integers",
    "service": "nonnegative integer"
  },
  "assumptions": [
    "Service precedes arrivals on every step.",
    "Initial state is safe; disturbance always lies in the declared set; no hidden transition exists."
  ],
  "limits": "A conditional finite invariant is not a verified production queue bound or a stochastic tail guarantee."
}
```

### Exercice 1

Donnez l’ensemble des successeurs fixés.

<details><summary>Réponse 1</summary>

Il vaut `[0,1,2]`, inclus dans l’ensemble sûr. La liste des sorties vaut `[]` ; la fermeture vaut `true` selon l’ordre stipulé.

</details>

### Exercice 2

Trouvez la transition qui sort dans le contrôle.

<details><summary>Réponse 2</summary>

Le triplet `[2,2,3]` part de l’état sûr supérieur et aboutit dehors. Les successeurs sont `[0,1,2,3]` ; la fermeture vaut donc `false`.

</details>

### Exercice 3

Pourquoi la fermeture vaut-elle à tout horizon fini ?

<details><summary>Réponse 3</summary>

L’état initial est intérieur et chaque étape autorisée préserve l’appartenance. La récurrence la conserve après tout nombre fini d’étapes, tant que les hypothèses restent vraies.

</details>

### Exercice 4

Le tableau estime-t-il une probabilité de panne ?

<details><summary>Réponse 4</summary>

Non. Les perturbations sont des possibilités sans probabilités. La fermeture ou un témoin de sortie traite l’appartenance au pire cas, pas la fréquence des événements.

</details>

### Exercice 5

Que faut-il avant une adoption opérationnelle ?

<details><summary>Réponse 5</summary>

Des preuves de l’ordre des étapes, de la borne de service, des perturbations et de l’état initial, puis des vérifications des transitions omises. Une affirmation d’agent ne fournit pas ces prémisses.

</details>

## Travail avec consultation des sources

Évaluez une esquisse finie de sûreté du travail en attente avant une garde d’admission.

**Référence manuelle directe:** Énumérez à la main chaque successeur état-perturbation et son appartenance à l’ensemble.

**Critère de réfutation:** Une paire état-perturbation autorisée sort de l’ensemble annoncé invariant.

Enregistrez une première réponse avant d’ouvrir les corrigés. Repérez les types des entrées, le périmètre de comparaison et la quantité à préserver. Dessinez le plus petit tableau ou schéma qui permette de vérifier chaque résultat intermédiaire. Gardez un résultat inattendu : modifier les prémisses pour obtenir la conclusion souhaitée ferait disparaître le contre-exemple.

Lisez le prérequis et le passage primaire dans les limites indiquées. Notez la révision de la source, la définition réellement utilisée et les hypothèses reprises. L’artefact du projet fournit une représentation réelle à examiner ; le modèle fixé apporte des entrées inventées. Un nom de document ou une URL accessible n’établit pas un résultat de production. Précisez les observations nécessaires avant d’utiliser le calcul dans une décision opérationnelle.

Énoncez la référence manuelle directe et son critère de réfutation avant de proposer un DSL composable ou une abstraction d’agent. Demandez à un assistant de contester votre réponse manuelle après l’avoir enregistrée. Conservez la consigne, la réponse, le passage cité et la correction retenue ou rejetée. Une expression plus courte n’est utile que si elle préserve l’opération, le contrôle et la limite de refus. Comparez-la d’abord à un simple tableau.

Remettez ensemble réponse initiale, étapes intermédiaires, réponse corrigée et contrôle. Signalez la consultation des sources et l’usage d’une calculatrice comme des aides. Une future comparaison en dogfood doit porter sur la même version de la tâche et garder les échecs comme les réussites ; changer la question pourrait autrement passer pour un progrès. Les critères préparés ci-dessous restent indéterminés jusqu’à une tentative réelle. Un corrigé et une vérification d’auteur n’établissent ni apprentissage ni adoption.

## Critères préparés pour l’apprenant

- Exercice 1: Donnez l’ensemble des successeurs fixés. — Décision indéterminée.
- Exercice 2: Trouvez la transition qui sort dans le contrôle. — Décision indéterminée.
- Exercice 3: Pourquoi la fermeture vaut-elle à tout horizon fini ? — Décision indéterminée.
- Exercice 4: Le tableau estime-t-il une probabilité de panne ? — Décision indéterminée.
- Exercice 5: Que faut-il avant une adoption opérationnelle ? — Décision indéterminée.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25-b/journal.md)
