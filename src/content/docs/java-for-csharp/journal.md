---
title: Journal
description: Dated progress notes for the Java course — attempts, surprises, practical cases in my repositories, and items to verify.
sidebar:
  order: 99
---

## Progress

- [x] Lesson 1 — The JDK and build tools
- [x] Lesson 2 — Types, equality and operators
- [x] Lesson 3 — Classes, records and enums
- [x] Lesson 4 — Generics and type erasure
- [x] Lesson 5 — Exceptions, `null` and `Optional`
- [x] Lesson 6 — Lambdas and functional interfaces
- [x] Lesson 7 — Collections and Streams
- [x] Lesson 8 — Pattern matching
- [x] Lesson 9 — Concurrency and virtual threads
- [x] Lesson 10 — Maven and Gradle in depth
- [x] Lesson 11 — Testing
- [x] Lesson 12 — The standard library you reach for
- [ ] Lesson 13 — The JVM at run time
- [ ] Lesson 14 — Annotations, reflection and modules

## 2026-09-13 — Lesson 12

- Lesson 12's examples, their C# counterparts and three compile-fail snippets run in CI on Windows, Linux and macOS; the main project now has 123 tests. Every HTTP call goes to a local server, the JDK's `HttpServer` on the Java side and `HttpListener` on the C# side, so the output doesn't depend on the network.
- The C# project had `InvariantGlobalization` enabled. Lesson 12 needs IANA time zones and named cultures, so ICU is now on, and `Program.cs` sets the current culture to the invariant culture. The outputs of lessons 2 to 9 didn't change.

**Surprises coming from C#:**

- Java's `HttpClient` doesn't follow redirects and has no request timeout unless you set them. Porting .NET code gets you a 302 with an empty body, or a call that can wait forever.
- For a local time that happens twice, `ZonedDateTime` picks the summer-time offset and `TimeZoneInfo.GetUtcOffset` the standard one: one hour apart.
- `YYYY` in a Java date pattern printed 2027 for December 31, 2026 with `Locale.US`, and 2026 with `Locale.FRANCE`.
- `Files.readString` throws on invalid UTF-8, where `File.ReadAllText` replaces the byte.
- A first probe printed `héllo` read from a UTF-8 file as `h�llo` in Git Bash on Windows, while the file itself was correct. JEP 400 leaves `System.out` on the console's encoding; *to verify*: which encoding Java picked in that terminal.

**Things I got wrong first:**

- The first C# probe ran with `InvariantGlobalization` on. `FindSystemTimeZoneById("Europe/Paris")` threw `TimeZoneNotFoundException` on Windows, and `new CultureInfo("fr-FR")` threw "Only the invariant culture is supported in globalization-invariant mode."
- The first Java probe formatted numbers with the default locale, which is `en_CA` on my machine and something else on CI runners. The examples now pass a `Locale` everywhere the output depends on one.

## 2026-09-13 — Lesson 11

