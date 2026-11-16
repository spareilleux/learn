---
module_id: "cog-009-counterbalance-practice-order-before-comparing-interfaces"
department: "cognitive-science"
course: "Contrebalancer l’ordre de pratique avant de comparer des interfaces"
title: "Contrebalancer l’ordre de pratique avant de comparer des interfaces"
level: "intermediate"
prerequisites: ["cog-007-separate-unaided-recall-from-assisted-success"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Contrebalancer l’ordre de pratique avant de comparer des interfaces

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cog-007-separate-unaided-recall-from-assisted-success.md](../../cognitive-science/en/cog-007-separate-unaided-recall-from-assisted-success.md)
- [pri332.htm](https://www.itl.nist.gov/div898/handbook/pri/section3/pri332.htm)

Une interface de pratique GA semble plus rapide après qu'un agent a remanié ses consignes. Pourtant, l'apprenant voit toujours l'ancienne interface en premier. La familiarité expliquerait-elle une partie de l'écart ? Le prérequis sur l'assistance définit les réponses admissibles. Ce cours ajoute une question : quel dispositif distingue l'effet de l'interface d'un effet d'ordre supposé ? Tous les temps sont fictifs et déterministes, sans apprenant observé.

Les recommandations du NIST expliquent pourquoi suivre et contrôler un facteur parasite. Nous déclarons la période comme tel et plaçons chaque interface dans chaque période avec le même poids. Ce dispositif pédagogique équilibré ne signifie pas qu'inverser l'ordre élimine tout effet de report chez l'humain. Le modèle suppose un bénéfice additif commun dans la période suivante et aucun apprentissage propre à l'interface. Un vrai pilote devrait précisément remettre ces hypothèses à l'épreuve.

Dans l'ordre direct, la seconde interface cumule son avantage initial et le bénéfice de période. Dans l'ordre inverse, ces contributions se compensent dans le contraste interne. Gardez la soustraction orientée selon l'identité des interfaces, indépendamment de leur ordre de présentation. Inverser la soustraction fabriquerait sinon une compensation. Moins de secondes signifie ici terminer plus vite ; cela ne prouve ni un meilleur apprentissage ni moins d'erreurs.

Faites la moyenne des contrastes avec des poids égaux. Dans le modèle additif stipulé, le terme de période s'annule et la différence restante égale le contraste initial entre interfaces. Le contrôle négatif leur attribue des temps initiaux identiques. Il doit conserver des effets d'ordre opposés sans différence équilibrée entre interfaces. Un avantage initial dans ce contrôle révèle une confusion sur l'ordre, les poids ou le sens du contraste.

Pour le travail avec les sources, lisez le tableau d'assistance du prérequis et la définition du facteur parasite du NIST. Préparez une fiche de comparaison sans réponses pour une tâche de manche GA : fixez les bornes temporelles, l'admissibilité, le relevé d'erreurs et l'attribution des ordres avant toute tentative. La référence directe est un tableau d'affectation sur papier. Demandez à un assistant de critiquer report et difficulté inégale. Rejetez une conclusion fondée seulement sur l'ordre direct ou présentant ces secondes inventées comme des mesures d'utilisateurs.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "A_base_seconds": 60,
    "B_base_seconds": 50,
    "second_period_change_seconds": -10,
    "AB": [
      60,
      40
    ],
    "BA": [
      50,
      50
    ]
  },
  "formula": "contrast=B_time-A_time within each order; balanced contrast=mean(order contrasts)",
  "expected": {
    "AB_contrast_seconds": -20,
    "BA_contrast_seconds": 0,
    "balanced_contrast_seconds": -10,
    "A_mean_seconds": 55,
    "B_mean_seconds": 45,
    "null_interface_balanced_contrast": 0
  },
  "negative_control": "Set both interface base times to60; order contrasts are -10 and+10 and average0.",
  "assumptions": [
    "Invented matched tasks, additive identical period benefit, no carryover, complete observations, equal order weights."
  ],
  "limits": "Not a user study, statistical significance estimate or general proof that counterbalancing removes carryover."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Calculez le contraste dans l’ordre direct.

<details>
<summary>Réponse 1</summary>

`40-60=-20` secondes, avec effets d’interface et de période.

</details>

### Exercice 2

Calculez le contraste dans l’ordre inverse.

<details>
<summary>Réponse 2</summary>

`50-50=0` seconde, en conservant le sens B moins A.

</details>

### Exercice 3

Calculez le contraste équilibré.

<details>
<summary>Réponse 3</summary>

`(-20+0)/2=-10` secondes ; moyennes A `55`, B `45`.

</details>

### Exercice 4

Évaluez des interfaces de même temps initial.

<details>
<summary>Réponse 4</summary>

Les contrastes `-10` et `+10` donnent une moyenne de `0`.

</details>

### Exercice 5

Quelle hypothèse le report violerait-il ?

<details>
<summary>Réponse 5</summary>

Le modèle de période additif commun sans report propre à l’interface ; l’apprentissage réel reste non mesuré.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
