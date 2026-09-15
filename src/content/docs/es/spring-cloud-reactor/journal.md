---
title: Diario
description: Notas de progreso fechadas del curso de Spring Boot, Spring Cloud y Reactor — versiones elegidas, sorpresas viniendo de ASP.NET Core, errores y puntos por verificar.
sidebar:
  order: 99
---

## Progreso

- [x] Lección 1 — Spring Boot visto desde ASP.NET Core
- [x] Lección 2 — Reactor: `Mono` y `Flux`
- [x] Lección 3 — Reactor por dentro
- [x] Lección 4 — WebFlux
- [ ] Lección 5 — Acceso reactivo a datos con R2DBC y Spring Data
- [ ] Lección 6 — Spring Cloud Gateway
- [ ] Lección 7 — Configuración centralizada con Spring Cloud Config
- [ ] Lección 8 — Descubrimiento de servicios y balanceo de carga del lado del cliente
- [ ] Lección 9 — Resiliencia con Resilience4j y Spring Cloud Circuit Breaker
- [ ] Lección 10 — Mensajería con Spring Cloud Stream
- [ ] Lección 11 — Observabilidad con Micrometer
- [ ] Lección 12 — Probar un conjunto de servicios Spring

## 2026-09-14 — Lecciones 1 a 4

- Las versiones son las que [start.spring.io](https://start.spring.io/) ofrecía por defecto el 2026-09-14: Spring Boot 4.1.1, con Spring Framework 7.0.9, Reactor 3.8.7, Jackson 3, Tomcat 11 y Netty 4.2. El release train de Spring Cloud es 2025.1.3 "Oakwood", que spring.io asocia con Spring Boot 4.0.x y 4.1.x. Su BOM sigue declarando `spring-boot.version` 4.0.8; el curso lo importa bajo el padre Boot 4.1.1, y nada en las lecciones 1 a 4 usa todavía Spring Cloud, así que será la lección 6 la que muestre si la combinación se sostiene.
- El código es un proyecto Maven multimódulo en [`code/spring-cloud-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor): un módulo `music` compartido (notas, modos, escalas, tríadas) y un módulo por lección. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/check.sh) ejecuta las pruebas, que comparan cada salida citada con un archivo de `expected/`, ejecuta el JAR de la lección 1 con variables de entorno, y ejecuta los cuatro programas C# con `dotnet run` sobre .NET 10. La CI lo ejecuta en Windows, Linux y macOS.
- Todos los servidores HTTP de las pruebas arrancan en un puerto local libre, y la minimal API de C# escucha en el puerto 0 y se llama a sí misma. Sin Docker, sin servicios externos.
- Ninguno de los repositorios de GuitarAlchemist tiene código Spring o Reactor, así que estas lecciones aún no tienen caso práctico; el ejemplo conductor es un servicio de escalas escrito para el curso.

**Sorpresas viniendo de ASP.NET Core:**

- Spring Boot 4 renombró el starter web: `spring-boot-starter-webmvc`, donde la mayoría de los ejemplos de la web dicen `spring-boot-starter-web`. La API de Initializr sigue queriendo `dependencies=web`, y respondió a `webmvc` con un 400, "Unknown dependency 'webmvc'".
- También nuevo en Spring Boot 4: el bean `WebClient.Builder` necesita `spring-boot-starter-webclient`, y `HealthIndicator` y `@AutoConfigureWebTestClient` se movieron a paquetes nuevos.
- Una dependencia que falta o que es ambigua detiene una aplicación Spring al arrancar con un informe que sugiere una solución, mientras que `IServiceCollection` toma el último registro y descubre uno que falta en la primera resolución, salvo que `ValidateOnBuild` esté activado.
- Jackson escribe un `ProblemDetail` en orden alfabético; ASP.NET Core empieza por `type` y `title`. Un `ProblemDetail` devuelto por un endpoint funcional con `bodyValue` sale como `application/json` con el título "Bad Request"; el mismo objeto desde un `@ExceptionHandler` es `application/problem+json` con `instance`.
- Spring escribe los server-sent events como `data:G`, .NET 10 como `data: G`. Ambos son válidos.
- `Flux.log()` sin SLF4J en el class path escribe en la consola con su propio formato, y un `subscribe` sin manejador de errores registra `ErrorCallbackNotImplemented` en lugar de lanzar una excepción.
- `Mono.fromCallable(...).block()` en un hilo de `parallel()` no dispara la comprobación "block() is not supported" de Reactor: `MonoCallable` ejecuta el callable directamente. BlockHound lo detectó.
- `onBackpressureBuffer(3)` no señala su desbordamiento en el momento en que ocurre: el error espera detrás de los valores del buffer, así que un suscriptor que ha pedido un valor no ve nada hasta que pide más.
- Del lado .NET, `Channel.CreateBounded` con `BoundedChannelFullMode.DropWrite` hace que `TryWrite` devuelva `true` para los elementos que descarta.
- Una app C# basada en archivo con `#:sdk Microsoft.NET.Sdk.Web` publica con Native AOT por defecto: `CreateSlimBuilder` y los tipos anónimos respondían entonces un 500 con advertencias IL2026 e IL3050, hasta `#:property PublishAot=false`.
- `dotnet build file.cs -v quiet -nologo` falló con MSB4025: las opciones antes o después de una app basada en archivo rompían la compilación con el SDK 10.0.112, y `dotnet build file.cs` a secas funciona. *Por verificar*: si es intencionado.

**Lo que hice mal al principio:**

- La primera ejecución de CI falló en Linux y macOS: la prueba del log de arranque capturaba las líneas que Tomcat imprime al cerrarse el contexto, y otro hilo las imprime sin un orden fijo. La prueba ahora lee el log antes de cerrar el contexto.
- La segunda ejecución falló solo en macOS. El endpoint de progresiones usaba `Flux.interval`, que falla con `OverflowException` cuando Netty no ha pedido a tiempo el siguiente evento. `delayElements` espera a la demanda; la lección 4 cuenta la historia.
- Llamé `scaleRoutes` a un método `@Bean` de una clase llamada `ScaleRoutes`: mismo nombre de bean, y la aplicación se negó a arrancar con `BeanDefinitionOverrideException`.
- La JVM de Surefire imprimía la advertencia de Mockito "A Java agent has been loaded dynamically", aunque ninguna prueba simula nada: el starter de pruebas de Spring inicializa Mockito. Cargarlo con `-javaagent`, como en la lección 11 del curso de Java, la eliminó.
- Una prueba arrancada con `SpringApplication` registraba el `ForkedBooter` de Surefire como clase de la aplicación hasta `setMainApplicationClass`.
- Mi primer borrador del ejercicio 2 de la lección 3 afirmaba que ocho búsquedas tardaban menos de 160 ms. Las aserciones de tiempo fallan en los runners de CI cargados; la prueba ahora cuenta las búsquedas que se ejecutan al mismo tiempo.

## Preguntas abiertas

- El BOM de Spring Cloud 2025.1.3 declara Spring Boot 4.0.8: ¿algún módulo de Spring Cloud se comporta mal con Boot 4.1.1? *Por verificar* en la lección 6.
- Rendimiento del mismo endpoint en Spring MVC con hilos virtuales y en WebFlux, medido en esta máquina: *por verificar* en la lección 11.
- Lo que ve el servidor cuando un suscriptor de `WebClient` cancela un stream de server-sent events tras dos eventos: *por verificar*.
- Los comandos de Initializr, `java -jar` y `curl` de las lecciones 1 y 4 solo se ejecutaron en Windows; en Linux y macOS están *por verificar*, mientras que la CI ejecuta allí las pruebas equivalentes.
