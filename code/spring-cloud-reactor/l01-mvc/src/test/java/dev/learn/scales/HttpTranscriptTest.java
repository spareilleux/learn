package dev.learn.scales;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.web.server.LocalServerPort;

// WebApplicationFactory<Program> with a real Kestrel: the application starts on a free port for the test class.
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
class HttpTranscriptTest {

    @LocalServerPort
    int port;

    private final HttpClient client = HttpClient.newHttpClient();

    @Test
    void requestsShownInTheLesson() throws Exception {
        var transcript = new StringBuilder();
        for (String path : new String[] {"/scales/D?mode=dorian", "/scales/Bb", "/scales/H", "/actuator/health/scaleCatalog", "/actuator/health/liveness"}) {
            var request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path)).build();
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            transcript.append("GET ").append(path).append('\n')
                    .append(response.statusCode()).append(' ')
                    .append(response.headers().firstValue("Content-Type").orElse("")).append('\n')
                    .append(response.body()).append("\n\n");
        }
        Expected.check("http", transcript.toString());
    }
}
