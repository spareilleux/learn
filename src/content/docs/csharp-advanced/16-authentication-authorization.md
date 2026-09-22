---
title: 16. Authentication and authorization
description: Validate JWT bearer credentials locally, distinguish 401 from 403, and enforce a claim-based ASP.NET Core policy.
sidebar:
  order: 16
---

[Authentication](https://learn.microsoft.com/aspnet/core/security/authentication/) establishes an identity. [Policy-based authorization](https://learn.microsoft.com/aspnet/core/security/authorization/policies) decides whether that identity may perform an operation. Keeping those steps separate explains the two failure codes:

- `401 Unauthorized`: no usable identity was established;
- `403 Forbidden`: the identity is valid but does not satisfy the endpoint policy.

## Prerequisites

Complete [minimal APIs and controllers](../14-minimal-apis-controllers/) first. You should already understand HTTP status codes, middleware order and dependency injection.

## Validate a token; do not merely decode it

The local proof configures the [JWT bearer handler](https://learn.microsoft.com/aspnet/core/security/authentication/configure-jwt-bearer-authentication) with an issuer, audience, signing key and lifetime validation. Decoding the three Base64Url segments is not authentication: the signature and all relevant claims still need validation.

The signing keys are generated in memory for one process. Tokens never enter stdout, fixtures, source control or the site. A fixed course time drives the lifetime validator, so an expired token stays expired on every runner.

```text
== JWT bearer authentication rejects unusable credentials
missing token: 401
malformed token: 401
expired token: 401
wrong signature: 401
```

## A policy expresses application permission

The endpoint requires a `CanReadScales` policy. That policy requires the `scope=scales.read` claim. A correctly signed token without the claim is authenticated but forbidden; the token with the claim reaches the handler:

```text
== A policy distinguishes authenticated from authorized
without required claim: 403
with required claim: 200 C major
```

This experiment proves local ASP.NET Core behavior, not an OAuth2 deployment. Production still needs a trusted authorization server, key rotation and discovery, HTTPS, a deliberate claim mapping contract, and an audience per resource server. Do not create access tokens inside a production API.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l16
```

The checked transcript is [`expected/l16.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l16.txt).

## Exercises

1. Add a second policy that accepts either `scales.read` or an `admin` role, and test both branches.
2. Add an issuer mismatch and an audience mismatch to the 401 matrix without printing a token.
3. Replace the symmetric course key with validation against a local asymmetric public key.

<details>
<summary>Solutions</summary>

1. Write a custom `AuthorizationHandler` or use `RequireAssertion`; keep authentication unchanged and verify valid-but-insufficient identities still return 403.
2. Parameterize the token factory's issuer and audience, send only the resulting status to the transcript, and retain the fixed lifetime validator.
3. Create an ephemeral RSA key pair, sign with the private key, and configure validation with only the public key. Dispose both keys and publish neither the key nor the token.

</details>
