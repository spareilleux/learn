---
title: 14. Minimal APIs and controllers
description: Compare route-handler binding, endpoint filters, TypedResults, controllers and streamed IAsyncEnumerable responses on one real routing table.
sidebar:
  order: 14
---

[Minimal APIs](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis) and [controllers](https://learn.microsoft.com/aspnet/core/web-api/) both publish endpoints through ASP.NET Core endpoint routing. Choose by composition needs, not by slogans.

## Binding is part of the public contract

A route handler can bind route values, query strings, headers, services and bodies directly from parameters. Make the source explicit when ambiguity would be dangerous. The lesson binds `root` from the route and `notes` from the query, then applies an endpoint filter:

```text
without key: 400; with key: 200 {"root":"C","notes":7}
```

[`TypedResults`](https://learn.microsoft.com/aspnet/core/fundamentals/minimal-apis/responses) preserve concrete response types for tests and OpenAPI metadata. An endpoint filter can validate or decorate a route-handler family, but authorization should use the framework authorization system and endpoint metadata rather than an improvised header filter.

## Where controllers remain deep

Controllers provide conventions for action discovery, model binding, filters, validation responses and larger APIs. The lesson maps a controller and a Minimal API into the same routing table:

```text
controller: 200 {"symbol":"Cmaj7","characters":5}
```

Do not duplicate one use case in both styles. Keep transport binding thin and call the same application seam.

## Streaming

Returning `IAsyncEnumerable<T>` lets JSON serialization consume items asynchronously. The lesson emits three chords as one JSON array. This avoids buffering the whole source in application code, but proxies and formatters may still buffer. For progressive delivery, measure the full path and choose an explicit framing protocol such as NDJSON, SSE or SignalR when appropriate.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l14
```

The checked transcript is [`expected/l14.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l14.txt).

## Exercises

1. Add a negative `notes` value. Define one portable error body and test status, media type and payload.
2. Implement the same application operation behind one Minimal API and one controller adapter without duplicating policy.
3. Cancel the streamed request after the first item and prove the source observes cancellation.

<details>
<summary>Solutions</summary>

1. Reject at the transport boundary with a stable problem-details contract. Validation success is not authorization success.
2. Bind transport inputs into one command/query type, call one application handler, and map its result independently in each adapter.
3. Pass `RequestAborted` into the async iterator, dispose the response early in the client, and assert the iterator's `finally` or cancellation probe ran.

</details>
