---
module_id: "inf-017-merge-sum-count-summaries-before-taking-means"
department: "information-theory"
course: "Fusionner sommes et effectifs avant de calculer les moyennes"
level: "intermediate"
prerequisites: ["inf-015-weight-sampled-telemetry-before-summarizing-failures"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Fusionner sommes et effectifs avant de calculer les moyennes

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Des étapes parallèles résument des nombres différents d’éléments Learn fictifs. Faire la moyenne de leurs moyennes donne le même poids aux étapes et des poids différents aux éléments. Le prérequis corrige des probabilités d’observation inégales ; ici tous les éléments sont présents et seul leur partitionnement pose problème.

Conservez une somme et un effectif comme résumé composable. Leur addition composante par composante possède un élément neutre vide et préserve le total quand on regroupe des partitions disjointes. Ne divisez qu’après fusion. La lecture SELECT de SQLite distingue lignes d’entrée et agrégats ; elle ne justifie pas de remplacer les éléments par les travailleurs comme unité moyenne.

Le cas principal est déséquilibré. Le contrôle répartit les mêmes valeurs en groupes de même taille : la méthode naïve donne alors le bon résultat et cache l’erreur. Un DSL d’agent doit préciser les questions auxquelles son résumé répond. Somme et effectif donnent une moyenne, mais pas les identités individuelles ni la médiane exacte. La compacité se juge selon la question du destinataire.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: inf-015-weight-sampled-telemetry-before-summarizing-failures](../../information-theory/en/inf-015-weight-sampled-telemetry-before-summarizing-failures.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.sqlite.org/lang_select.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "partitions": [
      [
        2
      ],
      [
        4,
        6,
        8
      ]
    ]
  },
  "formula": "Each partition summary=(sum,count). Merge by componentwise addition; mean=total_sum/total_count. Naive mean averages nonempty partition means with equal partition weights.",
  "expected": {
    "summaries": [
      [
        2,
        1
      ],
      [
        18,
        3
      ]
    ],
    "merged": [
      20,
      4
    ],
    "mean": 5,
    "naive_mean": 4
  },
  "negative_control": {
    "values": {
      "partitions": [
        [
          2,
          4
        ],
        [
          6,
          8
        ]
      ]
    },
    "expected": {
      "summaries": [
        [
          6,
          2
        ],
        [
          14,
          2
        ]
      ],
      "merged": [
        20,
        4
      ],
      "mean": 5,
      "naive_mean": 5
    },
    "why": "Equal-sized partitions hide the naive reducer error; the unequal main case exposes it."
  },
  "assumptions": [
    "Disjoint partitions cover the same exact numeric items once.",
    "Arithmetic exact; empty summary is [0,0] and final empty mean undefined."
  ],
  "limits": "Sufficient only for arithmetic mean, not variance, quantiles, identity audits or unbiased population estimates.",
  "input_types": {
    "partitions": "list<list<real>>"
  }
}
```

### Exercice 1

Calculez les résumés des partitions.

<details><summary>Réponse 1</summary>

Ils valent `[2,1]` et `[18,3]`, dans l’ordre somme puis effectif. Précisez unités et ordre.

</details>

### Exercice 2

Fusionnez et calculez la moyenne globale.

<details><summary>Réponse 2</summary>

La paire fusionnée est `[20,4]`, donc la moyenne vaut `5`. La taille de chaque partition fixe sa contribution.

</details>

### Exercice 3

Calculez la moyenne naïve des moyennes.

<details><summary>Réponse 3</summary>

Les moyennes valent `2` et `6` ; leur moyenne équipondérée vaut `4`. Elle répond à une autre pondération.

</details>

### Exercice 4

Appliquez le contrôle équilibré.

<details><summary>Réponse 4</summary>

Les résumés `[6,2]` et `[14,2]` donnent `[20,4]`. Les deux méthodes donnent `5` ; ce contrôle seul manque l’erreur.

</details>

### Exercice 5

La paire permet-elle une médiane exacte ?

<details><summary>Réponse 5</summary>

Non. Plusieurs collections ont la même somme et le même effectif. Gardez davantage de données pour les questions d’ordre ou d’identité.

</details>

## Travail avec consultation des sources

Préparez une fiche de résumé composable de durées fictives de revue Learn sans créer de réducteur exécutable.

**Référence manuelle directe:** Calculez les sommes et effectifs sur papier, additionnez les paires et divisez une seule fois.

**Critère de réfutation:** Déplacer seulement les frontières des partitions change la moyenne annoncée des éléments.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
