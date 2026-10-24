---
title: Conserver les résultats conjoints en composant des verdicts
description: Conserver les résultats conjoints en composant des verdicts — Théorie de l'information
sidebar:
  label: INF-010 · Conserver les résultats conjoints en composant des verdicts
  order: 10
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/information-theory/fr/inf-010-keep-joint-outcomes-when-composing-verdicts.fr.md
---

:::note[Streeling University]
**INF-010** · Conserver les résultats conjoints en composant des verdicts · intermédiaire · 45 minutes

Généré par le département *Théorie de l'information* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/information-theory/fr/inf-010-keep-joint-outcomes-when-composing-verdicts.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-008](../../computer-science/cs-008-compose-exact-source-review-verdicts/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cs-008-compose-exact-source-review-verdicts.md](../../computer-science/cs-008-compose-exact-source-review-verdicts/)
- [inf-003-verdict-distribution-drift.md](../../information-theory/inf-003-verdict-distribution-drift/)

Un tableau de bord Streeling affiche les mêmes taux de réussite pour deux contrôles obligatoires. Peut-on les multiplier pour estimer les cours ayant réussi les deux ? Il faut un modèle conjoint. Les reçus liés à des sources exactes définissent la portée des verdicts ; le cours sur leurs distributions examine les proportions marginales. Ici, nous conservons l'association des résultats au même artefact avant de composer une décision exigeant tous les contrôles.

Les cas construits ont les mêmes taux marginaux, mais associent autrement les étiquettes. Dans le premier, les réussites coïncident. Dans l'autre, beaucoup portent sur des artefacts différents. Construisez le tableau apparié avant son résumé. Chaque ligne représente la même identité de source sous les deux contrôles ; chaque artefact apparaît une seule fois. Associer des réussites arbitraires de versions différentes ne satisfait pas l'exigence du consommateur.

Relisez la distinction des types de revue dans le prérequis. Les verdicts technique et linguistique sont des affirmations distinctes ; notre modèle binaire les réduit volontairement à réussite ou échec pour l'arithmétique. Il n'authentifie personne et n'infère aucun avis d'apprenant absent. Même une réussite conjointe n'est que le résultat de la politique déclarée à deux contrôles. Elle n'autorise pas globalement la publication et ne représente pas tous les vrais jalons.

Le produit des taux marginaux correspond à une hypothèse d'indépendance. Les nombres appariés fournis déterminent directement le taux conjoint : les remplacer par ce produit jette une information disponible. L'estimation peut être trop basse ou trop haute selon l'association. Le contrôle négatif utilise un autre tableau construit pour respecter le produit. Il vérifie l'arithmétique sans prétendre découvrir l'indépendance dans les autres cas.

Pour le travail avec les sources, examinez les types de reçus du prérequis et reproduisez les deux tableaux à la main. Demandez à un assistant de calculer l'admissibilité conjointe sans multiplier sauf hypothèse explicite. Conservez les estimations erronées à côté des valeurs correctes. Rejetez une proposition de tableau de bord si elle attribue la même admissibilité aux deux cas au seul motif que leurs résumés marginaux coïncident.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "total": 10,
    "case_X": {
      "both_pass": 6,
      "A_only": 0,
      "B_only": 0,
      "both_fail": 4
    },
    "case_Y": {
      "both_pass": 2,
      "A_only": 4,
      "B_only": 4,
      "both_fail": 0
    }
  },
  "formula": "all_required_pass=both_pass/total; marginal_A=(both_pass+A_only)/total",
  "expected": {
    "A_rate": 0.6,
    "B_rate": 0.6,
    "X_joint_rate": 0.6,
    "Y_joint_rate": 0.2,
    "independence_product": 0.36,
    "X_product_error": -0.24,
    "Y_product_error": 0.16
  },
  "negative_control": "An explicitly independent authored table with total25 and cells9,6,6,4 gives joint9/25 equal to(15/25)^2.",
  "assumptions": [
    "Same ten fictional artifacts per table; paired verdicts use identical scope; all-input policy requires both passes."
  ],
  "limits": "No actual approval prevalence or independence is measured; valid verdicts still require identity and authority checks."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez les taux marginaux.

<details>
<summary>Réponse 1</summary>

Dans les deux cas, A et B réussissent chacun `6/10=0.6`.

</details>

### Exercice 2

Calculez les réussites conjointes.

<details>
<summary>Réponse 2</summary>

X donne `6/10=0.6` ; Y donne `2/10=0.2`.

</details>

### Exercice 3

Comparez l’estimation par produit.

<details>
<summary>Réponse 3</summary>

`0.6*0.6=0.36` ; estimation moins réalité : X `-0.24`, Y `0.16`.

</details>

### Exercice 4

Vérifiez le contrôle indépendant.

<details>
<summary>Réponse 4</summary>

Les cases `9,6,6,4` totalisent `25` ; `9/25=(15/25)^2=0.36`.

</details>

### Exercice 5

La réussite conjointe autorise-t-elle la publication ?

<details>
<summary>Réponse 5</summary>

Non. Identité, portée, autres jalons et autorité d’action restent des exigences distinctes.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
