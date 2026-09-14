---
title: 11. Tests
description: JUnit au lieu de xUnit, AssertJ au lieu de FluentAssertions, Mockito au lieu de Moq — plus les agents Java pour Mockito et BlockHound, et la vérification de null au moment du build avec JSpecify et NullAway.
sidebar:
  order: 11
---

Exemple complet : [`code/java-for-csharp/l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), une petite bibliothèque de boutique avec ses tests. Les messages d'échec cités ci-dessous sont vérifiés par un test, et [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l11/check.sh) compare le reste de la sortie avec la leçon en CI.

## Les mêmes idées, d'autres noms

Chaque outil qu'utilise un projet de test C# a un équivalent Java, et les concepts se correspondent de près :

| .NET | Java |
|---|---|
| [xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), NUnit, MSTest | [JUnit](https://docs.junit.org/current/user-guide/) (API Jupiter) |
| `[Fact]` | `@Test` |
| `[Theory]` avec `[InlineData]` / `[MemberData]` | `@ParameterizedTest` avec `@CsvSource` / `@MethodSource` |
| constructeur / `IDisposable` | `@BeforeEach` / `@AfterEach` |
| `IClassFixture<T>` | `@BeforeAll` / `@AfterAll` (statiques) |
| `[Trait("Category", "slow")]` | `@Tag("slow")` |
| `Assert.Equal`, `Assert.Throws` | `assertEquals`, `assertThrows` |
| [FluentAssertions](https://fluentassertions.com/) | [AssertJ](https://assertj.github.io/doc/) |
| [Moq](https://github.com/devlooped/moq) | [Mockito](https://site.mockito.org/) |
| [`TimeProvider`](https://learn.microsoft.com/dotnet/api/system.timeprovider) | `java.time.Clock` |
| `dotnet test` | `mvn test` ([Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)) |
| un projet `*.Tests` séparé | `src/test/java` dans le même projet |
| [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references) | annotations [JSpecify](https://jspecify.dev/docs/user-guide/) vérifiées par [NullAway](https://github.com/uber/NullAway) |

Les tests se trouvent dans `src/test/java`, dans le **même package** que le code qu'ils testent. Ils peuvent donc utiliser les membres package-private, là où .NET a besoin d'`InternalsVisibleTo`. Les dépendances de test ont le scope `test` de la leçon 10, et le projet importe deux BOM, celui de JUnit et celui de Mockito, pour que les artefacts apparentés partagent une même version :

```xml
  <dependencyManagement>
    <dependencies>
      <dependency>
        <groupId>org.junit</groupId>
        <artifactId>junit-bom</artifactId>
        <version>6.1.3</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
      <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-bom</artifactId>
        <version>5.23.0</version>
        <type>pom</type>
        <scope>import</scope>
      </dependency>
    </dependencies>
  </dependencyManagement>
```

## JUnit

La classe testée calcule le total d'une commande : une remise de 5 % sur toute ligne de 10 articles ou plus, puis un coupon facultatif.

```java
class PriceCalculatorTest {

    private PriceCalculator calculator;
    private int testsRunOnThisInstance;

    // S'exécute avant chaque test, sur une nouvelle instance : le constructeur d'une classe de test xUnit.
    @BeforeEach
    void setUp() {
        calculator = new PriceCalculator();
        testsRunOnThisInstance++;
    }

    @Test
    void sumsLineTotals() {
        var items = List.of(new Item("pen", 2, 150), new Item("pad", 1, 400));
        assertEquals(700, calculator.totalCents(items, null));
        assertEquals(1, testsRunOnThisInstance);
    }

    @Test
    @DisplayName("an unknown coupon is rejected with its code in the message")
    void unknownCoupon() {
        var items = List.of(new Item("pen", 1, 150));
        var e = assertThrows(IllegalArgumentException.class, () -> calculator.totalCents(items, "FREE"));
        assertEquals("unknown coupon: FREE", e.getMessage());
        assertEquals(1, testsRunOnThisInstance);
    }
```

- **Une nouvelle instance par test.** Comme [xUnit](https://xunit.net/docs/shared-context), et contrairement à NUnit, qui réutilise une instance par fixture, JUnit crée par défaut une nouvelle instance de la classe de test pour chaque méthode de test : `testsRunOnThisInstance` vaut donc toujours 1. Les champs portent l'état propre à chaque test ; l'état partagé va dans des champs `static` initialisés dans `@BeforeAll`.
- **Pas de `public`.** Les classes et méthodes de test peuvent être package-private, et le sont en général.
- **La valeur attendue d'abord.** `assertEquals(expected, actual)`, dans le même ordre qu'`Assert.Equal`.
- **`assertThrows` renvoie l'exception**, comme `Assert.Throws<T>` : on peut donc vérifier son message ensuite.

Les tests paramétrés sont des `[Theory]`. `@CsvSource` est un `[InlineData]` écrit sous forme de lignes CSV, et `@MethodSource` est `[MemberData]` :

```java
// [Theory] avec [InlineData] : un test par ligne.
@ParameterizedTest(name = "{0} pens at 100 cents cost {1}")
@CsvSource({
    "1,  100",
    "9,  900",
    "10, 950",
    "20, 1900",
})
void bulkDiscountStartsAtTen(int quantity, long expectedCents) {
    assertEquals(expectedCents, calculator.totalCents(List.of(new Item("pen", quantity, 100)), null));
}

// [MemberData] : des arguments construits par une méthode statique.
static Stream<Arguments> coupons() {
    return Stream.of(Arguments.of("TEN", 900), Arguments.of("HALF", 500));
}

@ParameterizedTest
@MethodSource("coupons")
void couponsTakeAPercentageOff(String code, long expectedCents) {
    assertEquals(expectedCents, calculator.totalCents(List.of(new Item("book", 1, 1000)), code));
}

// Les classes imbriquées regroupent des tests et partagent la préparation de la classe englobante.
@Nested
class InvalidItems {

    @Test
    void zeroQuantityIsRejected() {
        var e = assertThrows(IllegalArgumentException.class, () -> new Item("pen", 0, 100));
        assertEquals("quantity must be positive for pen: 0", e.getMessage());
    }
}
```

Voici les noms du rapport de tests, triés :

```text
an unknown coupon is rejected with its code in the message
bulkDiscountStartsAtTen(int, long) "1" pens at 100 cents cost "100"
bulkDiscountStartsAtTen(int, long) "10" pens at 100 cents cost "950"
bulkDiscountStartsAtTen(int, long) "20" pens at 100 cents cost "1900"
bulkDiscountStartsAtTen(int, long) "9" pens at 100 cents cost "900"
couponsTakeAPercentageOff(String, long)[1] "TEN", 900
couponsTakeAPercentageOff(String, long)[2] "HALF", 500
sumsLineTotals
zeroQuantityIsRejected
```

Deux détails m'ont surpris :

- **Les nombres sont entre guillemets.** Depuis JUnit 6, les arguments textuels sont [mis entre guillemets dans les noms affichés](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html), et cela se produit avant la conversion : la valeur CSV `"950"` est encore une chaîne à ce moment-là. `@MethodSource` passe un vrai `Integer` : `900` n'est donc pas entre guillemets.
- **Surefire ignore `@DisplayName` par défaut.** Le rapport utilisait les noms de méthodes jusqu'à ce que je configure un reporter avec `usePhrasedTestCaseMethodName`. Dans la console, Surefire a aussi attribué les neuf tests de la classe à la classe imbriquée `PriceCalculatorTest$InvalidItems`, et zéro à `PriceCalculatorTest`.

Pour exécuter un sous-ensemble, `mvn test -Dtest=PriceCalculatorTest` ou `-Dtest='OrderServiceTest#outOfStock*'` sont les équivalents de `dotnet test --filter`. Les tags sélectionnent des groupes avec `-Dgroups=slow`.

## Assertions : JUnit et AssertJ

Les assertions de JUnit suffisent pour des valeurs simples. Pour les collections et les objets, beaucoup de projets Java utilisent AssertJ, qui est à FluentAssertions ce que JUnit est à xUnit : des chaînes `assertThat(actual).isEqualTo(expected)`, avec des messages d'échec bien plus détaillés. La même comparaison de listes, d'abord avec JUnit :

```java
assertEquals(List.of("pen", "pad"), List.of("pen", "pencil"))
```

```text
org.opentest4j.AssertionFailedError: expected: <[pen, pad]> but was: <[pen, pencil]>
```

Puis avec AssertJ :

```java
assertThat(List.of("pen", "pencil")).containsExactly("pen", "pad")
```

```text
org.opentest4j.AssertionFailedError: 
Expecting actual:
  ["pen", "pencil"]
to contain exactly (and in same order):
  ["pen", "pad"]
but some elements were not found:
  ["pad"]
and others were not expected:
  ["pencil"]
```

L'`assertSoftly` d'AssertJ est l'`AssertionScope` de FluentAssertions : il exécute toutes les assertions du bloc et rapporte tous les échecs ensemble :

```java
var receipt = new Receipt("ada", 250, "tx-1", OrderServiceTest.NOON);
check("assertj-soft", failureOf(() -> SoftAssertions.assertSoftly(softly -> {
    softly.assertThat(receipt.customer()).isEqualTo("grace");
    softly.assertThat(receipt.totalCents()).isEqualTo(300);
})));
```

```text
org.assertj.core.error.AssertJMultipleFailuresError: 
Multiple Failures (2 failures)
-- failure 1 --
expected: "grace"
 but was: "ada"
at FailureMessagesTest.lambda$assertjSoftAssertions$1(FailureMessagesTest.java:66)
-- failure 2 --
expected: 300L
 but was: 250L
at FailureMessagesTest.lambda$assertjSoftAssertions$1(FailureMessagesTest.java:67)
```

`check` et `failureOf` sont des utilitaires de l'exemple : ils interceptent l'échec et comparent son message avec le texte ci-dessus, pour que la leçon ne puisse pas s'écarter de ce qu'affichent les bibliothèques.

## Mockito

`OrderService` vérifie le stock, débite une passerelle de paiement et horodate le reçu avec l'heure d'une `Clock`. Les deux interfaces sont mockées ; l'horloge ne l'est pas, car `Clock.fixed` fournit déjà une horloge qui ne bouge jamais, l'équivalent du `FakeTimeProvider` de .NET :

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    static final Instant NOON = Instant.parse("2026-09-13T12:00:00Z");

    @Mock
    Inventory inventory;

    @Mock
    PaymentGateway gateway;

    OrderService service;

    @BeforeEach
    void setUp() {
        // Une horloge fixe n'a pas besoin de mock, comme FakeTimeProvider.
        service = new OrderService(inventory, gateway, Clock.fixed(NOON, ZoneOffset.UTC));
    }

    @Test
    void chargesTheTotalAndReturnsAReceipt() {
        when(inventory.inStock("pen", 2)).thenReturn(true);
        when(gateway.charge("ada", 300)).thenReturn(new PaymentResult(true, "tx-42"));

        Receipt receipt = service.place("ada", List.of(new Item("pen", 2, 150)), null);

        assertThat(receipt).isEqualTo(new Receipt("ada", 300, "tx-42", NOON));
        verify(gateway).charge("ada", 300);
    }

    @Test
    void outOfStockNeverCharges() {
        when(inventory.inStock(anyString(), org.mockito.ArgumentMatchers.anyInt())).thenReturn(false);

        assertThatThrownBy(() -> service.place("ada", List.of(new Item("pen", 1, 150)), null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("out of stock: pen");
        verify(gateway, never()).charge(anyString(), anyLong());
    }
```

| Moq | Mockito |
|---|---|
| `new Mock<IPaymentGateway>()`, `mock.Object` | `@Mock PaymentGateway gateway` (le mock *est* l'objet) |
| `Setup(g => g.Charge("ada", 300)).Returns(result)` | `when(gateway.charge("ada", 300)).thenReturn(result)` |
| `It.IsAny<string>()` | `anyString()`, `any()` |
| `Verify(g => g.Charge("ada", 300), Times.Once())` | `verify(gateway).charge("ada", 300)` |
| `Times.Never()` | `verify(gateway, never())` |
| `Capture.In(list)` | `ArgumentCaptor` |
| `MockBehavior.Strict` : un appel sans setup échoue | stubs stricts : un stub jamais utilisé échoue (le comportement par défaut avec `MockitoExtension`) |

Les expressions Moq décrivent un appel dans une lambda ; Mockito enregistre l'appel sur le mock lui-même, d'où l'allure d'appel réel de `when(gateway.charge(...))`. Un `verify` en échec montre l'appel attendu et l'appel réel, avec la ligne de chacun :

```text
org.mockito.exceptions.verification.opentest4j.ArgumentsAreDifferent: 
Argument(s) are different! Wanted:
paymentGateway.charge("ada", 300L);
-> at shop.FailureMessagesTest.lambda$mockitoWrongArguments$0(FailureMessagesTest.java:75)
Actual invocations have different arguments at position [1]:
paymentGateway.charge("ada", 250L);
-> at shop.FailureMessagesTest.mockitoWrongArguments(FailureMessagesTest.java:74)
```

Les **stubs stricts** font échouer un test qui configure un appel qu'il ne fait jamais. Les mocks permissifs (loose) par défaut de Moq l'acceptent en silence ; Mockito, avec `MockitoExtension`, fait échouer le test après son exécution :

```text
org.mockito.exceptions.misusing.UnnecessaryStubbingException: 
Unnecessary stubbings detected.
Clean & maintainable test code requires zero unnecessary code.
Following stubbings are unnecessary (click to navigate to relevant line of code):
  1. -> at shop.FailureMessagesTest.mockitoUnusedStub(FailureMessagesTest.java:82)
Please remove unnecessary stubbings or use 'lenient' strictness. More info: javadoc for UnnecessaryStubbingException class.
```

Mockito sait aussi mocker ce que Moq ne peut pas : les classes finales, les records et les méthodes non virtuelles. Les méthodes Java sont virtuelles par défaut, et depuis Mockito 5 le mock maker « inline » par défaut réécrit le bytecode de la classe elle-même :

```java
@Test
void recordsAreFinalButCanStillBeMocked() {
    // Moq ne peut mocker que des interfaces et des membres virtuels ; Mockito 5 mocke aussi les classes finales.
    PaymentResult result = org.mockito.Mockito.mock(PaymentResult.class);
    when(result.approved()).thenReturn(true);
    assertThat(result.approved()).isTrue();
}
```

Pouvoir le faire n'en fait pas une bonne idée : mocker un record signale que la conception n'offre pas de point de découplage (seam) à cet endroit.

### L'agent Java de Mockito

Réécrire du bytecode demande un agent Java, et la [JEP 451](https://openjdk.org/jeps/451) (Java 21) avertit quand une bibliothèque charge un agent dans une JVM en cours d'exécution. Sans aucune configuration, les tests passent, mais la sortie indique :

```text
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build as described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (…byte-buddy-agent-1.17.7.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
```

La correction, tirée de la [documentation de Mockito](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3), consiste à démarrer la JVM de test avec Mockito comme agent. Le goal `properties` du plugin de dépendances expose le chemin du JAR sous forme de propriété, et Surefire la passe à la JVM :

```xml
      <!-- Définit des propriétés comme org.mockito:mockito-core:jar au chemin du JAR de chaque dépendance -->
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.11.0</version>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <!-- Charge Mockito et BlockHound comme agents Java au démarrage de la JVM de test, au lieu de les attacher à l'exécution -->
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
        <configuration>
          <argLine>${mockitoAgent} ${blockHoundAgent}</argLine>
```

`mockitoAgent` est une propriété qui vaut `-javaagent:${org.mockito:mockito-core:jar}`, et `blockHoundAgent` est celle de la section suivante ; le profil `self-attach` de l'exemple la vide pour reproduire l'avertissement. L'extrait de Mockito lui-même écrit `@{argLine}` devant, pour conserver les arguments qu'ajoutent d'autres plugins comme JaCoCo. Même avec l'agent, JDK 25 affiche toujours des avertissements sur `sun.misc.Unsafe` ([JEP 498](https://openjdk.org/jeps/498)), appelé par la bibliothèque Byte Buddy qu'utilise Mockito. Ceux-là viennent de la bibliothèque, pas de la configuration du build.

### Détecter les appels bloquants avec BlockHound

La leçon 9 a montré que bloquer ne coûte pas cher sur un thread virtuel. C'est pourtant un bug sur un thread qui ne doit jamais bloquer : les quelques threads de boucle d'événements (event loop) des bibliothèques réactives comme [Project Reactor](https://projectreactor.io/docs/core/release/reference/), sur laquelle repose Spring WebFlux, et Netty. Un seul `Thread.sleep` ou appel JDBC à cet endroit bloque toutes les requêtes que sert ce thread, un peu comme le sync-over-async en C#, où `.Result` monopolise un thread du pool. [BlockHound](https://github.com/reactor/BlockHound), de l'équipe Reactor, est un agent Java qui instrumente les méthodes bloquantes du JDK et lève une exception quand l'une d'elles s'exécute sur un thread marqué comme non bloquant :

```java
@Test
void blockingOnAParallelSchedulerThreadIsReported() throws IOException {
    // Mono.delay émet sur Schedulers.parallel(), dont les threads ne doivent jamais bloquer.
    FailureMessagesTest.check("blockhound", FailureMessagesTest.failureOf(() ->
            Mono.delay(Duration.ofMillis(1)).map(tick -> slowLookup("pen")).block()));
}

@Test
void blockingOnBoundedElasticIsAllowed() {
    // boundedElastic() est le scheduler de Reactor destiné au travail bloquant.
    String sku = Mono.fromCallable(() -> slowLookup("pad")).subscribeOn(Schedulers.boundedElastic()).block();
    assertThat(sku).isEqualTo("PAD");
}
```

`slowLookup` dort 10 ms. Sur un thread de `Schedulers.parallel()`, le pipeline échoue :

```text
reactor.core.Exceptions$ReactiveException: reactor.blockhound.BlockingOperationError: Blocking call! java.lang.Thread.sleepNanos0
```

Le même appel passe sur `boundedElastic()`, le scheduler prévu pour le travail bloquant, et sur un thread virtuel, que démarre un troisième test. `sleepNanos0` est la méthode privée de JDK 25 derrière `Thread.sleep` : BlockHound instrumente le JDK à ce niveau.

Le README de BlockHound l'installe depuis le code de test avec `BlockHound.install()`, qui attache l'agent à l'exécution, comme Mockito sans configuration. Sur JDK 25, cela a échoué sur ma machine avec « Could not self-attach to current VM using external process ». Le charger avec `-javaagent`, comme pour Mockito, va plus loin, mais la JVM de test s'arrête avant d'exécuter le moindre test :

```text
Caused by: java.lang.IllegalStateException: The instrumentation have failed.
It looks like you're running on JDK 13+.
You need to add '-XX:+AllowRedefinitionToAddDeleteMethods' JVM flag.
See https://github.com/reactor/BlockHound/issues/33 for more info.
```

Avec l'agent et le flag à la fois, les tests passent :

```xml
    <blockHoundAgent>-javaagent:${io.projectreactor.tools:blockhound:jar} -XX:+AllowRedefinitionToAddDeleteMethods</blockHoundAgent>
```

La JVM avertit alors à propos du flag lui-même :

```text
OpenJDK 64-Bit Server VM warning: Option AllowRedefinitionToAddDeleteMethods was deprecated in version 13.0 and will likely be removed in a future release.
```

BlockHound 1.0.17 repose sur une option de la JVM dépréciée depuis douze versions. Il vaut la peine de l'exécuter dans les tests de code réactif, mais revérifiez-le à chaque nouveau JDK avant qu'un build n'en dépende.

## Vérifier null au moment du build

La leçon 5 a laissé une question ouverte : Java peut-il obtenir les vérifications de null à la compilation qu'apportent les types référence nullables de C# ? La réponse tient en deux outils. [JSpecify](https://jspecify.dev/docs/user-guide/) standardise les annotations, et [NullAway](https://github.com/uber/NullAway), un plugin pour les vérifications du compilateur [Error Prone](https://errorprone.info/docs/installation) de Google, les fait respecter.

`@NullMarked` sur un package équivaut à `<Nullable>enable</Nullable>` : tout type qu'il contient est non null, sauf s'il est marqué `@Nullable`.

```java
// Tout type de ce package est non null sauf s'il est annoté @Nullable, comme <Nullable>enable</Nullable>.
@NullMarked
package shop;

import org.jspecify.annotations.NullMarked;
```

```java
// @Nullable dit ce que C# dit avec int? : les appelants doivent traiter le cas absent.
public static @Nullable Integer percentOff(String code) {
    return PERCENT_OFF.get(code);
}
```

javac traite ces annotations comme de la documentation. Cette classe compile, et lève `NullPointerException` pour un code inconnu :

```java
public final class Discounts {

    private Discounts() {}

    // Compile avec javac ; NullAway rejette les deux lignes qui utilisent le résultat @Nullable.
    public static int percentOrZero(String code) {
        return Coupons.percentOff(code);
    }

    public static String describe(String code) {
        return Coupons.percentOff(code).toString() + "% off";
    }
}
```

Avec NullAway (`mvn compile -Pnullaway` dans l'exemple), le build échoue :

```text
[ERROR] Discounts.java:[9,34] [NullAway] unboxing of a @Nullable expression 'Coupons.percentOff(code)'
[ERROR] Discounts.java:[13,40] [NullAway] dereferenced expression 'Coupons.percentOff(code)' is @Nullable
```

C# détecte les deux mêmes erreurs autrement : un `int?` ne se convertit pas en `int` sans cast (erreur CS0266), et déréférencer une référence possiblement null déclenche l'avertissement CS8602. La différence tient à la mise en place. C# a besoin d'une propriété ; côté Java, il faut Error Prone comme plugin du compilateur, NullAway sur le chemin des processeurs d'annotations, et trois arguments de compilation :

```xml
              <compilerArgs>
                <arg>-XDcompilePolicy=simple</arg>
                <arg>--should-stop=ifError=FLOW</arg>
                <arg>-Xplugin:ErrorProne -XepDisableAllChecks -Xep:NullAway:ERROR -XepOpt:NullAway:OnlyNullMarked=true</arg>
              </compilerArgs>
              <annotationProcessorPaths>
                <path>
                  <groupId>com.google.errorprone</groupId>
                  <artifactId>error_prone_core</artifactId>
                  <version>2.50.0</version>
                </path>
                <path>
                  <groupId>com.uber.nullaway</groupId>
                  <artifactId>nullaway</artifactId>
                  <version>0.14.1</version>
                </path>
              </annotationProcessorPaths>
```

`-XepDisableAllChecks` ne garde que NullAway, et `OnlyNullMarked=true` le limite au code `@NullMarked` : on peut donc l'adopter un package à la fois, comme `#nullable enable` dans un seul fichier. Error Prone utilise aussi des éléments internes de javac que le système de modules masque. Ma première exécution a échoué avec « An unknown compilation problem occurred » et, avec `-e`, une `IllegalAccessError`. La correction est un fichier `.mvn/jvm.config` de lignes `--add-exports` et `--add-opens`, copiées de la page d'installation d'Error Prone.

## À retenir

- JUnit Jupiter se calque presque trait pour trait sur xUnit : `@Test`, `@ParameterizedTest`, `@BeforeEach`, une nouvelle instance par test.
- AssertJ est le FluentAssertions de Java ; ses messages d'échec, et `assertSoftly`, valent la dépendance.
- Mockito enregistre les appels sur le mock lui-même ; avec `MockitoExtension`, ses stubs sont stricts. Il mocke les classes finales, ce que Moq ne sait pas faire.
- Sur JDK 21 et au-delà, chargez Mockito comme `-javaagent` dans l'`argLine` de Surefire, sinon la JVM avertit que l'auto-attachement cessera de fonctionner.
- BlockHound fait échouer les tests qui bloquent sur des threads non bloquants, comme ceux de Reactor. Sur JDK 25, il lui faut `-javaagent` et le flag déprécié `-XX:+AllowRedefinitionToAddDeleteMethods`.
- `@NullMarked` et `@Nullable` de JSpecify, vérifiés par NullAway via Error Prone, apportent au build une vérification de nullabilité à la C#.

## Exercices

1. Écrivez un test pour un paiement refusé : `place` doit lever `IllegalStateException` avec le message `payment declined for alan`, et la passerelle doit avoir été débitée exactement une fois de 300 centimes, et rien d'autre. Avec Moq, vous écririez `Verify(..., Times.Once())` et `VerifyNoOtherCalls()`.

<details>
<summary>Solution</summary>

```java
@Test
void exercise1DeclinedPayment() {
    var service = new OrderService(inventory, gateway, Clock.fixed(OrderServiceTest.NOON, ZoneOffset.UTC));
    when(inventory.inStock(anyString(), anyInt())).thenReturn(true);
    when(gateway.charge(anyString(), anyLong())).thenReturn(new PaymentResult(false, null));

    assertThatThrownBy(() -> service.place("alan", List.of(new Item("pen", 3, 100)), null))
            .isInstanceOf(IllegalStateException.class)
            .hasMessage("payment declined for alan");
    verify(gateway, times(1)).charge("alan", 300);
    verifyNoMoreInteractions(gateway);
}
```

`times(1)` est la valeur par défaut de `verify`, écrite ici pour refléter `Times.Once()`. `verifyNoMoreInteractions` est `VerifyNoOtherCalls`. La documentation de Mockito elle-même conseille de l'utiliser avec parcimonie, car elle lie le test à chaque appel que fait le code.

</details>

2. FluentAssertions compare des graphes d'objets avec `BeEquivalentTo`, en excluant éventuellement des membres. Vérifiez qu'une liste de reçus contient les clients et totaux `("ada", 300)` et `("grace", 1800)` dans cet ordre, puis comparez un reçu avec un reçu attendu en ignorant son identifiant de transaction.

<details>
<summary>Solution</summary>

```java
@Test
void exercise2Receipts() {
    var receipts = List.of(
            new Receipt("ada", 300, "tx-1", OrderServiceTest.NOON),
            new Receipt("grace", 1800, "tx-2", OrderServiceTest.NOON));

    assertThat(receipts)
            .extracting(Receipt::customer, Receipt::totalCents)
            .containsExactly(tuple("ada", 300L), tuple("grace", 1800L));
    assertThat(receipts.get(0))
            .usingRecursiveComparison()
            .ignoringFields("transactionId")
            .isEqualTo(new Receipt("ada", 300, "tx-999", OrderServiceTest.NOON));
}
```

`extracting` avec plusieurs références de méthodes transforme chaque reçu en tuple. Les totaux sont des `long` : les valeurs attendues ont donc besoin de `300L`, car `tuple("ada", 300)` contiendrait un `Integer` et ne correspondrait pas. `usingRecursiveComparison()` compare champ par champ, comme `BeEquivalentTo`, et n'a pas besoin d'`equals`.

</details>

3. Réécrivez les deux méthodes de `Discounts` pour que NullAway les accepte : `percentOrZero` renvoie 0 pour un code inconnu, et `describe` renvoie `no discount`.

<details>
<summary>Solution</summary>

```java
public static int percentOrZero(String code) {
    return Objects.requireNonNullElse(Coupons.percentOff(code), 0);
}

public static String describe(String code) {
    Integer percent = Coupons.percentOff(code);
    return percent == null ? "no discount" : percent + "% off";
}
```

L'exemple conserve cette version sous le nom `SafeDiscounts` dans le code principal, que le profil `nullaway` compile aussi : NullAway ne signale que les deux erreurs de `Discounts`. NullAway comprend la vérification de null sur la variable locale, comme l'analyse de flux de C#. `requireNonNullElse` est l'équivalent de `??`, et NullAway accepte son résultat comme non null.

</details>

## Sources

- [Guide utilisateur de JUnit](https://docs.junit.org/current/user-guide/), [tests paramétrés](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html)
- [Documentation d'AssertJ](https://assertj.github.io/doc/)
- [Documentation de Mockito](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html), [JEP 451 — Prepare to Disallow the Dynamic Loading of Agents](https://openjdk.org/jeps/451)
- [BlockHound](https://github.com/reactor/BlockHound), [guide de référence de Project Reactor](https://projectreactor.io/docs/core/release/reference/)
- [Maven Surefire et la JUnit Platform](https://maven.apache.org/surefire/maven-surefire-plugin/examples/junit-platform.html)
- [Guide utilisateur de JSpecify](https://jspecify.dev/docs/user-guide/), [NullAway](https://github.com/uber/NullAway), [installation d'Error Prone](https://errorprone.info/docs/installation)
- xUnit : [contexte partagé entre les tests](https://xunit.net/docs/shared-context) ; C# : [types référence nullables](https://learn.microsoft.com/dotnet/csharp/nullable-references)
