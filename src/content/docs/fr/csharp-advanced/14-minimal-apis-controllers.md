---
title: 14. Minimal APIs et contrôleurs
description: Comparer binding des route handlers, endpoint filters, TypedResults, contrôleurs et réponses IAsyncEnumerable streamées dans une même table de routing.
sidebar:
  order: 14
---

Les [Minimal APIs](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) et les [contrôleurs](https://learn.microsoft.com/aspnet/core/web-api/) publient tous des endpoints via endpoint routing. Le choix dépend des besoins de composition, pas d'un slogan.

## Le binding est un contrat public

Un handler lie directement route, query, headers, services et body. Il faut rendre la source explicite dès qu'une ambiguïté devient dangereuse.

```text
without key: 400; with key: 200 {"root":"C","notes":7}
```

[`TypedResults`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/responses) conserve des types concrets pour tests et OpenAPI. Un endpoint filter peut décorer une famille de handlers ; l'autorisation reste la responsabilité du système d'autorisation et des métadonnées d'endpoint.

## Là où les contrôleurs restent profonds

Les contrôleurs apportent conventions, model binding, filtres et validation pour les grandes APIs. Le programme mappe les deux styles dans la même table :

```text
controller: 200 {"symbol":"Cmaj7","characters":5}
```

Ne pas dupliquer la policy : chaque transport appelle la même seam applicative.

## Streaming

`IAsyncEnumerable<T>` permet au serializer de consommer les éléments de façon asynchrone. Les proxies peuvent néanmoins bufferiser ; pour une livraison progressive, mesurer toute la chaîne et choisir NDJSON, SSE ou SignalR selon le contrat.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l14
```

La sortie vérifiée est [`expected/l14.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l14.txt).

## Exercices

1. Ajouter une valeur `notes` négative et un contrat d'erreur portable.
2. Exposer la même opération par Minimal API et contrôleur sans dupliquer la policy.
3. Annuler le stream après le premier élément et prouver que la source observe la cancellation.

<details>
<summary>Solutions</summary>

1. Rejeter à la frontière avec un problem details stable et tester statut, media type et payload.
2. Lier les entrées vers une commande/requête unique, appeler un seul handler, puis mapper le résultat dans chaque adapter.
3. Passer `RequestAborted`, fermer la réponse côté client et vérifier le `finally` ou la sonde de cancellation.

</details>
