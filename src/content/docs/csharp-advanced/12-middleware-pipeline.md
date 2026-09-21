---
title: 12. The middleware pipeline
description: Treat Use, Map and Run as nested control flow whose registration order determines security, failures, routing and short-circuits.
sidebar:
  order: 12
---

[ASP.NET Core middleware](https://learn.microsoft.com/aspnet/core/fundamentals/middleware/) is nested control flow. Code before `next` runs on the way in; code after `next` runs on the way out. Registration order is therefore observable behavior.

## The onion is executable

The lesson registers an outer middleware, a gate and one endpoint. The successful request produces:

```text
GET /ok: 200; outer:before -> endpoint -> outer:after
```

The gate deliberately short-circuits `/blocked`:

```text
GET /blocked: 429; outer:before -> gate:short-circuit -> outer:after
```

The endpoint is absent because the gate did not call `next`. The outer middleware still completes its response path.

## Ordering rules with consequences

- exception handling must wrap code whose exceptions it converts;
- forwarded headers must run before code that reads scheme, host or client IP;
- routing selects an endpoint before authorization evaluates endpoint metadata;
- authentication establishes a principal before authorization checks it;
- response compression and caching must be placed according to which representation they store or transform;
- terminal `Run` middleware ends the branch.

`Map` branches by path; `MapWhen` branches by a predicate; endpoint routing dispatches endpoint metadata. A branch is not a new process or trust boundary.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l12
```

The checked transcript is [`expected/l12.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l12.txt).

## Exercises

1. Put exception handling after an endpoint that throws. Explain why it cannot convert that exception.
2. Add a correlation-id middleware and decide whether a client-supplied ID is trusted, replaced or namespaced.
3. Add a `Map("/admin")` branch and prove that authorization still runs inside it.

<details>
<summary>Solutions</summary>

1. Middleware only wraps components registered after it. Move the handler earlier and keep the original exception in logs while returning a stable problem response.
2. Validate length and character set, preserve the inbound value only as untrusted baggage, and generate the server correlation ID used for logs and responses.
3. Register authentication/authorization in the relevant branch or use endpoint routing with authorization metadata. A path branch alone grants no authority.

</details>
