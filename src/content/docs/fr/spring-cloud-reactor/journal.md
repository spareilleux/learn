---
title: Journal
description: Notes de progression datées du cours Spring Boot, Spring Cloud et Reactor — versions choisies, surprises en venant d'ASP.NET Core, erreurs et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Leçon 1 — Spring Boot vu depuis ASP.NET Core
- [x] Leçon 2 — Reactor : `Mono` et `Flux`
- [x] Leçon 3 — Reactor sous le capot
- [x] Leçon 4 — WebFlux
- [ ] Leçon 5 — Accès réactif aux données avec R2DBC et Spring Data
- [ ] Leçon 6 — Spring Cloud Gateway
- [ ] Leçon 7 — Configuration centralisée avec Spring Cloud Config
- [ ] Leçon 8 — Découverte de services et répartition de charge côté client
- [ ] Leçon 9 — Résilience avec Resilience4j et Spring Cloud Circuit Breaker
- [ ] Leçon 10 — Messagerie avec Spring Cloud Stream
- [ ] Leçon 11 — Observabilité avec Micrometer
- [ ] Leçon 12 — Tester un ensemble de services Spring

## 2026-09-14 — Leçons 1 à 4

- Les versions sont celles que [start.spring.io](https://start.spring.io/) proposait par défaut le 2026-09-14 : Spring Boot 4.1.1, avec Spring Framework 7.0.9, Reactor 3.8.7, Jackson 3, Tomcat 11 et Netty 4.2. Le release train Spring Cloud est 2025.1.3 « Oakwood », que spring.io associe à Spring Boot 4.0.x et 4.1.x. Son BOM déclare encore `spring-boot.version` 4.0.8 ; le cours l'importe sous le parent Boot 4.1.1, et rien dans les leçons 1 à 4 n'utilise encore Spring Cloud : c'est donc à la leçon 6 de montrer si la combinaison tient.
- Le code est un projet Maven multimodule dans [`code/spring-cloud-reactor`](https://github.com/spareilleux/learn/tree/main/code/spring-cloud-reactor) : un module `music` partagé (notes, modes, gammes, triades) et un module par leçon. [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/spring-cloud-reactor/check.sh) exécute les tests, qui comparent chaque sortie citée à un fichier de `expected/`, lance le JAR de la leçon 1 avec des variables d'environnement, et exécute les quatre programmes C# avec `dotnet run` sur .NET 10. La CI le lance sous Windows, Linux et macOS.
- Chaque serveur HTTP des tests démarre sur un port local libre, et la minimal API C# écoute sur le port 0 et s'appelle elle-même. Pas de Docker, pas de service externe.
- Aucun des dépôts GuitarAlchemist ne contient de code Spring ou Reactor : ces leçons n'ont donc pas encore de cas pratique, et l'exemple fil rouge est un service de gammes écrit pour le cours.

**Surprises en venant d'ASP.NET Core :**

- Spring Boot 4 a renommé le starter web : `spring-boot-starter-webmvc`, là où la plupart des exemples du web disent `spring-boot-starter-web`. L'API d'Initializr veut toujours `dependencies=web`, et a répondu à `webmvc` par une 400, "Unknown dependency 'webmvc'".
- Autre nouveauté de Spring Boot 4 : le bean `WebClient.Builder` a besoin de `spring-boot-starter-webclient`, et `HealthIndicator` et `@AutoConfigureWebTestClient` ont changé de package.
- Une dépendance manquante ou ambiguë arrête une application Spring au démarrage avec un rapport qui suggère une correction, là où `IServiceCollection` prend le dernier enregistrement et ne découvre une dépendance manquante qu'à la première résolution, sauf si `ValidateOnBuild` est activé.
- Jackson écrit un `ProblemDetail` dans l'ordre alphabétique ; ASP.NET Core commence par `type` et `title`. Un `ProblemDetail` renvoyé par un endpoint fonctionnel avec `bodyValue` part en `application/json` avec le titre "Bad Request" ; le même objet renvoyé par un `@ExceptionHandler` est en `application/problem+json` avec `instance`.
- Spring écrit les server-sent events sous la forme `data:G`, .NET 10 sous la forme `data: G`. Les deux sont valides.
- `Flux.log()` sans SLF4J sur le class path écrit dans la console avec son propre format, et un `subscribe` sans gestionnaire d'erreur journalise `ErrorCallbackNotImplemented` au lieu de lever une exception.
- `Mono.fromCallable(...).block()` sur un thread `parallel()` ne déclenche pas la vérification "block() is not supported" de Reactor : `MonoCallable` exécute directement le callable. BlockHound l'a détecté.
- `onBackpressureBuffer(3)` ne signale pas son débordement au moment où il se produit : l'erreur attend derrière les valeurs mises en tampon, si bien qu'un subscriber qui a demandé une valeur ne voit rien tant qu'il n'en redemande pas.
- Côté .NET, `Channel.CreateBounded` avec `BoundedChannelFullMode.DropWrite` fait renvoyer `true` à `TryWrite` pour les éléments qu'il abandonne.
- Une application C# basée sur un fichier avec `#:sdk Microsoft.NET.Sdk.Web` se publie par défaut avec Native AOT : `CreateSlimBuilder` et les types anonymes ont alors répondu par une 500 avec des avertissements IL2026 et IL3050, jusqu'à `#:property PublishAot=false`.
- `dotnet build file.cs -v quiet -nologo` a échoué avec MSB4025 : des options placées avant ou après une application basée sur un fichier cassaient le build sur le SDK 10.0.112, alors que `dotnet build file.cs` seul fonctionne. *À vérifier* : si c'est voulu.

**Ce que j'ai d'abord mal fait :**

- La première exécution de la CI a échoué sous Linux et macOS : le test du journal de démarrage capturait les lignes que Tomcat affiche à la fermeture du contexte, et un autre thread les affiche dans un ordre variable. Le test lit désormais le journal avant de fermer le contexte.
- La deuxième exécution a échoué sous macOS seulement. L'endpoint des progressions utilisait `Flux.interval`, qui échoue avec `OverflowException` quand Netty n'a pas demandé l'événement suivant à temps. `delayElements` attend la demande ; la leçon 4 raconte l'histoire.
- J'ai nommé une méthode `@Bean` `scaleRoutes` dans une classe appelée `ScaleRoutes` : même nom de bean, et l'application a refusé de démarrer avec `BeanDefinitionOverrideException`.
- La JVM de Surefire affichait l'avertissement de Mockito "A Java agent has been loaded dynamically", alors qu'aucun test ne mocke quoi que ce soit : le starter de test de Spring initialise Mockito. Le charger avec `-javaagent`, comme dans la leçon 11 du cours Java, l'a fait disparaître.
- Un test démarré avec `SpringApplication` journalisait `ForkedBooter` de Surefire comme classe de l'application, jusqu'à `setMainApplicationClass`.
- Mon premier jet de l'exercice 2 de la leçon 3 affirmait que huit recherches prenaient moins de 160 ms. Les assertions de durée échouent sur les runners de CI chargés ; le test compte désormais les recherches qui s'exécutent en même temps.

## Questions ouvertes

- Le BOM de Spring Cloud 2025.1.3 déclare Spring Boot 4.0.8 : un module Spring Cloud se comporte-t-il mal sous Boot 4.1.1 ? *À vérifier* à la leçon 6.
- Débit du même endpoint sur Spring MVC avec threads virtuels et sur WebFlux, mesuré sur cette machine : *à vérifier* à la leçon 11.
- Ce que voit le serveur quand un subscriber `WebClient` annule un flux de server-sent events après deux événements : *à vérifier*.
- Les commandes Initializr, `java -jar` et `curl` des leçons 1 et 4 n'ont tourné que sous Windows ; sous Linux et macOS, elles sont *à vérifier*, même si la CI y exécute les tests équivalents.
