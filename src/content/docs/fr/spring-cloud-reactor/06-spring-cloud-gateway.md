---
title: Spring Cloud Gateway
description: Router, réécrire et tester le trafic à la périphérie sans transformer la gateway en service métier.
sidebar:
  order: 6
---

[Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/reference/) est le pendant réactif de YARP : les prédicats choisissent une route, les filtres transforment l'échange et l'URI cible choisit la destination.

## Une route périphérique étroite

La gateway expose `/api/scales/**`, retire le préfixe public `/api` et ajoute un en-tête traçable :

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

La route porte la politique de transport, pas les décisions musicales. Authentification, limites et corrélation conviennent à la périphérie; construire un accord, non. Chaque filtre modifie aussi les pannes possibles : gardez la chaîne courte et observable.

## Un vrai test sans service externe

Le test d'intégration lie les deux processus à des ports attribués par l'OS. Un petit upstream Reactor Netty renvoie son chemin et l'en-tête; la gateway démarre avec `@SpringBootTest` et reçoit l'URI via `@DynamicPropertySource`.

```java
upstream = HttpServer.create().port(0)
        .route(routes -> routes.get("/scales/C", (request, response) -> response
                .sendString(Mono.just(request.uri() + "|"
                        + request.requestHeaders().get("X-Course")))))
        .bindNow();
```

```text
GET /api/scales/C -> /scales/C|spring-cloud-gateway
GET /other        -> 404
```

```text
mvn -B -pl l06-gateway -am test
```

Cela couvre prédicat, ordre des filtres, transfert et chemin sans route. Cela ne prouve ni latence de production, ni terminaison TLS, ni confiance envers les en-têtes proxy.

## Exercices

1. Ajoutez `/api/progressions/**` en conservant le chemin après retrait de `/api`.

<details>
<summary>Solution</summary>

Ajoutez une route avec un ID distinct, `path("/api/progressions/**")` et `stripPrefix(1)`. Testez l'URI reçue par l'upstream plutôt que l'objet route.

</details>

2. Ajoutez à la réponse l'ID de la route choisie.

<details>
<summary>Solution</summary>

Employez `addResponseHeader("X-Route", "scales")` et `WebTestClient.expectHeader()`. N'exposez pas les noms d'hôtes internes.

</details>

3. Pourquoi ne pas appliquer automatiquement un retry à toutes les requêtes ?

<details>
<summary>Solution</summary>

Un retry peut dupliquer un effet non idempotent et multiplier la charge pendant une panne. Restreignez méthodes et erreurs, bornez les tentatives et mesurez l'amplification. La leçon 9 traite la résilience explicitement.

</details>

## Sources

- [Spring Cloud Gateway reference](https://docs.spring.io/spring-cloud-gateway/reference/)
- [Route predicates](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/request-predicates-factories.html)
- [Gateway filter factories](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/gatewayfilter-factories.html)
