---
title: Journal
description: Notes de progression datées du cours Java — essais, surprises, cas pratiques dans mes dépôts et points à vérifier.
sidebar:
  order: 99
---

## Progression

- [x] Leçon 1 — Le JDK et les outils de build
- [x] Leçon 2 — Types, égalité et opérateurs
- [x] Leçon 3 — Classes, records et enums
- [x] Leçon 4 — Génériques et effacement de type
- [x] Leçon 5 — Exceptions, `null` et `Optional`
- [x] Leçon 6 — Lambdas et interfaces fonctionnelles
- [x] Leçon 7 — Collections et Streams
- [x] Leçon 8 — Pattern matching
- [x] Leçon 9 — Concurrence et threads virtuels
- [x] Leçon 10 — Maven et Gradle en profondeur
- [x] Leçon 11 — Tests
- [x] Leçon 12 — La bibliothèque standard du quotidien
- [ ] Leçon 13 — La JVM à l'exécution
- [ ] Leçon 14 — Annotations, réflexion et modules

## 2026-09-13 — Leçon 12

- Les exemples de la leçon 12, leurs équivalents C# et trois extraits qui ne compilent pas tournent en CI sous Windows, Linux et macOS ; le projet principal compte désormais 123 tests. Chaque appel HTTP va vers un serveur local, le `HttpServer` du JDK côté Java et `HttpListener` côté C#, pour que la sortie ne dépende pas du réseau.
- `InvariantGlobalization` était activé dans le projet C#. La leçon 12 a besoin des fuseaux horaires IANA et de cultures nommées : ICU est donc activé, et `Program.cs` règle la culture courante sur la culture invariante. Les sorties des leçons 2 à 9 n'ont pas changé.

**Surprises en venant de C# :**

- Le `HttpClient` de Java ne suit pas les redirections et n'a pas de timeout de requête tant qu'on ne les définit pas. Du code .NET porté tel quel obtient un 302 au corps vide, ou un appel qui peut attendre indéfiniment.
- Pour une heure locale qui existe deux fois, `ZonedDateTime` choisit le décalage de l'heure d'été et `TimeZoneInfo.GetUtcOffset` celui de l'heure standard : une heure d'écart.
- `YYYY` dans un pattern de date Java a affiché 2027 pour le 31 décembre 2026 avec `Locale.US`, et 2026 avec `Locale.FRANCE`.
- `Files.readString` lève une exception sur de l'UTF-8 invalide, là où `File.ReadAllText` remplace l'octet.
- Un premier essai a affiché `héllo`, lu dans un fichier UTF-8, sous la forme `h�llo` dans Git Bash sous Windows, alors que le fichier lui-même était correct. La JEP 400 laisse `System.out` sur l'encodage de la console ; *à vérifier* : quel encodage Java a choisi dans ce terminal.

**Ce que j'ai d'abord mal fait :**

- Le premier essai C# tournait avec `InvariantGlobalization` activé. `FindSystemTimeZoneById("Europe/Paris")` a levé `TimeZoneNotFoundException` sous Windows, et `new CultureInfo("fr-FR")` a levé « Only the invariant culture is supported in globalization-invariant mode. »
- Le premier essai Java formatait les nombres avec la locale par défaut, qui est `en_CA` sur ma machine et autre chose sur les runners de CI. Les exemples passent désormais une `Locale` partout où la sortie en dépend.

## 2026-09-13 — Leçon 11

