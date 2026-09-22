---
title: 11. Hosting, WebApplication et Kestrel
description: Suivre la responsabilité du generic host à WebApplication, Kestrel, DI, aux callbacks de cycle de vie et à l'arrêt gracieux via un vrai serveur loopback.
sidebar:
  order: 11
---

[`WebApplication`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/webapplication) compose configuration, logging, injection de dépendances, middleware et endpoints. Le generic host possède le cycle de vie ; [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) possède le transport réseau.

## Ce que le builder assemble

`CreateBuilder` charge les sources de configuration et les services. `Build` fige ce graphe en application. `StartAsync` démarre les hosted services et le serveur ; `StopAsync` lance l'arrêt gracieux.

Le programme lie Kestrel à un port loopback éphémère, appelle réellement `/health` et observe les callbacks :

```text
started callback observed: True
GET /health: 200 {"status":"ready"}
graceful stop callbacks observed: stopping=True, stopped=True
```

Cela prouve la composition du cours, pas la readiness de production. Il faut encore déclarer limites, timeouts, confiance accordée aux forwarded headers, terminaison TLS et budget d'arrêt.

## Gracieux ne veut pas dire infini

`ApplicationStopping` demande d'arrêter l'admission. Le travail en vol doit finir dans le budget ou laisser une preuve durable de récupération. En conteneur, le timeout du host doit rester inférieur à la période de grâce de l'orchestrateur.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l11
```

La sortie vérifiée est [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l11.txt).

## Exercices

1. Ajouter un endpoint lent qui observe `RequestAborted`, puis déclencher l'arrêt.
2. Fixer une petite limite de body Kestrel et tester juste en dessous et au-dessus.
3. Tester les forwarded headers avec un proxy autorisé et une requête directe qui les usurpe.

<details>
<summary>Solutions</summary>

1. Prouver que la requête a démarré, appeler `StopAsync` avec un token borné et enregistrer la cancellation observée.
2. Configurer avant `Build`, vérifier le statut et prouver que l'endpoint rejeté n'a pas été appelé.
3. Déclarer explicitement les proxies/réseaux connus ; une requête directe ne doit pas choisir son identité client.

</details>
