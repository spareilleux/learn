---
title: Libérer uniquement les ressources acquises
description: Libérer uniquement les ressources acquises — Informatique
sidebar:
  label: CS-023 · Libérer uniquement les ressources acquises
  order: 23
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-023-unwind-only-acquired-resources.fr.md
---

:::note[Streeling University]
**CS-023** · Libérer uniquement les ressources acquises · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-023-unwind-only-acquired-resources.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-010](../../computer-science/cs-010-compose-fail-fast-ga-computations/)
:::

> Ce cours utilise des entrées construites et des passages de sources consultés. Les nombres, historiques et étiquettes sont pédagogiques. La revue technique humaine, la relecture linguistique, les tentatives apprenantes, l’exécution, l’adoption en production et la publication restent indéterminées.

Un export GA fictif ouvre une ressource d’entrée, puis une ressource de sortie. Le traitement échoue. Conserver l’erreur est nécessaire, mais il faut aussi définir la durée de vie des ressources. Une composition qui s’arrête au premier échec ne désigne pas à elle seule le responsable de leur libération. Séparez les événements d’acquisition et de libération du résultat du traitement.

La documentation F# décrit la libération à la sortie de portée et l’ordre inverse des liaisons `use` imbriquées. Notre trace emploie des ressources symboliques sans ouvrir de fichier. Seule une acquisition réussie confère la responsabilité de libération. Si la seconde échoue, aucune seconde ressource n’existe à libérer et le traitement ne commence pas. L’acquisition extérieure réussie doit tout de même être dénouée.

Fermer une ressource n’efface pas les données écrites, n’annule pas un effet distant et ne restaure pas un état métier. Nous supposons aussi que la libération réussit. Son échec réel demanderait une politique explicite. Une proposition de DSL doit conserver à la fois la responsabilité des ressources et le résultat.

## Sources et périmètre du projet

L’utilitaire Learn sépare métadonnées, titre et corps dans `parseModule` et indexe les noms anglais dans `englishModuleKeys`. Ces représentations permettent de nommer source et métadonnées ; elles n’implémentent pas l’opération construite. Le relevé de pratique distingue plutôt métriques de recherche et preuves apprenantes. Examinez le fichier lié et ne retenez que ce qu’il étaye réellement. Aucune entrée du modèle n’a été estimée à partir de ce fichier.

[Prérequis: cs-010-compose-fail-fast-ga-computations](../../computer-science/cs-010-compose-fail-fast-ga-computations/)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/scripts/streeling-lib.mjs)

[Artefact conservé du projet](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/practice-outcomes-2026-10-22/source-observations.json)