- La leçon 11 a son propre projet Maven, [`l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), avec 24 tests. Les messages d'échec que cite la leçon sont produits par `FailureMessagesTest` et comparés à des fichiers texte : une mise à jour de bibliothèque qui modifie un message fait donc échouer le build. `l11/check.sh` couvre le reste : les noms des tests, l'avertissement de Mockito sans l'agent, l'échec de BlockHound sans son flag de JVM, et les erreurs de NullAway.
- La question ouverte de la leçon 5 sur JSpecify et NullAway trouve sa réponse dans cette leçon : NullAway 0.14.1 sur Error Prone 2.50.0 fonctionne sur JDK 25.

**Surprises en venant de C# :**

- Le conflit de la leçon 10 est apparu tout seul dans ce projet. Mockito 5.23.0 demande Byte Buddy 1.17.7, AssertJ 3.27.7 demande 1.18.3, et la règle de la définition la plus proche de Maven a placé Byte Buddy 1.18.3 à côté de `byte-buddy-agent` 1.17.7. Cela fonctionne par chance, parce que le chemin d'AssertJ est plus court et apporte la version la plus récente.
- JUnit 6 met entre guillemets les valeurs CSV dans les noms des tests paramétrés, nombres compris, parce que les valeurs sont encore des chaînes quand le nom est construit.
- Les rapports de Surefire ignorent `@DisplayName` tant qu'une option de reporter n'est pas définie, et sa sortie console a attribué les neuf tests de `PriceCalculatorTest` à sa classe imbriquée.
- Avec Mockito chargé comme agent, la JVM affiche encore « Sharing is only supported for boot loader classes because bootstrap classpath has been appended ». La leçon ne le cite pas ; *à vérifier* : si `-Xshare:off` est la bonne façon de le faire taire.
- BlockHound 1.0.17 a besoin de `-XX:+AllowRedefinitionToAddDeleteMethods`, un flag de JVM déprécié depuis JDK 13, et signale `Thread.sleep` sous le nom `java.lang.Thread.sleepNanos0`, la méthode privée du JDK qu'il instrumente.

**Ce que j'ai d'abord mal fait :**

- La première exécution de NullAway a échoué avec « An unknown compilation problem occurred ». La vraie erreur, une `IllegalAccessError` sur l'API interne de javac, n'est apparue qu'avec `mvn -e`. Error Prone a besoin d'un `.mvn/jvm.config` avec des lignes `--add-exports`.
- J'ai d'abord installé BlockHound avec `BlockHound.install()`, comme le fait son README. Sur JDK 25, cela a échoué avec « Could not self-attach to current VM using external process », et avec `-Djdk.attach.allowAttachSelf=true` avec « Agent JAR loaded but agent failed to initialize ». Seul `-javaagent` associé au flag a fonctionné.
- Mon premier jet faisait correspondre `MockBehavior.Strict` de Moq aux stubs stricts de Mockito. Ils ne vérifient pas la même chose : Moq échoue sur un appel sans setup, Mockito sur un stub jamais utilisé.
- J'ai d'abord écrit que C# signale l'unboxing d'un nullable par l'avertissement CS8629. Convertir un `int?` en `int` sans cast ne compile pas du tout (CS0266) ; CS8629 concerne `.Value` sur un `int?` possiblement null.

## 2026-09-13 — Leçon 10

- La leçon 10 est testée différemment : [`l10/check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l10/check.sh) exécute les builds Maven, Gradle et NuGet, et la CI compare 14 fichiers de sortie avec ceux que cite la leçon. Le script prend environ trois minutes sur ma machine, dont l'essentiel pour le démarrage de Maven et de Gradle.
- Maven 4 : la page de téléchargement propose 4.0.0-rc-6 en préversion et la 3.9.x comme version actuelle, ce qui répond pour l'instant à la question ouverte ci-dessous.

**Surprises en venant de C# :**

- Maven a mis Commons Lang 3.14.0 sur le class path alors qu'une bibliothèque du build avait besoin de 3.20.0, sans le moindre avertissement, et le programme n'a échoué qu'à l'exécution avec `NoClassDefFoundError`. Il faut `-Dverbose` rien que pour voir qu'une autre version avait été demandée.
- Un `implementation("…:3.14.0")` direct dans Gradle ne rétrograde rien : c'est un candidat de plus, et 3.20.0 l'emporte toujours. Seul `strictly` impose la version.
- NuGet s'est montré le plus strict des trois : son avertissement de rétrogradation, NU1605, est une erreur par défaut.
- `failOnVersionConflict()` a laissé `compileJava` réussir, parce que le conflit n'existe que sur le class path d'exécution quand l'autre version arrive par une dépendance `implementation`.

**Ce que j'ai d'abord mal fait :**

- Mon premier build Gradle partageait ses réglages avec `subprojects { }` dans le script racine. La documentation de Gradle qualifie cela de « an improper way to share build logic » ; l'exemple utilise désormais un plugin de convention dans `buildSrc`.
- La première exécution de `mvn install` a placé les modules de l'exemple dans mon dépôt local (`~/.m2`). Le script construit désormais dans le réacteur avec `package`, qui ne demande aucune installation, et j'ai supprimé les copies installées.
- `dotnet list package` affiche des messages de restauration dont la formulation dépend de ce qui est déjà restauré : le script de vérification les filtre donc.
- Mon tableau récapitulatif indiquait d'abord que Maven n'avait pas d'équivalent de `PrivateAssets="all"`, alors que le tableau des scopes, deux sections plus loin, l'associait à `<optional>true</optional>`. Le tableau récapitulatif concorde désormais.

