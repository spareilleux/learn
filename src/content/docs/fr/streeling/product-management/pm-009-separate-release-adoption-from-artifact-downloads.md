---
title: Distinguer adoption d’une version et téléchargements
description: Distinguer adoption d’une version et téléchargements — Gestion de produit et de projet
sidebar:
  label: PM-009 · Distinguer adoption d’une version et téléchargements
  order: 9
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-009-separate-release-adoption-from-artifact-downloads.fr.md
---

:::note[Streeling University]
**PM-009** · Distinguer adoption d’une version et téléchargements · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-009-separate-release-adoption-from-artifact-downloads.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-002](../../product-management/pm-002-release-evidence-gate/), [PM-006](../../product-management/pm-006-test-a-pilot-against-its-decision-horizon/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [pm-002-release-evidence-gate.md](../../product-management/pm-002-release-evidence-gate/)
- [pm-006-test-a-pilot-against-its-decision-horizon.md](../../product-management/pm-006-test-a-pilot-against-its-decision-horizon/)

Un artefact de version reçoit beaucoup de téléchargements et un agent annonce une large adoption. Ces événements peuvent inclure relances, automatisation, miroirs et personnes hors de la cohorte cible. Un jalon de version indique si l'artefact est prêt ou accessible ; il ne fournit pas le dénominateur d'usage. Le prérequis sur l'horizon demande quelles décisions réutilisent une preuve. Ici, nous précisons quelles personnes et actions relèvent de l'adoption.

Le dossier donne des nombres fictifs d'événements et d'utilisateurs dans une fenêtre fixe. La cohorte active admissible est définie séparément des personnes ayant téléchargé. Les utilisateurs ayant activé la version appartiennent à cette cohorte ; les tentatives appartiennent aux activations et les réussites aux tentatives. Ces inclusions autorisent les rapports indiqués. La population des téléchargements n'est pas la cohorte déclarée : la substituer au dénominateur changerait la question.

L'adoption signifie ici activer la version dans la cohorte active admissible. C'est un critère pédagogique, pas une définition universelle. Donnez séparément couverture des tentatives et réussite observée. Une fonction activée peut rester inutilisée ; une tâche réussie ne prouve ni usage durable ni apprentissage. Adopter ensuite un critère plus strict exige un autre numérateur et une frontière de comparaison explicite.

Le rapport téléchargements/cohorte se calcule, mais son unité est événements par membre. Ce n'est pas une proportion d'utilisateurs ayant adopté : les événements se répètent et peuvent venir de l'extérieur. Même le nombre de personnes ayant téléchargé peut dépasser celui de la cohorte. Un tableau de bord doit conserver ces unités au lieu de plafonner un pourcentage incohérent et de croire le problème résolu.

Le contrôle négatif augmente les téléchargements miroirs sans changer les actions de la cohorte. Les rapports d'adoption et de tâche restent identiques. Pour le travail avec les sources, examinez les distinctions du cours sur les jalons et rédigez une fiche donnant version, cohorte, fenêtre, unité d'événement et résultat. Calculez les rapports à la main avant de demander une phrase de statut à un assistant. Rejetez-la si elle confond accessibilité publique et usage ou prétend tirer une télémétrie réelle de ces nombres construits.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "download_events": 120,
    "distinct_downloaders": 70,
    "eligible_active_cohort": 50,
    "enabled_in_cohort": 30,
    "task_attempted_in_enabled_cohort": 18,
    "task_success_in_attempted": 12
  },
  "formula": "adoption=enabled_in_cohort/eligible_active_cohort; attempted_coverage=attempted/enabled; observed_task_success=success/attempted",
  "expected": {
    "adoption": 0.6,
    "attempted_coverage": 0.6,
    "task_success_fraction": "2/3",
    "cohort_task_success_rate": 0.24,
    "downloads_per_cohort_member": 2.4
  },
  "negative_control": "A mirrored artifact can have more download events without any change in the eligible cohort or enabled users.",
  "assumptions": [
    "Fictional counts in one fixed window, stable release and cohort identity, nested enabled/attempted/success sets, downloader set not identical to eligible cohort."
  ],
  "limits": "No real telemetry, causal benefit, retention, sustained adoption or user-learning improvement was measured."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez le taux d’adoption défini.

<details>
<summary>Réponse 1</summary>

`30/50=0.6` dans la cohorte active admissible.

</details>

### Exercice 2

Calculez la couverture des tentatives.

<details>
<summary>Réponse 2</summary>

`18/30=0.6` parmi les membres ayant activé la version.

</details>

### Exercice 3

Calculez la réussite avec les deux dénominateurs.

<details>
<summary>Réponse 3</summary>

Parmi les tentatives `12/18=2/3` ; dans toute la cohorte `12/50=0.24`.

</details>

### Exercice 4

Interprétez téléchargements divisés par taille de cohorte.

<details>
<summary>Réponse 4</summary>

`120/50=2.4` événements par membre ; ce n’est pas une proportion d’adoption.

</details>

### Exercice 5

Évaluez le contrôle de téléchargements miroirs.

<details>
<summary>Réponse 5</summary>

Les rapports restent identiques car tous les numérateurs et dénominateurs de cohorte restent fixes.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
