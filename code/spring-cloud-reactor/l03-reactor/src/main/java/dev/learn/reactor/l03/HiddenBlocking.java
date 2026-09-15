package dev.learn.reactor.l03;

import dev.learn.music.Scale;
import java.time.Duration;
import reactor.core.publisher.Mono;

/** Blocking calls that Reactor's own check doesn't see. Run it without BlockHound, then with its agent. */
public class HiddenBlocking {

    public static void main(String[] args) {
        try {
            // A Thread.sleep inside map, on a parallel() thread.
            Scale scale = Mono.delay(Duration.ofMillis(1))
                    .map(tick -> BlockingCalls.slowLookup("E", "phrygian"))
                    .block();
            System.out.println("sleep in map: no error, " + scale.notes());
        } catch (RuntimeException e) {
            System.out.println("sleep in map: " + e);
        }
        try {
            // block() on Mono.fromCallable runs the callable directly, without the check that caught the nested block().
            String where = Mono.delay(Duration.ofMillis(1))
                    .map(tick -> Mono.fromCallable(() -> {
                        BlockingCalls.slowLookup("F", "lydian");
                        return BlockingCalls.thread();
                    }).block())
                    .block();
            System.out.println("nested block() of Mono.fromCallable: no error, ran on " + where);
        } catch (RuntimeException e) {
            System.out.println("nested block() of Mono.fromCallable: " + e);
        }
    }
}
