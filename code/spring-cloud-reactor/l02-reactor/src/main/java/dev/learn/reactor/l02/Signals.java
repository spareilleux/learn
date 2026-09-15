package dev.learn.reactor.l02;

import reactor.core.publisher.Flux;

public class Signals {

    public static void main(String[] args) {
        // log() prints every signal that crosses this point of the pipeline.
        Flux.just("C", "E", "G")
                .map(String::toLowerCase)
                .log("triad")
                .take(2)
                .subscribe(note -> System.out.println("subscriber got " + note));
    }
}
