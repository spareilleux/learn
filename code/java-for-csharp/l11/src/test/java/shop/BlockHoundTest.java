package shop;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

/** BlockHound is installed by its Java agent, configured in Surefire's argLine: see pom.xml. */
class BlockHoundTest {

    static String slowLookup(String sku) {
        try {
            Thread.sleep(10);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        return sku.toUpperCase();
    }

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

    @Test
    void blockingOnAVirtualThreadIsAllowed() throws InterruptedException {
        var result = new String[1];
        Thread.ofVirtual().start(() -> result[0] = slowLookup("ink")).join();
        assertThat(result[0]).isEqualTo("INK");
    }
}
