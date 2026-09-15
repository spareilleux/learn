package dev.learn.scales.reactive;

import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.test.StepVerifier;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class ChordChartClientTest {

    @LocalServerPort
    int port;

    // Spring Boot configures a WebClient.Builder with the application's codecs, like IHttpClientFactory.
    @Autowired
    WebClient.Builder builder;

    ChordChartClient charts;

    @BeforeEach
    void setUp() {
        charts = new ChordChartClient(builder, "http://localhost:" + port);
    }

    @Test
    void chartFromTheScalesApi() {
        StepVerifier.create(charts.chart("C", "major", List.of(2, 5, 1)))
                .expectNext("| Dm | G | C |")
                .verifyComplete();
    }

    @Test
    void anErrorStatusBecomesAnErrorSignal() {
        StepVerifier.create(charts.chart("H", "major", List.of(1)))
                .consumeErrorWith(error -> Expected.check("webclient-error",
                        error.getClass().getName() + ": " + error.getMessage().replace(":" + port + "/", ":<port>/")))
                .verify();
    }
}