- Lesson 11 has its own Maven project, [`l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), with 24 tests. The failure messages the lesson quotes are produced by `FailureMessagesTest` and compared with text files, so a library upgrade that changes a message fails the build. `l11/check.sh` covers the rest: test names, Mockito's warning without the agent, BlockHound's failure without its JVM flag, and NullAway's errors.
- Lesson 5's open question about JSpecify and NullAway is answered in this lesson: NullAway 0.14.1 on Error Prone 2.50.0 works on JDK 25.

**Surprises coming from C#:**

- Lesson 10's conflict appeared in this project by itself. Mockito 5.23.0 asks for Byte Buddy 1.17.7, AssertJ 3.27.7 for 1.18.3, and Maven's nearest-wins rule put Byte Buddy 1.18.3 next to `byte-buddy-agent` 1.17.7. It happens to work, because AssertJ's path is shorter and brings the newer version.
- JUnit 6 quotes CSV values in parameterized test names, numbers included, because the values are still strings when the name is built.
- Surefire's reports ignore `@DisplayName` unless a reporter option is set, and its console output credited all nine tests of `PriceCalculatorTest` to its nested class.
- With Mockito loaded as an agent, the JVM still prints "Sharing is only supported for boot loader classes because bootstrap classpath has been appended". The lesson doesn't quote it; *to verify*: whether `-Xshare:off` is the right way to silence it.
- BlockHound 1.0.17 needs `-XX:+AllowRedefinitionToAddDeleteMethods`, a JVM flag deprecated since JDK 13, and reports `Thread.sleep` as `java.lang.Thread.sleepNanos0`, the private JDK method it instruments.

**Things I got wrong first:**

- NullAway's first run failed with "An unknown compilation problem occurred". The real error, an `IllegalAccessError` on javac's internal API, only appeared with `mvn -e`. Error Prone needs `.mvn/jvm.config` with `--add-exports` lines.
- I first installed BlockHound with `BlockHound.install()`, as its README does. On JDK 25 it failed with "Could not self-attach to current VM using external process", and with `-Djdk.attach.allowAttachSelf=true` it failed with "Agent JAR loaded but agent failed to initialize". Only `-javaagent` together with the flag worked.
- My first draft mapped Moq's `MockBehavior.Strict` onto Mockito's strict stubs. They check different things: Moq fails on a call without a setup, Mockito on a stub that is never used.
- I first wrote that C# reports unboxing a nullable as warning CS8629. Converting an `int?` to `int` without a cast doesn't compile at all (CS0266); CS8629 is for `.Value` on a possibly null `int?`.

## 2026-09-13 — Lesson 10

- Lesson 10 is tested differently: [`l10/check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l10/check.sh) runs the Maven, Gradle and NuGet builds and CI compares 14 output files with the ones quoted in the lesson. The script takes about three minutes on my machine, most of it Maven and Gradle starting up.
- Maven 4: the download page offers 4.0.0-rc-6 as a preview and 3.9.x as the current release, which answers the open question below for now.

**Surprises coming from C#:**

- Maven put Commons Lang 3.14.0 on the class path when a library in the build needed 3.20.0, without a warning, and the program failed only at run time with `NoClassDefFoundError`. `-Dverbose` is needed even to see that another version was requested.
- A direct `implementation("…:3.14.0")` in Gradle doesn't downgrade anything: it is one more candidate, and 3.20.0 still wins. Only `strictly` forces it.
- NuGet was the strictest of the three: its downgrade warning, NU1605, is an error by default.
- `failOnVersionConflict()` let `compileJava` succeed, because the conflict only exists on the runtime class path when the other version comes through an `implementation` dependency.

**Things I got wrong first:**

- My first Gradle build shared its settings with `subprojects { }` in the root script. Gradle's documentation calls that "an improper way to share build logic"; the example now uses a convention plugin in `buildSrc`.
- The first run of `mvn install` put the example's modules into my local repository (`~/.m2`). The script now builds in the reactor with `package`, which needs no install, and I deleted the installed copies.
- `dotnet list package` prints restore messages whose wording depends on what is already restored, so the check script filters them out.
- My summary table first said Maven had no equivalent of `PrivateAssets="all"`, while the scopes table two sections later mapped it to `<optional>true</optional>`. The summary table now matches.

## 2026-09-13 — Lesson 9

- The project now has 113 tests: 63 rejected snippets, 26 example outputs and 24 exercise solutions. Lesson 9's examples start more than 14,000 virtual threads (10,000 sleeping tasks and 4,600 short ones), and the whole `ExamplesTest` still runs in under 3 seconds on my machine.
- Concurrent examples need deterministic output to be tested. Each one prints only results that don't depend on scheduling: totals, collected lists, and the order that latches enforce.

**Surprises coming from C#:**

- `CompletableFuture.cancel(true)` doesn't interrupt the task: the Javadoc says the argument "has no effect in this implementation". The future reports cancelled while its task keeps running.
- A racy `value++` from 1,000 tasks of 1,000 increments printed 76,422, then 855,000, then 803,000. The first run lost more than 90% of the updates, presumably before the JIT compiled the loop: *to verify*.
- Synchronizing on an `Integer` compiles. The only sign of trouble is a lint warning, in a category that Java 25 calls `[identity]`.
- `ScopedValue` doesn't reach tasks in an ordinary executor; only threads forked by `StructuredTaskScope`, still a preview, inherit it. `AsyncLocal` flows everywhere.

**Things I got wrong first:**

