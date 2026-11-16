---
module_id: gaa-017-audit-a-practice-staircase-stopping-rule
department: guitar-alchemist-academy
course: "Auditer la règle d’arrêt d’un escalier de pratique"
level: advanced
prerequisites: ["gaa-010-define-a-practice-pass-before-counting-success"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Auditer la règle d’arrêt d’un escalier de pratique

> Modèle construit et lecture délimitée de sources. Les avis techniques humains, linguistiques, musicaux et pédagogiques restent en attente. Aucun nouveau jeu, résultat d’écoute, rendu du moteur, analyse exécutée ou usage en production n’est revendiqué.

Un assistant augmente le tempo après réussite, le diminue après échec, puis présente le dernier tempo comme un seuil personnel. La règle de mise à jour ne justifie pas cette interprétation. Nous construisons un escalier et vérifions précisément sa condition d’arrêt. Le prérequis définit la réussite ; la nouvelle opération conserve l’histoire séquentielle nécessaire au comptage des retournements.

Un retournement est un changement de direction de mise à jour, pas un simple échec. Des échecs consécutifs poursuivent la descente. La première mise à jour ne peut inverser une direction encore inexistante. Conservez le tempo avant réponse et le prochain tempo programmé pour ne pas résumer le mauvais côté de la transition. Notre estimation moyenne volontairement les niveaux avant mise à jour aux retournements et reste absente avant l’arrêt demandé.

Le témoin contient autant de tentatives complètes sans jamais changer de sens. Son dernier niveau programmé existe, mais l’estimation d’arrêt reste non résolue. Cela distingue limite d’essais et règle de retournement. Une interface réelle demanderait aussi bornes, réponses manquantes et interruption. Le dossier de pratique précise cible et indices autorisés ; ils doivent accompagner l’histoire des réponses. Aucun guitariste n’a produit cette trace et l’arithmétique ne mesure aucun seuil. La table manuelle précède toute recommandation d’adaptation.

## Lire les éléments du projet conservés

Le prérequis fournit l’opération antérieure et sa limite de preuve. Examinez l’artefact lié avant de proposer un changement à partir du cas construit. Les observations conservées gardent leur portée initiale : un fichier ou une donnée d’exemple ne prouve pas un déploiement actuel. Le dossier fixe conserve entrées, résultats préparés et provenance des lectures. Les empreintes locales identifient les octets complets sans élargir le passage réellement lu. Une page primaire étaye seulement la définition consultée, sans révision immuable ni empreinte inventée.

[Prérequis](../../guitar-alchemist-academy/en/gaa-010-define-a-practice-pass-before-counting-success.md)

[Artefact du projet conservé](../../../../code/streeling/evidence/practice-outcomes-2026-10-22/practice-items.json)

[Dossier des cas construits](../../../../code/streeling/evidence/batch50-2026-10-25-b/unit-a.json)

## Cas fixe et grandeurs préparées

```json
{
  "values": {
    "initial_tempo": 60,
    "step": 5,
    "passes": [
      true,
      true,
      false,
      false,
      true,
      false
    ],
    "required_reversals": 3
  },
  "formula": "direction=1 if pass else -1; next_tempo=current_tempo+step*direction; reversal occurs when direction differs from previous direction; stop at required_reversals; estimate=mean(pre_update_tempo at reversals) only after stop",
  "expected": {
    "pre_update_tempo": [
      60,
      65,
      70,
      65,
      60,
      65
    ],
    "post_update_tempo": [
      65,
      70,
      65,
      60,
      65,
      60
    ],
    "reversal_indices": [
      2,
      4,
      5
    ],
    "stop_index": 5,
    "estimate_tempo": 65
  },
  "negative_control": {
    "values": {
      "initial_tempo": 60,
      "step": 5,
      "passes": [
        true,
        true,
        true,
        true,
        true,
        true
      ],
      "required_reversals": 3
    },
    "expected": {
      "pre_update_tempo": [
        60,
        65,
        70,
        75,
        80,
        85
      ],
      "post_update_tempo": [
        65,
        70,
        75,
        80,
        85,
        90
      ],
      "reversal_indices": [],
      "stop_index": null,
      "estimate_tempo": null
    }
  }
}
```

## Hypothèses et limites des preuves

Supposez des résultats booléens construits complets et une trace à pas fixe sans borne atteinte. La première mise à jour n’a pas de direction antérieure ; les indices partent de zéro. Le résumé ne valide aucun seuil personnel.

## Interpréter l’opération avant de choisir une abstraction

Avant de révéler le corrigé, reformulez le contrat d’entrée et dérivez le résultat principal à la main. Conservez les grandeurs intermédiaires ou transitions d’état plutôt que le seul résultat final. Appliquez la même règle au témoin et repérez l’entrée modifiée. Le modèle est un exemple construit fini. Un calcul concordant étaye son affirmation précise ; il ne fournit ni observation d’utilisateur ni validation d’une fonctionnalité en production.

### Exercice 1

Suivez les tempos avant et après chaque réponse.

<details><summary>Réponse 1</summary>

Appliquez le pas fixe dans le sens de la réponse en distinguant niveau testé et prochain niveau.

</details>

### Exercice 2

Quels changements sont de vrais retournements ?

<details><summary>Réponse 2</summary>

Seul un changement par rapport à la direction précédente compte ; des réussites ou échecs répétés ne sont pas des retournements.

</details>

### Exercice 3

Quand la trace principale s’arrête-t-elle ?

<details><summary>Réponse 3</summary>

À l’essai affiché où le nombre requis est atteint ; l’estimation utilise les niveaux avant mise à jour déclarés.

</details>

### Exercice 4

Pourquoi l’estimation du témoin reste-t-elle absente ?

<details><summary>Réponse 4</summary>

Il n’atteint jamais la condition de retournements, même si tous les essais sont complets et le dernier niveau existe.

</details>

### Exercice 5

Qu’est-ce qui rejette l’annonce d’un seuil personnel ?

<details><summary>Réponse 5</summary>

Sans réponses réelles ni validation de l’interprétation, le résumé construit ne peut établir un seuil d’apprenant.

</details>

## Travail avec consultation des sources

Construisez la table sans aide, puis proposez un relevé séparant niveaux testés et programmés. Laissez seuil personnel et adoption indécis.

Conservez votre réponse sans aide avant de consulter source ou calculatrice. Repérez ensuite un passage précis et sa révision, notez toutes les aides et gardez la réponse initiale avec sa correction éventuelle. Un flux d’agent ou un DSL proposé doit conserver le résultat manuel et son contre-cas avant que son intérêt puisse être évalué. Si une entrée manque, laissez la décision non résolue au lieu d’inventer une valeur plausible.

Formulez un critère de réfutation observable face à la règle, puis précisez l’observation nécessaire à l’étape suivante. Les réponses sont des contrôles préparés, pas la trace de votre tentative. Le dossier contient un critère distinct par exercice ; toutes les décisions d’apprenant restent indécises jusqu’à conservation d’une réponse réelle et de sa revue. Joignez aides, corrections et limites à la note finale pour ne pas confondre calcul juste, rappel autonome, avis musical et validation d’exécution.
