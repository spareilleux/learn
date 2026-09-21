---
title: Spring Cloud Gateway
description: Route, rewrite and test traffic at a reactive edge without turning the gateway into a business service.
sidebar:
  order: 6
---

[Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/reference/) is the reactive counterpart of YARP: predicates select a route, filters transform the exchange, and a target URI decides where it goes.

## A narrow edge route

The course gateway exposes `/api/scales/**`, removes the public `/api` prefix and adds one traceable header:

```java
@Bean
RouteLocator courseRoutes(RouteLocatorBuilder routes,
                          @Value("${course.scales-uri}") String scalesUri) {
    return routes.routes()
            .route("scales", route -> route.path("/api/scales/**")
                    .filters(filters -> filters.stripPrefix(1)
                            .addRequestHeader("X-Course", "spring-cloud-gateway"))
                    .uri(scalesUri))
            .build();
}
```

The route owns transport policy, not music-domain decisions. Authentication, rate limits and correlation are reasonable edge concerns; chord construction is not. Every filter also changes failure semantics, so keep the chain short and observable.

## A real test with no external service

The integration test binds both processes to OS-assigned ports. A tiny Reactor Netty upstream echoes its path and header; the gateway starts through `@SpringBootTest` and receives the upstream URI through `@DynamicPropertySource`.

```java
upstream = HttpServer.create().port(0)
        .route(routes -> routes.get("/scales/C", (request, response) -> response
                .sendString(Mono.just(request.uri() + "|"
                        + request.requestHeaders().get("X-Course")))))
        .bindNow();
```

The assertion is deterministic:

```text
GET /api/scales/C -> /scales/C|spring-cloud-gateway
GET /other        -> 404
```

Run it with:

```text
mvn -B -pl l06-gateway -am test
```

This covers predicate matching, filter order, forwarding and an unmatched path. It does not prove production latency, TLS termination or proxy-header trust; those require deployment-specific tests.

## Exercises

1. Add a route for `/api/progressions/**` that preserves the path after removing `/api`.

<details>
<summary>Solution</summary>

Add a second route with a distinct ID, a `path("/api/progressions/**")` predicate and `stripPrefix(1)`. Test the upstream URI rather than inspecting the route object.

</details>

2. Add a response header containing the matched route ID.

<details>
<summary>Solution</summary>

Use `addResponseHeader("X-Route", "scales")` and assert it with `WebTestClient.expectHeader()`. Do not expose internal host names.

</details>

3. Why should a retry filter not cover every request automatically?

<details>
<summary>Solution</summary>

Retries can duplicate non-idempotent effects and multiply load during an outage. Restrict them by method and failure class, bound attempts, and measure retry amplification. Lesson 9 adds resilience deliberately.

</details>

## Sources

- [Spring Cloud Gateway reference](https://docs.spring.io/spring-cloud-gateway/reference/)
- [Route predicates](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/request-predicates-factories.html)
- [Gateway filter factories](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/gatewayfilter-factories.html)
