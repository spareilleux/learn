---
title: Datos reactivos con R2DBC y Spring Data
description: Persistir y transmitir filas sin ocultar llamadas JDBC bloqueantes dentro de Reactor.
sidebar:
  order: 5
---

[R2DBC](https://r2dbc.io/) es un contrato reactivo para bases de datos. A diferencia de JDBC, no mantiene un hilo bloqueado por consulta. [Spring Data R2DBC](https://docs.spring.io/spring-data/relational/reference/r2dbc.html) mapea filas y compone el trabajo como `Mono` y `Flux`.

## La frontera, no solo el tipo devuelto

Envolver JDBC en `Flux<Row>` sigue siendo bloqueante. Un controlador R2DBC real produce señales Reactive Streams desde la conexión hasta la decodificación. El módulo usa [H2 R2DBC](https://github.com/r2dbc/r2dbc-h2) en memoria: la misma prueba funciona en Windows, Linux y macOS sin Docker.

```java
@Table("voicing")
public record Voicing(@Id Long id, String symbol, int fret) {
    public static Voicing newVoicing(String symbol, int fret) {
        return new Voicing(null, symbol, fret);
    }
}
```

`R2dbcEntityTemplate` equivale a usar directamente un `DbContext` de EF Core:

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

Nada ocurre antes de la suscripción. La prueba encadena esquema, inserciones y selección, y verifica las señales con [`StepVerifier`](https://projectreactor.io/docs/test/release/api/reactor/test/StepVerifier.html). `block()` solo aparece en la preparación de la prueba.

```text
mvn -B -pl l05-r2dbc -am test
```

## Las transacciones también son publishers

Una transacción R2DBC pertenece a una conexión y es asíncrona. La segunda prueba inicia una transacción, inserta `G7`, revierte y prueba que la consulta siguiente está vacía. Una aplicación suele usar [`R2dbcTransactionManager`](https://docs.spring.io/spring-framework/reference/data-access/transaction/programmatic.html) y `TransactionalOperator`; la conexión explícita hace visible el ciclo de vida.

No compartas una conexión mutable entre suscriptores, no ejecutes JDBC en el event loop y no uses un ID generado antes de que termine la inserción. La backpressure controla la entrega, no la capacidad de la base de datos.

## Ejercicios

1. Añade `findAtOrAboveFret(int fret)` y ordena por traste.

<details>
<summary>Solución</summary>

Usa `Query.query(Criteria.where("fret").greaterThanOrEquals(fret)).sort(Sort.by("fret"))` y verifica el orden con `StepVerifier.expectNextMatches`.

</details>

2. Inserta dos filas en una transacción, fuerza un error y demuestra que no queda ninguna.

<details>
<summary>Solución</summary>

Compón ambos statements en la misma conexión, añade `Mono.error` y aplica `onErrorResume` solo después de `rollbackTransaction()`. El invariante es la atomicidad.

</details>

3. ¿Cuándo es más sencillo JDBC sobre hilos virtuales?

<details>
<summary>Solución</summary>

Elige JDBC si el driver, el ORM y el equipo son bloqueantes y la concurrencia es moderada. Elige R2DBC si todo el camino es reactivo y la concurrencia consumiría demasiados hilos bloqueados.

</details>

## Fuentes

- [Spring Data R2DBC reference](https://docs.spring.io/spring-data/relational/reference/r2dbc.html)
- [R2DBC specification](https://r2dbc.io/spec/1.0.0.RELEASE/spec/html/)
- [Spring transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)