## 2026-09-13 — Leçon 9

- Le projet compte désormais 113 tests : 63 extraits rejetés, 26 sorties d'exemples et 24 solutions d'exercices. Les exemples de la leçon 9 démarrent plus de 14 000 threads virtuels (10 000 tâches qui dorment et 4 600 tâches courtes), et l'ensemble d'`ExamplesTest` s'exécute toujours en moins de 3 secondes sur ma machine.
- Pour être testés, les exemples concurrents ont besoin d'une sortie déterministe. Chacun n'affiche que des résultats qui ne dépendent pas de l'ordonnancement : des totaux, des listes collectées, et l'ordre qu'imposent les latches.

**Surprises en venant de C# :**

- `CompletableFuture.cancel(true)` n'interrompt pas la tâche : la Javadoc indique que l'argument « has no effect in this implementation ». Le future se déclare annulé alors que sa tâche continue de s'exécuter.
- Un `value++` non protégé, depuis 1 000 tâches de 1 000 incréments, a affiché 76 422, puis 855 000, puis 803 000. La première exécution a perdu plus de 90 % des mises à jour, sans doute avant que le JIT ne compile la boucle : *à vérifier*.
- Synchroniser sur un `Integer` compile. Le seul signe de problème est un avertissement de lint, dans une catégorie que Java 25 nomme `[identity]`.
- `ScopedValue` n'atteint pas les tâches d'un executor ordinaire ; seuls les threads créés (forked) par `StructuredTaskScope`, encore en préversion, en héritent. `AsyncLocal` se propage partout.

**Ce que j'ai d'abord mal fait :**

- Le premier exemple `Futures` annulait une tâche de cinq secondes avec `CompletableFuture.cancel(true)`, et l'exemple prenait cinq secondes : le `close()` de l'executor attendait la tâche qui n'avait jamais été interrompue. C'est devenu une partie de la leçon, avec une tâche d'une seconde.
- La ligne « interrupted » du worker et la ligne « cancelled » de `main` étaient affichées par deux threads : leur ordre relevait donc d'une situation de compétition (race). Un second latch règle le problème.
- Côté C#, je lisais d'abord un `ThreadLocal` dans `Task.Run` après un `await`. La continuation s'exécute sur un thread du pool, et `Task.Run` pouvait réutiliser ce même thread : la sortie n'était donc pas garantie. La comparaison utilise désormais un `Thread` dédié.
- J'ai d'abord vérifié quel thread exécutait un stream parallèle d'un seul élément. Cela reposait sur un détail d'implémentation ; l'exemple enregistre désormais chaque thread qui participe à un stream volumineux.

## 2026-09-13 — Leçons 5 à 8

- Le côté C# couvre désormais toutes les leçons : `dotnet run -- l05` à `l08` affichent le comportement .NET auquel chaque leçon se compare.
- Le projet compte 98 tests : 56 extraits rejetés, 21 sorties d'exemples et 21 solutions d'exercices.

**Surprises en venant de C# :**

- Quand la fermeture d'une ressource échoue après l'échec du corps, Java conserve l'exception du corps et y attache l'autre comme exception *supprimée* (suppressed). Le `using` de C# perd l'exception d'origine : le côté C# affiche `dispose failed: db` au lieu de `query failed on db`.
- `throw e` conserve la trace de pile en Java, car la trace est capturée à la création de l'exception. L'analyseur C# avertit sur la même ligne (CA2200).
- Deux évaluations de `display::onPrice` produisent deux objets différents au sens d'`equals` : retirer un écouteur avec une nouvelle référence de méthode ne fait donc rien, en silence. Les délégués C# sont égaux.
- `Map.of(…)` itère dans un ordre différent d'un démarrage de la JVM à l'autre : quatre exécutions du même one-liner ont donné deux ordres.
- Une expression `switch` sur une interface scellée qui oublie un sous-type est une erreur de compilation, là où C# se contente d'un avertissement (CS8509).
- Les motifs primitifs (`case byte b` sur un `int`) sont encore en préversion en Java 25 ; javac le dit et suggère `--enable-preview`.

