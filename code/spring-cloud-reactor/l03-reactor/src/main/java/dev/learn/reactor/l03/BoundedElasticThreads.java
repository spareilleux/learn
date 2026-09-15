package dev.learn.reactor.l03;

import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

/** Run it twice: as is, then with -Dreactor.schedulers.defaultBoundedElasticOnVirtualThreads=true. */
public class BoundedElasticThreads {

    public static void main(String[] args) {
        String where = Mono.fromCallable(() -> {
                    Thread thread = Thread.currentThread();
                    return thread.getName().replaceAll("-\\d+$", "") + ", virtual=" + thread.isVirtual();
                })
                .subscribeOn(Schedulers.boundedElastic())
                .block();
        System.out.println("boundedElastic() ran the call on " + where);
    }
}
