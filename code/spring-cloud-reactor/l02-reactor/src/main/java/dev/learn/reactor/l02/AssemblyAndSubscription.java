package dev.learn.reactor.l02;

import dev.learn.music.Scale;
import java.util.concurrent.CompletableFuture;
import reactor.core.publisher.Mono;

public class AssemblyAndSubscription {

    static Scale lookUp(String root, String mode) {
        System.out.println("  looking up " + root + " " + mode);
        return Scale.of(root, mode);
    }

    public static void main(String[] args) {
        // Assembly: this line builds a description of the work. Nothing runs yet.
        Mono<Scale> dorian = Mono.fromCallable(() -> lookUp("D", "dorian"));
        System.out.println("assembled a Mono");

        // Subscription starts the work, once per subscriber: a Mono is cold.
        System.out.println("first subscriber:");
        dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));
        System.out.println("second subscriber:");
        dorian.subscribe(scale -> System.out.println("  got " + scale.notes()));

        // A CompletableFuture is hot, like a Task: it starts when created and runs once.
        System.out.println("CompletableFuture:");
        CompletableFuture<Scale> future = CompletableFuture.supplyAsync(() -> lookUp("E", "phrygian"));
        future.join();
        System.out.println("  joined twice, same result: " + (future.join() == future.join()));

        // Mono.just takes a value, so its argument is computed during assembly, subscriber or not.
        System.out.println("Mono.just:");
        Mono<Scale> eager = Mono.just(lookUp("F", "lydian"));
        System.out.println("  assembled, no subscriber yet");

        // Mono.defer postpones building the Mono itself until someone subscribes.
        System.out.println("Mono.defer:");
        Mono<Scale> deferred = Mono.defer(() -> Mono.just(lookUp("G", "mixolydian")));
        System.out.println("  assembled, no subscriber yet");
        deferred.subscribe();
        eager.subscribe();
    }
}