- The first `Futures` example cancelled a five-second task with `CompletableFuture.cancel(true)`, and the example took five seconds: the executor's `close()` was waiting for the task that was never interrupted. That became part of the lesson, with a one-second task.
- The worker's "interrupted" line and `main`'s "cancelled" line were printed by two threads, so their order was a race. A second latch fixes it.
- On the C# side, I first read a `ThreadLocal` inside `Task.Run` after an `await`. The continuation runs on a pool thread, and `Task.Run` could reuse that same thread, so the output wasn't guaranteed. The comparison now uses a dedicated `Thread`.
- I first checked which thread ran a single-element parallel stream. That relied on an implementation detail; the example now records every thread that takes part in a large one.

## 2026-09-13 — Lessons 5 to 8

- The C# side now covers every lesson: `dotnet run -- l05` to `l08` print the .NET behaviour each lesson compares with.
- The project has 98 tests: 56 rejected snippets, 21 example outputs and 21 exercise solutions.

**Surprises coming from C#:**

- When closing a resource fails after the body has failed, Java keeps the body's exception and attaches the other as *suppressed*. C#'s `using` loses the original: the C# side prints `dispose failed: db` instead of `query failed on db`.
- `throw e` keeps the stack trace in Java, because the trace is captured when the exception is created. The C# analyzer warns about the same line (CA2200).
- Two evaluations of `display::onPrice` produce two unequal objects, so removing a listener with a fresh method reference silently does nothing. C# delegates compare equal.
- `Map.of(…)` iterates in a different order from one JVM start to the next: four runs of the same one-liner gave two orders.
- A `switch` expression over a sealed interface that misses a subtype is a compile error, where C# only warns (CS8509).
- Primitive patterns (`case byte b` on an `int`) are still a preview in Java 25; javac says so and suggests `--enable-preview`.

**Things I got wrong first:**

- The first capture of the C# expected output for lesson 7 included an analyzer warning, because `dotnet run` rebuilt the project and printed the warning to standard output. The expected files are now produced with `dotnet run --no-build`, as in CI.
- `IntSummaryStatistics.toString()` and `printf("%.2f")` format numbers with the default locale, so the output depends on the machine: `2.200000` here, `2,200000` with a French locale. Lesson 7 prints the fields itself and lesson 8 passes `Locale.ROOT`. Lesson 3's `Enums` and `Shapes` examples still use the default locale: *to verify* on a French-locale machine.
- I remembered C#'s dominated switch-arm error as CS8120. That code is for `switch` statements; a switch expression reports CS8510.
- `reduce(UnaryOperator.identity(), (f, g) -> f.andThen(g))` doesn't compile: `andThen` returns a `Function`, not a `UnaryOperator`. Exercise 1 of lesson 6 explains why.

## 2026-09-13 — Lessons 1 to 4

