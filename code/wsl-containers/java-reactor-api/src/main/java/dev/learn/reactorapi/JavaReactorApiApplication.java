package dev.learn.reactorapi;

import java.time.Duration;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@SpringBootApplication
public class JavaReactorApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(JavaReactorApiApplication.class, args);
	}

}

record Info(String app, String runtime, String os, String machine) {
}

@RestController
class InfoController {

	// GET / : who am I, and where am I running?
	@GetMapping("/")
	Mono<Info> info() {
		return Mono.just(new Info(
				"java-reactor-api",
				"Java " + Runtime.version(),
				System.getProperty("os.name") + " " + System.getProperty("os.version"),
				System.getenv().getOrDefault("HOSTNAME", "?")));
	}

	// GET /ticks : a stream of 3 Server-Sent Events, one per second
	@GetMapping(value = "/ticks", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
	Flux<Long> ticks() {
		return Flux.interval(Duration.ofSeconds(1)).take(3);
	}

}
