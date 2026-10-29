---
title: Faire de l’annulation un résultat explicite du pipeline
description: Faire de l’annulation un résultat explicite du pipeline — Informatique
sidebar:
  label: CS-016 · Faire de l’annulation un résultat explicite du pipeline
  order: 16
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/computer-science/fr/cs-016-make-cancellation-an-explicit-pipeline-outcome.fr.md
---

:::note[Streeling University]
**CS-016** · Faire de l’annulation un résultat explicite du pipeline · intermédiaire · 45 minutes

Généré par le département *Informatique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/computer-science/fr/cs-016-make-cancellation-an-explicit-pipeline-outcome.fr.md) · [Mon journal](../../journal/)

Prérequis: [CS-011](../../computer-science/cs-011-preserve-absence-and-failure-boundaries/)
:::

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [cs-011-preserve-absence-and-failure-boundaries.md](../../computer-science/cs-011-preserve-absence-and-failure-boundaries/)
- [GaAsync.fs](https://raw.githubusercontent.com/GuitarAlchemist/ga/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Business.DSL/Closures/GaAsync.fs)
- [cancellation-in-managed-threads](https://learn.microsoft.com/dotnet/standard/threading/cancellation-in-managed-threads)

Un coordinateur demande l'arrêt d'un pipeline d'analyse audio et reçoit une réponse positive à sa demande d'annulation. Toutes les branches sont-elles arrêtées, et peut-on supprimer leur fichier de sortie ? Il faut observer chaque branche. L'union d'erreurs GA épinglée contient un cas d'annulation, mais sa présence n'indique pas où chaque opération traite la demande. Le prérequis laisse volontairement la sûreté de l'annulation ouverte ; ce cours propose un petit modèle d'audit, sans prétendre combler cette lacune par une exécution.

La documentation Microsoft décrit une demande coopérative et un destinataire qui doit y répondre. Lisez ce mécanisme introductif, puis séparez le reçu de demande des preuves de fin. Dans notre registre construit, toutes les tentatives nommées reçoivent une demande. L'une confirme son annulation avant tout effet, une autre se termine en enregistrant une écriture, et la dernière n'a aucune observation terminale. Les nombres du dossier découlent exactement de ces données. Ce ne sont pas des mesures d'un service GA.

L'identité d'une tentative est essentielle : une confirmation tardive pourrait sinon être attribuée à sa remplaçante. Un horodatage situe l'événement sans remplacer cette identité. Conservez l'événement attestant un effet même si une demande ultérieure exige l'arrêt. L'annulation ne compense pas à elle seule une écriture terminée. Toute suppression ou inversion demande sa propre autorité, son modèle d'effet et ses preuves. Un état souhaité ne remplace jamais un état observé.

Le contrôle négatif est un registre de demandes dépourvu de confirmations. Un rapport qui le classe comme annulé déduit le résultat de sa propre commande. Notre rapport doit conserver l'état inconnu. Cet état diffère aussi d'un échec : il peut provenir d'une réponse retardée, d'un reçu absent ou d'une observation perdue. Une nouvelle tentative peut produire un effet supplémentaire alors que la première travaille encore ; cette catégorie ne suffit donc pas à justifier une relance.

Pour le travail réel avec les sources, lisez l'union d'erreurs, l'enveloppe asynchrone et la composition dépendante du fichier GA épinglé. Repérez les lignes décrivant des erreurs retournées et les preuves supplémentaires nécessaires à un contrat d'annulation terminale. Prenez un tableau d'événements manuel comme référence. Demandez à un assistant de classer le même registre en citant les passages utilisés. Rejetez sa réponse si une demande d'arrêt devient une garantie de restauration ou s'il prétend avoir effectué un test d'annulation absent de cet exercice.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "requested": [
      "A",
      "B",
      "C"
    ],
    "acknowledged_cancelled": [
      "A"
    ],
    "completed": [
      "B"
    ],
    "unknown": [
      "C"
    ],
    "B_effect": "written"
  },
  "formula": "requested set partitions by observed terminal evidence, not by request count",
  "expected": {
    "requests": 3,
    "cancelled": 1,
    "completed": 1,
    "unknown": 1,
    "safe_to_claim_all_cancelled": false
  },
  "negative_control": "A request-only record has no acknowledged cancellation.",
  "assumptions": [
    "A terminal acknowledgment refers to the same attempt identity; effects are independently recorded."
  ],
  "limits": "No GA cancellation delivery, rollback or distributed stop was executed."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

Comptez les demandes et les catégories terminales.

<details>
<summary>Réponse 1</summary>

`3` demandes ; `1` annulée, `1` terminée, `1` inconnue.

</details>

### Exercice 2

Peut-on déclarer B restaurée ?

<details>
<summary>Réponse 2</summary>

Non. B conserve une écriture et une fin enregistrées ; aucun reçu de compensation n’existe.

</details>

### Exercice 3

Que prouve le contrôle limité aux demandes ?

<details>
<summary>Réponse 3</summary>

Il prouve seulement l’envoi des demandes ; chaque résultat terminal reste inconnu.

</details>

### Exercice 4

Pourquoi conserver l’identité de la tentative ?

<details>
<summary>Réponse 4</summary>

Pour éviter d’attribuer une confirmation tardive à une tentative remplaçante.

</details>

### Exercice 5

L’union d’erreurs prouve-t-elle la livraison coopérative ?

<details>
<summary>Réponse 5</summary>

Non. Un cas représentable ne constitue ni demande observée, ni confirmation, ni restauration.

</details>

[Dossier de preuves fixes](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/batch50-2026-10-23/journal.md)
