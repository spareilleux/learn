package shop;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.assertj.core.api.SoftAssertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.function.Executable;
import org.mockito.MockitoSession;
import org.mockito.quality.Strictness;

/**
 * Captures the message each failing assertion produces and compares it with the text quoted in the lesson,
 * stored under src/test/resources/messages. The actual messages are also written to target/messages.
 */
class FailureMessagesTest {

    static String failureOf(Executable failing) {
        try {
            failing.execute();
        } catch (Throwable t) {
            return t.getClass().getName() + ": " + t.getMessage();
        }
        throw new AssertionError("expected a failure");
    }

    static String quoted(String name) throws IOException {
        try (InputStream in = FailureMessagesTest.class.getResourceAsStream("/messages/" + name + ".txt")) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8).replace("\r\n", "\n").strip();
        }
    }

    static void check(String name, String actual) throws IOException {
        String normalized = actual.replace("\r\n", "\n").strip();
        Path copy = Path.of("target", "messages", name + ".txt");
        Files.createDirectories(copy.getParent());
        Files.writeString(copy, normalized + "\n");
        assertEquals(quoted(name), normalized);
    }

    @Test
    void junitAssertEquals() throws IOException {
        check("junit-assert-equals", failureOf(() ->
                assertEquals(List.of("pen", "pad"), List.of("pen", "pencil"))));
    }

    @Test
    void assertjContainsExactly() throws IOException {
        check("assertj-contains-exactly", failureOf(() ->
                assertThat(List.of("pen", "pencil")).containsExactly("pen", "pad")));
    }

    @Test
    void assertjSoftAssertions() throws IOException {
        var receipt = new Receipt("ada", 250, "tx-1", OrderServiceTest.NOON);
        check("assertj-soft", failureOf(() -> SoftAssertions.assertSoftly(softly -> {
            softly.assertThat(receipt.customer()).isEqualTo("grace");
            softly.assertThat(receipt.totalCents()).isEqualTo(300);
        })));
    }

    @Test
    void mockitoWrongArguments() throws IOException {
        PaymentGateway gateway = mock(PaymentGateway.class);
        gateway.charge("ada", 250);
        check("mockito-arguments-different", failureOf(() -> verify(gateway).charge("ada", 300)));
    }

    @Test
    void mockitoUnusedStub() throws IOException {
        MockitoSession session = org.mockito.Mockito.mockitoSession().strictness(Strictness.STRICT_STUBS).startMocking();
        Inventory inventory = mock(Inventory.class);
        when(inventory.inStock("pen", 1)).thenReturn(true);
        check("mockito-unnecessary-stubbing", failureOf(session::finishMocking));
    }
}
