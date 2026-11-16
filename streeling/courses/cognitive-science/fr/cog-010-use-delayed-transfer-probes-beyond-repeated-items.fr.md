---
module_id: "cog-010-use-delayed-transfer-probes-beyond-repeated-items"
department: "cognitive-science"
course: "Utiliser des épreuves différées de transfert au-delà des items répétés"
title: "Utiliser des épreuves différées de transfert au-delà des items répétés"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success", "cog-008-choose-probes-that-distinguish-reasoning-models"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Utiliser des épreuves différées de transfert au-delà des items répétés

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cog-007-separate-unaided-recall-from-assisted-success.md](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)
- [cog-008-choose-probes-that-distinguish-reasoning-models.md](../../cognitive-science/en/cog-008-choose-probes-that-distinguish-reasoning-models.md)

Un agent de pratique annonce de bons résultats parce que l'apprenant répond correctement à des consignes répétées. L'équipe veut savoir s'il saura appliquer la même règle à un nouveau voicing plus tard. Ces questions exigent des observations distinctes. Le prérequis sur l'assistance conserve l'historique des indices, et celui sur les épreuves demande si une réponse distingue les règles candidates. Ce cours organise ces distinctions selon l'exposition et le délai d'évaluation.

Le dossier fixe contient des nombres fictifs. Les items répétés immédiats, répétés différés et nouveaux différés ont chacun leur dénominateur. Nouveau signifie que la consigne exacte n'a pas été pratiquée selon la définition déclarée ; cela ne garantit pas que toutes ses caractéristiques soient inconnues. Une affirmation de transfert doit préciser ce qui change et la règle qui reste applicable. Sans cela, un score différé pourrait simplement mesurer la reconnaissance d'une même réponse.

Une réponse correcte à un item nouveau a été précédée de l'affichage de la réponse. Elle est inadmissible pour notre critère sans aide : retirez-la du nombre de réussites comme du nombre d'observations admissibles. Gardez les nombres bruts et la cause d'exclusion. Une réussite exclue ne devient pas une erreur observée. Aucun total d'items manquants n'est fourni ; ces taux observés ne représentent donc pas toutes les personnes invitées.

Comparez descriptivement les taux immédiat et différé sur items répétés. Leur différence ne mesure pas un oubli causé par le temps : le modèle n'a ni historiques individuels ni preuve d'affectation. Le taux sur items nouveaux n'est pas davantage un effet causal de transfert produit par GA. Le contrôle négatif utilise seulement des consignes répétées. Il peut établir une réussite sur celles-ci selon sa règle, mais pas créer une observation sur un item nouveau.

Pour le travail avec les sources, examinez les exclusions liées à l'assistance et la distinction entre modèles de prédiction. Concevez deux épreuves de voicing GA où le doigté de surface change tandis que le raisonnement requis est nommé. Déclarez délai et politique d'exposition avant toute tentative. La référence manuelle croise catégorie, délai, admissibilité et réponse. Demandez à un assistant si l'item supposé nouveau révèle sa réponse. Rejetez une affirmation de transfert fondée uniquement sur des répétitions ou sur des réponses assistées rebaptisées sans aide.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "immediate_repeated": {
      "correct": 8,
      "observed": 10
    },
    "delayed_repeated": {
      "correct": 6,
      "observed": 10
    },
    "delayed_novel": {
      "correct": 3,
      "observed": 8
    },
    "novel_exposed_correct": 1
  },
  "formula": "rate=eligible correct/eligible observed; remove exposed item from both numerator and denominator",
  "expected": {
    "immediate_rate": 0.8,
    "delayed_repeated_rate": 0.6,
    "raw_novel_rate": 0.375,
    "eligible_novel_correct": 2,
    "eligible_novel_observed": 7,
    "eligible_novel_rate_fraction": "2/7",
    "repeated_rate_change": -0.2
  },
  "negative_control": "Repeating identical prompts cannot supply evidence of novel-item transfer.",
  "assumptions": [
    "Fictional counts, same rubric, declared delay, observed items only; exposed novel item is correct and ineligible."
  ],
  "limits": "No real learning, causal effect, optimal delay or psychometric validity is inferred."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez les taux sur items répétés.

<details>
<summary>Réponse 1</summary>

Immédiat `8/10=0.8` ; différé `6/10=0.6` ; variation `-0.2`.

</details>

### Exercice 2

Calculez le taux brut sur items nouveaux.

<details>
<summary>Réponse 2</summary>

`3/8=0.375`, avant exclusion de l’exposition à la réponse.

</details>

### Exercice 3

Appliquez l’exclusion liée à l’exposition.

<details>
<summary>Réponse 3</summary>

Réussites admissibles `2`, observations `7`, taux `2/7` ; conservez la réussite exclue.

</details>

### Exercice 4

Le contrôle limité aux répétitions démontre-t-il le transfert ?

<details>
<summary>Réponse 4</summary>

Non. Il ne contient aucune observation d’item nouveau selon la définition déclarée.

</details>

### Exercice 5

Que doit conserver le relevé réel de l’apprenant ?

<details>
<summary>Réponse 5</summary>

Identité, caractéristiques modifiées, délai, réponse, aide et admissibilité ; aucun effet causal n’est fourni.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
