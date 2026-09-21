package dev.learn.spring.l06;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.netty.DisposableServer;
import reactor.netty.http.server.HttpServer;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GatewayApplicationTest {
    private static DisposableServer upstream;

    @LocalServerPort
    int port;

    @BeforeAll
    static void startUpstream() {
        upstream = HttpServer.create().port(0)
                .route(routes -> routes.get("/scales/C", (request, response) -> response
                        .header("Content-Type", "text/plain")
                        .sendString(reactor.core.publisher.Mono.just(
                                request.uri() + "|" + request.requestHeaders().get("X-Course")))))
                .bindNow();
    }

    @AfterAll
    static void stopUpstream() {
        upstream.disposeNow();
    }

    @DynamicPropertySource
    static void gatewayProperties(DynamicPropertyRegistry properties) {
        properties.add("course.scales-uri", () -> "http://localhost:" + upstream.port());
    }

    @Test
    void matchesRewritesAndForwardsTheRequest() {
        WebTestClient.bindToServer().baseUrl("http://localhost:" + port).build()
                .get().uri("/api/scales/C")
                .exchange()
                .expectStatus().isOk()
                .expectBody(String.class).isEqualTo("/scales/C|spring-cloud-gateway");
    }

    @Test
    void anUnmatchedPathDoesNotReachTheUpstream() {
        WebTestClient.bindToServer().baseUrl("http://localhost:" + port).build()
                .get().uri("/other")
                .exchange()
                .expectStatus().isNotFound();
    }
}