**Ce que j'ai d'abord mal fait :**

- La première capture de la sortie C# attendue pour la leçon 7 contenait un avertissement de l'analyseur, parce que `dotnet run` avait recompilé le projet et écrit l'avertissement sur la sortie standard. Les fichiers attendus sont désormais produits avec `dotnet run --no-build`, comme en CI.
- `IntSummaryStatistics.toString()` et `printf("%.2f")` formatent les nombres selon la locale par défaut : la sortie dépend donc de la machine, `2.200000` ici, `2,200000` avec une locale française. La leçon 7 affiche elle-même les champs et la leçon 8 passe `Locale.ROOT`. Les exemples `Enums` et `Shapes` de la leçon 3 utilisent encore la locale par défaut : *à vérifier* sur une machine en locale française.
- Je me souvenais de l'erreur C# de bras de switch dominé comme CS8120. Ce code concerne les instructions `switch` ; une expression switch signale CS8510.
- `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))` ne compile pas : `andThen` renvoie une `Function`, pas un `UnaryOperator`. L'exercice 1 de la leçon 6 explique pourquoi.

## 2026-09-13 — Leçons 1 à 4

- Chaîne d'outils sur ma machine : OpenJDK `25+36`, Maven 3.9.16, Gradle 9.7.1, et le SDK .NET 10 pour le côté C#. La CI utilise Eclipse Temurin 25 sous Windows, Ubuntu et macOS.
- Le code du cours se trouve dans [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp) :
  - la sortie de chaque exemple est comparée à la leçon par un test JUnit ;
  - chaque extrait rejeté est compilé via l'API [`javax.tools`](https://docs.oracle.com/en/java/javase/25/docs/api/java.compiler/javax/tools/package-summary.html) et doit produire la clé de diagnostic javac que cite la leçon (par exemple `compiler.err.not.exhaustive`) — l'équivalent Java des codes `E0xxx` de Rust ;
  - les solutions des exercices sont des tests ;
  - un petit programme .NET 10 affiche le côté C# de chaque comparaison.

**Surprises en venant de C# :**

- `Integer a = 128, b = 128; a == b` vaut `false`, mais avec 127 c'est `true`. L'intervalle de cache de −128 à 127 n'est pas un détail d'implémentation : la JLS l'impose.
- `java -jar` sur un JAR Maven fraîchement construit échoue avec `no main manifest attribute`. Rien dans `dotnet build` ne prépare à un artefact qui ne connaît pas son propre point d'entrée.
- Un `enum` C# accepte `(Size)42` ; un enum Java ne peut pas contenir une valeur qu'il ne déclare pas. Les enums Java sont bien plus proches d'un ensemble scellé d'objets singletons.
- Les messages d'erreur de javac sont parfois indirects : créer une classe interne depuis une méthode statique donne `non-static variable this cannot be referenced from a static context`.

**Ce que j'ai d'abord mal fait :**

- Dans un commentaire de code, j'avais décrit `final var` comme « une variable locale readonly de C# ». C# n'a pas de variables locales readonly. Le commentaire le dit désormais.
- Je m'attendais à ce que `javac -XDrawDiagnostics` et l'API du compilateur rapportent la même clé de diagnostic. Ce n'est pas toujours le cas : pour un ajout dans une `List<? extends Number>`, la ligne de commande rapporte `compiler.err.cant.apply.symbols` tandis que l'API rapporte la version simplifiée `compiler.err.prob.found.req`. Les tests utilisent l'API, les leçons citent donc ce que voit l'API.
- Plusieurs leçons montraient d'abord un extrait d'un snippet rejeté à côté d'un message d'erreur dont le numéro de ligne se rapportait au fichier entier. Les leçons montrent désormais le fichier complet.
- Le signe `‰` d'un exemple s'affichait `�` dans la console Windows. L'exemple écrit désormais « per mille ».

## Cas pratiques dans mes dépôts

Chaque cas applique une leçon à un dépôt public, à un commit figé.

### GuitarAlchemist/ga — le build du plugin JetBrains (leçon 1)

