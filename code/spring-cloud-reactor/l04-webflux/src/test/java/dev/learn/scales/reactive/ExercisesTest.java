package dev.learn.scales.reactive;

import static org.springframework.web.reactive.function.server.RouterFunctions.route;

import dev.learn.scales.reactive.ScaleCatalog.ScaleView;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.server.RouterFunction;
import org.springframework.web.reactive.function.server.ServerResponse;
import reactor.core.publisher.Mono;
import reactor.test.StepVerifier;
import reactor.util.retry.Retry;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT, properties = "progressions.beat=20ms")
@Import(ExercisesTest.ExerciseRoutes.class)
class ExercisesTest {

    @TestConfiguration
    static class ExerciseRoutes {

        // Exercise 1: the NDJSON stream of every mode, as a functional endpoint.
        @Bean
        RouterFunction<ServerResponse> modeRoutes(ScaleCatalog catalog) {
            return route()
                    .GET("/fn/scales/{root}/modes", request -> ServerResponse.ok()
                            .contentType(MediaType.APPLICATION_NDJSON)
                            .body(catalog.allModes(request.pathVariable("root")), ScaleView.class))
                    // Exercise 2 needs a service that answers too late.
                    .GET("/fn/slow", request -> ServerResponse.ok().body(Mono.delay(Duration.ofSeconds(2)).map(tick -> "late"), String.class))
                    .build();
        }
    }

    @LocalServerPort
    int port;

    @Autowired
    WebClient.Builder builder;

    @Test
    void exercise1FunctionalStream() {
        var modes = builder.baseUrl("http://localhost:" + port).build()
                .get().uri("/fn/scales/{root}/modes", "D")
                .accept(MediaType.APPLICATION_NDJSON)
                .retrieve()
                .bodyToFlux(ScaleView.class)
                .map(view -> view.root() + " " + view.mode());
        StepVerifier.create(modes)
                .expectNext("D ionian", "D dorian")
                .expectNextCount(5)
                .verifyComplete();
    }

    // Exercise 2: a call with a timeout, two retries with backoff, and a fallback value.
    static Mono<String> callWithFallback(WebClient client, String path) {
        return client.get().uri(path)
                .retrieve()
                .bodyToMono(String.class)
                .timeout(Duration.ofMillis(200))
                .retryWhen(Retry.backoff(2, Duration.ofMillis(50)).jitter(0))
                .onErrorReturn("service unavailable");
    }

    @Test
    void exercise2TimeoutRetryFallback() {
        WebClient client = builder.baseUrl("http://localhost:" + port).build();
        // Three attempts of 200 ms and two waits of 50 and 100 ms: about 750 ms.
        StepVerifier.create(callWithFallback(client, "/fn/slow"))
                .expectNext("service unavailable")
                .verifyComplete();
        StepVerifier.create(callWithFallback(client, "/scales/C"))
                .expectNextMatches(body -> body.startsWith("{\"root\":\"C\""))
                .verifyComplete();
    }

    // Exercise 3: read the first two chords of a progression as a client, and stop listening.
    @Test
    void exercise3FirstChordsOfAProgression() {
        Mono<List<String>> firstTwo = builder.baseUrl("http://localhost:" + port).build()
                .get().uri("/progressions/{root}", "D")
                .retrieve()
                .bodyToFlux(new ParameterizedTypeReference<ServerSentEvent<String>>() {})
                .map(ServerSentEvent::data)
                .take(2)
                .collectList();
        StepVerifier.create(firstTwo)
                .expectNext(List.of("D", "Bm"))
                .verifyComplete();
    }
}
