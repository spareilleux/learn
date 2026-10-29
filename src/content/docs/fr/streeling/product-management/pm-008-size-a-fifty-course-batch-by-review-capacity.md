---
title: Dimensionner un lot de cinquante cours selon la capacité de revue
description: Dimensionner un lot de cinquante cours selon la capacité de revue — Gestion de produit et de projet
sidebar:
  label: PM-008 · Dimensionner un lot de cinquante cours selon la capacité de revue
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-008-size-a-fifty-course-batch-by-review-capacity.fr.md
---

:::note[Streeling University]
**PM-008** · Dimensionner un lot de cinquante cours selon la capacité de revue · intermédiaire · 45 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-008-size-a-fifty-course-batch-by-review-capacity.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-003](../../product-management/pm-003-review-queue-flow-metrics/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [pm-003-review-queue-flow-metrics.md](../../product-management/pm-003-review-queue-flow-metrics/)
- [pm-002-release-evidence-gate.md](../../product-management/pm-002-release-evidence-gate/)
- [production-plan.md](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/production-plan.md)
- [batch-plan.json](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/batch-plan.json)

La demande actuelle fixe un lot de cours distincts ; les traductions ajoutent des sources, pas des cours. Quelle revue cette portée exige-t-elle ? Le prérequis sur les files explique pourquoi un inventaire n'est pas un débit. Ce cours utilise la taille réellement demandée et des minutes de revue explicitement fictives pour identifier le rôle limitant un planning proposé. Le nombre d'agents rédacteurs ne mesure aucune disponibilité humaine.

Lisez le plan de production et le manifeste comme autorité de portée. Dans ce scénario pédagogique, comptez une revue technique par cours anglais, une revue linguistique par source traduite et un travail d'apprenant par cours. La charge linguistique exclut la revue technique de la langue source, déjà comptée séparément. Ce sont des hypothèses de planification, pas l'affirmation que tous les cours prennent autant de temps ni qu'une tentative d'apprenant suffit à l'acceptation.

Multipliez la portée par le temps unitaire avant de diviser par la capacité. Gardez minutes, sources, cours et jours visibles. Additionner toutes les minutes disponibles masque les spécialités : du temps linguistique libre ne réalise pas automatiquement le travail technique ou apprenant. La fin parallèle optimiste est la plus longue durée de rôle, avec disponibilité simultanée et travail divisible. Dépendances, calendriers partiels, échecs et nouvelles tentatives exigeraient un scénario plus précis ; ils ne sont pas mesurés ici.

Le dossier compte aussi les couples exercice-réponse localisés et les critères d'apprenant préparés. Ce sont des obligations de rédaction et de contrôle, pas des observations achevées. Un critère reste indécidé jusqu'à disposer d'une réponse réelle et de son historique d'aide. Accélérer la rédaction n'autorise donc pas à annoncer des cours revus. Conservez constats et reprises au lieu d'effacer les jalons échoués pour afficher le débit prévu comme acquis.

Pour le travail avec les sources, réconciliez manuellement les nombres de modules et de langues du manifeste, puis construisez le tableau des charges avec les taux stipulés. Demandez à un assistant les goulets et mesures manquantes. La référence directe est ce tableau, sans DSL d'ordonnancement. Le contrôle à capacité nulle doit empêcher toute promesse finie pour le rôle requis. Rejetez une annonce utilisant ces minutes fictives comme capacité observée ou comptant les traductions comme cours distincts.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "courses": 50,
    "locales": 3,
    "translated_sources": 100,
    "exercises_per_course": 5,
    "subject_minutes_per_course": 20,
    "language_minutes_per_translation": 12,
    "learner_minutes_per_course": 25,
    "subject_minutes_per_day": 100,
    "language_minutes_per_day": 200,
    "learner_minutes_per_day": 125
  },
  "formula": "role_work=scope*minutes_per_item; role_days=role_work/role_capacity; optimistic_parallel_days=max(role_days)",
  "expected": {
    "sources": 150,
    "localized_answer_pairs": 750,
    "prepared_learner_criteria": 250,
    "subject_minutes": 1000,
    "language_minutes": 1200,
    "learner_minutes": 1250,
    "total_minutes": 3450,
    "subject_days": 10,
    "language_days": 6,
    "learner_days": 10,
    "optimistic_parallel_days": 10
  },
  "negative_control": "Zero capacity in any required role admits no finite completion estimate for its positive work.",
  "assumptions": [
    "Actual requested fifty-course scope; all durations/capacities fictional, dedicated roles, divisible work, parallel availability, no rework or waiting."
  ],
  "limits": "Capacity planning scenario, not a deadline, measured team rate, completed review or learner result."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Comptez sources, couples localisés et critères préparés.

<details>
<summary>Réponse 1</summary>

`50*3=150` sources ; `50*3*5=750` couples ; `50*5=250` critères.

</details>

### Exercice 2

Calculez les charges par rôle.

<details>
<summary>Réponse 2</summary>

Technique `50*20=1000`, langues `100*12=1200`, apprenant `50*25=1250` minutes ; total `3450`.

</details>

### Exercice 3

Calculez les durées et la borne parallèle.

<details>
<summary>Réponse 3</summary>

Technique `10`, langues `6`, apprenant `10` jours ; borne parallèle optimiste `10` jours.

</details>

### Exercice 4

Évaluez un rôle requis sans capacité.

<details>
<summary>Réponse 4</summary>

Un travail requis positif n’a pas de fin estimable finie ; ne divisez pas par zéro et ne le déclarez pas fini.

</details>

### Exercice 5

Quelles données sont réelles ou fictives ?

<details>
<summary>Réponse 5</summary>

La portée demandée est réelle ; temps, capacités et scénario calendaire sont construits.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
