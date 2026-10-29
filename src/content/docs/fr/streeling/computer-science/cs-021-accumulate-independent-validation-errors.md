---
title: Accumuler les erreurs de validation indépendantes
description: Accumuler les erreurs de validation indépendantes — Informatique
sidebar:
  label: CS-021 · Accumuler les erreurs de validation indépendantes
  order: 21
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-021-accumulate-independent-validation-errors.fr.md
---

:::note[Streeling University]
**CS-021** · Accumuler les erreurs de validation indépendantes · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-021-accumulate-independent-validation-errors.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Une requête audio GA peut contenir à la fois une fréquence invalide, un nombre de canaux non pris en charge et un nombre de trames négatif. Ne renvoyer que la première erreur impose plusieurs cycles de correction. Pour autant, les étapes audio dépendantes ne doivent pas se poursuivre après un échec. Distinguez l’examen des entrées indépendantes du calcul dépendant avant de choisir leur composition.

La documentation FSharp.Core précise le comportement de `Result.bind` en cas d’erreur. Elle ne promet pas de recueillir les suivantes. Notre tableau construit définit donc une autre opération : examiner chaque champ indépendant, concaténer les noms des erreurs et ne construire aucune requête acceptée tant que la liste reste non vide. Il s’agit de concevoir une interface, pas de remplacer le module de résultats de GA.

Une simplification tentante consiste à exécuter toutes les étapes pour recueillir leurs échecs. Elle oublie l’hypothèse d’indépendance : décoder des échantillons peut exiger un format valide. Dans une proposition de DSL, inscrivez les dépendances près de chaque vérification. Les diagnostics supplémentaires ne sont utiles que s’ils ont un sens et précèdent les effets.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cs-010-compose-fail-fast-ga-computations](../../computer-science/cs-010-compose-fail-fast-ga-computations/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://fsharp.github.io/fsharp-core-docs/reference/fsharp-core-resultmodule.html)

## Modèle fixé et contrôle

```json
{
  "values": {
    "sample_rate_hz": 0,
    "channels": 3,
    "frames": -1
  },
  "formula": "Validate fields independently in sample_rate_hz, channels, frames order: rate>0; channels in [1,2]; frames>=0. Concatenate error field names. Reject if any error; no effects occur.",
  "expected": {
    "errors": [
      "sample_rate_hz",
      "channels",
      "frames"
    ],
    "error_count": 3,
    "accepted": false
  },
  "negative_control": {
    "values": {
      "sample_rate_hz": 48000,
      "channels": 2,
      "frames": 64
    },
    "expected": {
      "errors": [],
      "error_count": 0,
      "accepted": true
    },
    "why": "Valid inputs remove every independent error without substituting defaults."
  },
  "assumptions": [
    "Pure total field checks; no check depends on another field being valid.",
    "Error order follows declared field order; frames is an integer."
  ],
  "limits": "Accumulation does not authorize dependent audio work or provide a GA implementation.",
  "input_types": {
    "sample_rate_hz": "integer",
    "channels": "integer",
    "frames": "integer"
  }
}
```

### Exercice 1

Énumérez les erreurs du cas fixé.

<details><summary>Réponse 1</summary>

La liste ordonnée est `[sample_rate_hz,channels,frames]`, soit `3` erreurs. Chaque champ enfreint sa propre règle ; l’ordre vient du contrat, pas du moment de découverte.

</details>

### Exercice 2

Que renverrait une chaîne qui s’arrête au premier échec ?

<details><summary>Réponse 2</summary>

Elle conserverait seulement `sample_rate_hz` selon cet ordre. Ce comportement peut convenir aux calculs dépendants, mais ne fournit pas la liste complète demandée.

</details>

### Exercice 3

Appliquez le contrôle valide.

<details><summary>Réponse 3</summary>

Avec `48000`, `2` et `64`, la liste vaut `[]`, le nombre vaut `0` et la requête est acceptée. Aucune valeur par défaut n’a réparé une entrée.

</details>

### Exercice 4

Un décodeur peut-il fonctionner pendant cette collecte ?

<details><summary>Réponse 4</summary>

Seulement si ses propres préconditions sont établies séparément. Ces vérifications pures ne fournissent ni tampon valide ni autorisation d’effets dépendants.

</details>

### Exercice 5

Qu’est-ce qui réfuterait la proposition ?

<details><summary>Réponse 5</summary>

Perdre une erreur, changer son identité ou accepter une requête dont la liste reste non vide réfute le contrat. Du texte supplémentaire ne remplace pas un diagnostic manquant.

</details>

## Travail avec consultation des sources

Préparez une note de diagnostic pour une requête audio GA fictive et demandez à un assistant de conserver tous les échecs indépendants.

**Référence manuelle directe:** Établissez à la main un tableau champ/règle/erreur, puis concaténez les erreurs dans l’ordre annoncé.

**Critère de réfutation:** Une erreur de champ indépendant disparaît ou une liste non vide conduit à l’acceptation.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