[Lecture primaire](https://learn.microsoft.com/dotnet/fsharp/language-reference/resource-management-the-use-keyword)

## Modèle fixé et contrôle

```json
{
  "values": {
    "resources": [
      "input",
      "output"
    ],
    "fail_acquire": null,
    "work_error": true
  },
  "formula": "Acquire in listed order until failure. If acquisition completes run work. Release every successfully acquired resource exactly once in reverse order. Release cannot fail in this model.",
  "expected": {
    "acquired": [
      "input",
      "output"
    ],
    "released": [
      "output",
      "input"
    ],
    "outcome": "work_error"
  },
  "negative_control": {
    "values": {
      "resources": [
        "input",
        "output"
      ],
      "fail_acquire": "output",
      "work_error": true
    },
    "expected": {
      "acquired": [
        "input"
      ],
      "released": [
        "input"
      ],
      "outcome": "acquire_error"
    },
    "why": "A failed acquisition does not create ownership; work is skipped and only input is released."
  },
  "assumptions": [
    "Acquisition failure returns no resource; all releases succeed.",
    "Nested scopes own their acquired resources; no process crash or escaping borrow."
  ],
  "limits": "No implementation, exception suppression policy, asynchronous disposal or crash recovery is provided.",
  "input_types": {
    "resources": "ordered list<unique string>",
    "fail_acquire": "string|null",
    "work_error": "boolean"
  }
}
```

### Exercice 1

Décrivez la libération après l’échec du traitement.

<details><summary>Réponse 1</summary>

Les acquisitions sont `[input,output]` ; les libérations suivent `[output,input]`. Le résultat reste `work_error` ; libérer ne transforme pas l’échec en réussite.

</details>

### Exercice 2

Pourquoi cet ordre inverse est-il utile ?

<details><summary>Réponse 2</summary>

La portée intérieure peut dépendre de la ressource extérieure. La fermer d’abord respecte cette imbrication, sous l’hypothèse annoncée.

</details>

### Exercice 3

Appliquez le contrôle d’acquisition échouée.

<details><summary>Réponse 3</summary>

Seule `[input]` est acquise et libérée. Le résultat vaut `acquire_error` ; `output` n’a jamais été détenue et le traitement est sauté.

</details>

### Exercice 4

La libération annule-t-elle l’artefact exporté ?

<details><summary>Réponse 4</summary>

Non. La durée de vie d’une ressource et la compensation métier sont différentes. La trace ne traite ni les octets partiels, ni les transactions, ni les effets distants.

</details>

### Exercice 5

Quelle hypothèse change si une libération échoue ?

<details><summary>Réponse 5</summary>

L’hypothèse de libération réussie tombe. Une nouvelle politique doit conserver les erreurs du traitement et du nettoyage ; aucun masquage n’est défini ici.

</details>

## Travail avec consultation des sources

Rédigez une fiche de durée de vie pour un export GA construit et comparez la trace d’un assistant aux portées imbriquées.

**Référence manuelle directe:** Listez les acquisitions réussies, inversez la liste pour libérer et conservez l’échec initial.

**Critère de réfutation:** Une ressource jamais acquise est libérée, une ressource acquise fuit ou le nettoyage transforme l’échec en réussite.

Enregistrez une première réponse avant d’ouvrir les corrigés. Recopiez les identités et unités des entrées, écrivez les étapes intermédiaires et distinguez calcul et interprétation. Un nombre juste avec un dénominateur, une frontière d’état ou une unité de comptage erronés ne satisfait pas la tâche. Conservez un résultat surprenant au lieu de modifier l’entrée pour rendre la réponse plausible.

Lisez le passage primaire cité dans le périmètre indiqué au dossier. Comparez sa définition à la règle construite du modèle. La référence peut motiver un concept sans spécifier tout notre modèle. Notez version ou date, passage utilisé et hypothèse importée. L’accès à une page ou la lecture réussie d’un fichier ne vérifie pas une affirmation.

Examinez l’artefact conservé et un prérequis. Séparez ce que représente réellement le fichier de ce que cette nouvelle tâche suppose. Gardez révision et historique des aides. Après avoir enregistré la référence manuelle, demandez à un assistant de contester une hypothèse. Conservez consigne, réponse, correction retenue et suggestion rejetée. Sources et calculatrice sont des aides autorisées, pas du rappel sans assistance.

Traitez l’entrée modifiée avec le même raisonnement sur papier. Énoncez le critère de réfutation avant de proposer une abstraction d’agent ou une expression DSL composable. Si l’abstraction perd le contre-exemple ou change le point d’évaluation accepté, elle échoue même en étant plus courte. Comparez d’abord un tableau direct ou un enregistrement typé ; aucun nouveau langage ni moteur de production n’est nécessaire.

Remettez réponses initiale et corrigée, contrôle, passage source et incertitudes restantes. Le dossier prépare un critère distinct par exercice ; toutes les décisions apprenantes restent indéterminées. Corrigé, empreinte d’octets et vérification d’auteur diffèrent d’une tentative réelle. Une comparaison future en dogfood doit conserver les tentatives sur la même tâche versionnée et la référence directe avant d’annoncer un progrès utile.

[Dossier fixé](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-25/journal.md)