[`jetbrains-plugin/`](https://github.com/GuitarAlchemist/ga/tree/5560b883/jetbrains-plugin) à `ga@5560b883` est un projet Gradle en Kotlin DSL (le plugin lui-même est écrit en Kotlin). Je l'ai copié et j'ai essayé de le compiler sur cette machine.

- **Le wrapper est incomplet.** Seul `gradle/wrapper/gradle-wrapper.properties` est versionné. `gradlew`, `gradlew.bat` et `gradle-wrapper.jar` manquent : `./gradlew` n'existe donc pas et chaque contributeur doit installer un Gradle compatible. `gradle wrapper` régénère les trois fichiers, qu'il faudrait versionner.
- **Gradle 8.5 ne peut pas tourner sur JDK 25.** Avec le Gradle 8.5 figé et JDK 25, `gradle help` échoue avec un message d'un seul mot :

  ```text
  * What went wrong:
  25
  ```

  La trace de pile montre une `java.lang.IllegalArgumentException: 25` levée pendant que Gradle compile le script de build Kotlin : le compilateur Kotlin embarqué dans cette version de Gradle ne connaît pas Java 25. La correction passe soit par un JDK que Gradle 8.5 prend en charge, soit par un Gradle plus récent ; la [matrice de compatibilité de Gradle](https://docs.gradle.org/current/userguide/compatibility.html) indique quelle version de Gradle tourne sur quelle version de Java.
- **Mettre à jour Gradle seul ne suffit pas.** Avec Gradle 9.7.1, le build va plus loin et échoue dans l'ancien plugin `org.jetbrains.intellij` 1.16.1 :

  ```text
  class org.jetbrains.intellij.MemoizedProvider overrides final method org.gradle.api.internal.provider.AbstractMinimalProvider.toString()Ljava/lang/String;
  ```

  Ce plugin a été remplacé par l'[IntelliJ Platform Gradle Plugin 2.x](https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin.html), qui utilise un DSL différent. La migration est un vrai changement, pas une simple montée de version.
- **Le dossier de cache de Gradle est versionné.** Douze fichiers sous `jetbrains-plugin/.gradle/` (fichiers de verrou, sommes de contrôle, `last-build.bin`) sont dans le dépôt, l'équivalent Gradle de versionner `obj/`. Il a sa place dans le `.gitignore`.
- **Une cible Java sans toolchain.** Le script définit `sourceCompatibility = "17"` sur chaque tâche `JavaCompile` au lieu d'un bloc `java { toolchain { … } }` : le JDK utilisé dépend donc de la machine qui exécute Gradle — exactement la variabilité que décrit la note sur les toolchains de la leçon 1.

Étape suivante, *à vérifier* : générer le wrapper, migrer vers le plugin 2.x, et vérifier que le plugin se charge toujours dans une version actuelle d'IntelliJ IDEA.

### spareilleux/learn — l'exemple Spring Boot du cours WSL (leçon 1, exercice 2)

[`code/wsl-containers/java-reactor-api`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/java-reactor-api) n'a aucune configuration de `maven-jar-plugin`, et pourtant `java -jar target/app.jar` fonctionne. Le compiler montre pourquoi :

```text
Main-Class: org.springframework.boot.loader.launch.JarLauncher
Start-Class: dev.learn.reactorapi.JavaReactorApiApplication
```

Le `spring-boot-maven-plugin` réempaquette le JAR : la `Main-Class` du manifeste est le lanceur de Spring Boot, qui lit `Start-Class` et charge les 62 JAR de dépendances imbriqués sous `BOOT-INF/lib/` (35 Mo au total). Il répond aux deux moitiés de l'exercice 2 — le point d'entrée manquant et les dépendances manquantes. L'élément `<parent>` (`spring-boot-starter-parent`) explique aussi pourquoi le POM n'indique aucune version de plugin ni de dépendance : il joue le rôle de `Directory.Packages.props` et des valeurs par défaut du SDK. La leçon 10 y reviendra.

## Questions ouvertes

- Maven 4 vaut-il déjà la peine d'être enseigné ? Au 2026-09-13, c'est encore une version candidate (4.0.0-rc-6) ; à réexaminer quand la 4.0.0 sera finale.
- Comment les inspections d'IntelliJ IDEA se comparent-elles à `-Xlint:all` de javac pour les pièges des leçons 2 et 3 ?
