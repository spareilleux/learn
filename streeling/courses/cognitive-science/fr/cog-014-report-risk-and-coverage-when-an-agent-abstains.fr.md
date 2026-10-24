---
module_id: "cog-014-report-risk-and-coverage-when-an-agent-abstains"
department: "cognitive-science"
course: "Présenter le risque et la couverture lorsqu’un agent s’abstient"
level: "intermediate"
prerequisites: ["cog-003-calibrating-fretboard-confidence"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Présenter le risque et la couverture lorsqu’un agent s’abstient

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un agent ne fournit que les réponses dont la confiance dépasse un seuil et annonce moins d’erreurs. Il peut simplement répondre à moins de questions. Le prérequis évalue la justesse probabiliste avec un score approprié ; ce cours évalue la sélection. Un classement par confiance peut servir à sélectionner sans que les nombres aient été validés comme probabilités. Le nom du champ ne suffit pas à établir la calibration.

Gardez tous les éléments candidats, abstentions comprises. La couverture divise les réponses acceptées par les éléments admissibles. Le risque conditionnel divise les erreurs acceptées par les réponses acceptées. Ces dénominateurs répondent à des questions différentes et il faut les deux pour interpréter une politique. Le seul nombre d’erreurs récompense le silence sans montrer le service retiré.

Le résumé des auteurs sur la classification sélective présente un compromis entre risque et couverture. Nous reprenons ce cadre pour une table finie, sans importer leurs résultats neuronaux ni leurs garanties probabilistes. Le seuil principal inclut l’égalité. Une réponse fausse très bien classée reste acceptée : sélectionner ne supprime pas le besoin d’une clé. Un seuil inférieur peut accroître ici le service et l’erreur ; cette direction n’est pas garantie pour des données arbitraires.

Le contrôle qui s’abstient toujours est essentiel. Sans réponse acceptée, le dénominateur du risque est vide. Conservez une valeur indéterminée au lieu d’un score parfait. Les observations du projet distinguent la confiance de recherche des résultats d’apprenants et ne fournissent pas notre vecteur de correction. Un essai devrait comparer la même tâche admissible en mode manuel, conserver les rejets et préciser le coût d’abstention avant de recommander un seuil.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cog-003-calibrating-fretboard-confidence](../../cognitive-science/en/cog-003-calibrating-fretboard-confidence.md)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire: Geifman and El-Yaniv, 1705.08500v2, 2017-06-01](https://arxiv.org/abs/1705.08500)

## Modèle fixé et contrôle

```json
{
  "values": {
    "confidence": [
      0.95,
      0.9,
      0.8,
      0.6,
      0.4
    ],
    "correct": [
      1,
      0,
      1,
      0,
      1
    ],
    "threshold": 0.8
  },
  "formula": "Accept when confidence>=threshold; coverage=accepted/n; risk=accepted_errors/accepted, null if accepted=0.",
  "expected": {
    "accepted_indices": [
      0,
      1,
      2
    ],
    "accepted": 3,
    "errors": 1,
    "coverage": 0.6,
    "risk": 0.3333333333333333
  },
  "negative_control": {
    "values": {
      "confidence": [
        0.95,
        0.9,
        0.8,
        0.6,
        0.4
      ],
      "correct": [
        1,
        0,
        1,
        0,
        1
      ],
      "threshold": 0.99
    },
    "expected": {
      "accepted_indices": [],
      "accepted": 0,
      "errors": 0,
      "coverage": 0,
      "risk": null
    },
    "why": "Abstaining on everything supplies no conditional error estimate, rather than perfect answers."
  },
  "assumptions": [
    "Correctness key is stipulated external and fixed.",
    "Equality at threshold is accepted; original item order retained."
  ],
  "limits": "Finite authored risk/coverage point, not calibrated confidence, statistical risk guarantee or measured GA use."
}
```

### Exercice 1

Quels indices sont acceptés au seuil déclaré, frontière comprise ?

<details><summary>Réponse 1</summary>

Les indices `[0,1,2]` sont acceptés. Il y a `3` réponses acceptées et `1` erreur. La confiance `0.8` est incluse car la comparaison utilise supérieur ou égal, sans inégalité stricte.

</details>

### Exercice 2

Calculez la couverture et le risque conditionnel du cas principal.

<details><summary>Réponse 2</summary>

La couverture vaut `0.6` ; le risque vaut `1/3=0.3333333333333333`. La première utilise tous les éléments admissibles, le second seulement les réponses émises. Gardez les dénominateurs explicites dans le bilan.

</details>

### Exercice 3

Que se passe-t-il sur cette table exacte si le seuil descend à `0.4` ?

<details><summary>Réponse 3</summary>

Les `5` éléments sont acceptés, la couverture vaut `1` et le risque `2/5=0.4`. Cette comparaison concerne un classement fixé, sans loi universelle de monotonie du risque conditionnel empirique.

</details>

### Exercice 4

Appliquez le contrôle d’abstention totale. Son risque est-il nul ?

<details><summary>Réponse 4</summary>

Non. La couverture vaut `0` et le risque `null`, car aucune réponse n’a été émise. Un dénominateur conditionnel vide ne fournit aucune estimation ; le qualifier de parfait récompenserait le refus de toute réponse.

</details>

### Exercice 5

Qu’est-ce qui justifierait une recommandation réelle de seuil ?

<details><summary>Réponse 5</summary>

Gardez la tâche admissible, la clé réelle, les réponses émises et retenues, les aides et le coût d’abstention. Comparez à la référence manuelle. Ni un score de recherche ni ces vecteurs inventés ne démontre une capacité d’apprenant ou une garantie de risque en production.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
