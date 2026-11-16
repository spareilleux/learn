---
module_id: "cs-020-audit-evidence-join-multiplicity"
department: "computer-science"
course: "Auditer la multiplicité d’une jointure de preuves"
level: "intermediate"
prerequisites: ["cs-008-compose-exact-source-review-verdicts", "inf-010-keep-joint-outcomes-when-composing-verdicts"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Auditer la multiplicité d’une jointure de preuves

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un agent combine une table de revues avec une table de tests et présente le nombre de lignes jointes comme le nombre d’artefacts validés. Une jointure peut produire plus de lignes que chacune de ses entrées, car chaque paire correspondante est conservée. Le prérequis sur les revues vérifie les octets désignés ; celui sur les résultats conjoints conserve les verdicts appariés. Ce cours ajoute une question différente : la multiplicité créée lorsque plusieurs reçus partagent une clé.

Écrivez les paires revue/test de chaque artefact avant de compter. Plusieurs revues et plusieurs tests d’un même artefact produisent leurs combinaisons cartésiennes. Ces lignes facilitent parfois la navigation, mais elles ne constituent ni de nouveaux artefacts, ni de nouveaux réviseurs, ni des exécutions indépendantes. Calculer ensuite un taux de réussite sur la table aplatie peut pondérer silencieusement chaque artefact selon son nombre de reçus.

La documentation SELECT de [SQLite](https://www.sqlite.org/lang_select.html) définit les jointures à partir d’un produit cartésien filtré par des contraintes. Nos tables utilisent cette interprétation en multiensemble sans exécuter de base de données. L’utilitaire Learn conserve plutôt un ensemble de clés de modules. Son insertion montre une représentation dont le comptage a un autre sens : l’appartenance ne conserve pas les combinaisons nécessaires à l’audit des reçus. Aucune représentation n’est toujours préférable ; la question du projet fixe l’unité comptée.

La provenance [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) distingue les entités, les activités et leurs relations. Attachez les identités des reçus initiaux aux lignes jointes pour retrouver cette distinction. Le contrôle supprime un test tout en conservant la couverture des artefacts. Un rapport qui prétend que des artefacts ont disparu parce que le nombre de lignes baisse confond multiplicité et couverture. Toute jointure DSL proposée doit préciser sa clé, sa sémantique des lignes et son unité d’agrégation avant la rédaction du bilan.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cs-008-compose-exact-source-review-verdicts](../../computer-science/en/cs-008-compose-exact-source-review-verdicts.md)

[Prérequis: inf-010-keep-joint-outcomes-when-composing-verdicts](../../information-theory/en/inf-010-keep-joint-outcomes-when-composing-verdicts.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire: SQLite SELECT documentation, section 2.1, read 2026-10-24](https://www.sqlite.org/lang_select.html)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "left": [
      {
        "artifact": "a",
        "review": "r1"
      },
      {
        "artifact": "a",
        "review": "r2"
      },
      {
        "artifact": "b",
        "review": "r3"
      }
    ],
    "right": [
      {
        "artifact": "a",
        "check": "t1"
      },
      {
        "artifact": "a",
        "check": "t2"
      },
      {
        "artifact": "b",
        "check": "t3"
      }
    ]
  },
  "formula": "Inner equality join on artifact emits every matching row pair; count rows and distinct artifact keys separately.",
  "expected": {
    "joined_rows": 5,
    "distinct_artifacts": 2,
    "rows_per_artifact": {
      "a": 4,
      "b": 1
    }
  },
  "negative_control": {
    "values": {
      "left": [
        {
          "artifact": "a",
          "review": "r1"
        },
        {
          "artifact": "a",
          "review": "r2"
        },
        {
          "artifact": "b",
          "review": "r3"
        }
      ],
      "right": [
        {
          "artifact": "a",
          "check": "t1"
        },
        {
          "artifact": "b",
          "check": "t3"
        }
      ]
    },
    "expected": {
      "joined_rows": 3,
      "distinct_artifacts": 2,
      "rows_per_artifact": {
        "a": 2,
        "b": 1
      }
    },
    "why": "Removing one check changes join multiplicity without changing artifact coverage."
  },
  "assumptions": [
    "Bag semantics; exact equality on retained artifact key.",
    "Review rows and check rows are not assumed independent trials."
  ],
  "limits": "Artifact key is simplified; real matching also requires revision and scope. No query or production data was executed."
}
```

### Exercice 1

Combien de lignes jointes chaque artefact fournit-il ?

<details><summary>Réponse 1</summary>

L’artefact `a` fournit `4` paires et `b` en fournit `1`, soit `5` lignes. Chaque revue d’un artefact s’apparie avec chacun de ses tests ; ce n’est pas une ligne par artefact.

</details>

### Exercice 2

Combien d’artefacts distincts sont représentés ? Le nombre de lignes prouve-t-il une revue indépendante ?

<details><summary>Réponse 2</summary>

Il y a `2` artefacts distincts. Les lignes répètent les mêmes reçus dans plusieurs combinaisons. Elles ne créent ni identité de réviseur, ni garantie d’indépendance, ni exécution supplémentaire.

</details>

### Exercice 3

Appliquez le contrôle qui retire un test. Qu’est-ce qui change et qu’est-ce qui reste égal ?

<details><summary>Réponse 3</summary>

Le total passe à `3` lignes : `2` pour `a` et `1` pour `b`. Le nombre d’artefacts distincts reste `2`. La multiplicité change, tandis que la couverture selon cette clé reste identique.

</details>

### Exercice 4

Pourquoi un pourcentage sur les lignes jointes peut-il déformer un bilan par artefact ?

<details><summary>Réponse 4</summary>

Un artefact disposant de plus de reçus reçoit plus de poids. Précisez si le dénominateur compte les artefacts, les revues, les tests ou les paires avant l’agrégation. Un calcul juste ne répare pas une unité implicite.

</details>

### Exercice 5

Que faut-il ajouter avant d’utiliser cette clé simplifiée pour des preuves liées aux octets exacts ?

<details><summary>Réponse 5</summary>

Conservez la révision et le périmètre des reçus avec l’identité de l’artefact, puis vérifiez manuellement la correspondance voulue. Cette table n’autorise ni à joindre des révisions différentes ni à transformer une déclaration en observation d’exécution.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
