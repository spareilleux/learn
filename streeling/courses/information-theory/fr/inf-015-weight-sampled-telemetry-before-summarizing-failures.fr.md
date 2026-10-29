---
module_id: "inf-015-weight-sampled-telemetry-before-summarizing-failures"
department: "information-theory"
course: "Pondérer la télémétrie échantillonnée avant de résumer les échecs"
level: "intermediate"
prerequisites: ["inf-011-separate-compressed-size-from-preserved-information", "pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Pondérer la télémétrie échantillonnée avant de résumer les échecs

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un agent résume un échantillon de télémétrie comme si chaque événement avait la même chance d’y figurer. Une politique peut retenir les classes avec des probabilités différentes. Le prérequis sur la compression examine l’information conservée ; celui sur l’adoption fixe les unités d’événements et de cohortes. Ce cours ajoute la probabilité d’inclusion nécessaire à l’interprétation, au lieu de traiter les lignes visibles comme toute la population.

Attribuez à chaque événement conservé l’inverse de sa probabilité d’inclusion. Ces effectifs ajustés représentent les événements attribués à chaque observation selon le plan déclaré. Additionnez-les pour le total, puis gardez les contributions d’échec pour leur effectif ajusté. Le rapport constitue une estimation descriptive utile, sans être la moyenne des étiquettes binaires. Gardez la même unité et le même périmètre d’échantillonnage.

La spécification [OpenTelemetry](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/) nomme cette quantité inverse un effectif ajusté. Nos probabilités décimales sont construites, sans lecture de trace réelle ni décodage d’un champ de seuil. La source étaye la pondération ; elle ne fournit pas les probabilités GA et ne certifie pas la représentativité du petit échantillon. Le rapport de totaux estimés exige aussi une analyse d’incertitude avant toute affirmation forte sur la population.

Le contrôle à probabilités égales supprime la pondération inégale et fait coïncider les rapports. Des probabilités absentes ou nulles rendraient au contraire l’estimation indéfinie. Ne les remplacez pas après coup par des valeurs pratiques. Un résumé composable pourrait conserver les métadonnées d’inclusion ; reproduisez d’abord la table manuellement. Le dossier du projet énumère des champs de requête et distingue scores et rétention, sans fournir une population d’échecs utilisateurs à laquelle attribuer ces nombres inventés.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: inf-011-separate-compressed-size-from-preserved-information](../../information-theory/en/inf-011-separate-compressed-size-from-preserved-information.md)

[Prérequis: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire: OpenTelemetry specification 1.62.0 displayed, read 2026-10-24](https://opentelemetry.io/docs/specs/otel/trace/tracestate-handling/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "sampled_failures": [
      1,
      0,
      0
    ],
    "inclusion_probabilities": [
      0.5,
      0.25,
      0.25
    ]
  },
  "formula": "weight_i=1/p_i; adjusted_total=sum(weight_i); adjusted_failures=sum(weight_i*failure_i); ratio=adjusted_failures/adjusted_total; raw_rate=sum(failure_i)/n.",
  "expected": {
    "weights": [
      2,
      4,
      4
    ],
    "adjusted_total": 10,
    "adjusted_failures": 2,
    "weighted_ratio": 0.2,
    "raw_rate": 0.3333333333333333
  },
  "negative_control": {
    "values": {
      "sampled_failures": [
        1,
        0,
        0
      ],
      "inclusion_probabilities": [
        1,
        1,
        1
      ]
    },
    "expected": {
      "weights": [
        1,
        1,
        1
      ],
      "adjusted_total": 3,
      "adjusted_failures": 1,
      "weighted_ratio": 0.3333333333333333,
      "raw_rate": 0.3333333333333333
    },
    "why": "Equal inclusion weights make the weighted ratio equal the raw sample rate."
  },
  "assumptions": [
    "Positive known inclusion probabilities correspond to each retained event.",
    "Failure indicators refer to one declared event unit."
  ],
  "limits": "Adjusted counts and ratio are estimates; this finite ratio is not promised unbiased and does not reveal exact population failures."
}
```

### Exercice 1

Calculez le poids de chaque événement échantillonné.

<details><summary>Réponse 1</summary>

Les poids valent `[2,4,4]`, inverses des probabilités d’inclusion. Ce sont des effectifs ajustés, sans unité de millisecondes, de confiance ni copies d’événements réels de la population.

</details>

### Exercice 2

Calculez total ajusté, échecs ajustés et leur rapport.

<details><summary>Réponse 2</summary>

Le total vaut `10`, les échecs `2` et le rapport `0.2`. Seul le premier événement contribue aux échecs. Ces quantités restent des estimations sous le plan supposé.

</details>

### Exercice 3

Comparez le taux brut et expliquez l’écart.

<details><summary>Réponse 3</summary>

Le taux brut vaut `1/3=0.3333333333333333`. Il donne le même poids à chaque ligne. Le rapport pondéré donne plus de contribution aux événements corrects moins probables, d’où l’écart dans cet échantillon construit.

</details>

### Exercice 4

Appliquez le contrôle à probabilités égales.

<details><summary>Réponse 4</summary>

Les poids deviennent `[1,1,1]`, le total `3`, les échecs `1` et le rapport `0.3333333333333333`, égal au taux brut. Des poids positifs égaux se simplifient dans ce rapport.

</details>

### Exercice 5

Peut-on annoncer ce rapport comme le taux exact d’échec en production ?

<details><summary>Réponse 5</summary>

Non. La population n’est pas observée, les probabilités sont stipulées et l’incertitude finie demeure. Une probabilité absente laisse le calcul indéterminé. Gardez les métadonnées et ne prétendez pas qu’un rapport de totaux estimés est automatiquement sans biais.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
