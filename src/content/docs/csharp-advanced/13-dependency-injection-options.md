---
title: 13. Dependency injection and options
description: Make singleton, scoped and transient lifetimes explicit ownership rules; detect captive dependencies; use keyed services and validate options at the boundary.
sidebar:
  order: 13
---

[ASP.NET Core dependency injection](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection) is an ownership system. A lifetime says how long one instance and its state may be shared.

## Lifetimes are not performance hints

- **singleton:** one instance for the root provider; it must be thread-safe and cannot capture request-scoped state;
- **scoped:** one instance per explicit scope, normally one HTTP request;
- **transient:** a new instance per resolution; disposable transients are still owned by their resolving container.

The executable lesson proves identity across resolutions and enables scope validation. A singleton constructor that requests a scoped service is rejected:

```text
same scope returns same instance: True
singleton returns same instance: True
different scopes return different instances: True
captive scoped dependency rejected: True
```

[Keyed services](https://learn.microsoft.com/aspnet/core/fundamentals/dependency-injection#keyed-services) select an implementation by an explicit key. Use them when the key is part of composition policy, not as a service locator spread through domain code.

## Options are a configuration contract

[`IOptions<T>`](https://learn.microsoft.com/dotnet/core/extensions/options) is a singleton view, `IOptionsSnapshot<T>` recomputes per scope, and `IOptionsMonitor<T>` observes changes. Reloadability is not automatically safe: decide whether an in-flight operation sees the old or new value and whether the setting can change without rebuilding dependent state.

The lesson configures an invalid capacity and proves `OptionsValidationException` is raised. In hosted applications, `ValidateOnStart` moves that failure to startup rather than the first request.

## Run the proof

```bash
dotnet run --project code/csharp-advanced/Advanced -c Release -- l13
```

The checked transcript is [`expected/l13.txt`](https://github.com/spareilleux/learn/blob/main/code/csharp-advanced/expected/l13.txt).

## Exercises

1. Inject a scoped repository into a singleton cache and enable `ValidateScopes`. Repair the ownership without resolving from the root provider.
2. Model two keyed formatters, then move key selection to the composition root.
3. Reload a capacity option while work is in flight and write the invariant that must remain true.

<details>
<summary>Solutions</summary>

1. Make the consumer scoped, pass immutable data into the singleton, or inject `IServiceScopeFactory` only into an infrastructure coordinator that creates and disposes each scope explicitly.
2. Resolve the keyed formatter when wiring the use case and inject the unkeyed contract into domain code. The domain should not know DI keys.
3. Existing queues cannot silently change capacity. Apply the new value to newly created queues, or perform an explicit migration with admission paused and observable completion.

</details>
