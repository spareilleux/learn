package dev.learn.scales.exercises;

import dev.learn.scales.ScalesApplication;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureRestTestClient;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.client.RestTestClient;

@SpringBootTest(classes = ScalesApplication.class, webEnvironment = WebEnvironment.RANDOM_PORT)
@AutoConfigureRestTestClient
class Exercise3ProblemDetailsTest {

    @Autowired
    RestTestClient client;

    @Test
    void unknownModeIsABadRequestProblem() {
        client.get().uri("/scales/C?mode=blues")
                .exchange()
                .expectStatus().isBadRequest()
                .expectHeader().contentType(MediaType.APPLICATION_PROBLEM_JSON)
                .expectBody()
                .jsonPath("$.title").isEqualTo("Unknown note or mode")
                .jsonPath("$.detail").isEqualTo("unknown mode: blues")
                .jsonPath("$.instance").isEqualTo("/scales/C");
    }
}
