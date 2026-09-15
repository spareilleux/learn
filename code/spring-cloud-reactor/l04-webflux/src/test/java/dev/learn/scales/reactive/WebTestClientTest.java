package dev.learn.scales.reactive;

import dev.learn.scales.reactive.ScaleCatalog.ScaleView;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.webtestclient.autoconfigure.AutoConfigureWebTestClient;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.test.web.reactive.server.WebTestClient;
import reactor.test.StepVerifier;

@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT, properties = "progressions.beat=20ms")
@AutoConfigureWebTestClient
class WebTestClientTest {

    @Autowired
    WebTestClient client;

    @Test
    void jsonBody() {
        client.get().uri("/scales/A?mode=minor")
                .exchange()
                .expectStatus().isOk()
                .expectBody(ScaleView.class)
                .isEqualTo(new ScaleView("A", "aeolian", List.of("A", "B", "C", "D", "E", "F", "G"),
                        List.of("Am", "Bdim", "C", "Dm", "Em", "F", "G")));
    }

    @Test
    void ndjsonStreamAsAFlux() {
        var modes = client.get().uri("/scales/C/modes")
                .accept(MediaType.APPLICATION_NDJSON)
                .exchange()
                .expectStatus().isOk()
                .returnResult(ScaleView.class)
                .getResponseBody()
                .map(ScaleView::mode);
        StepVerifier.create(modes)
                .expectNext("ionian", "dorian", "phrygian", "lydian", "mixolydian", "aeolian", "locrian")
                .verifyComplete();
    }

    @Test
    void serverSentEvents() {
        var chords = client.get().uri("/progressions/F")
                .accept(MediaType.TEXT_EVENT_STREAM)
                .exchange()
                .expectStatus().isOk()
                .returnResult(new ParameterizedTypeReference<ServerSentEvent<String>>() {})
                .getResponseBody()
                .map(event -> event.id() + ":" + event.data());
        StepVerifier.create(chords)
                .expectNext("1:F", "2:Dm", "3:A#", "4:C")
                .verifyComplete();
    }

    @Test
    void problemDetail() {
        client.get().uri("/fn/scales/C?mode=blues")
                .exchange()
                .expectStatus().isBadRequest()
                .expectBody()
                .jsonPath("$.detail").isEqualTo("unknown mode: blues");
    }
}
