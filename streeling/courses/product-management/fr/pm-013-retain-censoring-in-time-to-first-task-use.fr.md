---
module_id: "pm-013-retain-censoring-in-time-to-first-task-use"
department: "product-management"
course: "Conserver la censure du délai avant la première utilisation"
level: "intermediate"
prerequisites: ["pm-009-separate-release-adoption-from-artifact-downloads"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Conserver la censure du délai avant la première utilisation

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Les membres d’une cohorte GA fictive n’ont pas tous le même recul. Une personne dont le suivi s’arrête sans utilisation n’est pas connue pour ne jamais utiliser la tâche ensuite. Une fraction dans une fenêtre fixe et une estimation du délai avant première utilisation répondent à des questions différentes lorsque l’observation se termine tôt. Le prérequis fixe personnes et tâches ; ce cours ajoute la durée d’exposition.

La lecture Kaplan-Meier de NIST définit les ensembles à risque et les facteurs du produit limite pour des histoires censurées. Nous remplaçons l’événement de défaillance par la première utilisation admissible. Ce point d’évaluation est construit, sans télémétrie réelle. Retirez les personnes censurées des ensembles ultérieurs sans compter leur censure comme événement.

Le contrôle prolonge un suivi sans événement. Le nombre d’événements reste fixe, mais l’ensemble ultérieur et l’estimation changent. L’interprétation en population suppose aussi une censure non informative. Des utilisateurs frustrés qui disparaissent plus tôt pourraient violer cette hypothèse. Un calcul correct ne diagnostique pas ce mécanisme. Gardez les suivis individuels et indicateurs de censure dans les résumés proposés.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: pm-009-separate-release-adoption-from-artifact-downloads](../../product-management/en/pm-009-separate-release-adoption-from-artifact-downloads.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://itl.nist.gov/div898/handbook/apr/section2/apr215.htm)

## Modèle fixé et contrôle

```json
{
  "values": {
    "followup_days": [
      1,
      2,
      3,
      4
    ],
    "event": [
      1,
      0,
      1,
      0
    ],
    "horizon_days": 3
  },
  "formula": "Event=first eligible task use; zero=censored at followup. At each event time <=horizon, risk=count(followup>=time), failures=count(event=1 at time); S multiplies (1-failures/risk). Report 1-S and raw observed events/N separately.",
  "expected": {
    "event_times": [
      1,
      3
    ],
    "risk_sets": [
      4,
      2
    ],
    "survival": [
      0.75,
      0.375
    ],
    "cumulative_first_use": 0.625,
    "raw_event_fraction": 0.5
  },
  "negative_control": {
    "values": {
      "followup_days": [
        1,
        4,
        3,
        4
      ],
      "event": [
        1,
        0,
        1,
        0
      ],
      "horizon_days": 3
    },
    "expected": {
      "event_times": [
        1,
        3
      ],
      "risk_sets": [
        4,
        3
      ],
      "survival": [
        0.75,
        0.5
      ],
      "cumulative_first_use": 0.5,
      "raw_event_fraction": 0.5
    },
    "why": "Extending the early censored followup changes the later risk set without changing observed event count."
  },
  "assumptions": [
    "Common eligible entry time and exact first-event times; distinct event times.",
    "Independent noninformative censoring is required for a population interpretation; no competing events."
  ],
  "limits": "Authored time-to-event estimate, not observed adoption, causal benefit, retention or uncertainty interval.",
  "input_types": {
    "followup_days": "list<positive real>",
    "event": "same-length list<0|1>",
    "horizon_days": "positive real"
  }
}
```

### Exercice 1

Construisez les ensembles à risque.

<details><summary>Réponse 1</summary>

Aux instants `[1,3]`, leurs tailles sont `[4,2]`. La personne censurée auparavant ne figure plus dans le second.

</details>

### Exercice 2

Calculez la survie par produit limite.

<details><summary>Réponse 2</summary>

Les valeurs sont `[0.75,0.375]` ; chaque événement multiplie la survie précédente par sa fraction sans événement.

</details>

### Exercice 3

Comparez utilisation cumulée et fraction brute.

<details><summary>Réponse 3</summary>

L’estimation vaut `0.625`, tandis que la fraction observée vaut `0.5`. Elles traitent différemment les durées de suivi.

</details>

### Exercice 4

Appliquez le contrôle de suivi prolongé.

<details><summary>Réponse 4</summary>

Les ensembles valent `[4,3]`, la survie `[0.75,0.5]` et l’utilisation cumulée `0.5`. La fraction brute reste `0.5`.

</details>

### Exercice 5

Un calcul correct établit-il une censure indépendante ?

<details><summary>Réponse 5</summary>

Non. Cela concerne la raison de la fin du suivi relativement aux événements futurs. Il faut du contexte réel ; le tableau n’en observe aucun.

</details>

## Travail avec consultation des sources

Préparez une fiche de mesure de première utilisation pour une cohorte GA fictive avec ses indicateurs de censure.

**Référence manuelle directe:** Triez les événements, comptez les personnes encore suivies juste avant chacun et multipliez les facteurs à la main.

**Critère de réfutation:** Une censure est comptée comme événement ou une personne reste à risque après la fin de son suivi.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
