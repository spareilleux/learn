---
title: 11. Hosting, WebApplication and Kestrel
description: Follow ownership from the generic host to WebApplication, Kestrel, DI, lifetime callbacks and graceful shutdown through a real loopback server.
sidebar:
  order: 11
---

[`WebApplication`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/webapplication) is the composition root for configuration, logging, dependency injection, middleware and endpoints. The generic host owns application lifetime; [Kestrel](https://learn.microsoft.com/aspnet/core/fundamentals/servers/kestrel) owns the network transport.

## What the builder actually assembles

`WebApplication.CreateBuilder` loads configuration sources, registers logging and host services, then exposes `Services` and `WebHost` for explicit changes. `Build` freezes that service graph into an application. `StartAsync` starts hosted services and the server; `StopAsync` begins graceful shutdown.

The executable lesson binds Kestrel to an ephemeral loopback port, maps `/health`, makes a real HTTP request and records lifetime callbacks:

```text
started callback observed: True
GET /health: 200 {"status":"ready"}
graceful stop callbacks observed: stopping=True, stopped=True
```

This proves the course composition, not production readiness. Production still needs declared request/body limits, timeouts, forwarded-header trust, TLS termination, readiness behavior and a shutdown budget longer than the longest accepted request.

## Graceful does not mean infinite

`ApplicationStopping` tells code to stop accepting or producing new work. In-flight work should observe cancellation and either finish inside the budget or leave durable recovery evidence. A `BackgroundService` that ignores cancellation can extend shutdown until the host timeout expires.

In containers, align the host shutdown timeout with the orchestrator termination grace period. If the outer deadline is shorter, the process is killed before .NET can complete its graceful path.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l11
```

The checked transcript is [`expected/l11.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l11.txt).

## Exercises

1. Add a slow endpoint that observes `RequestAborted`, begin shutdown, and record whether the request completes inside the host timeout.
2. Set a small Kestrel request-body limit and prove the status returned for a larger body.
3. Put the app behind one proxy and test forwarded headers with one trusted proxy and one spoofed direct request.

<details>
<summary>Solutions</summary>

1. Use a `TaskCompletionSource` to prove the request entered, call `StopAsync` with a bounded token, and make the endpoint log cancellation. The test passes only when the observed behavior matches the declared shutdown contract.
2. Configure the limit before `Build`, send bodies just below and above it, and assert both the status and that the endpoint was not invoked for the rejected body.
3. Configure known proxies/networks explicitly. The direct request must not be able to choose its client identity through `X-Forwarded-For`.

</details>
