---
title: Données réactives avec R2DBC et Spring Data
description: Persister et diffuser des lignes sans dissimuler des appels JDBC bloquants dans un pipeline Reactor.
sidebar:
  order: 5
---

[R2DBC](https://r2dbc.io/) est un contrat réactif pour les bases de données. Contrairement à JDBC, il n'immobilise pas un thread pour chaque requête. [Spring Data R2DBC](https://docs.spring.io/spring-data/relational/reference/r2dbc.html) mappe les lignes et compose le travail sous forme de `Mono` et de `Flux`.

## La frontière, pas seulement le type retourné

Envelopper un appel JDBC dans `Flux<Row>` reste bloquant. Un vrai pilote R2DBC produit des signaux Reactive Streams depuis l'acquisition de la connexion jusqu'au décodage des lignes. Le module utilise le [pilote R2DBC H2](https://github.com/r2dbc/r2dbc-h2) en mémoire : le même test tourne sous Windows, Linux et macOS, sans Docker.

```java
@Table("voicing")
public record Voicing(@Id Long id, String symbol, int fret) {
    public static Voicing newVoicing(String symbol, int fret) {
        return new Voicing(null, symbol, fret);
    }
}
```

`R2dbcEntityTemplate` correspond à l'utilisation directe d'un `DbContext` EF Core, sans le cacher derrière un repository générique :

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

Rien ne s'exécute avant l'abonnement. Le test chaîne création du schéma, insertions et sélection, puis vérifie les signaux avec [`StepVerifier`](https://projectreactor.io/docs/test/release/api/reactor/test/StepVerifier.html). `block()` n'apparaît que dans la préparation du test, hors du pipeline étudié.

```text
mvn -B -pl l05-r2dbc -am test
```

## Les transactions sont aussi des publishers

Une transaction R2DBC appartient à une connexion et reste asynchrone. Le second test démarre une transaction, insère `G7`, annule la transaction et prouve que la requête suivante est vide. En application, on emploie plutôt [`R2dbcTransactionManager`](https://docs.spring.io/spring-framework/reference/data-access/transaction/programmatic.html) et `TransactionalOperator`; la connexion explicite rend ici le cycle de vie visible.

Ne partagez pas une connexion mutable entre plusieurs abonnés, n'exécutez pas JDBC sur l'event loop et n'utilisez pas un identifiant généré avant la fin du publisher d'insertion. La backpressure contrôle la livraison des lignes, pas la capacité de la base : la taille du pool compte toujours.

## Exercices

1. Ajoutez `findAtOrAboveFret(int fret)` et triez les résultats par case.

<details>
<summary>Solution</summary>

Utilisez `Query.query(Criteria.where("fret").greaterThanOrEquals(fret)).sort(Sort.by("fret"))`, puis vérifiez l'ordre avec `StepVerifier.expectNextMatches`.

</details>

2. Insérez deux lignes dans une transaction, forcez une erreur et prouvez qu'aucune ne subsiste.

<details>
<summary>Solution</summary>

Composez les deux statements sur la même connexion, ajoutez `Mono.error`, puis n'employez `onErrorResume` qu'après `rollbackTransaction()`. L'invariant est l'atomicité, pas le texte de l'exception.

</details>

3. Quand JDBC sur threads virtuels est-il plus simple que R2DBC ?

<details>
<summary>Solution</summary>

Choisissez JDBC si le pilote, l'ORM et l'équipe sont conçus autour du blocage et si la concurrence reste modérée. Choisissez R2DBC quand tout le chemin est réactif et que la concurrence immobiliserait trop de threads. Un contrôleur réactif seul ne suffit pas.

</details>

## Sources

- [Spring Data R2DBC reference](https://docs.spring.io/spring-data/relational/reference/r2dbc.html)
- [R2DBC specification](https://r2dbc.io/spec/1.0.0.RELEASE/spec/html/)
- [Spring transaction management](https://docs.spring.io/spring-framework/reference/data-access/transaction.html)
