package dev.learn.reactor.l03;

import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;
import reactor.util.context.Context;

public class ContextPropagation {

    static final ThreadLocal<String> CURRENT_USER = new ThreadLocal<>();

    /** Reads the user from the subscriber's context when it is subscribed to. */
    static Mono<String> greeting() {
        return Mono.deferContextual(context -> Mono.just("hello " + context.getOrDefault("user", "anonymous")));
    }

    public static void main(String[] args) {
        // contextWrite is written below the operators that read it: the context travels up with the subscription.
        System.out.println("context below the reader: " + greeting().contextWrite(Context.of("user", "ada")).block());

        // Written above, it only reaches what is above it.
        System.out.println("context above the reader: " + Mono.just("ignored")
                .contextWrite(Context.of("user", "ada"))
                .flatMap(value -> greeting())
                .block());

        // Two writes: the one closest to the reader wins.
        System.out.println("two writes: " + greeting()
                .contextWrite(Context.of("user", "grace"))
                .contextWrite(Context.of("user", "ada"))
                .block());

        // A ThreadLocal stays on its thread; the context follows the pipeline to another one.
        CURRENT_USER.set("ada");
        try {
            String seen = Mono.just("scale")
                    .publishOn(Schedulers.parallel())
                    .flatMap(value -> Mono.deferContextual(context ->
                            Mono.just("ThreadLocal=" + CURRENT_USER.get() + ", context=" + context.get("user"))))
                    .contextWrite(Context.of("user", "ada"))
                    .block();
            System.out.println("after publishOn: " + seen);
        } finally {
            CURRENT_USER.remove();
        }
    }
}
