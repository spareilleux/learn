---
title: 12. Le pipeline middleware
description: Traiter Use, Map et Run comme un contrôle de flux imbriqué dont l'ordre détermine sécurité, erreurs, routing et short-circuits.
sidebar:
  order: 12
---

Un [middleware ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/middleware/) est du contrôle de flux imbriqué. Le code avant `next` s'exécute à l'aller ; le code après `next`, au retour. L'ordre d'enregistrement est donc un comportement observable.

## L'oignon est exécutable

```text
GET /ok: 200; outer:before -> endpoint -> outer:after
```

Le gate court-circuite volontairement `/blocked` :

```text
GET /blocked: 429; outer:before -> gate:short-circuit -> outer:after
```

L'endpoint est absent car le gate n'appelle pas `next`. Le middleware externe termine néanmoins son chemin de réponse.

## Des règles d'ordre qui comptent

- le handler d'exception doit envelopper le code qu'il convertit ;
- les forwarded headers précèdent les lecteurs du scheme, host ou client IP ;
- le routing choisit l'endpoint avant l'autorisation fondée sur ses métadonnées ;
- l'authentification établit le principal avant l'autorisation ;
- un `Run` terminal achève sa branche.

`Map` branche sur un chemin, `MapWhen` sur un prédicat. Une branche n'est ni un nouveau process ni une frontière de confiance.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l12
```

La sortie vérifiée est [`expected/l12.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l12.txt).

## Exercices

1. Placer le handler d'exception après un endpoint qui lance une exception.
2. Ajouter un correlation ID et décider comment traiter une valeur fournie par le client.
3. Ajouter une branche `/admin` et prouver que l'autorisation s'y exécute.

<details>
<summary>Solutions</summary>

1. Il ne peut envelopper que les composants enregistrés après lui ; il faut le déplacer plus tôt.
2. Valider l'entrée, la garder seulement comme baggage non fiable et générer l'ID serveur utilisé dans les logs.
3. Mettre l'autorisation dans la branche pertinente ou utiliser les métadonnées d'endpoint. Le chemin seul n'accorde aucune autorité.

</details>
