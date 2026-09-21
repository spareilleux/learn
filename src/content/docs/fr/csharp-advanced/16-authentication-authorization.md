---
title: 16. Authentification et autorisation
description: Valider localement des credentials JWT bearer, distinguer 401 de 403 et appliquer une stratégie ASP.NET Core fondée sur les claims.
sidebar:
  order: 16
---

L'[authentification](https://learn.microsoft.com/aspnet/core/security/authentication/) établit une identité. L'[autorisation par stratégie](https://learn.microsoft.com/aspnet/core/security/authorization/policies) décide si cette identité peut exécuter l'opération. Cette séparation explique les deux codes d'échec :

- `401 Unauthorized` : aucune identité utilisable n'a été établie ;
- `403 Forbidden` : l'identité est valide, mais ne satisfait pas la stratégie de l'endpoint.

## Prérequis

Suivez d'abord [les minimal APIs et les controllers](14-minimal-apis-controllers/). Vous devez déjà comprendre les codes HTTP, l'ordre des middlewares et l'injection de dépendances.

## Valider un token, pas seulement le décoder

La preuve locale configure le [handler JWT bearer](https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication) avec issuer, audience, clé de signature et durée de validité. Décoder les trois segments Base64Url n'est pas authentifier : il faut encore valider la signature et tous les claims pertinents.

Les clés sont générées en mémoire pour un seul processus. Aucun token n'entre dans stdout, les fixtures, Git ou le site. Un temps de cours fixe pilote la validation de durée, donc un token expiré le reste sur chaque runner.

```text
== JWT bearer authentication rejects unusable credentials
missing token: 401
malformed token: 401
expired token: 401
wrong signature: 401
```

## Une stratégie exprime l'autorisation applicative

L'endpoint exige la stratégie `CanReadScales`, qui exige le claim `scope=scales.read`. Un token bien signé sans ce claim est authentifié mais interdit ; celui qui porte le claim atteint le handler :

```text
== A policy distinguishes authenticated from authorized
without required claim: 403
with required claim: 200 C major
```

L'expérience prouve le comportement local d'ASP.NET Core, pas un déploiement OAuth2. En production, il faut encore un serveur d'autorisation de confiance, rotation et découverte des clés, HTTPS, mapping de claims délibéré et une audience par resource server. Une API de production ne doit pas fabriquer ses propres access tokens.

## Exécuter la preuve

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l16
```

La sortie vérifiée est [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l16.txt).

## Exercices

1. Ajouter une stratégie qui accepte `scales.read` ou le rôle `admin`, puis tester les deux branches.
2. Ajouter un issuer incorrect et une audience incorrecte à la matrice 401 sans afficher de token.
3. Remplacer la clé symétrique du cours par la validation d'une clé publique asymétrique locale.

<details>
<summary>Solutions</summary>

1. Écrire un `AuthorizationHandler` ou utiliser `RequireAssertion` ; ne pas modifier l'authentification et vérifier qu'une identité valide mais insuffisante reçoit toujours 403.
2. Paramétrer issuer et audience dans la fabrique, n'écrire que le statut dans la sortie et conserver la validation temporelle fixe.
3. Créer une paire RSA éphémère, signer avec la clé privée et configurer la validation avec la seule clé publique. Libérer les deux clés sans publier clé ni token.

</details>
