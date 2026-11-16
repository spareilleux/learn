---
module_id: gaa-018-bind-delayed-feedback-to-the-original-attempt
department: guitar-alchemist-academy
course: "Rattacher un retour différé à sa tentative d’origine"
level: advanced
prerequisites: ["gaa-007-turn-a-voicing-result-into-a-practice-item"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Rattacher un retour différé à sa tentative d’origine

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un guitariste passe à la question suivante avant la fin d’une revue assistée. Le résultat tardif appartient à la tentative initiale, même si un autre exercice est affiché. Attacher chaque résultat à la dernière question fabriquerait un historique faux. La nouvelle opération rattache le retour à une identité immuable et conserve les cas inconnus ou non résolus. Elle complète la construction d’items au-delà de la justesse du corrigé.

Commencez par un relevé ordonné sans décisions. L’ordre d’arrivée décrit le transport ; l’identité choisit la ligne à modifier. Le cas principal fait arriver d’abord le retour de la tentative la plus récente. Après traitement, le relevé reste dans l’ordre initial sans confondre réception et séquence de pratique. Gardez les deux ordres pour expliquer un délai.

Le témoin remplace une identité par une inconnue. Rejetez la mise à jour et gardez la tentative initiale non résolue, sans transformer une absence en échec. Un verdict positif rattaché à la mauvaise question ne prouve aucune réussite utile. Les doublons ou contradictions demanderaient une autre politique, exclus de ces cas. Le dossier existant conserve des critères et indices propres à la cible ; un futur retour doit les rattacher à la même révision. Une table manuelle révèle déjà l’erreur d’attribution avant tout tutorat asynchrone.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-alchemist-academy/en/gaa-007-turn-a-voicing-result-into-a-practice-item.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "attempt_ids": [
      "A",
      "B"
    ],
    "feedback": [
      {
        "attempt_id": "B",
        "pass": false
      },
      {
        "attempt_id": "A",
        "pass": true
      }
    ]
  },
  "formula": "initialize every attempt to null; process feedback in arrival order; update only matching attempt_id; unknown ids are rejected; output ledger in original attempt order",
  "expected": {
    "ledger": [
      {
        "attempt_id": "A",
        "pass": true
      },
      {
        "attempt_id": "B",
        "pass": false
      }
    ],
    "rejected_ids": [],
    "unresolved_ids": []
  },
  "negative_control": {
    "values": {
      "attempt_ids": [
        "A",
        "B"
      ],
      "feedback": [
        {
          "attempt_id": "B",
          "pass": false
        },
        {
          "attempt_id": "C",
          "pass": true
        }
      ]
    },
    "expected": {
      "ledger": [
        {
          "attempt_id": "A",
          "pass": null
        },
        {
          "attempt_id": "B",
          "pass": false
        }
      ],
      "rejected_ids": [
        "C"
      ],
      "unresolved_ids": [
        "A"
      ]
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des identités uniques et au plus un retour par identité dans ces cas. Doublons et contradictions sont exclus. Aucune course de transport, tentative réelle ou exécution de tutorat n’a été observée.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Initialisez le relevé avant l’arrivée des retours.

<details><summary>Réponse 1</summary>

Chaque tentative est non résolue ; l’ordre est celui de la pratique, pas celui des messages.

</details>

### Exercice 2

Rattachez les messages principaux aux tentatives.

<details><summary>Réponse 2</summary>

L’identité exacte produit les décisions affichées malgré l’ordre d’arrivée inversé.

</details>

### Exercice 3

Que perd une attribution à la dernière question ?

<details><summary>Réponse 3</summary>

Elle peut écraser la question courante avec le résultat d’une autre tentative, même si le verdict est juste.

</details>

### Exercice 4

Appliquez le témoin d’identité inconnue.

<details><summary>Réponse 4</summary>

Rejetez ce retour, conservez le résultat connu et laissez la tentative sans correspondant non résolue.

</details>

### Exercice 5

Qu’est-ce qui réfute une attribution correcte ?

<details><summary>Réponse 5</summary>

Tout résultat associé à une autre identité ou révision la réfute ; une absence ne doit pas devenir un échec inventé.

</details>

## Travail avec consultation des sources

Construisez la table sans aide. Proposez le plus petit relevé liant tentative, révision, réponse et revue, sans implémenter une file.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
