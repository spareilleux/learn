---
title: 11. Pruebas
description: JUnit en lugar de xUnit, AssertJ en lugar de FluentAssertions, Mockito en lugar de Moq — además de los agentes Java de Mockito y BlockHound, y la comprobación de null durante el build con JSpecify y NullAway.
sidebar:
  order: 11
---

Ejemplo completo: [`code/java-for-csharp/l11`](https://github.com/spareilleux/learn/tree/main/code/java-for-csharp/l11), una pequeña biblioteca de tienda con sus pruebas. Una prueba comprueba los mensajes de fallo citados abajo, y [`check.sh`](https://github.com/spareilleux/learn/blob/main/code/java-for-csharp/l11/check.sh) compara en CI el resto de la salida con la lección.

## Las mismas ideas, otros nombres

Cada herramienta que usa un proyecto de pruebas C# tiene su equivalente en Java, y los conceptos se corresponden de cerca:

| .NET | Java |
|---|---|
| [xUnit](https://learn.microsoft.com/dotnet/core/testing/unit-testing-csharp-with-xunit), NUnit, MSTest | [JUnit](https://docs.junit.org/current/user-guide/) (API Jupiter) |
| `[Fact]` | `@Test` |
| `[Theory]` con `[InlineData]` / `[MemberData]` | `@ParameterizedTest` con `@CsvSource` / `@MethodSource` |
| constructor / `IDisposable` | `@BeforeEach` / `@AfterEach` |
| `IClassFixture<T>` | `@BeforeAll` / `@AfterAll` (estáticos) |
| `[Trait("Category", "slow")]` | `@Tag("slow")` |
| `Assert.Equal`, `Assert.Throws` | `assertEquals`, `assertThrows` |
| [FluentAssertions](https://fluentassertions.com/) | [AssertJ](https://assertj.github.io/doc/) |
| [Moq](https://github.com/devlooped/moq) | [Mockito](https://site.mockito.org/) |
| [`TimeProvider`](https://learn.microsoft.com/dotnet/api/system.timeprovider) | `java.time.Clock` |
| `dotnet test` | `mvn test` ([Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)) |
| un proyecto `*.Tests` aparte | `src/test/java` en el mismo proyecto |
| [tipos de referencia que aceptan valores NULL](https://learn.microsoft.com/dotnet/csharp/nullable-references) | anotaciones [JSpecify](https://jspecify.dev/docs/user-guide/) comprobadas por [NullAway](https://github.com/uber/NullAway) |

Las pruebas viven en `src/test/java`, en el **mismo paquete** que el código que prueban. Por eso pueden usar miembros package-private, donde .NET necesita `InternalsVisibleTo`. Las dependencias de prueba tienen el ámbito `test` de la lección 10, y el proyecto importa dos BOM, el de JUnit y el de Mockito, para que los artefactos relacionados compartan una misma versión:

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

La clase bajo prueba calcula el total de un pedido: un 5 % de descuento en cualquier línea de 10 artículos o más, y después un cupón opcional.

```java
class PriceCalculatorTest {

    private PriceCalculator calculator;
    private int testsRunOnThisInstance;

    // Se ejecuta antes de cada prueba, sobre una instancia nueva: el constructor de una clase de pruebas xUnit.
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

- **Una instancia nueva por prueba.** Como [xUnit](https://xunit.net/docs/shared-context), y a diferencia de NUnit, que reutiliza una instancia por fixture, JUnit crea por defecto una instancia nueva de la clase de pruebas para cada método de prueba, así que `testsRunOnThisInstance` vale siempre 1. Los campos son el estado de cada prueba; el estado compartido va en campos `static` inicializados en `@BeforeAll`.
- **Sin `public`.** Las clases y los métodos de prueba pueden ser package-private, y normalmente lo son.
- **Primero el valor esperado.** `assertEquals(expected, actual)`, en el mismo orden que `Assert.Equal`.
- **`assertThrows` devuelve la excepción**, como `Assert.Throws<T>`, así que a continuación se puede comprobar el mensaje.

Las pruebas parametrizadas son `[Theory]`. `@CsvSource` es `[InlineData]` escrito como líneas CSV, y `@MethodSource` es `[MemberData]`:

```java
// [Theory] con [InlineData]: una prueba por fila.
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

// [MemberData]: argumentos construidos por un método estático.
static Stream<Arguments> coupons() {
    return Stream.of(Arguments.of("TEN", 900), Arguments.of("HALF", 500));
}

@ParameterizedTest
@MethodSource("coupons")
void couponsTakeAPercentageOff(String code, long expectedCents) {
    assertEquals(expectedCents, calculator.totalCents(List.of(new Item("book", 1, 1000)), code));
}

// Las clases anidadas agrupan pruebas y comparten la preparación de la clase exterior.
@Nested
class InvalidItems {

    @Test
    void zeroQuantityIsRejected() {
        var e = assertThrows(IllegalArgumentException.class, () -> new Item("pen", 0, 100));
        assertEquals("quantity must be positive for pen: 0", e.getMessage());
    }
}
```

Los nombres del informe de pruebas, ordenados, son estos:

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

Dos detalles me sorprendieron:

- **Los números van entre comillas.** Desde JUnit 6, los argumentos de texto se [entrecomillan en los nombres visibles](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html), y el entrecomillado ocurre antes de la conversión: el valor CSV `"950"` sigue siendo una cadena en ese momento. `@MethodSource` pasa un `Integer` de verdad, así que `900` no va entre comillas.
- **Surefire ignora `@DisplayName` por defecto.** El informe usaba los nombres de los métodos hasta que configuré un reporter con `usePhrasedTestCaseMethodName`. En la consola, Surefire además atribuyó las nueve pruebas de la clase a la clase anidada `PriceCalculatorTest$InvalidItems`, y ninguna a `PriceCalculatorTest`.

Ejecuta un subconjunto con `mvn test -Dtest=PriceCalculatorTest` o `-Dtest='OrderServiceTest#outOfStock*'`, los equivalentes de `dotnet test --filter`. Las etiquetas seleccionan grupos con `-Dgroups=slow`.

## Aserciones: JUnit y AssertJ

Las aserciones de JUnit bastan para valores simples. Para colecciones y objetos, muchos proyectos Java usan AssertJ, que es a FluentAssertions lo que JUnit es a xUnit: cadenas `assertThat(actual).isEqualTo(expected)`, con mensajes de fallo mucho más detallados. La misma comparación de listas, primero con JUnit:

```java
assertEquals(List.of("pen", "pad"), List.of("pen", "pencil"))
```

```text
org.opentest4j.AssertionFailedError: expected: <[pen, pad]> but was: <[pen, pencil]>
```

Después con AssertJ:

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

El `assertSoftly` de AssertJ es el `AssertionScope` de FluentAssertions: ejecuta todas las aserciones del bloque e informa de todos los fallos juntos:

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

`check` y `failureOf` son funciones auxiliares del ejemplo: capturan el fallo y comparan su mensaje con el texto de arriba, así que la lección no puede desviarse de lo que imprimen las bibliotecas.

## Mockito

`OrderService` comprueba el inventario, cobra a través de una pasarela de pago y pone en el recibo la hora de un `Clock`. Las dos interfaces se sustituyen por mocks; el reloj no, porque `Clock.fixed` ya da un reloj que nunca avanza, el equivalente del `FakeTimeProvider` de .NET:

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
        // Un reloj fijo no necesita mock, como FakeTimeProvider.
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
| `new Mock<IPaymentGateway>()`, `mock.Object` | `@Mock PaymentGateway gateway` (el mock *es* el objeto) |
| `Setup(g => g.Charge("ada", 300)).Returns(result)` | `when(gateway.charge("ada", 300)).thenReturn(result)` |
| `It.IsAny<string>()` | `anyString()`, `any()` |
| `Verify(g => g.Charge("ada", 300), Times.Once())` | `verify(gateway).charge("ada", 300)` |
| `Times.Never()` | `verify(gateway, never())` |
| `Capture.In(list)` | `ArgumentCaptor` |
| `MockBehavior.Strict`: falla una llamada sin setup | stubs estrictos: falla un stub que nunca se usa (el comportamiento por defecto con `MockitoExtension`) |

Las expresiones de Moq describen una llamada dentro de una lambda; Mockito registra la llamada sobre el propio mock, y por eso `when(gateway.charge(...))` parece una llamada real. Un `verify` fallido muestra la llamada esperada y la real, con la línea de cada una:

```text
org.mockito.exceptions.verification.opentest4j.ArgumentsAreDifferent: 
Argument(s) are different! Wanted:
paymentGateway.charge("ada", 300L);
-> at shop.FailureMessagesTest.lambda$mockitoWrongArguments$0(FailureMessagesTest.java:75)
Actual invocations have different arguments at position [1]:
paymentGateway.charge("ada", 250L);
-> at shop.FailureMessagesTest.mockitoWrongArguments(FailureMessagesTest.java:74)
```

**Los stubs estrictos** hacen fallar una prueba que prepara un stub para una llamada que nunca hace. Los mocks laxos (loose) que Moq usa por defecto lo aceptan sin decir nada; Mockito, con `MockitoExtension`, hace fallar la prueba después de ejecutarla:

```text
org.mockito.exceptions.misusing.UnnecessaryStubbingException: 
Unnecessary stubbings detected.
Clean & maintainable test code requires zero unnecessary code.
Following stubbings are unnecessary (click to navigate to relevant line of code):
  1. -> at shop.FailureMessagesTest.mockitoUnusedStub(FailureMessagesTest.java:82)
Please remove unnecessary stubbings or use 'lenient' strictness. More info: javadoc for UnnecessaryStubbingException class.
```

Mockito también puede crear mocks de lo que Moq no puede: clases final, records y métodos no virtuales. Los métodos Java son virtuales por defecto, y desde Mockito 5 el mock maker «inline» por defecto reescribe el bytecode de la propia clase:

```java
@Test
void recordsAreFinalButCanStillBeMocked() {
    // Moq solo puede simular interfaces y miembros virtuales; Mockito 5 también simula clases final.
    PaymentResult result = org.mockito.Mockito.mock(PaymentResult.class);
    when(result.approved()).thenReturn(true);
    assertThat(result.approved()).isTrue();
}
```

Poder hacerlo no lo convierte en buena idea: crear un mock de un record indica que el diseño no tiene ahí ninguna costura (seam).

### El agente Java de Mockito

Reescribir bytecode requiere un agente Java, y [JEP 451](https://openjdk.org/jeps/451) (Java 21) advierte cuando una biblioteca carga un agente en una JVM en ejecución. Sin ninguna configuración, las pruebas pasan, pero la salida dice:

```text
Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK. Please add Mockito as an agent to your build as described in Mockito's documentation: https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3
WARNING: A Java agent has been loaded dynamically (…byte-buddy-agent-1.17.7.jar)
WARNING: If a serviceability tool is in use, please run with -XX:+EnableDynamicAgentLoading to hide this warning
WARNING: If a serviceability tool is not in use, please run with -Djdk.instrument.traceUsage for more information
WARNING: Dynamic loading of agents will be disallowed by default in a future release
```

La solución, según la [documentación de Mockito](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html#0.3), es arrancar la JVM de pruebas con Mockito como agente. El goal `properties` del plugin de dependencias expone la ruta del JAR como propiedad, y Surefire se la pasa a la JVM:

```xml
      <!-- Asigna a propiedades como org.mockito:mockito-core:jar la ruta del JAR de cada dependencia -->
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
      <!-- Carga Mockito y BlockHound como agentes Java al arrancar la JVM de pruebas, en lugar de adjuntarlos en tiempo de ejecución -->
      <plugin>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
        <configuration>
          <argLine>${mockitoAgent} ${blockHoundAgent}</argLine>
```

`mockitoAgent` es una propiedad con el valor `-javaagent:${org.mockito:mockito-core:jar}`, y `blockHoundAgent` es la de la sección siguiente; el perfil `self-attach` del ejemplo la vacía para reproducir la advertencia. El fragmento de la propia documentación de Mockito escribe `@{argLine}` delante, para conservar los argumentos que añaden otros plugins como JaCoCo. Incluso con el agente, JDK 25 sigue imprimiendo advertencias sobre `sun.misc.Unsafe` ([JEP 498](https://openjdk.org/jeps/498)), llamado por la biblioteca Byte Buddy que usa Mockito. Esas advertencias vienen de la biblioteca, no de la configuración del build.

### Detectar llamadas bloqueantes con BlockHound

La lección 9 mostró que bloquear es barato en un hilo virtual. Sigue siendo un error en un hilo que nunca debe bloquearse: los pocos hilos de bucle de eventos (event loop) de las bibliotecas reactivas como [Project Reactor](https://projectreactor.io/docs/core/release/reference/), sobre la que está construido Spring WebFlux, y Netty. Un solo `Thread.sleep` o una llamada JDBC ahí paraliza todas las peticiones que atiende ese hilo, de forma parecida a sync-over-async en C#, donde `.Result` retiene un hilo del thread pool. [BlockHound](https://github.com/reactor/BlockHound), del equipo de Reactor, es un agente Java que instrumenta los métodos bloqueantes del JDK y lanza una excepción cuando uno de ellos se ejecuta en un hilo marcado como no bloqueante:

```java
@Test
void blockingOnAParallelSchedulerThreadIsReported() throws IOException {
    // Mono.delay emite en Schedulers.parallel(), cuyos hilos nunca deben bloquearse.
    FailureMessagesTest.check("blockhound", FailureMessagesTest.failureOf(() ->
            Mono.delay(Duration.ofMillis(1)).map(tick -> slowLookup("pen")).block()));
}

@Test
void blockingOnBoundedElasticIsAllowed() {
    // boundedElastic() es el planificador de Reactor para el trabajo bloqueante.
    String sku = Mono.fromCallable(() -> slowLookup("pad")).subscribeOn(Schedulers.boundedElastic()).block();
    assertThat(sku).isEqualTo("PAD");
}
```

`slowLookup` duerme 10 ms. En un hilo de `Schedulers.parallel()`, el pipeline falla:

```text
reactor.core.Exceptions$ReactiveException: reactor.blockhound.BlockingOperationError: Blocking call! java.lang.Thread.sleepNanos0
```

La misma llamada pasa en `boundedElastic()`, el planificador pensado para el trabajo bloqueante, y en un hilo virtual, que arranca una tercera prueba. `sleepNanos0` es el método privado de JDK 25 que hay detrás de `Thread.sleep`: BlockHound instrumenta el JDK a ese nivel.

El README de BlockHound lo instala desde el código de prueba con `BlockHound.install()`, que adjunta el agente en tiempo de ejecución, como hace Mockito sin configuración. En JDK 25 eso falló en mi máquina con «Could not self-attach to current VM using external process». Cargarlo con `-javaagent`, como con Mockito, llega más lejos, pero la JVM de pruebas se detiene antes de ejecutar una sola prueba:

```text
Caused by: java.lang.IllegalStateException: The instrumentation have failed.
It looks like you're running on JDK 13+.
You need to add '-XX:+AllowRedefinitionToAddDeleteMethods' JVM flag.
See https://github.com/reactor/BlockHound/issues/33 for more info.
```

Con el agente y la opción a la vez, las pruebas pasan:

```xml
    <blockHoundAgent>-javaagent:${io.projectreactor.tools:blockhound:jar} -XX:+AllowRedefinitionToAddDeleteMethods</blockHoundAgent>
```

Después la JVM advierte sobre la propia opción:

```text
OpenJDK 64-Bit Server VM warning: Option AllowRedefinitionToAddDeleteMethods was deprecated in version 13.0 and will likely be removed in a future release.
```

BlockHound 1.0.17 depende de una opción de la JVM obsoleta desde hace doce versiones. Merece la pena ejecutarlo en las pruebas de código reactivo, pero vuelve a comprobarlo con cada JDK nuevo antes de que un build dependa de él.

## Comprobación de null durante el build

La lección 5 dejó una pregunta abierta: ¿puede Java tener las comprobaciones de null en tiempo de compilación que dan los tipos de referencia que aceptan valores NULL de C#? La respuesta son dos herramientas. [JSpecify](https://jspecify.dev/docs/user-guide/) estandariza las anotaciones, y [NullAway](https://github.com/uber/NullAway), un plugin para [Error Prone](https://errorprone.info/docs/installation), las comprobaciones de compilación de Google, las hace cumplir.

`@NullMarked` sobre un paquete es `<Nullable>enable</Nullable>`: todo tipo que contiene es no nulo salvo que se marque `@Nullable`.

```java
// Todo tipo de este paquete es no nulo salvo que se anote con @Nullable, como <Nullable>enable</Nullable>.
@NullMarked
package shop;

import org.jspecify.annotations.NullMarked;
```

```java
// @Nullable dice lo que C# dice con int?: quien llama debe tratar el caso ausente.
public static @Nullable Integer percentOff(String code) {
    return PERCENT_OFF.get(code);
}
```

javac trata estas anotaciones como documentación. Esta clase compila, y lanza `NullPointerException` para un código desconocido:

```java
public final class Discounts {

    private Discounts() {}

    // Compila con javac; NullAway rechaza las dos líneas que usan el resultado @Nullable.
    public static int percentOrZero(String code) {
        return Coupons.percentOff(code);
    }

    public static String describe(String code) {
        return Coupons.percentOff(code).toString() + "% off";
    }
}
```

Con NullAway (`mvn compile -Pnullaway` en el ejemplo), el build falla:

```text
[ERROR] Discounts.java:[9,34] [NullAway] unboxing of a @Nullable expression 'Coupons.percentOff(code)'
[ERROR] Discounts.java:[13,40] [NullAway] dereferenced expression 'Coupons.percentOff(code)' is @Nullable
```

C# detecta los mismos dos errores de otra manera: un `int?` no se convierte en `int` sin un cast (error CS0266), y desreferenciar una referencia posiblemente nula es la advertencia CS8602. La diferencia está en la configuración. C# necesita una propiedad; el lado Java necesita Error Prone como plugin del compilador, NullAway en la ruta de procesadores de anotaciones y tres argumentos del compilador:

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

`-XepDisableAllChecks` deja solo NullAway, y `OnlyNullMarked=true` lo limita al código `@NullMarked`, así que se puede adoptar paquete a paquete, como `#nullable enable` en un archivo. Error Prone también usa partes internas de javac que el sistema de módulos oculta. Mi primera ejecución falló con «An unknown compilation problem occurred» y, con `-e`, un `IllegalAccessError`. La solución es un archivo `.mvn/jvm.config` con líneas `--add-exports` y `--add-opens`, copiadas de la página de instalación de Error Prone.

## Puntos clave

- JUnit Jupiter se corresponde con xUnit casi uno a uno: `@Test`, `@ParameterizedTest`, `@BeforeEach`, una instancia nueva por prueba.
- AssertJ es el FluentAssertions de Java; sus mensajes de fallo, y `assertSoftly`, justifican la dependencia.
- Mockito registra las llamadas sobre el propio mock; con `MockitoExtension` sus stubs son estrictos. Crea mocks de clases final, algo que Moq no puede hacer.
- En JDK 21 y posteriores, carga Mockito como `-javaagent` en el `argLine` de Surefire, o la JVM advertirá de que adjuntarse a sí mismo dejará de funcionar.
- BlockHound hace fallar las pruebas que bloquean en hilos no bloqueantes, como los de Reactor. En JDK 25 necesita `-javaagent` y la opción obsoleta `-XX:+AllowRedefinitionToAddDeleteMethods`.
- `@NullMarked` y `@Nullable` de JSpecify, comprobados por NullAway a través de Error Prone, llevan al build la comprobación de null al estilo de C#.

## Ejercicios

1. Escribe una prueba para un pago rechazado: `place` debe lanzar `IllegalStateException` con el mensaje `payment declined for alan`, y la pasarela debe haber recibido exactamente un cobro de 300 céntimos, y nada más. En Moq escribirías `Verify(..., Times.Once())` y `VerifyNoOtherCalls()`.

<details>
<summary>Solución</summary>

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

`times(1)` es el valor por defecto de `verify`, escrito aquí de forma explícita para reflejar `Times.Once()`. `verifyNoMoreInteractions` es `VerifyNoOtherCalls`. La propia documentación de Mockito aconseja usarlo con moderación, porque ata la prueba a cada llamada que hace el código.

</details>

2. FluentAssertions compara grafos de objetos con `BeEquivalentTo`, con la opción de excluir miembros. Comprueba que una lista de recibos tiene los clientes y totales `("ada", 300)` y `("grace", 1800)` en ese orden, y después compara un recibo con uno esperado ignorando su ID de transacción.

<details>
<summary>Solución</summary>

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

`extracting` con varias referencias a métodos convierte cada recibo en una tupla. Los totales son `long`, así que los valores esperados necesitan `300L`: `tuple("ada", 300)` contendría un `Integer` y no coincidiría. `usingRecursiveComparison()` compara campo a campo, como `BeEquivalentTo`, y no necesita `equals`.

</details>

3. Reescribe los dos métodos de `Discounts` para que NullAway los acepte: `percentOrZero` devuelve 0 para un código desconocido, y `describe` devuelve `no discount`.

<details>
<summary>Solución</summary>

```java
public static int percentOrZero(String code) {
    return Objects.requireNonNullElse(Coupons.percentOff(code), 0);
}

public static String describe(String code) {
    Integer percent = Coupons.percentOff(code);
    return percent == null ? "no discount" : percent + "% off";
}
```

El ejemplo guarda esta versión como `SafeDiscounts` en el código principal, que el perfil `nullaway` también compila: NullAway solo informa de los dos errores de `Discounts`. NullAway entiende la comprobación de null sobre la variable local, como el análisis de flujo de C#. `requireNonNullElse` es el equivalente de `??`, y NullAway acepta su resultado como no nulo.

</details>

## Fuentes

- [Guía de usuario de JUnit](https://docs.junit.org/current/user-guide/), [pruebas parametrizadas](https://docs.junit.org/current/writing-tests/parameterized-classes-and-tests.html)
- [Documentación de AssertJ](https://assertj.github.io/doc/)
- [Documentación de Mockito](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html), [JEP 451 — Prepare to Disallow the Dynamic Loading of Agents](https://openjdk.org/jeps/451)
- [BlockHound](https://github.com/reactor/BlockHound), [guía de referencia de Project Reactor](https://projectreactor.io/docs/core/release/reference/)
- [Maven Surefire y la JUnit Platform](https://maven.apache.org/surefire/maven-surefire-plugin/examples/junit-platform.html)
- [Guía de usuario de JSpecify](https://jspecify.dev/docs/user-guide/), [NullAway](https://github.com/uber/NullAway), [instalación de Error Prone](https://errorprone.info/docs/installation)
- xUnit: [contexto compartido entre pruebas](https://xunit.net/docs/shared-context); C#: [tipos de referencia que aceptan valores NULL](https://learn.microsoft.com/dotnet/csharp/nullable-references)
