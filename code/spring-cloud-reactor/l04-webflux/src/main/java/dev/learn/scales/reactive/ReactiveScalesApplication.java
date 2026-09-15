package dev.learn.scales.reactive;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// Same entry point as lesson 1: spring-boot-starter-webflux on the class path makes it a Netty server.
@SpringBootApplication
public class ReactiveScalesApplication {

    public static void main(String[] args) {
        SpringApplication.run(ReactiveScalesApplication.class, args);
    }
}
