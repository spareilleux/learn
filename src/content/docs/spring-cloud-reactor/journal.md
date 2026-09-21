---
title: Journal
description: Dated progress notes for the Spring Boot, Spring Cloud and Reactor course — versions chosen, surprises coming from ASP.NET Core, mistakes, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — Spring Boot seen from ASP.NET Core
- [x] Lesson 2 — Reactor: `Mono` and `Flux`
- [x] Lesson 3 — Reactor under the hood
- [x] Lesson 4 — WebFlux
- [x] Lesson 5 — Reactive data access with R2DBC and Spring Data
- [x] Lesson 6 — Spring Cloud Gateway
- [ ] Lesson 7 — Centralised configuration with Spring Cloud Config
- [ ] Lesson 8 — Service discovery and client-side load balancing
- [ ] Lesson 9 — Resilience with Resilience4j and Spring Cloud Circuit Breaker
- [ ] Lesson 10 — Messaging with Spring Cloud Stream
- [ ] Lesson 11 — Observability with Micrometer
- [ ] Lesson 12 — Testing a set of Spring services

## 2026-09-14 — Lessons 1 to 4

- The versions are the ones [start.spring.io](https://start.spring.io/) offered by default on 2026-09-14: Spring Boot 4.1.1, with Spring Framework 7.0.9, Reactor 3.8.7, Jackson 3, Tomcat 11 and Netty 4.2. The Spring Cloud release train is 2025.1.3 "Oakwood", which spring.io pairs with Spring Boot 4.0.x and 4.1.x. Its BOM still declares `spring-boot.version` 4.0.8; the course imports it under the Boot 4.1.1 parent, and nothing in lessons 1 to 4 uses Spring Cloud yet, so whether the combination holds is for lesson 6 to show.
- The code is a Maven multi-module project in [`code/spring-cloud-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor): a shared `music` module (notes, modes, scales, triads) and one module per lesson. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/check.sh) runs the tests, which compare every quoted output with a file in `expected/`, runs the lesson 1 JAR with environment variables, and runs the four C# programs with `dotnet run` on .NET 10. CI runs it on Windows, Linux and macOS.
- Every HTTP server in the tests starts on a free local port, and the C# minimal API listens on port 0 and calls itself. No Docker, no external service.
- None of the GuitarAlchemist repositories has Spring or Reactor code, so these lessons have no practical case yet; the running example is a scales service written for the course.

**Surprises coming from ASP.NET Core:**

- Spring Boot 4 renamed the web starter: `spring-boot-starter-webmvc`, where most examples on the web say `spring-boot-starter-web`. The Initializr API still wants `dependencies=web`, and answered `webmvc` with a 400, "Unknown dependency 'webmvc'".
- Also new in Spring Boot 4: the `WebClient.Builder` bean needs `spring-boot-starter-webclient`, and `HealthIndicator` and `@AutoConfigureWebTestClient` moved to new packages.
- A missing or ambiguous dependency stops a Spring application at startup with a report that suggests a fix, where `IServiceCollection` takes the last registration and finds a missing one at the first resolution, unless `ValidateOnBuild` is on.
- Jackson writes a `ProblemDetail` in alphabetical order; ASP.NET Core starts with `type` and `title`. A `ProblemDetail` returned by a functional endpoint with `bodyValue` goes out as `application/json` with the title "Bad Request"; the same object from an `@ExceptionHandler` is `application/problem+json` with `instance`.
- Spring writes server-sent events as `data:G`, .NET 10 as `data: G`. Both are valid.
- `Flux.log()` without SLF4J on the class path writes to the console with its own format, and a `subscribe` without an error handler logs `ErrorCallbackNotImplemented` instead of throwing.
- `Mono.fromCallable(...).block()` on a `parallel()` thread doesn't trigger Reactor's "block() is not supported" check: `MonoCallable` runs the callable directly. BlockHound caught it.
- `onBackpressureBuffer(3)` doesn't signal its overflow when it happens: the error waits behind the buffered values, so a subscriber that has requested one value sees nothing until it asks for more.
- On the .NET side, `Channel.CreateBounded` with `BoundedChannelFullMode.DropWrite` makes `TryWrite` return `true` for the items it drops.
- A file-based C# app with `#:sdk Microsoft.NET.Sdk.Web` publishes with Native AOT by default: `CreateSlimBuilder` and anonymous types then answered a 500 with IL2026 and IL3050 warnings, until `#:property PublishAot=false`.
- `dotnet build file.cs -v quiet -nologo` failed with MSB4025: options after or before a file-based app broke the build on SDK 10.0.112, and `dotnet build file.cs` alone works. *To verify*: whether that is intended.

**Things I got wrong first:**

- The first CI run failed on Linux and macOS: the startup log test captured the lines Tomcat prints when the context closes, and another thread prints them in no fixed order. The test now reads the log before closing the context.
- The second run failed on macOS only. The progressions endpoint used `Flux.interval`, which fails with `OverflowException` when Netty hasn't requested the next event in time. `delayElements` waits for demand; lesson 4 tells the story.
- I named a `@Bean` method `scaleRoutes` in a class called `ScaleRoutes`: same bean name, and the application refused to start with `BeanDefinitionOverrideException`.
- The Surefire JVM printed Mockito's "A Java agent has been loaded dynamically" warning, although no test mocks anything: the Spring test starter initialises Mockito. Loading it with `-javaagent`, as in lesson 11 of the Java course, removed it.
- A test started with `SpringApplication` logged Surefire's `ForkedBooter` as the application class until `setMainApplicationClass`.
- My first draft of exercise 2 in lesson 3 asserted that eight lookups took less than 160 ms. Timing assertions fail on busy CI runners; the test now counts the lookups running at the same time.

## 2026-09-21 — Lessons 5 and 6

- Lesson 5 uses an in-memory H2 database through R2DBC. Two deterministic integration tests prove insert/query signal flow and transaction rollback without Docker or an external database.
- Lesson 6 starts Spring Cloud Gateway and a Reactor Netty upstream on dynamic loopback ports. Two integration tests prove route matching, prefix stripping, header propagation and forwarding, plus the unmatched-path `404` case.
- `mvn -B -pl l05-r2dbc,l06-gateway -am test` passed on Java 25 with four tests, no failures and no errors. Spring Cloud 2025.1.3 therefore supports this bounded Gateway scenario under the Spring Boot 4.1.1 parent; that is evidence for these routes, not a blanket compatibility claim.

## Open questions

- Spring Cloud 2025.1.3's BOM declares Spring Boot 4.0.8. The lesson 6 Gateway scenario passes under Boot 4.1.1; broader module compatibility remains *to verify*.
- Throughput of the same endpoint on Spring MVC with virtual threads and on WebFlux, measured on this machine: *to verify* in lesson 11.
- What the server sees when a `WebClient` subscriber cancels a server-sent event stream after two events: *to verify*.
- The Initializr, `java -jar` and `curl` commands of lessons 1 and 4 ran on Windows only; on Linux and macOS they are *to verify*, while CI runs the equivalent tests there.
