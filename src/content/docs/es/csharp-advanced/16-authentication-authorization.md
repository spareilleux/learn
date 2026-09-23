---
title: 16. Autenticación y autorización
description: Validar credenciales JWT bearer localmente, distinguir 401 de 403 y aplicar una política ASP.NET Core basada en claims.
sidebar:
  order: 16
---

La [autenticación](https://learn.microsoft.com/aspnet/core/security/authentication/) establece una identidad. La [autorización basada en políticas](https://learn.microsoft.com/aspnet/core/security/authorization/policies) decide si esa identidad puede ejecutar una operación. Separarlas explica los dos códigos de fallo:

- `401 Unauthorized`: no se estableció una identidad utilizable;
- `403 Forbidden`: la identidad es válida, pero no satisface la política del endpoint.

## Requisitos previos

Completa primero [minimal APIs y controladores](../14-minimal-apis-controllers/). Ya debes comprender los códigos HTTP, el orden del middleware y la inyección de dependencias.

## Validar un token, no solo decodificarlo

La prueba local configura el [manejador JWT bearer](https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication) con issuer, audience, clave de firma y validación de vida útil. Decodificar los tres segmentos Base64Url no es autenticar: aún hay que validar la firma y todos los claims relevantes.

Las claves se generan en memoria para un solo proceso. Ningún token entra en stdout, fixtures, control de versiones ni el sitio. Un tiempo fijo del curso gobierna la vida útil, así que un token caducado sigue caducado en cada runner.

```text
== JWT bearer authentication rejects unusable credentials
missing token: 401
malformed token: 401
expired token: 401
wrong signature: 401
```

## Una política expresa el permiso de aplicación

El endpoint exige `CanReadScales`, una política que requiere el claim `scope=scales.read`. Un token bien firmado sin ese claim está autenticado pero prohibido; el token con el claim llega al manejador:

```text
== A policy distinguishes authenticated from authorized
without required claim: 403
with required claim: 200 C major
```

El experimento demuestra el comportamiento local de ASP.NET Core, no un despliegue OAuth2. Producción aún necesita un servidor de autorización confiable, rotación y descubrimiento de claves, HTTPS, un contrato deliberado de mapeo de claims y una audience por resource server. Una API de producción no debe crear sus propios access tokens.

## Ejecutar la prueba

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l16
```

La salida comprobada está en [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l16.txt).

## Ejercicios

1. Añade una política que acepte `scales.read` o el rol `admin` y prueba ambas ramas.
2. Añade un issuer incorrecto y una audience incorrecta a la matriz 401 sin imprimir ningún token.
3. Sustituye la clave simétrica del curso por la validación de una clave pública asimétrica local.

<details>
<summary>Soluciones</summary>

1. Escribe un `AuthorizationHandler` o usa `RequireAssertion`; no cambies autenticación y verifica que una identidad válida pero insuficiente aún recibe 403.
2. Parametriza issuer y audience en la fábrica, escribe solo el estado y conserva el validador temporal fijo.
3. Crea un par RSA efímero, firma con la clave privada y configura validación solo con la clave pública. Libera ambas claves y no publiques clave ni token.

</details>
