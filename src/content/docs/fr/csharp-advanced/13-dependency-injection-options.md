---
title: 13. Injection de dépendances et options
description: Faire des lifetimes singleton, scoped et transient des règles de possession, détecter les captive dependencies, utiliser les keyed services et valider les options.
sidebar:
  order: 13
---

L'[injection de dépendances ASP.NET Core](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection) est un système de possession. Un lifetime dit combien de temps une instance et son état peuvent être partagés.

## Les lifetimes ne sont pas des astuces de performance

- **singleton** : une instance racine, thread-safe, sans état scoped capturé ;
- **scoped** : une instance par scope explicite, normalement une requête HTTP ;
- **transient** : une instance par résolution, toujours possédée et disposée par son conteneur.

```text
same scope returns same instance: True
singleton returns same instance: True
different scopes return different instances: True
captive scoped dependency rejected: True
```

Les [keyed services](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection#keyed-services) choisissent une implémentation par une clé de composition. Ne pas transformer cette clé en service locator dans le domaine.

## Les options forment un contrat

[`IOptions<T>`](https://learn.microsoft.com/dotnet/core/extensions/options) est une vue singleton, `IOptionsSnapshot<T>` recalcule par scope, `IOptionsMonitor<T>` observe les changements. Reloadable ne signifie pas sûr : il faut définir ce que voit une opération en vol.

Le programme configure une capacité invalide et observe `OptionsValidationException`. `ValidateOnStart` déplace cette erreur au démarrage d'une application hostée.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l13
```

La sortie vérifiée est [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l13.txt).

## Exercices

1. Injecter un repository scoped dans un cache singleton et réparer la possession.
2. Câbler deux formatters keyed puis déplacer le choix de clé à la composition.
3. Recharger une capacité pendant du travail en vol et écrire l'invariant.

<details>
<summary>Solutions</summary>

1. Rendre le consommateur scoped, transmettre des données immuables au singleton, ou créer et disposer explicitement un scope dans un coordinateur d'infrastructure.
2. Résoudre le service keyed au câblage et injecter un contrat sans clé dans le domaine.
3. Appliquer la nouvelle valeur aux nouvelles files ou effectuer une migration explicite avec admission suspendue.

</details>
