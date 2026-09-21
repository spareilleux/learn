---
title: Reactive data with R2DBC and Spring Data
description: Persist and stream rows without hiding blocking JDBC work inside a Reactor pipeline.
sidebar:
  order: 5
---

[R2DBC](https://r2dbc.io/) is a reactive database contract. Unlike JDBC, it does not dedicate a blocked thread to each query. [Spring Data R2DBC](https://docs.spring.io/spring-data/relational/reference/r2dbc.html) maps rows and composes database work as `Mono` and `Flux`.

## The boundary, not just the return type

Returning `Flux<Row>` around a JDBC call is still blocking. A true R2DBC driver produces Reactive Streams signals from connection acquisition through row decoding. The lesson module uses the all-Java [H2 R2DBC driver](https://github.com/r2dbc/r2dbc-h2) in memory, so the same test runs on Windows, Linux and macOS without Docker.

```java
@Table("voicing")
public record Voicing(@Id Long id, String symbol, int fret) {
    public static Voicing newVoicing(String symbol, int fret) {
        return new Voicing(null, symbol, fret);
    }
}
```

`R2dbcEntityTemplate` is the direct counterpart of using an EF Core `DbContext` without hiding it behind a generic repository:

```java
public Mono<Voicing> save(Voicing voicing) {
    return template.insert(voicing);
}

public Flux<Voicing> findBySymbol(String symbol) {
    return template.select(Voicing.class)
            .matching(Query.query(Criteria.where("symbol").is(symbol)))
            .all();
}
```

Nothing executes until subscription. The test chains schema creation, inserts and selection, then verifies the exact signal sequence with [`StepVerifier`](https://projectreactor.io/docs/test/release/api/reactor/test/StepVerifier.html). `block()` appears only in test setup, outside the pipeline being taught.

Run the evidence:

```text
mvn -B -pl l05-r2dbc -am test
```

## Transactions are publishers too

R2DBC transactions live on a connection and are asynchronous. The second test begins a transaction, inserts `G7`, rolls it back and proves that the following query is empty. Application code normally uses [`R2dbcTransactionManager`](https://docs.spring.io/spring-framework/reference/data-access/transaction/programmatic.html) and `TransactionalOperator`; the explicit connection makes the lifecycle visible.

Do not share one mutable connection between subscribers, call blocking JDBC code on the event loop, or rely on generated IDs before the insert publisher completes. Backpressure controls row delivery, not database capacity: connection-pool limits still matter.

## Exercises

1. Add `findAtOrAboveFret(int fret)` and return rows ordered by fret.

<details>
<summary>Solution</summary>

Use `Query.query(Criteria.where("fret").greaterThanOrEquals(fret)).sort(Sort.by("fret"))`, then verify the ordered values with `StepVerifier.expectNextMatches`.

</details>

2. Insert two rows inside one transaction, force an error after the second insert, and prove that neither row remains.

<details>
<summary>Solution</summary>

Compose both statements on the same connection, append `Mono.error`, and use `onErrorResume` only after `rollbackTransaction()`. The important invariant is atomicity, not the exception text.

</details>

3. Explain when JDBC on virtual threads is simpler than R2DBC.

<details>
<summary>Solution</summary>

Choose JDBC when the driver, ORM and team are blocking-first and concurrency is moderate. Choose R2DBC when the whole request path is reactive and high concurrency would otherwise consume many blocked threads. A reactive controller alone is not sufficient evidence.

</details>

## Sources

- [Spring Data R2DBC reference](https://docs.spring.io/spring-data/relational/reference/r2dbc.html)
- [R2DBC specification](https://r2dbc.io/spec/1.0.0.RELEASE/spec/html/)
- [Spring transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)