- Toolchain on my machine: OpenJDK `25+36`, Maven 3.9.16, Gradle 9.7.1, and the .NET 10 SDK for the C# side. CI uses Eclipse Temurin 25 on Windows, Ubuntu and macOS.
- The course code lives in [`code/java-for-csharp`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp):
  - every example's output is compared with the lesson by a JUnit test;
  - every rejected snippet is compiled through the [`javax.tools`](https://docs.oracle.com/en/java/javase/25/docs/api/java.compiler/javax/tools/package-summary.html) API and must produce the javac diagnostic key the lesson quotes (for example `compiler.err.not.exhaustive`) — the Java counterpart of Rust's `E0xxx` codes;
  - exercise solutions are tests;
  - a small .NET 10 program prints the C# side of each comparison.

**Surprises coming from C#:**

- `Integer a = 128, b = 128; a == b` is `false`, but with 127 it is `true`. The cache range −128 to 127 is not an implementation detail: the JLS requires it.
- `java -jar` on a freshly built Maven JAR fails with `no main manifest attribute`. Nothing in `dotnet build` prepares you for an artefact that doesn't know its own entry point.
- A C# `enum` accepts `(Size)42`; a Java enum cannot hold a value it doesn't declare. Java enums are much closer to a sealed set of singleton objects.
- javac error messages are sometimes indirect: creating an inner class from a static method reports `non-static variable this cannot be referenced from a static context`.

**Things I got wrong first:**

- In a code comment I called `final var` "like a C# readonly local". C# has no readonly locals. The comment now says so.
- I expected `javac -XDrawDiagnostics` and the compiler API to report the same diagnostic key. They don't always: for adding to a `List<? extends Number>`, the command line reports `compiler.err.cant.apply.symbols` while the API reports the simplified `compiler.err.prob.found.req`. The tests use the API, so the lessons quote what the API sees.
- Several lessons first showed an excerpt of a rejected snippet next to an error message whose line number referred to the whole file. The lessons now show the complete file.
- The `‰` sign in an example printed as `�` in the Windows console. The example now writes "per mille".

## Practical cases in my repositories

Each case applies a lesson to a public repository, at a pinned commit.

### GuitarAlchemist/ga — the JetBrains plugin build (lesson 1)

[`jetbrains-plugin/`](https://github.com/GuitarAlchemist/ga/tree/5560b883/jetbrains-plugin) at `ga@5560b883` is a Gradle Kotlin DSL project (the plugin itself is written in Kotlin). I copied it and tried to build it on this machine.

- **The wrapper is incomplete.** Only `gradle/wrapper/gradle-wrapper.properties` is committed. `gradlew`, `gradlew.bat` and `gradle-wrapper.jar` are missing, so `./gradlew` does not exist and every contributor needs a matching Gradle installed. `gradle wrapper` regenerates the three files, and they should be committed.
- **Gradle 8.5 cannot run on JDK 25.** With the pinned Gradle 8.5 and JDK 25, `gradle help` fails with a one-word message:

  ```text
  * What went wrong:
  25
  ```

  The stack trace shows `java.lang.IllegalArgumentException: 25` thrown while Gradle compiles the Kotlin build script: that Gradle version's embedded Kotlin compiler doesn't know Java 25. The fix is either a JDK that Gradle 8.5 supports or a newer Gradle; the [Gradle compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html) lists which Gradle version runs on which Java.
- **Upgrading Gradle alone is not enough.** With Gradle 9.7.1 the build gets further and fails in the legacy `org.jetbrains.intellij` 1.16.1 plugin:

  ```text
  class org.jetbrains.intellij.MemoizedProvider overrides final method org.gradle.api.internal.provider.AbstractMinimalProvider.toString()Ljava/lang/String;
  ```

  That plugin was replaced by the [IntelliJ Platform Gradle Plugin 2.x](https://plugins.jetbrains.com/docs/intellij/tools-intellij-platform-gradle-plugin.html), which uses a different DSL. Migrating is a real change, not a version bump.
- **Gradle's cache directory is committed.** Twelve files under `jetbrains-plugin/.gradle/` (lock files, checksums, `last-build.bin`) are in the repository, the Gradle equivalent of committing `obj/`. It belongs in `.gitignore`.
- **Java target without a toolchain.** The script sets `sourceCompatibility = "17"` on each `JavaCompile` task instead of a `java { toolchain { … } }` block, so the JDK used depends on the machine that runs Gradle — exactly the variability lesson 1's toolchain note describes.

Next step, *to verify*: generate the wrapper, migrate to the 2.x plugin, and check that the plugin still loads in a current IntelliJ IDEA.

### spareilleux/learn — the Spring Boot example of the WSL course (lesson 1, exercise 2)

[`code/wsl-containers/java-reactor-api`](https://github.com/spareilleux/learn/tree/main/code/wsl-containers/java-reactor-api) has no `maven-jar-plugin` configuration, yet `java -jar target/app.jar` works. Building it shows why:

```text
Main-Class: org.springframework.boot.loader.launch.JarLauncher
Start-Class: dev.learn.reactorapi.JavaReactorApiApplication
```

The `spring-boot-maven-plugin` repackages the JAR: the manifest's `Main-Class` is Spring Boot's launcher, which reads `Start-Class` and loads the 62 dependency JARs nested under `BOOT-INF/lib/` (35 MB in total). It answers both halves of exercise 2 — the missing entry point and the missing dependencies. The `<parent>` element (`spring-boot-starter-parent`) is also why the POM has no plugin or dependency versions: it plays the role of `Directory.Packages.props` and the SDK's defaults. Lesson 10 comes back to it.

## Open questions

- Is Maven 4 worth teaching yet? On 2026-09-13 it is still a release candidate (4.0.0-rc-6); revisit when 4.0.0 is final.
- How do IntelliJ IDEA's inspections compare with javac's `-Xlint:all` for the traps in lessons 2 and 3?
