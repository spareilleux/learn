---
module_id: "cog-012-separate-review-alert-hit-rate-from-response-bias"
department: "cognitive-science"
course: "Distinguer le taux de détection des alertes et la tendance à répondre"
level: "intermediate"
prerequisites: ["cog-011-measure-rubric-disagreement-before-adjudication"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguer le taux de détection des alertes et la tendance à répondre

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un assistant de revue repère presque tous les défauts introduits et passe pour très sensible. Il peut aussi signaler presque tous les éléments corrects. Le prérequis compare des réviseurs sans déterminer lequel a raison. Ce cours fournit une clé externe explicite et examine les réponses conditionnellement à cette clé. Être d’accord avec un autre réviseur et détecter un défaut réel constituent des critères différents.

Placez le statut réel en lignes et la décision d’alerte en colonnes, selon la définition officielle de la matrice de confusion. Une détection appartient à la ligne des défauts ; une fausse alerte à celle des éléments corrects. Leurs dénominateurs doivent donc différer. La fréquence globale d’alerte mélange les deux lignes et dépend de la proportion de défauts. L’appeler sensibilité masquerait cette dépendance.

Nous utilisons la différence entre détections et fausses alertes comme mesure descriptive déclarée de séparation. Ce n’est pas la sensibilité d’un modèle gaussien de détection du signal et cela n’identifie aucun mécanisme psychologique. Une tendance à répondre oui peut déplacer les deux taux. Le contrôle qui alerte toujours est utile : sa détection parfaite coexiste avec une séparation nulle. Il montre ce que le résumé omet sans imposer de modèle de distribution.

Le dossier GA conservé précise qu’une confiance affichée est un score de recherche et que les données choisies ne contiennent aucune réponse d’apprenant. Il ne fournit ni clé externe ni réponses réelles pour ce cas. Un futur essai doit conserver les éléments corrects et défectueux, la clé arbitrée, les alertes initiales et les aides. Calculez d’abord la table à la main, puis contestez tout bilan qui transforme le seul taux de détection en preuve de meilleur jugement.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cog-011-measure-rubric-disagreement-before-adjudication](../../cognitive-science/en/cog-011-measure-rubric-disagreement-before-adjudication.md)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire: scikit-learn 1.9.1 documentation, read 2026-10-24](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.confusion_matrix.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "true_positive": 8,
    "false_negative": 2,
    "false_positive": 4,
    "true_negative": 6
  },
  "formula": "hit=TP/(TP+FN); false_alarm=FP/(FP+TN); alert=(TP+FP)/N; accuracy=(TP+TN)/N; separation=hit-false_alarm.",
  "expected": {
    "hit_rate": 0.8,
    "false_alarm_rate": 0.4,
    "alert_rate": 0.6,
    "accuracy": 0.7,
    "separation": 0.4
  },
  "negative_control": {
    "values": {
      "true_positive": 10,
      "false_negative": 0,
      "false_positive": 10,
      "true_negative": 0
    },
    "expected": {
      "hit_rate": 1,
      "false_alarm_rate": 1,
      "alert_rate": 1,
      "accuracy": 0.5,
      "separation": 0
    },
    "why": "Alerting on every item maximizes hits while destroying discrimination under this rate contrast."
  },
  "assumptions": [
    "Independent external defect key is stipulated correct.",
    "Positive means flagging a defect; both true classes are nonempty."
  ],
  "limits": "Authored confusion table, not a human sensitivity estimate or evidence of psychological response bias; no signal-distribution model is assumed."
}
```

### Exercice 1

Calculez les taux de détection et de fausse alerte avec leurs dénominateurs propres.

<details><summary>Réponse 1</summary>

La détection vaut `8/10=0.8` ; la fausse alerte vaut `4/10=0.4`. Les deux conditionnent sur le statut réel. Diviser par toute la collection répondrait à une autre question de fréquence conjointe.

</details>

### Exercice 2

Calculez fréquence d’alerte, exactitude et séparation déclarée.

<details><summary>Réponse 2</summary>

Elles valent `0.6`, `0.7` et `0.4`. La fréquence compte les décisions de signaler ; l’exactitude compte les accords avec la clé ; la séparation compare les taux conditionnels. Aucun n’est un trait psychologique mesuré.

</details>

### Exercice 3

Appliquez le contrôle qui alerte toujours. Que devient le taux de détection apparemment excellent ?

<details><summary>Réponse 3</summary>

La détection vaut `1`, mais la fausse alerte aussi `1`, l’exactitude `0.5` et la séparation `0`. Repérer tous les défauts ne prouve pas la discrimination lorsque tous les éléments corrects sont signalés.

</details>

### Exercice 4

Le tableau d’accord des réviseurs du prérequis donnerait-il la même conclusion ?

<details><summary>Réponse 4</summary>

Non. L’accord nécessite des étiquettes appariées ; ce calcul exige une clé externe de correction. Deux réviseurs peuvent approuver la même mauvaise alerte, et la clé arbitrée peut elle-même nécessiter une validation indépendante.

</details>

### Exercice 5

Que faut-il conserver avant de discuter un biais de réponse dans une étude réelle ?

<details><summary>Réponse 5</summary>

Gardez statut des défauts, alertes initiales, composition des éléments, construction de la clé, consignes et aides. Ces taux motivent une question sur les réponses, sans diagnostiquer la cognition ni établir un progrès en production à partir de nombres inventés.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
