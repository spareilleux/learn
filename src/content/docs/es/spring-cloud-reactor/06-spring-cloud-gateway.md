---
title: Spring Cloud Gateway
description: Enrutar, reescribir y probar tráfico en el borde sin convertir el gateway en servicio de dominio.
sidebar:
  order: 6
---

[Spring Cloud Gateway](https://docs.spring.io/spring-cloud-gateway/reference/) es el equivalente reactivo de YARP: predicados eligen la ruta, filtros transforman el intercambio y una URI decide el destino.

## Una ruta de borde estrecha

El gateway expone `/api/scales/**`, elimina `/api` y añade una cabecera rastreable:

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

La ruta contiene políticas de transporte, no decisiones musicales. Autenticación, límites y correlación son asuntos del borde; construir acordes no. Cada filtro cambia los fallos posibles: mantén la cadena corta y observable.

## Una prueba real sin servicio externo

La prueba liga ambos procesos a puertos asignados por el sistema. Un upstream Reactor Netty devuelve ruta y cabecera; el gateway arranca con `@SpringBootTest` y recibe la URI mediante `@DynamicPropertySource`.

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

Esto cubre predicado, orden de filtros, reenvío y ruta no encontrada. No demuestra latencia productiva, TLS ni confianza en cabeceras proxy.

## Ejercicios

1. Añade `/api/progressions/**` preservando el camino tras eliminar `/api`.

<details>
<summary>Solución</summary>

Añade una ruta con ID distinto, `path("/api/progressions/**")` y `stripPrefix(1)`. Prueba la URI del upstream, no el objeto route.

</details>

2. Añade a la respuesta el ID de la ruta elegida.

<details>
<summary>Solución</summary>

Usa `addResponseHeader("X-Route", "scales")` y `WebTestClient.expectHeader()`. No expongas nombres internos.

</details>

3. ¿Por qué no aplicar retry automáticamente a toda petición?

<details>
<summary>Solución</summary>

Puede duplicar efectos no idempotentes y multiplicar carga durante un fallo. Limita método, error e intentos y mide la amplificación. La lección 9 añade resiliencia deliberadamente.

</details>

## Fuentes

- [Spring Cloud Gateway reference](https://docs.spring.io/spring-cloud-gateway/reference/)
- [Route predicates](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/request-predicates-factories.html)
- [Gateway filter factories](https://docs.spring.io/spring-cloud-gateway/reference/spring-cloud-gateway-server-webflux/gatewayfilter-factories.html)
