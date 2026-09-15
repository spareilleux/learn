package dev.learn.reactor.l03;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import dev.learn.music.Scale;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

/** BlockHound is installed by its Java agent, configured in Surefire's argLine: see pom.xml. */
class BlockHoundTest {

    @Test
    void sleepingOnParallelIsReported() {
        // A Thread.sleep hidden in a map: Reactor's own check can't see it, BlockHound does.
        var error = assertThrows(RuntimeException.class, () -> Mono.delay(Duration.ofMillis(1))
                .map(tick -> BlockingCalls.slowLookup("D", "dorian"))
                .block());
        assertEquals("reactor.blockhound.BlockingOperationError: Blocking call! java.lang.Thread.sleepNanos0", error.getMessage());
    }

    @Test
    void theSameCallOnBoundedElasticPasses() {
        Scale scale = Mono.delay(Duration.ofMillis(1))
                .flatMap(tick -> Mono.fromCallable(() -> BlockingCalls.slowLookup("D", "dorian"))
                        .subscribeOn(Schedulers.boundedElastic()))
                .block();
        assertEquals("[D, E, F, G, A, B, C]", scale.notes().toString());
    }
}
