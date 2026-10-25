---
module_id: "cyb-016-test-feedforward-against-disturbance-mismatch"
department: "cybernetics"
course: "Éprouver l’anticipation face à une perturbation mal estimée"
level: "intermediate"
prerequisites: ["cyb-010-separate-derivative-noise-from-plant-motion"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Éprouver l’anticipation face à une perturbation mal estimée

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un agent prévoit une charge entrante et propose de la compenser avant d’observer une erreur de sortie. Cette voie d’information diffère de la rétroaction sur le résidu. La référence directe ignore l’estimation de perturbation ; la commande proposée la soustrait avant de diviser par le gain supposé.

L’extrait officiel de Caltech consulté décrit une anticipation fondée sur une perturbation mesurée et dépendante du modèle du système. Seul ce passage extrait était disponible ; le téléchargement intégral a échoué. Notre équation scalaire statique est une simplification construite, sans réglage de production déduit de la lecture. Elle rend visible l’écart d’estimation.

Calculez la sortie avec la perturbation réelle stipulée, pas avec l’estimation utilisée pour commander. Sinon le modèle confirmerait sa propre prévision. Comparez les résidus absolus à la référence directe. Le contrôle fournit volontairement une mauvaise estimation : aider dans un cas ne garantit pas d’aider dans l’autre. Le DSL doit conserver le rôle de chaque quantité.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cyb-010-separate-derivative-noise-from-plant-motion](../../cybernetics/en/cyb-010-separate-derivative-noise-from-plant-motion.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Artefact conservé du projet](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://www.cds.caltech.edu/~murray/books/AM08/pdf/cds101-complete_20Sep07.pdf)

## Modèle fixé et contrôle

```json
{
  "values": {
    "target": 10,
    "plant_gain": 2,
    "disturbance": 4,
    "measured_disturbance": 3,
    "assumed_gain": 2
  },
  "formula": "No compensation: u=target/assumed_gain. Feedforward: u=(target-measured_disturbance)/assumed_gain. Actual y=plant_gain*u+disturbance; error=y-target.",
  "expected": {
    "baseline_command": 5,
    "baseline_output": 14,
    "baseline_error": 4,
    "command": 3.5,
    "output": 11,
    "error": 1
  },
  "negative_control": {
    "values": {
      "target": 10,
      "plant_gain": 2,
      "disturbance": 4,
      "measured_disturbance": 10,
      "assumed_gain": 2
    },
    "expected": {
      "baseline_command": 5,
      "baseline_output": 14,
      "baseline_error": 4,
      "command": 0,
      "output": 4,
      "error": -6
    },
    "why": "Overstating the disturbance makes compensation worse in absolute error than the direct baseline."
  },
  "assumptions": [
    "Static scalar plant, known positive gain, additive disturbance; command unrestricted.",
    "Measurement available before command; no feedback, delay or noise distribution."
  ],
  "limits": "No live GA controller or universal benefit; inaccurate gain or disturbance can reverse the comparison.",
  "input_types": {
    "target": "real output units",
    "plant_gain": "positive real output/command",
    "disturbance": "real output units",
    "measured_disturbance": "real output units",
    "assumed_gain": "positive real output/command"
  }
}
```

### Exercice 1

Calculez la référence sans compensation.

<details><summary>Réponse 1</summary>

La commande `5` donne une sortie `14` et une erreur `4`. Elle utilise la cible et le gain supposé sans soustraire la perturbation.

</details>

### Exercice 2

Calculez la commande proposée et sa sortie.

<details><summary>Réponse 2</summary>

La commande `3.5` donne une sortie `11` et une erreur `1`. La perturbation reste `4`, même si son estimation vaut `3`.

</details>

### Exercice 3

Pourquoi ne pas employer l’estimation dans la sortie réelle ?

<details><summary>Réponse 3</summary>

Cela remplacerait le monde stipulé par l’estimation du contrôleur et masquerait l’écart. Prévision et entrée réelle du modèle ont des rôles distincts.

</details>

### Exercice 4

Appliquez le contrôle surestimé.

<details><summary>Réponse 4</summary>

La commande `0` donne une sortie `4` et une erreur `-6`. Sa valeur absolue dépasse celle de référence, `4` ; l’anticipation est moins bonne ici.

</details>

### Exercice 5

Que manque-t-il pour recommander un changement ?

<details><summary>Réponse 5</summary>

Un gain justifié, une mesure disponible à temps, des limites de commande et des observations réelles de la tâche. Ce calcul ne les fournit pas.

</details>

## Travail avec consultation des sources

Comparez les commandes directe et compensée dans une note sur une charge GA fictive.

**Référence manuelle directe:** Séparez sur papier gain supposé, perturbation estimée et équation de sortie réelle.

**Critère de réfutation:** La compensation est déclarée toujours meilleure malgré le résidu plus mauvais du contrôle.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](../../../../code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-25/journal.md)
