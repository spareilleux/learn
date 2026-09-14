---
title: 11. Testing
description: JUnit instead of xUnit, AssertJ instead of FluentAssertions, Mockito instead of Moq — plus Java agents for Mockito and BlockHound, and null checking at build time with JSpecify and NullAway.
sidebar:
  order: 11
---

Full example: [`code/java-for-csharp/l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), a small shop library with its tests. The failure messages quoted below are checked by a test, and [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l11/check.sh) compares the rest of the output with the lesson in CI.

## The same ideas, other names

Every tool a C# test project uses has a Java counterpart, and the concepts line up closely:

| .NET | Java |
|---|---|
| [xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), NUnit, MSTest | [JUnit](https://docs.junit.org/current/user-guide/) (Jupiter API) |
| `[Fact]` | `@Test` |
| `[Theory]` with `[InlineData]` / `[MemberData]` | `@ParameterizedTest` with `@CsvSource` / `@MethodSource` |
| constructor / `IDisposable` | `@BeforeEach` / `@AfterEach` |
| `IClassFixture<T>` | `@BeforeAll` / `@AfterAll` (static) |
| `[Trait("Category", "slow")]` | `@Tag("slow")` |
| `Assert.Equal`, `Assert.Throws` | `assertEquals`, `assertThrows` |
| [FluentAssertions](https://fluentassertions.com/) | [AssertJ](https://assertj.github.io/doc/) |
| [Moq](https://github.com/devlooped/moq) | [Mockito](https://site.mockito.org/) |
| [`TimeProvider`](https://learn.microsoft.com/dotnet/api/system.timeprovider) | `java.time.Clock` |
| `dotnet test` | `mvn test` ([Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)) |
| a separate `*.Tests` project | `src/test/java` in the same project |
| [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references) | [JSpecify](https://jspecify.dev/docs/user-guide/) annotations checked by [NullAway](https://github.com/uber/NullAway) |

Tests live in `src/test/java`, in the **same package** as the code they test. They can therefore use package-private members, where .NET needs `InternalsVisibleTo`. Test dependencies have the `test` scope from lesson 10, and the project imports two BOMs, JUnit's and Mockito's, so that the related artifacts share one version:

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

The class under test computes an order total: a 5% discount on any line of 10 items or more, then an optional coupon.

```java
class PriceCalculatorTest {

    private PriceCalculator calculator;
    private int testsRunOnThisInstance;

    // Runs before each test, on a new instance: the constructor of an xUnit test class.
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

- **A new instance per test.** Like [xUnit](https://xunit.net/docs/shared-context), and unlike NUnit, which reuses one instance per fixture, JUnit creates a new instance of the test class for each test method by default, so `testsRunOnThisInstance` is always 1. Fields are the per-test state; shared state goes into `static` fields set up in `@BeforeAll`.
- **No `public`.** Test classes and methods can be package-private, and usually are.
- **Expected value first.** `assertEquals(expected, actual)`, in the same order as `Assert.Equal`.
- **`assertThrows` returns the exception**, like `Assert.Throws<T>`, so the message can be checked next.

Parameterized tests are `[Theory]`. `@CsvSource` is `[InlineData]` written as CSV lines, and `@MethodSource` is `[MemberData]`:

```java
// [Theory] with [InlineData]: one test per row.
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

// [MemberData]: arguments built by a static method.
static Stream<Arguments> coupons() {
    return Stream.of(Arguments.of("TEN", 900), Arguments.of("HALF", 500));
}

@ParameterizedTest
@MethodSource("coupons")
void couponsTakeAPercentageOff(String code, long expectedCents) {
    assertEquals(expectedCents, calculator.totalCents(List.of(new Item("book", 1, 1000)), code));
}

// Nested classes group tests and share the outer setup.
@Nested
class InvalidItems {

    @Test
    void zeroQuantityIsRejected() {
        var e = assertThrows(IllegalArgumentException.class, () -> new Item("pen", 0, 100));
        assertEquals("quantity must be positive for pen: 0", e.getMessage());
    }
}
```

The names in the test report, sorted, are these:

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

Two details surprised me:

- **The numbers are quoted.** Since JUnit 6, text arguments are [quoted in display names](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html), and the quoting happens before conversion: the CSV value `"950"` is still a string at that point. `@MethodSource` passes a real `Integer`, so `900` isn't quoted.
- **Surefire ignores `@DisplayName` by default.** The report used method names until I configured a reporter with `usePhrasedTestCaseMethodName`. In the console, Surefire also reported all nine tests of the class under the nested class `PriceCalculatorTest$InvalidItems`, and zero under `PriceCalculatorTest`.

Run a subset with `mvn test -Dtest=PriceCalculatorTest` or `-Dtest='OrderServiceTest#outOfStock*'`, the counterparts of `dotnet test --filter`. Tags select groups with `-Dgroups=slow`.

## Assertions: JUnit and AssertJ

JUnit's assertions are enough for simple values. For collections and objects, many Java projects use AssertJ, which is to FluentAssertions what JUnit is to xUnit: `assertThat(actual).isEqualTo(expected)` chains, with far more detailed failure messages. The same list comparison, first with JUnit:

```java
assertEquals(List.of("pen", "pad"), List.of("pen", "pencil"))
```

```text
org.opentest4j.AssertionFailedError: expected: <[pen, pad]> but was: <[pen, pencil]>
```

Then with AssertJ:

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

AssertJ's `assertSoftly` is FluentAssertions' `AssertionScope`: it runs every assertion in the block and reports all the failures together:

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

`check` and `failureOf` are the example's helpers: they catch the failure and compare its message with the text above, so the lesson can't drift from what the libraries print.

## Mockito

`OrderService` checks the inventory, charges a payment gateway, and stamps the receipt with the time from a `Clock`. The two interfaces are mocked; the clock isn't, because `Clock.fixed` already gives a clock that never moves, the counterpart of .NET's `FakeTimeProvider`:

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
        // A fixed clock needs no mock, like FakeTimeProvider.
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
| `new Mock<IPaymentGateway>()`, `mock.Object` | `@Mock PaymentGateway gateway` (the mock *is* the object) |
| `Setup(g => g.Charge("ada", 300)).Returns(result)` | `when(gateway.charge("ada", 300)).thenReturn(result)` |
| `It.IsAny<string>()` | `anyString()`, `any()` |
| `Verify(g => g.Charge("ada", 300), Times.Once())` | `verify(gateway).charge("ada", 300)` |
| `Times.Never()` | `verify(gateway, never())` |
| `Capture.In(list)` | `ArgumentCaptor` |
| `MockBehavior.Strict`: a call without a setup fails | strict stubs: a stub that is never used fails (the default with `MockitoExtension`) |

Moq expressions describe a call inside a lambda; Mockito records the call on the mock itself, which is why `when(gateway.charge(...))` looks like a real call. A failed `verify` shows the expected and the actual call, with the line of each:

```text
org.mockito.exceptions.verification.opentest4j.ArgumentsAreDifferent: 
Argument(s) are different! Wanted:
paymentGateway.charge("ada", 300L);
-> at shop.FailureMessagesTest.lambda$mockitoWrongArguments$0(FailureMessagesTest.java:75)
Actual invocations have different arguments at position [1]:
paymentGateway.charge("ada", 250L);
-> at shop.FailureMessagesTest.mockitoWrongArguments(FailureMessagesTest.java:74)
```

**Strict stubs** fail a test that stubs a call it never makes. Moq's default loose mocks accept that silently; Mockito, with `MockitoExtension`, fails the test after it runs:

```text
org.mockito.exceptions.misusing.UnnecessaryStubbingException: 
Unnecessary stubbings detected.
Clean & maintainable test code requires zero unnecessary code.
Following stubbings are unnecessary (click to navigate to relevant line of code):
  1. -> at shop.FailureMessagesTest.mockitoUnusedStub(FailureMessagesTest.java:82)
Please remove unnecessary stubbings or use 'lenient' strictness. More info: javadoc for UnnecessaryStubbingException class.
```

Mockito can also mock what Moq can't: final classes, records and non-virtual methods. Java methods are virtual by default, and since Mockito 5 the default "inline" mock maker rewrites the bytecode of the class itself:

```java
@Test
void recordsAreFinalButCanStillBeMocked() {
    // Moq can only mock interfaces and virtual members; Mockito 5 also mocks final classes.
    PaymentResult result = org.mockito.Mockito.mock(PaymentResult.class);
    when(result.approved()).thenReturn(true);
    assertThat(result.approved()).isTrue();
}
```

Being able to doesn't make it a good idea: mocking a record says the design has no seam there.

### Mockito's Java agent

Rewriting bytecode requires a Java agent, and [JEP 451](https://openjdk.org/jeps/451) (Java 21) warns when a library loads an agent into a running JVM. With no configuration, the tests pass, but the output says:

```text
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build as described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (…byte-buddy-agent-1.17.7.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
```

The fix, from [Mockito's documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3), is to start the test JVM with Mockito as an agent. The `properties` goal of the dependency plugin exposes the JAR's path as a property, and Surefire passes it to the JVM:

```xml
      <!-- Sets properties such as org.mockito:mockito-core:jar to the path of each dependency's JAR -->
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
      <!-- Loads Mockito and BlockHound as Java agents when the test JVM starts, instead of attaching them at run time -->
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
        <configuration>
          <argLine>${mockitoAgent} ${blockHoundAgent}</argLine>
```

`mockitoAgent` is a property set to `-javaagent:${org.mockito:mockito-core:jar}`, and `blockHoundAgent` is the next section's; the example's `self-attach` profile empties it to reproduce the warning. Mockito's own snippet writes `@{argLine}` in front, to keep arguments that other plugins such as JaCoCo add. Even with the agent, JDK 25 still prints warnings about `sun.misc.Unsafe` ([JEP 498](https://openjdk.org/jeps/498)), called by the Byte Buddy library that Mockito uses. Those come from the library, not from the build configuration.

### Catching blocking calls with BlockHound

Lesson 9 showed that blocking is cheap on a virtual thread. It is still a bug on a thread that must never block: the few event-loop threads of reactive libraries such as [Project Reactor](https://projectreactor.io/docs/core/release/reference/), which Spring WebFlux is built on, and Netty. One `Thread.sleep` or JDBC call there stalls every request that thread serves, much like sync-over-async in C#, where `.Result` holds a thread-pool thread. [BlockHound](https://github.com/reactor/BlockHound), from the Reactor team, is a Java agent that instruments the JDK's blocking methods and throws when one of them runs on a thread marked as non-blocking:

```java
@Test
void blockingOnAParallelSchedulerThreadIsReported() throws IOException {
    // Mono.delay emits on Schedulers.parallel(), whose threads must never block.
    FailureMessagesTest.check("blockhound", FailureMessagesTest.failureOf(() ->
            Mono.delay(Duration.ofMillis(1)).map(tick -> slowLookup("pen")).block()));
}

@Test
void blockingOnBoundedElasticIsAllowed() {
    // boundedElastic() is Reactor's scheduler for blocking work.
    String sku = Mono.fromCallable(() -> slowLookup("pad")).subscribeOn(Schedulers.boundedElastic()).block();
    assertThat(sku).isEqualTo("PAD");
}
```

`slowLookup` sleeps for 10 ms. On a thread of `Schedulers.parallel()`, the pipeline fails:

```text
reactor.core.Exceptions$ReactiveException: reactor.blockhound.BlockingOperationError: Blocking call! java.lang.Thread.sleepNanos0
```

The same call passes on `boundedElastic()`, the scheduler meant for blocking work, and on a virtual thread, which a third test starts. `sleepNanos0` is the private JDK 25 method behind `Thread.sleep`: BlockHound instruments the JDK at that level.

BlockHound's README installs it from the test code with `BlockHound.install()`, which attaches the agent at run time, as Mockito does without configuration. On JDK 25 that failed on my machine with "Could not self-attach to current VM using external process". Loading it with `-javaagent`, as for Mockito, gets further, but the test JVM stops before running a single test:

```text
Caused by: java.lang.IllegalStateException: The instrumentation have failed.
It looks like you're running on JDK 13+.
You need to add '-XX:+AllowRedefinitionToAddDeleteMethods' JVM flag.
See https://github.com/reactor/BlockHound/issues/33 for more info.
```

With both the agent and the flag, the tests pass:

```xml
    <blockHoundAgent>-javaagent:${io.projectreactor.tools:blockhound:jar} -XX:+AllowRedefinitionToAddDeleteMethods</blockHoundAgent>
```

The JVM then warns about the flag itself:

```text
OpenJDK 64-Bit Server VM warning: Option AllowRedefinitionToAddDeleteMethods was deprecated in version 13.0 and will likely be removed in a future release.
```

BlockHound 1.0.17 relies on a JVM option deprecated twelve releases ago. It is worth running in the tests of reactive code, but check it again with each new JDK before a build depends on it.

## Null checking at build time

Lesson 5 left a question open: can Java get the compile-time null checks that C#'s nullable reference types give? The answer is two tools. [JSpecify](https://jspecify.dev/docs/user-guide/) standardises the annotations, and [NullAway](https://github.com/uber/NullAway), a plugin for Google's [Error Prone](https://errorprone.info/docs/installation) compiler checks, enforces them.

`@NullMarked` on a package is `<Nullable>enable</Nullable>`: every type in it is non-null unless marked `@Nullable`.

```java
// Every type in this package is non-null unless annotated @Nullable, like <Nullable>enable</Nullable>.
@NullMarked
package shop;

import org.jspecify.annotations.NullMarked;
```

```java
// @Nullable says what C# says with int?: callers must handle the missing case.
public static @Nullable Integer percentOff(String code) {
    return PERCENT_OFF.get(code);
}
```

javac treats these annotations as documentation. This class compiles, and throws `NullPointerException` for an unknown code:

```java
public final class Discounts {

    private Discounts() {}

    // Compiles with javac; NullAway rejects both lines that use the @Nullable result.
    public static int percentOrZero(String code) {
        return Coupons.percentOff(code);
    }

    public static String describe(String code) {
        return Coupons.percentOff(code).toString() + "% off";
    }
}
```

With NullAway (`mvn compile -Pnullaway` in the example), the build fails:

```text
[ERROR] Discounts.java:[9,34] [NullAway] unboxing of a @Nullable expression 'Coupons.percentOff(code)'
[ERROR] Discounts.java:[13,40] [NullAway] dereferenced expression 'Coupons.percentOff(code)' is @Nullable
```

C# catches the same two mistakes differently: an `int?` doesn't convert to `int` without a cast (error CS0266), and dereferencing a possibly null reference is warning CS8602. The difference is the setup. C# needs one property; the Java side needs Error Prone as a compiler plugin, NullAway on the annotation processor path, and three compiler arguments:

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

`-XepDisableAllChecks` keeps only NullAway, and `OnlyNullMarked=true` limits it to `@NullMarked` code, so it can be adopted one package at a time, like `#nullable enable` in one file. Error Prone also uses javac internals that the module system hides. My first run failed with "An unknown compilation problem occurred" and, with `-e`, an `IllegalAccessError`. The fix is a `.mvn/jvm.config` file of `--add-exports` and `--add-opens` lines, copied from Error Prone's installation page.

## Key takeaways

- JUnit Jupiter maps onto xUnit almost one to one: `@Test`, `@ParameterizedTest`, `@BeforeEach`, a new instance per test.
- AssertJ is Java's FluentAssertions; its failure messages, and `assertSoftly`, are worth the dependency.
- Mockito records calls on the mock itself; with `MockitoExtension` its stubs are strict. It mocks final classes, which Moq can't.
- On JDK 21 and later, load Mockito as a `-javaagent` in Surefire's `argLine`, or the JVM warns that self-attaching will stop working.
- BlockHound fails tests that block on non-blocking threads, such as Reactor's. On JDK 25 it needs `-javaagent` and the deprecated `-XX:+AllowRedefinitionToAddDeleteMethods` flag.
- JSpecify's `@NullMarked` and `@Nullable`, checked by NullAway through Error Prone, bring C#-style nullable checking to the build.

## Exercises

1. Write a test for a declined payment: `place` must throw `IllegalStateException` with the message `payment declined for alan`, and the gateway must have been charged exactly once with 300 cents, and nothing else. In Moq you would write `Verify(..., Times.Once())` and `VerifyNoOtherCalls()`.

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

`times(1)` is the default of `verify`, written out here to mirror `Times.Once()`. `verifyNoMoreInteractions` is `VerifyNoOtherCalls`. Mockito's own documentation advises using it sparingly, because it ties the test to every call the code makes.

</details>

2. FluentAssertions compares object graphs with `BeEquivalentTo`, optionally excluding members. Check that a list of receipts has the customers and totals `("ada", 300)` and `("grace", 1800)` in that order, then compare one receipt with an expected one while ignoring its transaction ID.

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

`extracting` with several method references turns each receipt into a tuple. The totals are `long`, so the expected values need `300L`: `tuple("ada", 300)` would hold an `Integer` and fail to match. `usingRecursiveComparison()` compares field by field, like `BeEquivalentTo`, and doesn't need `equals`.

</details>

3. Rewrite the two `Discounts` methods so that NullAway accepts them: `percentOrZero` returns 0 for an unknown code, and `describe` returns `no discount`.

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

The example keeps this version as `SafeDiscounts` in the main code, which the `nullaway` profile also compiles: NullAway reports only the two errors in `Discounts`. NullAway understands the null check on the local variable, like C#'s flow analysis. `requireNonNullElse` is the counterpart of `??`, and NullAway accepts its result as non-null.

</details>

## Sources

- [JUnit User Guide](https://docs.junit.org/current/user-guide/), [parameterized tests](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html)
- [AssertJ documentation](https://assertj.github.io/doc/)
- [Mockito documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html), [JEP 451 — Prepare to Disallow the Dynamic Loading of Agents](https://openjdk.org/jeps/451)
- [BlockHound](https://github.com/reactor/BlockHound), [Project Reactor reference guide](https://projectreactor.io/docs/core/release/reference/)
- [Maven Surefire and the JUnit Platform](https://maven.apache.org/surefire/maven-surefire-plugin/examples/junit-platform.html)
- [JSpecify user guide](https://jspecify.dev/docs/user-guide/), [NullAway](https://github.com/uber/NullAway), [Error Prone installation](https://errorprone.info/docs/installation)
- xUnit: [shared context between tests](https://xunit.net/docs/shared-context); C#: [nullable reference types](https://learn.microsoft.com/dotnet/csharp/nullable-references)
